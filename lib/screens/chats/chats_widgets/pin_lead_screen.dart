import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/widgets/channel_source_icon.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class PinnedLeadMessageWidget extends StatelessWidget {
  final String message;
  final String? channelType;
  final VoidCallback? onTap;
  // Кнопка в конце баннера (например, настройки ИИ). null — не показываем.
  final Widget? trailing;

  const PinnedLeadMessageWidget({
    super.key,
    required this.message,
    this.channelType,
    this.onTap,
    this.trailing,
  });

  // Иконка канала — PNG из assets/icons/leads.
  // В тёмной теме телефон и почта берут файл с суффиксом _dark.

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: context.appColors.surfacePrimary.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.appColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: context.appColors.buttonPrimaryBg,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            ChannelSourceIcon(
              sourceName: channelType,
              size: 28,
              background: context.appColors.surfacePrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.appColors.buttonPrimaryBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('account_request'),
                      style: context.appTextStyles.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.appColors.buttonPrimaryFg,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Высота строки фиксирована: имя интеграции только
                  // проявляется, баннер не подпрыгивает и не сдвигает чат.
                  SizedBox(
                    height: 20,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: Text(
                        message,
                        key: ValueKey(message),
                        style: context.appTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
