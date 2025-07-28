import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'workout_exercise.g.dart';

@JsonSerializable()
@HiveType(typeId: 2)
class WorkoutExercise extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'workout_id')
  final String workoutId;
  
  @HiveField(2)
  @JsonKey(name: 'exercise_id')
  final String exerciseId;
  
  @HiveField(3)
  final String name;
  
  @HiveField(4)
  final int? sets;
  
  @HiveField(5)
  @JsonKey(name: 'order_index')
  final int? orderIndex;
  
  @HiveField(6)
  final int? order;
  
  @HiveField(7)
  final bool completed;
  
  @HiveField(8)
  @JsonKey(name: 'rest_interval')
  final int? restInterval;
  
  @HiveField(9)
  final List<int>? weight;
  
  @HiveField(10)
  final List<int>? reps;
  
  @HiveField(11)
  @JsonKey(name: 'reps_old')
  final List<int>? repsOld;
  
  @HiveField(12)
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.name,
    this.sets,
    this.orderIndex,
    this.order,
    this.completed = false,
    this.restInterval,
    this.weight,
    this.reps,
    this.repsOld,
    this.createdAt,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => 
      _$WorkoutExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutExerciseToJson(this);

  WorkoutExercise copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    String? name,
    int? sets,
    int? orderIndex,
    int? order,
    bool? completed,
    int? restInterval,
    List<int>? weight,
    List<int>? reps,
    List<int>? repsOld,
    DateTime? createdAt,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      orderIndex: orderIndex ?? this.orderIndex,
      order: order ?? this.order,
      completed: completed ?? this.completed,
      restInterval: restInterval ?? this.restInterval,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      repsOld: repsOld ?? this.repsOld,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutExercise &&
        other.id == id &&
        other.workoutId == workoutId &&
        other.exerciseId == exerciseId &&
        other.name == name &&
        other.sets == sets &&
        other.orderIndex == orderIndex &&
        other.order == order &&
        other.completed == completed &&
        other.restInterval == restInterval &&
        _listEquals(other.weight, weight) &&
        _listEquals(other.reps, reps) &&
        _listEquals(other.repsOld, repsOld) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      workoutId,
      exerciseId,
      name,
      sets,
      orderIndex,
      order,
      completed,
      restInterval,
      Object.hashAll(weight ?? []),
      Object.hashAll(reps ?? []),
      Object.hashAll(repsOld ?? []),
      createdAt,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  // Validation methods
  bool get isValid => 
      id.isNotEmpty && 
      workoutId.isNotEmpty && 
      exerciseId.isNotEmpty && 
      name.isNotEmpty;

  bool get hasWeightData => weight != null && weight!.isNotEmpty;
  
  bool get hasRepsData => reps != null && reps!.isNotEmpty;
  
  bool get isConfigured => sets != null && sets! > 0;

  // Helper methods
  int get effectiveSets => sets ?? (reps?.length ?? 0);
  
  int get effectiveOrder => order ?? orderIndex ?? 0;
  
  Duration get restDuration => Duration(seconds: restInterval ?? 60);

  // Progress tracking
  bool get hasProgressData => repsOld != null && repsOld!.isNotEmpty;
  
  double? get averageWeight {
    if (!hasWeightData) return null;
    return weight!.reduce((a, b) => a + b) / weight!.length;
  }
  
  double? get averageReps {
    if (!hasRepsData) return null;
    return reps!.reduce((a, b) => a + b) / reps!.length;
  }

  // Volume calculation (sets × reps × weight)
  double get totalVolume {
    if (!hasWeightData || !hasRepsData) return 0.0;
    
    double volume = 0.0;
    final minLength = weight!.length < reps!.length ? weight!.length : reps!.length;
    
    for (int i = 0; i < minLength; i++) {
      volume += weight![i] * reps![i];
    }
    
    return volume;
  }

  // Comparison with previous performance
  Map<String, dynamic> getProgressComparison() {
    if (!hasProgressData || !hasRepsData) {
      return {'hasProgress': false};
    }

    final currentTotal = reps!.reduce((a, b) => a + b);
    final previousTotal = repsOld!.reduce((a, b) => a + b);
    final improvement = currentTotal - previousTotal;
    final improvementPercentage = previousTotal > 0 
        ? (improvement / previousTotal) * 100 
        : 0.0;

    return {
      'hasProgress': true,
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
      'improvement': improvement,
      'improvementPercentage': improvementPercentage,
      'isImprovement': improvement > 0,
    };
  }
}