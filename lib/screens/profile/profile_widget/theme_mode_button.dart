import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/theme/app_theme_mode.dart';
import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:crm_task_manager/theme/theme_mode_selector_sheet.dart';
import 'package:flutter/material.dart';

class ThemeModeButtonWidget extends StatelessWidget {
  const ThemeModeButtonWidget({super.key});

  String _modeLabel(BuildContext context, AppThemeMode mode) {
    final localizations = AppLocalizations.of(context);
    switch (mode) {
      case AppThemeMode.system:
        return localizations?.translate('theme_mode_system') ?? 'Системная';
      case AppThemeMode.light:
        return localizations?.translate('theme_mode_light') ?? 'Светлая';
      case AppThemeMode.dark:
        return localizations?.translate('theme_mode_dark') ?? 'Тёмная';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final currentMode = context.appThemeMode;
    final title =
        AppLocalizations.of(context)?.translate('theme_label') ?? 'Тема';

    return GestureDetector(
      onTap: () => showThemeModeSelectorSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderPrimary),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceInteractive,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.palette_outlined,
                color: colors.iconBrand,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _modeLabel(context, currentMode),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.iconSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
