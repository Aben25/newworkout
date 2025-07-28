import 'package:logger/logger.dart';
import '../models/models.dart';
import 'exercise_service.dart';
import 'profile_service.dart';
import 'workout_service.dart';

/// Service for generating personalized exercise and workout recommendations
class RecommendationService {
  static RecommendationService? _instance;
  static RecommendationService get instance => _instance ??= RecommendationService._();
  
  RecommendationService._();
  
  final Logger _logger = Logger();
  final ExerciseService _exerciseService = ExerciseService.instance;
  final ProfileService _profileService = ProfileService.instance;
  final WorkoutService _workoutService = WorkoutService.instance;

  /// Generate personalized exercise recommendations
  Future<List<Exercise>> getPersonalizedExerciseRecommendations({
    int limit = 20,
    List<String>? excludeExerciseIds,
    String? focusMuscleGroup,
  }) async {
    try {
      // Get user profile for personalization
      final userProfile = await _profileService.getCurrentUserProfile();
      if (userProfile == null) {
        _logger.w('No user profile found, using default recommendations');
        return await _exerciseService.getExercises(limit: limit);
      }

      // Extract user preferences
      final userEquipment = userProfile.equipment ?? [];
      final excludedExercises = [
        ...?userProfile.excludedExercises,
        ...?userProfile.exercisesToAvoid,
        ...?excludeExerciseIds,
      ];
      
      final fitnessLevel = _determineFitnessLevel(userProfile);
      final preferredMuscleGroups = _getPreferredMuscleGroups(
        userProfile,
        focusMuscleGroup,
      );

      // Get recommendations from exercise service
      final recommendations = await _exerciseService.getRecommendedExercises(
        userEquipment: userEquipment,
        preferredMuscleGroups: preferredMuscleGroups,
        excludedExercises: excludedExercises,
        fitnessLevel: fitnessLevel,
        limit: limit * 2, // Get more to allow for scoring
      );

      // Score and rank recommendations
      final scoredRecommendations = _scoreExercises(
        recommendations,
        userProfile,
        focusMuscleGroup,
      );

      // Sort by score and return top results
      scoredRecommendations.sort((a, b) => b.score.compareTo(a.score));
      
      final finalRecommendations = scoredRecommendations
          .take(limit)
          .map((scored) => scored.exercise)
          .toList();

      _logger.i('Generated ${finalRecommendations.length} personalized exercise recommendations');
      return finalRecommendations;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to generate personalized exercise recommendations',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Fallback to basic recommendations
      return await _exerciseService.getExercises(limit: limit);
    }
  }

  /// Generate workout recommendations based on user goals and preferences
  Future<List<WorkoutRecommendation>> getWorkoutRecommendations({
    int limit = 10,
  }) async {
    try {
      final userProfile = await _profileService.getCurrentUserProfile();
      if (userProfile == null) {
        return [];
      }

      final recommendations = <WorkoutRecommendation>[];

      // Generate different types of workout recommendations
      final fitnessGoals = userProfile.fitnessGoalsArray ?? [];
      final userEquipment = userProfile.equipment ?? [];
      final fitnessLevel = _determineFitnessLevel(userProfile);
      final workoutDuration = userProfile.workoutDurationInt ?? 45;

      for (final goal in fitnessGoals.take(3)) { // Limit to top 3 goals
        final workoutRec = await _generateWorkoutForGoal(
          goal,
          userEquipment,
          fitnessLevel,
          workoutDuration,
        );
        
        if (workoutRec != null) {
          recommendations.add(workoutRec);
        }
      }

      // Add variety workouts if we have fewer than the limit
      if (recommendations.length < limit) {
        final varietyWorkouts = await _generateVarietyWorkouts(
          userEquipment,
          fitnessLevel,
          workoutDuration,
          limit - recommendations.length,
        );
        recommendations.addAll(varietyWorkouts);
      }

      // Sort by relevance score
      recommendations.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      _logger.i('Generated ${recommendations.length} workout recommendations');
      return recommendations.take(limit).toList();
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to generate workout recommendations',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get exercise alternatives for a specific exercise
  Future<List<Exercise>> getExerciseAlternatives(
    String exerciseId, {
    int limit = 5,
  }) async {
    try {
      final originalExercise = await _exerciseService.getExerciseById(exerciseId);
      if (originalExercise == null) {
        return [];
      }

      // Get user profile for equipment filtering
      final userProfile = await _profileService.getCurrentUserProfile();
      final userEquipment = userProfile?.equipment ?? [];

      // Find exercises with similar muscle groups
      final alternatives = await _exerciseService.getExercises(
        muscleGroup: originalExercise.primaryMuscle,
        limit: limit * 3, // Get more to filter and rank
      );

      // Filter out the original exercise and unavailable equipment
      var filteredAlternatives = alternatives
          .where((exercise) => 
              exercise.id != exerciseId &&
              (userEquipment.isEmpty || 
               userEquipment.contains(exercise.equipment) ||
               exercise.equipment == 'bodyweight' ||
               exercise.equipment == 'none'))
          .toList();

      // Score alternatives based on similarity
      final scoredAlternatives = filteredAlternatives
          .map((exercise) => ScoredExercise(
                exercise: exercise,
                score: _calculateSimilarityScore(originalExercise, exercise),
              ))
          .toList();

      // Sort by similarity score and return top results
      scoredAlternatives.sort((a, b) => b.score.compareTo(a.score));
      
      final finalAlternatives = scoredAlternatives
          .take(limit)
          .map((scored) => scored.exercise)
          .toList();

      _logger.i('Found ${finalAlternatives.length} alternatives for exercise: ${originalExercise.name}');
      return finalAlternatives;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get exercise alternatives for: $exerciseId',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get progressive exercise recommendations (easier/harder variations)
  Future<ExerciseProgression> getExerciseProgression(String exerciseId) async {
    try {
      final originalExercise = await _exerciseService.getExerciseById(exerciseId);
      if (originalExercise == null) {
        return ExerciseProgression(
          current: null,
          easier: [],
          harder: [],
        );
      }

      // Get exercises with same muscle groups
      final relatedExercises = await _exerciseService.getExercises(
        muscleGroup: originalExercise.primaryMuscle,
        limit: 50,
      );

      // Categorize by difficulty (simplified logic)
      final easier = <Exercise>[];
      final harder = <Exercise>[];

      for (final exercise in relatedExercises) {
        if (exercise.id == exerciseId) continue;

        final difficultyComparison = _compareDifficulty(originalExercise, exercise);
        
        if (difficultyComparison < 0) {
          easier.add(exercise);
        } else if (difficultyComparison > 0) {
          harder.add(exercise);
        }
      }

      // Limit results
      easier.shuffle();
      harder.shuffle();

      return ExerciseProgression(
        current: originalExercise,
        easier: easier.take(3).toList(),
        harder: harder.take(3).toList(),
      );
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get exercise progression for: $exerciseId',
        error: e,
        stackTrace: stackTrace,
      );
      return ExerciseProgression(
        current: null,
        easier: [],
        harder: [],
      );
    }
  }

  /// Get recommendations based on workout history
  Future<List<Exercise>> getHistoryBasedRecommendations({
    int limit = 15,
  }) async {
    try {
      // Get recent workout history
      final recentWorkouts = await _workoutService.getCompletedWorkouts(limit: 10);
      
      if (recentWorkouts.isEmpty) {
        return await getPersonalizedExerciseRecommendations(limit: limit);
      }

      // Analyze exercise frequency and performance
      final exerciseFrequency = <String, int>{};
      final recentExerciseIds = <String>{};

      for (final workout in recentWorkouts) {
        final workoutExercises = await _workoutService.getWorkoutExercises(workout.id);
        
        for (final workoutExercise in workoutExercises) {
          exerciseFrequency[workoutExercise.exerciseId] = 
              (exerciseFrequency[workoutExercise.exerciseId] ?? 0) + 1;
          
          // Track recent exercises (last 3 workouts)
          if (recentWorkouts.indexOf(workout) < 3) {
            recentExerciseIds.add(workoutExercise.exerciseId);
          }
        }
      }

      // Get underutilized muscle groups
      final allExerciseIds = exerciseFrequency.keys.toList();
      final allExercises = await _exerciseService.getExercisesByIds(allExerciseIds);
      
      final muscleGroupFrequency = <String, int>{};
      for (final exercise in allExercises) {
        for (final muscle in exercise.muscleGroups) {
          muscleGroupFrequency[muscle] = (muscleGroupFrequency[muscle] ?? 0) + 1;
        }
      }

      // Find underutilized muscle groups
      final sortedMuscleGroups = muscleGroupFrequency.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final underutilizedMuscles = sortedMuscleGroups
          .take(3)
          .map((entry) => entry.key)
          .toList();

      // Get recommendations for underutilized muscles
      final recommendations = <Exercise>[];
      
      for (final muscle in underutilizedMuscles) {
        final muscleExercises = await getPersonalizedExerciseRecommendations(
          limit: limit ~/ underutilizedMuscles.length + 2,
          excludeExerciseIds: recentExerciseIds.toList(),
          focusMuscleGroup: muscle,
        );
        recommendations.addAll(muscleExercises);
      }

      // Remove duplicates and limit results
      final uniqueRecommendations = recommendations.toSet().toList();
      uniqueRecommendations.shuffle();

      _logger.i('Generated ${uniqueRecommendations.length} history-based recommendations');
      return uniqueRecommendations.take(limit).toList();
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to generate history-based recommendations',
        error: e,
        stackTrace: stackTrace,
      );
      return await getPersonalizedExerciseRecommendations(limit: limit);
    }
  }

  // Private helper methods

  String _determineFitnessLevel(UserProfile profile) {
    final cardioLevel = profile.cardioFitnessLevel ?? 1;
    final weightliftingLevel = profile.weightliftingFitnessLevel ?? 1;
    final averageLevel = (cardioLevel + weightliftingLevel) / 2;

    if (averageLevel <= 2) return 'beginner';
    if (averageLevel <= 4) return 'intermediate';
    return 'advanced';
  }

  List<String> _getPreferredMuscleGroups(UserProfile profile, String? focusMuscleGroup) {
    final preferredMuscles = <String>[];
    
    if (focusMuscleGroup != null) {
      preferredMuscles.add(focusMuscleGroup);
    }

    // Add muscle groups based on fitness goals
    final goals = profile.fitnessGoalsArray ?? [];
    
    for (final goal in goals) {
      switch (goal.toLowerCase()) {
        case 'build muscle':
        case 'strength':
          preferredMuscles.addAll(['chest', 'back', 'shoulders', 'legs']);
          break;
        case 'lose weight':
        case 'cardio':
          preferredMuscles.addAll(['full body', 'core']);
          break;
        case 'tone':
          preferredMuscles.addAll(['arms', 'core', 'legs']);
          break;
      }
    }

    return preferredMuscles.toSet().toList();
  }

  List<ScoredExercise> _scoreExercises(
    List<Exercise> exercises,
    UserProfile profile,
    String? focusMuscleGroup,
  ) {
    return exercises.map((exercise) {
      double score = 0.0;

      // Equipment availability bonus
      final userEquipment = profile.equipment ?? [];
      if (userEquipment.contains(exercise.equipment) || 
          exercise.equipment == 'bodyweight' || 
          exercise.equipment == 'none') {
        score += 10.0;
      }

      // Muscle group preference bonus
      if (focusMuscleGroup != null && exercise.muscleGroups.contains(focusMuscleGroup)) {
        score += 15.0;
      }

      // Fitness level appropriateness
      final fitnessLevel = _determineFitnessLevel(profile);
      if (_isAppropriateForFitnessLevel(exercise, fitnessLevel)) {
        score += 8.0;
      }

      // Video content bonus (better for learning)
      if (exercise.hasVideo) {
        score += 5.0;
      }

      // Complete exercise information bonus
      if (exercise.isComplete) {
        score += 3.0;
      }

      return ScoredExercise(exercise: exercise, score: score);
    }).toList();
  }

  bool _isAppropriateForFitnessLevel(Exercise exercise, String fitnessLevel) {
    switch (fitnessLevel) {
      case 'beginner':
        return exercise.equipment == 'bodyweight' || 
               exercise.equipment == 'none' ||
               exercise.category?.toLowerCase().contains('basic') == true;
      case 'intermediate':
        return exercise.category?.toLowerCase().contains('advanced') != true;
      case 'advanced':
        return true;
      default:
        return true;
    }
  }

  Future<WorkoutRecommendation?> _generateWorkoutForGoal(
    String goal,
    List<String> userEquipment,
    String fitnessLevel,
    int duration,
  ) async {
    try {
      final exercises = await _getExercisesForGoal(goal, userEquipment, fitnessLevel);
      
      if (exercises.isEmpty) return null;

      // Calculate number of exercises based on duration
      final exerciseCount = _calculateExerciseCount(duration);
      final selectedExercises = exercises.take(exerciseCount).toList();

      return WorkoutRecommendation(
        name: _getWorkoutNameForGoal(goal),
        description: _getWorkoutDescriptionForGoal(goal),
        exercises: selectedExercises,
        estimatedDuration: duration,
        difficulty: fitnessLevel,
        goal: goal,
        relevanceScore: _calculateGoalRelevanceScore(goal),
      );
      
    } catch (e) {
      return null;
    }
  }

  Future<List<Exercise>> _getExercisesForGoal(
    String goal,
    List<String> userEquipment,
    String fitnessLevel,
  ) async {
    List<String>? preferredMuscleGroups;
    
    switch (goal.toLowerCase()) {
      case 'build muscle':
      case 'strength':
        preferredMuscleGroups = ['chest', 'back', 'shoulders', 'legs', 'arms'];
        break;
      case 'lose weight':
      case 'cardio':
        preferredMuscleGroups = ['full body', 'core'];
        break;
      case 'tone':
        preferredMuscleGroups = ['arms', 'core', 'legs'];
        break;
      default:
        preferredMuscleGroups = null;
    }

    return await _exerciseService.getRecommendedExercises(
      userEquipment: userEquipment,
      preferredMuscleGroups: preferredMuscleGroups,
      fitnessLevel: fitnessLevel,
      limit: 15,
    );
  }

  Future<List<WorkoutRecommendation>> _generateVarietyWorkouts(
    List<String> userEquipment,
    String fitnessLevel,
    int duration,
    int count,
  ) async {
    final varietyWorkouts = <WorkoutRecommendation>[];
    final workoutTypes = ['Full Body', 'Upper Body', 'Lower Body', 'Core Focus'];

    for (int i = 0; i < count && i < workoutTypes.length; i++) {
      final workoutType = workoutTypes[i];
      final exercises = await _exerciseService.getRecommendedExercises(
        userEquipment: userEquipment,
        fitnessLevel: fitnessLevel,
        limit: _calculateExerciseCount(duration),
      );

      if (exercises.isNotEmpty) {
        varietyWorkouts.add(WorkoutRecommendation(
          name: '$workoutType Workout',
          description: 'A balanced $workoutType.toLowerCase() workout for overall fitness',
          exercises: exercises,
          estimatedDuration: duration,
          difficulty: fitnessLevel,
          goal: 'variety',
          relevanceScore: 5.0,
        ));
      }
    }

    return varietyWorkouts;
  }

  int _calculateExerciseCount(int duration) {
    // Rough estimate: 5-7 minutes per exercise including rest
    return (duration / 6).round().clamp(4, 12);
  }

  String _getWorkoutNameForGoal(String goal) {
    switch (goal.toLowerCase()) {
      case 'build muscle':
        return 'Muscle Building Workout';
      case 'strength':
        return 'Strength Training Session';
      case 'lose weight':
        return 'Fat Burning Workout';
      case 'cardio':
        return 'Cardio Blast';
      case 'tone':
        return 'Toning & Sculpting';
      default:
        return 'Custom Workout';
    }
  }

  String _getWorkoutDescriptionForGoal(String goal) {
    switch (goal.toLowerCase()) {
      case 'build muscle':
        return 'Focus on compound movements and progressive overload to build lean muscle mass';
      case 'strength':
        return 'Heavy compound exercises to increase overall strength and power';
      case 'lose weight':
        return 'High-intensity exercises to maximize calorie burn and boost metabolism';
      case 'cardio':
        return 'Cardiovascular exercises to improve heart health and endurance';
      case 'tone':
        return 'Targeted exercises to sculpt and define your physique';
      default:
        return 'A well-rounded workout tailored to your preferences';
    }
  }

  double _calculateGoalRelevanceScore(String goal) {
    // Primary goals get higher scores
    switch (goal.toLowerCase()) {
      case 'build muscle':
      case 'lose weight':
      case 'strength':
        return 10.0;
      case 'cardio':
      case 'tone':
        return 8.0;
      default:
        return 5.0;
    }
  }

  double _calculateSimilarityScore(Exercise original, Exercise alternative) {
    double score = 0.0;

    // Same primary muscle group
    if (original.primaryMuscle == alternative.primaryMuscle) {
      score += 10.0;
    }

    // Same secondary muscle group
    if (original.secondaryMuscle != null && 
        original.secondaryMuscle == alternative.secondaryMuscle) {
      score += 5.0;
    }

    // Same equipment
    if (original.equipment == alternative.equipment) {
      score += 8.0;
    }

    // Same category
    if (original.category == alternative.category) {
      score += 6.0;
    }

    // Overlapping muscle groups
    final originalMuscles = original.muscleGroups.toSet();
    final alternativeMuscles = alternative.muscleGroups.toSet();
    final overlap = originalMuscles.intersection(alternativeMuscles).length;
    score += overlap * 3.0;

    return score;
  }

  int _compareDifficulty(Exercise original, Exercise alternative) {
    // Simplified difficulty comparison based on equipment and category
    final originalDifficulty = _getExerciseDifficulty(original);
    final alternativeDifficulty = _getExerciseDifficulty(alternative);
    
    return alternativeDifficulty.compareTo(originalDifficulty);
  }

  int _getExerciseDifficulty(Exercise exercise) {
    int difficulty = 2; // Default intermediate

    // Equipment-based difficulty
    switch (exercise.equipment?.toLowerCase()) {
      case 'bodyweight':
      case 'none':
        difficulty = 1;
        break;
      case 'dumbbells':
      case 'resistance bands':
        difficulty = 2;
        break;
      case 'barbell':
      case 'cable machine':
        difficulty = 3;
        break;
    }

    // Category-based adjustment
    if (exercise.category?.toLowerCase().contains('basic') == true) {
      difficulty = 1;
    } else if (exercise.category?.toLowerCase().contains('advanced') == true) {
      difficulty = 4;
    }

    return difficulty;
  }
}

/// Scored exercise for ranking
class ScoredExercise {
  final Exercise exercise;
  final double score;

  ScoredExercise({
    required this.exercise,
    required this.score,
  });
}

/// Workout recommendation with metadata
class WorkoutRecommendation {
  final String name;
  final String description;
  final List<Exercise> exercises;
  final int estimatedDuration;
  final String difficulty;
  final String goal;
  final double relevanceScore;

  WorkoutRecommendation({
    required this.name,
    required this.description,
    required this.exercises,
    required this.estimatedDuration,
    required this.difficulty,
    required this.goal,
    required this.relevanceScore,
  });

  int get totalExercises => exercises.length;
  
  List<String> get targetedMuscleGroups {
    final muscles = <String>{};
    for (final exercise in exercises) {
      muscles.addAll(exercise.muscleGroups);
    }
    return muscles.toList()..sort();
  }

  List<String> get requiredEquipment {
    final equipment = exercises
        .where((exercise) => exercise.equipment != null)
        .map((exercise) => exercise.equipment!)
        .toSet()
        .toList();
    equipment.sort();
    return equipment;
  }
}

/// Exercise progression (easier/harder variations)
class ExerciseProgression {
  final Exercise? current;
  final List<Exercise> easier;
  final List<Exercise> harder;

  ExerciseProgression({
    required this.current,
    required this.easier,
    required this.harder,
  });

  bool get hasEasierOptions => easier.isNotEmpty;
  bool get hasHarderOptions => harder.isNotEmpty;
  bool get hasProgression => hasEasierOptions || hasHarderOptions;
}