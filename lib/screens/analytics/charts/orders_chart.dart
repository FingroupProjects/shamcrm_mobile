import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/online_store_orders_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/details/online_store_orders_details_screen.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class OrdersChart extends StatefulWidget {
  const OrdersChart({super.key, required this.title});

  final String title;

  @override
  State<OrdersChart> createState() => _OrdersChartState();
}

class _OrdersChartState extends State<OrdersChart> {
  bool _isLoading = true;
  String? _error;
  OnlineStoreOrdersResponse? _data;

  String get _title => widget.title;

  static final List<OrdersChartPoint> _previewPoints = [
    OrdersChartPoint(
        month: 1, totalOrders: 120, successfulOrders: 92, canceledOrders: 28),
    OrdersChartPoint(
        month: 2, totalOrders: 135, successfulOrders: 104, canceledOrders: 31),
    OrdersChartPoint(
        month: 3, totalOrders: 148, successfulOrders: 121, canceledOrders: 27),
    OrdersChartPoint(
        month: 4, totalOrders: 162, successfulOrders: 129, canceledOrders: 33),
    OrdersChartPoint(
        month: 5, totalOrders: 175, successfulOrders: 143, canceledOrders: 32),
    OrdersChartPoint(
        month: 6, totalOrders: 190, successfulOrders: 156, canceledOrders: 34),
  ];

  List<OrdersChartPoint> _normalizePointsToYear(List<OrdersChartPoint> source) {
    final byMonth = <int, OrdersChartPoint>{};
    for (final point in source) {
      if (point.month >= 1 && point.month <= 12) {
        byMonth[point.month] = point;
      }
    }

    return List.generate(12, (index) {
      final month = index + 1;
      final point = byMonth[month];
      if (point != null) return point;
      return OrdersChartPoint(
        month: month,
        totalOrders: 0,
        successfulOrders: 0,
        canceledOrders: 0,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final chartId = AnalyticsChartRequestPolicy.chartIdForState(this);
    AnalyticsChartRequestPolicy.cancelPendingRetry(chartId);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getOnlineStoreOrdersChartV2();

      AnalyticsChartRequestPolicy.reset(chartId);
      if (!mounted) return;
      setState(() {
        _data = response;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      await AnalyticsChartRequestPolicy.handleLoadError(
        state: this,
        setStateCallback: setState,
        chartId: chartId,
        error: e,
        stackTrace: stackTrace,
        onFatalError: () {
          _error = AnalyticsChartRequestPolicy.userFacingMessage(e);
          _isLoading = false;
        },
        retry: _loadData,
      );
    }
  }

  void _showDetails() {
    OnlineStoreOrdersDetailsScreen.open(context, title: _title);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final points = _data?.chartData ?? [];
    final isEmpty = points.isEmpty || (_data?.totalOrders ?? 0) == 0;
    final displayPoints =
        _normalizePointsToYear(isEmpty ? _previewPoints : points);
    final maxOrders = displayPoints.isEmpty
        ? 0.0
        : displayPoints
            .map((p) => p.totalOrders.toDouble())
            .reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                  width: ResponsiveHelper(context).iconSize,
                  height: ResponsiveHelper(context).iconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff14B8A6), Color(0xff0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff14B8A6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: colors.textInverse,
                    size: ResponsiveHelper(context).smallIconSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Expanded(
                  child: Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showDetails,
                  icon: Icon(Icons.crop_free,
                      color: colors.iconSecondary,
                      size: ResponsiveHelper(context).smallIconSize),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceElevated,
                    minimumSize: Size(36, 36),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: colors.error),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            Text(
                              analyticsText(
                                context,
                                _error!,
                                fallback: _error!,
                              ),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: responsive.bodyFontSize,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            TextButton(
                              onPressed: _loadData,
                              child: Text(
                                analyticsText(
                                  context,
                                  'retry',
                                  fallback: 'Retry',
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: GestureDetector(
                          onTap: _showDetails,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 20, left: 10, bottom: 20),
                            child: LayoutBuilder(
                              builder: (context, chartConstraints) {
                                final groupCount = displayPoints.length;
                                final groupWidth = groupCount > 0
                                    ? chartConstraints.maxWidth / groupCount
                                    : chartConstraints.maxWidth;
                                final rodWidth =
                                    (groupWidth * 0.22).clamp(4.0, 10.0);
                                final barsSpace =
                                    (groupWidth * 0.10).clamp(2.0, 4.0);

                                return BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxOrders <= 0 ? 1 : maxOrders + 2,
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) =>
                                            colors.surfacePrimary,
                                        tooltipBorder: BorderSide(
                                          color: colors.borderSubtle,
                                        ),
                                        tooltipRoundedRadius: 8,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                          if (rodIndex != 0) return null;
                                          final index = group.x.toInt();
                                          if (index < 0 ||
                                              index >= displayPoints.length) {
                                            return null;
                                          }
                                          final item = displayPoints[index];
                                          final monthLabel =
                                              analyticsMonthShort(
                                            context,
                                            item.month,
                                          );
                                          return BarTooltipItem(
                                            '$monthLabel\n',
                                            TextStyle(
                                              color: colors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  responsive.smallFontSize,
                                              fontFamily: 'Golos',
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${analyticsText(context, 'analytics_total_orders', fallback: 'Total orders')}: ${item.totalOrders}\n',
                                                style: TextStyle(
                                                  color: colors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      responsive.smallFontSize,
                                                  fontFamily: 'Golos',
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${analyticsText(context, 'successful', fallback: 'Successful')}: ${item.successfulOrders}\n',
                                                style: TextStyle(
                                                  color: colors.info,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      responsive.smallFontSize,
                                                  fontFamily: 'Golos',
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${analyticsText(context, 'cancelled', fallback: 'Cancelled')}: ${item.canceledOrders}',
                                                style: TextStyle(
                                                  color: colors.error,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      responsive.smallFontSize,
                                                  fontFamily: 'Golos',
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
                                          reservedSize: 36,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 &&
                                                index < displayPoints.length) {
                                              final month =
                                                  displayPoints[index].month;
                                              final label = analyticsMonthShort(
                                                context,
                                                month,
                                              );
                                              return RotatedBox(
                                                quarterTurns: 3,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 8,
                                                  ),
                                                  child: Text(
                                                    label,
                                                    style: TextStyle(
                                                      color:
                                                          colors.textSecondary,
                                                      fontSize: responsive
                                                          .smallFontSize,
                                                      fontFamily: 'Golos',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            return Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        axisNameWidget: Text(
                                          analyticsText(
                                            context,
                                            'quantity',
                                            fallback: 'Quantity',
                                          ),
                                          style: TextStyle(
                                            fontSize: responsive.smallFontSize,
                                            color: colors.textMuted,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                        axisNameSize: 16,
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: TextStyle(
                                                color: colors.textSecondary,
                                                fontSize:
                                                    responsive.smallFontSize,
                                                fontFamily: 'Golos',
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: maxOrders <= 0
                                          ? 1
                                          : (maxOrders / 5).ceilToDouble(),
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: colors.borderSubtle,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: displayPoints
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final p = entry.value;
                                      return _makeGroupData(
                                        entry.key,
                                        p.totalOrders.toDouble(),
                                        p.successfulOrders.toDouble(),
                                        rodWidth: rodWidth.toDouble(),
                                        barsSpace: barsSpace.toDouble(),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
          ),
          // Footer
          if (!_isLoading && _error == null)
            Container(
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final successRate = _data?.successRate ?? 0;
                  final successText =
                      '${_data?.successfulOrders ?? 0} (${successRate.toStringAsFixed(successRate % 1 == 0 ? 0 : 1)}%)';

                  return Row(
                    children: [
                      Expanded(
                        child: _buildFooterStat(
                          label: analyticsText(
                            context,
                            'analytics_total_orders',
                            fallback: 'Total orders',
                          ),
                          value: '${_data?.totalOrders ?? 0}',
                          valueColor: colors.textPrimary,
                          alignment: CrossAxisAlignment.start,
                          responsive: responsive,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFooterStat(
                          label: analyticsText(
                            context,
                            'analytics_successful_orders',
                            fallback: 'Successful',
                          ),
                          value: successText,
                          valueColor: colors.success,
                          alignment: CrossAxisAlignment.center,
                          responsive: responsive,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFooterStat(
                          label: analyticsText(
                            context,
                            'analytics_average_check',
                            fallback: 'Average check',
                          ),
                          value: _data?.averageCheck.toStringAsFixed(1) ?? '0',
                          valueColor: colors.textPrimary,
                          alignment: CrossAxisAlignment.center,
                          responsive: responsive,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFooterStat(
                          label: analyticsText(
                            context,
                            'analytics_revenue',
                            fallback: 'Revenue',
                          ),
                          value: _data?.revenue.toStringAsFixed(0) ?? '0',
                          valueColor: colors.textPrimary,
                          alignment: CrossAxisAlignment.end,
                          responsive: responsive,
                          isCompact: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterStat({
    required String label,
    required String value,
    required Color valueColor,
    required CrossAxisAlignment alignment,
    required ResponsiveHelper responsive,
    bool isCompact = false,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isCompact
                ? (responsive.smallFontSize - 1).clamp(9, 14).toDouble()
                : responsive.smallFontSize,
            color: context.appColors.textSecondary,
            fontFamily: 'Golos',
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment == CrossAxisAlignment.end
              ? Alignment.centerRight
              : alignment == CrossAxisAlignment.center
                  ? Alignment.center
                  : Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: isCompact
                  ? (responsive.largeFontSize - 2).clamp(11, 22).toDouble()
                  : responsive.largeFontSize,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFamily: 'Golos',
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeGroupData(
    int x,
    double total,
    double success, {
    required double rodWidth,
    required double barsSpace,
  }) {
    return BarChartGroupData(
      x: x,
      barsSpace: barsSpace,
      barRods: [
        BarChartRodData(
          toY: total,
          gradient: const LinearGradient(
            colors: [Color(0xff94A3B8), Color(0xff64748B)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: rodWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: success,
          gradient: const LinearGradient(
            colors: [Color(0xff14B8A6), Color(0xff0D9488)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: rodWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
