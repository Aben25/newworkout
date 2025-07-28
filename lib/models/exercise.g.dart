// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 1;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      instructions: fields[3] as String?,
      videoUrl: fields[4] as String?,
      verticalVideo: fields[5] as String?,
      primaryMuscle: fields[6] as String?,
      secondaryMuscle: fields[7] as String?,
      equipment: fields[8] as String?,
      category: fields[9] as String?,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.instructions)
      ..writeByte(4)
      ..write(obj.videoUrl)
      ..writeByte(5)
      ..write(obj.verticalVideo)
      ..writeByte(6)
      ..write(obj.primaryMuscle)
      ..writeByte(7)
      ..write(obj.secondaryMuscle)
      ..writeByte(8)
      ..write(obj.equipment)
      ..writeByte(9)
      ..write(obj.category)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      videoUrl: json['video_url'] as String?,
      verticalVideo: json['vertical_video'] as String?,
      primaryMuscle: json['primary_muscle'] as String?,
      secondaryMuscle: json['secondary_muscle'] as String?,
      equipment: json['equipment'] as String?,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'instructions': instance.instructions,
      'video_url': instance.videoUrl,
      'vertical_video': instance.verticalVideo,
      'primary_muscle': instance.primaryMuscle,
      'secondary_muscle': instance.secondaryMuscle,
      'equipment': instance.equipment,
      'category': instance.category,
      'created_at': instance.createdAt.toIso8601String(),
    };
