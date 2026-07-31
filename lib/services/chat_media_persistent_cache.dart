import 'dart:convert';
import 'dart:io';

import 'package:crm_task_manager/api/service/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ChatMediaPersistentCache {
  ChatMediaPersistentCache._();

  static final ChatMediaPersistentCache instance = ChatMediaPersistentCache._();

  static const String _imagePrefix = 'chat_media_image_';
  static const String _thumbPrefix = 'chat_media_thumb_';

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

  Future<File?> getImageFile(String url) async {
    final key = _safeKey(url);
    final prefKey = '$_imagePrefix$key';
    final cachedPath = await _readPath(prefKey);
    if (cachedPath != null) {
      final cachedFile = File(cachedPath);
      if (await cachedFile.exists()) {
        return cachedFile;
      }
    }

    try {
      final response = await LoggedDioClient.create().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const <int>[]);
      if (bytes.isEmpty) return null;

      final file = await _fileForKey(_imagePrefix, key, '.jpg');
      await file.writeAsBytes(bytes, flush: true);
      await _writePath(prefKey, file.path);
      return file;
    } catch (e) {
      debugPrint('ChatMediaPersistentCache image error: $e');
      return null;
    }
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
