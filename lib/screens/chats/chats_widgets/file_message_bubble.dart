import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';
import 'package:crm_task_manager/services/chat_media_download_manager.dart';
import 'package:crm_task_manager/widgets/chat_download_progress_overlay.dart';

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
    final textStyles = context.appTextStyles;
    final appearance = ChatAppearanceScope.of(context);
    final fileExtension = _extractFileExtension();
    final iconPath = _buildPrimaryIconPath(fileExtension);
    final fallbackIconPath = _buildFallbackIconPath(fileExtension);
    final bubbleColor = isSender
        ? appearance.senderBubbleColor(context)
        : appearance.receiverBubbleColor(context);
    final foreground = isSender
        ? appearance.outgoingForeground(context)
        : appearance.incomingForeground(context);

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
                style: textStyles.labelMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: appearance.senderNameColor(context),
                ),
              ),
            GestureDetector(
              onTap: () => onTap(filePath),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: appearance.bubbleRadius(isSender),
                  border: Border.all(
                    color: appearance.borderColor(context, isSender),
                  ),
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
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Stack(
                        alignment: Alignment.center,
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
                          ListenableBuilder(
                            listenable: ChatMediaDownloadManager.instance,
                            builder: (context, _) {
                              final task = ChatMediaDownloadManager.instance
                                  .taskFor(filePath);
                              if (task == null || !task.showOverlay) {
                                return const SizedBox.shrink();
                              }
                              return ChatDownloadProgressOverlay(
                                task: task,
                                compact: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                        width: 10), // Add this line to create spacing

                    Flexible(
                      child: Text(
                        fileName,
                        style: textStyles.bodyMd.copyWith(
                          color: foreground,
                          fontSize: appearance.scaledFont(14),
                          fontWeight: appearance.messageFontWeight,
                        ),
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
                  style: textStyles.caption.copyWith(
                    fontSize: appearance.scaledFont(12),
                    color: appearance.secondaryForeground(context, isSender),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 3),
                if (isSender)
                  Icon(
                    isRead ? Icons.done_all : Icons.done_all,
                    size: 18,
                    color: isRead
                        ? foreground
                        : appearance.secondaryForeground(context, isSender),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
