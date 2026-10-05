import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Какая карточка только что закрылась. Список слушает и мягко её подсвечивает.
class ReturnHighlight {
  ReturnHighlight._();

  static final Map<String, ValueNotifier<String?>> _active = {};

  static ValueNotifier<String?> notifier(String section) {
    return _active.putIfAbsent(section, () => ValueNotifier<String?>(null));
  }

  static void flash(String section, String itemId) {
    final notice = notifier(section);
    notice.value = null;
    notice.value = itemId;
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (notice.value == itemId) notice.value = null;
    });
  }
}

class ReturnHighlightBox extends StatefulWidget {
  const ReturnHighlightBox({
    super.key,
    required this.section,
    required this.itemId,
    required this.child,
  });

  final String section;
  final String itemId;
  final Widget child;

  @override
  State<ReturnHighlightBox> createState() => _ReturnHighlightBoxState();
}

class _ReturnHighlightBoxState extends State<ReturnHighlightBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final ValueNotifier<String?> _notice;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _notice = ReturnHighlight.notifier(widget.section);
    _notice.addListener(_onFlash);
    if (_notice.value == widget.itemId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  void _onFlash() {
    if (_notice.value == widget.itemId) _play();
  }

  void _play() {
    if (!mounted) return;
    _fade.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _notice.removeListener(_onFlash);
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _notice.value == widget.itemId || _fade.isAnimating;
    return Stack(
      children: [
        widget.child,
        if (active)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fade,
                builder: (context, _) {
                  final opacity = (1 - _fade.value) * 0.18;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.appColors.buttonPrimaryBg
                          .withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
