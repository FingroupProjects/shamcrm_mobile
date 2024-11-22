import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class DealStatsChart extends StatelessWidget {
  DealStatsChart({Key? key}) : super(key: key);

 // Define month names in Russian
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
  // Определяем цвета для каждого месяца как на сайте
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
              SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 4,
                      minY: 0,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          // tooltipBgColor: Colors.white,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()}',
                              const TextStyle(color: Colors.black),
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
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    months[value.toInt()],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              );
                            },
                            reservedSize: 28,
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
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: List.generate(months.length, (index) {
                        // Находим значение для текущего месяца
                        double value = 0;
                        if (state.dealStatsData.month == months[index]) {
                          value = state.dealStatsData.count.toDouble();
                        }

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              // Даже если значение 0, устанавливаем минимальную высоту 0.1
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
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}