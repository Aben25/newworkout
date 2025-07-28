import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance => _instance ??= SecureStorageService._();
  
  SecureStorageService._();
  
  final Logger _logger = Logger();
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'modern_workout_tracker_secure_prefs',
      preferencesKeyPrefix: 'mwt_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.modernworkouttracker.app',
      accountName: 'modern_workout_tracker',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginKey = 'last_login';
  
  /// Store access token securely
  Future<void> storeAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      _logger.d('Access token stored securely');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to store access token',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Retrieve access token
  Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      _logger.d('Access token retrieved');
      return token;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to retrieve access token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Store refresh token securely
  Future<void> storeRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      _logger.d('Refresh token stored securely');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to store refresh token',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      _logger.d('Refresh token retrieved');
      return token;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to retrieve refresh token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Store user ID
  Future<void> storeUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      _logger.d('User ID stored securely');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to store user ID',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Retrieve user ID
  Future<String?> getUserId() async {
    try {
      final userId = await _storage.read(key: _userIdKey);
      _logger.d('User ID retrieved');
      return userId;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to retrieve user ID',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Store biometric authentication preference
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
      _logger.d('Biometric preference stored: $enabled');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to store biometric preference',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      final enabled = value?.toLowerCase() == 'true';
      _logger.d('Biometric preference retrieved: $enabled');
      return enabled;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to retrieve biometric preference',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  /// Store last login timestamp
  Future<void> storeLastLogin() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      await _storage.write(key: _lastLoginKey, value: timestamp);
      _logger.d('Last login timestamp stored');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to store last login timestamp',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Get last login timestamp
  Future<DateTime?> getLastLogin() async {
    try {
      final timestamp = await _storage.read(key: _lastLoginKey);
      if (timestamp != null) {
        final lastLogin = DateTime.parse(timestamp);
        _logger.d('Last login timestamp retrieved: $lastLogin');
        return lastLogin;
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to retrieve last login timestamp',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Clear all stored authentication data
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _lastLoginKey),
      ]);
      _logger.i('All authentication data cleared');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to clear authentication data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Clear all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      _logger.i('All secure storage data cleared');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to clear all secure storage data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Check if authentication data exists
  Future<bool> hasAuthData() async {
    try {
      final accessToken = await getAccessToken();
      final userId = await getUserId();
      return accessToken != null && userId != null;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to check authentication data',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}