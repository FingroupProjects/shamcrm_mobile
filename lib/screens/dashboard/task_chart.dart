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
    context.read<DashboardTaskChartBloc>().add(LoadTaskChartData());
  }

 @override
Widget build(BuildContext context) {
  return BlocConsumer<DashboardTaskChartBloc, DashboardTaskChartState>(
    listener: (context, state) {
      // Можно добавить действия при изменении состояния, если нужно
    },
    builder: (context, state) {
      if (state is DashboardTaskChartLoading) {
        // Показать индикатор загрузки, если данные загружаются
        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey.withOpacity(0.1),
            //     spreadRadius: 0,
            //     blurRadius: 4,
            //     offset: const Offset(0, 2),
            //   ),
            // ],
          ),
          child: Center(
            // child: CircularProgressIndicator(), // Индикатор загрузки
          ),
        );
      } else if (state is DashboardTaskChartError) {
        // Показать сообщение об ошибке, если загрузка данных не удалась
        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Ошибка загрузки данных',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else if (state is DashboardTaskChartLoaded) {
        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12), // Отступ
              const Text(
                'Задачи',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildChart(state),
              ),
              const SizedBox(height: 16),
              _buildLegend(state.taskChartData),
            ],
          ),
        );
      }
      return const SizedBox.shrink(); // Возвращаем пустой контейнер, если нет данных
    },
  );
}


  Widget _buildChart(DashboardTaskChartState state) {
    if (state is DashboardTaskChartLoading) {
      // return const Center(child: CircularProgressIndicator());
    } else if (state is DashboardTaskChartError) {
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
      const Color.fromARGB(255, 29, 93, 197), // Активный - голубой
      const Color.fromARGB(255, 255, 0, 0), // Просрочен - фиолетовый
      const Color(0xFF34D399), // Завершён - зеленый
    ];

    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final opacity = isTouched ? 1.0 : 0.8;
      final radius = isTouched ? 50.0 : 40.0;

      return PieChartSectionData(
        color: colors[i].withOpacity(opacity),
        value: taskChart.data[i],
        title: isTouched ? '${taskChart.data[i].toStringAsFixed(1)}' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegend(TaskChart taskChart) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              'Активные ',
              const Color.fromARGB(255, 29, 93, 197),
            ),
            const SizedBox(width: 24),
            _buildLegendItem(
              'Просроченные',
              const Color.fromARGB(255, 245, 0, 0),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          'Завершённые ',
          const Color(0xFF34D399),
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
            color: Color(0xFF718096),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
