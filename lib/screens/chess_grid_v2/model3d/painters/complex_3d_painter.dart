import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/poly_3d.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';
import 'package:flutter/material.dart';

class BuildingRenderInfo {
  final Building building;
  final Offset badgePosition;
  final Rect hitBounds;
  final int totalApts;
  final int freeApts;

  const BuildingRenderInfo({
    required this.building,
    required this.badgePosition,
    required this.hitBounds,
    required this.totalApts,
    required this.freeApts,
  });
}

/// Renders Level 1: Full Residential Complex in photorealistic architectural 3D (Media 1)
class Complex3DPainter {
  static List<BuildingRenderInfo> render({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required ResidentialComplex complex,
    required List<Apartment> allApartments,
    Building? highlightedBuilding,
  }) {
    final buildings = complex.buildings;
    if (buildings.isEmpty) return [];

    final result = <BuildingRenderInfo>[];
    final allPolys = <Poly3D>[];

    // Building dimensions
    const double bWidth = 92.0;
    const double bDepth = 62.0;
    const double floorHeight = 12.0;
    const double plinthHeight = 14.0;
    const double parapetHeight = 3.5;

    // Palette matching Three.js Web Render (Media 1):
    const cPlinthFront = Color(0xFF5A6972); // Dense dark plinth
    const cPlinthSide = Color(0xFF48555C);
    const cFacadeFront = Color(0xFFECEFEF); // Solid architectural concrete (Light)
    const cFacadeSide = Color(0xFFBAC6C4);  // Solid architectural concrete (Shade)
    const cRoofLawn = Color(0xFF1EA355);    // Vibrant rooftop emerald lawn
    const cRoofFront = Color(0xFF188243);
    const cRoofSide = Color(0xFF146A36);
    const cParapet = Color(0xFFDFE6E4);

    for (int i = 0; i < buildings.length; i++) {
      final b = buildings[i];
      final floors = b.floorCount.clamp(6, 18);
      final double totalBuildingHeight = floors * floorHeight;

      // Realistic diagonal formation (Media 1: Корпус 4 на переднем плане, остальные уходят вдаль)
      final double progress = buildings.length > 1 ? i / (buildings.length - 1) : 0.5;
      final double posX = 115.0 - (progress * 230.0);
      final double posZ = -120.0 + (progress * 220.0);

      final isHighlighted = highlightedBuilding?.key == b.key;

      // Statistics for floating badge
      final bApts = allApartments.where((a) => a.buildingKey == b.key).toList();
      final totalCount = bApts.isNotEmpty
          ? bApts.length
          : (b.entranceCount * b.floorCount * b.apartsPerFloor);
      final freeCount = bApts.isNotEmpty
          ? bApts.where((a) => a.status == ApartmentStatus.available).length
          : (totalCount * 0.5).round();

      // 1. Basement Styloplate / Plinth (Цоколь)
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, plinthHeight / 2, posZ),
        width: bWidth + 2.0,
        height: plinthHeight,
        depth: bDepth + 2.0,
        topColor: const Color(0xFF6A7982),
        frontColor: cPlinthFront,
        sideColor: cPlinthSide,
        strokeColor: const Color(0xFF3B464C),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // 2. Main Building Body (Фасад)
      final facadeHeight = totalBuildingHeight - plinthHeight;
      final facadeCenterY = plinthHeight + (facadeHeight / 2);

      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, facadeCenterY, posZ),
        width: bWidth,
        height: facadeHeight,
        depth: bDepth,
        topColor: cFacadeFront,
        frontColor: isHighlighted ? const Color(0xFFFAFCFB) : cFacadeFront,
        sideColor: isHighlighted ? const Color(0xFFC7D3D1) : cFacadeSide,
        strokeColor: const Color(0xFF9EAFA9),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // 3. Parapet and Emerald Green Roof (Крыша)
      final roofCenterY = totalBuildingHeight + (parapetHeight / 2);

      // Emerald roof surface
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, roofCenterY, posZ),
        width: bWidth + 3.0,
        height: parapetHeight,
        depth: bDepth + 3.0,
        topColor: cRoofLawn,
        frontColor: cRoofFront,
        sideColor: cRoofSide,
        strokeColor: cParapet,
        strokeWidth: 0.8,
        camera: camera,
      ));

      // Elevator Shaft / Rooftop mechanical room (Лифтовая надстройка на крыше)
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, totalBuildingHeight + parapetHeight + 3.0, posZ),
        width: 24.0,
        height: 6.0,
        depth: 18.0,
        topColor: const Color(0xFFCFD8D6),
        frontColor: const Color(0xFFB5C1BF),
        sideColor: const Color(0xFF9DA8A6),
        strokeColor: const Color(0xFF869290),
        strokeWidth: 0.5,
        camera: camera,
      ));

      // Badge anchor point
      final roofPeak3D = Vector3D(posX, totalBuildingHeight + 14.0, posZ);
      final badgeScreenPos = camera.project(roofPeak3D, size);

      // Hit area for tapping
      final bottomScreenPos = camera.project(Vector3D(posX, 0, posZ), size);
      final hitRect = Rect.fromCenter(
        center: Offset(badgeScreenPos.dx, (badgeScreenPos.dy + bottomScreenPos.dy) / 2),
        width: 110,
        height: (bottomScreenPos.dy - badgeScreenPos.dy).abs().clamp(70.0, 260.0),
      );

      result.add(BuildingRenderInfo(
        building: b,
        badgePosition: badgeScreenPos,
        hitBounds: hitRect,
        totalApts: totalCount,
        freeApts: freeCount,
      ));
    }

    // Sort polygons by camera depth (Z-buffer / Painter's algorithm)
    allPolys.sort((a, b) => b.depth.compareTo(a.depth));

    // Render 3D volume
    for (final poly in allPolys) {
      poly.render(canvas, size, camera);
    }

    // 4. Render Architectural Window Panes and Floor Lines on visible facades
    _renderRealisticWindows(
      canvas: canvas,
      size: size,
      camera: camera,
      buildings: buildings,
      bWidth: bWidth,
      bDepth: bDepth,
      floorHeight: floorHeight,
      plinthHeight: plinthHeight,
    );

    return result;
  }

  static void _renderRealisticWindows({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required List<Building> buildings,
    required double bWidth,
    required double bDepth,
    required double floorHeight,
    required double plinthHeight,
  }) {
    // Window styling: deep indigo glass with white frame matching Three.js render
    final glassPaint = Paint()
      ..color = const Color(0xFF324858) // Realistic glass reflection
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = const Color(0xFFF7FAF9).withValues(alpha: 0.9)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final floorLinePaint = Paint()
      ..color = const Color(0xFFBAC6C4).withValues(alpha: 0.65)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final entranceDoorPaint = Paint()
      ..color = const Color(0xFF23323D)
      ..style = PaintingStyle.fill;

    final entranceFramePaint = Paint()
      ..color = const Color(0xFFE2EBE8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final isFrontVisible = camera.cameraDir.z > 0.02;
    final isRightSideVisible = camera.cameraDir.x > 0.02;

    for (int i = 0; i < buildings.length; i++) {
      final b = buildings[i];
      final floors = b.floorCount.clamp(6, 18);
      final double progress = buildings.length > 1 ? i / (buildings.length - 1) : 0.5;
      final double posX = 115.0 - (progress * 230.0);
      final double posZ = -120.0 + (progress * 220.0);

      // 1. FRONT FACADE WINDOWS (+Z face)
      if (isFrontVisible) {
        const cols = 5;
        const winW = 8.8;
        const winH = 6.2;
        final colSpacing = bWidth / (cols + 1);

        for (int f = 1; f < floors; f++) {
          final floorY = plinthHeight + (f * floorHeight) - 2.5;

          // Horizontal floor line
          final flStart = camera.project(Vector3D(posX - bWidth / 2 + 1, floorY - 1.5, posZ + bDepth / 2 + 0.2), size);
          final flEnd = camera.project(Vector3D(posX + bWidth / 2 - 1, floorY - 1.5, posZ + bDepth / 2 + 0.2), size);
          canvas.drawLine(flStart, flEnd, floorLinePaint);

          // Window row
          for (int c = 1; c <= cols; c++) {
            final winX = posX - (bWidth / 2) + (c * colSpacing);
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

        // Entrance Doors on Plinth
        const doorW = 12.0;
        const doorH = 8.5;
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
        canvas.drawPath(doorPath, entranceDoorPaint);
        canvas.drawPath(doorPath, entranceFramePaint);
      }

      // 2. RIGHT SIDE FACADE WINDOWS (+X face)
      if (isRightSideVisible) {
        const sideCols = 3;
        const winW = 8.8;
        const winH = 6.2;
        final sideSpacing = bDepth / (sideCols + 1);

        for (int f = 1; f < floors; f++) {
          final floorY = plinthHeight + (f * floorHeight) - 2.5;

          // Horizontal floor line on side
          final flStart = camera.project(Vector3D(posX + bWidth / 2 + 0.2, floorY - 1.5, posZ - bDepth / 2 + 1), size);
          final flEnd = camera.project(Vector3D(posX + bWidth / 2 + 0.2, floorY - 1.5, posZ + bDepth / 2 - 1), size);
          canvas.drawLine(flStart, flEnd, floorLinePaint);

          for (int c = 1; c <= sideCols; c++) {
            final winZ = posZ - (bDepth / 2) + (c * sideSpacing);
            final winX = posX + (bWidth / 2) + 0.4;

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
}
