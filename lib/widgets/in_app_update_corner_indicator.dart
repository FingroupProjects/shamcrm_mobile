import 'package:crm_task_manager/services/in_app_update_service.dart';
import 'package:flutter/material.dart';

class InAppUpdateCornerIndicator extends StatelessWidget {
  const InAppUpdateCornerIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final service = InAppUpdateService.instance;

    return ValueListenableBuilder<InAppUpdateProgress?>(
      valueListenable: service.progressNotifier,
      builder: (context, progress, child) {
        if (progress == null) {
          return const SizedBox.shrink();
        }

        final visible = progress.stage == InAppUpdateStage.pending ||
            progress.stage == InAppUpdateStage.downloading ||
            progress.stage == InAppUpdateStage.downloaded ||
            progress.stage == InAppUpdateStage.installing;

        if (!visible) {
          return const SizedBox.shrink();
        }

        return Positioned(
          right: 12,
          bottom: 24,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(progress.canInstall ? 18 : 24),
                onTap: progress.canInstall
                    ? () {
                        service.installDownloadedUpdate();
                      }
                    : null,
                child: Ink(
                  width: progress.canInstall ? null : 52,
                  height: progress.canInstall ? null : 52,
                  padding: progress.canInstall
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                      : const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xF21976D2),
                    borderRadius:
                        BorderRadius.circular(progress.canInstall ? 18 : 24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: progress.canInstall
                      ? const Text(
                          'Установить обновление',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              value: progress.stage ==
                                          InAppUpdateStage.downloading ||
                                      progress.stage ==
                                          InAppUpdateStage.downloaded
                                  ? progress.progressPercent / 100
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
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
