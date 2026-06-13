import 'package:flutter/material.dart';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

Widget buildDropDownStyles({
  required BuildContext context,
  required String text,
  required bool isSelected,
}) {
  final backgroundColor = context.appColors.surfacePrimary;
  final textColor = context.appColors.textPrimary;
  final borderColor = context.appColors.borderSubtle;
  final selectedColor = context.appColors.buttonPrimaryBg;

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 7),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor.withValues(alpha: 0.45)),
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? selectedColor : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.transparent : borderColor,
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: textColor,
            ),
          ),
        ),
        Image.asset(
          'assets/icons/arrow-right.png',
          width: 16,
          height: 16,
          color: context.appColors.iconSecondary,
        ),
      ],
    ),
  );
}
