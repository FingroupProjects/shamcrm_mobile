import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_detail_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/building_3d_painter.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/complex_3d_painter.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/floor_plan_3d_painter.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/ground_grid_painter.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/painters/section_3d_painter.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/scene_3d_state.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/vector_3d.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/widgets/floating_3d_badge.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/widgets/scene_3d_breadcrumbs.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/widgets/scene_3d_hud_controls.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/widgets/apartment_quick_dock_v2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Full Interactive 3D Real Estate Chessboard Visualizer (Media 1, 2, 3, 4)
class ChessGrid3DView extends StatefulWidget {
  final ResidentialComplex complex;
  final VoidCallback? onSwitchTo2D;

  const ChessGrid3DView({
    super.key,
    required this.complex,
    this.onSwitchTo2D,
  });

  @override
  State<ChessGrid3DView> createState() => _ChessGrid3DViewState();
}

class _ChessGrid3DViewState extends State<ChessGrid3DView>
    with TickerProviderStateMixin {
  late final ChessGridController _controller;
  late Scene3DState _state;

  late final AnimationController _animController;
  Camera3D? _animStartCamera;
  Camera3D? _animTargetCamera;

  Ticker? _rotationTicker;
  double _lastScale = 1.0;
  Offset _lastFocalPoint = Offset.zero;

  // Cached render info from custom painters for overlay interaction
  List<BuildingRenderInfo> _buildingInfos = [];
  List<EntranceRenderInfo> _entranceInfos = [];
  List<FloorRenderInfo> _floorInfos = [];
  List<Apartment3DRenderInfo> _apartmentInfos = [];

  @override
  void initState() {
    super.initState();
    _controller = ChessGridController.instance;

    final initialBuilding = widget.complex.buildings.isNotEmpty
        ? widget.complex.buildings.first
        : null;

    _state = Scene3DState(
      level: Scene3DLevel.complex,
      selectedBuilding: initialBuilding,
      selectedEntrance: 1,
      selectedFloor: initialBuilding != null ? (initialBuilding.floorCount >= 7 ? 7 : initialBuilding.floorCount) : 7,
      camera: Scene3DState.defaultCameraForLevel(Scene3DLevel.complex),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(_onCameraAnimTick);

    _rotationTicker = createTicker((elapsed) {
      if (_state.isAutoRotating && !_animController.isAnimating) {
        setState(() {
          _state = _state.copyWith(
            camera: _state.camera.copyWith(
              yaw: _state.camera.yaw + 0.006,
            ),
          );
        });
      }
    });
    _rotationTicker?.start();
  }

  void _onCameraAnimTick() {
    if (_animStartCamera == null || _animTargetCamera == null) return;
    final t = Curves.easeInOutCubic.transform(_animController.value);

    final newYaw = _animStartCamera!.yaw + (_animTargetCamera!.yaw - _animStartCamera!.yaw) * t;
    final newPitch = _animStartCamera!.pitch + (_animTargetCamera!.pitch - _animStartCamera!.pitch) * t;
    final newZoom = _animStartCamera!.zoom + (_animTargetCamera!.zoom - _animStartCamera!.zoom) * t;

    setState(() {
      _state = _state.copyWith(
        camera: _state.camera.copyWith(
          yaw: newYaw,
          pitch: newPitch,
          zoom: newZoom,
        ),
      );
    });
  }

  void _animateCameraTo(Camera3D target) {
    _animStartCamera = _state.camera;
    _animTargetCamera = target;
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _rotationTicker?.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _navigateLevel(Scene3DLevel newLevel) {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = _state.copyWith(
        level: newLevel,
        isAutoRotating: false,
      );
    });
    _animateCameraTo(Scene3DState.defaultCameraForLevel(newLevel));
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    switch (_state.level) {
      case Scene3DLevel.complex:
        widget.onSwitchTo2D?.call();
        break;
      case Scene3DLevel.building:
        _navigateLevel(Scene3DLevel.complex);
        break;
      case Scene3DLevel.section:
        _navigateLevel(Scene3DLevel.building);
        break;
      case Scene3DLevel.floor:
        _navigateLevel(Scene3DLevel.section);
        break;
    }
  }

  void _onNextLevel() {
    switch (_state.level) {
      case Scene3DLevel.complex:
        _navigateLevel(Scene3DLevel.building);
        break;
      case Scene3DLevel.building:
        _navigateLevel(Scene3DLevel.section);
        break;
      case Scene3DLevel.section:
        _navigateLevel(Scene3DLevel.floor);
        break;
      case Scene3DLevel.floor:
        break;
    }
  }

  void _onResetCamera() {
    HapticFeedback.selectionClick();
    _animateCameraTo(Scene3DState.defaultCameraForLevel(_state.level));
  }

  void _onToggleAutoRotate() {
    HapticFeedback.selectionClick();
    setState(() {
      _state = _state.copyWith(isAutoRotating: !_state.isAutoRotating);
    });
  }

  // Gesture handling
  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = 1.0;
    _lastFocalPoint = details.focalPoint;
    if (_state.isAutoRotating) {
      setState(() => _state = _state.copyWith(isAutoRotating: false));
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final delta = details.focalPoint - _lastFocalPoint;
    _lastFocalPoint = details.focalPoint;

    // Single finger drag -> Orbit rotation (Yaw & Pitch)
    if (details.pointerCount == 1) {
      const sensitivity = 0.007;
      final newYaw = _state.camera.yaw - (delta.dx * sensitivity);
      final newPitch = _state.camera.pitch + (delta.dy * sensitivity);

      setState(() {
        _state = _state.copyWith(
          camera: _state.camera.copyWith(
            yaw: newYaw,
            pitch: newPitch,
          ),
        );
      });
    } else if (details.pointerCount >= 2) {
      // Two finger pinch -> Zoom
      final scaleFactor = details.scale / _lastScale;
      _lastScale = details.scale;

      final newZoom = _state.camera.zoom * scaleFactor;
      setState(() {
        _state = _state.copyWith(
          camera: _state.camera.copyWith(zoom: newZoom),
        );
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final tapPos = details.localPosition;

    // Hit-testing based on level
    switch (_state.level) {
      case Scene3DLevel.complex:
        for (final info in _buildingInfos) {
          if (info.hitBounds.contains(tapPos)) {
            HapticFeedback.mediumImpact();
            setState(() {
              _state = _state.copyWith(selectedBuilding: info.building);
            });
            _navigateLevel(Scene3DLevel.building);
            return;
          }
        }
        break;

      case Scene3DLevel.building:
        for (final info in _entranceInfos) {
          if (info.hitBounds.contains(tapPos)) {
            HapticFeedback.mediumImpact();
            setState(() {
              _state = _state.copyWith(selectedEntrance: info.entranceNumber);
            });
            _navigateLevel(Scene3DLevel.section);
            return;
          }
        }
        break;

      case Scene3DLevel.section:
        for (final info in _floorInfos) {
          if (info.hitBounds.contains(tapPos)) {
            HapticFeedback.mediumImpact();
            setState(() {
              _state = _state.copyWith(selectedFloor: info.floorNumber);
            });
            _navigateLevel(Scene3DLevel.floor);
            return;
          }
        }
        break;

      case Scene3DLevel.floor:
        for (final info in _apartmentInfos) {
          if (info.hitBounds.contains(tapPos)) {
            HapticFeedback.mediumImpact();
            setState(() {
              _state = _state.copyWith(selectedApartment: info.apartment);
            });
            return;
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allApts = _controller.getApartmentsForComplex(widget.complex.id);
    final building = _state.selectedBuilding ??
        (widget.complex.buildings.isNotEmpty ? widget.complex.buildings.first : null);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Interactive 3D Canvas
        GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onDoubleTap: _onResetCamera,
          onTapUp: _handleTapUp,
          child: CustomPaint(
            painter: _Master3DScenePainter(
              state: _state,
              complex: widget.complex,
              allApartments: allApts,
              building: building,
              onRenderFinished: (bInfos, eInfos, fInfos, aInfos) {
                _buildingInfos = bInfos;
                _entranceInfos = eInfos;
                _floorInfos = fInfos;
                _apartmentInfos = aInfos;
              },
            ),
            size: Size.infinite,
          ),
        ),

        // 2. Interactive 3D Overlay Badges (Media 1, 2, 3, 4)
        ..._buildInteractiveFloatingBadges(),

        // 3. Top Breadcrumb Bar (Media 1, 2, 3, 4)
        Positioned(
          top: 10,
          left: 14,
          right: 14,
          child: Center(
            child: Scene3DBreadcrumbs(
              state: _state,
              complex: widget.complex,
              onBack: _navigateBack,
              onSelectLevel: _navigateLevel,
            ),
          ),
        ),

        // 4. Bottom Entrance Strip (Media 2 - "Подъезд 1 · свободно 18 из 36")
        if (_state.level == Scene3DLevel.building)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Center(
              child: _buildMedia2EntranceDock(),
            ),
          ),

        // 5. Right HUD Controls (Camera reset, auto-rotate, next level)
        Positioned(
          right: 16,
          bottom: _state.level == Scene3DLevel.floor && _state.selectedApartment != null
              ? 165
              : 32,
          child: Scene3DHudControls(
            state: _state,
            onResetCamera: _onResetCamera,
            onToggleAutoRotate: _onToggleAutoRotate,
            onNextLevel: _onNextLevel,
          ),
        ),

        // 6. Bottom-Left Status Legend
        Positioned(
          left: 16,
          bottom: _state.level == Scene3DLevel.floor && _state.selectedApartment != null
              ? 165
              : 32,
          child: const Scene3DStatusLegend(),
        ),

        // 7. Quick Dock on Apartment Selection (Media 4)
        if (_state.level == Scene3DLevel.floor && _state.selectedApartment != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 4,
            child: ApartmentQuickDockV2(
              apartment: _state.selectedApartment!,
              onClose: () => setState(() => _state = _state.copyWith(clearApartment: true)),
              onOpenDetail: () {
                ApartmentDetailSheet.show(
                  context: context,
                  apartment: _state.selectedApartment!,
                  onCreateOrder: () {
                    OrderCreateSheet.show(
                      context: context,
                      apartment: _state.selectedApartment!,
                    );
                  },
                  onToggleReserve: () {
                    _controller.toggleApartmentReserve(_state.selectedApartment!);
                    setState(() {});
                  },
                );
              },
              onToggleReserve: () {
                _controller.toggleApartmentReserve(_state.selectedApartment!);
                setState(() {});
              },
              onCreateOrder: () {
                OrderCreateSheet.show(
                  context: context,
                  apartment: _state.selectedApartment!,
                );
              },
            ),
          ),
      ],
    );
  }

  /// Media 2 Bottom Badge: "Подъезд 1 · свободно 18 из 36"
  Widget _buildMedia2EntranceDock() {
    final building = _state.selectedBuilding;
    if (building == null) return const SizedBox.shrink();

    final allApts = _controller.getApartmentsForComplex(widget.complex.id);
    final entApts = allApts
        .where((a) => a.buildingKey == building.key && a.entrance == _state.selectedEntrance)
        .toList();

    final total = entApts.isNotEmpty ? entApts.length : (building.floorCount * building.apartsPerFloor);
    final free = entApts.isNotEmpty
        ? entApts.where((a) => a.status == ApartmentStatus.available).length
        : (total * 0.5).round();

    return GestureDetector(
      onTap: () => _navigateLevel(Scene3DLevel.section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2830).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2979FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Подъезд ${_state.selectedEntrance} · свободно $free из $total',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2979FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Этажи',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive HTML-like floating labels positioned precisely on 3D coordinates
  List<Widget> _buildInteractiveFloatingBadges() {
    final widgets = <Widget>[];

    switch (_state.level) {
      case Scene3DLevel.complex:
        for (final info in _buildingInfos) {
          final pos = info.badgePosition;
          widgets.add(
            Positioned(
              left: pos.dx - 60,
              top: pos.dy - 40,
              child: FloatingBuildingBadge(
                title: info.building.name,
                subtitle: 'свободно ${info.freeApts} из ${info.totalApts}',
                isSelected: _state.selectedBuilding?.key == info.building.key,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _state = _state.copyWith(selectedBuilding: info.building));
                  _navigateLevel(Scene3DLevel.building);
                },
              ),
            ),
          );
        }
        break;

      case Scene3DLevel.building:
        for (final info in _entranceInfos) {
          final pos = info.badgePosition;
          widgets.add(
            Positioned(
              left: pos.dx - 55,
              top: pos.dy - 40,
              child: FloatingEntranceBadge(
                entranceNumber: info.entranceNumber,
                subtitle: 'свободно ${info.freeApts} из ${info.totalApts}',
                isSelected: _state.selectedEntrance == info.entranceNumber,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _state = _state.copyWith(selectedEntrance: info.entranceNumber));
                  _navigateLevel(Scene3DLevel.section);
                },
              ),
            ),
          );
        }
        break;

      case Scene3DLevel.section:
        for (final info in _floorInfos) {
          final pos = info.badgePosition;
          widgets.add(
            Positioned(
              left: pos.dx - 13,
              top: pos.dy - 11,
              child: FloatingFloorBadge(
                floorNumber: info.floorNumber,
                isSelected: _state.selectedFloor == info.floorNumber,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _state = _state.copyWith(selectedFloor: info.floorNumber));
                  _navigateLevel(Scene3DLevel.floor);
                },
              ),
            ),
          );
        }
        break;

      case Scene3DLevel.floor:
        for (final info in _apartmentInfos) {
          final pos = info.badgePosition;
          widgets.add(
            Positioned(
              left: pos.dx - 32,
              top: pos.dy - 12,
              child: FloatingApartmentUnitBadge(
                number: info.apartment.number,
                isSelected: info.isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _state = _state.copyWith(selectedApartment: info.apartment));
                },
              ),
            ),
          );
        }
        break;
    }

    return widgets;
  }
}

/// Master 3D Scene Painter routing to specific level renderer
class _Master3DScenePainter extends CustomPainter {
  final Scene3DState state;
  final ResidentialComplex complex;
  final List<Apartment> allApartments;
  final Building? building;
  final Function(
    List<BuildingRenderInfo>,
    List<EntranceRenderInfo>,
    List<FloorRenderInfo>,
    List<Apartment3DRenderInfo>,
  ) onRenderFinished;

  _Master3DScenePainter({
    required this.state,
    required this.complex,
    required this.allApartments,
    required this.building,
    required this.onRenderFinished,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Render Ground Plane & Atmospheric Grid
    GroundGridPainter.render(
      canvas: canvas,
      size: size,
      camera: state.camera,
    );

    var bInfos = <BuildingRenderInfo>[];
    var eInfos = <EntranceRenderInfo>[];
    var fInfos = <FloorRenderInfo>[];
    var aInfos = <Apartment3DRenderInfo>[];

    // 2. Render 3D Model by active level
    switch (state.level) {
      case Scene3DLevel.complex:
        bInfos = Complex3DPainter.render(
          canvas: canvas,
          size: size,
          camera: state.camera,
          complex: complex,
          allApartments: allApartments,
          highlightedBuilding: state.selectedBuilding,
        );
        break;

      case Scene3DLevel.building:
        if (building != null) {
          eInfos = Building3DPainter.render(
            canvas: canvas,
            size: size,
            camera: state.camera,
            building: building!,
            allApartments: allApartments,
            selectedEntrance: state.selectedEntrance,
          );
        }
        break;

      case Scene3DLevel.section:
        if (building != null) {
          fInfos = Section3DPainter.render(
            canvas: canvas,
            size: size,
            camera: state.camera,
            building: building!,
            entrance: state.selectedEntrance,
            selectedFloor: state.selectedFloor,
            allApartments: allApartments,
          );
        }
        break;

      case Scene3DLevel.floor:
        if (building != null) {
          final floorApts = allApartments
              .where((a) =>
                  a.buildingKey == building!.key &&
                  a.entrance == state.selectedEntrance &&
                  a.floor == state.selectedFloor)
              .toList();

          aInfos = FloorPlan3DPainter.render(
            canvas: canvas,
            size: size,
            camera: state.camera,
            building: building!,
            entrance: state.selectedEntrance,
            floor: state.selectedFloor,
            floorApartments: floorApts,
            selectedApartment: state.selectedApartment,
          );
        }
        break;
    }

    onRenderFinished(bInfos, eInfos, fInfos, aInfos);
  }

  @override
  bool shouldRepaint(covariant _Master3DScenePainter oldDelegate) {
    return oldDelegate.state.camera.yaw != state.camera.yaw ||
        oldDelegate.state.camera.pitch != state.camera.pitch ||
        oldDelegate.state.camera.zoom != state.camera.zoom ||
        oldDelegate.state.level != state.level ||
        oldDelegate.state.selectedBuilding?.key != state.selectedBuilding?.key ||
        oldDelegate.state.selectedEntrance != state.selectedEntrance ||
        oldDelegate.state.selectedFloor != state.selectedFloor ||
        oldDelegate.state.selectedApartment?.id != state.selectedApartment?.id;
  }
}
