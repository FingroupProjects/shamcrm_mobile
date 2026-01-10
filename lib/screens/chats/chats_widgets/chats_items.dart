import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatItem {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final String avatar;
  final String icon;
  final bool isGroup;

  ChatItem(
    this.name,
    this.message,
    this.time,
    this.avatar,
    this.icon,
    this.unreadCount, {
    this.isGroup = false,
  });

  get id => null;
}

class ChatListItem extends StatelessWidget {
  final ChatItem chatItem;
  final String endPointInTab;

  const ChatListItem({
    super.key,
    required this.chatItem,
    required this.endPointInTab,
  });

  @override
  Widget build(BuildContext context) {
    bool isSupportAvatar = chatItem.avatar == 'assets/icons/Profile/image.png';
    bool isLeadsSection = endPointInTab == 'lead';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            child: _buildAvatar(chatItem.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chatItem.name.isNotEmpty
                            ? (chatItem.name == 'support'
                                ? AppLocalizations.of(context)!.translate('support_chat_name')
                                : chatItem.name)
                            : AppLocalizations.of(context)!.translate('no_name'),
                        style: AppStyles.chatNameStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatChatTime(chatItem.time),
                      style: AppStyles.chatTimeStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: parseHtmlToTextSpans(
                            chatItem.message,
                            AppStyles.chatMessageStyle,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 33,
                      height: 33,
                      child: chatItem.unreadCount > 0
                          ? Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                chatItem.unreadCount <= 9
                                    ? '${chatItem.unreadCount}'
                                    : '+9',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Gilroy',
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatar) {
    bool isLeadsSection = endPointInTab == 'lead';
    bool isSupportAvatar = avatar == 'assets/icons/Profile/support_chat.png';
    bool isTaskSection = endPointInTab == 'task';

    if (isTaskSection && !avatar.contains('<svg')) {
      return CircleAvatar(
        backgroundImage: const AssetImage('assets/images/AvatarTask.png'),
        radius: 24,
        backgroundColor: Colors.white,
        onBackgroundImageError: (exception, stackTrace) {
          // print('Error loading asset image: assets/images/AvatarTask.png, $exception');
        },
      );
    }

    if (isLeadsSection && (avatar.isEmpty || avatar == 'assets/icons/leads/default.png')) {
      return CircleAvatar(
        backgroundImage: const AssetImage('assets/images/AvatarChat.png'),
        radius: 24,
        backgroundColor: isSupportAvatar ? Colors.black : Colors.white,
        onBackgroundImageError: (exception, stackTrace) {
          // print('Error loading asset image: assets/images/AvatarChat.png, $exception');
        },
      );
    }

    if (isLeadsSection && chatItem.icon.isNotEmpty && chatItem.icon != 'assets/icons/leads/default.png') {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[100],
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Image.asset(
            chatItem.icon,
            width: 52,
            height: 52,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 32,
                color: Colors.grey[600],
              );
            },
          ),
        ),
      );
    }

    if (avatar.contains('<svg')) {
      final imageUrl = extractImageUrlFromSvg(avatar);
      if (imageUrl != null) {
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        final text = extractTextFromSvg(avatar);
        final backgroundColor = extractBackgroundColorFromSvg(avatar);

        if (text != null && backgroundColor != null) {
          return Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          return SvgPicture.string(
            avatar,
            width: 52,
            height: 52,
            placeholderBuilder: (context) => const CircularProgressIndicator(),
          );
        }
      }
    }

    try {
      return CircleAvatar(
        backgroundImage: AssetImage(avatar),
        radius: 24,
        backgroundColor: isSupportAvatar ? Colors.black : Colors.white,
        onBackgroundImageError: (exception, stackTrace) {
          // print('Error loading asset image: $avatar, $exception');
        },
      );
    } catch (e) {
      // print('Fallback avatar due to error: $e');
      return CircleAvatar(
        backgroundImage: AssetImage(isTaskSection ? 'assets/images/AvatarTask.png' : 'assets/images/AvatarChat.png'),
        radius: 24,
        backgroundColor: isSupportAvatar ? Colors.black : Colors.white,
      );
    }
  }

  String formatChatTime(String time) {
    if (time.isEmpty) {
      return '';
    }

    try {
      DateTime parsedTime = DateTime.parse(time);
      return DateFormat('dd.MM.yyyy').format(parsedTime);
    } catch (e) {
      // print("Ошибка парсинга даты: $e");
      return '';
    }
  }

  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  String? extractTextFromSvg(String svg) {
    final textMatch = RegExp(r'<text[^>]*>(.*?)</text>').firstMatch(svg);
    return textMatch?.group(1);
  }

  Color? extractBackgroundColorFromSvg(String svg) {
    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    if (fillMatch != null) {
      final colorHex = fillMatch.group(1);
      if (colorHex != null) {
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  List<TextSpan> parseHtmlToTextSpans(String html, TextStyle baseStyle) {
    final RegExp htmlRegExp = RegExp(
      r'<(strong|em|s|a href="([^"]*)"[^>]*)(.*?)>(.*?)</\1>',
      multiLine: true,
      caseSensitive: false,
    );

    List<TextSpan> spans = [];
    int lastEnd = 0;

    for (final match in htmlRegExp.allMatches(html)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: html.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      String tag = match.group(1)!.toLowerCase();
      String content = match.group(4)!;
      String? href = tag.startsWith('a href') ? match.group(2) : null;

      if (tag == 'strong') {
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (tag == 'em') {
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (tag == 's') {
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else if (tag.startsWith('a') && href != null) {
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final url = Uri.parse(href);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < html.length) {
      spans.add(TextSpan(
        text: html.substring(lastEnd),
        style: baseStyle,
      ));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: html, style: baseStyle));
    }

    return spans;
  }
}