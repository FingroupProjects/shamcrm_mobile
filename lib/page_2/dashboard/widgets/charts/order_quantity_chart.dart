import 'package:crm_task_manager/models/page_2/dashboard/order_dashboard_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'chart_scale.dart';
import 'example_chart_frame.dart';

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
  OrderTimePeriod selectedPeriod = OrderTimePeriod.year;

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

      // Вызываем перезагрузку данных через Bloc
      context.read<SalesDashboardBloc>().add(ReloadOrderQuantityData(period));
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
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonPrimaryBg
              : colors.surfaceElevated.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          getPeriodText(context, period),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? colors.textInverse : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  // void _handleDownload(DownloadFormat format) async {
  //   setState(() {
  //     isDownloading = true;
  //   });
  //
  //   try {
  //     await Future.delayed(const Duration(seconds: 2));
  //   } catch (e) {
  //     // Handle error silently
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         isDownloading = false;
  //       });
  //     }
  //   }
  // }

  List<OrderChartData> _exampleOrders() {
    const first = <int>[4, 6, 5, 8, 7, 10, 9, 8, 12, 11, 14, 13];
    const second = <int>[2, 3, 4, 3, 5, 6, 5, 7, 6, 8, 7, 9];
    List<DataPoint> points(List<int> amounts) {
      return List.generate(
        amounts.length,
        (index) => DataPoint(
          id: index,
          label: '${index + 1}',
          amount: amounts[index],
        ),
      );
    }

    return [
      OrderChartData(name: 'Новая заявка', data: points(first)),
      OrderChartData(name: 'Реализован', data: points(second)),
    ];
  }

  LineChartData _buildChartData(
    List<OrderChartData> chartData, {
    bool interactive = true,
  }) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context)!;
    var pointCount = 0;
    final amounts = <double>[];
    for (final data in chartData) {
      if (data.data.length > pointCount) pointCount = data.data.length;
      for (final point in data.data) {
        amounts.add(point.amount < 0 ? 0 : point.amount.toDouble());
      }
    }
    // Один день не должен растягиваться на весь год.
    final maxX = pointCount <= 1 ? 0.5 : (pointCount - 1).toDouble();
    final minX = pointCount <= 1 ? -0.5 : 0.0;
    final scale = ChartScale.fromValues(amounts);

    List<LineChartBarData> lineBars = chartData.asMap().entries.map((entry) {
      int lineIndex = entry.key;
      OrderChartData data = entry.value;

      if (!(_lineVisibility[data.name] ?? true)) {
        return LineChartBarData(
            spots: [], show: false, dotData: const FlDotData(show: false));
      }

      List<FlSpot> spots = data.data.asMap().entries.map((entry) {
        double x = entry.key.toDouble();
        double y = entry.value.amount < 0 ? 0 : entry.value.amount.toDouble();
        return FlSpot(x, y);
      }).toList();

      Color lineColor = _getColorForIndex(lineIndex);

      return LineChartBarData(
        spots: spots,
        isCurved: false,
        color: lineColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            bool isSelected =
                lineIndex == selectedLineIndex && index == selectedIndex;
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

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: scale.interval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: colors.borderSubtle.withValues(alpha: 0.38),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: scale.interval,
            reservedSize: 48,
            getTitlesWidget: (value, meta) {
              return chartValueLabel(
                formatChartAxis(value, localizations),
                colors.textSecondary,
                meta,
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (chartData.isEmpty ||
                  index < 0 ||
                  index >= chartData.first.data.length ||
                  (value - index).abs() > 0.01) {
                return const SizedBox.shrink();
              }
              return chartAxisLabel(
                localizedShortMonth(
                  chartData.first.data[index].label,
                  localizations,
                ),
                colors.textSecondary,
                meta,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: minX,
      maxX: maxX,
      minY: scale.minY,
      maxY: scale.maxY,
      lineBarsData: lineBars,
      lineTouchData: LineTouchData(
        enabled: interactive,
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
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                color: lineColor.withValues(alpha: isVisible ? 1.0 : 0.3),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                data.name,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary
                      .withValues(alpha: isVisible ? 1.0 : 0.3),
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
    final hasValues = chartData.any(
      (line) => line.data.any((point) => point.amount != 0),
    );
    final showExample = !hasValues;
    final display = showExample ? _exampleOrders() : chartData;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('order_quantity'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              // Transform.translate(
              //   offset: const Offset(16, 0),
              //   child: DownloadPopupMenu(
              //     onDownload: _handleDownload,
              //     loading: isDownloading,
              //     formats: const [
              //       DownloadFormat.png,
              //       DownloadFormat.svg,
              //       DownloadFormat.csv,
              //     ],
              //   ),
              // ),
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
          if (display.isNotEmpty) _buildLegend(display),

          const SizedBox(height: 24),

          // Chart content
          SizedBox(
            height: 300,
            child: ExampleChartFrame(
              show: showExample,
              label: localizations.translate('no_data_to_display'),
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 16),
                  child: LineChart(
                    _buildChartData(display, interactive: !showExample),
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
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        DetailedReportScreen(currentTabIndex: 10)));
              },
              child: Text(
                localizations.translate('more_details'),
                style: textStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.buttonPrimaryBg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
