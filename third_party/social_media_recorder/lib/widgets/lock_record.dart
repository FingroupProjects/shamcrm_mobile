library social_media_recorder;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// Floating lock pill above the mic — swipe up to lock recording.
class LockRecord extends StatefulWidget {
  final SoundRecordNotifier soundRecorderState;
  final Widget? lockIcon;

  const LockRecord({
    this.lockIcon,
    required this.soundRecorderState,
    Key? key,
  }) : super(key: key);

  @override
  State<LockRecord> createState() => _LockRecordState();
}

class _LockRecordState extends State<LockRecord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.soundRecorderState.buttonPressed) {
      return const SizedBox.shrink();
    }

    final progress = widget.soundRecorderState.heightPosition.clamp(0.0, 50.0);
    final remaining = (52 - progress).clamp(0.0, 52.0);
    final fading = widget.soundRecorderState.edge >= 50;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: fading ? 0 : 1,
      child: Transform.translate(
        offset: Offset(0, -78 + (progress * 0.35)),
        child: AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) {
            final lift = Curves.easeInOut.transform(_bounce.value) * 5;
            return Transform.translate(
              offset: Offset(0, -lift),
              child: child,
            );
          },
          child: Container(
            width: 40,
            height: remaining,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: remaining < 20
                ? null
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          const SizedBox(height: 1),
                          widget.lockIcon ??
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
