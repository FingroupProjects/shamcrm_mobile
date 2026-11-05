import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/building_form_sheet.dart';
import 'package:flutter/material.dart';

class ChessGridFilterDialog extends StatefulWidget {
  final dynamic controller;

  const ChessGridFilterDialog({super.key, required this.controller});

  static Future<void> show({
    required BuildContext context,
    required dynamic controller,
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
  int _selectedRoom = 0;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _minAreaController;
  late TextEditingController _maxAreaController;
  late Set<ApartmentStatus> _statuses;
  ApartmentStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final f = widget.controller.filter;
    final List<Building> buildings = (widget.controller.complex.buildings as Iterable).cast<Building>().toList();
    _buildingKey = f.buildingKey.isNotEmpty
        ? f.buildingKey
        : (buildings.isNotEmpty ? buildings.first.key : '');
    _entrance = f.entrance;
    _rooms = Set<int>.from(f.rooms);
    _selectedRoom = _rooms.length == 1 ? _rooms.first : 0;
    _minPriceController = TextEditingController(text: f.minPrice != null ? '${f.minPrice!.toInt()}' : '');
    _maxPriceController = TextEditingController(text: f.maxPrice != null ? '${f.maxPrice!.toInt()}' : '');
    _minAreaController = TextEditingController(text: f.minArea != null ? '${f.minArea}' : '');
    _maxAreaController = TextEditingController(text: f.maxArea != null ? '${f.maxArea}' : '');
    _statuses = Set<ApartmentStatus>.from(f.statuses);
    _selectedStatus = _statuses.length == 1 ? _statuses.first : null;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    super.dispose();
  }

  ButtonStyle _buildActionButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor:
          context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
    );
  }

  void _applyFilters() {
    final minP = double.tryParse(_minPriceController.text);
    final maxP = double.tryParse(_maxPriceController.text);
    final minA = double.tryParse(_minAreaController.text);
    final maxA = double.tryParse(_maxAreaController.text);

    widget.controller.setFilter(widget.controller.filter.copyWith(
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
  }

  void _resetFilters() {
    setState(() {
      _entrance = 0;
      _rooms.clear();
      _selectedRoom = 0;
      _minPriceController.clear();
      _maxPriceController.clear();
      _minAreaController.clear();
      _maxAreaController.clear();
      _statuses = Set<ApartmentStatus>.from(ApartmentStatus.values);
      _selectedStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;
    final List<Building> buildings = (controller.complex.buildings as Iterable).cast<Building>().toList();

    final Building? building = buildings.firstWhereOrNull((b) => b.key == _buildingKey) ??
        (buildings.isNotEmpty ? buildings.first : null);

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

          // Header in the exact CRM style (Лиды / Сделки / Задачи)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('chess_grid_filter_title', fallback: 'Фильтр'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  style: _buildActionButtonStyle(),
                  child: Text(
                    context.tr('chess_grid_reset_filters', fallback: 'Сбросить'),
                    style: context.appTextStyles.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.buttonPrimaryBg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _applyFilters,
                  style: _buildActionButtonStyle(),
                  child: Text(
                    context.tr('chess_grid_apply', fallback: 'Применить'),
                    style: context.appTextStyles.labelLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.buttonPrimaryBg,
                    ),
                  ),
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
                  // 1. Building Dropdown + Add button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildDropdown<String>(
                          label: context.tr('chess_grid_building', fallback: 'Корпус'),
                          value: _buildingKey,
                          items: buildings.map((b) {
                            return DropdownMenuItem(value: b.key, child: Text(b.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _buildingKey = val;
                                _entrance = 0;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Tooltip(
                          message: context.tr('chess_grid_action_add_building', fallback: 'Добавить корпус'),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              BuildingFormSheet.show(context: context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.buttonPrimaryBg.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 18, color: colors.buttonPrimaryBg),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.tr('chess_grid_building', fallback: 'Корпус'),
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: colors.buttonPrimaryBg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Entrance Dropdown
                  if (building != null && building.entranceCount > 0) ...[
                    _buildDropdown<int>(
                      label: context.tr('chess_grid_entrance_label', fallback: 'Подъезд'),
                      value: _entrance,
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(context.tr('chess_grid_all_entrances', fallback: 'Все подъезды')),
                        ),
                        for (int e = 1; e <= building.entranceCount; e++)
                          DropdownMenuItem(
                            value: e,
                            child: Text('${context.tr('chess_grid_entrance_label', fallback: 'Подъезд')} $e'),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _entrance = val);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 3. Rooms Dropdown
                  _buildDropdown<int>(
                    label: context.tr('chess_grid_rooms_count_label', fallback: 'Количество комнат'),
                    value: _selectedRoom,
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text(context.tr('chess_grid_all_rooms', fallback: 'Все комнаты')),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(context.tr('chess_grid_room_1', fallback: '1 комната')),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(context.tr('chess_grid_rooms_2_label', fallback: '2 комнаты')),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(context.tr('chess_grid_rooms_3_label', fallback: '3 комнаты')),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text(context.tr('chess_grid_rooms_4plus_label', fallback: '4+ комнат')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRoom = val;
                          if (val == 0) {
                            _rooms.clear();
                          } else {
                            _rooms = {val};
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // 4. Status Dropdown
                  _buildDropdown<ApartmentStatus?>(
                    label: context.tr('chess_grid_apartment_status_filter', fallback: 'Статус квартиры'),
                    value: _selectedStatus,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(context.tr('chess_grid_all_statuses', fallback: 'Все статусы')),
                      ),
                      ...ApartmentStatus.values.map((s) {
                        return DropdownMenuItem<ApartmentStatus?>(
                          value: s,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(s.localizedLabel(context)),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val;
                        if (val == null) {
                          _statuses = Set<ApartmentStatus>.from(ApartmentStatus.values);
                        } else {
                          _statuses = {val};
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // 5. Price Range (каждое поле на отдельной строке)
                  CustomTextField(
                    controller: _minPriceController,
                    label: context.tr('chess_grid_price_from', fallback: 'Цена от'),
                    hintText: context.tr('chess_grid_min_price_hint', fallback: 'Введите минимальную сумму'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _maxPriceController,
                    label: context.tr('chess_grid_price_to', fallback: 'Цена до'),
                    hintText: context.tr('chess_grid_max_price_hint', fallback: 'Введите максимальную сумму'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),

                  // 6. Area Range (каждое поле на отдельной строке)
                  CustomTextField(
                    controller: _minAreaController,
                    label: context.tr('chess_grid_area_from', fallback: 'Общая площадь от, м²'),
                    hintText: context.tr('chess_grid_min_area_hint', fallback: 'Введите минимальную площадь'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _maxAreaController,
                    label: context.tr('chess_grid_area_to', fallback: 'Общая площадь до, м²'),
                    hintText: context.tr('chess_grid_max_area_hint', fallback: 'Введите максимальную площадь'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.fieldBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            border: AppFieldStyle.outline(context),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppFieldStyle.radius,
              borderSide: AppFieldStyle.side(context),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppFieldStyle.radius,
              borderSide: AppFieldStyle.side(context, focused: true),
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconSecondary),
          dropdownColor: colors.surfacePrimary,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

