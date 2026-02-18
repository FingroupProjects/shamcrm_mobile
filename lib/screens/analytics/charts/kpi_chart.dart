import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class KpiChart extends StatefulWidget {
  const KpiChart({super.key, required this.title});

  final String title;

  @override
  State<KpiChart> createState() => _KpiChartState();
}

class _KpiChartState extends State<KpiChart> {
  int _touchedIndex = -1;
  bool _isLoading = true;
  String? _error;
  List<int> _taskData = [];
  double _completionRate = 0.0;
  int _totalTasks = 0;

  String get _title => widget.title;

  static const List<int> _previewTaskData = [35, 48, 129];

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
      final response = await apiService.getTaskChartDataV2();

      setState(() {
        _taskData = response.data;
        _completionRate = response.completionRate;
        _totalTasks = response.total;
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
    if (_total == 0) return;
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                  fontFamily: 'Golos',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Выполнено',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                    fontFamily: 'Golos',
                  ),
                ),
                trailing: Text(
                  '$_completed',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff10B981),
                    fontFamily: 'Golos',
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'В работе',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                    fontFamily: 'Golos',
                  ),
                ),
                trailing: Text(
                  '$_inProgress',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffF59E0B),
                    fontFamily: 'Golos',
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Просрочено',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                    fontFamily: 'Golos',
                  ),
                ),
                trailing: Text(
                  '$_overdue',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffEF4444),
                    fontFamily: 'Golos',
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Всего задач',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                    fontFamily: 'Golos',
                  ),
                ),
                trailing: Text(
                  '$_total',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff64748B),
                    fontFamily: 'Golos',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int get _total => _totalTasks > 0
      ? _totalTasks
      : (_taskData.isEmpty
          ? 0
          : _taskData.reduce((a, b) => a + b));
  int get _completed =>
      _taskData.isNotEmpty && _taskData.length > 2 ? _taskData[2] : 0;
  int get _inProgress =>
      _taskData.isNotEmpty && _taskData.length > 1 ? _taskData[1] : 0;
  int get _overdue => _taskData.isNotEmpty ? _taskData[0] : 0;

  double _calloutMaxWidth(double width) {
    final target = width * 0.44;
    return target.clamp(120.0, 180.0);
  }

  String _truncateCalloutLabel(String value, {int maxChars = 20}) {
    final normalized = value.trim();
    if (normalized.length <= maxChars) return normalized;
    return '${normalized.substring(0, maxChars)}...';
  }

  Widget _buildPieCallout(
    Size size,
    List<_KpiSlice> slices,
  ) {
    if (_touchedIndex < 0 || _touchedIndex >= slices.length) {
      return const SizedBox.shrink();
    }

    final total = slices.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) return const SizedBox.shrink();

    final selected = slices[_touchedIndex];

    const startAngleDeg = -90.0;
    var cumulativeDeg = 0.0;
    for (int i = 0; i < _touchedIndex; i++) {
      cumulativeDeg += (slices[i].value / total) * 360.0;
    }
    final sweepDeg = (selected.value / total) * 360.0;
    final midAngleDeg = startAngleDeg + cumulativeDeg + (sweepDeg / 2);
    final rad = midAngleDeg * math.pi / 180;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide * 0.32;
    final anchor = Offset(
      center.dx + math.cos(rad) * outerRadius,
      center.dy + math.sin(rad) * outerRadius,
    );
    final isRight = math.cos(rad) >= 0;

    final bubbleWidth = _calloutMaxWidth(size.width);
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
          painter: _KpiCalloutPainter(
            color: selected.color,
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
              border: Border.all(color: selected.color.withValues(alpha: 0.35)),
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
                    color: selected.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _truncateCalloutLabel(selected.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff334155),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${selected.value.toInt()}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected.color,
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
    final isEmpty = _total == 0;
    final displayTaskData = isEmpty ? _previewTaskData : _taskData;
    final displayCompleted =
        displayTaskData.isNotEmpty && displayTaskData.length > 2
            ? displayTaskData[2]
            : 0;
    final displayInProgress =
        displayTaskData.isNotEmpty && displayTaskData.length > 1
            ? displayTaskData[1]
            : 0;
    final displayOverdue =
        displayTaskData.isNotEmpty ? displayTaskData[0] : 0;
    final slices = <_KpiSlice>[
      _KpiSlice(
        label: 'Выполнено',
        value: displayCompleted.toDouble(),
        color: const Color(0xff10B981),
      ),
      _KpiSlice(
        label: 'В работе',
        value: displayInProgress.toDouble(),
        color: const Color(0xffF59E0B),
      ),
      _KpiSlice(
        label: 'Просрочено',
        value: displayOverdue.toDouble(),
        color: const Color(0xffEF4444),
      ),
    ];

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
                      colors: [Color(0xff6366F1), Color(0xff4F46E5)],
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
                  child: const Icon(
                    Icons.task_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                  icon: const Icon(Icons.crop_free, color: Color(0xff64748B), size: 22),
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
            height: responsive.smallChartHeight,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Color(0xffEF4444)),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 14,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Повторить'),
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
                                        centerSpaceRadius: 50,
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
                                        sections: List.generate(slices.length, (index) {
                                          final isTouched = index == _touchedIndex;
                                          final slice = slices[index];
                                          return PieChartSectionData(
                                            value: slice.value,
                                            title: '',
                                            color: slice.color,
                                            radius: isTouched ? 55 : 50,
                                          );
                                        }),
                                      ),
                                    ),
                                    IgnorePointer(
                                      child: _buildPieCallout(size, slices),
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
          if (!_isLoading && _error == null && _total > 0)
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
                      const Text(
                        'Всего задач',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_total',
                        style: const TextStyle(
                          fontSize: 20,
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
                      const Text(
                        'Выполнено',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_completionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 20,
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

class _KpiSlice {
  const _KpiSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _KpiCalloutPainter extends CustomPainter {
  const _KpiCalloutPainter({
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
  bool shouldRepaint(covariant _KpiCalloutPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.anchor != anchor ||
        oldDelegate.radialOut != radialOut ||
        oldDelegate.verticalTurn != verticalTurn ||
        oldDelegate.end != end;
  }
}
