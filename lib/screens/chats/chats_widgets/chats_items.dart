import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class ChatItem {
  final String name;
  final String message;
  final String time;
  final int unredMessageCount;
  final String avatar;
  final String icon;
  final bool isGroup;

  ChatItem(this.name, this.message, this.time, this.avatar, this.icon,
      this.unredMessageCount,
      {this.isGroup = false});

  get id => null;
}

class ChatListItem extends StatelessWidget {
  final ChatItem chatItem;

  const ChatListItem({super.key, required this.chatItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: _buildAvatar(chatItem.avatar),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      chatItem.icon,
                      width: 20,
                      height: 20,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        chatItem.name.isNotEmpty ? chatItem.name : 'Без имени',
                        style: AppStyles.chatNameStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  chatItem.message,
                  style: AppStyles.chatMessageStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatChatTime(chatItem.time),
                style: AppStyles.chatTimeStyle,
              ),
              getUnredMessageWidget(chatItem.unredMessageCount)
            ],
          ),
        ],
      ),
    );
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
        // Конвертируем hex в Color
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  Widget _buildAvatar(String avatar) {
    // Проверяем, содержит ли SVG
    if (avatar.contains('<svg')) {
      // Проверяем, есть ли в SVG тег `<image>` с URL
      final imageUrl = extractImageUrlFromSvg(avatar);
      if (imageUrl != null) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        // Проверяем на наличие текста в SVG
        final text = extractTextFromSvg(avatar);
        final backgroundColor = extractBackgroundColorFromSvg(avatar);

        if (text != null && backgroundColor != null) {
          return Container(
            width: 48,
            height: 48,
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20, // было 15
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          // Рендерим сам SVG если нет текста
          return SvgPicture.string(
            avatar,
            width: 48,
            height: 48,
            placeholderBuilder: (context) => CircularProgressIndicator(),
          );
        }
      }
    }

    // Если это не SVG, предполагаем, что это локальное изображение
    return CircleAvatar(
      backgroundImage: AssetImage(avatar),
      radius: 24,
      backgroundColor: Colors.white,
    );
  }

  String formatChatTime(String time) {
    if (time.isEmpty) {
      return '';
    }

    try {
      DateTime parsedTime = DateTime.parse(time);
      return DateFormat('dd/MM/yyyy').format(parsedTime);
    } catch (e) {
      print("Ошибка парсинга даты!");
      return '';
    }
  }

  Widget getUnredMessageWidget(int unreadMessageCount) {
    if (unreadMessageCount > 0) {
      return Container(
        decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
        padding: EdgeInsets.all(8),
        child: Text(
          unreadMessageCount.toString(),
          style: AppStyles.chatTimeStyleWhite,
        ),
      );
    }
    return SizedBox();
  }
}
