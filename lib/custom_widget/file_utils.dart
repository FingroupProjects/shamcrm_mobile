import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:crm_task_manager/api/service/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<void> showFile({
    required BuildContext context,
    required String fileUrl,
    required int fileId,
    required Function setState,
    required Map<int, double> downloadProgress,
    required bool isDownloading,
    required ApiService apiService,
  }) async {
    try {
      if (isDownloading) return;

      final cachedFilePath = await FileCacheManager().getCachedFilePath(fileId);
      if (cachedFilePath != null) {
        final result = await OpenFile.open(cachedFilePath);
        if (result.type == ResultType.error) {
          _showErrorSnackBar(context, AppLocalizations.of(context)!.translate('failed_to_open_file'));
        }
        return;
      }

      setState(() {
        isDownloading = true;
        downloadProgress[fileId] = 0;
      });

      // Используем новый универсальный метод для получения полного URL файла
      final fullUrl = await apiService.getFileUrl(fileUrl);

      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cached_files');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final fileName = '${fileId}_${fileUrl.split('/').last}';
      final filePath = '${cacheDir.path}/$fileName';

      final dio = LoggedDioClient.create();
      await dio.download(fullUrl, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            downloadProgress[fileId] = received / total;
          });
        }
      });

      await FileCacheManager().cacheFile(fileId, filePath);

      setState(() {
        downloadProgress.remove(fileId);
        isDownloading = false;
      });

      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.error) {
        _showErrorSnackBar(context, AppLocalizations.of(context)!.translate('failed_to_open_file'));
      }
    } catch (e) {
      setState(() {
        downloadProgress.remove(fileId);
        isDownloading = false;
      });

      _showErrorSnackBar(context, AppLocalizations.of(context)!.translate('file_download_or_open_error'));
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
