// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_collection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseCollectionAdapter extends TypeAdapter<ExerciseCollection> {
  @override
  final int typeId = 11;

  @override
  ExerciseCollection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseCollection(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String?,
      exerciseIds: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      isPublic: fields[7] as bool,
      color: fields[8] as String?,
      icon: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseCollection obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.exerciseIds)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isPublic)
      ..writeByte(8)
      ..write(obj.color)
      ..writeByte(9)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseCollectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseCollection _$ExerciseCollectionFromJson(Map<String, dynamic> json) =>
    ExerciseCollection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      exerciseIds: (json['exercise_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPublic: json['is_public'] as bool? ?? false,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$ExerciseCollectionToJson(ExerciseCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'exercise_ids': instance.exerciseIds,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_public': instance.isPublic,
      'color': instance.color,
      'icon': instance.icon,
    };
