import 'dart:io';
import 'dart:math' as math;

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:crm_task_manager/services/chat_voice_player_service.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/models/chat/message_reaction_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_file_utils.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/compact_reaction_chip.dart';

class VoiceMessageWidget extends StatefulWidget {
  final Message message;
  final String baseUrl;
  final int chatId;
  final ChatItem chatItem;
  final String endPointInTab;
  final bool canSendMessage;
  final String? chatUniqueId;
  final String? channelName;
  final bool isLeadChat;
  final bool? isGroupChat;
  final List<MessageReaction> reactions;
  final Function(String)? onReactionTap;

  const VoiceMessageWidget({
    super.key,
    required this.message,
    required this.baseUrl,
    required this.chatId,
    required this.chatItem,
    required this.endPointInTab,
    this.canSendMessage = true,
    this.chatUniqueId,
    this.channelName,
    this.isLeadChat = false,
    this.isGroupChat,
    this.reactions = const [],
    this.onReactionTap,
  });

  @override
  VoiceMessageWidgetState createState() => VoiceMessageWidgetState();
}

class VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final ChatVoicePlayerService _player = ChatVoicePlayerService.instance;
  String? _localPath;
  bool _isLoading = false;
  bool _hasError = false;
  int _loadGeneration = 0;

  String get _filePath => widget.message.filePath ?? '';

  bool get _isCurrent => _player.isCurrent(
        chatId: widget.chatId,
        messageId: widget.message.id,
        filePath: _filePath,
      );

  @override
  void initState() {
    super.initState();
    _player.addListener(_onPlayerChanged);
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerChanged);
    super.dispose();
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  String _getAudioSource() {
    final url = resolveFileUrl(_filePath, widget.baseUrl.replaceAll('/api', ''));
    return url.isNotEmpty ? url : _filePath;
  }

  Future<String?> _resolveLocalPath(String source) async {
    if (source.startsWith('/') || source.startsWith('file:')) {
      final file = File(source.replaceFirst('file://', ''));
      return await file.exists() ? file.path : null;
    }

    final file = await ChatMediaPersistentCache.instance.getAnyFile(source);
    return file?.path;
  }

  Future<void> _togglePlayback() async {
    if (_isCurrent && _player.isPlaying) {
      await _player.pause();
      return;
    }
    if (_isCurrent) {
      await _player.resume();
      return;
    }

    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final source = _getAudioSource();
      final localPath = _localPath ?? await _resolveLocalPath(source);
      if (!mounted || generation != _loadGeneration) return;

      if (localPath == null || localPath.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      _localPath = localPath;
      setState(() {
        _isLoading = false;
        _hasError = false;
      });

      await _player.play(
        ChatVoiceTrack(
          messageId: widget.message.id,
          chatId: widget.chatId,
          filePath: _filePath,
          localPath: localPath,
          senderName: widget.message.senderName,
          sentAtLabel: formatChatVoiceSentAt(widget.message.createMessateTime),
          duration: widget.message.duration,
          chatItem: widget.chatItem,
          endPointInTab: widget.endPointInTab,
          canSendMessage: widget.canSendMessage,
          chatUniqueId: widget.chatUniqueId,
          channelName: widget.channelName,
        ),
      );
    } catch (error) {
      debugPrint('VoiceMessageWidget play error: $error');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ChatAppearanceScope.of(context);
    final bubbleColor = widget.message.isMyMessage
        ? appearance.senderBubbleColor(context)
        : appearance.receiverBubbleColor(context);
    final foreground = widget.message.isMyMessage
        ? appearance.outgoingForeground(context)
        : appearance.incomingForeground(context);
    final progress = _isCurrent ? _player.progress : 0.0;
    final displayDuration = _isCurrent && _player.isPlaying
        ? _player.duration - _player.position
        : (_isCurrent ? _player.duration : widget.message.duration);

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
          const SizedBox(height: 4),
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
          Material(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: _isLoading ? null : _togglePlayback,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _VoicePlayButton(
                      isLoading: _isLoading,
                      isPlaying: _isCurrent && _player.isPlaying,
                      hasError: _hasError,
                      color: foreground,
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 118,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _VoiceWaveform(
                            progress: progress,
                            color: foreground,
                            seed: widget.message.id,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _hasError
                                ? (AppLocalizations.of(context)
                                        ?.translate('retry') ??
                                    'Retry')
                                : formatVoiceClock(
                                    displayDuration > Duration.zero
                                        ? displayDuration
                                        : widget.message.duration,
                                  ),
                            style: TextStyle(
                              color: foreground.withValues(alpha: 0.86),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isCurrent) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _player.cycleSpeed,
                        child: Text(
                          formatVoiceSpeedLabel(_player.speed),
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
          const SizedBox(height: 2),
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
                  Icons.done_all,
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
}

class _VoicePlayButton extends StatelessWidget {
  final bool isLoading;
  final bool isPlaying;
  final bool hasError;
  final Color color;

  const _VoicePlayButton({
    required this.isLoading,
    required this.isPlaying,
    required this.hasError,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(
                hasError
                    ? Icons.refresh_rounded
                    : (isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                color: color,
                size: 22,
              ),
      ),
    );
  }
}

class _VoiceWaveform extends StatelessWidget {
  final double progress;
  final Color color;
  final int seed;

  const _VoiceWaveform({
    required this.progress,
    required this.color,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    final random = math.Random(seed);
    return SizedBox(
      height: 22,
      child: Row(
        children: List.generate(18, (index) {
          final height = 6 + random.nextDouble() * 16;
          final reached = progress >= (index + 1) / 18;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: height,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: reached ? 0.95 : 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
