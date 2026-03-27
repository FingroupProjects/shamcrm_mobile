import 'package:crm_task_manager/models/page_2/call_statistics1_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticChart1 extends StatelessWidget {
  final CallStatistics statistics;

  const StatisticChart1({Key? key, required this.statistics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const int currentMonthIndex = 6; // Июль 2025, 0-based индекс

    // Подготовка данных до текущего месяца
    List<FlSpot> getSpots(double Function(CallStatMonth) valueExtractor) {
      List<FlSpot> spots = [];
      for (int i = 0; i < statistics.result.length; i++) {
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 0.5,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                 bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 40, // Увеличено для повернутого текста
    getTitlesWidget: (value, meta) {
      const monthNames = [
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
      if (index < 0 || index >= monthNames.length) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 16), // Смещение текста вниз
        child: Transform.rotate(
          angle: -1.55, // Поворот текста (~90 градусов)
          child: Text(
            monthNames[index],
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.black, // Явно задаем цвет для согласованности
            ),
          ),
        ),
      );
    },
    interval: 1,
  ),
),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
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
                maxX: 11,
                minY: 0,
                maxY: 250, // Увеличено для вмещения всех данных
                lineBarsData: [
                  // Общее количество звонков
                  
                  LineChartBarData(
                    spots: getSpots((data) => data.total.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF038FFB),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF038FFB).withOpacity(0.2),
                    ),
                  ),
                  // Среднее время ответа
                  LineChartBarData(
                    spots: getSpots((data) => data.averageAnswerTime * 10),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF01E396),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF01E396).withOpacity(0.2),
                    ),
                  ),
                  // Звонки без перезвона
                  LineChartBarData(
                    spots: getSpots((data) => data.notCalledBackCount.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFFFEB01A),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFEB01A).withOpacity(0.2),
                    ),
                  ),
                  // Пропущенные звонки
                  LineChartBarData(
                    spots: getSpots((data) => data.missed.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFFFF4560),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF4560).withOpacity(0.2),
                    ),
                  ),
                  // Исходящие звонки
                  LineChartBarData(
                    spots: getSpots((data) => data.outgoing.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF775DD0),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF775DD0).withOpacity(0.2),
                    ),
                  ),
                  // Входящие звонки
                  LineChartBarData(
                    spots: getSpots((data) => data.incoming.toDouble()),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF038FFB).withOpacity(0.7), // Отличаем от total
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF038FFB).withOpacity(0.1),
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
                        const monthNames = [
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
                        if (touchedSpot.barIndex == 1) {
                          value = value / 10; // Обратное масштабирование для времени ответа
                        }
                        switch (touchedSpot.barIndex) {
                          case 0:
                            metricName = 'Общее количество звонков';
                            textColor = const Color(0xFF038FFB);
                            break;
                          case 1:
                            metricName = 'Среднее время ответа';
                            textColor = const Color(0xFF01E396);
                            break;
                          case 2:
                            metricName = 'Звонки без перезвона';
                            textColor = const Color(0xFFFEB01A);
                            break;
                          case 3:
                            metricName = 'Пропущенные звонки';
                            textColor = const Color(0xFFFF4560);
                            break;
                          case 4:
                            metricName = 'Исходящие звонки';
                            textColor = const Color(0xFF775DD0);
                            break;
                          case 5:
                            metricName = 'Входящие звонки';
                            textColor = const Color(0xFF038FFB).withOpacity(0.7);
                            break;
                          default:
                            metricName = '';
                            textColor = Colors.black;
                        }

                        return LineTooltipItem(
                          '$month: ${value.toStringAsFixed(touchedSpot.barIndex == 1 ? 2 : 0)} ($metricName)',
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
                  getTouchedSpotIndicator: (barData, spotIndexes) {
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
    Container(
      width: double.infinity, // Forces each item to take full width
      child: _buildLegendItem('Общее количество звонков', const Color(0xFF038FFB)),
    ),
    Container(
      width: double.infinity,
      child: _buildLegendItem('Среднее время ответа', const Color(0xFF01E396)),
    ),
    Container(
      width: double.infinity,
      child: _buildLegendItem('Звонки без перезвона', const Color(0xFFFEB01A)),
    ),
    Container(
      width: double.infinity,
      child: _buildLegendItem('Пропущенные звонки', const Color(0xFFFF4560)),
    ),
    Container(
      width: double.infinity,
      child: _buildLegendItem('Исходящие звонки', const Color(0xFF775DD0)),
    ),
    Container(
      width: double.infinity,
      child: _buildLegendItem('Входящие звонки', const Color(0xFF038FFB).withOpacity(0.7)),
    ),
  ],
),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}