import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';

class ChessGridFilterDialog extends StatefulWidget {
  final ChessGridController controller;

  const ChessGridFilterDialog({super.key, required this.controller});

  static Future<void> show({
    required BuildContext context,
    required ChessGridController controller,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ChessGridFilterDialog(controller: controller),
      ),
    );
  }

  @override
  State<ChessGridFilterDialog> createState() => _ChessGridFilterDialogState();
}

class _ChessGridFilterDialogState extends State<ChessGridFilterDialog> {
  late String _buildingKey;
  late int _entrance;
  late Set<int> _rooms;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _minAreaController;
  late TextEditingController _maxAreaController;
  late Set<ApartmentStatus> _statuses;

  @override
  void initState() {
    super.initState();
    final f = widget.controller.filter;
    final buildings = widget.controller.complex.buildings;
    _buildingKey = f.buildingKey.isNotEmpty
        ? f.buildingKey
        : (buildings.isNotEmpty ? buildings.first.key : '');
    _entrance = f.entrance;
    _rooms = Set<int>.from(f.rooms);
    _minPriceController = TextEditingController(text: f.minPrice != null ? '${f.minPrice!.toInt()}' : '');
    _maxPriceController = TextEditingController(text: f.maxPrice != null ? '${f.maxPrice!.toInt()}' : '');
    _minAreaController = TextEditingController(text: f.minArea != null ? '${f.minArea}' : '');
    _maxAreaController = TextEditingController(text: f.maxArea != null ? '${f.maxArea}' : '');
    _statuses = Set<ApartmentStatus>.from(f.statuses);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;
    final buildings = controller.complex.buildings;

    final Building? building = buildings.isNotEmpty
        ? buildings.firstWhere(
            (b) => b.key == _buildingKey,
            orElse: () => buildings.first,
          )
        : null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фильтры шахматки',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _entrance = 0;
                      _rooms.clear();
                      _minPriceController.clear();
                      _maxPriceController.clear();
                      _minAreaController.clear();
                      _maxAreaController.clear();
                      _statuses = Set<ApartmentStatus>.from(ApartmentStatus.values);
                    });
                  },
                  child: const Text('Сбросить'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Building
                  if (buildings.isNotEmpty) ...[
                    Text('Корпус', style: _sectionTitleStyle(colors)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: buildings.map((b) {
                        final isSelected = _buildingKey == b.key;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _buildingKey = b.key;
                              _entrance = 0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.buttonPrimaryBg
                                  : colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colors.buttonPrimaryBg
                                    : colors.borderSubtle.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colors.buttonPrimaryBg
                                            .withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.apartment_rounded,
                                  size: 15,
                                  color: isSelected
                                      ? colors.buttonPrimaryFg
                                      : colors.iconSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  b.name,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 13,
                                    color: isSelected
                                        ? colors.buttonPrimaryFg
                                        : colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Entrance
                  if (building != null && building.entranceCount > 0) ...[
                    Text('Подъезд', style: _sectionTitleStyle(colors)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildEntranceFilterPill(
                          title: 'Все подъезды',
                          isSelected: _entrance == 0,
                          onTap: () => setState(() => _entrance = 0),
                          colors: colors,
                        ),
                        for (int e = 1; e <= building.entranceCount; e++)
                          _buildEntranceFilterPill(
                            title: 'Подъезд $e',
                            isSelected: _entrance == e,
                            onTap: () => setState(() => _entrance = e),
                            colors: colors,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Rooms
                  Text('Количество комнат', style: _sectionTitleStyle(colors)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (int r = 1; r <= 4; r++)
                        FilterChip(
                          label: Text(r == 4 ? '4+ комн.' : '$r комн.'),
                          selected: _rooms.contains(r),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _rooms.add(r);
                              } else {
                                _rooms.remove(r);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Price Range
                  Text('Цена, \$', style: _sectionTitleStyle(colors)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'От',
                            prefixText: '\$ ',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'До',
                            prefixText: '\$ ',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Area Range
                  Text('Общая площадь, м²', style: _sectionTitleStyle(colors)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAreaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'От, м²',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _maxAreaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'До, м²',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Status
                  Text('Статус квартиры', style: _sectionTitleStyle(colors)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ApartmentStatus.values.map((s) {
                      final isSelected = _statuses.contains(s);
                      return FilterChip(
                        avatar: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                        ),
                        label: Text(s.labelRu),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _statuses.add(s);
                            } else {
                              if (_statuses.length > 1) _statuses.remove(s);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final minP = double.tryParse(_minPriceController.text);
                        final maxP = double.tryParse(_maxPriceController.text);
                        final minA = double.tryParse(_minAreaController.text);
                        final maxA = double.tryParse(_maxAreaController.text);

                        controller.setFilter(controller.filter.copyWith(
                          buildingKey: _buildingKey,
                          entrance: _entrance,
                          rooms: _rooms,
                          minPrice: minP,
                          maxPrice: maxP,
                          minArea: minA,
                          maxArea: maxA,
                          statuses: _statuses,
                        ));

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Применить фильтры',
                        style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionTitleStyle(dynamic colors) => TextStyle(
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: colors.textPrimary,
      );

  Widget _buildEntranceFilterPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.buttonPrimaryBg : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12.5,
            color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

