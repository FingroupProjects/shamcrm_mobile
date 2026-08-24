import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class ConversionChart extends StatefulWidget {
  const ConversionChart({super.key, required this.title});

  final String title;

  @override
  State<ConversionChart> createState() => _ConversionChartState();
}

class _ConversionChartState extends State<ConversionChart> {
  static const List<double> _fixedConversionTicks = [100, 80, 60, 40, 20, 0];

  bool _isLoading = true;
  String? _error;
  List<double> _conversionData = [];

  String get _title => widget.title;

  static const List<double> _previewData = [
    18.2,
    21.5,
    19.8,
    24.1,
    22.4,
    25.3,
    27.6,
    29.1,
    26.8,
    28.0,
    27.2,
    26.4
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
      final response = await apiService.getLeadConversionDataV2();

      AnalyticsChartRequestPolicy.reset(chartId, readyState: this);
      if (!mounted) return;
      setState(() {
        _conversionData = response.monthlyData;
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

  double get _averagePercentage {
    if (_conversionData.isEmpty) return 0.0;
    return _conversionData.reduce((a, b) => a + b) / _conversionData.length;
  }

  double _roundUpTo2Decimals(double value) {
    const factor = 100.0;
    if (value >= 0) {
      return (value * factor).ceil() / factor;
    }
    return (value * factor).floor() / factor;
  }

  String _formatPercent(double value) {
    return _roundUpTo2Decimals(value).toStringAsFixed(2);
  }

  String get _averagePercentageFormatted {
    return _formatPercent(_averagePercentage);
  }

  int get _bestMonthIndex {
    if (_conversionData.isEmpty) return 0;
    double maxValue = _conversionData[0];
    int maxIndex = 0;

    for (int i = 1; i < _conversionData.length; i++) {
      if (_conversionData[i] > maxValue) {
        maxValue = _conversionData[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  String get _bestMonth {
    return analyticsMonthFull(context, _bestMonthIndex + 1);
  }

  void _showDetails() {
    if (_conversionData.isEmpty) return;
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfacePrimary,
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
                        color: colors.textPrimary,
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.iconSecondary),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper(context).smallSpacing),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _conversionData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final monthName = analyticsMonthFull(context, index + 1);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        monthName,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${_formatPercent(_conversionData[index])}%',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: colors.buttonPrimaryBg,
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final isEmpty =
        _conversionData.isEmpty || _conversionData.every((v) => v == 0);
    final chartData = isEmpty ? _previewData : _conversionData;
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
                      colors: [Color(0xff6366F1), Color(0xff8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: colors.textInverse,
                    size: ResponsiveHelper(context).smallIconSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Golos',
                  ),
                ),
                const Spacer(),
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
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                minY: 0,
                                maxY: 100,
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
                                      return BarTooltipItem(
                                        '${_formatPercent(rod.toY)}%',
                                        TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: responsive.bodyFontSize,
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
                                      reservedSize: 36,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < chartData.length) {
                                          return RotatedBox(
                                            quarterTurns: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                analyticsMonthShort(
                                                  context,
                                                  value.toInt() + 1,
                                                ),
                                                style: TextStyle(
                                                  color: colors.textSecondary,
                                                  fontSize:
                                                      responsive.smallFontSize,
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
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: 20,
                                      getTitlesWidget: (value, meta) {
                                        final bool isTick =
                                            _fixedConversionTicks.any((tick) =>
                                                (tick - value).abs() < 0.001);
                                        if (!isTick) {
                                          return const SizedBox.shrink();
                                        }
                                        final label = '${value.toInt()}%';
                                        return Text(
                                          label,
                                          style: TextStyle(
                                            color: colors.textSecondary,
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
                                  horizontalInterval: 20,
                                  getDrawingHorizontalLine: (value) {
                                    final bool isTick =
                                        _fixedConversionTicks.any((tick) =>
                                            (tick - value).abs() < 0.001);
                                    if (!isTick) {
                                      return const FlLine(
                                        color: Colors.transparent,
                                        strokeWidth: 0,
                                      );
                                    }
                                    return FlLine(
                                      color: colors.borderSubtle,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: chartData
                                    .asMap()
                                    .entries
                                    .map((entry) =>
                                        _makeGroupData(entry.key, entry.value))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
          // Footer
          if (_isLoading)
            AnalyticsChartFooterSkeleton(padding: responsive.cardPadding)
          else if (_error == null && _conversionData.isNotEmpty)
            Container(
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analyticsText(
                          context,
                          'analytics_average_conversion',
                          fallback: 'Average conversion',
                        ),
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: colors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$_averagePercentageFormatted%',
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        analyticsText(
                          context,
                          'analytics_best_period',
                          fallback: 'Best period',
                        ),
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: colors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _bestMonth,
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
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

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xff6366F1), Color(0xff8B5CF6)],
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
