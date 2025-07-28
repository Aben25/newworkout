import 'package:flutter_test/flutter_test.dart';
import 'package:modern_workout_tracker/models/user_profile.dart';
import 'package:modern_workout_tracker/models/auth_state.dart';

void main() {
  group('Authentication Models Tests', () {
    test('UserProfile should serialize to/from JSON correctly', () {
      // Arrange
      final profile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        age: 25,
        gender: 'male',
        height: 180.0,
        weight: 75.0,
        fitnessGoalsArray: ['weight_loss', 'muscle_gain'],
        fitnessLevel: 3,
        equipment: ['dumbbells', 'barbell'],
        workoutDays: ['monday', 'wednesday', 'friday'],
        workoutDuration: 60,
        workoutFrequency: 3,
        onboardingCompleted: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      // Act
      final json = profile.toJson();
      final deserializedProfile = UserProfile.fromJson(json);

      // Assert
      expect(deserializedProfile.id, equals(profile.id));
      expect(deserializedProfile.email, equals(profile.email));
      expect(deserializedProfile.displayName, equals(profile.displayName));
      expect(deserializedProfile.age, equals(profile.age));
      expect(deserializedProfile.gender, equals(profile.gender));
      expect(deserializedProfile.height, equals(profile.height));
      expect(deserializedProfile.weight, equals(profile.weight));
      expect(deserializedProfile.fitnessGoalsArray, equals(profile.fitnessGoalsArray));
      expect(deserializedProfile.fitnessLevel, equals(profile.fitnessLevel));
      expect(deserializedProfile.equipment, equals(profile.equipment));
      expect(deserializedProfile.workoutDays, equals(profile.workoutDays));
      expect(deserializedProfile.workoutDuration, equals(profile.workoutDuration));
      expect(deserializedProfile.workoutFrequency, equals(profile.workoutFrequency));
      expect(deserializedProfile.onboardingCompleted, equals(profile.onboardingCompleted));
      expect(deserializedProfile.createdAt, equals(profile.createdAt));
      expect(deserializedProfile.updatedAt, equals(profile.updatedAt));
    });

    test('UserProfile copyWith should work correctly', () {
      // Arrange
      final profile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        onboardingCompleted: false,
      );

      // Act
      final updatedProfile = profile.copyWith(
        displayName: 'Updated User',
        onboardingCompleted: true,
      );

      // Assert
      expect(updatedProfile.id, equals(profile.id));
      expect(updatedProfile.email, equals(profile.email));
      expect(updatedProfile.displayName, equals('Updated User'));
      expect(updatedProfile.onboardingCompleted, equals(true));
    });

    test('AuthState should have correct status properties', () {
      // Test initial state
      const initialState = AuthState.initial();
      expect(initialState.isInitial, isTrue);
      expect(initialState.isAuthenticated, isFalse);
      expect(initialState.isUnauthenticated, isFalse);
      expect(initialState.hasError, isFalse);
      expect(initialState.isLoading, isFalse);

      // Test loading state
      const loadingState = AuthState.loading();
      expect(loadingState.isLoading, isTrue);
      expect(loadingState.isAuthenticated, isFalse);

      // Test unauthenticated state
      const unauthenticatedState = AuthState.unauthenticated();
      expect(unauthenticatedState.isUnauthenticated, isTrue);
      expect(unauthenticatedState.isAuthenticated, isFalse);

      // Test error state
      const errorState = AuthState.error('Test error');
      expect(errorState.hasError, isTrue);
      expect(errorState.errorMessage, equals('Test error'));
      expect(errorState.isAuthenticated, isFalse);
    });

    test('AuthState copyWith should work correctly', () {
      // Arrange
      const initialState = AuthState.initial();

      // Act
      final updatedState = initialState.copyWith(
        isLoading: true,
        errorMessage: 'Test error',
      );

      // Assert
      expect(updatedState.status, equals(initialState.status));
      expect(updatedState.isLoading, isTrue);
      expect(updatedState.errorMessage, equals('Test error'));
    });
  });
}