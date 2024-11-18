<<<<<<< HEAD:lib/screens/chats/chats_widgets/chats_items.dart
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';

class ChatItem {
  final String name;
  final String message;
  final String time;
  final int unredMessageCount;
  final String avatar;
  final String icon; // Добавлено поле для иконки

  ChatItem(this.name, this.message, this.time, this.avatar, this.icon,
      this.unredMessageCount);

  get id => null;
}

class ChatListItem extends StatelessWidget {
  final ChatItem chatItem;

  const ChatListItem({super.key, required this.chatItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    Expanded(
                      child: Text(
                        chatItem.name.isNotEmpty ? chatItem.name : 'Без имени',
                        style: AppStyles.chatNameStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date(chatItem.time),
                style: AppStyles.chatTimeStyle,
              ),
              getUnredMessageWidget(chatItem.unredMessageCount)
            ],
          ),
        ],
      ),
    );
  }

  Widget getUnredMessageWidget(int unreadMessageCount) {
    if (unreadMessageCount > 0) {
      return Container(
        decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
        padding: EdgeInsets.all(8),
        child: Text(
          unreadMessageCount.toString(),
          style: AppStyles.chatTimeStyleWhite,
        ),
      );
    }
    return SizedBox();
  }
}
=======
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
>>>>>>> main:lib/screens/chats/chats_items.dart
