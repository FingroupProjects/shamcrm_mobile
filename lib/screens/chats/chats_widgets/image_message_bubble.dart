import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_file_utils.dart';
import 'package:crm_task_manager/widgets/full_image_screen_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final bool isMenuOpen;
  final List<MessageReaction> reactions;
  final Function(String)? onReactionTap;

  const ImageMessageBubble({
    super.key,
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
    this.isMenuOpen = false,
    this.reactions = const [],
    this.onReactionTap,
  });

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
  final ApiService _apiService = ApiService();
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      if (!mounted) return;
      setState(() {
        baseUrl = staticBaseUrl;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        baseUrl = 'https://info1fingrouptj-back.shamcrm.com';
      });
      debugPrint('Error fetching baseUrl: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Если сервер уже вернул полный URL — используем как есть
    // (сервер возвращает https://file-api.shamcrm.com/tenants/...)
    final String? fullUrl = baseUrl != null
        ? resolveFileUrl(widget.filePath, baseUrl!)
        : null;

    debugPrint(
        'ImageMessageBubble: baseUrl=$baseUrl, filePath=${widget.filePath}, fullUrl=$fullUrl');

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: widget.isHighlighted
            ? [
                BoxShadow(
                  color: context.appColors.shadow.withValues(alpha: 0.18),
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: const Offset(0, -4),
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
            if (widget.isLeadChat ||
                widget.isGroupChat == true ||
                !widget.isSender)
              Text(
                widget.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: widget.isSender
                      ? context.appColors.textSecondary
                      : context.appColors.textPrimary,
                ),
              ),
            GestureDetector(
              onTap: fullUrl != null
                  ? () {
                      if (widget.isMenuOpen) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullImageScreenViewer(
                            imagePaths: [fullUrl],
                            initialIndex: 0,
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
                      border: Border.all(
                          width: 1, color: context.appColors.borderSubtle),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12)),
                      boxShadow: [
                        BoxShadow(
                          color: context.appColors.shadow
                              .withValues(alpha: 0.1),
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: fullUrl != null
                          ? _ShimmerImageLoader(
                              url: fullUrl,
                              width: 200,
                              height: 200,
                            )
                          : _buildUrlPending(context),
                    ),
                  ),
                  if (widget.reactions.isNotEmpty)
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: widget.isSender ? 0 : 6,
                          right: widget.isSender ? 6 : 0,
                          bottom: 2,
                        ),
                        child: ReactionCapsule(
                          reactions: widget.reactions,
                          isSender: widget.isSender,
                          onReactionTap: widget.onReactionTap,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                              : context.appColors.textSecondary
                                  .withValues(alpha: 0.5),
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

  Widget _buildUrlPending(BuildContext context) {
    return _ShimmerBox(width: 200, height: 200);
  }
}

// ─────────────────────────────────────────────────────────────
// Главный виджет загрузки с shimmer → плавное появление картинки
// ─────────────────────────────────────────────────────────────
class _ShimmerImageLoader extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const _ShimmerImageLoader({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  State<_ShimmerImageLoader> createState() => _ShimmerImageLoaderState();
}

class _ShimmerImageLoaderState extends State<_ShimmerImageLoader> {
  bool _loaded = false;
  bool _error = false;
  bool _minDisplayElapsed = false;
  DateTime? _loadStart;
  Future<File?>? _cachedFileFuture;

  @override
  void initState() {
    super.initState();
    _cachedFileFuture = ChatMediaPersistentCache.instance.getImageFile(widget.url);
  }

  void _onLoaded() {
    if (!mounted || _loaded) return;
    _loadStart ??= DateTime.now();
    const minVisible = Duration(milliseconds: 420);
    final elapsed = DateTime.now().difference(_loadStart!);
    final remaining = minVisible - elapsed;

    Future.delayed(remaining.isNegative ? Duration.zero : remaining, () {
      if (!mounted) return;
      setState(() {
        _minDisplayElapsed = true;
        _loaded = true;
      });
    });
  }

  void _onError() {
    if (!mounted) return;
    setState(() {
      _error = true;
      _loaded = true; // убираем shimmer, показываем заглушку
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _loaded ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _ShimmerBox(
              width: widget.width,
              height: widget.height,
            ),
          ),
          AnimatedOpacity(
            opacity: (_loaded && !_error && _minDisplayElapsed) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: FutureBuilder<File?>(
              future: _cachedFileFuture,
              builder: (context, snapshot) {
                final file = snapshot.data;
                if (file != null && file.existsSync()) {
                  _onLoaded();
                  return Image.file(
                    file,
                    width: widget.width,
                    height: widget.height,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                if (_error) {
                  return const SizedBox.shrink();
                }

                return CachedNetworkImage(
                  imageUrl: widget.url,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 140),
                  fadeOutDuration: Duration.zero,
                  useOldImageOnUrlChange: true,
                  imageBuilder: (context, imageProvider) {
                    _onLoaded();
                    return Image(
                      image: imageProvider,
                      width: widget.width,
                      height: widget.height,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    );
                  },
                  placeholder: (context, url) => const SizedBox.shrink(),
                  errorWidget: (context, error, stackTrace) {
                    debugPrint('_ShimmerImageLoader error: $error');
                    _onError();
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),

          // 3. Заглушка при ошибке
          if (_error)
            _ImageErrorFallback(
              width: widget.width,
              height: widget.height,
              onRetry: () => setState(() {
                _error = false;
                _loaded = false;
                _minDisplayElapsed = false;
                _loadStart = null;
              }),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shimmer-волна (использует ShimmerWave как в дашборде)
// ─────────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xffEAF4FF)),
            ShimmerWave(
              duration: const Duration(milliseconds: 1650),
              colors: const [
                Color(0xffD6EFFF),
                Color(0xffF8FDFF),
                Color(0xffBFE6FF),
                Color(0xffFFFFFF),
                Color(0xffD6EFFF),
              ],
              stops: const [0.0, 0.32, 0.52, 0.68, 1.0],
              child: Container(color: const Color(0xffEAF4FF)),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff9BD7FF).withValues(alpha: 0.9),
                  width: 1.1,
                ),
              ),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: math.min(width, height) * 0.30,
                  height: math.min(width, height) * 0.30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xff5AAEFF).withValues(alpha: 0.26),
                        const Color(0xff5AAEFF).withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    size: math.min(width, height) * 0.15,
                    color: const Color(0xff1E2E52).withValues(alpha: 0.42),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.02),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Заглушка при ошибке загрузки
// ─────────────────────────────────────────────────────────────
class _ImageErrorFallback extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onRetry;

  const _ImageErrorFallback({
    required this.width,
    required this.height,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRetry,
      child: Container(
        width: width,
        height: height,
        color: context.appColors.backgroundSecondary,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded,
                  color: context.appColors.textSecondary, size: 26),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.translate('loading'),
                style: TextStyle(
                    color: context.appColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
