import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getTelephonyByHourChartV2(
        date: _selectedDate,
      );

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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 2),
      helpText: 'Выберите день',
      cancelText: 'Отмена',
      confirmText: 'OK',
      builder: (context, child) {
        final base = Theme.of(context);
        const accent = Color(0xff1E2E52);
        return Theme(
          data: base.copyWith(
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
            colorScheme: base.colorScheme.copyWith(
              primary: accent,
              onPrimary: Colors.white,
              onSurface: accent,
              surface: Colors.white,
            ),
            textTheme: base.textTheme.apply(
              bodyColor: accent,
              displayColor: accent,
              fontFamily: 'Gilroy',
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: accent,
              weekdayStyle: TextStyle(
                color: accent,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
              ),
              dayStyle: TextStyle(
                color: accent,
                fontFamily: 'Gilroy',
              ),
              yearStyle: TextStyle(
                color: accent,
                fontFamily: 'Gilroy',
              ),
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(accent),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(accent),
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
                        fontSize: 18,
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
              const SizedBox(height: 12),
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
                        item.hour,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        'Вход: ${item.incoming}, Исход: ${item.outgoing}, Пропущ: ${item.missed}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        'Всего: ${item.total}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0EA5E9),
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
        : displayItems.map((e) {
            final incoming = _showIncoming ? e.incoming : 0;
            final outgoing = _showOutgoing ? e.outgoing : 0;
            final missed = _showMissed ? e.missed : 0;
            return incoming + outgoing + missed;
          }).reduce((a, b) => a > b ? a : b).toDouble();
    final safeMaxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final selectedDateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final isCompact = MediaQuery.of(context).size.width < 420;

    final barWidth = responsive.screenWidth < 360 ? 16.0 : 22.0;

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
                            color: const Color(0xff0EA5E9).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        color: const Color(0xffF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: Color(0xff64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            selectedDateLabel,
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff334155),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: BarChart(
                            BarChartData(
                              maxY: safeMaxY,
                              barGroups: _buildGroups(
                                displayItems,
                                barWidth: barWidth,
                              ),
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
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
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
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xff64748B),
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
                        label: 'Входящие',
                        enabled: _showIncoming,
                        onTap: () => setState(() => _showIncoming = !_showIncoming),
                      ),
                      _LegendToggle(
                        color: const Color(0xff22B3D6),
                        label: 'Исходящие',
                        enabled: _showOutgoing,
                        onTap: () => setState(() => _showOutgoing = !_showOutgoing),
                      ),
                      _LegendToggle(
                        color: const Color(0xffEF4444),
                        label: 'Пропущенные',
                        enabled: _showMissed,
                        onTap: () => setState(() => _showMissed = !_showMissed),
                      ),
                    ],
                  );

                  final peakText = Text(
                    'Пик: ${_data!.peakHour ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff64748B),
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
    final baseColor = enabled ? color : const Color(0xffCBD5E1);
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
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? const Color(0xff64748B) : const Color(0xff94A3B8),
              fontFamily: 'Golos',
            ),
          ),
        ],
      ),
    );
  }
}
