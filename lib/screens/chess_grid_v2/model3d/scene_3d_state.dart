import 'package:flutter/painting.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';

/// The 4-step spatial hierarchy of the 3D Real Estate Chessboard
enum Scene3DLevel {
  /// Level 1: Full Complex overview (Media 1)
  /// All buildings situated on a landscaped grid with floating metrics badges
  complex,

  /// Level 2: Selected Building with entrance/section breakdown (Media 2)
  /// Close-up view of the selected building with neon highlight on active entrance
  building,

  /// Level 3: Vertical Section Floors Cutout (Media 3)
  /// Multi-storey cut showing apartments on the facade with status colors & floor selector
  section,

  /// Level 4: 3D Floor Plan (Media 4)
  /// Isometric horizontal slab with volumetric apartment blocks and unit numbers
  floor,
}

class Scene3DState {
  final Scene3DLevel level;
  final Building? selectedBuilding;
  final int selectedEntrance;
  final int selectedFloor;
  final Apartment? selectedApartment;
  final Camera3D camera;
  final bool isAutoRotating;

  const Scene3DState({
    this.level = Scene3DLevel.complex,
    this.selectedBuilding,
    this.selectedEntrance = 1,
    this.selectedFloor = 7,
    this.selectedApartment,
    this.camera = const Camera3D(
      yaw: 0.58,
      pitch: 0.45,
      zoom: 1.05,
      target: Vector3D(0, 55, 0),
    ),
    this.isAutoRotating = false,
  });

  /// Default optimal camera configuration tailored for each level
  static Camera3D defaultCameraForLevel(Scene3DLevel level) {
    switch (level) {
      case Scene3DLevel.complex:
        return const Camera3D(
          yaw: 0.58,
          pitch: 0.45,
          zoom: 1.05,
          target: Vector3D(0, 55, 0),
        );
      case Scene3DLevel.building:
        return const Camera3D(
          yaw: 0.40,
          pitch: 0.38,
          zoom: 1.45,
          target: Vector3D(0, 70, 0),
        );
      case Scene3DLevel.section:
        return const Camera3D(
          yaw: 0.35,
          pitch: 0.32,
          zoom: 1.60,
          target: Vector3D(0, 85, 0),
        );
      case Scene3DLevel.floor:
        return const Camera3D(
          yaw: 0.58,
          pitch: 0.65,
          zoom: 1.65,
          target: Vector3D(0, 15, 0),
          panOffset: Offset(0, -120),
        );
    }
  }

  Scene3DState copyWith({
    Scene3DLevel? level,
    Building? selectedBuilding,
    int? selectedEntrance,
    int? selectedFloor,
    Apartment? selectedApartment,
    Camera3D? camera,
    bool? isAutoRotating,
    bool clearApartment = false,
  }) {
    return Scene3DState(
      level: level ?? this.level,
      selectedBuilding: selectedBuilding ?? this.selectedBuilding,
      selectedEntrance: selectedEntrance ?? this.selectedEntrance,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      selectedApartment: clearApartment
          ? null
          : (selectedApartment ?? this.selectedApartment),
      camera: camera ?? this.camera,
      isAutoRotating: isAutoRotating ?? this.isAutoRotating,
    );
  }
}

