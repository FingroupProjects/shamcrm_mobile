// dashboard/tasks_box.dart
import 'package:crm_task_manager/bloc/dashboard/stats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_state.dart';
import 'package:crm_task_manager/screens/dashboard/style_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardStatsBloc, DashboardStatsState>(
      builder: (context, state) {
        if (state is DashboardStatsLoaded) {
          return BaseStatsBox(
            title: 'Задачи',
            icon: Icons.task_outlined,
            items: [
              StatItem(
                label: 'Выполнено',
                value: state.stats.taskStats.finished.toString(),
              ),
              StatItem(
                label: 'Просрочено',
                value: state.stats.taskStats.outDated.toString(),
              ),
              StatItem(
                label: 'Открытых',
                value: (state.stats.taskStats.all - 
                       state.stats.taskStats.finished - 
                       state.stats.taskStats.outDated).toString(),
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
} 