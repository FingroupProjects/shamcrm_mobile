import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback? onPressed;
  final Color? buttonColor;
  final Color? textColor;
  final Widget? child;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  CustomButton({
    required this.buttonText,
    required this.onPressed,
    this.buttonColor,
    this.textColor,
    this.child,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedButtonColor = buttonColor ?? colors.buttonPrimaryBackground;
    final resolvedTextColor = textColor ?? colors.buttonPrimaryForeground;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: resolvedTextColor,
        );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: resolvedButtonColor,
          foregroundColor: resolvedTextColor,
          disabledBackgroundColor:
              colors.buttonSecondaryBackground.withValues(alpha: 0.75),
          disabledForegroundColor: colors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
          surfaceTintColor: Colors.transparent,
          shadowColor: colors.shadowColor,
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(resolvedTextColor),
                ),
              )
            : (child ??
                Text(
                  buttonText,
                  style: textStyle,
                )),
      ),
    );
  }
}
