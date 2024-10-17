import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isSender;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.time,
    required this.isSender,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isSender
                  ? ChatSmsStyles.messageBubbleSenderColor
                  : ChatSmsStyles.messageBubbleReceiverColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: isSender
                  ? ChatSmsStyles.senderMessageTextStyle
                  : ChatSmsStyles.receiverMessageTextStyle,
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
