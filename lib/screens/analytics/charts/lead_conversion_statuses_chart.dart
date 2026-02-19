import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_conversion_by_statuses_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class LeadConversionStatusesChart extends StatefulWidget {
  const LeadConversionStatusesChart({super.key, required this.title});

  final String title;

  @override
  State<LeadConversionStatusesChart> createState() =>
      _LeadConversionStatusesChartState();
}

class _LeadConversionStatusesChartState
    extends State<LeadConversionStatusesChart> {
  bool _isLoading = true;
  String? _error;
  LeadConversionByStatusesResponse? _data;

  String get _title => widget.title;

  static final List<StatusConversion> _previewStatuses = [
    StatusConversion(
        statusName: 'Неизвестный',
        totalLeads: 214,
        conversionFromPrevious: 214,
        conversionRate: '100%'),
    StatusConversion(
        statusName: 'Звонок без ответа',
        totalLeads: 65,
        conversionFromPrevious: 65,
        conversionRate: '30%'),
    StatusConversion(
        statusName: 'В работе',
        totalLeads: 93,
        conversionFromPrevious: 93,
        conversionRate: '43%'),
    StatusConversion(
        statusName: 'Холодное обращение',
        totalLeads: 138,
        conversionFromPrevious: 138,
        conversionRate: '64%'),
    StatusConversion(
        statusName: 'Клиент',
        totalLeads: 59,
        conversionFromPrevious: 59,
        conversionRate: '28%'),
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
      final response = await apiService.getLeadConversionByStatuses();

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
    final items = _data?.statuses ?? [];
    if (items.isEmpty) return;
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadData();
                    },
                    icon: const Icon(Icons.refresh, color: Color(0xff64748B)),
                  ),
                ],
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
                        item.statusName,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        'Лидов: ${item.totalLeads}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        item.conversionRate,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff8B5CF6),
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

  List<BarChartGroupData> _buildGroups(List<StatusConversion> items) {
    return List.generate(items.length, (index) {
      final item = items[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.totalLeads.toDouble(),
            color: const Color(0xff6366F1),
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final items = _data?.statuses ?? [];
    final isEmpty = items.isEmpty || items.every((e) => e.totalLeads == 0);
    final displayItems = isEmpty ? _previewStatuses : items;
    final maxValue = displayItems.isEmpty
        ? 1
        : displayItems.map((e) => e.totalLeads).reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxValue * 1.2;
    final leftInterval = (chartMaxY / 5).ceilToDouble();

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
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff8B5CF6), Color(0xff6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff0F172A),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showDetails,
                  icon: Icon(Icons.crop_free, color: Color(0xff64748B), size: 22),
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
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xffEF4444),
                            fontFamily: 'Golos',
                          ),
                        ),
                      )
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: BarChart(
                              BarChartData(
                                maxY: chartMaxY,
                                barGroups: _buildGroups(displayItems),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: const Color(0xffE2E8F0),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      interval: leftInterval,
                                      maxIncluded: false,
                                      getTitlesWidget: (value, meta) {
                                        return RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              fontSize: responsive.xSmallFontSize,
                                              color: Color(0xff64748B),
                                              fontFamily: 'Golos',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 120,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >= displayItems.length) {
                                          return const SizedBox.shrink();
                                        }
                                        if (displayItems.length > 6 &&
                                            index.isOdd) {
                                          return const SizedBox.shrink();
                                        }
                                        return RotatedBox(
                                          quarterTurns: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              displayItems[index].statusName,
                                              style: TextStyle(
                                                fontSize: responsive.xSmallFontSize,
                                                color: Color(0xff64748B),
                                                fontFamily: 'Golos',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => Colors.white,
                                    tooltipBorder: const BorderSide(
                                      color: Color(0xffE2E8F0),
                                    ),
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
                                        '${item.statusName}\n${item.totalLeads} (${item.conversionRate})',
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
                          ),
                        ),
                      ),
                        ),
                      ),
          ),
          if (_data != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.cardPadding,
                0,
                responsive.cardPadding,
                responsive.cardPadding,
              ),
              child: Text(
                'Средняя конверсия: ${_data!.averageConversion}',
                style: TextStyle(
                  fontSize: responsive.smallFontSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff64748B),
                  fontFamily: 'Golos',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
