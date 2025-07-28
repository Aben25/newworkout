// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutLogAdapter extends TypeAdapter<WorkoutLog> {
  @override
  final int typeId = 5;

  @override
  WorkoutLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutLog(
      id: fields[0] as String,
      userId: fields[1] as String?,
      workoutId: fields[2] as String?,
      completedAt: fields[3] as DateTime?,
      startedAt: fields[4] as DateTime?,
      endedAt: fields[5] as DateTime?,
      duration: fields[6] as int?,
      durationSeconds: fields[7] as int?,
      rating: fields[8] as int?,
      notes: fields[9] as String?,
      status: fields[10] as String?,
      createdAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutLog obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.workoutId)
      ..writeByte(3)
      ..write(obj.completedAt)
      ..writeByte(4)
      ..write(obj.startedAt)
      ..writeByte(5)
      ..write(obj.endedAt)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.durationSeconds)
      ..writeByte(8)
      ..write(obj.rating)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutStatusAdapter extends TypeAdapter<WorkoutStatus> {
  @override
  final int typeId = 6;

  @override
  WorkoutStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkoutStatus.unknown;
      case 1:
        return WorkoutStatus.inProgress;
      case 2:
        return WorkoutStatus.completed;
      case 3:
        return WorkoutStatus.cancelled;
      case 4:
        return WorkoutStatus.paused;
      default:
        return WorkoutStatus.unknown;
    }
  }

  @override
  void write(BinaryWriter writer, WorkoutStatus obj) {
    switch (obj) {
      case WorkoutStatus.unknown:
        writer.writeByte(0);
        break;
      case WorkoutStatus.inProgress:
        writer.writeByte(1);
        break;
      case WorkoutStatus.completed:
        writer.writeByte(2);
        break;
      case WorkoutStatus.cancelled:
        writer.writeByte(3);
        break;
      case WorkoutStatus.paused:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutLog _$WorkoutLogFromJson(Map<String, dynamic> json) => WorkoutLog(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      workoutId: json['workout_id'] as String?,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      duration: (json['duration'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      status: json['status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WorkoutLogToJson(WorkoutLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'workout_id': instance.workoutId,
      'completed_at': instance.completedAt?.toIso8601String(),
      'started_at': instance.startedAt?.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'duration': instance.duration,
      'duration_seconds': instance.durationSeconds,
      'rating': instance.rating,
      'notes': instance.notes,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };
