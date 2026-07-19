// Этот файл отвечает за общие SIP-цвета и стеклянные UI-элементы экрана.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

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

  static const lightBg = Color(0xFFF2F6FF);
  static const lightText = Color(0xFF0F172A);
  static const lightSubtext = Color(0xFF64748B);
}

class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.color = _G.glassFill,
    this.borderColor = _G.glassBorder,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 14 : 12,
          sigmaY: isDark ? 14 : 12,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.18),
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
                          Colors.white.withValues(alpha: isDark ? 0.10 : 0.24),
                          Colors.white.withValues(alpha: isDark ? 0.03 : 0.08),
                          const Color(0xFFBFD7FF)
                              .withValues(alpha: isDark ? 0.04 : 0.10),
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
                          Colors.white.withValues(alpha: isDark ? 0.14 : 0.30),
                          Colors.white.withValues(alpha: 0),
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
    this.color = _G.glassFill,
    this.borderColor = _G.glassBorder,
  });

  final Widget child;
  final VoidCallback onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: color,
              borderRadius: radius,
              border: Border.all(color: borderColor, width: 0.8),
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
