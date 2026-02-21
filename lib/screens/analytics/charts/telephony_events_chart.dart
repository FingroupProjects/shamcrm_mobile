import 'dart:math' as math;

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/models/telephony_events_model.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';

class TelephonyEventsChart extends StatefulWidget {
  const TelephonyEventsChart({super.key, required this.title});

  final String title;

  @override
  State<TelephonyEventsChart> createState() => _TelephonyEventsChartState();
}

class _TelephonyEventsChartState extends State<TelephonyEventsChart> {
  static const Color _incomingColor = Color(0xff20B486);
  static const Color _outgoingColor = Color(0xff5F62E0);
  static const Color _missedColor = Color(0xffEF4444);
  static const Color _createdColor = Color(0xff7B4CE2);
  static const Color _closedColor = Color(0xffF59E0B);
  static const Color _labelColor = Color(0xff64748B);

  static const List<String> _weekDays = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс'
  ];

  bool _isLoading = true;
  String? _error;
  TelephonyEventsResponse? _data;
  bool _showIncoming = true;
  bool _showOutgoing = true;
  bool _showMissed = true;
  bool _showCreated = true;
  bool _showClosed = true;

  String get _title => widget.title;

  static final List<TelephonyEventDay> _previewDays = [
    TelephonyEventDay(
      day: 1,
      incoming: 140,
      outgoing: 98,
      missed: 12,
      noticesCreated: 45,
      noticesFinished: 38,
    ),
    TelephonyEventDay(
      day: 2,
      incoming: 155,
      outgoing: 112,
      missed: 18,
      noticesCreated: 52,
      noticesFinished: 48,
    ),
    TelephonyEventDay(
      day: 3,
      incoming: 132,
      outgoing: 89,
      missed: 14,
      noticesCreated: 47,
      noticesFinished: 42,
    ),
    TelephonyEventDay(
      day: 4,
      incoming: 166,
      outgoing: 134,
      missed: 21,
      noticesCreated: 60,
      noticesFinished: 53,
    ),
    TelephonyEventDay(
      day: 5,
      incoming: 188,
      outgoing: 145,
      missed: 24,
      noticesCreated: 68,
      noticesFinished: 58,
    ),
    TelephonyEventDay(
      day: 6,
      incoming: 97,
      outgoing: 68,
      missed: 8,
      noticesCreated: 32,
      noticesFinished: 28,
    ),
    TelephonyEventDay(
      day: 7,
      incoming: 86,
      outgoing: 57,
      missed: 6,
      noticesCreated: 29,
      noticesFinished: 25,
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
      final response = await apiService.getTelephonyAndEventsChartV2();

      if (!mounted) return;
      setState(() {
        _data = response;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить данные. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  void _showDetails() {
    final items = _data?.chart ?? const <TelephonyEventDay>[];
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
                    icon: Icon(Icons.refresh, color: _labelColor),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: _labelColor),
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
                    final dayLabel = index < _weekDays.length
                        ? _weekDays[index]
                        : 'Д${item.day}';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).subtitleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        'Входящие: ${item.incoming}, Исходящие: ${item.outgoing}, Пропущенные: ${item.missed}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).captionFontSize,
                          color: _labelColor,
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${item.noticesCreated}/${item.noticesFinished}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w700,
                          color: _createdColor,
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

  List<BarChartGroupData> _buildGroups(List<TelephonyEventDay> items) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final incoming = item.incoming.toDouble();
      final outgoing = item.outgoing.toDouble();
      final missed = item.missed.toDouble();
      var sum = 0.0;
      final stackItems = <BarChartRodStackItem>[];

      if (_showIncoming) {
        stackItems
            .add(BarChartRodStackItem(sum, sum + incoming, _incomingColor));
        sum += incoming;
      }
      if (_showOutgoing) {
        stackItems
            .add(BarChartRodStackItem(sum, sum + outgoing, _outgoingColor));
        sum += outgoing;
      }
      if (_showMissed) {
        stackItems.add(BarChartRodStackItem(sum, sum + missed, _missedColor));
        sum += missed;
      }

      if (stackItems.isEmpty) {
        stackItems.add(BarChartRodStackItem(0, 0.001, Colors.transparent));
      }

      return BarChartGroupData(
        x: index,
        barsSpace: 0,
        barRods: [
          BarChartRodData(
            toY: sum,
            width: 38,
            borderRadius: BorderRadius.circular(2),
            rodStackItems: stackItems,
          ),
        ],
      );
    });
  }

  List<LineChartBarData> _buildLineBars(List<TelephonyEventDay> items) {
    final createdSpots = <FlSpot>[];
    final closedSpots = <FlSpot>[];

    for (int i = 0; i < items.length; i++) {
      createdSpots
          .add(FlSpot(i.toDouble(), items[i].noticesCreated.toDouble()));
      closedSpots
          .add(FlSpot(i.toDouble(), items[i].noticesFinished.toDouble()));
    }

    final bars = <LineChartBarData>[];

    if (_showCreated) {
      bars.add(
        LineChartBarData(
          spots: createdSpots,
          color: _createdColor,
          isCurved: false,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4,
              color: Colors.white,
              strokeColor: _createdColor,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    if (_showClosed) {
      bars.add(
        LineChartBarData(
          spots: closedSpots,
          color: _closedColor,
          isCurved: false,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: Colors.white,
              strokeColor: _closedColor,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    return bars;
  }

  double _maxY(List<TelephonyEventDay> items) {
    if (items.isEmpty) return 6;

    final maxBar = items
        .map((e) =>
            (_showIncoming ? e.incoming : 0) +
            (_showOutgoing ? e.outgoing : 0) +
            (_showMissed ? e.missed : 0))
        .fold<int>(0, (prev, curr) => math.max(prev, curr));
    final maxCreated = _showCreated
        ? items
            .map((e) => e.noticesCreated)
            .fold<int>(0, (prev, curr) => math.max(prev, curr))
        : 0;
    final maxClosed = _showClosed
        ? items
            .map((e) => e.noticesFinished)
            .fold<int>(0, (prev, curr) => math.max(prev, curr))
        : 0;

    final maxBase = math.max(maxBar, math.max(maxCreated, maxClosed));
    final padded = (maxBase * 1.1).ceil();

    if (padded <= 6) return 6;
    if (padded <= 12) return 12;
    if (padded <= 18) return 18;
    if (padded <= 24) return 24;
    return padded.toDouble();
  }

  int _leftInterval(double maxY) {
    if (maxY <= 6) return 1;
    if (maxY <= 12) return 2;
    if (maxY <= 18) return 3;
    if (maxY <= 24) return 4;
    return math.max(1, (maxY / 6).round());
  }

  @override
  Widget build(BuildContext context) {
    final items = _data?.chart ?? const <TelephonyEventDay>[];
    final isEmpty = items.isEmpty ||
        items.every((e) =>
            e.incoming == 0 &&
            e.outgoing == 0 &&
            e.missed == 0 &&
            e.noticesCreated == 0 &&
            e.noticesFinished == 0);
    final displayItems = isEmpty ? _previewDays : items;

    final maxY = _maxY(displayItems);
    final leftInterval = _leftInterval(maxY);

    final totalCalls = _data?.totalCalls ?? 0;
    final totalMissed = _data?.totalMissed ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;
        final isVeryCompact = constraints.maxWidth < 360;
        final headerIconSize = isVeryCompact ? 30.0 : (isCompact ? 34.0 : 38.0);
        final headerPadding = isVeryCompact ? 10.0 : (isCompact ? 12.0 : 14.0);
        final chartHeight = isVeryCompact ? 220.0 : (isCompact ? 245.0 : 270.0);
        final numberFontSize = isVeryCompact ? 18.0 : (isCompact ? 22.0 : 26.0);
        final titleSize = isVeryCompact ? 16.0 : (isCompact ? 17.0 : 18.0);
        final leftReserved = isVeryCompact ? 28.0 : 32.0;
        final bottomReserved = isVeryCompact ? 28.0 : 32.0;
        final tooltipMaxWidth = math.max(
          180.0,
          (constraints.maxWidth - (headerPadding * 2)) * 0.55,
        );

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xffF8FAFC),
            borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
            border: Border.all(color: const Color(0xffE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0F172A).withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(headerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: headerIconSize,
                      height: headerIconSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.call,
                        color: Colors.black,
                        size: isVeryCompact ? 13 : (isCompact ? 14 : 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _title,
                        maxLines: isVeryCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _showDetails,
                          icon: Icon(
                            Icons.crop_free,
                            color: Color(0xff64748B),
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xffF1F5F9),
                            minimumSize: Size(
                              isVeryCompact ? 36 : 40,
                              isVeryCompact ? 36 : 40,
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(isVeryCompact ? 12 : 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: isVeryCompact ? 8 : 10,
                  runSpacing: 6,
                  children: [
                    _LegendRect(
                      color: _incomingColor,
                      label: 'Входящие',
                      enabled: _showIncoming,
                      onTap: () =>
                          setState(() => _showIncoming = !_showIncoming),
                    ),
                    _LegendRect(
                      color: _outgoingColor,
                      label: 'Исходящие',
                      enabled: _showOutgoing,
                      onTap: () =>
                          setState(() => _showOutgoing = !_showOutgoing),
                    ),
                    _LegendRect(
                      color: _missedColor,
                      label: 'Пропущенные',
                      enabled: _showMissed,
                      onTap: () => setState(() => _showMissed = !_showMissed),
                    ),
                    _LegendLine(
                      color: _createdColor,
                      label: 'События создано',
                      enabled: _showCreated,
                      onTap: () => setState(() => _showCreated = !_showCreated),
                    ),
                    _LegendLine(
                      color: _closedColor,
                      label: 'События закрыто',
                      enabled: _showClosed,
                      onTap: () => setState(() => _showClosed = !_showClosed),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: chartHeight,
                  child: _isLoading
                      ? const AnalyticsChartShimmerLoader()
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: _missedColor,
                                  fontFamily: 'Golos',
                                ),
                              ),
                            )
                          : ChartEmptyOverlay(
                              show: isEmpty,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    BarChart(
                                      BarChartData(
                                        maxY: maxY,
                                        minY: 0,
                                        alignment:
                                            BarChartAlignment.spaceAround,
                                        barGroups: _buildGroups(displayItems),
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: math
                                              .max(1, leftInterval)
                                              .toDouble(),
                                          getDrawingHorizontalLine: (_) =>
                                              FlLine(
                                            color: const Color(0xffD5DEE8),
                                            strokeWidth: 1,
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: const Border(
                                            bottom: BorderSide(
                                                color: Color(0xffD5DEE8),
                                                width: 1),
                                            left: BorderSide(
                                                color: Colors.transparent),
                                            right: BorderSide(
                                                color: Colors.transparent),
                                            top: BorderSide(
                                                color: Colors.transparent),
                                          ),
                                        ),
                                        barTouchData: BarTouchData(
                                          enabled: true,
                                          handleBuiltInTouches: true,
                                          touchTooltipData: BarTouchTooltipData(
                                            getTooltipColor: (_) =>
                                                const Color(0xffF8FAFC),
                                            tooltipRoundedRadius: 12,
                                            tooltipPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            maxContentWidth: tooltipMaxWidth,
                                            fitInsideHorizontally: true,
                                            fitInsideVertically: true,
                                            getTooltipItem:
                                                (group, _, __, ___) {
                                              final index = group.x.toInt();
                                              if (index < 0 ||
                                                  index >=
                                                      displayItems.length) {
                                                return null;
                                              }
                                              final item = displayItems[index];
                                              final day =
                                                  index < _weekDays.length
                                                      ? _weekDays[index]
                                                      : 'Д${item.day}';

                                              final spans = <TextSpan>[];
                                              final metricTextStyle = TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    ResponsiveHelper(context)
                                                        .captionFontSize,
                                                fontFamily: 'Golos',
                                              );
                                              final metricContentWidth =
                                                  math.max(
                                                140.0,
                                                tooltipMaxWidth - 32,
                                              );

                                              double measureTextWidth(
                                                String text,
                                                TextStyle style,
                                              ) {
                                                final painter = TextPainter(
                                                  text: TextSpan(
                                                    text: text,
                                                    style: style,
                                                  ),
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  maxLines: 1,
                                                )..layout();
                                                return painter.width;
                                              }

                                              TextSpan buildMetricSpan({
                                                required String label,
                                                required int value,
                                                required Color color,
                                                required bool withNewLine,
                                              }) {
                                                final valueText =
                                                    value.toString();
                                                final labelText = '● $label';
                                                final spaceWidth =
                                                    measureTextWidth(
                                                  ' ',
                                                  metricTextStyle,
                                                );
                                                final leftWidth =
                                                    measureTextWidth(
                                                  labelText,
                                                  metricTextStyle,
                                                );
                                                final valueWidth =
                                                    measureTextWidth(
                                                  valueText,
                                                  metricTextStyle,
                                                );
                                                final spaces = math.max(
                                                  1,
                                                  ((metricContentWidth -
                                                              leftWidth -
                                                              valueWidth) /
                                                          math.max(
                                                            1,
                                                            spaceWidth,
                                                          ))
                                                      .floor(),
                                                );
                                                return TextSpan(
                                                  text:
                                                      '$labelText${' ' * spaces}$valueText${withNewLine ? '\n' : ''}',
                                                  style: metricTextStyle
                                                      .copyWith(color: color),
                                                );
                                              }

                                              if (_showIncoming) {
                                                spans.add(
                                                  buildMetricSpan(
                                                    label: 'Входящие',
                                                    value: item.incoming,
                                                    color: _incomingColor,
                                                    withNewLine: true,
                                                  ),
                                                );
                                              }
                                              if (_showOutgoing) {
                                                spans.add(
                                                  buildMetricSpan(
                                                    label: 'Исходящие',
                                                    value: item.outgoing,
                                                    color: _outgoingColor,
                                                    withNewLine: true,
                                                  ),
                                                );
                                              }
                                              if (_showMissed) {
                                                spans.add(
                                                  buildMetricSpan(
                                                    label: 'Пропущенные',
                                                    value: item.missed,
                                                    color: _missedColor,
                                                    withNewLine: true,
                                                  ),
                                                );
                                              }
                                              if (_showCreated) {
                                                spans.add(
                                                  buildMetricSpan(
                                                    label: 'События создано',
                                                    value: item.noticesCreated,
                                                    color: _createdColor,
                                                    withNewLine: true,
                                                  ),
                                                );
                                              }
                                              if (_showClosed) {
                                                spans.add(
                                                  buildMetricSpan(
                                                    label: 'События закрыто',
                                                    value: item.noticesFinished,
                                                    color: _closedColor,
                                                    withNewLine: false,
                                                  ),
                                                );
                                              }

                                              return BarTooltipItem(
                                                '$day\n',
                                                TextStyle(
                                                  color: Color(0xff0F172A),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize:
                                                      ResponsiveHelper(context)
                                                          .subtitleFontSize,
                                                  fontFamily: 'Golos',
                                                ),
                                                textAlign: TextAlign.left,
                                                children: spans,
                                              );
                                            },
                                          ),
                                        ),
                                        titlesData: FlTitlesData(
                                          topTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              interval: leftInterval.toDouble(),
                                              reservedSize: leftReserved,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  value.toInt().toString(),
                                                  style: TextStyle(
                                                    fontSize:
                                                        isVeryCompact ? 10 : 11,
                                                    color: _labelColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Golos',
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
                                                        displayItems.length) {
                                                  return const SizedBox
                                                      .shrink();
                                                }
                                                final text = index <
                                                        _weekDays.length
                                                    ? _weekDays[index]
                                                    : 'Д${displayItems[index].day}';
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 6),
                                                  child: Text(
                                                    text,
                                                    style: TextStyle(
                                                      fontSize: isVeryCompact
                                                          ? 12
                                                          : 14,
                                                      color: _labelColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily: 'Golos',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_showCreated || _showClosed)
                                      Positioned.fill(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            left: leftReserved,
                                            bottom: bottomReserved,
                                          ),
                                          child: IgnorePointer(
                                            child: LineChart(
                                              LineChartData(
                                                minX: 0,
                                                maxX: (displayItems.length - 1)
                                                    .toDouble(),
                                                minY: 0,
                                                maxY: maxY,
                                                clipData:
                                                    const FlClipData.all(),
                                                lineBarsData: _buildLineBars(
                                                    displayItems),
                                                gridData: const FlGridData(
                                                    show: false),
                                                borderData:
                                                    FlBorderData(show: false),
                                                titlesData: const FlTitlesData(
                                                  topTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false),
                                                  ),
                                                  rightTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false),
                                                  ),
                                                  leftTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false),
                                                  ),
                                                  bottomTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false),
                                                  ),
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
                const SizedBox(height: 8),
                const Divider(color: Color(0xffD5DEE8), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Всего звонков',
                            style: TextStyle(
                              color: _labelColor,
                              fontSize: isVeryCompact
                                  ? 10.0
                                  : (isCompact ? 11.0 : 12.0),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Golos',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalCalls',
                            style: TextStyle(
                              color: const Color(0xff0F172A),
                              fontSize: numberFontSize,
                              height: 0.92,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Golos',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Пропущенные',
                            style: TextStyle(
                              color: _labelColor,
                              fontSize: isVeryCompact
                                  ? 10.0
                                  : (isCompact ? 11.0 : 12.0),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Golos',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalMissed',
                            style: TextStyle(
                              color: _missedColor,
                              fontSize: numberFontSize,
                              height: 0.92,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Golos',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LegendRect extends StatelessWidget {
  const _LegendRect({
    required this.color,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : const Color(0xffCBD5E1);
    final effectiveText =
        enabled ? const Color(0xff64748B) : const Color(0xff94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 22,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: effectiveText,
              fontSize: ResponsiveHelper(context).captionFontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Golos',
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.color,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : const Color(0xffCBD5E1);
    final effectiveText =
        enabled ? const Color(0xff64748B) : const Color(0xff94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            child: Row(
              children: [
                Expanded(child: Container(height: 2.5, color: effectiveColor)),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: effectiveColor, width: 3),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: effectiveText,
              fontSize: ResponsiveHelper(context).captionFontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Golos',
            ),
          ),
        ],
      ),
    );
  }
}
