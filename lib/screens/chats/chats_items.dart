import 'package:flutter/material.dart';

class AppStyles {
  static const TextStyle chatNameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Gilroy',
    color: Color(0xfff1E2E52),
  );

  static const TextStyle chatMessageStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xfff99A4BA),
  );

  static const TextStyle chatTimeStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xfff99A4BA),
  );
}

class ChatItem {
  final String name;
  final String message;
  final String time;
  final String avatar;
  final String icon; // Добавлено поле для иконки

  ChatItem(this.name, this.message, this.time, this.avatar, this.icon);

  get id => null;
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
            backgroundColor: Colors.white, // Укажите желаемый цвет фона
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
                    // Здесь добавлено использование иконки
                    Image.asset(
                      chatItem.icon, // Используем поле иконки
                      width: 20,
                      height: 20,
                    ),
                    SizedBox(width: 4), // Отступ между иконкой и текстом
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
