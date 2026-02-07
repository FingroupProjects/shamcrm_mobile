import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'dart:math' as math;

class SpeedGauge extends StatefulWidget {
  const SpeedGauge({super.key});

  @override
  State<SpeedGauge> createState() => _SpeedGaugeState();
}

class _SpeedGaugeState extends State<SpeedGauge> {
  bool _isLoading = true;
  String? _error;
  double _speedHours = 0.0;

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
      final response = await apiService.getProcessSpeedData();

      setState(() {
        _speedHours = response.speed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

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
                      colors: [Color(0xffEC4899), Color(0xffDB2777)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffEC4899).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.speed,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Скорость обработки лидов',
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff0F172A),
                      fontFamily: 'Golos',
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
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xffEC4899),
                    ),
                  )
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
                    : Padding(
                        padding: EdgeInsets.all(responsive.cardPadding),
                        child: CustomPaint(
                          painter: SpeedGaugePainter(
                            speedHours: _speedHours,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 130),
                                Text(
                                  '${_speedHours.toStringAsFixed(1)} ч',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff1E2E52),
                                    fontFamily: 'Golos',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Среднее время',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xff64748B),
                                    fontFamily: 'Golos',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
          // Footer
          if (!_isLoading && _error == null)
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
                        'Среднее время',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_speedHours.toStringAsFixed(1)} ч',
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
                        'Лучшее время',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_speedHours * 0.6).toStringAsFixed(1)} ч',
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

class SpeedGaugePainter extends CustomPainter {
  final double speedHours;

  SpeedGaugePainter({required this.speedHours});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final radius = size.width * 0.35;

    // Background arc
    final backgroundPaint = Paint()
      ..color = const Color(0xffF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start from left (180 degrees)
      math.pi, // Sweep 180 degrees
      false,
      backgroundPaint,
    );

    // Gradient arc (progress)
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xffEF4444), Color(0xffF59E0B), Color(0xff10B981)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Calculate progress (0-24 hours mapped to 0-180 degrees)
    final maxHours = 24.0;
    final normalizedSpeed = (speedHours / maxHours).clamp(0.0, 1.0);
    final sweepAngle = math.pi * normalizedSpeed;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      gradientPaint,
    );

    // Pointer
    final pointerAngle = math.pi + sweepAngle;
    final pointerLength = radius + 10;
    final pointerEnd = Offset(
      center.dx + pointerLength * math.cos(pointerAngle),
      center.dy + pointerLength * math.sin(pointerAngle),
    );

    final pointerPaint = Paint()
      ..color = const Color(0xff1E2E52)
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;

    // Draw pointer with shadow
    canvas.drawCircle(
        center, 8, pointerPaint..color = Colors.black.withValues(alpha: 0.2));
    canvas.drawCircle(center, 6, pointerPaint..color = const Color(0xff1E2E52));
    canvas.drawLine(center, pointerEnd, pointerPaint..strokeWidth = 3);

    // Center circle
    final centerCirclePaint = Paint()
      ..color = const Color(0xff1E2E52)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 12, centerCirclePaint);
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(SpeedGaugePainter oldDelegate) {
    return oldDelegate.speedHours != speedHours;
  }
}
