import 'dart:async';
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_media_preview_sheet.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ChatFileSendContext {
  ChatFileSendContext({
    required this.chatId,
    required this.apiService,
    required this.isInstagramCommentChannel,
    required this.instagramResponseType,
    required this.myDisplayName,
    required this.onAddLocalMessage,
    required this.onUpdateLocalMessageProgress,
    required this.onFinalizeLocalMessages,
    required this.onPersistState,
    required this.onSentSound,
  });

  final int chatId;
  final ApiService apiService;
  final bool isInstagramCommentChannel;
  final String? instagramResponseType;
  final String myDisplayName;
  final void Function(Message message) onAddLocalMessage;
  final void Function(int localMessageId, List<MessageMediaItem> updatedItems)
      onUpdateLocalMessageProgress;
  final void Function(List<int> localMessageIds) onFinalizeLocalMessages;
  final Future<void> Function() onPersistState;
  final Future<void> Function() onSentSound;
}

class ChatFileSendService {
  Future<void> sendPickedFiles(
    List<PickedChatMedia> items, {
    required ChatMediaQuality quality,
    required ChatFileSendContext context,
  }) async {
    final preparedPaths = <String>[];
    final localMessageIds = <int>[];
    final localMediaItems = <MessageMediaItem>[];
    final fileSizes = <int>[];
    final chunkedMessageIds = <int, List<int>>{};

    for (final item in items) {
      final preparedPath = await _prepareFileForSending(item, quality);
      preparedPaths.add(preparedPath);
      fileSizes.add(await File(preparedPath).length());
      localMediaItems.add(
        MessageMediaItem(
          path: preparedPath,
          name: item.name,
          isImage: item.isImage,
          isVideo: item.isVideo,
        ),
      );
    }

    final now = DateTime.now();
    for (int start = 0; start < localMediaItems.length; start += 10) {
      final chunk = localMediaItems.skip(start).take(10).toList();
      final localMessageId = -(now.microsecondsSinceEpoch + start);
      localMessageIds.add(localMessageId);
      chunkedMessageIds[localMessageId] =
          List<int>.generate(chunk.length, (index) => start + index);

      final localMessage = Message(
        id: localMessageId,
        text: '${chunk.length} media',
        type: 'media_group',
        createMessateTime: now.toUtc().toIso8601String(),
        isMyMessage: true,
        senderName: context.myDisplayName,
        isUploading: true,
        mediaGroupId: 'local-${now.millisecondsSinceEpoch}-${start ~/ 10}',
        mediaItems: chunk,
      );

      context.onAddLocalMessage(localMessage);
    }

    await context.onSentSound();

    try {
      await context.apiService.sendChatFiles(
        context.chatId,
        preparedPaths,
        responseType: context.isInstagramCommentChannel
            ? context.instagramResponseType
            : null,
        onSendProgress: (sent, total) {
          if (total <= 0) return;

          final totalFileBytes =
              fileSizes.fold<int>(0, (sum, size) => sum + size);
          if (totalFileBytes <= 0) return;

          final payloadSent = (sent.clamp(0, total) / total) * totalFileBytes;
          double consumed = 0;
          final perFileProgress = <double>[];

          for (final size in fileSizes) {
            final fileStart = consumed;
            final fileEnd = consumed + size;
            double progress;
            if (payloadSent <= fileStart) {
              progress = 0;
            } else if (payloadSent >= fileEnd) {
              progress = 1;
            } else {
              progress = (payloadSent - fileStart) / size;
            }
            perFileProgress.add(progress.clamp(0, 1));
            consumed = fileEnd;
          }

          for (final entry in chunkedMessageIds.entries) {
            final localMessageId = entry.key;
            final indices = entry.value;
            final updatedItems = <MessageMediaItem>[];
            for (int i = 0; i < indices.length; i++) {
              final globalIndex = indices[i];
              updatedItems.add(
                localMediaItems[globalIndex].copyWith(
                  uploadProgress: perFileProgress[globalIndex],
                ),
              );
            }
            context.onUpdateLocalMessageProgress(localMessageId, updatedItems);
          }

          unawaited(context.onPersistState());
        },
      );

      context.onFinalizeLocalMessages(localMessageIds);
      await context.onPersistState();
    } catch (e) {
      context.onFinalizeLocalMessages(localMessageIds);
      await context.onPersistState();
      rethrow;
    }
  }

  Future<String> _prepareFileForSending(
    PickedChatMedia item,
    ChatMediaQuality quality,
  ) async {
    final originalPath = item.path;
    if (originalPath == null || originalPath.isEmpty) {
      throw StateError('Media path is missing for ${item.name}');
    }

    if (quality == ChatMediaQuality.hd || !item.isImage) {
      return originalPath;
    }

    final targetDir = await getTemporaryDirectory();
    final targetPath =
        '${targetDir.path}/chat_${DateTime.now().microsecondsSinceEpoch}_${item.name}';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      originalPath,
      targetPath,
      quality: 72,
      minWidth: 1600,
      minHeight: 1600,
      keepExif: true,
    );

    return compressedFile?.path ?? originalPath;
  }
}
