import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';
import 'package:flutter/material.dart';

/// Renders the architectural landscaped ground plane with isometric grid lines matching Three.js Web
class GroundGridPainter {
  static void render({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    double extent = 750.0,
    double step = 48.0,
  }) {
    // 1. Atmosphere/Horizon background
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE8F1F3), // Pale atmospheric sky
          Color(0xFFE2EBE0), // Landscaped horizon
          Color(0xFFE2EBE0),
        ],
        stops: [0.0, 0.4, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Ground polygon on Y = 0
    final groundPoly = [
      Vector3D(-extent, 0, -extent),
      Vector3D(extent, 0, -extent),
      Vector3D(extent, 0, extent),
      Vector3D(-extent, 0, extent),
    ];

    final groundPath = Path();
    final p0 = camera.project(groundPoly[0], size);
    groundPath.moveTo(p0.dx, p0.dy);
    for (int i = 1; i < groundPoly.length; i++) {
      final p = camera.project(groundPoly[i], size);
      groundPath.lineTo(p.dx, p.dy);
    }
    groundPath.close();

    final groundPaint = Paint()
      ..color = const Color(0xFFE2EBE0) // Authentic pastel green floor from Media 1-4
      ..style = PaintingStyle.fill;
    canvas.drawPath(groundPath, groundPaint);

    // 3. Grid Lines
    final linePaint = Paint()
      ..color = const Color(0xFFC8D7C6).withValues(alpha: 0.7)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // Lines along Z axis
    for (double x = -extent; x <= extent; x += step) {
      final start = camera.project(Vector3D(x, 0, -extent), size);
      final end = camera.project(Vector3D(x, 0, extent), size);
      canvas.drawLine(start, end, linePaint);
    }

    // Lines along X axis
    for (double z = -extent; z <= extent; z += step) {
      final start = camera.project(Vector3D(-extent, 0, z), size);
      final end = camera.project(Vector3D(extent, 0, z), size);
      canvas.drawLine(start, end, linePaint);
    }
  }
}
