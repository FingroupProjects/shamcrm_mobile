import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/auth/pin_change_screen.dart'; // ✅ НОВЫЙ ИМПОРТ
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
      child: _buildPinOption(context, localizations),
    );
  }

  Widget _buildPinOption(BuildContext context, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appColors.surfaceAccent.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.lock_outline,
                color: context.appColors.buttonPrimaryBg,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              localizations.translate('change_pin_code'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.appColors.iconSecondary,
          ),
        ],
      ),
    );
  }
}
