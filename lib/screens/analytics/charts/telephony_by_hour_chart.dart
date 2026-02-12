import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/telephony_by_hour_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class TelephonyByHourChart extends StatefulWidget {
  const TelephonyByHourChart({super.key});

  @override
  State<TelephonyByHourChart> createState() => _TelephonyByHourChartState();
}

class _TelephonyByHourChartState extends State<TelephonyByHourChart> {
  bool _isLoading = true;
  String? _error;
  TelephonyByHourResponse? _data;

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
      final response = await apiService.getTelephonyByHourChartV2();

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
                  const Expanded(
                    child: Text(
                      'Аналитика звонков по часам',
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

  List<BarChartGroupData> _buildGroups(List<TelephonyHourItem> items) {
    return List.generate(items.length, (index) {
      final item = items[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.incoming.toDouble(),
            color: const Color(0xff10B981),
            width: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          BarChartRodData(
            toY: item.outgoing.toDouble(),
            color: const Color(0xff6366F1),
            width: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          BarChartRodData(
            toY: item.missed.toDouble(),
            color: const Color(0xffEF4444),
            width: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
        barsSpace: 2,
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
        ? 1
        : displayItems
            .map((e) => e.incoming + e.outgoing + e.missed)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

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
                    'Аналитика звонков по часам',
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
                  icon: const Icon(Icons.more_vert, color: Color(0xff64748B)),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff0EA5E9),
                    ),
                  )
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
                              maxY: maxValue * 1.2,
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
              child: Row(
                children: [
                  const _LegendDot(color: Color(0xff10B981), label: 'Входящие'),
                  const SizedBox(width: 12),
                  const _LegendDot(color: Color(0xff6366F1), label: 'Исходящие'),
                  const SizedBox(width: 12),
                  const _LegendDot(color: Color(0xffEF4444), label: 'Пропущенные'),
                  const Spacer(),
                  Text(
                    'Пик: ${_data!.peakHour ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff64748B),
                      fontFamily: 'Golos',
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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff64748B),
            fontFamily: 'Golos',
          ),
        ),
      ],
    );
  }
}
