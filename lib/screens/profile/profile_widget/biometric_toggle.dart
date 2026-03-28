import 'dart:io';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('biometric_not_available'),
            ),
            backgroundColor: Colors.red,
          ),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      height: 80, // Increased height
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Switch(
            value: _isBiometricEnabled,
            onChanged: _toggleBiometric,
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
            activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
            inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isBiometricEnabled
                  ? localizations.translate('biometric_unlock_on')
                  : localizations.translate('biometric_unlock_off'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xFF1E1E1E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

