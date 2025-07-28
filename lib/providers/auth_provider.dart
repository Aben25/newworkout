import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:logger/logger.dart';
import '../models/auth_state.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService, this._storageService) : super(const AuthState.initial()) {
    _initialize();
  }

  final AuthService _authService;
  final StorageService _storageService;
  final Logger _logger = Logger();
  StreamSubscription<supabase.AuthState>? _authSubscription;

  /// Initialize authentication state
  Future<void> _initialize() async {
    try {
      _logger.i('Initializing authentication state');
      
      // Listen to auth state changes
      _authSubscription = _authService.authStateChanges.listen(
        _handleAuthStateChange,
        onError: (error, stackTrace) {
          _logger.e(
            'Auth state change error',
            error: error,
            stackTrace: stackTrace,
          );
          state = AuthState.error(error.toString());
        },
      );
      
      // Check current authentication status
      await _checkCurrentAuth();
      
      _logger.i('Authentication state initialized');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize authentication state',
        error: e,
        stackTrace: stackTrace,
      );
      state = AuthState.error(e.toString());
    }
  }

  /// Check current authentication status
  Future<void> _checkCurrentAuth() async {
    try {
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        _logger.d('Current user found: ${currentUser.id}');
        
        // Validate session
        final isValid = await _authService.isSessionValid();
        if (!isValid) {
          _logger.w('Session is invalid, signing out');
          await signOut();
          return;
        }
        
        // Load user profile
        final profile = await _loadUserProfile(currentUser.id);
        state = AuthState.authenticated(user: currentUser, profile: profile);
      } else {
        _logger.d('No current user found');
        state = const AuthState.unauthenticated();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to check current authentication',
        error: e,
        stackTrace: stackTrace,
      );
      state = AuthState.error(e.toString());
    }
  }

  /// Handle auth state changes from Supabase
  Future<void> _handleAuthStateChange(supabase.AuthState authState) async {
    try {
      _logger.d('Auth state changed: ${authState.event}');
      
      switch (authState.event) {
        case supabase.AuthChangeEvent.signedIn:
          if (authState.session?.user != null) {
            final profile = await _loadUserProfile(authState.session!.user.id);
            state = AuthState.authenticated(
              user: authState.session!.user,
              profile: profile,
            );
          }
          break;
          
        case supabase.AuthChangeEvent.signedOut:
          await _clearLocalData();
          state = const AuthState.unauthenticated();
          break;
          
        case supabase.AuthChangeEvent.tokenRefreshed:
          if (authState.session?.user != null) {
            // Keep current profile if available
            state = state.copyWith(user: authState.session!.user);
          }
          break;
          
        case supabase.AuthChangeEvent.userUpdated:
          if (authState.session?.user != null) {
            final profile = await _loadUserProfile(authState.session!.user.id);
            state = AuthState.authenticated(
              user: authState.session!.user,
              profile: profile,
            );
          }
          break;
          
        default:
          _logger.d('Unhandled auth event: ${authState.event}');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to handle auth state change',
        error: e,
        stackTrace: stackTrace,
      );
      state = AuthState.error(e.toString());
    }
  }

  /// Load user profile from database or cache
  Future<UserProfile?> _loadUserProfile(String userId) async {
    try {
      _logger.d('Loading user profile for: $userId');
      
      // Try to load from cache first
      final cachedProfile = _storageService.retrieve<Map<String, dynamic>>(
        AppConstants.userProfileBox,
        userId,
      );
      
      UserProfile? profile;
      
      if (cachedProfile != null) {
        try {
          profile = UserProfile.fromJson(cachedProfile);
          _logger.d('Profile loaded from cache');
        } catch (e) {
          _logger.w('Failed to parse cached profile, fetching from server');
        }
      }
      
      // Fetch from server if not in cache or cache is invalid
      if (profile == null) {
        profile = await _authService.getUserProfile(userId);
        
        if (profile != null) {
          // Cache the profile
          await _storageService.store(
            AppConstants.userProfileBox,
            userId,
            profile.toJson(),
          );
          _logger.d('Profile loaded from server and cached');
        }
      }
      
      return profile;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to load user profile',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = const AuthState.loading();
      _logger.i('Signing up user with email: $email');
      
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      if (response.user != null) {
        // Create initial profile
        final profile = await _authService.createUserProfile(
          userId: response.user!.id,
          email: email,
          displayName: displayName,
        );
        
        // Cache the profile
        await _storageService.store(
          AppConstants.userProfileBox,
          response.user!.id,
          profile.toJson(),
        );
        
        state = AuthState.authenticated(user: response.user!, profile: profile);
        _logger.i('User signed up successfully');
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign up user',
        error: e,
        stackTrace: stackTrace,
      );
      state = AuthState.error(_getErrorMessage(e));
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = const AuthState.loading();
      _logger.i('Signing in user with email: $email');
      
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final profile = await _loadUserProfile(response.user!.id);
        state = AuthState.authenticated(user: response.user!, profile: profile);
        _logger.i('User signed in successfully');
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign in user',
        error: e,
        stackTrace: stackTrace,
      );
      state = AuthState.error(_getErrorMessage(e));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      state = const AuthState.loading();
      _logger.i('Signing in with Google');
      
      final success = await _authService.signInWithGoogle();
      
      if (!success) {
        state = const AuthState.unauthenticated();
        _logger.w('Google sign in was not successful');
      }
      // Auth state will be updated via the auth state listener
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign in with Google',
        error: e,
        stackTrace: stackTrace,
      );
      state = AuthState.error(_getErrorMessage(e));
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      state = const AuthState.loading();
      _logger.i('Signing in with Apple');
      
      final success = await _authService.signInWithApple();
      
      if (!success) {
        state = const AuthState.unauthenticated();
        _logger.w('Apple sign in was not successful');
      }
      // Auth state will be updated via the auth state listener
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign in with Apple',
        error: e,
        stackTrace: stackTrace,
      );
      state = AuthState.error(_getErrorMessage(e));
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      _logger.i('Resetting password for email: $email');
      
      await _authService.resetPassword(email);
      
      _logger.i('Password reset email sent successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to reset password',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    try {
      _logger.i('Updating user profile: ${profile.id}');
      
      await _authService.updateUserProfile(profile);
      
      // Update cache
      await _storageService.store(
        AppConstants.userProfileBox,
        profile.id,
        profile.toJson(),
      );
      
      // Update state
      state = state.copyWith(profile: profile);
      
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

  /// Sign out
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');
      
      await _authService.signOut();
      await _clearLocalData();
      
      state = const AuthState.unauthenticated();
      _logger.i('User signed out successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to sign out user',
        error: e,
        stackTrace: stackTrace,
      );
      state = AuthState.error(_getErrorMessage(e));
    }
  }

  /// Clear local data
  Future<void> _clearLocalData() async {
    try {
      await _storageService.clearBox(AppConstants.userProfileBox);
      _logger.d('Local authentication data cleared');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to clear local data',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is supabase.AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid login credentials':
          return 'Invalid email or password. Please try again.';
        case 'email not confirmed':
          return 'Please check your email and confirm your account.';
        case 'user not found':
          return 'No account found with this email address.';
        case 'weak password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'email already registered':
          return 'An account with this email already exists.';
        default:
          return error.message;
      }
    }
    
    return error.toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// Provider definitions
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthNotifier(authService, storageService);
});

// Convenience providers
final currentUserProvider = Provider<supabase.User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

final userProfileProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.profile;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isLoading;
});