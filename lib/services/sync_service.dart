import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// Service for managing data synchronization between local cache and server
class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  
  SyncService._();
  
  final Logger _logger = Logger();
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  /// Current sync status
  bool get isSyncing => _isSyncing;

  /// Initialize sync service
  Future<void> initialize() async {
    try {
      _logger.i('Initializing sync service...');
      
      // Listen for connectivity changes to trigger sync
      ConnectivityService.instance.statusStream.listen((status) {
        if (status.isConnected && !_isSyncing) {
          _logger.i('Connectivity restored, starting sync...');
          unawaited(syncPendingData());
        }
      });
      
      // Start periodic sync timer (every 5 minutes when connected)
      _startPeriodicSync();
      
      _logger.i('Sync service initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize sync service', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (ConnectivityService.instance.isConnected && !_isSyncing) {
        unawaited(syncPendingData());
      }
    });
  }

  /// Add item to sync queue
  Future<void> addToSyncQueue({
    required SyncType type,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.normal,
    bool requiresAuth = true,
  }) async {
    try {
      final item = SyncQueueItem.create(
        type: type,
        data: data,
        priority: priority,
        requiresAuth: requiresAuth,
      );
      
      await OfflineCacheService.instance.addSyncQueueItem(item);
      
      _logger.d('Added ${type.name} to sync queue with priority ${priority.name}');
      
      // Trigger immediate sync if connected and high/critical priority
      if (ConnectivityService.instance.isConnected && 
          (priority == SyncPriority.high || priority == SyncPriority.critical)) {
        unawaited(syncPendingData());
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to add item to sync queue', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sync all pending data
  Future<SyncResult> syncPendingData() async {
    if (_isSyncing) {
      _logger.d('Sync already in progress, skipping...');
      return SyncResult.skipped();
    }
    
    if (!ConnectivityService.instance.isConnected) {
      _logger.d('No internet connection, skipping sync');
      return SyncResult.noConnection();
    }

    _isSyncing = true;
    _updateSyncStatus(SyncStatus.syncing());
    
    try {
      _logger.i('Starting data synchronization...');
      
      final syncItems = OfflineCacheService.instance.getSyncQueueItems();
      if (syncItems.isEmpty) {
        _logger.d('No items to sync');
        _updateSyncStatus(SyncStatus.idle());
        return SyncResult.success(syncedCount: 0);
      }
      
      _logger.i('Found ${syncItems.length} items to sync');
      
      // Sort by priority (critical first, then by creation time)
      syncItems.sort((a, b) {
        final priorityComparison = _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority));
        if (priorityComparison != 0) return priorityComparison;
        return a.createdAt.compareTo(b.createdAt);
      });
      
      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = [];
      
      for (final item in syncItems) {
        try {
          // Skip items that shouldn't be retried yet
          if (!item.shouldRetry) {
            _logger.d('Skipping ${item.type.name} (${item.id}) - not ready for retry');
            continue;
          }
          
          _logger.d('Syncing ${item.type.name} (${item.id})...');
          
          final success = await _syncItem(item);
          
          if (success) {
            await OfflineCacheService.instance.removeSyncQueueItem(item.id);
            successCount++;
            _logger.d('Successfully synced ${item.type.name} (${item.id})');
          } else {
            // Update retry count and error
            final updatedItem = item.copyWithRetry(
              errorMessage: 'Sync failed - will retry later',
            );
            await OfflineCacheService.instance.updateSyncQueueItem(updatedItem);
            failureCount++;
            errors.add('${item.type.name}: Sync failed');
          }
        } catch (e, stackTrace) {
          _logger.e('Error syncing ${item.type.name} (${item.id})', error: e, stackTrace: stackTrace);
          
          // Update retry count and error message
          final updatedItem = item.copyWithRetry(
            errorMessage: e.toString(),
          );
          await OfflineCacheService.instance.updateSyncQueueItem(updatedItem);
          failureCount++;
          errors.add('${item.type.name}: ${e.toString()}');
        }
      }
      
      _logger.i('Sync completed: $successCount successful, $failureCount failed');
      
      final result = SyncResult.completed(
        syncedCount: successCount,
        failedCount: failureCount,
        errors: errors,
      );
      
      _updateSyncStatus(SyncStatus.completed(result));
      
      return result;
    } catch (e, stackTrace) {
      _logger.e('Sync process failed', error: e, stackTrace: stackTrace);
      
      final result = SyncResult.error(e.toString());
      _updateSyncStatus(SyncStatus.error(e.toString()));
      
      return result;
    } finally {
      _isSyncing = false;
      
      // Schedule next sync status update to idle after a delay
      Timer(const Duration(seconds: 3), () {
        if (!_isSyncing) {
          _updateSyncStatus(SyncStatus.idle());
        }
      });
    }
  }

  /// Sync individual item based on type
  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      // Check authentication if required
      if (item.requiresAuth && !AuthService.instance.isAuthenticated) {
        _logger.w('Skipping ${item.type.name} - user not authenticated');
        return false;
      }
      
      switch (item.type) {
        case SyncType.workoutLog:
          return await _syncWorkoutLog(item.data);
        case SyncType.setLog:
          return await _syncSetLog(item.data);
        case SyncType.profileUpdate:
          return await _syncProfileUpdate(item.data);
        case SyncType.workoutCreate:
          return await _syncWorkoutCreate(item.data);
        case SyncType.workoutUpdate:
          return await _syncWorkoutUpdate(item.data);
        case SyncType.exerciseFavorite:
          return await _syncExerciseFavorite(item.data);
        case SyncType.exerciseCollection:
          return await _syncExerciseCollection(item.data);
        case SyncType.completedWorkout:
          return await _syncCompletedWorkout(item.data);
        case SyncType.completedSet:
          return await _syncCompletedSet(item.data);
        case SyncType.workoutSession:
          return await _syncWorkoutSession(item.data);
        case SyncType.analyticsData:
          return await _syncAnalyticsData(item.data);
        default:
          _logger.w('Unknown sync type: ${item.type}');
          return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to sync ${item.type.name}', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Sync workout log
  Future<bool> _syncWorkoutLog(Map<String, dynamic> data) async {
    try {
      final workoutLog = WorkoutLog.fromJson(data);
      await SupabaseService.instance.insertWorkoutLog(workoutLog);
      return true;
    } catch (e) {
      _logger.e('Failed to sync workout log', error: e);
      return false;
    }
  }

  /// Sync set log
  Future<bool> _syncSetLog(Map<String, dynamic> data) async {
    try {
      final setLog = WorkoutSetLog.fromJson(data);
      await SupabaseService.instance.insertWorkoutSetLog(setLog);
      return true;
    } catch (e) {
      _logger.e('Failed to sync set log', error: e);
      return false;
    }
  }

  /// Sync profile update
  Future<bool> _syncProfileUpdate(Map<String, dynamic> data) async {
    try {
      final profile = UserProfile.fromJson(data);
      await SupabaseService.instance.updateUserProfile(profile);
      return true;
    } catch (e) {
      _logger.e('Failed to sync profile update', error: e);
      return false;
    }
  }

  /// Sync workout creation
  Future<bool> _syncWorkoutCreate(Map<String, dynamic> data) async {
    try {
      final workout = Workout.fromJson(data);
      await SupabaseService.instance.createWorkout(workout);
      return true;
    } catch (e) {
      _logger.e('Failed to sync workout creation', error: e);
      return false;
    }
  }

  /// Sync workout update
  Future<bool> _syncWorkoutUpdate(Map<String, dynamic> data) async {
    try {
      final workout = Workout.fromJson(data);
      await SupabaseService.instance.updateWorkout(workout);
      return true;
    } catch (e) {
      _logger.e('Failed to sync workout update', error: e);
      return false;
    }
  }

  /// Sync exercise favorite
  Future<bool> _syncExerciseFavorite(Map<String, dynamic> data) async {
    try {
      final favorite = ExerciseFavorite.fromJson(data);
      await SupabaseService.instance.addExerciseFavorite(favorite);
      return true;
    } catch (e) {
      _logger.e('Failed to sync exercise favorite', error: e);
      return false;
    }
  }

  /// Sync exercise collection
  Future<bool> _syncExerciseCollection(Map<String, dynamic> data) async {
    try {
      final collection = ExerciseCollection.fromJson(data);
      await SupabaseService.instance.createExerciseCollection(collection);
      return true;
    } catch (e) {
      _logger.e('Failed to sync exercise collection', error: e);
      return false;
    }
  }

  /// Sync completed workout
  Future<bool> _syncCompletedWorkout(Map<String, dynamic> data) async {
    try {
      final completedWorkout = CompletedWorkout.fromJson(data);
      await SupabaseService.instance.insertCompletedWorkout(completedWorkout);
      return true;
    } catch (e) {
      _logger.e('Failed to sync completed workout', error: e);
      return false;
    }
  }

  /// Sync completed set
  Future<bool> _syncCompletedSet(Map<String, dynamic> data) async {
    try {
      final completedSet = CompletedSet.fromJson(data);
      await SupabaseService.instance.insertCompletedSet(completedSet);
      return true;
    } catch (e) {
      _logger.e('Failed to sync completed set', error: e);
      return false;
    }
  }

  /// Sync workout session
  Future<bool> _syncWorkoutSession(Map<String, dynamic> data) async {
    try {
      final workout = Workout.fromJson(data);
      await SupabaseService.instance.updateWorkout(workout);
      return true;
    } catch (e) {
      _logger.e('Failed to sync workout session', error: e);
      return false;
    }
  }

  /// Sync analytics data
  Future<bool> _syncAnalyticsData(Map<String, dynamic> data) async {
    try {
      // Analytics data is typically read-only, so this might not be needed
      // But we can implement it for completeness
      _logger.d('Analytics data sync not implemented yet');
      return true;
    } catch (e) {
      _logger.e('Failed to sync analytics data', error: e);
      return false;
    }
  }

  /// Get priority value for sorting
  int _getPriorityValue(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.critical:
        return 4;
      case SyncPriority.high:
        return 3;
      case SyncPriority.normal:
        return 2;
      case SyncPriority.low:
        return 1;
    }
  }

  /// Update sync status and notify listeners
  void _updateSyncStatus(SyncStatus status) {
    _syncStatusController.add(status);
  }

  /// Force sync all data (useful for manual refresh)
  Future<SyncResult> forceSyncAll() async {
    _logger.i('Force syncing all data...');
    return await syncPendingData();
  }

  /// Get sync queue statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final items = OfflineCacheService.instance.getSyncQueueItems();
      
      final stats = <String, dynamic>{
        'total_items': items.length,
        'pending_items': items.where((item) => item.shouldRetry).length,
        'failed_items': items.where((item) => !item.shouldRetry && item.retryCount > 0).length,
        'by_type': <String, int>{},
        'by_priority': <String, int>{},
        'oldest_item': null,
        'newest_item': null,
      };
      
      if (items.isNotEmpty) {
        // Count by type
        for (final item in items) {
          final typeName = item.type.name;
          stats['by_type'][typeName] = (stats['by_type'][typeName] ?? 0) + 1;
          
          final priorityName = item.priority.name;
          stats['by_priority'][priorityName] = (stats['by_priority'][priorityName] ?? 0) + 1;
        }
        
        // Find oldest and newest items
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        stats['oldest_item'] = items.first.createdAt.toIso8601String();
        stats['newest_item'] = items.last.createdAt.toIso8601String();
      }
      
      return stats;
    } catch (e, stackTrace) {
      _logger.e('Failed to get sync stats', error: e, stackTrace: stackTrace);
      return {'error': e.toString()};
    }
  }

  /// Clear all sync queue items (use with caution)
  Future<void> clearSyncQueue() async {
    try {
      await OfflineCacheService.instance.clearSyncQueue();
      _logger.i('Sync queue cleared');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear sync queue', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Dispose of the service
  Future<void> dispose() async {
    try {
      _syncTimer?.cancel();
      await _syncStatusController.close();
      _logger.i('Sync service disposed');
    } catch (e, stackTrace) {
      _logger.e('Error disposing sync service', error: e, stackTrace: stackTrace);
    }
  }
}

/// Sync status information
class SyncStatus {
  final SyncState state;
  final String? message;
  final SyncResult? result;
  final DateTime timestamp;

  SyncStatus._({
    required this.state,
    this.message,
    this.result,
    required this.timestamp,
  });

  factory SyncStatus.idle() => SyncStatus._(
    state: SyncState.idle,
    timestamp: DateTime.now(),
  );

  factory SyncStatus.syncing({String? message}) => SyncStatus._(
    state: SyncState.syncing,
    message: message ?? 'Syncing data...',
    timestamp: DateTime.now(),
  );

  factory SyncStatus.completed(SyncResult result) => SyncStatus._(
    state: SyncState.completed,
    result: result,
    message: 'Sync completed',
    timestamp: DateTime.now(),
  );

  factory SyncStatus.error(String error) => SyncStatus._(
    state: SyncState.error,
    message: error,
    timestamp: DateTime.now(),
  );
}

/// Sync state enumeration
enum SyncState {
  idle,
  syncing,
  completed,
  error,
}

/// Sync result information
class SyncResult {
  final SyncResultType type;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;
  final String? message;

  SyncResult._({
    required this.type,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
    this.message,
  });

  factory SyncResult.success({required int syncedCount}) => SyncResult._(
    type: SyncResultType.success,
    syncedCount: syncedCount,
  );

  factory SyncResult.completed({
    required int syncedCount,
    required int failedCount,
    required List<String> errors,
  }) => SyncResult._(
    type: failedCount > 0 ? SyncResultType.partial : SyncResultType.success,
    syncedCount: syncedCount,
    failedCount: failedCount,
    errors: errors,
  );

  factory SyncResult.error(String message) => SyncResult._(
    type: SyncResultType.error,
    message: message,
  );

  factory SyncResult.skipped() => SyncResult._(
    type: SyncResultType.skipped,
    message: 'Sync already in progress',
  );

  factory SyncResult.noConnection() => SyncResult._(
    type: SyncResultType.noConnection,
    message: 'No internet connection',
  );

  bool get isSuccess => type == SyncResultType.success;
  bool get hasErrors => errors.isNotEmpty || type == SyncResultType.error;
}

/// Sync result type enumeration
enum SyncResultType {
  success,
  partial,
  error,
  skipped,
  noConnection,
}

/// Riverpod providers for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.syncStatusStream;
});

final isSyncingProvider = Provider<bool>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.isSyncing;
});

/// Extension for unawaited futures
extension UnawaiteExtension on Future {
  void get unawaited {}
}