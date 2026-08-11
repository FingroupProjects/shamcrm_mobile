import 'package:crm_task_manager/bloc/sales_plan/sales_plan_leaderboard_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_leaderboard_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_leaderboard_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_details/sales_plan_detail_screen.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:crm_task_manager/screens/sales_planning/widgets/sales_plan_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesPlanLeaderboardScreen extends StatefulWidget {
  const SalesPlanLeaderboardScreen({super.key});

  @override
  State<SalesPlanLeaderboardScreen> createState() =>
      _SalesPlanLeaderboardScreenState();
}

class _SalesPlanLeaderboardScreenState
    extends State<SalesPlanLeaderboardScreen> {
  String? _periodType = 'month';

  @override
  void initState() {
    super.initState();
    context
        .read<SalesPlanLeaderboardBloc>()
        .add(FetchSalesPlanLeaderboard(periodType: _periodType));
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
        title: Text(t.translate('sp_leaderboard')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              value: _periodType,
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                DropdownMenuItem(
                    value: 'week',
                    child: Text(t.translate('sp_period_week'))),
                DropdownMenuItem(
                    value: 'month',
                    child: Text(t.translate('sp_period_month'))),
                DropdownMenuItem(
                    value: 'quarter',
                    child: Text(t.translate('sp_period_quarter'))),
              ],
              onChanged: (v) {
                setState(() => _periodType = v);
                context.read<SalesPlanLeaderboardBloc>().add(
                      FetchSalesPlanLeaderboard(periodType: v),
                    );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<SalesPlanLeaderboardBloc,
                SalesPlanLeaderboardState>(
              builder: (context, state) {
                if (state is SalesPlanLeaderboardLoading ||
                    state is SalesPlanLeaderboardInitial) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.success),
                  );
                }
                if (state is SalesPlanLeaderboardError) {
                  return Center(
                    child: Text(state.message,
                        style: TextStyle(color: colors.textSecondary)),
                  );
                }
                final items =
                    (state as SalesPlanLeaderboardLoaded).items;
                if (items.isEmpty) {
                  return Center(
                    child: Text(t.translate('sp_leaderboard_empty'),
                        style: TextStyle(color: colors.textSecondary)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<SalesPlanLeaderboardBloc>().add(
                          FetchSalesPlanLeaderboard(periodType: _periodType),
                        );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final medal = index == 0
                          ? '🏆 '
                          : item.status == SalesPlanStatus.overachieved
                              ? '🏆 '
                              : '';
                      return Material(
                        color: colors.surfacePrimary,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SalesPlanDetailScreen(
                                    planId: item.planId),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$medal${item.userName}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    SalesPlanStatusBadge(status: item.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.planName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '${SalesPlanLabels.formatNumber(item.targetValue)} / ${SalesPlanLabels.formatNumber(item.actualValue)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      SalesPlanLabels.formatPercent(
                                          item.percent),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: item.percent >= 100
                                            ? colors.success
                                            : colors.textPrimary,
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
