import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class DealStatsChart extends StatelessWidget {
  DealStatsChart({Key? key}) : super(key: key);

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  final List<Color> monthColors = [
    Colors.lightBlue.shade300,
    Colors.purple.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.pink.shade300,
    Colors.teal.shade300,
    Colors.cyan.shade300,
    Colors.red.shade300,
    Colors.amber.shade300,
    Colors.blue.shade300,
    Colors.deepPurple.shade300,
    Colors.indigo.shade300,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DealStatsBloc, DealStatsState>(
      builder: (context, state) {
        if (state is DealStatsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DealStatsError) {
          return Center(child: Text('Ошибка: ${state.message}'));
        } else if (state is DealStatsLoaded) {
          List<int> monthData = state.dealStatsData.monthlyStats;

          int maxCount = monthData.fold(0, (max, value) => value > max ? value : max);
          // Add some padding to the max value to prevent bars from touching the top
          double maxY = (maxCount * 1.1).ceilToDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 24),
                child: Text(
                  'Сделки',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                height: 300,
                padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    minY: 0,
                    groupsSpace: 12,
                    backgroundColor: Colors.white,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 4,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tooltipMargin: 4,
                        fitInsideVertically: true,
                        fitInsideHorizontally: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${months[groupIndex]}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: rod.toY.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= months.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Transform.rotate(
                                angle: -1.55,
                                child: Text(
                                  months[value.toInt()],
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return SizedBox(
                              width: 60, // Increased width for larger numbers
                              child: Text(
                                value.toInt().toString(),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                          reservedSize: 60, // Increased reserved size
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      horizontalInterval: maxY / 5, // Adjust grid lines based on data
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        left: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    barGroups: List.generate(months.length, (index) {
                      final value = monthData[index].toDouble();
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value > 0 ? value : 0.1,
                            color: monthColors[index],
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}