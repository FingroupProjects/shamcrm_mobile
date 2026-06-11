import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:voice_message_package/voice_message_package.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';

class VoiceMessageWidget extends StatefulWidget {
  final Message message;
  final String baseUrl;
  final bool isLeadChat;
  final bool? isGroupChat;
  final List<MessageReaction> reactions;
  final Function(String)? onReactionTap;

  const VoiceMessageWidget({
    Key? key,
    required this.message,
    required this.baseUrl,
    this.isLeadChat = false,
    this.isGroupChat,
    this.reactions = const [],
    this.onReactionTap,
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
    // Формируем источник аудио в зависимости от filePath
    final String audioSource = _getAudioSource();

    _audioController = VoiceController(
      audioSrc: audioSource,
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
        // Обработка ошибок воспроизведения
        debugPrint(
            'Ошибка воспроизведения аудио: $err, filePath: ${widget.message.filePath}');
      },
      maxDuration: widget.message.duration.inSeconds > 0
          ? widget.message.duration
          : const Duration(seconds: 5),
      isFile: false, // Ссылка, а не локальный файл
    );
  }

  // Метод для определения источника аудио
  String _getAudioSource() {
    final filePath = widget.message.filePath ?? '';
    // Если filePath начинается с https://, используем его как есть
    if (filePath.startsWith('https://')) {
      return filePath;
    }
    // Иначе формируем путь через baseUrl
    return '${widget.baseUrl.replaceAll('/api', '')}/storage/$filePath';
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
          // ✅ Логика отображения имени отправителя:
          // - В лид-чатах: показываем имя для ОБЕИХ сторон (несколько менеджеров могут отвечать)
          // - В корпоративных группах: показываем имя только для собеседника
          // - В корпоративных чатах (не группа): показываем имя хотя бы для собеседника
          if (widget.isLeadChat ||
              widget.isGroupChat == true ||
              !widget.message.isMyMessage)
            Text(
              widget.message.senderName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.message.isMyMessage
                    ? context.appColors.textSecondary
                    : context.appColors.textPrimary,
              ),
            ),
          VoiceMessageView(
            innerPadding: 8,
            backgroundColor: widget.message.isMyMessage
                ? ChatSmsStyles.messageBubbleSenderColor
                : ChatSmsStyles.messageBubbleReceiverColor,
            activeSliderColor: widget.message.isMyMessage
                ? context.appColors.surfacePrimary
                : ChatSmsStyles.messageBubbleSenderColor,
            circlesColor: widget.message.isMyMessage
                ? context.appColors.surfacePrimary.withValues(alpha: 0.2)
                : ChatSmsStyles.messageBubbleSenderColor,
            controller: _audioController,
            counterTextStyle: TextStyle(
              color: widget.message.isMyMessage
                  ? context.appColors.surfacePrimary
                  : ChatSmsStyles.messageBubbleSenderColor,
            ),
          ),
          if (widget.reactions.isNotEmpty)
            Transform.translate(
              offset: const Offset(0, -4),
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.message.isMyMessage ? 0 : 6,
                  right: widget.message.isMyMessage ? 6 : 0,
                  bottom: 2,
                ),
                child: ReactionCapsule(
                  reactions: widget.reactions,
                  isSender: widget.message.isMyMessage,
                  onReactionTap: widget.onReactionTap,
                ),
              ),
            ),
          SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time(widget.message.createMessateTime),
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
                      ? context.appColors.buttonPrimaryBg
                      : context.appColors.textSecondary.withValues(alpha: 0.45),
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
