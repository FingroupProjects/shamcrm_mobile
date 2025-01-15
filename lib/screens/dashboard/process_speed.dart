import 'dart:math' as math;
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProcessSpeedGauge extends StatefulWidget {
  const ProcessSpeedGauge({Key? key}) : super(key: key);

  @override
  State<ProcessSpeedGauge> createState() => _ProcessSpeedGaugeState();
}

class _ProcessSpeedGaugeState extends State<ProcessSpeedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _initialAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _initialAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProcessSpeedBloc, ProcessSpeedState>(
      listener: (context, state) {
        if (state is ProcessSpeedLoaded) {
          _animationController.forward(from: 0.0);
        } else if (state is ProcessSpeedError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProcessSpeedLoaded) {
          return _buildGauge(state);
        } else if (state is ProcessSpeedLoading) {}
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGauge(ProcessSpeedLoaded state) {
    final bool hasNoData = state.processSpeedData.speed == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Скорость обработки',
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Gilroy",
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                CustomPaint(
                  painter: GaugePainter(
                    speed: state.processSpeedData.speed,
                    animation: _animation,
                    initialAnimation: _initialAnimation,
                    hasNoData: hasNoData,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasNoData)
                          const Text(
                            'Нет данных для отображения',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Gilroy",
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          )
                        else ...[
                          Text(
                            '${state.processSpeedData.speed}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontFamily: "Gilroy",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Gilroy",
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
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

class GaugePainter extends CustomPainter {
  final double speed;
  final Animation<double> animation;
  final Animation<double> initialAnimation;
  final bool hasNoData;

  GaugePainter({
    required this.speed,
    required this.animation,
    required this.initialAnimation,
    required this.hasNoData,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.25;

    const startAngle = 135 * math.pi / 180;
    const endAngle = -45 * math.pi / 180;
    const totalAngle = math.pi * 1.5;

    final colors = hasNoData
        ? List.filled(
            3, const Color.fromARGB(255, 210, 210, 210)) // Серый цвет для фона
        : [
            const Color(0xFF27a945),
            const Color(0xFF3935E7),
            const Color(0xFFc30202),
          ];

    final double sweepAnglePerSection = totalAngle / 3;

    // Draw the main arc segments
    for (int i = 0; i < 3; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.butt;

      final segmentStartAngle = startAngle + (i * sweepAnglePerSection);

      // Draw the main segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segmentStartAngle,
        sweepAnglePerSection,
        false,
        paint,
      );

      if (!hasNoData) {
        // Draw dividers within each segment
        final dividerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        // Draw 2 additional dividers within each segment
        for (int j = 1; j <= 2; j++) {
          final dividerAngle =
              segmentStartAngle + (sweepAnglePerSection * j / 2);
          final outerPoint = Offset(
            center.dx + (radius + 10) * math.cos(dividerAngle),
            center.dy + (radius + 10) * math.sin(dividerAngle),
          );

          final innerPoint = Offset(
            center.dx + (radius - 10) * math.cos(dividerAngle),
            center.dy + (radius - 10) * math.sin(dividerAngle),
          );

          canvas.drawLine(innerPoint, outerPoint, dividerPaint);
        }

        // Draw segment boundary divider
        if (i < 3) {
          final dividerAngle = segmentStartAngle + sweepAnglePerSection;
          final outerPoint = Offset(
            center.dx + (radius + 10) * math.cos(dividerAngle),
            center.dy + (radius + 10) * math.sin(dividerAngle),
          );

          final innerPoint = Offset(
            center.dx + (radius - 10) * math.cos(dividerAngle),
            center.dy + (radius - 10) * math.sin(dividerAngle),
          );

          canvas.drawLine(innerPoint, outerPoint, dividerPaint);
        }
      }
    }

    // Draw time markers
    if (!hasNoData) {
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      final times = [
        '00:00',
        '01:00',
        '02:00',
        '03:00',
        '04:00',
        '05:00',
        '06:00',
      ];

      for (int i = 0; i < times.length; i++) {
        final angle = startAngle + (totalAngle * i / 6);
        final markerRadius = radius + 25;

        textPainter.text = TextSpan(
          text: times[i],
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
          ),
        );

        textPainter.layout();

        final x =
            center.dx + markerRadius * math.cos(angle) - textPainter.width / 2;
        final y =
            center.dy + markerRadius * math.sin(angle) - textPainter.height / 2;

        textPainter.paint(canvas, Offset(x, y));
      }

      // Draw animated needle only if there is data
      if (!hasNoData) {
        final needleLength = radius - 10;
        final normalizedSpeed = math.min(math.max(speed, 0), 6) / 6;
        final targetAngle = startAngle + (totalAngle * normalizedSpeed);
        final currentAngle =
            startAngle + (targetAngle - startAngle) * animation.value;

        final needlePaint = Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawLine(
          center,
          Offset(
            center.dx + needleLength * math.cos(currentAngle),
            center.dy + needleLength * math.sin(currentAngle),
          ),
          needlePaint,
        );

        final centerPaint = Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.fill;

        canvas.drawCircle(center, 4, centerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.speed != speed ||
        oldDelegate.animation != animation ||
        oldDelegate.initialAnimation != initialAnimation ||
        oldDelegate.hasNoData != hasNoData;
  }
}
