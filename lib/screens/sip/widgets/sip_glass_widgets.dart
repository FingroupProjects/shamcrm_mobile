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
  static const amber = Color(0xFFFFCC00);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xAAFFFFFF);
  static const textTertiary = Color(0x66FFFFFF);

  static const lightBg = Color(0xFFF2F6FF);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF0F172A);
  static const lightSubtext = Color(0xFF64748B);
  static const lightAccent = Color(0xFF0A84FF);
  static const lightGreen = Color(0xFF25A344);
  static const brandPrimary = Color(0xFF1E2E52);
  static const brandMuted = Color(0xFF99A4BA);
  static const lightPanel = Color(0xFFF4F7FD);
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: child,
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
