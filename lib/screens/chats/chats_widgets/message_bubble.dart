import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';

// Регулярное выражение для поиска URL в тексте
final RegExp _urlRegex = RegExp(
  r'https?://[^\s]+|www\.[^\s]+',
  caseSensitive: false,
);

// Функция для удаления HTML тегов и получения чистого текста
String _stripHtmlTags(String html) {
  if (!html.contains('<') || !html.contains('>')) {
    return html; // Если нет HTML тегов, возвращаем как есть
  }

  try {
    final document = parse(html);
    return document.body?.text ?? html.replaceAll(RegExp(r'<[^>]*>'), '');
  } catch (e) {
    // Если парсинг не удался, используем регулярное выражение
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isSender;
  final String senderName;
  final String? replyMessage;
  final String? replyAuthorName;
  final bool isTargetReferralReplyPreview;
  final VoidCallback? onTargetReferralTap;
  final int? replyMessageId;
  final void Function(int)? onReplyTap;
  final bool isHighlighted;
  final bool isChanged;
  final bool isRead;
  final bool isNote;
  final bool isLeadChat;
  final bool? isGroupChat;
  final List<MessageReaction> reactions; // Реакции
  final Function(String emoji)? onReactionTap; // Callback для реакций
  final VoidCallback? onLongPress; // Callback для long press

  MessageBubble({
    Key? key,
    required this.message,
    required this.time,
    required this.isSender,
    required this.senderName,
    this.replyMessage,
    this.replyAuthorName,
    this.isTargetReferralReplyPreview = false,
    this.onTargetReferralTap,
    this.replyMessageId,
    this.onReplyTap,
    this.isHighlighted = false,
    required this.isChanged,
    required this.isRead,
    required this.isNote,
    this.isLeadChat = false,
    this.isGroupChat,
    this.reactions = const [], // Реакции по умолчанию пустой список
    this.onReactionTap, // Callback для реакций
    this.onLongPress, // Callback для long press
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final bubbleColor = isNote
        ? colors.warning
        : isSender
            ? colors.info
            : colors.surfacePrimary;
    final onBubbleColor =
        isNote || !isSender ? colors.textPrimary : colors.textInverse;
    final onBubbleMuted = onBubbleColor.withValues(alpha: 0.7);

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.3),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: const Offset(0, -4),
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
              // ✅ Логика отображения имени отправителя:
              // - В лид-чатах: показываем имя для ОБЕИХ сторон (несколько менеджеров могут отвечать)
              // - В корпоративных группах: показываем имя только для собеседника
              // - В корпоративных чатах (не группа): показываем имя хотя бы для собеседника
              if (isLeadChat || isGroupChat == true || !isSender)
                Text(
                  senderName,
                  style: textStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSender ? colors.textMuted : colors.buttonPrimaryBg,
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isSender
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (replyMessage != null && replyMessage!.isNotEmpty) ...[
                      _buildReplyPreview(context),
                      const SizedBox(height: 8),
                    ],
                    // Текст сообщения
                    _buildMessageWithHtml(
                      context,
                      message,
                      baseStyle: textStyles.bodyMd.copyWith(
                        color: onBubbleColor,
                        fontWeight: FontWeight.w500,
                      ),
                      linkColor: isSender ? colors.textInverse : colors.info,
                    ),

                    // "Изменено" если отредактировано
                    if (isChanged)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          AppLocalizations.of(context)!.translate('edited_sms'),
                          style: textStyles.caption.copyWith(
                            color: onBubbleMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Нижний блок: реакции и время в одной строке (компактно)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Реакции слева (если есть)
                        if (reactions.isNotEmpty) ...[
                          Wrap(
                            spacing: 3,
                            runSpacing: 3,
                            children: reactions.map((reaction) {
                              return CompactReactionChip(
                                reaction: reaction,
                                isSender: isSender,
                                onTap: () =>
                                    onReactionTap?.call(reaction.emoji),
                              );
                            }).toList(),
                          ),
                          const SizedBox(width: 6),
                        ],

                        // Время
                        if (time.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                time,
                                style: textStyles.caption.copyWith(
                                  color: onBubbleMuted,
                                ),
                              ),
                              const SizedBox(width: 3),
                              if (isSender)
                                Icon(
                                  isRead ? Icons.done_all : Icons.done_all,
                                  size: 16,
                                  color: isRead ? onBubbleColor : onBubbleMuted,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final replyText = _stripHtmlTags(replyMessage ?? '').trim();
    final isTapEnabled = isTargetReferralReplyPreview
        ? onTargetReferralTap != null
        : replyMessageId != null && onReplyTap != null;
    final Color accentColor =
        isSender ? colors.textInverse : colors.buttonPrimaryBg;
    final Color panelBackground = isSender
        ? colors.textInverse.withValues(alpha: 0.15)
        : colors.surfaceAccent;
    final Color titleColor =
        isSender ? colors.textInverse : colors.buttonPrimaryBg;
    final Color bodyColor =
        isSender ? colors.textInverse.withValues(alpha: 0.7) : colors.textPrimary;
    final int maxPreviewLines = isTargetReferralReplyPreview ? 40 : 2;
    final authorLabel = (replyAuthorName ?? '').trim().isNotEmpty
        ? replyAuthorName!.trim()
        : AppLocalizations.of(context)!.translate('unknown_channel');

    return GestureDetector(
      onTap: isTapEnabled
          ? () {
              if (isTargetReferralReplyPreview) {
                onTargetReferralTap?.call();
                return;
              }
              onReplyTap?.call(replyMessageId!);
            }
          : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.68,
        ),
        decoration: BoxDecoration(
          color: panelBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSender
                ? colors.textInverse.withValues(alpha: 0.2)
                : colors.shadow.withValues(alpha: 0.13),
            width: 0.8,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authorLabel,
                        style: textStyles.caption.copyWith(
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        replyText,
                        maxLines: maxPreviewLines,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodySm.copyWith(
                          height: 1.2,
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Метод для парсинга текста с ссылками (без HTML)
  List<TextSpan> _parseTextWithLinks(
    BuildContext context,
    String text,
    TextStyle baseStyle, {
    required Color linkColor,
  }) {
    final List<TextSpan> spans = [];
    final matches = _urlRegex.allMatches(text);

    if (matches.isEmpty) {
      // Нет ссылок — возвращаем обычный текст
      return [TextSpan(text: text, style: baseStyle)];
    }

    int currentPosition = 0;

    for (final match in matches) {
      // Добавляем текст до ссылки
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
          style: baseStyle,
        ));
      }

      // Добавляем саму ссылку
      String url = match.group(0)!;
      String displayUrl = url;

      // Добавляем https:// если ссылка начинается с www.
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }

      spans.add(
        TextSpan(
          text: displayUrl,
          style: baseStyle.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _handleLinkTap(context, url),
        ),
      );

      currentPosition = match.end;
    }

    // Добавляем оставшийся текст
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
        style: baseStyle,
      ));
    }

    return spans;
  }

  // Универсальный обработчик клика по ссылке
  void _handleLinkTap(BuildContext context, String url) {
    // Вариант 1: Показываем меню с опциями (текущая логика)
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox messageBox = context.findRenderObject() as RenderBox;
    final Offset position =
        messageBox.localToGlobal(Offset.zero, ancestor: overlay);

    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    showMenu(
      context: context,
      color: colors.surfacePrimary,
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
          context: context,
          icon: 'assets/icons/chats/menu_icons/open.svg',
          text: AppLocalizations.of(context)!.translate('open_url_source'),
          iconColor: colors.textPrimary,
          textColor: colors.textPrimary,
          onTap: () async {
            Navigator.pop(context);
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
        ),
        _buildMenuItem(
          context: context,
          icon: 'assets/icons/chats/menu_icons/copy.svg',
          text: AppLocalizations.of(context)!.translate('copy'),
          iconColor: colors.textPrimary,
          textColor: colors.textPrimary,
          onTap: () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate('copy_url_source_text'),
                  style: textStyles.bodyMd.copyWith(
                    color: colors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: colors.success,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
      ],
    );

    // Вариант 2: Прямой переход (раскомментируйте, если нужно)
    // launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _buildMessageWithHtml(
    BuildContext context,
    String text, {
    required TextStyle baseStyle,
    required Color linkColor,
  }) {
    final double maxWidth = MediaQuery.of(context).size.width * 0.7;

    // Проверяем, содержит ли текст HTML-теги
    final bool isHtml = text.contains('<') && text.contains('>');

    if (!isHtml) {
      // Простой текст — ищем ссылки регуляркой
      final spans = _parseTextWithLinks(
        context,
        text,
        baseStyle,
        linkColor: linkColor,
      );

      return Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RichText(
          text: TextSpan(style: baseStyle, children: spans),
          maxLines: 10000000,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Предобработка HTML: убираем служебные теги
    String cleanedHtml = text
        // Убираем служебные теги Quill-редактора
        .replaceAll(
            RegExp(r'<span class="ql-cursor"[^>]*>.*?</span>', dotAll: true),
            '')
        .replaceAll(RegExp(r'<span[^>]*>\s*</span>'), '') // Пустые span
        // Убираем невидимые символы
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Оригинальная логика для HTML
    final document = parse(cleanedHtml);
    List<TextSpan> spans = [];
    bool needsLineBreak =
        false; // Флаг для добавления переноса строки после блочных элементов

    void parseNode(dom.Node node, TextStyle currentStyle,
        {bool isFirstInBlock = false}) {
      if (node is dom.Text) {
        final textContent = node.text.trim();
        if (textContent.isNotEmpty) {
          // Добавляем перенос строки если предыдущий блок закончился
          if (needsLineBreak && spans.isNotEmpty) {
            spans.add(TextSpan(text: '\n', style: currentStyle));
            needsLineBreak = false;
          }
          // Парсим текстовые узлы на предмет ссылок
          spans.addAll(_parseTextWithLinks(
            context,
            textContent,
            currentStyle,
            linkColor: linkColor,
          ));
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
                  color: linkColor,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _handleLinkTap(context, url),
              ),
            );
          }
          return;
        } else if (node.localName == 'br') {
          // Обработка переноса строки
          spans.add(TextSpan(text: '\n', style: currentStyle));
          return;
        } else if (node.localName == 'p' ||
            node.localName == 'div' ||
            node.localName == 'h1' ||
            node.localName == 'h2' ||
            node.localName == 'h3' ||
            node.localName == 'blockquote') {
          // Блочные элементы - обрабатываем их содержимое без самих тегов
          // Добавляем перенос строки перед блоком если это не первый элемент
          if (spans.isNotEmpty && !isFirstInBlock) {
            spans.add(TextSpan(text: '\n', style: currentStyle));
          }

          for (var child in node.nodes) {
            parseNode(child, newStyle);
          }

          // Помечаем что после блока нужен перенос
          needsLineBreak = true;
          return;
        } else if (node.localName == 'span') {
          // Обычный span без служебных классов - просто обрабатываем содержимое
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

    bool isFirst = true;
    for (var node in document.body!.nodes) {
      parseNode(node, baseStyle, isFirstInBlock: isFirst);
      isFirst = false;
    }

    // Если нет span'ов (только теги без текста), возвращаем пустой текст
    if (spans.isEmpty) {
      return Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RichText(
          text: TextSpan(text: '', style: baseStyle),
          maxLines: 10000000,
          overflow: TextOverflow.ellipsis,
        ),
      );
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
    required BuildContext context,
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
                  style: context.appTextStyles.bodyMd.copyWith(
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
