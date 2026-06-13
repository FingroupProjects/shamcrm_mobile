// Модель для представления файла с необходимыми атрибутами
import 'dart:io';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class FileHelper {
  final int id;
  final String name;
  final String path;
  final String? size;

  FileHelper({required this.name, required this.id, this.size, required this.path});

  // Преобразует объект в карту (JSON) для передачи в BLoC
  // при вызове API — данные файла, отправляемые на бэкенд
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
    };
  }
}

/// Строит иконку файла или превью изображения
Widget buildFileIcon(List<FileHelper> files, String fileName, String fileExtension) {
  // Список расширений изображений
  final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'];

  // Если файл - изображение, показываем превью
  if (imageExtensions.contains(fileExtension)) {
    final filePath = files.firstWhere((file) => file.name == fileName).path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(filePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Если не удалось загрузить превью, показываем иконку
          return ColorFiltered(
            colorFilter:
                const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            child: Image.asset(
              'assets/icons/files/file.png',
              width: 60,
              height: 60,
            ),
          );
        },
      ),
    );
  } else {
    // Для остальных типов файлов показываем иконку по расширению
    return Builder(
      builder: (context) {
        final colors = context.appColors;
        final asset = 'assets/icons/files/$fileExtension.png';
        return ColorFiltered(
          colorFilter: ColorFilter.mode(colors.textInverse, BlendMode.srcIn),
          child: Image.asset(
            asset,
            width: 60,
            height: 60,
            errorBuilder: (context, error, stackTrace) {
              return ColorFiltered(
                colorFilter:
                    ColorFilter.mode(colors.textInverse, BlendMode.srcIn),
                child: Image.asset(
                  'assets/icons/files/file.png',
                  width: 60,
                  height: 60,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
