import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'exercise_provider.dart';

final logger = Logger();

// Workout Session State Notifier with comprehensive session management
class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionNotifier(
    this._workoutService,
    this._workoutSessionService,
    this._supabaseService,
    this._timerService,
    this._setLoggingService,
  ) : super(const WorkoutSessionState.idle()) {
    _initializeRealtimeSubscription();
    _initializeTimerSubscriptions();
  }

  final WorkoutService _workoutService;
  final WorkoutSessionService _workoutSessionService;
  final SupabaseService _supabaseService;
  final WorkoutTimerService _timerService;
  final SetLoggingService _setLoggingService;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;
  StreamSubscription<int>? _restTimerSubscription;
  StreamSubscription<bool>? _restTimerStateSubscription;
  Timer? _sessionTimer;
  Timer? _syncTimer;

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _restTimerSubscription?.cancel();
    _restTimerStateSubscription?.cancel();
    _sessionTimer?.cancel();
    _syncTimer?.cancel();
    _timerService.dispose();
    _workoutSessionService.dispose();
    super.dispose();
  }

  /// Initialize Supabase Realtime subscription for live workout updates
  void _initializeRealtimeSubscription() {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      // Initialize realtime subscription through the service
      _workoutSessionService.initializeRealtimeSubscription(userId);
      
      // Listen to realtime updates
      _realtimeSubscription = _workoutSessionService.realtimeUpdates?.listen(
        (data) => _handleRealtimeUpdate(data),
        onError: (error) => logger.e('Realtime subscription error: $error'),
      );

      logger.i('Initialized workout session realtime subscription');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize realtime subscription',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Initialize timer service subscriptions
  void _initializeTimerSubscriptions() {
    try {
      // Listen to rest timer updates
      _restTimerSubscription = _timerService.restTimerStream.listen((timeRemaining) {
        final currentState = state;
        if (currentState is WorkoutSessionActive) {
          state = currentState.copyWith(restTimeRemaining: timeRemaining);
        }
      });

      // Listen to rest timer state changes
      _restTimerStateSubscription = _timerService.restTimerStateStream.listen((isActive) {
        final currentState = state;
        if (currentState is WorkoutSessionActive) {
          state = currentState.copyWith(isRestTimerActive: isActive);
        }
      });

      logger.i('Initialized timer service subscriptions');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize timer subscriptions',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle realtime updates from Supabase
  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      // Check if update is for current workout
      if (data['id'] == currentState.workout.id) {
        final updatedWorkout = Workout.fromJson(data);
        
        // Update state with new workout data
        state = currentState.copyWith(workout: updatedWorkout);
        
        logger.i('Updated workout session from realtime: ${updatedWorkout.id}');
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to handle realtime update',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Start a new workout session with comprehensive session management
  Future<void> startSession(String workoutId) async {
    state = const WorkoutSessionState.loading();

    try {
      // Check for existing active sessions
      final hasActive = await _workoutSessionService.hasActiveSession();
      if (hasActive) {
        // End existing active sessions to prevent conflicts
        await _workoutSessionService.endAllActiveSessions();
        logger.w('Ended existing active sessions before starting new session');
      }

      // Get workout with exercises
      final workoutWithExercises = await _workoutService.getWorkoutWithExercises(workoutId);
      if (workoutWithExercises == null) {
        state = const WorkoutSessionState.error('Workout not found');
        return;
      }
      
      // Check if workout has exercises
      if (workoutWithExercises.workoutExercises.isEmpty) {
        state = const WorkoutSessionState.error('Workout has no exercises');
        return;
      }

      // Start the workout session using the service
      final startedWorkout = await _workoutSessionService.startWorkoutSession(workoutId);

      // Initialize session state with comprehensive tracking
      final sessionState = WorkoutSessionActive(
        workout: startedWorkout,
        workoutExercises: workoutWithExercises.workoutExercises,
        exercises: workoutWithExercises.exercises,
        currentExerciseIndex: 0,
        currentSet: 1,
        completedSets: const [],
        exerciseLogs: const [],
        startTime: startedWorkout.startTime ?? DateTime.now(),
        lastSyncTime: DateTime.now(),
        isRestTimerActive: false,
        restTimeRemaining: 0,
      );

      state = sessionState;

      // Start session timer for periodic state persistence
      _startSessionTimer();

      // Start workout timer
      _timerService.startWorkoutTimer();

      logger.i('Started workout session: $workoutId with session_order: ${startedWorkout.sessionOrder}');
    } catch (e, stackTrace) {
      logger.e('Failed to start workout session', error: e, stackTrace: stackTrace);
      state = WorkoutSessionState.error(e.toString());
    }
  }

  /// Resume an existing workout session
  Future<void> resumeSession(String workoutId) async {
    state = const WorkoutSessionState.loading();

    try {
      // Get workout with exercises
      final workoutWithExercises = await _workoutService.getWorkoutWithExercises(workoutId);
      if (workoutWithExercises == null) {
        state = const WorkoutSessionState.error('Workout not found');
        return;
      }

      final workout = workoutWithExercises.workout;
      
      // Check if workout has exercises
      if (workoutWithExercises.workoutExercises.isEmpty) {
        state = const WorkoutSessionState.error('Workout has no exercises');
        return;
      }

      // Check if workout can be resumed
      if (!workout.canResume) {
        state = const WorkoutSessionState.error('Workout cannot be resumed');
        return;
      }

      // Resume workout using the service
      final resumedWorkout = await _workoutSessionService.resumeWorkoutSession(workoutId);

      // Restore session state from last_state
      final restoredState = _restoreSessionState(
        resumedWorkout,
        workoutWithExercises.workoutExercises,
        workoutWithExercises.exercises,
      );

      state = restoredState;

      // Start session timer
      _startSessionTimer();

      // Resume workout timer
      _timerService.resumeWorkoutTimer();

      logger.i('Resumed workout session: $workoutId');
    } catch (e, stackTrace) {
      logger.e('Failed to resume workout session', error: e, stackTrace: stackTrace);
      state = WorkoutSessionState.error(e.toString());
    }
  }

  /// Pause the current workout session
  Future<void> pauseSession() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      // Save current state and pause workout using the service
      await _persistSessionState(currentState);
      await _workoutSessionService.pauseWorkoutSession(
        currentState.workout.id,
        _createWorkoutStateFromSession(currentState).toJson(),
      );

      // Stop timers
      _stopSessionTimer();
      _timerService.pauseWorkoutTimer();
      _timerService.stopAllTimers();

      // Update state to paused
      state = WorkoutSessionPaused(
        workout: currentState.workout,
        workoutExercises: currentState.workoutExercises,
        exercises: currentState.exercises,
        currentExerciseIndex: currentState.currentExerciseIndex,
        currentSet: currentState.currentSet,
        completedSets: currentState.completedSets,
        exerciseLogs: currentState.exerciseLogs,
        startTime: currentState.startTime,
        pausedAt: DateTime.now(),
      );

      logger.i('Paused workout session: ${currentState.workout.id}');
    } catch (e, stackTrace) {
      logger.e('Failed to pause workout session', error: e, stackTrace: stackTrace);
      state = WorkoutSessionState.error(e.toString());
    }
  }

  /// Complete the current workout session with comprehensive logging
  Future<void> completeSession({
    int? rating,
    String? notes,
  }) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(currentState.startTime);

      // Complete workout using the service
      final completedWorkout = await _workoutSessionService.completeWorkoutSession(
        currentState.workout.id,
        rating: rating,
        notes: notes,
      );

      // Log all completed sets to database for detailed tracking
      if (currentState.completedSets.isNotEmpty) {
        await _workoutSessionService.logCompletedSets(currentState.completedSets);
      }

      // Create completed workout entry for historical tracking
      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        final caloriesBurned = _workoutSessionService.estimateCaloriesBurned(
          duration: duration,
          completedSets: currentState.completedSets,
        );
        
        final workoutSummary = _workoutSessionService.createWorkoutSummary(
          duration: duration,
          completedSets: currentState.completedSets,
          exerciseLogs: currentState.exerciseLogs,
          exercises: currentState.exercises,
        );

        await _workoutSessionService.createCompletedWorkoutEntry(
          workoutId: currentState.workout.id,
          userId: userId,
          duration: duration,
          caloriesBurned: caloriesBurned,
          rating: rating,
          userFeedback: notes,
          workoutSummary: workoutSummary,
        );

        // Create workout set logs for historical analysis
        final workoutLogId = '${currentState.workout.id}_${DateTime.now().millisecondsSinceEpoch}';
        await _workoutSessionService.createWorkoutSetLogs(
          workoutLogId: workoutLogId,
          completedSets: currentState.completedSets,
        );
      }

      // Stop timers and cleanup
      _stopSessionTimer();
      _timerService.stopAllTimers();

      // Update state to completed
      state = WorkoutSessionCompleted(
        workout: completedWorkout,
        workoutExercises: currentState.workoutExercises,
        exercises: currentState.exercises,
        completedSets: currentState.completedSets,
        exerciseLogs: currentState.exerciseLogs,
        startTime: currentState.startTime,
        endTime: endTime,
        rating: rating,
        notes: notes,
      );

      logger.i('Completed workout session: ${currentState.workout.id} with ${currentState.completedSets.length} sets');
    } catch (e, stackTrace) {
      logger.e('Failed to complete workout session', error: e, stackTrace: stackTrace);
      state = WorkoutSessionState.error(e.toString());
    }
  }

  /// Cancel the current workout session
  Future<void> cancelSession() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive && currentState is! WorkoutSessionPaused) {
      return;
    }

    try {
      final workoutId = currentState is WorkoutSessionActive
          ? currentState.workout.id
          : (currentState as WorkoutSessionPaused).workout.id;

      // Cancel workout using the service
      await _workoutSessionService.cancelWorkoutSession(workoutId);

      // Stop timers
      _stopSessionTimer();
      _timerService.stopAllTimers();

      // Reset state
      state = const WorkoutSessionState.idle();

      logger.i('Cancelled workout session: $workoutId');
    } catch (e, stackTrace) {
      logger.e('Failed to cancel workout session', error: e, stackTrace: stackTrace);
      state = WorkoutSessionState.error(e.toString());
    }
  }

  /// Log a completed set with comprehensive tracking
  Future<void> logSet({
    required int reps,
    required double weight,
    String? notes,
    String? difficultyRating,
  }) async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      final currentWorkoutExercise = currentState.currentWorkoutExercise;
      final currentExercise = currentState.currentExercise;

      if (currentExercise == null) return;

      // Log to database using comprehensive set logging service
      await _setLoggingService.logCompletedSet(
        workoutId: currentState.workout.id,
        workoutExerciseId: currentWorkoutExercise.id,
        performedSetOrder: currentState.currentSet,
        performedReps: reps,
        performedWeight: weight.toInt(),
        setFeedbackDifficulty: difficultyRating,
        notes: notes,
      );

      // Create set log for session state
      final setLog = CompletedSetLog(
        workoutExerciseId: currentWorkoutExercise.id,
        exerciseId: currentExercise.id,
        exerciseIndex: currentState.currentExerciseIndex,
        setNumber: currentState.currentSet,
        reps: reps,
        weight: weight,
        notes: notes,
        difficultyRating: difficultyRating,
        timestamp: DateTime.now(),
      );

      // Update completed sets
      final updatedCompletedSets = [...currentState.completedSets, setLog];

      // Update or create exercise log
      final updatedExerciseLogs = _updateExerciseLogs(
        currentState.exerciseLogs,
        currentExercise.id,
        setLog,
      );

      // Update state
      state = currentState.copyWith(
        completedSets: updatedCompletedSets,
        exerciseLogs: updatedExerciseLogs,
      );

      // Persist state to database
      await _persistSessionState(state as WorkoutSessionActive);

      // Start rest timer if not on last set using timer service
      final maxSets = currentWorkoutExercise.effectiveSets;
      if (currentState.currentSet < maxSets) {
        final restInterval = _timerService.getRestIntervalForExercise(currentWorkoutExercise);
        _timerService.startRestTimer(restInterval);
      }

      logger.i('Logged set with comprehensive tracking: ${setLog.reps} reps @ ${setLog.weight}kg');
    } catch (e, stackTrace) {
      logger.e('Failed to log set', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Move to next set
  void nextSet() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    final currentWorkoutExercise = currentState.currentWorkoutExercise;
    final maxSets = currentWorkoutExercise.effectiveSets;

    if (currentState.currentSet >= maxSets) {
      nextExercise();
      return;
    }

    state = currentState.copyWith(
      currentSet: currentState.currentSet + 1,
    );
  }

  /// Move to next exercise
  void nextExercise() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    final nextIndex = currentState.currentExerciseIndex + 1;
    if (nextIndex >= currentState.workoutExercises.length) {
      // All exercises completed - auto-complete workout
      completeSession();
      return;
    }

    _timerService.skipRestTimer();

    state = currentState.copyWith(
      currentExerciseIndex: nextIndex,
      currentSet: 1,
      isRestTimerActive: false,
      restTimeRemaining: 0,
    );
  }

  /// Move to previous exercise
  void previousExercise() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    final prevIndex = currentState.currentExerciseIndex - 1;
    if (prevIndex < 0) return;

    _timerService.skipRestTimer();

    state = currentState.copyWith(
      currentExerciseIndex: prevIndex,
      currentSet: 1,
      isRestTimerActive: false,
      restTimeRemaining: 0,
    );
  }

  /// Skip rest timer
  void skipRest() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    _timerService.skipRestTimer();
  }

  /// Add extra rest time
  void addRestTime(int seconds) {
    final currentState = state;
    if (currentState is! WorkoutSessionActive || !currentState.isRestTimerActive) return;

    _timerService.addRestTime(seconds);
  }

  /// Minimize session (background mode)
  Future<void> minimizeSession() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      // Minimize workout using the service
      await _workoutSessionService.minimizeWorkoutSession(currentState.workout.id);

      // Update state
      state = currentState.copyWith(
        workout: currentState.workout.copyWith(isMinimized: true),
      );

      logger.i('Minimized workout session: ${currentState.workout.id}');
    } catch (e, stackTrace) {
      logger.e('Failed to minimize workout session', error: e, stackTrace: stackTrace);
    }
  }

  /// Restore session from minimized state
  Future<void> restoreSession() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      // Restore workout using the service
      await _workoutSessionService.restoreWorkoutSession(currentState.workout.id);

      // Update state
      state = currentState.copyWith(
        workout: currentState.workout.copyWith(isMinimized: false),
      );

      logger.i('Restored workout session: ${currentState.workout.id}');
    } catch (e, stackTrace) {
      logger.e('Failed to restore workout session', error: e, stackTrace: stackTrace);
    }
  }

  /// End session and reset state with cleanup
  void endSession() {
    final currentState = state;
    
    // Log session end
    if (currentState is WorkoutSessionActive) {
      logger.i('Ending workout session: ${currentState.workout.id}');
    }
    
    // Stop all timers and cleanup
    _stopSessionTimer();
    _timerService.stopAllTimers();
    
    // Reset state
    state = const WorkoutSessionState.idle();
  }

  /// Check for and recover any existing active sessions on app start
  Future<void> recoverActiveSession() async {
    try {
      final activeSessions = await _workoutSessionService.getActiveWorkoutSessions();
      
      if (activeSessions.isEmpty) {
        logger.d('No active sessions to recover');
        return;
      }

      // Get the most recent active session
      final mostRecentSession = activeSessions.first;
      
      logger.i('Found active session to recover: ${mostRecentSession.id}');
      
      // Resume the most recent session
      await resumeSession(mostRecentSession.id);
      
    } catch (e, stackTrace) {
      logger.e('Failed to recover active session', error: e, stackTrace: stackTrace);
      // Don't throw - app should continue normally
    }
  }

  /// Get session statistics for analytics
  Map<String, dynamic> getSessionStatistics() {
    final currentState = state;
    
    return currentState.when(
      idle: () => {'status': 'idle'},
      loading: () => {'status': 'loading'},
      active: (workout, workoutExercises, exercises, currentExerciseIndex, currentSet, 
               completedSets, exerciseLogs, startTime, lastSyncTime, isRestTimerActive, restTimeRemaining) {
        return {
          'status': 'active',
          'workout_id': workout.id,
          'workout_name': workout.name,
          'session_order': workout.sessionOrder,
          'start_time': startTime.toIso8601String(),
          'elapsed_time_seconds': DateTime.now().difference(startTime).inSeconds,
          'current_exercise_index': currentExerciseIndex,
          'current_set': currentSet,
          'total_exercises': workoutExercises.length,
          'completed_sets': completedSets.length,
          'total_volume': completedSets.fold<double>(0, (sum, set) => sum + set.volume),
          'total_reps': completedSets.fold<int>(0, (sum, set) => sum + set.reps),
          'progress_percentage': (completedSets.length / workoutExercises.fold<int>(0, (sum, we) => sum + we.effectiveSets) * 100).clamp(0, 100),
          'is_rest_timer_active': isRestTimerActive,
          'rest_time_remaining': restTimeRemaining,
          'is_minimized': workout.isMinimized == true,
          'last_sync_time': lastSyncTime.toIso8601String(),
          'needs_sync': DateTime.now().difference(lastSyncTime).inMinutes > 1,
        };
      },
      paused: (workout, workoutExercises, exercises, currentExerciseIndex, currentSet, 
               completedSets, exerciseLogs, startTime, pausedAt) {
        return {
          'status': 'paused',
          'workout_id': workout.id,
          'workout_name': workout.name,
          'session_order': workout.sessionOrder,
          'start_time': startTime.toIso8601String(),
          'paused_at': pausedAt.toIso8601String(),
          'elapsed_time_seconds': pausedAt.difference(startTime).inSeconds,
          'pause_duration_seconds': DateTime.now().difference(pausedAt).inSeconds,
          'current_exercise_index': currentExerciseIndex,
          'current_set': currentSet,
          'total_exercises': workoutExercises.length,
          'completed_sets': completedSets.length,
          'progress_percentage': (completedSets.length / workoutExercises.fold<int>(0, (sum, we) => sum + we.effectiveSets) * 100).clamp(0, 100),
        };
      },
      completed: (workout, workoutExercises, exercises, completedSets, exerciseLogs, 
                  startTime, endTime, rating, notes) {
        return {
          'status': 'completed',
          'workout_id': workout.id,
          'workout_name': workout.name,
          'session_order': workout.sessionOrder,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'total_duration_seconds': endTime.difference(startTime).inSeconds,
          'total_exercises': workoutExercises.length,
          'completed_sets': completedSets.length,
          'total_volume': completedSets.fold<double>(0, (sum, set) => sum + set.volume),
          'total_reps': completedSets.fold<int>(0, (sum, set) => sum + set.reps),
          'rating': rating,
          'has_notes': notes != null && notes.isNotEmpty,
          'completion_percentage': 100.0,
        };
      },
      error: (message) => {
        'status': 'error',
        'error_message': message,
      },
    );
  }

  // Private helper methods

  /// Start session timer for periodic state persistence
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncSessionState(),
    );
    
    // Also start sync timer for more frequent state persistence
    _startSyncTimer();
  }

  /// Stop session timer
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _stopSyncTimer();
  }

  /// Start sync timer for frequent state persistence
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _persistCurrentState(),
    );
  }

  /// Stop sync timer
  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }



  /// Sync session state periodically with comprehensive error handling
  Future<void> _syncSessionState() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      // Persist session state to database
      await _persistSessionState(currentState);
      
      // Update last sync time
      state = currentState.copyWith(lastSyncTime: DateTime.now());
      
      logger.d('Synced workout session state for workout: ${currentState.workout.id}');
    } catch (e, stackTrace) {
      logger.e('Failed to sync session state', error: e, stackTrace: stackTrace);
      
      // Don't update sync time on failure to trigger retry
      // The session will continue to work offline and sync when possible
    }
  }

  /// Force sync session state (manual trigger)
  Future<void> forceSyncSessionState() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      await _persistSessionState(currentState);
      state = currentState.copyWith(lastSyncTime: DateTime.now());
      logger.i('Force synced workout session state');
    } catch (e, stackTrace) {
      logger.e('Failed to force sync session state', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Persist current state for seamless workout resumption
  Future<void> _persistCurrentState() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      final workoutState = _createWorkoutStateFromSession(currentState);
      await _workoutSessionService.syncWorkoutSessionState(
        currentState.workout.id,
        workoutState.toJson(),
      );
    } catch (e, stackTrace) {
      logger.e('Failed to persist current state', error: e, stackTrace: stackTrace);
    }
  }

  /// Persist session state to database
  Future<void> _persistSessionState(WorkoutSessionActive sessionState) async {
    final workoutState = _createWorkoutStateFromSession(sessionState);

    await _workoutSessionService.updateWorkoutSession(
      sessionState.workout.id,
      {'last_state': workoutState.toJson()},
    );
  }

  /// Create workout state from session state
  WorkoutState _createWorkoutStateFromSession(WorkoutSessionActive sessionState) {
    return WorkoutState(
      currentExerciseIndex: sessionState.currentExerciseIndex,
      currentSet: sessionState.currentSet,
      completedExercises: sessionState.completedSets
          .map((set) => set.exerciseId)
          .toSet()
          .toList(),
      exerciseLogs: sessionState.exerciseLogs
          .map((log) => ExerciseLog(
                exerciseId: log.exerciseId,
                sets: log.sets.map((setLog) => SetLog(
                  setNumber: setLog.setNumber,
                  reps: setLog.reps,
                  weight: setLog.weight,
                  completed: true,
                  startTime: setLog.timestamp,
                  endTime: setLog.timestamp,
                )).toList(),
                notes: log.notes,
                difficultyRating: log.difficultyRating,
                startTime: log.startTime,
                endTime: log.endTime,
              ))
          .toList(),
      totalExercises: sessionState.workoutExercises.length,
      startTime: sessionState.startTime,
      lastUpdated: DateTime.now(),
    );
  }



  /// Restore session state from database
  WorkoutSessionActive _restoreSessionState(
    Workout workout,
    List<WorkoutExercise> workoutExercises,
    List<Exercise> exercises,
  ) {
    final workoutState = workout.workoutState;
    
    if (workoutState == null) {
      // No saved state, start from beginning
      return WorkoutSessionActive(
        workout: workout,
        workoutExercises: workoutExercises,
        exercises: exercises,
        currentExerciseIndex: 0,
        currentSet: 1,
        completedSets: const [],
        exerciseLogs: const [],
        startTime: workout.startTime ?? DateTime.now(),
        lastSyncTime: DateTime.now(),
        isRestTimerActive: false,
        restTimeRemaining: 0,
      );
    }

    // Restore from saved state
    final completedSets = _restoreCompletedSets(workoutState.exerciseLogs);
    final exerciseLogs = _restoreExerciseLogs(workoutState.exerciseLogs);

    return WorkoutSessionActive(
      workout: workout,
      workoutExercises: workoutExercises,
      exercises: exercises,
      currentExerciseIndex: workoutState.currentExerciseIndex,
      currentSet: workoutState.currentSet,
      completedSets: completedSets,
      exerciseLogs: exerciseLogs,
      startTime: workoutState.startTime ?? workout.startTime ?? DateTime.now(),
      lastSyncTime: DateTime.now(),
      isRestTimerActive: false,
      restTimeRemaining: 0,
    );
  }

  /// Restore completed sets from exercise logs
  List<CompletedSetLog> _restoreCompletedSets(List<ExerciseLog> exerciseLogs) {
    final completedSets = <CompletedSetLog>[];
    
    for (int exerciseIndex = 0; exerciseIndex < exerciseLogs.length; exerciseIndex++) {
      final exerciseLog = exerciseLogs[exerciseIndex];
      
      for (final setLog in exerciseLog.sets) {
        if (setLog.completed) {
          completedSets.add(CompletedSetLog(
            workoutExerciseId: '', // Will be filled from workout exercises
            exerciseId: exerciseLog.exerciseId,
            exerciseIndex: exerciseIndex,
            setNumber: setLog.setNumber,
            reps: setLog.reps,
            weight: setLog.weight ?? 0,
            timestamp: setLog.endTime ?? DateTime.now(),
          ));
        }
      }
    }
    
    return completedSets;
  }

  /// Restore exercise logs from workout state
  List<ExerciseLogSession> _restoreExerciseLogs(List<ExerciseLog> exerciseLogs) {
    return exerciseLogs.map((log) => ExerciseLogSession(
      exerciseId: log.exerciseId,
      sets: log.sets.map((setLog) => CompletedSetLog(
        workoutExerciseId: '',
        exerciseId: log.exerciseId,
        exerciseIndex: 0,
        setNumber: setLog.setNumber,
        reps: setLog.reps,
        weight: setLog.weight ?? 0,
        timestamp: setLog.endTime ?? DateTime.now(),
        notes: null,
        difficultyRating: null,
      )).toList(),
      notes: log.notes,
      difficultyRating: log.difficultyRating,
      startTime: log.startTime,
      endTime: log.endTime,
    )).toList();
  }

  /// Update exercise logs with new set
  List<ExerciseLogSession> _updateExerciseLogs(
    List<ExerciseLogSession> exerciseLogs,
    String exerciseId,
    CompletedSetLog setLog,
  ) {
    final updatedLogs = List<ExerciseLogSession>.from(exerciseLogs);
    
    // Find existing log for exercise
    final existingLogIndex = updatedLogs.indexWhere((log) => log.exerciseId == exerciseId);
    
    if (existingLogIndex >= 0) {
      // Update existing log
      final existingLog = updatedLogs[existingLogIndex];
      final updatedSets = [...existingLog.sets, setLog];
      
      updatedLogs[existingLogIndex] = existingLog.copyWith(
        sets: updatedSets,
        endTime: setLog.timestamp,
      );
    } else {
      // Create new log
      updatedLogs.add(ExerciseLogSession(
        exerciseId: exerciseId,
        sets: [setLog],
        startTime: setLog.timestamp,
        endTime: setLog.timestamp,
      ));
    }
    
    return updatedLogs;
  }


}

// Workout Session State Provider
final workoutSessionNotifierProvider = StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>((ref) {
  final workoutService = ref.read(workoutServiceProvider);
  final workoutSessionService = ref.read(workoutSessionServiceProvider);
  final supabaseService = ref.read(supabaseServiceProvider);
  final timerService = ref.read(workoutTimerServiceProvider);
  final setLoggingService = ref.read(setLoggingServiceProvider);
  return WorkoutSessionNotifier(workoutService, workoutSessionService, supabaseService, timerService, setLoggingService);
});

// Active workout session provider
final activeWorkoutSessionProvider = Provider<WorkoutSessionState>((ref) {
  return ref.watch(workoutSessionNotifierProvider);
});

// Current workout provider (if session is active)
final currentWorkoutProvider = Provider<Workout?>((ref) {
  final sessionState = ref.watch(workoutSessionNotifierProvider);
  return sessionState.maybeWhen(
    active: (workout, _, __, ___, ____, _____, ______, _______, ________, _________, __________) => workout,
    paused: (workout, _, __, ___, ____, _____, ______, _______, ________) => workout,
    orElse: () => null,
  );
});

// Session progress provider
final sessionProgressProvider = Provider<double>((ref) {
  final sessionState = ref.watch(workoutSessionNotifierProvider);
  return sessionState.maybeWhen(
    active: (_, __, ___, ____, _____, ______, _______, ________, _________, __________, ___________) => 
        (sessionState as WorkoutSessionActive).progressPercentage,
    paused: (_, __, ___, ____, _____, ______, _______, ________, _________) =>
        (sessionState as WorkoutSessionPaused).progressPercentage,
    orElse: () => 0.0,
  );
});

// Session statistics provider
final sessionStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(workoutSessionNotifierProvider.notifier);
  return notifier.getSessionStatistics();
});

// Current exercise provider
final currentExerciseProvider = Provider<Exercise?>((ref) {
  final sessionState = ref.watch(workoutSessionNotifierProvider);
  return sessionState.maybeWhen(
    active: (_, __, exercises, currentExerciseIndex, ____, _____, ______, _______, ________, _________, __________) {
      final state = sessionState as WorkoutSessionActive;
      return state.currentExercise;
    },
    orElse: () => null,
  );
});

// Current workout exercise provider
final currentWorkoutExerciseProvider = Provider<WorkoutExercise?>((ref) {
  final sessionState = ref.watch(workoutSessionNotifierProvider);
  return sessionState.maybeWhen(
    active: (_, workoutExercises, __, currentExerciseIndex, ____, _____, ______, _______, ________, _________, __________) {
      final state = sessionState as WorkoutSessionActive;
      return state.currentWorkoutExercise;
    },
    orElse: () => null,
  );
});

// Session timer providers
final sessionElapsedTimeProvider = Provider<Duration>((ref) {
  final sessionState = ref.watch(workoutSessionNotifierProvider);
  return sessionState.maybeWhen(
    active: (_, __, ___, ____, _____, ______, _______, startTime, ________, _________, __________) => 
        DateTime.now().difference(startTime),
    paused: (_, __, ___, ____, _____, ______, _______, startTime, pausedAt) =>
        pausedAt.difference(startTime),
    completed: (_, __, ___, ____, _____, startTime, endTime, ______, _______) =>
        endTime.difference(startTime),
    orElse: () => Duration.zero,
  );
});

// Rest timer provider
final restTimerProvider = Provider<Map<String, dynamic>>((ref) {
  final sessionState = ref.watch(workoutSessionNotifierProvider);
  return sessionState.maybeWhen(
    active: (_, __, ___, ____, _____, ______, _______, ________, _________, isRestTimerActive, restTimeRemaining) => {
      'is_active': isRestTimerActive,
      'time_remaining': restTimeRemaining,
      'formatted_time': _formatTime(restTimeRemaining),
    },
    orElse: () => {
      'is_active': false,
      'time_remaining': 0,
      'formatted_time': '00:00',
    },
  );
});

// Helper function for formatting time
String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

// Session sync status provider
final sessionSyncStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final sessionState = ref.watch(workoutSessionNotifierProvider);
  return sessionState.maybeWhen(
    active: (_, __, ___, ____, _____, ______, _______, ________, lastSyncTime, _________, __________) {
      final needsSync = DateTime.now().difference(lastSyncTime).inMinutes > 1;
      return {
        'needs_sync': needsSync,
        'last_sync_time': lastSyncTime,
        'minutes_since_sync': DateTime.now().difference(lastSyncTime).inMinutes,
      };
    },
    orElse: () => {
      'needs_sync': false,
      'last_sync_time': null,
      'minutes_since_sync': 0,
    },
  );
});

// Session recovery provider
final sessionRecoveryProvider = FutureProvider<bool>((ref) async {
  final notifier = ref.read(workoutSessionNotifierProvider.notifier);
  try {
    await notifier.recoverActiveSession();
    return true;
  } catch (e) {
    return false;
  }
});