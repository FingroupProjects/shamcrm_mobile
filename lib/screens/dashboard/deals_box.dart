
// dashboard/deals_box.dart
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';
import 'package:crm_task_manager/screens/dashboard/style_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
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