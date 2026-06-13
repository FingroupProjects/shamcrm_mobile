import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class SimpleSwitch extends StatelessWidget {
  final String? title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? onText;
  final String? offText;

  const SimpleSwitch({
    Key? key,
    this.title,
    required this.value,
    required this.onChanged,
    this.onText,
    this.offText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(
          title!,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        if (title != null) const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.42)),
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: colors.buttonPrimaryFg,
                  inactiveThumbColor: colors.surfacePrimary,
                  activeTrackColor: colors.buttonPrimaryBg,
                  inactiveTrackColor: colors.borderSubtle.withOpacity(0.5),
                ),
              ),
              if (onText != null && offText != null) const SizedBox(width: 10),
              if (onText != null && offText != null) Expanded(
                child: Text(
                  value ? onText! : offText!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
