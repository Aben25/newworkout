// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutExerciseAdapter extends TypeAdapter<WorkoutExercise> {
  @override
  final int typeId = 2;

  @override
  WorkoutExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutExercise(
      id: fields[0] as String,
      workoutId: fields[1] as String,
      exerciseId: fields[2] as String,
      name: fields[3] as String,
      sets: fields[4] as int?,
      orderIndex: fields[5] as int?,
      order: fields[6] as int?,
      completed: fields[7] as bool,
      restInterval: fields[8] as int?,
      weight: (fields[9] as List?)?.cast<int>(),
      reps: (fields[10] as List?)?.cast<int>(),
      repsOld: (fields[11] as List?)?.cast<int>(),
      createdAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutExercise obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workoutId)
      ..writeByte(2)
      ..write(obj.exerciseId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.sets)
      ..writeByte(5)
      ..write(obj.orderIndex)
      ..writeByte(6)
      ..write(obj.order)
      ..writeByte(7)
      ..write(obj.completed)
      ..writeByte(8)
      ..write(obj.restInterval)
      ..writeByte(9)
      ..write(obj.weight)
      ..writeByte(10)
      ..write(obj.reps)
      ..writeByte(11)
      ..write(obj.repsOld)
      ..writeByte(12)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutExercise _$WorkoutExerciseFromJson(Map<String, dynamic> json) =>
    WorkoutExercise(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String,
      exerciseId: json['exercise_id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num?)?.toInt(),
      orderIndex: (json['order_index'] as num?)?.toInt(),
      order: (json['order'] as num?)?.toInt(),
      completed: json['completed'] as bool? ?? false,
      restInterval: (json['rest_interval'] as num?)?.toInt(),
      weight: (json['weight'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      reps: (json['reps'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      repsOld: (json['reps_old'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WorkoutExerciseToJson(WorkoutExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workout_id': instance.workoutId,
      'exercise_id': instance.exerciseId,
      'name': instance.name,
      'sets': instance.sets,
      'order_index': instance.orderIndex,
      'order': instance.order,
      'completed': instance.completed,
      'rest_interval': instance.restInterval,
      'weight': instance.weight,
      'reps': instance.reps,
      'reps_old': instance.repsOld,
      'created_at': instance.createdAt?.toIso8601String(),
    };
