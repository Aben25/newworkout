// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_set_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSetLogAdapter extends TypeAdapter<WorkoutSetLog> {
  @override
  final int typeId = 34;

  @override
  WorkoutSetLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSetLog(
      id: fields[0] as String,
      workoutLogId: fields[1] as String,
      exerciseId: fields[2] as String,
      setNumber: fields[3] as int,
      repsCompleted: fields[4] as int,
      weight: fields[5] as double?,
      completedAt: fields[6] as DateTime,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSetLog obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workoutLogId)
      ..writeByte(2)
      ..write(obj.exerciseId)
      ..writeByte(3)
      ..write(obj.setNumber)
      ..writeByte(4)
      ..write(obj.repsCompleted)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSetLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutSetLog _$WorkoutSetLogFromJson(Map<String, dynamic> json) =>
    WorkoutSetLog(
      id: json['id'] as String,
      workoutLogId: json['workout_log_id'] as String,
      exerciseId: json['exercise_id'] as String,
      setNumber: (json['set_number'] as num).toInt(),
      repsCompleted: (json['reps_completed'] as num).toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      completedAt: DateTime.parse(json['completed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WorkoutSetLogToJson(WorkoutSetLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workout_log_id': instance.workoutLogId,
      'exercise_id': instance.exerciseId,
      'set_number': instance.setNumber,
      'reps_completed': instance.repsCompleted,
      'weight': instance.weight,
      'completed_at': instance.completedAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
