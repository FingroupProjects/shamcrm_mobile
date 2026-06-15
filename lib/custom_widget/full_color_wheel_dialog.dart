import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Модалка с цветовым кругом на 360° (миллионы оттенков).
/// Пользователь перетаскивает указатель или тапает — выбирает цвет.
/// По нажатию "Применить" — возвращает выбранный цвет через Navigator.pop.
class FullColorWheelDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const FullColorWheelDialog({
    super.key,
    this.initialColor = const Color(0xFF0EA5E9),
    this.title = 'Выберите цвет',
  });

  static Future<Color?> show(BuildContext context, {Color? initialColor}) {
    return showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FullColorWheelDialog(
        initialColor: initialColor ?? const Color(0xFF0EA5E9),
      ),
    );
  }

  @override
  State<FullColorWheelDialog> createState() => _FullColorWheelDialogState();
}

class _FullColorWheelDialogState extends State<FullColorWheelDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;
  late Color _selectedColor;

  Offset _pointer = Offset.zero;

  double _saturationSlider = 1.0;
  double _lightnessSlider = 0.55;

  static const double _wheelSize = 200;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
    _selectedColor = widget.initialColor;
    _saturationSlider = _saturation.clamp(0.0, 1.0);
    _lightnessSlider = _lightness.clamp(0.0, 1.0);
    _updatePointer();
  }

  void _updatePointer() {
    final radius = _wheelSize / 2;
    final angle = (_hue / 360) * 2 * math.pi - math.pi;
    final distance = _saturationSlider * radius;
    _pointer = Offset(
      radius + math.cos(angle) * distance,
      radius + math.sin(angle) * distance,
    );
  }

  void _applyHsl() {
    setState(() {
      _selectedColor =
          HSLColor.fromAHSL(1, _hue, _saturation, _lightnessSlider).toColor();
    });
  }

  void _updateFromPointer(Offset localPosition) {
    final center = Offset(_wheelSize / 2, _wheelSize / 2);
    final radius = _wheelSize / 2;
    final delta = localPosition - center;
    final distance = delta.distance.clamp(0.0, radius);
    if (distance < 2) return;

    final angle = (math.atan2(delta.dy, delta.dx) + math.pi) % (2 * math.pi);
    _hue = (angle / (2 * math.pi) * 360) % 360;
    _saturation = (distance / radius).clamp(0.0, 1.0);
    _saturationSlider = _saturation;

    _applyHsl();
    _updatePointer();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // заголовок
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // цветовой круг (уменьшен)
              GestureDetector(
                onPanStart: (d) => _updateFromPointer(d.localPosition),
                onPanUpdate: (d) => _updateFromPointer(d.localPosition),
                onPanEnd: (_) {},
                onTapDown: (d) => _updateFromPointer(d.localPosition),
                child: CustomPaint(
                  size: const Size(_wheelSize, _wheelSize),
                  painter: _WheelPainter(
                    hue: _hue,
                    saturation: _saturationSlider,
                    lightness: _lightnessSlider,
                    pointer: _pointer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // превью цвета и hex
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'HSL ${_hue.round()}° ${(_saturationSlider * 100).round()}% ${(_lightnessSlider * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ползунки
              _SliderRow(
                label: 'Насыщенность',
                value: _saturationSlider,
                onChanged: (v) {
                  setState(() {
                    _saturationSlider = v;
                    _saturation = v;
                  });
                  _applyHsl();
                  _updatePointer();
                },
                isDark: isDark,
              ),
              _SliderRow(
                label: 'Светлота',
                value: _lightnessSlider,
                onChanged: (v) {
                  setState(() => _lightnessSlider = v);
                  _applyHsl();
                  _updatePointer();
                },
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              // кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        foregroundColor:
                            isDark ? Colors.white70 : Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selectedColor),
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor:
                            _lightnessSlider > 0.5 ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Применить',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double lightness;
  final Offset pointer;

  _WheelPainter({
    required this.hue,
    required this.saturation,
    required this.lightness,
    required this.pointer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const segments = 360;
    for (int i = 0; i < segments; i++) {
      final sweep = 2 * math.pi / segments;
      final start = (i * sweep) - math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius
        ..shader = SweepGradient(
          colors: [
            HSLColor.fromAHSL(1, (i * 360 / segments), saturation, lightness)
                .toColor(),
            HSLColor.fromAHSL(
                    1, ((i + 1) * 360 / segments), saturation, lightness)
                .toColor(),
          ],
          stops: const [0, 1],
        ).createShader(rect);
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    // указатель
    final pFill = Paint()..color = Colors.white;
    canvas.drawCircle(pointer, 8, pFill);
    canvas.drawCircle(
      pointer,
      10,
      Paint()
        ..color = HSLColor.fromAHSL(1, hue, saturation, lightness).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.hue != hue ||
      old.saturation != saturation ||
      old.lightness != lightness ||
      old.pointer != pointer;
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isDark;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
