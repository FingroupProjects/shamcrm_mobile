import 'package:crm_task_manager/screens/auth/pin_change_screen.dart'; // ✅ НОВЫЙ ИМПОРТ
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_settings_tile.dart';
import 'package:flutter/material.dart';

class PinChangeWidget extends StatelessWidget {
  const PinChangeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        // ✅ ИЗМЕНЕНО: теперь открываем PinChangeScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PinChangeScreen(),
          ),
        );
      },
      child: _buildPinOption(localizations),
    );
  }

  Widget _buildPinOption(AppLocalizations localizations) {
    return ProfileSettingsTile(
      title: localizations.translate('change_pin_code'),
      icon: Icons.lock_outline_rounded,
    );
  }
}
