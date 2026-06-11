import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';

class FileMessageBubble extends StatelessWidget {
  final String time;
  final bool isSender;
  final String filePath;
  final String fileName;
  final String senderName;
  final Function(String) onTap;
  final bool isHighlighted;
  final bool isRead;
  final bool isLeadChat;
  final bool? isGroupChat;
  final List<MessageReaction> reactions;
  final Function(String)? onReactionTap;

  const FileMessageBubble({
    super.key,
    required this.time,
    required this.isSender,
    required this.filePath,
    required this.fileName,
    required this.onTap,
    required this.senderName,
    this.isHighlighted = false,
    required this.isRead,
    this.isLeadChat = false,
    this.isGroupChat,
    this.reactions = const [],
    this.onReactionTap,
  });

  String _extractFileExtension() {
    String candidate = fileName.trim();

    if (!candidate.contains('.') && filePath.trim().isNotEmpty) {
      candidate = filePath.trim();
    }

    candidate = candidate.split('?').first.split('#').first;
    final segments = candidate.split('/');
    final lastSegment = segments.isNotEmpty ? segments.last : candidate;

    if (!lastSegment.contains('.')) {
      return 'file';
    }

    final rawExtension = lastSegment.split('.').last.toLowerCase();

    switch (rawExtension) {
      case 'jpeg':
        return 'jpg';
      case 'docx':
        return 'docx';
      case 'xlsx':
        return 'xls';
      default:
        return rawExtension;
    }
  }

  String _buildPrimaryIconPath(String fileExtension) {
    return 'assets/icons/files/$fileExtension.png';
  }

  String _buildFallbackIconPath(String fileExtension) {
    switch (fileExtension) {
      case 'mp3':
        return 'assets/icons/chats/mp3.png';
      case 'mp4':
        return 'assets/icons/chats/mp4.png';
      case 'webp':
        return 'assets/icons/chats/webp.png';
      default:
        return 'assets/icons/files/file.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileExtension = _extractFileExtension();
    final iconPath = _buildPrimaryIconPath(fileExtension);
    final fallbackIconPath = _buildFallbackIconPath(fileExtension);

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: context.appColors.shadow.withValues(alpha: 0.18),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: Offset(0, -4),
                ),
              ]
            : [],
      ),
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ✅ Логика отображения имени отправителя:
            // - В лид-чатах: показываем имя для ОБЕИХ сторон (несколько менеджеров могут отвечать)
            // - В корпоративных группах: показываем имя только для собеседника
            // - В корпоративных чатах (не группа): показываем имя хотя бы для собеседника
            if (isLeadChat || isGroupChat == true || !isSender)
              Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSender ? context.appColors.textSecondary : context.appColors.textPrimary,
                ),
              ),
            GestureDetector(
              onTap: () => onTap(filePath),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  color: isSender
                      ? ChatSmsStyles.messageBubbleSenderColor
                      : ChatSmsStyles.messageBubbleReceiverColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow.withValues(alpha: 0.1),
                      offset: Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Центрируем по вертикали
                  children: [
                    Image.asset(
                      iconPath,
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          fallbackIconPath,
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/icons/files/file.png',
                              width: 32,
                              height: 32,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(
                        width: 10), // Add this line to create spacing

                    Flexible(
                      child: Text(
                        fileName,
                        style: TextStyle(
                            color: isSender ? context.appColors.textInverse : context.appColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (reactions.isNotEmpty)
              Transform.translate(
                offset: const Offset(0, -4),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isSender ? 0 : 6,
                    right: isSender ? 6 : 0,
                    bottom: 2,
                  ),
                  child: ReactionCapsule(
                    reactions: reactions,
                    isSender: isSender,
                    onReactionTap: onReactionTap,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChatSmsStyles.appBarTitleColor,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                  ),
                ),
                const SizedBox(width: 3),
                if (isSender)
                  Icon(
                    isRead ? Icons.done_all : Icons.done_all,
                    size: 18,
                    color: isRead
                        ? const Color.fromARGB(255, 45, 28, 235)
                        : context.appColors.textSecondary.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
