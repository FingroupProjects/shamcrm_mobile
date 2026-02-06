import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/widgets/full_image_screen_viewer.dart';

class ImageMessageBubble extends StatefulWidget {
  final String time;
  final bool isSender;
  final String filePath;
  final String fileName;
  final String senderName;
  final String? replyMessage;
  final bool isHighlighted;
  final bool isRead;
  final bool isLeadChat;
  final bool? isGroupChat;
  final List<MessageReaction> reactions;
  final Function(String)? onReactionTap;

  const ImageMessageBubble({
    Key? key,
    required this.time,
    required this.isSender,
    required this.senderName,
    required this.filePath,
    required this.fileName,
    this.replyMessage,
    this.isHighlighted = false,
    required this.isRead,
    required Message message,
    this.isLeadChat = false,
    this.isGroupChat,
    this.reactions = const [],
    this.onReactionTap,
  }) : super(key: key);

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
  final ApiService _apiService = ApiService();
  String? baseUrl;
  String? _lastFailedUrl;

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      setState(() {
        baseUrl = staticBaseUrl;
      });
    } catch (error) {
      setState(() {
        baseUrl =
            'https://info1fingrouptj-back.shamcrm.com'; // Обновляем fallback URL
      });
      debugPrint('Error fetching baseUrl: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Исправление: Добавляем /storage к пути, если его нет в filePath
    final String normalizedFilePath = widget.filePath.startsWith('storage/')
        ? widget.filePath
        : 'storage/${widget.filePath.startsWith('/') ? widget.filePath.substring(1) : widget.filePath}';

    // Формируем полный URL с помощью Uri для корректной обработки слешей
    final String? fullUrl = baseUrl != null
        ? Uri.parse(baseUrl!).resolve(normalizedFilePath).toString()
        : null;

    // Отладка: Логируем URL
    debugPrint(
        'ImageMessageBubble: baseUrl=$baseUrl, filePath=${widget.filePath}, fullUrl=$fullUrl');

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: widget.isHighlighted
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
        alignment:
            widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: widget.isSender
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ✅ Логика отображения имени отправителя:
            // - В лид-чатах: показываем имя для ОБЕИХ сторон (несколько менеджеров могут отвечать)
            // - В корпоративных группах: показываем имя только для собеседника
            // - В корпоративных чатах (не группа): показываем имя хотя бы для собеседника
            if (widget.isLeadChat ||
                widget.isGroupChat == true ||
                !widget.isSender)
              Text(
                widget.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isSender ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
            GestureDetector(
              onTap: fullUrl != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullImageScreenViewer(
                            imagePath: fullUrl,
                            time: widget.time,
                            fileName: widget.fileName,
                            senderName:
                                (!widget.isSender) ? widget.senderName : '',
                          ),
                        ),
                      );
                    }
                  : null,
              child: Column(
                crossAxisAlignment: widget.isSender
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.black26),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: fullUrl != null
                          ? Image.network(
                              fullUrl,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const _ImageLoadingPlaceholder(
                                  width: 200,
                                  height: 200,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading image: $error, StackTrace: $stackTrace');
                                _lastFailedUrl = fullUrl;
                                return _ImageErrorPlaceholder(
                                  width: 200,
                                  height: 200,
                                  onRetry: () {
                                    if (_lastFailedUrl == null) return;
                                    setState(() {});
                                  },
                                );
                              },
                            )
                          : Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey,
                              child: Center(
                                child: Text(AppLocalizations.of(context)!
                                    .translate('loading')),
                              ),
                            ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.reactions.isNotEmpty) ...[
                        Wrap(
                          spacing: 3,
                          runSpacing: 3,
                          children: widget.reactions.map((reaction) {
                            return CompactReactionChip(
                              reaction: reaction,
                              isSender: widget.isSender,
                              onTap: () =>
                                  widget.onReactionTap?.call(reaction.emoji),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Padding(
                        padding: EdgeInsets.only(
                          right: widget.isSender ? 0 : 10,
                          left: widget.isSender ? 10 : 0,
                        ),
                        child: Text(
                          widget.time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ChatSmsStyles.appBarTitleColor,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      if (widget.isSender)
                        Icon(
                          widget.isRead ? Icons.done_all : Icons.done_all,
                          size: 18,
                          color: widget.isRead
                              ? const Color.fromARGB(255, 45, 28, 235)
                              : Colors.grey.shade400,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageLoadingPlaceholder extends StatefulWidget {
  final double width;
  final double height;

  const _ImageLoadingPlaceholder({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  State<_ImageLoadingPlaceholder> createState() =>
      _ImageLoadingPlaceholderState();
}

class _ImageLoadingPlaceholderState extends State<_ImageLoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(_animation.value, 0),
                end: Alignment(_animation.value + 1, 0),
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                  Colors.grey.shade300,
                ],
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onRetry;

  const _ImageErrorPlaceholder({
    Key? key,
    required this.width,
    required this.height,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRetry,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: Colors.grey.shade700),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.translate('loading'),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
