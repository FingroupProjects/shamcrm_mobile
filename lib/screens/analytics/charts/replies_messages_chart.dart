import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/replies_messages_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class RepliesMessagesChart extends StatefulWidget {
  const RepliesMessagesChart({super.key, required this.title});

  final String title;

  @override
  State<RepliesMessagesChart> createState() => _RepliesMessagesChartState();
}

class _RepliesMessagesChartState extends State<RepliesMessagesChart> {
  bool _isLoading = true;
  String? _error;
  RepliesToMessagesResponse? _data;
  bool _showReceived = true;
  bool _showAnswered = true;
  bool _showUnanswered = true;

  String get _title => widget.title;

  static final List<ReplyChannelStats> _previewChannels = [
    ReplyChannelStats(
        channelName: 'instagram',
        sentMessages: 298,
        receivedMessages: 312,
        unansweredChats: 14),
    ReplyChannelStats(
        channelName: 'whatsapp',
        sentMessages: 274,
        receivedMessages: 287,
        unansweredChats: 13),
    ReplyChannelStats(
        channelName: 'telegram',
        sentMessages: 189,
        receivedMessages: 198,
        unansweredChats: 9),
    ReplyChannelStats(
        channelName: 'email',
        sentMessages: 138,
        receivedMessages: 145,
        unansweredChats: 7),
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
      final response = await apiService.getRepliesToMessagesChartV2();

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
    final items = _data?.byChannel ?? [];
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
                        item.channelName,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        'Получено: ${item.receivedMessages}, Отвечено: ${item.sentMessages}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        'Без ответа: ${item.unansweredChats}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffEF4444),
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

  List<BarChartGroupData> _buildGroups(List<ReplyChannelStats> items) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final rods = <BarChartRodData>[];
      if (_showReceived) {
        rods.add(
          BarChartRodData(
            toY: item.receivedMessages.toDouble(),
            color: const Color(0xff6366F1),
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }
      if (_showAnswered) {
        rods.add(
          BarChartRodData(
            toY: item.sentMessages.toDouble(),
            color: const Color(0xff10B981),
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }
      if (_showUnanswered) {
        rods.add(
          BarChartRodData(
            toY: item.unansweredChats.toDouble(),
            color: const Color(0xffEF4444),
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }
      if (rods.isEmpty) {
        rods.add(
          BarChartRodData(
            toY: 0.001,
            color: Colors.transparent,
            width: 10,
          ),
        );
      }
      return BarChartGroupData(
        x: index,
        barRods: rods,
        barsSpace: 3,
      );
    });
  }

  String _shortLabel(String value) {
    if (value.length <= 10) return value;
    return '${value.substring(0, 10)}...';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final items = _data?.byChannel ?? [];
    final totals = _data?.totals;
    final isEmpty = items.isEmpty ||
        ((totals?.receivedMessages ?? 0) +
                (totals?.sentMessages ?? 0) +
                (totals?.unansweredChats ?? 0)) ==
            0;
    final displayItems = isEmpty ? _previewChannels : items;
    final maxValue = displayItems.isEmpty
        ? 1
        : displayItems
            .map((e) {
              final received = _showReceived ? e.receivedMessages : 0;
              final answered = _showAnswered ? e.sentMessages : 0;
              final unanswered = _showUnanswered ? e.unansweredChats : 0;
              return [received, answered, unanswered]
                  .reduce((a, b) => a > b ? a : b);
            })
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
                    Icons.mark_chat_read,
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
                  icon:
                      Icon(Icons.crop_free, color: Color(0xff64748B), size: 22),
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
                          child: BarChart(
                            BarChartData(
                              maxY: maxValue * 1.2,
                              barGroups: _buildGroups(displayItems),
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
                                    final item = displayItems[group.x.toInt()];
                                    final label = switch (rodIndex) {
                                      0 => 'Получено',
                                      1 => 'Отвечено',
                                      _ => 'Без ответа',
                                    };
                                    final value = switch (rodIndex) {
                                      0 => item.receivedMessages,
                                      1 => item.sentMessages,
                                      _ => item.unansweredChats,
                                    };

                                    return BarTooltipItem(
                                      '${item.channelName}\n$label: $value',
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
                                    reservedSize: 80,
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
                                            _shortLabel(displayItems[index]
                                                .channelName),
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
                _LegendToggleDot(
                  color: const Color(0xff6366F1),
                  label: 'Получено',
                  enabled: _showReceived,
                  onTap: () => setState(() => _showReceived = !_showReceived),
                ),
                const SizedBox(width: 12),
                _LegendToggleDot(
                  color: const Color(0xff10B981),
                  label: 'Отвечено',
                  enabled: _showAnswered,
                  onTap: () => setState(() => _showAnswered = !_showAnswered),
                ),
                const SizedBox(width: 12),
                _LegendToggleDot(
                  color: const Color(0xffEF4444),
                  label: 'Без ответа',
                  enabled: _showUnanswered,
                  onTap: () =>
                      setState(() => _showUnanswered = !_showUnanswered),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendToggleDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _LegendToggleDot({
    required this.color,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = enabled ? color : const Color(0xffCBD5E1);
    final textColor =
        enabled ? const Color(0xff64748B) : const Color(0xff94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper(context).smallFontSize,
              color: textColor,
              fontFamily: 'Golos',
            ),
          ),
        ],
      ),
    );
  }
}
