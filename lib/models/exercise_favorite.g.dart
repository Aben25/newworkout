// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_favorite.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseFavoriteAdapter extends TypeAdapter<ExerciseFavorite> {
  @override
  final int typeId = 10;

  @override
  ExerciseFavorite read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseFavorite(
      id: fields[0] as String,
      userId: fields[1] as String,
      exerciseId: fields[2] as String,
      createdAt: fields[3] as DateTime,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseFavorite obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.exerciseId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFavoriteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseFavorite _$ExerciseFavoriteFromJson(Map<String, dynamic> json) =>
    ExerciseFavorite(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseId: json['exercise_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ExerciseFavoriteToJson(ExerciseFavorite instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'exercise_id': instance.exerciseId,
      'created_at': instance.createdAt.toIso8601String(),
      'notes': instance.notes,
    };
