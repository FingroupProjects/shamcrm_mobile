import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumHapticWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTap;

  const PremiumHapticWrapper({
    Key? key,
    required this.child,
    required this.onLongPress,
    this.onDoubleTap,
    this.onTap,
  }) : super(key: key);

  @override
  State<PremiumHapticWrapper> createState() => _PremiumHapticWrapperState();
}

class _PremiumHapticWrapperState extends State<PremiumHapticWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _longPressTimer;
  bool _isLongPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _isLongPressed = false;
    _controller.forward();
    _longPressTimer = Timer(const Duration(milliseconds: 250), () {
      _isLongPressed = true;
      HapticFeedback.mediumImpact();
      widget.onLongPress();
      _controller.reverse();
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isLongPressed) {
      _longPressTimer?.cancel();
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    _longPressTimer?.cancel();
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onDoubleTap: widget.onDoubleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
