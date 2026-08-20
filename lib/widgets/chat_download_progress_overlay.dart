import 'package:crm_task_manager/services/chat_media_download_manager.dart';
import 'package:flutter/material.dart';

class ChatDownloadProgressOverlay extends StatelessWidget {
  final ChatDownloadTask task;
  final bool compact;

  const ChatDownloadProgressOverlay({
    super.key,
    required this.task,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!task.showOverlay) return const SizedBox.shrink();

    final size = compact ? 28.0 : 42.0;
    final stroke = compact ? 2.2 : 3.0;
    final iconSize = compact ? 14.0 : 20.0;

    return ColoredBox(
      color: Colors.black.withValues(alpha: compact ? 0.28 : 0.42),
      child: Center(
        child: Container(
          width: size + 16,
          height: size + 16,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: switch (task.status) {
            ChatDownloadStatus.completed => Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: iconSize + 4,
              ),
            ChatDownloadStatus.failed => Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: iconSize + 2,
              ),
            _ => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: task.progress > 0 ? task.progress / 100 : null,
                      strokeWidth: stroke,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Text(
                    '${task.progress}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}
