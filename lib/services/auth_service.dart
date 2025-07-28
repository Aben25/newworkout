import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  
  /// Get current user
  User? get currentUser => _supabaseService.currentUser;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _supabaseService.isAuthenticated;
  
  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;
  
  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _logger.i('Attempting to sign up user with email: $email');
      
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      
      if (response.user != null) {
        await _handleSuccessfulAuth(response.user!, response.session);
        _logger.i('User signed up successfully: ${response.user!.id}');
      }
      
      return response;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign up user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Attempting to sign in user with email: $email');
      
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _handleSuccessfulAuth(response.user!, response.session);
        _logger.i('User signed in successfully: ${response.user!.id}');
      }
      
      return response;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign in user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _logger.i('Attempting to sign in with Google');
      
      final response = await _supabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.modernworkouttracker.app://login-callback/',
      );
      
      _logger.i('Google sign in initiated: $response');
      return response;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign in with Google',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      _logger.i('Attempting to sign in with Apple');
      
      final response = await _supabaseService.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.modernworkouttracker.app://login-callback/',
      );
      
      _logger.i('Apple sign in initiated: $response');
      return response;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign in with Apple',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      _logger.i('Attempting to reset password for email: $email');
      
      await _supabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.modernworkouttracker.app://reset-password/',
      );
      
      _logger.i('Password reset email sent successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to send password reset email',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      _logger.i('Attempting to update user password');
      
      final response = await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      _logger.i('Password updated successfully');
      return response;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update password',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      _logger.i('Attempting to sign out user');
      
      await _supabaseService.signOut();
      await _secureStorage.clearAuthData();
      
      _logger.i('User signed out successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign out user',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Get user profile
  Future<UserProfile?> getUserProfile([String? userId]) async {
    try {
      final targetUserId = userId ?? currentUser?.id;
      if (targetUserId == null) {
        _logger.w('No user ID provided and no current user');
        return null;
      }
      
      _logger.d('Fetching user profile for ID: $targetUserId');
      
      final profileData = await _supabaseService.getUserProfile(targetUserId);
      if (profileData != null) {
        final profile = UserProfile.fromJson(profileData);
        _logger.d('User profile fetched successfully');
        return profile;
      }
      
      _logger.w('No profile found for user: $targetUserId');
      return null;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get user profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      _logger.i('Updating user profile for ID: ${profile.id}');
      
      final profileData = profile.toJson();
      await _supabaseService.updateUserProfile(profile.id, profileData);
      
      _logger.i('User profile updated successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update user profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Create initial user profile
  Future<UserProfile> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      _logger.i('Creating initial user profile for ID: $userId');
      
      final profile = UserProfile(
        id: userId,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await updateUserProfile(profile);
      
      _logger.i('Initial user profile created successfully');
      return profile;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create user profile',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      _logger.d('Refreshing user session');
      
      final response = await _supabaseService.client.auth.refreshSession();
      
      if (response.user != null) {
        await _handleSuccessfulAuth(response.user!, response.session);
        _logger.d('Session refreshed successfully');
      }
      
      return response;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to refresh session',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      // Check if session is expired
      final session = _supabaseService.client.auth.currentSession;
      if (session == null) return false;
      
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final now = DateTime.now();
      
      // Refresh if session expires within 5 minutes
      if (expiresAt.difference(now).inMinutes < 5) {
        _logger.d('Session expires soon, attempting refresh');
        final refreshResponse = await refreshSession();
        return refreshResponse.user != null;
      }
      
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to validate session',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  /// Handle successful authentication
  Future<void> _handleSuccessfulAuth(User user, Session? session) async {
    try {
      // Store tokens securely
      if (session?.accessToken != null) {
        await _secureStorage.storeAccessToken(session!.accessToken);
      }
      
      if (session?.refreshToken != null) {
        await _secureStorage.storeRefreshToken(session!.refreshToken!);
      }
      
      // Store user ID
      await _secureStorage.storeUserId(user.id);
      
      // Store last login timestamp
      await _secureStorage.storeLastLogin();
      
      _logger.d('Authentication data stored securely');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to handle successful authentication',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow here as the auth was successful
    }
  }
}