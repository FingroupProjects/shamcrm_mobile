import 'dart:math' as math;

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Кнопка AI-генерации рядом с «прикрепить».
/// В покое — статичная звезда. При ожидании ответа искры мерцают вразнобой,
/// как будто ИИ «думает» (без вращения).
class ChatAiGenerateButton extends StatefulWidget {
  const ChatAiGenerateButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<ChatAiGenerateButton> createState() => _ChatAiGenerateButtonState();
}

class _ChatAiGenerateButtonState extends State<ChatAiGenerateButton>
    with SingleTickerProviderStateMixin {
  // Один контроллер крутит общий цикл, каждая искра берёт свою фазу.
  late final AnimationController _controller;

  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _cyan = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _syncLoading(widget.isLoading);
  }

  @override
  void didUpdateWidget(ChatAiGenerateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      _syncLoading(widget.isLoading);
    }
  }

  void _syncLoading(bool loading) {
    if (loading) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)?.translate('ai_generation') ??
        'AI-генерация';

    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: widget.onPressed,
        iconSize: 22,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        icon: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(
                painter: _SparklePainter(
                  progress: _controller.value,
                  isLoading: widget.isLoading,
                  colors: const [_violet, _blue, _cyan],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Описание одной искры: центр, базовый размер и сдвиг фазы мерцания.
class _Sparkle {
  const _Sparkle(this.center, this.radius, this.phase);

  final Offset center; // 0..1 в пределах квадрата
  final double radius; // 0..1 доля от стороны
  final double phase; // сдвиг мерцания, 0..1
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.progress,
    required this.isLoading,
    required this.colors,
  });

  final double progress;
  final bool isLoading;
  final List<Color> colors;

  // Раскладка искр повторяет иконку ИИ: одна большая и две маленькие.
  static const List<_Sparkle> _sparkles = [
    _Sparkle(Offset(0.40, 0.55), 0.30, 0.0),
    _Sparkle(Offset(0.74, 0.26), 0.16, 0.35),
    _Sparkle(Offset(0.76, 0.78), 0.14, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(Offset.zero & size);

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final sparkle in _sparkles) {
      // Каждая искра пульсирует по синусу со своей фазой.
      final double twinkle;
      if (isLoading) {
        final t = (progress + sparkle.phase) % 1.0;
        // 0.55..1.0 — искра не гаснет полностью, но заметно «дышит».
        twinkle = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
      } else {
        twinkle = 1.0;
      }

      final center = Offset(
        sparkle.center.dx * size.width,
        sparkle.center.dy * size.height,
      );
      final radius = sparkle.radius * size.width * twinkle;

      canvas.drawPath(_starPath(center, radius), paint);
    }
  }

  /// Четырёхлучевая «искра» с вогнутыми боками (как sparkle-иконка).
  Path _starPath(Offset center, double radius) {
    final path = Path();
    final inner = radius * 0.34; // насколько «втянуты» бока между лучами
    for (int i = 0; i < 4; i++) {
      final outerAngle = (math.pi / 2) * i - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 4;

      final outer = Offset(
        center.dx + radius * math.cos(outerAngle),
        center.dy + radius * math.sin(outerAngle),
      );
      final side = Offset(
        center.dx + inner * math.cos(innerAngle),
        center.dy + inner * math.sin(innerAngle),
      );

      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(side.dx, side.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isLoading != isLoading;
  }
}
