import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class ProfileService {
  static ProfileService? _instance;
  static ProfileService get instance => _instance ??= ProfileService._();
  
  ProfileService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        _logger.w('No authenticated user found');
        return null;
      }

      final profileData = await _supabaseService.getUserProfile(userId);
      if (profileData == null) {
        _logger.w('No profile found for user: $userId');
        return null;
      }

      return UserProfile.fromJson(profileData);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get current user profile',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Upload profile photo to Supabase Storage
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      _logger.i('Uploading profile photo for user: $userId');
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'profile_${userId}_$timestamp.$extension';
      
      // Upload to Supabase Storage
      final response = await _supabaseService.client.storage
          .from('profile-photos')
          .upload(fileName, imageFile);
      
      if (response.isEmpty) {
        throw Exception('Failed to upload profile photo');
      }
      
      // Get public URL
      final publicUrl = _supabaseService.client.storage
          .from('profile-photos')
          .getPublicUrl(fileName);
      
      // Update user profile with photo URL
      await _supabaseService.updateUserProfile(userId, {
        'profile_photo_url': publicUrl,
      });
      
      _logger.i('Profile photo uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to upload profile photo',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Delete profile photo from Supabase Storage
  Future<void> deleteProfilePhoto(String userId, String photoUrl) async {
    try {
      _logger.i('Deleting profile photo for user: $userId');
      
      // Extract filename from URL
      final uri = Uri.parse(photoUrl);
      final fileName = uri.pathSegments.last;
      
      // Delete from Supabase Storage
      await _supabaseService.client.storage
          .from('profile-photos')
          .remove([fileName]);
      
      // Update user profile to remove photo URL
      await _supabaseService.updateUserProfile(userId, {
        'profile_photo_url': null,
      });
      
      _logger.i('Profile photo deleted successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to delete profile photo',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Calculate profile completion percentage
  double calculateProfileCompletion(UserProfile profile) {
    int completedFields = 0;
    int totalFields = 0;
    
    // Basic Information (weight: 25%)
    totalFields += 5;
    if (profile.displayName?.isNotEmpty == true) completedFields++;
    if (profile.age != null) completedFields++;
    if (profile.gender?.isNotEmpty == true) completedFields++;
    if (profile.height != null) completedFields++;
    if (profile.weight != null) completedFields++;
    
    // Fitness Goals (weight: 20%)
    totalFields += 3;
    if (profile.fitnessGoalsArray?.isNotEmpty == true) completedFields++;
    if (profile.cardioFitnessLevel != null) completedFields++;
    if (profile.weightliftingFitnessLevel != null) completedFields++;
    
    // Equipment & Preferences (weight: 20%)
    totalFields += 4;
    if (profile.equipment?.isNotEmpty == true) completedFields++;
    if (profile.workoutDays?.isNotEmpty == true) completedFields++;
    if (profile.workoutDurationInt != null) completedFields++;
    if (profile.workoutFrequencyInt != null) completedFields++;
    
    // Health Information (weight: 15%)
    totalFields += 2;
    if (profile.healthConditions?.isNotEmpty == true) completedFields++;
    if (profile.physicalLimitations?.isNotEmpty == true) completedFields++;
    
    // Nutrition (weight: 10%)
    totalFields += 2;
    if (profile.dietPreferences?.isNotEmpty == true) completedFields++;
    if (profile.sleepQuality?.isNotEmpty == true) completedFields++;
    
    // Additional Information (weight: 10%)
    totalFields += 2;
    if (profile.sportActivity?.isNotEmpty == true) completedFields++;
    if (profile.workoutEnvironment?.isNotEmpty == true) completedFields++;
    
    return totalFields > 0 ? (completedFields / totalFields) : 0.0;
  }
  
  /// Get profile completion sections with their status
  Map<String, ProfileSectionStatus> getProfileSectionStatus(UserProfile profile) {
    return {
      'Basic Information': ProfileSectionStatus(
        isComplete: profile.isBasicInfoComplete,
        completedFields: [
          if (profile.displayName?.isNotEmpty == true) 'Display Name',
          if (profile.age != null) 'Age',
          if (profile.gender?.isNotEmpty == true) 'Gender',
          if (profile.height != null) 'Height',
          if (profile.weight != null) 'Weight',
        ],
        totalFields: 5,
      ),
      'Fitness Goals': ProfileSectionStatus(
        isComplete: profile.isFitnessGoalsComplete && 
                   profile.cardioFitnessLevel != null && 
                   profile.weightliftingFitnessLevel != null,
        completedFields: [
          if (profile.fitnessGoalsArray?.isNotEmpty == true) 'Fitness Goals',
          if (profile.cardioFitnessLevel != null) 'Cardio Level',
          if (profile.weightliftingFitnessLevel != null) 'Weightlifting Level',
        ],
        totalFields: 3,
      ),
      'Equipment & Preferences': ProfileSectionStatus(
        isComplete: profile.isEquipmentComplete && 
                   profile.isWorkoutPreferencesComplete,
        completedFields: [
          if (profile.equipment?.isNotEmpty == true) 'Equipment',
          if (profile.workoutDays?.isNotEmpty == true) 'Workout Days',
          if (profile.workoutDurationInt != null) 'Duration',
          if (profile.workoutFrequencyInt != null) 'Frequency',
        ],
        totalFields: 4,
      ),
      'Health Information': ProfileSectionStatus(
        isComplete: profile.healthConditions?.isNotEmpty == true && 
                   profile.physicalLimitations?.isNotEmpty == true,
        completedFields: [
          if (profile.healthConditions?.isNotEmpty == true) 'Health Conditions',
          if (profile.physicalLimitations?.isNotEmpty == true) 'Physical Limitations',
        ],
        totalFields: 2,
      ),
      'Nutrition': ProfileSectionStatus(
        isComplete: profile.dietPreferences?.isNotEmpty == true && 
                   profile.sleepQuality?.isNotEmpty == true,
        completedFields: [
          if (profile.dietPreferences?.isNotEmpty == true) 'Diet Preferences',
          if (profile.sleepQuality?.isNotEmpty == true) 'Sleep Quality',
        ],
        totalFields: 2,
      ),
      'Additional Information': ProfileSectionStatus(
        isComplete: profile.sportActivity?.isNotEmpty == true && 
                   profile.workoutEnvironment?.isNotEmpty == true,
        completedFields: [
          if (profile.sportActivity?.isNotEmpty == true) 'Sport Activity',
          if (profile.workoutEnvironment?.isNotEmpty == true) 'Workout Environment',
        ],
        totalFields: 2,
      ),
    };
  }
  
  /// Convert height between units
  double convertHeight(double height, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return height;
    
    if (fromUnit == 'cm' && toUnit == 'ft') {
      return height / 30.48; // Convert cm to feet
    } else if (fromUnit == 'ft' && toUnit == 'cm') {
      return height * 30.48; // Convert feet to cm
    }
    
    return height;
  }
  
  /// Convert weight between units
  double convertWeight(double weight, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return weight;
    
    if (fromUnit == 'kg' && toUnit == 'lbs') {
      return weight * 2.20462; // Convert kg to lbs
    } else if (fromUnit == 'lbs' && toUnit == 'kg') {
      return weight / 2.20462; // Convert lbs to kg
    }
    
    return weight;
  }
  
  /// Format height for display
  String formatHeight(double? height, String unit) {
    if (height == null) return 'Not set';
    
    if (unit == 'ft') {
      final feet = height.floor();
      final inches = ((height - feet) * 12).round();
      return '$feet\'$inches"';
    } else {
      return '${height.toStringAsFixed(1)} $unit';
    }
  }
  
  /// Format weight for display
  String formatWeight(double? weight, String unit) {
    if (weight == null) return 'Not set';
    return '${weight.toStringAsFixed(1)} $unit';
  }
  
  /// Get BMI calculation
  double? calculateBMI(double? height, String heightUnit, double? weight, String weightUnit) {
    if (height == null || weight == null) return null;
    
    // Convert to metric units for calculation
    final heightInMeters = heightUnit == 'cm' ? height / 100 : height * 0.3048;
    final weightInKg = weightUnit == 'kg' ? weight : weight / 2.20462;
    
    return weightInKg / (heightInMeters * heightInMeters);
  }
  
  /// Get BMI category
  String getBMICategory(double? bmi) {
    if (bmi == null) return 'Unknown';
    
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

class ProfileSectionStatus {
  final bool isComplete;
  final List<String> completedFields;
  final int totalFields;
  
  ProfileSectionStatus({
    required this.isComplete,
    required this.completedFields,
    required this.totalFields,
  });
  
  double get completionPercentage => totalFields > 0 ? completedFields.length / totalFields : 0.0;
}

// Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService.instance;
});