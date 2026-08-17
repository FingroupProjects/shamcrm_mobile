import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_dashboard_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_dashboard_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_colors.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_details/sales_plan_detail_screen.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_planning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesPlanDashboardWidget extends StatefulWidget {
  const SalesPlanDashboardWidget({super.key});

  @override
  State<SalesPlanDashboardWidget> createState() =>
      _SalesPlanDashboardWidgetState();
}

class _SalesPlanDashboardWidgetState extends State<SalesPlanDashboardWidget> {
  final ApiService _apiService = ApiService();
  bool _canRead = false;
  bool _permissionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('planning.read');
    if (!mounted) return;
    setState(() {
      _canRead = canRead;
      _permissionsLoaded = true;
    });
    if (canRead) {
      context
          .read<SalesPlanDashboardBloc>()
          .add(const FetchSalesPlanDashboard());
    }
  }

  Color _pctColor(BuildContext context, SalesPlanStatus status, double pct) {
    return SalesPlanColors.progress(
      context,
      percent: pct,
      status: status,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsLoaded || !_canRead) {
      return const SizedBox.shrink();
    }

    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return BlocBuilder<SalesPlanDashboardBloc, SalesPlanDashboardState>(
      builder: (context, state) {
        if (state is SalesPlanDashboardError) {
          return const SizedBox.shrink();
        }
        // Не резервируем высоту на время загрузки — иначе на дашборде
        // появляется большой пустой отступ над KPI-карточками.
        if (state is SalesPlanDashboardLoading ||
            state is SalesPlanDashboardInitial) {
          return const SizedBox.shrink();
        }
        final items = (state as SalesPlanDashboardLoaded).items;
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.translate('sp_dashboard_title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SalesPlanningScreen(),
                        ),
                      );
                    },
                    child: Text(t.translate('sp_all_plans')),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final color =
                      _pctColor(context, item.status, item.percent);
                  final owner = item.users.isNotEmpty
                      ? item.users.first.displayName
                      : item.name;
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SalesPlanDetailScreen(planId: item.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfacePrimary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            owner,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            SalesPlanLabels.formatPercent(item.percent),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
