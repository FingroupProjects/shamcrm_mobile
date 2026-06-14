import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
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
  double? _serverMaxScale;
  String _scaleUnit = 'hours';
  late final AnimationController _needleController;
  late Animation<double> _needleAnimation;

  String get _title => widget.title;

  static const double _previewSpeedHours = 0.41;
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
    AnalyticsChartRequestPolicy.reset(
      AnalyticsChartRequestPolicy.chartIdForState(this),
    );
    _needleController.dispose();
    super.dispose();
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
      final response = await apiService.getLeadProcessSpeedV2();
      final normalizedSpeed = _normalizeSpeedToScale(
        value: response.averageProcessingSpeed,
        from: response.leadsFormat,
        to: response.speedTimeFormat,
      );

      AnalyticsChartRequestPolicy.reset(chartId);
      if (!mounted) return;
      setState(() {
        _speedHours = normalizedSpeed;
        _serverMaxScale = response.badTo;
        _scaleUnit = response.speedTimeFormat;
        _isLoading = false;
      });
      _animateNeedle();
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

  void _animateNeedle() {
    _needleController.stop();
    _needleController.duration = _needleDuration;
    _needleController.forward(from: 0);
  }

  void _showDetails() {
    if (_isLoading || _error != null) return;
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  analyticsText(
                    context,
                    'analytics_average_time',
                    fallback: 'Average time',
                  ),
                  style: TextStyle(
                    fontSize: ResponsiveHelper(context).bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Golos',
                  ),
                ),
                trailing: Text(
                  _formatHoursLabel(_speedHours),
                  style: TextStyle(
                    fontSize: ResponsiveHelper(context).bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: colors.success,
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
    if (_serverMaxScale != null && _serverMaxScale! > 0) {
      return _serverMaxScale!;
    }
    if (hours <= 0) return 10;
    if (hours <= 10) return 10;
    final rounded = (hours / 10).ceil() * 10;
    return rounded < 10 ? 10 : rounded.toDouble();
  }

  String _formatHoursLabel(double value) {
    if (value <= 0) {
      return '0 ${_unitLabel()}';
    }
    return '${value.toStringAsFixed(2)} ${_unitLabel()}';
  }

  String _unitLabel() {
    switch (_scaleUnit) {
      case 'minutes':
        return analyticsText(
          context,
          'analytics_minutes_label',
          fallback: 'minutes',
        );
      case 'days':
        return analyticsText(
          context,
          'analytics_days_label',
          fallback: 'days',
        );
      case 'hours':
      default:
        return analyticsText(
          context,
          'analytics_hours_label',
          fallback: 'hours',
        );
    }
  }

  String _unitSuffix() {
    switch (_scaleUnit) {
      case 'minutes':
        return analyticsText(
          context,
          'analytics_minutes_short_label',
          fallback: ' min',
        );
      case 'days':
        return analyticsText(
          context,
          'analytics_days_short_label',
          fallback: ' d',
        );
      case 'hours':
      default:
        return analyticsText(
          context,
          'analytics_hours_short_label',
          fallback: ' h',
        );
    }
  }

  double _normalizeSpeedToScale({
    required double value,
    required String from,
    required String to,
  }) {
    if (from == to) return value;
    if (from == 'days' && to == 'hours') return value * 24;
    if (from == 'hours' && to == 'days') return value / 24;
    if (from == 'minutes' && to == 'hours') return value / 60;
    if (from == 'hours' && to == 'minutes') return value * 60;
    if (from == 'days' && to == 'minutes') return value * 24 * 60;
    if (from == 'minutes' && to == 'days') return value / (24 * 60);
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final isEmpty = _speedHours <= 0;
    final displaySpeedHours = isEmpty ? _previewSpeedHours : _speedHours;
    final displaySpeedLabel = _formatHoursLabel(displaySpeedHours);
    final maxHours = _computeMaxHours(displaySpeedHours);

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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.speed_rounded,
                    color: colors.iconPrimary,
                    size: 18,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
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
                                            unitSuffix: _unitSuffix(),
                                            labelFontSize:
                                                responsive.smallFontSize,
                                            baseArcColor:
                                                colors.surfaceElevated,
                                            tickMajorColor: colors.borderSubtle,
                                            tickMinorColor: colors.borderSubtle
                                                .withValues(alpha: 0.72),
                                            labelColor: colors.textMuted,
                                            successColor: colors.success,
                                            warningColor: colors.warning,
                                            errorColor: colors.error,
                                            accentColor: colors.buttonPrimaryBg,
                                            accentForegroundColor:
                                                colors.textInverse,
                                            shadowColor: colors.shadow,
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
                                                color: colors.success,
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
  final String unitSuffix;
  final Color baseArcColor;
  final Color tickMajorColor;
  final Color tickMinorColor;
  final Color labelColor;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Color accentColor;
  final Color accentForegroundColor;
  final Color shadowColor;

  SpeedGaugePainter(
      {required this.speedHours,
      this.maxHours = 10,
      this.labelFontSize = 12,
      this.unitSuffix = ' h',
      required this.baseArcColor,
      required this.tickMajorColor,
      required this.tickMinorColor,
      required this.labelColor,
      required this.successColor,
      required this.warningColor,
      required this.errorColor,
      required this.accentColor,
      required this.accentForegroundColor,
      required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);
    final radius = math.min(size.width, size.height) * 0.38;
    final startAngle = math.pi;
    final totalSweep = math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..color = baseArcColor
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
        colors: [
          successColor,
          warningColor,
          errorColor,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    if (sweepAngle > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
      final endCapPaint = Paint()
        ..color = errorColor
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
      ..color = tickMajorColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final minorTickPaint = Paint()
      ..color = tickMinorColor
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
      color: labelColor,
      fontFamily: 'Golos',
    );

    final step = maxHours / divisions;
    for (int i = 0; i <= divisions; i++) {
      final value = step * i;
      final angle = startAngle + totalSweep * (i / divisions);
      final label = i == 0 ? '0' : '${value.toStringAsFixed(0)}$unitSuffix';
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
        ..color = shadowColor.withValues(alpha: 0.16)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      final pointerPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            tickMajorColor.withValues(alpha: 0.9),
            tickMinorColor.withValues(alpha: 0.95),
          ],
        ).createShader(Rect.fromPoints(center, pointerEnd))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, pointerEnd, pointerShadow);
      canvas.drawLine(center, pointerEnd, pointerPaint);
    }

    final shadowPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, shadowPaint);
    canvas.drawCircle(center, 7, Paint()..color = accentColor);
    canvas.drawCircle(center, 3, Paint()..color = accentForegroundColor);
  }

  @override
  bool shouldRepaint(SpeedGaugePainter oldDelegate) {
    return oldDelegate.speedHours != speedHours ||
        oldDelegate.maxHours != maxHours ||
        oldDelegate.unitSuffix != unitSuffix;
  }
}
