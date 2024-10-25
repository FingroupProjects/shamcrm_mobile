// dropdown_styles.dart

import 'package:flutter/material.dart';

const Color backgroundColor = Color(0xFFF4F7FD);
const Color textColor = Color(0xFFf1E2E52);

const TextStyle titleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  fontFamily: 'Gilroy',
  color: textColor,
);

Widget buildDropDownStyles({required String text, required bool isSelected}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 7),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Color(0xfff4F40EC) : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.transparent : Color(0xfff99A4BA),
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
              : Container(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: titleStyle,
          ),
        ),
        Image.asset(
          'assets/icons/arrow-right.png',
          width: 16,
          height: 16,
        ),
      ],
    ),
  );
}
