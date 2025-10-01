import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import 'download_popup_menu.dart';

enum TimePeriod { day, week, month, year }

class SalesData {
  final String period;
  final double value;

  SalesData({required this.period, required this.value});
}

class SalesDynamicsLineChart extends StatefulWidget {
  const SalesDynamicsLineChart({Key? key}) : super(key: key);

  @override
  State<SalesDynamicsLineChart> createState() => _SalesDynamicsLineChartState();
}

class _SalesDynamicsLineChartState extends State<SalesDynamicsLineChart> {
  TimePeriod selectedPeriod = TimePeriod.year;
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

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      salesData = _getDataForPeriod(selectedPeriod);
      isLoading = false;
    });
  }

  List<SalesData> _getDataForPeriod(TimePeriod period) {
    // Mock data for different time periods
    switch (period) {
      case TimePeriod.day:
        return [
          SalesData(period: '09:00', value: 25),
          SalesData(period: '12:00', value: 45),
          SalesData(period: '15:00', value: 35),
          SalesData(period: '18:00', value: 60),
          SalesData(period: '21:00', value: 50),
        ];
      case TimePeriod.week:
        return [
          SalesData(period: 'Пн', value: 30),
          SalesData(period: 'Вт', value: 45),
          SalesData(period: 'Ср', value: 25),
          SalesData(period: 'Чт', value: 55),
          SalesData(period: 'Пт', value: 70),
          SalesData(period: 'Сб', value: 80),
          SalesData(period: 'Вс', value: 40),
        ];
      case TimePeriod.month:
        return [
          SalesData(period: 'Неделя 1', value: 40),
          SalesData(period: 'Неделя 2', value: 35),
          SalesData(period: 'Неделя 3', value: 50),
          SalesData(period: 'Неделя 4', value: 45),
        ];
      case TimePeriod.year:
        return [
          SalesData(period: 'Июль', value: 30),
          SalesData(period: 'Август', value: 40),
          SalesData(period: 'Сентябрь', value: 25),
          SalesData(period: 'Октябрь', value: 50),
          SalesData(period: 'Ноябрь', value: 45),
          SalesData(period: 'Декабрь', value: 100),
        ];
    }
  }

  void onPeriodChanged(TimePeriod period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
      });
      loadSalesData();
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

  void _handleDownload(DownloadFormat format) async {
    setState(() {
      isDownloading = true;
    });

    try {
      // Simulate download process
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('sales_dynamics'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Transform.translate(
                offset: const Offset(16, 0),
                child:DownloadPopupMenu(
                onDownload: _handleDownload,
                loading: isDownloading,
                formats: const [
                  DownloadFormat.png,
                  DownloadFormat.svg,
                  DownloadFormat.csv,
                ],
              ),),
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
                            borderData: FlBorderData(
                              show: false,
                            ),
                            minX: 0,
                            maxX: (salesData.length - 1).toDouble(),
                            minY: 0,
                            maxY: salesData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
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
                                color: const Color(0xFF00E676),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: const Color(0xFF00E676),
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
                                      const Color(0xFF00E676).withOpacity(0.3),
                                      const Color(0xFF00E676).withOpacity(0.0),
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
                                            text: '${touchedSpot.y.toInt()}',
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
}
