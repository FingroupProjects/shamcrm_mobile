import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/models/chat/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_file_utils.dart';
import 'package:crm_task_manager/services/chat_media_download_manager.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:crm_task_manager/widgets/chat_download_progress_overlay.dart';
import 'package:crm_task_manager/widgets/full_image_screen_viewer.dart';
import 'package:crm_task_manager/widgets/full_video_screen_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MediaGroupMessageBubble extends StatefulWidget {
  final List<Message> messages;
  final String time;
  final bool isSender;
  final String senderName;
  final bool isHighlighted;
  final bool isRead;
  final bool isLeadChat;
  final bool? isGroupChat;
  final bool isMenuOpen;
  final List<MessageReaction> reactions;
  final Function(String)? onReactionTap;

  const MediaGroupMessageBubble({
    super.key,
    required this.messages,
    required this.time,
    required this.isSender,
    required this.senderName,
    required this.isHighlighted,
    required this.isRead,
    required this.isLeadChat,
    required this.isGroupChat,
    required this.isMenuOpen,
    required this.reactions,
    required this.onReactionTap,
  });

  @override
  State<MediaGroupMessageBubble> createState() =>
      _MediaGroupMessageBubbleState();
}

class _MediaGroupMessageBubbleState extends State<MediaGroupMessageBubble> {
  final ApiService _apiService = ApiService();
  String? _baseUrl;

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
        _baseUrl = staticBaseUrl;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _baseUrl = 'https://info1fingrouptj-back.shamcrm.com';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ChatAppearanceScope.of(context);
    final firstMessage = widget.messages.first;
    final items =
        firstMessage.type == 'media_group' && firstMessage.mediaItems.isNotEmpty
            ? firstMessage.mediaItems
            : widget.messages
                .map(
                  (message) => MessageMediaItem(
                    path: message.filePath ?? '',
                    name: message.text,
                    isImage: message.type == 'image',
                    isVideo: message.type == 'video',
                  ),
                )
                .where((item) => item.path.isNotEmpty)
                .toList();

    final isUploading = widget.messages.any((message) => message.isUploading);
    final viewerImagePaths = items
        .where((item) => item.isImage && item.path.isNotEmpty)
        .map((item) => _buildMediaUrl(item.path, _baseUrl))
        .whereType<String>()
        .where((path) => path.startsWith('http'))
        .toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: widget.isHighlighted
            ? [
                BoxShadow(
                  color: context.appColors.shadow.withValues(alpha: 0.18),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, -2),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: appearance.senderNameColor(context),
                  ),
                ),
              ),
            _MediaCollage(
              items: items,
              viewerImagePaths: viewerImagePaths,
              time: widget.time,
              isSender: widget.isSender,
              isRead: widget.isRead,
              isUploading: isUploading,
              isMenuOpen: widget.isMenuOpen,
              baseUrl: _baseUrl,
              senderName: widget.senderName,
            ),
            if (widget.reactions.isNotEmpty)
              Transform.translate(
                offset: const Offset(0, -4),
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
          ],
        ),
      ),
    );
  }
}

class _MediaCollage extends StatelessWidget {
  final List<MessageMediaItem> items;
  final List<String> viewerImagePaths;
  final String time;
  final bool isSender;
  final bool isRead;
  final bool isUploading;
  final bool isMenuOpen;
  final String? baseUrl;
  final String senderName;

  const _MediaCollage({
    required this.items,
    required this.viewerImagePaths,
    required this.time,
    required this.isSender,
    required this.isRead,
    required this.isUploading,
    required this.isMenuOpen,
    required this.baseUrl,
    required this.senderName,
  });

  static const double _spacing = 2;
  static const double _maxWidth = 290;
  static const double _singleHeight = 320;
  static const double _doubleHeight = 196;
  static const double _tripleHeight = 248;
  static const double _quadHeight = 248;
  static const double _manyHeight = 286;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _maxWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: _buildLayout(context),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _StatusOverlay(
                time: time,
                isSender: isSender,
                isRead: isRead,
                isUploading: isUploading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    switch (items.length) {
      case 1:
        return _tile(context, items[0], height: _singleHeight);
      case 2:
        return SizedBox(
          height: _doubleHeight,
          child: Row(
            children: [
              Expanded(child: _tile(context, items[0], height: _doubleHeight)),
              const SizedBox(width: _spacing),
              Expanded(child: _tile(context, items[1], height: _doubleHeight)),
            ],
          ),
        );
      case 3:
        return SizedBox(
          height: _tripleHeight,
          child: Row(
            children: [
              Expanded(
                flex: 13,
                child: _tile(context, items[0], height: _tripleHeight),
              ),
              const SizedBox(width: _spacing),
              Expanded(
                flex: 9,
                child: Column(
                  children: [
                    Expanded(
                      child: _tile(
                        context,
                        items[1],
                        height: (_tripleHeight - _spacing) / 2,
                      ),
                    ),
                    const SizedBox(height: _spacing),
                    Expanded(
                      child: _tile(
                        context,
                        items[2],
                        height: (_tripleHeight - _spacing) / 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 4:
        return SizedBox(
          height: _quadHeight,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _tile(
                        context,
                        items[0],
                        height: (_quadHeight - _spacing) / 2,
                      ),
                    ),
                    const SizedBox(width: _spacing),
                    Expanded(
                      child: _tile(
                        context,
                        items[1],
                        height: (_quadHeight - _spacing) / 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _spacing),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _tile(
                        context,
                        items[2],
                        height: (_quadHeight - _spacing) / 2,
                      ),
                    ),
                    const SizedBox(width: _spacing),
                    Expanded(
                      child: _tile(
                        context,
                        items[3],
                        height: (_quadHeight - _spacing) / 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return SizedBox(
          height: _manyHeight,
          child: Column(
            children: [
              Expanded(
                flex: 11,
                child: Row(
                  children: [
                    Expanded(
                      child: _tile(
                        context,
                        items[0],
                        height: 124,
                      ),
                    ),
                    const SizedBox(width: _spacing),
                    Expanded(
                      child: _tile(
                        context,
                        items[1],
                        height: 124,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _spacing),
              Expanded(
                flex: 13,
                child: Row(
                  children: [
                    Expanded(
                      child: _tile(
                        context,
                        items[2],
                        height: 160,
                      ),
                    ),
                    const SizedBox(width: _spacing),
                    Expanded(
                      child: _tile(
                        context,
                        items[3],
                        height: 160,
                      ),
                    ),
                    const SizedBox(width: _spacing),
                    Expanded(
                      child: _tile(
                        context,
                        items[4],
                        height: 160,
                        extraCount: items.length > 5 ? items.length - 5 : 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _tile(
    BuildContext context,
    MessageMediaItem item, {
    required double height,
    int extraCount = 0,
  }) {
    return _MediaTile(
      item: item,
      height: height,
      extraCount: extraCount,
      viewerImagePaths: viewerImagePaths,
      baseUrl: baseUrl,
      isMenuOpen: isMenuOpen,
      isUploading: isUploading,
      time: time,
      senderName: senderName,
      isSender: isSender,
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MessageMediaItem item;
  final double height;
  final int extraCount;
  final List<String> viewerImagePaths;
  final String? baseUrl;
  final bool isMenuOpen;
  final bool isUploading;
  final String time;
  final String senderName;
  final bool isSender;

  const _MediaTile({
    required this.item,
    required this.height,
    required this.extraCount,
    required this.viewerImagePaths,
    required this.baseUrl,
    required this.isMenuOpen,
    required this.isUploading,
    required this.time,
    required this.senderName,
    required this.isSender,
  });

  bool get _isLocalFile =>
      item.path.startsWith('/') || item.path.startsWith('file:');

  String? _buildRemoteUrl() {
    return _buildMediaUrl(item.path, baseUrl);
  }

  String? _playableSource() {
    if (_isLocalFile) {
      return item.path.replaceFirst('file://', '');
    }
    return _buildRemoteUrl();
  }

  int _resolveInitialIndex(String? remoteUrl) {
    if (remoteUrl == null || viewerImagePaths.isEmpty) {
      return 0;
    }

    final exactMatchIndex =
        viewerImagePaths.indexWhere((path) => path == remoteUrl);
    if (exactMatchIndex >= 0) {
      return exactMatchIndex;
    }

    final normalizedRemoteUrl = Uri.tryParse(remoteUrl)?.toString();
    if (normalizedRemoteUrl == null) {
      return 0;
    }

    final fallbackIndex = viewerImagePaths.indexWhere((path) {
      final parsedPath = Uri.tryParse(path)?.toString();
      return parsedPath == normalizedRemoteUrl || path.contains(remoteUrl);
    });

    return fallbackIndex >= 0 ? fallbackIndex : 0;
  }

  @override
  Widget build(BuildContext context) {
    final remoteUrl = _buildRemoteUrl();
    final initialIndex = _resolveInitialIndex(remoteUrl);

    return GestureDetector(
      onTap: !isMenuOpen && !isUploading && _playableSource() != null
          ? () {
              final source = _playableSource()!;
              if (item.isVideo) {
                openFullVideoScreenViewer(
                  context,
                  videoPath: source,
                  fileName: item.name,
                  time: time,
                  senderName: !isSender ? senderName : '',
                );
                return;
              }
              if (item.isImage && (remoteUrl != null || source.isNotEmpty)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullImageScreenViewer(
                      imagePaths: viewerImagePaths.isNotEmpty
                          ? viewerImagePaths
                          : [remoteUrl ?? source],
                      initialIndex: initialIndex,
                      time: time,
                      fileName: item.name,
                      senderName: !isSender ? senderName : '',
                    ),
                  ),
                );
              }
            }
          : null,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMediaContent(context, remoteUrl),
            ListenableBuilder(
              listenable: ChatMediaDownloadManager.instance,
              builder: (context, _) {
                final task = ChatMediaDownloadManager.instance
                    .taskFor(_playableSource());
                final hidePlay = task?.showOverlay == true;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.isVideo && !hidePlay)
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    if (task != null && task.showOverlay)
                      ChatDownloadProgressOverlay(task: task),
                  ],
                );
              },
            ),
            if (extraCount > 0)
              Container(
                color: Colors.black.withValues(alpha: 0.42),
                alignment: Alignment.center,
                child: Text(
                  '+$extraCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            if (isUploading)
              Container(
                color: Colors.black.withValues(alpha: 0.24),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        value: item.uploadProgress > 0
                            ? item.uploadProgress
                            : null,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(item.uploadProgress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (item.isVideo)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, String? remoteUrl) {
    if (item.isImage) {
      if (_isLocalFile) {
        return Image.file(
          File(item.path),
          fit: BoxFit.cover,
        );
      }
      if (remoteUrl != null) {
        return _GroupImageLoader(url: remoteUrl);
      }
    }

    if (item.isVideo) {
      final videoSource = _playableSource();
      if (videoSource != null && videoSource.isNotEmpty) {
        return _VideoThumbnailPreview(videoSource: videoSource);
      }
    }

    return Container(
      color: const Color(0xFF111827),
      alignment: Alignment.center,
      child: Icon(
        item.isVideo ? Icons.videocam_rounded : Icons.image_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

String? _buildMediaUrl(String path, String? baseUrl) {
  if (path.startsWith('/') || path.startsWith('file:')) {
    return path.replaceFirst('file://', '');
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (baseUrl == null || baseUrl.isEmpty) return null;
  final url = resolveFileUrl(path, baseUrl);
  return url.isEmpty ? null : url;
}

class _VideoThumbnailPreview extends StatelessWidget {
  final String videoSource;

  const _VideoThumbnailPreview({required this.videoSource});

  @override
  Widget build(BuildContext context) {
    return _MemoizedVideoThumbnail(videoSource: videoSource);
  }
}

class _MemoizedVideoThumbnail extends StatefulWidget {
  final String videoSource;

  const _MemoizedVideoThumbnail({required this.videoSource});

  @override
  State<_MemoizedVideoThumbnail> createState() =>
      _MemoizedVideoThumbnailState();
}

class _MemoizedVideoThumbnailState extends State<_MemoizedVideoThumbnail> {
  late final Future<File?> _thumbnailFuture = ChatMediaPersistentCache.instance
      .getVideoThumbnailFile(widget.videoSource);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null || !file.existsSync()) {
          return const _VideoWavePlaceholder();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            const _VideoWavePlaceholder(),
            Image.file(
              file,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VideoWavePlaceholder extends StatelessWidget {
  const _VideoWavePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xffFCFEFF)),
        ShimmerWave(
          duration: const Duration(milliseconds: 1650),
          colors: const [
            Color(0xffE7F3FF),
            Color(0xffF7FCFF),
            Color(0xffCFEFFF),
            Color(0xffFFFFFF),
            Color(0xffE7F3FF),
          ],
          stops: const [0.0, 0.32, 0.52, 0.68, 1.0],
          child: Container(color: const Color(0xffFCFEFF)),
        ),
        Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xff89D2FF).withValues(alpha: 0.18),
                  const Color(0xff89D2FF).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageWavePlaceholder extends StatelessWidget {
  const _ImageWavePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
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
        Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xff5AAEFF).withValues(alpha: 0.26),
                  const Color(0xff5AAEFF).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupImageLoader extends StatefulWidget {
  final String url;

  const _GroupImageLoader({required this.url});

  @override
  State<_GroupImageLoader> createState() => _GroupImageLoaderState();
}

class _GroupImageLoaderState extends State<_GroupImageLoader> {
  late final Future<File?> _cachedFileFuture =
      ChatMediaPersistentCache.instance.getImageFile(widget.url);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _ImageWavePlaceholder(),
        FutureBuilder<File?>(
          future: _cachedFileFuture,
          builder: (context, snapshot) {
            final file = snapshot.data;
            if (file != null && file.existsSync()) {
              return Image.file(
                file,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            return CachedNetworkImage(
              imageUrl: widget.url,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 160),
              fadeOutDuration: Duration.zero,
              useOldImageOnUrlChange: true,
              imageBuilder: (context, imageProvider) {
                return Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                );
              },
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: (context, error, stackTrace) {
                debugPrint(
                  'MediaGroupMessageBubble image error for ${widget.url}: $error',
                );
                return const _ImageWavePlaceholder();
              },
            );
          },
        ),
      ],
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  final String time;
  final bool isSender;
  final bool isRead;
  final bool isUploading;

  const _StatusOverlay({
    required this.time,
    required this.isSender,
    required this.isRead,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    final appearance = ChatAppearanceScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isSender
                ? appearance.senderBubbleColor(context)
                : appearance.receiverBubbleColor(context))
            .withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appearance.borderColor(context, isSender),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUploading)
            const Padding(
              padding: EdgeInsets.only(right: 5),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          Text(
            time,
            style: TextStyle(
              fontSize: appearance.scaledFont(12),
              color: isSender
                  ? appearance.outgoingForeground(context)
                  : appearance.incomingForeground(context),
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
            ),
          ),
          if (isSender) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.done_all,
              size: 16,
              color: isRead
                  ? appearance.outgoingForeground(context)
                  : appearance.secondaryForeground(context, isSender),
            ),
          ],
        ],
      ),
    );
  }
}
