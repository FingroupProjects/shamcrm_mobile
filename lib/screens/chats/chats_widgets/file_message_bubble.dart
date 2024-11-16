import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';

class FileMessageBubble extends StatelessWidget {
  final String time;
  final bool isSender;
  final String filePath;
  final String fileName;
  final Function onTap;

  const FileMessageBubble({
    Key? key,
    required this.time,
    required this.isSender,
    required this.filePath,
    required this.fileName,
    required this.onTap,
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

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onTap(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: 220),
              decoration: BoxDecoration(
                color: isSender
                    ? ChatSmsStyles.messageBubbleSenderColor
                    : ChatSmsStyles.messageBubbleReceiverColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset(iconPath, width: 32, height: 32),
                  SizedBox(width: 8),
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
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: ChatSmsStyles.appBarTitleColor,
              fontWeight: FontWeight.w400,
              fontFamily: 'Gilroy',
            ),
          ),
        ],
      ),
    );
  }
}
