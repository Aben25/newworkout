import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../models/onboarding_state.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// Onboarding state notifier
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._ref) : super(OnboardingState()) {
    _loadOnboardingState();
    
    // Listen for profile changes and refresh onboarding data
    _ref.listen<UserProfile?>(userProfileProvider, (previous, next) {
      if (next != null && (previous == null || previous != next)) {
        _logger.d('Profile data changed, refreshing onboarding data');
        _refreshOnboardingFromProfile(next);
      }
    });
  }

  final Ref _ref;
  static const String _onboardingBoxName = 'onboarding_box';
  static const String _onboardingKey = 'onboarding_state';
  final Logger _logger = Logger();

  // Load onboarding state from local storage and merge with existing profile data
  Future<void> _loadOnboardingState() async {
    try {
      final box = await Hive.openBox<OnboardingState>(_onboardingBoxName);
      final savedState = box.get(_onboardingKey);
      
      // Load existing profile data from Supabase if user is authenticated
      final userProfile = _ref.read(userProfileProvider);
      Map<String, dynamic> profileData = {};
      
      if (userProfile != null) {
        profileData = _extractProfileDataForOnboarding(userProfile);
        _logger.i('Loaded existing profile data for onboarding');
      }
      
      if (savedState != null && !savedState.isCompleted) {
        // Merge saved onboarding state with existing profile data
        final mergedStepData = <String, dynamic>{};
        mergedStepData.addAll(profileData); // Profile data as base
        mergedStepData.addAll(savedState.stepData); // Onboarding data takes precedence
        
        state = savedState.copyWith(stepData: mergedStepData);
        _logger.i('Loaded onboarding state: step ${savedState.currentStep} with profile data');
      } else if (profileData.isNotEmpty) {
        // Create new onboarding state with existing profile data
        state = OnboardingState(stepData: profileData);
        _logger.i('Created onboarding state from existing profile data');
      }
    } catch (e) {
      // If loading fails, keep default state
      _logger.e('Error loading onboarding state: $e');
    }
  }

  // Extract relevant profile data for onboarding
  Map<String, dynamic> _extractProfileDataForOnboarding(UserProfile profile) {
    final data = <String, dynamic>{};
    
    // Personal Information
    if (profile.displayName?.isNotEmpty == true) {
      data['displayName'] = profile.displayName;
    }
    if (profile.age != null) {
      data['age'] = profile.age;
    }
    if (profile.gender?.isNotEmpty == true) {
      data['gender'] = profile.gender;
    }
    if (profile.height != null) {
      data['height'] = profile.height;
    }
    if (profile.weight != null) {
      data['weight'] = profile.weight;
    }
    if (profile.heightUnit?.isNotEmpty == true) {
      data['heightUnit'] = profile.heightUnit;
    }
    if (profile.weightUnit?.isNotEmpty == true) {
      data['weightUnit'] = profile.weightUnit;
    }
    
    // Fitness Goals
    if (profile.fitnessGoalsArray?.isNotEmpty == true) {
      data['fitnessGoals'] = profile.fitnessGoalsArray;
    }
    if (profile.fitnessGoalsOrder?.isNotEmpty == true) {
      data['fitnessGoalsOrder'] = profile.fitnessGoalsOrder;
    }
    
    // Fitness Levels
    if (profile.cardioFitnessLevel != null) {
      data['cardioFitnessLevel'] = profile.cardioFitnessLevel;
    }
    if (profile.weightliftingFitnessLevel != null) {
      data['weightliftingFitnessLevel'] = profile.weightliftingFitnessLevel;
    }
    if (profile.fitnessExperience?.isNotEmpty == true) {
      data['fitnessExperience'] = profile.fitnessExperience;
    }
    
    // Equipment and Environment
    if (profile.equipment?.isNotEmpty == true) {
      data['equipment'] = profile.equipment;
    }
    if (profile.workoutEnvironment?.isNotEmpty == true) {
      data['workoutEnvironment'] = profile.workoutEnvironment;
    }
    
    // Workout Preferences
    if (profile.workoutDays?.isNotEmpty == true) {
      data['workoutDays'] = profile.workoutDays;
    }
    if (profile.workoutDurationPreference?.isNotEmpty == true) {
      data['workoutDuration'] = profile.workoutDurationPreference;
    }
    if (profile.workoutFrequency?.isNotEmpty == true) {
      data['workoutFrequency'] = profile.workoutFrequency;
    }
    if (profile.scheduleFlexibility?.isNotEmpty == true) {
      data['scheduleFlexibility'] = profile.scheduleFlexibility;
    }
    
    return data;
  }

  // Refresh onboarding data when profile changes
  void _refreshOnboardingFromProfile(UserProfile profile) {
    try {
      final profileData = _extractProfileDataForOnboarding(profile);
      if (profileData.isNotEmpty) {
        final mergedStepData = <String, dynamic>{};
        mergedStepData.addAll(profileData); // Profile data as base
        mergedStepData.addAll(state.stepData); // Current onboarding data takes precedence
        
        state = state.copyWith(stepData: mergedStepData);
        _saveOnboardingState();
        _logger.i('Refreshed onboarding data from profile changes');
      }
    } catch (e) {
      _logger.e('Error refreshing onboarding from profile: $e');
    }
  }

  // Save onboarding state to local storage
  Future<void> _saveOnboardingState() async {
    try {
      final box = await Hive.openBox<OnboardingState>(_onboardingBoxName);
      await box.put(_onboardingKey, state);
    } catch (e) {
      _logger.e('Error saving onboarding state: $e');
    }
  }

  // Navigate to next step
  Future<void> nextStep() async {
    if (state.canGoNext) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        lastUpdated: DateTime.now(),
      );
      await _saveOnboardingState();
    }
  }

  // Navigate to previous step
  Future<void> previousStep() async {
    if (state.canGoBack) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        lastUpdated: DateTime.now(),
      );
      await _saveOnboardingState();
    }
  }

  // Jump to specific step
  Future<void> goToStep(int step) async {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(
        currentStep: step,
        lastUpdated: DateTime.now(),
      );
      await _saveOnboardingState();
    }
  }

  // Update step data
  Future<void> updateStepData(String key, dynamic value) async {
    final updatedStepData = Map<String, dynamic>.from(state.stepData);
    updatedStepData[key] = value;
    
    state = state.copyWith(
      stepData: updatedStepData,
      lastUpdated: DateTime.now(),
    );
    await _saveOnboardingState();
  }

  // Update multiple step data at once
  Future<void> updateMultipleStepData(Map<String, dynamic> data) async {
    final updatedStepData = Map<String, dynamic>.from(state.stepData);
    updatedStepData.addAll(data);
    
    state = state.copyWith(
      stepData: updatedStepData,
      lastUpdated: DateTime.now(),
    );
    await _saveOnboardingState();
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    state = state.copyWith(
      isCompleted: true,
      currentStep: state.totalSteps,
      lastUpdated: DateTime.now(),
    );
    await _saveOnboardingState();
  }

  // Complete onboarding with data persistence to Supabase
  Future<void> completeOnboardingWithPersistence(String userId) async {
    try {
      // Import required services
      final supabaseService = SupabaseService.instance;
      
      // Prepare profile data from onboarding steps
      final profileData = _buildProfileDataFromSteps();
      
      // Add onboarding completion flag
      profileData['onboarding_completed'] = true;
      profileData['fitness_assessment_completed'] = true;
      profileData['has_completed_preferences'] = true;
      
      // Update profile in Supabase
      await supabaseService.updateUserProfile(userId, profileData);
      
      // Update local onboarding state
      await completeOnboarding();
      
      _logger.i('Onboarding completed and data persisted successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to complete onboarding with persistence',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Build profile data from onboarding steps
  Map<String, dynamic> _buildProfileDataFromSteps() {
    final data = <String, dynamic>{};
    final stepData = state.stepData;
    
    // Personal Information
    if (stepData['displayName'] != null) {
      data['display_name'] = stepData['displayName'];
    }
    if (stepData['age'] != null) {
      data['age'] = stepData['age'];
    }
    if (stepData['gender'] != null) {
      data['gender'] = stepData['gender'];
    }
    if (stepData['height'] != null) {
      data['height'] = stepData['height'];
    }
    if (stepData['weight'] != null) {
      data['weight'] = stepData['weight'];
    }
    if (stepData['heightUnit'] != null) {
      data['height_unit'] = stepData['heightUnit'];
    }
    if (stepData['weightUnit'] != null) {
      data['weight_unit'] = stepData['weightUnit'];
    }
    
    // Fitness Goals
    if (stepData['fitnessGoals'] != null) {
      data['fitness_goals_array'] = stepData['fitnessGoals'];
    }
    if (stepData['fitnessGoalsOrder'] != null) {
      data['fitness_goals_order'] = stepData['fitnessGoalsOrder'];
    }
    if (stepData['fitnessGoals'] is List && (stepData['fitnessGoals'] as List).isNotEmpty) {
      data['fitness_goal_primary'] = (stepData['fitnessGoals'] as List).first;
    }
    
    // Fitness Levels
    if (stepData['cardioFitnessLevel'] != null) {
      data['cardio_fitness_level'] = stepData['cardioFitnessLevel'];
    }
    if (stepData['weightliftingFitnessLevel'] != null) {
      data['weightlifting_fitness_level'] = stepData['weightliftingFitnessLevel'];
    }
    if (stepData['fitnessExperience'] != null) {
      data['fitness_experience'] = stepData['fitnessExperience'];
    }
    
    // Equipment and Environment
    if (stepData['equipment'] != null) {
      data['equipment'] = stepData['equipment'];
    }
    if (stepData['workoutEnvironment'] != null) {
      data['workout_environment'] = stepData['workoutEnvironment'];
    }
    
    // Workout Preferences
    if (stepData['workoutDays'] != null) {
      data['workoutdays'] = stepData['workoutDays'];
    }
    if (stepData['workoutDuration'] != null) {
      data['workout_duration_preference'] = stepData['workoutDuration'];
    }
    if (stepData['workoutFrequency'] != null) {
      data['workout_frequency'] = stepData['workoutFrequency'];
    }
    if (stepData['scheduleFlexibility'] != null) {
      data['schedule_flexibility'] = stepData['scheduleFlexibility'];
    }
    
    return data;
  }

  // Reset onboarding (for testing or re-onboarding)
  Future<void> resetOnboarding() async {
    // Load existing profile data when resetting
    final userProfile = _ref.read(userProfileProvider);
    Map<String, dynamic> profileData = {};
    
    if (userProfile != null) {
      profileData = _extractProfileDataForOnboarding(userProfile);
    }
    
    state = OnboardingState(stepData: profileData);
    await _saveOnboardingState();
    _logger.i('Onboarding reset to initial state with profile data');
  }

  // Refresh onboarding data from current profile
  Future<void> refreshFromProfile() async {
    final userProfile = _ref.read(userProfileProvider);
    
    if (userProfile != null) {
      _refreshOnboardingFromProfile(userProfile);
      await _saveOnboardingState(); // Ensure it's saved after manual refresh
      _logger.i('Manually refreshed onboarding data from profile');
    } else {
      _logger.w('No profile available to refresh from');
    }
  }

  // Check if there's resumable onboarding data
  bool get hasResumableData {
    return !state.isCompleted && 
           (state.currentStep > 0 || state.stepData.isNotEmpty);
  }

  // Get resume summary for display
  String get resumeSummary {
    if (!hasResumableData) return '';
    
    final stepName = OnboardingStepExtension.fromIndex(state.currentStep).title;
    final progress = ((state.currentStep / state.totalSteps) * 100).round();
    
    return 'Continue from "$stepName" ($progress% complete)';
  }

  // Skip onboarding
  Future<void> skipOnboarding() async {
    if (state.canSkip) {
      await completeOnboarding();
    }
  }

  // Check if current step data is valid
  bool isCurrentStepValid() {
    final currentStep = OnboardingStepExtension.fromIndex(state.currentStep);
    
    switch (currentStep) {
      case OnboardingStep.welcome:
        return true; // Welcome screen is always valid
      case OnboardingStep.personalInfo:
        return _isPersonalInfoValid();
      case OnboardingStep.fitnessGoals:
        return _isFitnessGoalsValid();
      case OnboardingStep.fitnessLevel:
        return _isFitnessLevelValid();
      case OnboardingStep.equipment:
        // Temporarily always return true for debugging
        return true; // _isEquipmentValid();
      case OnboardingStep.preferences:
        return _isPreferencesValid();
    }
  }

  bool _isPersonalInfoValid() {
    final data = state.stepData;
    return data['displayName'] != null &&
           data['displayName'].toString().trim().isNotEmpty &&
           data['age'] != null &&
           data['gender'] != null &&
           data['height'] != null &&
           data['weight'] != null;
  }

  bool _isFitnessGoalsValid() {
    final goals = state.stepData['fitnessGoals'] as List<String>?;
    return goals != null && goals.isNotEmpty;
  }

  bool _isFitnessLevelValid() {
    final data = state.stepData;
    return data['cardioFitnessLevel'] != null &&
           data['weightliftingFitnessLevel'] != null;
  }

  bool _isEquipmentValid() {
    final equipment = state.stepData['equipment'] as List<String>?;
    return equipment != null && equipment.isNotEmpty;
  }

  bool _isPreferencesValid() {
    final data = state.stepData;
    final workoutDays = data['workoutDays'] as List<String>?;
    // Only require workout days to be selected for now
    // Duration and frequency can be set later
    return workoutDays != null && workoutDays.isNotEmpty;
  }

  // Get current step enum
  OnboardingStep get currentStepEnum => OnboardingStepExtension.fromIndex(state.currentStep);

  // Get step data for current step
  Map<String, dynamic> get currentStepData {
    final currentStep = OnboardingStepExtension.fromIndex(state.currentStep);
    final data = <String, dynamic>{};
    
    switch (currentStep) {
      case OnboardingStep.welcome:
        // No data to collect from welcome screen
        break;
      case OnboardingStep.personalInfo:
        data['displayName'] = state.stepData['displayName'];
        data['age'] = state.stepData['age'];
        data['gender'] = state.stepData['gender'];
        data['height'] = state.stepData['height'];
        data['weight'] = state.stepData['weight'];
        data['heightUnit'] = state.stepData['heightUnit'] ?? 'cm';
        data['weightUnit'] = state.stepData['weightUnit'] ?? 'kg';
        break;
      case OnboardingStep.fitnessGoals:
        data['fitnessGoals'] = state.stepData['fitnessGoals'];
        data['fitnessGoalsOrder'] = state.stepData['fitnessGoalsOrder'];
        break;
      case OnboardingStep.fitnessLevel:
        data['cardioFitnessLevel'] = state.stepData['cardioFitnessLevel'];
        data['weightliftingFitnessLevel'] = state.stepData['weightliftingFitnessLevel'];
        data['fitnessExperience'] = state.stepData['fitnessExperience'];
        break;
      case OnboardingStep.equipment:
        data['equipment'] = state.stepData['equipment'];
        data['workoutEnvironment'] = state.stepData['workoutEnvironment'];
        break;
      case OnboardingStep.preferences:
        data['workoutDays'] = state.stepData['workoutDays'];
        data['workoutDuration'] = state.stepData['workoutDuration'];
        data['workoutFrequency'] = state.stepData['workoutFrequency'];
        data['scheduleFlexibility'] = state.stepData['scheduleFlexibility'];
        break;
    }
    
    return data;
  }
}

// Provider for onboarding state
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});

// Provider for checking if onboarding should be shown
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final onboardingState = ref.watch(onboardingProvider);
  return !onboardingState.isCompleted;
});

// Provider for current step progress
final onboardingProgressProvider = Provider<double>((ref) {
  final onboardingState = ref.watch(onboardingProvider);
  return onboardingState.progress;
});

// Provider for current step validation
final currentStepValidProvider = Provider<bool>((ref) {
  final onboardingNotifier = ref.read(onboardingProvider.notifier);
  return onboardingNotifier.isCurrentStepValid();
});

// Provider to check if user has existing profile data
final hasExistingProfileDataProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  
  if (userProfile == null) return false;
  
  return userProfile.displayName?.isNotEmpty == true ||
         userProfile.age != null ||
         userProfile.gender?.isNotEmpty == true ||
         userProfile.height != null ||
         userProfile.weight != null ||
         userProfile.fitnessGoalsArray?.isNotEmpty == true ||
         userProfile.cardioFitnessLevel != null ||
         userProfile.weightliftingFitnessLevel != null ||
         userProfile.equipment?.isNotEmpty == true ||
         userProfile.workoutDays?.isNotEmpty == true;
});

// Provider to get profile completion percentage
final profileCompletionProvider = Provider<double>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  
  if (userProfile == null) return 0.0;
  
  int completedFields = 0;
  const int totalFields = 10; // Key fields for onboarding
  
  if (userProfile.displayName?.isNotEmpty == true) completedFields++;
  if (userProfile.age != null) completedFields++;
  if (userProfile.gender?.isNotEmpty == true) completedFields++;
  if (userProfile.height != null) completedFields++;
  if (userProfile.weight != null) completedFields++;
  if (userProfile.fitnessGoalsArray?.isNotEmpty == true) completedFields++;
  if (userProfile.cardioFitnessLevel != null) completedFields++;
  if (userProfile.weightliftingFitnessLevel != null) completedFields++;
  if (userProfile.equipment?.isNotEmpty == true) completedFields++;
  if (userProfile.workoutDays?.isNotEmpty == true) completedFields++;
  
  return completedFields / totalFields;
});