// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompletedSetLogAdapter extends TypeAdapter<CompletedSetLog> {
  @override
  final int typeId = 31;

  @override
  CompletedSetLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompletedSetLog(
      workoutExerciseId: fields[0] as String,
      exerciseId: fields[1] as String,
      exerciseIndex: fields[2] as int,
      setNumber: fields[3] as int,
      reps: fields[4] as int,
      weight: fields[5] as double,
      notes: fields[6] as String?,
      difficultyRating: fields[7] as String?,
      timestamp: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompletedSetLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.workoutExerciseId)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.exerciseIndex)
      ..writeByte(3)
      ..write(obj.setNumber)
      ..writeByte(4)
      ..write(obj.reps)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.difficultyRating)
      ..writeByte(8)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedSetLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseLogSessionAdapter extends TypeAdapter<ExerciseLogSession> {
  @override
  final int typeId = 32;

  @override
  ExerciseLogSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseLogSession(
      exerciseId: fields[0] as String,
      sets: (fields[1] as List).cast<CompletedSetLog>(),
      notes: fields[2] as String?,
      difficultyRating: fields[3] as String?,
      startTime: fields[4] as DateTime?,
      endTime: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseLogSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.sets)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.difficultyRating)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseLogSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompletedSetLog _$CompletedSetLogFromJson(Map<String, dynamic> json) =>
    CompletedSetLog(
      workoutExerciseId: json['workout_exercise_id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseIndex: (json['exercise_index'] as num).toInt(),
      setNumber: (json['set_number'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      notes: json['notes'] as String?,
      difficultyRating: json['difficulty_rating'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$CompletedSetLogToJson(CompletedSetLog instance) =>
    <String, dynamic>{
      'workout_exercise_id': instance.workoutExerciseId,
      'exercise_id': instance.exerciseId,
      'exercise_index': instance.exerciseIndex,
      'set_number': instance.setNumber,
      'reps': instance.reps,
      'weight': instance.weight,
      'notes': instance.notes,
      'difficulty_rating': instance.difficultyRating,
      'timestamp': instance.timestamp.toIso8601String(),
    };

ExerciseLogSession _$ExerciseLogSessionFromJson(Map<String, dynamic> json) =>
    ExerciseLogSession(
      exerciseId: json['exercise_id'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => CompletedSetLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      difficultyRating: json['difficulty_rating'] as String?,
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
    );

Map<String, dynamic> _$ExerciseLogSessionToJson(ExerciseLogSession instance) =>
    <String, dynamic>{
      'exercise_id': instance.exerciseId,
      'sets': instance.sets,
      'notes': instance.notes,
      'difficulty_rating': instance.difficultyRating,
      'start_time': instance.startTime?.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
    };
