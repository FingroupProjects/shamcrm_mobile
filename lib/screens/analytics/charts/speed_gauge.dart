import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';
import 'dart:math' as math;

class SpeedGauge extends StatefulWidget {
  const SpeedGauge({super.key, required this.title});

  final String title;

  @override
  State<SpeedGauge> createState() => _SpeedGaugeState();
}

class _SpeedGaugeState extends State<SpeedGauge>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  double _speedHours = 0.0;
  String _speedLabel = '0 ч';
  late final AnimationController _needleController;
  late Animation<double> _needleAnimation;

  String get _title => widget.title;

  static const double _previewSpeedHours = 0.41;
  static const String _previewSpeedLabel = '0.41 часов';

  static const Duration _needleDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _needleController = AnimationController(vsync: this);
    _needleAnimation =
        CurvedAnimation(parent: _needleController, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _needleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getLeadProcessSpeedV2();
      final speedHours = response.leadsFormat == 'days'
          ? response.averageProcessingSpeed * 24
          : response.averageProcessingSpeed;

      setState(() {
        _speedHours = speedHours;
        _speedLabel = response.displayText;
        _isLoading = false;
      });
      _animateNeedle();
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  void _animateNeedle() {
    _needleController.stop();
    _needleController.duration = _needleDuration;
    _needleController.forward(from: 0);
  }

  void _showDetails() {
    if (_isLoading || _error != null) return;
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
              Text(
                _title,
                style: TextStyle(
                  fontSize: ResponsiveHelper(context).titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                  fontFamily: 'Golos',
                ),
              ),
              SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Среднее время',
                  style: TextStyle(
                    fontSize: ResponsiveHelper(context).bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                    fontFamily: 'Golos',
                  ),
                ),
                trailing: Text(
                  _speedLabel,
                  style: TextStyle(
                    fontSize: ResponsiveHelper(context).bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffEC4899),
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

  double _computeMaxHours(double hours) {
    if (hours <= 0) return 10;
    if (hours <= 10) return 10;
    final rounded = (hours / 10).ceil() * 10;
    return rounded < 10 ? 10 : rounded.toDouble();
  }

  String _formatHoursLabel(double hours) {
    if (hours <= 0) {
      return '0 часов';
    }
    return '${hours.toStringAsFixed(2)} часов';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty = _speedHours <= 0;
    final displaySpeedHours = isEmpty ? _previewSpeedHours : _speedHours;
    final displaySpeedLabel =
        isEmpty ? _previewSpeedLabel : _formatHoursLabel(_speedHours);
    final maxHours = _computeMaxHours(displaySpeedHours);

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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.speed_rounded,
                    color: Color(0xff0F172A),
                    size: 18,
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
                  icon: Icon(Icons.crop_free,
                      color: Color(0xff64748B), size: 22),
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
          // Gauge
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
                                return AnimatedBuilder(
                                  animation: _needleAnimation,
                                  builder: (context, child) {
                                    final animatedSpeed = displaySpeedHours *
                                        _needleAnimation.value;
                                    return Stack(
                                      children: [
                                        CustomPaint(
                                          size: size,
                                          painter: SpeedGaugePainter(
                                            speedHours: animatedSpeed,
                                            maxHours: maxHours,
                                            labelFontSize:
                                                responsive.smallFontSize,
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 12,
                                          child: Center(
                                            child: Text(
                                              displaySpeedLabel,
                                              style: TextStyle(
                                                fontSize:
                                                    responsive.largeFontSize,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xff22C55E),
                                                fontFamily: 'Golos',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class SpeedGaugePainter extends CustomPainter {
  final double speedHours;
  final double maxHours;
  final double labelFontSize;

  SpeedGaugePainter(
      {required this.speedHours, this.maxHours = 10, this.labelFontSize = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);
    final radius = math.min(size.width, size.height) * 0.38;
    final startAngle = math.pi;
    final totalSweep = math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..color = const Color(0xff334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, totalSweep, false, basePaint);

    final normalizedSpeed = (speedHours / maxHours).clamp(0.0, 1.0);
    final sweepAngle = totalSweep * normalizedSpeed;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: const [
          Color(0xff22C55E),
          Color(0xffF59E0B),
          Color(0xffEF4444),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    if (sweepAngle > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
      final endCapPaint = Paint()
        ..color = const Color(0xffEF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      final capSweep = math.min(0.03, sweepAngle);
      canvas.drawArc(
        rect,
        startAngle + sweepAngle - capSweep,
        capSweep,
        false,
        endCapPaint,
      );
    }

    final majorTickPaint = Paint()
      ..color = const Color(0xffE2E8F0)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = const Color(0xffCBD5E1)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const divisions = 10;
    final steps = divisions * 2;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = startAngle + totalSweep * t;
      final isMajor = i % 2 == 0;
      final tickLength = isMajor ? 10.0 : 6.0;
      final tickStart = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      final tickEnd = Offset(
        center.dx + (radius - 8 + tickLength) * math.cos(angle),
        center.dy + (radius - 8 + tickLength) * math.sin(angle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        isMajor ? majorTickPaint : minorTickPaint,
      );
    }

    final labelStyle = TextStyle(
      fontSize: labelFontSize,
      fontWeight: FontWeight.w600,
      color: Color(0xff94A3B8),
      fontFamily: 'Golos',
    );

    final step = maxHours / divisions;
    for (int i = 0; i <= divisions; i++) {
      final value = step * i;
      final angle = startAngle + totalSweep * (i / divisions);
      final label = i == 0 ? '0' : '${value.toStringAsFixed(0)}ч';
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelOffset = Offset(
        center.dx + (radius + 28) * math.cos(angle) - textPainter.width / 2,
        center.dy + (radius + 28) * math.sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, labelOffset);
    }

    if (speedHours > 0) {
      final pointerAngle = startAngle + sweepAngle;
      final pointerLength = radius - 12;
      final pointerEnd = Offset(
        center.dx + pointerLength * math.cos(pointerAngle),
        center.dy + pointerLength * math.sin(pointerAngle),
      );
      final pointerShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      final pointerPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE5E7EB), Color(0xFFCBD5E1)],
        ).createShader(Rect.fromPoints(center, pointerEnd))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, pointerEnd, pointerShadow);
      canvas.drawLine(center, pointerEnd, pointerPaint);
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, shadowPaint);
    canvas.drawCircle(center, 7, Paint()..color = const Color(0xff6366F1));
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(SpeedGaugePainter oldDelegate) {
    return oldDelegate.speedHours != speedHours;
  }
}
