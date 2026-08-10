library social_media_recorder;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// Compact Telegram-style recording timer with live mic waveform.
class ShowCounter extends StatelessWidget {
  final SoundRecordNotifier soundRecorderState;
  final TextStyle? counterTextStyle;
  final Color? counterBackGroundColor;
  final double fullRecordPackageHeight;
  final bool compact;
  final bool expandWave;

  const ShowCounter({
    required this.soundRecorderState,
    required this.fullRecordPackageHeight,
    Key? key,
    this.counterTextStyle,
    required this.counterBackGroundColor,
    this.compact = false,
    this.expandWave = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = counterTextStyle ??
        const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          fontFeatures: [FontFeature.tabularFigures()],
        );
    final surface = counterBackGroundColor ?? Colors.grey.shade100;
    final height = compact
        ? (fullRecordPackageHeight - 12).clamp(32.0, 44.0)
        : fullRecordPackageHeight;
    final time =
        '${soundRecorderState.minute.toString().padLeft(2, '0')}:'
        '${soundRecorderState.second.toString().padLeft(2, '0')}';
    final pulse = soundRecorderState.second % 2 == 0;
    final amp = soundRecorderState.currentAmplitude;
    final compactStyle = style.copyWith(
      fontSize: compact ? 13 : style.fontSize,
      letterSpacing: compact ? 0.2 : style.letterSpacing,
    );
    final waveColor = (style.color ?? Colors.redAccent).withValues(alpha: 0.95);
    final wave = LiveAmplitudeWaveform(
      samples: soundRecorderState.amplitudeSamples,
      currentAmplitude: amp,
      color: waveColor,
      barCount: compact ? 20 : 28,
      strokeWidth: compact ? 1.4 : 1.6,
      barGap: compact ? 1.0 : 1.2,
      maxHeightFactor: compact ? 0.82 : 0.9,
    );

    final content = Row(
      mainAxisSize: expandWave ? MainAxisSize.max : MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: compact ? 7 : 9,
          height: compact ? 7 : 9,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.redAccent.shade200,
              Colors.redAccent,
              amp.clamp(0.0, 1.0),
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(
                  alpha: 0.18 + (amp * 0.45),
                ),
                blurRadius: 6 + (amp * 10),
                spreadRadius: amp > 0.55 ? 1 : 0,
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        Text(
          time,
          textDirection: TextDirection.ltr,
          style: compactStyle,
        ),
        SizedBox(width: compact ? 6 : 10),
        if (expandWave)
          Expanded(
            child: SizedBox(height: compact ? 18 : 22, child: wave),
          )
        else
          SizedBox(
            width: compact ? 56 : 96,
            height: compact ? 18 : 22,
            child: wave,
          ),
      ],
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: height.clamp(32.0, 56.0),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.22 + amp * 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(
                alpha: pulse ? 0.12 + amp * 0.16 : 0.06 + amp * 0.1,
              ),
              blurRadius: 8 + (amp * 10),
              spreadRadius: amp > 0.7 ? 0.8 : 0,
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}

/// Real-time bars driven by mic amplitude samples (0..1).
class LiveAmplitudeWaveform extends StatelessWidget {
  final List<double> samples;
  final double currentAmplitude;
  final Color color;
  final int barCount;
  final double strokeWidth;
  final double barGap;
  final double maxHeightFactor;

  const LiveAmplitudeWaveform({
    Key? key,
    required this.samples,
    required this.currentAmplitude,
    required this.color,
    this.barCount = 24,
    this.strokeWidth = 1.6,
    this.barGap = 1.3,
    this.maxHeightFactor = 0.88,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LiveWavePainter(
        samples: List<double>.from(samples),
        currentAmplitude: currentAmplitude,
        color: color,
        barCount: barCount,
        strokeWidth: strokeWidth,
        barGap: barGap,
        maxHeightFactor: maxHeightFactor,
      ),
    );
  }
}

class _LiveWavePainter extends CustomPainter {
  final List<double> samples;
  final double currentAmplitude;
  final Color color;
  final int barCount;
  final double strokeWidth;
  final double barGap;
  final double maxHeightFactor;

  _LiveWavePainter({
    required this.samples,
    required this.currentAmplitude,
    required this.color,
    required this.barCount,
    required this.strokeWidth,
    required this.barGap,
    required this.maxHeightFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Keep bars tightly spaced and fill the whole available width.
    final step = math.max(strokeWidth + barGap, 2.0);
    final fittedCount =
        (((size.width - strokeWidth) / step).floor() + 1).clamp(barCount, 56);
    final startX = strokeWidth / 2;
    // Stretch slightly so first/last bars touch the edges and fill empty space.
    final usedStep =
        fittedCount <= 1 ? 0.0 : (size.width - strokeWidth) / (fittedCount - 1);

    for (var i = 0; i < fittedCount; i++) {
      double level;
      final sampleIndex = samples.length - fittedCount + i;
      if (sampleIndex >= 0 && sampleIndex < samples.length) {
        level = samples[sampleIndex];
      } else if (samples.isEmpty) {
        final phase = i * 0.45 + currentAmplitude * 4;
        level = 0.08 + 0.06 * ((math.sin(phase) + 1) / 2);
      } else {
        // Soft trail for missing older samples.
        final age = fittedCount - i;
        level = math.max(0.05, currentAmplitude * math.pow(0.86, age).toDouble());
      }

      if (i == fittedCount - 1) {
        level = math.max(level, currentAmplitude);
      }

      final amp = 0.16 + (level.clamp(0.0, 1.0) * maxHeightFactor);
      final h = size.height * amp;
      final x = fittedCount == 1
          ? size.width / 2
          : startX + (i * usedStep);
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveWavePainter oldDelegate) {
    return oldDelegate.currentAmplitude != currentAmplitude ||
        oldDelegate.color != color ||
        oldDelegate.barCount != barCount ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.barGap != barGap ||
        oldDelegate.maxHeightFactor != maxHeightFactor ||
        oldDelegate.samples.length != samples.length ||
        !_listEquals(oldDelegate.samples, samples);
  }

  bool _listEquals(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
