import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'exercise_provider.dart';

final logger = Logger();

// User Workouts Provider
final userWorkoutsProvider = FutureProvider.family<List<Workout>, WorkoutFilters>((ref, filters) async {
  final workoutService = ref.read(workoutServiceProvider);
  try {
    return await workoutService.getWorkouts(
      userId: filters.userId,
      isActive: filters.isActive,
      isCompleted: filters.isCompleted,
      limit: filters.limit,
      offset: filters.offset,
    );
  } catch (e, stackTrace) {
    logger.e('Failed to load user workouts', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Workout with Exercises Provider
final workoutWithExercisesProvider = FutureProvider.family<WorkoutWithExercises?, String>((ref, workoutId) async {
  final workoutService = ref.read(workoutServiceProvider);
  try {
    return await workoutService.getWorkoutWithExercises(workoutId);
  } catch (e, stackTrace) {
    logger.e('Failed to load workout with exercises: $workoutId', error: e, stackTrace: stackTrace);
    return null;
  }
});

// Active Workouts Provider
final activeWorkoutsProvider = FutureProvider.family<List<Workout>, String?>((ref, userId) async {
  final workoutService = ref.read(workoutServiceProvider);
  try {
    return await workoutService.getActiveWorkouts(userId: userId);
  } catch (e, stackTrace) {
    logger.e('Failed to load active workouts', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Completed Workouts Provider
final completedWorkoutsProvider = FutureProvider.family<List<Workout>, CompletedWorkoutFilters>((ref, filters) async {
  final workoutService = ref.read(workoutServiceProvider);
  try {
    return await workoutService.getCompletedWorkouts(
      userId: filters.userId,
      limit: filters.limit,
      offset: filters.offset,
    );
  } catch (e, stackTrace) {
    logger.e('Failed to load completed workouts', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Workout Templates Provider
final workoutTemplatesProvider = FutureProvider.family<List<Workout>, String?>((ref, userId) async {
  final workoutService = ref.read(workoutServiceProvider);
  try {
    return await workoutService.getWorkoutTemplates(userId: userId);
  } catch (e, stackTrace) {
    logger.e('Failed to load workout templates', error: e, stackTrace: stackTrace);
    return [];
  }
});

// Workout Exercises Provider
final workoutExercisesProvider = FutureProvider.family<List<WorkoutExercise>, String>((ref, workoutId) async {
  final workoutService = ref.read(workoutServiceProvider);
  try {
    return await workoutService.getWorkoutExercises(workoutId);
  } catch (e, stackTrace) {
    logger.e('Failed to load workout exercises: $workoutId', error: e, stackTrace: stackTrace);
    return [];
  }
});

// State Notifier for Workout Management
class WorkoutNotifier extends StateNotifier<AsyncValue<Workout?>> {
  WorkoutNotifier(this._workoutService) : super(const AsyncValue.data(null));

  final WorkoutService _workoutService;

  Future<void> createWorkout({
    required String name,
    String? description,
    List<WorkoutExerciseTemplate>? exercises,
  }) async {
    state = const AsyncValue.loading();

    try {
      final workout = await _workoutService.createWorkout(
        name: name,
        description: description,
        exercises: exercises,
      );
      state = AsyncValue.data(workout);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateWorkout(String workoutId, Map<String, dynamic> updates) async {
    try {
      final workout = await _workoutService.updateWorkout(workoutId, updates);
      state = AsyncValue.data(workout);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _workoutService.deleteWorkout(workoutId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> startWorkout(String workoutId) async {
    try {
      final workout = await _workoutService.startWorkout(workoutId);
      state = AsyncValue.data(workout);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> completeWorkout(
    String workoutId, {
    int? rating,
    String? notes,
  }) async {
    try {
      final workout = await _workoutService.completeWorkout(
        workoutId,
        rating: rating,
        notes: notes,
      );
      state = AsyncValue.data(workout);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> pauseWorkout(String workoutId, Map<String, dynamic> lastState) async {
    try {
      final workout = await _workoutService.pauseWorkout(workoutId, lastState);
      state = AsyncValue.data(workout);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> resumeWorkout(String workoutId) async {
    try {
      final workout = await _workoutService.resumeWorkout(workoutId);
      state = AsyncValue.data(workout);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearWorkout() {
    state = const AsyncValue.data(null);
  }
}

// Workout State Provider
final workoutNotifierProvider = StateNotifierProvider<WorkoutNotifier, AsyncValue<Workout?>>((ref) {
  final workoutService = ref.read(workoutServiceProvider);
  return WorkoutNotifier(workoutService);
});

// State Notifier for Workout Session Management
class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionNotifier(this._workoutService) : super(const WorkoutSessionState.idle());

  final WorkoutService _workoutService;

  Future<void> startSession(String workoutId) async {
    state = const WorkoutSessionState.loading();

    try {
      final workoutWithExercises = await _workoutService.getWorkoutWithExercises(workoutId);
      if (workoutWithExercises == null) {
        state = const WorkoutSessionState.error('Workout not found');
        return;
      }

      // Start the workout
      await _workoutService.startWorkout(workoutId);

      state = WorkoutSessionState.active(
        workout: workoutWithExercises.workout,
        workoutExercises: workoutWithExercises.workoutExercises,
        exercises: workoutWithExercises.exercises,
        currentExerciseIndex: 0,
        currentSet: 1,
        completedSets: [],
        startTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      logger.e('Failed to start workout session', error: e, stackTrace: stackTrace);
      state = WorkoutSessionState.error(e.toString());
    }
  }

  void nextExercise() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    final nextIndex = currentState.currentExerciseIndex + 1;
    if (nextIndex >= currentState.workoutExercises.length) {
      // Workout completed
      _completeSession();
      return;
    }

    state = currentState.copyWith(
      currentExerciseIndex: nextIndex,
      currentSet: 1,
    );
  }

  void previousExercise() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    final prevIndex = currentState.currentExerciseIndex - 1;
    if (prevIndex < 0) return;

    state = currentState.copyWith(
      currentExerciseIndex: prevIndex,
      currentSet: 1,
    );
  }

  void nextSet() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    final currentWorkoutExercise = currentState.workoutExercises[currentState.currentExerciseIndex];
    final maxSets = currentWorkoutExercise.effectiveSets;

    if (currentState.currentSet >= maxSets) {
      nextExercise();
      return;
    }

    state = currentState.copyWith(
      currentSet: currentState.currentSet + 1,
    );
  }

  void logSet({
    required int reps,
    required double weight,
    String? notes,
  }) {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    final setLog = CompletedSetLog(
      exerciseIndex: currentState.currentExerciseIndex,
      setNumber: currentState.currentSet,
      reps: reps,
      weight: weight,
      notes: notes,
      timestamp: DateTime.now(),
    );

    final updatedCompletedSets = [...currentState.completedSets, setLog];

    state = currentState.copyWith(
      completedSets: updatedCompletedSets,
    );

    // Automatically move to next set
    nextSet();
  }

  void pauseSession() {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    state = WorkoutSessionState.paused(
      workout: currentState.workout,
      workoutExercises: currentState.workoutExercises,
      exercises: currentState.exercises,
      currentExerciseIndex: currentState.currentExerciseIndex,
      currentSet: currentState.currentSet,
      completedSets: currentState.completedSets,
      startTime: currentState.startTime,
      pausedAt: DateTime.now(),
    );
  }

  void resumeSession() {
    final currentState = state;
    if (currentState is! WorkoutSessionPaused) return;

    state = WorkoutSessionState.active(
      workout: currentState.workout,
      workoutExercises: currentState.workoutExercises,
      exercises: currentState.exercises,
      currentExerciseIndex: currentState.currentExerciseIndex,
      currentSet: currentState.currentSet,
      completedSets: currentState.completedSets,
      startTime: currentState.startTime,
    );
  }

  Future<void> _completeSession() async {
    final currentState = state;
    if (currentState is! WorkoutSessionActive) return;

    try {
      // Complete the workout
      await _workoutService.completeWorkout(currentState.workout.id);

      state = WorkoutSessionState.completed(
        workout: currentState.workout,
        workoutExercises: currentState.workoutExercises,
        exercises: currentState.exercises,
        completedSets: currentState.completedSets,
        startTime: currentState.startTime,
        endTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      logger.e('Failed to complete workout session', error: e, stackTrace: stackTrace);
      state = WorkoutSessionState.error(e.toString());
    }
  }

  void endSession() {
    state = const WorkoutSessionState.idle();
  }
}

// Workout Session State Provider
final workoutSessionNotifierProvider = StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>((ref) {
  final workoutService = ref.read(workoutServiceProvider);
  return WorkoutSessionNotifier(workoutService);
});

// Helper classes for provider parameters
class WorkoutFilters {
  final String? userId;
  final bool? isActive;
  final bool? isCompleted;
  final int? limit;
  final int? offset;

  const WorkoutFilters({
    this.userId,
    this.isActive,
    this.isCompleted,
    this.limit,
    this.offset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutFilters &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          isActive == other.isActive &&
          isCompleted == other.isCompleted &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      userId.hashCode ^
      isActive.hashCode ^
      isCompleted.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}

class CompletedWorkoutFilters {
  final String? userId;
  final int? limit;
  final int? offset;

  const CompletedWorkoutFilters({
    this.userId,
    this.limit,
    this.offset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedWorkoutFilters &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => userId.hashCode ^ limit.hashCode ^ offset.hashCode;
}

// Workout Session State Classes
abstract class WorkoutSessionState {
  const WorkoutSessionState();

  const factory WorkoutSessionState.idle() = WorkoutSessionIdle;
  const factory WorkoutSessionState.loading() = WorkoutSessionLoading;
  const factory WorkoutSessionState.active({
    required Workout workout,
    required List<WorkoutExercise> workoutExercises,
    required List<Exercise> exercises,
    required int currentExerciseIndex,
    required int currentSet,
    required List<CompletedSetLog> completedSets,
    required DateTime startTime,
  }) = WorkoutSessionActive;
  const factory WorkoutSessionState.paused({
    required Workout workout,
    required List<WorkoutExercise> workoutExercises,
    required List<Exercise> exercises,
    required int currentExerciseIndex,
    required int currentSet,
    required List<CompletedSetLog> completedSets,
    required DateTime startTime,
    required DateTime pausedAt,
  }) = WorkoutSessionPaused;
  const factory WorkoutSessionState.completed({
    required Workout workout,
    required List<WorkoutExercise> workoutExercises,
    required List<Exercise> exercises,
    required List<CompletedSetLog> completedSets,
    required DateTime startTime,
    required DateTime endTime,
  }) = WorkoutSessionCompleted;
  const factory WorkoutSessionState.error(String message) = WorkoutSessionError;
}

class WorkoutSessionIdle extends WorkoutSessionState {
  const WorkoutSessionIdle();
}

class WorkoutSessionLoading extends WorkoutSessionState {
  const WorkoutSessionLoading();
}

class WorkoutSessionActive extends WorkoutSessionState {
  final Workout workout;
  final List<WorkoutExercise> workoutExercises;
  final List<Exercise> exercises;
  final int currentExerciseIndex;
  final int currentSet;
  final List<CompletedSetLog> completedSets;
  final DateTime startTime;

  const WorkoutSessionActive({
    required this.workout,
    required this.workoutExercises,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.currentSet,
    required this.completedSets,
    required this.startTime,
  });

  WorkoutExercise get currentWorkoutExercise {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) {
      throw StateError('No exercises available or invalid exercise index');
    }
    return workoutExercises[currentExerciseIndex];
  }
  
  Exercise? get currentExercise => exercises
      .where((e) => e.id == currentWorkoutExercise.exerciseId)
      .firstOrNull;

  Duration get elapsedTime => DateTime.now().difference(startTime);
  
  double get progressPercentage {
    final totalSets = workoutExercises.fold<int>(0, (sum, we) => sum + we.effectiveSets);
    return totalSets > 0 ? completedSets.length / totalSets : 0.0;
  }

  WorkoutSessionActive copyWith({
    Workout? workout,
    List<WorkoutExercise>? workoutExercises,
    List<Exercise>? exercises,
    int? currentExerciseIndex,
    int? currentSet,
    List<CompletedSetLog>? completedSets,
    DateTime? startTime,
  }) {
    return WorkoutSessionActive(
      workout: workout ?? this.workout,
      workoutExercises: workoutExercises ?? this.workoutExercises,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSet: currentSet ?? this.currentSet,
      completedSets: completedSets ?? this.completedSets,
      startTime: startTime ?? this.startTime,
    );
  }
}

class WorkoutSessionPaused extends WorkoutSessionState {
  final Workout workout;
  final List<WorkoutExercise> workoutExercises;
  final List<Exercise> exercises;
  final int currentExerciseIndex;
  final int currentSet;
  final List<CompletedSetLog> completedSets;
  final DateTime startTime;
  final DateTime pausedAt;

  const WorkoutSessionPaused({
    required this.workout,
    required this.workoutExercises,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.currentSet,
    required this.completedSets,
    required this.startTime,
    required this.pausedAt,
  });

  Duration get elapsedTime => pausedAt.difference(startTime);
}

class WorkoutSessionCompleted extends WorkoutSessionState {
  final Workout workout;
  final List<WorkoutExercise> workoutExercises;
  final List<Exercise> exercises;
  final List<CompletedSetLog> completedSets;
  final DateTime startTime;
  final DateTime endTime;

  const WorkoutSessionCompleted({
    required this.workout,
    required this.workoutExercises,
    required this.exercises,
    required this.completedSets,
    required this.startTime,
    required this.endTime,
  });

  Duration get totalDuration => endTime.difference(startTime);
  
  int get totalSetsCompleted => completedSets.length;
  
  double get totalVolumeLifted => completedSets.fold<double>(
    0.0,
    (sum, set) => sum + (set.reps * set.weight),
  );
}

class WorkoutSessionError extends WorkoutSessionState {
  final String message;

  const WorkoutSessionError(this.message);
}

// Completed Set Log for session tracking
class CompletedSetLog {
  final int exerciseIndex;
  final int setNumber;
  final int reps;
  final double weight;
  final String? notes;
  final DateTime timestamp;

  const CompletedSetLog({
    required this.exerciseIndex,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.notes,
    required this.timestamp,
  });
}