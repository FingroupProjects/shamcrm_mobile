import 'dart:convert';
import 'dart:async';
import 'dart:io'; // Importing WebSocket from dart:io
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/api_service_chats.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/chats/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/file_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/message_bubble.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/input_field.dart';

class ChatSmsScreen extends StatefulWidget {
  final ChatItem chatItem;
  final List<Message> messages;
  final int chatId;
  final ApiService apiService = ApiService();
  final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

  ChatSmsScreen({
    Key? key,
    required this.chatItem,
    required this.messages,
    required this.chatId,
  }) : super(key: key);

  @override
  _ChatSmsScreenState createState() => _ChatSmsScreenState();
}

class _ChatSmsScreenState extends State<ChatSmsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  WebSocket? _webSocket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    try {
      print('1. Начало процесса подключения WebSocket');

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        print('2. Ошибка: Token is null. Please log in again.');
        throw Exception('Token is null. Please log in again.');
      } else {
        print('2. Токен успешно загружен: $token');
      }

      // Получение socket_id через WebSocket
      final socketId = await _getSocketId(token);
      print('3. Получен socket_id: $socketId'); // Логируем socket_id

      // Аутентификация через HTTP-запрос
      print('4. Начало процесса аутентификации на /broadcasting/auth');
      print('4.1. Отправка тела запроса: ${jsonEncode({
            'socket_id': socketId,
            'channel_name': 'presence-chat.${widget.chatId}'
          })}');

      final response = await http.post(
        Uri.parse('http://62.84.186.96/broadcasting/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'socket_id': socketId,
          'channel_name': 'presence-chat.${widget.chatId}',
        }),
      );

      print(
          '4.2. Получен ответ: ${response.statusCode} ${response.body}'); // Логируем статус ответа и тело

      if (response.statusCode != 200) {
        print('4.3. Ошибка аутентификации: ${response.body}');
        throw Exception('Ошибка аутентификации: ${response.body}');
      } else {
        print('4.3. Аутентификация прошла успешно');
      }

      // Подключение к WebSocket серверу
      print('5. Подключение к серверу WebSocket');
      _webSocket = await WebSocket.connect(
        'ws://62.84.186.96:6001/app/app-key?protocol=7&version=7&flash=false',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('5.1. WebSocket успешно подключен');

      // Подписка на канал после успешного подключения

      final subscriptionMessage = jsonEncode({
        'event': 'pusher:subscribe',
        'data': {
          'channel': 'presence-chat.${widget.chatId}',
          // 'token': 'Bearer $token', // Добавляем токен в данные подписки
        },
      });

      print('5.2. Подписка на канал с сообщением: $subscriptionMessage');
      _webSocket!.add(subscriptionMessage);

      print('5.3. Подписка на канал presence-chat.${widget.chatId} отправлена');

      // Обработка входящих сообщений
      _webSocket!.listen(
        (data) {
          print('Получено новое сообщение: $data');
          _handleIncomingMessage(data);

          // Handling successful subscription event
          if (data.contains('pusher:subscription_succeeded')) {
            print('Subscription to channel ${widget.chatId} succeeded.');
          }
        },
        onError: (error) {
          print('Ошибка WebSocket: $error');
        },
        onDone: () {
          print('Соединение с WebSocket закрыто');
        },
      );
    } catch (e) {
      print('Ошибка подключения к WebSocket: $e');
    }
  }

  Future<String> _getSocketId(String token) async {
    String socketId = '';

    // Примерная логика получения socket_id
    try {
      // Подключение к WebSocket для получения socket_id
      final url =
          'ws://62.84.186.96:6001/app/app-key?protocol=7&version=7&flash=false';
      final channel = await WebSocket.connect(url, headers: {
        'Authorization': 'Bearer $token',
      });

      final completer = Completer<String>();
      channel.listen((message) {
        try {
          final data = jsonDecode(message);
          if (data['event'] == 'pusher:connection_established' &&
              data['data'] is String) {
            final dataMap = jsonDecode(data['data']);
            socketId = dataMap['socket_id'];
            print('Получен socket_id: $socketId');
            completer.complete(socketId);
          }
        } catch (e) {
          print('Ошибка обработки сообщения: $e');
        }
      }, onError: (error) {
        print('Ошибка WebSocket: $error');
        completer.completeError(error);
      });

      socketId =
          await completer.future.timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('Таймаут при получении socket_id');
      });
      channel.close();
    } catch (e) {
      print('Ошибка получения socket_id: $e');
      throw e;
    }

    return socketId;
  }

  // Метод для обработки входящих сообщений
  void _handleIncomingMessage(dynamic messageJson) {
    print('Начало обработки входящего сообщения');

    // Проверка, что сообщение не null, не пустое и валидное
    if (messageJson == null || messageJson.isEmpty) {
      print('Ошибка: пустое или null сообщение');
      return;
    }

    try {
      // Попытка декодирования JSON
      final messageData = jsonDecode(messageJson);

      // Игнорирование системных сообщений (pusher:subscription_succeeded и т.д.)
      if (messageData['event'].startsWith('pusher:')) {
        print('Системное сообщение Pusher: ${messageData['event']}');
        return;
      }

      // Обработка пользовательских событий, например, new_message
      if (messageData['event'] == 'new_message' &&
          messageData.containsKey('data')) {
        final data = messageData['data'];
        if (data.containsKey('text') && data.containsKey('id')) {
          setState(() {
            widget.messages.insert(
              0,
              Message(
                id: data['id'],
                text: data['text'],
                type: data['type'] ?? 'text',
                isMyMessage: data['isMyMessage'] ?? false,
              ),
            );
          });
          _scrollToBottom();
        } else {
          print('Ошибка: Неверная структура сообщения: $data');
        }
      }
    } catch (e) {
      // Логирование ошибки
      print('Ошибка обработки сообщения: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onSend() async {
    print('9. Начало отправки сообщения');

    final messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      // 1. Вывести сообщение в консоль
      print('9.1. Сообщение для отправки: $messageText');

      try {
        print('9.2. Отправка сообщения через API');
        await widget.apiService.sendMessage(widget.chatId, messageText);

        // 2. Добавить сообщение в локальный список
        _addMessageToLocalList(messageText, true);
        print('9.3. Сообщение успешно отправлено через API');

        // 3. Отправить сообщение в WebSocket
        _sendMessageToWebSocket(messageText);
      } catch (e) {
        print('9.4. Ошибка отправки сообщения через API: $e');
      }
    } else {
      print('9.5. Сообщение пустое, отправка не выполнена');
    }
  }

  void _addMessageToLocalList(String messageText, bool isMyMessage) {
    setState(() {
      widget.messages.insert(
        0,
        Message(
          id: DateTime.now().millisecondsSinceEpoch,
          text: messageText,
          type: 'text',
          isMyMessage: isMyMessage,
        ),
      );
      _messageController.clear();
    });
    _scrollToBottom();
  }

  void _sendMessageToWebSocket(String messageText) {
    final messagePayload = {
      'event': 'client-new_message', // Это должно быть событие клиентского типа
      'data': {
        'chatId': widget.chatId,
        'text': messageText,
        'isMyMessage': true,
      },
    };

    print('Отправка сообщения в WebSocket: $messagePayload');

    try {
      _webSocket?.add(jsonEncode(messagePayload));
    } catch (e) {
      print('Ошибка при отправке сообщения в WebSocket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки сообщения: $e')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _webSocket
        ?.close(); // Закрытие WebSocket соединения при уничтожении виджета
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ChatSmsStyles.appBarBackgroundColor,
        leading: IconButton(
          icon:
              Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.chatItem.avatar),
              radius: ChatSmsStyles.avatarRadius,
            ),
            const SizedBox(width: 10),
            Text(
              widget.chatItem.name,
              style: const TextStyle(
                fontSize: 16,
                color: ChatSmsStyles.appBarTitleColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xffF4F7FD),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.messages.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final message = widget.messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          InputField(
            onSend: _onSend,
            onAttachFile: () {
              print('Attach file triggered');
            },
            onRecordVoice: () {
              print('Record voice triggered');
            },
            messageController: _messageController,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    switch (message.type) {
      case 'text':
        return MessageBubble(
          message: message.text,
          time: "14:32", // Динамическое время
          isSender: message.isMyMessage,
        );
      case 'file':
        return FileMessageBubble(
          time: "14:34",
          isSender: message.isMyMessage,
          filePath: message.filePath ?? 'Unknown file format',
          fileName: message.text,
          onTap: () async {
            await widget.apiServiceDownload
                .downloadAndOpenFile(message.filePath!);
          },
        );
      default:
        return Container(); // Для неизвестных типов сообщений
    }
  }
}


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/api/service/api_service_chats.dart';
// import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
// import 'package:crm_task_manager/screens/chats/chats_items.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/file_message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/pusher_service.dart';
// import 'package:flutter/material.dart';
// import 'package:crm_task_manager/models/chats_model.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/input_field.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';

// class PusherService {
//   final String _appKey = 'app-key';
//   final String _wsHost = '62.84.186.96';
//   final int _wsPort = 6001;

//   late WebSocketChannel channel;

//   Future<void> connect(String token) async {
//   final url = 'ws://$_wsHost:$_wsPort/app/$_appKey?protocol=7&version=7&flash=false';

//   channel = IOWebSocketChannel.connect(url, headers: {
//     'Authorization': 'Bearer $token',
//   });

//   // Слушаем входящие сообщения
//   channel.stream.listen((message) {
//     try {
//       final data = jsonDecode(message);
//       print('Received message: $data');

//       if (data['event'] == 'pusher:connection_established') {
//         // Проверяем, что data['data'] является строкой
//         if (data['data'] is String) {
//           final dataMap = jsonDecode(data['data']); // Декодируем строку JSON
//           final socketId = dataMap['socket_id']; // Получаем socket_id
//           print('Socket ID: $socketId');
//           _authenticate(socketId, token);
//         } else {
//           print('Ошибка: data["data"] не является строкой: ${data['data']}');
//         }
//       }
//     } catch (e) {
//       print('Ошибка при обработке сообщения: $e');
//     }
//   }, onError: (error) {
//     print('WebSocket error: $error');
//   }, onDone: () {
//     print('WebSocket connection closed');
//   });
// }


//   Future<void> _authenticate(String socketId, String token) async {
//     final response = await http.post(
//       Uri.parse('http://62.84.186.96/broadcasting/auth'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//       body: jsonEncode({
//         'socket_id': socketId,
//         'channel_name': 'presence-chat',
//       }),
//     );

//     if (response.statusCode != 200) {
//       print('Ошибка аутентификации: ${response.body}');
//       throw Exception('Ошибка аутентификации: ${response.body}');
//     } else {
//       print('Аутентификация прошла успешно');
//     }
//   }

//   void subscribe(String channelName) {
//     final subscribeMessage = {
//       'event': 'pusher:subscribe',
//       'data': {'channel': channelName},
//     };

//     channel.sink.add(jsonEncode(subscribeMessage));
//   }

//   void sendMessage(String channelName, String message) {
//     final messageData = {
//       'event': 'chat.message',
//       'data': {
//         'channel': channelName,
//         'message': message,
//       },
//     };

//     channel.sink.add(jsonEncode(messageData));
//   }

//   void disconnect() {
//     channel.sink.close();
//   }
// }

// class ChatSmsScreen extends StatefulWidget {
//   final ChatItem chatItem;
//   final List<Message> messages;
//   final int chatId;
//   final ApiService apiService = ApiService();
//   final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

//   ChatSmsScreen(
//       {Key? key,
//       required this.chatItem,
//       required this.messages,
//       required this.chatId})
//       : super(key: key);

//   @override
//   _ChatSmsScreenState createState() => _ChatSmsScreenState();
// }

// class _ChatSmsScreenState extends State<ChatSmsScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController = TextEditingController();
//   late PusherService pusherService;

//   @override
//   void initState() {
//     super.initState();
//     pusherService = PusherService();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//       _connectToPusher();
//     });
//   }

//   Future<void> _connectToPusher() async {
//     final token = '4XtzN4lYAxyx4lN9EfTgb3aBp7EkgDtlTyav9kala0d8304a';
//     await pusherService.connect(token);
//     // Не подписывайтесь здесь, пока не получите socket_id
//   }

//   Future<void> _onSend() async {
//     final messageText = _messageController.text.trim();

//     if (messageText.isNotEmpty) {
//       try {
//         await widget.apiService.sendMessage(widget.chatId, messageText);
//         pusherService.sendMessage('presence-chat.${widget.chatId}', messageText);

//         setState(() {
//           widget.messages.insert(
//             0,
//             Message(
//               id: DateTime.now().millisecondsSinceEpoch,
//               text: messageText,
//               type: 'text',
//               isMyMessage: true,
//             ),
//           );
//           _messageController.clear();
//         });

//         _scrollToBottom();
//       } catch (e) {
//         print('Ошибка отправки сообщения: $e');
//       }
//     }
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.minScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   void _onAttachFile() {
//     // Логика для прикрепления файла
//   }

//   void _onRecordVoice() {
//     // Логика для записи голосового сообщения
//   }

//   @override
//   void dispose() {
//     pusherService.disconnect();
//     _scrollController.dispose();
//     _messageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: ChatSmsStyles.appBarBackgroundColor,
//         leading: IconButton(
//           icon: Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundImage: AssetImage(widget.chatItem.avatar),
//               radius: ChatSmsStyles.avatarRadius,
//             ),
//             SizedBox(width: 10),
//             Text(
//               widget.chatItem.name,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: ChatSmsStyles.appBarTitleColor,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Gilroy',
//               ),
//             ),
//           ],
//         ),
//       ),
//       backgroundColor: const Color(0xffF4F7FD),
//       body: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.only(left: 16, right: 16),
//               child: ListView.builder(
//                 controller: _scrollController,
//                 itemCount: widget.messages.length,
//                 reverse: true,
//                 itemBuilder: (context, index) {
//                   final message = widget.messages[index];

//                   if (message.type == 'text') {
//                     return MessageBubble(
//                       message: message.text,
//                       time: "14:32",
//                       isSender: message.isMyMessage,
//                     );
//                   } else if (message.type == 'file') {
//                     return FileMessageBubble(
//                       time: "14:34",
//                       isSender: message.isMyMessage,
//                       filePath: message.filePath ?? 'Неизвестный формат файла',
//                       fileName: message.text,
//                       onTap: () async {
//                         await widget.apiServiceDownload.downloadAndOpenFile(message.filePath!);
//                       },
//                     );
//                   }

//                   return SizedBox.shrink();
//                 },
//               ),
//             ),
//           ),
//           InputField(
//             onSend: _onSend,
//             onAttachFile: _onAttachFile,
//             onRecordVoice: _onRecordVoice,
//             messageController: _messageController,
//           ),
//         ],
//       ),
//     );
//   }
// }




// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/api/service/api_service_chats.dart';
// import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
// import 'package:crm_task_manager/screens/chats/chats_items.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/file_message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/image_message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/voice_message_bubble.dart';
// import 'package:flutter/material.dart';
// import 'package:crm_task_manager/models/chats_model.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/input_field.dart';

// class ChatSmsScreen extends StatefulWidget {
//   final ChatItem chatItem;
//   final List<Message> messages;
//   final int chatId; // Добавляем chatId для отправки сообщений
//   final ApiService apiService = ApiService(); // Экземпляр ApiService
//   final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

//   ChatSmsScreen(
//       {Key? key,
//       required this.chatItem,
//       required this.messages,
//       required this.chatId})
//       : super(key: key);

//   @override
//   _ChatSmsScreenState createState() => _ChatSmsScreenState();
// }

// class _ChatSmsScreenState extends State<ChatSmsScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController =
//       TextEditingController(); // Контроллер для текста сообщения
      

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//     });
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.minScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Future<void> _onSend() async {
//     final messageText = _messageController.text.trim();

//     if (messageText.isNotEmpty) {
//       try {
//         await widget.apiService.sendMessage(widget.chatId, messageText);

//         setState(() {
//           widget.messages.insert(
//               0,
//               Message(
//                 id: DateTime.now().millisecondsSinceEpoch,
//                 text: messageText,
//                 type: 'text',
//                 isMyMessage: true,
//               ));
//           _messageController.clear();
//         });

//         _scrollToBottom();
//       } catch (e) {
//         print('Ошибка отправки сообщения: $e');
//       }
//     }
//   }

//   void _onAttachFile() {
//     // Логика для прикрепления файла
//   }

//   void _onRecordVoice() {
//     // Логика для записи голосового сообщения
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: ChatSmsStyles.appBarBackgroundColor,
//         leading: IconButton(
//           icon:
//               Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundImage: AssetImage(widget.chatItem.avatar),
//               radius: ChatSmsStyles.avatarRadius,
//             ),
//             SizedBox(width: 10),
//             Text(
//               widget.chatItem.name,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: ChatSmsStyles.appBarTitleColor,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Gilroy',
//               ),
//             ),
//           ],
//         ),
//       ),
//       backgroundColor: const Color(0xffF4F7FD),
//       body: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.only(left: 16,right: 16), // Отступы слева и справа
//               child: ListView.builder(
//                 controller: _scrollController,
//                 itemCount: widget.messages.length,
//                 reverse: true, // Сообщения сверху вниз
//                 itemBuilder: (context, index) {
//                   final message = widget.messages[index];

//                   if (message.type == 'text') {
//                     return MessageBubble(
//                       message: message.text,
//                       time: "14:32",
//                       isSender: message.isMyMessage,
//                     );
//                   } 
//                   // else if (message.type == 'voice') {
//                   //   return VoiceMessageBubble(
//                   //     time: "14:34",
//                   //     isSender: message.isMyMessage,
//                   //     filePath:
//                   //         message.filePath ?? 'Неизвестное голосовое сообщение',
//                   //   );
//                   // }
//                    else if (message.type == 'file') {
//                     return FileMessageBubble(
//                       time: "14:34",
//                       isSender: message.isMyMessage,
//                       filePath: message.filePath ?? 'Неизвестный формат файла',
//                       fileName: message.text,
//                       onTap: () async {
//                         await widget.apiServiceDownload
//                             .downloadAndOpenFile(message.filePath!);
//                       },
//                     );
//                   } 
//                   // else if (message.type == 'image') {
//                   //   return ImageMessageBubble(
//                   //     time: "14:34",
//                   //     isSender: message.isMyMessage,
//                   //     filePath: message.filePath ?? 'Неизвестное изображение',
//                   //     fileName: message.text,
//                   //   );
//                   // }

//                   return SizedBox
//                       .shrink(); // Пустой элемент для неизвестных типов
//                 },
//               ),
//             ),
//           ),
//           InputField(
//             onSend: _onSend,
//             onAttachFile: _onAttachFile,
//             onRecordVoice: _onRecordVoice,
//             messageController: _messageController,
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/api/service/api_service_chats.dart';
// import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
// import 'package:crm_task_manager/screens/chats/chats_items.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/file_message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/image_message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/message_bubble.dart';
// import 'package:crm_task_manager/models/chats_model.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/input_field.dart';

// class ChatSmsScreen extends StatefulWidget {
//   final ChatItem chatItem;
//   final List<Message> messages;
//   final int chatId;
//   final ApiService apiService = ApiService();
//   final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

//   ChatSmsScreen({
//     Key? key,
//     required this.chatItem,
//     required this.messages,
//     required this.chatId,
//   }) : super(key: key);

//   @override
//   _ChatSmsScreenState createState() => _ChatSmsScreenState();
// }

// class _ChatSmsScreenState extends State<ChatSmsScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController = TextEditingController();
//   IO.Socket? _socket;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//     });
//     _connectSocket();
//   }

//   Future<void> _connectSocket() async {
//     try {
//       print('1. Начало процесса подключения сокета');

//       final prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');

//       if (token == null) {
//         print('2. Ошибка: Token is null. Please log in again.');
//         throw Exception('Token is null. Please log in again.');
//       } else {
//         print('2. Токен успешно загружен: $token');
//       }

//       // 3. Аутентификация через HTTP-запрос
//       print('3. Начало процесса аутентификации');

//       final response = await http.post(
//         Uri.parse('http://62.84.186.96/broadcasting/auth'),
//         headers: {
//           'Authorization': 'Bearer ${token}',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode({
//           'socket_id': await _getSocketId(),
//           'channel_name': 'presence-chat.${widget.chatId}',
//         }),
//       );

//       if (response.statusCode != 200) {
//         print('3.1. Ошибка аутентификации: ${response.body}');
//         throw Exception('Ошибка аутентификации: ${response.body}');
//       } else {
//         print('3.1. Аутентификация прошла успешно');
//       }

//       // 4. Подключение к Socket.IO серверу
//       print('4. Подключение к серверу Socket.IO');
//      _socket = IO.io('http://62.84.186.96:6001', <String, dynamic>{
//   'transports': ['websocket', 'polling'],
//   'autoConnect': true,
//   'forceNew': true,
//   'query': {'token': token}
// });


//       _socket!.on('connect_error', (error) {
//         print('Socket.IO connect_error: $error');
//       });


//       _socket!.on('connect', (_) {
//         print('5. Подключение к серверу прошло успешно');
//         print('5.1 Socket ID: ${_socket!.id}');
//       });

//       _socket!.on('disconnect', (_) {
//         print('5.2. Отключено от сервера Socket.IO');
//       });

//       _socket!.on('message', (data) {
//         print('6. Получено новое сообщение: $data');
//         _handleIncomingMessage(data);
//       });

//       _socket!.on('error', (error) {
//         print('6.1. Ошибка Socket.IO: $error');
//       });
//     } catch (e) {
//       print('7. Ошибка подключения к Socket.IO: $e');
//     }
//   }

//   Future<String> _getSocketId() async {
//     // Реализуйте вашу логику для получения socket_id
//     return '7972037280.8977577839';
//   }

//   void _handleIncomingMessage(dynamic messageJson) {
//     print('7.1. Начало обработки входящего сообщения');
//     try {
//       final messageData = jsonDecode(messageJson);
//       if (messageData.containsKey('text') && messageData.containsKey('id')) {
//         print('7.2. Сообщение прошло валидацию');

//         setState(() {
//           widget.messages.insert(
//             0,
//             Message(
//               id: messageData['id'],
//               text: messageData['text'],
//               type: messageData['type'] ?? 'text',
//               isMyMessage: messageData['isMyMessage'] ?? false,
//             ),
//           );
//         });

//         _scrollToBottom();
//       } else {
//         print('7.2. Ошибка: Неверная структура сообщения: $messageData');
//       }
//     } catch (e) {
//       print('7.3. Ошибка обработки сообщения: $e');
//     }
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.minScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Future<void> _onSend() async {
//     print('8. Начало отправки сообщения');

//     final messageText = _messageController.text.trim();

//     if (messageText.isNotEmpty) {
//       try {
//         print('8.1. Отправка сообщения через API');
//         await widget.apiService.sendMessage(widget.chatId, messageText);

//         _addMessageToLocalList(messageText, true);
//         print('8.2. Сообщение успешно отправлено через API');

//         _sendMessageToSocket(messageText);
//       } catch (e) {
//         print('8.3. Ошибка отправки сообщения через API: $e');
//       }
//     } else {
//       print('8.4. Сообщение пустое, отправка не выполнена');
//     }
//   }

//   void _addMessageToLocalList(String messageText, bool isMyMessage) {
//     setState(() {
//       widget.messages.insert(
//         0,
//         Message(
//           id: DateTime.now().millisecondsSinceEpoch,
//           text: messageText,
//           type: 'text',
//           isMyMessage: isMyMessage,
//         ),
//       );
//       _messageController.clear();
//     });
//     _scrollToBottom();
//   }

//   void _sendMessageToSocket(String messageText) {
//     final messagePayload = {
//       'chatId': widget.chatId,
//       'text': messageText,
//       'isMyMessage': true,
//     };

//     print('9. Отправка сообщения в Socket.IO: $messagePayload');

//     _socket?.emit('send_message', jsonEncode(messagePayload));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: ChatSmsStyles.appBarBackgroundColor,
//         leading: IconButton(
//           icon:
//               Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundImage: AssetImage(widget.chatItem.avatar),
//               radius: ChatSmsStyles.avatarRadius,
//             ),
//             const SizedBox(width: 10),
//             Text(
//               widget.chatItem.name,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: ChatSmsStyles.appBarTitleColor,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Gilroy',
//               ),
//             ),
//           ],
//         ),
//       ),
//       backgroundColor: const Color(0xffF4F7FD),
//       body: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: ListView.builder(
//                 controller: _scrollController,
//                 itemCount: widget.messages.length,
//                 reverse: true,
//                 itemBuilder: (context, index) {
//                   final message = widget.messages[index];
//                   return _buildMessageBubble(message);
//                 },
//               ),
//             ),
//           ),
//           InputField(
//             onSend: _onSend,
//             onAttachFile: () {
//               print('Attach file triggered');
//             },
//             onRecordVoice: () {
//               print('Record voice triggered');
//             },
//             messageController: _messageController,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageBubble(Message message) {
//     switch (message.type) {
//       case 'text':
//         return MessageBubble(
//           message: message.text,
//           time: "14:32", // Динамическое время
//           isSender: message.isMyMessage,
//         );
//       case 'file':
//         return FileMessageBubble(
//           time: "14:34",
//           isSender: message.isMyMessage,
//           filePath: message.filePath ?? 'Unknown file format',
//           fileName: message.text,
//           onTap: () async {
//             await widget.apiServiceDownload
//                 .downloadAndOpenFile(message.filePath!);
//           },
//         );
//       default:
//         return Container(); // Для неизвестных типов сообщений
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _messageController.dispose();
//     _socket
//         ?.disconnect(); // Закрытие Socket.IO соединения при уничтожении виджета
//     super.dispose();
//   }
// }



// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:pusher_client/pusher_client.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/api/service/api_service_chats.dart';
// import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
// import 'package:crm_task_manager/screens/chats/chats_items.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/file_message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/image_message_bubble.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/message_bubble.dart';
// import 'package:crm_task_manager/models/chats_model.dart';
// import 'package:crm_task_manager/screens/chats/chats_widgets/input_field.dart';

// class ChatSmsScreen extends StatefulWidget {
//   final ChatItem chatItem;
//   final List<Message> messages;
//   final int chatId;
//   final ApiService apiService = ApiService();
//   final ApiServiceDownload apiServiceDownload = ApiServiceDownload();
//   final String appKey = 'app-key'; // Замените на ваш реальный ключ Pusher
//   final String cluster = 'mt1'; // Замените на ваш реальный кластер

//   ChatSmsScreen({
//     Key? key,
//     required this.chatItem,
//     required this.messages,
//     required this.chatId,
//   }) : super(key: key);

//   @override
//   _ChatSmsScreenState createState() => _ChatSmsScreenState();
// }

// class _ChatSmsScreenState extends State<ChatSmsScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController = TextEditingController();
//   late PusherClient _pusher;
//   late Channel _channel;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//     });
//     _authenticateAndConnect();
//   }

//   Future<void> _authenticateAndConnect() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');

//       if (token == null) {
//         throw Exception('Token is null. Please log in again.');
//       }

//       print('Token: $token');

//       // Получение socket_id для аутентификации
//       // String socketId = _pusher.socketId;
//       // print('Socket ID: $socketId');

//       // Аутентификация пользователя с помощью Pusher
//       final response = await http.post(
//         Uri.parse('http://62.84.186.96/broadcasting/auth'), // Замените на ваш реальный эндпоинт
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: jsonEncode({
//           'socket_id': '7972037280.8977577839',
//           'channel_name': 'presence-chat.${widget.chatId}',
//         }),
//       );

//       if (response.statusCode == 200) {
//         _initPusher(token); // Инициализация Pusher с токеном
//       } else {
//         print('Authentication error: ${response.statusCode} ${response.body}');
//       }
//     } catch (e) {
//       print('Error authenticating or connecting: $e');
//     }
//   }

//   void _initPusher(String token) {
//     _pusher = PusherClient(
//       widget.appKey,
//       PusherOptions(
//         cluster: widget.cluster,
//         host: '62.84.186.96',
//         wsPort: 6001,
//         auth: PusherAuth(
//           'http://62.84.186.96/broadcasting/auth', // Ваш эндпоинт аутентификации
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',
//           },
//         ),
//       ),
//       autoConnect: false,
//     );

//     _pusher.connect();

//     _channel = _pusher.subscribe('presence-chat.${widget.chatId}');

//     _channel.bind('pusher:subscription_succeeded', (event) {
//       print('Successfully subscribed to channel');
//     });

//     _channel.bind('chat.message', (event) {
//       _handleIncomingMessage(event!.data);
//     });
//   }

//   void _handleIncomingMessage(String? messageJson) {
//     if (messageJson != null) {
//       try {
//         final messageData = jsonDecode(messageJson);
//         if (messageData.containsKey('text') && messageData.containsKey('id')) {
//           setState(() {
//             widget.messages.insert(
//               0,
//               Message(
//                 id: messageData['id'],
//                 text: messageData['text'],
//                 type: messageData['type'] ?? 'text',
//                 isMyMessage: messageData['isMyMessage'] ?? false,
//               ),
//             );
//           });
//           _scrollToBottom();
//         } else {
//           print('Error: Invalid message structure: $messageData');
//         }
//       } catch (e) {
//         print('Error processing message: $e');
//       }
//     }
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.minScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Future<void> _onSend() async {
//     final messageText = _messageController.text.trim();
//     if (messageText.isNotEmpty) {
//       try {
//         await widget.apiService.sendMessage(widget.chatId, messageText);
//         _addMessageToLocalList(messageText, true);
//         _sendMessageToPusher(messageText);
//       } catch (e) {
//         print('Error sending message: $e');
//       }
//     } else {
//       print('Message is empty, not sent');
//     }
//   }

//   void _addMessageToLocalList(String messageText, bool isMyMessage) {
//     setState(() {
//       widget.messages.insert(
//         0,
//         Message(
//           id: DateTime.now().millisecondsSinceEpoch,
//           text: messageText,
//           type: 'text',
//           isMyMessage: isMyMessage,
//         ),
//       );
//       _messageController.clear();
//     });
//     _scrollToBottom();
//   }

//   void _sendMessageToPusher(String messageText) {
//     final messagePayload = {
//       'chatId': widget.chatId,
//       'text': messageText,
//       'isMyMessage': true,
//     };

//     _channel.trigger('chat.message', messagePayload);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: ChatSmsStyles.appBarBackgroundColor,
//         leading: IconButton(
//           icon: Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundImage: AssetImage(widget.chatItem.avatar),
//               radius: ChatSmsStyles.avatarRadius,
//             ),
//             const SizedBox(width: 10),
//             Text(
//               widget.chatItem.name,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: ChatSmsStyles.appBarTitleColor,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Gilroy',
//               ),
//             ),
//           ],
//         ),
//       ),
//       backgroundColor: const Color(0xffF4F7FD),
//       body: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: ListView.builder(
//                 controller: _scrollController,
//                 itemCount: widget.messages.length,
//                 reverse: true,
//                 itemBuilder: (context, index) {
//                   final message = widget.messages[index];
//                   return _buildMessageBubble(message);
//                 },
//               ),
//             ),
//           ),
//           InputField(
//             onSend: _onSend,
//             onAttachFile: () {
//               print('Attach file triggered');
//             },
//             onRecordVoice: () {
//               print('Record voice triggered');
//             },
//             messageController: _messageController,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageBubble(Message message) {
//     switch (message.type) {
//       case 'text':
//         return MessageBubble(
//           message: message.text,
//           time: "14:32", // Временная метка может быть динамической
//           isSender: message.isMyMessage,
//         );
//       case 'file':
//         return FileMessageBubble(
//           time: "14:34",
//           isSender: message.isMyMessage,
//           filePath: message.filePath ?? 'Unknown file format',
//           fileName: message.text,
//           onTap: () async {
//             await widget.apiServiceDownload.downloadAndOpenFile(message.filePath!);
//           },
//         );
//       // case 'image':
//       //   return ImageMessageBubble(
//       //     time: "14:36",
//       //     isSender: message.isMyMessage,
//       //     imageUrl: message.text,
//       //   );
//       default:
//         return Container(); // На случай, если тип сообщения неизвестен
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _messageController.dispose();
//     _pusher.disconnect(); // Обязательно отключаем Pusher при уничтожении виджета
//     super.dispose();
//   }
// }
