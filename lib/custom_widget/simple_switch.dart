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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(
          title!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        if (title != null) const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF4A90E2),
                  inactiveTrackColor: Colors.grey.withOpacity(0.5),
                ),
              ),
              if (onText != null && offText != null) const SizedBox(width: 10),
              if (onText != null && offText != null) Expanded(
                child: Text(
                  value ? onText! : offText!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
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
