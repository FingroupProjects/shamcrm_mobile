import 'dart:async';
import 'dart:math' as math;

import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gmail-style undo: 5 seconds at the bottom, burning countdown ring.
class UndoActions {
  UndoActions._();

  static const Duration defaultDuration = Duration(seconds: 5);

  static int _generation = 0;
  static Future<void> Function()? _pendingCommit;
  static OverlayEntry? _entry;

  /// Action already happened. Undo reverts it.
  static void showRevert({
    required String message,
    required String actionLabel,
    required Future<void> Function() onUndo,
    Duration duration = defaultDuration,
  }) {
    _commitPending();
    final token = ++_generation;
    _showToast(
      message: message,
      actionLabel: actionLabel,
      duration: duration,
      onUndo: () async {
        if (token != _generation) return;
        try {
          await onUndo();
        } catch (_) {
          final ctx = navigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            showCustomSnackBar(
              context: ctx,
              message: 'error_text',
              isSuccess: false,
            );
          }
        }
      },
    );
  }

  /// Action runs after the toast closes, unless the user taps undo.
  static void defer({
    required String message,
    required String actionLabel,
    required Future<void> Function() onCommit,
    Duration duration = defaultDuration,
  }) {
    _commitPending();
    final token = ++_generation;
    _pendingCommit = onCommit;

    _showToast(
      message: message,
      actionLabel: actionLabel,
      duration: duration,
      onUndo: () async {
        if (token != _generation) return;
        _pendingCommit = null;
      },
      onExpired: () {
        if (token != _generation) return;
        final commit = _pendingCommit;
        _pendingCommit = null;
        if (commit != null) {
          unawaited(commit());
        }
      },
    );
  }

  static void _commitPending() {
    final commit = _pendingCommit;
    _pendingCommit = null;
    _generation++;
    _removeToast();
    if (commit != null) {
      unawaited(commit());
    }
  }

  static void _removeToast() {
    _entry?.remove();
    _entry = null;
  }

  static void _showToast({
    required String message,
    required String actionLabel,
    required Duration duration,
    required Future<void> Function() onUndo,
    VoidCallback? onExpired,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    final context = navigatorKey.currentContext;
    if (overlay == null || context == null) {
      onExpired?.call();
      return;
    }

    HapticFeedback.selectionClick();
    _removeToast();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return _UndoToast(
          message: message,
          actionLabel: actionLabel,
          duration: duration,
          onUndo: () {
            unawaited(onUndo());
            if (identical(_entry, entry)) {
              _removeToast();
            }
          },
          onExpired: () {
            if (identical(_entry, entry)) {
              _removeToast();
            }
            onExpired?.call();
          },
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _UndoToast extends StatefulWidget {
  const _UndoToast({
    required this.message,
    required this.actionLabel,
    required this.duration,
    required this.onUndo,
    required this.onExpired,
  });

  final String message;
  final String actionLabel;
  final Duration duration;
  final VoidCallback onUndo;
  final VoidCallback onExpired;

  @override
  State<_UndoToast> createState() => _UndoToastState();
}

class _UndoToastState extends State<_UndoToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finish(widget.onExpired);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(VoidCallback action) {
    if (_finished) return;
    _finished = true;
    action();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 12,
      right: 12,
      bottom: bottom + 10,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.toastBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return _BurningSecondsCircle(
                      progress: 1 - _controller.value,
                      secondsLeft: math.max(
                        1,
                        (widget.duration.inMilliseconds *
                                (1 - _controller.value) /
                                1000)
                            .ceil(),
                      ),
                      ringColor: context.toastAction,
                      trackColor:
                          context.toastForeground.withValues(alpha: 0.18),
                      textColor: context.toastForeground,
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.toastForeground,
                      height: 1.25,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _controller.stop();
                    _finish(widget.onUndo);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: context.toastAction,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    widget.actionLabel,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BurningSecondsCircle extends StatelessWidget {
  const _BurningSecondsCircle({
    required this.progress,
    required this.secondsLeft,
    required this.ringColor,
    required this.trackColor,
    required this.textColor,
  });

  final double progress;
  final int secondsLeft;
  final Color ringColor;
  final Color trackColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _BurningCirclePainter(
          progress: progress.clamp(0.0, 1.0),
          ringColor: ringColor,
          trackColor: trackColor,
        ),
        child: Center(
          child: Text(
            '$secondsLeft',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BurningCirclePainter extends CustomPainter {
  _BurningCirclePainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant _BurningCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor;
  }
}
