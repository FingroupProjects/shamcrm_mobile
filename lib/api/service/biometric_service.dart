// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const String faceBiometricKey = 'face_biometric_enabled';
  static const String fingerBiometricKey = 'finger_biometric_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<void> setBiometricEnabled(BiometricType type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == BiometricType.face ? faceBiometricKey : fingerBiometricKey;
    await prefs.setBool(key, enabled);
  }

  Future<bool> isBiometricEnabled(BiometricType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == BiometricType.face ? faceBiometricKey : fingerBiometricKey;
    return prefs.getBool(key) ?? false;
  }

  Future<bool> authenticate(String reason) async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return false;

      final isFaceEnabled = await isBiometricEnabled(BiometricType.face);
      final isFingerEnabled = await isBiometricEnabled(BiometricType.strong);
      
      if (!isFaceEnabled && !isFingerEnabled) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
