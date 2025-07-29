import 'package:crm_task_manager/models/page_2/call_statistics1_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticChart1 extends StatelessWidget {
  final CallStatistics statistics;

  const StatisticChart1({Key? key, required this.statistics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Текущий месяц (июль 2025 = месяц 7, индекс 6)
    const int currentMonthIndex = 6; // 0-based индекс для июля

    // Подготовка данных до текущего месяца
    List<FlSpot> getSpots(double Function(CallStatMonth) valueExtractor) {
      List<FlSpot> spots = [];
      for (int i = 0; i < statistics.result.length; i++) {
        // Ограничиваем данные до текущего месяца
        double value = i <= currentMonthIndex ? valueExtractor(statistics.result[i]) : 0;
        spots.add(FlSpot(i.toDouble(), value));
      }
      return spots;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статистика звонков',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 50,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final monthNames = [
                          'Янв',
                          'Фев',
                          'Мар',
                          'Апр',
                          'Май',
                          'Июн',
                          'Июл',
                          'Авг',
                          'Сен',
                          'Окт',
                          'Ноя',
                          'Дек'
                        ];
                        final index = value.toInt();
                        if (index >= 0 && index < monthNames.length) {
                          return Text(
                            monthNames[index],
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      },
                      interval: 50,
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                minX: 0,
                maxX: 11, // Все 12 месяцев
                minY: 0,
                maxY: 200,
                lineBarsData: [
                  // Общее количество звонков
                  LineChartBarData(
                    spots: getSpots((data) => data.total.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF6C5CE7),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6C5CE7).withOpacity(0.2),
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                  ),
                  // Исходящие звонки
                  LineChartBarData(
                    spots: getSpots((data) => data.outgoing.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF00C48C),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00C48C).withOpacity(0.2),
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                  ),
                  // Пропущенные звонки
                  LineChartBarData(
                    spots: getSpots((data) => data.missed.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFFFD9843),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFD9843).withOpacity(0.2),
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                  ),
                  // Звонки без перезвона
                  LineChartBarData(
                    spots: getSpots((data) => data.notCalledBackCount.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFFE84393),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFE84393).withOpacity(0.2),
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                  ),
                  // Среднее время ответа
                  LineChartBarData(
                    spots: getSpots((data) => data.averageAnswerTime * 10),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF0984E3),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0984E3).withOpacity(0.2),
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tooltipMargin: 10,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final int xValue = touchedSpot.x.toInt();
                        final monthNames = [
                          'Янв',
                          'Фев',
                          'Мар',
                          'Апр',
                          'Май',
                          'Июн',
                          'Июл',
                          'Авг',
                          'Сен',
                          'Окт',
                          'Ноя',
                          'Дек'
                        ];
                        String month = xValue < monthNames.length ? monthNames[xValue] : '';

                        String metricName;
                        Color textColor;
                        double value = touchedSpot.y;
                        if (touchedSpot.barIndex == 4) {
                          value = value / 10; // Обратное масштабирование для времени ответа
                        }
                        if (touchedSpot.barIndex == 0) {
                          metricName = 'Общее количество звонков';
                          textColor = const Color(0xFF6C5CE7);
                        } else if (touchedSpot.barIndex == 1) {
                          metricName = 'Исходящие звонки';
                          textColor = const Color(0xFF00C48C);
                        } else if (touchedSpot.barIndex == 2) {
                          metricName = 'Пропущенные звонки';
                          textColor = const Color(0xFFFD9843);
                        } else if (touchedSpot.barIndex == 3) {
                          metricName = 'Звонки без перезвона';
                          textColor = const Color(0xFFE84393);
                        } else {
                          metricName = 'Среднее время ответа';
                          textColor = const Color(0xFF0984E3);
                        }

                        return LineTooltipItem(
                          '$month: ${value.toStringAsFixed(touchedSpot.barIndex == 4 ? 2 : 0)} ($metricName)',
                          TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: textColor,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: barData.color, strokeWidth: 2),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 4,
                            color: barData.color ?? Colors.black,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFF6C5CE7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Общее количество звонков',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFF00C48C),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Исходящие звонки',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFFFD9843),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Пропущенные звонки',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFFE84393),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Звонки без перезвона',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFF0984E3),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Среднее время ответа',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}