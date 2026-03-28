import 'package:crm_task_manager/models/page_2/dashboard/order_dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../screens/profile/languages/app_localizations.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'download_popup_menu.dart';

// Removed hardcoded strings - now using localization

class OrderQuantityChart extends StatefulWidget {
  const OrderQuantityChart({super.key, required this.orderDashboardData});
  final List<AllOrdersData> orderDashboardData;

  @override
  State<OrderQuantityChart> createState() => _OrderQuantityChartState();
}

class _OrderQuantityChartState extends State<OrderQuantityChart> {
  bool isDownloading = false;
  int? selectedIndex;
  int? selectedLineIndex;
  final Map<String, bool> _lineVisibility = {};
  OrderTimePeriod selectedPeriod = OrderTimePeriod.week;

  // Generate colors based on index
  final List<Color> lineColors = [
    const Color(0xFF3935E7),
    const Color(0xFFFFA726),
    const Color(0xFF66BB6A),
    const Color(0xFFEF5350),
    const Color(0xFF42A5F5),
    const Color(0xFFAB47BC),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLineVisibility();
  }

  void _initializeLineVisibility() {
    final currentData = _getCurrentPeriodData();
    if (currentData != null) {
      for (var chartData in currentData.data.chartData) {
        _lineVisibility[chartData.name] = true;
      }
    }
  }

  AllOrdersData? _getCurrentPeriodData() {
    try {
      return widget.orderDashboardData.firstWhere(
            (data) => data.period == selectedPeriod,
      );
    } catch (e) {
      return null;
    }
  }

  Color _getColorForIndex(int index) {
    return lineColors[index % lineColors.length];
  }

  void onPeriodChanged(OrderTimePeriod period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
        selectedIndex = null;
        selectedLineIndex = null;
        _lineVisibility.clear();
        _initializeLineVisibility();
      });
    }
  }

  String getPeriodText(BuildContext context, OrderTimePeriod period) {
    final localizations = AppLocalizations.of(context)!;
    switch (period) {
      case OrderTimePeriod.week:
        return localizations.translate('week');
      case OrderTimePeriod.month:
        return localizations.translate('month');
      case OrderTimePeriod.year:
        return localizations.translate('year');
    }
  }

  Widget buildPeriodButton(OrderTimePeriod period) {
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

  double _calculateInterval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 150) return 20;
    if (maxY <= 500) return 50;
    if (maxY <= 1000) return 100;
    if (maxY <= 2000) return 200;
    return 500;
  }

  LineChartData _buildChartData(List<OrderChartData> chartData) {
    // Determine maxX based on data points
    double maxX = 0;
    for (var data in chartData) {
      if (data.data.isNotEmpty) {
        maxX = data.data.length - 1.0;
      }
    }
    if (maxX < 1) maxX = 11;

    List<LineChartBarData> lineBars = chartData.asMap().entries.map((entry) {
      int lineIndex = entry.key;
      OrderChartData data = entry.value;

      if (!(_lineVisibility[data.name] ?? true)) {
        return LineChartBarData(spots: [], show: false, dotData: const FlDotData(show: false));
      }

      List<FlSpot> spots = data.data.asMap().entries.map((entry) {
        double x = entry.key.toDouble();
        double y = entry.value.amount < 0 ? 0 : entry.value.amount.toDouble();
        return FlSpot(x, y);
      }).toList();

      Color lineColor = _getColorForIndex(lineIndex);

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: lineColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            bool isSelected = lineIndex == selectedLineIndex && index == selectedIndex;
            return FlDotCirclePainter(
              radius: isSelected ? 6 : 4,
              color: isSelected ? Colors.black87 : lineColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    // Find the actual maximum value from data
    double maxY = 0;
    for (var data in chartData) {
      for (var point in data.data) {
        if (point.amount > maxY) {
          maxY = point.amount.toDouble();
        }
      }
    }

    // Set minimum maxY to avoid division by zero and ensure readable chart
    if (maxY == 0) {
      maxY = 1; // Default scale when no data
    }

    double adjustedMaxY = maxY * 1.1;
    double horizontalInterval = _calculateInterval(adjustedMaxY);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: horizontalInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: horizontalInterval,
            reservedSize: 40,
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
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (chartData.isNotEmpty &&
                  chartData.first.data.length > index &&
                  index >= 0) {
                String label = chartData.first.data[index].label;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: adjustedMaxY,
      lineBarsData: lineBars,
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          if (event is FlTapUpEvent && touchResponse?.lineBarSpots != null) {
            final firstSpot = touchResponse!.lineBarSpots!.first;
            setState(() {
              selectedLineIndex = firstSpot.barIndex;
              selectedIndex = firstSpot.spotIndex;
            });
          }
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tooltipMargin: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (List<LineBarSpot> spots) {
            return spots.map((spot) {
              if (spot.barIndex >= chartData.length) return null;
              final lineData = chartData[spot.barIndex];
              if (!(_lineVisibility[lineData.name] ?? true)) return null;

              return LineTooltipItem(
                '${lineData.name}\n',
                const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: '${spot.y.toInt()}',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildLegend(List<OrderChartData> chartData) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: chartData.asMap().entries.map((entry) {
        int index = entry.key;
        OrderChartData data = entry.value;
        bool isVisible = _lineVisibility[data.name] ?? true;
        Color lineColor = _getColorForIndex(index);

        return GestureDetector(
          onTap: () {
            setState(() {
              _lineVisibility[data.name] = !isVisible;
              if (!isVisible) {
                selectedIndex = null;
                selectedLineIndex = null;
              }
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: lineColor.withOpacity(isVisible ? 1.0 : 0.3),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                data.name,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(isVisible ? 1.0 : 0.3),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currentData = _getCurrentPeriodData();
    final chartData = currentData?.data.chartData ?? [];

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
              Text(
                localizations.translate('order_quantity'),
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

          // Period selector buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildPeriodButton(OrderTimePeriod.week),
                const SizedBox(width: 8),
                buildPeriodButton(OrderTimePeriod.month),
                const SizedBox(width: 8),
                buildPeriodButton(OrderTimePeriod.year),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          if (chartData.isNotEmpty) _buildLegend(chartData),

          const SizedBox(height: 24),

          // Chart content
          SizedBox(
            height: 300,
            child: chartData.isEmpty
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
              child: LineChart(_buildChartData(chartData)),
            ),
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                debugPrint("Подробнее pressed");
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailedReportScreen(currentTabIndex: 10)));
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
}