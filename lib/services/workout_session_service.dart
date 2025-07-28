import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';
import 'offline_cache_service.dart';

/// Service for managing workout session operations and database interactions
/// Integrates with workouts table (is_active, last_state JSONB) for session persistence
/// Provides dual logging system: real-time to workouts table and historical to workout_logs
/// Supports session_order tracking and is_minimized state for background tracking
class WorkoutSessionService {
  static WorkoutSessionService? _instance;
  static WorkoutSessionService get instance => _instance ??= WorkoutSessionService._();
  
  WorkoutSessionService._();
  
  final Logger _logger = Logger();
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OfflineCacheService _cacheService = OfflineCacheService.instance;
  
  // Realtime subscription for live workout updates
  RealtimeChannel? _realtimeChannel;
  StreamController<Map<String, dynamic>>? _realtimeController;

  /// Initialize Supabase Realtime subscription for live workout updates
  Future<void> initializeRealtimeSubscription(String userId) async {
    try {
      // Clean up existing subscription
      await _cleanupRealtimeSubscription();
      
      _realtimeController = StreamController<Map<String, dynamic>>.broadcast();
      
      _realtimeChannel = _supabaseService.client
          .channel('workout_sessions_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: AppConstants.workoutsTable,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              _logger.d('Realtime workout update: ${payload.eventType}');
              _realtimeController?.add(payload.newRecord);
            },
          )
          .subscribe();

      _logger.i('Initialized workout session realtime subscription for user: $userId');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize realtime subscription',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get realtime updates stream
  Stream<Map<String, dynamic>>? get realtimeUpdates => _realtimeController?.stream;

  /// Clean up realtime subscription
  Future<void> _cleanupRealtimeSubscription() async {
    try {
      await _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
      await _realtimeController?.close();
      _realtimeController = null;
    } catch (e) {
      _logger.w('Error cleaning up realtime subscription: $e');
    }
  }

  /// Start a workout session with comprehensive state management
  Future<Workout> startWorkoutSession(String workoutId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final sessionOrder = await _getNextSessionOrder(userId);
      final startTime = DateTime.now();
      
      final updates = {
        'is_active': true,
        'is_completed': false,
        'is_minimized': false,
        'start_time': startTime.toIso8601String(),
        'session_order': sessionOrder,
        'last_state': _createInitialWorkoutState(startTime).toJson(),
        'updated_at': startTime.toIso8601String(),
      };

      final response = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .update(updates)
          .eq('id', workoutId)
          .eq('user_id', userId) // Ensure user owns the workout
          .select()
          .single();

      final workout = Workout.fromJson(response);

      // Cache for offline access
      await _cacheService.cacheWorkout(workout);

      // Create initial workout log entry for historical tracking
      await _createWorkoutLogEntry(workout);

      // Initialize realtime subscription if not already done
      if (_realtimeChannel == null) {
        await initializeRealtimeSubscription(userId);
      }

      _logger.i('Started workout session: $workoutId with session_order: $sessionOrder');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to start workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update workout session state with user validation
  Future<Workout> updateWorkoutSession(
    String workoutId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updateData = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .update(updateData)
          .eq('id', workoutId)
          .eq('user_id', userId) // Ensure user owns the workout
          .select()
          .single();

      final workout = Workout.fromJson(response);

      // Update cache
      await _cacheService.cacheWorkout(workout);

      _logger.d('Updated workout session: $workoutId');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Pause workout session with state persistence
  Future<Workout> pauseWorkoutSession(
    String workoutId,
    Map<String, dynamic> lastState,
  ) async {
    try {
      final pauseTime = DateTime.now();
      
      final updates = {
        'is_active': false,
        'is_minimized': true,
        'last_state': {
          ...lastState,
          'paused_at': pauseTime.toIso8601String(),
        },
      };

      final workout = await updateWorkoutSession(workoutId, updates);

      // Update workout log entry status
      await _updateWorkoutLogStatus(workoutId, 'paused');

      _logger.i('Paused workout session: $workoutId');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to pause workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Resume workout session from paused state
  Future<Workout> resumeWorkoutSession(String workoutId) async {
    try {
      final resumeTime = DateTime.now();
      
      // Get current workout to access last_state
      final currentWorkout = await getWorkoutSession(workoutId);
      if (currentWorkout == null) {
        throw Exception('Workout not found');
      }

      final lastState = currentWorkout.lastState ?? {};
      final updates = {
        'is_active': true,
        'is_minimized': false,
        'last_state': {
          ...lastState,
          'resumed_at': resumeTime.toIso8601String(),
          'paused_at': null, // Clear pause timestamp
        },
      };

      final workout = await updateWorkoutSession(workoutId, updates);

      // Update workout log entry status
      await _updateWorkoutLogStatus(workoutId, 'in_progress');

      _logger.i('Resumed workout session: $workoutId');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to resume workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Complete workout session with comprehensive logging
  Future<Workout> completeWorkoutSession(
    String workoutId, {
    int? rating,
    String? notes,
  }) async {
    try {
      final endTime = DateTime.now();
      
      final updates = {
        'is_active': false,
        'is_completed': true,
        'is_minimized': false,
        'end_time': endTime.toIso8601String(),
        if (rating != null) 'rating': rating,
        if (notes != null) 'notes': notes,
        'last_state': null, // Clear state on completion
      };

      final workout = await updateWorkoutSession(workoutId, updates);

      // Update workout log entry with completion details
      await _updateWorkoutLogEntry(
        workoutId,
        endTime,
        workout.duration?.inSeconds,
        'completed',
        rating,
        notes,
      );

      _logger.i('Completed workout session: $workoutId with rating: $rating');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to complete workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Cancel workout session with cleanup
  Future<Workout> cancelWorkoutSession(String workoutId) async {
    try {
      final endTime = DateTime.now();
      
      final updates = {
        'is_active': false,
        'is_completed': false,
        'is_minimized': false,
        'end_time': endTime.toIso8601String(),
        'last_state': null, // Clear state on cancellation
      };

      final workout = await updateWorkoutSession(workoutId, updates);

      // Update workout log entry with cancellation
      await _updateWorkoutLogEntry(
        workoutId,
        endTime,
        workout.duration?.inSeconds,
        'cancelled',
        null,
        'Workout cancelled by user',
      );

      _logger.i('Cancelled workout session: $workoutId');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to cancel workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Minimize workout session for background tracking
  Future<Workout> minimizeWorkoutSession(String workoutId) async {
    try {
      final minimizeTime = DateTime.now();
      
      // Get current workout to preserve last_state
      final currentWorkout = await getWorkoutSession(workoutId);
      if (currentWorkout == null) {
        throw Exception('Workout not found');
      }

      final lastState = currentWorkout.lastState ?? {};
      final updates = {
        'is_minimized': true,
        'last_state': {
          ...lastState,
          'minimized_at': minimizeTime.toIso8601String(),
        },
      };

      final workout = await updateWorkoutSession(workoutId, updates);
      
      _logger.i('Minimized workout session: $workoutId for background tracking');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to minimize workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Restore workout session from minimized state
  Future<Workout> restoreWorkoutSession(String workoutId) async {
    try {
      final restoreTime = DateTime.now();
      
      // Get current workout to access last_state
      final currentWorkout = await getWorkoutSession(workoutId);
      if (currentWorkout == null) {
        throw Exception('Workout not found');
      }

      final lastState = currentWorkout.lastState ?? {};
      final updates = {
        'is_minimized': false,
        'last_state': {
          ...lastState,
          'restored_at': restoreTime.toIso8601String(),
          'minimized_at': null, // Clear minimize timestamp
        },
      };

      final workout = await updateWorkoutSession(workoutId, updates);
      
      _logger.i('Restored workout session: $workoutId from background');
      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to restore workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Log completed sets to database
  Future<void> logCompletedSets(List<CompletedSetLog> completedSets) async {
    try {
      if (completedSets.isEmpty) return;

      final completedSetsData = completedSets.map((setLog) => {
        'workout_id': setLog.workoutExerciseId.split('_')[0], // Extract workout ID
        'workout_exercise_id': setLog.workoutExerciseId,
        'performed_set_order': setLog.setNumber,
        'performed_reps': setLog.reps,
        'performed_weight': setLog.weight.toInt(),
        'set_feedback_difficulty': setLog.difficultyRating,
        'created_at': setLog.timestamp.toIso8601String(),
        'updated_at': setLog.timestamp.toIso8601String(),
      }).toList();

      await _supabaseService.client
          .from(AppConstants.completedSetsTable)
          .insert(completedSetsData);

      _logger.i('Logged ${completedSetsData.length} completed sets');
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to log completed sets',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create completed workout entry
  Future<void> createCompletedWorkoutEntry({
    required String workoutId,
    required String userId,
    required Duration duration,
    required int caloriesBurned,
    int? rating,
    String? userFeedback,
    Map<String, dynamic>? workoutSummary,
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

      await _supabaseService.client
          .from(AppConstants.completedWorkoutsTable)
          .insert(completedWorkoutData);

      _logger.i('Created completed workout entry for: $workoutId');
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create completed workout entry',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create workout set logs for historical analysis
  Future<void> createWorkoutSetLogs({
    required String workoutLogId,
    required List<CompletedSetLog> completedSets,
  }) async {
    try {
      if (completedSets.isEmpty) return;

      final workoutSetLogsData = completedSets.map((setLog) => {
        'workout_log_id': workoutLogId,
        'exercise_id': setLog.exerciseId,
        'set_number': setLog.setNumber,
        'reps_completed': setLog.reps,
        'weight': setLog.weight,
        'completed_at': setLog.timestamp.toIso8601String(),
        'created_at': setLog.timestamp.toIso8601String(),
      }).toList();

      await _supabaseService.client
          .from(AppConstants.workoutSetLogsTable)
          .insert(workoutSetLogsData);

      _logger.i('Created ${workoutSetLogsData.length} workout set logs');
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create workout set logs',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get active workout sessions for user
  Future<List<Workout>> getActiveWorkoutSessions({String? userId}) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .select()
          .eq('user_id', currentUserId)
          .eq('is_active', true)
          .order('start_time', ascending: false);

      final workouts = (response as List)
          .map((json) => Workout.fromJson(json))
          .toList();

      // Cache workouts for offline access
      for (final workout in workouts) {
        await _cacheService.cacheWorkout(workout);
      }

      _logger.i('Fetched ${workouts.length} active workout sessions');
      return workouts;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch active workout sessions',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try to get from offline cache as fallback
      final cachedWorkouts = _cacheService.getCachedWorkouts(userId: userId);
      return cachedWorkouts.where((workout) => workout.isActive).toList();
    }
  }

  /// Get workout session by ID
  Future<Workout?> getWorkoutSession(String workoutId) async {
    try {
      final response = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .select()
          .eq('id', workoutId)
          .maybeSingle();

      if (response == null) return null;

      final workout = Workout.fromJson(response);
      
      // Cache for offline access
      await _cacheService.cacheWorkout(workout);

      return workout;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch workout session: $workoutId',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Try offline cache
      return _cacheService.getCachedWorkout(workoutId);
    }
  }

  /// Estimate calories burned during workout
  int estimateCaloriesBurned({
    required Duration duration,
    required List<CompletedSetLog> completedSets,
    double? userWeight,
  }) {
    // Basic estimation algorithm
    // This is a simplified calculation - in a real app you'd use more sophisticated algorithms
    // based on user weight, exercise type, intensity, MET values, etc.
    
    final baseCaloricRate = 5.0; // calories per minute of general strength training
    final weightMultiplier = (userWeight ?? 70.0) / 70.0; // normalize to 70kg
    
    // Calculate intensity factor based on volume
    final totalVolume = completedSets.fold<double>(0, (sum, set) => sum + set.volume);
    final intensityFactor = (totalVolume / 1000).clamp(0.5, 2.0); // Scale based on volume
    
    final estimatedCalories = (duration.inMinutes * baseCaloricRate * weightMultiplier * intensityFactor).round();
    
    return estimatedCalories.clamp(10, 1000); // Reasonable bounds
  }

  /// Create workout summary for analytics
  Map<String, dynamic> createWorkoutSummary({
    required Duration duration,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
    required List<Exercise> exercises,
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
      };
    }

    // Calculate muscle group distribution
    final muscleGroupDistribution = <String, int>{};
    for (final exercise in exercises) {
      for (final muscle in exercise.muscleGroups) {
        muscleGroupDistribution[muscle] = (muscleGroupDistribution[muscle] ?? 0) + 1;
      }
    }

    return {
      'duration_minutes': duration.inMinutes,
      'duration_seconds': duration.inSeconds,
      'total_sets': totalSets,
      'total_reps': totalReps,
      'total_volume_kg': totalVolume,
      'exercises_completed': exerciseLogs.length,
      'exercise_breakdown': exerciseBreakdown,
      'muscle_group_distribution': muscleGroupDistribution,
      'average_rest_time_seconds': _calculateAverageRestTime(completedSets),
      'workout_intensity': _calculateWorkoutIntensity(completedSets, duration),
      'completion_timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Private helper methods

  /// Get next session order for user with proper tracking
  Future<int> _getNextSessionOrder(String userId) async {
    try {
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
      _logger.w('Failed to get next session order, defaulting to 1: $e');
      return 1;
    }
  }

  /// Create initial workout state with comprehensive tracking
  WorkoutState _createInitialWorkoutState(DateTime startTime) {
    return WorkoutState(
      currentExerciseIndex: 0,
      currentSet: 1,
      completedExercises: [],
      exerciseLogs: [],
      totalExercises: 0,
      startTime: startTime,
      lastUpdated: startTime,
    );
  }

  /// Update workout log status for tracking
  Future<void> _updateWorkoutLogStatus(String workoutId, String status) async {
    try {
      await _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('workout_id', workoutId);
      
      _logger.d('Updated workout log status to: $status for workout: $workoutId');
    } catch (e, stackTrace) {
      _logger.e('Failed to update workout log status', error: e, stackTrace: stackTrace);
      // Don't rethrow as this is not critical
    }
  }

  /// Create workout log entry
  Future<String> _createWorkoutLogEntry(Workout workout) async {
    try {
      final logData = {
        'user_id': workout.userId,
        'workout_id': workout.id,
        'started_at': workout.startTime?.toIso8601String(),
        'status': 'in_progress',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .insert(logData)
          .select('id')
          .single();

      final logId = response['id'] as String;
      _logger.i('Created workout log entry: $logId');
      return logId;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to create workout log entry', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update workout log entry
  Future<void> _updateWorkoutLogEntry(
    String workoutId,
    DateTime endTime,
    int? durationSeconds,
    String status,
    int? rating,
    String? notes,
  ) async {
    try {
      final updateData = {
        'ended_at': endTime.toIso8601String(),
        'status': status,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (rating != null) 'rating': rating,
        if (notes != null) 'notes': notes,
      };

      await _supabaseService.client
          .from(AppConstants.workoutLogsTable)
          .update(updateData)
          .eq('workout_id', workoutId);
      
      _logger.i('Updated workout log entry for: $workoutId');
    } catch (e, stackTrace) {
      _logger.e('Failed to update workout log entry', error: e, stackTrace: stackTrace);
      // Don't rethrow as this is not critical
    }
  }

  /// Calculate average rest time between sets
  int _calculateAverageRestTime(List<CompletedSetLog> completedSets) {
    if (completedSets.length < 2) return 0;

    final restTimes = <int>[];
    for (int i = 1; i < completedSets.length; i++) {
      final restTime = completedSets[i].timestamp.difference(completedSets[i - 1].timestamp).inSeconds;
      if (restTime > 0 && restTime < 600) { // Only consider reasonable rest times (0-10 minutes)
        restTimes.add(restTime);
      }
    }

    if (restTimes.isEmpty) return 0;
    return (restTimes.reduce((a, b) => a + b) / restTimes.length).round();
  }

  /// Calculate workout intensity score (0-10)
  double _calculateWorkoutIntensity(List<CompletedSetLog> completedSets, Duration duration) {
    if (completedSets.isEmpty || duration.inMinutes == 0) return 0.0;

    final totalVolume = completedSets.fold<double>(0, (sum, set) => sum + set.volume);
    final volumePerMinute = totalVolume / duration.inMinutes;
    
    // Normalize to 0-10 scale (this is a simplified calculation)
    final intensityScore = (volumePerMinute / 50).clamp(0.0, 10.0);
    
    return double.parse(intensityScore.toStringAsFixed(1));
  }

  /// Dispose of service resources
  Future<void> dispose() async {
    try {
      await _cleanupRealtimeSubscription();
      _logger.i('WorkoutSessionService disposed');
    } catch (e) {
      _logger.w('Error disposing WorkoutSessionService: $e');
    }
  }

  /// Get workout timer system with rest interval support
  Future<Map<String, dynamic>> getWorkoutTimerConfig(String workoutId) async {
    try {
      // Get workout exercises with rest intervals
      final response = await _supabaseService.client
          .from(AppConstants.workoutExercisesTable)
          .select('id, rest_interval, sets, order_index')
          .eq('workout_id', workoutId)
          .order('order_index', ascending: true);

      final exercises = response as List<dynamic>;
      
      return {
        'exercises': exercises,
        'default_rest_interval': AppConstants.defaultRestTime,
        'total_exercises': exercises.length,
      };
    } catch (e, stackTrace) {
      _logger.e('Failed to get workout timer config', error: e, stackTrace: stackTrace);
      return {
        'exercises': [],
        'default_rest_interval': AppConstants.defaultRestTime,
        'total_exercises': 0,
      };
    }
  }

  /// Get all active workout sessions for user (for session management)
  Future<List<Workout>> getAllActiveWorkoutSessions({String? userId}) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .select()
          .eq('user_id', currentUserId)
          .eq('is_active', true)
          .order('session_order', ascending: false);

      final workouts = (response as List)
          .map((json) => Workout.fromJson(json))
          .toList();

      _logger.i('Fetched ${workouts.length} active workout sessions for session management');
      return workouts;
      
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to fetch all active workout sessions',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Check for existing active sessions and handle conflicts
  Future<bool> hasActiveSession({String? userId}) async {
    try {
      final activeSessions = await getAllActiveWorkoutSessions(userId: userId);
      return activeSessions.isNotEmpty;
    } catch (e) {
      _logger.w('Failed to check for active sessions: $e');
      return false;
    }
  }

  /// End all active sessions (for cleanup)
  Future<void> endAllActiveSessions({String? userId}) async {
    try {
      final currentUserId = userId ?? _supabaseService.currentUser?.id;
      if (currentUserId == null) return;

      await _supabaseService.client
          .from(AppConstants.workoutsTable)
          .update({
            'is_active': false,
            'is_completed': false,
            'end_time': DateTime.now().toIso8601String(),
            'last_state': null,
          })
          .eq('user_id', currentUserId)
          .eq('is_active', true);

      _logger.i('Ended all active sessions for user: $currentUserId');
    } catch (e, stackTrace) {
      _logger.e('Failed to end all active sessions', error: e, stackTrace: stackTrace);
    }
  }

  /// Sync workout session state for persistence
  Future<void> syncWorkoutSessionState(String workoutId, Map<String, dynamic> sessionState) async {
    try {
      final updates = {
        'last_state': sessionState,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await updateWorkoutSession(workoutId, updates);
      _logger.d('Synced workout session state for: $workoutId');
    } catch (e, stackTrace) {
      _logger.e('Failed to sync workout session state', error: e, stackTrace: stackTrace);
      // Don't rethrow as this should not interrupt the workout
    }
  }
}

// Provider
final workoutSessionServiceProvider = Provider<WorkoutSessionService>((ref) {
  return WorkoutSessionService.instance;
});