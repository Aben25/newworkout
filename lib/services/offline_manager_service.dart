import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';
import 'offline_cache_service.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import 'background_sync_service.dart';

/// Comprehensive service for managing all offline functionality
class OfflineManagerService {
  static OfflineManagerService? _instance;
  static OfflineManagerService get instance => _instance ??= OfflineManagerService._();
  
  OfflineManagerService._();
  
  final Logger _logger = Logger();
  
  Timer? _cacheMaintenanceTimer;
  bool _isInitialized = false;
  
  /// Initialize offline manager
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.d('Offline manager already initialized');
      return;
    }
    
    try {
      _logger.i('Initializing offline manager...');
      
      // Start cache maintenance timer (daily)
      _startCacheMaintenance();
      
      // Perform initial cache cleanup
      await _performCacheCleanup();
      
      _isInitialized = true;
      _logger.i('Offline manager initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize offline manager', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Start cache maintenance timer
  void _startCacheMaintenance() {
    _cacheMaintenanceTimer?.cancel();
    
    _cacheMaintenanceTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      _logger.d('Performing scheduled cache maintenance...');
      unawaited(_performCacheCleanup());
    });
    
    _logger.d('Cache maintenance timer started');
  }

  /// Perform cache cleanup and maintenance
  Future<void> _performCacheCleanup() async {
    try {
      _logger.d('Starting cache cleanup...');
      
      // Clean expired cache entries
      await OfflineCacheService.instance.cleanExpiredCache();
      
      // Compact storage
      await OfflineCacheService.instance.compactCache();
      
      _logger.d('Cache cleanup completed');
    } catch (e, stackTrace) {
      _logger.e('Cache cleanup failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Cache workout for offline access
  Future<void> cacheWorkoutForOffline({
    required Workout workout,
    required List<Exercise> exercises,
    Duration? cacheDuration,
  }) async {
    try {
      final offlineWorkout = OfflineWorkout.create(
        workout: workout,
        exercises: exercises,
        cacheDuration: cacheDuration,
      );
      
      await OfflineCacheService.instance.cacheOfflineWorkout(offlineWorkout);
      
      _logger.i('Cached workout for offline access: ${workout.name}');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache workout for offline', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Cache exercises for offline access
  Future<void> cacheExercisesForOffline({
    required List<Exercise> exercises,
    Duration? cacheDuration,
    String? version,
  }) async {
    try {
      final exerciseCache = OfflineExerciseCache.create(
        exercises: exercises,
        cacheDuration: cacheDuration,
        version: version,
      );
      
      await OfflineCacheService.instance.cacheOfflineExercises(exerciseCache);
      
      _logger.i('Cached ${exercises.length} exercises for offline access');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache exercises for offline', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get available offline workouts
  List<OfflineWorkout> getOfflineWorkouts() {
    try {
      return OfflineCacheService.instance.getCachedOfflineWorkouts();
    } catch (e, stackTrace) {
      _logger.e('Failed to get offline workouts', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get offline workout by ID
  OfflineWorkout? getOfflineWorkout(String workoutId) {
    try {
      return OfflineCacheService.instance.getCachedOfflineWorkout(workoutId);
    } catch (e, stackTrace) {
      _logger.e('Failed to get offline workout', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get available offline exercises
  List<Exercise> getOfflineExercises() {
    try {
      return OfflineCacheService.instance.getValidCachedExercises();
    } catch (e, stackTrace) {
      _logger.e('Failed to get offline exercises', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Log workout data for offline sync
  Future<void> logWorkoutOffline({
    required WorkoutLog workoutLog,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    try {
      // Cache the workout log locally
      await OfflineCacheService.instance.cacheWorkoutLog(workoutLog);
      
      // Add to sync queue
      await SyncService.instance.addToSyncQueue(
        type: SyncType.workoutLog,
        data: workoutLog.toJson(),
        priority: priority,
      );
      
      _logger.d('Logged workout offline: ${workoutLog.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to log workout offline', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Log set data for offline sync
  Future<void> logSetOffline({
    required CompletedSet completedSet,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    try {
      // Cache the completed set locally
      await OfflineCacheService.instance.cacheCompletedSet(completedSet);
      
      // Add to sync queue
      await SyncService.instance.addToSyncQueue(
        type: SyncType.completedSet,
        data: completedSet.toJson(),
        priority: priority,
      );
      
      _logger.d('Logged set offline: ${completedSet.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to log set offline', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update profile offline
  Future<void> updateProfileOffline({
    required UserProfile profile,
    SyncPriority priority = SyncPriority.high,
  }) async {
    try {
      // Cache the profile locally
      await OfflineCacheService.instance.cacheUserProfile(profile);
      
      // Add to sync queue
      await SyncService.instance.addToSyncQueue(
        type: SyncType.profileUpdate,
        data: profile.toJson(),
        priority: priority,
      );
      
      _logger.d('Updated profile offline: ${profile.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to update profile offline', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Create workout offline
  Future<void> createWorkoutOffline({
    required Workout workout,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    try {
      // Cache the workout locally
      await OfflineCacheService.instance.cacheWorkout(workout);
      
      // Add to sync queue
      await SyncService.instance.addToSyncQueue(
        type: SyncType.workoutCreate,
        data: workout.toJson(),
        priority: priority,
      );
      
      _logger.d('Created workout offline: ${workout.name}');
    } catch (e, stackTrace) {
      _logger.e('Failed to create workout offline', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if app is in offline mode
  bool get isOfflineMode => !ConnectivityService.instance.isConnected;

  /// Check if offline data is available
  bool get hasOfflineData => OfflineCacheService.instance.hasOfflineData();

  /// Get offline mode status
  OfflineModeStatus getOfflineModeStatus() {
    final isConnected = ConnectivityService.instance.isConnected;
    final hasData = hasOfflineData;
    final syncItems = OfflineCacheService.instance.getSyncQueueItems();
    final pendingSync = syncItems.where((item) => item.shouldRetry).length;
    
    return OfflineModeStatus(
      isOffline: !isConnected,
      hasOfflineData: hasData,
      pendingSyncItems: pendingSync,
      lastSyncAttempt: _getLastSyncAttempt(),
      cacheStatistics: OfflineCacheService.instance.getEnhancedCacheStatistics(),
    );
  }

  /// Get last sync attempt time
  DateTime? _getLastSyncAttempt() {
    try {
      final syncStats = OfflineCacheService.instance.getCachedSyncStats();
      return syncStats?.lastSyncAttempt;
    } catch (e) {
      return null;
    }
  }

  /// Force sync all offline data
  Future<SyncResult> syncOfflineData() async {
    try {
      _logger.i('Forcing sync of offline data...');
      return await SyncService.instance.forceSyncAll();
    } catch (e, stackTrace) {
      _logger.e('Failed to sync offline data', error: e, stackTrace: stackTrace);
      return SyncResult.error(e.toString());
    }
  }

  /// Clear all offline data (use with caution)
  Future<void> clearOfflineData() async {
    try {
      _logger.w('Clearing all offline data...');
      await OfflineCacheService.instance.clearAllCache();
      _logger.i('All offline data cleared');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear offline data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get comprehensive offline statistics
  Map<String, dynamic> getOfflineStatistics() {
    try {
      final cacheStats = OfflineCacheService.instance.getEnhancedCacheStatistics();
      final connectivityStats = ConnectivityService.instance.getConnectivityStats();
      final backgroundSyncStats = BackgroundSyncService.instance.getBackgroundSyncStats();
      
      return {
        'offline_mode': isOfflineMode,
        'has_offline_data': hasOfflineData,
        'cache_statistics': cacheStats,
        'connectivity_statistics': connectivityStats,
        'background_sync_statistics': backgroundSyncStats,
        'last_maintenance': _cacheMaintenanceTimer != null ? 'Active' : 'Inactive',
        'is_initialized': _isInitialized,
      };
    } catch (e, stackTrace) {
      _logger.e('Failed to get offline statistics', error: e, stackTrace: stackTrace);
      return {'error': e.toString()};
    }
  }

  /// Enable offline mode features
  void enableOfflineMode() {
    try {
      BackgroundSyncService.instance.enableBackgroundSync();
      _logger.i('Offline mode features enabled');
    } catch (e, stackTrace) {
      _logger.e('Failed to enable offline mode', error: e, stackTrace: stackTrace);
    }
  }

  /// Disable offline mode features
  void disableOfflineMode() {
    try {
      BackgroundSyncService.instance.disableBackgroundSync();
      _logger.i('Offline mode features disabled');
    } catch (e, stackTrace) {
      _logger.e('Failed to disable offline mode', error: e, stackTrace: stackTrace);
    }
  }

  /// Dispose of the service
  Future<void> dispose() async {
    try {
      _cacheMaintenanceTimer?.cancel();
      _isInitialized = false;
      _logger.i('Offline manager disposed');
    } catch (e, stackTrace) {
      _logger.e('Error disposing offline manager', error: e, stackTrace: stackTrace);
    }
  }
}

/// Offline mode status information
class OfflineModeStatus {
  final bool isOffline;
  final bool hasOfflineData;
  final int pendingSyncItems;
  final DateTime? lastSyncAttempt;
  final Map<String, dynamic> cacheStatistics;

  OfflineModeStatus({
    required this.isOffline,
    required this.hasOfflineData,
    required this.pendingSyncItems,
    this.lastSyncAttempt,
    required this.cacheStatistics,
  });

  /// Check if offline mode is fully functional
  bool get isOfflineFunctional => hasOfflineData;

  /// Check if sync is needed
  bool get needsSync => pendingSyncItems > 0;

  /// Get status message
  String get statusMessage {
    if (!isOffline) {
      return 'Online - All features available';
    } else if (hasOfflineData) {
      return 'Offline - Limited features available';
    } else {
      return 'Offline - No cached data available';
    }
  }
}

/// Riverpod providers for offline manager
final offlineManagerProvider = Provider<OfflineManagerService>((ref) {
  return OfflineManagerService.instance;
});

final offlineModeStatusProvider = Provider<OfflineModeStatus>((ref) {
  final manager = ref.watch(offlineManagerProvider);
  return manager.getOfflineModeStatus();
});

final isOfflineModeProvider = Provider<bool>((ref) {
  final manager = ref.watch(offlineManagerProvider);
  return manager.isOfflineMode;
});

final hasOfflineDataProvider = Provider<bool>((ref) {
  final manager = ref.watch(offlineManagerProvider);
  return manager.hasOfflineData;
});

/// Extension for unawaited futures
extension UnawaiteExtension on Future {
  void get unawaited {}
}