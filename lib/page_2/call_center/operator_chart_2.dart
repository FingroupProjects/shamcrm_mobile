import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OperatorChart2 extends StatelessWidget {
  const OperatorChart2({Key? key}) : super(key: key);

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
            'Длительность звонков',
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
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 2, color: Colors.green)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3, color: Colors.blue)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1, color: Colors.red)]),
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