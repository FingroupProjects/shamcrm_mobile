import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
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
            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                child: Text(
                  message,
                  style: isSender
                      ? ChatSmsStyles.senderMessageTextStyle
                      : ChatSmsStyles.receiverMessageTextStyle,
                ),
              ),
              if (time.isNotEmpty)
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
        ),
      ),
    );
  }
}