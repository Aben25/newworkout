import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'workout.g.dart';

@JsonSerializable()
@HiveType(typeId: 7)
class Workout extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String? userId;
  
  @HiveField(2)
  final String? name;
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  
  @HiveField(5)
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  
  @HiveField(6)
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @HiveField(7)
  @JsonKey(name: 'is_completed')
  final bool? isCompleted;
  
  @HiveField(8)
  @JsonKey(name: 'is_minimized')
  final bool? isMinimized;
  
  @HiveField(9)
  final int? rating;
  
  @HiveField(10)
  final String? notes;
  
  @HiveField(11)
  @JsonKey(name: 'ai_description')
  final String? aiDescription;
  
  @HiveField(12)
  @JsonKey(name: 'session_order')
  final int? sessionOrder;
  
  @HiveField(13)
  @JsonKey(name: 'last_state')
  final Map<String, dynamic>? lastState;
  
  @HiveField(14)
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @HiveField(15)
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Workout({
    required this.id,
    this.userId,
    this.name,
    this.description,
    this.startTime,
    this.endTime,
    this.isActive = false,
    this.isCompleted,
    this.isMinimized,
    this.rating,
    this.notes,
    this.aiDescription,
    this.sessionOrder,
    this.lastState,
    this.createdAt,
    this.updatedAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => _$WorkoutFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutToJson(this);

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    bool? isCompleted,
    bool? isMinimized,
    int? rating,
    String? notes,
    String? aiDescription,
    int? sessionOrder,
    Map<String, dynamic>? lastState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      isMinimized: isMinimized ?? this.isMinimized,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      aiDescription: aiDescription ?? this.aiDescription,
      sessionOrder: sessionOrder ?? this.sessionOrder,
      lastState: lastState ?? this.lastState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workout &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.description == description &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.isActive == isActive &&
        other.isCompleted == isCompleted &&
        other.isMinimized == isMinimized &&
        other.rating == rating &&
        other.notes == notes &&
        other.aiDescription == aiDescription &&
        other.sessionOrder == sessionOrder &&
        _mapEquals(other.lastState, lastState) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      description,
      startTime,
      endTime,
      isActive,
      isCompleted,
      isMinimized,
      rating,
      notes,
      aiDescription,
      sessionOrder,
      lastState,
      createdAt,
      updatedAt,
    );
  }

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  // Validation methods
  bool get isValid => id.isNotEmpty && userId != null;
  
  bool get hasName => name != null && name!.isNotEmpty;
  
  bool get hasDescription => description != null && description!.isNotEmpty;
  
  bool get hasRating => rating != null && rating! >= 1 && rating! <= 5;
  
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  // Status checks
  bool get isInProgress => isActive && (isCompleted != true);
  
  bool get isFinished => isCompleted == true || (!isActive && endTime != null);
  
  bool get isPaused => !isActive && startTime != null && endTime == null && (isCompleted != true);
  
  bool get canResume => isPaused || (isActive && lastState != null);

  // Duration calculations
  Duration? get duration {
    if (startTime == null) return null;
    final end = endTime ?? (isActive ? DateTime.now() : null);
    if (end == null) return null;
    return end.difference(startTime!);
  }

  int? get durationInMinutes => duration?.inMinutes;
  
  int? get durationInSeconds => duration?.inSeconds;

  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'Not started';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    final seconds = dur.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // State management
  WorkoutState? get workoutState {
    if (lastState == null) return null;
    try {
      return WorkoutState.fromJson(lastState!);
    } catch (e) {
      return null;
    }
  }

  bool get hasState => lastState != null && lastState!.isNotEmpty;

  // Progress tracking
  double get completionPercentage {
    final state = workoutState;
    if (state == null) return 0.0;
    
    final totalExercises = state.totalExercises;
    if (totalExercises == 0) return 0.0;
    
    return state.completedExercises.length / totalExercises;
  }

  // Rating helpers
  String get formattedRating {
    if (!hasRating) return 'Not rated';
    return '${'⭐' * rating!}${'☆' * (5 - rating!)}';
  }

  double get ratingScore => (rating ?? 0) / 5.0;
  
  bool get isHighRated => rating != null && rating! >= 4;
  
  bool get isLowRated => rating != null && rating! <= 2;

  // Time-based helpers
  bool get isToday {
    if (startTime == null) return false;
    final now = DateTime.now();
    return startTime!.year == now.year && 
           startTime!.month == now.month && 
           startTime!.day == now.day;
  }

  bool get isThisWeek {
    if (startTime == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return startTime!.isAfter(weekStart);
  }

  // Comparison methods
  int compareTo(Workout other) {
    final thisTime = startTime ?? createdAt ?? DateTime.now();
    final otherTime = other.startTime ?? other.createdAt ?? DateTime.now();
    return thisTime.compareTo(otherTime);
  }

  bool isNewerThan(Workout other) => compareTo(other) > 0;
  
  bool isOlderThan(Workout other) => compareTo(other) < 0;
}

@JsonSerializable()
@HiveType(typeId: 8)
class WorkoutState extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'current_exercise_index')
  final int currentExerciseIndex;
  
  @HiveField(1)
  @JsonKey(name: 'current_set')
  final int currentSet;
  
  @HiveField(2)
  @JsonKey(name: 'completed_exercises')
  final List<String> completedExercises;
  
  @HiveField(3)
  @JsonKey(name: 'exercise_logs')
  final List<ExerciseLog> exerciseLogs;
  
  @HiveField(4)
  @JsonKey(name: 'total_exercises')
  final int totalExercises;
  
  @HiveField(5)
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  
  @HiveField(6)
  @JsonKey(name: 'last_updated')
  final DateTime lastUpdated;

  WorkoutState({
    required this.currentExerciseIndex,
    required this.currentSet,
    required this.completedExercises,
    required this.exerciseLogs,
    this.totalExercises = 0,
    this.startTime,
    required this.lastUpdated,
  });

  factory WorkoutState.fromJson(Map<String, dynamic> json) => 
      _$WorkoutStateFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutStateToJson(this);

  WorkoutState copyWith({
    int? currentExerciseIndex,
    int? currentSet,
    List<String>? completedExercises,
    List<ExerciseLog>? exerciseLogs,
    int? totalExercises,
    DateTime? startTime,
    DateTime? lastUpdated,
  }) {
    return WorkoutState(
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSet: currentSet ?? this.currentSet,
      completedExercises: completedExercises ?? this.completedExercises,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      totalExercises: totalExercises ?? this.totalExercises,
      startTime: startTime ?? this.startTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Progress calculations
  double get progressPercentage {
    if (totalExercises == 0) return 0.0;
    return completedExercises.length / totalExercises;
  }

  bool get isComplete => completedExercises.length >= totalExercises;
  
  bool get hasStarted => currentExerciseIndex > 0 || exerciseLogs.isNotEmpty;

  // Current state helpers
  bool get isOnLastExercise => currentExerciseIndex >= totalExercises - 1;
  
  int get remainingExercises => totalExercises - completedExercises.length;

  // Exercise log helpers
  ExerciseLog? getLogForExercise(String exerciseId) {
    try {
      return exerciseLogs.firstWhere((log) => log.exerciseId == exerciseId);
    } catch (e) {
      return null;
    }
  }

  bool hasLogForExercise(String exerciseId) => 
      exerciseLogs.any((log) => log.exerciseId == exerciseId);

  List<ExerciseLog> get completedLogs => 
      exerciseLogs.where((log) => log.isComplete).toList();

  // Time tracking
  Duration? get totalDuration {
    if (startTime == null) return null;
    return lastUpdated.difference(startTime!);
  }

  bool get isRecent => DateTime.now().difference(lastUpdated).inMinutes < 30;
}

@JsonSerializable()
@HiveType(typeId: 9)
class ExerciseLog extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'exercise_id')
  final String exerciseId;
  
  @HiveField(1)
  final List<SetLog> sets;
  
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

  ExerciseLog({
    required this.exerciseId,
    required this.sets,
    this.notes,
    this.difficultyRating,
    this.startTime,
    this.endTime,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => 
      _$ExerciseLogFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseLogToJson(this);

  ExerciseLog copyWith({
    String? exerciseId,
    List<SetLog>? sets,
    String? notes,
    String? difficultyRating,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  // Completion status
  bool get isComplete => sets.isNotEmpty && sets.every((set) => set.completed);
  
  bool get hasStarted => sets.isNotEmpty;
  
  bool get isInProgress => hasStarted && !isComplete;

  // Performance metrics
  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);
  
  double get totalVolume => sets.fold(0.0, (sum, set) => sum + set.volume);
  
  int get completedSets => sets.where((set) => set.completed).length;

  // Duration tracking
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  // Set management
  SetLog? get currentSet => sets.isEmpty ? null : sets.last;
  
  bool get canAddSet => sets.isEmpty || sets.last.completed;

  ExerciseLog addSet(SetLog newSet) {
    return copyWith(sets: [...sets, newSet]);
  }

  ExerciseLog updateSet(int index, SetLog updatedSet) {
    if (index < 0 || index >= sets.length) return this;
    final newSets = List<SetLog>.from(sets);
    newSets[index] = updatedSet;
    return copyWith(sets: newSets);
  }
}

@JsonSerializable()
@HiveType(typeId: 33)
class SetLog extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'set_number')
  final int setNumber;
  
  @HiveField(1)
  final int reps;
  
  @HiveField(2)
  final double? weight;
  
  @HiveField(3)
  final bool completed;
  
  @HiveField(4)
  @JsonKey(name: 'rest_duration')
  final int? restDuration;
  
  @HiveField(5)
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  
  @HiveField(6)
  @JsonKey(name: 'end_time')
  final DateTime? endTime;

  SetLog({
    required this.setNumber,
    required this.reps,
    this.weight,
    required this.completed,
    this.restDuration,
    this.startTime,
    this.endTime,
  });

  factory SetLog.fromJson(Map<String, dynamic> json) => _$SetLogFromJson(json);

  Map<String, dynamic> toJson() => _$SetLogToJson(this);

  SetLog copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    bool? completed,
    int? restDuration,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return SetLog(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completed: completed ?? this.completed,
      restDuration: restDuration ?? this.restDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  // Performance calculations
  double get volume => (weight ?? 0) * reps;
  
  bool get hasWeight => weight != null && weight! > 0;

  // Duration tracking
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  Duration get restDurationObj => Duration(seconds: restDuration ?? 60);

  // Formatting helpers
  String get formattedWeight => hasWeight ? '${weight!.toStringAsFixed(1)}kg' : 'Bodyweight';
  
  String get formattedReps => '$reps reps';
  
  String get formattedVolume => hasWeight ? '${volume.toStringAsFixed(1)}kg' : '$reps reps';

  // Validation
  bool get isValid => reps > 0 && setNumber > 0;
}