import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/offline_cache_models.dart';
import 'offline_cache_service.dart';

/// Service for managing network connectivity detection and status
class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance ??= ConnectivityService._();
  
  ConnectivityService._();
  
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final StreamController<ConnectivityStatus> _statusController = StreamController<ConnectivityStatus>.broadcast();
  
  ConnectivityStatus? _currentStatus;
  
  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;
  
  /// Current connectivity status
  ConnectivityStatus? get currentStatus => _currentStatus;
  
  /// Check if currently connected to internet
  bool get isConnected => _currentStatus?.isConnected ?? false;
  
  /// Get connection type (wifi, mobile, ethernet, none)
  String get connectionType => _currentStatus?.connectionType ?? 'none';

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      _logger.i('Initializing connectivity service...');
      
      // Check initial connectivity status
      await _checkConnectivity();
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error, stackTrace) {
          _logger.e('Connectivity stream error', error: error, stackTrace: stackTrace);
        },
      );
      
      _logger.i('Connectivity service initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize connectivity service', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check current connectivity status
  Future<ConnectivityStatus> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      final isConnected = connectivityResult != ConnectivityResult.none;
      final connectionType = _getConnectionTypeString(connectivityResult);
      
      final status = ConnectivityStatus.create(
        isConnected: isConnected,
        connectionType: connectionType,
      );
      
      _updateStatus(status);
      
      _logger.d('Connectivity check: $connectionType (connected: $isConnected)');
      
      return status;
    } catch (e, stackTrace) {
      _logger.e('Failed to check connectivity', error: e, stackTrace: stackTrace);
      
      // Return offline status on error
      final status = ConnectivityStatus.create(
        isConnected: false,
        connectionType: 'none',
      );
      
      _updateStatus(status);
      return status;
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    try {
      final isConnected = result != ConnectivityResult.none;
      final connectionType = _getConnectionTypeString(result);
      
      final newStatus = _currentStatus?.copyWith(
        isConnected: isConnected,
        connectionType: connectionType,
      ) ?? ConnectivityStatus.create(
        isConnected: isConnected,
        connectionType: connectionType,
      );
      
      _updateStatus(newStatus);
      
      _logger.i('Connectivity changed: $connectionType (connected: $isConnected)');
      
      // Trigger sync when connection is restored
      if (isConnected && (_currentStatus?.isConnected == false)) {
        _logger.i('Connection restored, triggering sync...');
        _triggerSync();
      }
    } catch (e, stackTrace) {
      _logger.e('Error handling connectivity change', error: e, stackTrace: stackTrace);
    }
  }

  /// Update current status and notify listeners
  void _updateStatus(ConnectivityStatus status) {
    _currentStatus = status;
    _statusController.add(status);
    
    // Cache connectivity status
    _cacheConnectivityStatus(status);
  }

  /// Cache connectivity status for offline access
  Future<void> _cacheConnectivityStatus(ConnectivityStatus status) async {
    try {
      await OfflineCacheService.instance.cacheConnectivityStatus(status);
    } catch (e, stackTrace) {
      _logger.e('Failed to cache connectivity status', error: e, stackTrace: stackTrace);
    }
  }

  /// Convert ConnectivityResult to string
  String _getConnectionTypeString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'wifi';
      case ConnectivityResult.mobile:
        return 'mobile';
      case ConnectivityResult.ethernet:
        return 'ethernet';
      case ConnectivityResult.bluetooth:
        return 'bluetooth';
      case ConnectivityResult.vpn:
        return 'vpn';
      case ConnectivityResult.other:
        return 'other';
      case ConnectivityResult.none:
        return 'none';
    }
  }

  /// Trigger sync when connectivity is restored
  void _triggerSync() {
    // This will be implemented by the sync service
    // For now, just log the event
    _logger.i('Sync trigger requested due to connectivity restoration');
  }

  /// Manually check connectivity (useful for pull-to-refresh)
  Future<ConnectivityStatus> checkConnectivity() async {
    return await _checkConnectivity();
  }

  /// Test internet connectivity by attempting to reach a reliable endpoint
  Future<bool> testInternetConnectivity() async {
    try {
      _logger.d('Testing internet connectivity...');
      
      // This would typically involve making a simple HTTP request
      // to a reliable endpoint like Google DNS or a health check endpoint
      // For now, we'll rely on the connectivity plugin
      
      final status = await _checkConnectivity();
      return status.isConnected;
    } catch (e, stackTrace) {
      _logger.e('Internet connectivity test failed', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get connectivity history from cache
  Future<List<ConnectivityStatus>> getConnectivityHistory({int limit = 10}) async {
    try {
      return OfflineCacheService.instance.getConnectivityHistory(limit: limit);
    } catch (e, stackTrace) {
      _logger.e('Failed to get connectivity history', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get connectivity statistics
  Map<String, dynamic> getConnectivityStats() {
    try {
      final status = _currentStatus;
      if (status == null) {
        return {
          'current_status': 'unknown',
          'is_connected': false,
          'connection_type': 'none',
          'last_checked': null,
        };
      }
      
      return {
        'current_status': status.isConnected ? 'connected' : 'disconnected',
        'is_connected': status.isConnected,
        'connection_type': status.connectionType,
        'last_checked': status.lastChecked.toIso8601String(),
        'last_connected': status.lastConnected?.toIso8601String(),
        'last_disconnected': status.lastDisconnected?.toIso8601String(),
      };
    } catch (e, stackTrace) {
      _logger.e('Failed to get connectivity stats', error: e, stackTrace: stackTrace);
      return {'error': e.toString()};
    }
  }

  /// Dispose of the service
  Future<void> dispose() async {
    try {
      await _connectivitySubscription?.cancel();
      await _statusController.close();
      _logger.i('Connectivity service disposed');
    } catch (e, stackTrace) {
      _logger.e('Error disposing connectivity service', error: e, stackTrace: stackTrace);
    }
  }
}

/// Riverpod provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Riverpod provider for connectivity status stream
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Riverpod provider for current connectivity status
final currentConnectivityProvider = Provider<ConnectivityStatus?>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.currentStatus;
});

/// Riverpod provider for connection state
final isConnectedProvider = Provider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isConnected;
});