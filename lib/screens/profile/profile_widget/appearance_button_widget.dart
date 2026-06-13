import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/appearance_settings_screen.dart';
import 'package:flutter/material.dart';

class AppearanceButtonWidget extends StatelessWidget {
  const AppearanceButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        debugPrint('AppearanceButtonWidget: tap');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              debugPrint('AppearanceButtonWidget: route builder');
              return const AppearanceSettingsScreen();
            },
          ),
        );
        debugPrint('AppearanceButtonWidget: push called');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.appColors.buttonPrimaryBg,
                    context.appColors.surfaceAccent,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.palette_outlined,
                color: context.appColors.textInverse,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Оформление',
                    style: context.appTextStyles.bodyLg.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Палитра, тема и фоновый арт',
                    style: context.appTextStyles.bodySm.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appColors.iconSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
