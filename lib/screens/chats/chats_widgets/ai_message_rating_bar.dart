import 'dart:ui';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Панель оценки ответа ИИ: две кнопки — палец вверх и палец вниз.
/// Показывается только под сообщениями, созданными ИИ.
/// [rating] — текущая оценка: 'good' | 'bad' | null (ещё не оценено).
/// [onRate] вызывается со значением 'good' или 'bad' при нажатии.
class AiMessageRatingBar extends StatelessWidget {
  const AiMessageRatingBar({
    super.key,
    required this.rating,
    required this.onRate,
    this.alignEnd = true,
  });

  final String? rating;
  final ValueChanged<String> onRate;
  final bool alignEnd; // Прижимать к правому краю (для своих сообщений).

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isGood = rating == 'good';
    final bool isBad = rating == 'bad';

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2, left: 8, right: 8),
      child: Row(
        mainAxisAlignment:
            alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          _RatingIconButton(
            icon: Icons.thumb_up_rounded,
            // Зелёная подсветка, если выбрана хорошая оценка.
            active: isGood,
            activeColor: const Color(0xFF22C55E),
            baseColor: colors.textSecondary,
            onTap: () => onRate('good'),
          ),
          const SizedBox(width: 6),
          _RatingIconButton(
            icon: Icons.thumb_down_rounded,
            // Красная подсветка, если выбрана плохая оценка.
            active: isBad,
            activeColor: colors.error,
            baseColor: colors.textSecondary,
            onTap: () => onRate('bad'),
          ),
        ],
      ),
    );
  }
}

/// Небольшая круглая кнопка-иконка для оценки.
class _RatingIconButton extends StatelessWidget {
  const _RatingIconButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.baseColor,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color baseColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : baseColor;
    return Material(
      color: active
          ? activeColor.withValues(alpha: 0.14)
          : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

/// Показывает шторку с полем «Причина» для плохой оценки ответа ИИ.
///
/// Причина необязательна. Возвращает:
/// - строку (возможно пустую) — если пользователь нажал «Отправить»;
/// - null — если пользователь закрыл шторку, не подтвердив оценку.
Future<String?> showAiRatingReasonSheet(BuildContext context) {
  final controller = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (sheetContext) {
      final colors = sheetContext.appColors;
      final loc = AppLocalizations.of(sheetContext);
      // Отступ снизу, чтобы поле не пряталось под клавиатурой.
      final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfacePrimary.withValues(alpha: 0.98),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Полоска-«ручка» вверху шторки.
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: colors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  loc?.translate('ai_rating_reason_title') ??
                      'Что не так с ответом?',
                  style: context.appTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 2,
                  autofocus: true,
                  style: context.appTextStyles.bodyLg
                      .copyWith(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: loc?.translate('ai_rating_reason_hint') ??
                        'Опишите причину',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    filled: true,
                    fillColor: colors.surfaceElevated.withValues(alpha: 0.6),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.borderSubtle.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.buttonPrimaryBg),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      loc?.translate('send') ?? 'Отправить',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
