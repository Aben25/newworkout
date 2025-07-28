import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'secure_storage_service.dart';

class BiometricService {
  static BiometricService? _instance;
  static BiometricService get instance => _instance ??= BiometricService._();
  
  BiometricService._();
  
  final Logger _logger = Logger();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  
  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      _logger.d('Biometric available: $isAvailable, Device supported: $isDeviceSupported');
      return isAvailable && isDeviceSupported;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to check biometric availability',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      _logger.d('Available biometrics: $biometrics');
      return biometrics;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get available biometrics',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
  
  /// Authenticate using biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your account',
  }) async {
    try {
      // Check if biometrics are available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _logger.w('Biometric authentication not available');
        return false;
      }
      
      // Check if biometric authentication is enabled by user
      final isEnabled = await _secureStorage.isBiometricEnabled();
      if (!isEnabled) {
        _logger.w('Biometric authentication not enabled by user');
        return false;
      }
      
      _logger.i('Attempting biometric authentication');
      
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated) {
        _logger.i('Biometric authentication successful');
      } else {
        _logger.w('Biometric authentication failed');
      }
      
      return isAuthenticated;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to authenticate with biometrics',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  /// Enable biometric authentication for the user
  Future<bool> enableBiometricAuth() async {
    try {
      // Check if biometrics are available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _logger.w('Cannot enable biometric auth - not available');
        return false;
      }
      
      // Test biometric authentication
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated) {
        await _secureStorage.setBiometricEnabled(true);
        _logger.i('Biometric authentication enabled');
        return true;
      } else {
        _logger.w('Failed to enable biometric authentication');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to enable biometric authentication',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  /// Disable biometric authentication for the user
  Future<void> disableBiometricAuth() async {
    try {
      await _secureStorage.setBiometricEnabled(false);
      _logger.i('Biometric authentication disabled');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to disable biometric authentication',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Check if biometric authentication is enabled by the user
  Future<bool> isBiometricEnabled() async {
    try {
      return await _secureStorage.isBiometricEnabled();
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to check if biometric is enabled',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  /// Get a user-friendly description of available biometric types
  Future<String> getBiometricDescription() async {
    try {
      final biometrics = await getAvailableBiometrics();
      
      if (biometrics.isEmpty) {
        return 'No biometric authentication available';
      }
      
      final descriptions = <String>[];
      
      if (biometrics.contains(BiometricType.face)) {
        descriptions.add('Face ID');
      }
      if (biometrics.contains(BiometricType.fingerprint)) {
        descriptions.add('Fingerprint');
      }
      if (biometrics.contains(BiometricType.iris)) {
        descriptions.add('Iris');
      }
      if (biometrics.contains(BiometricType.strong)) {
        descriptions.add('Strong biometric');
      }
      if (biometrics.contains(BiometricType.weak)) {
        descriptions.add('Weak biometric');
      }
      
      if (descriptions.isEmpty) {
        return 'Biometric authentication';
      }
      
      if (descriptions.length == 1) {
        return descriptions.first;
      }
      
      return descriptions.join(' or ');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get biometric description',
        error: e,
        stackTrace: stackTrace,
      );
      return 'Biometric authentication';
    }
  }
}