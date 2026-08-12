import 'package:crm_task_manager/api/service/device/biometric_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_toggle_card.dart';
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
            style: context.appTextStyles.bodyMd.copyWith(
              color: context.appColors.textInverse,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: context.appColors.error,
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

    return ProfileToggleCard(
      icon: biometricIconWidget(
        availability: availability,
        size: 20,
        color: context.appColors.buttonPrimaryBg,
      ),
      title: _isBiometricEnabled
          ? localizations.translate('biometric_unlock_on')
          : localizations.translate('biometric_unlock_off'),
      value: _isBiometricEnabled,
      onChanged: _toggleBiometric,
    );
  }
}
