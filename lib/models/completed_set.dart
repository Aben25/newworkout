import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'completed_set.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class CompletedSet extends HiveObject {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  
  @HiveField(2)
  @JsonKey(name: 'workout_exercise_id')
  final String? workoutExerciseId;
  
  @HiveField(3)
  @JsonKey(name: 'performed_set_order')
  final int? performedSetOrder;
  
  @HiveField(4)
  @JsonKey(name: 'performed_reps')
  final int? performedReps;
  
  @HiveField(5)
  @JsonKey(name: 'performed_weight')
  final int? performedWeight;
  
  @HiveField(6)
  @JsonKey(name: 'set_feedback_difficulty')
  final String? setFeedbackDifficulty;
  
  @HiveField(7)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @HiveField(8)
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CompletedSet({
    required this.id,
    this.workoutId,
    this.workoutExerciseId,
    this.performedSetOrder,
    this.performedReps,
    this.performedWeight,
    this.setFeedbackDifficulty,
    required this.createdAt,
    this.updatedAt,
  });

  factory CompletedSet.fromJson(Map<String, dynamic> json) => 
      _$CompletedSetFromJson(json);

  Map<String, dynamic> toJson() => _$CompletedSetToJson(this);

  CompletedSet copyWith({
    int? id,
    String? workoutId,
    String? workoutExerciseId,
    int? performedSetOrder,
    int? performedReps,
    int? performedWeight,
    String? setFeedbackDifficulty,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompletedSet(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      performedSetOrder: performedSetOrder ?? this.performedSetOrder,
      performedReps: performedReps ?? this.performedReps,
      performedWeight: performedWeight ?? this.performedWeight,
      setFeedbackDifficulty: setFeedbackDifficulty ?? this.setFeedbackDifficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompletedSet &&
        other.id == id &&
        other.workoutId == workoutId &&
        other.workoutExerciseId == workoutExerciseId &&
        other.performedSetOrder == performedSetOrder &&
        other.performedReps == performedReps &&
        other.performedWeight == performedWeight &&
        other.setFeedbackDifficulty == setFeedbackDifficulty &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      workoutId,
      workoutExerciseId,
      performedSetOrder,
      performedReps,
      performedWeight,
      setFeedbackDifficulty,
      createdAt,
      updatedAt,
    );
  }

  // Validation methods
  bool get isValid => 
      workoutId != null && 
      workoutExerciseId != null && 
      performedReps != null && 
      performedReps! > 0;

  bool get hasWeight => performedWeight != null && performedWeight! > 0;
  
  bool get hasFeedback => setFeedbackDifficulty != null && 
                         setFeedbackDifficulty!.isNotEmpty;

  // Performance metrics
  double get volume => hasWeight 
      ? (performedWeight! * (performedReps ?? 0)).toDouble()
      : 0.0;

  // Difficulty assessment
  SetDifficulty get difficulty {
    switch (setFeedbackDifficulty?.toLowerCase()) {
      case 'easy':
        return SetDifficulty.easy;
      case 'moderate':
        return SetDifficulty.moderate;
      case 'hard':
        return SetDifficulty.hard;
      case 'very_hard':
        return SetDifficulty.veryHard;
      default:
        return SetDifficulty.unknown;
    }
  }

  // Helper methods for analysis
  bool get isPersonalRecord => false; // This would need comparison with historical data
  
  bool get needsWeightIncrease => difficulty == SetDifficulty.easy;
  
  bool get needsWeightDecrease => difficulty == SetDifficulty.veryHard;

  // Time-based analysis
  bool get isRecent => DateTime.now().difference(createdAt).inDays < 7;
  
  Duration get ageInDays => DateTime.now().difference(createdAt);

  // Formatting helpers
  String get formattedWeight => hasWeight ? '${performedWeight}kg' : 'Bodyweight';
  
  String get formattedReps => '${performedReps ?? 0} reps';
  
  String get formattedVolume => hasWeight ? '${volume.toStringAsFixed(1)}kg' : '${performedReps ?? 0} reps';

  // Comparison methods
  int comparePerformance(CompletedSet other) {
    // Compare by volume first
    final volumeComparison = volume.compareTo(other.volume);
    if (volumeComparison != 0) return volumeComparison;
    
    // If volume is equal, compare by reps
    final repsComparison = (performedReps ?? 0).compareTo(other.performedReps ?? 0);
    if (repsComparison != 0) return repsComparison;
    
    // Finally compare by weight
    return (performedWeight ?? 0).compareTo(other.performedWeight ?? 0);
  }

  bool isBetterThan(CompletedSet other) => comparePerformance(other) > 0;
}

@HiveType(typeId: 4)
enum SetDifficulty {
  @HiveField(0)
  unknown,
  
  @HiveField(1)
  easy,
  
  @HiveField(2)
  moderate,
  
  @HiveField(3)
  hard,
  
  @HiveField(4)
  veryHard,
}

extension SetDifficultyExtension on SetDifficulty {
  String get displayName {
    switch (this) {
      case SetDifficulty.easy:
        return 'Easy';
      case SetDifficulty.moderate:
        return 'Moderate';
      case SetDifficulty.hard:
        return 'Hard';
      case SetDifficulty.veryHard:
        return 'Very Hard';
      case SetDifficulty.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case SetDifficulty.easy:
        return '😊';
      case SetDifficulty.moderate:
        return '😐';
      case SetDifficulty.hard:
        return '😤';
      case SetDifficulty.veryHard:
        return '🥵';
      case SetDifficulty.unknown:
        return '❓';
    }
  }

  double get intensityScore {
    switch (this) {
      case SetDifficulty.easy:
        return 0.25;
      case SetDifficulty.moderate:
        return 0.5;
      case SetDifficulty.hard:
        return 0.75;
      case SetDifficulty.veryHard:
        return 1.0;
      case SetDifficulty.unknown:
        return 0.5;
    }
  }
}