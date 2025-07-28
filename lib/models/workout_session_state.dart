import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'models.dart';

part 'workout_session_state.g.dart';

/// Comprehensive workout session state management
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
    required List<ExerciseLogSession> exerciseLogs,
    required DateTime startTime,
    required DateTime lastSyncTime,
    required bool isRestTimerActive,
    required int restTimeRemaining,
  }) = WorkoutSessionActive;
  const factory WorkoutSessionState.paused({
    required Workout workout,
    required List<WorkoutExercise> workoutExercises,
    required List<Exercise> exercises,
    required int currentExerciseIndex,
    required int currentSet,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
    required DateTime startTime,
    required DateTime pausedAt,
  }) = WorkoutSessionPaused;
  const factory WorkoutSessionState.completed({
    required Workout workout,
    required List<WorkoutExercise> workoutExercises,
    required List<Exercise> exercises,
    required List<CompletedSetLog> completedSets,
    required List<ExerciseLogSession> exerciseLogs,
    required DateTime startTime,
    required DateTime endTime,
    int? rating,
    String? notes,
  }) = WorkoutSessionCompleted;
  const factory WorkoutSessionState.error(String message) = WorkoutSessionError;

  /// Helper method to handle state pattern matching
  T when<T>({
    required T Function() idle,
    required T Function() loading,
    required T Function(
      Workout workout,
      List<WorkoutExercise> workoutExercises,
      List<Exercise> exercises,
      int currentExerciseIndex,
      int currentSet,
      List<CompletedSetLog> completedSets,
      List<ExerciseLogSession> exerciseLogs,
      DateTime startTime,
      DateTime lastSyncTime,
      bool isRestTimerActive,
      int restTimeRemaining,
    ) active,
    required T Function(
      Workout workout,
      List<WorkoutExercise> workoutExercises,
      List<Exercise> exercises,
      int currentExerciseIndex,
      int currentSet,
      List<CompletedSetLog> completedSets,
      List<ExerciseLogSession> exerciseLogs,
      DateTime startTime,
      DateTime pausedAt,
    ) paused,
    required T Function(
      Workout workout,
      List<WorkoutExercise> workoutExercises,
      List<Exercise> exercises,
      List<CompletedSetLog> completedSets,
      List<ExerciseLogSession> exerciseLogs,
      DateTime startTime,
      DateTime endTime,
      int? rating,
      String? notes,
    ) completed,
    required T Function(String message) error,
  }) {
    if (this is WorkoutSessionIdle) {
      return idle();
    } else if (this is WorkoutSessionLoading) {
      return loading();
    } else if (this is WorkoutSessionActive) {
      final state = this as WorkoutSessionActive;
      return active(
        state.workout,
        state.workoutExercises,
        state.exercises,
        state.currentExerciseIndex,
        state.currentSet,
        state.completedSets,
        state.exerciseLogs,
        state.startTime,
        state.lastSyncTime,
        state.isRestTimerActive,
        state.restTimeRemaining,
      );
    } else if (this is WorkoutSessionPaused) {
      final state = this as WorkoutSessionPaused;
      return paused(
        state.workout,
        state.workoutExercises,
        state.exercises,
        state.currentExerciseIndex,
        state.currentSet,
        state.completedSets,
        state.exerciseLogs,
        state.startTime,
        state.pausedAt,
      );
    } else if (this is WorkoutSessionCompleted) {
      final state = this as WorkoutSessionCompleted;
      return completed(
        state.workout,
        state.workoutExercises,
        state.exercises,
        state.completedSets,
        state.exerciseLogs,
        state.startTime,
        state.endTime,
        state.rating,
        state.notes,
      );
    } else if (this is WorkoutSessionError) {
      final state = this as WorkoutSessionError;
      return error(state.message);
    }
    throw StateError('Unknown WorkoutSessionState: $runtimeType');
  }

  /// Helper method for optional pattern matching
  T maybeWhen<T>({
    T Function()? idle,
    T Function()? loading,
    T Function(
      Workout workout,
      List<WorkoutExercise> workoutExercises,
      List<Exercise> exercises,
      int currentExerciseIndex,
      int currentSet,
      List<CompletedSetLog> completedSets,
      List<ExerciseLogSession> exerciseLogs,
      DateTime startTime,
      DateTime lastSyncTime,
      bool isRestTimerActive,
      int restTimeRemaining,
    )? active,
    T Function(
      Workout workout,
      List<WorkoutExercise> workoutExercises,
      List<Exercise> exercises,
      int currentExerciseIndex,
      int currentSet,
      List<CompletedSetLog> completedSets,
      List<ExerciseLogSession> exerciseLogs,
      DateTime startTime,
      DateTime pausedAt,
    )? paused,
    T Function(
      Workout workout,
      List<WorkoutExercise> workoutExercises,
      List<Exercise> exercises,
      List<CompletedSetLog> completedSets,
      List<ExerciseLogSession> exerciseLogs,
      DateTime startTime,
      DateTime endTime,
      int? rating,
      String? notes,
    )? completed,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is WorkoutSessionIdle && idle != null) {
      return idle();
    } else if (this is WorkoutSessionLoading && loading != null) {
      return loading();
    } else if (this is WorkoutSessionActive && active != null) {
      final state = this as WorkoutSessionActive;
      return active(
        state.workout,
        state.workoutExercises,
        state.exercises,
        state.currentExerciseIndex,
        state.currentSet,
        state.completedSets,
        state.exerciseLogs,
        state.startTime,
        state.lastSyncTime,
        state.isRestTimerActive,
        state.restTimeRemaining,
      );
    } else if (this is WorkoutSessionPaused && paused != null) {
      final state = this as WorkoutSessionPaused;
      return paused(
        state.workout,
        state.workoutExercises,
        state.exercises,
        state.currentExerciseIndex,
        state.currentSet,
        state.completedSets,
        state.exerciseLogs,
        state.startTime,
        state.pausedAt,
      );
    } else if (this is WorkoutSessionCompleted && completed != null) {
      final state = this as WorkoutSessionCompleted;
      return completed(
        state.workout,
        state.workoutExercises,
        state.exercises,
        state.completedSets,
        state.exerciseLogs,
        state.startTime,
        state.endTime,
        state.rating,
        state.notes,
      );
    } else if (this is WorkoutSessionError && error != null) {
      final state = this as WorkoutSessionError;
      return error(state.message);
    }
    return orElse();
  }
}

/// Idle state - no active workout session
class WorkoutSessionIdle extends WorkoutSessionState {
  const WorkoutSessionIdle();

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkoutSessionIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loading state - session is being initialized
class WorkoutSessionLoading extends WorkoutSessionState {
  const WorkoutSessionLoading();

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkoutSessionLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Active workout session state
class WorkoutSessionActive extends WorkoutSessionState {
  final Workout workout;
  final List<WorkoutExercise> workoutExercises;
  final List<Exercise> exercises;
  final int currentExerciseIndex;
  final int currentSet;
  final List<CompletedSetLog> completedSets;
  final List<ExerciseLogSession> exerciseLogs;
  final DateTime startTime;
  final DateTime lastSyncTime;
  final bool isRestTimerActive;
  final int restTimeRemaining;

  const WorkoutSessionActive({
    required this.workout,
    required this.workoutExercises,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.currentSet,
    required this.completedSets,
    required this.exerciseLogs,
    required this.startTime,
    required this.lastSyncTime,
    required this.isRestTimerActive,
    required this.restTimeRemaining,
  });

  /// Get current workout exercise
  WorkoutExercise get currentWorkoutExercise {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) {
      throw StateError('No exercises available or invalid exercise index');
    }
    return workoutExercises[currentExerciseIndex];
  }
  
  /// Get current exercise details
  Exercise? get currentExercise => exercises
      .where((e) => e.id == currentWorkoutExercise.exerciseId)
      .firstOrNull;

  /// Get elapsed time since workout started
  Duration get elapsedTime => DateTime.now().difference(startTime);
  
  /// Get workout progress percentage
  double get progressPercentage {
    final totalSets = workoutExercises.fold<int>(0, (sum, we) => sum + we.effectiveSets);
    return totalSets > 0 ? completedSets.length / totalSets : 0.0;
  }

  /// Get exercise progress percentage
  double get exerciseProgressPercentage {
    final currentExerciseSets = currentWorkoutExercise.effectiveSets;
    final completedSetsForExercise = completedSets
        .where((set) => set.exerciseIndex == currentExerciseIndex)
        .length;
    return currentExerciseSets > 0 ? completedSetsForExercise / currentExerciseSets : 0.0;
  }

  /// Check if current exercise is completed
  bool get isCurrentExerciseCompleted {
    final completedSetsForExercise = completedSets
        .where((set) => set.exerciseIndex == currentExerciseIndex)
        .length;
    return completedSetsForExercise >= currentWorkoutExercise.effectiveSets;
  }

  /// Check if workout is completed
  bool get isWorkoutCompleted => currentExerciseIndex >= workoutExercises.length;

  /// Get remaining exercises count
  int get remainingExercises => workoutExercises.length - currentExerciseIndex;

  /// Get remaining sets for current exercise
  int get remainingSetsForCurrentExercise {
    final completedSetsForExercise = completedSets
        .where((set) => set.exerciseIndex == currentExerciseIndex)
        .length;
    return (currentWorkoutExercise.effectiveSets - completedSetsForExercise).clamp(0, double.infinity).toInt();
  }

  /// Get total volume lifted so far
  double get totalVolumeLifted => completedSets.fold<double>(
    0.0,
    (sum, set) => sum + (set.reps * set.weight),
  );

  /// Get total reps completed
  int get totalRepsCompleted => completedSets.fold<int>(0, (sum, set) => sum + set.reps);

  /// Check if session needs sync
  bool get needsSync => DateTime.now().difference(lastSyncTime).inMinutes > 1;

  /// Check if workout is minimized
  bool get isMinimized => workout.isMinimized == true;

  /// Get formatted rest time remaining
  String get formattedRestTime {
    final minutes = restTimeRemaining ~/ 60;
    final seconds = restTimeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Copy with method for state updates
  WorkoutSessionActive copyWith({
    Workout? workout,
    List<WorkoutExercise>? workoutExercises,
    List<Exercise>? exercises,
    int? currentExerciseIndex,
    int? currentSet,
    List<CompletedSetLog>? completedSets,
    List<ExerciseLogSession>? exerciseLogs,
    DateTime? startTime,
    DateTime? lastSyncTime,
    bool? isRestTimerActive,
    int? restTimeRemaining,
  }) {
    return WorkoutSessionActive(
      workout: workout ?? this.workout,
      workoutExercises: workoutExercises ?? this.workoutExercises,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSet: currentSet ?? this.currentSet,
      completedSets: completedSets ?? this.completedSets,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      startTime: startTime ?? this.startTime,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isRestTimerActive: isRestTimerActive ?? this.isRestTimerActive,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionActive &&
          runtimeType == other.runtimeType &&
          workout == other.workout &&
          currentExerciseIndex == other.currentExerciseIndex &&
          currentSet == other.currentSet &&
          completedSets.length == other.completedSets.length &&
          exerciseLogs.length == other.exerciseLogs.length &&
          startTime == other.startTime &&
          isRestTimerActive == other.isRestTimerActive &&
          restTimeRemaining == other.restTimeRemaining;

  @override
  int get hashCode => Object.hash(
        workout.id,
        currentExerciseIndex,
        currentSet,
        completedSets.length,
        exerciseLogs.length,
        startTime,
        isRestTimerActive,
        restTimeRemaining,
      );
}

/// Paused workout session state
class WorkoutSessionPaused extends WorkoutSessionState {
  final Workout workout;
  final List<WorkoutExercise> workoutExercises;
  final List<Exercise> exercises;
  final int currentExerciseIndex;
  final int currentSet;
  final List<CompletedSetLog> completedSets;
  final List<ExerciseLogSession> exerciseLogs;
  final DateTime startTime;
  final DateTime pausedAt;

  const WorkoutSessionPaused({
    required this.workout,
    required this.workoutExercises,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.currentSet,
    required this.completedSets,
    required this.exerciseLogs,
    required this.startTime,
    required this.pausedAt,
  });

  /// Get elapsed time when paused
  Duration get elapsedTime => pausedAt.difference(startTime);

  /// Get pause duration
  Duration get pauseDuration => DateTime.now().difference(pausedAt);

  /// Get workout progress percentage
  double get progressPercentage {
    final totalSets = workoutExercises.fold<int>(0, (sum, we) => sum + we.effectiveSets);
    return totalSets > 0 ? completedSets.length / totalSets : 0.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionPaused &&
          runtimeType == other.runtimeType &&
          workout == other.workout &&
          currentExerciseIndex == other.currentExerciseIndex &&
          currentSet == other.currentSet &&
          pausedAt == other.pausedAt;

  @override
  int get hashCode => Object.hash(
        workout.id,
        currentExerciseIndex,
        currentSet,
        pausedAt,
      );
}

/// Completed workout session state
class WorkoutSessionCompleted extends WorkoutSessionState {
  final Workout workout;
  final List<WorkoutExercise> workoutExercises;
  final List<Exercise> exercises;
  final List<CompletedSetLog> completedSets;
  final List<ExerciseLogSession> exerciseLogs;
  final DateTime startTime;
  final DateTime endTime;
  final int? rating;
  final String? notes;

  const WorkoutSessionCompleted({
    required this.workout,
    required this.workoutExercises,
    required this.exercises,
    required this.completedSets,
    required this.exerciseLogs,
    required this.startTime,
    required this.endTime,
    this.rating,
    this.notes,
  });

  /// Get total workout duration
  Duration get totalDuration => endTime.difference(startTime);
  
  /// Get total sets completed
  int get totalSetsCompleted => completedSets.length;
  
  /// Get total volume lifted
  double get totalVolumeLifted => completedSets.fold<double>(
    0.0,
    (sum, set) => sum + (set.reps * set.weight),
  );

  /// Get total reps completed
  int get totalRepsCompleted => completedSets.fold<int>(0, (sum, set) => sum + set.reps);

  /// Get exercises completed count
  int get exercisesCompleted => exerciseLogs.length;

  /// Get completion percentage
  double get completionPercentage {
    return workoutExercises.isNotEmpty 
        ? (exercisesCompleted / workoutExercises.length * 100).clamp(0, 100)
        : 0.0;
  }

  /// Check if workout was fully completed
  bool get isFullyCompleted => exercisesCompleted >= workoutExercises.length;

  /// Get average set difficulty rating
  double? get averageDifficultyRating {
    final ratingsWithValues = completedSets
        .where((set) => set.difficultyRating != null)
        .map((set) => _parseDifficultyRating(set.difficultyRating!))
        .where((rating) => rating != null)
        .cast<double>()
        .toList();

    if (ratingsWithValues.isEmpty) return null;
    
    return ratingsWithValues.reduce((a, b) => a + b) / ratingsWithValues.length;
  }

  /// Parse difficulty rating string to numeric value
  double? _parseDifficultyRating(String rating) {
    switch (rating.toLowerCase()) {
      case 'very_easy':
        return 1.0;
      case 'easy':
        return 2.0;
      case 'moderate':
        return 3.0;
      case 'hard':
        return 4.0;
      case 'very_hard':
        return 5.0;
      default:
        return double.tryParse(rating);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionCompleted &&
          runtimeType == other.runtimeType &&
          workout == other.workout &&
          endTime == other.endTime &&
          rating == other.rating;

  @override
  int get hashCode => Object.hash(workout.id, endTime, rating);
}

/// Error state for workout session
class WorkoutSessionError extends WorkoutSessionState {
  final String message;

  const WorkoutSessionError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Completed set log for session tracking
@JsonSerializable()
@HiveType(typeId: 31)
class CompletedSetLog extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'workout_exercise_id')
  final String workoutExerciseId;
  
  @HiveField(1)
  @JsonKey(name: 'exercise_id')
  final String exerciseId;
  
  @HiveField(2)
  @JsonKey(name: 'exercise_index')
  final int exerciseIndex;
  
  @HiveField(3)
  @JsonKey(name: 'set_number')
  final int setNumber;
  
  @HiveField(4)
  final int reps;
  
  @HiveField(5)
  final double weight;
  
  @HiveField(6)
  final String? notes;
  
  @HiveField(7)
  @JsonKey(name: 'difficulty_rating')
  final String? difficultyRating;
  
  @HiveField(8)
  final DateTime timestamp;

  CompletedSetLog({
    required this.workoutExerciseId,
    required this.exerciseId,
    required this.exerciseIndex,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.notes,
    this.difficultyRating,
    required this.timestamp,
  });

  factory CompletedSetLog.fromJson(Map<String, dynamic> json) => 
      _$CompletedSetLogFromJson(json);

  Map<String, dynamic> toJson() => _$CompletedSetLogToJson(this);

  /// Get volume for this set
  double get volume => reps * weight;

  /// Check if set has weight
  bool get hasWeight => weight > 0;

  /// Get formatted weight
  String get formattedWeight => hasWeight ? '${weight.toStringAsFixed(1)}kg' : 'Bodyweight';
  
  /// Get formatted reps
  String get formattedReps => '$reps reps';
  
  /// Get formatted volume
  String get formattedVolume => hasWeight ? '${volume.toStringAsFixed(1)}kg' : '$reps reps';

  /// Get difficulty rating as numeric value
  double? get difficultyRatingValue {
    if (difficultyRating == null) return null;
    
    switch (difficultyRating!.toLowerCase()) {
      case 'very_easy':
        return 1.0;
      case 'easy':
        return 2.0;
      case 'moderate':
        return 3.0;
      case 'hard':
        return 4.0;
      case 'very_hard':
        return 5.0;
      default:
        return double.tryParse(difficultyRating!);
    }
  }

  CompletedSetLog copyWith({
    String? workoutExerciseId,
    String? exerciseId,
    int? exerciseIndex,
    int? setNumber,
    int? reps,
    double? weight,
    String? notes,
    String? difficultyRating,
    DateTime? timestamp,
  }) {
    return CompletedSetLog(
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedSetLog &&
          runtimeType == other.runtimeType &&
          workoutExerciseId == other.workoutExerciseId &&
          exerciseIndex == other.exerciseIndex &&
          setNumber == other.setNumber &&
          reps == other.reps &&
          weight == other.weight &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        workoutExerciseId,
        exerciseIndex,
        setNumber,
        reps,
        weight,
        timestamp,
      );
}

/// Exercise log for session tracking
@JsonSerializable()
@HiveType(typeId: 32)
class ExerciseLogSession extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'exercise_id')
  final String exerciseId;
  
  @HiveField(1)
  final List<CompletedSetLog> sets;
  
  @HiveField(2)
  final String? notes;
  
  @HiveField(3)
  @JsonKey(name: 'difficulty_rating')
  final String? difficultyRating;
  
  @HiveField(4)
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  
  @HiveField(5)
  @JsonKey(name: 'end_time')
  final DateTime? endTime;

  ExerciseLogSession({
    required this.exerciseId,
    required this.sets,
    this.notes,
    this.difficultyRating,
    this.startTime,
    this.endTime,
  });

  factory ExerciseLogSession.fromJson(Map<String, dynamic> json) => 
      _$ExerciseLogSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseLogSessionToJson(this);

  /// Check if exercise is completed
  bool get isComplete => sets.isNotEmpty;
  
  /// Check if exercise has started
  bool get hasStarted => sets.isNotEmpty;

  /// Get total reps for exercise
  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);
  
  /// Get total volume for exercise
  double get totalVolume => sets.fold(0.0, (sum, set) => sum + set.volume);
  
  /// Get completed sets count
  int get completedSets => sets.length;

  /// Get exercise duration
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  /// Get average difficulty rating
  double? get averageDifficultyRating {
    final ratingsWithValues = sets
        .where((set) => set.difficultyRating != null)
        .map((set) => set.difficultyRatingValue)
        .where((rating) => rating != null)
        .cast<double>()
        .toList();

    if (ratingsWithValues.isEmpty) return null;
    
    return ratingsWithValues.reduce((a, b) => a + b) / ratingsWithValues.length;
  }

  ExerciseLogSession copyWith({
    String? exerciseId,
    List<CompletedSetLog>? sets,
    String? notes,
    String? difficultyRating,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ExerciseLogSession(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseLogSession &&
          runtimeType == other.runtimeType &&
          exerciseId == other.exerciseId &&
          sets.length == other.sets.length;

  @override
  int get hashCode => Object.hash(exerciseId, sets.length);
}