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
      setState(() => _baseUrl = staticBaseUrl);
    } catch (_) {
      if (!mounted) return;
      setState(() => _baseUrl = 'https://info1fingrouptj-back.shamcrm.com');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;
    if (messages.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: widget.isHighlighted
            ? [
                BoxShadow(
                  color: context.appColors.shadow.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ]
            : const [],
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
                  style: context.appTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.isSender
                        ? context.appColors.textSecondary
                        : context.appColors.textPrimary,
                  ),
                ),
              ),
            _MediaCollage(
              messages: messages,
              time: widget.time,
              isSender: widget.isSender,
              isRead: widget.isRead,
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
  static const double _spacing = 2;
  static const double _maxWidth = 290;

  final List<Message> messages;
  final String time;
  final bool isSender;
  final bool isRead;
  final bool isMenuOpen;
  final String? baseUrl;
  final String senderName;

  const _MediaCollage({
    required this.messages,
    required this.time,
    required this.isSender,
    required this.isRead,
    required this.isMenuOpen,
    required this.baseUrl,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: _maxWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            _layout(context, items),
            Positioned(
              right: 8,
              bottom: 8,
              child: _StatusOverlay(
                time: time,
                isSender: isSender,
                isRead: isRead,
                isUploading: messages.any((message) => message.isUploading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MediaTileData> _buildItems() {
    final built = <_MediaTileData>[];
    for (final message in messages) {
      if (message.type == 'media_group' && message.mediaItems.isNotEmpty) {
        for (final item in message.mediaItems) {
          built.add(
            _MediaTileData(
              path: item.path,
              name: item.name,
              isImage: item.isImage,
              isVideo: item.isVideo,
              uploadProgress: item.uploadProgress,
              isUploading: message.isUploading,
            ),
          );
        }
        continue;
      }

      final path = message.filePath ?? '';
      if (path.isEmpty) continue;
      built.add(
        _MediaTileData(
          path: path,
          name: message.text.isEmpty ? path.split('/').last : message.text,
          isImage: message.type == 'image',
          isVideo: message.type == 'video',
          uploadProgress: message.isUploading ? 0 : 1,
          isUploading: message.isUploading,
        ),
      );
    }
    return built.take(10).toList();
  }

  Widget _layout(BuildContext context, List<_MediaTileData> items) {
    if (items.length == 1) {
      return _tile(context, items[0], height: 320);
    }
    if (items.length == 2) {
      return SizedBox(
        height: 196,
        child: Row(
          children: [
            Expanded(child: _tile(context, items[0], height: 196)),
            const SizedBox(width: _spacing),
            Expanded(child: _tile(context, items[1], height: 196)),
          ],
        ),
      );
    }
    if (items.length == 3) {
      return SizedBox(
        height: 248,
        child: Row(
          children: [
            Expanded(
              flex: 13,
              child: _tile(context, items[0], height: 248),
            ),
            const SizedBox(width: _spacing),
            Expanded(
              flex: 9,
              child: Column(
                children: [
                  Expanded(
                    child: _tile(context, items[1], height: 123),
                  ),
                  const SizedBox(height: _spacing),
                  Expanded(
                    child: _tile(context, items[2], height: 123),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (items.length == 4) {
      return SizedBox(
        height: 248,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(context, items[0], height: 123)),
                  const SizedBox(width: _spacing),
                  Expanded(child: _tile(context, items[1], height: 123)),
                ],
              ),
            ),
            const SizedBox(height: _spacing),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(context, items[2], height: 123)),
                  const SizedBox(width: _spacing),
                  Expanded(child: _tile(context, items[3], height: 123)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final visible = items.take(5).toList();
    final hiddenCount = items.length - visible.length;
    return SizedBox(
      height: 286,
      child: Column(
        children: [
          Expanded(
            flex: 11,
            child: Row(
              children: [
                Expanded(child: _tile(context, visible[0], height: 124)),
                const SizedBox(width: _spacing),
                Expanded(child: _tile(context, visible[1], height: 124)),
              ],
            ),
          ),
          const SizedBox(height: _spacing),
          Expanded(
            flex: 13,
            child: Row(
              children: [
                Expanded(child: _tile(context, visible[2], height: 160)),
                const SizedBox(width: _spacing),
                Expanded(child: _tile(context, visible[3], height: 160)),
                const SizedBox(width: _spacing),
                Expanded(
                  child: _tile(
                    context,
                    visible[4],
                    height: 160,
                    extraCount: hiddenCount > 0 ? hiddenCount : 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    _MediaTileData item, {
    required double height,
    int extraCount = 0,
  }) {
    return _MediaTile(
      item: item,
      height: height,
      extraCount: extraCount,
      baseUrl: baseUrl,
      isMenuOpen: isMenuOpen,
      time: time,
      senderName: senderName,
      isSender: isSender,
    );
  }
}

class _MediaTileData {
  final String path;
  final String name;
  final bool isImage;
  final bool isVideo;
  final double uploadProgress;
  final bool isUploading;

  const _MediaTileData({
    required this.path,
    required this.name,
    required this.isImage,
    required this.isVideo,
    required this.uploadProgress,
    required this.isUploading,
  });
}

class _MediaTile extends StatelessWidget {
  final _MediaTileData item;
  final double height;
  final int extraCount;
  final String? baseUrl;
  final bool isMenuOpen;
  final String time;
  final String senderName;
  final bool isSender;

  const _MediaTile({
    required this.item,
    required this.height,
    required this.extraCount,
    required this.baseUrl,
    required this.isMenuOpen,
    required this.time,
    required this.senderName,
    required this.isSender,
  });

  bool get _isLocalFile =>
      item.path.startsWith('/') || item.path.startsWith('file:');

  String? _buildRemoteUrl() {
    if (baseUrl == null || item.path.isEmpty) return null;
    final normalizedPath = item.path.startsWith('storage/')
        ? item.path
        : 'storage/${item.path.startsWith('/') ? item.path.substring(1) : item.path}';
    return Uri.parse(baseUrl!).resolve(normalizedPath).toString();
  }

  @override
  Widget build(BuildContext context) {
    final remoteUrl = _buildRemoteUrl();
    final viewableImagePath = _isLocalFile ? item.path : remoteUrl;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return GestureDetector(
      onTap: item.isImage && !isMenuOpen && viewableImagePath != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullImageScreenViewer(
                    imagePath: viewableImagePath,
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
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.overlay.withValues(alpha: 0.34),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 34,
                    color: colors.textInverse,
                  ),
                ),
              ),
            if (extraCount > 0)
              Container(
                color: colors.overlay.withValues(alpha: 0.44),
                alignment: Alignment.center,
                child: Text(
                  '+$extraCount',
                  style: textStyles.displayLg.copyWith(
                    color: colors.textInverse,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (item.isUploading)
              Container(
                color: colors.overlay.withValues(alpha: 0.28),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2.6,
                            value: item.uploadProgress.clamp(0, 1),
                            backgroundColor:
                                colors.textInverse.withValues(alpha: 0.18),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.textInverse,
                            ),
                          ),
                          Text(
                            '${(item.uploadProgress.clamp(0, 1) * 100).round()}%',
                            style: textStyles.bodySm.copyWith(
                              color: colors.textInverse,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
        return Image.file(File(item.path), fit: BoxFit.cover);
      }
      if (remoteUrl != null) {
        return Image.network(remoteUrl, fit: BoxFit.cover);
      }
    }

    if (item.isVideo) {
      final source = _isLocalFile ? item.path : remoteUrl;
      if (source != null && source.isNotEmpty) {
        return _VideoThumbnailPreview(videoSource: source);
      }
    }

    return Container(
      color: context.appColors.surfaceElevated,
      alignment: Alignment.center,
      child: Icon(
        item.isVideo ? Icons.videocam_rounded : Icons.image_rounded,
        color: context.appColors.textInverse,
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
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(
          color: context.appColors.surfaceElevated,
          alignment: Alignment.center,
          child: Icon(
            Icons.videocam_rounded,
            color: context.appColors.textInverse,
            size: 30,
          ),
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
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.overlay.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUploading)
            Padding(
              padding: EdgeInsets.only(right: 5),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.textInverse),
                ),
              ),
            ),
          Text(
            time,
            style: textStyles.bodySm.copyWith(
              fontSize: 12,
              color: colors.textInverse,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isSender) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.done_all,
              size: 16,
              color: isRead
                  ? colors.info
                  : colors.textInverse.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }
}
