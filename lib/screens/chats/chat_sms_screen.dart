import 'dart:async';
import 'dart:io';
import 'package:chat_bubbles/bubbles/bubble_normal_audio.dart';
import 'package:chat_bubbles/bubbles/bubble_special_one.dart';
import 'package:crm_task_manager/models/msg_data_in_socket.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late StreamSubscription<ChannelReadEvent> chatSubscribtion;
  late PusherChannelsClient socketClient;
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  bool isLoading = false;
  bool isPause = false;

  List<Message> messages = [];

  @override
  void initState() {
    messages = widget.messages;
    audioPlayer = AudioPlayer(); // AudioPlayer obyektini yaratamiz
    setUpServices();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // _connectWebSocket();
  }


  Future<void> setUpServices() async {
    print('--------------------------- start socket:::::::');
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
        // here you can handle connection errors.
        // refresh callback enables to reconnect the client
        print(exception);
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
        authorizationEndpoint:
            Uri.parse('https://shamcrm.com/broadcasting/auth'),
        headers: {'Authorization': 'Bearer $token'},
        onAuthFailed: (exception, trace) {
          print(exception);
        },
      ),
    );

    socketClient.onConnectionEstablished.listen((_) {
      print('--------------------------- connected socket:::::::');

      myPresenceChannel.subscribeIfNotUnsubscribed();

      chatSubscribtion = myPresenceChannel.bind('chat.message').listen((event) {
        MessageSocketData mm = messageSocketDataFromJson(event.data);
        print(event.data);
        print(event.channelName);
        print('--------');
        print(mm.message);
        print('--------');

        if (mm.message!.isMyMessage! == true) {
          Message msg = Message(
              id: mm.message!.id!,
              text: mm.message!.text ??= mm.message!.type!,
              type: mm.message!.type.toString(),
              isMyMessage: mm.message!.isMyMessage!);
          setState(() {
            messages.insert(0, msg);
          });
          _scrollToBottom();
        }
      });
    });

    try {
      await socketClient.connect();
    } catch (e) {
      print(e);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        // Endiga scroll qilish uchun maxScrollExtent dan foydalanamiz
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onSendInButton() async {
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
        // _sendMessageToWebSocket(messageText);
      } catch (e) {
        print('9.4. Ошибка отправки сообщения через API: $e');
      }
    } else {
      print('9.5. Сообщение пустое, отправка не выполнена');
    }
  }

  void _addMessageToLocalList(String messageText, bool isMyMessage) {
    setState(() {
      messages.insert(
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

  @override
  void dispose() {
    chatSubscribtion.cancel();
    _scrollController.dispose();
    audioPlayer.dispose(); // AudioPlayer obyektini yo'q qilamiz

    _messageController.dispose();
    socketClient.dispose();
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
                // key: UniqueKey(),
                itemCount: messages.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          InputField(
            onSend: _onSendInButton,
            onAttachFile: () {
              print('Attach file triggered');
            },
            onRecordVoice: () {
              print('Record voice triggered');
            },
            messageController: _messageController,
            sendRequestFunction: (File soundFile, String time) async {
              File sound = soundFile;

              print("the current path is ${soundFile.path}");

              // sendCahtAudioFile
              print('9.2. Отправка сообщения через API');
              await widget.apiService
                  .sendChatAudioFile(widget.chatId, sound.path);

              print('added aduio -----');
              // 2. Добавить сообщение в локальный список
              // _addMessageToLocalList(messageText, true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    switch (message.type) {
      case 'text':
        MessageBubble(
          message: message.text,
          time: "14:32", // Динамическое время
          isSender: message.isMyMessage,
        );
        return BubbleSpecialOne(
          text: message.text,
          isSender: message.isMyMessage,
          color: message.isMyMessage
          ? ChatSmsStyles.messageBubbleSenderColor
          : ChatSmsStyles.messageBubbleReceiverColor,
          textStyle: message.isMyMessage
          ? ChatSmsStyles.senderMessageTextStyle
          : ChatSmsStyles.receiverMessageTextStyle,
        );
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

      case 'voice':
        return BubbleNormalAudio(
          color: message.isMyMessage
              ? ChatSmsStyles.messageBubbleSenderColor
              : ChatSmsStyles.messageBubbleReceiverColor,
          duration: message.duration.inSeconds.toDouble(),  // Davomiylik to'g'ri o'rnatiladi
          position: message.position.inSeconds.toDouble().clamp(0.0, message.duration.inSeconds.toDouble()), // Hozirgi pozitsiya
          isPlaying: message.isPlaying,
          isSender: false,
          isLoading: isLoading,
          textStyle: message.isMyMessage
              ? ChatSmsStyles.senderMessageTextStyle
              : ChatSmsStyles.receiverMessageTextStyle,
          isPause: message.isPause,
          onSeekChanged: _changeSeek,
          onPlayPauseButtonClick: () => _playAudio(message),
          sent: false,
        );
      default:
        return Container(); // Для неизвестных типов сообщений
    }
  }


  void _changeSeek(double value) {
    setState(() {
      audioPlayer.seek(new Duration(seconds: value.toInt()));
    });
  }

  void _playAudio(Message message) async {
    final url = '${baseUrl.replaceAll('/api', '',)}/storage/${message.filePath}';
    print('audio url: $url');

    try {
      await audioPlayer.setUrl(url);

      // Tinglash davomida davomiylikni olish
      audioPlayer.durationStream.listen((Duration? d) {
        setState(() {
          if (d != null) {
            message.duration = d;  // To'g'ri davomiylikni o'rnatamiz
          } else {
            message.duration = Duration(seconds: 0); // Null bo'lsa, 0 ga o'rnatamiz
          }
        });
      });

      if (message.isPause) {
        // Agar oldin to'xtatilgan bo'lsa, davom ettiramiz
        await audioPlayer.play();
        setState(() {
          message.isPlaying = true;
          message.isPause = false;
        });
      } else if (message.isPlaying) {
        // Agar o'ynayotgan bo'lsa, to'xtatamiz
        await audioPlayer.pause();
        setState(() {
          message.isPlaying = false;
          message.isPause = true;
        });
      } else {
        // Yangi audio o'ynash
        await audioPlayer.play();
        setState(() {
          message.isPlaying = true;
        });
      }

      // Har bir xabar uchun pozitsiyani yangilash
      audioPlayer.positionStream.listen((Duration p) {
        setState(() {
          message.position = p;
        });
      });

      // Audio tugaganda
      audioPlayer.playerStateStream.listen((PlayerState state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            message.isPlaying = false;
            message.isPause = false;
            message.position = Duration();
          });
        }
      });
    } catch (e) {
      print("Audio o'ynatishda xato: $e");
    }
  }
  /*
  void _playAudio(String audioPathUrl) async {
    final url =
        '$baseUrl/storage/$audioPathUrl';
    if (isPause) {
      await audioPlayer.resume();
      setState(() {
        isPlaying = true;
        isPause = false;
      });
    } else if (isPlaying) {
      await audioPlayer.pause();
      setState(() {
        isPlaying = false;
        isPause = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
      await audioPlayer.play(UrlSource(url));
      setState(() {
        isPlaying = true;
      });
    }

    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        duration = d;
        isLoading = false;
      });
    });
    audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        position = p;
      });
    });
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        duration =  Duration();
        position =  Duration();
      });
    });
  }
  */

}

}



