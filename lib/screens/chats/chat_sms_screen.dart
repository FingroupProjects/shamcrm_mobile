import 'dart:async';
import 'dart:io';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_event.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_state.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/models/msg_data_in_socket.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chatById_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chatById_task_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/image_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_corporate_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_user_corporate.dart';
import 'package:crm_task_manager/screens/chats/pin_message_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final String endPointInTab;
  final bool canSendMessage;
  final ApiService apiService = ApiService();
  final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

  ChatSmsScreen({
    super.key,
    required this.chatItem,
    required this.chatId,
    required this.endPointInTab,
    required this.canSendMessage,
  });

  @override
  State<ChatSmsScreen> createState() => _ChatSmsScreenState();
}

class _ChatSmsScreenState extends State<ChatSmsScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _currentDate;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); 
  WebSocket? _webSocket;
  late StreamSubscription<ChannelReadEvent> chatSubscribtion;
  late PusherChannelsClient socketClient;

  late VoiceController audioController;
  final ApiService apiService = ApiService();
  String? _visibleDate;
  late String baseUrl;
  bool _canCreateChat = false;
  bool _isRequestInProgress = false;
  int? _highlightedMessageId;
  bool _isMenuOpen = false;

  Future<void> _checkPermissions() async {
    if (widget.endPointInTab == 'lead') {
      final canCreate = await apiService.hasPermission('chat.create');
      setState(() {
        _canCreateChat = canCreate;
      });
    } else {
      setState(() {
        _canCreateChat = true;
      });
    }
  }

  @override
  void initState() {
    _checkPermissions();
    context.read<MessagingCubit>().getMessages(widget.chatId);

    context.read<ListenSenderFileCubit>().updateValue(false);
    context.read<ListenSenderVoiceCubit>().updateValue(false);
    context.read<ListenSenderTextCubit>().updateValue(false);

    setUpServices();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _fetchBaseUrl();
      // _markMessagesAsRead();
    });
  }

  // void _markMessagesAsRead() {
  //   final state = context.read<MessagingCubit>().state;
  //   if (state is MessagesLoadedState && state.messages.isNotEmpty) {
  //     final messageIds = state.messages.map((msg) => msg.id).toList();
  //     widget.apiService.readChatMessages(widget.chatId, messageIds);
  //   }
  // }

  Future<void> _fetchBaseUrl() async {
    baseUrl = await apiService.getDynamicBaseUrl();
  }

  // Обновляем показ календаря
  void _showDatePicker(BuildContext context, List<Message> messages) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('go_to_date'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 400,
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  onDateChanged: (date) {
                    final index = _findMessageIndexByDate(messages, date);
                    if (index != -1) {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToMessageIndex(index);
                      });
                    } else {
                      // Обработка, если нет сообщений на выбранную дату
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _findMessageIndexByDate(List<Message> messages, DateTime targetDate) {
    // Ищем последний индекс сообщения с указанной датой
    int lastIndex = -1;
    for (int i = 0; i < messages.length; i++) {
      final messageDate = DateTime.parse(messages[i].createMessateTime);
      if (isSameDay(messageDate, targetDate)) {
        lastIndex = i; // Сохраняем последний найденный индекс
      }
    }
    return lastIndex;
  }

  void _scrollToMessageIndex(int index) {
    if (_scrollController.hasClients) {
      final state = context.read<MessagingCubit>().state;
      if (state is MessagesLoadedState) {
        final messagesLength = state.messages.length;

        // Вычисляем высоту одного элемента
        final maxScroll = _scrollController.position.maxScrollExtent;
        final itemHeight = maxScroll / messagesLength;

        // Целевая позиция для движения
        final targetPosition = index * itemHeight;

        // Скроллим к позиции
        _scrollController.animateTo(
          targetPosition.clamp(0.0, maxScroll), // Ограничение для корректности
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

        // Обновляем текущую видимую дату
        if (index >= 0 && index < state.messages.length) {
          setState(() {
            _currentDate = formatDate(
              DateTime.parse(state.messages[index].createMessateTime),
            );
          });
        }
      }
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  Widget _buildAvatar(String avatar) {
    // Проверяем, содержит ли SVG
    if (avatar.contains('<svg')) {
      // Проверяем, есть ли в SVG тег `<image>` с URL
      final imageUrl = extractImageUrlFromSvg(avatar);
      if (imageUrl != null) {
        return Container(
          width: ChatSmsStyles.avatarRadius * 2,
          height: ChatSmsStyles.avatarRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        // Проверяем на наличие текста в SVG
        final text = extractTextFromSvg(avatar);
        final backgroundColor = extractBackgroundColorFromSvg(avatar);

        if (text != null && backgroundColor != null) {
          return Container(
            width: ChatSmsStyles.avatarRadius * 2,
            height: ChatSmsStyles.avatarRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          // Рендерим сам SVG
          return SvgPicture.string(
            avatar,
            width: ChatSmsStyles.avatarRadius * 2,
            height: ChatSmsStyles.avatarRadius * 2,
            placeholderBuilder: (context) => CircularProgressIndicator(),
          );
        }
      }
    }

    // Если это не SVG, предполагаем, что это локальное изображение
    return CircleAvatar(
      backgroundImage: AssetImage(avatar),
      radius: ChatSmsStyles.avatarRadius,
      backgroundColor: Colors.white,
    );
  }

  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  String? extractTextFromSvg(String svg) {
    final textMatch = RegExp(r'<text[^>]*>(.*?)</text>').firstMatch(svg);
    return textMatch?.group(1);
  }

  Color? extractBackgroundColorFromSvg(String svg) {
    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    if (fillMatch != null) {
      final colorHex = fillMatch.group(1);
      if (colorHex != null) {
        // Конвертируем hex в Color
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteMessageBloc, DeleteMessageState>(
      listener: (context, state) {
        if (state is DeleteMessageSuccess) {
          context.read<MessagingCubit>().getMessages(widget.chatId);

          if (widget.endPointInTab == 'task' ||
              widget.endPointInTab == 'corporate') {
            final chatsBloc = context.read<ChatsBloc>();
            chatsBloc.add(ClearChats());
            chatsBloc.add(FetchChats(endPoint: widget.endPointInTab));
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ChatSmsStyles.appBarBackgroundColor,
          leading: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: InkWell(
            onTap: () async {
              if (_isRequestInProgress) return; // Блокируем повторные нажатия
              setState(() {
                _isRequestInProgress = true;
              });

              try {
                if (widget.endPointInTab == 'lead') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserProfileScreen(chatId: widget.chatId),
                    ),
                  );
                } else if (widget.endPointInTab == 'task') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TaskByIdScreen(chatId: widget.chatId),
                    ),
                  );
                } else if (widget.endPointInTab == 'corporate') {
                  final getChatById =
                      await ApiService().getChatById(widget.chatId);
                  if (getChatById.chatUsers.length == 2 &&
                      getChatById.group == null) {
                    String userIdCheck = '';
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    userIdCheck = prefs.getString('userID') ?? '';
                    final participant = getChatById.chatUsers
                        .firstWhere((user) =>
                            user.participant.id.toString() != userIdCheck)
                        .participant;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParticipantProfileScreen(
                          userId: participant.id.toString(),
                          image: participant.image,
                          name: participant.name,
                          email: participant.email,
                          phone: participant.phone,
                          login: participant.login,
                          lastSeen: participant.lastSeen.toString(),
                          buttonChat: false,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CorporateProfileScreen(
                          chatId: widget.chatId,
                          chatItem: widget.chatItem,
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ОШИБКА!',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } finally {
                setState(() {
                  _isRequestInProgress = false;
                });
              }
            },
            child: Row(
              children: [
                _buildAvatar(widget.chatItem.avatar), 
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.chatItem.name.isEmpty
                        ? AppLocalizations.of(context)!.translate('no_name')
                        : widget.chatItem.name,
                    style: const TextStyle(
                      fontSize: 18,
                      color: ChatSmsStyles.appBarTitleColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: const Color(0xffF4F7FD),
        body: Column(
          children: [
            Expanded(child: messageListUi()),
            if (widget.canSendMessage && _canCreateChat)
              inputWidget()
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Center(
                  child: Text(
                    widget.canSendMessage
                        ? AppLocalizations.of(context)!
                            .translate('not_premission_to_send_sms')
                        : AppLocalizations.of(context)!
                            .translate('24_hour_leads'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      color: AppColors.textPrimary700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// Исправленный метод для прокрутки к сообщению
void _scrollToMessageReply(int messageId) {
  final state = context.read<MessagingCubit>().state;
  if (state is MessagesLoadedState || state is PinnedMessageState) {
    final messages = state is MessagesLoadedState
        ? state.messages
        : (state as PinnedMessageState).messages;

    final messageIndex = messages.indexWhere((msg) => msg.id == messageId);

    if (messageIndex != -1) {
      final message = messages[messageIndex];

      _scrollController.animateTo(
        messageIndex * 95.0,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );

      // Подсвечиваем сообщение
      setState(() {
        _highlightedMessageId = message.id;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }
}



Widget messageListUi() {
  return BlocBuilder<MessagingCubit, MessagingState>(
    builder: (context, state) {
      if (state is MessagesErrorState) {
        return Center(child: Text("An error occurred"));
      }
      if (state is MessagesLoadingState) {
        return Center(child: CircularProgressIndicator.adaptive());
      }
 if (state is MessagesLoadedState || state is ReplyingToMessageState || state is PinnedMessageState || state is EditingMessageState) {
  final messages = state is MessagesLoadedState
      ? state.messages
      : state is ReplyingToMessageState
          ? state.messages
          : state is PinnedMessageState
              ? state.messages
              : (state as EditingMessageState).messages;

  final pinnedMessage = state is PinnedMessageState
      ? state.pinnedMessage
      : state is ReplyingToMessageState
          ? state.pinnedMessage
          : state is EditingMessageState
              ? state.pinnedMessage
              : null;
        
        String _getMessageText(Message message) {
           if (message.type == 'voice') {
              return 'Голосовое сообщение'; 
            }
            return message.text; 
          }

        if (messages.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.translate('not_sms'),
              style: TextStyle(color: AppColors.textPrimary700),
            ),
          );
        }

        // Отображаем список сообщений
       List<Widget> messageWidgets = [];
        DateTime? currentDate;
        List<Widget> currentGroup = [];
        
        for (int i = messages.length - 1; i >= 0; i--) {
          final message = messages[i];
          final messageDate = DateTime.parse(message.createMessateTime);
        
          // Логика группировки сообщений по датам
          if (currentDate == null || !isSameDay(currentDate, messageDate)) {
            if (currentGroup.isNotEmpty) {
              messageWidgets.addAll(currentGroup);
              currentGroup = [];
            }
        
            currentGroup.add(
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: GestureDetector(
                  onTap: () => _showDatePicker(context, messages),
                  child: Center(
                    child: Text(
                      formatDate(messageDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Gilroy",
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            );
            currentDate = messageDate;
          }
        
          currentGroup.add(
            MessageItemWidget(
              message: message,
              chatId: widget.chatId,
              endPointInTab: widget.endPointInTab,
              apiServiceDownload: widget.apiServiceDownload,
              baseUrl: baseUrl,
              onReplyTap: _scrollToMessageReply,
              highlightedMessageId: _highlightedMessageId,
              onMenuStateChanged: (isOpen) {
                setState(() {
                  _isMenuOpen = isOpen;
                });
              },
              focusNode: _focusNode, 
            ),
          );
        }
        
        if (currentGroup.isNotEmpty) {
          messageWidgets.addAll(currentGroup);
        }
        
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                reverse: true,
                children: [
                  ...messageWidgets.reversed.toList(),
                ],
              ),
            ),
            if (pinnedMessage != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: PinnedMessageWidget(
                    message: _getMessageText(pinnedMessage),
                    onUnpin: () {
                      context.read<MessagingCubit>().unpinMessage();
                    },
              onTap: () {
                  _scrollToMessageReply(pinnedMessage.id); 
                },
                  ),
                ),
              ),
            if (_isMenuOpen)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
          ],
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
      focusNode: _focusNode, 
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

        try {
          await widget.apiService.sendChatAudioFile(widget.chatId, soundFile);
        } catch (e) {
          context.read<ListenSenderVoiceCubit>().updateValue(false);
        }
        context.read<ListenSenderVoiceCubit>().updateValue(false);
      },
    );
  }

  Future<String> getOutputPath(String fileName) async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/$fileName';
  }

  void setUpServices() async {
    debugPrint('--------------------------- start socket:::::::');
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final baseUrlSocket = await apiService.getSocketBaseUrl();
    final enteredDomainMap = await ApiService().getEnteredDomain();
    // Извлекаем значения из Map
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    final customOptions = PusherChannelsOptions.custom(
      uriResolver: (metadata) =>
          Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
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
        authorizationEndpoint: Uri.parse(
            'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': '$enteredDomain-back',
        },
        onAuthFailed: (exception, trace) {
          debugPrint(exception);
        },
      ),
    );

    socketClient.onConnectionEstablished.listen((_) {
      myPresenceChannel.subscribeIfNotUnsubscribed();
      chatSubscribtion = myPresenceChannel.bind('chat.message').listen((event) async {
        MessageSocketData mm = messageSocketDataFromJson(event.data);
        print('=====================================');
        print('==================EVENT DATA======START=============');
        print(event.data);
        print('==================EVENT DATA======END=============');

        print('----sender');
        print(mm.message?.text ?? 'No text');
        print(mm.message?.sender?.name ?? 'Unknown sender');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String UUID = prefs.getString('userID') ?? '';
        print('userID : $UUID');

        Message msg;
        if (mm.message?.type == 'voice' ||
            mm.message?.type == 'file' ||
            mm.message?.type == 'image' ||
            mm.message?.type == 'document') {
          ForwardedMessage? forwardedMessage;
          if (mm.message?.forwardedMessage != null) {
            forwardedMessage =
                ForwardedMessage.fromJson(mm.message!.forwardedMessage!);
          }

          msg = Message(
            id: mm.message?.id ?? 0,
            filePath: mm.message?.filePath.toString() ?? '',
            text: mm.message?.text ?? mm.message?.type ?? '',
            type: mm.message?.type ?? '',
            isMyMessage: (UUID == mm.message?.sender?.id.toString() &&
                mm.message?.sender?.type == 'user'),
            createMessateTime: mm.message?.createdAt?.toString() ?? '',
            duration: Duration(
                seconds: (mm.message?.voiceDuration != null)
                    ? double.parse(mm.message!.voiceDuration.toString()).round()
                    : 20),
            senderName: mm.message?.sender?.name ?? 'Unknown sender',
            forwardedMessage: forwardedMessage,
          );
        } else {
          ForwardedMessage? forwardedMessage;
          if (mm.message?.forwardedMessage != null) {
            forwardedMessage =
                ForwardedMessage.fromJson(mm.message!.forwardedMessage!);
          }
          msg = Message(
            id: mm.message?.id ?? 0,
            text: mm.message?.text ?? mm.message?.type ?? '',
            type: mm.message?.type ?? '',
            createMessateTime: mm.message?.createdAt?.toString() ?? '',
            isMyMessage: (UUID == mm.message?.sender?.id.toString() &&
                mm.message?.sender?.type == 'user'),
            senderName: mm.message?.sender?.name ?? 'Unknown sender',
            forwardedMessage: forwardedMessage,
          );
        }

        setState(() {
          context.read<MessagingCubit>().addMessageFormSocket(msg);
        });
        _scrollToBottom();
      });
    myPresenceChannel.bind('chat.messageEdited').listen((event) async {
  print('==================MESSAGE EDITITING EVENT DATA======START=============');
  print(event.data);
  print('==================MESSAGE EDITITING--EVENT DATA======END=============');

  try {
    MessageSocketData mm = messageSocketDataFromJson(event.data);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String UUID = prefs.getString('userID') ?? '';
    print('userID : $UUID');

    Message msg;
    if (mm.message?.type == 'voice' ||
        mm.message?.type == 'file' ||
        mm.message?.type == 'image' ||
        mm.message?.type == 'document') {
      ForwardedMessage? forwardedMessage;
      if (mm.message?.forwardedMessage != null) {
        forwardedMessage = ForwardedMessage.fromJson(mm.message!.forwardedMessage!);
      }

      msg = Message(
        id: mm.message?.id ?? 0,
        filePath: mm.message?.filePath.toString() ?? '',
        text: mm.message?.text ?? mm.message?.type ?? '',
        type: mm.message?.type ?? '',
        isMyMessage: (UUID == mm.message?.sender?.id.toString() &&
            mm.message?.sender?.type == 'user'),
        createMessateTime: mm.message?.createdAt?.toString() ?? '',
        duration: Duration(
            seconds: (mm.message?.voiceDuration != null)
                ? double.parse(mm.message!.voiceDuration.toString()).round()
                : 20),
        senderName: mm.message?.sender?.name ?? 'Unknown sender',
        forwardedMessage: forwardedMessage,
        isChanged: mm.message?.isChanged ?? false,
      );
    } else {
      ForwardedMessage? forwardedMessage;
      if (mm.message?.forwardedMessage != null) {
        forwardedMessage = ForwardedMessage.fromJson(mm.message!.forwardedMessage!);
      }
      msg = Message(
        id: mm.message?.id ?? 0,
        text: mm.message?.text ?? mm.message?.type ?? '',
        type: mm.message?.type ?? '',
        createMessateTime: mm.message?.createdAt?.toString() ?? '',
        isMyMessage: (UUID == mm.message?.sender?.id.toString() &&
            mm.message?.sender?.type == 'user'),
        senderName: mm.message?.sender?.name ?? 'Unknown sender',
        forwardedMessage: forwardedMessage,
        isChanged: mm.message?.isChanged ?? false, 
      );
    }

    setState(() {
      context.read<MessagingCubit>().updateMessageFromSocket(msg);
    });
  } catch (e) {
    print('Error processing messageEdited event: $e');
  }
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

  Future<void> _onSendInButton(
      String messageText, String? replyMessageId) async {
    context.read<ListenSenderTextCubit>().updateValue(true);

    if (messageText.trim().isNotEmpty) {
      try {
        _messageController.clear();
        await widget.apiService.sendMessage(
          widget.chatId,
          messageText.trim(),
          replyMessageId: replyMessageId,
        );
        context.read<ListenSenderTextCubit>().updateValue(false);
      } catch (e) {
        debugPrint('Ошибка отправки сообщения через API!');
      }
    } else {
      debugPrint('Сообщение пустое, отправка не выполнена');
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

  void _onScroll() {
    if (_scrollController.hasClients) {
      print("Scroll position: ${_scrollController.position.pixels}");

      // Получаем видимые элементы
      final position = _scrollController.position;
      final viewportOffset = position.pixels;
      final viewportExtent = position.viewportDimension;

      // Проверяем позиции сообщений
      for (final entry in _messagePositions.entries) {
        if (viewportOffset < entry.value &&
            entry.value < viewportOffset + viewportExtent) {
          setState(() {
            _currentDate = entry.key;
          });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    chatSubscribtion.cancel();
    _scrollController.dispose();

    _scrollController.addListener(_onScroll);
    _messageController.dispose();
    socketClient.dispose();
    _webSocket?.close();
    _focusNode.dispose(); 
    print("ScrollController is initialized");
    super.dispose();
  }
}

extension on Key? {
  get currentContext => null;
}

// Храним позиции сообщений и их даты
final Map<String, double> _messagePositions = {};

class MessageItemWidget extends StatelessWidget {
  final Message message;
  final int chatId;
  final String endPointInTab;
  final ApiServiceDownload apiServiceDownload;
  final String baseUrl;
  final void Function(int)? onReplyTap;
  final int? highlightedMessageId;
  final void Function(bool)? onMenuStateChanged;
  final FocusNode focusNode; 

  const MessageItemWidget({
    super.key,
    required this.message,
    required this.endPointInTab,
    required this.chatId,
    required this.apiServiceDownload,
    required this.baseUrl,
    this.onReplyTap,
    this.highlightedMessageId,
    this.onMenuStateChanged,
    required this.focusNode, 
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(message.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        focusNode.requestFocus(); 
        context.read<MessagingCubit>().setReplyMessage(message);
        return false;
      },
      child: GestureDetector(
        onLongPress: () => _showMessageContextMenu(context, message, focusNode), 
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          child: _buildMessageContent(context),
        ),
      ),
    );
  }




  Widget _buildMessageContent(BuildContext context) {
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
          isHighlighted: highlightedMessageId == message.id,
          onTap: (path) async {
            if (message.filePath != null && message.filePath!.isNotEmpty) {
              try {
                await apiServiceDownload.downloadAndOpenFile(message.filePath!);
              } catch (e) {
                if (kDebugMode) {
                  print('Error opening file!');
                }
              }
            } else {
              if (kDebugMode) {
                print('Invalid file path. Cannot open file.');
              }
            }
          },
          senderName: message.senderName,
        );
      case 'voice':
        return voiceState();
      default:
        return SizedBox();
    }
  }

  Widget textState() {
    String? replyMessageText;
    if (message.forwardedMessage != null &&
        message.forwardedMessage!.type == 'voice') {
      replyMessageText = "Голосовое сообщение";
    } else {
      replyMessageText = message.forwardedMessage?.text;
    }

    return MessageBubble(
      message: message.text,
      time: time(message.createMessateTime),
      isSender: message.isMyMessage,
      senderName: message.senderName.toString(),
      replyMessage: replyMessageText,
      replyMessageId: message.forwardedMessage?.id,
      onReplyTap: (int replyMessageId) {
        onReplyTap?.call(replyMessageId);
      },
      isHighlighted: highlightedMessageId == message.id,
      isChanged: message.isChanged,
    );
  }

  Widget imageState() {
    return ImageMessageBubble(
      time: time(message.createMessateTime),
      isSender: message.isMyMessage,
      filePath: message.filePath ?? 'Unknown file format',
      fileName: message.text,
      message: message,
      senderName: message.senderName,
      replyMessage: message.forwardedMessage?.text,
      isHighlighted: highlightedMessageId == message.id,
    );
  }

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
        /// do something on error
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
          SizedBox(height: 8),
          if (message.isMyMessage == false)
            Text(
              message.senderName,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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

void _showMessageContextMenu(BuildContext context, Message message, FocusNode focusNode) {
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final RenderBox messageBox = context.findRenderObject() as RenderBox;
  final Offset position = messageBox.localToGlobal(Offset.zero, ancestor: overlay);

  onMenuStateChanged?.call(true);

  final List<PopupMenuItem> menuItems = [];

  menuItems.add(
    _buildMenuItem(
      icon: 'assets/icons/chats/menu_icons/reply.svg',
      text: "Ответить",
      iconColor: Colors.black,
      textColor: Colors.black,
      onTap: () {
        Navigator.pop(context);
        focusNode.requestFocus();
        context.read<MessagingCubit>().setReplyMessage(message);
      },
    ),
  );
    menuItems.add(
    _buildMenuItem(
      icon: 'assets/icons/chats/menu_icons/pin.svg',
      text: "Закрепить",
      iconColor: Colors.black,
      textColor: Colors.black,
      onTap: () {
        Navigator.pop(context);
        context.read<MessagingCubit>().pinMessage(message);
        print("Сообщение закреплено");
      },
    ),
  );

  if (message.isMyMessage) {
    menuItems.add(
      _buildMenuItem(
        icon: 'assets/icons/chats/menu_icons/edit.svg',
        text: "Изменить",
        iconColor: Colors.black,
        textColor: Colors.black,
        onTap: () {
          Navigator.pop(context);
          focusNode.requestFocus();
          context.read<MessagingCubit>().startEditingMessage(message);
          print("Сообщение изменено");
        },
      ),
    );

    menuItems.add(
      _buildMenuItem(
        icon: 'assets/icons/chats/menu_icons/delete-red.svg',
        text: "Удалить",
        iconColor: Colors.red,
        textColor: Colors.red,
        onTap: () {
          Navigator.pop(context);
          _deleteMessage(context);
          print("Сообщение удалено");
        },
      ),
    );
  }

  // Показываем меню
  showMenu(
    context: context,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    position: RelativeRect.fromLTRB(
      position.dx + messageBox.size.width / 2.5,
      position.dy,
      position.dx + messageBox.size.width / 2 + 1,
      position.dy + messageBox.size.height,
    ),
    items: menuItems,
  ).then((_) {
    onMenuStateChanged?.call(false);
  });
}

PopupMenuItem _buildMenuItem({
  required String icon, 
  required String text,
  required Color iconColor,
  required Color textColor, 
  required VoidCallback onTap,
}) {
  return PopupMenuItem(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          children: [
            SvgPicture.asset(
              icon, 
              width: 24,
              height: 24,
              color: iconColor,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: textColor, 
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // Логика для удаления сообщения
  void _deleteMessage(BuildContext context) {
    // Проверка, является ли сообщение отправленным текущим пользователем
    if (message.isMyMessage) {
      int messageId = message.id;

      // Удаление сообщения с помощью блока
      context.read<DeleteMessageBloc>().add(DeleteMessage(messageId));

      // Показ уведомления о успешном удалении
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('sms_deletes_successfully'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.green,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .translate('cannot_someone_delete_sms'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
