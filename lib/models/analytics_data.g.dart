// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnalyticsDataAdapter extends TypeAdapter<AnalyticsData> {
  @override
  final int typeId = 35;

  @override
  AnalyticsData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalyticsData(
      userId: fields[0] as String,
      calculatedAt: fields[1] as DateTime,
      workoutFrequency: fields[2] as WorkoutFrequencyAnalytics,
      volume: fields[3] as VolumeAnalytics,
      progress: fields[4] as ProgressAnalytics,
      personalRecords: (fields[5] as List).cast<PersonalRecord>(),
      milestones: (fields[6] as List).cast<Milestone>(),
      trends: fields[7] as TrendAnalytics,
    );
  }

  @override
  void write(BinaryWriter writer, AnalyticsData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.calculatedAt)
      ..writeByte(2)
      ..write(obj.workoutFrequency)
      ..writeByte(3)
      ..write(obj.volume)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.personalRecords)
      ..writeByte(6)
      ..write(obj.milestones)
      ..writeByte(7)
      ..write(obj.trends);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutFrequencyAnalyticsAdapter
    extends TypeAdapter<WorkoutFrequencyAnalytics> {
  @override
  final int typeId = 39;

  @override
  WorkoutFrequencyAnalytics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutFrequencyAnalytics(
      totalWorkouts: fields[0] as int,
      workoutsThisWeek: fields[1] as int,
      workoutsThisMonth: fields[2] as int,
      averageWorkoutsPerWeek: fields[3] as double,
      currentStreak: fields[4] as int,
      longestStreak: fields[5] as int,
      consistencyScore: fields[6] as double,
      dailyWorkouts: (fields[7] as List).cast<DailyWorkoutCount>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutFrequencyAnalytics obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.totalWorkouts)
      ..writeByte(1)
      ..write(obj.workoutsThisWeek)
      ..writeByte(2)
      ..write(obj.workoutsThisMonth)
      ..writeByte(3)
      ..write(obj.averageWorkoutsPerWeek)
      ..writeByte(4)
      ..write(obj.currentStreak)
      ..writeByte(5)
      ..write(obj.longestStreak)
      ..writeByte(6)
      ..write(obj.consistencyScore)
      ..writeByte(7)
      ..write(obj.dailyWorkouts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutFrequencyAnalyticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VolumeAnalyticsAdapter extends TypeAdapter<VolumeAnalytics> {
  @override
  final int typeId = 40;

  @override
  VolumeAnalytics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VolumeAnalytics(
      totalVolumeLifetime: fields[0] as double,
      totalVolumeThisWeek: fields[1] as double,
      totalVolumeThisMonth: fields[2] as double,
      averageVolumePerWorkout: fields[3] as double,
      averageVolumePerWeek: fields[4] as double,
      weeklyVolume: (fields[5] as List).cast<WeeklyVolumeData>(),
      exerciseVolume: (fields[6] as List).cast<ExerciseVolumeData>(),
    );
  }

  @override
  void write(BinaryWriter writer, VolumeAnalytics obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.totalVolumeLifetime)
      ..writeByte(1)
      ..write(obj.totalVolumeThisWeek)
      ..writeByte(2)
      ..write(obj.totalVolumeThisMonth)
      ..writeByte(3)
      ..write(obj.averageVolumePerWorkout)
      ..writeByte(4)
      ..write(obj.averageVolumePerWeek)
      ..writeByte(5)
      ..write(obj.weeklyVolume)
      ..writeByte(6)
      ..write(obj.exerciseVolume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumeAnalyticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProgressAnalyticsAdapter extends TypeAdapter<ProgressAnalytics> {
  @override
  final int typeId = 41;

  @override
  ProgressAnalytics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressAnalytics(
      totalSets: fields[0] as int,
      totalReps: fields[1] as int,
      totalExercisesCompleted: fields[2] as int,
      averageWorkoutDuration: fields[3] as double,
      averageWorkoutRating: fields[4] as double,
      totalCaloriesBurned: fields[5] as int,
      exerciseProgress: (fields[6] as List).cast<ExerciseProgressData>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProgressAnalytics obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.totalSets)
      ..writeByte(1)
      ..write(obj.totalReps)
      ..writeByte(2)
      ..write(obj.totalExercisesCompleted)
      ..writeByte(3)
      ..write(obj.averageWorkoutDuration)
      ..writeByte(4)
      ..write(obj.averageWorkoutRating)
      ..writeByte(5)
      ..write(obj.totalCaloriesBurned)
      ..writeByte(6)
      ..write(obj.exerciseProgress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressAnalyticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonalRecordAdapter extends TypeAdapter<PersonalRecord> {
  @override
  final int typeId = 42;

  @override
  PersonalRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonalRecord(
      exerciseId: fields[0] as String,
      exerciseName: fields[1] as String,
      type: fields[2] as PersonalRecordType,
      value: fields[3] as double,
      achievedAt: fields[4] as DateTime,
      workoutLogId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PersonalRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.achievedAt)
      ..writeByte(5)
      ..write(obj.workoutLogId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MilestoneAdapter extends TypeAdapter<Milestone> {
  @override
  final int typeId = 44;

  @override
  Milestone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Milestone(
      id: fields[0] as String,
      type: fields[1] as MilestoneType,
      title: fields[2] as String,
      description: fields[3] as String,
      achievedAt: fields[4] as DateTime,
      metadata: (fields[5] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Milestone obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.achievedAt)
      ..writeByte(5)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrendAnalyticsAdapter extends TypeAdapter<TrendAnalytics> {
  @override
  final int typeId = 46;

  @override
  TrendAnalytics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrendAnalytics(
      volumeTrend: fields[0] as double,
      frequencyTrend: fields[1] as double,
      durationTrend: fields[2] as double,
      ratingTrend: fields[3] as double,
      volumeTrendData: (fields[4] as List).cast<TrendDataPoint>(),
      frequencyTrendData: (fields[5] as List).cast<TrendDataPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, TrendAnalytics obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.volumeTrend)
      ..writeByte(1)
      ..write(obj.frequencyTrend)
      ..writeByte(2)
      ..write(obj.durationTrend)
      ..writeByte(3)
      ..write(obj.ratingTrend)
      ..writeByte(4)
      ..write(obj.volumeTrendData)
      ..writeByte(5)
      ..write(obj.frequencyTrendData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendAnalyticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyWorkoutCountAdapter extends TypeAdapter<DailyWorkoutCount> {
  @override
  final int typeId = 47;

  @override
  DailyWorkoutCount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyWorkoutCount(
      date: fields[0] as DateTime,
      count: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyWorkoutCount obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyWorkoutCountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeeklyVolumeDataAdapter extends TypeAdapter<WeeklyVolumeData> {
  @override
  final int typeId = 48;

  @override
  WeeklyVolumeData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyVolumeData(
      weekStart: fields[0] as DateTime,
      volume: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyVolumeData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.weekStart)
      ..writeByte(1)
      ..write(obj.volume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyVolumeDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseVolumeDataAdapter extends TypeAdapter<ExerciseVolumeData> {
  @override
  final int typeId = 49;

  @override
  ExerciseVolumeData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseVolumeData(
      exerciseId: fields[0] as String,
      exerciseName: fields[1] as String,
      totalVolume: fields[2] as double,
      totalSets: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseVolumeData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.totalVolume)
      ..writeByte(3)
      ..write(obj.totalSets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseVolumeDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseProgressDataAdapter extends TypeAdapter<ExerciseProgressData> {
  @override
  final int typeId = 27;

  @override
  ExerciseProgressData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseProgressData(
      exerciseId: fields[0] as String,
      exerciseName: fields[1] as String,
      maxWeight: fields[2] as double,
      maxReps: fields[3] as int,
      totalVolume: fields[4] as double,
      totalSets: fields[5] as int,
      progressHistory: (fields[6] as List).cast<ProgressDataPoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseProgressData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.maxWeight)
      ..writeByte(3)
      ..write(obj.maxReps)
      ..writeByte(4)
      ..write(obj.totalVolume)
      ..writeByte(5)
      ..write(obj.totalSets)
      ..writeByte(6)
      ..write(obj.progressHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseProgressDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProgressDataPointAdapter extends TypeAdapter<ProgressDataPoint> {
  @override
  final int typeId = 28;

  @override
  ProgressDataPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressDataPoint(
      date: fields[0] as DateTime,
      weight: fields[1] as double,
      reps: fields[2] as int,
      volume: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressDataPoint obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.volume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressDataPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrendDataPointAdapter extends TypeAdapter<TrendDataPoint> {
  @override
  final int typeId = 29;

  @override
  TrendDataPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrendDataPoint(
      date: fields[0] as DateTime,
      value: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TrendDataPoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendDataPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonalRecordTypeAdapter extends TypeAdapter<PersonalRecordType> {
  @override
  final int typeId = 43;

  @override
  PersonalRecordType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PersonalRecordType.maxWeight;
      case 1:
        return PersonalRecordType.maxReps;
      case 2:
        return PersonalRecordType.maxVolume;
      case 3:
        return PersonalRecordType.bestTime;
      default:
        return PersonalRecordType.maxWeight;
    }
  }

  @override
  void write(BinaryWriter writer, PersonalRecordType obj) {
    switch (obj) {
      case PersonalRecordType.maxWeight:
        writer.writeByte(0);
        break;
      case PersonalRecordType.maxReps:
        writer.writeByte(1);
        break;
      case PersonalRecordType.maxVolume:
        writer.writeByte(2);
        break;
      case PersonalRecordType.bestTime:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalRecordTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MilestoneTypeAdapter extends TypeAdapter<MilestoneType> {
  @override
  final int typeId = 45;

  @override
  MilestoneType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MilestoneType.workoutCount;
      case 1:
        return MilestoneType.streak;
      case 2:
        return MilestoneType.volume;
      case 3:
        return MilestoneType.personalRecord;
      case 4:
        return MilestoneType.consistency;
      default:
        return MilestoneType.workoutCount;
    }
  }

  @override
  void write(BinaryWriter writer, MilestoneType obj) {
    switch (obj) {
      case MilestoneType.workoutCount:
        writer.writeByte(0);
        break;
      case MilestoneType.streak:
        writer.writeByte(1);
        break;
      case MilestoneType.volume:
        writer.writeByte(2);
        break;
      case MilestoneType.personalRecord:
        writer.writeByte(3);
        break;
      case MilestoneType.consistency:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsData _$AnalyticsDataFromJson(Map<String, dynamic> json) =>
    AnalyticsData(
      userId: json['userId'] as String,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      workoutFrequency: WorkoutFrequencyAnalytics.fromJson(
          json['workoutFrequency'] as Map<String, dynamic>),
      volume: VolumeAnalytics.fromJson(json['volume'] as Map<String, dynamic>),
      progress:
          ProgressAnalytics.fromJson(json['progress'] as Map<String, dynamic>),
      personalRecords: (json['personalRecords'] as List<dynamic>)
          .map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      milestones: (json['milestones'] as List<dynamic>)
          .map((e) => Milestone.fromJson(e as Map<String, dynamic>))
          .toList(),
      trends: TrendAnalytics.fromJson(json['trends'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AnalyticsDataToJson(AnalyticsData instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
      'workoutFrequency': instance.workoutFrequency,
      'volume': instance.volume,
      'progress': instance.progress,
      'personalRecords': instance.personalRecords,
      'milestones': instance.milestones,
      'trends': instance.trends,
    };

WorkoutFrequencyAnalytics _$WorkoutFrequencyAnalyticsFromJson(
        Map<String, dynamic> json) =>
    WorkoutFrequencyAnalytics(
      totalWorkouts: (json['totalWorkouts'] as num).toInt(),
      workoutsThisWeek: (json['workoutsThisWeek'] as num).toInt(),
      workoutsThisMonth: (json['workoutsThisMonth'] as num).toInt(),
      averageWorkoutsPerWeek:
          (json['averageWorkoutsPerWeek'] as num).toDouble(),
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      consistencyScore: (json['consistencyScore'] as num).toDouble(),
      dailyWorkouts: (json['dailyWorkouts'] as List<dynamic>)
          .map((e) => DailyWorkoutCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkoutFrequencyAnalyticsToJson(
        WorkoutFrequencyAnalytics instance) =>
    <String, dynamic>{
      'totalWorkouts': instance.totalWorkouts,
      'workoutsThisWeek': instance.workoutsThisWeek,
      'workoutsThisMonth': instance.workoutsThisMonth,
      'averageWorkoutsPerWeek': instance.averageWorkoutsPerWeek,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'consistencyScore': instance.consistencyScore,
      'dailyWorkouts': instance.dailyWorkouts,
    };

VolumeAnalytics _$VolumeAnalyticsFromJson(Map<String, dynamic> json) =>
    VolumeAnalytics(
      totalVolumeLifetime: (json['totalVolumeLifetime'] as num).toDouble(),
      totalVolumeThisWeek: (json['totalVolumeThisWeek'] as num).toDouble(),
      totalVolumeThisMonth: (json['totalVolumeThisMonth'] as num).toDouble(),
      averageVolumePerWorkout:
          (json['averageVolumePerWorkout'] as num).toDouble(),
      averageVolumePerWeek: (json['averageVolumePerWeek'] as num).toDouble(),
      weeklyVolume: (json['weeklyVolume'] as List<dynamic>)
          .map((e) => WeeklyVolumeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      exerciseVolume: (json['exerciseVolume'] as List<dynamic>)
          .map((e) => ExerciseVolumeData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VolumeAnalyticsToJson(VolumeAnalytics instance) =>
    <String, dynamic>{
      'totalVolumeLifetime': instance.totalVolumeLifetime,
      'totalVolumeThisWeek': instance.totalVolumeThisWeek,
      'totalVolumeThisMonth': instance.totalVolumeThisMonth,
      'averageVolumePerWorkout': instance.averageVolumePerWorkout,
      'averageVolumePerWeek': instance.averageVolumePerWeek,
      'weeklyVolume': instance.weeklyVolume,
      'exerciseVolume': instance.exerciseVolume,
    };

ProgressAnalytics _$ProgressAnalyticsFromJson(Map<String, dynamic> json) =>
    ProgressAnalytics(
      totalSets: (json['totalSets'] as num).toInt(),
      totalReps: (json['totalReps'] as num).toInt(),
      totalExercisesCompleted: (json['totalExercisesCompleted'] as num).toInt(),
      averageWorkoutDuration:
          (json['averageWorkoutDuration'] as num).toDouble(),
      averageWorkoutRating: (json['averageWorkoutRating'] as num).toDouble(),
      totalCaloriesBurned: (json['totalCaloriesBurned'] as num).toInt(),
      exerciseProgress: (json['exerciseProgress'] as List<dynamic>)
          .map((e) => ExerciseProgressData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProgressAnalyticsToJson(ProgressAnalytics instance) =>
    <String, dynamic>{
      'totalSets': instance.totalSets,
      'totalReps': instance.totalReps,
      'totalExercisesCompleted': instance.totalExercisesCompleted,
      'averageWorkoutDuration': instance.averageWorkoutDuration,
      'averageWorkoutRating': instance.averageWorkoutRating,
      'totalCaloriesBurned': instance.totalCaloriesBurned,
      'exerciseProgress': instance.exerciseProgress,
    };

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) =>
    PersonalRecord(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      type: $enumDecode(_$PersonalRecordTypeEnumMap, json['type']),
      value: (json['value'] as num).toDouble(),
      achievedAt: DateTime.parse(json['achievedAt'] as String),
      workoutLogId: json['workoutLogId'] as String,
    );

Map<String, dynamic> _$PersonalRecordToJson(PersonalRecord instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'type': _$PersonalRecordTypeEnumMap[instance.type]!,
      'value': instance.value,
      'achievedAt': instance.achievedAt.toIso8601String(),
      'workoutLogId': instance.workoutLogId,
    };

const _$PersonalRecordTypeEnumMap = {
  PersonalRecordType.maxWeight: 'maxWeight',
  PersonalRecordType.maxReps: 'maxReps',
  PersonalRecordType.maxVolume: 'maxVolume',
  PersonalRecordType.bestTime: 'bestTime',
};

Milestone _$MilestoneFromJson(Map<String, dynamic> json) => Milestone(
      id: json['id'] as String,
      type: $enumDecode(_$MilestoneTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      achievedAt: DateTime.parse(json['achievedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$MilestoneToJson(Milestone instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$MilestoneTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'achievedAt': instance.achievedAt.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$MilestoneTypeEnumMap = {
  MilestoneType.workoutCount: 'workoutCount',
  MilestoneType.streak: 'streak',
  MilestoneType.volume: 'volume',
  MilestoneType.personalRecord: 'personalRecord',
  MilestoneType.consistency: 'consistency',
};

TrendAnalytics _$TrendAnalyticsFromJson(Map<String, dynamic> json) =>
    TrendAnalytics(
      volumeTrend: (json['volumeTrend'] as num).toDouble(),
      frequencyTrend: (json['frequencyTrend'] as num).toDouble(),
      durationTrend: (json['durationTrend'] as num).toDouble(),
      ratingTrend: (json['ratingTrend'] as num).toDouble(),
      volumeTrendData: (json['volumeTrendData'] as List<dynamic>)
          .map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      frequencyTrendData: (json['frequencyTrendData'] as List<dynamic>)
          .map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrendAnalyticsToJson(TrendAnalytics instance) =>
    <String, dynamic>{
      'volumeTrend': instance.volumeTrend,
      'frequencyTrend': instance.frequencyTrend,
      'durationTrend': instance.durationTrend,
      'ratingTrend': instance.ratingTrend,
      'volumeTrendData': instance.volumeTrendData,
      'frequencyTrendData': instance.frequencyTrendData,
    };

DailyWorkoutCount _$DailyWorkoutCountFromJson(Map<String, dynamic> json) =>
    DailyWorkoutCount(
      date: DateTime.parse(json['date'] as String),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$DailyWorkoutCountToJson(DailyWorkoutCount instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'count': instance.count,
    };

WeeklyVolumeData _$WeeklyVolumeDataFromJson(Map<String, dynamic> json) =>
    WeeklyVolumeData(
      weekStart: DateTime.parse(json['weekStart'] as String),
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$WeeklyVolumeDataToJson(WeeklyVolumeData instance) =>
    <String, dynamic>{
      'weekStart': instance.weekStart.toIso8601String(),
      'volume': instance.volume,
    };

ExerciseVolumeData _$ExerciseVolumeDataFromJson(Map<String, dynamic> json) =>
    ExerciseVolumeData(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      totalVolume: (json['totalVolume'] as num).toDouble(),
      totalSets: (json['totalSets'] as num).toInt(),
    );

Map<String, dynamic> _$ExerciseVolumeDataToJson(ExerciseVolumeData instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'totalVolume': instance.totalVolume,
      'totalSets': instance.totalSets,
    };

ExerciseProgressData _$ExerciseProgressDataFromJson(
        Map<String, dynamic> json) =>
    ExerciseProgressData(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      maxWeight: (json['maxWeight'] as num).toDouble(),
      maxReps: (json['maxReps'] as num).toInt(),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      totalSets: (json['totalSets'] as num).toInt(),
      progressHistory: (json['progressHistory'] as List<dynamic>)
          .map((e) => ProgressDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExerciseProgressDataToJson(
        ExerciseProgressData instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'maxWeight': instance.maxWeight,
      'maxReps': instance.maxReps,
      'totalVolume': instance.totalVolume,
      'totalSets': instance.totalSets,
      'progressHistory': instance.progressHistory,
    };

ProgressDataPoint _$ProgressDataPointFromJson(Map<String, dynamic> json) =>
    ProgressDataPoint(
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$ProgressDataPointToJson(ProgressDataPoint instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'weight': instance.weight,
      'reps': instance.reps,
      'volume': instance.volume,
    };

TrendDataPoint _$TrendDataPointFromJson(Map<String, dynamic> json) =>
    TrendDataPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );

Map<String, dynamic> _$TrendDataPointToJson(TrendDataPoint instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'value': instance.value,
    };
