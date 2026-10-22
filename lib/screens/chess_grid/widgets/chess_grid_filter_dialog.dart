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
    _buildingKey = f.buildingKey;
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

    final building = controller.complex.buildings.firstWhere(
      (b) => b.key == _buildingKey,
      orElse: () => controller.complex.buildings.first,
    );

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
                  Text('Корпус', style: _sectionTitleStyle(colors)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: controller.complex.buildings.map((b) {
                      final isSelected = _buildingKey == b.key;
                      return ChoiceChip(
                        label: Text(b.name),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _buildingKey = b.key;
                              _entrance = 0; // reset entrance
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Entrance
                  Text('Подъезд', style: _sectionTitleStyle(colors)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Все подъезды'),
                        selected: _entrance == 0,
                        onSelected: (val) => setState(() => _entrance = 0),
                      ),
                      for (int e = 1; e <= building.entranceCount; e++)
                        ChoiceChip(
                          label: Text('Подъезд $e'),
                          selected: _entrance == e,
                          onSelected: (val) => setState(() => _entrance = e),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

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
}

