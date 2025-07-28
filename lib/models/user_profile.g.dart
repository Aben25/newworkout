// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      email: fields[1] as String?,
      displayName: fields[2] as String?,
      createdAt: fields[3] as DateTime?,
      updatedAt: fields[4] as DateTime?,
      age: fields[5] as int?,
      gender: fields[6] as String?,
      height: fields[7] as double?,
      heightUnit: fields[8] as String,
      weight: fields[9] as double?,
      weightUnit: fields[10] as String,
      primaryGoal: (fields[11] as List?)?.cast<String>(),
      fitnessGoals: fields[12] as String?,
      fitnessGoal: fields[13] as String?,
      fitnessGoalsArray: (fields[14] as List?)?.cast<String>(),
      fitnessGoalsOrder: (fields[15] as List?)?.cast<String>(),
      fitnessGoalPrimary: fields[16] as String?,
      cardioLevel: fields[17] as String?,
      weightliftingLevel: fields[18] as String?,
      cardioLevelDescription: fields[19] as String?,
      weightliftingLevelDescription: fields[20] as String?,
      cardioFitnessLevel: fields[21] as int?,
      weightliftingFitnessLevel: fields[22] as int?,
      fitnessLevel: fields[23] as int?,
      fitnessExperience: fields[24] as String?,
      trainingExperienceLevel: fields[25] as String?,
      equipment: (fields[26] as List?)?.cast<String>(),
      workoutEnvironment: (fields[27] as List?)?.cast<String>(),
      workoutDays: (fields[28] as List?)?.cast<String>(),
      workoutDuration: fields[29] as String?,
      workoutFrequency: fields[30] as String?,
      workoutFrequencyDays: fields[31] as int?,
      workoutDurationPreference: fields[32] as String?,
      preferredWorkoutDaysCount: fields[33] as int?,
      preferredWorkoutDuration: fields[34] as String?,
      workoutDurationInt: fields[35] as int?,
      workoutFrequencyInt: fields[36] as int?,
      scheduleFlexibility: fields[37] as String?,
      healthConditions: (fields[38] as List?)?.cast<String>(),
      dietaryRestrictions: (fields[39] as List?)?.cast<String>(),
      physicalLimitations: (fields[40] as List?)?.cast<String>(),
      exercisesToAvoid: (fields[41] as List?)?.cast<String>(),
      excludedExercises: (fields[42] as List?)?.cast<String>(),
      additionalHealthInfo: fields[43] as String?,
      additionalNotes: fields[44] as String?,
      sportActivity: fields[45] as String?,
      specificSportActivity: fields[46] as String?,
      sportOfChoice: fields[47] as String?,
      exercisePreferences: (fields[48] as List?)?.cast<String>(),
      dietPreferences: (fields[49] as List?)?.cast<String>(),
      takingSupplements: fields[50] as bool?,
      supplements: (fields[51] as List?)?.cast<String>(),
      mealsPerDay: fields[52] as int?,
      caloricGoal: fields[53] as int?,
      sleepQuality: fields[54] as String?,
      hasCompletedPreferences: fields[55] as bool,
      onboardingCompleted: fields[56] as bool,
      fitnessAssessmentCompleted: fields[57] as bool,
      fitnessGuide: fields[58] as String?,
      metadata: (fields[59] as Map?)?.cast<String, dynamic>(),
      profilePhotoUrl: fields[60] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(61)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.age)
      ..writeByte(6)
      ..write(obj.gender)
      ..writeByte(7)
      ..write(obj.height)
      ..writeByte(8)
      ..write(obj.heightUnit)
      ..writeByte(9)
      ..write(obj.weight)
      ..writeByte(10)
      ..write(obj.weightUnit)
      ..writeByte(11)
      ..write(obj.primaryGoal)
      ..writeByte(12)
      ..write(obj.fitnessGoals)
      ..writeByte(13)
      ..write(obj.fitnessGoal)
      ..writeByte(14)
      ..write(obj.fitnessGoalsArray)
      ..writeByte(15)
      ..write(obj.fitnessGoalsOrder)
      ..writeByte(16)
      ..write(obj.fitnessGoalPrimary)
      ..writeByte(17)
      ..write(obj.cardioLevel)
      ..writeByte(18)
      ..write(obj.weightliftingLevel)
      ..writeByte(19)
      ..write(obj.cardioLevelDescription)
      ..writeByte(20)
      ..write(obj.weightliftingLevelDescription)
      ..writeByte(21)
      ..write(obj.cardioFitnessLevel)
      ..writeByte(22)
      ..write(obj.weightliftingFitnessLevel)
      ..writeByte(23)
      ..write(obj.fitnessLevel)
      ..writeByte(24)
      ..write(obj.fitnessExperience)
      ..writeByte(25)
      ..write(obj.trainingExperienceLevel)
      ..writeByte(26)
      ..write(obj.equipment)
      ..writeByte(27)
      ..write(obj.workoutEnvironment)
      ..writeByte(28)
      ..write(obj.workoutDays)
      ..writeByte(29)
      ..write(obj.workoutDuration)
      ..writeByte(30)
      ..write(obj.workoutFrequency)
      ..writeByte(31)
      ..write(obj.workoutFrequencyDays)
      ..writeByte(32)
      ..write(obj.workoutDurationPreference)
      ..writeByte(33)
      ..write(obj.preferredWorkoutDaysCount)
      ..writeByte(34)
      ..write(obj.preferredWorkoutDuration)
      ..writeByte(35)
      ..write(obj.workoutDurationInt)
      ..writeByte(36)
      ..write(obj.workoutFrequencyInt)
      ..writeByte(37)
      ..write(obj.scheduleFlexibility)
      ..writeByte(38)
      ..write(obj.healthConditions)
      ..writeByte(39)
      ..write(obj.dietaryRestrictions)
      ..writeByte(40)
      ..write(obj.physicalLimitations)
      ..writeByte(41)
      ..write(obj.exercisesToAvoid)
      ..writeByte(42)
      ..write(obj.excludedExercises)
      ..writeByte(43)
      ..write(obj.additionalHealthInfo)
      ..writeByte(44)
      ..write(obj.additionalNotes)
      ..writeByte(45)
      ..write(obj.sportActivity)
      ..writeByte(46)
      ..write(obj.specificSportActivity)
      ..writeByte(47)
      ..write(obj.sportOfChoice)
      ..writeByte(48)
      ..write(obj.exercisePreferences)
      ..writeByte(49)
      ..write(obj.dietPreferences)
      ..writeByte(50)
      ..write(obj.takingSupplements)
      ..writeByte(51)
      ..write(obj.supplements)
      ..writeByte(52)
      ..write(obj.mealsPerDay)
      ..writeByte(53)
      ..write(obj.caloricGoal)
      ..writeByte(54)
      ..write(obj.sleepQuality)
      ..writeByte(55)
      ..write(obj.hasCompletedPreferences)
      ..writeByte(56)
      ..write(obj.onboardingCompleted)
      ..writeByte(57)
      ..write(obj.fitnessAssessmentCompleted)
      ..writeByte(58)
      ..write(obj.fitnessGuide)
      ..writeByte(59)
      ..write(obj.metadata)
      ..writeByte(60)
      ..write(obj.profilePhotoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      heightUnit: json['height_unit'] as String? ?? 'cm',
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weight_unit'] as String? ?? 'kg',
      primaryGoal: (json['primarygoal'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      fitnessGoals: json['fitnessgoals'] as String?,
      fitnessGoal: json['fitness_goal'] as String?,
      fitnessGoalsArray: (json['fitness_goals_array'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      fitnessGoalsOrder: (json['fitness_goals_order'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      fitnessGoalPrimary: json['fitness_goal_primary'] as String?,
      cardioLevel: json['cardiolevel'] as String?,
      weightliftingLevel: json['weightliftinglevel'] as String?,
      cardioLevelDescription: json['cardio_level_description'] as String?,
      weightliftingLevelDescription:
          json['weightlifting_level_description'] as String?,
      cardioFitnessLevel: (json['cardio_fitness_level'] as num?)?.toInt(),
      weightliftingFitnessLevel:
          (json['weightlifting_fitness_level'] as num?)?.toInt(),
      fitnessLevel: (json['fitness_level'] as num?)?.toInt(),
      fitnessExperience: json['fitness_experience'] as String?,
      trainingExperienceLevel: json['training_experience_level'] as String?,
      equipment: (json['equipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      workoutEnvironment: (json['workout_environment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      workoutDays: (json['workoutdays'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      workoutDuration: json['workoutduration'] as String?,
      workoutFrequency: json['workoutfrequency'] as String?,
      workoutFrequencyDays: (json['workout_frequency_days'] as num?)?.toInt(),
      workoutDurationPreference: json['workout_duration_preference'] as String?,
      preferredWorkoutDaysCount:
          (json['preferred_workout_days_count'] as num?)?.toInt(),
      preferredWorkoutDuration: json['preferred_workout_duration'] as String?,
      workoutDurationInt: (json['workout_duration'] as num?)?.toInt(),
      workoutFrequencyInt: (json['workout_frequency'] as num?)?.toInt(),
      scheduleFlexibility: json['schedule_flexibility'] as String?,
      healthConditions: (json['health_conditions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      dietaryRestrictions: (json['dietary_restrictions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      physicalLimitations: (json['physical_limitations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      exercisesToAvoid: (json['exercises_to_avoid'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      excludedExercises: (json['excluded_exercises'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      additionalHealthInfo: json['additional_health_info'] as String?,
      additionalNotes: json['additional_notes'] as String?,
      sportActivity: json['sport_activity'] as String?,
      specificSportActivity: json['specific_sport_activity'] as String?,
      sportOfChoice: json['sport_of_choice'] as String?,
      exercisePreferences: (json['exercise_preferences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      dietPreferences: (json['diet_preferences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      takingSupplements: json['taking_supplements'] as bool?,
      supplements: (json['supplements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mealsPerDay: (json['meals_per_day'] as num?)?.toInt(),
      caloricGoal: (json['caloric_goal'] as num?)?.toInt(),
      sleepQuality: json['sleep_quality'] as String?,
      hasCompletedPreferences:
          json['has_completed_preferences'] as bool? ?? false,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      fitnessAssessmentCompleted:
          json['fitness_assessment_completed'] as bool? ?? false,
      fitnessGuide: json['fitness_guide'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'age': instance.age,
      'gender': instance.gender,
      'height': instance.height,
      'height_unit': instance.heightUnit,
      'weight': instance.weight,
      'weight_unit': instance.weightUnit,
      'primarygoal': instance.primaryGoal,
      'fitnessgoals': instance.fitnessGoals,
      'fitness_goal': instance.fitnessGoal,
      'fitness_goals_array': instance.fitnessGoalsArray,
      'fitness_goals_order': instance.fitnessGoalsOrder,
      'fitness_goal_primary': instance.fitnessGoalPrimary,
      'cardiolevel': instance.cardioLevel,
      'weightliftinglevel': instance.weightliftingLevel,
      'cardio_level_description': instance.cardioLevelDescription,
      'weightlifting_level_description': instance.weightliftingLevelDescription,
      'cardio_fitness_level': instance.cardioFitnessLevel,
      'weightlifting_fitness_level': instance.weightliftingFitnessLevel,
      'fitness_level': instance.fitnessLevel,
      'fitness_experience': instance.fitnessExperience,
      'training_experience_level': instance.trainingExperienceLevel,
      'equipment': instance.equipment,
      'workout_environment': instance.workoutEnvironment,
      'workoutdays': instance.workoutDays,
      'workoutduration': instance.workoutDuration,
      'workoutfrequency': instance.workoutFrequency,
      'workout_frequency_days': instance.workoutFrequencyDays,
      'workout_duration_preference': instance.workoutDurationPreference,
      'preferred_workout_days_count': instance.preferredWorkoutDaysCount,
      'preferred_workout_duration': instance.preferredWorkoutDuration,
      'workout_duration': instance.workoutDurationInt,
      'workout_frequency': instance.workoutFrequencyInt,
      'schedule_flexibility': instance.scheduleFlexibility,
      'health_conditions': instance.healthConditions,
      'dietary_restrictions': instance.dietaryRestrictions,
      'physical_limitations': instance.physicalLimitations,
      'exercises_to_avoid': instance.exercisesToAvoid,
      'excluded_exercises': instance.excludedExercises,
      'additional_health_info': instance.additionalHealthInfo,
      'additional_notes': instance.additionalNotes,
      'sport_activity': instance.sportActivity,
      'specific_sport_activity': instance.specificSportActivity,
      'sport_of_choice': instance.sportOfChoice,
      'exercise_preferences': instance.exercisePreferences,
      'diet_preferences': instance.dietPreferences,
      'taking_supplements': instance.takingSupplements,
      'supplements': instance.supplements,
      'meals_per_day': instance.mealsPerDay,
      'caloric_goal': instance.caloricGoal,
      'sleep_quality': instance.sleepQuality,
      'has_completed_preferences': instance.hasCompletedPreferences,
      'onboarding_completed': instance.onboardingCompleted,
      'fitness_assessment_completed': instance.fitnessAssessmentCompleted,
      'fitness_guide': instance.fitnessGuide,
      'metadata': instance.metadata,
      'profile_photo_url': instance.profilePhotoUrl,
    };
