import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OperatorChart3 extends StatelessWidget {
  const OperatorChart3({Key? key}) : super(key: key);

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
            'Рейтинг по дням',
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
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 4),
                      FlSpot(1, 3.5),
                      FlSpot(2, 4.5),
                    ],
                    isCurved: true,
                    color: const Color(0xFF6C5CE7),
                    barWidth: 2,
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Пн', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: Colors.grey));
                          case 1:
                            return const Text('Вт', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: Colors.grey));
                          case 2:
                            return const Text('Ср', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: Colors.grey));
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}