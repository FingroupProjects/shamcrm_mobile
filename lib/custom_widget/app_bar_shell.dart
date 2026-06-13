import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class AppBarShell extends StatelessWidget {
  const AppBarShell({
    super.key,
    required this.leading,
    required this.center,
    this.trailing,
  });

  final Widget leading;
  final Widget center;
  final Widget? trailing;

  static const double orbSize = 52;
  static const double radius = 26;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: orbSize,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(child: center),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }

  static Widget capsule(
    BuildContext context, {
    required Widget child,
    double? width,
    double height = orbSize,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    List<Color>? gradientColors,
    Color? borderColor,
    Color? shadowColor,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ??
              [
                context.appColors.surfacePrimary.withValues(alpha: 0.88),
                context.appColors.surfaceElevated.withValues(alpha: 0.72),
              ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ??
              context.appColors.borderSubtle.withValues(alpha: 0.36),
        ),
        boxShadow: [
          BoxShadow(
            color:
                shadowColor ?? context.appColors.shadow.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
