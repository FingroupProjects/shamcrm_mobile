import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isSender;
  final String senderName;
  final String? replyMessage;
  final int? replyMessageId;
  final void Function(int)? onReplyTap;
  final bool isHighlighted;
  final bool isChanged;
  final bool isRead;

  MessageBubble({
    Key? key,
    required this.message,
    required this.time,
    required this.isSender,
    required this.senderName,
    this.replyMessage,
    this.replyMessageId,
    this.onReplyTap,
    this.isHighlighted = false,
    required this.isChanged,
    required this.isRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        child: Container(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (!isSender)
                Text(
                  senderName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                ),
              if (replyMessage != null && replyMessage!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    if (replyMessageId != null) {
                      onReplyTap?.call(replyMessageId!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      replyMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isSender
                      ? ChatSmsStyles.messageBubbleSenderColor
                      : ChatSmsStyles.messageBubbleReceiverColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    _buildMessageWithLinks(message),
                    if (isChanged)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Изменено',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSender ? Colors.white70 : Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (time.isNotEmpty)
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
                        isRead ? Icons.done_all : Icons.done_all,
                        size: 18,
                        color: isRead ? const Color.fromARGB(255, 45, 28, 235) : Colors.grey.shade400,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageWithLinks(String text) {
  final RegExp linkRegExp = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
  final matches = linkRegExp.allMatches(text);

  if (matches.isEmpty) {
    return Text(
      text,
      style: isSender
          ? ChatSmsStyles.senderMessageTextStyle
          : ChatSmsStyles.receiverMessageTextStyle,
    );
  }

  List<TextSpan> spans = [];
  int start = 0;
  for (final match in matches) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }
    final String url = match.group(0)!;
    spans.add(
    TextSpan(
         text: url,
         style: TextStyle(
          color: isSender ? Colors.white : Colors.blue, 
           fontWeight: FontWeight.w600,
           decoration: TextDecoration.underline, 
           fontStyle: FontStyle.normal,
           fontFamily: 'Gilroy',
           fontSize: 14, 
         ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            try {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                print("Не удалось открыть ссылку");
              } else {
               launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } catch (e) {
              print("Ошибка при открытии ссылки: $e");
            }
          },
      ),
    );
    start = match.end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }
  return RichText(
    text: TextSpan(
      style: isSender
          ? ChatSmsStyles.senderMessageTextStyle
          : ChatSmsStyles.receiverMessageTextStyle,
      children: spans,
    ),
  );
}
}
