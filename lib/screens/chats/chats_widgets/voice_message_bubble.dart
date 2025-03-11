import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:voice_message_package/voice_message_package.dart';
import 'package:crm_task_manager/models/chats_model.dart';

class VoiceMessageWidget extends StatefulWidget {
  final Message message;
  final String baseUrl;

  const VoiceMessageWidget({
    Key? key,
    required this.message,
    required this.baseUrl,
  }) : super(key: key);

  @override
  _VoiceMessageWidgetState createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
  with AutomaticKeepAliveClientMixin {
  late VoiceController _audioController;
  @override
  void initState() {
    super.initState();
    _audioController = VoiceController(
      audioSrc: '${widget.baseUrl.replaceAll('/api', '')}/storage/${widget.message.filePath}',
      onComplete: () {
        // Действия при завершении воспроизведения
      },
      onPause: () {
        // Действия при паузе
      },
      onPlaying: () {
        // Действия при воспроизведении
      },
      onError: (err) {
        // Действия при ошибке
      },
      maxDuration: widget.message.duration.inSeconds > 0
          ? widget.message.duration
          : const Duration(seconds: 5),
      isFile: false,
    );
  }
  

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        right: widget.message.isMyMessage == false ? 60 : 0,
        left: widget.message.isMyMessage ? 60 : 0,
      ),
      child: Column(
        crossAxisAlignment: widget.message.isMyMessage
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          if (widget.message.isMyMessage == false)
            Text(
              widget.message.senderName,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          VoiceMessageView(
            innerPadding: 8,
            backgroundColor: widget.message.isMyMessage
                ? ChatSmsStyles.messageBubbleSenderColor
                : ChatSmsStyles.messageBubbleReceiverColor,
            activeSliderColor: widget.message.isMyMessage
                ? Colors.white
                : ChatSmsStyles.messageBubbleSenderColor,
            circlesColor: widget.message.isMyMessage
                ? Colors.white.withOpacity(.2)
                : ChatSmsStyles.messageBubbleSenderColor,
            controller: _audioController,
            counterTextStyle: TextStyle(
              color: widget.message.isMyMessage
                  ? Colors.white
                  : ChatSmsStyles.messageBubbleSenderColor,
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(time(widget.message.createMessateTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: ChatSmsStyles.appBarTitleColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(width: 3),
              if (widget.message.isMyMessage)
                Icon(
                  widget.message.isRead ? Icons.done_all : Icons.done_all,
                  size: 18,
                  color: widget.message.isRead
                      ? const Color.fromARGB(255, 45, 28, 235)
                      : Colors.grey.shade400,
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioController.dispose(); 
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; 
}
