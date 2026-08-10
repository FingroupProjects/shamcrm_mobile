library social_media_recorder;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';
import 'package:social_media_recorder/widgets/show_counter.dart';

/// Locked recording bar — single frosted capsule, Telegram+ quality.
class SoundRecorderWhenLockedDesign extends StatelessWidget {
  final double fullRecordPackageHeight;
  final SoundRecordNotifier soundRecordNotifier;
  final String? cancelText;
  final Function sendRequestFunction;
  final Function(String time)? stopRecording;
  final Widget? recordIconWhenLockedRecord;
  final TextStyle? cancelTextStyle;
  final TextStyle? counterTextStyle;
  final Color recordIconWhenLockBackGroundColor;
  final Color? counterBackGroundColor;
  final Color? cancelTextBackGroundColor;
  final Widget? sendButtonIcon;

  const SoundRecorderWhenLockedDesign({
    Key? key,
    required this.fullRecordPackageHeight,
    required this.sendButtonIcon,
    required this.soundRecordNotifier,
    required this.cancelText,
    required this.sendRequestFunction,
    this.stopRecording,
    required this.recordIconWhenLockedRecord,
    required this.cancelTextStyle,
    required this.counterTextStyle,
    required this.recordIconWhenLockBackGroundColor,
    required this.counterBackGroundColor,
    required this.cancelTextBackGroundColor,
  }) : super(key: key);

  void _cancel() {
    soundRecordNotifier.isShow = false;
    final time =
        '${soundRecordNotifier.minute}:${soundRecordNotifier.second}';
    stopRecording?.call(time);
    soundRecordNotifier.resetEdgePadding();
  }

  void _send() {
    soundRecordNotifier.isShow = false;
    soundRecordNotifier.finishRecording();
  }

  @override
  Widget build(BuildContext context) {
    final barHeight = fullRecordPackageHeight.clamp(48.0, 64.0);
    final shell = cancelTextBackGroundColor ?? Colors.grey.shade100;
    final accent = recordIconWhenLockBackGroundColor;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: double.infinity,
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: shell,
          borderRadius: BorderRadius.circular(barHeight / 2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _CircleAction(
              size: barHeight - 10,
              onTap: _cancel,
              background: Colors.redAccent.withValues(alpha: 0.14),
              border: Colors.redAccent.withValues(alpha: 0.28),
              child: Tooltip(
                message: cancelText ?? 'Cancel',
                child: const Icon(
                  Icons.delete_rounded,
                  size: 20,
                  color: Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ShowCounter(
                soundRecorderState: soundRecordNotifier,
                counterTextStyle: counterTextStyle,
                counterBackGroundColor:
                    counterBackGroundColor ?? accent.withValues(alpha: 0.12),
                fullRecordPackageHeight: fullRecordPackageHeight,
                expandWave: true,
              ),
            ),
            _CircleAction(
              size: barHeight - 6,
              onTap: _send,
              background: accent,
              border: accent.withValues(alpha: 0.5),
              glow: accent.withValues(alpha: 0.35),
              child: sendButtonIcon ??
                  const Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final Color background;
  final Color border;
  final Color? glow;
  final Widget child;

  const _CircleAction({
    required this.size,
    required this.onTap,
    required this.background,
    required this.border,
    required this.child,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: border),
            boxShadow: glow == null
                ? null
                : [
                    BoxShadow(
                      color: glow!,
                      blurRadius: 16,
                      spreadRadius: 0.5,
                    ),
                  ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
