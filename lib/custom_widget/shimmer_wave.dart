import 'package:flutter/material.dart';

class _SlidingGradientTransform extends GradientTransform {
  final double dx;

  const _SlidingGradientTransform(this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class ShimmerWave extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerWave({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<ShimmerWave> createState() => _ShimmerWaveState();
}

class _ShimmerWaveState extends State<ShimmerWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final width = bounds.width <= 0 ? 1.0 : bounds.width;
            final dx = (value * 2 - 1) * width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xffE5E7EB),
                Color(0xffF3F4F6),
                Color(0xffE5E7EB),
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: _SlidingGradientTransform(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
