import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Cover-fit size of a rotated image inside a square crop window.
Size profilePhotoCoverSize({
  required int imageWidth,
  required int imageHeight,
  required int quarterTurns,
  required double viewport,
}) {
  final rotatedW =
      quarterTurns.isOdd ? imageHeight.toDouble() : imageWidth.toDouble();
  final rotatedH =
      quarterTurns.isOdd ? imageWidth.toDouble() : imageHeight.toDouble();
  final scale = math.max(viewport / rotatedW, viewport / rotatedH);
  return Size(rotatedW * scale, rotatedH * scale);
}

/// Draws the source photo rotated and flipped into [fittedSize].
void paintProfilePhoto({
  required Canvas canvas,
  required ui.Image image,
  required Size fittedSize,
  required int quarterTurns,
  required bool flipHorizontal,
}) {
  final rotatedW =
      quarterTurns.isOdd ? image.height.toDouble() : image.width.toDouble();
  final scale = fittedSize.width / rotatedW;

  canvas.save();
  canvas.translate(fittedSize.width / 2, fittedSize.height / 2);
  if (flipHorizontal) {
    canvas.scale(-1, 1);
  }
  canvas.rotate(quarterTurns * math.pi / 2);
  canvas.scale(scale);
  canvas.translate(-image.width / 2, -image.height / 2);
  canvas.drawImage(
    image,
    Offset.zero,
    Paint()..filterQuality = FilterQuality.high,
  );
  canvas.restore();
}

/// Same transform as the editor: image is centered, then panned and scaled.
void paintProfilePhotoInViewport({
  required Canvas canvas,
  required ui.Image image,
  required Size fittedSize,
  required double viewport,
  required double scale,
  required Offset pan,
  required int quarterTurns,
  required bool flipHorizontal,
}) {
  canvas.save();
  canvas.translate(viewport / 2 + pan.dx, viewport / 2 + pan.dy);
  canvas.scale(scale);
  canvas.translate(-fittedSize.width / 2, -fittedSize.height / 2);
  paintProfilePhoto(
    canvas: canvas,
    image: image,
    fittedSize: fittedSize,
    quarterTurns: quarterTurns,
    flipHorizontal: flipHorizontal,
  );
  canvas.restore();
}

/// Exports the circle as a square JPEG. Only the area inside the viewport.
Future<File> exportProfilePhotoCrop({
  required ui.Image image,
  required Size fittedSize,
  required double viewport,
  required double scale,
  required Offset pan,
  required int quarterTurns,
  required bool flipHorizontal,
  required int outputSize,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, outputSize.toDouble(), outputSize.toDouble()),
  );
  canvas.clipRect(
    Rect.fromLTWH(0, 0, outputSize.toDouble(), outputSize.toDouble()),
  );
  canvas.scale(outputSize / viewport);
  paintProfilePhotoInViewport(
    canvas: canvas,
    image: image,
    fittedSize: fittedSize,
    viewport: viewport,
    scale: scale,
    pan: pan,
    quarterTurns: quarterTurns,
    flipHorizontal: flipHorizontal,
  );

  final picture = recorder.endRecording();
  final cropped = await picture.toImage(outputSize, outputSize);
  final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
  cropped.dispose();
  if (bytes == null) {
    throw Exception('profile_photo_crop_failed');
  }

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/profile_avatar_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  return file;
}

class ProfilePhotoCircleOverlay extends CustomPainter {
  final double diameter;
  final bool showGrid;

  ProfilePhotoCircleOverlay({
    required this.diameter,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = diameter / 2;
    final circle = Rect.fromCircle(center: center, radius: radius);

    final dimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(circle);
    canvas.drawPath(
      dimPath,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.42),
    );

    if (!showGrid) return;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Colors.white.withValues(alpha: 0.28);
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    for (var i = 1; i < 3; i++) {
      final t = i / 3;
      canvas.drawLine(
        Offset(circle.left + circle.width * t, circle.top),
        Offset(circle.left + circle.width * t, circle.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(circle.left, circle.top + circle.height * t),
        Offset(circle.right, circle.top + circle.height * t),
        grid,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ProfilePhotoCircleOverlay oldDelegate) {
    return oldDelegate.diameter != diameter || oldDelegate.showGrid != showGrid;
  }
}
