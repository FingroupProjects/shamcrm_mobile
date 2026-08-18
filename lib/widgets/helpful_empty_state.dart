import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class HelpfulEmptyState extends StatelessWidget {
  const HelpfulEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  static Widget loading() {
    return const Center(
      child: PlayStoreImageLoading(
        size: 80.0,
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  static bool isReadyForStatus({
    required bool isFetching,
    required int? completedStatusId,
    required int statusId,
  }) {
    return !isFetching && completedStatusId == statusId;
  }

  static HelpfulEmptyState search(AppLocalizations l10n) {
    return HelpfulEmptyState(
      icon: Icons.search_off_rounded,
      title: l10n.translate('empty_search_title'),
      subtitle: l10n.translate('empty_search_subtitle'),
    );
  }

  static HelpfulEmptyState section({
    required AppLocalizations l10n,
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    String? actionKey,
    VoidCallback? onAction,
  }) {
    return HelpfulEmptyState(
      icon: icon,
      title: l10n.translate(titleKey),
      subtitle: l10n.translate(subtitleKey),
      actionLabel: actionKey == null ? null : l10n.translate(actionKey),
      onAction: onAction,
    );
  }

  static Widget refreshable({
    required BuildContext context,
    required Future<void> Function() onRefresh,
    required HelpfulEmptyState child,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.appColors.buttonPrimaryBg,
      backgroundColor: context.appColors.surfacePrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canAct = actionLabel != null && onAction != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.surfaceAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: colors.buttonPrimaryBg,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: colors.textPrimary,
                height: 1.2,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
            if (canAct) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.buttonPrimaryBg,
                    foregroundColor: context.adaptiveForegroundOn(
                      colors.buttonPrimaryBg,
                      lightColor: const Color(0xFFF8FAFC),
                      darkColor: const Color(0xFF0F172A),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
