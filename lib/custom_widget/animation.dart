import 'package:flutter/material.dart';

class PlayStoreImageLoading extends StatefulWidget {
  final double size;
  final Duration duration;

  const PlayStoreImageLoading({
    super.key,
    this.size = 48.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PlayStoreImageLoading> createState() => _PlayStoreImageLoadingState();
}

class _PlayStoreImageLoadingState extends State<PlayStoreImageLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Создаём анимацию с кривой для эффекта ускорения/замедления
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Можно попробовать: fastOutSlowIn, easeInOutCubic
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Image.asset(
              'assets/icons/playstore.png',
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}