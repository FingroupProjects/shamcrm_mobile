// Модель для представления файла с необходимыми атрибутами
import 'dart:io';

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
          return Image.asset(
            'assets/icons/files/file.png',
            width: 60,
            height: 60,
          );
        },
      ),
    );
  } else {
    // Для остальных типов файлов показываем иконку по расширению
    return Image.asset(
      'assets/icons/files/$fileExtension.png',
      width: 60,
      height: 60,
      errorBuilder: (context, error, stackTrace) {
        // Если нет иконки для этого типа, показываем общую иконку файла
        return Image.asset(
          'assets/icons/files/file.png',
          width: 60,
          height: 60,
        );
      },
    );
  }
}
