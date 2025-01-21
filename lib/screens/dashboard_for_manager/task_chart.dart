
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/task_chart_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskChartWidgetManager extends StatefulWidget {
  const TaskChartWidgetManager({super.key});

  @override
  State<TaskChartWidgetManager> createState() => _TaskChartWidgetStateManager();
}

class _TaskChartWidgetStateManager extends State<TaskChartWidgetManager>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    final state = context.read<DashboardTaskChartBlocManager>().state;
    if (state is! DashboardTaskChartLoadedManager) {
      context.read<DashboardTaskChartBlocManager>().add(LoadTaskChartDataManager());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocConsumer<DashboardTaskChartBlocManager, DashboardTaskChartStateManager>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is DashboardTaskChartLoadedManager) {
          final totalTasks = state.taskChartData.data.reduce((a, b) => a + b);
          return Container(
            height: 330,
            padding: const EdgeInsets.only(left: 12, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations!.translate('tasks'),
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Gilroy",
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(state.taskChartData),
                const SizedBox(height: 16),
                Expanded(
                  child: Stack(
                    children: [
                      _buildChart(state),
                      if (state.taskChartData.data.every((value) => value == 0))
                        Center(
                          child: Text(
                          localizations.translate('no_data_to_display'),
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Gilroy",
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                  '${localizations.translate('total_tasks')}: ${totalTasks.toInt()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: "Gilroy",
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A202C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        } else if (state is DashboardTaskChartErrorManager) {
          return Center(
            child: Text(
            localizations!.translate('data_loading_error'),
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontFamily: "Gilroy",
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildChart(DashboardTaskChartStateManager state) {
    if (state is DashboardTaskChartErrorManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${state.message}',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (state is DashboardTaskChartLoadedManager) {
      return PieChart(
        PieChartData(
          startDegreeOffset: -90,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _showingSections(state.taskChartData),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<PieChartSectionData> _showingSections(TaskChartManager taskChart) {
    final List<Color> colors = [
      const Color(0xFF3935E7), // Активный - голубой
      const Color(0xFFC30202), // Просрочен - красный
      const Color(0xFF27A945), // Завершён - зеленый
    ];

    // Проверяем, все ли значения равны 0
    bool allZeros = taskChart.data.every((value) => value == 0);

    // Если все значения 0, возвращаем полностью красный круг
    if (allZeros) {
      return [
        PieChartSectionData(
          color: const Color.fromARGB(255, 210, 210, 210), // Кроваво-красный
          value: 100, // 100% круга
          title: '',
          radius: 40.0,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ];
    }

    // Стандартная логика для ненулевых значений
    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final opacity = isTouched ? 0.8 : 1.0;
      final radius = isTouched ? 50.0 : 40.0;

      return PieChartSectionData(
        color: colors[i].withOpacity(opacity),
        value: taskChart.data[i],
        title: isTouched ? '${taskChart.data[i].toStringAsFixed(0)}' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontFamily: "Gilroy",
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegend(TaskChartManager taskChart) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(
            localizations.translate('active_tasks'),
            const Color(0xFF3935E7),
          ),
          const SizedBox(
            width: 24,
            height: 12,
          ),
          _buildLegendItem(
            localizations.translate('overdue_tasks'),
            const Color(0xFFC30202),
          ),
        ],
      ),
      _buildLegendItem(
        localizations.translate('completed_tasks'),
        const Color(0xFF27A945),
      ),
    ],
  );
}

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A202C),
          ),
        ),
      ],
    );
  }
}
