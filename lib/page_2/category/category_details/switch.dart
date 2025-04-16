import 'package:flutter/material.dart';

class PriceAffectSwitcher extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const PriceAffectSwitcher({
    Key? key,
    required this.isActive,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Текстовая часть
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Влияет на цену',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Если включено, характеристики категории будут влиять на формирование цены товара',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                    color: Color(0x991E2E52), // прозрачный серый текст
                  ),
                ),
              ],
            ),
          ),

          // Переключатель
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
            activeTrackColor: const Color(0xFF4759FF), // можно заменить на ChatSmsStyles.messageBubbleSenderColor
            inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
          ),
        ],
      ),
    );
  }
}
