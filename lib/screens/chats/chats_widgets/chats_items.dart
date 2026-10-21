import 'package:crm_task_manager/app/analytics/clarity_host.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/widgets/channel_source_icon.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/chat_draft_store.dart';
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
  final int? chatId;
  final List<ChatLabel> labels;

  ChatItem(
    this.name,
    this.message,
    this.time,
    this.avatar,
    this.icon,
    this.unreadCount, {
    this.isGroup = false,
    this.chatId,
    this.labels = const [],
  });

  get id => null;
}

class ChatListItem extends StatelessWidget {
  final ChatItem chatItem;
  final String endPointInTab;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final bool isCompact;

  const ChatListItem({
    super.key,
    required this.chatItem,
    required this.endPointInTab,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double cardPaddingV = isCompact ? 6 : 10;
    final double cardPaddingH = isCompact ? 10 : 12;
    final double cardMarginV = isCompact ? 2.5 : 6;
    final double radius = isCompact ? 14 : 20;
    final double checkSize = isCompact ? 20 : 24;
    final double avatarSize = isCompact ? 36 : 52;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: cardMarginV),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: cardPaddingH, vertical: cardPaddingV),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.1)
              : context.appColors.surfacePrimary.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isSelected
                ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.6)
                : context.appColors.borderSubtle.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.12)
                  : context.appColors.shadow.withValues(alpha: 0.06),
              blurRadius: isSelected ? (isCompact ? 8 : 14) : (isCompact ? 6 : 12),
              offset: Offset(0, isCompact ? 2 : 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: EdgeInsets.only(right: isCompact ? 8 : 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: checkSize,
                  height: checkSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.appColors.buttonPrimaryBg
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? context.appColors.buttonPrimaryBg
                          : context.appColors.textSecondary
                              .withValues(alpha: 0.5),
                      width: isCompact ? 1.5 : 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: isCompact ? 13 : 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            _buildAvatar(context, chatItem.avatar, size: avatarSize),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(
              child: ClaritySensitive(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatItem.name.isNotEmpty
                                ? (chatItem.name == 'support'
                                    ? AppLocalizations.of(context)!
                                        .translate('support_chat_name')
                                    : chatItem.name)
                                : AppLocalizations.of(context)!
                                    .translate('no_name'),
                            style: (isCompact
                                    ? context.appTextStyles.bodyMd
                                    : context.appTextStyles.bodyLg)
                                .copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.appColors.textPrimary,
                              fontSize: isCompact ? 14 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatChatTime(chatItem.time),
                          style: (isCompact
                                  ? context.appTextStyles.caption
                                  : context.appTextStyles.bodySm)
                              .copyWith(
                            color: context.appColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: isCompact ? 11 : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 2 : 4),
                    Row(
                      children: [
                        Expanded(child: _buildPreview(context)),
                        const SizedBox(width: 2),
                        SizedBox(
                          width: isCompact ? 24 : 33,
                          height: isCompact ? 24 : 33,
                          child: chatItem.unreadCount > 0
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.all(isCompact ? 4 : 8),
                                  decoration: BoxDecoration(
                                    color: context.appColors.buttonPrimaryBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    chatItem.unreadCount <= 9
                                        ? '${chatItem.unreadCount}'
                                        : '+9',
                                    style:
                                        context.appTextStyles.caption.copyWith(
                                      color: context.appColors.textInverse,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isCompact ? 10 : null,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                    if (chatItem.labels.isNotEmpty) ...[
                      SizedBox(height: isCompact ? 3 : 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        children: chatItem.labels.take(3).map((label) {
                          return _buildLabelChip(context, label);
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelChip(BuildContext context, ChatLabel label) {
    final chipColor = _parseColor(label.color);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 7.5,
        vertical: isCompact ? 1.5 : 2.5,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.38),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: chipColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4.5),
          Flexible(
            child: Text(
              label.name,
              style: TextStyle(
                color: chipColor,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.trim().isEmpty) {
      return const Color(0xFF6B7280);
    }
    String hex = colorStr.trim().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    } else if (hex.length == 3) {
      hex = 'FF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    } else if (hex.length == 8) {
      // already 8
    } else {
      return const Color(0xFF6B7280);
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF6B7280);
    }
  }

  Widget _buildPreview(BuildContext context) {
    final chatId = chatItem.chatId;
    if (chatId == null) return _messagePreview(context, chatItem.message);

    return ListenableBuilder(
      listenable: ChatDraftStore.instance,
      builder: (context, _) {
        final draft = ChatDraftStore.instance.peek(chatId);
        if (draft == null) return _messagePreview(context, chatItem.message);
        final label = AppLocalizations.of(context)?.translate('chat_draft') ??
            'Draft';
        final base = context.appTextStyles.bodyMd;
        return RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style: base.copyWith(
                  color: context.appColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: draft,
                style: base.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _messagePreview(BuildContext context, String message) {
    return RichText(
      text: TextSpan(
        children: parseHtmlToTextSpans(
          context,
          message,
          (isCompact
                  ? context.appTextStyles.caption
                  : context.appTextStyles.bodyMd)
              .copyWith(
            color: context.appColors.textPrimary.withValues(alpha: 0.76),
            fontSize: isCompact ? 12 : null,
          ),
        ),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAvatar(BuildContext context, String avatar, {double size = 52}) {
    bool isLeadsSection = endPointInTab == 'lead';
    bool isSupportAvatar = avatar == 'assets/icons/Profile/support_chat.png';
    bool isTaskSection = endPointInTab == 'task';
    final double radius = size / 2;

    if (isTaskSection && !avatar.contains('<svg')) {
      return CircleAvatar(
        backgroundImage: const AssetImage('assets/images/AvatarTask.png'),
        radius: radius,
        backgroundColor: context.appColors.surfacePrimary,
        onBackgroundImageError: (exception, stackTrace) {
          // print('Error loading asset image: assets/images/AvatarTask.png, $exception');
        },
      );
    }

    if (isLeadsSection &&
        (avatar.isEmpty || avatar == 'assets/icons/leads/default.png')) {
      return CircleAvatar(
        backgroundImage: const AssetImage('assets/images/AvatarChat.png'),
        radius: radius,
        backgroundColor: isSupportAvatar
            ? context.appColors.textPrimary
            : context.appColors.surfacePrimary,
        onBackgroundImageError: (exception, stackTrace) {
          // print('Error loading asset image: assets/images/AvatarChat.png, $exception');
        },
      );
    }

    // Пустая иконка — это site. Рисуем Icons.language.
    // Остальные каналы — PNG из assets/icons/leads.
    // Заглушку default.png здесь не показываем: ниже будет аватар чата.
    if (isLeadsSection && chatItem.icon != 'assets/icons/leads/default.png') {
      final isSite = chatItem.icon.isEmpty;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.appColors.backgroundSecondary,
          border: Border.all(
            color: context.appColors.borderPrimary,
            width: 1,
          ),
        ),
        child: Center(
          child: ChannelSourceIcon(
            sourceName: isSite ? 'site' : chatItem.icon,
            size: isSite ? (size * 0.6) : size,
            background: context.appColors.backgroundSecondary,
          ),
        ),
      );
    }

    if (avatar.contains('<svg')) {
      final imageUrl = extractImageUrlFromSvg(avatar);
      if (imageUrl != null) {
        return Container(
          width: size,
          height: size,
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
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: context.appColors.textInverse,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: context.appColors.textInverse,
                  fontSize: size * 0.38,
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
            width: size,
            height: size,
            placeholderBuilder: (context) => const CircularProgressIndicator(),
          );
        }
      }
    }

    try {
      return CircleAvatar(
        backgroundImage: AssetImage(avatar),
        radius: radius,
        backgroundColor: isSupportAvatar
            ? context.appColors.textPrimary
            : context.appColors.surfacePrimary,
        onBackgroundImageError: (exception, stackTrace) {
          // print('Error loading asset image: $avatar, $exception');
        },
      );
    } catch (e) {
      // print('Fallback avatar due to error: $e');
      return CircleAvatar(
        backgroundImage: AssetImage(isTaskSection
            ? 'assets/images/AvatarTask.png'
            : 'assets/images/AvatarChat.png'),
        radius: radius,
        backgroundColor: isSupportAvatar
            ? context.appColors.textPrimary
            : context.appColors.surfacePrimary,
      );
    }
  }

  String formatChatTime(String time) {
    if (time.isEmpty) {
      return '';
    }

    try {
      final DateTime parsedTime = DateTime.parse(time).toLocal();
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime messageDate =
          DateTime(parsedTime.year, parsedTime.month, parsedTime.day);
      final DateTime yesterday = today.subtract(const Duration(days: 1));

      if (messageDate == today) {
        return DateFormat('HH:mm').format(parsedTime);
      }

      if (messageDate == yesterday) {
        return 'Вчера';
      }

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

  List<TextSpan> parseHtmlToTextSpans(
    BuildContext context,
    String html,
    TextStyle baseStyle,
  ) {
    // Проверяем, содержит ли текст HTML-теги
    final bool isHtml = html.contains('<') && html.contains('>');

    if (!isHtml) {
      // Простой текст - возвращаем как есть
      return [TextSpan(text: html, style: baseStyle)];
    }

    // Предобработка HTML: убираем служебные теги
    String cleanedHtml = html
        // Убираем служебные теги Quill-редактора
        .replaceAll(
            RegExp(r'<span class="ql-cursor"[^>]*>.*?</span>', dotAll: true),
            '')
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
        } else if (node.localName == 's' ||
            node.localName == 'strike' ||
            node.localName == 'del') {
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
                  color: context.appColors.buttonPrimaryBg,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
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
      return [
        TextSpan(
            text: plainText.isNotEmpty ? plainText : html, style: baseStyle)
      ];
    }

    return spans;
  }
}
