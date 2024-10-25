import 'package:flutter/material.dart';

class AppStyles {
  static const TextStyle chatNameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52), // Исправленный цвет (без лишней 'f')
  );

  static const TextStyle chatMessageStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff99A4BA),
  );

  static const TextStyle chatTimeStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff99A4BA),
  );
}

class ChatItem {
  final String name;
  final String message;
  final String time;
  final String avatar;
  final String icon; // Поле для иконки

  ChatItem({
    required this.name,
    required this.message,
    required this.time,
    required this.avatar,
    required this.icon,
  });

  // Метод для создания ChatItem из JSON
  factory ChatItem.fromJson(Map<String, dynamic> json) {
    return ChatItem(
      name: json['name'] ?? '',
      message: json['message'] ?? '',
      time: json['time'] ?? '',
      avatar: json['avatar'] ?? 'assets/default_avatar.png', // Файл по умолчанию
      icon: json['icon'] ?? 'assets/default_icon.png', // Файл по умолчанию
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatItem chatItem;

  const ChatListItem({Key? key, required this.chatItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: AssetImage(chatItem.avatar),
            radius: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      chatItem.icon, // Используем поле иконки
                      width: 20,
                      height: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      chatItem.name,
                      style: AppStyles.chatNameStyle,
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  chatItem.message,
                  style: AppStyles.chatMessageStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Text(
            chatItem.time,
            style: AppStyles.chatTimeStyle,
          ),
        ],
      ),
    );
  }
}
