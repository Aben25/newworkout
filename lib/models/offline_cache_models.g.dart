// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_cache_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineWorkoutAdapter extends TypeAdapter<OfflineWorkout> {
  @override
  final int typeId = 50;

  @override
  OfflineWorkout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineWorkout(
      workout: fields[0] as Workout,
      exercises: (fields[1] as List).cast<Exercise>(),
      cachedAt: fields[2] as DateTime,
      expiresAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineWorkout obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.workout)
      ..writeByte(1)
      ..write(obj.exercises)
      ..writeByte(2)
      ..write(obj.cachedAt)
      ..writeByte(3)
      ..write(obj.expiresAt)
      ..writeByte(4)
      ..write(obj.isExpired);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineWorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 51;

  @override
  SyncQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueItem(
      id: fields[0] as String,
      type: fields[1] as SyncType,
      data: (fields[2] as Map).cast<String, dynamic>(),
      createdAt: fields[3] as DateTime,
      retryCount: fields[4] as int,
      lastRetryAt: fields[5] as DateTime?,
      errorMessage: fields[6] as String?,
      priority: fields[7] as SyncPriority,
      requiresAuth: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.lastRetryAt)
      ..writeByte(6)
      ..write(obj.errorMessage)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.requiresAuth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OfflineExerciseCacheAdapter extends TypeAdapter<OfflineExerciseCache> {
  @override
  final int typeId = 54;

  @override
  OfflineExerciseCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineExerciseCache(
      exercises: (fields[0] as List).cast<Exercise>(),
      cachedAt: fields[1] as DateTime,
      expiresAt: fields[2] as DateTime,
      version: fields[3] as String,
      metadata: (fields[4] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, OfflineExerciseCache obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.exercises)
      ..writeByte(1)
      ..write(obj.cachedAt)
      ..writeByte(2)
      ..write(obj.expiresAt)
      ..writeByte(3)
      ..write(obj.version)
      ..writeByte(4)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineExerciseCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConnectivityStatusAdapter extends TypeAdapter<ConnectivityStatus> {
  @override
  final int typeId = 55;

  @override
  ConnectivityStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConnectivityStatus(
      isConnected: fields[0] as bool,
      connectionType: fields[1] as String,
      lastChecked: fields[2] as DateTime,
      lastConnected: fields[3] as DateTime?,
      lastDisconnected: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ConnectivityStatus obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.isConnected)
      ..writeByte(1)
      ..write(obj.connectionType)
      ..writeByte(2)
      ..write(obj.lastChecked)
      ..writeByte(3)
      ..write(obj.lastConnected)
      ..writeByte(4)
      ..write(obj.lastDisconnected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OfflineSyncStatsAdapter extends TypeAdapter<OfflineSyncStats> {
  @override
  final int typeId = 56;

  @override
  OfflineSyncStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineSyncStats(
      totalSyncItems: fields[0] as int,
      pendingSyncItems: fields[1] as int,
      failedSyncItems: fields[2] as int,
      lastSyncAttempt: fields[3] as DateTime,
      lastSuccessfulSync: fields[4] as DateTime?,
      syncTypeCount: (fields[5] as Map).cast<String, int>(),
      recentErrors: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, OfflineSyncStats obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.totalSyncItems)
      ..writeByte(1)
      ..write(obj.pendingSyncItems)
      ..writeByte(2)
      ..write(obj.failedSyncItems)
      ..writeByte(3)
      ..write(obj.lastSyncAttempt)
      ..writeByte(4)
      ..write(obj.lastSuccessfulSync)
      ..writeByte(5)
      ..write(obj.syncTypeCount)
      ..writeByte(6)
      ..write(obj.recentErrors);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineSyncStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncTypeAdapter extends TypeAdapter<SyncType> {
  @override
  final int typeId = 52;

  @override
  SyncType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncType.workoutLog;
      case 1:
        return SyncType.setLog;
      case 2:
        return SyncType.profileUpdate;
      case 3:
        return SyncType.workoutCreate;
      case 4:
        return SyncType.workoutUpdate;
      case 5:
        return SyncType.exerciseFavorite;
      case 6:
        return SyncType.exerciseCollection;
      case 7:
        return SyncType.completedWorkout;
      case 8:
        return SyncType.completedSet;
      case 9:
        return SyncType.workoutSession;
      case 10:
        return SyncType.analyticsData;
      default:
        return SyncType.workoutLog;
    }
  }

  @override
  void write(BinaryWriter writer, SyncType obj) {
    switch (obj) {
      case SyncType.workoutLog:
        writer.writeByte(0);
        break;
      case SyncType.setLog:
        writer.writeByte(1);
        break;
      case SyncType.profileUpdate:
        writer.writeByte(2);
        break;
      case SyncType.workoutCreate:
        writer.writeByte(3);
        break;
      case SyncType.workoutUpdate:
        writer.writeByte(4);
        break;
      case SyncType.exerciseFavorite:
        writer.writeByte(5);
        break;
      case SyncType.exerciseCollection:
        writer.writeByte(6);
        break;
      case SyncType.completedWorkout:
        writer.writeByte(7);
        break;
      case SyncType.completedSet:
        writer.writeByte(8);
        break;
      case SyncType.workoutSession:
        writer.writeByte(9);
        break;
      case SyncType.analyticsData:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncPriorityAdapter extends TypeAdapter<SyncPriority> {
  @override
  final int typeId = 53;

  @override
  SyncPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncPriority.low;
      case 1:
        return SyncPriority.normal;
      case 2:
        return SyncPriority.high;
      case 3:
        return SyncPriority.critical;
      default:
        return SyncPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, SyncPriority obj) {
    switch (obj) {
      case SyncPriority.low:
        writer.writeByte(0);
        break;
      case SyncPriority.normal:
        writer.writeByte(1);
        break;
      case SyncPriority.high:
        writer.writeByte(2);
        break;
      case SyncPriority.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineWorkout _$OfflineWorkoutFromJson(Map<String, dynamic> json) =>
    OfflineWorkout(
      workout: Workout.fromJson(json['workout'] as Map<String, dynamic>),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$OfflineWorkoutToJson(OfflineWorkout instance) =>
    <String, dynamic>{
      'workout': instance.workout,
      'exercises': instance.exercises,
      'cachedAt': instance.cachedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

SyncQueueItem _$SyncQueueItemFromJson(Map<String, dynamic> json) =>
    SyncQueueItem(
      id: json['id'] as String,
      type: $enumDecode(_$SyncTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastRetryAt: json['lastRetryAt'] == null
          ? null
          : DateTime.parse(json['lastRetryAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      priority: $enumDecodeNullable(_$SyncPriorityEnumMap, json['priority']) ??
          SyncPriority.normal,
      requiresAuth: json['requiresAuth'] as bool? ?? true,
    );

Map<String, dynamic> _$SyncQueueItemToJson(SyncQueueItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SyncTypeEnumMap[instance.type]!,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'retryCount': instance.retryCount,
      'lastRetryAt': instance.lastRetryAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'priority': _$SyncPriorityEnumMap[instance.priority]!,
      'requiresAuth': instance.requiresAuth,
    };

const _$SyncTypeEnumMap = {
  SyncType.workoutLog: 'workoutLog',
  SyncType.setLog: 'setLog',
  SyncType.profileUpdate: 'profileUpdate',
  SyncType.workoutCreate: 'workoutCreate',
  SyncType.workoutUpdate: 'workoutUpdate',
  SyncType.exerciseFavorite: 'exerciseFavorite',
  SyncType.exerciseCollection: 'exerciseCollection',
  SyncType.completedWorkout: 'completedWorkout',
  SyncType.completedSet: 'completedSet',
  SyncType.workoutSession: 'workoutSession',
  SyncType.analyticsData: 'analyticsData',
};

const _$SyncPriorityEnumMap = {
  SyncPriority.low: 'low',
  SyncPriority.normal: 'normal',
  SyncPriority.high: 'high',
  SyncPriority.critical: 'critical',
};

OfflineExerciseCache _$OfflineExerciseCacheFromJson(
        Map<String, dynamic> json) =>
    OfflineExerciseCache(
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      version: json['version'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$OfflineExerciseCacheToJson(
        OfflineExerciseCache instance) =>
    <String, dynamic>{
      'exercises': instance.exercises,
      'cachedAt': instance.cachedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'version': instance.version,
      'metadata': instance.metadata,
    };

ConnectivityStatus _$ConnectivityStatusFromJson(Map<String, dynamic> json) =>
    ConnectivityStatus(
      isConnected: json['isConnected'] as bool,
      connectionType: json['connectionType'] as String,
      lastChecked: DateTime.parse(json['lastChecked'] as String),
      lastConnected: json['lastConnected'] == null
          ? null
          : DateTime.parse(json['lastConnected'] as String),
      lastDisconnected: json['lastDisconnected'] == null
          ? null
          : DateTime.parse(json['lastDisconnected'] as String),
    );

Map<String, dynamic> _$ConnectivityStatusToJson(ConnectivityStatus instance) =>
    <String, dynamic>{
      'isConnected': instance.isConnected,
      'connectionType': instance.connectionType,
      'lastChecked': instance.lastChecked.toIso8601String(),
      'lastConnected': instance.lastConnected?.toIso8601String(),
      'lastDisconnected': instance.lastDisconnected?.toIso8601String(),
    };

OfflineSyncStats _$OfflineSyncStatsFromJson(Map<String, dynamic> json) =>
    OfflineSyncStats(
      totalSyncItems: (json['totalSyncItems'] as num).toInt(),
      pendingSyncItems: (json['pendingSyncItems'] as num).toInt(),
      failedSyncItems: (json['failedSyncItems'] as num).toInt(),
      lastSyncAttempt: DateTime.parse(json['lastSyncAttempt'] as String),
      lastSuccessfulSync: json['lastSuccessfulSync'] == null
          ? null
          : DateTime.parse(json['lastSuccessfulSync'] as String),
      syncTypeCount: (json['syncTypeCount'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      recentErrors: (json['recentErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OfflineSyncStatsToJson(OfflineSyncStats instance) =>
    <String, dynamic>{
      'totalSyncItems': instance.totalSyncItems,
      'pendingSyncItems': instance.pendingSyncItems,
      'failedSyncItems': instance.failedSyncItems,
      'lastSyncAttempt': instance.lastSyncAttempt.toIso8601String(),
      'lastSuccessfulSync': instance.lastSuccessfulSync?.toIso8601String(),
      'syncTypeCount': instance.syncTypeCount,
      'recentErrors': instance.recentErrors,
    };
