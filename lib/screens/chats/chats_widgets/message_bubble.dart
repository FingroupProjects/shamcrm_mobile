import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
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
                      maxLines: 2222,
                      overflow: TextOverflow.ellipsis,
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
                    _buildMessageWithHtml(context, message),
                    if (isChanged)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          AppLocalizations.of(context)!.translate('edited_sms'),
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

  Widget _buildMessageWithHtml(BuildContext context, String text) {
    final double maxWidth = MediaQuery.of(context).size.width * 0.7;

    // Парсим HTML
    final document = parse(text);
    List<TextSpan> spans = [];

    void parseNode(dom.Node node, TextStyle baseStyle) {
      if (node is dom.Text) {
        spans.add(TextSpan(text: node.text, style: baseStyle));
      } else if (node is dom.Element) {
        TextStyle newStyle = baseStyle;
        if (node.localName == 'strong') {
          newStyle = newStyle.copyWith(fontWeight: FontWeight.bold);
        } else if (node.localName == 'em') {
          newStyle = newStyle.copyWith(fontStyle: FontStyle.italic);
        } else if (node.localName == 's') {
          newStyle = newStyle.copyWith(decoration: TextDecoration.lineThrough);
        } else if (node.localName == 'a') {
          final url = node.attributes['href'] ?? '';
          spans.add(
            TextSpan(
              text: node.text,
              style: newStyle.copyWith(
                color: isSender ? Colors.white : Colors.blue,
                decoration: TextDecoration.underline,
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
                        text: AppLocalizations.of(context)!.translate('open_url_source'),
                        iconColor: Colors.black,
                        textColor: Colors.black,
                        onTap: () async {
                          Navigator.pop(context);
                          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        },
                      ),
                      _buildMenuItem(
                        icon: 'assets/icons/chats/menu_icons/copy.svg',
                        text: AppLocalizations.of(context)!.translate('copy'),
                        iconColor: Colors.black,
                        textColor: Colors.black,
                        onTap: () {
                          Navigator.pop(context);
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.translate('copy_url_source_text'),
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
          return;
        }

        for (var child in node.nodes) {
          parseNode(child, newStyle);
        }
      }
    }

    final baseStyle = isSender
        ? ChatSmsStyles.senderMessageTextStyle
        : ChatSmsStyles.receiverMessageTextStyle;

    for (var node in document.body!.nodes) {
      parseNode(node, baseStyle);
    }

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: spans,
        ),
        maxLines: 10000000,
        overflow: TextOverflow.ellipsis,
      ),
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