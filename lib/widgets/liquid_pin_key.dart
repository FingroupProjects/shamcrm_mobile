import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class LiquidPinKey extends StatefulWidget {
  static const List<String> _phoneLetters = [
    '',
    '',
    'АБВГ\nABC',
    'ДЕЖЗ\nDEF',
    'ИЙКЛ\nGHI',
    'МНОП\nJKL',
    'РСТУ\nMNO',
    'ФХЦЧ\nPQRS',
    'ШЩЪЫ\nTUV',
    'ЬЭЮЯ\nWXYZ',
  ];

  final String digit;
  final String? letters;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final Color textColor;
  final bool isDarkBackground;
  final double size;
  // Telephony keypad: no drop shadow under each digit.
  final bool showShadow;

  const LiquidPinKey({
    super.key,
    required this.digit,
    required this.onPressed,
    this.onLongPress,
    required this.textColor,
    required this.isDarkBackground,
    this.letters,
    this.size = 88,
    this.showShadow = true,
  });

  String get resolvedLetters {
    if (letters != null) return letters!;
    final number = int.tryParse(digit);
    if (number == null || number < 0 || number > 9) return '';
    return _phoneLetters[number];
  }

  @override
  State<LiquidPinKey> createState() => _LiquidPinKeyState();
}

class PinProgressDots extends StatefulWidget {
  final int filledCount;
  final bool isLoading;
  final bool isError;
  final Color activeColor;
  final Color inactiveColor;
  final Color errorColor;
  final double size;
  final double spacing;

  const PinProgressDots({
    super.key,
    required this.filledCount,
    required this.isLoading,
    required this.isError,
    required this.activeColor,
    required this.inactiveColor,
    required this.errorColor,
    this.size = 12,
    this.spacing = 8,
  });

  @override
  State<PinProgressDots> createState() => _PinProgressDotsState();
}

class _PinProgressDotsState extends State<PinProgressDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PinProgressDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller
        ..stop()
        ..reset();
    }
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final phase = (_controller.value - index * 0.18 + 1) % 1;
            final jump = widget.isLoading && phase < 0.42
                ? Curves.easeInOut.transform(
                    (phase / 0.42).clamp(0.0, 1.0),
                  )
                : 0.0;
            final height = -10 * math.sin(math.pi * jump);
            final filled = widget.isLoading || index < widget.filledCount;
            final color = widget.isError
                ? widget.errorColor
                : (filled ? widget.activeColor : widget.inactiveColor);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing),
              child: Transform.translate(
                offset: Offset(0, height),
                child: Transform.scale(
                  scale: 1 + jump * 0.16,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isError
                            ? widget.errorColor
                            : widget.activeColor.withValues(alpha: 0.38),
                      ),
                      boxShadow: widget.isLoading
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.32),
                                blurRadius: 9,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _LiquidPinKeyState extends State<LiquidPinKey> {
  static const _longPressDelay = Duration(milliseconds: 420);

  bool _isPressed = false;
  final Set<int> _activePointers = <int>{};
  Timer? _longPressTimer;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_activePointers.add(event.pointer)) return;
    if (_activePointers.length != 1) return;

    _setPressed(true);
    widget.onPressed();
    _longPressTimer?.cancel();
    if (widget.onLongPress != null) {
      _longPressTimer = Timer(_longPressDelay, () {
        if (!mounted || _activePointers.isEmpty) return;
        widget.onLongPress!();
      });
    }
  }

  void _handlePointerRelease(int pointer) {
    if (!_activePointers.remove(pointer)) return;
    if (_activePointers.isNotEmpty) return;
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _setPressed(false);
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.resolvedLetters;

    return Semantics(
      button: true,
      label: widget.digit,
      child: Center(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handlePointerDown,
          onPointerUp: (event) => _handlePointerRelease(event.pointer),
          onPointerCancel: (event) => _handlePointerRelease(event.pointer),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _isPressed ? 1 : 0),
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOut,
            builder: (context, pressure, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  1 - pressure * 0.035,
                  1 - pressure * 0.065,
                  1,
                ),
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOut,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: widget.showShadow
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: _isPressed ? 0.07 : 0.14,
                          ),
                          blurRadius: _isPressed ? 10 : 24,
                          spreadRadius: -2,
                          offset: Offset(0, _isPressed ? 3 : 9),
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: _LiquidBackdropLens(
                  isDarkBackground: widget.isDarkBackground,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 70),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isDarkBackground
                            ? [
                                Colors.white.withValues(
                                  alpha: _isPressed ? 0.15 : 0.10,
                                ),
                                const Color(0xFF7D858A).withValues(
                                  alpha: _isPressed ? 0.10 : 0.06,
                                ),
                                Colors.black.withValues(
                                  alpha: _isPressed ? 0.15 : 0.20,
                                ),
                              ]
                            : [
                                Colors.white.withValues(
                                  alpha: _isPressed ? 0.50 : 0.40,
                                ),
                                const Color(0xFFD8DDE0).withValues(
                                  alpha: _isPressed ? 0.24 : 0.16,
                                ),
                                Colors.black.withValues(
                                  alpha: _isPressed ? 0.05 : 0.08,
                                ),
                              ],
                        stops: const [0, 0.58, 1],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.46, -0.72),
                              radius: _isPressed ? 0.74 : 0.96,
                              colors: [
                                Colors.white.withValues(
                                  alpha: widget.isDarkBackground
                                      ? (_isPressed ? 0.10 : 0.14)
                                      : (_isPressed ? 0.16 : 0.22),
                                ),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.74],
                            ),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: _isPressed ? 1 : 0),
                          duration: const Duration(milliseconds: 230),
                          curve: Curves.easeOutCubic,
                          builder: (context, liquidProgress, child) {
                            return CustomPaint(
                              painter: _LiquidGlassCausticPainter(
                                isDarkBackground: widget.isDarkBackground,
                                progress: liquidProgress,
                              ),
                            );
                          },
                        ),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: letters.isEmpty ? 0 : 1,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.digit,
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 35,
                                    height: 0.94,
                                    fontWeight: FontWeight.w400,
                                    color: widget.textColor,
                                    shadows: [
                                      Shadow(
                                        color: widget.isDarkBackground
                                            ? Colors.black.withValues(
                                                alpha: 0.46,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.94,
                                              ),
                                        blurRadius:
                                            widget.isDarkBackground ? 2.2 : 1.6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (letters.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    letters,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 8.7,
                                      height: 1.03,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                      color: widget.textColor.withValues(
                                        alpha: widget.isDarkBackground
                                            ? 0.88
                                            : 0.96,
                                      ),
                                      shadows: [
                                        Shadow(
                                          color: widget.isDarkBackground
                                              ? Colors.black.withValues(
                                                  alpha: 0.48,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.96,
                                                ),
                                          blurRadius: widget.isDarkBackground
                                              ? 1.8
                                              : 2.4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidBackdropLens extends StatefulWidget {
  final bool isDarkBackground;
  final Widget child;

  const _LiquidBackdropLens({
    required this.isDarkBackground,
    required this.child,
  });

  @override
  State<_LiquidBackdropLens> createState() => _LiquidBackdropLensState();
}

class _LiquidBackdropLensState extends State<_LiquidBackdropLens> {
  static Future<FragmentProgram?>? _programFuture;
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeShader());
  }

  Future<void> _initializeShader() async {
    if (!ImageFilter.isShaderFilterSupported) return;
    final program = await (_programFuture ??= _loadProgram());
    if (!mounted || program == null) return;
    setState(() {
      _shader = program.fragmentShader();
    });
  }

  static Future<FragmentProgram?> _loadProgram() async {
    try {
      return await FragmentProgram.fromAsset('shaders/liquid_glass.frag');
    } catch (error) {
      debugPrint('LiquidPinKey: shader unavailable: $error');
      return null;
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageFilter filter = ImageFilter.blur(sigmaX: 8, sigmaY: 8);
    final shader = _shader;
    if (shader != null && ImageFilter.isShaderFilterSupported) {
      shader
        ..setFloat(2, 0)
        ..setFloat(3, 0.13)
        ..setFloat(4, 1.05)
        ..setFloat(5, widget.isDarkBackground ? 1 : 0);
      filter = ImageFilter.compose(
        outer: ImageFilter.shader(shader),
        inner: ImageFilter.blur(sigmaX: 2.6, sigmaY: 2.6),
      );
    }

    return BackdropFilter(
      filter: filter,
      child: widget.child,
    );
  }
}

class _LiquidGlassCausticPainter extends CustomPainter {
  final bool isDarkBackground;
  final double progress;

  const _LiquidGlassCausticPainter({
    required this.isDarkBackground,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final causticCenter = Offset(
      size.width * (0.27 + 0.27 * progress),
      size.height * (0.21 + 0.12 * progress),
    );
    final causticRadius = size.shortestSide * (0.29 + 0.05 * progress);
    final causticRect = Rect.fromCircle(
      center: causticCenter,
      radius: causticRadius,
    );
    final causticPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(
            alpha: isDarkBackground ? 0.08 : 0.12,
          ),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 1],
      ).createShader(causticRect);
    canvas.drawCircle(causticCenter, causticRadius, causticPaint);

    final lensRect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 0.8,
    );
    final opticalEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..shader = SweepGradient(
        transform: const GradientRotation(-1.5708),
        colors: [
          Colors.white.withValues(
            alpha: isDarkBackground ? 0.46 : 0.56,
          ),
          Colors.white.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(
            alpha: isDarkBackground ? 0.46 : 0.56,
          ),
        ],
        stops: const [0, 0.24, 0.52, 0.78, 1],
      ).createShader(lensRect);
    canvas.drawOval(lensRect, opticalEdgePaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassCausticPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDarkBackground != isDarkBackground;
  }
}
