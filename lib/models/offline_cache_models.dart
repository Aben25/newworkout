import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'models.dart';

part 'offline_cache_models.g.dart';

/// Offline workout cache with expiration
@HiveType(typeId: 50)
@JsonSerializable()
class OfflineWorkout extends HiveObject {
  @HiveField(0)
  final Workout workout;
  
  @HiveField(1)
  final List<Exercise> exercises;
  
  @HiveField(2)
  final DateTime cachedAt;
  
  @HiveField(3)
  final DateTime expiresAt;
  
  @HiveField(4)
  final bool isExpired;

  OfflineWorkout({
    required this.workout,
    required this.exercises,
    required this.cachedAt,
    required this.expiresAt,
  }) : isExpired = DateTime.now().isAfter(expiresAt);

  factory OfflineWorkout.fromJson(Map<String, dynamic> json) => _$OfflineWorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineWorkoutToJson(this);

  /// Create offline workout with default 7-day expiration
  factory OfflineWorkout.create({
    required Workout workout,
    required List<Exercise> exercises,
    Duration? cacheDuration,
  }) {
    final now = DateTime.now();
    return OfflineWorkout(
      workout: workout,
      exercises: exercises,
      cachedAt: now,
      expiresAt: now.add(cacheDuration ?? const Duration(days: 7)),
    );
  }

  /// Check if cache is still valid
  bool get isValid => !isExpired && DateTime.now().isBefore(expiresAt);
}

/// Sync queue item for offline operations
@HiveType(typeId: 51)
@JsonSerializable()
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final SyncType type;
  
  @HiveField(2)
  final Map<String, dynamic> data;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final int retryCount;
  
  @HiveField(5)
  final DateTime? lastRetryAt;
  
  @HiveField(6)
  final String? errorMessage;
  
  @HiveField(7)
  final SyncPriority priority;
  
  @HiveField(8)
  final bool requiresAuth;

  SyncQueueItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastRetryAt,
    this.errorMessage,
    this.priority = SyncPriority.normal,
    this.requiresAuth = true,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => _$SyncQueueItemFromJson(json);
  Map<String, dynamic> toJson() => _$SyncQueueItemToJson(this);

  /// Create a new sync queue item
  factory SyncQueueItem.create({
    required SyncType type,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.normal,
    bool requiresAuth = true,
  }) {
    return SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
      priority: priority,
      requiresAuth: requiresAuth,
    );
  }

  /// Create a copy with updated retry information
  SyncQueueItem copyWithRetry({
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id,
      type: type,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount + 1,
      lastRetryAt: DateTime.now(),
      errorMessage: errorMessage,
      priority: priority,
      requiresAuth: requiresAuth,
    );
  }

  /// Check if item should be retried based on exponential backoff
  bool get shouldRetry {
    if (retryCount >= 5) return false; // Max 5 retries
    if (lastRetryAt == null) return true;
    
    // Exponential backoff: 1min, 2min, 4min, 8min, 16min
    final backoffMinutes = 1 << retryCount;
    final nextRetryTime = lastRetryAt!.add(Duration(minutes: backoffMinutes));
    
    return DateTime.now().isAfter(nextRetryTime);
  }
}

/// Types of sync operations
@HiveType(typeId: 52)
enum SyncType {
  @HiveField(0)
  workoutLog,
  
  @HiveField(1)
  setLog,
  
  @HiveField(2)
  profileUpdate,
  
  @HiveField(3)
  workoutCreate,
  
  @HiveField(4)
  workoutUpdate,
  
  @HiveField(5)
  exerciseFavorite,
  
  @HiveField(6)
  exerciseCollection,
  
  @HiveField(7)
  completedWorkout,
  
  @HiveField(8)
  completedSet,
  
  @HiveField(9)
  workoutSession,
  
  @HiveField(10)
  analyticsData,
}

/// Priority levels for sync operations
@HiveType(typeId: 53)
enum SyncPriority {
  @HiveField(0)
  low,
  
  @HiveField(1)
  normal,
  
  @HiveField(2)
  high,
  
  @HiveField(3)
  critical,
}

/// Offline exercise cache with metadata
@HiveType(typeId: 54)
@JsonSerializable()
class OfflineExerciseCache extends HiveObject {
  @HiveField(0)
  final List<Exercise> exercises;
  
  @HiveField(1)
  final DateTime cachedAt;
  
  @HiveField(2)
  final DateTime expiresAt;
  
  @HiveField(3)
  final String version;
  
  @HiveField(4)
  final Map<String, dynamic> metadata;

  OfflineExerciseCache({
    required this.exercises,
    required this.cachedAt,
    required this.expiresAt,
    required this.version,
    this.metadata = const {},
  });

  factory OfflineExerciseCache.fromJson(Map<String, dynamic> json) => _$OfflineExerciseCacheFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineExerciseCacheToJson(this);

  /// Create exercise cache with default 24-hour expiration
  factory OfflineExerciseCache.create({
    required List<Exercise> exercises,
    Duration? cacheDuration,
    String? version,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return OfflineExerciseCache(
      exercises: exercises,
      cachedAt: now,
      expiresAt: now.add(cacheDuration ?? const Duration(hours: 24)),
      version: version ?? '1.0.0',
      metadata: metadata ?? {},
    );
  }

  /// Check if cache is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);
  
  /// Check if cache is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Network connectivity status
@HiveType(typeId: 55)
@JsonSerializable()
class ConnectivityStatus extends HiveObject {
  @HiveField(0)
  final bool isConnected;
  
  @HiveField(1)
  final String connectionType;
  
  @HiveField(2)
  final DateTime lastChecked;
  
  @HiveField(3)
  final DateTime? lastConnected;
  
  @HiveField(4)
  final DateTime? lastDisconnected;

  ConnectivityStatus({
    required this.isConnected,
    required this.connectionType,
    required this.lastChecked,
    this.lastConnected,
    this.lastDisconnected,
  });

  factory ConnectivityStatus.fromJson(Map<String, dynamic> json) => _$ConnectivityStatusFromJson(json);
  Map<String, dynamic> toJson() => _$ConnectivityStatusToJson(this);

  /// Create connectivity status
  factory ConnectivityStatus.create({
    required bool isConnected,
    required String connectionType,
  }) {
    final now = DateTime.now();
    return ConnectivityStatus(
      isConnected: isConnected,
      connectionType: connectionType,
      lastChecked: now,
      lastConnected: isConnected ? now : null,
      lastDisconnected: !isConnected ? now : null,
    );
  }

  /// Update connectivity status
  ConnectivityStatus copyWith({
    bool? isConnected,
    String? connectionType,
  }) {
    final now = DateTime.now();
    final wasConnected = this.isConnected;
    final willBeConnected = isConnected ?? this.isConnected;
    
    return ConnectivityStatus(
      isConnected: willBeConnected,
      connectionType: connectionType ?? this.connectionType,
      lastChecked: now,
      lastConnected: willBeConnected && !wasConnected ? now : lastConnected,
      lastDisconnected: !willBeConnected && wasConnected ? now : lastDisconnected,
    );
  }
}

/// Offline sync statistics
@HiveType(typeId: 56)
@JsonSerializable()
class OfflineSyncStats extends HiveObject {
  @HiveField(0)
  final int totalSyncItems;
  
  @HiveField(1)
  final int pendingSyncItems;
  
  @HiveField(2)
  final int failedSyncItems;
  
  @HiveField(3)
  final DateTime lastSyncAttempt;
  
  @HiveField(4)
  final DateTime? lastSuccessfulSync;
  
  @HiveField(5)
  final Map<String, int> syncTypeCount;
  
  @HiveField(6)
  final List<String> recentErrors;

  OfflineSyncStats({
    required this.totalSyncItems,
    required this.pendingSyncItems,
    required this.failedSyncItems,
    required this.lastSyncAttempt,
    this.lastSuccessfulSync,
    this.syncTypeCount = const {},
    this.recentErrors = const [],
  });

  factory OfflineSyncStats.fromJson(Map<String, dynamic> json) => _$OfflineSyncStatsFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineSyncStatsToJson(this);

  /// Create empty sync stats
  factory OfflineSyncStats.empty() {
    return OfflineSyncStats(
      totalSyncItems: 0,
      pendingSyncItems: 0,
      failedSyncItems: 0,
      lastSyncAttempt: DateTime.now(),
    );
  }
}