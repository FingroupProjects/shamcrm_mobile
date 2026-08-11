import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:crm_task_manager/screens/sales_planning/widgets/sales_plan_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesPlanDailyArchive extends StatelessWidget {
  final List<SalesPlan> items;
  final bool loading;
  final int currentPlanId;
  final ValueChanged<int>? onTapPlan;

  const SalesPlanDailyArchive({
    super.key,
    required this.items,
    this.loading = false,
    required this.currentPlanId,
    this.onTapPlan,
  });

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final df = DateFormat('EEE dd MMM', 'ru');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('sp_daily_archive'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: colors.success),
            ),
          )
        else if (items.isEmpty)
          Text(
            t.translate('sp_daily_archive_empty'),
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          )
        else
          ...items.map((plan) {
            final today = _isToday(plan.periodStart);
            final selected = plan.id == currentPlanId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: selected
                    ? colors.success.withValues(alpha: 0.08)
                    : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: today ? colors.warning : colors.borderSubtle,
                ),
              ),
              child: ListTile(
                dense: true,
                onTap: onTapPlan == null ? null : () => onTapPlan!(plan.id),
                title: Text(
                  today
                      ? '● ${t.translate('sp_today')} — ${plan.periodStart != null ? df.format(plan.periodStart!) : ''}'
                      : (plan.periodStart != null
                          ? df.format(plan.periodStart!)
                          : plan.name),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${t.translate('sp_plan')}: ${SalesPlanLabels.formatNumber(plan.targetValue)}  '
                  '${t.translate('sp_fact')}: ${SalesPlanLabels.formatNumber(plan.actualValue)}  '
                  '${SalesPlanLabels.formatPercent(plan.percent)}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                trailing: SalesPlanStatusBadge(status: plan.status),
              ),
            );
          }),
      ],
    );
  }
}
