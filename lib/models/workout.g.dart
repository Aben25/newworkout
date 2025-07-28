// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 7;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Workout(
      id: fields[0] as String,
      userId: fields[1] as String?,
      name: fields[2] as String?,
      description: fields[3] as String?,
      startTime: fields[4] as DateTime?,
      endTime: fields[5] as DateTime?,
      isActive: fields[6] as bool,
      isCompleted: fields[7] as bool?,
      isMinimized: fields[8] as bool?,
      rating: fields[9] as int?,
      notes: fields[10] as String?,
      aiDescription: fields[11] as String?,
      sessionOrder: fields[12] as int?,
      lastState: (fields[13] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[14] as DateTime?,
      updatedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.isMinimized)
      ..writeByte(9)
      ..write(obj.rating)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.aiDescription)
      ..writeByte(12)
      ..write(obj.sessionOrder)
      ..writeByte(13)
      ..write(obj.lastState)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutStateAdapter extends TypeAdapter<WorkoutState> {
  @override
  final int typeId = 8;

  @override
  WorkoutState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutState(
      currentExerciseIndex: fields[0] as int,
      currentSet: fields[1] as int,
      completedExercises: (fields[2] as List).cast<String>(),
      exerciseLogs: (fields[3] as List).cast<ExerciseLog>(),
      totalExercises: fields[4] as int,
      startTime: fields[5] as DateTime?,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutState obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.currentExerciseIndex)
      ..writeByte(1)
      ..write(obj.currentSet)
      ..writeByte(2)
      ..write(obj.completedExercises)
      ..writeByte(3)
      ..write(obj.exerciseLogs)
      ..writeByte(4)
      ..write(obj.totalExercises)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseLogAdapter extends TypeAdapter<ExerciseLog> {
  @override
  final int typeId = 9;

  @override
  ExerciseLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseLog(
      exerciseId: fields[0] as String,
      sets: (fields[1] as List).cast<SetLog>(),
      notes: fields[2] as String?,
      difficultyRating: fields[3] as String?,
      startTime: fields[4] as DateTime?,
      endTime: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseLog obj) {
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
      other is ExerciseLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SetLogAdapter extends TypeAdapter<SetLog> {
  @override
  final int typeId = 33;

  @override
  SetLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SetLog(
      setNumber: fields[0] as int,
      reps: fields[1] as int,
      weight: fields[2] as double?,
      completed: fields[3] as bool,
      restDuration: fields[4] as int?,
      startTime: fields[5] as DateTime?,
      endTime: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SetLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.setNumber)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.restDuration)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Workout _$WorkoutFromJson(Map<String, dynamic> json) => Workout(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      isActive: json['is_active'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool?,
      isMinimized: json['is_minimized'] as bool?,
      rating: (json['rating'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      aiDescription: json['ai_description'] as String?,
      sessionOrder: (json['session_order'] as num?)?.toInt(),
      lastState: json['last_state'] as Map<String, dynamic>?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$WorkoutToJson(Workout instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'start_time': instance.startTime?.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'is_active': instance.isActive,
      'is_completed': instance.isCompleted,
      'is_minimized': instance.isMinimized,
      'rating': instance.rating,
      'notes': instance.notes,
      'ai_description': instance.aiDescription,
      'session_order': instance.sessionOrder,
      'last_state': instance.lastState,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

WorkoutState _$WorkoutStateFromJson(Map<String, dynamic> json) => WorkoutState(
      currentExerciseIndex: (json['current_exercise_index'] as num).toInt(),
      currentSet: (json['current_set'] as num).toInt(),
      completedExercises: (json['completed_exercises'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      exerciseLogs: (json['exercise_logs'] as List<dynamic>)
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalExercises: (json['total_exercises'] as num?)?.toInt() ?? 0,
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time'] as String),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$WorkoutStateToJson(WorkoutState instance) =>
    <String, dynamic>{
      'current_exercise_index': instance.currentExerciseIndex,
      'current_set': instance.currentSet,
      'completed_exercises': instance.completedExercises,
      'exercise_logs': instance.exerciseLogs,
      'total_exercises': instance.totalExercises,
      'start_time': instance.startTime?.toIso8601String(),
      'last_updated': instance.lastUpdated.toIso8601String(),
    };

ExerciseLog _$ExerciseLogFromJson(Map<String, dynamic> json) => ExerciseLog(
      exerciseId: json['exercise_id'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => SetLog.fromJson(e as Map<String, dynamic>))
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

Map<String, dynamic> _$ExerciseLogToJson(ExerciseLog instance) =>
    <String, dynamic>{
      'exercise_id': instance.exerciseId,
      'sets': instance.sets,
      'notes': instance.notes,
      'difficulty_rating': instance.difficultyRating,
      'start_time': instance.startTime?.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
    };

SetLog _$SetLogFromJson(Map<String, dynamic> json) => SetLog(
      setNumber: (json['set_number'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      completed: json['completed'] as bool,
      restDuration: (json['rest_duration'] as num?)?.toInt(),
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
    );

Map<String, dynamic> _$SetLogToJson(SetLog instance) => <String, dynamic>{
      'set_number': instance.setNumber,
      'reps': instance.reps,
      'weight': instance.weight,
      'completed': instance.completed,
      'rest_duration': instance.restDuration,
      'start_time': instance.startTime?.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
    };
