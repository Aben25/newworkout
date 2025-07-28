import 'package:logger/logger.dart';
import '../models/user_profile.dart';

/// Mock authentication service for testing without Supabase
class MockAuthService {
  static MockAuthService? _instance;
  static MockAuthService get instance => _instance ??= MockAuthService._();
  
  MockAuthService._();
  
  final Logger _logger = Logger();
  
  // Mock user data
  static const _mockUser = {
    'id': 'mock-user-123',
    'email': 'demo@example.com',
    'display_name': 'Demo User',
  };
  
  static const _mockProfile = {
    'id': 'mock-user-123',
    'email': 'demo@example.com',
    'display_name': 'Demo User',
    'age': 25,
    'gender': 'other',
    'height': 175.0,
    'weight': 70.0,
    'fitness_goals_array': ['weight_loss', 'muscle_gain'],
    'fitness_level': 3,
    'equipment': ['dumbbells', 'bodyweight'],
    'workout_days': ['monday', 'wednesday', 'friday'],
    'workout_duration': 60,
    'workout_frequency': 3,
    'onboarding_completed': true,
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-01-01T00:00:00Z',
  };
  
  /// Mock sign in - always succeeds with demo credentials
  Future<Map<String, dynamic>> mockSignIn(String email, String password) async {
    _logger.i('Mock sign in for: $email');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Simple validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    return {
      'user': _mockUser,
      'profile': _mockProfile,
    };
  }
  
  /// Mock sign up - always succeeds
  Future<Map<String, dynamic>> mockSignUp(String email, String password, String? displayName) async {
    _logger.i('Mock sign up for: $email');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Simple validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    final mockUser = Map<String, dynamic>.from(_mockUser);
    final mockProfile = Map<String, dynamic>.from(_mockProfile);
    
    if (displayName != null && displayName.isNotEmpty) {
      mockUser['display_name'] = displayName;
      mockProfile['display_name'] = displayName;
    }
    
    mockUser['email'] = email;
    mockProfile['email'] = email;
    
    return {
      'user': mockUser,
      'profile': mockProfile,
    };
  }
  
  /// Mock password reset
  Future<void> mockResetPassword(String email) async {
    _logger.i('Mock password reset for: $email');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (email.isEmpty) {
      throw Exception('Email is required');
    }
    
    // Always succeeds in mock mode
  }
  
  /// Get mock user profile
  UserProfile getMockProfile() {
    return UserProfile.fromJson(_mockProfile);
  }
}