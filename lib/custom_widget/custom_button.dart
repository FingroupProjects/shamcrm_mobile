import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String buttonText;
  final VoidCallback? onPressed;
  final Color buttonColor;
  final Color textColor;
  final Color? borderColor;
  final double borderWidth;
  final Widget? child;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    required this.buttonColor,
    required this.textColor,
    this.borderColor,
    this.borderWidth = 0,
    this.child,
    this.isLoading = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _tapLocked = false;

  @override
  void didUpdateWidget(covariant CustomButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && _tapLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.isLoading || !_tapLocked) return;
        setState(() => _tapLocked = false);
      });
    }
  }

  void _handlePressed() {
    if (_tapLocked || widget.isLoading || widget.onPressed == null) return;

    setState(() => _tapLocked = true);
    widget.onPressed!.call();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.isLoading || !_tapLocked) return;
      setState(() => _tapLocked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isLoading || _tapLocked;
    final colors = context.appColors;

    Color? effectiveBorderColor;
    double effectiveBorderWidth = 1.0;

    if (widget.borderColor != null) {
      effectiveBorderColor = widget.borderColor;
      effectiveBorderWidth = widget.borderWidth > 0 ? widget.borderWidth : 1.0;
    } else {
      final isPrimary = widget.buttonColor == colors.buttonPrimaryBg;
      final isDanger = widget.buttonColor == colors.buttonDangerBg ||
          widget.buttonColor == colors.error;

      final lowerText = widget.buttonText.toLowerCase().trim();
      final isCancelOrSecondaryText = lowerText == 'отмена' ||
          lowerText == 'cancel' ||
          lowerText == 'bekor qilish' ||
          lowerText == 'bekor' ||
          lowerText == 'назад' ||
          lowerText == 'back' ||
          lowerText == 'сбросить' ||
          lowerText == 'reset';

      if (!isPrimary && !isDanger) {
        effectiveBorderColor = colors.borderSubtle;
        effectiveBorderWidth = 1.0;
      } else if (isCancelOrSecondaryText) {
        effectiveBorderColor = colors.borderSubtle;
        effectiveBorderWidth = 1.0;
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.buttonColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: effectiveBorderColor == null
                ? BorderSide.none
                : BorderSide(
                    color: effectiveBorderColor,
                    width: effectiveBorderWidth,
                  ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: isDisabled ? null : _handlePressed,
        child: widget.isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
                ),
              )
            : (widget.child ??
                Text(
                  widget.buttonText,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.textColor,
                    fontFamily: 'Gilroy',
                  ),
                )),
      ),
    );
  }
}
