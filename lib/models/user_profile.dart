import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  // Core Identity
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? email;
  @HiveField(2)
  @JsonKey(name: 'display_name')
  final String? displayName;
  @HiveField(3)
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @HiveField(4)
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Personal Information
  @HiveField(5)
  final int? age;
  @HiveField(6)
  final String? gender;
  @HiveField(7)
  final double? height;
  @HiveField(8)
  @JsonKey(name: 'height_unit')
  final String heightUnit;
  @HiveField(9)
  final double? weight;
  @HiveField(10)
  @JsonKey(name: 'weight_unit')
  final String weightUnit;

  // Fitness Goals and Preferences
  @HiveField(11)
  @JsonKey(name: 'primarygoal')
  final List<String>? primaryGoal;
  @HiveField(12)
  @JsonKey(name: 'fitnessgoals')
  final String? fitnessGoals;
  @HiveField(13)
  @JsonKey(name: 'fitness_goal')
  final String? fitnessGoal;
  @HiveField(14)
  @JsonKey(name: 'fitness_goals_array')
  final List<String>? fitnessGoalsArray;
  @HiveField(15)
  @JsonKey(name: 'fitness_goals_order')
  final List<String>? fitnessGoalsOrder;
  @HiveField(16)
  @JsonKey(name: 'fitness_goal_primary')
  final String? fitnessGoalPrimary;

  // Fitness Levels
  @HiveField(17)
  @JsonKey(name: 'cardiolevel')
  final String? cardioLevel;
  @HiveField(18)
  @JsonKey(name: 'weightliftinglevel')
  final String? weightliftingLevel;
  @HiveField(19)
  @JsonKey(name: 'cardio_level_description')
  final String? cardioLevelDescription;
  @HiveField(20)
  @JsonKey(name: 'weightlifting_level_description')
  final String? weightliftingLevelDescription;
  @HiveField(21)
  @JsonKey(name: 'cardio_fitness_level')
  final int? cardioFitnessLevel;
  @HiveField(22)
  @JsonKey(name: 'weightlifting_fitness_level')
  final int? weightliftingFitnessLevel;
  @HiveField(23)
  @JsonKey(name: 'fitness_level')
  final int? fitnessLevel;
  @HiveField(24)
  @JsonKey(name: 'fitness_experience')
  final String? fitnessExperience;
  @HiveField(25)
  @JsonKey(name: 'training_experience_level')
  final String? trainingExperienceLevel;

  // Equipment and Environment
  @HiveField(26)
  final List<String>? equipment;
  @HiveField(27)
  @JsonKey(name: 'workout_environment')
  final List<String>? workoutEnvironment;

  // Workout Preferences
  @HiveField(28)
  @JsonKey(name: 'workoutdays')
  final List<String>? workoutDays;
  @HiveField(29)
  @JsonKey(name: 'workoutduration')
  final String? workoutDuration;
  @HiveField(30)
  @JsonKey(name: 'workoutfrequency')
  final String? workoutFrequency;
  @HiveField(31)
  @JsonKey(name: 'workout_frequency_days')
  final int? workoutFrequencyDays;
  @HiveField(32)
  @JsonKey(name: 'workout_duration_preference')
  final String? workoutDurationPreference;
  @HiveField(33)
  @JsonKey(name: 'preferred_workout_days_count')
  final int? preferredWorkoutDaysCount;
  @HiveField(34)
  @JsonKey(name: 'preferred_workout_duration')
  final String? preferredWorkoutDuration;
  @HiveField(35)
  @JsonKey(name: 'workout_duration')
  final int? workoutDurationInt;
  @HiveField(36)
  @JsonKey(name: 'workout_frequency')
  final int? workoutFrequencyInt;
  @HiveField(37)
  @JsonKey(name: 'schedule_flexibility')
  final String? scheduleFlexibility;

  // Health and Restrictions
  @HiveField(38)
  @JsonKey(name: 'health_conditions')
  final List<String>? healthConditions;
  @HiveField(39)
  @JsonKey(name: 'dietary_restrictions')
  final List<String>? dietaryRestrictions;
  @HiveField(40)
  @JsonKey(name: 'physical_limitations')
  final List<String>? physicalLimitations;
  @HiveField(41)
  @JsonKey(name: 'exercises_to_avoid')
  final List<String>? exercisesToAvoid;
  @HiveField(42)
  @JsonKey(name: 'excluded_exercises')
  final List<String>? excludedExercises;
  @HiveField(43)
  @JsonKey(name: 'additional_health_info')
  final String? additionalHealthInfo;
  @HiveField(44)
  @JsonKey(name: 'additional_notes')
  final String? additionalNotes;

  // Sports and Activities
  @HiveField(45)
  @JsonKey(name: 'sport_activity')
  final String? sportActivity;
  @HiveField(46)
  @JsonKey(name: 'specific_sport_activity')
  final String? specificSportActivity;
  @HiveField(47)
  @JsonKey(name: 'sport_of_choice')
  final String? sportOfChoice;
  @HiveField(48)
  @JsonKey(name: 'exercise_preferences')
  final List<String>? exercisePreferences;

  // Nutrition
  @HiveField(49)
  @JsonKey(name: 'diet_preferences')
  final List<String>? dietPreferences;
  @HiveField(50)
  @JsonKey(name: 'taking_supplements')
  final bool? takingSupplements;
  @HiveField(51)
  final List<String>? supplements;
  @HiveField(52)
  @JsonKey(name: 'meals_per_day')
  final int? mealsPerDay;
  @HiveField(53)
  @JsonKey(name: 'caloric_goal')
  final int? caloricGoal;
  @HiveField(54)
  @JsonKey(name: 'sleep_quality')
  final String? sleepQuality;

  // Completion Flags
  @HiveField(55)
  @JsonKey(name: 'has_completed_preferences')
  final bool hasCompletedPreferences;
  @HiveField(56)
  @JsonKey(name: 'onboarding_completed')
  final bool onboardingCompleted;
  @HiveField(57)
  @JsonKey(name: 'fitness_assessment_completed')
  final bool fitnessAssessmentCompleted;

  // AI and Metadata
  @HiveField(58)
  @JsonKey(name: 'fitness_guide')
  final String? fitnessGuide;
  @HiveField(59)
  final Map<String, dynamic>? metadata;
  
  // Profile Photo
  @HiveField(60)
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;

  UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.createdAt,
    this.updatedAt,
    this.age,
    this.gender,
    this.height,
    this.heightUnit = 'cm',
    this.weight,
    this.weightUnit = 'kg',
    this.primaryGoal,
    this.fitnessGoals,
    this.fitnessGoal,
    this.fitnessGoalsArray,
    this.fitnessGoalsOrder,
    this.fitnessGoalPrimary,
    this.cardioLevel,
    this.weightliftingLevel,
    this.cardioLevelDescription,
    this.weightliftingLevelDescription,
    this.cardioFitnessLevel,
    this.weightliftingFitnessLevel,
    this.fitnessLevel,
    this.fitnessExperience,
    this.trainingExperienceLevel,
    this.equipment,
    this.workoutEnvironment,
    this.workoutDays,
    this.workoutDuration,
    this.workoutFrequency,
    this.workoutFrequencyDays,
    this.workoutDurationPreference,
    this.preferredWorkoutDaysCount,
    this.preferredWorkoutDuration,
    this.workoutDurationInt,
    this.workoutFrequencyInt,
    this.scheduleFlexibility,
    this.healthConditions,
    this.dietaryRestrictions,
    this.physicalLimitations,
    this.exercisesToAvoid,
    this.excludedExercises,
    this.additionalHealthInfo,
    this.additionalNotes,
    this.sportActivity,
    this.specificSportActivity,
    this.sportOfChoice,
    this.exercisePreferences,
    this.dietPreferences,
    this.takingSupplements,
    this.supplements,
    this.mealsPerDay,
    this.caloricGoal,
    this.sleepQuality,
    this.hasCompletedPreferences = false,
    this.onboardingCompleted = false,
    this.fitnessAssessmentCompleted = false,
    this.fitnessGuide,
    this.metadata,
    this.profilePhotoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? age,
    String? gender,
    double? height,
    String? heightUnit,
    double? weight,
    String? weightUnit,
    List<String>? primaryGoal,
    String? fitnessGoals,
    String? fitnessGoal,
    List<String>? fitnessGoalsArray,
    List<String>? fitnessGoalsOrder,
    String? fitnessGoalPrimary,
    String? cardioLevel,
    String? weightliftingLevel,
    String? cardioLevelDescription,
    String? weightliftingLevelDescription,
    int? cardioFitnessLevel,
    int? weightliftingFitnessLevel,
    int? fitnessLevel,
    String? fitnessExperience,
    String? trainingExperienceLevel,
    List<String>? equipment,
    List<String>? workoutEnvironment,
    List<String>? workoutDays,
    String? workoutDuration,
    String? workoutFrequency,
    int? workoutFrequencyDays,
    String? workoutDurationPreference,
    int? preferredWorkoutDaysCount,
    String? preferredWorkoutDuration,
    int? workoutDurationInt,
    int? workoutFrequencyInt,
    String? scheduleFlexibility,
    List<String>? healthConditions,
    List<String>? dietaryRestrictions,
    List<String>? physicalLimitations,
    List<String>? exercisesToAvoid,
    List<String>? excludedExercises,
    String? additionalHealthInfo,
    String? additionalNotes,
    String? sportActivity,
    String? specificSportActivity,
    String? sportOfChoice,
    List<String>? exercisePreferences,
    List<String>? dietPreferences,
    bool? takingSupplements,
    List<String>? supplements,
    int? mealsPerDay,
    int? caloricGoal,
    String? sleepQuality,
    bool? hasCompletedPreferences,
    bool? onboardingCompleted,
    bool? fitnessAssessmentCompleted,
    String? fitnessGuide,
    Map<String, dynamic>? metadata,
    String? profilePhotoUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      heightUnit: heightUnit ?? this.heightUnit,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      fitnessGoalsArray: fitnessGoalsArray ?? this.fitnessGoalsArray,
      fitnessGoalsOrder: fitnessGoalsOrder ?? this.fitnessGoalsOrder,
      fitnessGoalPrimary: fitnessGoalPrimary ?? this.fitnessGoalPrimary,
      cardioLevel: cardioLevel ?? this.cardioLevel,
      weightliftingLevel: weightliftingLevel ?? this.weightliftingLevel,
      cardioLevelDescription: cardioLevelDescription ?? this.cardioLevelDescription,
      weightliftingLevelDescription: weightliftingLevelDescription ?? this.weightliftingLevelDescription,
      cardioFitnessLevel: cardioFitnessLevel ?? this.cardioFitnessLevel,
      weightliftingFitnessLevel: weightliftingFitnessLevel ?? this.weightliftingFitnessLevel,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      fitnessExperience: fitnessExperience ?? this.fitnessExperience,
      trainingExperienceLevel: trainingExperienceLevel ?? this.trainingExperienceLevel,
      equipment: equipment ?? this.equipment,
      workoutEnvironment: workoutEnvironment ?? this.workoutEnvironment,
      workoutDays: workoutDays ?? this.workoutDays,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      workoutFrequency: workoutFrequency ?? this.workoutFrequency,
      workoutFrequencyDays: workoutFrequencyDays ?? this.workoutFrequencyDays,
      workoutDurationPreference: workoutDurationPreference ?? this.workoutDurationPreference,
      preferredWorkoutDaysCount: preferredWorkoutDaysCount ?? this.preferredWorkoutDaysCount,
      preferredWorkoutDuration: preferredWorkoutDuration ?? this.preferredWorkoutDuration,
      workoutDurationInt: workoutDurationInt ?? this.workoutDurationInt,
      workoutFrequencyInt: workoutFrequencyInt ?? this.workoutFrequencyInt,
      scheduleFlexibility: scheduleFlexibility ?? this.scheduleFlexibility,
      healthConditions: healthConditions ?? this.healthConditions,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      physicalLimitations: physicalLimitations ?? this.physicalLimitations,
      exercisesToAvoid: exercisesToAvoid ?? this.exercisesToAvoid,
      excludedExercises: excludedExercises ?? this.excludedExercises,
      additionalHealthInfo: additionalHealthInfo ?? this.additionalHealthInfo,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      sportActivity: sportActivity ?? this.sportActivity,
      specificSportActivity: specificSportActivity ?? this.specificSportActivity,
      sportOfChoice: sportOfChoice ?? this.sportOfChoice,
      exercisePreferences: exercisePreferences ?? this.exercisePreferences,
      dietPreferences: dietPreferences ?? this.dietPreferences,
      takingSupplements: takingSupplements ?? this.takingSupplements,
      supplements: supplements ?? this.supplements,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      caloricGoal: caloricGoal ?? this.caloricGoal,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      hasCompletedPreferences: hasCompletedPreferences ?? this.hasCompletedPreferences,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      fitnessAssessmentCompleted: fitnessAssessmentCompleted ?? this.fitnessAssessmentCompleted,
      fitnessGuide: fitnessGuide ?? this.fitnessGuide,
      metadata: metadata ?? this.metadata,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.age == age &&
        other.gender == gender &&
        other.height == height &&
        other.weight == weight &&
        _listEquals(other.fitnessGoalsArray, fitnessGoalsArray) &&
        other.fitnessLevel == fitnessLevel &&
        _listEquals(other.equipment, equipment) &&
        _listEquals(other.workoutDays, workoutDays) &&
        other.onboardingCompleted == onboardingCompleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      displayName,
      age,
      gender,
      height,
      weight,
      Object.hashAll(fitnessGoalsArray ?? []),
      fitnessLevel,
      Object.hashAll(equipment ?? []),
      Object.hashAll(workoutDays ?? []),
      onboardingCompleted,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  // Validation methods
  bool get isBasicInfoComplete {
    return age != null && 
           gender != null && 
           height != null && 
           weight != null;
  }

  bool get isFitnessGoalsComplete {
    return fitnessGoalsArray != null && 
           fitnessGoalsArray!.isNotEmpty;
  }

  bool get isEquipmentComplete {
    return equipment != null && 
           equipment!.isNotEmpty;
  }

  bool get isWorkoutPreferencesComplete {
    return workoutDays != null && 
           workoutDays!.isNotEmpty &&
           workoutDurationInt != null &&
           workoutFrequencyInt != null;
  }

  double get profileCompletionPercentage {
    int completedSections = 0;
    int totalSections = 4;

    if (isBasicInfoComplete) completedSections++;
    if (isFitnessGoalsComplete) completedSections++;
    if (isEquipmentComplete) completedSections++;
    if (isWorkoutPreferencesComplete) completedSections++;

    return completedSections / totalSections;
  }
}