import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Универсальный диалог для выбора типа источника файла
/// Поддерживает: Файлы, Галерея, Камера
class FilePickerDialog {
  /// Показывает диалог выбора и возвращает выбранные файлы
  /// 
  /// [context] - контекст для показа диалога
  /// [allowMultiple] - разрешить множественный выбор
  /// [maxSizeMB] - максимальный размер файлов в МБ
  /// [currentTotalSizeMB] - текущий размер уже выбранных файлов
  /// [fileLabel] - метка "Файл" (для локализации)
  /// [galleryLabel] - метка "Галерея" (для локализации)
  /// [cameraLabel] - метка "Камера" (для локализации)
  /// [cancelLabel] - метка "Отмена" (для локализации)
  /// [fileSizeTooLargeMessage] - сообщение об ошибке размера
  /// [errorPickingFileMessage] - сообщение об ошибке выбора
  /// 
  /// Возвращает List<PickedFileInfo> или null если отменено
  static Future<List<PickedFileInfo>?> show({
    required BuildContext context,
    bool allowMultiple = true,
    double maxSizeMB = 50.0,
    double currentTotalSizeMB = 0.0,
    String fileLabel = 'Файл',
    String galleryLabel = 'Галерея',
    String cameraLabel = 'Камера',
    String cancelLabel = 'Отмена',
    String? fileSizeTooLargeMessage,
    String? errorPickingFileMessage,
  }) async {
    return showModalBottomSheet<List<PickedFileInfo>>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Индикатор для перетаскивания
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Color(0xffE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Кнопка "Файл"
              _buildOption(
                context: context,
                icon: Icons.insert_drive_file_outlined,
                label: fileLabel,
                iconColor: Color(0xff4759FF),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await _pickFiles(
                    allowMultiple: allowMultiple,
                    maxSizeMB: maxSizeMB,
                    currentTotalSizeMB: currentTotalSizeMB,
                    context: context,
                    fileSizeTooLargeMessage: fileSizeTooLargeMessage,
                    errorPickingFileMessage: errorPickingFileMessage,
                  );
                  if (result != null) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              
              Divider(height: 1, color: Color(0xffF0F0F0)),
              
              // Кнопка "Галерея"
              _buildOption(
                context: context,
                icon: Icons.photo_library_outlined,
                label: galleryLabel,
                iconColor: Color(0xff10B981),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await _pickFromGallery(
                    allowMultiple: allowMultiple,
                    maxSizeMB: maxSizeMB,
                    currentTotalSizeMB: currentTotalSizeMB,
                    context: context,
                    fileSizeTooLargeMessage: fileSizeTooLargeMessage,
                    errorPickingFileMessage: errorPickingFileMessage,
                  );
                  if (result != null) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              
              Divider(height: 1, color: Color(0xffF0F0F0)),
              
              // Кнопка "Камера"
              _buildOption(
                context: context,
                icon: Icons.camera_alt_outlined,
                label: cameraLabel,
                iconColor: Color(0xffF59E0B),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await _pickFromCamera(
                    maxSizeMB: maxSizeMB,
                    currentTotalSizeMB: currentTotalSizeMB,
                    context: context,
                    fileSizeTooLargeMessage: fileSizeTooLargeMessage,
                    errorPickingFileMessage: errorPickingFileMessage,
                  );
                  if (result != null) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              
              SizedBox(height: 8),
              
              // Кнопка "Отмена"
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Color(0xffF4F7FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Вспомогательный метод для создания опции
  static Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xffBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  /// Выбор файлов через FilePicker
  static Future<List<PickedFileInfo>?> _pickFiles({
    required bool allowMultiple,
    required double maxSizeMB,
    required double currentTotalSizeMB,
    required BuildContext context,
    String? fileSizeTooLargeMessage,
    String? errorPickingFileMessage,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
      );

      if (result != null) {
        double newFilesSize = result.files.fold<double>(
          0.0,
          (sum, file) => sum + file.size / (1024 * 1024),
        );

        if (currentTotalSizeMB + newFilesSize > maxSizeMB) {
          _showError(
            context,
            fileSizeTooLargeMessage ?? 'Размер файлов превышает $maxSizeMB МБ',
          );
          return null;
        }

        return result.files.map((file) {
          return PickedFileInfo(
            path: file.path!,
            name: file.name,
            size: file.size,
          );
        }).toList();
      }
    } catch (e) {
      _showError(
        context,
        errorPickingFileMessage ?? 'Ошибка при выборе файла!',
      );
    }
    return null;
  }

  /// Выбор из галереи через ImagePicker
  static Future<List<PickedFileInfo>?> _pickFromGallery({
    required bool allowMultiple,
    required double maxSizeMB,
    required double currentTotalSizeMB,
    required BuildContext context,
    String? fileSizeTooLargeMessage,
    String? errorPickingFileMessage,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      List<XFile> images;

      if (allowMultiple) {
        images = await picker.pickMultiImage();
      } else {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        images = image != null ? [image] : [];
      }

      if (images.isNotEmpty) {
        List<PickedFileInfo> pickedFiles = [];
        double newFilesSize = 0;

        for (var image in images) {
          final file = File(image.path);
          final fileSize = file.lengthSync();
          newFilesSize += fileSize / (1024 * 1024);

          if (currentTotalSizeMB + newFilesSize > maxSizeMB) {
            _showError(
              context,
              fileSizeTooLargeMessage ?? 'Размер файлов превышает $maxSizeMB МБ',
            );
            return null;
          }

          pickedFiles.add(PickedFileInfo(
            path: image.path,
            name: image.name,
            size: fileSize,
          ));
        }

        return pickedFiles;
      }
    } catch (e) {
      _showError(
        context,
        errorPickingFileMessage ?? 'Ошибка при выборе из галереи!',
      );
    }
    return null;
  }

  /// Съемка фото через камеру
  static Future<List<PickedFileInfo>?> _pickFromCamera({
    required double maxSizeMB,
    required double currentTotalSizeMB,
    required BuildContext context,
    String? fileSizeTooLargeMessage,
    String? errorPickingFileMessage,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        final file = File(photo.path);
        final fileSize = file.lengthSync();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (currentTotalSizeMB + fileSizeMB > maxSizeMB) {
          _showError(
            context,
            fileSizeTooLargeMessage ?? 'Размер файла превышает $maxSizeMB МБ',
          );
          return null;
        }

        return [
          PickedFileInfo(
            path: photo.path,
            name: photo.name,
            size: fileSize,
          )
        ];
      }
    } catch (e) {
      _showError(
        context,
        errorPickingFileMessage ?? 'Ошибка при съемке фото!',
      );
    }
    return null;
  }

  /// Показать ошибку
  static void _showError(BuildContext context, String message) {
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
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.red,
        elevation: 3,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

/// Модель для информации о выбранном файле
class PickedFileInfo {
  final String path;
  final String name;
  final int size;

  PickedFileInfo({
    required this.path,
    required this.name,
    required this.size,
  });

  String get sizeKB => '${(size / 1024).toStringAsFixed(3)}KB';
}