import 'package:flutter/material.dart';

class SaveHintBanner extends StatelessWidget {
  final String message;

  const SaveHintBanner({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w400,
          color: Color(0xffaeb4c3),
          height: 1.2,
        ),
      ),
    );
  }
}

