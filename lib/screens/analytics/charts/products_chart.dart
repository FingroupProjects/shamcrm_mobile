import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/top_selling_products_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class ProductsChart extends StatefulWidget {
  const ProductsChart({super.key, required this.title});

  final String title;

  @override
  State<ProductsChart> createState() => _ProductsChartState();
}

class _ProductsChartState extends State<ProductsChart> {
  bool _isLoading = true;
  String? _error;
  TopSellingProductsResponse? _data;

  String get _title => widget.title;

  static final List<TopSellingProductItem> _previewItems = [
    TopSellingProductItem(
      goodId: 1,
      name: 'Кольцо 585',
      totalSold: 120,
      successful: 97,
      cancelled: 23,
      conversion: 80.8,
      revenue: 54000000,
      revenueFormatted: '54 000 000 сум',
    ),
    TopSellingProductItem(
      goodId: 2,
      name: 'Серьги "Classic"',
      totalSold: 85,
      successful: 71,
      cancelled: 14,
      conversion: 83.5,
      revenue: 31500000,
      revenueFormatted: '31 500 000 сум',
    ),
    TopSellingProductItem(
      goodId: 3,
      name: 'Цепочка серебро',
      totalSold: 93,
      successful: 81,
      cancelled: 12,
      conversion: 87.1,
      revenue: 22400000,
      revenueFormatted: '22 400 000 сум',
    ),
    TopSellingProductItem(
      goodId: 4,
      name: 'Браслет золотой',
      totalSold: 67,
      successful: 58,
      cancelled: 9,
      conversion: 86.6,
      revenue: 28900000,
      revenueFormatted: '28 900 000 сум',
    ),
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
      final response = await apiService.getTopSellingProductsChartV2();

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
    if (_data == null || _data!.list.isEmpty) return;
    final items = _data!.list;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title,
                style: TextStyle(
                  fontSize: ResponsiveHelper(context).bodyFontSize,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                  fontFamily: 'Golos',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        'Продано: ${item.totalSold} • Успешные: ${item.successful}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        item.revenueFormatted.isNotEmpty
                            ? item.revenueFormatted
                            : item.revenue.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffF97316),
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

  List<TopSellingProductItem> get _topItems {
    final list = _data?.list ?? [];
    final sorted = List<TopSellingProductItem>.from(list)
      ..sort((a, b) => b.totalSold.compareTo(a.totalSold));
    return sorted.take(7).toList();
  }

  String _shortName(String name) {
    if (name.length <= 12) return name;
    return '${name.substring(0, 12)}…';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty =
        _topItems.isEmpty || _topItems.every((item) => item.totalSold == 0);
    final displayItems = isEmpty ? _previewItems : _topItems;
    final maxSold = displayItems.isEmpty
        ? 0.0
        : displayItems
            .map((e) => e.totalSold.toDouble())
            .reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                      colors: [Color(0xffF97316), Color(0xffEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffF97316).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _title,
                    maxLines: 2,
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
                  icon: const Icon(Icons.crop_free, color: Color(0xff64748B), size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xffF1F5F9),
                    minimumSize: Size(44, 44),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: 400,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Color(0xffEF4444)),
                            SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Color(0xff64748B),
                                fontSize: responsive.bodyFontSize,
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
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: GestureDetector(
                          onTap: _showDetails,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 20, left: 10, bottom: 20),
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxSold <= 0 ? 1 : maxSold + 5,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (group) => Colors.white,
                                      tooltipBorder: const BorderSide(
                                          color: Color(0xffE2E8F0)),
                                      tooltipRoundedRadius: 10,
                                      tooltipPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      tooltipMargin: 10,
                                      fitInsideHorizontally: true,
                                      fitInsideVertically: true,
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                        final item =
                                            displayItems[group.x.toInt()];
                                        return BarTooltipItem(
                                          '${item.name}\n${rod.toY.toInt()} шт',
                                          TextStyle(
                                            color: Color(0xff0F172A),
                                            fontWeight: FontWeight.w700,
                                            fontSize: responsive.smallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 120,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < displayItems.length) {
                                            return RotatedBox(
                                              quarterTurns: 3,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                  _shortName(
                                                      displayItems[index].name),
                                                  style: TextStyle(
                                                    color: Color(0xff64748B),
                                                    fontSize: responsive.xSmallFontSize,
                                                    fontFamily: 'Golos',
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 36,
                                        getTitlesWidget: (value, meta) {
                                          return RotatedBox(
                                            quarterTurns: 3,
                                            child: Padding(
                                              padding: EdgeInsets.zero,
                                              child: Text(
                                                value.toInt().toString(),
                                                style: TextStyle(
                                                  color: Color(0xff64748B),
                                                  fontSize: responsive.smallFontSize,
                                                  fontFamily: 'Golos',
                                                ),
                                              ),
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
                                    horizontalInterval: maxSold <= 0
                                        ? 1
                                        : (maxSold / 5).ceilToDouble(),
                                    getDrawingHorizontalLine: (value) {
                                      return const FlLine(
                                        color: Color(0xffE2E8F0),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: displayItems
                                      .asMap()
                                      .entries
                                      .map((entry) => _makeGroupData(
                                          entry.key,
                                          entry.value.totalSold.toDouble()))
                                      .toList(),
                                ),
                              ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Топ товар',
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _data?.top.name.isNotEmpty == true
                            ? _data!.top.name
                            : (_topItems.isNotEmpty ? _topItems.first.name : '-'),
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Всего продано',
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_topItems.isNotEmpty ? _topItems.fold<int>(0, (sum, item) => sum + item.totalSold) : 0} шт',
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
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

  BarChartGroupData _makeGroupData(int x, double value) {
    final colors = [
      [const Color(0xffF97316), const Color(0xffEA580C)],
      [const Color(0xff6366F1), const Color(0xff4F46E5)],
      [const Color(0xff10B981), const Color(0xff059669)],
      [const Color(0xffEC4899), const Color(0xffDB2777)],
      [const Color(0xff8B5CF6), const Color(0xff7C3AED)],
      [const Color(0xff06B6D4), const Color(0xff0891B2)],
      [const Color(0xffF59E0B), const Color(0xffD97706)],
    ];

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          gradient: LinearGradient(
            colors: colors[x % colors.length],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}
