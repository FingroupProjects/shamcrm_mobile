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

/// Renders Level 1: Full Residential Complex in photorealistic architectural 3D
/// with modern luxury facades, corner pylons, French balconies, AC baskets,
/// Grand Lobbies for all entrances, and night architectural facade lighting.
class Complex3DPainter {
  static List<BuildingRenderInfo> render({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required ResidentialComplex complex,
    required List<Apartment> allApartments,
    Building? highlightedBuilding,
    bool isNightMode = false,
    Map<String, Offset>? customOffsets,
    String? draggingBuildingKey,
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

    // Architectural Palette (Day vs Night mode):
    final cPlinthFront = isNightMode ? const Color(0xFF26333D) : const Color(0xFF5A6972);
    final cPlinthSide = isNightMode ? const Color(0xFF1D2730) : const Color(0xFF48555C);
    final cFacadeFront = isNightMode ? const Color(0xFF4C5B65) : const Color(0xFFECEFEF);
    final cFacadeSide = isNightMode ? const Color(0xFF38464E) : const Color(0xFFBAC6C4);
    final cRoofLawn = isNightMode ? const Color(0xFF0E542C) : const Color(0xFF1EA355);
    final cRoofFront = isNightMode ? const Color(0xFF0A4021) : const Color(0xFF188243);
    final cRoofSide = isNightMode ? const Color(0xFF08331A) : const Color(0xFF146A36);
    final cParapet = isNightMode ? const Color(0xFF394852) : const Color(0xFFDFE6E4);

    // Accent Pylon Colors (Architectural contrast)
    final cPylonFront = isNightMode ? const Color(0xFF323F49) : const Color(0xFFD6DDD8);
    final cPylonSide = isNightMode ? const Color(0xFF253139) : const Color(0xFFAAB8B4);

    for (int i = 0; i < buildings.length; i++) {
      final b = buildings[i];
      final floors = b.floorCount.clamp(6, 18);
      final double totalBuildingHeight = floors * floorHeight;

      // Position: custom coordinates if moved, otherwise diagonal formation
      final double progress = buildings.length > 1 ? i / (buildings.length - 1) : 0.5;
      final defaultPosX = 115.0 - (progress * 230.0);
      final defaultPosZ = -120.0 + (progress * 220.0);

      final customPos = customOffsets?[b.key];
      final double posX = customPos?.dx ?? defaultPosX;
      final double posZ = customPos?.dy ?? defaultPosZ;

      final isDragging = draggingBuildingKey == b.key;
      final double elevation = isDragging ? 9.0 : 0.0;

      // Ground plane shadow and indicator when dragging
      if (isDragging) {
        final groundCenter = camera.project(Vector3D(posX, 0.2, posZ), size);
        final shadowRect = Rect.fromCenter(
          center: groundCenter,
          width: bWidth * camera.zoom * 1.15,
          height: bDepth * camera.zoom * 0.55,
        );
        canvas.drawOval(
          shadowRect,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0),
        );
        canvas.drawOval(
          shadowRect,
          Paint()
            ..color = const Color(0xFF2979FF).withValues(alpha: 0.85)
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke,
        );
      } else {
        // Subtle ambient contact shadow on the masterplan ground
        final groundCenter = camera.project(Vector3D(posX, 0.22, posZ), size);
        canvas.drawOval(
          Rect.fromCenter(
            center: groundCenter,
            width: bWidth * camera.zoom * 1.08,
            height: bDepth * camera.zoom * 0.58,
          ),
          Paint()
            ..color = Colors.black.withValues(alpha: isNightMode ? 0.5 : 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
        );
      }

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
        center: Vector3D(posX, elevation + (plinthHeight / 2), posZ),
        width: bWidth + 3.0,
        height: plinthHeight,
        depth: bDepth + 3.0,
        topColor: isNightMode ? const Color(0xFF334350) : const Color(0xFF6A7982),
        frontColor: cPlinthFront,
        sideColor: cPlinthSide,
        strokeColor: isNightMode ? const Color(0xFF1E2831) : const Color(0xFF3B464C),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // 2. Main Building Body (Фасад)
      final facadeHeight = totalBuildingHeight - plinthHeight;
      final facadeCenterY = elevation + plinthHeight + (facadeHeight / 2);

      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, facadeCenterY, posZ),
        width: bWidth,
        height: facadeHeight,
        depth: bDepth,
        topColor: isNightMode ? const Color(0xFF3E4F5D) : cFacadeFront,
        frontColor: isHighlighted
            ? (isNightMode ? const Color(0xFF5D707D) : const Color(0xFFFAFCFB))
            : cFacadeFront,
        sideColor: isHighlighted
            ? (isNightMode ? const Color(0xFF445460) : const Color(0xFFC7D3D1))
            : cFacadeSide,
        strokeColor: isHighlighted
            ? const Color(0xFF2979FF)
            : (isNightMode ? const Color(0xFF2C3B47) : const Color(0xFF9EAFA9)),
        strokeWidth: isHighlighted ? 1.4 : 0.6,
        camera: camera,
      ));

      // 3. Architectural Corner Accent Pylons (Left & Right framing pillars)
      const pylonW = 6.0;
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX - (bWidth / 2) + (pylonW / 2), facadeCenterY, posZ),
        width: pylonW,
        height: facadeHeight,
        depth: bDepth + 0.8,
        topColor: isNightMode ? const Color(0xFF3A4854) : cPylonFront,
        frontColor: cPylonFront,
        sideColor: cPylonSide,
        strokeColor: isNightMode ? const Color(0xFF243038) : const Color(0xFF8E9E9B),
        strokeWidth: 0.5,
        camera: camera,
      ));
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX + (bWidth / 2) - (pylonW / 2), facadeCenterY, posZ),
        width: pylonW,
        height: facadeHeight,
        depth: bDepth + 0.8,
        topColor: isNightMode ? const Color(0xFF3A4854) : cPylonFront,
        frontColor: cPylonFront,
        sideColor: cPylonSide,
        strokeColor: isNightMode ? const Color(0xFF243038) : const Color(0xFF8E9E9B),
        strokeWidth: 0.5,
        camera: camera,
      ));

      // 4. Parapet and Emerald Green Roof (Крыша)
      final roofCenterY = elevation + totalBuildingHeight + (parapetHeight / 2);

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

      // Elevator Shaft / Rooftop mechanical room
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(posX, elevation + totalBuildingHeight + parapetHeight + 3.0, posZ),
        width: 24.0,
        height: 6.0,
        depth: 18.0,
        topColor: isNightMode ? const Color(0xFF2D3C47) : const Color(0xFFCFD8D6),
        frontColor: isNightMode ? const Color(0xFF222F38) : const Color(0xFFB5C1BF),
        sideColor: isNightMode ? const Color(0xFF1B262E) : const Color(0xFF9DA8A6),
        strokeColor: isNightMode ? const Color(0xFF151E24) : const Color(0xFF869290),
        strokeWidth: 0.5,
        camera: camera,
      ));

      // Badge anchor point
      final roofPeak3D = Vector3D(posX, elevation + totalBuildingHeight + 14.0, posZ);
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

    // 5. Render Architectural Windows, French Balconies, AC Baskets & Grand Lobbies
    _renderRealisticWindows(
      canvas: canvas,
      size: size,
      camera: camera,
      buildings: buildings,
      allApartments: allApartments,
      bWidth: bWidth,
      bDepth: bDepth,
      floorHeight: floorHeight,
      plinthHeight: plinthHeight,
      isNightMode: isNightMode,
      customOffsets: customOffsets,
      draggingBuildingKey: draggingBuildingKey,
    );

    // 6. Night Architectural Facade Lighting (LED Accent uplights on corners & roofline)
    if (isNightMode) {
      _renderNightFacadeLighting(
        canvas: canvas,
        size: size,
        camera: camera,
        buildings: buildings,
        bWidth: bWidth,
        bDepth: bDepth,
        floorHeight: floorHeight,
        customOffsets: customOffsets,
      );
    }

    return result;
  }

  /// High-detail windows, French balconies, AC baskets and Grand Entrance Lobbies
  static void _renderRealisticWindows({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required List<Building> buildings,
    required List<Apartment> allApartments,
    required double bWidth,
    required double bDepth,
    required double floorHeight,
    required double plinthHeight,
    required bool isNightMode,
    Map<String, Offset>? customOffsets,
    String? draggingBuildingKey,
  }) {
    final defaultGlassPaint = Paint()
      ..color = isNightMode ? const Color(0xFF14202B) : const Color(0xFF334A5C)
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = isNightMode
          ? const Color(0xFF4C5D6B).withValues(alpha: 0.6)
          : const Color(0xFFF7FAF9).withValues(alpha: 0.9)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final floorLinePaint = Paint()
      ..color = isNightMode
          ? const Color(0xFF33434E).withValues(alpha: 0.5)
          : const Color(0xFFBAC6C4).withValues(alpha: 0.65)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    // AC basket paint
    final acBasketPaint = Paint()
      ..color = isNightMode ? const Color(0xFF222F38) : const Color(0xFF7A898F)
      ..style = PaintingStyle.fill;

    // French balcony glass paint
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

    for (int i = 0; i < buildings.length; i++) {
      final b = buildings[i];
      final floors = b.floorCount.clamp(6, 18);
      final double progress = buildings.length > 1 ? i / (buildings.length - 1) : 0.5;
      final defaultPosX = 115.0 - (progress * 230.0);
      final defaultPosZ = -120.0 + (progress * 220.0);

      final customPos = customOffsets?[b.key];
      final double posX = customPos?.dx ?? defaultPosX;
      final double posZ = customPos?.dy ?? defaultPosZ;

      final isDragging = draggingBuildingKey == b.key;
      final double elevation = isDragging ? 9.0 : 0.0;
      final bApts = allApartments.where((a) => a.buildingKey == b.key).toList();

      // ==========================================
      // 1. FRONT FACADE (+Z face)
      // ==========================================
      if (isFrontVisible) {
        const cols = 5;
        const winW = 8.8;
        const winH = 6.4;
        final colSpacing = bWidth / (cols + 1);

        for (int f = 1; f < floors; f++) {
          final floorY = elevation + plinthHeight + (f * floorHeight) - 2.5;

          // Horizontal floor slab line
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

            if (isNightMode) {
              final fApts = bApts.where((a) => a.floor == f).toList();
              final isSold = fApts.isNotEmpty
                  ? (fApts[(c - 1) % fApts.length].status == ApartmentStatus.sold ||
                      fApts[(c - 1) % fApts.length].status == ApartmentStatus.booked)
                  : ((f * 3 + c + i) % 4 != 0);

              if (isSold) {
                final warmColor = (f + c) % 2 == 0 ? const Color(0xFFFFD166) : const Color(0xFFFFB703);
                final glowPaint = Paint()
                  ..color = warmColor.withValues(alpha: 0.45)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
                canvas.drawPath(path, glowPaint);

                final litPaint = Paint()
                  ..color = (f + c) % 2 == 0 ? const Color(0xFFFFF2CD) : const Color(0xFFFFDF8B)
                  ..style = PaintingStyle.fill;
                canvas.drawPath(path, litPaint);
                canvas.drawPath(path, Paint()..color = warmColor.withValues(alpha: 0.85)..strokeWidth = 0.6..style = PaintingStyle.stroke);
              } else {
                canvas.drawPath(path, defaultGlassPaint);
                canvas.drawPath(path, framePaint);
              }
            } else {
              // Day mode: tinted panoramic glass with subtle reflection
              canvas.drawPath(path, defaultGlassPaint);
              canvas.drawPath(path, framePaint);

              // Specular glass highlight reflection (diagonal ray)
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

            // French Balcony Glass Railing on select floors (f = 2, 4, 6...)
            if (f % 2 == 0 && (c == 2 || c == 4)) {
              final b0 = camera.project(Vector3D(winX - winW / 2 - 0.2, floorY, winZ + 0.8), size);
              final b1 = camera.project(Vector3D(winX + winW / 2 + 0.2, floorY, winZ + 0.8), size);
              final b2 = camera.project(Vector3D(winX + winW / 2 + 0.2, floorY + 2.4, winZ + 0.8), size);
              final b3 = camera.project(Vector3D(winX - winW / 2 - 0.2, floorY + 2.4, winZ + 0.8), size);

              final bPath = Path()..moveTo(b0.dx, b0.dy)..lineTo(b1.dx, b1.dy)..lineTo(b2.dx, b2.dy)..lineTo(b3.dx, b3.dy)..close();
              canvas.drawPath(bPath, balconyGlassPaint);
              canvas.drawLine(b3, b2, balconyRailPaint);
            }

            // AC Basket (under odd column windows)
            if (f % 2 != 0 && (c == 1 || c == 3 || c == 5)) {
              final ac0 = camera.project(Vector3D(winX - 2.8, floorY - 1.8, winZ + 0.7), size);
              final ac1 = camera.project(Vector3D(winX + 2.8, floorY - 1.8, winZ + 0.7), size);
              final ac2 = camera.project(Vector3D(winX + 2.8, floorY - 0.5, winZ + 0.7), size);
              final ac3 = camera.project(Vector3D(winX - 2.8, floorY - 0.5, winZ + 0.7), size);

              final acPath = Path()..moveTo(ac0.dx, ac0.dy)..lineTo(ac1.dx, ac1.dy)..lineTo(ac2.dx, ac2.dy)..lineTo(ac3.dx, ac3.dy)..close();
              canvas.drawPath(acPath, acBasketPaint);
              canvas.drawPath(acPath, Paint()..color = Colors.black.withValues(alpha: 0.3)..strokeWidth = 0.5..style = PaintingStyle.stroke);
            }
          }
        }

        // ==========================================
        // GRAND LOBBY ENTRANCE GROUPS FOR EACH ENTRANCE
        // ==========================================
        final entranceCount = b.entranceCount.clamp(1, 6);
        const lobbyW = 15.0;
        const lobbyH = 10.5;
        final entranceSpacing = bWidth / (entranceCount + 1);

        for (int ent = 1; ent <= entranceCount; ent++) {
          final entX = posX - (bWidth / 2) + (ent * entranceSpacing);
          final doorZ = posZ + bDepth / 2 + 0.6;

          // 1. Entrance Granite Steps & Approach Pad
          final st0 = camera.project(Vector3D(entX - lobbyW / 2 - 2.5, 0.2, doorZ + 6.0), size);
          final st1 = camera.project(Vector3D(entX + lobbyW / 2 + 2.5, 0.2, doorZ + 6.0), size);
          final st2 = camera.project(Vector3D(entX + lobbyW / 2 + 2.5, 0.2, doorZ), size);
          final st3 = camera.project(Vector3D(entX - lobbyW / 2 - 2.5, 0.2, doorZ), size);
          final stepPath = Path()..moveTo(st0.dx, st0.dy)..lineTo(st1.dx, st1.dy)..lineTo(st2.dx, st2.dy)..lineTo(st3.dx, st3.dy)..close();
          canvas.drawPath(stepPath, Paint()..color = isNightMode ? const Color(0xFF28343E) : const Color(0xFFCFD8DC)..style = PaintingStyle.fill);
          canvas.drawPath(stepPath, Paint()..color = Colors.black.withValues(alpha: 0.25)..strokeWidth = 0.6..style = PaintingStyle.stroke);

          // 2. Double-height Glass Grand Lobby Portal
          final d0 = camera.project(Vector3D(entX - lobbyW / 2, 0.4, doorZ), size);
          final d1 = camera.project(Vector3D(entX + lobbyW / 2, 0.4, doorZ), size);
          final d2 = camera.project(Vector3D(entX + lobbyW / 2, lobbyH, doorZ), size);
          final d3 = camera.project(Vector3D(entX - lobbyW / 2, lobbyH, doorZ), size);
          final doorPath = Path()..moveTo(d0.dx, d0.dy)..lineTo(d1.dx, d1.dy)..lineTo(d2.dx, d2.dy)..lineTo(d3.dx, d3.dy)..close();

          // Warm interior foyer glow
          final foyerColor = isNightMode ? const Color(0xFF2D2519) : const Color(0xFF37474F);
          canvas.drawPath(doorPath, Paint()..color = foyerColor..style = PaintingStyle.fill);

          // Glass frame
          canvas.drawPath(
            doorPath,
            Paint()
              ..color = isNightMode ? const Color(0xFF5D6F7E) : const Color(0xFFECEFF1)
              ..strokeWidth = 1.0
              ..style = PaintingStyle.stroke,
          );

          // Center mullion divider
          final dm0 = camera.project(Vector3D(entX, 0.4, doorZ + 0.1), size);
          final dm1 = camera.project(Vector3D(entX, lobbyH, doorZ + 0.1), size);
          canvas.drawLine(dm0, dm1, Paint()..color = isNightMode ? const Color(0xFF5D6F7E) : const Color(0xFFECEFF1)..strokeWidth = 1.0);

          // Warm Lobby Chandelier Glow inside entrance
          final glowCenter = camera.project(Vector3D(entX, lobbyH * 0.65, doorZ + 0.2), size);
          canvas.drawCircle(
            glowCenter,
            3.5,
            Paint()
              ..color = const Color(0xFFFFD54F).withValues(alpha: isNightMode ? 0.85 : 0.4)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
          );

          // 3. Cantilevered Architectural Canopy (Козырек с подсветкой)
          final c0 = camera.project(Vector3D(entX - lobbyW / 2 - 3.0, lobbyH + 1.2, doorZ - 0.5), size);
          final c1 = camera.project(Vector3D(entX + lobbyW / 2 + 3.0, lobbyH + 1.2, doorZ - 0.5), size);
          final c2 = camera.project(Vector3D(entX + lobbyW / 2 + 3.0, lobbyH + 1.2, doorZ + 4.5), size);
          final c3 = camera.project(Vector3D(entX - lobbyW / 2 - 3.0, lobbyH + 1.2, doorZ + 4.5), size);
          final canopyPath = Path()..moveTo(c0.dx, c0.dy)..lineTo(c1.dx, c1.dy)..lineTo(c2.dx, c2.dy)..lineTo(c3.dx, c3.dy)..close();
          canvas.drawPath(canopyPath, Paint()..color = isNightMode ? const Color(0xFF1B242C) : const Color(0xFF263238)..style = PaintingStyle.fill);
          canvas.drawPath(canopyPath, Paint()..color = const Color(0xFF2979FF).withValues(alpha: 0.8)..strokeWidth = 1.0..style = PaintingStyle.stroke);

          // Downlights from canopy in night mode
          if (isNightMode) {
            final l0 = camera.project(Vector3D(entX - 4.0, lobbyH + 0.6, doorZ + 2.2), size);
            final l1 = camera.project(Vector3D(entX + 4.0, lobbyH + 0.6, doorZ + 2.2), size);
            final spotPaint = Paint()
              ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.8)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
            canvas.drawCircle(l0, 2.0, spotPaint);
            canvas.drawCircle(l1, 2.0, spotPaint);
          }

          // 4. Entrance Planters with Decorative Shrubs flanking the doors
          for (double side in [-1.0, 1.0]) {
            final planterX = entX + (side * (lobbyW / 2 + 2.0));
            final pBase = camera.project(Vector3D(planterX, 0.2, doorZ + 2.5), size);
            final pTop = camera.project(Vector3D(planterX, 2.8, doorZ + 2.5), size);

            // Planter box
            canvas.drawRect(
              Rect.fromCenter(center: pBase, width: 4.5 * camera.zoom, height: 3.5 * camera.zoom),
              Paint()..color = isNightMode ? const Color(0xFF37474F) : const Color(0xFF78909C),
            );
            // Green shrub
            canvas.drawCircle(
              pTop,
              3.2 * camera.zoom,
              Paint()..color = isNightMode ? const Color(0xFF1B5E20) : const Color(0xFF43A047),
            );
          }
        }
      }

      // ==========================================
      // 2. RIGHT SIDE FACADE (+X face)
      // ==========================================
      if (isRightSideVisible) {
        const sideCols = 3;
        const winW = 8.8;
        const winH = 6.4;
        final sideSpacing = bDepth / (sideCols + 1);

        for (int f = 1; f < floors; f++) {
          final floorY = elevation + plinthHeight + (f * floorHeight) - 2.5;

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

            final path = Path()..moveTo(p0.dx, p0.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();

            if (isNightMode) {
              final fApts = bApts.where((a) => a.floor == f).toList();
              final isSold = fApts.isNotEmpty
                  ? (fApts[(c - 1) % fApts.length].status == ApartmentStatus.sold ||
                      fApts[(c - 1) % fApts.length].status == ApartmentStatus.booked)
                  : ((f * 3 + c + i) % 4 != 0);

              if (isSold) {
                final warmColor = (f + c) % 2 == 0 ? const Color(0xFFFFD166) : const Color(0xFFFFB703);
                final glowPaint = Paint()
                  ..color = warmColor.withValues(alpha: 0.45)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
                canvas.drawPath(path, glowPaint);

                final litPaint = Paint()
                  ..color = (f + c) % 2 == 0 ? const Color(0xFFFFF2CD) : const Color(0xFFFFDF8B)
                  ..style = PaintingStyle.fill;
                canvas.drawPath(path, litPaint);
                canvas.drawPath(path, Paint()..color = warmColor.withValues(alpha: 0.85)..strokeWidth = 0.6..style = PaintingStyle.stroke);
              } else {
                canvas.drawPath(path, defaultGlassPaint);
                canvas.drawPath(path, framePaint);
              }
            } else {
              canvas.drawPath(path, defaultGlassPaint);
              canvas.drawPath(path, framePaint);
            }
          }
        }
      }
    }
  }

  /// Night Architectural Facade Lighting: vertical LED strip beams and roofline contour glow
  static void _renderNightFacadeLighting({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required List<Building> buildings,
    required double bWidth,
    required double bDepth,
    required double floorHeight,
    Map<String, Offset>? customOffsets,
  }) {
    final ledBeamPaint = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.65)
      ..strokeWidth = 1.6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final rooflinePaint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.75)
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    for (int i = 0; i < buildings.length; i++) {
      final b = buildings[i];
      final floors = b.floorCount.clamp(6, 18);
      final double totalHeight = floors * floorHeight;

      final double progress = buildings.length > 1 ? i / (buildings.length - 1) : 0.5;
      final defaultPosX = 115.0 - (progress * 230.0);
      final defaultPosZ = -120.0 + (progress * 220.0);

      final customPos = customOffsets?[b.key];
      final double posX = customPos?.dx ?? defaultPosX;
      final double posZ = customPos?.dy ?? defaultPosZ;

      // Vertical LED beams on front-left and front-right corners
      final cLeftBottom = camera.project(Vector3D(posX - bWidth / 2 + 0.5, 2.0, posZ + bDepth / 2 + 0.8), size);
      final cLeftTop = camera.project(Vector3D(posX - bWidth / 2 + 0.5, totalHeight, posZ + bDepth / 2 + 0.8), size);
      canvas.drawLine(cLeftBottom, cLeftTop, ledBeamPaint);

      final cRightBottom = camera.project(Vector3D(posX + bWidth / 2 - 0.5, 2.0, posZ + bDepth / 2 + 0.8), size);
      final cRightTop = camera.project(Vector3D(posX + bWidth / 2 - 0.5, totalHeight, posZ + bDepth / 2 + 0.8), size);
      canvas.drawLine(cRightBottom, cRightTop, ledBeamPaint);

      // Horizontal roofline illuminated strip
      final rLeft = camera.project(Vector3D(posX - bWidth / 2, totalHeight + 3.0, posZ + bDepth / 2 + 0.8), size);
      final rRight = camera.project(Vector3D(posX + bWidth / 2, totalHeight + 3.0, posZ + bDepth / 2 + 0.8), size);
      canvas.drawLine(rLeft, rRight, rooflinePaint);
    }
  }
}
