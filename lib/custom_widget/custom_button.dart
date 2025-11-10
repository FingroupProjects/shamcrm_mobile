  import 'package:flutter/material.dart';

  class CustomButton extends StatelessWidget {
    final String buttonText;
    final VoidCallback? onPressed;
    final Color buttonColor;
    final Color textColor;
    final Widget? child;
    final bool isLoading;

    CustomButton({
      required this.buttonText,
      required this.onPressed,
      required this.buttonColor,
      required this.textColor,
      this.child,
      this.isLoading = false,
    });

    @override
    Widget build(BuildContext context) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : (child ?? 
                  Text(
                    buttonText,
                    style: TextStyle(fontSize: 14, color: textColor, fontFamily: 'Gilroy'),
                  )),
        ),
      );
    }
  }
