import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/online_store_orders_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class OrdersChart extends StatefulWidget {
  const OrdersChart({Key? key}) : super(key: key);

  @override
  State<OrdersChart> createState() => _OrdersChartState();
}

class _OrdersChartState extends State<OrdersChart> {
  bool _isLoading = true;
  String? _error;
  OnlineStoreOrdersResponse? _data;

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
        _error = 'Ошибка: $e';
        _isLoading = false;
      });
    }
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
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Заказы интернет-магазина',
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0F172A),
                    fontFamily: 'Golos',
                  ),
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff14B8A6),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Color(0xffEF4444)),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 14,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : (_data == null || _data!.chartData.isEmpty)
                        ? const Center(
                            child: Text(
                              'Нет данных',
                              style: TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 14,
                                fontFamily: 'Golos',
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(
                                right: 20, left: 10, bottom: 20),
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _maxOrders <= 0 ? 1 : _maxOrders + 2,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => Colors.white,
                                    tooltipBorder:
                                        const BorderSide(color: Color(0xffE2E8F0)),
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
                                        final points = _data!.chartData;
                                        if (index >= 0 && index < points.length) {
                                          final month = points[index].month;
                                          final label = month >= 0 &&
                                                  month < _monthNames.length
                                              ? _monthNames[month]
                                              : month.toString();
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                color: Color(0xff64748B),
                                                fontSize: 12,
                                                fontFamily: 'Golos',
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
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
                                          style: const TextStyle(
                                            color: Color(0xff64748B),
                                            fontSize: 12,
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
                                  horizontalInterval: _maxOrders <= 0
                                      ? 1
                                      : (_maxOrders / 5).ceilToDouble(),
                                  getDrawingHorizontalLine: (value) {
                                    return const FlLine(
                                      color: Color(0xffE2E8F0),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _data!.chartData
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final p = entry.value;
                                  return _makeGroupData(
                                    entry.key,
                                    p.totalOrders.toDouble(),
                                    p.successfulOrders.toDouble(),
                                  );
                                }).toList(),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Всего заказов',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_data?.totalOrders ?? 0}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Успешных',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_data?.successfulOrders ?? 0}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff10B981),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Средний чек',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_data?.averageCheck.toStringAsFixed(1) ?? '0'}',
                        style: const TextStyle(
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

  BarChartGroupData _makeGroupData(int x, double total, double success) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: total,
          gradient: const LinearGradient(
            colors: [Color(0xff94A3B8), Color(0xff64748B)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
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
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
