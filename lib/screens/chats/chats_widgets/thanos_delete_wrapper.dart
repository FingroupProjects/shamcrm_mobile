import 'dart:math';
import 'dart:ui' as ui;
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// ────────────────────────────────────────────────────────────
// Public API
// ────────────────────────────────────────────────────────────

/// Типы эффекта для разных видов сообщений
enum ThanosEffectType {
  /// Текстовое СМС — пыль разлетается
  text,

  /// Голосовое — волны сжимаются к центру
  voice,

  /// Файл — сдувает вправо
  file,

  /// Изображение — пиксели хаотично гаснут
  image,
}

/// Виджет-обёртка. Оберни любое сообщение в него и вызови
/// ThanosDeleteWrapperState.startDelete() чтобы запустить анимацию.
class ThanosDeleteWrapper extends StatefulWidget {
  final Widget child;
  final ThanosEffectType effectType;
  final VoidCallback onDeleteComplete;

  const ThanosDeleteWrapper({
    super.key,
    required this.child,
    required this.effectType,
    required this.onDeleteComplete,
  });

  @override
  State<ThanosDeleteWrapper> createState() => ThanosDeleteWrapperState();
}

class ThanosDeleteWrapperState extends State<ThanosDeleteWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // snapshot виджета до начала анимации
  ui.Image? _snapshot;
  bool _animating = false;

  // ключ для захвата изображения
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDeleteComplete();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Вызывается извне для запуска анимации удаления
  Future<void> startDelete() async {
    if (_animating) return;

    // Делаем снимок виджета
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        if (!mounted) return;
        setState(() {
          _snapshot = image;
          _animating = true;
        });
        _ctrl.forward();
        return;
      }
    } catch (_) {}

    // Если не удалось сделать снимок — просто вызываем коллбэк
    widget.onDeleteComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animating) {
      return RepaintBoundary(
        key: _repaintKey,
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          child: CustomPaint(
            painter: _buildPainter(_ctrl.value),
            // Резервируем место, пока анимация идёт, через прозрачный оригинал
            child: Opacity(
              opacity: 0,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  CustomPainter _buildPainter(double progress) {
    final colors = context.appColors;
    switch (widget.effectType) {
      case ThanosEffectType.text:
        return _DustParticlePainter(
          image: _snapshot,
          progress: progress,
          seed: 42,
          inverseColor: colors.textInverse,
          accentColor: colors.warning,
        );
      case ThanosEffectType.voice:
        return _WaveCollapsePainter(
          image: _snapshot,
          progress: progress,
          seed: 7,
          inverseColor: colors.textInverse,
          accentColor: colors.info,
        );
      case ThanosEffectType.file:
        return _WindBlowPainter(
          image: _snapshot,
          progress: progress,
          seed: 13,
          inverseColor: colors.textInverse,
          accentColor: colors.info,
        );
      case ThanosEffectType.image:
        return _PixelFadePainter(
          image: _snapshot,
          progress: progress,
          seed: 99,
          inverseColor: colors.textInverse,
        );
    }
  }
}

// ────────────────────────────────────────────────────────────
// 1. ТЕКСТ — пыль разлетается (мелкие кусочки)
// ────────────────────────────────────────────────────────────

class _DustParticlePainter extends CustomPainter {
  final ui.Image? image;
  final double progress;
  final int seed;
  final Color inverseColor;
  final Color accentColor;

  static const int _cols = 28;
  static const int _rows = 14;

  late final List<_Particle> _particles;
  bool _initialized = false;

  _DustParticlePainter(
      {required this.image,
      required this.progress,
      required this.seed,
      required this.inverseColor,
      required this.accentColor});

  void _init(Size size) {
    if (_initialized) return;
    _initialized = true;
    final rng = Random(seed);
    _particles = [];
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final cx = (c + 0.5) / _cols * size.width;
        final cy = (r + 0.5) / _rows * size.height;
        _particles.add(_Particle(
          origin: Offset(cx, cy),
          velocity: Offset(
            (rng.nextDouble() - 0.5) * 90,
            (rng.nextDouble() - 1.3) * 70,
          ),
          delay: rng.nextDouble() * 0.45,
          size: (rng.nextDouble() * 1.8 + 0.8) * (size.width / _cols) * 0.6,
          alpha: 1.0,
        ));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _init(size);

    final paint = Paint();

    if (image != null) {
      // Рисуем оригинал с угасанием
      final overallAlpha = (1.0 - progress * 2).clamp(0.0, 1.0);
      if (overallAlpha > 0) {
        paint.color = inverseColor.withValues(alpha: overallAlpha);
        canvas.saveLayer(Offset.zero & size, paint);
        paintImage(
          canvas: canvas,
          rect: Offset.zero & size,
          image: image!,
          fit: BoxFit.fill,
        );
        canvas.restore();
      }
    }

    // Рисуем частицы
    for (final p in _particles) {
      final localProgress =
          ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      final pos = p.origin + p.velocity * localProgress;
      final alpha = (1.0 - localProgress).clamp(0.0, 1.0);

      if (image != null) {
        final srcX = (p.origin.dx / size.width) * image!.width;
        final srcY = (p.origin.dy / size.height) * image!.height;
        final srcTileW = image!.width / _cols.toDouble();
        final srcTileH = image!.height / _rows.toDouble();

        final src = Rect.fromLTWH(
            srcX - srcTileW / 2, srcY - srcTileH / 2, srcTileW, srcTileH);
        final dst = Rect.fromCenter(center: pos, width: p.size, height: p.size);

        paint
          ..color = inverseColor.withValues(alpha: alpha)
          ..filterQuality = FilterQuality.low;

        canvas.saveLayer(dst.inflate(2), paint);
        canvas.drawImageRect(image!, src, dst, Paint());
        canvas.restore();
      } else {
        paint.color = accentColor.withValues(alpha: alpha);
        canvas.drawCircle(pos, p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DustParticlePainter old) =>
      old.progress != progress || old.image != image;
}

class _Particle {
  final Offset origin;
  final Offset velocity;
  final double delay;
  final double size;
  final double alpha;

  _Particle({
    required this.origin,
    required this.velocity,
    required this.delay,
    required this.size,
    required this.alpha,
  });
}

// ────────────────────────────────────────────────────────────
// 2. ГОЛОСОВОЕ — волновые кольца сжимаются к центру
// ────────────────────────────────────────────────────────────

class _WaveCollapsePainter extends CustomPainter {
  final ui.Image? image;
  final double progress;
  final int seed;
  final Color inverseColor;
  final Color accentColor;

  _WaveCollapsePainter(
      {required this.image,
      required this.progress,
      required this.seed,
      required this.inverseColor,
      required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius =
        sqrt(size.width * size.width + size.height * size.height) / 2;

    final scale = (1.0 - progress * 0.9).clamp(0.01, 1.0);
    final alpha = (1.0 - progress * 1.3).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.translate(-center.dx, -center.dy);

    if (image != null) {
      final paint = Paint()
        ..color = inverseColor.withValues(alpha: alpha)
        ..filterQuality = FilterQuality.low;
      canvas.saveLayer(Offset.zero & size, paint);
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: image!,
        fit: BoxFit.fill,
      );
      canvas.restore();
    }

    canvas.restore();

    final int ringCount = 5;
    final rng = Random(seed);
    for (int i = 0; i < ringCount; i++) {
      final phase = i / ringCount;
      final t = ((progress * 1.4) - phase * 0.35).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final radius = maxRadius * (1.0 - t);
      final ringAlpha = (sin(t * pi)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = accentColor.withValues(alpha: ringAlpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 + rng.nextDouble() * 2;

      canvas.drawCircle(center, radius.clamp(0, maxRadius), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveCollapsePainter old) =>
      old.progress != progress || old.image != image;
}

// ────────────────────────────────────────────────────────────
// 3. ФАЙЛ — сдувает вправо с истончением
// ────────────────────────────────────────────────────────────

class _WindBlowPainter extends CustomPainter {
  final ui.Image? image;
  final double progress;
  final int seed;
  final Color inverseColor;
  final Color accentColor;

  _WindBlowPainter(
      {required this.image,
      required this.progress,
      required this.seed,
      required this.inverseColor,
      required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    const int strips = 18;
    final stripH = size.height / strips;

    for (int i = 0; i < strips; i++) {
      final stripDelay = (i / strips) * 0.4 + rng.nextDouble() * 0.1;
      final t = ((progress - stripDelay) / (1.0 - stripDelay)).clamp(0.0, 1.0);

      final offsetX = size.width * t * (1.0 + rng.nextDouble() * 0.3);
      final alpha = (1.0 - t * 1.2).clamp(0.0, 1.0);

      final dstRect =
          Rect.fromLTWH(offsetX, i * stripH, size.width, stripH + 0.5);

      if (image != null) {
        final srcRect = Rect.fromLTWH(
          0,
          (i / strips) * image!.height,
          image!.width.toDouble(),
          image!.height / strips,
        );

        final paint = Paint()
          ..color = inverseColor.withValues(alpha: alpha)
          ..filterQuality = FilterQuality.low;

        canvas.saveLayer(dstRect.inflate(1), paint);
        canvas.drawImageRect(image!, srcRect, dstRect, Paint());
        canvas.restore();
      }

      if (t > 0.1 && t < 0.85) {
        final windPaint = Paint()
          ..color = accentColor.withValues(alpha: alpha * 0.4)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        final y = i * stripH + stripH / 2;
        canvas.drawLine(
          Offset(offsetX - size.width * 0.12, y),
          Offset(offsetX, y),
          windPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WindBlowPainter old) =>
      old.progress != progress || old.image != image;
}

// ────────────────────────────────────────────────────────────
// 4. ИЗОБРАЖЕНИЕ — пиксели хаотично гаснут
// ────────────────────────────────────────────────────────────

class _PixelFadePainter extends CustomPainter {
  final ui.Image? image;
  final double progress;
  final int seed;
  final Color inverseColor;

  static const int _blockSize = 8;

  _PixelFadePainter(
      {required this.image,
      required this.progress,
      required this.seed,
      required this.inverseColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    final int cols = (size.width / _blockSize).ceil();
    final int rows = (size.height / _blockSize).ceil();
    final int totalBlocks = cols * rows;

    final rng = Random(seed);
    final indices = List<int>.generate(totalBlocks, (i) => i)..shuffle(rng);

    final liveCount = (totalBlocks * (1.0 - progress)).round();

    final liveSet = indices.take(liveCount).toSet();

    final paint = Paint()..filterQuality = FilterQuality.low;

    for (int blockIdx = 0; blockIdx < totalBlocks; blockIdx++) {
      if (!liveSet.contains(blockIdx)) continue;

      final r = blockIdx ~/ cols;
      final c = blockIdx % cols;

      final dstRect = Rect.fromLTWH(
        c * _blockSize.toDouble(),
        r * _blockSize.toDouble(),
        _blockSize.toDouble(),
        _blockSize.toDouble(),
      );

      final srcRect = Rect.fromLTWH(
        (c / cols) * image!.width,
        (r / rows) * image!.height,
        image!.width / cols,
        image!.height / rows,
      );

      canvas.drawImageRect(image!, srcRect, dstRect, paint);
    }

    final sparkCount = (totalBlocks * progress * 0.15).round();
    final deadBlocks = indices.skip(liveCount).take(sparkCount);
    final sparkPaint = Paint()
      ..color = inverseColor.withValues(alpha: (1.0 - progress) * 0.7);

    for (final b in deadBlocks) {
      final r = b ~/ cols;
      final c = b % cols;
      canvas.drawRect(
        Rect.fromLTWH(
          c * _blockSize.toDouble() + 2,
          r * _blockSize.toDouble() + 2,
          _blockSize - 4.0,
          _blockSize - 4.0,
        ),
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelFadePainter old) =>
      old.progress != progress || old.image != image;
}
