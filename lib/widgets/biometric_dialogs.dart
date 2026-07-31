import 'dart:io';

import 'package:crm_task_manager/api/service/biometric_service.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

Widget biometricIconWidget({
  required BiometricAvailability availability,
  required double size,
  required Color color,
}) {
  if (availability.shouldUseFaceIcon) {
    return Image.asset(
      'assets/icons/tabBar/face-id.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
  }

  return Icon(
    Icons.fingerprint,
    color: color,
    size: size,
  );
}

String biometricDisplayName(
  AppLocalizations localizations,
  BiometricAvailability availability,
) {
  if (availability.hasFace && availability.hasFingerprint) {
    return localizations.translate('biometric_fingerprint');
  }

  if (availability.hasFace) {
    return localizations.translate(
      Platform.isIOS ? 'biometric_face_id' : 'biometric_face_recognition',
    );
  }

  if (availability.hasFingerprint) {
    return localizations.translate(
      Platform.isIOS ? 'biometric_touch_id' : 'biometric_fingerprint',
    );
  }

  return localizations.translate('biometric_generic');
}

String biometricEnableTitle(
  AppLocalizations localizations,
  BiometricAvailability availability,
) {
  final useSpecificName =
      !(availability.hasFace && availability.hasFingerprint);
  if (!useSpecificName) {
    return localizations.translate('biometric_enable_title_generic');
  }

  final biometricName = biometricDisplayName(localizations, availability);
  switch (localizations.locale.languageCode) {
    case 'uz':
      return '$biometricName ${localizations.translate('biometric_enable_title_uz_suffix')}';
    case 'en':
      return '${localizations.translate('biometric_enable_title_face_prefix')} $biometricName?';
    default:
      return '${localizations.translate('biometric_enable_title_face_prefix')} $biometricName?';
  }
}

String biometricEnableDescription(
  AppLocalizations localizations,
  BiometricAvailability availability,
) {
  final useSpecificName =
      !(availability.hasFace && availability.hasFingerprint);
  if (!useSpecificName) {
    return localizations.translate('biometric_enable_description_generic');
  }

  final biometricName = biometricDisplayName(localizations, availability);
  switch (localizations.locale.languageCode) {
    case 'uz':
      return '$biometricName ${localizations.translate('biometric_enable_description_uz_suffix')}';
    case 'en':
      return '${localizations.translate('biometric_enable_description_face_prefix')} $biometricName. ${localizations.translate('biometric_enable_description_suffix')}';
    default:
      return '${localizations.translate('biometric_enable_description_face_prefix')} $biometricName. ${localizations.translate('biometric_enable_description_suffix')}';
  }
}

Future<bool?> showBiometricSetupRequiredDialog({
  required BuildContext context,
  required AppLocalizations localizations,
  required BiometricAvailability availability,
}) {
  final usesFace = availability.hasFace &&
      !availability.hasFingerprint &&
      availability.shouldUseFaceIcon;

  final descriptionKey = usesFace
      ? 'biometric_setup_required_face_description'
      : availability.hasFingerprint
          ? 'biometric_setup_required_fingerprint_description'
          : 'biometric_setup_required_generic_description';

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark ||
          MediaQuery.platformBrightnessOf(dialogContext) == Brightness.dark;
      final dialogSurface =
          isDark ? const Color(0xFF151827) : colors.surface;
      final dialogText = isDark ? Colors.white : colors.onSurface;
      final dialogSecondaryText = isDark
          ? const Color(0xFFB5B8C5)
          : colors.onSurfaceVariant;
      final dialogOutline =
          isDark ? const Color(0xFF3A4054) : colors.outline;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: dialogSurface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B)
                      .withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: biometricIconWidget(
                    availability: availability,
                    size: 38,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                localizations.translate('biometric_setup_required_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                  color: dialogText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                localizations.translate(descriptionKey),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Gilroy',
                  color: dialogSecondaryText,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dialogText,
                        side: BorderSide(color: dialogOutline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localizations.translate('cancel'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localizations.translate('open_settings'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
