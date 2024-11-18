// custom_chat_styles.dart

import 'package:flutter/material.dart';

class ChatSmsStyles {
  // AppBar Styles
  static const appBarBackgroundColor = Colors.white;
  static const appBarTitleColor = Color(0xfff1A202C);

  // Message Bubble Styles
  static const messageBubbleSenderColor = Color(0xfff4F40EC);
  static const messageBubbleReceiverColor = Colors.white;

  // Input Field Styles
  static const hintTextColor = Color(0xfffCBD5E0);
  static const inputBackgroundColor = Color(0xffF4F7FD);
  static const inputBorderRadius = BorderRadius.all(Radius.circular(8));

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
