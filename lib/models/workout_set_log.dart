import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'workout_set_log.g.dart';

@JsonSerializable()
@HiveType(typeId: 34)
class WorkoutSetLog extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'workout_log_id')
  final String workoutLogId;
  
  @HiveField(2)
  @JsonKey(name: 'exercise_id')
  final String exerciseId;
  
  @HiveField(3)
  @JsonKey(name: 'set_number')
  final int setNumber;
  
  @HiveField(4)
  @JsonKey(name: 'reps_completed')
  final int repsCompleted;
  
  @HiveField(5)
  final double? weight;
  
  @HiveField(6)
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  
  @HiveField(7)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  WorkoutSetLog({
    required this.id,
    required this.workoutLogId,
    required this.exerciseId,
    required this.setNumber,
    required this.repsCompleted,
    this.weight,
    required this.completedAt,
    required this.createdAt,
  });

  factory WorkoutSetLog.fromJson(Map<String, dynamic> json) => 
      _$WorkoutSetLogFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutSetLogToJson(this);

  WorkoutSetLog copyWith({
    String? id,
    String? workoutLogId,
    String? exerciseId,
    int? setNumber,
    int? repsCompleted,
    double? weight,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return WorkoutSetLog(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      weight: weight ?? this.weight,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSetLog &&
        other.id == id &&
        other.workoutLogId == workoutLogId &&
        other.exerciseId == exerciseId &&
        other.setNumber == setNumber &&
        other.repsCompleted == repsCompleted &&
        other.weight == weight &&
        other.completedAt == completedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      workoutLogId,
      exerciseId,
      setNumber,
      repsCompleted,
      weight,
      completedAt,
      createdAt,
    );
  }

  // Validation methods
  bool get isValid => 
      id.isNotEmpty && 
      workoutLogId.isNotEmpty && 
      exerciseId.isNotEmpty &&
      setNumber > 0 &&
      repsCompleted > 0;

  bool get hasWeight => weight != null && weight! > 0;

  // Performance metrics
  double get volume => hasWeight 
      ? weight! * repsCompleted
      : repsCompleted.toDouble();

  // Time-based analysis
  bool get isToday {
    final now = DateTime.now();
    return completedAt.year == now.year && 
           completedAt.month == now.month && 
           completedAt.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return completedAt.isAfter(weekStart);
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return completedAt.year == now.year && completedAt.month == now.month;
  }

  // Formatting helpers
  String get formattedWeight => hasWeight ? '${weight!.toStringAsFixed(1)}kg' : 'Bodyweight';
  
  String get formattedReps => '$repsCompleted reps';
  
  String get formattedVolume => hasWeight 
      ? '${volume.toStringAsFixed(1)}kg' 
      : '$repsCompleted reps';

  // Comparison methods
  int comparePerformance(WorkoutSetLog other) {
    // Compare by volume first
    final volumeComparison = volume.compareTo(other.volume);
    if (volumeComparison != 0) return volumeComparison;
    
    // If volume is equal, compare by reps
    final repsComparison = repsCompleted.compareTo(other.repsCompleted);
    if (repsComparison != 0) return repsComparison;
    
    // Finally compare by weight
    return (weight ?? 0).compareTo(other.weight ?? 0);
  }

  bool isBetterThan(WorkoutSetLog other) => comparePerformance(other) > 0;

  int compareTo(WorkoutSetLog other) {
    return completedAt.compareTo(other.completedAt);
  }

  bool isNewerThan(WorkoutSetLog other) => compareTo(other) > 0;
  
  bool isOlderThan(WorkoutSetLog other) => compareTo(other) < 0;
}