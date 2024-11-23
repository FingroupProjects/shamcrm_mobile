import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/stats_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GraphicsDashboard extends StatefulWidget {
  const GraphicsDashboard({Key? key}) : super(key: key);

  @override
  _GraphicsDashboardState createState() => _GraphicsDashboardState();
}

class _GraphicsDashboardState extends State<GraphicsDashboard> {
  int currentPage = 0;
  final int itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardChartBloc, DashboardChartState>(
      builder: (context, state) {
        if (state is DashboardChartLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DashboardChartError) {
          return const Center(
            child: Text(
              'Ошибка загрузки данных',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (state is DashboardChartLoaded && state.chartData.isNotEmpty) {
          // Разбиваем данные на страницы
          List<List<ChartData>> paginatedData = _paginateData(state.chartData);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Клиенты',  // Добавляем текст "Клиенты" перед графиком
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),  // Отступ
                SizedBox(
                  height: 300, // Фиксированная высота графика
                  child: LineChart(
                    _buildChartData(state.chartData),
                  ),
                ),
                const SizedBox(height: 16), // Отступ между графиком и списком
                _buildStatsList(paginatedData[currentPage]), // Список для текущей страницы
                _buildPagination(paginatedData), // Пагинация
              ],
            ),
          );
        }

        return const Center(
          child: Text(
            'Нет данных для отображения',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }
  // Разбиваем список данных на страницы
  List<List<ChartData>> _paginateData(List<ChartData> chartData) {
    List<List<ChartData>> paginatedData = [];
    for (int i = 0; i < chartData.length; i += itemsPerPage) {
      paginatedData.add(chartData.sublist(i, i + itemsPerPage > chartData.length ? chartData.length : i + itemsPerPage));
    }
    return paginatedData;
  }

  LineChartData _buildChartData(List<ChartData> chartData) {
    List<LineChartBarData> lineBars = chartData.map((data) {
      List<FlSpot> spots = data.data.asMap().entries.map((entry) {
        double x = entry.key.toDouble();
        double y = entry.value.toDouble();
        return FlSpot(x, y);
      }).toList();

      Color lineColor;
      try {
        lineColor = Color(int.parse(data.color.replaceFirst('#', '0xff')));
      } catch (e) {
        lineColor = Colors.black;
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: lineColor,
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
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final months = [
                'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 
                'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
              ];
              return Text(
                months[value.toInt() % 12],
                style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  Widget _buildStatsList(List<ChartData> chartData) {
    List<Widget> stats = chartData.map((data) {
      Color color = Color(int.parse(data.color.replaceFirst('#', '0xff')));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('${data.label}'),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статистика:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...stats,
      ],
    );
  }

  // Добавляем пагинацию с разделителем
  Widget _buildPagination(List<List<ChartData>> paginatedData) {
    int totalPages = paginatedData.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: currentPage > 0
              ? () {
                  setState(() {
                    currentPage--;
                  });
                }
              : null,
        ),
        Text('${currentPage + 1}/$totalPages', style: const TextStyle(fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.arrow_right),
          onPressed: currentPage < totalPages - 1
              ? () {
                  setState(() {
                    currentPage++;
                  });
                }
              : null,
        ),
      ],
    );
  }
}
