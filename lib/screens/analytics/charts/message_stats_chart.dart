import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/message_stats_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class MessageStatsChart extends StatefulWidget {
  const MessageStatsChart({super.key});

  @override
  State<MessageStatsChart> createState() => _MessageStatsChartState();
}

class _MessageStatsChartState extends State<MessageStatsChart> {
  bool _isLoading = true;
  String? _error;
  MessageStatsResponse? _data;

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
      final response = await apiService.getMessageStats();

      AnalyticsChartRequestPolicy.reset(chartId, readyState: this);
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
    final items = _data?.stats ?? [];
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
                      analyticsText(
                        context,
                        'analytics_chart_message_stats',
                        fallback: 'Message statistics',
                      ),
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
                    icon: Icon(Icons.refresh,
                        color: context.appColors.iconSecondary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close,
                        color: context.appColors.iconSecondary),
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
                        item.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        '${analyticsText(context, 'analytics_received', fallback: 'Received')}: ${item.received}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: context.appColors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${analyticsText(context, 'analytics_answered', fallback: 'Answered')}: ${item.sent}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.success,
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

  List<BarChartGroupData> _buildGroups(List<MessageStat> items) {
    return List.generate(items.length, (index) {
      final item = items[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.received.toDouble(),
            color: const Color(0xff6366F1),
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: item.sent.toDouble(),
            color: const Color(0xff10B981),
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final items = _data?.activeChannels ?? [];
    final maxValue = items.isEmpty
        ? 1
        : items.map((e) => e.total).reduce((a, b) => a > b ? a : b).toDouble();

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
                    Icons.message_outlined,
                    color: context.appColors.textInverse,
                    size: ResponsiveHelper(context).smallIconSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Expanded(
                  child: Text(
                    analyticsText(
                      context,
                      'analytics_chart_message_stats',
                      fallback: 'Message statistics',
                    ),
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
                          _error!,
                          style: const TextStyle(
                            color: Color(0xffEF4444),
                            fontFamily: 'Golos',
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: BarChart(
                          BarChartData(
                            maxY: maxValue * 1.2,
                            barGroups: _buildGroups(items),
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
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: responsive.xSmallFontSize,
                                        color: Color(0xff64748B),
                                        fontFamily: 'Golos',
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= items.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        items[index].name,
                                        style: TextStyle(
                                          fontSize: responsive.xSmallFontSize,
                                          color: Color(0xff64748B),
                                          fontFamily: 'Golos',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                          ),
                        ),
                      ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive.cardPadding,
              0,
              responsive.cardPadding,
              responsive.cardPadding,
            ),
            child: Row(
              children: [
                _LegendDot(
                  color: Color(0xff6366F1),
                  label: analyticsText(
                    context,
                    'analytics_received',
                    fallback: 'Received',
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                _LegendDot(
                  color: Color(0xff10B981),
                  label: analyticsText(
                    context,
                    'analytics_answered',
                    fallback: 'Answered',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper(context).smallFontSize,
            color: Color(0xff64748B),
            fontFamily: 'Golos',
          ),
        ),
      ],
    );
  }
}
