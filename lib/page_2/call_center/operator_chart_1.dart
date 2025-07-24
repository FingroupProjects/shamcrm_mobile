import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OperatorChartRating extends StatelessWidget {
  const OperatorChartRating({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Рейтинг оператора по дням',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        );
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Пн', style: style);
                          case 1:
                            return const Text('Вт', style: style);
                          case 2:
                            return const Text('Ср', style: style);
                          case 3:
                            return const Text('Чт', style: style);
                          case 4:
                            return const Text('Пт', style: style);
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                ),
                minX: 0,
                maxX: 4,
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 4.0), // Понедельник
                      FlSpot(1, 3.5), // Вторник
                      FlSpot(2, 4.2), // Среда
                      FlSpot(3, 4.5), // Четверг (текущая дата)
                      FlSpot(4, 3.8), // Пятница
                    ],
                    isCurved: true,
                    color: const Color(0xFF6C5CE7),
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}