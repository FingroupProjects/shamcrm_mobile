// Этот файл отвечает за общие SIP-цвета и стеклянные UI-элементы экрана.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

abstract class _TelephonyVisualColors {
  static const blue = Color(0xFF38BDF8);
  static const green = Color(0xFF34D399);
  static const amber = Color(0xFFFBBF24);
  static const red = Color(0xFFFB7185);
}

abstract class _G {
  static const activeBg = [
    Color(0xFF080C18),
    Color(0xFF0D1730),
    Color(0xFF0A1A2E),
  ];

  static const glassFill = Color(0x18FFFFFF);
  static const glassBorder = Color(0x30FFFFFF);

  static const accent = Color(0xFF3D8EFF);
  static const green = Color(0xFF34C759);
  static const red = Color(0xFFFF3B30);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xAAFFFFFF);
  static const textTertiary = Color(0x66FFFFFF);

  static const lightText = Color(0xFF0F172A);
  static const lightSubtext = Color(0xFF64748B);
}

class _TelephonyBackground extends StatelessWidget {
  const _TelephonyBackground({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const readability = 0.08;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      color: colors.backgroundPrimary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(
            preset: AppBackgroundPreset.none,
            blurSigma: 18,
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.backgroundPrimary.withValues(
                      alpha: isDark ? readability + 0.16 : readability,
                    ),
                    colors.surfacePrimary.withValues(
                      alpha: isDark ? 0.12 : 0.04,
                    ),
                    colors.backgroundSecondary.withValues(
                      alpha: isDark ? readability + 0.12 : readability + 0.03,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -150,
            right: -130,
            child: IgnorePointer(
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _TelephonyVisualColors.blue.withValues(
                        alpha: isDark ? 0.08 : 0.055,
                      ),
                      _TelephonyVisualColors.blue.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    final resolvedColor =
        color ?? colors.surfacePrimary.withValues(alpha: isDark ? 0.54 : 0.66);
    final resolvedBorder = borderColor ??
        colors.borderSubtle.withValues(alpha: isDark ? 0.52 : 0.72);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 14 : 12,
          sigmaY: isDark ? 14 : 12,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: resolvedColor,
            borderRadius: radius,
            border: Border.all(color: resolvedBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: colors.surfaceElevated.withValues(
                  alpha: isDark ? 0.07 : 0.16,
                ),
                blurRadius: 18,
                offset: const Offset(0, -2),
              ),
              BoxShadow(
                color: const Color(0xFF9DB7E8)
                    .withValues(alpha: isDark ? 0.08 : 0.16),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.surfaceElevated.withValues(
                            alpha: isDark ? 0.12 : 0.20,
                          ),
                          colors.surfaceElevated.withValues(
                            alpha: isDark ? 0.04 : 0.07,
                          ),
                          colors.surfaceAccent.withValues(
                            alpha: isDark ? 0.08 : 0.12,
                          ),
                        ],
                        stops: const [0.0, 0.38, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 1,
                right: 1,
                top: 1,
                child: IgnorePointer(
                  child: Container(
                    height: borderRadius * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(borderRadius),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.surfaceElevated.withValues(
                            alpha: isDark ? 0.16 : 0.26,
                          ),
                          colors.surfaceElevated.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.child,
    required this.onPressed,
    this.borderRadius = 20,
    this.padding,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    final resolvedColor =
        color ?? colors.surfacePrimary.withValues(alpha: isDark ? 0.50 : 0.64);
    final resolvedBorder = borderColor ??
        colors.borderSubtle.withValues(alpha: isDark ? 0.50 : 0.70);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isDark ? 12 : 10,
            sigmaY: isDark ? 12 : 10,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: resolvedColor,
              borderRadius: radius,
              border: Border.all(color: resolvedBorder, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, -1),
                ),
                BoxShadow(
                  color: const Color(0xFF9DB7E8)
                      .withValues(alpha: isDark ? 0.05 : 0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white
                                .withValues(alpha: isDark ? 0.08 : 0.20),
                            Colors.white
                                .withValues(alpha: isDark ? 0.02 : 0.06),
                            const Color(0xFFBFD7FF)
                                .withValues(alpha: isDark ? 0.03 : 0.08),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 1,
                  right: 1,
                  top: 1,
                  child: IgnorePointer(
                    child: Container(
                      height: borderRadius * 0.72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(borderRadius),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white
                                .withValues(alpha: isDark ? 0.12 : 0.24),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding ?? const EdgeInsets.all(14),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
