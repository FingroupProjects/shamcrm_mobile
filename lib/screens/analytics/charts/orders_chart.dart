import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/online_store_orders_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
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

  static const List<String> _monthNames = [
    '',
    'Янв',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Июн',
    'Июл',
    'Авг',
    'Сен',
    'Окт',
    'Ноя',
    'Дек',
  ];

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getOnlineStoreOrdersChartV2();

      setState(() {
        _data = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  void _showDetails() {
    if (_data == null || _data!.chartData.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: TextStyle(
                        fontSize: ResponsiveHelper(context).titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A),
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Color(0xff64748B)),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper(context).smallSpacing),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _data!.chartData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final point = _data!.chartData[index];
                    final month =
                        point.month >= 0 && point.month < _monthNames.length
                            ? _monthNames[point.month]
                            : point.month.toString();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        month,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        'Успешные: ${point.successfulOrders} • Отменённые: ${point.canceledOrders}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${point.totalOrders}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff14B8A6),
                          fontFamily: 'Golos',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double get _maxOrders {
    final list = _data?.chartData ?? [];
    if (list.isEmpty) return 0;
    return list
        .map((e) => e.totalOrders.toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
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
                  width: ResponsiveHelper(context).iconSize,
                  height: ResponsiveHelper(context).iconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff14B8A6), Color(0xff0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff14B8A6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
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
                      color: const Color(0xff0F172A),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showDetails,
                  icon: Icon(Icons.crop_free,
                      color: Color(0xff64748B),
                      size: ResponsiveHelper(context).smallIconSize),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xffF1F5F9),
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
                                size: 48, color: Color(0xffEF4444)),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Color(0xff64748B),
                                fontSize: responsive.bodyFontSize,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Повторить'),
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
                                        getTooltipColor: (group) => Colors.white,
                                        tooltipBorder: const BorderSide(
                                            color: Color(0xffE2E8F0)),
                                        tooltipRoundedRadius: 8,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 &&
                                                index < displayPoints.length) {
                                              final month =
                                                  displayPoints[index].month;
                                              final label = month >= 0 &&
                                                      month < _monthNames.length
                                                  ? _monthNames[month]
                                                  : month.toString();
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: Color(0xff64748B),
                                                    fontSize:
                                                        responsive.smallFontSize,
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
                                              style: TextStyle(
                                                color: Color(0xff64748B),
                                                fontSize: responsive.smallFontSize,
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
                                      horizontalInterval: maxOrders <= 0
                                          ? 1
                                          : (maxOrders / 5).ceilToDouble(),
                                      getDrawingHorizontalLine: (value) {
                                        return const FlLine(
                                          color: Color(0xffE2E8F0),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups:
                                        displayPoints.asMap().entries.map((entry) {
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
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xffE2E8F0)),
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
                          label: 'Всего заказов',
                          value: '${_data?.totalOrders ?? 0}',
                          valueColor: const Color(0xff0F172A),
                          alignment: CrossAxisAlignment.start,
                          responsive: responsive,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFooterStat(
                          label: 'Успешных',
                          value: successText,
                          valueColor: const Color(0xff10B981),
                          alignment: CrossAxisAlignment.center,
                          responsive: responsive,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFooterStat(
                          label: 'Средний чек',
                          value: _data?.averageCheck.toStringAsFixed(1) ?? '0',
                          valueColor: const Color(0xff0F172A),
                          alignment: CrossAxisAlignment.center,
                          responsive: responsive,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFooterStat(
                          label: 'Выручка',
                          value: _data?.revenue.toStringAsFixed(0) ?? '0',
                          valueColor: const Color(0xff0F172A),
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
            color: const Color(0xff64748B),
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
