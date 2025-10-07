import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../models/page_2/dashboard/top_selling_model.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'download_popup_menu.dart';

class TopSellingProductsChart extends StatefulWidget {
  const TopSellingProductsChart(this.allTopSellingData, {super.key});

  final List<AllTopSellingData> allTopSellingData;

  @override
  State<TopSellingProductsChart> createState() => _TopSellingProductsChartState();
}

class _TopSellingProductsChartState extends State<TopSellingProductsChart> {
  TopSellingTimePeriod selectedPeriod = TopSellingTimePeriod.day;

  List<TopSellingData> _getDataForSelectedPeriod() {
    try {
      final periodData = widget.allTopSellingData.firstWhere(
        (item) => item.period == selectedPeriod,
      );
      return periodData.data.data;
    } catch (e) {
      return [];
    }
  }

  void onPeriodChanged(TopSellingTimePeriod period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
      });
    }
  }

  String getPeriodText(BuildContext context, TopSellingTimePeriod period) {
    final localizations = AppLocalizations.of(context)!;
    switch (period) {
      case TopSellingTimePeriod.day:
        return localizations.translate('day');
      case TopSellingTimePeriod.week:
        return localizations.translate('week');
      case TopSellingTimePeriod.month:
        return localizations.translate('month');
      case TopSellingTimePeriod.year:
        return localizations.translate('year');
    }
  }

  Widget buildPeriodButton(TopSellingTimePeriod period) {
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3935E7) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          getPeriodText(context, period),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final productsData = _getDataForSelectedPeriod();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  localizations.translate('top_selling_products'),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(16, 0),
                child: DownloadPopupMenu(onDownload: (DownloadFormat type) {}),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Period selector buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildPeriodButton(TopSellingTimePeriod.day),
                const SizedBox(width: 8),
                buildPeriodButton(TopSellingTimePeriod.week),
                const SizedBox(width: 8),
                buildPeriodButton(TopSellingTimePeriod.month),
                const SizedBox(width: 8),
                buildPeriodButton(TopSellingTimePeriod.year),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Chart content
          SizedBox(
            height: 300,
            child: productsData.isEmpty
                ? Center(
                    child: Text(
                      localizations.translate('no_data_to_display'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: "Gilroy",
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 16, top: 16),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: productsData.map((e) => double.parse(e.totalQuantity.toString())).reduce((a, b) => a > b ? a : b) *
                            1.2,
                        minY: 0,
                        groupsSpace: 20,
                        backgroundColor: Colors.transparent,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            tooltipMargin: 8,
                            fitInsideVertically: true,
                            fitInsideHorizontally: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final product = productsData[groupIndex];
                              return BarTooltipItem(
                                '${product.name}\n',
                                const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${rod.toY.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                                if (value < 0 || value >= productsData.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: Text(
                                      productsData[value.toInt()].name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 50,
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                );
                              },
                              reservedSize: 40,
                              interval: _getIntervalForPeriod(),
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getIntervalForPeriod(),
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
                        barGroups: List.generate(
                          productsData.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: double.parse(productsData[index].totalQuantity.toString()),
                                color: const Color(0xFF3935E7),
                                width: 28,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                debugPrint("Подробнее pressed");
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailedReportScreen(currentTabIndex: 5)));
              },
              child: Text(
                localizations.translate('more_details'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getIntervalForPeriod() {
    final productsData = _getDataForSelectedPeriod();
    if (productsData.isEmpty) return 1; // ← Changed from 100 to 1

    final maxValue = productsData.map((e) => e.totalQuantity.toDouble()).reduce((a, b) => a > b ? a : b);

    // ← Added more granular intervals for small values
    if (maxValue <= 10) return 2;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    if (maxValue <= 500) return 50;
    if (maxValue <= 1000) return 100;
    if (maxValue <= 2000) return 200;
    return 500;
  }
}
