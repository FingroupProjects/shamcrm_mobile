import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';

class FileMessageBubble extends StatelessWidget {
  final String time;
  final bool isSender;
  final String filePath;
  final String fileName;
  final String senderName;
  final Function(String) onTap;
  final bool isHighlighted; // Add this line
  final bool isRead; // Added isRead property

  const FileMessageBubble({
    Key? key,
    required this.time,
    required this.isSender,
    required this.filePath,
    required this.fileName,
    required this.onTap,
    required this.senderName,
    this.isHighlighted = false, // Add this line
    required this.isRead, // Add isRead to constructor
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
      case 'jpeg':
      case 'png':
        iconPath = 'assets/icons/chats/jpg-file.png';
        break;
      case 'doc':
      case 'docx':
      case 'document':
        iconPath = 'assets/icons/chats/doc.png';
        break;
      case 'xls':
      case 'xlsx':
        iconPath = 'assets/icons/chats/xls.png';
        break;
      case 'webp':
        iconPath = 'assets/icons/chats/webp.png';
        break;
      case 'svg':
        iconPath = 'assets/icons/chats/svg-file.png';
        break;
      default:
        iconPath = 'assets/icons/chats/file.png';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: isHighlighted
            ? [
                BoxShadow(
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
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (!isSender)
              Text(
                senderName,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(iconPath, width: 32, height: 32),
                    Flexible(
                      child: Text(
                        fileName,
                        style: TextStyle(
                            color: isSender ? Colors.white : Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
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
                    isRead
                        ? Icons.done_all
                        : Icons.done_all,
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
