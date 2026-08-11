import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_detail_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_detail_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_detail_state.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_colors.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_details/sales_plan_constructor_screen.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_details/sales_plan_daily_archive.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:crm_task_manager/screens/sales_planning/widgets/sales_plan_progress_bar.dart';
import 'package:crm_task_manager/screens/sales_planning/widgets/sales_plan_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesPlanDetailScreen extends StatefulWidget {
  final int planId;

  const SalesPlanDetailScreen({super.key, required this.planId});

  @override
  State<SalesPlanDetailScreen> createState() => _SalesPlanDetailScreenState();
}

class _SalesPlanDetailScreenState extends State<SalesPlanDetailScreen> {
  final ApiService _apiService = ApiService();
  late int _planId;
  bool _canUpdate = false;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _planId = widget.planId;
    _checkPermissions();
    context.read<SalesPlanDetailBloc>().add(FetchSalesPlanDetail(_planId));
  }

  Future<void> _checkPermissions() async {
    final canUpdate = await _apiService.hasPermission('planning.update');
    final canDelete = await _apiService.hasPermission('planning.delete');
    if (!mounted) return;
    setState(() {
      _canUpdate = canUpdate;
      _canDelete = canDelete;
    });
  }

  Future<void> _edit(SalesPlan plan) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SalesPlanConstructorScreen(planId: plan.id, plan: plan),
      ),
    );
    if (saved == true && mounted) {
      context.read<SalesPlanDetailBloc>().add(FetchSalesPlanDetail(_planId));
    }
  }

  Future<void> _delete(SalesPlan plan) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.translate('sp_delete_title')),
        content: Text(t.translate('sp_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.translate('sp_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.translate('sp_delete')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<SalesPlanBloc>().add(DeleteSalesPlanEvent(plan.id));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        foregroundColor: colors.textPrimary,
        title: Text(t.translate('sales_planning')),
        actions: [
          BlocBuilder<SalesPlanDetailBloc, SalesPlanDetailState>(
            builder: (context, state) {
              if (state is! SalesPlanDetailLoaded) {
                return const SizedBox.shrink();
              }
              if (!_canUpdate && !_canDelete) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canUpdate)
                    IconButton(
                      tooltip: t.translate('sp_edit'),
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(state.plan),
                    ),
                  if (_canDelete)
                    IconButton(
                      tooltip: t.translate('sp_delete'),
                      icon: Icon(
                        Icons.delete_outline,
                        color: SalesPlanColors.red,
                      ),
                      onPressed: () => _delete(state.plan),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SalesPlanDetailBloc, SalesPlanDetailState>(
        builder: (context, state) {
          if (state is SalesPlanDetailLoading ||
              state is SalesPlanDetailInitial) {
            return Center(
              child: CircularProgressIndicator(color: colors.success),
            );
          }
          if (state is SalesPlanDetailError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context
                          .read<SalesPlanDetailBloc>()
                          .add(FetchSalesPlanDetail(_planId)),
                      child: Text(t.translate('sp_retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          final loaded = state as SalesPlanDetailLoaded;
          final plan = loaded.plan;
          final accent = SalesPlanColors.forecast(context, plan);

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<SalesPlanDetailBloc>()
                  .add(FetchSalesPlanDetail(_planId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${SalesPlanLabels.planType(context, plan.planType)} · '
                            '${plan.ownersLabel} · '
                            '${SalesPlanLabels.formatPeriod(plan)}'
                            '${plan.daysLeft != null ? ' · ${t.translate('sp_days_left')}: ${plan.daysLeft}' : ''}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SalesPlanStatusBadge(status: plan.status),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${t.translate('sp_fact')}: ${SalesPlanLabels.formatNumber(plan.actualValue)}',
                      style: TextStyle(
                          fontSize: 12.5, color: colors.textSecondary),
                    ),
                    Text(
                      '${t.translate('sp_plan')}: ${SalesPlanLabels.formatNumber(plan.targetValue)}',
                      style: TextStyle(
                          fontSize: 12.5, color: colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SalesPlanProgressBar(
                  percent: plan.percent,
                  status: plan.status,
                  height: 10,
                  showLabel: true,
                  labelOnRight: true,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cross = width > 520 ? 5 : (width > 360 ? 3 : 2);
                    return GridView.count(
                      crossAxisCount: cross,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.35,
                      children: [
                        _metric(t.translate('sp_days_left'),
                            '${plan.daysLeft ?? '—'}'),
                        _metric(
                          t.translate('sp_daily_need'),
                          plan.dailyNeed == null
                              ? '—'
                              : SalesPlanLabels.formatNumber(plan.dailyNeed!),
                        ),
                        _metric(
                          t.translate('sp_daily_avg'),
                          plan.dailyAverage == null
                              ? '—'
                              : SalesPlanLabels.formatNumber(
                                  plan.dailyAverage!),
                        ),
                        _metric(
                          t.translate('sp_forecast'),
                          plan.forecast == null
                              ? '—'
                              : SalesPlanLabels.formatNumber(plan.forecast!),
                          valueColor: accent,
                        ),
                        _metric(
                          t.translate('sp_forecast_pct'),
                          plan.forecastPercent == null
                              ? '—'
                              : SalesPlanLabels.formatPercent(
                                  plan.forecastPercent!),
                          valueColor: accent,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                Text(
                  t.translate('sp_hierarchy'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                if (plan.children.isNotEmpty)
                  ...[
                    _hierRow(
                      context,
                      title:
                          '${plan.name} — ${t.translate('sp_plan')} ${SalesPlanLabels.formatNumber(plan.targetValue)}',
                      pct: plan.percent,
                      top: true,
                    ),
                    ...plan.children.map(
                      (c) => _hierRow(
                        context,
                        title:
                            '${c.name}${c.targetValue != null ? ' — ${SalesPlanLabels.formatNumber(c.targetValue!)}' : ''}',
                        pct: c.percent ?? 0,
                        indent: true,
                      ),
                    ),
                  ]
                else if (loaded.hierarchyFromLeaderboard.isNotEmpty)
                  ...[
                    _hierRow(
                      context,
                      title:
                          '${plan.name} — ${t.translate('sp_plan')} ${SalesPlanLabels.formatNumber(plan.targetValue)}',
                      pct: plan.percent,
                      top: true,
                    ),
                    ...loaded.hierarchyFromLeaderboard.map(
                      (c) => _hierRow(
                        context,
                        title:
                            '${c.userName} — ${SalesPlanLabels.formatNumber(c.targetValue)}',
                        pct: c.percent,
                        indent: true,
                      ),
                    ),
                  ]
                else if (plan.users.isNotEmpty)
                  ...plan.users.map(
                    (u) => _hierRow(
                      context,
                      title: u.displayName,
                      pct: plan.percent,
                      indent: false,
                    ),
                  )
                else
                  Text(
                    t.translate('sp_hierarchy_empty'),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                if (plan.isDailyRecurring) ...[
                  const SizedBox(height: 24),
                  SalesPlanDailyArchive(
                    items: loaded.dailyArchive,
                    loading: loaded.archiveLoading,
                    currentPlanId: plan.id,
                    onTapPlan: (id) {
                      setState(() => _planId = id);
                      context
                          .read<SalesPlanDetailBloc>()
                          .add(FetchSalesPlanDetail(id));
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metric(String label, String value, {Color? valueColor}) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor ?? colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _hierRow(
    BuildContext context, {
    required String title,
    required double pct,
    bool top = false,
    bool indent = false,
  }) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(indent ? 20 : 12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: top ? colors.borderSubtle.withValues(alpha: 1) : colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: top ? FontWeight.w600 : FontWeight.w500,
                color: indent ? colors.textSecondary : colors.textPrimary,
              ),
            ),
          ),
          Text(
            '${SalesPlanLabels.formatPercent(pct)} ${AppLocalizations.of(context)!.translate('sp_done')}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
