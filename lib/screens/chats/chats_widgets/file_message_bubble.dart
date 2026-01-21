import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';

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

  const FileMessageBubble({
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String fileExtension = fileName.split('.').last.toLowerCase();
    String iconPath;

    switch (fileExtension) {
      case 'pdf':
        iconPath = 'assets/icons/chats/pdf.png';
        break;
      case 'jpg':
        iconPath = 'assets/icons/files/jpg.png';
        break;
      case 'jpeg':
        iconPath = 'assets/icons/files/jpg.png';
        break;
      case 'png':
        iconPath = 'assets/icons/chats/jpg-file.png';
        break;
      case 'doc':
        iconPath = 'assets/icons/files/doc.png';
        break;
      case 'docx':
        iconPath = 'assets/icons/files/doc.png';
        break;
      case 'pptx':
        iconPath = 'assets/icons/files/pptx.png';
        break;
      case 'ppt':
        iconPath = 'assets/icons/files/ppt.png';
        break;
      case 'document':
        iconPath = 'assets/icons/chats/doc.png';
        break;
      case 'xls':
        iconPath = 'assets/icons/chats/xls.png';
        break;
      case 'xlsx':
        iconPath = 'assets/icons/chats/xls.png';
        break;
      case 'webp':
        iconPath = 'assets/icons/chats/webp.png';
        break;
      case 'svg':
        iconPath = 'assets/icons/chats/svg-file.png';
        break;
      case 'mp4':
        iconPath = 'assets/icons/chats/mp4.png';
        break;
      case 'mp3':
        iconPath = 'assets/icons/chats/mp3.png';
        break;
      default:
        iconPath = 'assets/icons/files/file.png';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: isHighlighted
            ? [ BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
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
          crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ✅ Логика отображения имени отправителя:
            // - В лид-чатах: показываем имя для ОБЕИХ сторон (несколько менеджеров могут отвечать)
            // - В корпоративных группах: показываем имя только для собеседника
            // - В корпоративных чатах (не группа): НЕ показываем имя
            if (isLeadChat || (isGroupChat == true && !isSender))
              Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSender ? Colors.grey.shade600 : Colors.black87,
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
                      color: Colors.black.withOpacity(0.1),
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
                    Image.asset(iconPath, width: 32, height: 32),
                    const SizedBox(
                        width: 10), // Add this line to create spacing

                    Flexible(
                      child: Text(
                        fileName,
                        style: TextStyle( color: isSender ? Colors.white : Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row( mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: const TextStyle(
                    fontSize: 12,
                    color: ChatSmsStyles.appBarTitleColor,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                  ),
                ),
                const SizedBox(width: 3),
                if (isSender)

                  Icon(isRead ? Icons.done_all : Icons.done_all,
                    size: 18,
                    color: isRead
                        ? const Color.fromARGB(255, 45, 28, 235)
                        : Colors.grey.shade400,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
