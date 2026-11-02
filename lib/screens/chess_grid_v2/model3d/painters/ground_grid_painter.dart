import 'dart:math' as math;
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';
import 'package:flutter/material.dart';

/// Renders the architectural landscaped ground plane with real geolocation aura,
/// asphalt road network, paved promenades, 3D trees, courtyard fountain, and night streetlamps.
class GroundGridPainter {
  static void render({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    ResidentialComplex? complex,
    double extent = 800.0,
    double step = 48.0,
    bool isNightMode = false,
  }) {
    // 1. Atmosphere / Horizon Background Sky
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = (isNightMode
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF060B12), // Deep celestial dark night
                    Color(0xFF0C1622), // Midnight atmospheric blue
                    Color(0xFF142436), // Twilight horizon haze
                  ],
                  stops: [0.0, 0.5, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE5EFF4), // Clean sunny sky
                    Color(0xFFDEE9E3), // Soft horizon haze
                    Color(0xFFDEE9E3),
                  ],
                  stops: [0.0, 0.42, 1.0],
                ))
          .createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Subtle Night Stars effect
    if (isNightMode) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.65);
      final stars = [
        Offset(size.width * 0.10, size.height * 0.07),
        Offset(size.width * 0.22, size.height * 0.04),
        Offset(size.width * 0.36, size.height * 0.11),
        Offset(size.width * 0.52, size.height * 0.05),
        Offset(size.width * 0.68, size.height * 0.09),
        Offset(size.width * 0.81, size.height * 0.13),
        Offset(size.width * 0.92, size.height * 0.06),
        Offset(size.width * 0.17, size.height * 0.16),
        Offset(size.width * 0.44, size.height * 0.18),
        Offset(size.width * 0.74, size.height * 0.17),
      ];
      for (int i = 0; i < stars.length; i++) {
        final r = (i % 3 == 0) ? 1.8 : 1.1;
        canvas.drawCircle(stars[i], r, starPaint);
      }
    }

    // 2. Base Ground Polygon (Turf / Meadow)
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
      ..color = isNightMode
          ? const Color(0xFF111A24) // Deep night architectural turf
          : const Color(0xFFE2EBE0) // Authentic pastel green landscape
      ..style = PaintingStyle.fill;
    canvas.drawPath(groundPath, groundPaint);

    // 3. Grid Lines (Cadastral / Architectural masterplan grid)
    final linePaint = Paint()
      ..color = isNightMode
          ? const Color(0xFF1E2E3E).withValues(alpha: 0.65)
          : const Color(0xFFC7D6C6).withValues(alpha: 0.65)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double x = -extent; x <= extent; x += step) {
      final start = camera.project(Vector3D(x, 0, -extent), size);
      final end = camera.project(Vector3D(x, 0, extent), size);
      canvas.drawLine(start, end, linePaint);
    }

    for (double z = -extent; z <= extent; z += step) {
      final start = camera.project(Vector3D(-extent, 0, z), size);
      final end = camera.project(Vector3D(extent, 0, z), size);
      canvas.drawLine(start, end, linePaint);
    }

    // 4. ARCHITECTURAL MASTERPLAN ROADS & LANDSCAPING (Real Site Environment)
    _renderMasterplanSite(
      canvas: canvas,
      size: size,
      camera: camera,
      isNightMode: isNightMode,
      complex: complex,
    );
  }

  /// Renders the real-estate masterplan: perimeter asphalt road, pedestrian promenades,
  /// central fountain courtyard, parked cars, trees, streetlamps, and geolocation datum.
  static void _renderMasterplanSite({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required bool isNightMode,
    ResidentialComplex? complex,
  }) {
    // Colors
    final asphaltColor = isNightMode ? const Color(0xFF161A1E) : const Color(0xFF353C42);
    final curbColor = isNightMode ? const Color(0xFF28343E) : const Color(0xFFD3DDD8);
    final roadStripeColor = isNightMode
        ? const Color(0xFF6B7B88).withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.75);
    final walkwayColor = isNightMode ? const Color(0xFF1C2732) : const Color(0xFFECEFEF);
    final walkwayEdgeColor = isNightMode ? const Color(0xFF283745) : const Color(0xFFBAC6C4);
    final courtyardLawnColor = isNightMode ? const Color(0xFF0F2618) : const Color(0xFF8BAE7A);

    // ----------------------------------------------------
    // A. Courtyard Lush Green Lawn Bed (between buildings)
    // ----------------------------------------------------
    _draw3DQuad(
      canvas: canvas,
      size: size,
      camera: camera,
      v0: const Vector3D(-180, 0.1, -150),
      v1: const Vector3D(180, 0.1, -150),
      v2: const Vector3D(180, 0.1, 150),
      v3: const Vector3D(-180, 0.1, 150),
      fillColor: courtyardLawnColor,
      strokeColor: isNightMode ? const Color(0xFF193B26) : const Color(0xFF759765),
      strokeWidth: 1.0,
    );

    // ----------------------------------------------------
    // B. Perimeter Asphalt Road Network
    // ----------------------------------------------------
    // Outer boundary: X: [-210, 210], Z: [-180, 180], Road width: 22
    const rw = 22.0;

    // South Road Segment
    _draw3DQuad(
      canvas: canvas,
      size: size,
      camera: camera,
      v0: const Vector3D(-210, 0.15, 155),
      v1: const Vector3D(210, 0.15, 155),
      v2: const Vector3D(210, 0.15, 155 + rw),
      v3: const Vector3D(-210, 0.15, 155 + rw),
      fillColor: asphaltColor,
      strokeColor: curbColor,
      strokeWidth: 0.8,
    );

    // South Road dashed centerline
    for (double rx = -190; rx <= 190; rx += 24) {
      final s0 = camera.project(Vector3D(rx, 0.2, 155 + rw / 2), size);
      final s1 = camera.project(Vector3D(rx + 12, 0.2, 155 + rw / 2), size);
      canvas.drawLine(s0, s1, Paint()..color = roadStripeColor..strokeWidth = 1.2);
    }

    // Zebra Crossings (Pedestrian crosswalks onto the site)
    for (double zx in [-80.0, 80.0]) {
      for (double offset = 0; offset <= 10; offset += 2.5) {
        final z0 = camera.project(Vector3D(zx + offset, 0.22, 156), size);
        final z1 = camera.project(Vector3D(zx + offset, 0.22, 155 + rw - 1), size);
        canvas.drawLine(z0, z1, Paint()..color = roadStripeColor..strokeWidth = 1.4);
      }
    }

    // North Road Segment
    _draw3DQuad(
      canvas: canvas,
      size: size,
      camera: camera,
      v0: const Vector3D(-210, 0.15, -177),
      v1: const Vector3D(210, 0.15, -177),
      v2: const Vector3D(210, 0.15, -155),
      v3: const Vector3D(-210, 0.15, -155),
      fillColor: asphaltColor,
      strokeColor: curbColor,
      strokeWidth: 0.8,
    );

    // ----------------------------------------------------
    // C. Paved Pedestrian Promenades (Брусчатка к подъездам)
    // ----------------------------------------------------
    // Main pedestrian avenue running along building front entrances
    _draw3DQuad(
      canvas: canvas,
      size: size,
      camera: camera,
      v0: const Vector3D(-160, 0.2, 40),
      v1: const Vector3D(160, 0.2, 40),
      v2: const Vector3D(160, 0.2, 75),
      v3: const Vector3D(-160, 0.2, 75),
      fillColor: walkwayColor,
      strokeColor: walkwayEdgeColor,
      strokeWidth: 0.8,
    );

    // Connecting cross-walkway from south road to the main promenade
    _draw3DQuad(
      canvas: canvas,
      size: size,
      camera: camera,
      v0: const Vector3D(-16, 0.2, 75),
      v1: const Vector3D(16, 0.2, 75),
      v2: const Vector3D(16, 0.2, 155),
      v3: const Vector3D(-16, 0.2, 155),
      fillColor: walkwayColor,
      strokeColor: walkwayEdgeColor,
      strokeWidth: 0.8,
    );

    // ----------------------------------------------------
    // D. Central Courtyard Plaza & Decorative Fountain / Reflection Pool
    // ----------------------------------------------------
    const fountainCenter = Vector3D(0, 0.25, -20);
    const fountainRadius = 26.0;

    // Plaza paving polygon around fountain
    _draw3DQuad(
      canvas: canvas,
      size: size,
      camera: camera,
      v0: const Vector3D(-42, 0.22, -60),
      v1: const Vector3D(42, 0.22, -60),
      v2: const Vector3D(42, 0.22, 20),
      v3: const Vector3D(-42, 0.22, 20),
      fillColor: isNightMode ? const Color(0xFF222F3C) : const Color(0xFFE5EAE7),
      strokeColor: walkwayEdgeColor,
      strokeWidth: 0.8,
    );

    // Fountain basin stone rim
    _draw3DOval(
      canvas: canvas,
      size: size,
      camera: camera,
      center: fountainCenter,
      radiusX: fountainRadius,
      radiusZ: fountainRadius * 0.8,
      fillColor: isNightMode ? const Color(0xFF2A3845) : const Color(0xFFB0BEC5),
      strokeColor: isNightMode ? const Color(0xFF3F5263) : const Color(0xFF78909C),
      strokeWidth: 1.2,
    );

    // Fountain water surface with subtle ripple reflection
    final waterColor = isNightMode ? const Color(0xFF00796B) : const Color(0xFF26C6DA);
    _draw3DOval(
      canvas: canvas,
      size: size,
      camera: camera,
      center: Vector3D(fountainCenter.x, 0.35, fountainCenter.z),
      radiusX: fountainRadius - 3.5,
      radiusZ: (fountainRadius - 3.5) * 0.8,
      fillColor: waterColor.withValues(alpha: isNightMode ? 0.75 : 0.85),
      strokeColor: Colors.white.withValues(alpha: 0.5),
      strokeWidth: 0.6,
    );

    // Fountain water jet center
    final jetBase = camera.project(Vector3D(fountainCenter.x, 0.4, fountainCenter.z), size);
    final jetTop = camera.project(Vector3D(fountainCenter.x, 6.0, fountainCenter.z), size);
    canvas.drawLine(
      jetBase,
      jetTop,
      Paint()
        ..color = isNightMode
            ? const Color(0xFF80DEEA).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // ----------------------------------------------------
    // E. Parking Bays & Stylized 3D Cars
    // ----------------------------------------------------
    _renderParkingAndCars(
      canvas: canvas,
      size: size,
      camera: camera,
      isNightMode: isNightMode,
    );

    // ----------------------------------------------------
    // F. Architectural 3D Landscaping (Trees & Shrubbery)
    // ----------------------------------------------------
    _render3DTrees(
      canvas: canvas,
      size: size,
      camera: camera,
      isNightMode: isNightMode,
    );

    // ----------------------------------------------------
    // G. Street Light Poles & Night Glow Cones
    // ----------------------------------------------------
    _renderStreetLamps(
      canvas: canvas,
      size: size,
      camera: camera,
      isNightMode: isNightMode,
    );

    // ----------------------------------------------------
    // H. Geolocation Coordinates Datum on Ground
    // ----------------------------------------------------
    _renderGeoLocationDatum(
      canvas: canvas,
      size: size,
      camera: camera,
      isNightMode: isNightMode,
      complex: complex,
    );
  }

  /// Parking bays with 3D architectural low-poly cars
  static void _renderParkingAndCars({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required bool isNightMode,
  }) {
    // 4 parking bays along the south side road
    final bayPaint = Paint()
      ..color = Colors.white.withValues(alpha: isNightMode ? 0.35 : 0.65)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 4; i++) {
      final bx = 45.0 + (i * 18.0);
      final b0 = camera.project(Vector3D(bx, 0.2, 155), size);
      final b1 = camera.project(Vector3D(bx, 0.2, 140), size);
      final b2 = camera.project(Vector3D(bx + 14, 0.2, 140), size);
      final b3 = camera.project(Vector3D(bx + 14, 0.2, 155), size);
      canvas.drawLine(b0, b1, bayPaint);
      canvas.drawLine(b1, b2, bayPaint);
      canvas.drawLine(b2, b3, bayPaint);
    }

    // Car 1: Pearl White Executive Sedan
    _drawStylizedCar(
      canvas: canvas,
      size: size,
      camera: camera,
      center: const Vector3D(52, 0.2, 147.5),
      bodyColor: isNightMode ? const Color(0xFFDCE2E6) : const Color(0xFFF0F4F8),
      cabinColor: const Color(0xFF263238),
      isNightMode: isNightMode,
    );

    // Car 2: Metallic Sapphire SUV
    _drawStylizedCar(
      canvas: canvas,
      size: size,
      camera: camera,
      center: const Vector3D(70, 0.2, 147.5),
      bodyColor: const Color(0xFF1E3A8A),
      cabinColor: const Color(0xFF1E293B),
      isNightMode: isNightMode,
    );

    // Car 3: Graphite Grey Sedan
    _drawStylizedCar(
      canvas: canvas,
      size: size,
      camera: camera,
      center: const Vector3D(88, 0.2, 147.5),
      bodyColor: const Color(0xFF475569),
      cabinColor: const Color(0xFF0F172A),
      isNightMode: isNightMode,
    );
  }

  /// Draws a stylized architectural low-poly car
  static void _drawStylizedCar({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required Vector3D center,
    required Color bodyColor,
    required Color cabinColor,
    required bool isNightMode,
  }) {
    const carW = 10.5; // along X
    const carD = 18.0; // along Z
    const carH = 3.8;

    // Ground shadow
    final shadowCenter = camera.project(Vector3D(center.x, 0.22, center.z), size);
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: carW * camera.zoom * 1.3,
        height: carD * camera.zoom * 0.6,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // Lower body box
    _draw3DQuad(
      canvas: canvas,
      size: size,
      camera: camera,
      v0: Vector3D(center.x - carW / 2, carH * 0.55, center.z - carD / 2),
      v1: Vector3D(center.x + carW / 2, carH * 0.55, center.z - carD / 2),
      v2: Vector3D(center.x + carW / 2, carH * 0.55, center.z + carD / 2),
      v3: Vector3D(center.x - carW / 2, carH * 0.55, center.z + carD / 2),
      fillColor: bodyColor,
      strokeColor: Colors.black.withValues(alpha: 0.3),
      strokeWidth: 0.5,
    );

    // Cabin roof
    const cabW = 8.5;
    const cabD = 10.0;
    _draw3DQuad(
      canvas: canvas,
      size: size,
      camera: camera,
      v0: Vector3D(center.x - cabW / 2, carH, center.z - cabD / 2 + 1),
      v1: Vector3D(center.x + cabW / 2, carH, center.z - cabD / 2 + 1),
      v2: Vector3D(center.x + cabW / 2, carH, center.z + cabD / 2 + 1),
      v3: Vector3D(center.x - cabW / 2, carH, center.z + cabD / 2 + 1),
      fillColor: cabinColor,
      strokeColor: Colors.black.withValues(alpha: 0.4),
      strokeWidth: 0.5,
    );

    // Night headlights projection
    if (isNightMode) {
      final hL = camera.project(Vector3D(center.x - 3.5, 1.2, center.z - carD / 2), size);
      final hR = camera.project(Vector3D(center.x + 3.5, 1.2, center.z - carD / 2), size);
      final lightPaint = Paint()
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(hL, 1.8, lightPaint);
      canvas.drawCircle(hR, 1.8, lightPaint);
    }
  }

  /// Realistic 3D Trees with volumetric canopies and ground shadows
  static void _render3DTrees({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required bool isNightMode,
  }) {
    // Array of tree coordinates (cypress/thujas & rounded park trees)
    final trees = [
      // Courtyard trees around fountain
      const Vector3D(-35, 0, -45),
      const Vector3D(-35, 0, 5),
      const Vector3D(35, 0, -45),
      const Vector3D(35, 0, 5),
      // Along perimeter walkway & driveways
      const Vector3D(-140, 0, 85),
      const Vector3D(-95, 0, 85),
      const Vector3D(95, 0, 85),
      const Vector3D(140, 0, 85),
      // North landscaped lawn
      const Vector3D(-140, 0, -130),
      const Vector3D(-70, 0, -130),
      const Vector3D(0, 0, -130),
      const Vector3D(70, 0, -130),
      const Vector3D(140, 0, -130),
    ];

    // Colors
    final trunkColor = isNightMode ? const Color(0xFF261D17) : const Color(0xFF5D4037);
    final folTop = isNightMode ? const Color(0xFF13361E) : const Color(0xFF388E3C);
    final folMid = isNightMode ? const Color(0xFF0C2413) : const Color(0xFF2E7D32);

    for (int i = 0; i < trees.length; i++) {
      final t = trees[i];
      final isConifer = i % 2 == 0;
      final treeHeight = isConifer ? 18.0 : 14.0;
      final foliageRadius = isConifer ? 6.5 : 9.0;

      // 1. Ground contact shadow
      final shadowPos = camera.project(Vector3D(t.x, 0.2, t.z), size);
      canvas.drawOval(
        Rect.fromCenter(
          center: shadowPos,
          width: foliageRadius * camera.zoom * 1.5,
          height: foliageRadius * camera.zoom * 0.7,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: isNightMode ? 0.45 : 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // 2. Trunk (vertical cylinder / line)
      final trunkBase = camera.project(Vector3D(t.x, 0, t.z), size);
      final trunkTop = camera.project(Vector3D(t.x, treeHeight * 0.4, t.z), size);
      canvas.drawLine(
        trunkBase,
        trunkTop,
        Paint()
          ..color = trunkColor
          ..strokeWidth = 2.2 * camera.zoom
          ..strokeCap = StrokeCap.round,
      );

      // 3. Volumetric Foliage (layered spheres / cones)
      if (isConifer) {
        // Conical thuja / cypress: 3 stacked tiers
        for (int tier = 0; tier < 3; tier++) {
          final tierY = (treeHeight * 0.3) + (tier * 4.5);
          final tierR = foliageRadius * (1.0 - (tier * 0.25));
          final center = camera.project(Vector3D(t.x, tierY, t.z), size);

          canvas.drawCircle(
            center,
            tierR * camera.zoom,
            Paint()
              ..color = (tier == 2 ? folTop : folMid)
              ..style = PaintingStyle.fill,
          );
        }
      } else {
        // Rounded park tree: 2 soft overlapping canopies
        final cBottom = camera.project(Vector3D(t.x, treeHeight * 0.6, t.z), size);
        final cTop = camera.project(Vector3D(t.x, treeHeight * 0.85, t.z), size);

        canvas.drawCircle(cBottom, foliageRadius * camera.zoom, Paint()..color = folMid);
        canvas.drawCircle(cTop, (foliageRadius * 0.85) * camera.zoom, Paint()..color = folTop);
      }
    }
  }

  /// Streetlamps with radial glow pools on the ground
  static void _renderStreetLamps({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required bool isNightMode,
  }) {
    final lamps = [
      const Vector3D(-120, 0, 42),
      const Vector3D(-40, 0, 42),
      const Vector3D(40, 0, 42),
      const Vector3D(120, 0, 42),
      const Vector3D(-16, 0, 115),
      const Vector3D(16, 0, 115),
    ];

    const lampH = 14.0;
    final poleColor = isNightMode ? const Color(0xFF384654) : const Color(0xFF607D8B);

    for (final lamp in lamps) {
      // In night mode: draw radial light cone on the ground first
      if (isNightMode) {
        final groundPt = camera.project(Vector3D(lamp.x, 0.25, lamp.z), size);
        final lightRadius = 26.0 * camera.zoom;

        final lightPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE082).withValues(alpha: 0.38),
              const Color(0xFFFFD54F).withValues(alpha: 0.12),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: groundPt, radius: lightRadius));

        canvas.drawOval(
          Rect.fromCenter(
            center: groundPt,
            width: lightRadius * 1.8,
            height: lightRadius * 0.9,
          ),
          lightPaint,
        );
      }

      // Vertical pole
      final pBase = camera.project(Vector3D(lamp.x, 0, lamp.z), size);
      final pTop = camera.project(Vector3D(lamp.x, lampH, lamp.z), size);
      canvas.drawLine(
        pBase,
        pTop,
        Paint()..color = poleColor..strokeWidth = 1.4 * camera.zoom,
      );

      // Horizontal arm & luminaire
      final pArm = camera.project(Vector3D(lamp.x + 2.5, lampH, lamp.z), size);
      canvas.drawLine(
        pTop,
        pArm,
        Paint()..color = poleColor..strokeWidth = 1.2 * camera.zoom,
      );

      // Light head glow
      if (isNightMode) {
        canvas.drawCircle(
          pArm,
          2.5,
          Paint()
            ..color = const Color(0xFFFFF9C4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
        );
      }
    }
  }

  /// Real Geolocation Coordinates datum inscribed on the architectural site border
  static void _renderGeoLocationDatum({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required bool isNightMode,
    ResidentialComplex? complex,
  }) {
    final lat = complex?.lat ?? 41.311081;
    final lng = complex?.lng ?? 69.240562;

    // Site Datum point at South-East corner
    const datumPoint = Vector3D(180, 0.2, 180);
    final datumScreen = camera.project(datumPoint, size);

    // Crosshair target
    final crossPaint = Paint()
      ..color = isNightMode
          ? const Color(0xFF2979FF).withValues(alpha: 0.8)
          : const Color(0xFF007AFF).withValues(alpha: 0.85)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(datumScreen.dx - 8, datumScreen.dy),
      Offset(datumScreen.dx + 8, datumScreen.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(datumScreen.dx, datumScreen.dy - 8),
      Offset(datumScreen.dx, datumScreen.dy + 8),
      crossPaint,
    );
    canvas.drawCircle(
      datumScreen,
      4.0,
      Paint()
        ..color = crossPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Coordinate text
    final textSpan = TextSpan(
      text: '📍 ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E\nМАСШТАБ 1:500',
      style: TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isNightMode
            ? Colors.white.withValues(alpha: 0.75)
            : const Color(0xFF2C3E50).withValues(alpha: 0.85),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(datumScreen.dx + 12, datumScreen.dy - 12));
  }

  /// Helper to project and draw a 3D Quad
  static void _draw3DQuad({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required Vector3D v0,
    required Vector3D v1,
    required Vector3D v2,
    required Vector3D v3,
    required Color fillColor,
    Color? strokeColor,
    double strokeWidth = 1.0,
  }) {
    final p0 = camera.project(v0, size);
    final p1 = camera.project(v1, size);
    final p2 = camera.project(v2, size);
    final p3 = camera.project(v3, size);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);

    if (strokeColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }
  }

  /// Helper to project and draw an ellipse on the 3D ground plane
  static void _draw3DOval({
    required Canvas canvas,
    required Size size,
    required Camera3D camera,
    required Vector3D center,
    required double radiusX,
    required double radiusZ,
    required Color fillColor,
    Color? strokeColor,
    double strokeWidth = 1.0,
  }) {
    const segments = 16;
    final path = Path();
    for (int i = 0; i < segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final pt = Vector3D(
        center.x + math.cos(angle) * radiusX,
        center.y,
        center.z + math.sin(angle) * radiusZ,
      );
      final sp = camera.project(pt, size);
      if (i == 0) {
        path.moveTo(sp.dx, sp.dy);
      } else {
        path.lineTo(sp.dx, sp.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);

    if (strokeColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }
  }
}
