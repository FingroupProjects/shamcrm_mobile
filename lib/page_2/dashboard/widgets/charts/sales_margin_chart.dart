import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/dashboard/expense_structure.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import 'download_popup_menu.dart';

enum TimeRange { sixMonths, year }

class SalesData {
  final String period;
  final double value;
  final DateTime? date;

  SalesData({required this.period, required this.value, this.date});
}

class ExpenseOrderChart extends StatefulWidget {
  const ExpenseOrderChart({super.key});

  @override
  State<ExpenseOrderChart> createState() => _ExpenseOrderChartState();
}

class _ExpenseOrderChartState extends State<ExpenseOrderChart> {
  TimeRange selectedTimeRange = TimeRange.sixMonths;
  bool isLoading = false;
  bool isDownloading = false;
  List<SalesData> salesData = [];

  @override
  void initState() {
    super.initState();
    loadSalesData();
  }

  // Simulate data loading
  Future<void> loadSalesData() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      salesData = _getDataForConfiguration();
      isLoading = false;
    });
  }

  List<SalesData> _getDataForConfiguration() {
    // Enhanced mock data based on profitability type and time range
    switch (selectedTimeRange) {
      case TimeRange.sixMonths:
        return _getSixMonthsData();
      case TimeRange.year:
        return _getYearlyData();
    }
  }

  List<SalesData> _getSixMonthsData() {
    return [
      SalesData(period: 'Июль', value: 30.0),
      SalesData(period: 'Август', value: 40.0),
      SalesData(period: 'Сентябрь', value: 25.0),
      SalesData(period: 'Октябрь', value: 50.0),
      SalesData(period: 'Ноябрь', value: 45.0),
      SalesData(period: 'Декабрь', value: 60.0),
    ];
  }

  List<SalesData> _getYearlyData() {
    return [
      SalesData(period: 'Q1 2024', value: 100.0),
      SalesData(period: 'Q2 2024', value: 115.0),
      SalesData(period: 'Q3 2024', value: 95.0),
      SalesData(period: 'Q4 2024', value: 135.0),
    ];
  }

  void onTimeRangeChanged(TimeRange range) {
    if (selectedTimeRange != range) {
      setState(() {
        selectedTimeRange = range;
      });
      loadSalesData();
    }
  }

  String getTimeRangeText(TimeRange range) {
    switch (range) {
      case TimeRange.sixMonths:
        return '6 месяцев';
      case TimeRange.year:
        return 'Год';
    }
  }

  void _handleDownload(DownloadFormat format) async {
    setState(() {
      isDownloading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
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
          // Header with title and download menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('profitability_sales'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Transform.translate(
                offset: const Offset(16, 0),
                child: DownloadPopupMenu(
                  onDownload: _handleDownload,
                  loading: isDownloading,
                  formats: const [
                    DownloadFormat.png,
                    DownloadFormat.svg,
                    DownloadFormat.csv,
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Period dropdown and Compare button
          Row(
            children: [
              Flexible(child: _buildPeriodDropdown()),
              const SizedBox(width: 12),
              Flexible(
                  child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  localizations.translate('compare'),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              )),
            ],
          ),

          const SizedBox(height: 16),

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
                : salesData.isEmpty
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
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.transparent,
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value < 0 || value >= salesData.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Transform.rotate(
                                        angle: -0.3,
                                        child: Text(
                                          salesData[value.toInt()].period,
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
                                  interval: 20,
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (salesData.length - 1).toDouble(),
                            minY: 0,
                            maxY:
                                salesData.isNotEmpty ? salesData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2 : 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  salesData.length,
                                  (index) => FlSpot(
                                    index.toDouble(),
                                    salesData[index].value,
                                  ),
                                ),
                                isCurved: true,
                                curveSmoothness: 0.3,
                                color: const Color(0xFF5D5FEF),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: const Color(0xFF5D5FEF),
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF5D5FEF).withOpacity(0.3),
                                      const Color(0xFF5D5FEF).withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                tooltipMargin: 8,
                                fitInsideVertically: true,
                                fitInsideHorizontally: true,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    final index = touchedSpot.x.toInt();
                                    if (index >= 0 && index < salesData.length) {
                                      return LineTooltipItem(
                                        '${salesData[index].period}\n',
                                        const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${touchedSpot.y.toInt()}%',
                                            style: const TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return null;
                                  }).toList();
                                },
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

  Widget _buildPeriodDropdown() {
    return CustomDropdown<TimeRange>(
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
      ),
      items: TimeRange.values,
      initialItem: selectedTimeRange,
      onChanged: (TimeRange? value) {
        if (value != null) {
          onTimeRangeChanged(value);
        }
      },
      headerBuilder: (context, selectedItem, enabled) {
        return Text(
          getTimeRangeText(selectedItem),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );
      },
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return Text(
          getTimeRangeText(item),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );
      },
    );
  }
}
