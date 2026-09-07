import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/services/chat_voice_player_service.dart';
import 'package:flutter/material.dart';

class ChatVoiceMiniPlayer extends StatelessWidget {
  final VoidCallback? onOpenChat;

  const ChatVoiceMiniPlayer({
    super.key,
    this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChatVoicePlayerService.instance,
      builder: (context, _) {
        final player = ChatVoicePlayerService.instance;
        final track = player.track;
        if (track == null || !player.shouldShowMiniPlayer) {
          return const SizedBox.shrink();
        }

        final colors = context.appColors;
        return Material(
          color: colors.surfaceElevated.withValues(alpha: 0.94),
          child: InkWell(
            onTap: onOpenChat,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: player.progress,
                  minHeight: 2,
                  backgroundColor: colors.borderSubtle,
                  color: colors.buttonPrimaryBg,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
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
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.senderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.appTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.sentAtLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.appTextStyles.bodySm.copyWith(
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          formatVoiceSpeedLabel(player.speed),
                          style: TextStyle(
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
              ],
            ),
          ),
        );
      },
    );
  }
}
