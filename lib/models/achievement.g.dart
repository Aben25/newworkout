// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 14;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      icon: fields[3] as String,
      type: fields[4] as AchievementType,
      rarity: fields[5] as AchievementRarity,
      criteria: (fields[6] as Map).cast<String, dynamic>(),
      points: fields[7] as int,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.rarity)
      ..writeByte(6)
      ..write(obj.criteria)
      ..writeByte(7)
      ..write(obj.points)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserAchievementAdapter extends TypeAdapter<UserAchievement> {
  @override
  final int typeId = 15;

  @override
  UserAchievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserAchievement(
      id: fields[0] as String,
      userId: fields[1] as String,
      achievementId: fields[2] as String,
      unlockedAt: fields[3] as DateTime,
      workoutId: fields[4] as String?,
      metadata: (fields[5] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserAchievement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.achievementId)
      ..writeByte(3)
      ..write(obj.unlockedAt)
      ..writeByte(4)
      ..write(obj.workoutId)
      ..writeByte(5)
      ..write(obj.metadata)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 37;

  @override
  AchievementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementType.workout;
      case 1:
        return AchievementType.strength;
      case 2:
        return AchievementType.endurance;
      case 3:
        return AchievementType.consistency;
      case 4:
        return AchievementType.volume;
      case 5:
        return AchievementType.personal_record;
      case 6:
        return AchievementType.milestone;
      case 7:
        return AchievementType.social;
      default:
        return AchievementType.workout;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementType obj) {
    switch (obj) {
      case AchievementType.workout:
        writer.writeByte(0);
        break;
      case AchievementType.strength:
        writer.writeByte(1);
        break;
      case AchievementType.endurance:
        writer.writeByte(2);
        break;
      case AchievementType.consistency:
        writer.writeByte(3);
        break;
      case AchievementType.volume:
        writer.writeByte(4);
        break;
      case AchievementType.personal_record:
        writer.writeByte(5);
        break;
      case AchievementType.milestone:
        writer.writeByte(6);
        break;
      case AchievementType.social:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementRarityAdapter extends TypeAdapter<AchievementRarity> {
  @override
  final int typeId = 38;

  @override
  AchievementRarity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementRarity.common;
      case 1:
        return AchievementRarity.uncommon;
      case 2:
        return AchievementRarity.rare;
      case 3:
        return AchievementRarity.epic;
      case 4:
        return AchievementRarity.legendary;
      default:
        return AchievementRarity.common;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementRarity obj) {
    switch (obj) {
      case AchievementRarity.common:
        writer.writeByte(0);
        break;
      case AchievementRarity.uncommon:
        writer.writeByte(1);
        break;
      case AchievementRarity.rare:
        writer.writeByte(2);
        break;
      case AchievementRarity.epic:
        writer.writeByte(3);
        break;
      case AchievementRarity.legendary:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementRarityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
      rarity: $enumDecode(_$AchievementRarityEnumMap, json['rarity']),
      criteria: json['criteria'] as Map<String, dynamic>,
      points: (json['points'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'rarity': _$AchievementRarityEnumMap[instance.rarity]!,
      'criteria': instance.criteria,
      'points': instance.points,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$AchievementTypeEnumMap = {
  AchievementType.workout: 'workout',
  AchievementType.strength: 'strength',
  AchievementType.endurance: 'endurance',
  AchievementType.consistency: 'consistency',
  AchievementType.volume: 'volume',
  AchievementType.personal_record: 'personal_record',
  AchievementType.milestone: 'milestone',
  AchievementType.social: 'social',
};

const _$AchievementRarityEnumMap = {
  AchievementRarity.common: 'common',
  AchievementRarity.uncommon: 'uncommon',
  AchievementRarity.rare: 'rare',
  AchievementRarity.epic: 'epic',
  AchievementRarity.legendary: 'legendary',
};

UserAchievement _$UserAchievementFromJson(Map<String, dynamic> json) =>
    UserAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      workoutId: json['workout_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserAchievementToJson(UserAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'achievement_id': instance.achievementId,
      'unlocked_at': instance.unlockedAt.toIso8601String(),
      'workout_id': instance.workoutId,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
    };
