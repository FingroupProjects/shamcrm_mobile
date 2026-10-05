import 'dart:math' as math;

import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:flutter/material.dart';

/// Показывает текст под обязательным полем, прокручивает к нему и чуть трясёт.
class RequiredFieldSlot extends StatefulWidget {
  const RequiredFieldSlot({
    super.key,
    required this.invalid,
    required this.focus,
    required this.pulse,
    required this.message,
    required this.child,
    this.showCaption = true,
  });

  final bool invalid;
  final bool focus;
  final int pulse;
  final String message;
  final Widget child;

  /// false, если само поле уже пишет текст ошибки.
  final bool showCaption;

  @override
  State<RequiredFieldSlot> createState() => _RequiredFieldSlotState();
}

class _RequiredFieldSlotState extends State<RequiredFieldSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(RequiredFieldSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldShake =
        widget.invalid && widget.pulse != oldWidget.pulse;
    if (!shouldShake) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // К первому пустому полю прокручиваем. Трясутся все пустые.
      if (widget.focus) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.2,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
      _shake.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _shake,
          child: widget.child,
          builder: (context, child) {
            final t = _shake.value;
            final dx = math.sin(t * math.pi * 6) * (1 - t) * 7;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
        ),
        if (widget.invalid && widget.showCaption && widget.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.message,
              style: TextStyle(
                color: AppFieldStyle.borderColor(context, hasError: true),
                fontSize: 12,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
