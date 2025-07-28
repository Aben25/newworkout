// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompletedWorkoutAdapter extends TypeAdapter<CompletedWorkout> {
  @override
  final int typeId = 13;

  @override
  CompletedWorkout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompletedWorkout(
      id: fields[0] as String,
      userId: fields[1] as String,
      workoutId: fields[2] as String,
      completedAt: fields[3] as DateTime,
      duration: fields[4] as int,
      caloriesBurned: fields[5] as int,
      rating: fields[6] as int?,
      userFeedback: fields[7] as String?,
      workoutSummary: (fields[8] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompletedWorkout obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.workoutId)
      ..writeByte(3)
      ..write(obj.completedAt)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.caloriesBurned)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.userFeedback)
      ..writeByte(8)
      ..write(obj.workoutSummary)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedWorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompletedWorkout _$CompletedWorkoutFromJson(Map<String, dynamic> json) =>
    CompletedWorkout(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      duration: (json['duration'] as num).toInt(),
      caloriesBurned: (json['calories_burned'] as num).toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      userFeedback: json['user_feedback_completed_workout'] as String?,
      workoutSummary:
          json['completed_workout_summary'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CompletedWorkoutToJson(CompletedWorkout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'workout_id': instance.workoutId,
      'completed_at': instance.completedAt.toIso8601String(),
      'duration': instance.duration,
      'calories_burned': instance.caloriesBurned,
      'rating': instance.rating,
      'user_feedback_completed_workout': instance.userFeedback,
      'completed_workout_summary': instance.workoutSummary,
      'created_at': instance.createdAt.toIso8601String(),
    };
