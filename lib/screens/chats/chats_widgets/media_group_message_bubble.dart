import 'dart:io';
import 'dart:typed_data';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';
import 'package:crm_task_manager/widgets/full_image_screen_viewer.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
                    color: widget.isSender
                        ? context.appColors.textSecondary
                        : context.appColors.textPrimary,
                  ),
                ),
              ),
            _MediaCollage(
              items: items,
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
  final String time;
  final bool isSender;
  final bool isRead;
  final bool isUploading;
  final bool isMenuOpen;
  final String? baseUrl;
  final String senderName;

  const _MediaCollage({
    required this.items,
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
    if (baseUrl == null) return null;
    final normalizedPath = item.path.startsWith('storage/')
        ? item.path
        : 'storage/${item.path.startsWith('/') ? item.path.substring(1) : item.path}';
    return Uri.parse(baseUrl!).resolve(normalizedPath).toString();
  }

  @override
  Widget build(BuildContext context) {
    final remoteUrl = _buildRemoteUrl();

    return GestureDetector(
      onTap: item.isImage && !isMenuOpen && remoteUrl != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullImageScreenViewer(
                    imagePath: remoteUrl,
                    time: time,
                    fileName: item.name,
                    senderName: !isSender ? senderName : '',
                  ),
                ),
              );
            }
          : null,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMediaContent(context, remoteUrl),
            if (item.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 34,
                  color: Colors.white,
                ),
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
        return Image.network(
          remoteUrl,
          fit: BoxFit.cover,
        );
      }
    }

    if (item.isVideo) {
      final videoSource = _isLocalFile ? item.path : remoteUrl;
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

class _VideoThumbnailPreview extends StatelessWidget {
  final String videoSource;

  const _VideoThumbnailPreview({required this.videoSource});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: VideoThumbnail.thumbnailData(
        video: videoSource,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 60,
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return Container(
            color: const Color(0xFF111827),
            alignment: Alignment.center,
            child: const Icon(
              Icons.videocam_rounded,
              color: Colors.white,
              size: 30,
            ),
          );
        }

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
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
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
            ),
          ),
          if (isSender) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.done_all,
              size: 16,
              color: isRead ? const Color(0xFF7DD3FC) : Colors.white70,
            ),
          ],
        ],
      ),
    );
  }
}
