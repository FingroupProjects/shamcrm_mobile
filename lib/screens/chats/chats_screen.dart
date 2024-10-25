import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';

class ChatsScreen extends StatelessWidget {
  final ApiService apiService = ApiService(); // Инициализация ApiService
  bool isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Chats>>(
        future: apiService
            .getAllChats(), // Использование метода для получения чатов
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Ошибка загрузки чатов: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет доступных чатов'));
          }

          final List<Chats> chats = snapshot.data!;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return GestureDetector(
                onTap: () async {
                  if (!isNavigating) {
                    isNavigating = true;
                    final messages = await apiService.getMessages(chat
                        .id); // Использование метода для получения сообщений
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatSmsScreen(
                          chatItem: _buildChatItem(chat),
                          messages: messages,
                          chatId: chat.id,
                        ),
                      ),
                    ).then((_) {
                      isNavigating = false;
                    });
                  }
                },
                child: ChatListItem(chatItem: _buildChatItem(chat)),
              );
            },
          );
        },
      ),
    );
  }

  ChatItem _buildChatItem(Chats chat) {
    return ChatItem(
      chat.name,
      chat.lastMessage,
      "08:00",
      "assets/images/AvatarChat.png",
      _mapChannelToIcon(chat.channel),
    );
  }

  String _mapChannelToIcon(String channel) {
    const channelIconMap = {
      'telegram_bot': 'assets/icons/leads/telegram.png',
      'telegram_account': 'assets/icons/leads/telegram.png',
      'whatsapp': 'assets/icons/leads/whatsapp.png',
      'instagram': 'assets/icons/leads/instagram.png',
      'facebook': 'assets/icons/leads/facebook.png',
    };
    return channelIconMap[channel] ?? 'assets/icons/leads/default.png';
  }
}
