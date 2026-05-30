import 'dart:io';

import 'package:camera/camera.dart';

class WorkdayCaptureService {
  const WorkdayCaptureService();

  Future<File> capturePhoto() async {
    CameraController? controller;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Камера не найдена');
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final photo = await controller.takePicture();
      return File(photo.path);
    } catch (e) {
      throw Exception('Не удалось сделать фото: $e');
    } finally {
      await controller?.dispose();
    }
  }
}
