import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/poly_3d.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';
import 'package:flutter/material.dart';

class FloorRenderInfo {
  final int floorNumber;
  final Offset badgePosition;
  final Rect hitBounds;
  final List<Apartment> apartments;

  const FloorRenderInfo({
    required this.floorNumber,
    required this.badgePosition,
    required this.hitBounds,
    required this.apartments,
  });
}

/// Renders Level 3: Vertical Section Cutout by Floors (Media 3)
class Section3DPainter {
  static List<FloorRenderInfo> render({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required Building building,
    required int entrance,
    required int selectedFloor,
    required List<Apartment> allApartments,
  }) {
    final result = <FloorRenderInfo>[];
    final allPolys = <Poly3D>[];

    final floors = building.floorCount.clamp(6, 16);
    const double secWidth = 96.0;
    const double secDepth = 80.0;
    const double floorHeight = 15.5;
    const double slabHeight = 2.8;

    final sectionApts = allApartments
        .where((a) => a.buildingKey == building.key && a.entrance == entrance)
        .toList();

    // 1. Dark architectural roof structure
    final totalH = floors * floorHeight;
    allPolys.addAll(Poly3D.createBox(
      center: Vector3D(0, totalH + 2.5, 0),
      width: secWidth + 6.0,
      height: 4.5,
      depth: secDepth + 6.0,
      topColor: const Color(0xFF475560),
      frontColor: const Color(0xFF37444D),
      sideColor: const Color(0xFF2C373E),
      strokeColor: const Color(0xFF1E262B),
      strokeWidth: 0.8,
      camera: camera,
    ));

    // 2. Multi-storey architectural slabs
    for (int f = 1; f <= floors; f++) {
      final floorBottomY = (f - 1) * floorHeight;
      final floorCenterY = floorBottomY + (floorHeight / 2);

      // Floor slab (pure white solid plate)
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(0, floorBottomY + (slabHeight / 2), 0),
        width: secWidth,
        height: slabHeight,
        depth: secDepth,
        topColor: const Color(0xFFFFFFFF),
        frontColor: const Color(0xFFF1F5F4),
        sideColor: const Color(0xFFDEE5E3),
        strokeColor: const Color(0xFFC5CECC),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // Floor core volume
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(0, floorCenterY, 0),
        width: secWidth - 1.5,
        height: floorHeight - slabHeight,
        depth: secDepth - 1.5,
        topColor: const Color(0xFFECEFEF),
        frontColor: const Color(0xFFE2E7E6),
        sideColor: const Color(0xFFBAC6C4),
        strokeColor: const Color(0xFFAEBDBA),
        strokeWidth: 0.5,
        camera: camera,
      ));

      final fApts = sectionApts.where((a) => a.floor == f).toList();

      // Screen position for the floor badge (pinned to the left in 3D)
      final badgePoint3D = Vector3D(-(secWidth / 2) - 22.0, floorCenterY, (secDepth / 2));
      final badgePos = camera.project(badgePoint3D, size);

      // Hit area for tapping the floor
      final floorRightScreen = camera.project(Vector3D((secWidth / 2) + 10.0, floorCenterY, (secDepth / 2)), size);
      final hitRect = Rect.fromCenter(
        center: Offset((badgePos.dx + floorRightScreen.dx) / 2, badgePos.dy),
        width: (floorRightScreen.dx - badgePos.dx).abs().clamp(120.0, 320.0),
        height: (floorHeight * camera.zoom).clamp(16.0, 50.0),
      );

      result.add(FloorRenderInfo(
        floorNumber: f,
        badgePosition: badgePos,
        hitBounds: hitRect,
        apartments: fApts,
      ));
    }

    // Sort polygons by depth
    allPolys.sort((a, b) => b.depth.compareTo(a.depth));

    // Render solid geometry
    for (final poly in allPolys) {
      poly.render(canvas, size, camera);
    }

    // 3. Render Status-Colored Apartment blocks on the front facade of each floor (Media 3)
    _renderFloorFacadeUnits(canvas, size, camera, floors, floorHeight, secWidth, secDepth, sectionApts);

    // 4. Render Neon Blue highlight box around the selected floor (Media 3 - Floor 7)
    _renderSelectedFloorNeonFrame(
      canvas: canvas,
      size: size,
      camera: camera,
      selectedFloor: selectedFloor,
      floors: floors,
      floorHeight: floorHeight,
      secWidth: secWidth,
      secDepth: secDepth,
    );

    return result;
  }

  static void _renderFloorFacadeUnits(
    Canvas canvas,
    Size size,
    Camera3D camera,
    int floors,
    double floorHeight,
    double secWidth,
    double secDepth,
    List<Apartment> sectionApts,
  ) {
    const int unitsPerFloor = 4;
    const double unitW = 16.5;
    const double unitH = 8.5;
    final double colSpacing = secWidth / (unitsPerFloor + 1);

    for (int f = 1; f <= floors; f++) {
      final floorCenterY = (f - 1) * floorHeight + (floorHeight / 2) - 0.5;
      final fApts = sectionApts.where((a) => a.floor == f).toList();

      for (int u = 0; u < unitsPerFloor; u++) {
        final posX = -(secWidth / 2) + ((u + 1) * colSpacing);
        final double posZ = (secDepth / 2) + 0.6;

        // Colors matching Media 3
        Color unitColor = const Color(0xFF10B981); // Available default
        if (u < fApts.length) {
          final apt = fApts[u];
          switch (apt.status) {
            case ApartmentStatus.available:
              unitColor = const Color(0xFF10B981); // Vibrant Green
              break;
            case ApartmentStatus.booked:
              unitColor = const Color(0xFFF59E0B); // Warm Orange
              break;
            case ApartmentStatus.sold:
              unitColor = const Color(0xFF94A3B8); // Slate Gray
              break;
            case ApartmentStatus.reserved:
              unitColor = const Color(0xFF0D9488); // Deep Teal
              break;
          }
        } else {
          final hash = (f * 7 + u * 13) % 4;
          if (hash == 0) unitColor = const Color(0xFF10B981);
          if (hash == 1) unitColor = const Color(0xFFF59E0B);
          if (hash == 2) unitColor = const Color(0xFF94A3B8);
          if (hash == 3) unitColor = const Color(0xFF0D9488);
        }

        final p0 = camera.project(Vector3D(posX - unitW / 2, floorCenterY - unitH / 2, posZ), size);
        final p1 = camera.project(Vector3D(posX + unitW / 2, floorCenterY - unitH / 2, posZ), size);
        final p2 = camera.project(Vector3D(posX + unitW / 2, floorCenterY + unitH / 2, posZ), size);
        final p3 = camera.project(Vector3D(posX - unitW / 2, floorCenterY + unitH / 2, posZ), size);

        final unitPath = Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();

        // Drop shadow for apartment capsule
        canvas.drawPath(unitPath, Paint()..color = unitColor..style = PaintingStyle.fill);

        // Highlight top edge
        canvas.drawPath(
          unitPath,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.45)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  static void _renderSelectedFloorNeonFrame({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required int selectedFloor,
    required int floors,
    required double floorHeight,
    required double secWidth,
    required double secDepth,
  }) {
    if (selectedFloor < 1 || selectedFloor > floors) return;

    final bottomY = (selectedFloor - 1) * floorHeight - 0.5;
    final topY = bottomY + floorHeight + 1.2;

    final hw = (secWidth / 2) + 2.5;
    final hd = (secDepth / 2) + 2.5;

    final b0 = camera.project(Vector3D(-hw, bottomY, -hd), size);
    final b1 = camera.project(Vector3D(hw, bottomY, -hd), size);
    final b2 = camera.project(Vector3D(hw, bottomY, hd), size);
    final b3 = camera.project(Vector3D(-hw, bottomY, hd), size);

    final t0 = camera.project(Vector3D(-hw, topY, -hd), size);
    final t1 = camera.project(Vector3D(hw, topY, -hd), size);
    final t2 = camera.project(Vector3D(hw, topY, hd), size);
    final t3 = camera.project(Vector3D(-hw, topY, hd), size);

    // Transparent blue volume fill
    final frontFill = Path()..moveTo(b3.dx, b3.dy)..lineTo(b2.dx, b2.dy)..lineTo(t2.dx, t2.dy)..lineTo(t3.dx, t3.dy)..close();
    canvas.drawPath(frontFill, Paint()..color = const Color(0xFF2979FF).withValues(alpha: 0.16)..style = PaintingStyle.fill);

    // Neon Frame
    final neonPaint = Paint()
      ..color = const Color(0xFF2979FF)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF2979FF).withValues(alpha: 0.3)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    for (final p in [glowPaint, neonPaint]) {
      canvas.drawPath(Path()..moveTo(b0.dx, b0.dy)..lineTo(b1.dx, b1.dy)..lineTo(b2.dx, b2.dy)..lineTo(b3.dx, b3.dy)..close(), p);
      canvas.drawPath(Path()..moveTo(t0.dx, t0.dy)..lineTo(t1.dx, t1.dy)..lineTo(t2.dx, t2.dy)..lineTo(t3.dx, t3.dy)..close(), p);
      canvas.drawLine(b0, t0, p);
      canvas.drawLine(b1, t1, p);
      canvas.drawLine(b2, t2, p);
      canvas.drawLine(b3, t3, p);
    }
  }
}
