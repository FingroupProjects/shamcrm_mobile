import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticChart1 extends StatelessWidget {
  const StatisticChart1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Статистика',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 20,
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
                  horizontalInterval: 20,
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Янв',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ));
                          case 2:
                            return const Text('Февр',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ));
                          case 4:
                            return const Text('Март',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ));
                          case 6:
                            return const Text('Апр',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ));
                          case 8:
                            return const Text('Май',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ));
                          case 10:
                            return const Text('Июн',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ));
                          case 12:
                            return const Text('Июл',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ));
                          default:
                            return const Text('');
                        }
                      },
                      interval: 2,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ));
                      },
                      interval: 20,
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                minX: 0,
                maxX: 14,
                minY: 0,
                maxY: 110,
                lineBarsData: [

  LineChartBarData(
    spots: [
      FlSpot(0, 18),
      FlSpot(2, 43),
      FlSpot(4, 66),
      FlSpot(6, 93),
      FlSpot(8, 58),
      FlSpot(10, 83),
      FlSpot(12, 47),
      FlSpot(14, 33),
    ],
    isCurved: true,
    color: const Color(0xFF6C5CE7),
    barWidth: 2,
    dotData: FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      color: const Color(0xFF6C5CE7).withOpacity(0.2),
    ),
  ),
  LineChartBarData(
    spots: [
      FlSpot(0, 28),
      FlSpot(2, 54),
      FlSpot(4, 76),
      FlSpot(6, 74),
      FlSpot(8, 87),
      FlSpot(10, 62),
      FlSpot(12, 42),
      FlSpot(14, 23),
    ],
    isCurved: true,
    color: const Color(0xFF00C48C),
    barWidth: 2,
    dotData: FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      color: const Color(0xFF00C48C).withOpacity(0.2),
    ),
  ),
  LineChartBarData(
    spots: [
      FlSpot(0, 12),
      FlSpot(2, 27),
      FlSpot(4, 53),
      FlSpot(6, 58),
      FlSpot(8, 43),
      FlSpot(10, 68),
      FlSpot(12, 29),
      FlSpot(14, 52),
    ],
    isCurved: true,
    color: const Color(0xFFFD9843),
    barWidth: 2,
    dotData: FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      color: const Color(0xFFFD9843).withOpacity(0.2),
    ),
  ),


                ],
                lineTouchData: LineTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFF6C5CE7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Оператор 1',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFF00C48C),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Оператор 2',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFFFD9843),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Оператор 3',
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