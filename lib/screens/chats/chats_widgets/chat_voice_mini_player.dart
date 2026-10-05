import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/chat_voice_player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Плавающая капсула под шапкой.
/// Прямоугольник на всю ширину здесь больше не используем.
class ChatVoiceMiniPlayer extends StatefulWidget {
  final VoidCallback? onOpenChat;

  const ChatVoiceMiniPlayer({
    super.key,
    this.onOpenChat,
  });

  @override
  State<ChatVoiceMiniPlayer> createState() => _ChatVoiceMiniPlayerState();
}

class _ChatVoiceMiniPlayerState extends State<ChatVoiceMiniPlayer> {
  double _dragX = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragX += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldClose = _dragX.abs() > 72 || velocity.abs() > 700;
    if (shouldClose) {
      HapticFeedback.lightImpact();
      ChatVoicePlayerService.instance.stop();
      return;
    }
    setState(() => _dragX = 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChatVoicePlayerService.instance,
      builder: (context, _) {
        final player = ChatVoicePlayerService.instance;
        final track = player.track;
        if (track == null || !player.shouldShowMiniPlayer) {
          _dragX = 0;
          return const SizedBox.shrink();
        }

        final colors = context.appColors;
        final loc = AppLocalizations.of(context);

        return Transform.translate(
          offset: Offset(_dragX, 0),
          child: Opacity(
            opacity: (1 - (_dragX.abs() / 220)).clamp(0.45, 1.0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceElevated.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colors.borderSubtle.withValues(alpha: 0.9),
                  ),
                  boxShadow: context.appShadows.floating,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _VoiceSeekBar(
                        progress: player.progress,
                        label: loc?.translate('voice_player_seek') ?? 'Seek',
                        onSeek: player.seekToFraction,
                      ),
                      GestureDetector(
                        onHorizontalDragUpdate: _onDragUpdate,
                        onHorizontalDragEnd: _onDragEnd,
                        child: InkWell(
                          onTap: widget.onOpenChat,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 2, 4, 6),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: player.toggle,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    player.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: colors.buttonPrimaryBg,
                                    size: 28,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.senderName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.appTextStyles.bodyMd
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${track.sentAtLabel} · ${formatVoiceClock(player.position)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.appTextStyles.bodySm
                                            .copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: player.cycleSpeed,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(40, 32),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    formatVoiceSpeedLabel(player.speed),
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w700,
                                      color: colors.buttonPrimaryBg,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: player.stop,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VoiceSeekBar extends StatefulWidget {
  final double progress;
  final String label;
  final ValueChanged<double> onSeek;

  const _VoiceSeekBar({
    required this.progress,
    required this.label,
    required this.onSeek,
  });

  @override
  State<_VoiceSeekBar> createState() => _VoiceSeekBarState();
}

class _VoiceSeekBarState extends State<_VoiceSeekBar> {
  // Пока палец на линии, рисуем место нажатия, а не старую позицию плеера.
  double? _fingerFraction;

  double? _fractionAt(double dx) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    if (width <= 0) return null;
    return (dx / width).clamp(0.0, 1.0);
  }

  void _commit(double? fraction) {
    if (fraction == null) return;
    widget.onSeek(fraction);
  }

  @override
  void didUpdateWidget(_VoiceSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final finger = _fingerFraction;
    if (finger == null) return;
    if ((widget.progress - finger).abs() < 0.04) {
      _fingerFraction = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safe = (_fingerFraction ?? widget.progress).clamp(0.0, 1.0);

    return Semantics(
      label: widget.label,
      slider: true,
      value: '${(safe * 100).round()}%',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final fraction = _fractionAt(details.localPosition.dx);
          if (fraction == null) return;
          setState(() => _fingerFraction = fraction);
          _commit(fraction);
        },
        onHorizontalDragUpdate: (details) {
          final fraction = _fractionAt(details.localPosition.dx);
          if (fraction == null) return;
          setState(() => _fingerFraction = fraction);
        },
        onHorizontalDragEnd: (_) => _commit(_fingerFraction),
        onHorizontalDragCancel: () => _commit(_fingerFraction),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: SizedBox(
            height: 10,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                if (safe > 0)
                  FractionallySizedBox(
                    widthFactor: safe,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
