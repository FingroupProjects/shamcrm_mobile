import 'dart:io';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:voice_message_package/voice_message_package.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/models/chat/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_file_utils.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';

class VoiceMessageWidget extends StatefulWidget {
  final Message message;
  final String baseUrl;
  final bool isLeadChat;
  final bool? isGroupChat;
  final List<MessageReaction> reactions;
  final Function(String)? onReactionTap;

  const VoiceMessageWidget({
    super.key,
    required this.message,
    required this.baseUrl,
    this.isLeadChat = false,
    this.isGroupChat,
    this.reactions = const [],
    this.onReactionTap,
  });

  @override
  VoiceMessageWidgetState createState() => VoiceMessageWidgetState();
}

class VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with AutomaticKeepAliveClientMixin {
  VoiceController? _audioController;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _prepareAudio();
  }

  @override
  void didUpdateWidget(covariant VoiceMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.filePath == widget.message.filePath &&
        oldWidget.baseUrl == widget.baseUrl) {
      return;
    }
    _prepareAudio();
  }

  Future<void> _prepareAudio() async {
    final generation = ++_loadGeneration;
    _audioController?.dispose();
    _audioController = null;
    _isLoading = true;
    _hasError = false;
    if (mounted && generation > 1) {
      setState(() {});
    }

    try {
      final source = _getAudioSource();
      if (source.isEmpty) {
        if (!mounted || generation != _loadGeneration) return;
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final localPath = await _resolveLocalPath(source);
      if (!mounted || generation != _loadGeneration) return;

      if (localPath == null || localPath.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      _audioController = VoiceController(
        audioSrc: localPath,
        onComplete: () {},
        onPause: () {},
        onPlaying: () {},
        onError: (err) {
          debugPrint(
              'Ошибка воспроизведения аудио: $err, filePath: ${widget.message.filePath}');
          if (!mounted || generation != _loadGeneration) return;
          setState(() {
            _hasError = true;
          });
        },
        maxDuration: widget.message.duration.inSeconds > 0
            ? widget.message.duration
            : const Duration(seconds: 5),
        isFile: true,
      );

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (error) {
      debugPrint('VoiceMessageWidget prepare error: $error');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<String?> _resolveLocalPath(String source) async {
    if (source.startsWith('/') || source.startsWith('file:')) {
      final file = File(source.replaceFirst('file://', ''));
      return await file.exists() ? file.path : null;
    }

    final file = await ChatMediaPersistentCache.instance.getAnyFile(source);
    return file?.path;
  }

  String _getAudioSource() {
    final filePath = widget.message.filePath ?? '';
    final url = resolveFileUrl(filePath, widget.baseUrl.replaceAll('/api', ''));
    return url.isNotEmpty ? url : filePath;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appearance = ChatAppearanceScope.of(context);
    final bubbleColor = widget.message.isMyMessage
        ? appearance.senderBubbleColor(context)
        : appearance.receiverBubbleColor(context);
    final foreground = widget.message.isMyMessage
        ? appearance.outgoingForeground(context)
        : appearance.incomingForeground(context);

    return Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        right: widget.message.isMyMessage == false ? 60 : 0,
        left: widget.message.isMyMessage ? 60 : 0,
      ),
      child: Column(
        crossAxisAlignment: widget.message.isMyMessage
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          if (widget.isLeadChat ||
              widget.isGroupChat == true ||
              !widget.message.isMyMessage)
            Text(
              widget.message.senderName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: appearance.secondaryForeground(
                  context,
                  widget.message.isMyMessage,
                ),
              ),
            ),
          if (_audioController != null && !_isLoading && !_hasError)
            VoiceMessageView(
              innerPadding: 8,
              backgroundColor: bubbleColor,
              activeSliderColor: widget.message.isMyMessage
                  ? foreground.withValues(alpha: 0.78)
                  : appearance.accentColor(context),
              circlesColor: widget.message.isMyMessage
                  ? foreground.withValues(alpha: 0.18)
                  : appearance.accentColor(context).withValues(alpha: 0.28),
              controller: _audioController!,
              counterTextStyle: TextStyle(
                color: foreground,
              ),
            )
          else
            _VoiceStatusBubble(
              color: bubbleColor,
              foreground: foreground,
              isLoading: _isLoading,
              onRetry: _prepareAudio,
            ),
          if (widget.reactions.isNotEmpty)
            Transform.translate(
              offset: const Offset(0, -4),
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.message.isMyMessage ? 0 : 6,
                  right: widget.message.isMyMessage ? 6 : 0,
                  bottom: 2,
                ),
                child: ReactionCapsule(
                  reactions: widget.reactions,
                  isSender: widget.message.isMyMessage,
                  onReactionTap: widget.onReactionTap,
                ),
              ),
            ),
          SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time(widget.message.createMessateTime),
                style: context.appTextStyles.bodySm.copyWith(
                  color: appearance.secondaryForeground(
                    context,
                    widget.message.isMyMessage,
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 3),
              if (widget.message.isMyMessage)
                Icon(
                  widget.message.isRead ? Icons.done_all : Icons.done_all,
                  size: 18,
                  color: widget.message.isRead
                      ? foreground
                      : appearance.secondaryForeground(
                          context,
                          widget.message.isMyMessage,
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class _VoiceStatusBubble extends StatelessWidget {
  final Color color;
  final Color foreground;
  final bool isLoading;
  final VoidCallback onRetry;

  const _VoiceStatusBubble({
    required this.color,
    required this.foreground,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onRetry,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(Icons.refresh_rounded, color: foreground, size: 20),
              const SizedBox(width: 8),
              Text(
                isLoading
                    ? (localizations?.translate('loading') ?? '...')
                    : (localizations?.translate('retry') ?? 'Retry'),
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
