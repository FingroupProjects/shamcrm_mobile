import 'package:flutter/material.dart';

class PinChangeWidget extends StatelessWidget {
  const PinChangeWidget({super.key});

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushReplacementNamed(context, '/pin_setup');
    },
    child: _buildPinOption(),
  );
}

  Widget _buildPinOption() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Pin icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 223, 225, 249),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.lock_outline,
                color: Color.fromARGB(255, 91,77,235),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // "Изменить пин-код" text
          const Expanded(
            child: Text(
              'Изменить пин-код',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xFF1E1E1E),
              ),
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
}