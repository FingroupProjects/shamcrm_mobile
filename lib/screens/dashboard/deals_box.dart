
// dashboard/deals_box.dart
import 'package:crm_task_manager/bloc/dashboard/stats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_state.dart';
import 'package:crm_task_manager/screens/dashboard/style_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardStatsBloc, DashboardStatsState>(
      builder: (context, state) {
        if (state is DashboardStatsLoaded) {
          return BaseStatsBox(
            title: 'Сделки',
            icon: Icons.receipt_outlined,
            items: [
              StatItem(
                label: 'Заказа обработано',
                value: state.stats.dealStats.finished.toString(),
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}