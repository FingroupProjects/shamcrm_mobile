import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:flutter/material.dart';

/// Карточка на том же фоне, что экран «Забыли PIN».
/// Заголовок и поля смены пароля живут внутри неё.
class PasswordFlowShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const PasswordFlowShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.iconPrimary),
        forceMaterialTransparency: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                        decoration: BoxDecoration(
                          color: colors.surfacePrimary.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colors.borderSubtle.withValues(alpha: 0.42),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.16),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textStyles.titleLg.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: textStyles.bodyMd.copyWith(
                                fontSize: 14,
                                height: 1.4,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Поле в цветах карточки восстановления, чтобы форма не выбивалась из темы.
Widget passwordFlowField({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  required String hint,
  bool isPassword = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  final colors = context.appColors;
  return CustomTextField(
    controller: controller,
    hintText: hint,
    label: label,
    isPassword: isPassword,
    keyboardType: keyboardType,
    backgroundColor: colors.backgroundPrimary.withValues(alpha: 0.36),
    labelColor: colors.textPrimary,
    hintColor: colors.textSecondary,
    textColor: colors.textPrimary,
    borderColor: colors.borderSubtle.withValues(alpha: 0.36),
    focusedBorderColor: colors.buttonPrimaryBg,
  );
}
