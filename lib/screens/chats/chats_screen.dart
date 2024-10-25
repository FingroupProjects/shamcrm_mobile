import 'dart:async';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ApiService apiService = ApiService();
  bool isNavigating = false;

  @override
  void initState() {
    super.initState();
    print('Инициализация ChatsScreen');
    _initializeFirebase();
  }

  void _initializeFirebase() async {
    await FirebaseApi().initNotifications();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Получено сообщение на переднем плане!');
      final chatId = message.data['chatId'];

      if (chatId != null) {
        print('Получено уведомление для чата с id: $chatId');
        
        // Передаем контекст и chatId
        checkChatExists(context, chatId).then((chatExists) async {
          if (chatExists) {
            print('Чат с id $chatId найден. Открываем его.');
            ChatItem? chatItem = await _buildChatItemById(int.parse(chatId)); // Используем await для получения результата Future
            if (chatItem != null) {
              apiService.getMessages(int.parse(chatId)).then((messages) {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatSmsScreen(
                        chatId: int.parse(chatId),
                        chatItem: chatItem,
                        messages: messages,
                      ),
                    ),
                  );
                }
              });
            } else {
              print('Ошибка: chatItem равен null.');
            }
          } else {
            print('Чат с id $chatId не найден в списке.');
          }
        });
      } else {
        print('chatId отсутствует в данных уведомления.');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final chatId = message.data['chatId'];

      if (chatId != null) {
        print('Открытие приложения через уведомление для чата с id: $chatId');
        
        // Передаем контекст и chatId
        checkChatExists(context, chatId).then((chatExists) async {
          if (chatExists) {
            print('Чат с id $chatId найден. Открываем его.');
            var chatItem = await _buildChatItemById(int.parse(chatId));
            var messages = await apiService.getMessages(int.parse(chatId));
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatSmsScreen(
                    chatId: int.parse(chatId),
                    chatItem: chatItem!,
                    messages: messages,
                  ),
                ),
              );
            }
          } else {
            print('Чат с id $chatId не найден в списке.');
          }
        }).catchError((error) {
          print('Ошибка при проверке существования чата: $error');
        });
      } else {
        print('chatId отсутствует в данных уведомления.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Chats>>(
        future: apiService.getAllChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки чатов: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет доступных чатов'));
          }

          final List<Chats> chats = snapshot.data!;
          for (var chat in chats) {
            print('ID чата: ${chat.id}, Имя: ${chat.name}');
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return GestureDetector(
                onTap: () async {
                  if (!isNavigating) {
                    isNavigating = true;
                    final messages = await apiService.getMessages(chat.id);
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
                      isNavigating = false; // Сбрасываем флаг навигации
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
      name: chat.name,
      message: chat.lastMessage,
      time: "08:00", // Здесь можно заменить на актуальное время
      avatar: "assets/images/AvatarChat.png",
      icon: _mapChannelToIcon(chat.channel),
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

  Future<ChatItem?> _buildChatItemById(int chatId) async {
    final chat = await apiService.getChatById(chatId);
    if (chat != null) {
      return ChatItem(
        name: chat.name,
        message: chat.lastMessage,
        time: "08:00",
        avatar: "assets/images/AvatarChat.png",
        icon: _mapChannelToIcon(chat.channel),
      );
    } else {
      print('Чат с id $chatId не найден.');
      return null;
    }
  }

  Future<bool> checkChatExists(BuildContext context, String chatId) async {
    final List<Chats> chats = await apiService.getAllChats();
    print('Полученный chatId: $chatId');
    print('Список id чатов: ${chats.map((chat) => chat.id).toList()}');

    for (var chat in chats) {
      if (chat.id == int.parse(chatId)) {
        print('Найден чат с id: $chatId');

        // Получение сообщений чата
        final messages = await apiService.getMessages(chat.id);

        // Переход на экран с сообщениями чата
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatSmsScreen(
              chatItem: _buildChatItem(chat),
              messages: messages,
              chatId: chat.id,
            ),
          ),
        );

        return true;
      }
    }
    print('Чат с id $chatId не найден.');
    return false;
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Обработка фонового сообщения: ${message.messageId}');
  print('Данные сообщения: ${message.data}');
  print('Заголовок уведомления: ${message.notification?.title}');
  print('Текст уведомления: ${message.notification?.body}');
}
