import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';

class ManagersChart extends StatelessWidget {
  const ManagersChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffF59E0B), Color(0xffD97706)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffF59E0B).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Сделки и выручка по менеджерам',
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff0F172A),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: 350,
            child: Padding(
              padding: const EdgeInsets.only(
                  right: 20, left: 10, bottom: 20, top: 10),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 140,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.white,
                      tooltipBorder: const BorderSide(color: Color(0xffE2E8F0)),
                      tooltipRoundedRadius: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const managers = [
                            'Иван П.',
                            'Анна С.',
                            'Дмитрий К.',
                            'Елена В.',
                            'Сергей Н.'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < managers.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                managers[value.toInt()],
                                style: const TextStyle(
                                  color: Color(0xff64748B),
                                  fontSize: 11,
                                  fontFamily: 'Golos',
                                ),
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Color(0xff64748B),
                              fontSize: 12,
                              fontFamily: 'Golos',
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xffE2E8F0),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeGroupData(0, 89, 67),
                    _makeGroupData(1, 124, 98),
                    _makeGroupData(2, 97, 74),
                    _makeGroupData(3, 112, 89),
                    _makeGroupData(4, 87, 65),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          Container(
            padding: EdgeInsets.all(responsive.cardPadding),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xffE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Лучший менеджер',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff64748B),
                        fontFamily: 'Golos',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Анна С.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A),
                        fontFamily: 'Golos',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Общая выручка',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff64748B),
                        fontFamily: 'Golos',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$284,500',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A),
                        fontFamily: 'Golos',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Менеджеров',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff64748B),
                        fontFamily: 'Golos',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '5',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A),
                        fontFamily: 'Golos',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(
      int x, double totalDeals, double successDeals) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: totalDeals,
          gradient: const LinearGradient(
            colors: [Color(0xff6366F1), Color(0xff4F46E5)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: successDeals,
          gradient: const LinearGradient(
            colors: [Color(0xff10B981), Color(0xff059669)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
