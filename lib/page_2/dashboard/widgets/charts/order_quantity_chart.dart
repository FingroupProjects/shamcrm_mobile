import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../screens/profile/languages/app_localizations.dart';
import 'download_popup_menu.dart';

// Translations
class _OrderQuantityStrings {
  static const String orderQuantity = 'Количество заказов';
  static const String day = 'День';
  static const String week = 'Неделя';
  static const String month = 'Месяц';
  static const String year = 'Год';
  static const String pending = 'В ожидании';
  static const String paid = 'Оплачено';
  static const String cancelled = 'Отменено';
  static const String noDataToDisplay = 'Нет данных для отображения';
  static const String moreDetails = 'Подробнее';
}

enum TimePeriod { day, week, month, year }

class OrderData {
  final String label;
  final List<double> data;
  final Color color;

  OrderData({
    required this.label,
    required this.data,
    required this.color,
  });
}

class OrderQuantityChart extends StatefulWidget {
  const OrderQuantityChart({Key? key}) : super(key: key);

  @override
  State<OrderQuantityChart> createState() => _OrderQuantityChartState();
}

class _OrderQuantityChartState extends State<OrderQuantityChart> {
  TimePeriod selectedPeriod = TimePeriod.day;
  bool isLoading = false;
  bool isDownloading = false;
  int? selectedIndex;
  int? selectedLineIndex;
  final Map<String, bool> _lineVisibility = {};
  List<OrderData> orderData = [];

  @override
  void initState() {
    super.initState();
    loadOrderData();
  }

  // Simulate data loading
  Future<void> loadOrderData() async {
    setState(() {
      isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      orderData = _getDataForPeriod(selectedPeriod);
      // Initialize line visibility
      for (var data in orderData) {
        _lineVisibility.putIfAbsent(data.label, () => true);
      }
      isLoading = false;
    });
  }

  List<OrderData> _getDataForPeriod(TimePeriod period) {
    // Mock data for different time periods
    switch (period) {
      case TimePeriod.day:
        return [
          OrderData(
            label: _OrderQuantityStrings.pending,
            data: [5, 15, 35, 25, 40, 30, 45, 35, 30, 35, 40, 35],
            color: const Color(0xFF3935E7),
          ),
          OrderData(
            label: _OrderQuantityStrings.paid,
            data: [10, 25, 40, 35, 30, 45, 25, 40, 45, 20, 30, 45],
            color: const Color(0xFF00E676),
          ),
          OrderData(
            label: _OrderQuantityStrings.cancelled,
            data: [20, 30, 50, 40, 35, 25, 30, 35, 25, 40, 35, 30],
            color: const Color(0xFFFF9800),
          ),
        ];
      case TimePeriod.week:
        return [
          OrderData(
            label: _OrderQuantityStrings.pending,
            data: [25, 45, 65, 55, 70, 60, 75, 65, 60, 65, 70, 65],
            color: const Color(0xFF3935E7),
          ),
          OrderData(
            label: _OrderQuantityStrings.paid,
            data: [30, 55, 70, 65, 60, 75, 55, 70, 75, 50, 60, 75],
            color: const Color(0xFF00E676),
          ),
          OrderData(
            label: _OrderQuantityStrings.cancelled,
            data: [40, 60, 80, 70, 65, 55, 60, 65, 55, 70, 65, 60],
            color: const Color(0xFFFF9800),
          ),
        ];
      case TimePeriod.month:
        return [
          OrderData(
            label: _OrderQuantityStrings.pending,
            data: [100, 180, 260, 220, 280, 240, 300, 260, 240, 260, 280, 260],
            color: const Color(0xFF3935E7),
          ),
          OrderData(
            label: _OrderQuantityStrings.paid,
            data: [120, 220, 280, 260, 240, 300, 220, 280, 300, 200, 240, 300],
            color: const Color(0xFF00E676),
          ),
          OrderData(
            label: _OrderQuantityStrings.cancelled,
            data: [160, 240, 320, 280, 260, 220, 240, 260, 220, 280, 260, 240],
            color: const Color(0xFFFF9800),
          ),
        ];
      case TimePeriod.year:
        return [
          OrderData(
            label: _OrderQuantityStrings.pending,
            data: [1200, 2160, 3120, 2640, 3360, 2880, 3600, 3120, 2880, 3120, 3360, 3120],
            color: const Color(0xFF3935E7),
          ),
          OrderData(
            label: _OrderQuantityStrings.paid,
            data: [1440, 2640, 3360, 3120, 2880, 3600, 2640, 3360, 3600, 2400, 2880, 3600],
            color: const Color(0xFF00E676),
          ),
          OrderData(
            label: _OrderQuantityStrings.cancelled,
            data: [1920, 2880, 3840, 3360, 3120, 2640, 2880, 3120, 2640, 3360, 3120, 2880],
            color: const Color(0xFFFF9800),
          ),
        ];
    }
  }

  bool _isAllZeros(List<OrderData> data) {
    return data.every((orderData) => orderData.data.every((value) => value == 0));
  }

  void onPeriodChanged(TimePeriod period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
        selectedIndex = null;
        selectedLineIndex = null;
      });
      loadOrderData();
    }
  }

  String getPeriodText(BuildContext context, TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return _OrderQuantityStrings.day;
      case TimePeriod.week:
        return _OrderQuantityStrings.week;
      case TimePeriod.month:
        return _OrderQuantityStrings.month;
      case TimePeriod.year:
        return _OrderQuantityStrings.year;
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

  LineChartData _buildEmptyChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 10,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 50,
      lineBarsData: [
        LineChartBarData(
          spots: [const FlSpot(0, 0), const FlSpot(11, 0)],
          color: Colors.grey.withOpacity(0.1),
          barWidth: 3,
          isCurved: false,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List<OrderData> chartData) {
    List<LineChartBarData> lineBars = chartData.asMap().entries.map((entry) {
      int lineIndex = entry.key;
      OrderData data = entry.value;

      if (!(_lineVisibility[data.label] ?? true)) {
        return LineChartBarData(spots: [], show: false, dotData: const FlDotData(show: false));
      }

      List<FlSpot> spots = data.data.asMap().entries.map((entry) {
        double x = entry.key.toDouble();
        double y = entry.value < 0 ? 0 : entry.value.toDouble();
        return FlSpot(x, y);
      }).toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: data.color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            bool isSelected = lineIndex == selectedLineIndex && index == selectedIndex;
            return FlDotCirclePainter(
              radius: isSelected ? 6 : 4,
              color: isSelected ? Colors.black87 : data.color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    double maxY = chartData.expand((data) => data.data).reduce((a, b) => a > b ? a : b).toDouble();
    double horizontalInterval = maxY / 5;
    if (horizontalInterval == 0) horizontalInterval = 10;

    final months = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];

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
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    months[value.toInt() % 12],
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
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: maxY * 1.1,
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
              if (!(_lineVisibility[lineData.label] ?? true)) return null;

              return LineTooltipItem(
                '${lineData.label}\n',
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

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: orderData.map((data) {
        bool isVisible = _lineVisibility[data.label] ?? true;
        return GestureDetector(
          onTap: () {
            setState(() {
              _lineVisibility[data.label] = !isVisible;
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
                color: data.color.withOpacity(isVisible ? 1.0 : 0.3),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                data.label,
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
                _OrderQuantityStrings.orderQuantity,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              DownloadPopupMenu(
                onDownload: _handleDownload,
                loading: isDownloading,
                formats: const [
                  DownloadFormat.png,
                  DownloadFormat.svg,
                  DownloadFormat.csv,
                ],
              ),
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

          const SizedBox(height: 16),

          // Legend
          _buildLegend(),

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
                : orderData.isEmpty
                    ? Stack(
                        children: [
                          LineChart(_buildEmptyChartData()),
                          Center(
                            child: Text(
                              _OrderQuantityStrings.noDataToDisplay,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: "Gilroy",
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _isAllZeros(orderData)
                        ? Stack(
                            children: [
                              LineChart(_buildEmptyChartData()),
                              Center(
                                child: Text(
                                  _OrderQuantityStrings.noDataToDisplay,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: "Gilroy",
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 16, top: 16),
                            child: LineChart(_buildChartData(orderData)),
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
