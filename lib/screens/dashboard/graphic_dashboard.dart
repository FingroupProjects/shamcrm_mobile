import 'package:crm_task_manager/models/dashboard_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';

class GraphicsDashboard extends StatelessWidget {
  const GraphicsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (state is DashboardError) {
          return Center(
            child: Text(
              'Ошибка загрузки данных',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (state is DashboardLoaded && state.chartData.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 300, // Задаем фиксированную высоту
              child: LineChart(
                _buildChartData(state.chartData),
              ),
            ),
          );
        }

        return Center(
          child: Text(
            'Нет данных для отображения',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }

  LineChartData _buildChartData(List<ChartData> chartData) {
    List<LineChartBarData> lineBars = chartData.map((data) {
      List<FlSpot> spots = data.data.asMap().entries.map((entry) {
        double x = entry.key.toDouble();
        double y = entry.value != null ? entry.value.toDouble() : 0.0; // Проверяем значения
        return FlSpot(x, y);
      }).toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: Color(int.parse(data.color.replaceFirst('#', '0xff'))),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
      );
    }).toList();

    double maxY = chartData
        .expand((data) => data.data)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final months = [
                'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
              ];
              return Text(
                months[value.toInt()],
                style: TextStyle(fontSize: 10, color: Colors.grey),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: maxY,
      lineBarsData: lineBars,
    );
  }
}
