import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
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
                    _buildMessageWithLinks(context, message),
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

  
 Widget _buildMessageWithLinks(BuildContext context, String text) {
  final RegExp linkRegExp = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
  final matches = linkRegExp.allMatches(text);
  
  // Определяем максимальную ширину сообщения - можно настроить в соответствии с вашими требованиями
  final double maxWidth = MediaQuery.of(context).size.width * 0.75; // 75% ширины экрана
  
  Widget textWidget;
  if (matches.isEmpty) {
    textWidget = Text(
      text,
      style: isSender
          ? ChatSmsStyles.senderMessageTextStyle
          : ChatSmsStyles.receiverMessageTextStyle,
    );
  } else {
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
            fontSize: 14,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
              final RenderBox messageBox = context.findRenderObject() as RenderBox;
              final Offset position = messageBox.localToGlobal(Offset.zero, ancestor: overlay);
          
              showMenu(
                context: context,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                position: RelativeRect.fromLTRB(
                  position.dx + messageBox.size.width / 2.5,
                  position.dy,
                  position.dx + messageBox.size.width / 2 + 1,
                  position.dy + messageBox.size.height,
                ),
                items: [
                  _buildMenuItem(
                    icon: 'assets/icons/chats/menu_icons/open.svg',
                    text: "Открыть",
                    iconColor: Colors.black,
                    textColor: Colors.black,
                    onTap: () async {
                      Navigator.pop(context);
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
                  _buildMenuItem(
                    icon: 'assets/icons/chats/menu_icons/copy.svg',
                    text: "Копировать",
                    iconColor: Colors.black,
                    textColor: Colors.black,
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.translate('Ссылка скопировано!'), 
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.green,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    textWidget = RichText(
      text: TextSpan(
        style: isSender
            ? ChatSmsStyles.senderMessageTextStyle
            : ChatSmsStyles.receiverMessageTextStyle,
        children: spans,
      ),
    );
  }

  // Оборачиваем текст в контейнер с ограничением ширины
  return Container(
    constraints: BoxConstraints(
      maxWidth: maxWidth,
    ),
    child: textWidget,
  );
}
  
  PopupMenuItem _buildMenuItem({
  required String icon,
  required String text,
  required Color iconColor,
  required Color textColor,
  required VoidCallback onTap,
}) {
  return PopupMenuItem(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Row(
          children: [
            if (icon.isNotEmpty)
              SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                color: iconColor,
              ),
            if (icon.isNotEmpty) const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,  
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
