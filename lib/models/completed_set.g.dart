// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_set.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompletedSetAdapter extends TypeAdapter<CompletedSet> {
  @override
  final int typeId = 3;

  @override
  CompletedSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompletedSet(
      id: fields[0] as int,
      workoutId: fields[1] as String?,
      workoutExerciseId: fields[2] as String?,
      performedSetOrder: fields[3] as int?,
      performedReps: fields[4] as int?,
      performedWeight: fields[5] as int?,
      setFeedbackDifficulty: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CompletedSet obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workoutId)
      ..writeByte(2)
      ..write(obj.workoutExerciseId)
      ..writeByte(3)
      ..write(obj.performedSetOrder)
      ..writeByte(4)
      ..write(obj.performedReps)
      ..writeByte(5)
      ..write(obj.performedWeight)
      ..writeByte(6)
      ..write(obj.setFeedbackDifficulty)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SetDifficultyAdapter extends TypeAdapter<SetDifficulty> {
  @override
  final int typeId = 4;

  @override
  SetDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SetDifficulty.unknown;
      case 1:
        return SetDifficulty.easy;
      case 2:
        return SetDifficulty.moderate;
      case 3:
        return SetDifficulty.hard;
      case 4:
        return SetDifficulty.veryHard;
      default:
        return SetDifficulty.unknown;
    }
  }

  @override
  void write(BinaryWriter writer, SetDifficulty obj) {
    switch (obj) {
      case SetDifficulty.unknown:
        writer.writeByte(0);
        break;
      case SetDifficulty.easy:
        writer.writeByte(1);
        break;
      case SetDifficulty.moderate:
        writer.writeByte(2);
        break;
      case SetDifficulty.hard:
        writer.writeByte(3);
        break;
      case SetDifficulty.veryHard:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompletedSet _$CompletedSetFromJson(Map<String, dynamic> json) => CompletedSet(
      id: (json['id'] as num).toInt(),
      workoutId: json['workout_id'] as String?,
      workoutExerciseId: json['workout_exercise_id'] as String?,
      performedSetOrder: (json['performed_set_order'] as num?)?.toInt(),
      performedReps: (json['performed_reps'] as num?)?.toInt(),
      performedWeight: (json['performed_weight'] as num?)?.toInt(),
      setFeedbackDifficulty: json['set_feedback_difficulty'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CompletedSetToJson(CompletedSet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workout_id': instance.workoutId,
      'workout_exercise_id': instance.workoutExerciseId,
      'performed_set_order': instance.performedSetOrder,
      'performed_reps': instance.performedReps,
      'performed_weight': instance.performedWeight,
      'set_feedback_difficulty': instance.setFeedbackDifficulty,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
