import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;

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
    // Проверяем, содержит ли текст HTML-теги
    final bool isHtml = html.contains('<') && html.contains('>');
    
    if (!isHtml) {
      // Простой текст - возвращаем как есть
      return [TextSpan(text: html, style: baseStyle)];
    }

    // Предобработка HTML: убираем служебные теги
    String cleanedHtml = html
        // Убираем служебные теги Quill-редактора
        .replaceAll(RegExp(r'<span class="ql-cursor"[^>]*>.*?</span>', dotAll: true), '')
        .replaceAll(RegExp(r'<span[^>]*>\s*</span>'), '') // Пустые span
        // Убираем невидимые символы
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Парсим HTML с помощью HTML parser для правильной обработки вложенных тегов
    final document = parse(cleanedHtml);
    List<TextSpan> spans = [];

    void parseNode(dom.Node node, TextStyle currentStyle) {
      if (node is dom.Text) {
        final textContent = node.text.trim();
        if (textContent.isNotEmpty) {
          spans.add(TextSpan(text: textContent, style: currentStyle));
        }
      } else if (node is dom.Element) {
        // Игнорируем служебные элементы
        if (node.localName == 'span' && 
            (node.attributes['class']?.contains('ql-') ?? false)) {
          return; // Пропускаем служебные span от Quill
        }
        
        TextStyle newStyle = currentStyle;
        
        // Обработка форматирования
        if (node.localName == 'strong' || node.localName == 'b') {
          newStyle = newStyle.copyWith(fontWeight: FontWeight.bold);
        } else if (node.localName == 'em' || node.localName == 'i') {
          newStyle = newStyle.copyWith(fontStyle: FontStyle.italic);
        } else if (node.localName == 's' || node.localName == 'strike' || node.localName == 'del') {
          newStyle = newStyle.copyWith(decoration: TextDecoration.lineThrough);
        } else if (node.localName == 'u') {
          newStyle = newStyle.copyWith(decoration: TextDecoration.underline);
        } else if (node.localName == 'a') {
          final url = node.attributes['href'] ?? '';
          final linkText = node.text.trim();
          if (linkText.isNotEmpty) {
            spans.add(
              TextSpan(
                text: linkText,
                style: newStyle.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
              ),
            );
          }
          return;
        } else if (node.localName == 'br') {
          spans.add(TextSpan(text: ' ', style: currentStyle));
          return;
        } else if (node.localName == 'p' || 
                   node.localName == 'div' || 
                   node.localName == 'span') {
          // Блочные элементы и span - просто обрабатываем содержимое
          for (var child in node.nodes) {
            parseNode(child, newStyle);
          }
          return;
        }

        // Обрабатываем дочерние узлы
        for (var child in node.nodes) {
          parseNode(child, newStyle);
        }
      }
    }

    for (var node in document.body!.nodes) {
      parseNode(node, baseStyle);
    }

    // Если нет span'ов, возвращаем исходный текст без тегов
    if (spans.isEmpty) {
      // Убираем все HTML теги и возвращаем чистый текст
      final plainText = cleanedHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      return [TextSpan(text: plainText.isNotEmpty ? plainText : html, style: baseStyle)];
    }

    return spans;
  }
}