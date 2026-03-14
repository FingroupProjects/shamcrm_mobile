import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/theme/app_theme_mode.dart';
import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

Future<void> showThemeModeSelectorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.modalBackgroundColor,
    builder: (context) => const ThemeModeSelectorSheet(),
  );
}

class ThemeModeSelectorSheet extends StatelessWidget {
  const ThemeModeSelectorSheet({super.key});

  String _label(BuildContext context, AppThemeMode mode) {
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

  String _subtitle(BuildContext context, AppThemeMode mode) {
    final localizations = AppLocalizations.of(context);
    switch (mode) {
      case AppThemeMode.system:
        return localizations?.translate('theme_mode_system_description') ??
            'Следовать настройке устройства';
      case AppThemeMode.light:
        return localizations?.translate('theme_mode_light_description') ??
            'Всегда использовать светлую тему';
      case AppThemeMode.dark:
        return localizations?.translate('theme_mode_dark_description') ??
            'Всегда использовать тёмную тему';
    }
  }

  IconData _icon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto_rounded;
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final currentMode = context.appThemeMode;
    final title =
        AppLocalizations.of(context)?.translate('theme_label') ?? 'Тема';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              for (final mode in AppThemeMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await context.appThemeController.setMode(mode);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: currentMode == mode
                            ? colors.surfaceInteractive
                            : colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: currentMode == mode
                              ? colors.borderFocused
                              : colors.borderPrimary,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: currentMode == mode
                                  ? colors.selectionBackground
                                      .withValues(alpha: 0.16)
                                  : colors.surfacePrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _icon(mode),
                              color: currentMode == mode
                                  ? colors.iconBrand
                                  : colors.iconSecondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _label(context, mode),
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _subtitle(context, mode),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            currentMode == mode
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            color: currentMode == mode
                                ? colors.iconBrand
                                : colors.iconSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
