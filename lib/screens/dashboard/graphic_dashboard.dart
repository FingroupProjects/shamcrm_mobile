import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead%20chart/chart_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
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
  int? selectedIndex; // Индекс выбранной точки
  int? selectedLineIndex; // Индекс выбранной линии

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardChartBloc, DashboardChartState>(
      builder: (context, state) {
        if (state is DashboardChartLoading) {
          // return const Center(child: CircularProgressIndicator());
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
          List<List<ChartData>> paginatedData = _paginateData(state.chartData);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Клиенты',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    _buildChartData(state.chartData),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatsList(paginatedData[currentPage]),
                _buildPagination(paginatedData),
              ],
            ),
          );
        }

        return const Center(
          child: Text(
            '',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }

  List<List<ChartData>> _paginateData(List<ChartData> chartData) {
    List<List<ChartData>> paginatedData = [];
    for (int i = 0; i < chartData.length; i += itemsPerPage) {
      paginatedData.add(chartData.sublist(
          i,
          i + itemsPerPage > chartData.length
              ? chartData.length
              : i + itemsPerPage));
    }
    return paginatedData;
  }

  LineChartData _buildChartData(List<ChartData> chartData) {
    List<LineChartBarData> lineBars = chartData.asMap().entries.map((entry) {
      int lineIndex = entry.key;
      ChartData data = entry.value;

      List<FlSpot> spots = data.data.asMap().entries.map((entry) {
        double x = entry.key.toDouble();
        double y = entry.value < 0 ? 0 : entry.value.toDouble();
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
        isCurved: false,
        color: lineColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            bool isSelected =
                lineIndex == selectedLineIndex && index == selectedIndex;
            return FlDotCirclePainter(
              radius: isSelected ? 6 : 4,
              color: isSelected ? const Color.fromARGB(255, 25, 2, 47) : lineColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    double maxY = chartData
        .expand((data) => data.data)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxY / 5,
        verticalInterval: 1,
      ),
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
                'Январь',
                'Февраль',
                'Март',
                'Апрель',
                'Май',
                'Июнь',
                'Июль',
                'Август',
                'Сентябрь',
                'Октябрь',
                'Ноябрь',
                'Декабрь'
              ];
              return Text(
                months[value.toInt() % 12],
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: maxY * 1.1,
      lineBarsData: lineBars,
      lineTouchData: LineTouchData(
  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
    if (event is FlTapUpEvent && touchResponse?.lineBarSpots != null) {
      // Проверяем, что список не пуст
      final firstSpot = touchResponse!.lineBarSpots!.first;
      setState(() {
        selectedLineIndex = chartData.indexWhere(
          (data) => data.data.contains(firstSpot.y.toInt()),
        );
        selectedIndex = firstSpot.spotIndex; // Убедитесь, что 'spotIndex' существует.
      });
    }
  },
  touchTooltipData: LineTouchTooltipData(
    getTooltipItems: (List<LineBarSpot> spots) {
      return spots.map((spot) {
        // Найти соответствующий ChartData для линии и точки
        final lineData = chartData[spots.indexOf(spot)];
        final label = lineData.label; // Название статуса
        return LineTooltipItem(
          '$label: ${spot.y.toInt()}',
          const TextStyle(color: Colors.white));
      }).toList();
    },
  ),
),
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
        Text(
          '${currentPage + 1}/$totalPages',
          style: const TextStyle(fontSize: 16),
        ),
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
