// dashboard/leads_box.dart
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';
import 'package:crm_task_manager/screens/dashboard/style_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          return BaseStatsBox(
            title: 'Контрагенты',
            icon: Icons.people_outline,
            items: [
              StatItem(
                label: 'Неизвестно',
                value: state.stats.leadStats.unknown.toString(),
              ),
              StatItem(
                label: 'Приведено',
                value: state.stats.leadStats.atWork.toString(),
              ),
              StatItem(
                label: 'Ушедших',
                value: state.stats.leadStats.finished.toString(),
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}