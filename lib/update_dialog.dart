import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:crm_task_manager/theme/theme_context_extensions.dart';

class UpdateDialog {
  static Future<void> show({
    required BuildContext context,
    required VersionStatus status,
    required String title,
    required String message,
    required String updateButton,
    String laterButton = 'Позже', // Новый параметр
    VoidCallback? onLaterPressed, // Опциональный колбэк
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true, // ← Теперь можно закрыть тапом вне диалога
      builder: (BuildContext context) {
        final colors = context.appColors;
        final textTheme = Theme.of(context).textTheme;

        return PopScope(
          canPop: true, // ← Разрешаем кнопку "Назад"
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.dialogBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка с градиентом
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.buttonPrimaryBackground,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadowColor.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 36,
                      color: colors.buttonPrimaryForeground,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Заголовок
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Описание
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // === ДВЕ КНОПКИ ===
                  Row(
                    children: [
                      // Кнопка "Позже" — текстовая, слева
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            onLaterPressed?.call();
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            laterButton,
                            style: textTheme.labelLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Кнопка "Обновить" — акцентная, справа
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            NewVersionPlus()
                                .launchAppStore(status.appStoreLink);
                            // Не закрываем диалог — пусть пользователь сам уйдёт в магазин
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.buttonPrimaryBackground,
                            foregroundColor: colors.buttonPrimaryForeground,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            updateButton,
                            style: textTheme.labelLarge?.copyWith(
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
