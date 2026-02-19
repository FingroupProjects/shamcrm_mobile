import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/source_of_leads_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class SourcesChart extends StatefulWidget {
  const SourcesChart({super.key, required this.title});

  final String title;

  @override
  State<SourcesChart> createState() => _SourcesChartState();
}

class _SourcesChartState extends State<SourcesChart> {
  int _touchedIndex = -1;
  bool _isLoading = true;
  String? _error;
  List<LeadSourceItem> _channels = [];
  String _bestSource = '';
  int _totalSources = 0;

  String get _title => widget.title;

  static final List<LeadSourceItem> _previewSources = [
    LeadSourceItem(name: 'WhatsApp', count: 420),
    LeadSourceItem(name: 'Instagram', count: 210),
    LeadSourceItem(name: 'Telegram', count: 160),
    LeadSourceItem(name: 'Сайт', count: 120),
    LeadSourceItem(name: 'Телефон', count: 80),
    LeadSourceItem(name: 'Прочее', count: 45),
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
      final response = await apiService.getSourceOfLeadsChartV2();

      setState(() {
        _channels = response.activeSources;
        _bestSource = response.bestSource;
        _totalSources =
            response.totalSources > 0 ? response.totalSources : _channels.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  Color _colorForSource(String name) {
    final key = name.toLowerCase();
    if (key.contains('whatsapp')) return const Color(0xff25D366);
    if (key.contains('инстаграм') || key.contains('instagram')) {
      return const Color(0xffE1306C);
    }
    if (key.contains('телеграм') || key.contains('telegram')) {
      return const Color(0xff0088CC);
    }
    if (key.contains('messenger')) return const Color(0xff1877F2);
    if (key.contains('телефон')) return const Color(0xff8BC34A);
    if (key.contains('демо')) return const Color(0xffBCAAA4);
    if (key.contains('личные')) return const Color(0xff5C6BC0);
    if (key.contains('маркет')) return const Color(0xff7E57C2);
    if (key.contains('радио')) return const Color(0xffF59E0B);
    if (key.contains('сайт')) return const Color(0xff94A3B8);
    return const Color(0xff64748B);
  }

  void _showDetails() {
    if (_channels.isEmpty) return;
    final total = _channels.fold<int>(0, (sum, item) => sum + item.count);
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
              Text(_title,
                style: TextStyle(
                  fontSize: ResponsiveHelper(context).titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                  fontFamily: 'Golos',
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _channels.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final channel = _channels[index];
                    final percent =
                        total == 0 ? 0 : (channel.count / total * 100);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colorForSource(channel.name),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        channel.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${channel.count} (${percent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff64748B),
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

  double _centerLabelMaxWidth(double width) {
    final target = width * 0.44;
    return target.clamp(120.0, 180.0);
  }

  String _truncateCalloutLabel(String value, {int maxChars = 20}) {
    final normalized = value.trim();
    if (normalized.length <= maxChars) return normalized;
    return '${normalized.substring(0, maxChars)}...';
  }

  Widget _buildPieCallout(Size size, List<LeadSourceItem> channels) {
    if (_touchedIndex < 0 || _touchedIndex >= channels.length) {
      return const SizedBox.shrink();
    }

    final total = channels.fold<int>(0, (sum, item) => sum + item.count);
    if (total <= 0) return const SizedBox.shrink();

    final selected = channels[_touchedIndex];
    final color = _colorForSource(selected.name);

    const startAngleDeg = -90.0;
    var cumulativeDeg = 0.0;
    for (int i = 0; i < _touchedIndex; i++) {
      cumulativeDeg += (channels[i].count / total) * 360.0;
    }
    final sweepDeg = (selected.count / total) * 360.0;
    final midAngleDeg = startAngleDeg + cumulativeDeg + (sweepDeg / 2);
    final rad = midAngleDeg * math.pi / 180;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide * 0.34;
    final anchor = Offset(
      center.dx + math.cos(rad) * outerRadius,
      center.dy + math.sin(rad) * outerRadius,
    );
    final isRight = math.cos(rad) >= 0;

    final bubbleWidth = _centerLabelMaxWidth(size.width);
    const bubbleHeight = 52.0;
    const outerPadding = 8.0;
    final bubbleTop = anchor.dy >= center.dy
        ? outerPadding
        : (size.height - bubbleHeight - outerPadding);
    final bubbleLeft = isRight
        ? (size.width - bubbleWidth - outerPadding)
        : outerPadding;
    final bubbleCenterY = bubbleTop + (bubbleHeight / 2);

    final radialOut = Offset(
      center.dx + math.cos(rad) * (outerRadius + 12),
      center.dy + math.sin(rad) * (outerRadius + 12),
    );
    final verticalTurn = Offset(
      radialOut.dx,
      bubbleCenterY.clamp(12.0, size.height - 12.0),
    );
    final lineEndX = isRight ? bubbleLeft : (bubbleLeft + bubbleWidth);
    final lineEnd = Offset(lineEndX, bubbleCenterY);

    return Stack(
      children: [
        CustomPaint(
          size: size,
          painter: _PieCalloutPainter(
            color: color,
            anchor: anchor,
            radialOut: radialOut,
            verticalTurn: verticalTurn,
            end: lineEnd,
          ),
        ),
        Positioned(
          left: bubbleLeft,
          top: bubbleTop,
          width: bubbleWidth,
          height: bubbleHeight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0F172A).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _truncateCalloutLabel(selected.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ResponsiveHelper(context).smallFontSize,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff334155),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${selected.count}',
                  style: TextStyle(
                    fontSize: ResponsiveHelper(context).captionFontSize,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'Golos',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty =
        _channels.isEmpty || _channels.every((item) => item.count == 0);
    final displayChannels = isEmpty ? _previewSources : _channels;

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
          // Header
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff10B981), Color(0xff059669)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff10B981).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline,
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
                            const Icon(Icons.error_outline,
                                size: 48, color: Color(0xffEF4444)),
                            SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Color(0xff64748B),
                                fontSize: responsive.bodyFontSize,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadData,
                              child: Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: GestureDetector(
                          onTap: _showDetails,
                          child: Padding(
                            padding: EdgeInsets.all(responsive.cardPadding),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                                return Stack(
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 60,
                                        startDegreeOffset: -90,
                                        pieTouchData: PieTouchData(
                                          touchCallback:
                                              (FlTouchEvent event, pieTouchResponse) {
                                            setState(() {
                                              if (!event.isInterestedForInteractions ||
                                                  pieTouchResponse == null ||
                                                  pieTouchResponse.touchedSection ==
                                                      null) {
                                                _touchedIndex = -1;
                                                return;
                                              }
                                              _touchedIndex = pieTouchResponse
                                                  .touchedSection!
                                                  .touchedSectionIndex;
                                            });
                                          },
                                        ),
                                        sections: List.generate(displayChannels.length,
                                            (index) {
                                          final isTouched = index == _touchedIndex;
                                          final channel = displayChannels[index];
                                          final color = _colorForSource(channel.name);

                                          return PieChartSectionData(
                                            value: channel.count.toDouble(),
                                            title: '',
                                            color: color,
                                            radius: isTouched ? 65 : 60,
                                          );
                                        }),
                                      ),
                                    ),
                                    IgnorePointer(
                                      child: _buildPieCallout(size, displayChannels),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
          ),
          // Footer
          if (!_isLoading && _error == null && _channels.isNotEmpty)
            Container(
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xffE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Топ источник',
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _bestSource.isNotEmpty
                            ? _bestSource
                            : (_channels.isNotEmpty ? _channels.first.name : '-'),
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Всего источников',
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$_totalSources',
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
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
}

class _PieCalloutPainter extends CustomPainter {
  const _PieCalloutPainter({
    required this.color,
    required this.anchor,
    required this.radialOut,
    required this.verticalTurn,
    required this.end,
  });

  final Color color;
  final Offset anchor;
  final Offset radialOut;
  final Offset verticalTurn;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..lineTo(radialOut.dx, radialOut.dy)
      ..lineTo(verticalTurn.dx, verticalTurn.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(path, linePaint);
    canvas.drawCircle(anchor, 3.2, Paint()..color = color);
    canvas.drawCircle(
      anchor,
      5.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PieCalloutPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.anchor != anchor ||
        oldDelegate.radialOut != radialOut ||
        oldDelegate.verticalTurn != verticalTurn ||
        oldDelegate.end != end;
  }
}
