import 'package:logger/logger.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'offline_cache_service.dart';
import 'exercise_service.dart';

class WorkoutService {
  static WorkoutService? _instance;
  static WorkoutService get instance => _instance ??= WorkoutService._();
  
  WorkoutService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OfflineCacheService _cacheService = OfflineCacheService.instance;
  final ExerciseService _exerciseService = ExerciseService.instance;

  /// Get workouts for a user with optional filtering
  Future<List<Workout>> getWorkouts({
    String? userId,
    bool? isActive,
    bool? isCompleted,
    int? limit,
    int? offset,
  }) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      dynamic queryBuilder = _supabaseService.client
          .from(AppConstants.workoutsTable)
          .select()
          .eq('user_id', currentUserId);

      // Apply filters
      if (isActive != null) {
        queryBuilder = queryBuilder.eq('is_active', isActive);
      }
      
      if (isCompleted != null) {
        queryBuilder = queryBuilder.eq('is_completed', isCompleted);
      }

      // Apply pagination
      if (limit != null) {
        queryBuilder = queryBuilder.limit(limit);
      }
      
      if (offset != null) {
        queryBuilder = queryBuilder.range(offset, offset + (limit ?? AppConstants.defaultPageSize) - 1);
      }

      // Order by most recent first and execute
      final response = await queryBuilder.order('created_at', ascending: false);
      final workouts = (response as List)
          .map((json) => Workout.fromJson(json))
          .toList();

      // Cache workouts for offline access
      for (final workout in workouts) {
        await _cacheService.cacheWorkout(workout);
      }

      _logger.i('Fetched ${workouts.length} workouts from database');
      return workouts;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch workouts from database',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try to get from offline cache as fallback
      final cachedWorkouts = _cacheService.getCachedWorkouts(userId: userId);
      if (cachedWorkouts.isNotEmpty) {
        _logger.i('Using ${cachedWorkouts.length} cached workouts as fallback');
        return _filterWorkouts(
          cachedWorkouts,
          isActive: isActive,
          isCompleted: isCompleted,
          limit: limit,
          offset: offset,
        );
      }
      
      rethrow;
    }
  }

  /// Get a specific workout by ID with its exercises
  Future<WorkoutWithExercises?> getWorkoutWithExercises(String workoutId) async {
    try {
      // Get workout
      final workoutResponse = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .select()
          .eq('id', workoutId)
          .maybeSingle();

      if (workoutResponse == null) {
        return null;
      }

      final workout = Workout.fromJson(workoutResponse);

      // Get workout exercises
      final exercisesResponse = await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .select()
          .eq('workout_id', workoutId)
          .order('order_index');

      final workoutExercises = (exercisesResponse as List)
          .map((json) => WorkoutExercise.fromJson(json))
          .toList();

      // Get exercise details
      final exerciseIds = workoutExercises.map((we) => we.exerciseId).toList();
      final exercises = await _exerciseService.getExercisesByIds(exerciseIds);

      // Cache for offline access
      await _cacheService.cacheWorkout(workout);
      await _cacheService.cacheWorkoutExercises(workoutExercises);

      return WorkoutWithExercises(
        workout: workout,
        workoutExercises: workoutExercises,
        exercises: exercises,
      );
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch workout with exercises: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try offline cache
      final cachedWorkout = _cacheService.getCachedWorkout(workoutId);
      if (cachedWorkout != null) {
        final cachedWorkoutExercises = _cacheService.getCachedWorkoutExercises(workoutId);
        final exerciseIds = cachedWorkoutExercises.map((we) => we.exerciseId).toList();
        final cachedExercises = exerciseIds
            .map((id) => _cacheService.getCachedExercise(id))
            .where((exercise) => exercise != null)
            .cast<Exercise>()
            .toList();

        return WorkoutWithExercises(
          workout: cachedWorkout,
          workoutExercises: cachedWorkoutExercises,
          exercises: cachedExercises,
        );
      }
      
      return null;
    }
  }

  /// Create a new workout
  Future<Workout> createWorkout({
    required String name,
    String? description,
    List<WorkoutExerciseTemplate>? exercises,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create workout (excluding description field as it doesn't exist in DB)
      final workoutData = {
        'user_id': userId,
        'name': name,
        // 'description': description, // Column doesn't exist in Supabase table
        'is_active': false,
        'is_completed': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final workoutResponse = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .insert(workoutData)
          .select()
          .single();

      final workout = Workout.fromJson(workoutResponse);

      // Add exercises if provided
      if (exercises != null && exercises.isNotEmpty) {
        await _addExercisesToWorkout(workout.id, exercises);
      }

      // Cache for offline access
      await _cacheService.cacheWorkout(workout);

      _logger.i('Created workout: ${workout.id}');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create workout',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing workout
  Future<Workout> updateWorkout(
    String workoutId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final updateData = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .update(updateData)
          .eq('id', workoutId)
          .select()
          .single();

      final workout = Workout.fromJson(response);

      // Update cache
      await _cacheService.cacheWorkout(workout);

      _logger.i('Updated workout: $workoutId');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      // Delete workout exercises first (cascade delete)
      await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .delete()
          .eq('workout_id', workoutId);

      // Delete workout
      await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .delete()
          .eq('id', workoutId);

      _logger.i('Deleted workout: $workoutId');
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to delete workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Start a workout session
  Future<Workout> startWorkout(String workoutId) async {
    try {
      final updates = {
        'is_active': true,
        'start_time': DateTime.now().toIso8601String(),
        'session_order': await _getNextSessionOrder(),
      };

      return await updateWorkout(workoutId, updates);
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to start workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Complete a workout session
  Future<Workout> completeWorkout(
    String workoutId, {
    int? rating,
    String? notes,
  }) async {
    try {
      final updates = {
        'is_active': false,
        'is_completed': true,
        'end_time': DateTime.now().toIso8601String(),
        if (rating != null) 'rating': rating,
        if (notes != null) 'notes': notes,
      };

      final workout = await updateWorkout(workoutId, updates);

      // Create workout log entry
      await _createWorkoutLog(workout);

      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to complete workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Pause a workout session
  Future<Workout> pauseWorkout(
    String workoutId,
    Map<String, dynamic> lastState,
  ) async {
    try {
      final updates = {
        'is_minimized': true,
        'last_state': lastState,
      };

      return await updateWorkout(workoutId, updates);
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to pause workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Resume a workout session
  Future<Workout> resumeWorkout(String workoutId) async {
    try {
      final updates = {
        'is_minimized': false,
      };

      return await updateWorkout(workoutId, updates);
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to resume workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get workout exercises for a specific workout
  Future<List<WorkoutExercise>> getWorkoutExercises(String workoutId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .select()
          .eq('workout_id', workoutId)
          .order('order_index');

      final workoutExercises = (response as List)
          .map((json) => WorkoutExercise.fromJson(json))
          .toList();

      // Cache for offline access
      await _cacheService.cacheWorkoutExercises(workoutExercises);

      return workoutExercises;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch workout exercises for workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try offline cache
      return _cacheService.getCachedWorkoutExercises(workoutId);
    }
  }

  /// Add exercises to a workout
  Future<void> addExercisesToWorkout(
    String workoutId,
    List<WorkoutExerciseTemplate> exercises,
  ) async {
    try {
      await _addExercisesToWorkout(workoutId, exercises);
      _logger.i('Added ${exercises.length} exercises to workout: $workoutId');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to add exercises to workout: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update workout exercise
  Future<WorkoutExercise> updateWorkoutExercise(
    String workoutExerciseId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .update(updates)
          .eq('id', workoutExerciseId)
          .select()
          .single();

      final workoutExercise = WorkoutExercise.fromJson(response);

      // Update cache
      await _cacheService.cacheWorkoutExercises([workoutExercise]);

      return workoutExercise;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update workout exercise: $workoutExerciseId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Remove exercise from workout
  Future<void> removeExerciseFromWorkout(String workoutExerciseId) async {
    try {
      await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .delete()
          .eq('id', workoutExerciseId);

      _logger.i('Removed exercise from workout: $workoutExerciseId');
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to remove exercise from workout: $workoutExerciseId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get active workouts for user
  Future<List<Workout>> getActiveWorkouts({String? userId}) async {
    return getWorkouts(
      userId: userId,
      isActive: true,
    );
  }

  /// Get completed workouts for user
  Future<List<Workout>> getCompletedWorkouts({
    String? userId,
    int? limit,
    int? offset,
  }) async {
    return getWorkouts(
      userId: userId,
      isCompleted: true,
      limit: limit,
      offset: offset,
    );
  }

  /// Get workout templates (non-active, non-completed workouts)
  Future<List<Workout>> getWorkoutTemplates({String? userId}) async {
    return getWorkouts(
      userId: userId,
      isActive: false,
      isCompleted: false,
    );
  }

  // Private helper methods

  Future<void> _addExercisesToWorkout(
    String workoutId,
    List<WorkoutExerciseTemplate> exercises,
  ) async {
    final workoutExercisesData = exercises.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      
      return {
        'workout_id': workoutId,
        'exercise_id': exercise.exerciseId,
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'weight': exercise.weight,
        'rest_interval': exercise.restInterval,
        'order_index': index,
        'completed': false,
        'created_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    await _supabaseService.client
        .from(AppConstants.workoutExercisesTable)
        .insert(workoutExercisesData);
  }

  Future<int> _getNextSessionOrder() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return 1;

      final response = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .select('session_order')
          .eq('user_id', userId)
          .order('session_order', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return 1;
      
      return (response['session_order'] as int? ?? 0) + 1;
    } catch (e) {
      return 1;
    }
  }

  Future<void> _createWorkoutLog(Workout workout) async {
    try {
      final logData = {
        'user_id': workout.userId,
        'workout_id': workout.id,
        'started_at': workout.startTime?.toIso8601String(),
        'ended_at': workout.endTime?.toIso8601String(),
        'duration_seconds': workout.duration,
        'rating': workout.rating,
        'notes': workout.notes,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .insert(logData)
          .select()
          .single();

      final workoutLog = WorkoutLog.fromJson(response);
      await _cacheService.cacheWorkoutLog(workoutLog);
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create workout log',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow as this is not critical for workout completion
    }
  }

  List<Workout> _filterWorkouts(
    List<Workout> workouts, {
    bool? isActive,
    bool? isCompleted,
    int? limit,
    int? offset,
  }) {
    var filtered = workouts.where((workout) {
      if (isActive != null && workout.isActive != isActive) {
        return false;
      }
      
      if (isCompleted != null && workout.isCompleted != isCompleted) {
        return false;
      }
      
      return true;
    }).toList();

    // Apply pagination
    if (offset != null) {
      filtered = filtered.skip(offset).toList();
    }
    
    if (limit != null) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }
}

/// Template for creating workout exercises
class WorkoutExerciseTemplate {
  final String exerciseId;
  final String name;
  final int sets;
  final List<int>? reps;
  final List<int>? weight;
  final int? restInterval;

  WorkoutExerciseTemplate({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.reps,
    this.weight,
    this.restInterval,
  });
}

/// Combined workout with exercises data
class WorkoutWithExercises {
  final Workout workout;
  final List<WorkoutExercise> workoutExercises;
  final List<Exercise> exercises;

  WorkoutWithExercises({
    required this.workout,
    required this.workoutExercises,
    required this.exercises,
  });

  /// Get exercise details for a workout exercise
  Exercise? getExerciseForWorkoutExercise(WorkoutExercise workoutExercise) {
    return exercises
        .where((exercise) => exercise.id == workoutExercise.exerciseId)
        .firstOrNull;
  }

  /// Get total estimated duration in minutes
  int get estimatedDuration {
    int totalTime = 0;
    
    for (final workoutExercise in workoutExercises) {
      // Estimate 30 seconds per set + rest time
      final setTime = (workoutExercise.effectiveSets * 30);
      final restTime = (workoutExercise.effectiveSets - 1) * (workoutExercise.restInterval ?? 60);
      totalTime += setTime + restTime;
    }
    
    return (totalTime / 60).ceil(); // Convert to minutes
  }

  /// Get total number of exercises
  int get totalExercises => workoutExercises.length;

  /// Get total number of sets
  int get totalSets => workoutExercises
      .map((we) => we.effectiveSets)
      .fold(0, (sum, sets) => sum + sets);

  /// Check if workout has video content
  bool get hasVideoContent => exercises.any((exercise) => exercise.hasVideo);

  /// Get unique muscle groups targeted
  List<String> get targetedMuscleGroups {
    final muscleGroups = <String>{};
    
    for (final exercise in exercises) {
      muscleGroups.addAll(exercise.muscleGroups);
    }
    
    return muscleGroups.toList()..sort();
  }

  /// Get required equipment
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