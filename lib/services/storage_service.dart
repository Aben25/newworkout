import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import '../utils/hive_adapters.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();
  
  final Logger _logger = Logger();
  
  /// Initialize Hive storage
  static Future<void> initialize() async {
    try {
      // Register all Hive adapters for models
      await HiveAdapters.registerAdapters();
      
      // Open all required boxes
      await HiveAdapters.openBoxes();
      
      // Open legacy boxes for backward compatibility
      await Hive.openBox(AppConstants.userProfileBox);
      await Hive.openBox(AppConstants.workoutCacheBox);
      await Hive.openBox(AppConstants.syncQueueBox);
      await Hive.openBox(AppConstants.settingsBox);
      
      instance._logger.i('Hive storage initialized successfully');
    } catch (e, stackTrace) {
      instance._logger.e(
        'Failed to initialize Hive storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Get a Hive box by name
  Box getBox(String boxName) {
    return Hive.box(boxName);
  }
  
  /// Store data in a specific box
  Future<void> store(String boxName, String key, dynamic value) async {
    try {
      final box = getBox(boxName);
      await box.put(key, value);
      _logger.d('Stored data in $boxName with key: $key');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to store data in $boxName',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Retrieve data from a specific box
  T? retrieve<T>(String boxName, String key) {
    try {
      final box = getBox(boxName);
      return box.get(key) as T?;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to retrieve data from $boxName',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Delete data from a specific box
  Future<void> delete(String boxName, String key) async {
    try {
      final box = getBox(boxName);
      await box.delete(key);
      _logger.d('Deleted data from $boxName with key: $key');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to delete data from $boxName',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Clear all data from a specific box
  Future<void> clearBox(String boxName) async {
    try {
      final box = getBox(boxName);
      await box.clear();
      _logger.i('Cleared all data from $boxName');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to clear data from $boxName',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Close all boxes
  static Future<void> dispose() async {
    try {
      await HiveAdapters.closeBoxes();
      instance._logger.i('Hive storage disposed successfully');
    } catch (e, stackTrace) {
      instance._logger.e(
        'Failed to dispose Hive storage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Clear all user data (useful for logout)
  static Future<void> clearUserData() async {
    try {
      await HiveAdapters.clearUserData();
      instance._logger.i('User data cleared successfully');
    } catch (e, stackTrace) {
      instance._logger.e(
        'Failed to clear user data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return HiveAdapters.getCacheStats();
  }
  
  /// Check if offline data is available
  static bool hasOfflineData() {
    return HiveAdapters.hasOfflineData();
  }
  
  /// Compact all boxes to optimize storage
  static Future<void> compactStorage() async {
    try {
      await HiveAdapters.compactBoxes();
      instance._logger.i('Storage compacted successfully');
    } catch (e, stackTrace) {
      instance._logger.e(
        'Failed to compact storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}