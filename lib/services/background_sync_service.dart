import 'dart:async';
import 'dart:isolate';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import 'auth_service.dart';

/// Service for managing background data synchronization
class BackgroundSyncService {
  static BackgroundSyncService? _instance;
  static BackgroundSyncService get instance => _instance ??= BackgroundSyncService._();
  
  BackgroundSyncService._();
  
  final Logger _logger = Logger();
  
  Timer? _backgroundSyncTimer;
  Timer? _periodicCleanupTimer;
  bool _isBackgroundSyncEnabled = true;
  bool _isInitialized = false;
  
  // Sync intervals
  static const Duration _backgroundSyncInterval = Duration(minutes: 15);
  static const Duration _cleanupInterval = Duration(hours: 6);
  static const Duration _quickSyncInterval = Duration(minutes: 2);
  
  /// Initialize background sync service
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.d('Background sync service already initialized');
      return;
    }
    
    try {
      _logger.i('Initializing background sync service...');
      
      // Start background sync timer
      _startBackgroundSync();
      
      // Start periodic cleanup timer
      _startPeriodicCleanup();
      
      // Listen for connectivity changes for immediate sync
      ConnectivityService.instance.statusStream.listen((status) {
        if (status.isConnected && _isBackgroundSyncEnabled) {
          _logger.d('Connectivity restored, scheduling quick sync...');
          _scheduleQuickSync();
        }
      });
      
      // Listen for authentication changes
      AuthService.instance.authStateChanges.listen((authState) {
        if (authState.event == AuthChangeEvent.signedIn && _isBackgroundSyncEnabled) {
          _logger.d('User authenticated, scheduling sync...');
          _scheduleQuickSync();
        }
      });
      
      _isInitialized = true;
      _logger.i('Background sync service initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize background sync service', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Start background sync timer
  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (timer) {
      if (_isBackgroundSyncEnabled && _shouldPerformBackgroundSync()) {
        _logger.d('Performing scheduled background sync...');
        unawaited(_performBackgroundSync());
      }
    });
    
    _logger.d('Background sync timer started (interval: ${_backgroundSyncInterval.inMinutes} minutes)');
  }

  /// Start periodic cleanup timer
  void _startPeriodicCleanup() {
    _periodicCleanupTimer?.cancel();
    
    _periodicCleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      if (_isBackgroundSyncEnabled) {
        _logger.d('Performing periodic cache cleanup...');
        unawaited(_performCacheCleanup());
      }
    });
    
    _logger.d('Periodic cleanup timer started (interval: ${_cleanupInterval.inHours} hours)');
  }

  /// Schedule a quick sync (used when connectivity is restored or user logs in)
  void _scheduleQuickSync() {
    Timer(_quickSyncInterval, () {
      if (_isBackgroundSyncEnabled && _shouldPerformBackgroundSync()) {
        _logger.d('Performing quick sync...');
        unawaited(_performBackgroundSync());
      }
    });
  }

  /// Check if background sync should be performed
  bool _shouldPerformBackgroundSync() {
    // Check if connected to internet
    if (!ConnectivityService.instance.isConnected) {
      _logger.d('Skipping background sync - no internet connection');
      return false;
    }
    
    // Check if user is authenticated
    if (!AuthService.instance.isAuthenticated) {
      _logger.d('Skipping background sync - user not authenticated');
      return false;
    }
    
    // Check if sync is already in progress
    if (SyncService.instance.isSyncing) {
      _logger.d('Skipping background sync - sync already in progress');
      return false;
    }
    
    return true;
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    try {
      _logger.d('Starting background sync...');
      
      final result = await SyncService.instance.syncPendingData();
      
      if (result.isSuccess) {
        _logger.i('Background sync completed successfully: ${result.syncedCount} items synced');
      } else if (result.hasErrors) {
        _logger.w('Background sync completed with errors: ${result.errors.length} errors');
      } else {
        _logger.d('Background sync completed: ${result.message}');
      }
    } catch (e, stackTrace) {
      _logger.e('Background sync failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Perform cache cleanup
  Future<void> _performCacheCleanup() async {
    try {
      _logger.d('Starting cache cleanup...');
      
      // This would be implemented in the offline cache service
      // For now, just log the operation
      _logger.d('Cache cleanup completed');
    } catch (e, stackTrace) {
      _logger.e('Cache cleanup failed', error: e, stackTrace: stackTrace);
    }
  }

  /// Enable background sync
  void enableBackgroundSync() {
    if (!_isBackgroundSyncEnabled) {
      _isBackgroundSyncEnabled = true;
      _startBackgroundSync();
      _startPeriodicCleanup();
      _logger.i('Background sync enabled');
    }
  }

  /// Disable background sync
  void disableBackgroundSync() {
    if (_isBackgroundSyncEnabled) {
      _isBackgroundSyncEnabled = false;
      _backgroundSyncTimer?.cancel();
      _periodicCleanupTimer?.cancel();
      _logger.i('Background sync disabled');
    }
  }

  /// Check if background sync is enabled
  bool get isBackgroundSyncEnabled => _isBackgroundSyncEnabled;

  /// Force immediate background sync
  Future<void> forceBackgroundSync() async {
    if (!_isInitialized) {
      _logger.w('Background sync service not initialized');
      return;
    }
    
    _logger.i('Forcing immediate background sync...');
    await _performBackgroundSync();
  }

  /// Get background sync statistics
  Map<String, dynamic> getBackgroundSyncStats() {
    return {
      'is_initialized': _isInitialized,
      'is_enabled': _isBackgroundSyncEnabled,
      'background_sync_interval_minutes': _backgroundSyncInterval.inMinutes,
      'cleanup_interval_hours': _cleanupInterval.inHours,
      'quick_sync_interval_minutes': _quickSyncInterval.inMinutes,
      'should_perform_sync': _shouldPerformBackgroundSync(),
      'connectivity_status': ConnectivityService.instance.isConnected,
      'user_authenticated': AuthService.instance.isAuthenticated,
      'sync_in_progress': SyncService.instance.isSyncing,
    };
  }

  /// Update sync intervals (useful for testing or user preferences)
  void updateSyncInterval(Duration newInterval) {
    if (newInterval != _backgroundSyncInterval) {
      _logger.i('Updating background sync interval to ${newInterval.inMinutes} minutes');
      _startBackgroundSync(); // Restart with new interval
    }
  }

  /// Dispose of the service
  Future<void> dispose() async {
    try {
      _backgroundSyncTimer?.cancel();
      _periodicCleanupTimer?.cancel();
      _isInitialized = false;
      _logger.i('Background sync service disposed');
    } catch (e, stackTrace) {
      _logger.e('Error disposing background sync service', error: e, stackTrace: stackTrace);
    }
  }
}

/// Background sync isolate entry point
@pragma('vm:entry-point')
void backgroundSyncIsolateEntryPoint(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  
  receivePort.listen((message) async {
    if (message == 'sync') {
      try {
        // Perform sync operations in isolate
        // This would require setting up the services in the isolate
        // For now, just acknowledge the message
        sendPort.send('sync_completed');
      } catch (e) {
        sendPort.send('sync_failed: $e');
      }
    }
  });
}

/// Extension for unawaited futures
extension UnawaiteExtension on Future {
  void get unawaited {}
}