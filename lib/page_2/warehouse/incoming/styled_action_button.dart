import 'package:flutter/material.dart';

class StyledActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const StyledActionButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: IntrinsicWidth(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 100,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}