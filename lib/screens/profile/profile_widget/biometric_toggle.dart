import 'dart:io';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_settings_tile.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricToggleWidget extends StatefulWidget {
  const BiometricToggleWidget({super.key});

  @override
  State<BiometricToggleWidget> createState() => _BiometricToggleWidgetState();
}

class _BiometricToggleWidgetState extends State<BiometricToggleWidget> {
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadBiometricState();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        final availableBiometrics = await _auth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          // Check if device has Face ID (iOS) or strong biometrics (Android)
          final hasBiometric = Platform.isIOS
              ? availableBiometrics.contains(BiometricType.face)
              : availableBiometrics.contains(BiometricType.strong);

          if (mounted) {
            setState(() {
              _isBiometricAvailable = hasBiometric;
            });
          }
        }
      }
    } catch (e) {
      // Biometric not available
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
        });
      }
    }
  }

  Future<void> _loadBiometricState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = prefs.getBool('biometric_auth_enabled') ?? false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_isBiometricAvailable) {
      final localizations = AppLocalizations.of(context);
      if (localizations != null && mounted) {
        showCustomSnackBar(
          context: context,
          message: localizations.translate('biometric_not_available'),
          isSuccess: false,
        );
      }
      return;
    }

    setState(() {
      _isBiometricEnabled = value;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_auth_enabled', _isBiometricEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    // Only show widget if biometric is available
    if (!_isBiometricAvailable) {
      return const SizedBox.shrink();
    }

    return ProfileSettingsTile(
      title: _isBiometricEnabled
          ? localizations.translate('biometric_unlock_on')
          : localizations.translate('biometric_unlock_off'),
      icon: Icons.fingerprint_rounded,
      trailing: Switch(
        value: _isBiometricEnabled,
        onChanged: _toggleBiometric,
      ),
    );
  }
}
