import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ChatDownloadKind { image, video, file }

enum ChatDownloadStatus { downloading, saving, completed, failed }

class ChatDownloadTask {
  ChatDownloadTask({
    required this.key,
    required this.sourceUrl,
    required this.fileName,
    required this.kind,
  });

  final String key;
  final String sourceUrl;
  final String fileName;
  final ChatDownloadKind kind;
  ChatDownloadStatus status = ChatDownloadStatus.downloading;
  int progress = 0;
  DateTime? completedAt;

  bool get isInProgress =>
      status == ChatDownloadStatus.downloading ||
      status == ChatDownloadStatus.saving;

  bool get showOverlay {
    if (isInProgress) return true;
    if (status == ChatDownloadStatus.failed) return true;
    if (status == ChatDownloadStatus.completed && completedAt != null) {
      return DateTime.now().difference(completedAt!) <
          const Duration(seconds: 3);
    }
    return false;
  }
}

class ChatMediaDownloadManager extends ChangeNotifier {
  ChatMediaDownloadManager._();

  static final ChatMediaDownloadManager instance = ChatMediaDownloadManager._();

  final Map<String, ChatDownloadTask> _tasks = {};
  final Map<String, String> _aliases = {};
  final Map<String, Future<void>> _running = {};

  ChatDownloadTask? taskFor(String? source) {
    if (source == null || source.isEmpty) return null;
    final key = _key(source);
    return _tasks[key] ?? _tasks[_aliases[key] ?? ''];
  }

  Future<void> start({
    required String sourceUrl,
    required String fileName,
    required ChatDownloadKind kind,
    String? alias,
  }) {
    final key = _key(sourceUrl);
    if (alias != null && alias.isNotEmpty) {
      _aliases[_key(alias)] = key;
    }

    final running = _running[key];
    if (running != null) return running;

    final task = _tasks[key] ??
        ChatDownloadTask(
          key: key,
          sourceUrl: sourceUrl,
          fileName: fileName,
          kind: kind,
        );
    task.status = ChatDownloadStatus.downloading;
    task.progress = 0;
    task.completedAt = null;
    _tasks[key] = task;
    notifyListeners();

    final future = _run(task);
    _running[key] = future;
    return future.whenComplete(() => _running.remove(key));
  }

  Future<void> _run(ChatDownloadTask task) async {
    try {
      final file = await _download(task);
      if (file == null) {
        throw Exception('download failed');
      }

      task.status = ChatDownloadStatus.saving;
      task.progress = 100;
      notifyListeners();

      final success = await _persist(task, file);
      task.status =
          success ? ChatDownloadStatus.completed : ChatDownloadStatus.failed;
      task.completedAt = DateTime.now();
      notifyListeners();
      _showResult(task, success);
      Future<void>.delayed(const Duration(seconds: 3), notifyListeners);
    } catch (error) {
      debugPrint('ChatMediaDownloadManager error: $error');
      task.status = ChatDownloadStatus.failed;
      notifyListeners();
      _showResult(task, false);
    }
  }

  Future<File?> _download(ChatDownloadTask task) async {
    void onProgress(int received, int total) {
      if (total <= 0) return;
      final percent = ((received / total) * 100).clamp(0, 100).round();
      if (percent == task.progress) return;
      task.progress = percent;
      notifyListeners();
    }

    switch (task.kind) {
      case ChatDownloadKind.image:
        return ChatMediaPersistentCache.instance.getImageFile(
          task.sourceUrl,
          onProgress: onProgress,
        );
      case ChatDownloadKind.video:
        return ChatMediaPersistentCache.instance.getVideoFile(
          task.sourceUrl,
          onProgress: onProgress,
        );
      case ChatDownloadKind.file:
        return ChatMediaPersistentCache.instance.getAnyFile(
          task.sourceUrl,
          fileName: task.fileName,
          onProgress: onProgress,
        );
    }
  }

  Future<bool> _persist(ChatDownloadTask task, File file) async {
    if (task.kind == ChatDownloadKind.file) {
      return _saveGenericFile(file, task.fileName);
    }

    final result = await ImageGallerySaverPlus.saveFile(
      file.path,
      name: _safeFileName(task.fileName),
    );
    if (result is Map && result['isSuccess'] == true) {
      return true;
    }
    return false;
  }

  Future<bool> _saveGenericFile(File file, String fileName) async {
    final safeName = _safeFileName(fileName);
    try {
      if (Platform.isAndroid) {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          final dest = File('${downloads.path}/$safeName');
          await file.copy(dest.path);
          return await dest.exists();
        }
      }
    } catch (error) {
      debugPrint('ChatMediaDownloadManager downloads copy error: $error');
    }

    try {
      final docs = await getApplicationDocumentsDirectory();
      final dest = File('${docs.path}/$safeName');
      if (dest.path != file.path) {
        await file.copy(dest.path);
      }
      await Share.shareXFiles(
        [XFile(dest.existsSync() ? dest.path : file.path, name: safeName)],
      );
      return true;
    } catch (error) {
      debugPrint('ChatMediaDownloadManager share error: $error');
      return false;
    }
  }

  void _showResult(ChatDownloadTask task, bool success) {
    final messenger = ApiService.scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final context = ApiService.navigatorKey.currentContext;
    final loc = context == null ? null : AppLocalizations.of(context);
    final message = switch (task.kind) {
      ChatDownloadKind.image => loc?.translate(
            success ? 'image_saved_success' : 'image_save_failed',
          ) ??
          (success
              ? 'Изображение сохранено. ✅'
              : 'Не удалось сохранить изображение. ❌'),
      ChatDownloadKind.video => loc?.translate(
            success ? 'video_saved_success' : 'video_save_failed',
          ) ??
          (success ? 'Видео сохранено. ✅' : 'Не удалось сохранить видео. ❌'),
      ChatDownloadKind.file => loc?.translate(
            success ? 'file_saved_success' : 'file_save_failed',
          ) ??
          (success ? 'Файл сохранён. ✅' : 'Не удалось сохранить файл. ❌'),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? AppColors.primaryBlue : Colors.red,
        ),
      );
  }

  String _key(String value) => value.replaceFirst('file://', '').trim();

  String _safeFileName(String raw) {
    final cleaned = raw
        .split('/')
        .last
        .split('?')
        .first
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return cleaned.isEmpty
        ? 'chat_file_${DateTime.now().millisecondsSinceEpoch}'
        : cleaned;
  }
}
