import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

OverlayEntry? _fullTitleEntry;

/// Обрезанный заголовок. Долгое нажатие показывает полный текст над ним.
class HoldToReadText extends StatelessWidget {
  const HoldToReadText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 1,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showFullTitle(context),
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      ),
    );
  }

  void _showFullTitle(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || text.trim().isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: box.size.width);
    if (!painter.didExceedMaxLines) return;

    showFadingCaption(
      context,
      text,
      anchor: box.localToGlobal(Offset.zero),
      anchorHeight: box.size.height,
    );
  }
}

/// Короткое облачко над точкой. Само появляется и гаснет.
void showFadingCaption(
  BuildContext context,
  String text, {
  Offset? anchor,
  double anchorHeight = 24,
}) {
  if (text.trim().isEmpty) return;
  HapticFeedback.lightImpact();
  final origin = anchor ?? const Offset(24, 80);
  final overlay = Overlay.of(context, rootOverlay: true);

  _fullTitleEntry?.remove();
  _fullTitleEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final media = MediaQuery.of(overlayContext);
      final above = origin.dy - 64;
      final top = above < media.padding.top + 4
          ? origin.dy + anchorHeight + 8
          : above;
      return Positioned(
        left: 24,
        right: 24,
        top: top,
        child: IgnorePointer(
          child: _FadingTitle(text: text),
        ),
      );
    },
  );
  _fullTitleEntry = entry;
  overlay.insert(entry);
}

class _FadingTitle extends StatefulWidget {
  const _FadingTitle({required this.text});

  final String text;

  @override
  State<_FadingTitle> createState() => _FadingTitleState();
}

class _FadingTitleState extends State<_FadingTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _fade.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _fullTitleEntry?.remove();
      _fullTitleEntry = null;
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FadeTransition(
      opacity: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 12),
        TweenSequenceItem(tween: ConstantTween(1), weight: 58),
        TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
      ]).animate(_fade),
      child: Material(
        color: colors.surfacePrimary,
        elevation: 8,
        shadowColor: colors.shadow.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: context.appTextStyles.bodyLg.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
