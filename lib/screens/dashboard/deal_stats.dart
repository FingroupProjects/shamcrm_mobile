import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_state.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class DealStatsChart extends StatelessWidget {
  const DealStatsChart({Key? key}) : super(key: key);

  final List<String> months = const [
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
  String formatNumber(double value) {
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}млрд';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}м';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}т';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DealStatsBloc, DealStatsState>(
      builder: (context, state) {
        if (state is DealStatsError) {
          if (state.message.contains("Неавторизованный доступ!")) {
            _handleLogout(context);
            return const SizedBox();
          } else {
            return Center(
              child: Text(
                '${state.message}',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            );
          }
        } else if (state is DealStatsLoaded) {
          final data = state.dealStatsData.data;

          bool hasData =
              data.any((item) => item.totalSum > 0 || item.successfulSum > 0);

          double maxCount = hasData
              ? data.fold(
                  0,
                  (max, item) => math.max(
                      max,
                      math.max(item.totalSum.toDouble(),
                          item.successfulSum.toDouble())))
              : 100.0;
          double maxY = maxCount > 0 ? (maxCount * 1.1).ceilToDouble() : 100.0;

          if (!hasData) {
            final random = math.Random();
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 300,
                  padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      minY: 0,
                      groupsSpace: 12,
                      backgroundColor: Colors.white,
                      barGroups: List.generate(
                        months.length,
                        (index) => BarChartGroupData(
                          x: index,
                          groupVertically: false,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: 20 + random.nextDouble() * 80,
                              color: Colors.grey.withOpacity(0.3),
                              width: 8,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                            BarChartRodData(
                              toY: 20 + random.nextDouble() * 80,
                              color: Colors.grey.withOpacity(0.3),
                              width: 8,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
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
                                padding: const EdgeInsets.only(top: 16),
                                child: Transform.rotate(
                                  angle: -1.55,
                                  child: Text(
                                    months[value.toInt()],
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.withOpacity(0.5),
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
                                width: 60,
                                child: Text(
                                  formatNumber(value.toDouble()),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 42,
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
                        horizontalInterval: 20,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.1),
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
                          bottom:
                              BorderSide(color: Colors.grey.withOpacity(0.2)),
                          left: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Нет данных для отображения',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Gilroy",
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                )
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 8, bottom: 8),
                child: Text(
                  'Статистика сделок',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                height: 300,
                padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    backgroundColor: Colors.white,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 6,
                        tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        tooltipMargin: 4,
                        fitInsideVertically: true,
                        fitInsideHorizontally: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String label =
                              rodIndex == 0 ? 'Общая сумма' : 'Успешные';
                          double value = rod.toY;
                          return BarTooltipItem(
                            '${months[groupIndex]}\n$label\n',
                            const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(
                                text: value.toInt().toString(),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
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
                              padding: const EdgeInsets.only(top: 16),
                              child: Transform.rotate(
                                angle: -1.55,
                                child: Text(
                                  months[value.toInt()],
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
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
                              width: 60,
                              child: Text(
                                formatNumber(value.toDouble()),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          },
                          reservedSize: 42,
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
                      horizontalInterval: maxY / 5,
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
                      final totalSum = index < data.length
                          ? data[index].totalSum.toDouble()
                          : 0.0;
                      final successfulSum = index < data.length
                          ? data[index].successfulSum.toDouble()
                          : 0.0;

                      return BarChartGroupData(
                        x: index,
                        groupVertically: false,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: totalSum > 0 ? totalSum : 0.1,
                            color: const Color(0xFF3935E7),
                            width: 8,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          BarChartRodData(
                            toY: successfulSum > 0 ? successfulSum : 0.1,
                            color: Colors.green,
                            width: 8,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
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

        return const Center(
          child: Text(
            '',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    ApiService apiService = ApiService();
    await apiService.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
