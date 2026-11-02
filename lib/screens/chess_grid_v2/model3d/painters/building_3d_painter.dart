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

/// Renders Level 2: Selected Building with Entrances/Sections breakdown
/// with modern architectural detailing, French balconies, AC baskets,
/// Grand Lobbies with entrance steps & landscaping, and neon entrance selection.
class Building3DPainter {
  static List<EntranceRenderInfo> render({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required Building building,
    required List<Apartment> allApartments,
    required int selectedEntrance,
    bool isNightMode = false,
  }) {
    final result = <EntranceRenderInfo>[];
    final allPolys = <Poly3D>[];

    final entrances = building.entranceCount.clamp(1, 4);
    final floors = building.floorCount.clamp(6, 18);

    const double sectionWidth = 84.0;
    const double bDepth = 74.0;
    const double floorHeight = 12.5;
    const double plinthHeight = 14.0;
    const double parapetHeight = 3.5;

    // Palette matching Three.js Web (Day vs Night mode)
    final cPlinthFront = isNightMode ? const Color(0xFF25323C) : const Color(0xFF5A6972);
    final cPlinthSide = isNightMode ? const Color(0xFF1D2730) : const Color(0xFF48555C);
    final cFacadeFront = isNightMode ? const Color(0xFF4C5B65) : const Color(0xFFECEFEF);
    final cFacadeSide = isNightMode ? const Color(0xFF37444D) : const Color(0xFFBAC6C4);
    final cRoofLawn = isNightMode ? const Color(0xFF0E542C) : const Color(0xFF1EA355);
    final cRoofFront = isNightMode ? const Color(0xFF0A4021) : const Color(0xFF188243);
    final cRoofSide = isNightMode ? const Color(0xFF08331A) : const Color(0xFF146A36);
    final cParapet = isNightMode ? const Color(0xFF394852) : const Color(0xFFDFE6E4);

    final buildingApts = allApartments.where((a) => a.buildingKey == building.key).toList();

    final shape = building.buildingShape ??
        (entrances >= 3 && floors >= 12
            ? 'cascading'
            : (entrances <= 2 && floors >= 15 ? 'curvedTower' : 'standard'));
    final isCascading = shape == 'cascading';
    final isCurvedTower = shape == 'curvedTower';

    // 1. Construct solid geometry for each entrance/section
    for (int e = 1; e <= entrances; e++) {
      final double posX = (e - (entrances + 1) / 2.0) * (sectionWidth + 1.5);
      const double posZ = 0.0;
      final isSelected = selectedEntrance == e;

      // Cascading height adjustment per entrance section
      final double sectionFloors = isCascading
          ? (floors * (1.0 - ((e - 1) * 0.16))).clamp(5.0, floors.toDouble())
          : floors.toDouble();
      final double sectionTotalHeight = sectionFloors * floorHeight;

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
        width: sectionWidth + (isCurvedTower ? 4.0 : 1.0),
        height: plinthHeight,
        depth: bDepth + (isCurvedTower ? 6.0 : 1.0),
        topColor: isNightMode ? const Color(0xFF334350) : const Color(0xFF6A7982),
        frontColor: cPlinthFront,
        sideColor: cPlinthSide,
        strokeColor: isNightMode ? const Color(0xFF1E2831) : const Color(0xFF3B464C),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // Main Facade Section (Стены секции)
      final facadeHeight = sectionTotalHeight - plinthHeight;
      final facadeCenterY = plinthHeight + (facadeHeight / 2);

      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, facadeCenterY, posZ),
        width: sectionWidth,
        height: facadeHeight,
        depth: bDepth,
        topColor: isNightMode ? const Color(0xFF3E4F5D) : cFacadeFront,
        frontColor: isSelected
            ? (isNightMode ? const Color(0xFF5D707D) : const Color(0xFFFAFCFB))
            : cFacadeFront,
        sideColor: isSelected
            ? (isNightMode ? const Color(0xFF445460) : const Color(0xFFC7D3D1))
            : cFacadeSide,
        strokeColor: isNightMode ? const Color(0xFF2C3B47) : const Color(0xFF9EAFA9),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // Rooftop Green Lawn with Parapet
      final roofCenterY = sectionTotalHeight + (parapetHeight / 2);
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
      final badgePoint = Vector3D(posX, sectionTotalHeight + 16.0, posZ);
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

    // 2. Render Windows, French Balconies, AC Baskets and Grand Entrance Lobbies
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
      isCascading: isCascading,
      isNightMode: isNightMode,
      buildingApts: buildingApts,
    );

    // 3. Render Neon 3D Wireframe Highlight around selected Entrance
    final selectedSectionFloors = isCascading
        ? (floors * (1.0 - ((selectedEntrance - 1) * 0.16))).clamp(5.0, floors.toDouble())
        : floors.toDouble();
    final selectedSectionHeight = selectedSectionFloors * floorHeight + parapetHeight;

    _renderSelectedEntranceNeonHighlight(
      canvas: canvas,
      size: size,
      camera: camera,
      selectedEntrance: selectedEntrance,
      entrances: entrances,
      sectionWidth: sectionWidth,
      bDepth: bDepth,
      totalHeight: selectedSectionHeight,
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
    required bool isCascading,
    required bool isNightMode,
    required List<Apartment> buildingApts,
  }) {
    final defaultGlassPaint = Paint()
      ..color = isNightMode ? const Color(0xFF14202B) : const Color(0xFF384E5F)
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = isNightMode
          ? const Color(0xFF4C5D6B).withValues(alpha: 0.6)
          : const Color(0xFFF7FAF9).withValues(alpha: 0.85)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final floorLinePaint = Paint()
      ..color = isNightMode
          ? const Color(0xFF33434E).withValues(alpha: 0.5)
          : const Color(0xFFBAC6C4).withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final acBasketPaint = Paint()
      ..color = isNightMode ? const Color(0xFF222F38) : const Color(0xFF7A898F)
      ..style = PaintingStyle.fill;

    final balconyGlassPaint = Paint()
      ..color = isNightMode
          ? const Color(0xFF2979FF).withValues(alpha: 0.35)
          : const Color(0xFFB0BEC5).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final balconyRailPaint = Paint()
      ..color = isNightMode ? const Color(0xFF90CAF9) : Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 0.9;

    final isFrontVisible = camera.cameraDir.z > 0.02;
    final isRightSideVisible = camera.cameraDir.x > 0.02;

    for (int e = 1; e <= entrances; e++) {
      final double posX = (e - (entrances + 1) / 2.0) * (sectionWidth + 1.5);
      const double posZ = 0.0;

      final double sectionFloors = isCascading
          ? (floors * (1.0 - ((e - 1) * 0.16))).clamp(5.0, floors.toDouble())
          : floors.toDouble();
      final int sectionFloorsCount = sectionFloors.round();

      final entApts = buildingApts.where((a) => a.entrance == e).toList();

      if (isFrontVisible) {
        const cols = 4;
        const winW = 9.2;
        const winH = 6.4;
        final colSpacing = sectionWidth / (cols + 1);

        for (int f = 1; f < sectionFloorsCount; f++) {
          final floorY = plinthHeight + (f * floorHeight) - 2.5;

          // Floor joint line
          final flStart = camera.project(Vector3D(posX - sectionWidth / 2 + 1, floorY - 1.5, posZ + bDepth / 2 + 0.2), size);
          final flEnd = camera.project(Vector3D(posX + sectionWidth / 2 - 1, floorY - 1.5, posZ + bDepth / 2 + 0.2), size);
          canvas.drawLine(flStart, flEnd, floorLinePaint);

          final floorApts = entApts.where((a) => a.floor == f).toList();

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

            if (isNightMode) {
              final apt = floorApts.isNotEmpty ? floorApts[(c - 1) % floorApts.length] : null;
              final isSoldOrBooked = apt != null
                  ? (apt.status == ApartmentStatus.sold || apt.status == ApartmentStatus.booked)
                  : ((f * 3 + c + e) % 4 != 0);

              if (isSoldOrBooked) {
                final warmColor = (f + c) % 2 == 0 ? const Color(0xFFFFD166) : const Color(0xFFFFB703);
                final glowPaint = Paint()
                  ..color = warmColor.withValues(alpha: 0.45)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
                canvas.drawPath(path, glowPaint);

                final litPaint = Paint()
                  ..color = (f + c) % 2 == 0 ? const Color(0xFFFFF2CD) : const Color(0xFFFFDF8B)
                  ..style = PaintingStyle.fill;
                canvas.drawPath(path, litPaint);
                canvas.drawPath(path, Paint()..color = warmColor.withValues(alpha: 0.9)..strokeWidth = 0.6..style = PaintingStyle.stroke);
              } else {
                canvas.drawPath(path, defaultGlassPaint);
                canvas.drawPath(path, framePaint);
              }
            } else {
              canvas.drawPath(path, defaultGlassPaint);
              canvas.drawPath(path, framePaint);

              // Specular glass highlight reflection
              final refP0 = camera.project(Vector3D(winX - winW * 0.3, floorY, winZ + 0.1), size);
              final refP1 = camera.project(Vector3D(winX + winW * 0.2, floorY + winH, winZ + 0.1), size);
              canvas.drawLine(
                refP0,
                refP1,
                Paint()
                  ..color = Colors.white.withValues(alpha: 0.35)
                  ..strokeWidth = 1.0,
              );
            }

            // French Balcony on upper floors
            if (f % 2 == 0 && (c == 2 || c == 3)) {
              final b0 = camera.project(Vector3D(winX - winW / 2 - 0.2, floorY, winZ + 0.8), size);
              final b1 = camera.project(Vector3D(winX + winW / 2 + 0.2, floorY, winZ + 0.8), size);
              final b2 = camera.project(Vector3D(winX + winW / 2 + 0.2, floorY + 2.4, winZ + 0.8), size);
              final b3 = camera.project(Vector3D(winX - winW / 2 - 0.2, floorY + 2.4, winZ + 0.8), size);

              final bPath = Path()..moveTo(b0.dx, b0.dy)..lineTo(b1.dx, b1.dy)..lineTo(b2.dx, b2.dy)..lineTo(b3.dx, b3.dy)..close();
              canvas.drawPath(bPath, balconyGlassPaint);
              canvas.drawLine(b3, b2, balconyRailPaint);
            }

            // AC Basket under alternating windows
            if (f % 2 != 0 && (c == 1 || c == 4)) {
              final ac0 = camera.project(Vector3D(winX - 3.0, floorY - 1.8, winZ + 0.7), size);
              final ac1 = camera.project(Vector3D(winX + 3.0, floorY - 1.8, winZ + 0.7), size);
              final ac2 = camera.project(Vector3D(winX + 3.0, floorY - 0.5, winZ + 0.7), size);
              final ac3 = camera.project(Vector3D(winX - 3.0, floorY - 0.5, winZ + 0.7), size);

              final acPath = Path()..moveTo(ac0.dx, ac0.dy)..lineTo(ac1.dx, ac1.dy)..lineTo(ac2.dx, ac2.dy)..lineTo(ac3.dx, ac3.dy)..close();
              canvas.drawPath(acPath, acBasketPaint);
              canvas.drawPath(acPath, Paint()..color = Colors.black.withValues(alpha: 0.3)..strokeWidth = 0.5..style = PaintingStyle.stroke);
            }
          }
        }

        // --- Realistic Architectural Grand Lobby for this entrance ---
        const doorW = 22.0;
        const doorH = 12.0;
        final doorBaseZ = posZ + bDepth / 2 + 0.6;

        // 1. Entrance Granite Steps & Approach Pad
        final st0 = camera.project(Vector3D(posX - doorW / 2 - 3.0, 0.2, doorBaseZ + 7.0), size);
        final st1 = camera.project(Vector3D(posX + doorW / 2 + 3.0, 0.2, doorBaseZ + 7.0), size);
        final st2 = camera.project(Vector3D(posX + doorW / 2 + 3.0, 0.2, doorBaseZ), size);
        final st3 = camera.project(Vector3D(posX - doorW / 2 - 3.0, 0.2, doorBaseZ), size);
        final stepPath = Path()..moveTo(st0.dx, st0.dy)..lineTo(st1.dx, st1.dy)..lineTo(st2.dx, st2.dy)..lineTo(st3.dx, st3.dy)..close();
        canvas.drawPath(stepPath, Paint()..color = isNightMode ? const Color(0xFF28343E) : const Color(0xFFCFD8DC)..style = PaintingStyle.fill);
        canvas.drawPath(stepPath, Paint()..color = Colors.black.withValues(alpha: 0.25)..strokeWidth = 0.6..style = PaintingStyle.stroke);

        // 2. Entrance Canopy
        final c0 = camera.project(Vector3D(posX - (doorW / 2) - 3.0, doorH + 2.2, doorBaseZ - 1.0), size);
        final c1 = camera.project(Vector3D(posX + (doorW / 2) + 3.0, doorH + 2.2, doorBaseZ - 1.0), size);
        final c2 = camera.project(Vector3D(posX + (doorW / 2) + 3.0, doorH + 2.2, doorBaseZ + 5.5), size);
        final c3 = camera.project(Vector3D(posX - (doorW / 2) - 3.0, doorH + 2.2, doorBaseZ + 5.5), size);
        final canopyPath = Path()..moveTo(c0.dx, c0.dy)..lineTo(c1.dx, c1.dy)..lineTo(c2.dx, c2.dy)..lineTo(c3.dx, c3.dy)..close();
        canvas.drawPath(canopyPath, Paint()..color = isNightMode ? const Color(0xFF1D262F) : const Color(0xFF2C3E50)..style = PaintingStyle.fill);
        canvas.drawPath(canopyPath, Paint()..color = const Color(0xFF2979FF).withValues(alpha: 0.7)..strokeWidth = 1.0..style = PaintingStyle.stroke);

        // Canopy warm lantern at night
        if (isNightMode) {
          final lanternCenter = camera.project(Vector3D(posX, doorH + 1.2, doorBaseZ + 2.5), size);
          canvas.drawCircle(lanternCenter, 4.0, Paint()..color = const Color(0xFFFFEEAA).withValues(alpha: 0.65)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0));
          canvas.drawCircle(lanternCenter, 1.8, Paint()..color = Colors.white);
        }

        // 3. Entrance Sign (Табличка "Подъезд X")
        final s0 = camera.project(Vector3D(posX - 9.0, doorH + 0.4, doorBaseZ + 0.6), size);
        final s1 = camera.project(Vector3D(posX + 9.0, doorH + 0.4, doorBaseZ + 0.6), size);
        final s2 = camera.project(Vector3D(posX + 9.0, doorH + 1.8, doorBaseZ + 0.6), size);
        final s3 = camera.project(Vector3D(posX - 9.0, doorH + 1.8, doorBaseZ + 0.6), size);
        final signPath = Path()..moveTo(s0.dx, s0.dy)..lineTo(s1.dx, s1.dy)..lineTo(s2.dx, s2.dy)..lineTo(s3.dx, s3.dy)..close();
        canvas.drawPath(signPath, Paint()..color = const Color(0xFF1F2B36)..style = PaintingStyle.fill);
        canvas.drawPath(signPath, Paint()..color = const Color(0xFF2ECC71)..strokeWidth = 0.8..style = PaintingStyle.stroke);

        // 4. Double Glass Doors with warm interior foyer
        final d0 = camera.project(Vector3D(posX - doorW / 2, 0.4, doorBaseZ), size);
        final d1 = camera.project(Vector3D(posX + doorW / 2, 0.4, doorBaseZ), size);
        final d2 = camera.project(Vector3D(posX + doorW / 2, doorH, doorBaseZ), size);
        final d3 = camera.project(Vector3D(posX - doorW / 2, doorH, doorBaseZ), size);
        final doorPath = Path()..moveTo(d0.dx, d0.dy)..lineTo(d1.dx, d1.dy)..lineTo(d2.dx, d2.dy)..lineTo(d3.dx, d3.dy)..close();

        canvas.drawPath(doorPath, Paint()..color = isNightMode ? const Color(0xFF1B2C3A) : const Color(0xFF283B4A)..style = PaintingStyle.fill);
        canvas.drawPath(doorPath, Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1.0..style = PaintingStyle.stroke);

        // Warm interior lobby chandelier glow
        final glowCenter = camera.project(Vector3D(posX, doorH * 0.65, doorBaseZ + 0.2), size);
        canvas.drawCircle(
          glowCenter,
          4.0,
          Paint()
            ..color = const Color(0xFFFFD54F).withValues(alpha: isNightMode ? 0.85 : 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );

        // Door divider mullion & handles
        final dm0 = camera.project(Vector3D(posX, 0.4, doorBaseZ + 0.2), size);
        final dm1 = camera.project(Vector3D(posX, doorH, doorBaseZ + 0.2), size);
        canvas.drawLine(dm0, dm1, Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1.2);

        final h0 = camera.project(Vector3D(posX - 2.0, 3.5, doorBaseZ + 0.3), size);
        final h1 = camera.project(Vector3D(posX - 2.0, 6.5, doorBaseZ + 0.3), size);
        final h2 = camera.project(Vector3D(posX + 2.0, 3.5, doorBaseZ + 0.3), size);
        final h3 = camera.project(Vector3D(posX + 2.0, 6.5, doorBaseZ + 0.3), size);
        canvas.drawLine(h0, h1, Paint()..color = Colors.white..strokeWidth = 1.4);
        canvas.drawLine(h2, h3, Paint()..color = Colors.white..strokeWidth = 1.4);

        // 5. Entrance Planters with Decorative Shrubs
        for (double side in [-1.0, 1.0]) {
          final planterX = posX + (side * (doorW / 2 + 2.5));
          final pBase = camera.project(Vector3D(planterX, 0.2, doorBaseZ + 3.0), size);
          final pTop = camera.project(Vector3D(planterX, 3.2, doorBaseZ + 3.0), size);

          canvas.drawRect(
            Rect.fromCenter(center: pBase, width: 5.0 * camera.zoom, height: 4.0 * camera.zoom),
            Paint()..color = isNightMode ? const Color(0xFF37474F) : const Color(0xFF78909C),
          );
          canvas.drawCircle(
            pTop,
            3.5 * camera.zoom,
            Paint()..color = isNightMode ? const Color(0xFF1B5E20) : const Color(0xFF43A047),
          );
        }
      }

      // Windows on rightmost section's side face
      if (e == entrances && isRightSideVisible) {
        const sideCols = 3;
        const winW = 9.2;
        const winH = 6.4;
        final sideSpacing = bDepth / (sideCols + 1);

        final lastSectionFloorsCount = isCascading
            ? (floors * (1.0 - ((entrances - 1) * 0.16))).clamp(5.0, floors.toDouble()).round()
            : floors;

        for (int f = 1; f < lastSectionFloorsCount; f++) {
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

            canvas.drawPath(path, defaultGlassPaint);
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

    // Neon Glow Line (Electric Blue)
    final neonPaint = Paint()
      ..color = const Color(0xFF2979FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final softGlowPaint = Paint()
      ..color = const Color(0xFF2979FF).withValues(alpha: 0.25)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    for (final p in [softGlowPaint, neonPaint]) {
      canvas.drawPath(Path()..moveTo(b0.dx, b0.dy)..lineTo(b1.dx, b1.dy)..lineTo(b2.dx, b2.dy)..lineTo(b3.dx, b3.dy)..close(), p);
      canvas.drawPath(Path()..moveTo(t0.dx, t0.dy)..lineTo(t1.dx, t1.dy)..lineTo(t2.dx, t2.dy)..lineTo(t3.dx, t3.dy)..close(), p);
      canvas.drawLine(b0, t0, p);
      canvas.drawLine(b1, t1, p);
      canvas.drawLine(b2, t2, p);
      canvas.drawLine(b3, t3, p);
    }
  }
}
