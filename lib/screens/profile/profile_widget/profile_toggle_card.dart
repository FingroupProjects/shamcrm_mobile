import 'package:flutter/material.dart';

class ProfileToggleCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileToggleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 223, 225, 249),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xFF1E1E1E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
            activeTrackColor: const Color.fromARGB(255, 91, 77, 235),
            inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179)
                .withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
