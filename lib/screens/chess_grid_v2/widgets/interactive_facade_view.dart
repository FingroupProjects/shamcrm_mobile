import 'dart:io';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/controllers/chess_grid_v2_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Interactive Building Facade (Интерактивный фасад по фото / схеме здания).
/// Slices any uploaded photo or blueprint into interactive floor bands
/// based on the building's floor count and entrance count.
class InteractiveFacadeView extends StatefulWidget {
  final Building building;
  final List<Apartment> apartments;
  final void Function(int floor, int entrance)? onSelectFloor;
  final void Function(Apartment apt)? onSelectApartment;
  final VoidCallback? onSwitchToMatrix;

  const InteractiveFacadeView({
    super.key,
    required this.building,
    required this.apartments,
    this.onSelectFloor,
    this.onSelectApartment,
    this.onSwitchToMatrix,
  });

  @override
  State<InteractiveFacadeView> createState() => _InteractiveFacadeViewState();
}

class _InteractiveFacadeViewState extends State<InteractiveFacadeView> {
  int? _selectedFloor;
  int _selectedEntrance = 0; // 0 = all entrances
  bool _isCalibrating = false;
  double _topOffsetFraction = 0.08; // roof offset (8%)
  double _bottomOffsetFraction = 0.12; // podium offset (12%)
  String? _customImagePath;

  @override
  void initState() {
    super.initState();
    _customImagePath = widget.building.imageUrl;
    // Default selected floor: middle or top floor
    _selectedFloor = widget.building.floorCount > 0 ? widget.building.floorCount : 1;
  }

  @override
  void didUpdateWidget(covariant InteractiveFacadeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.building.imageUrl != widget.building.imageUrl) {
      setState(() {
        _customImagePath = widget.building.imageUrl;
      });
    }
  }

  Future<void> _pickCustomImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _customImagePath = picked.path;
        });
        // Update building in controller
        final updated = widget.building.copyWith(imageUrl: picked.path);
        ChessGridV2Controller.instance.updateBuilding(updated);
        if (mounted) {
          showCustomSnackBar(
            context: context,
            message: 'Фото фасада успешно обновлено',
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Не удалось загрузить фото: $e',
          isSuccess: false,
        );
      }
    }
  }

  void _selectPreset(String assetPath, String shape) {
    setState(() {
      _customImagePath = assetPath;
    });
    final updated = widget.building.copyWith(imageUrl: assetPath, buildingShape: shape);
    ChessGridV2Controller.instance.updateBuilding(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final building = widget.building;
    final floors = building.floorCount > 0 ? building.floorCount : 1;
    final entrances = building.entranceCount > 0 ? building.entranceCount : 1;

    final imagePath = _customImagePath ?? building.effectiveImage;
    final isLocalFile = imagePath.isNotEmpty &&
        !imagePath.startsWith('assets/') &&
        !imagePath.startsWith('http');

    final bApts = widget.apartments.where((a) => a.buildingKey == building.key).toList();

    return Column(
      children: [
        // Top Toolbar: Entrance Chips + Preset / Photo actions + Calibration button
        _buildTopControls(colors, entrances),

        // Main Interactive Facade Container
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1722),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.borderSubtle.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background Photo / Scheme Render
                  Positioned.fill(
                    child: isLocalFile
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackBg(),
                          )
                        : Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackBg(),
                          ),
                  ),

                  // 2. Luxury Dark Vignette Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.70),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Dynamic Floor Bands (Нарезка этажей под количество этажей)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final totalHeight = constraints.maxHeight;
                      final topPx = totalHeight * _topOffsetFraction;
                      final bottomPx = totalHeight * _bottomOffsetFraction;
                      final availableHeight = (totalHeight - topPx - bottomPx).clamp(50.0, totalHeight);
                      final singleFloorHeight = availableHeight / floors;

                      return Stack(
                        children: [
                          // Top Roof Indicator
                          Positioned(
                            top: 8,
                            left: 14,
                            child: _buildRoofBadge(colors, floors),
                          ),

                          // Bottom Podium / Plinth Indicator
                          Positioned(
                            bottom: 8,
                            left: 14,
                            child: _buildPodiumBadge(colors),
                          ),

                          // Sliced Floor Interactive Rows
                          for (int f = floors; f >= 1; f--) ...[
                            _buildFloorBand(
                              floor: f,
                              top: topPx + ((floors - f) * singleFloorHeight),
                              height: singleFloorHeight,
                              buildingApts: bApts,
                              colors: colors,
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  // 4. Calibration Sliders overlay (when active)
                  if (_isCalibrating)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _buildCalibrationCard(colors),
                    ),

                  // 5. Selected Floor Apartment Quick Dock at the bottom
                  if (_selectedFloor != null)
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: _buildSelectedFloorDock(
                        floor: _selectedFloor!,
                        buildingApts: bApts,
                        colors: colors,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBg() {
    return Container(
      color: const Color(0xFF16212D),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Text(
              'Схема фасада здания',
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(dynamic colors, int entrances) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Row(
        children: [
          // Entrance switcher pills
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildEntrancePill(
                    entranceNum: 0,
                    label: 'Все подъезды',
                    isSelected: _selectedEntrance == 0,
                    colors: colors,
                  ),
                  for (int e = 1; e <= entrances; e++) ...[
                    const SizedBox(width: 6),
                    _buildEntrancePill(
                      entranceNum: e,
                      label: 'Подъезд $e',
                      isSelected: _selectedEntrance == e,
                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Preset / Photo Menu Button
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: colors.surfaceElevated.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Выбрать фото/схему фасада',
              padding: EdgeInsets.zero,
              icon: Icon(Icons.add_photo_alternate_rounded, size: 18, color: colors.textPrimary),
              onSelected: (val) {
                if (val == 'gallery') {
                  _pickCustomImage();
                } else if (val == 'cascade') {
                  _selectPreset('assets/images/building_cascade.jpg', 'cascading');
                } else if (val == 'tower') {
                  _selectPreset('assets/images/building_tower.jpg', 'curvedTower');
                } else if (val == 'calibrate') {
                  setState(() => _isCalibrating = !_isCalibrating);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'gallery',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Загрузить своё фото фасада'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'cascade',
                  child: Row(
                    children: [
                      Icon(Icons.holiday_village_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Пресет: Каскадный дом (Фото 1)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tower',
                  child: Row(
                    children: [
                      Icon(Icons.location_city_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Пресет: Овальная башня (Фото 2)'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'calibrate',
                  child: Row(
                    children: [
                      Icon(_isCalibrating ? Icons.check_rounded : Icons.tune_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(_isCalibrating ? 'Скрыть калибровку' : 'Калибровка этажей'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntrancePill({
    required int entranceNum,
    required String label,
    required bool isSelected,
    required dynamic colors,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEntrance = entranceNum;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.buttonPrimaryBg : colors.surfaceElevated.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 11.5,
            color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRoofBadge(dynamic colors, int floors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Кровля · $floors этажей',
        style: const TextStyle(
          fontFamily: 'Golos',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildPodiumBadge(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'Стилобат / 1 этаж (Коммерция)',
        style: TextStyle(
          fontFamily: 'Golos',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildFloorBand({
    required int floor,
    required double top,
    required double height,
    required List<Apartment> buildingApts,
    required dynamic colors,
  }) {
    final isSelected = _selectedFloor == floor;

    // Filter apartments on this floor
    var floorApts = buildingApts.where((a) => a.floor == floor).toList();
    if (_selectedEntrance != 0) {
      floorApts = floorApts.where((a) => a.entrance == _selectedEntrance).toList();
    }

    final total = floorApts.length;
    final available = floorApts.where((a) => a.status == ApartmentStatus.available).length;
    final booked = floorApts.where((a) => a.status == ApartmentStatus.booked).length;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedFloor = floor;
          });
          widget.onSelectFloor?.call(floor, _selectedEntrance);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00D2B4).withValues(alpha: 0.28)
                : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: isSelected
                    ? const Color(0xFF00D2B4)
                    : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 1.6 : 0.6,
              ),
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFF00D2B4)
                    : Colors.transparent,
                width: isSelected ? 1.6 : 0,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Floor Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00D2B4)
                        : Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.25),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    '$floor эт',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ),

                // Right: Mini Stats Pill
                if (total > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E9E63),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$available/$total своб',
                          style: const TextStyle(
                            fontFamily: 'Golos',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (booked > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2A81C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFloorDock({
    required int floor,
    required List<Apartment> buildingApts,
    required dynamic colors,
  }) {
    var floorApts = buildingApts.where((a) => a.floor == floor).toList();
    if (_selectedEntrance != 0) {
      floorApts = floorApts.where((a) => a.entrance == _selectedEntrance).toList();
    }

    final freeCount = floorApts.where((a) => a.status == ApartmentStatus.available).length;
    final minPrice = floorApts.isNotEmpty
        ? floorApts.map((a) => a.totalPrice).reduce((v, e) => v < e ? v : e)
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D2B4).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Floor info + Switch to Grid button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2B4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$floor ЭТАЖ',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${floorApts.length} квартир · $freeCount своб.${minPrice > 0 ? " · от ${minPrice.toStringAsFixed(0)}\$" : ""}',
                    style: const TextStyle(
                      fontFamily: 'Golos',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onSwitchToMatrix,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.buttonPrimaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_view_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'В шахматку',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (floorApts.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Horizontal list of apartments on this floor
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: floorApts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final apt = floorApts[idx];
                  return _buildApartmentQuickCard(apt, colors);
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            const Text(
              'На этом этаже пока нет добавленных квартир',
              style: TextStyle(
                fontFamily: 'Golos',
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApartmentQuickCard(Apartment apt, dynamic colors) {
    final statusColor = apt.status.color;
    return InkWell(
      onTap: () => widget.onSelectApartment?.call(apt),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '№${apt.number}',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${apt.totalArea.toStringAsFixed(0)}м² · ${apt.totalPrice.toStringAsFixed(0)}\$',
              style: TextStyle(
                fontFamily: 'Golos',
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationCard(dynamic colors) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16212D).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Калибровка этажей',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isCalibrating = false),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Отступ крыши: ${(_topOffsetFraction * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
          Slider(
            value: _topOffsetFraction,
            min: 0.0,
            max: 0.30,
            onChanged: (v) => setState(() => _topOffsetFraction = v),
          ),
          Text(
            'Отступ стилобата: ${(_bottomOffsetFraction * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
          Slider(
            value: _bottomOffsetFraction,
            min: 0.0,
            max: 0.35,
            onChanged: (v) => setState(() => _bottomOffsetFraction = v),
          ),
        ],
      ),
    );
  }
}
