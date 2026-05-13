import 'package:crm_task_manager/api/service/biometric_service.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/biometric_dialogs.dart';
import 'package:flutter/material.dart';

class BiometricToggleWidget extends StatefulWidget {
  const BiometricToggleWidget({super.key});

  @override
  State<BiometricToggleWidget> createState() => _BiometricToggleWidgetState();
}

class _BiometricToggleWidgetState extends State<BiometricToggleWidget> {
  final BiometricService _biometricService = BiometricService();

  bool _isBiometricEnabled = false;
  BiometricAvailability? _availability;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final availability = await _biometricService.getAvailability();
    final isEnabled = await _biometricService.isBiometricEnabled();

    if (!mounted) return;

    setState(() {
      _availability = availability;
      _isBiometricEnabled = availability.hasAnyBiometric && isEnabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final localizations = AppLocalizations.of(context);
    final availability =
        _availability ?? await _biometricService.getAvailability();

    if (!value) {
      await _biometricService.setBiometricEnabled(false);
      if (!mounted) return;
      setState(() {
        _availability = availability;
        _isBiometricEnabled = false;
      });
      return;
    }

    if (!availability.hasAnyBiometric) {
      final shouldOpenSettings = await showBiometricSetupRequiredDialog(
        context: context,
        localizations: localizations!,
        availability: availability,
      );
      if (shouldOpenSettings == true) {
        await _biometricService.openBiometricSettings();
      }

      await _biometricService.setBiometricEnabled(false);
      if (!mounted) return;
      setState(() {
        _availability = availability;
        _isBiometricEnabled = false;
      });
      return;
    }

    final didAuthenticate = await _biometricService.authenticate(
      reason: localizations?.translate('confirm_identity') ??
          'Подтвердите личность',
    );

    await _biometricService.setBiometricEnabled(didAuthenticate);

    if (!mounted) return;

    setState(() {
      _availability = availability;
      _isBiometricEnabled = didAuthenticate;
    });

    if (!didAuthenticate && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.translate('biometric_enable_cancelled') ??
                'Biometric sign-in was not enabled',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final availability = _availability;

    if (localizations == null || availability == null) {
      return const SizedBox.shrink();
    }

    if (!availability.hasAnyBiometric) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 223, 225, 249),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: biometricIconWidget(
                availability: availability,
                size: 22,
                color: const Color.fromARGB(255, 91, 77, 235),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
          Switch(
            value: _isBiometricEnabled,
            onChanged: _toggleBiometric,
            activeThumbColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveTrackColor: const Color.fromARGB(
              255,
              179,
              179,
              179,
            ).withValues(alpha: 0.5),
            activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
            inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
          ),
        ],
      ),
    );
  }
}
