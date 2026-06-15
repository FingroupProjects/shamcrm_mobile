import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/advertising_roi_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class AdvertisingRoiChart extends StatefulWidget {
  const AdvertisingRoiChart({super.key, required this.title});
  final String title;

  @override
  State<AdvertisingRoiChart> createState() => _AdvertisingRoiChartState();
}

class _AdvertisingRoiChartState extends State<AdvertisingRoiChart> {
  static const Color _leadsColor = Color(0xff6366F1);
  static const Color _clientsColor = Color(0xff10B981);
  static const Color _coldColor = Color(0xffEF4444);
  static const Color _roiLineColor = Color(0xffF59E0B);
  static const Color _labelColor = Color(0xff64748B);

  bool _isLoading = true;
  String? _error;
  AdvertisingRoiResponse? _data;
  List<AdvertisingRoiCampaign> _campaigns = [];
  bool _showLeads = true;
  bool _showClients = true;
  bool _showCold = true;
  bool _showRoiLine = true;

  String get _title => widget.title;

  static final List<AdvertisingRoiCampaign> _previewCampaigns = [
    AdvertisingRoiCampaign(
      campaignId: 1,
      campaignName: 'WhatsApp 1',
      adType: 'ad',
      source: 'whatsapp',
      integrationId: 1,
      integrationName: 'WhatsApp Ads',
      integrationType: 'whatsapp',
      totalLeads: 14,
      clients: 2,
      cold: 7,
      conversionRate: 14.3,
      spent: 100,
      cpl: 7.14,
      revenue: 500,
      roi: 400,
      profit: 400,
    ),
    AdvertisingRoiCampaign(
      campaignId: 2,
      campaignName: 'WhatsApp 2',
      adType: 'ad',
      source: 'whatsapp',
      integrationId: 1,
      integrationName: 'WhatsApp Ads',
      integrationType: 'whatsapp',
      totalLeads: 13,
      clients: 1,
      cold: 11,
      conversionRate: 7.7,
      spent: 80,
      cpl: 6.15,
      revenue: 200,
      roi: 150,
      profit: 120,
    ),
    AdvertisingRoiCampaign(
      campaignId: 3,
      campaignName: 'Instagram Promo',
      adType: 'OPEN_THREAD',
      source: 'instagram',
      integrationId: 2,
      integrationName: 'Instagram Ads',
      integrationType: 'instagram',
      totalLeads: 17,
      clients: 3,
      cold: 12,
      conversionRate: 17.6,
      spent: 150,
      cpl: 8.82,
      revenue: 800,
      roi: 433.3,
      profit: 650,
    ),
    AdvertisingRoiCampaign(
      campaignId: 4,
      campaignName: 'Facebook Lead',
      adType: 'post',
      source: 'facebook',
      integrationId: 3,
      integrationName: 'Facebook Ads',
      integrationType: 'facebook',
      totalLeads: 9,
      clients: 1,
      cold: 6,
      conversionRate: 11.1,
      spent: 60,
      cpl: 6.67,
      revenue: 300,
      roi: 400,
      profit: 240,
    ),
  ];

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
      final response = await apiService.getAdvertisingRoiChartV2();
      final sorted = List<AdvertisingRoiCampaign>.from(response.campaigns)
        ..sort((a, b) => b.totalLeads.compareTo(a.totalLeads));

      AnalyticsChartRequestPolicy.reset(chartId);
      if (!mounted) return;
      setState(() {
        _data = response;
        _campaigns = sorted.take(8).toList();
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
    if (_campaigns.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final responsive = ResponsiveHelper(ctx);
        final colors = ctx.appColors;
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
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _loadData();
                    },
                    icon: Icon(Icons.refresh, color: colors.iconSecondary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: colors.iconSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _campaigns.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: colors.borderSubtle),
                  itemBuilder: (ctx2, index) {
                    final item = _campaigns[index];
                    final r = ResponsiveHelper(ctx2);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.integrationName,
                        style: TextStyle(
                          fontSize: r.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        '${analyticsText(context, 'leads', fallback: 'Leads')}: ${item.totalLeads}  ${analyticsText(context, 'clients', fallback: 'Clients')}: ${item.clients}  ${analyticsText(context, 'analytics_cold', fallback: 'Cold')}: ${item.cold}',
                        style: TextStyle(
                          fontSize: r.smallFontSize,
                          color: colors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        'ROI ${item.roi.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: r.smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: item.roi >= 0 ? colors.success : colors.error,
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

  // ── helpers ──

  double _barMaxY(List<AdvertisingRoiCampaign> items) {
    if (items.isEmpty) return 6;
    final maxVal = items.map((e) {
      final leads = _showLeads ? e.totalLeads : 0;
      final clients = _showClients ? e.clients : 0;
      final cold = _showCold ? e.cold : 0;
      return [leads, clients, cold].reduce((a, b) => a > b ? a : b);
    }).fold<int>(0, (prev, curr) => math.max(prev, curr));
    return math.max(6, (maxVal * 1.25).ceilToDouble());
  }

  double _roiMaxPercent(List<AdvertisingRoiCampaign> items) {
    if (items.isEmpty) return 1;
    final maxRoi = items
        .map((e) => e.roi.abs())
        .fold<double>(0, (prev, curr) => math.max(prev, curr));
    return math.max(1, (maxRoi * 1.25).ceilToDouble());
  }

  String _shortLabel(String value, int maxLen) {
    if (value.length <= maxLen) return value;
    return '${value.substring(0, maxLen)}…';
  }

  // ── bar groups ──
  List<BarChartGroupData> _buildGroups(
      List<AdvertisingRoiCampaign> items, double barWidth) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final rods = <BarChartRodData>[];
      if (_showLeads) {
        rods.add(BarChartRodData(
          toY: item.totalLeads.toDouble(),
          color: _leadsColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(barWidth / 2),
        ));
      }
      if (_showClients) {
        rods.add(BarChartRodData(
          toY: item.clients.toDouble(),
          color: _clientsColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(barWidth / 2),
        ));
      }
      if (_showCold) {
        rods.add(BarChartRodData(
          toY: item.cold.toDouble(),
          color: _coldColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(barWidth / 2),
        ));
      }
      if (rods.isEmpty) {
        rods.add(BarChartRodData(
          toY: 0.001,
          color: Colors.transparent,
          width: barWidth,
        ));
      }
      return BarChartGroupData(
        x: index,
        barRods: rods,
        barsSpace: math.max(2, barWidth * 0.3),
      );
    });
  }

  // ── ROI % line overlay ──
  List<LineChartBarData> _buildRoiLine(
      List<AdvertisingRoiCampaign> items, double barMaxY) {
    if (!_showRoiLine || items.isEmpty) return [];

    final maxRoi = items
        .map((e) => e.roi.abs())
        .fold<double>(0, (prev, curr) => math.max(prev, curr));
    final roiScale = maxRoi > 0 ? barMaxY / (maxRoi * 1.25) : 1.0;

    final spots = <FlSpot>[];
    for (int i = 0; i < items.length; i++) {
      spots.add(FlSpot(i.toDouble(), items[i].roi * roiScale));
    }

    return [
      LineChartBarData(
        spots: spots,
        color: _roiLineColor,
        isCurved: false,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
            radius: 4,
            color: Colors.white,
            strokeColor: _roiLineColor,
            strokeWidth: 3,
          ),
        ),
        belowBarData: BarAreaData(show: false),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final isCompact = screenW < 380;
        final isVeryCompact = screenW < 340;

        // ── adaptive sizes ──
        final headerIconSize = isVeryCompact ? 30.0 : (isCompact ? 34.0 : 36.0);
        final headerRadius = isVeryCompact ? 8.0 : 10.0;
        final headerPad = isVeryCompact ? 10.0 : (isCompact ? 12.0 : 16.0);
        final titleSize = isVeryCompact ? 14.0 : (isCompact ? 15.0 : 16.0);
        final axisLabelSize = isVeryCompact ? 9.0 : (isCompact ? 10.0 : 11.0);
        final chartHeight = isVeryCompact ? 210.0 : (isCompact ? 240.0 : 280.0);
        final leftReserved = isVeryCompact ? 30.0 : 36.0;
        final rightReserved = isVeryCompact ? 36.0 : 42.0;
        final bottomReserved = isVeryCompact ? 56.0 : (isCompact ? 64.0 : 72.0);
        final labelMaxLen = isVeryCompact ? 8 : (isCompact ? 10 : 12);
        final legendFontSize = isVeryCompact ? 10.0 : (isCompact ? 11.0 : 12.0);
        final statLabelSize = isVeryCompact ? 10.0 : (isCompact ? 11.0 : 12.0);
        final statValueSize = isVeryCompact ? 16.0 : (isCompact ? 18.0 : 20.0);
        final containerRadius = isVeryCompact ? 12.0 : 16.0;

        final isEmpty =
            _campaigns.isEmpty || _campaigns.every((i) => i.totalLeads == 0);
        final displayCampaigns = isEmpty ? _previewCampaigns : _campaigns;
        final maxY = _barMaxY(displayCampaigns);
        final maxRoi = _roiMaxPercent(displayCampaigns);

        // Adaptive bar width based on screen width and number of items
        final activeBarsCount =
            (_showLeads ? 1 : 0) + (_showClients ? 1 : 0) + (_showCold ? 1 : 0);
        final chartAreaWidth =
            screenW - leftReserved - rightReserved - headerPad * 2;
        final groupWidth = chartAreaWidth / displayCampaigns.length;
        final barWidth = math.max(4.0,
            math.min(14.0, (groupWidth * 0.6) / math.max(1, activeBarsCount)));

        return Container(
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(containerRadius),
            border:
                Border.all(color: colors.borderSubtle.withValues(alpha: 0.4)),
            boxShadow: context.appShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: EdgeInsets.all(headerPad),
                child: Row(
                  children: [
                    Container(
                      width: headerIconSize,
                      height: headerIconSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xffF59E0B), Color(0xffD97706)],
                        ),
                        borderRadius: BorderRadius.circular(headerRadius),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xffF59E0B).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: colors.textInverse,
                        size: headerIconSize * 0.55,
                      ),
                    ),
                    SizedBox(width: isCompact ? 8 : 12),
                    Expanded(
                      child: Text(
                        _title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showDetails,
                      icon: Icon(Icons.crop_free,
                          color: colors.iconSecondary,
                          size: isCompact ? 18 : 22),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceElevated,
                        minimumSize:
                            Size(isCompact ? 36 : 44, isCompact ? 36 : 44),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                              Radius.circular(containerRadius)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Axis labels ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: headerPad),
                child: Row(
                  children: [
                    Text(
                      analyticsText(
                        context,
                        'quantity',
                        fallback: 'Quantity',
                      ),
                      style: TextStyle(
                        fontSize: axisLabelSize,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Golos',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ROI %',
                      style: TextStyle(
                        fontSize: axisLabelSize,
                        color: _roiLineColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Golos',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // ── Chart ──
              SizedBox(
                height: chartHeight,
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
                              style: TextStyle(
                                color: colors.error,
                                fontFamily: 'Golos',
                              ),
                            ),
                          )
                        : ChartEmptyOverlay(
                            show: isEmpty,
                            child: Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: headerPad),
                              child: Stack(
                                children: [
                                  // ── Bar chart ──
                                  BarChart(
                                    BarChartData(
                                      maxY: maxY,
                                      alignment: BarChartAlignment.spaceAround,
                                      barGroups: _buildGroups(
                                          displayCampaigns, barWidth),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor: (_) =>
                                              colors.surfacePrimary,
                                          tooltipBorder: BorderSide(
                                            color: colors.borderSubtle,
                                          ),
                                          tooltipRoundedRadius: 10,
                                          tooltipPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          tooltipMargin: 8,
                                          fitInsideHorizontally: true,
                                          fitInsideVertically: true,
                                          getTooltipItem: (group, groupIndex,
                                              rod, rodIndex) {
                                            if (rodIndex != 0) return null;
                                            final item = displayCampaigns[
                                                group.x.toInt()];
                                            return BarTooltipItem(
                                              '${item.integrationName}\n',
                                              TextStyle(
                                                fontSize: axisLabelSize,
                                                fontWeight: FontWeight.w700,
                                                color: colors.textPrimary,
                                                fontFamily: 'Golos',
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '${analyticsText(context, 'leads', fallback: 'Leads')}: ${item.totalLeads}\n',
                                                  style: TextStyle(
                                                    fontSize: axisLabelSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: _leadsColor,
                                                    fontFamily: 'Golos',
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${analyticsText(context, 'clients', fallback: 'Clients')}: ${item.clients}\n',
                                                  style: TextStyle(
                                                    fontSize: axisLabelSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: _clientsColor,
                                                    fontFamily: 'Golos',
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${analyticsText(context, 'analytics_cold', fallback: 'Cold')}: ${item.cold}\n',
                                                  style: TextStyle(
                                                    fontSize: axisLabelSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: _coldColor,
                                                    fontFamily: 'Golos',
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      'ROI: ${item.roi.toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    fontSize: axisLabelSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: _roiLineColor,
                                                    fontFamily: 'Golos',
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (_) => FlLine(
                                          color: colors.borderSubtle,
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: leftReserved,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                value.toInt().toString(),
                                                style: TextStyle(
                                                  fontSize: axisLabelSize,
                                                  color: colors.textSecondary,
                                                  fontFamily: 'Golos',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: rightReserved,
                                            getTitlesWidget: (value, meta) {
                                              final roiPercent = maxY > 0
                                                  ? (value / maxY) * maxRoi
                                                  : 0.0;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 6),
                                                child: Text(
                                                  '${roiPercent.toStringAsFixed(roiPercent < 10 ? 1 : 0)}%',
                                                  style: TextStyle(
                                                    fontSize: axisLabelSize,
                                                    color: _roiLineColor,
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
                                            reservedSize: bottomReserved,
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              if (index < 0 ||
                                                  index >=
                                                      displayCampaigns.length) {
                                                return const SizedBox.shrink();
                                              }
                                              return RotatedBox(
                                                quarterTurns: 3,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 6),
                                                  child: Text(
                                                    _shortLabel(
                                                        displayCampaigns[index]
                                                            .integrationName,
                                                        labelMaxLen),
                                                    style: TextStyle(
                                                      fontSize: axisLabelSize,
                                                      color:
                                                          colors.textSecondary,
                                                      fontFamily: 'Golos',
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ── ROI % line overlay ──
                                  if (_showRoiLine)
                                    Positioned.fill(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: leftReserved,
                                          right: rightReserved,
                                          bottom: bottomReserved,
                                        ),
                                        child: IgnorePointer(
                                          child: LineChart(
                                            LineChartData(
                                              minX: 0,
                                              maxX:
                                                  (displayCampaigns.length - 1)
                                                      .toDouble(),
                                              minY: 0,
                                              maxY: maxY,
                                              clipData: const FlClipData.all(),
                                              lineBarsData: _buildRoiLine(
                                                  displayCampaigns, maxY),
                                              gridData:
                                                  const FlGridData(show: false),
                                              borderData:
                                                  FlBorderData(show: false),
                                              titlesData: const FlTitlesData(
                                                topTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false)),
                                                bottomTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false)),
                                                leftTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false)),
                                                rightTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false)),
                                              ),
                                              lineTouchData:
                                                  const LineTouchData(
                                                      enabled: false),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
              ),

              SizedBox(height: isCompact ? 8 : 12),

              // ── Legend ──
              if (_data != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: headerPad),
                  child: Wrap(
                    spacing: isCompact ? 8 : 14,
                    runSpacing: 6,
                    children: [
                      _LegendDot(
                        color: _leadsColor,
                        label: analyticsText(
                          context,
                          'leads',
                          fallback: 'Leads',
                        ),
                        enabled: _showLeads,
                        fontSize: legendFontSize,
                        onTap: () => setState(() => _showLeads = !_showLeads),
                      ),
                      _LegendDot(
                        color: _clientsColor,
                        label: analyticsText(
                          context,
                          'clients',
                          fallback: 'Clients',
                        ),
                        enabled: _showClients,
                        fontSize: legendFontSize,
                        onTap: () =>
                            setState(() => _showClients = !_showClients),
                      ),
                      _LegendDot(
                        color: _coldColor,
                        label: analyticsText(
                          context,
                          'analytics_cold',
                          fallback: 'Cold',
                        ),
                        enabled: _showCold,
                        fontSize: legendFontSize,
                        onTap: () => setState(() => _showCold = !_showCold),
                      ),
                      _LegendLine(
                        color: _roiLineColor,
                        label: 'ROI %',
                        enabled: _showRoiLine,
                        fontSize: legendFontSize,
                        onTap: () =>
                            setState(() => _showRoiLine = !_showRoiLine),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: isCompact ? 10 : 14),

              // ── Summary stats ──
              if (_data != null)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    headerPad,
                    isCompact ? 10 : 12,
                    headerPad,
                    headerPad,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      _StatCell(
                        label: analyticsText(
                          context,
                          'analytics_spent',
                          fallback: 'Spent',
                        ),
                        value: _data!.summary.totalSpent.toStringAsFixed(0),
                        labelSize: statLabelSize,
                        valueSize: statValueSize,
                        secondaryText:
                            'ROI ${_data!.summary.roi.toStringAsFixed(0)}%',
                        secondaryColor: _data!.summary.roi >= 0
                            ? colors.success
                            : colors.error,
                      ),
                      _StatCell(
                        label: analyticsText(
                          context,
                          'leads',
                          fallback: 'Leads',
                        ),
                        value: _data!.summary.totalLeads.toString(),
                        labelSize: statLabelSize,
                        valueSize: statValueSize,
                      ),
                      _StatCell(
                        label: 'CPL',
                        value: _data!.summary.cpl.toStringAsFixed(0),
                        labelSize: statLabelSize,
                        valueSize: statValueSize,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════
//  Small reusable widgets
// ══════════════════════════════════════════

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.labelSize,
    required this.valueSize,
    this.valueColor,
    this.secondaryText,
    this.secondaryColor,
  });

  final String label;
  final String value;
  final double labelSize;
  final double valueSize;
  final Color? valueColor;
  final String? secondaryText;
  final Color? secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              color: context.appColors.textSecondary,
              fontFamily: 'Golos',
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
                color: valueColor ?? context.appColors.textPrimary,
                fontFamily: 'Golos',
              ),
            ),
          ),
          if (secondaryText != null) ...[
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                secondaryText!,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w700,
                  color: secondaryColor ?? context.appColors.textSecondary,
                  fontFamily: 'Golos',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.enabled,
    required this.fontSize,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool enabled;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = enabled ? color : const Color(0xffCBD5E1);
    final textColor =
        enabled ? const Color(0xff64748B) : const Color(0xff94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontFamily: 'Golos',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.color,
    required this.label,
    required this.enabled,
    required this.fontSize,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool enabled;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lineColor = enabled ? color : const Color(0xffCBD5E1);
    final textColor =
        enabled ? const Color(0xff64748B) : const Color(0xff94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line + dot icon
            SizedBox(
              width: 20,
              height: 10,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: lineColor, width: 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontFamily: 'Golos',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
