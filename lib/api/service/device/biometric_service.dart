import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAvailability {
  const BiometricAvailability({
    required this.isDeviceSupported,
    required this.canCheckBiometrics,
    required this.availableBiometrics,
    required this.hasFace,
    required this.hasFingerprint,
  });

  final bool isDeviceSupported;
  final bool canCheckBiometrics;
  final List<BiometricType> availableBiometrics;
  final bool hasFace;
  final bool hasFingerprint;

  bool get hasAnyBiometric => hasFace || hasFingerprint;

  bool get shouldUseFaceIcon {
    if (Platform.isIOS) {
      return hasFace;
    }

    return hasFace && !hasFingerprint;
  }

  IconData get icon {
    return shouldUseFaceIcon ? Icons.face : Icons.fingerprint;
  }
}

class BiometricService {
  static const String biometricEnabledKey = 'biometric_auth_enabled';

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<BiometricAvailability> getAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = canCheckBiometrics && isDeviceSupported
          ? await _localAuth.getAvailableBiometrics()
          : const <BiometricType>[];

      return BiometricAvailability(
        isDeviceSupported: isDeviceSupported,
        canCheckBiometrics: canCheckBiometrics,
        availableBiometrics: availableBiometrics,
        hasFace: availableBiometrics.contains(BiometricType.face),
        hasFingerprint:
            availableBiometrics.contains(BiometricType.fingerprint) ||
                availableBiometrics.contains(BiometricType.strong) ||
                availableBiometrics.contains(BiometricType.weak),
      );
    } catch (_) {
      return const BiometricAvailability(
        isDeviceSupported: false,
        canCheckBiometrics: false,
        availableBiometrics: <BiometricType>[],
        hasFace: false,
        hasFingerprint: false,
      );
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(biometricEnabledKey, enabled);
  }

  Future<bool> authenticate({
    required String reason,
    bool stickyAuth = true,
    bool useErrorDialogs = true,
  }) async {
    try {
      final availability = await getAvailability();
      if (!availability.hasAnyBiometric) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
          useErrorDialogs: useErrorDialogs,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> openBiometricSettings() async {
    try {
      if (Platform.isAndroid) {
        try {
          final availability = await getAvailability();
          final intent = availability.hasAnyBiometric
              ? const AndroidIntent(
                  action: 'android.settings.SECURITY_SETTINGS',
                )
              : const AndroidIntent(
                  action: 'android.settings.BIOMETRIC_ENROLL',
                );
          await intent.launch();
        } catch (_) {
          await const AndroidIntent(
            action: 'android.settings.SECURITY_SETTINGS',
          ).launch();
        }
        return true;
      }

      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
