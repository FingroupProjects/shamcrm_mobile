import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/poly_3d.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';
import 'package:flutter/material.dart';

class Apartment3DRenderInfo {
  final Apartment apartment;
  final Offset badgePosition;
  final Rect hitBounds;
  final bool isSelected;

  const Apartment3DRenderInfo({
    required this.apartment,
    required this.badgePosition,
    required this.hitBounds,
    required this.isSelected,
  });
}

/// Renders Level 4: 3D Volumetric Architectural Floor Plan (Media 4 in Web)
class FloorPlan3DPainter {
  static List<Apartment3DRenderInfo> render({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required Building building,
    required int entrance,
    required int floor,
    required List<Apartment> floorApartments,
    Apartment? selectedApartment,
  }) {
    final result = <Apartment3DRenderInfo>[];
    final allPolys = <Poly3D>[];

    // Main floor foundation plate dimensions matching Three.js Web (Media 4)
    const double slabWidth = 148.0;
    const double slabDepth = 138.0;
    const double slabThickness = 8.5;

    // 1. Foundation Slab (White horizontal architectural concrete plate with chamfer)
    allPolys.addAll(Poly3D.createBox(
      center: const Vector3D(0, slabThickness / 2, 0),
      width: slabWidth,
      height: slabThickness,
      depth: slabDepth,
      topColor: const Color(0xFFF7FAF9),
      frontColor: const Color(0xFFE0E7E5),
      sideColor: const Color(0xFFD2DBD9),
      strokeColor: const Color(0xFFBCC7C4),
      strokeWidth: 0.8,
      camera: camera,
    ));

    // 2. Prepare 4 solid volumetric apartment blocks on the slab
    // 2x2 grid matching Media 4:
    // Top-Left:     № 11071 (Gray - Sold)
    // Top-Right:    № 11072 (Green - Available)
    // Bottom-Left:  № 11073 (Teal/Turquoise - Reserved, highlighted)
    // Bottom-Right: № 11074 (Warm Orange - Booked)
    const double aptW = 58.0;
    const double aptD = 52.0;
    const double aptH = 15.0; // Solid wall thickness

    const double offsetX = 34.0;
    const double offsetZ = 30.0;

    final positions = [
      const Vector3D(-offsetX, slabThickness + (aptH / 2), -offsetZ), // Top-Left
      const Vector3D(offsetX, slabThickness + (aptH / 2), -offsetZ),  // Top-Right
      const Vector3D(-offsetX, slabThickness + (aptH / 2), offsetZ),  // Bottom-Left (Selected)
      const Vector3D(offsetX, slabThickness + (aptH / 2), offsetZ),   // Bottom-Right
    ];

    // Guarantee 4 authentic units
    final displayUnits = <Apartment>[];
    for (int i = 0; i < 4; i++) {
      if (i < floorApartments.length) {
        displayUnits.add(floorApartments[i]);
      } else {
        final num = '${floor * 1000 + (entrance * 100) + 71 + i}';
        displayUnits.add(Apartment(
          id: 990000 + i,
          number: num,
          status: i == 0
              ? ApartmentStatus.sold
              : i == 1
                  ? ApartmentStatus.available
                  : i == 2
                      ? ApartmentStatus.reserved
                      : ApartmentStatus.booked,
          type: '3-комнатная',
          rooms: i == 0 ? 3 : (i % 2) + 2,
          totalArea: 86.0 - (i * 8.0),
          livingArea: 52.0,
          kitchenArea: 14.0,
          pricePerSqm: 845,
          totalPrice: 73000,
          currency: '\$',
          floor: floor,
          entrance: entrance,
          buildingKey: building.key,
          buildingName: building.name,
        ));
      }
    }

    // Generate solid 3D cuboids for each apartment
    for (int i = 0; i < 4; i++) {
      final apt = displayUnits[i];
      final pos = positions[i];
      final isSelected = selectedApartment?.id == apt.id ||
          (selectedApartment == null && i == 2); // Default selected bottom-left unit (Media 4)

      // Solid architectural colors from Three.js Web (Media 4)
      Color topColor;
      Color frontColor;
      Color sideColor;

      switch (apt.status) {
        case ApartmentStatus.available:
          // Emerald Green
          topColor = const Color(0xFF10B981);
          frontColor = const Color(0xFF059669);
          sideColor = const Color(0xFF047857);
          break;
        case ApartmentStatus.booked:
          // Warm Amber Orange
          topColor = const Color(0xFFF59E0B);
          frontColor = const Color(0xFFD97706);
          sideColor = const Color(0xFFB45309);
          break;
        case ApartmentStatus.sold:
          // Slate Cool Gray
          topColor = const Color(0xFF94A3B8);
          frontColor = const Color(0xFF64748B);
          sideColor = const Color(0xFF475569);
          break;
        case ApartmentStatus.reserved:
          // Royal Blue
          topColor = const Color(0xFF3B82F6);
          frontColor = const Color(0xFF2563EB);
          sideColor = const Color(0xFF1D4ED8);
          break;
      }

      allPolys.addAll(Poly3D.createBox(
        center: pos,
        width: aptW,
        height: aptH,
        depth: aptD,
        topColor: topColor,
        frontColor: frontColor,
        sideColor: sideColor,
        strokeColor: isSelected
            ? const Color(0xFF7C4DFF) // Purple neon highlight line (Media 4)
            : Colors.black.withValues(alpha: 0.12),
        strokeWidth: isSelected ? 2.4 : 0.8,
        camera: camera,
      ));

      // Screen coordinate for the apartment badge (centered on top face)
      final badgePoint = Vector3D(pos.x, slabThickness + aptH + 0.5, pos.z);
      final badgeScreenPos = camera.project(badgePoint, size);

      // Hit area for tapping
      final hitRect = Rect.fromCenter(
        center: badgeScreenPos,
        width: aptW * camera.zoom * 0.95,
        height: aptD * camera.zoom * 0.85,
      );

      result.add(Apartment3DRenderInfo(
        apartment: apt,
        badgePosition: badgeScreenPos,
        hitBounds: hitRect,
        isSelected: isSelected,
      ));
    }

    // Sort polygons by depth
    allPolys.sort((a, b) => b.depth.compareTo(a.depth));

    // Render solid mesh
    for (final poly in allPolys) {
      poly.render(canvas, size, camera);
    }

    // 3. Render Neon Outline around selected Apartment (Media 4)
    for (final info in result) {
      if (info.isSelected) {
        _renderSelectedApartmentGlow(
          canvas: canvas,
          size: size,
          camera: camera,
          aptIndex: displayUnits.indexOf(info.apartment),
          positions: positions,
          aptW: aptW,
          aptD: aptD,
          aptH: aptH,
        );
      }
    }

    return result;
  }

  static void _renderSelectedApartmentGlow({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required int aptIndex,
    required List<Vector3D> positions,
    required double aptW,
    required double aptD,
    required double aptH,
  }) {
    if (aptIndex < 0 || aptIndex >= positions.length) return;
    final pos = positions[aptIndex];

    final hw = (aptW / 2) + 1.5;
    final hd = (aptD / 2) + 1.5;
    final topY = pos.y + (aptH / 2) + 0.5;
    final bottomY = pos.y - (aptH / 2) - 0.2;

    final b0 = camera.project(Vector3D(pos.x - hw, bottomY, pos.z - hd), size);
    final b1 = camera.project(Vector3D(pos.x + hw, bottomY, pos.z - hd), size);
    final b2 = camera.project(Vector3D(pos.x + hw, bottomY, pos.z + hd), size);
    final b3 = camera.project(Vector3D(pos.x - hw, bottomY, pos.z + hd), size);

    final t0 = camera.project(Vector3D(pos.x - hw, topY, pos.z - hd), size);
    final t1 = camera.project(Vector3D(pos.x + hw, topY, pos.z - hd), size);
    final t2 = camera.project(Vector3D(pos.x + hw, topY, pos.z + hd), size);
    final t3 = camera.project(Vector3D(pos.x - hw, topY, pos.z + hd), size);

    // Purple/Indigo Neon Highlight (Media 4)
    final glowPaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final softGlow = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.3)
      ..strokeWidth = 5.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    for (final p in [softGlow, glowPaint]) {
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
