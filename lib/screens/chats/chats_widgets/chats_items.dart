import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatItem {
  final String name;
  final String message;
  final String time;
  final int unredMessageCount;
  final String avatar;
  final String icon;

  ChatItem(this.name, this.message, this.time, this.avatar, this.icon, this.unredMessageCount);

  get id => null;
}

class ChatListItem extends StatelessWidget {
  final ChatItem chatItem;

  const ChatListItem({super.key, required this.chatItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(chatItem.avatar),
              radius: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      chatItem.icon,
                      width: 20,
                      height: 20,
                    ),
                    SizedBox(width: 4),
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
                formatChatTime(chatItem.time),
                style: AppStyles.chatTimeStyle,
              ),
              getUnredMessageWidget(chatItem.unredMessageCount)
            ],
          ),
        ],
      ),
    );
  }

  String formatChatTime(String time) {
    if (time.isEmpty) {
      return ''; 
    }
    
    try {
      DateTime parsedTime = DateTime.parse(time);
      return DateFormat('dd/MM/yyyy').format(parsedTime); 
    } catch (e) {
      print("Ошибка парсинга даты: $e");
      return ''; 
    }
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
