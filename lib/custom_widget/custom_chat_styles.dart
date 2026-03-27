// custom_chat_styles.dart

import 'package:flutter/material.dart';

class ChatSmsStyles {
  // AppBar Styles
  static const appBarBackgroundColor = Colors.white;
  static const appBarTitleColor = Color(0xfff1A202C);

  // Message Bubble Styles
  static const messageBubbleSenderColor = Color(0xfff4F40EC);
  static const messageBubbleReceiverColor = Colors.white;
  static const messageBubbleNoteColor = Color(0xFFFFDB64); // Цвет для заметок (#FFDB64)
  
  


  // Input Field Styles - ✅ ОБНОВЛЕНО: Современный дизайн как в Telegram
  static const hintTextColor = Color(0xFF999999); // Более мягкий серый для hint
  static const inputBackgroundColor = Color(0xFFFFFFFF); // Белый для glass effect
  static const inputBackgroundColorTransparent = Color(0x80FFFFFF); // Прозрачный белый (50% opacity)
  static const inputBorderRadius = BorderRadius.all(Radius.circular(20)); // ✅ Более скругленные углы (20px вместо 8px)
  static const inputBorderRadiusLarge = BorderRadius.all(Radius.circular(24)); // Для больших полей
  
  // ✅ Glass morphism эффект (эффект стекла)
  static BoxDecoration get inputFieldDecoration => BoxDecoration(
    color: inputBackgroundColorTransparent, // Прозрачный фон
    borderRadius: inputBorderRadius,
    border: Border.all(
      color: Colors.white.withOpacity(0.3), // Полупрозрачная белая рамка
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05), // Мягкая тень
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // ✅ Альтернативный стиль для темной темы (если понадобится)
  static BoxDecoration get inputFieldDecorationDark => BoxDecoration(
    color: const Color(0x80000000), // Полупрозрачный черный
    borderRadius: inputBorderRadius,
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Avatar Styles
  static const avatarRadius = 20.0;

  // Date Text Styles
  static const dateTextStyle = TextStyle(
    fontSize: 14,
    color: Color(0xfff1E2E52),
    fontWeight: FontWeight.w400,
    fontFamily: 'Gilroy',
  );

  // Message Text Styles
  static const messageTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
  );

  // Sender Message Text Styles
  static const senderMessageTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.white,
  );

  // Receiver Message Text Styles
  static const receiverMessageTextStyle = TextStyle(
    fontSize: 14,
    color: Color(0xfff2A313C),
  );
}
