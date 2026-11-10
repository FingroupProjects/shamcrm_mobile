import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComplexPhotoStore {
  static const String _prefix = 'chess_complex_photos_';
  static final Map<int, List<String>> _memCache = {};

  /// Synchronous retrieval from in-memory cache if available.
  static List<String> getCachedPhotosSync(int complexId) {
    return _memCache[complexId] ?? const [];
  }

  /// Resolves any complex photo (relative server path or full URL) into a complete URL.
  static String resolveUrl(String path, {String? baseUrl}) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final rawBase = baseUrl ?? ApiService().baseUrl ?? 'https://sham-new-back.shamcrm.com';
    final cleanBase = rawBase.replaceAll('/api', '').replaceAll(RegExp(r'/+$'), '');

    final normalized = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (normalized.startsWith('storage/')) {
      return '$cleanBase/$normalized';
    }
    return '$cleanBase/storage/$normalized';
  }

  /// Retrieves cached photo paths/URLs for a given complex ID.
  static Future<List<String>> getPhotos(int complexId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('$_prefix$complexId') ?? [];
      if (list.isNotEmpty) {
        _memCache[complexId] = list;
      }
      return list;
    } catch (e) {
      debugPrint('ComplexPhotoStore.getPhotos error: $e');
      return [];
    }
  }

  /// Copies any temporary local files into the app documents directory and saves the list in SharedPreferences.
  static Future<List<String>> savePhotos(int complexId, List<String> photos) async {
    if (photos.isEmpty) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPaths = <String>[];

      Directory? docDir;
      try {
        docDir = await getApplicationDocumentsDirectory();
      } catch (e) {
        debugPrint('ComplexPhotoStore docDir error: $e');
      }

      for (int i = 0; i < photos.length; i++) {
        final p = photos[i].trim();
        if (p.isEmpty) continue;

        if (p.startsWith('http://') || p.startsWith('https://')) {
          savedPaths.add(p);
          continue;
        }

        final f = File(p);
        if (f.existsSync()) {
          // If the file is outside documents directory (e.g. cache/tmp), copy it to permanent storage
          if (docDir != null && !p.startsWith(docDir.path)) {
            try {
              final targetDir = Directory('${docDir.path}/complex_photos');
              if (!targetDir.existsSync()) {
                targetDir.createSync(recursive: true);
              }
              final ext = p.contains('.') ? p.split('.').last : 'jpg';
              final newPath = '${targetDir.path}/c_${complexId}_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
              final copied = f.copySync(newPath);
              savedPaths.add(copied.path);
              continue;
            } catch (e) {
              debugPrint('ComplexPhotoStore copy file error: $e');
            }
          }
          savedPaths.add(p);
        } else {
          savedPaths.add(p);
        }
      }

      if (savedPaths.isNotEmpty) {
        _memCache[complexId] = savedPaths;
        await prefs.setStringList('$_prefix$complexId', savedPaths);
      }
      return savedPaths;
    } catch (e) {
      debugPrint('ComplexPhotoStore.savePhotos error: $e');
      return photos;
    }
  }
}

