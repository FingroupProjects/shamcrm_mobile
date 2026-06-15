import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/telephony_by_hour_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';
import 'package:intl/intl.dart';

class TelephonyByHourChart extends StatefulWidget {
  const TelephonyByHourChart({super.key, required this.title});

  final String title;

  @override
  State<TelephonyByHourChart> createState() => _TelephonyByHourChartState();
}

class _TelephonyByHourChartState extends State<TelephonyByHourChart> {
  bool _isLoading = true;
  String? _error;
  TelephonyByHourResponse? _data;
  DateTime _selectedDate = DateTime.now();
  bool _showIncoming = true;
  bool _showOutgoing = true;
  bool _showMissed = true;

  String get _title => widget.title;

  static final List<TelephonyHourItem> _previewHours = [
    TelephonyHourItem(
        hour: '08:00',
        hourNumber: 8,
        incoming: 4,
        outgoing: 2,
        missed: 1,
        minutes: 20,
        total: 7),
    TelephonyHourItem(
        hour: '10:00',
        hourNumber: 10,
        incoming: 8,
        outgoing: 5,
        missed: 2,
        minutes: 45,
        total: 15),
    TelephonyHourItem(
        hour: '12:00',
        hourNumber: 12,
        incoming: 12,
        outgoing: 7,
        missed: 3,
        minutes: 60,
        total: 22),
    TelephonyHourItem(
        hour: '14:00',
        hourNumber: 14,
        incoming: 10,
        outgoing: 6,
        missed: 2,
        minutes: 50,
        total: 18),
    TelephonyHourItem(
        hour: '16:00',
        hourNumber: 16,
        incoming: 6,
        outgoing: 4,
        missed: 1,
        minutes: 30,
        total: 11),
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
      final response = await apiService.getTelephonyByHourChartV2(
        date: _selectedDate,
      );

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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 2),
      helpText: analyticsText(
        context,
        'analytics_select_day',
        fallback: 'Select day',
      ),
      cancelText: analyticsText(context, 'cancel', fallback: 'Cancel'),
      confirmText: 'OK',
      builder: (context, child) {
        final base = Theme.of(context);
        final colors = context.appColors;
        return Theme(
          data: base.copyWith(
            dialogTheme: DialogThemeData(
              backgroundColor: colors.surfacePrimary,
            ),
            colorScheme: base.colorScheme.copyWith(
              primary: colors.buttonPrimaryBg,
              onPrimary: colors.buttonPrimaryFg,
              onSurface: colors.textPrimary,
              surface: colors.surfacePrimary,
            ),
            textTheme: base.textTheme.apply(
              bodyColor: colors.textPrimary,
              displayColor: colors.textPrimary,
              fontFamily: 'Gilroy',
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.surfacePrimary,
              surfaceTintColor: colors.surfacePrimary,
              headerBackgroundColor: colors.surfacePrimary,
              headerForegroundColor: colors.textPrimary,
              weekdayStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
              ),
              dayStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
              ),
              yearStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
              ),
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
    await _loadData();
  }

  void _showDetails() {
    final items = _data?.chart ?? [];
    if (items.isEmpty) return;
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
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
                        color: colors.textPrimary,
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadData();
                    },
                    icon: Icon(Icons.refresh, color: colors.iconSecondary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.iconSecondary),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: colors.borderSubtle),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.hour,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        '${analyticsText(context, 'incoming', fallback: 'Incoming')}: ${item.incoming}, ${analyticsText(context, 'outgoing', fallback: 'Outgoing')}: ${item.outgoing}, ${analyticsText(context, 'missed', fallback: 'Missed')}: ${item.missed}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: colors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${analyticsText(context, 'total', fallback: 'Total')}: ${item.total}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: colors.info,
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

  List<BarChartGroupData> _buildGroups(
    List<TelephonyHourItem> items, {
    double barWidth = 18,
  }) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final stackItems = <BarChartRodStackItem>[];
      double sum = 0;
      if (_showIncoming) {
        final value = item.incoming.toDouble();
        stackItems.add(
          BarChartRodStackItem(sum, sum + value, const Color(0xff10B981)),
        );
        sum += value;
      }
      if (_showOutgoing) {
        final value = item.outgoing.toDouble();
        stackItems.add(
          BarChartRodStackItem(sum, sum + value, const Color(0xff22B3D6)),
        );
        sum += value;
      }
      if (_showMissed) {
        final value = item.missed.toDouble();
        stackItems.add(
          BarChartRodStackItem(sum, sum + value, const Color(0xffEF4444)),
        );
        sum += value;
      }

      if (stackItems.isEmpty) {
        stackItems.add(BarChartRodStackItem(0, 0.001, Colors.transparent));
        sum = 0.001;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: sum,
            width: barWidth,
            borderRadius: BorderRadius.circular(3),
            rodStackItems: stackItems,
          ),
        ],
        barsSpace: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final items = _data?.chart ?? [];
    final isEmpty = items.isEmpty ||
        items.every((e) =>
            e.incoming == 0 &&
            e.outgoing == 0 &&
            e.missed == 0 &&
            e.total == 0);
    final displayItems = isEmpty ? _previewHours : items;
    final maxValue = displayItems.isEmpty
        ? 1.0
        : displayItems
            .map((e) {
              final incoming = _showIncoming ? e.incoming : 0;
              final outgoing = _showOutgoing ? e.outgoing : 0;
              final missed = _showMissed ? e.missed : 0;
              return incoming + outgoing + missed;
            })
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    final safeMaxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final selectedDateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final isCompact = MediaQuery.of(context).size.width < 420;

    final barWidth = responsive.screenWidth < 360 ? 16.0 : 22.0;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.4)),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff0EA5E9), Color(0xff2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xff0EA5E9).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: colors.textInverse,
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
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showDetails,
                      icon: Icon(Icons.crop_free,
                          color: colors.iconSecondary, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceElevated,
                        minimumSize: Size(40, 40),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 10 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: colors.iconSecondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            selectedDateLabel,
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              fontFamily: 'Golos',
                            ),
                          ),
                        ],
                      ),
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
                          style: TextStyle(
                            color: colors.error,
                            fontFamily: 'Golos',
                          ),
                        ),
                      )
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: BarChart(
                            BarChartData(
                              maxY: safeMaxY,
                              barGroups: _buildGroups(
                                displayItems,
                                barWidth: barWidth,
                              ),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => colors.surfacePrimary,
                                  tooltipBorder: BorderSide(
                                    color: colors.borderSubtle,
                                  ),
                                  tooltipRoundedRadius: 12,
                                  tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  tooltipMargin: 8,
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    final index = group.x.toInt();
                                    if (index < 0 ||
                                        index >= displayItems.length) {
                                      return null;
                                    }
                                    final item = displayItems[index];
                                    return BarTooltipItem(
                                      '${item.hour}\n',
                                      TextStyle(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: responsive.smallFontSize,
                                        fontFamily: 'Golos',
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              '● ${analyticsText(context, 'incoming', fallback: 'Incoming')}: ${item.incoming}\n',
                                          style: TextStyle(
                                            color: const Color(0xff10B981),
                                            fontWeight: FontWeight.w600,
                                            fontSize: responsive.smallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '● ${analyticsText(context, 'outgoing', fallback: 'Outgoing')}: ${item.outgoing}\n',
                                          style: TextStyle(
                                            color: const Color(0xff22B3D6),
                                            fontWeight: FontWeight.w600,
                                            fontSize: responsive.smallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '● ${analyticsText(context, 'missed', fallback: 'Missed')}: ${item.missed}\n',
                                          style: TextStyle(
                                            color: const Color(0xffEF4444),
                                            fontWeight: FontWeight.w600,
                                            fontSize: responsive.smallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${analyticsText(context, 'total', fallback: 'Total')}: ${item.total}',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: responsive.smallFontSize,
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
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: colors.borderSubtle,
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
                                          fontSize: responsive.xSmallFontSize,
                                          color: colors.textSecondary,
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
                                      if (index < 0 ||
                                          index >= displayItems.length) {
                                        return const SizedBox.shrink();
                                      }
                                      if (index % 3 != 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          displayItems[index].hour,
                                          style: TextStyle(
                                            fontSize: responsive.xSmallFontSize,
                                            color: colors.textSecondary,
                                            fontFamily: 'Golos',
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final legend = Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _LegendToggle(
                        color: const Color(0xff10B981),
                        label: analyticsText(
                          context,
                          'incoming',
                          fallback: 'Incoming',
                        ),
                        enabled: _showIncoming,
                        onTap: () =>
                            setState(() => _showIncoming = !_showIncoming),
                      ),
                      _LegendToggle(
                        color: const Color(0xff22B3D6),
                        label: analyticsText(
                          context,
                          'outgoing',
                          fallback: 'Outgoing',
                        ),
                        enabled: _showOutgoing,
                        onTap: () =>
                            setState(() => _showOutgoing = !_showOutgoing),
                      ),
                      _LegendToggle(
                        color: const Color(0xffEF4444),
                        label: analyticsText(
                          context,
                          'missed',
                          fallback: 'Missed',
                        ),
                        enabled: _showMissed,
                        onTap: () => setState(() => _showMissed = !_showMissed),
                      ),
                    ],
                  );

                  final peakText = Text(
                    '${analyticsText(context, 'analytics_peak', fallback: 'Peak')}: ${_data!.peakHour ?? '-'}',
                    style: TextStyle(
                      fontSize: responsive.smallFontSize,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      fontFamily: 'Golos',
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        legend,
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: peakText,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      legend,
                      const Spacer(),
                      peakText,
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendToggle extends StatelessWidget {
  final Color color;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _LegendToggle({
    required this.color,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor =
        enabled ? color : context.appColors.borderSubtle.withValues(alpha: 0.9);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper(context).smallFontSize,
              color: enabled
                  ? context.appColors.textSecondary
                  : context.appColors.textMuted,
              fontFamily: 'Golos',
            ),
          ),
        ],
      ),
    );
  }
}
