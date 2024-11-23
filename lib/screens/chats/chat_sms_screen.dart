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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ChatSmsStyles.appBarTitleColor),
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

        // Получение organizationId из SharedPreferences
        String? organizationId = await widget.apiService.getSelectedOrganization();

        File? convertedFile = await convertAudioFile(inputPath, outputPath);
        if (convertedFile != null) {
          String uploadUrl = '$baseUrl/chat/sendVoice/${widget.chatId}?organization_id=$organizationId';
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


        context.read<ListenSenderFileCubit>().updateValue(false);
        context.read<ListenSenderVoiceCubit>().updateValue(false);
        context.read<ListenSenderTextCubit>().updateValue(false);

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
            isMyMessage: (userID.value == mm.message!.sender!.id.toString() &&
                mm.message!.sender!.type == 'user'),
            createMessateTime: mm.message!.createdAt.toString(),
            duration: Duration(
                seconds: (mm.message!.voiceDuration != null)
                    ? double.parse(mm.message!.voiceDuration.toString()).round()
                    : 20),
          );
        } else {
          msg = Message(
            id: mm.message!.id!,
            text: mm.message!.text ??= mm.message!.type!,
            type: mm.message!.type.toString(),
            createMessateTime: mm.message!.createdAt.toString(),
            isMyMessage: (userID.value == mm.message!.sender!.id.toString() &&
                mm.message!.sender!.type == 'user'),
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
    _webSocket?.close();

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
