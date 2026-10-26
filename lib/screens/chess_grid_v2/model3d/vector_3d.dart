import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D Vector for real-time spatial calculations in Flutter Canvas.
class Vector3D {
  final double x;
  final double y;
  final double z;

  const Vector3D(this.x, this.y, this.z);

  static const zero = Vector3D(0, 0, 0);

  Vector3D operator +(Vector3D v) => Vector3D(x + v.x, y + v.y, z + v.z);
  Vector3D operator -(Vector3D v) => Vector3D(x - v.x, y - v.y, z - v.z);
  Vector3D operator *(double s) => Vector3D(x * s, y * s, z * s);
  Vector3D operator /(double s) => Vector3D(x / s, y / s, z / s);

  double dot(Vector3D v) => x * v.x + y * v.y + z * v.z;

  Vector3D cross(Vector3D v) {
    return Vector3D(
      y * v.z - z * v.y,
      z * v.x - x * v.z,
      x * v.y - y * v.x,
    );
  }

  double get length => math.sqrt(x * x + y * y + z * z);

  Vector3D normalized() {
    final len = length;
    if (len < 1e-6) return zero;
    return this / len;
  }

  @override
  String toString() => 'Vector3D(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

/// 3D Orbit Camera with Isometric / Subtle-Perspective projection.
class Camera3D {
  final double yaw; // Horizontal rotation in radians
  final double pitch; // Vertical tilt in radians (clamped to prevent upside-down)
  final double zoom; // Scale multiplier
  final Vector3D target; // Focal point in world space
  final Offset panOffset; // Screen pan offset
  final double fov; // Field of view factor (0 = orthographic/isometric, >0 = perspective)

  const Camera3D({
    this.yaw = 0.65,
    this.pitch = 0.55,
    this.zoom = 1.0,
    this.target = Vector3D.zero,
    this.panOffset = Offset.zero,
    this.fov = 0.0012,
  });

  Camera3D copyWith({
    double? yaw,
    double? pitch,
    double? zoom,
    Vector3D? target,
    Offset? panOffset,
    double? fov,
  }) {
    return Camera3D(
      yaw: yaw ?? this.yaw,
      pitch: pitch != null
          ? pitch.clamp(0.12, math.pi / 2 - 0.05)
          : this.pitch,
      zoom: zoom != null ? zoom.clamp(0.35, 4.0) : this.zoom,
      target: target ?? this.target,
      panOffset: panOffset ?? this.panOffset,
      fov: fov ?? this.fov,
    );
  }

  /// Unit vector pointing from target towards the camera viewpoint.
  Vector3D get cameraDir => Vector3D(
        math.sin(yaw) * math.cos(pitch),
        math.sin(pitch),
        math.cos(yaw) * math.cos(pitch),
      );

  /// Camera right direction on the 2D projection screen.
  Vector3D get rightDir => Vector3D(
        math.cos(yaw),
        0.0,
        -math.sin(yaw),
      );

  /// Camera up direction on the 2D projection screen (orthonormal to cameraDir and rightDir).
  Vector3D get upDir => Vector3D(
        -math.sin(yaw) * math.sin(pitch),
        math.cos(pitch),
        -math.cos(yaw) * math.sin(pitch),
      );

  /// Transforms a world-space Vector3D into camera view-space (camX, camY, camZ).
  /// - camX: distance to the right on screen.
  /// - camY: distance upwards on screen.
  /// - camZ: distance away from camera into the scene (larger = further away).
  Vector3D transformToCamera(Vector3D worldPoint) {
    final rx = worldPoint.x - target.x;
    final ry = worldPoint.y - target.y;
    final rz = worldPoint.z - target.z;

    final camX = rx * rightDir.x + ry * rightDir.y + rz * rightDir.z;
    final camY = rx * upDir.x + ry * upDir.y + rz * upDir.z;
    // Points closer to camera have positive projection along cameraDir,
    // so depth away from camera is -projection.
    final camZ = -(rx * cameraDir.x + ry * cameraDir.y + rz * cameraDir.z);

    return Vector3D(camX, camY, camZ);
  }

  /// Projects a 3D world-space coordinate to 2D screen coordinates.
  Offset project(Vector3D worldPoint, Size screenSize) {
    final cam = transformToCamera(worldPoint);

    // Perspective distortion factor (subtle perspective for realistic architectural look)
    // Positive cam.z is further away from the camera.
    final double perspectiveFactor = 1.0 / (1.0 + (cam.z * fov).clamp(-0.4, 2.0));
    final effectiveZoom = zoom * perspectiveFactor;

    final screenX = (screenSize.width / 2) + (cam.x * effectiveZoom) + panOffset.dx;
    // In 2D canvas, Y increases downwards, so we subtract cam.y
    final screenY = (screenSize.height / 2) - (cam.y * effectiveZoom) + panOffset.dy;

    return Offset(screenX, screenY);
  }

  /// Calculates depth (distance away from camera) for Z-sorting polygons.
  /// Larger value = further away (drawn earlier).
  double depthOf(Vector3D worldPoint) {
    return transformToCamera(worldPoint).z;
  }
}

