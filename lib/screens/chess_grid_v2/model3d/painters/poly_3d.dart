import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';
import 'package:flutter/material.dart';

/// 3D Polygon with vertices, realistic architectural shading and solid backface culling.
class Poly3D {
  final List<Vector3D> vertices;
  final Color fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final double depth;
  final Vector3D normal; // World-space surface normal
  final bool isDoubleSided;

  Poly3D({
    required this.vertices,
    required this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    required this.depth,
    required this.normal,
    this.isDoubleSided = false,
  });

  /// Factory for a quad (4 vertices) with known surface normal.
  factory Poly3D.quad({
    required Vector3D v0,
    required Vector3D v1,
    required Vector3D v2,
    required Vector3D v3,
    required Color color,
    Color? strokeColor,
    double strokeWidth = 1.0,
    required Vector3D normal,
    bool isDoubleSided = false,
    required Camera3D camera,
  }) {
    final d = (camera.depthOf(v0) +
            camera.depthOf(v1) +
            camera.depthOf(v2) +
            camera.depthOf(v3)) /
        4.0;

    return Poly3D(
      vertices: [v0, v1, v2, v3],
      fillColor: color,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      depth: d,
      normal: normal,
      isDoubleSided: isDoubleSided,
    );
  }

  /// Factory for a solid opaque architectural cuboid (house, slab, or apartment block).
  /// Generates the visible faces with correct world normals. Bottom face is omitted since buildings sit on the ground.
  static List<Poly3D> createBox({
    required Vector3D center,
    required double width, // X
    required double height, // Y
    required double depth, // Z
    required Color topColor,
    required Color frontColor,
    required Color sideColor,
    Color? backColor,
    Color? strokeColor,
    double strokeWidth = 1.0,
    bool includeBottom = false,
    required Camera3D camera,
  }) {
    final hw = width / 2;
    final hh = height / 2;
    final hd = depth / 2;

    // 8 vertices in world coordinates:
    // Bottom 4:
    final b0 = Vector3D(center.x - hw, center.y - hh, center.z - hd); // back-left
    final b1 = Vector3D(center.x + hw, center.y - hh, center.z - hd); // back-right
    final b2 = Vector3D(center.x + hw, center.y - hh, center.z + hd); // front-right
    final b3 = Vector3D(center.x - hw, center.y - hh, center.z + hd); // front-left

    // Top 4:
    final t0 = Vector3D(center.x - hw, center.y + hh, center.z - hd); // back-left
    final t1 = Vector3D(center.x + hw, center.y + hh, center.z - hd); // back-right
    final t2 = Vector3D(center.x + hw, center.y + hh, center.z + hd); // front-right
    final t3 = Vector3D(center.x - hw, center.y + hh, center.z + hd); // front-left

    final polys = <Poly3D>[];

    // 1. Top face (Normal: +Y pointing straight up to sky)
    polys.add(Poly3D.quad(
      v0: t3,
      v1: t2,
      v2: t1,
      v3: t0,
      color: topColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      normal: const Vector3D(0, 1, 0),
      camera: camera,
    ));

    // 2. Front face (Normal: +Z pointing forward to camera)
    polys.add(Poly3D.quad(
      v0: b3,
      v1: b2,
      v2: t2,
      v3: t3,
      color: frontColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      normal: const Vector3D(0, 0, 1),
      camera: camera,
    ));

    // 3. Right face (Normal: +X pointing right)
    polys.add(Poly3D.quad(
      v0: b2,
      v1: b1,
      v2: t1,
      v3: t2,
      color: sideColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      normal: const Vector3D(1, 0, 0),
      camera: camera,
    ));

    // 4. Left face (Normal: -X pointing left)
    polys.add(Poly3D.quad(
      v0: b0,
      v1: b3,
      v2: t3,
      v3: t0,
      color: sideColor.withValues(alpha: 0.94),
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      normal: const Vector3D(-1, 0, 0),
      camera: camera,
    ));

    // 5. Back face (Normal: -Z pointing away)
    final rearColor = backColor ?? frontColor.withValues(alpha: 0.85);
    polys.add(Poly3D.quad(
      v0: b1,
      v1: b0,
      v2: t0,
      v3: t1,
      color: rearColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      normal: const Vector3D(0, 0, -1),
      camera: camera,
    ));

    // 6. Optional bottom face (only if floating above ground)
    if (includeBottom) {
      polys.add(Poly3D.quad(
        v0: b0,
        v1: b1,
        v2: b2,
        v3: b3,
        color: const Color(0xFF4A555C),
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        normal: const Vector3D(0, -1, 0),
        camera: camera,
      ));
    }

    return polys;
  }

  /// Determines visibility using Camera View Vector and Surface Normal (Dot Product)
  bool isVisibleToCamera(Camera3D camera) {
    if (isDoubleSided) return true;

    // View vector from camera pointing towards the scene
    final camDirX = camera.cameraDir.x;
    final camDirY = camera.cameraDir.y;
    final camDirZ = camera.cameraDir.z;

    // Dot product: normal · cameraDir
    // If dot > 0.001, surface faces towards the camera viewpoint!
    final dot = normal.x * camDirX + normal.y * camDirY + normal.z * camDirZ;
    return dot > 0.001;
  }

  /// Renders this polygon onto the Canvas
  void render(Canvas canvas, Size screenSize, Camera3D camera) {
    if (vertices.length < 3) return;

    // Check if visible to camera
    if (!isVisibleToCamera(camera)) return;

    final path = Path();
    final p0 = camera.project(vertices[0], screenSize);
    path.moveTo(p0.dx, p0.dy);

    for (int i = 1; i < vertices.length; i++) {
      final p = camera.project(vertices[i], screenSize);
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    // Solid opaque fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Subtle edge outline
    if (strokeColor != null && strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = strokeColor!
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    }
  }
}
