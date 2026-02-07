import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';

class ProductsChart extends StatelessWidget {
  const ProductsChart({Key? key}) : super(key: key);

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
                      colors: [Color(0xffF97316), Color(0xffEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffF97316).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ТОП продаваемых товаров',
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                    fontFamily: 'Golos',
                  ),
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: 400,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, left: 10, bottom: 20),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 450,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.white,
                      tooltipBorder: const BorderSide(color: Color(0xffE2E8F0)),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} шт',
                          const TextStyle(
                            color: Color(0xff0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Golos',
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 120,
                        getTitlesWidget: (value, meta) {
                          const products = [
                            'Смартфон Galaxy S24',
                            'Ноутбук MacBook Pro',
                            'Наушники AirPods',
                            'Планшет iPad Air',
                            'Часы Apple Watch',
                            'Клавиатура MX Keys',
                            'Мышь MX Master',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < products.length) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                products[value.toInt()],
                                style: const TextStyle(
                                  color: Color(0xff64748B),
                                  fontSize: 11,
                                  fontFamily: 'Golos',
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 12,
                                fontFamily: 'Golos',
                              ),
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
                    drawHorizontalLine: false,
                    verticalInterval: 50,
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Color(0xffE2E8F0),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeGroupData(0, 387),
                    _makeGroupData(1, 342),
                    _makeGroupData(2, 298),
                    _makeGroupData(3, 267),
                    _makeGroupData(4, 234),
                    _makeGroupData(5, 189),
                    _makeGroupData(6, 156),
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
                      'Топ товар',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff64748B),
                        fontFamily: 'Golos',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Galaxy S24',
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
                      'Всего продано',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff64748B),
                        fontFamily: 'Golos',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1,873 шт',
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

  BarChartGroupData _makeGroupData(int x, double value) {
    final colors = [
      [const Color(0xffF97316), const Color(0xffEA580C)],
      [const Color(0xff6366F1), const Color(0xff4F46E5)],
      [const Color(0xff10B981), const Color(0xff059669)],
      [const Color(0xffEC4899), const Color(0xffDB2777)],
      [const Color(0xff8B5CF6), const Color(0xff7C3AED)],
      [const Color(0xff06B6D4), const Color(0xff0891B2)],
      [const Color(0xffF59E0B), const Color(0xffD97706)],
    ];

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          gradient: LinearGradient(
            colors: colors[x % colors.length],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          width: 20,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}
