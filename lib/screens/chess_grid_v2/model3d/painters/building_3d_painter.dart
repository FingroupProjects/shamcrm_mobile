import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/poly_3d.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';
import 'package:flutter/material.dart';

class EntranceRenderInfo {
  final int entranceNumber;
  final Offset badgePosition;
  final Rect hitBounds;
  final int totalApts;
  final int freeApts;

  const EntranceRenderInfo({
    required this.entranceNumber,
    required this.badgePosition,
    required this.hitBounds,
    required this.totalApts,
    required this.freeApts,
  });
}

/// Renders Level 2: Selected Building with Entrances/Sections breakdown (Media 2)
class Building3DPainter {
  static List<EntranceRenderInfo> render({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required Building building,
    required List<Apartment> allApartments,
    required int selectedEntrance,
  }) {
    final result = <EntranceRenderInfo>[];
    final allPolys = <Poly3D>[];

    final entrances = building.entranceCount.clamp(1, 4);
    final floors = building.floorCount.clamp(6, 18);

    const double sectionWidth = 84.0;
    const double bDepth = 74.0;
    const double floorHeight = 12.5;
    final double totalHeight = floors * floorHeight;
    const double plinthHeight = 14.0;
    const double parapetHeight = 3.5;

    // Palette matching Three.js Web (Media 2)
    const cPlinthFront = Color(0xFF5A6972);
    const cPlinthSide = Color(0xFF48555C);
    const cFacadeFront = Color(0xFFECEFEF);
    const cFacadeSide = Color(0xFFBAC6C4);
    const cRoofLawn = Color(0xFF1EA355);
    const cRoofFront = Color(0xFF188243);
    const cRoofSide = Color(0xFF146A36);
    const cParapet = Color(0xFFDFE6E4);

    final buildingApts = allApartments.where((a) => a.buildingKey == building.key).toList();

    // 1. Construct solid geometry for each entrance/section
    for (int e = 1; e <= entrances; e++) {
      final double posX = (e - (entrances + 1) / 2.0) * (sectionWidth + 1.5);
      const double posZ = 0.0;
      final isSelected = selectedEntrance == e;

      // Stats for this entrance
      final entApts = buildingApts.where((a) => a.entrance == e).toList();
      final totalCount = entApts.isNotEmpty
          ? entApts.length
          : (floors * building.apartsPerFloor);
      final freeCount = entApts.isNotEmpty
          ? entApts.where((a) => a.status == ApartmentStatus.available).length
          : (totalCount * 0.5).round();

      // Basement (Цоколь)
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, plinthHeight / 2, posZ),
        width: sectionWidth + 1.0,
        height: plinthHeight,
        depth: bDepth + 1.0,
        topColor: const Color(0xFF6A7982),
        frontColor: cPlinthFront,
        sideColor: cPlinthSide,
        strokeColor: const Color(0xFF3B464C),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // Main Facade Section (Стены секции)
      final facadeHeight = totalHeight - plinthHeight;
      final facadeCenterY = plinthHeight + (facadeHeight / 2);

      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, facadeCenterY, posZ),
        width: sectionWidth,
        height: facadeHeight,
        depth: bDepth,
        topColor: cFacadeFront,
        frontColor: isSelected ? const Color(0xFFFAFCFB) : cFacadeFront,
        sideColor: isSelected ? const Color(0xFFC7D3D1) : cFacadeSide,
        strokeColor: const Color(0xFF9EAFA9),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // Rooftop Green Lawn with Parapet
      final roofCenterY = totalHeight + (parapetHeight / 2);
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, roofCenterY, posZ),
        width: sectionWidth + 2.5,
        height: parapetHeight,
        depth: bDepth + 2.5,
        topColor: cRoofLawn,
        frontColor: cRoofFront,
        sideColor: cRoofSide,
        strokeColor: cParapet,
        strokeWidth: 0.8,
        camera: camera,
      ));

      // Badge Position (Floating above roof)
      final badgePoint = Vector3D(posX, totalHeight + 16.0, posZ);
      final badgeScreenPos = camera.project(badgePoint, size);

      // Hit area for tapping
      final bottomScreenPos = camera.project(Vector3D(posX, 0, posZ), size);
      final hitRect = Rect.fromCenter(
        center: Offset(badgeScreenPos.dx, (badgeScreenPos.dy + bottomScreenPos.dy) / 2),
        width: sectionWidth * camera.zoom,
        height: (bottomScreenPos.dy - badgeScreenPos.dy).abs().clamp(100.0, 320.0),
      );

      result.add(EntranceRenderInfo(
        entranceNumber: e,
        badgePosition: badgeScreenPos,
        hitBounds: hitRect,
        totalApts: totalCount,
        freeApts: freeCount,
      ));
    }

    // Sort polygons by camera depth
    allPolys.sort((a, b) => b.depth.compareTo(a.depth));

    // Render solid opaque building
    for (final poly in allPolys) {
      poly.render(canvas, size, camera);
    }

    // 2. Render Windows and Floor separator lines on visible front facade
    _renderSectionWindows(
      canvas: canvas,
      size: size,
      camera: camera,
      entrances: entrances,
      sectionWidth: sectionWidth,
      bDepth: bDepth,
      floors: floors,
      floorHeight: floorHeight,
      plinthHeight: plinthHeight,
    );

    // 3. Render Neon 3D Wireframe Highlight around selected Entrance (Media 2)
    _renderSelectedEntranceNeonHighlight(
      canvas: canvas,
      size: size,
      camera: camera,
      selectedEntrance: selectedEntrance,
      entrances: entrances,
      sectionWidth: sectionWidth,
      bDepth: bDepth,
      totalHeight: totalHeight,
    );

    return result;
  }

  static void _renderSectionWindows({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required int entrances,
    required double sectionWidth,
    required double bDepth,
    required int floors,
    required double floorHeight,
    required double plinthHeight,
  }) {
    final glassPaint = Paint()
      ..color = const Color(0xFF384E5F)
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = const Color(0xFFF7FAF9).withValues(alpha: 0.85)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final floorLinePaint = Paint()
      ..color = const Color(0xFFBAC6C4).withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final isFrontVisible = camera.cameraDir.z > 0.02;
    final isRightSideVisible = camera.cameraDir.x > 0.02;

    for (int e = 1; e <= entrances; e++) {
      final double posX = (e - (entrances + 1) / 2.0) * (sectionWidth + 1.5);
      const double posZ = 0.0;

      if (isFrontVisible) {
        const cols = 4;
        const winW = 9.2;
        const winH = 6.4;
        final colSpacing = sectionWidth / (cols + 1);

        for (int f = 1; f < floors; f++) {
          final floorY = plinthHeight + (f * floorHeight) - 2.5;

          // Floor joint line
          final flStart = camera.project(Vector3D(posX - sectionWidth / 2 + 1, floorY - 1.5, posZ + bDepth / 2 + 0.2), size);
          final flEnd = camera.project(Vector3D(posX + sectionWidth / 2 - 1, floorY - 1.5, posZ + bDepth / 2 + 0.2), size);
          canvas.drawLine(flStart, flEnd, floorLinePaint);

          // Windows in row
          for (int c = 1; c <= cols; c++) {
            final winX = posX - (sectionWidth / 2) + (c * colSpacing);
            final winZ = posZ + (bDepth / 2) + 0.4;

            final p0 = camera.project(Vector3D(winX - winW / 2, floorY, winZ), size);
            final p1 = camera.project(Vector3D(winX + winW / 2, floorY, winZ), size);
            final p2 = camera.project(Vector3D(winX + winW / 2, floorY + winH, winZ), size);
            final p3 = camera.project(Vector3D(winX - winW / 2, floorY + winH, winZ), size);

            final path = Path()
              ..moveTo(p0.dx, p0.dy)
              ..lineTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy)
              ..lineTo(p3.dx, p3.dy)
              ..close();

            canvas.drawPath(path, glassPaint);
            canvas.drawPath(path, framePaint);
          }
        }

        // Entrance Portal Door at bottom
        const doorW = 14.0;
        const doorH = 9.0;
        final d0 = camera.project(Vector3D(posX - doorW / 2, 0.5, posZ + bDepth / 2 + 0.5), size);
        final d1 = camera.project(Vector3D(posX + doorW / 2, 0.5, posZ + bDepth / 2 + 0.5), size);
        final d2 = camera.project(Vector3D(posX + doorW / 2, doorH, posZ + bDepth / 2 + 0.5), size);
        final d3 = camera.project(Vector3D(posX - doorW / 2, doorH, posZ + bDepth / 2 + 0.5), size);
        final doorPath = Path()
          ..moveTo(d0.dx, d0.dy)
          ..lineTo(d1.dx, d1.dy)
          ..lineTo(d2.dx, d2.dy)
          ..lineTo(d3.dx, d3.dy)
          ..close();
        canvas.drawPath(doorPath, Paint()..color = const Color(0xFF23323D)..style = PaintingStyle.fill);
        canvas.drawPath(doorPath, Paint()..color = const Color(0xFFE2EBE8)..strokeWidth = 1.0..style = PaintingStyle.stroke);
      }

      // Windows on rightmost section's side face
      if (e == entrances && isRightSideVisible) {
        const sideCols = 3;
        const winW = 9.2;
        const winH = 6.4;
        final sideSpacing = bDepth / (sideCols + 1);

        for (int f = 1; f < floors; f++) {
          final floorY = plinthHeight + (f * floorHeight) - 2.5;

          for (int c = 1; c <= sideCols; c++) {
            final winZ = posZ - (bDepth / 2) + (c * sideSpacing);
            final winX = posX + (sectionWidth / 2) + 0.4;

            final p0 = camera.project(Vector3D(winX, floorY, winZ - winW / 2), size);
            final p1 = camera.project(Vector3D(winX, floorY, winZ + winW / 2), size);
            final p2 = camera.project(Vector3D(winX, floorY + winH, winZ + winW / 2), size);
            final p3 = camera.project(Vector3D(winX, floorY + winH, winZ - winW / 2), size);

            final path = Path()
              ..moveTo(p0.dx, p0.dy)
              ..lineTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy)
              ..lineTo(p3.dx, p3.dy)
              ..close();

            canvas.drawPath(path, glassPaint);
            canvas.drawPath(path, framePaint);
          }
        }
      }
    }
  }

  static void _renderSelectedEntranceNeonHighlight({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required int selectedEntrance,
    required int entrances,
    required double sectionWidth,
    required double bDepth,
    required double totalHeight,
  }) {
    if (selectedEntrance < 1 || selectedEntrance > entrances) return;

    final double posX = (selectedEntrance - (entrances + 1) / 2.0) * (sectionWidth + 1.5);
    const double posZ = 0.0;

    final hw = (sectionWidth / 2) + 1.5;
    final hd = (bDepth / 2) + 1.5;

    // 8 box corners of the neon cage
    final b0 = camera.project(Vector3D(posX - hw, 0, posZ - hd), size);
    final b1 = camera.project(Vector3D(posX + hw, 0, posZ - hd), size);
    final b2 = camera.project(Vector3D(posX + hw, 0, posZ + hd), size);
    final b3 = camera.project(Vector3D(posX - hw, 0, posZ + hd), size);

    final t0 = camera.project(Vector3D(posX - hw, totalHeight + 4.0, posZ - hd), size);
    final t1 = camera.project(Vector3D(posX + hw, totalHeight + 4.0, posZ - hd), size);
    final t2 = camera.project(Vector3D(posX + hw, totalHeight + 4.0, posZ + hd), size);
    final t3 = camera.project(Vector3D(posX - hw, totalHeight + 4.0, posZ + hd), size);

    // Neon Glow Line (Electric Blue from Media 2)
    final neonPaint = Paint()
      ..color = const Color(0xFF2979FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Outer subtle glow
    final softGlowPaint = Paint()
      ..color = const Color(0xFF2979FF).withValues(alpha: 0.25)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    // Render glow + sharp lines
    for (final p in [softGlowPaint, neonPaint]) {
      // Bottom loop
      canvas.drawPath(Path()..moveTo(b0.dx, b0.dy)..lineTo(b1.dx, b1.dy)..lineTo(b2.dx, b2.dy)..lineTo(b3.dx, b3.dy)..close(), p);
      // Top loop
      canvas.drawPath(Path()..moveTo(t0.dx, t0.dy)..lineTo(t1.dx, t1.dy)..lineTo(t2.dx, t2.dy)..lineTo(t3.dx, t3.dy)..close(), p);
      // Vertical pillars
      canvas.drawLine(b0, t0, p);
      canvas.drawLine(b1, t1, p);
      canvas.drawLine(b2, t2, p);
      canvas.drawLine(b3, t3, p);
    }
  }
}
