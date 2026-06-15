import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
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
        statusName: 'Unknown',
        totalLeads: 214,
        conversionFromPrevious: 214,
        conversionRate: '100%'),
    StatusConversion(
        statusName: 'Missed call',
        totalLeads: 65,
        conversionFromPrevious: 65,
        conversionRate: '30%'),
    StatusConversion(
        statusName: 'In progress',
        totalLeads: 93,
        conversionFromPrevious: 93,
        conversionRate: '43%'),
    StatusConversion(
        statusName: 'Cold lead',
        totalLeads: 138,
        conversionFromPrevious: 138,
        conversionRate: '64%'),
    StatusConversion(
        statusName: 'Client',
        totalLeads: 59,
        conversionFromPrevious: 59,
        conversionRate: '28%'),
  ];

  String _localizedStatusName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'неизвестный':
      case 'unknown':
        return analyticsText(
          context,
          'analytics_status_unknown',
          fallback: 'Unknown',
        );
      case 'звонок без ответа':
      case 'missed call':
        return analyticsText(
          context,
          'analytics_status_missed_call',
          fallback: 'Missed call',
        );
      case 'в работе':
      case 'in progress':
        return analyticsText(context, 'in_progress', fallback: 'In progress');
      case 'холодное обращение':
      case 'cold lead':
        return analyticsText(
          context,
          'analytics_status_cold_lead',
          fallback: 'Cold lead',
        );
      case 'клиент':
      case 'client':
        return analyticsText(
          context,
          'analytics_status_client',
          fallback: 'Client',
        );
      default:
        return name;
    }
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
      final response = await apiService.getLeadConversionByStatuses();

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
    final items = _data?.statuses ?? [];
    if (items.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
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
                        color: context.appColors.textPrimary,
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadData();
                    },
                    icon: Icon(Icons.refresh, color: context.appColors.iconSecondary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: context.appColors.iconSecondary),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper(context).smallSpacing),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: context.appColors.borderSubtle),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _localizedStatusName(item.statusName),
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        '${analyticsText(context, 'leads', fallback: 'Leads')}: ${item.totalLeads}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: context.appColors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        item.conversionRate,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.info,
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
        color: context.appColors.surfacePrimary,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: context.appColors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: ResponsiveHelper(context).iconSize,
                  height: ResponsiveHelper(context).iconSize,
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
                  child: Icon(
                    Icons.trending_up,
                    color: context.appColors.textInverse,
                    size: ResponsiveHelper(context).smallIconSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showDetails,
                  icon: Icon(Icons.crop_free,
                      color: context.appColors.iconSecondary,
                      size: ResponsiveHelper(context).smallIconSize),
                  style: IconButton.styleFrom(
                    backgroundColor: context.appColors.backgroundSecondary,
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
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Text(
                          analyticsText(
                            context,
                            _error!,
                            fallback: _error!,
                          ),
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
                                    axisNameWidget: Text(
                                      analyticsText(
                                        context,
                                        'quantity',
                                        fallback: 'Quantity',
                                      ),
                                      style: TextStyle(
                                        fontSize: responsive.xSmallFontSize,
                                        color: Color(0xff94A3B8),
                                        fontFamily: 'Golos',
                                      ),
                                    ),
                                    axisNameSize: 16,
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
                                              fontSize:
                                                  responsive.xSmallFontSize,
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
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              _localizedStatusName(
                                                displayItems[index].statusName,
                                              ),
                                              style: TextStyle(
                                                fontSize:
                                                    responsive.xSmallFontSize,
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
                                    getTooltipColor: (_) =>
                                        context.appColors.surfacePrimary,
                                    tooltipBorder: BorderSide(
                                      color: context.appColors.borderSubtle,
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
                                        '${_localizedStatusName(item.statusName)}\n${item.totalLeads} (${item.conversionRate})',
                                        TextStyle(
                                          color: context.appColors.textPrimary,
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
                '${analyticsText(context, 'analytics_average_conversion', fallback: 'Average conversion')}: ${_data!.averageConversion}',
                style: TextStyle(
                  fontSize: responsive.smallFontSize,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textSecondary,
                  fontFamily: 'Golos',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
