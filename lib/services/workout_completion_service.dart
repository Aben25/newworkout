import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'offline_cache_service.dart';
import 'profile_service.dart';

/// Comprehensive workout completion service
/// Handles workout completion, rating system, calorie estimation, achievements, and social sharing
class WorkoutCompletionService {
  static WorkoutCompletionService? _instance;
  static WorkoutCompletionService get instance => _instance ??= WorkoutCompletionService._();
  
  WorkoutCompletionService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OfflineCacheService _cacheService = OfflineCacheService.instance;
  final ProfileService _profileService = ProfileService.instance;

  /// Complete workout with comprehensive tracking and analytics
  Future<CompletedWorkout> completeWorkout({
    required String workoutId,
    required Duration duration,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
    required List<Exercise> exercises,
    int? rating,
    String? userFeedback,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile for calorie calculation
      final userProfile = await _profileService.getUserProfile();
      
      // Calculate calories burned using fitness algorithms
      final caloriesBurned = await _estimateCaloriesBurned(
        duration: duration,
        completedSets: completedSets,
        exerciseLogs: exerciseLogs,
        exercises: exercises,
        userWeight: userProfile?.weight,
        userAge: userProfile?.age,
        userGender: userProfile?.gender,
      );

      // Create comprehensive workout summary
      final workoutSummary = _createWorkoutSummary(
        duration: duration,
        completedSets: completedSets,
        exerciseLogs: exerciseLogs,
        exercises: exercises,
        caloriesBurned: caloriesBurned,
      );

      // Create completed workout entry
      final completedWorkout = await _createCompletedWorkoutEntry(
        userId: userId,
        workoutId: workoutId,
        duration: duration,
        caloriesBurned: caloriesBurned,
        rating: rating,
        userFeedback: userFeedback,
        workoutSummary: workoutSummary,
      );

      // Update workout rating in workouts table
      await _updateWorkoutRating(workoutId, rating);

      // Create automatic workout log entry
      await _createWorkoutLogEntry(
        userId: userId,
        workoutId: workoutId,
        duration: duration,
        rating: rating,
        userFeedback: userFeedback,
      );

      // Check and unlock achievements
      final unlockedAchievements = await _checkAndUnlockAchievements(
        userId: userId,
        completedWorkout: completedWorkout,
        completedSets: completedSets,
        exerciseLogs: exerciseLogs,
      );

      // Cache for offline access
      await _cacheService.cacheCompletedWorkout(completedWorkout);

      _logger.i('Completed workout: $workoutId with ${unlockedAchievements.length} achievements unlocked');
      return completedWorkout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to complete workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Estimate calories burned using comprehensive fitness algorithms
  Future<int> _estimateCaloriesBurned({
    required Duration duration,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
    required List<Exercise> exercises,
    double? userWeight,
    int? userAge,
    String? userGender,
  }) async {
    try {
      // Default values if user data not available
      final weight = userWeight ?? 70.0; // kg
      final age = userAge ?? 30;
      final isMale = userGender?.toLowerCase() == 'male';

      // Base metabolic rate calculation (Harris-Benedict equation)
      final bmr = isMale
          ? 88.362 + (13.397 * weight) + (4.799 * 175) - (5.677 * age) // Assuming average height 175cm
          : 447.593 + (9.247 * weight) + (3.098 * 165) - (4.330 * age); // Assuming average height 165cm

      // Calculate MET (Metabolic Equivalent of Task) based on workout intensity
      final workoutIntensity = _calculateWorkoutIntensity(completedSets, duration);
      final met = _getMETFromIntensity(workoutIntensity, exercises);

      // Calorie calculation: (MET * weight in kg * duration in hours)
      final durationHours = duration.inMinutes / 60.0;
      final caloriesBurned = (met * weight * durationHours).round();

      // Apply additional factors
      final adjustedCalories = _applyCalorieAdjustments(
        baseCalories: caloriesBurned,
        completedSets: completedSets,
        exerciseLogs: exerciseLogs,
        exercises: exercises,
        userAge: age,
        isMale: isMale,
      );

      return adjustedCalories.clamp(10, 2000); // Reasonable bounds
      
    } catch (e) {
      _logger.w('Failed to estimate calories, using fallback calculation: $e');
      // Fallback to simple calculation
      return (duration.inMinutes * 5.0).round().clamp(10, 1000);
    }
  }

  /// Calculate workout intensity score (0-10)
  double _calculateWorkoutIntensity(List<CompletedSetLog> completedSets, Duration duration) {
    if (completedSets.isEmpty || duration.inMinutes == 0) return 5.0; // Default moderate intensity

    final totalVolume = completedSets.fold<double>(0, (sum, set) => sum + set.volume);
    final volumePerMinute = totalVolume / duration.inMinutes;
    
    // Calculate intensity based on volume per minute and rest periods
    final averageRestTime = _calculateAverageRestTime(completedSets);
    final restFactor = averageRestTime > 0 ? (120 / averageRestTime).clamp(0.5, 2.0) : 1.0;
    
    // Normalize to 0-10 scale
    final baseIntensity = (volumePerMinute / 50).clamp(0.0, 10.0);
    final adjustedIntensity = (baseIntensity * restFactor).clamp(0.0, 10.0);
    
    return double.parse(adjustedIntensity.toStringAsFixed(1));
  }

  /// Get MET value from workout intensity and exercise types
  double _getMETFromIntensity(double intensity, List<Exercise> exercises) {
    // Base MET for strength training
    double baseMET = 3.5; // Light strength training
    
    if (intensity >= 8.0) {
      baseMET = 6.0; // Vigorous strength training
    } else if (intensity >= 6.0) {
      baseMET = 5.0; // Moderate-vigorous strength training
    } else if (intensity >= 4.0) {
      baseMET = 4.5; // Moderate strength training
    }

    // Adjust based on exercise types
    final hasCardio = exercises.any((e) => 
        e.category?.toLowerCase().contains('cardio') == true ||
        e.name.toLowerCase().contains('burpee') ||
        e.name.toLowerCase().contains('jump'));
    
    if (hasCardio) {
      baseMET += 1.0; // Increase MET for cardio elements
    }

    return baseMET.clamp(3.0, 8.0);
  }

  /// Apply additional calorie adjustments based on various factors
  int _applyCalorieAdjustments({
    required int baseCalories,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
    required List<Exercise> exercises,
    required int userAge,
    required bool isMale,
  }) {
    double adjustedCalories = baseCalories.toDouble();

    // Age adjustment (metabolism slows with age)
    if (userAge > 40) {
      adjustedCalories *= 0.95;
    } else if (userAge < 25) {
      adjustedCalories *= 1.05;
    }

    // Gender adjustment (males typically burn more calories)
    if (isMale) {
      adjustedCalories *= 1.1;
    }

    // Exercise variety bonus (more muscle groups = more calories)
    final uniqueMuscleGroups = exercises
        .expand((e) => e.muscleGroups)
        .toSet()
        .length;
    if (uniqueMuscleGroups >= 5) {
      adjustedCalories *= 1.1;
    }

    // High intensity bonus
    final avgDifficulty = _calculateAverageDifficulty(completedSets);
    if (avgDifficulty >= 4.0) {
      adjustedCalories *= 1.15;
    }

    return adjustedCalories.round();
  }

  /// Calculate average difficulty rating from completed sets
  double _calculateAverageDifficulty(List<CompletedSetLog> completedSets) {
    final ratingsWithValues = completedSets
        .where((set) => set.difficultyRating != null)
        .map((set) => set.difficultyRatingValue)
        .where((rating) => rating != null)
        .cast<double>()
        .toList();

    if (ratingsWithValues.isEmpty) return 3.0; // Default moderate
    
    return ratingsWithValues.reduce((a, b) => a + b) / ratingsWithValues.length;
  }

  /// Calculate average rest time between sets
  int _calculateAverageRestTime(List<CompletedSetLog> completedSets) {
    if (completedSets.length < 2) return 90; // Default rest time

    final restTimes = <int>[];
    for (int i = 1; i < completedSets.length; i++) {
      final restTime = completedSets[i].timestamp.difference(completedSets[i - 1].timestamp).inSeconds;
      if (restTime > 0 && restTime < 600) { // Only consider reasonable rest times (0-10 minutes)
        restTimes.add(restTime);
      }
    }

    if (restTimes.isEmpty) return 90;
    return (restTimes.reduce((a, b) => a + b) / restTimes.length).round();
  }

  /// Create comprehensive workout summary for analytics
  Map<String, dynamic> _createWorkoutSummary({
    required Duration duration,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
    required List<Exercise> exercises,
    required int caloriesBurned,
  }) {
    final totalSets = completedSets.length;
    final totalReps = completedSets.fold<int>(0, (sum, set) => sum + set.reps);
    final totalVolume = completedSets.fold<double>(0, (sum, set) => sum + set.volume);
    
    final exerciseBreakdown = <String, Map<String, dynamic>>{};
    
    for (final exerciseLog in exerciseLogs) {
      final exercise = exercises.firstWhere(
        (e) => e.id == exerciseLog.exerciseId,
        orElse: () => Exercise(id: exerciseLog.exerciseId, name: 'Unknown', createdAt: DateTime.now()),
      );
      
      exerciseBreakdown[exerciseLog.exerciseId] = {
        'name': exercise.name,
        'sets_completed': exerciseLog.sets.length,
        'total_reps': exerciseLog.totalReps,
        'total_volume': exerciseLog.totalVolume,
        'difficulty_rating': exerciseLog.difficultyRating,
        'notes': exerciseLog.notes,
        'duration_seconds': exerciseLog.duration?.inSeconds,
        'primary_muscle': exercise.primaryMuscle,
        'secondary_muscle': exercise.secondaryMuscle,
        'equipment': exercise.equipment,
        'category': exercise.category,
      };
    }

    // Calculate muscle group distribution
    final muscleGroupDistribution = <String, int>{};
    for (final exercise in exercises) {
      for (final muscle in exercise.muscleGroups) {
        muscleGroupDistribution[muscle] = (muscleGroupDistribution[muscle] ?? 0) + 1;
      }
    }

    // Calculate personal records
    final personalRecords = _identifyPersonalRecords(completedSets, exercises);

    return {
      'duration_minutes': duration.inMinutes,
      'duration_seconds': duration.inSeconds,
      'total_sets': totalSets,
      'total_reps': totalReps,
      'total_volume_kg': totalVolume,
      'exercises_completed': exerciseLogs.length,
      'calories_burned': caloriesBurned,
      'exercise_breakdown': exerciseBreakdown,
      'muscle_group_distribution': muscleGroupDistribution,
      'average_rest_time_seconds': _calculateAverageRestTime(completedSets),
      'workout_intensity': _calculateWorkoutIntensity(completedSets, duration),
      'average_difficulty': _calculateAverageDifficulty(completedSets),
      'personal_records': personalRecords,
      'completion_timestamp': DateTime.now().toIso8601String(),
      'workout_efficiency': _calculateWorkoutEfficiency(duration, totalVolume, totalSets),
      'volume_per_minute': duration.inMinutes > 0 ? totalVolume / duration.inMinutes : 0,
      'sets_per_minute': duration.inMinutes > 0 ? totalSets / duration.inMinutes : 0,
    };
  }

  /// Calculate workout efficiency score
  double _calculateWorkoutEfficiency(Duration duration, double totalVolume, int totalSets) {
    if (duration.inMinutes == 0) return 0.0;
    
    final volumeEfficiency = totalVolume / duration.inMinutes;
    final setEfficiency = totalSets / duration.inMinutes;
    
    // Normalize and combine metrics (this is a simplified calculation)
    final efficiency = ((volumeEfficiency / 50) + (setEfficiency / 0.5)) / 2;
    
    return efficiency.clamp(0.0, 10.0);
  }

  /// Identify personal records from completed sets
  List<Map<String, dynamic>> _identifyPersonalRecords(
    List<CompletedSetLog> completedSets,
    List<Exercise> exercises,
  ) {
    // This is a simplified implementation
    // In a real app, you'd compare against historical data
    final personalRecords = <Map<String, dynamic>>[];
    
    final exerciseMaxes = <String, Map<String, dynamic>>{};
    
    for (final set in completedSets) {
      final exerciseId = set.exerciseId;
      final volume = set.volume;
      final weight = set.weight;
      final reps = set.reps;
      
      if (!exerciseMaxes.containsKey(exerciseId)) {
        exerciseMaxes[exerciseId] = {
          'max_weight': weight,
          'max_volume': volume,
          'max_reps': reps,
          'best_set': set,
        };
      } else {
        final current = exerciseMaxes[exerciseId]!;
        
        if (weight > current['max_weight']) {
          current['max_weight'] = weight;
          personalRecords.add({
            'type': 'max_weight',
            'exercise_id': exerciseId,
            'value': weight,
            'set_data': set.toJson(),
          });
        }
        
        if (volume > current['max_volume']) {
          current['max_volume'] = volume;
          personalRecords.add({
            'type': 'max_volume',
            'exercise_id': exerciseId,
            'value': volume,
            'set_data': set.toJson(),
          });
        }
        
        if (reps > current['max_reps']) {
          current['max_reps'] = reps;
          personalRecords.add({
            'type': 'max_reps',
            'exercise_id': exerciseId,
            'value': reps,
            'set_data': set.toJson(),
          });
        }
      }
    }
    
    return personalRecords;
  }

  /// Create completed workout entry in database
  Future<CompletedWorkout> _createCompletedWorkoutEntry({
    required String userId,
    required String workoutId,
    required Duration duration,
    required int caloriesBurned,
    int? rating,
    String? userFeedback,
    required Map<String, dynamic> workoutSummary,
  }) async {
    try {
      final completedWorkoutData = {
        'user_id': userId,
        'workout_id': workoutId,
        'completed_at': DateTime.now().toIso8601String(),
        'duration': duration.inMinutes,
        'calories_burned': caloriesBurned,
        'rating': rating,
        'user_feedback_completed_workout': userFeedback,
        'completed_workout_summary': workoutSummary,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from(AppConstants.completedWorkoutsTable)
          .insert(completedWorkoutData)
          .select()
          .single();

      final completedWorkout = CompletedWorkout.fromJson(response);
      
      _logger.i('Created completed workout entry: ${completedWorkout.id}');
      return completedWorkout;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to create completed workout entry', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update workout rating in workouts table
  Future<void> _updateWorkoutRating(String workoutId, int? rating) async {
    try {
      if (rating == null) return;

      await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .update({
            'rating': rating,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workoutId);

      _logger.d('Updated workout rating: $workoutId -> $rating');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to update workout rating', error: e, stackTrace: stackTrace);
      // Don't rethrow as this is not critical
    }
  }

  /// Create automatic workout log entry
  Future<void> _createWorkoutLogEntry({
    required String userId,
    required String workoutId,
    required Duration duration,
    int? rating,
    String? userFeedback,
  }) async {
    try {
      final now = DateTime.now();
      final startedAt = now.subtract(duration);

      final logData = {
        'user_id': userId,
        'workout_id': workoutId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': now.toIso8601String(),
        'duration_seconds': duration.inSeconds,
        'status': 'completed',
        'rating': rating,
        'notes': userFeedback,
        'created_at': now.toIso8601String(),
      };

      await _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .insert(logData);

      _logger.i('Created workout log entry for: $workoutId');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to create workout log entry', error: e, stackTrace: stackTrace);
      // Don't rethrow as this is not critical
    }
  }

  /// Check and unlock achievements based on workout completion
  Future<List<UserAchievement>> _checkAndUnlockAchievements({
    required String userId,
    required CompletedWorkout completedWorkout,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
  }) async {
    try {
      final unlockedAchievements = <UserAchievement>[];
      
      // Get user's workout history for achievement calculations
      final userStats = await _getUserWorkoutStats(userId);
      
      // Check each predefined achievement
      for (final achievement in PredefinedAchievements.achievements) {
        final shouldUnlock = await _shouldUnlockAchievement(
          achievement: achievement,
          completedWorkout: completedWorkout,
          completedSets: completedSets,
          exerciseLogs: exerciseLogs,
          userStats: userStats,
        );
        
        if (shouldUnlock) {
          final userAchievement = await _unlockAchievement(
            userId: userId,
            achievementId: achievement.id,
            workoutId: completedWorkout.workoutId,
          );
          
          if (userAchievement != null) {
            unlockedAchievements.add(userAchievement);
          }
        }
      }
      
      _logger.i('Unlocked ${unlockedAchievements.length} achievements for user: $userId');
      return unlockedAchievements;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to check achievements', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get user workout statistics for achievement calculations
  Future<Map<String, dynamic>> _getUserWorkoutStats(String userId) async {
    try {
      // Get total workouts completed
      final totalWorkoutsResponse = await _supabaseService.client
          .from(AppConstants.completedWorkoutsTable)
          .select('id')
          .eq('user_id', userId);
      
      final totalWorkouts = (totalWorkoutsResponse as List).length;

      // Get total volume lifted
      final volumeResponse = await _supabaseService.client
          .from(AppConstants.completedWorkoutsTable)
          .select('completed_workout_summary')
          .eq('user_id', userId);
      
      double totalVolume = 0.0;
      int totalPersonalRecords = 0;
      
      for (final workout in volumeResponse as List) {
        final summary = workout['completed_workout_summary'] as Map<String, dynamic>?;
        if (summary != null) {
          totalVolume += (summary['total_volume_kg'] ?? 0.0).toDouble();
          final prs = summary['personal_records'] as List?;
          totalPersonalRecords += prs?.length ?? 0;
        }
      }

      // Calculate consecutive workout days (simplified)
      final recentWorkouts = await _supabaseService.client
          .from(AppConstants.completedWorkoutsTable)
          .select('completed_at')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(30);
      
      final consecutiveDays = _calculateConsecutiveDays(recentWorkouts as List);

      return {
        'total_workouts': totalWorkouts,
        'total_volume': totalVolume,
        'total_personal_records': totalPersonalRecords,
        'consecutive_days': consecutiveDays,
      };
      
    } catch (e, stackTrace) {
      _logger.e('Failed to get user workout stats', error: e, stackTrace: stackTrace);
      return {
        'total_workouts': 0,
        'total_volume': 0.0,
        'total_personal_records': 0,
        'consecutive_days': 0,
      };
    }
  }

  /// Calculate consecutive workout days
  int _calculateConsecutiveDays(List<dynamic> workouts) {
    if (workouts.isEmpty) return 0;
    
    final dates = workouts
        .map((w) => DateTime.parse(w['completed_at']))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first
    
    if (dates.isEmpty) return 0;
    
    int consecutiveDays = 1;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Check if the most recent workout was today or yesterday
    if (dates.first.difference(todayDate).inDays > 1) {
      return 0; // Streak is broken
    }
    
    for (int i = 1; i < dates.length; i++) {
      final daysDifference = dates[i - 1].difference(dates[i]).inDays;
      if (daysDifference == 1) {
        consecutiveDays++;
      } else {
        break;
      }
    }
    
    return consecutiveDays;
  }

  /// Check if an achievement should be unlocked
  Future<bool> _shouldUnlockAchievement({
    required Achievement achievement,
    required CompletedWorkout completedWorkout,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
    required Map<String, dynamic> userStats,
  }) async {
    try {
      // Check if user already has this achievement
      final existingAchievement = await _supabaseService.client
          .from('user_achievements')
          .select('id')
          .eq('user_id', completedWorkout.userId)
          .eq('achievement_id', achievement.id)
          .maybeSingle();
      
      if (existingAchievement != null) return false; // Already unlocked
      
      // Check achievement criteria
      final criteria = achievement.criteria;
      
      switch (achievement.id) {
        case 'first_workout':
          return userStats['total_workouts'] >= 1;
          
        case 'workout_streak_7':
          return userStats['consecutive_days'] >= 7;
          
        case 'workout_streak_30':
          return userStats['consecutive_days'] >= 30;
          
        case 'volume_1000':
          return completedWorkout.totalVolume >= 1000;
          
        case 'volume_10000':
          return userStats['total_volume'] >= 10000;
          
        case 'long_workout_60':
          return completedWorkout.duration >= 60;
          
        case 'long_workout_120':
          return completedWorkout.duration >= 120;
          
        case 'workouts_10':
          return userStats['total_workouts'] >= 10;
          
        case 'workouts_50':
          return userStats['total_workouts'] >= 50;
          
        case 'workouts_100':
          return userStats['total_workouts'] >= 100;
          
        case 'first_pr':
          return userStats['total_personal_records'] >= 1;
          
        case 'pr_streak_5':
          final prs = completedWorkout.workoutSummary?['personal_records'] as List?;
          return (prs?.length ?? 0) >= 5;
          
        default:
          return false;
      }
      
    } catch (e) {
      _logger.w('Error checking achievement ${achievement.id}: $e');
      return false;
    }
  }

  /// Unlock achievement for user
  Future<UserAchievement?> _unlockAchievement({
    required String userId,
    required String achievementId,
    required String workoutId,
  }) async {
    try {
      final userAchievementData = {
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
        'workout_id': workoutId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('user_achievements')
          .insert(userAchievementData)
          .select()
          .single();

      final userAchievement = UserAchievement.fromJson(response);
      
      _logger.i('Unlocked achievement: $achievementId for user: $userId');
      return userAchievement;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to unlock achievement: $achievementId', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get completed workouts for user with pagination
  Future<List<CompletedWorkout>> getCompletedWorkouts({
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from(AppConstants.completedWorkoutsTable)
          .select()
          .eq('user_id', currentUserId)
          .order('completed_at', ascending: false)
          .range(offset, offset + limit - 1);

      final completedWorkouts = (response as List)
          .map((json) => CompletedWorkout.fromJson(json))
          .toList();

      // Cache for offline access
      for (final workout in completedWorkouts) {
        await _cacheService.cacheCompletedWorkout(workout);
      }

      _logger.i('Fetched ${completedWorkouts.length} completed workouts');
      return completedWorkouts;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to fetch completed workouts', error: e, stackTrace: stackTrace);
      
      // Try offline cache as fallback
      return _cacheService.getCachedCompletedWorkouts(userId: userId);
    }
  }

  /// Get user achievements
  Future<List<UserAchievement>> getUserAchievements({String? userId}) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from('user_achievements')
          .select()
          .eq('user_id', currentUserId)
          .order('unlocked_at', ascending: false);

      final userAchievements = (response as List)
          .map((json) => UserAchievement.fromJson(json))
          .toList();

      _logger.i('Fetched ${userAchievements.length} user achievements');
      return userAchievements;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to fetch user achievements', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Create shareable workout summary for social features
  Map<String, dynamic> createShareableWorkoutSummary(CompletedWorkout completedWorkout) {
    return {
      'workout_id': completedWorkout.workoutId,
      'completed_at': completedWorkout.completedAt.toIso8601String(),
      'duration': completedWorkout.formattedDuration,
      'calories_burned': completedWorkout.caloriesBurned,
      'total_sets': completedWorkout.totalSets,
      'total_reps': completedWorkout.totalReps,
      'total_volume': completedWorkout.formattedVolume,
      'exercises_completed': completedWorkout.exercisesCompleted,
      'rating': completedWorkout.rating,
      'workout_intensity': completedWorkout.workoutIntensity,
      'achievements': completedWorkout.shareableData['achievements'],
      'muscle_groups': completedWorkout.muscleGroupDistribution?.keys.toList() ?? [],
      'share_text': _generateShareText(completedWorkout),
    };
  }

  /// Generate share text for social media
  String _generateShareText(CompletedWorkout completedWorkout) {
    final achievements = completedWorkout.shareableData['achievements'] as List<String>;
    final achievementText = achievements.isNotEmpty 
        ? ' 🏆 ${achievements.join(', ')}'
        : '';
    
    return 'Just completed an amazing workout! 💪\n'
        '⏱️ ${completedWorkout.formattedDuration}\n'
        '🔥 ${completedWorkout.caloriesBurned} calories\n'
        '🏋️ ${completedWorkout.totalSets} sets, ${completedWorkout.totalReps} reps\n'
        '📊 ${completedWorkout.formattedVolume} total volume\n'
        '${completedWorkout.formattedRating}$achievementText\n'
        '#WorkoutComplete #FitnessJourney #ModernWorkoutTracker';
  }

  /// Dispose of service resources
  Future<void> dispose() async {
    try {
      _logger.i('WorkoutCompletionService disposed');
    } catch (e) {
      _logger.w('Error disposing WorkoutCompletionService: $e');
    }
  }
}

// Provider
final workoutCompletionServiceProvider = Provider<WorkoutCompletionService>((ref) {
  return WorkoutCompletionService.instance;
});