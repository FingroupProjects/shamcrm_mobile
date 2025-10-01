import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import 'download_popup_menu.dart';

enum TimePeriod { day, week, month, year }

class ProductData {
  final String name;
  final double value;

  ProductData({required this.name, required this.value});
}

class TopSellingProductsChart extends StatefulWidget {
  const TopSellingProductsChart({Key? key}) : super(key: key);

  @override
  State<TopSellingProductsChart> createState() => _TopSellingProductsChartState();
}

class _TopSellingProductsChartState extends State<TopSellingProductsChart> {
  TimePeriod selectedPeriod = TimePeriod.day;
  bool isLoading = false;
  List<ProductData> productsData = [];

  @override
  void initState() {
    super.initState();
    loadProductsData();
  }

  // Simulate data loading
  Future<void> loadProductsData() async {
    setState(() {
      isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      productsData = _getDataForPeriod(selectedPeriod);
      isLoading = false;
    });
  }

  List<ProductData> _getDataForPeriod(TimePeriod period) {
    // Mock data for different time periods
    switch (period) {
      case TimePeriod.day:
        return [
          ProductData(name: 'MacBook', value: 80),
          ProductData(name: 'iPhone 11', value: 400),
          ProductData(name: 'AirPods Pro', value: 300),
          ProductData(name: 'iPad Air', value: 200),
          ProductData(name: 'Apple Watch', value: 290),
        ];
      case TimePeriod.week:
        return [
          ProductData(name: 'MacBook', value: 150),
          ProductData(name: 'iPhone 11', value: 450),
          ProductData(name: 'AirPods Pro', value: 380),
          ProductData(name: 'iPad Air', value: 250),
          ProductData(name: 'Apple Watch', value: 340),
        ];
      case TimePeriod.month:
        return [
          ProductData(name: 'MacBook', value: 600),
          ProductData(name: 'iPhone 11', value: 800),
          ProductData(name: 'AirPods Pro', value: 750),
          ProductData(name: 'iPad Air', value: 500),
          ProductData(name: 'Apple Watch', value: 650),
        ];
      case TimePeriod.year:
        return [
          ProductData(name: 'MacBook', value: 2400),
          ProductData(name: 'iPhone 11', value: 3200),
          ProductData(name: 'AirPods Pro', value: 2800),
          ProductData(name: 'iPad Air', value: 2000),
          ProductData(name: 'Apple Watch', value: 2600),
        ];
    }
  }

  void onPeriodChanged(TimePeriod period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
      });
      loadProductsData();
    }
  }

  String getPeriodText(BuildContext context, TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return 'День';
      case TimePeriod.week:
        return 'Неделя';
      case TimePeriod.month:
        return 'Месяц';
      case TimePeriod.year:
        return 'Год';
    }
  }

  Widget buildPeriodButton(TimePeriod period) {
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
    return Container(
      margin: const EdgeInsets.all(16),
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
              Text(
                localizations.translate('top_selling_products'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              DownloadPopupMenu(onDownload: (DownloadFormat type) {}),
            ],
          ),

          const SizedBox(height: 16),

          // Period selector buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildPeriodButton(TimePeriod.day),
                const SizedBox(width: 8),
                buildPeriodButton(TimePeriod.week),
                const SizedBox(width: 8),
                buildPeriodButton(TimePeriod.month),
                const SizedBox(width: 8),
                buildPeriodButton(TimePeriod.year),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Chart content
          SizedBox(
            height: 300,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3935E7),
                    ),
                  )
                : productsData.isEmpty
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
                            maxY: productsData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
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
                                  return BarTooltipItem(
                                    '${productsData[groupIndex].name}\n',
                                    const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${rod.toY.toInt()}',
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
                                  interval: selectedPeriod == TimePeriod.year ? 500 : 100,
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
                              drawVerticalLine: false,
                              horizontalInterval: selectedPeriod == TimePeriod.year ? 500 : 100,
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
                                    toY: productsData[index].value,
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
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                        ),
                      ),
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
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
}
