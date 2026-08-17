import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_colors.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:crm_task_manager/screens/sales_planning/widgets/sales_plan_progress_bar.dart';
import 'package:crm_task_manager/screens/sales_planning/widgets/sales_plan_status_badge.dart';
import 'package:flutter/material.dart';

class SalesPlanCard extends StatelessWidget {
  final SalesPlan plan;
  final VoidCallback? onTap;
  final bool selected;

  const SalesPlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final progressColor = SalesPlanColors.progress(
      context,
      percent: plan.percent,
      status: plan.status,
    );
    final initials = plan.ownersLabel.isNotEmpty
        ? plan.ownersLabel
            .split(' ')
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join()
        : '?';

    final sel = SalesPlanColors.selection(context);
    return Material(
      color: selected
          ? SalesPlanColors.selectionBg(context)
          : colors.surfacePrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? sel : colors.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${SalesPlanLabels.planType(context, plan.planType)}'
                          '${plan.recurrence != SalesPlanRecurrence.once ? ' · ${SalesPlanLabels.recurrence(context, plan.recurrence)}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SalesPlanStatusBadge(status: plan.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: colors.surfaceElevated,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.ownersLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    SalesPlanLabels.formatPeriod(plan),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                SalesPlanLabels.indicatorSummary(context, plan),
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: SalesPlanLabels.formatNumber(plan.targetValue),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          TextSpan(
                            text:
                                ' / ${SalesPlanLabels.formatNumber(plan.actualValue)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    SalesPlanLabels.formatPercent(plan.percent),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: progressColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SalesPlanProgressBar(
                percent: plan.percent,
                status: plan.status,
                height: 8,
                showLabel: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
