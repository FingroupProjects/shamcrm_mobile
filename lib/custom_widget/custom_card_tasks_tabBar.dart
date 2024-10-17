import 'package:flutter/material.dart';

class TaskCardStyles {
  // Цвета и размеры для контейнеров
  static BoxDecoration taskCardDecoration = BoxDecoration(
    color: Color(0xffF4F7FD), // Исправлено: убрано лишнее "f" в коде цвета
    borderRadius: BorderRadius.circular(16),
  );

  // Стиль заголовка
  static const TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: Color(0xff1E2E52),
    fontFamily: 'Gilroy',
  );

  // Стиль текста для приоритетов
  static const TextStyle priorityStyle = TextStyle(
    color: Color(0xffEC6648),
    fontWeight: FontWeight.w500,
    fontSize: 12,
    fontFamily: 'Gilroy',
  );

  // Стиль контейнера приоритета
  static BoxDecoration priorityContainerDecoration = BoxDecoration(
    color: Color(0xffFCE3DE),
    borderRadius: BorderRadius.circular(5),
  );

  // Стиль для DropdownButton
  static BoxDecoration dropdownDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  );

  // Стиль для ElevatedButton
  static ButtonStyle selectedButtonStyle(bool isSelected) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? Color(0xff1E2E52) : Colors.grey[200],
      foregroundColor: isSelected ? Colors.white : Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
