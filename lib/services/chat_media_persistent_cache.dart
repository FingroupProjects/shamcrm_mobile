import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crm_task_manager/api/service/http/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

bool isLikelyHtmlOrJsonError(List<int> bytes) {
  var index = 0;
  while (index < bytes.length &&
      (bytes[index] == 0x20 ||
          bytes[index] == 0x09 ||
          bytes[index] == 0x0A ||
          bytes[index] == 0x0D)) {
    index++;
  }
  if (index >= bytes.length) return true;
  final first = bytes[index];
  return first == 0x3C || first == 0x7B;
}

class ChatMediaPersistentCache {
  ChatMediaPersistentCache._();

  static final ChatMediaPersistentCache instance = ChatMediaPersistentCache._();

  static const String _imagePrefix = 'chat_media_image_';
  static const String _thumbPrefix = 'chat_media_thumb_';
  static const String _videoPrefix = 'chat_media_video_';
  static const String _filePrefix = 'chat_media_file_';

  final Map<String, Future<File?>> _inflight = {};

  String _safeKey(String value) {
    final encoded = base64Url.encode(utf8.encode(value));
    return encoded.replaceAll('=', '');
  }

  Future<Directory> _cacheDir() async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/chat_media_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<File> _fileForKey(String prefix, String key, String extension) async {
    final dir = await _cacheDir();
    return File('${dir.path}/$prefix$key$extension');
  }

  Future<String?> _readPath(String prefKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefKey);
  }

  Future<void> _writePath(String prefKey, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, path);
  }

  Future<File?> getImageFile(
    String url, {
    void Function(int received, int total)? onProgress,
  }) {
    return _getCachedOrDownload(
      url: url,
      prefix: _imagePrefix,
      fallbackExtension: '.jpg',
      onProgress: onProgress,
    );
  }

  String _fileExtension(String url, String fallback) {
    final path = Uri.tryParse(url)?.path ?? url;
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return fallback;
    final ext = name.substring(dot).toLowerCase().split('?').first;
    if (ext.length < 2 || ext.length > 8) return fallback;
    return ext;
  }

  String _videoExtension(String url) => _fileExtension(url, '.mp4');

  Future<File?> getAnyFile(
    String url, {
    String? fileName,
    void Function(int received, int total)? onProgress,
  }) {
    final fallback = fileName != null && fileName.contains('.')
        ? '.${fileName.split('.').last}'
        : '.bin';
    return _getCachedOrDownload(
      url: url,
      prefix: _filePrefix,
      fallbackExtension: fallback,
      onProgress: onProgress,
    );
  }

  Future<File?> getVideoFile(
    String url, {
    void Function(int received, int total)? onProgress,
  }) {
    return _getCachedOrDownload(
      url: url,
      prefix: _videoPrefix,
      fallbackExtension: _videoExtension(url),
      onProgress: onProgress,
    );
  }

  Future<File?> _getCachedOrDownload({
    required String url,
    required String prefix,
    required String fallbackExtension,
    void Function(int received, int total)? onProgress,
  }) {
    if (url.startsWith('/') || url.startsWith('file:')) {
      return _localFileIfExists(url);
    }

    final inflightKey = '$prefix$url';
    final existing = _inflight[inflightKey];
    if (existing != null) return existing;

    final download = _downloadAndCache(
      url: url,
      prefix: prefix,
      fallbackExtension: fallbackExtension,
      onProgress: onProgress,
    );
    _inflight[inflightKey] = download;
    return download.whenComplete(() => _inflight.remove(inflightKey));
  }

  Future<File?> _localFileIfExists(String url) async {
    final file = File(url.replaceFirst('file://', ''));
    return await file.exists() ? file : null;
  }

  Future<File?> _downloadAndCache({
    required String url,
    required String prefix,
    required String fallbackExtension,
    void Function(int received, int total)? onProgress,
  }) async {
    final key = _safeKey(url);
    final prefKey = '$prefix$key';
    final cachedPath = await _readPath(prefKey);
    if (cachedPath != null) {
      final cachedFile = File(cachedPath);
      if (await cachedFile.exists() && await cachedFile.length() > 0) {
        onProgress?.call(1, 1);
        return cachedFile;
      }
    }

    try {
      final file =
          await _fileForKey(prefix, key, _fileExtension(url, fallbackExtension));
      final downloaded = await _downloadToFile(
        url: url,
        file: file,
        onProgress: onProgress,
      );
      if (downloaded == null) return null;
      await _writePath(prefKey, downloaded.path);
      return downloaded;
    } catch (e) {
      debugPrint('ChatMediaPersistentCache download error: $e');
      return null;
    }
  }

  Future<File?> _downloadToFile({
    required String url,
    required File file,
    void Function(int received, int total)? onProgress,
  }) async {
    Future<void> attempt() {
      return LoggedDioClient.shared().download(
        url,
        file.path,
        onReceiveProgress: onProgress,
        options: Options(
          receiveTimeout: const Duration(seconds: 25),
          sendTimeout: const Duration(seconds: 25),
        ),
      );
    }

    try {
      await attempt();
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      await LoggedDioClient.reset();
      await attempt();
    }

    if (!await file.exists() || await file.length() == 0) {
      return null;
    }

    final raf = await file.open();
    try {
      final header = await raf.read(64);
      if (isLikelyHtmlOrJsonError(header)) {
        await file.delete();
        return null;
      }
    } finally {
      await raf.close();
    }

    return file;
  }

  bool _isRetryable(Object error) {
    if (error is DioException) return isTransientDioError(error);
    return error is SocketException ||
        error is HttpException ||
        error is TimeoutException;
  }

  Future<File?> getVideoThumbnailFile(String videoUrl) async {
    final key = _safeKey(videoUrl);
    final prefKey = '$_thumbPrefix$key';
    final cachedPath = await _readPath(prefKey);
    if (cachedPath != null) {
      final cachedFile = File(cachedPath);
      if (await cachedFile.exists()) {
        return cachedFile;
      }
    }

    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 60,
      );
      if (bytes == null || bytes.isEmpty) return null;

      final file = await _fileForKey(_thumbPrefix, key, '.jpg');
      await file.writeAsBytes(bytes, flush: true);
      await _writePath(prefKey, file.path);
      return file;
    } catch (e) {
      debugPrint('ChatMediaPersistentCache thumbnail error: $e');
      return null;
    }
  }

  Future<void> clearAll() async {
    _inflight.clear();
    await LoggedDioClient.reset();
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (error) {
      debugPrint('ChatMediaPersistentCache clear error: $error');
    }
  }
}
