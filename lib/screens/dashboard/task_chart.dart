import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/task_chart_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskChartWidget extends StatefulWidget {
  const TaskChartWidget({super.key});

  @override
  State<TaskChartWidget> createState() => _TaskChartWidgetState();
}

class _TaskChartWidgetState extends State<TaskChartWidget>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    final state = context.read<DashboardTaskChartBloc>().state;
    if (state is! DashboardTaskChartLoaded) {
      context.read<DashboardTaskChartBloc>().add(LoadTaskChartData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardTaskChartBloc, DashboardTaskChartState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is DashboardTaskChartLoaded) {
          final totalTasks = state.taskChartData.data.reduce((a, b) => a + b);
          return Container(
            height: 330,
            padding: const EdgeInsets.only(left: 12, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Задачи',
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
                  child: _buildChart(state),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Общее количество задач: ${totalTasks.toInt()}',
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
        } else if (state is DashboardTaskChartError) {
          return Center(
            child: Text(
              'Ошибка загрузки данных',
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

  Widget _buildChart(DashboardTaskChartState state) {
    if (state is DashboardTaskChartError) {
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
          duration: Duration(seconds: 2),
        ),
      );
    } else if (state is DashboardTaskChartLoaded) {
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

  List<PieChartSectionData> _showingSections(TaskChart taskChart) {
    final List<Color> colors = [
      const Color(0xFF3935E7), // Активный - голубой
      const Color(0xFFC30202), // Просрочен - фиолетовый
      const Color(0xFF27A945), // Завершён - зеленый
    ];
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
          color: Color.fromARGB(255, 255, 255, 255),
        ),
      );
    });
  }

  Widget _buildLegend(TaskChart taskChart) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              'Активные ',
              const Color(0xFF3935E7),
            ),
            const SizedBox(
              width: 24,
              height: 12,
            ),
            _buildLegendItem(
              'Просроченные',
              const Color(0xFFC30202),
            ),
          ],
        ),
        _buildLegendItem(
          'Завершённые ',
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
