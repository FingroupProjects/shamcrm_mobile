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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
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