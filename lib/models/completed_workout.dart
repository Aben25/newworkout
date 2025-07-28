import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'completed_workout.g.dart';

@JsonSerializable()
@HiveType(typeId: 13)
class CompletedWorkout extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String userId;
  
  @HiveField(2)
  @JsonKey(name: 'workout_id')
  final String workoutId;
  
  @HiveField(3)
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  
  @HiveField(4)
  final int duration; // in minutes
  
  @HiveField(5)
  @JsonKey(name: 'calories_burned')
  final int caloriesBurned;
  
  @HiveField(6)
  final int? rating;
  
  @HiveField(7)
  @JsonKey(name: 'user_feedback_completed_workout')
  final String? userFeedback;
  
  @HiveField(8)
  @JsonKey(name: 'completed_workout_summary')
  final Map<String, dynamic>? workoutSummary;
  
  @HiveField(9)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  CompletedWorkout({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.completedAt,
    required this.duration,
    required this.caloriesBurned,
    this.rating,
    this.userFeedback,
    this.workoutSummary,
    required this.createdAt,
  });

  factory CompletedWorkout.fromJson(Map<String, dynamic> json) => 
      _$CompletedWorkoutFromJson(json);

  Map<String, dynamic> toJson() => _$CompletedWorkoutToJson(this);

  CompletedWorkout copyWith({
    String? id,
    String? userId,
    String? workoutId,
    DateTime? completedAt,
    int? duration,
    int? caloriesBurned,
    int? rating,
    String? userFeedback,
    Map<String, dynamic>? workoutSummary,
    DateTime? createdAt,
  }) {
    return CompletedWorkout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      rating: rating ?? this.rating,
      userFeedback: userFeedback ?? this.userFeedback,
      workoutSummary: workoutSummary ?? this.workoutSummary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompletedWorkout &&
        other.id == id &&
        other.userId == userId &&
        other.workoutId == workoutId &&
        other.completedAt == completedAt &&
        other.duration == duration &&
        other.caloriesBurned == caloriesBurned &&
        other.rating == rating &&
        other.userFeedback == userFeedback &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      workoutId,
      completedAt,
      duration,
      caloriesBurned,
      rating,
      userFeedback,
      createdAt,
    );
  }

  // Validation methods
  bool get isValid => 
      id.isNotEmpty && 
      userId.isNotEmpty && 
      workoutId.isNotEmpty &&
      duration > 0 &&
      caloriesBurned >= 0;

  bool get hasRating => rating != null && rating! >= 1 && rating! <= 5;
  
  bool get hasFeedback => userFeedback != null && userFeedback!.isNotEmpty;
  
  bool get hasSummary => workoutSummary != null && workoutSummary!.isNotEmpty;

  // Duration calculations
  Duration get workoutDuration => Duration(minutes: duration);
  
  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Performance metrics
  double get caloriesPerMinute => duration > 0 ? caloriesBurned / duration : 0.0;
  
  double get ratingScore => (rating ?? 0) / 5.0;
  
  bool get isHighRated => rating != null && rating! >= 4;
  
  bool get isLowRated => rating != null && rating! <= 2;

  // Summary data accessors
  int get totalSets => workoutSummary?['total_sets'] ?? 0;
  
  int get totalReps => workoutSummary?['total_reps'] ?? 0;
  
  double get totalVolume => (workoutSummary?['total_volume_kg'] ?? 0.0).toDouble();
  
  int get exercisesCompleted => workoutSummary?['exercises_completed'] ?? 0;
  
  double get workoutIntensity => (workoutSummary?['workout_intensity'] ?? 0.0).toDouble();
  
  int get averageRestTime => workoutSummary?['average_rest_time_seconds'] ?? 0;

  Map<String, dynamic>? get exerciseBreakdown => 
      workoutSummary?['exercise_breakdown'] as Map<String, dynamic>?;
  
  Map<String, dynamic>? get muscleGroupDistribution => 
      workoutSummary?['muscle_group_distribution'] as Map<String, dynamic>?;

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
  String get formattedRating {
    if (!hasRating) return 'Not rated';
    return '${'⭐' * rating!}${'☆' * (5 - rating!)}';
  }

  String get formattedCalories => '$caloriesBurned cal';
  
  String get formattedVolume => '${totalVolume.toStringAsFixed(1)}kg';

  // Comparison methods
  int compareTo(CompletedWorkout other) {
    return completedAt.compareTo(other.completedAt);
  }

  bool isNewerThan(CompletedWorkout other) => compareTo(other) > 0;
  
  bool isOlderThan(CompletedWorkout other) => compareTo(other) < 0;

  // Achievement analysis
  bool get isPersonalRecord => false; // This would need comparison with historical data
  
  bool get isLongWorkout => duration >= 60; // 1+ hour
  
  bool get isShortWorkout => duration <= 30; // 30 minutes or less
  
  bool get isHighIntensity => workoutIntensity >= 7.0;
  
  bool get isHighVolume => totalVolume >= 1000; // 1000kg+ total volume

  // Social sharing data
  Map<String, dynamic> get shareableData => {
    'workout_id': workoutId,
    'duration': formattedDuration,
    'calories_burned': caloriesBurned,
    'total_sets': totalSets,
    'total_reps': totalReps,
    'total_volume': formattedVolume,
    'exercises_completed': exercisesCompleted,
    'rating': rating,
    'completed_at': completedAt.toIso8601String(),
    'achievements': _getAchievements(),
  };

  List<String> _getAchievements() {
    final achievements = <String>[];
    
    if (isPersonalRecord) achievements.add('Personal Record');
    if (isLongWorkout) achievements.add('Endurance Warrior');
    if (isHighIntensity) achievements.add('High Intensity');
    if (isHighVolume) achievements.add('Volume King');
    if (isHighRated) achievements.add('Great Workout');
    
    return achievements;
  }
}