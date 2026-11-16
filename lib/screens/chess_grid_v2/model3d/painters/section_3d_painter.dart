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
    List<ParkingSpot> parkingSpots = const [],
    bool isNightMode = false,
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
    final sectionParking = parkingSpots.where((spot) {
      return spot.buildingKey == building.key ||
          (building.id != null && spot.buildingId == building.id);
    }).toList();

    // 1. Dark architectural roof structure
    final totalH = floors * floorHeight;
    allPolys.addAll(Poly3D.createBox(
      center: Vector3D(0, totalH + 2.5, 0),
      width: secWidth + 6.0,
      height: 4.5,
      depth: secDepth + 6.0,
      topColor: isNightMode ? const Color(0xFF2C3843) : const Color(0xFF475560),
      frontColor: isNightMode ? const Color(0xFF222D36) : const Color(0xFF37444D),
      sideColor: isNightMode ? const Color(0xFF1B242C) : const Color(0xFF2C373E),
      strokeColor: isNightMode ? const Color(0xFF151C22) : const Color(0xFF1E262B),
      strokeWidth: 0.8,
      camera: camera,
    ));

    // 2. Multi-storey architectural slabs
    for (int f = 1; f <= floors; f++) {
      final floorBottomY = (f - 1) * floorHeight;
      final floorCenterY = floorBottomY + (floorHeight / 2);

      // Floor slab
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(0, floorBottomY + (slabHeight / 2), 0),
        width: secWidth,
        height: slabHeight,
        depth: secDepth,
        topColor: isNightMode ? const Color(0xFF334351) : const Color(0xFFFFFFFF),
        frontColor: isNightMode ? const Color(0xFF283643) : const Color(0xFFF1F5F4),
        sideColor: isNightMode ? const Color(0xFF1E2933) : const Color(0xFFDEE5E3),
        strokeColor: isNightMode ? const Color(0xFF172028) : const Color(0xFFC5CECC),
        strokeWidth: 0.6,
        camera: camera,
      ));

      // Floor core volume
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(0, floorCenterY, 0),
        width: secWidth - 1.5,
        height: floorHeight - slabHeight,
        depth: secDepth - 1.5,
        topColor: isNightMode ? const Color(0xFF2A3742) : const Color(0xFFECEFEF),
        frontColor: isNightMode ? const Color(0xFF202C36) : const Color(0xFFE2E7E6),
        sideColor: isNightMode ? const Color(0xFF19232B) : const Color(0xFFBAC6C4),
        strokeColor: isNightMode ? const Color(0xFF131B21) : const Color(0xFFAEBDBA),
        strokeWidth: 0.5,
        camera: camera,
      ));

      final fApts = sectionApts.where((a) => a.floor == f).toList();

      // Screen position for the floor badge (pinned to the left in 3D)
      final badgePoint3D = Vector3D(-(secWidth / 2) - 22.0, floorCenterY, (secDepth / 2));
      final badgePos = camera.project(badgePoint3D, size);
      final bottomY = floorBottomY - 0.5;
      final hitRect = _volumeHitBounds(
        camera: camera,
        size: size,
        bottomY: bottomY,
        topY: bottomY + floorHeight + 1.2,
        secWidth: secWidth,
        secDepth: secDepth,
      ).expandToInclude(Rect.fromCenter(center: badgePos, width: 36, height: 36));

      result.add(FloorRenderInfo(
        floorNumber: f,
        badgePosition: badgePos,
        hitBounds: hitRect,
        apartments: fApts,
      ));
    }

    if (sectionParking.isNotEmpty) {
      const parkingFloor = 0;
      final floorCenterY = -floorHeight / 2;
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(0, -floorHeight + (slabHeight / 2), 0),
        width: secWidth,
        height: slabHeight,
        depth: secDepth,
        topColor: isNightMode ? const Color(0xFF243140) : const Color(0xFFD7E3EA),
        frontColor: isNightMode ? const Color(0xFF1B2833) : const Color(0xFFC5D4DC),
        sideColor: isNightMode ? const Color(0xFF152029) : const Color(0xFFB7C6CE),
        strokeColor: isNightMode ? const Color(0xFF101820) : const Color(0xFF9AADB8),
        strokeWidth: 0.6,
        camera: camera,
      ));
      allPolys.addAll(Poly3D.createBox(
        center: Vector3D(0, floorCenterY, 0),
        width: secWidth - 1.5,
        height: floorHeight - slabHeight,
        depth: secDepth - 1.5,
        topColor: isNightMode ? const Color(0xFF1E3344) : const Color(0xFFE7F2F6),
        frontColor: isNightMode ? const Color(0xFF173041) : const Color(0xFFD5E6EE),
        sideColor: isNightMode ? const Color(0xFF122838) : const Color(0xFFC3D7E1),
        strokeColor: isNightMode ? const Color(0xFF0E1C28) : const Color(0xFFA9C0CC),
        strokeWidth: 0.5,
        camera: camera,
      ));
      final badgePoint3D = Vector3D(-(secWidth / 2) - 22.0, floorCenterY, (secDepth / 2));
      final badgePos = camera.project(badgePoint3D, size);
      final bottomY = -floorHeight - 0.5;
      result.add(FloorRenderInfo(
        floorNumber: parkingFloor,
        badgePosition: badgePos,
        hitBounds: _volumeHitBounds(
          camera: camera,
          size: size,
          bottomY: bottomY,
          topY: bottomY + floorHeight + 1.2,
          secWidth: secWidth,
          secDepth: secDepth,
        ).expandToInclude(Rect.fromCenter(center: badgePos, width: 36, height: 36)),
        apartments: const [],
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
    if (sectionParking.isNotEmpty) {
      _renderParkingFacade(canvas, size, camera, floorHeight, secWidth, secDepth, sectionParking);
    }

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
              unitColor = const Color(0xFF3B82F6); // Royal Blue
              break;
          }
        } else {
          final hash = (f * 7 + u * 13) % 4;
          if (hash == 0) unitColor = const Color(0xFF10B981);
          if (hash == 1) unitColor = const Color(0xFFF59E0B);
          if (hash == 2) unitColor = const Color(0xFF94A3B8);
          if (hash == 3) unitColor = const Color(0xFF3B82F6);
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

  static void _renderParkingFacade(
    Canvas canvas,
    Size size,
    Camera3D camera,
    double floorHeight,
    double secWidth,
    double secDepth,
    List<ParkingSpot> spots,
  ) {
    final visible = spots.take(6).toList();
    const double unitW = 12.0;
    const double unitH = 8.0;
    final floorCenterY = -floorHeight / 2;
    final spacing = secWidth / (visible.length + 1);

    for (var i = 0; i < visible.length; i++) {
      final spot = visible[i];
      final posX = -(secWidth / 2) + ((i + 1) * spacing);
      final unitColor = switch (spot.status) {
        ApartmentStatus.available => const Color(0xFF10B981),
        ApartmentStatus.booked => const Color(0xFFF59E0B),
        ApartmentStatus.sold => const Color(0xFF94A3B8),
        ApartmentStatus.reserved => const Color(0xFF3B82F6),
      };
      final p0 = camera.project(Vector3D(posX - unitW / 2, floorCenterY - unitH / 2, (secDepth / 2) + 0.6), size);
      final p1 = camera.project(Vector3D(posX + unitW / 2, floorCenterY - unitH / 2, (secDepth / 2) + 0.6), size);
      final p2 = camera.project(Vector3D(posX + unitW / 2, floorCenterY + unitH / 2, (secDepth / 2) + 0.6), size);
      final p3 = camera.project(Vector3D(posX - unitW / 2, floorCenterY + unitH / 2, (secDepth / 2) + 0.6), size);
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = unitColor);
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
    if (selectedFloor == 0) {
      final bottomY = -floorHeight - 0.5;
      final topY = bottomY + floorHeight + 1.2;
      _paintNeonFrame(canvas, size, camera, bottomY, topY, secWidth, secDepth);
      return;
    }
    if (selectedFloor < 1 || selectedFloor > floors) return;

    final bottomY = (selectedFloor - 1) * floorHeight - 0.5;
    final topY = bottomY + floorHeight + 1.2;
    _paintNeonFrame(canvas, size, camera, bottomY, topY, secWidth, secDepth);
  }

  /// Screen box of the whole floor volume, so a tap on the floor itself
  /// (not only the side badge) opens it.
  static Rect _volumeHitBounds({
    required Camera3D camera,
    required Size size,
    required double bottomY,
    required double topY,
    required double secWidth,
    required double secDepth,
  }) {
    final hw = (secWidth / 2) + 2.5;
    final hd = (secDepth / 2) + 2.5;
    final points = <Offset>[
      camera.project(Vector3D(-hw, bottomY, -hd), size),
      camera.project(Vector3D(hw, bottomY, -hd), size),
      camera.project(Vector3D(hw, bottomY, hd), size),
      camera.project(Vector3D(-hw, bottomY, hd), size),
      camera.project(Vector3D(-hw, topY, -hd), size),
      camera.project(Vector3D(hw, topY, -hd), size),
      camera.project(Vector3D(hw, topY, hd), size),
      camera.project(Vector3D(-hw, topY, hd), size),
    ];
    var minX = points.first.dx;
    var maxX = points.first.dx;
    var minY = points.first.dy;
    var maxY = points.first.dy;
    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }
    return Rect.fromLTRB(minX - 6, minY - 6, maxX + 6, maxY + 6);
  }

  static void _paintNeonFrame(
    Canvas canvas,
    Size size,
    Camera3D camera,
    double bottomY,
    double topY,
    double secWidth,
    double secDepth,
  ) {

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
