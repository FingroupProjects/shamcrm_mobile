library social_media_recorder;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// Mic button + optional slide-to-cancel hint.
///
/// [slideOffset] moves ONLY the mic button (cancel gesture), not the whole bar.
class ShowMicWithText extends StatefulWidget {
  final bool shouldShowText;
  final String? slideToCancelText;
  final SoundRecordNotifier soundRecorderState;
  final TextStyle? slideToCancelTextStyle;
  final Color? backGroundColor;
  final Widget? recordIcon;
  final Color? counterBackGroundColor;
  final double fullRecordPackageHeight;
  final double initRecordPackageWidth;
  final bool compactHint;
  final double slideOffset;
  final bool showMic;

  const ShowMicWithText({
    required this.backGroundColor,
    required this.initRecordPackageWidth,
    required this.fullRecordPackageHeight,
    Key? key,
    required this.shouldShowText,
    required this.soundRecorderState,
    required this.slideToCancelTextStyle,
    required this.slideToCancelText,
    required this.recordIcon,
    required this.counterBackGroundColor,
    this.compactHint = false,
    this.slideOffset = 0,
    this.showMic = true,
  }) : super(key: key);

  @override
  State<ShowMicWithText> createState() => _ShowMicWithTextState();
}

class _ShowMicWithTextState extends State<ShowMicWithText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hintController;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = widget.soundRecorderState.buttonPressed;
    final showHint = widget.shouldShowText;
    final layoutSize = pressed
        ? math.min(40.0, widget.fullRecordPackageHeight - 8)
        : math.min(40.0, widget.initRecordPackageWidth - 4);
    final hintStyle = (widget.slideToCancelTextStyle ??
            TextStyle(
              fontSize: widget.compactHint ? 11 : 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ))
        .copyWith(fontSize: widget.compactHint ? 11 : 13);

    final mic = SizedBox(
      key: widget.soundRecorderState.key,
      width: layoutSize,
      height: layoutSize,
      child: OverflowBox(
        minWidth: layoutSize,
        minHeight: layoutSize,
        maxWidth: 88,
        maxHeight: 88,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: pressed ? 1.06 : 1.0,
          child: Container(
            width: layoutSize,
            height: layoutSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed
                  ? (widget.backGroundColor ??
                      Theme.of(context).colorScheme.secondary)
                  : Colors.transparent,
              boxShadow: pressed
                  ? [
                      BoxShadow(
                        color: (widget.backGroundColor ?? Colors.blue)
                            .withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: Center(
                child: widget.recordIcon ??
                    Icon(
                      Icons.mic_rounded,
                      size: 22,
                      color: pressed ? Colors.white : Colors.black87,
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!showHint) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: mic,
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 4),
              child: AnimatedBuilder(
                animation: _hintController,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_hintController.value);
                  return Opacity(
                    opacity: 0.5 + (t * 0.4),
                    child: Transform.translate(
                      offset: Offset(-3 * t, 0),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  widget.slideToCancelText ?? '',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: hintStyle,
                ),
              ),
            ),
          ),
          if (widget.showMic)
            Transform.translate(
              offset: Offset(-widget.slideOffset, 0),
              child: mic,
            ),
        ],
      ),
    );
  }
}
