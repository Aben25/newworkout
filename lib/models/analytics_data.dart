import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'analytics_data.g.dart';

/// Comprehensive analytics data for progress tracking
@JsonSerializable()
@HiveType(typeId: 35)
class AnalyticsData extends HiveObject {
  @HiveField(0)
  final String userId;
  
  @HiveField(1)
  final DateTime calculatedAt;
  
  @HiveField(2)
  final WorkoutFrequencyAnalytics workoutFrequency;
  
  @HiveField(3)
  final VolumeAnalytics volume;
  
  @HiveField(4)
  final ProgressAnalytics progress;
  
  @HiveField(5)
  final List<PersonalRecord> personalRecords;
  
  @HiveField(6)
  final List<Milestone> milestones;
  
  @HiveField(7)
  final TrendAnalytics trends;

  AnalyticsData({
    required this.userId,
    required this.calculatedAt,
    required this.workoutFrequency,
    required this.volume,
    required this.progress,
    required this.personalRecords,
    required this.milestones,
    required this.trends,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => 
      _$AnalyticsDataFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsDataToJson(this);

  bool get isStale => DateTime.now().difference(calculatedAt).inHours > 1;
}

/// Workout frequency and consistency analytics
@JsonSerializable()
@HiveType(typeId: 39)
class WorkoutFrequencyAnalytics extends HiveObject {
  @HiveField(0)
  final int totalWorkouts;
  
  @HiveField(1)
  final int workoutsThisWeek;
  
  @HiveField(2)
  final int workoutsThisMonth;
  
  @HiveField(3)
  final double averageWorkoutsPerWeek;
  
  @HiveField(4)
  final int currentStreak;
  
  @HiveField(5)
  final int longestStreak;
  
  @HiveField(6)
  final double consistencyScore;
  
  @HiveField(7)
  final List<DailyWorkoutCount> dailyWorkouts;

  WorkoutFrequencyAnalytics({
    required this.totalWorkouts,
    required this.workoutsThisWeek,
    required this.workoutsThisMonth,
    required this.averageWorkoutsPerWeek,
    required this.currentStreak,
    required this.longestStreak,
    required this.consistencyScore,
    required this.dailyWorkouts,
  });

  factory WorkoutFrequencyAnalytics.fromJson(Map<String, dynamic> json) => 
      _$WorkoutFrequencyAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutFrequencyAnalyticsToJson(this);
}

/// Volume tracking analytics
@JsonSerializable()
@HiveType(typeId: 40)
class VolumeAnalytics extends HiveObject {
  @HiveField(0)
  final double totalVolumeLifetime;
  
  @HiveField(1)
  final double totalVolumeThisWeek;
  
  @HiveField(2)
  final double totalVolumeThisMonth;
  
  @HiveField(3)
  final double averageVolumePerWorkout;
  
  @HiveField(4)
  final double averageVolumePerWeek;
  
  @HiveField(5)
  final List<WeeklyVolumeData> weeklyVolume;
  
  @HiveField(6)
  final List<ExerciseVolumeData> exerciseVolume;

  VolumeAnalytics({
    required this.totalVolumeLifetime,
    required this.totalVolumeThisWeek,
    required this.totalVolumeThisMonth,
    required this.averageVolumePerWorkout,
    required this.averageVolumePerWeek,
    required this.weeklyVolume,
    required this.exerciseVolume,
  });

  factory VolumeAnalytics.fromJson(Map<String, dynamic> json) => 
      _$VolumeAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$VolumeAnalyticsToJson(this);
}

/// Progress tracking analytics
@JsonSerializable()
@HiveType(typeId: 41)
class ProgressAnalytics extends HiveObject {
  @HiveField(0)
  final int totalSets;
  
  @HiveField(1)
  final int totalReps;
  
  @HiveField(2)
  final int totalExercisesCompleted;
  
  @HiveField(3)
  final double averageWorkoutDuration;
  
  @HiveField(4)
  final double averageWorkoutRating;
  
  @HiveField(5)
  final int totalCaloriesBurned;
  
  @HiveField(6)
  final List<ExerciseProgressData> exerciseProgress;

  ProgressAnalytics({
    required this.totalSets,
    required this.totalReps,
    required this.totalExercisesCompleted,
    required this.averageWorkoutDuration,
    required this.averageWorkoutRating,
    required this.totalCaloriesBurned,
    required this.exerciseProgress,
  });

  factory ProgressAnalytics.fromJson(Map<String, dynamic> json) => 
      _$ProgressAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressAnalyticsToJson(this);
}

/// Personal record tracking
@JsonSerializable()
@HiveType(typeId: 42)
class PersonalRecord extends HiveObject {
  @HiveField(0)
  final String exerciseId;
  
  @HiveField(1)
  final String exerciseName;
  
  @HiveField(2)
  final PersonalRecordType type;
  
  @HiveField(3)
  final double value;
  
  @HiveField(4)
  final DateTime achievedAt;
  
  @HiveField(5)
  final String workoutLogId;

  PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.type,
    required this.value,
    required this.achievedAt,
    required this.workoutLogId,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => 
      _$PersonalRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalRecordToJson(this);

  String get formattedValue {
    switch (type) {
      case PersonalRecordType.maxWeight:
        return '${value.toStringAsFixed(1)}kg';
      case PersonalRecordType.maxReps:
        return '${value.toInt()} reps';
      case PersonalRecordType.maxVolume:
        return '${value.toStringAsFixed(1)}kg';
      case PersonalRecordType.bestTime:
        return '${(value / 60).toStringAsFixed(1)}min';
    }
  }
}

@HiveType(typeId: 43)
enum PersonalRecordType {
  @HiveField(0)
  maxWeight,
  
  @HiveField(1)
  maxReps,
  
  @HiveField(2)
  maxVolume,
  
  @HiveField(3)
  bestTime,
}

/// Milestone tracking
@JsonSerializable()
@HiveType(typeId: 44)
class Milestone extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final MilestoneType type;
  
  @HiveField(2)
  final String title;
  
  @HiveField(3)
  final String description;
  
  @HiveField(4)
  final DateTime achievedAt;
  
  @HiveField(5)
  final Map<String, dynamic> metadata;

  Milestone({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.achievedAt,
    required this.metadata,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) => 
      _$MilestoneFromJson(json);

  Map<String, dynamic> toJson() => _$MilestoneToJson(this);
}

@HiveType(typeId: 45)
enum MilestoneType {
  @HiveField(0)
  workoutCount,
  
  @HiveField(1)
  streak,
  
  @HiveField(2)
  volume,
  
  @HiveField(3)
  personalRecord,
  
  @HiveField(4)
  consistency,
}

/// Trend analysis data
@JsonSerializable()
@HiveType(typeId: 46)
class TrendAnalytics extends HiveObject {
  @HiveField(0)
  final double volumeTrend;
  
  @HiveField(1)
  final double frequencyTrend;
  
  @HiveField(2)
  final double durationTrend;
  
  @HiveField(3)
  final double ratingTrend;
  
  @HiveField(4)
  final List<TrendDataPoint> volumeTrendData;
  
  @HiveField(5)
  final List<TrendDataPoint> frequencyTrendData;

  TrendAnalytics({
    required this.volumeTrend,
    required this.frequencyTrend,
    required this.durationTrend,
    required this.ratingTrend,
    required this.volumeTrendData,
    required this.frequencyTrendData,
  });

  factory TrendAnalytics.fromJson(Map<String, dynamic> json) => 
      _$TrendAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$TrendAnalyticsToJson(this);
}

/// Supporting data structures
@JsonSerializable()
@HiveType(typeId: 47)
class DailyWorkoutCount extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final int count;

  DailyWorkoutCount({
    required this.date,
    required this.count,
  });

  factory DailyWorkoutCount.fromJson(Map<String, dynamic> json) => 
      _$DailyWorkoutCountFromJson(json);

  Map<String, dynamic> toJson() => _$DailyWorkoutCountToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 48)
class WeeklyVolumeData extends HiveObject {
  @HiveField(0)
  final DateTime weekStart;
  
  @HiveField(1)
  final double volume;

  WeeklyVolumeData({
    required this.weekStart,
    required this.volume,
  });

  factory WeeklyVolumeData.fromJson(Map<String, dynamic> json) => 
      _$WeeklyVolumeDataFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyVolumeDataToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 49)
class ExerciseVolumeData extends HiveObject {
  @HiveField(0)
  final String exerciseId;
  
  @HiveField(1)
  final String exerciseName;
  
  @HiveField(2)
  final double totalVolume;
  
  @HiveField(3)
  final int totalSets;

  ExerciseVolumeData({
    required this.exerciseId,
    required this.exerciseName,
    required this.totalVolume,
    required this.totalSets,
  });

  factory ExerciseVolumeData.fromJson(Map<String, dynamic> json) => 
      _$ExerciseVolumeDataFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseVolumeDataToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 27)
class ExerciseProgressData extends HiveObject {
  @HiveField(0)
  final String exerciseId;
  
  @HiveField(1)
  final String exerciseName;
  
  @HiveField(2)
  final double maxWeight;
  
  @HiveField(3)
  final int maxReps;
  
  @HiveField(4)
  final double totalVolume;
  
  @HiveField(5)
  final int totalSets;
  
  @HiveField(6)
  final List<ProgressDataPoint> progressHistory;

  ExerciseProgressData({
    required this.exerciseId,
    required this.exerciseName,
    required this.maxWeight,
    required this.maxReps,
    required this.totalVolume,
    required this.totalSets,
    required this.progressHistory,
  });

  factory ExerciseProgressData.fromJson(Map<String, dynamic> json) => 
      _$ExerciseProgressDataFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseProgressDataToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 28)
class ProgressDataPoint extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final double weight;
  
  @HiveField(2)
  final int reps;
  
  @HiveField(3)
  final double volume;

  ProgressDataPoint({
    required this.date,
    required this.weight,
    required this.reps,
    required this.volume,
  });

  factory ProgressDataPoint.fromJson(Map<String, dynamic> json) => 
      _$ProgressDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressDataPointToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 29)
class TrendDataPoint extends HiveObject {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final double value;

  TrendDataPoint({
    required this.date,
    required this.value,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) => 
      _$TrendDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$TrendDataPointToJson(this);
}