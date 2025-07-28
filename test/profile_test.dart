import 'package:flutter_test/flutter_test.dart';
import 'package:modern_workout_tracker/models/user_profile.dart';
import 'package:modern_workout_tracker/services/profile_service.dart';

void main() {
  group('Profile Service Tests', () {
    late ProfileService profileService;

    setUp(() {
      profileService = ProfileService.instance;
    });

    test('should calculate profile completion correctly', () {
      // Create a profile with basic info complete
      final profile = UserProfile(
        id: 'test-id',
        displayName: 'Test User',
        age: 25,
        gender: 'male',
        height: 180.0,
        weight: 75.0,
        fitnessGoalsArray: ['Weight Loss', 'Strength'],
        cardioFitnessLevel: 3,
        weightliftingFitnessLevel: 2,
        equipment: ['Dumbbells', 'Yoga Mat'],
        workoutDays: ['Monday', 'Wednesday', 'Friday'],
        workoutDurationInt: 60,
        workoutFrequencyInt: 3,
        healthConditions: ['None'],
        physicalLimitations: ['None'],
        dietPreferences: ['No Restrictions'],
        sleepQuality: 'good',
        sportActivity: 'weightlifting',
        workoutEnvironment: ['Gym'],
      );

      final completion = profileService.calculateProfileCompletion(profile);
      
      // Should be close to 100% since most fields are filled
      expect(completion, greaterThan(0.8));
    });

    test('should get profile section status correctly', () {
      final profile = UserProfile(
        id: 'test-id',
        displayName: 'Test User',
        age: 25,
        gender: 'male',
        height: 180.0,
        weight: 75.0,
      );

      final sectionStatus = profileService.getProfileSectionStatus(profile);
      
      expect(sectionStatus['Basic Information']?.isComplete, isTrue);
      expect(sectionStatus['Fitness Goals']?.isComplete, isFalse);
    });

    test('should convert height units correctly', () {
      // Convert 180 cm to feet
      final heightInFeet = profileService.convertHeight(180.0, 'cm', 'ft');
      expect(heightInFeet, closeTo(5.91, 0.1));

      // Convert 6 feet to cm
      final heightInCm = profileService.convertHeight(6.0, 'ft', 'cm');
      expect(heightInCm, closeTo(182.88, 0.1));
    });

    test('should convert weight units correctly', () {
      // Convert 75 kg to lbs
      final weightInLbs = profileService.convertWeight(75.0, 'kg', 'lbs');
      expect(weightInLbs, closeTo(165.35, 0.1));

      // Convert 165 lbs to kg
      final weightInKg = profileService.convertWeight(165.0, 'lbs', 'kg');
      expect(weightInKg, closeTo(74.84, 0.1));
    });

    test('should format height correctly', () {
      // Test cm formatting
      final heightCm = profileService.formatHeight(180.0, 'cm');
      expect(heightCm, equals('180.0 cm'));

      // Test feet formatting
      final heightFt = profileService.formatHeight(5.91, 'ft');
      expect(heightFt, equals('5\'11"'));
    });

    test('should calculate BMI correctly', () {
      // Test BMI calculation with metric units
      final bmi = profileService.calculateBMI(180.0, 'cm', 75.0, 'kg');
      expect(bmi, closeTo(23.15, 0.1));

      // Test BMI calculation with imperial units
      final bmiImperial = profileService.calculateBMI(5.91, 'ft', 165.0, 'lbs');
      expect(bmiImperial, closeTo(23.15, 0.5));
    });

    test('should get BMI category correctly', () {
      expect(profileService.getBMICategory(18.0), equals('Underweight'));
      expect(profileService.getBMICategory(22.0), equals('Normal weight'));
      expect(profileService.getBMICategory(27.0), equals('Overweight'));
      expect(profileService.getBMICategory(32.0), equals('Obese'));
      expect(profileService.getBMICategory(null), equals('Unknown'));
    });
  });

  group('UserProfile Model Tests', () {
    test('should create profile with all fields', () {
      final profile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        age: 25,
        gender: 'male',
        height: 180.0,
        weight: 75.0,
        fitnessGoalsArray: ['Weight Loss'],
        equipment: ['Dumbbells'],
        workoutDays: ['Monday'],
        healthConditions: ['None'],
        profilePhotoUrl: 'https://example.com/photo.jpg',
      );

      expect(profile.id, equals('test-id'));
      expect(profile.email, equals('test@example.com'));
      expect(profile.displayName, equals('Test User'));
      expect(profile.profilePhotoUrl, equals('https://example.com/photo.jpg'));
    });

    test('should validate basic info completion', () {
      final incompleteProfile = UserProfile(
        id: 'test-id',
        displayName: 'Test User',
        age: 25,
        // Missing gender, height, weight
      );

      expect(incompleteProfile.isBasicInfoComplete, isFalse);

      final completeProfile = UserProfile(
        id: 'test-id',
        displayName: 'Test User',
        age: 25,
        gender: 'male',
        height: 180.0,
        weight: 75.0,
      );

      expect(completeProfile.isBasicInfoComplete, isTrue);
    });

    test('should validate fitness goals completion', () {
      final profileWithoutGoals = UserProfile(
        id: 'test-id',
      );

      expect(profileWithoutGoals.isFitnessGoalsComplete, isFalse);

      final profileWithGoals = UserProfile(
        id: 'test-id',
        fitnessGoalsArray: ['Weight Loss', 'Strength'],
      );

      expect(profileWithGoals.isFitnessGoalsComplete, isTrue);
    });

    test('should copy profile with new values', () {
      final originalProfile = UserProfile(
        id: 'test-id',
        displayName: 'Original Name',
        age: 25,
      );

      final updatedProfile = originalProfile.copyWith(
        displayName: 'Updated Name',
        age: 26,
        profilePhotoUrl: 'https://example.com/new-photo.jpg',
      );

      expect(updatedProfile.id, equals('test-id')); // Unchanged
      expect(updatedProfile.displayName, equals('Updated Name')); // Changed
      expect(updatedProfile.age, equals(26)); // Changed
      expect(updatedProfile.profilePhotoUrl, equals('https://example.com/new-photo.jpg')); // New
    });
  });
}