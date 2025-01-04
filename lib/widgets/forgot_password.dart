import 'package:flutter/material.dart';

class ForgotPassword extends StatelessWidget {
  final VoidCallback onPressed;

  ForgotPassword({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: const Text(
        'Забыли PIN - код?',
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xfff4F40EC),
          fontSize: 14,
        ),
      ),
    );
  }
}
