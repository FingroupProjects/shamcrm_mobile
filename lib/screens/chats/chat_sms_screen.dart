<<<<<<< HEAD
import 'dart:async';
import 'dart:io';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/models/msg_data_in_socket.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/image_message_bubble.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:crm_task_manager/utils/global_value.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/api_service_chats.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/file_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/message_bubble.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/input_field.dart';
import 'package:voice_message_package/voice_message_package.dart';

class ChatSmsScreen extends StatefulWidget {
  final ChatItem chatItem;
  final int chatId;
  final ApiService apiService = ApiService();
  final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

  ChatSmsScreen({
    super.key,
    required this.chatItem,
    required this.chatId,
  });

  @override
  State<ChatSmsScreen> createState() => _ChatSmsScreenState();
}

class _ChatSmsScreenState extends State<ChatSmsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  WebSocket? _webSocket;
  late StreamSubscription<ChannelReadEvent> chatSubscribtion;
  late PusherChannelsClient socketClient;

  late VoiceController audioController;

  @override
  void initState() {
    context.read<MessagingCubit>().getMessages(widget.chatId);
    setUpServices();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    // _connectWebSocket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ChatSmsStyles.appBarBackgroundColor,
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
          Expanded(child: messageListUi()),

          /// bottom ui
          inputWidget(),
        ],
      ),
    );
  }

  Widget messageListUi() {
    return BlocBuilder<MessagingCubit, MessagingState>(
      builder: (context, state) {
        if (state is MessagesErrorState) {
          return Center(child: Text(state.error));
        }
        if (state is MessagesLoadingState) {
          Center(child: CircularProgressIndicator.adaptive());
        }

        if (state is MessagesLoadedState) {
          if (state.messages.isEmpty) {
            return Center(
                child: Text(
              'Нет сообщений',
              style: TextStyle(color: AppColors.textPrimary700),
            ));
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              controller: _scrollController,
              // key: UniqueKey(),
              itemCount: state.messages.length,
              padding: EdgeInsets.zero,
              reverse: true,
              itemBuilder: (context, index) {
                return MessageItemWidget(
                  message: state.messages[index],
                  apiServiceDownload: widget.apiServiceDownload,
                );
              },
            ),
          );
        }

        return Container();
      },
    );
  }

  Widget inputWidget() {
    return InputField(
      onSend: _onSendInButton,
      onAttachFile: _onPickFilePressed,
      onRecordVoice: () {
        debugPrint('Record voice triggered');
      },
      messageController: _messageController,
      sendRequestFunction: (File soundFile, String time) async {
        context.read<ListenSenderVoiceCubit>().updateValue(true);
        debugPrint("the current path is ${soundFile.path}");
        String inputPath = '/path/to/recorded/file.mp4a';
        String outputPath = await getOutputPath('converted_file.ogg');

        File? convertedFile = await convertAudioFile(inputPath, outputPath);
        if (convertedFile != null) {
          String uploadUrl = '$baseUrl/chat/sendVoice/${widget.chatId}';
          await uploadFile(convertedFile, uploadUrl);
        } else {
          debugPrint('Conversion failed');
        }

        await widget.apiService.sendChatAudioFile(widget.chatId, soundFile);
        context.read<ListenSenderVoiceCubit>().updateValue(false);

      },
    );
  }

  Future<String> getOutputPath(String fileName) async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/$fileName';
  }

  Future<void> setUpServices() async {
    debugPrint('--------------------------- start socket:::::::');
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final customOptions = PusherChannelsOptions.custom(
      // You may also apply the given metadata in your custom uri
      uriResolver: (metadata) =>
          Uri.parse('wss://soketi.shamcrm.com/app/app-key'),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    socketClient = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint(exception);
        // refresh();
      },
      minimumReconnectDelayDuration: const Duration(
        seconds: 1,
      ),
    );

    final myPresenceChannel = socketClient.presenceChannel(
      'presence-chat.${widget.chatId}',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(baseUrlSocket),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': 'fingroup-back'
        },
        onAuthFailed: (exception, trace) {
          debugPrint(exception);
        },
      ),
    );

    socketClient.onConnectionEstablished.listen((_) {
      myPresenceChannel.subscribeIfNotUnsubscribed();

      chatSubscribtion = myPresenceChannel.bind('chat.message').listen((event) {
        MessageSocketData mm = messageSocketDataFromJson(event.data);
        print('----sender');
        print(mm.message!.sender!);

        if (kDebugMode) {
          print(event.data);
          print(event.channelName);
          print('------ socket');
          print('--------');
          print(mm.message);

          print('--------');
        }

        print('----------------------- check');
        print('---- user in app');
        print(userID);
        print('----- sender');
        print(mm.message!.sender);


        Message msg;
        if (mm.message!.type == 'voice' ||
            mm.message!.type == 'file' ||
            mm.message!.type == 'image' ||
            mm.message!.type == 'document') {
          msg = Message(
              id: mm.message!.id!,
              filePath: mm.message!.filePath.toString(),
              text: mm.message!.text ??= mm.message!.type!,
              type: mm.message!.type.toString(),
              isMyMessage:  (userID.value == mm.message!.sender!.id.toString() &&
                  mm.message!.sender!.type == 'user'),
              createMessateTime: mm.message!.createdAt.toString(),
              duration: Duration(
                  seconds: (mm.message!.voiceDuration != null)
                      ? double.parse(mm.message!.voiceDuration.toString())
                          .round()
                      : 20),
          );
        } else {
          msg = Message(
            id: mm.message!.id!,
            text: mm.message!.text ??= mm.message!.type!,
            type: mm.message!.type.toString(),
            createMessateTime: mm.message!.createdAt.toString(),
            isMyMessage: (userID.value == mm.message!.sender!.id.toString() &&
                mm.message!.sender!.type ==
                    'user'),
          );
        }
        setState(() {
          context.read<MessagingCubit>().addMessageFormSocket(msg);
        });
        _scrollToBottom();
      });
    });

    try {
      await socketClient.connect();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.pixels,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onSendInButton() async {
    context.read<ListenSenderTextCubit>().updateValue(true);
    if (kDebugMode) {
      print('9. Начало отправки сообщения');
    }

    final messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      try {
        debugPrint('9.2. Отправка сообщения через API');
        _messageController.clear();
        await widget.apiService.sendMessage(widget.chatId, messageText);
        context.read<ListenSenderTextCubit>().updateValue(false);
      } catch (e) {
        debugPrint('9.4. Ошибка отправки сообщения через API: $e');
      }
    } else {
      debugPrint('9.5. Сообщение пустое, отправка не выполнена');
    }
  }

  void _onPickFilePressed() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result != null) {
      debugPrint('------------------ select file');
      debugPrint(result.files.first.path!);

      context.read<ListenSenderFileCubit>().updateValue(true);
      await widget.apiService
          .sendChatFile(widget.chatId, result.files.first.path!);
      context.read<ListenSenderFileCubit>().updateValue(false);
    }
  }

  @override
  void dispose() {
    context.watch<ListenSenderFileCubit>().updateValue(false);
    context.watch<ListenSenderVoiceCubit>().updateValue(false);
    context.watch<ListenSenderTextCubit>().updateValue(false);

    chatSubscribtion.cancel();
    _scrollController.dispose();

    _messageController.dispose();
    socketClient.dispose();
    _webSocket
        ?.close();

    super.dispose();
  }
}

class MessageItemWidget extends StatelessWidget {
  final Message message;
  final ApiServiceDownload apiServiceDownload;

  const MessageItemWidget(
      {super.key, required this.message, required this.apiServiceDownload});

  @override
  Widget build(BuildContext context) {

    switch (message.type) {
      case 'text':
        return textState();
      case 'image':
        return imageState();
      case 'file':
      case 'document':
        return FileMessageBubble(
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          filePath: message.filePath ?? 'Unknown file format',
          fileName: message.text,
          onTap: (path) async {

            if (message.filePath != null && message.filePath!.isNotEmpty) {
              try {
                await apiServiceDownload.downloadAndOpenFile(message.filePath!);
              } catch (e) {
                if (kDebugMode) {
                  print('Error opening file: $e');
                }
              }
            } else {
              if (kDebugMode) {
                print('Invalid file path. Cannot open file.');
              }
            }
          },
        );
      case 'voice':
        return voiceState();
      default:
        return SizedBox();
      // return undefinedFileState();
    }
  }

  // this fun worked messages type == 'text'
  Widget textState() {
    return MessageBubble(
      message: message.text,
      time: time(message.createMessateTime), // Динамическое время
      isSender: message.isMyMessage,
    );
  }

  // this fun worked messages type == 'image'
  Widget imageState() {
    return ImageMessageBubble(
      time: time(message.createMessateTime),
      isSender: message.isMyMessage,
      filePath: message.filePath ?? 'Unknown file format',
      fileName: message.text,
      message: message,
    );
  }

  // this fun worked messages type - undefined type
  Widget undefinedFileState() {
    return FileMessageBubble(
      time: time(message.createMessateTime),
      isSender: message.isMyMessage,
      filePath: message.filePath ?? 'Unknown file format',
      fileName: message.text,
      onTap: (path) async {
        await apiServiceDownload.downloadAndOpenFile(message.filePath!);
      },
    );
  }

  // this fun worked messages type == 'voice
  Widget voiceState() {
    String audioUrl = '${baseUrl.replaceAll(
      '/api',
      '',
    )}/storage/${message.filePath}';

    final audioController = VoiceController(
      audioSrc: audioUrl,
      onComplete: () {
        /// do something on complete
      },
      onPause: () {
        /// do something on pause
      },
      onPlaying: () {
        /// do something on playing
      },
      onError: (err) {
        /// do somethin on error
      },
      maxDuration: Duration(minutes: 5),
      isFile: false,
    );
    return Container(
      margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          right: message.isMyMessage == false ? 60 : 0,
          left: message.isMyMessage ? 60 : 0),
      child: Column(
        crossAxisAlignment: message.isMyMessage
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          VoiceMessageView(
            innerPadding: 8,
            backgroundColor: message.isMyMessage
                ? ChatSmsStyles.messageBubbleSenderColor
                : ChatSmsStyles.messageBubbleReceiverColor,
            activeSliderColor: message.isMyMessage
                ? Colors.white
                : ChatSmsStyles.messageBubbleSenderColor,
            circlesColor: message.isMyMessage
                ? Colors.white.withOpacity(.2)
                : ChatSmsStyles.messageBubbleSenderColor,
            controller: audioController,
            counterTextStyle: TextStyle(
              color: message.isMyMessage
                  ? Colors.white
                  : ChatSmsStyles.messageBubbleSenderColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            time(message.createMessateTime),
            style: const TextStyle(
              fontSize: 12,
              color: ChatSmsStyles.appBarTitleColor,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
            ),
          )
        ],
      ),
    );
  }
}
=======
import 'dart:convert';
import 'dart:async';
import 'dart:io';
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


>>>>>>> main
