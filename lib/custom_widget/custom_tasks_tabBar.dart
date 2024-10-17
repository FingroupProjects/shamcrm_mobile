// lib/styles/task_styles.dart

import 'package:flutter/material.dart';

class TaskStyles {
  static const Color activeColor = Color(0xfff1E2E52);
  static const Color inactiveColor = Color(0xfff99A4BA);
  static const Color borderActiveColor = Color(0xfff1E2E52);
  static const Color borderInactiveColor = Color(0xfffDFE3EC);
  
  static const TextStyle tabTextStyle = TextStyle(
    fontWeight: FontWeight.w400,
    fontFamily: 'Gilroy',
    fontSize: 14,
  );

  static BoxDecoration tabButtonDecoration(bool isActive) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isActive ? borderActiveColor : borderInactiveColor,
        width: 1,
      ),
    );
  }
}
