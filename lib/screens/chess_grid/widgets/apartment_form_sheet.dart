import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class ApartmentFormSheet extends StatefulWidget {
  final Apartment? existingApartment;
  final ParkingSpot? existingParking;
  final String? initialBuildingKey;
  final int? initialEntrance;
  final int? initialFloor;
  final int? initialPosition;
  final bool isParkingMode;

  const ApartmentFormSheet({
    super.key,
    this.existingApartment,
    this.existingParking,
    this.initialBuildingKey,
    this.initialEntrance,
    this.initialFloor,
    this.initialPosition,
    this.isParkingMode = false,
  });

  static Future<void> show({
    required BuildContext context,
    Apartment? existingApartment,
    ParkingSpot? existingParking,
    String? initialBuildingKey,
    int? initialEntrance,
    int? initialFloor,
    int? initialPosition,
    bool isParkingMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ApartmentFormSheet(
          existingApartment: existingApartment,
          existingParking: existingParking,
          initialBuildingKey: initialBuildingKey,
          initialEntrance: initialEntrance,
          initialFloor: initialFloor,
          initialPosition: initialPosition,
          isParkingMode: isParkingMode,
        ),
      ),
    );
  }

  @override
  State<ApartmentFormSheet> createState() => _ApartmentFormSheetState();
}

class _ApartmentFormSheetState extends State<ApartmentFormSheet> {
  late bool _isParking;
  late String _buildingKey;
  late int _entrance;
  late int _floor;
  late int _position;

  final _numberController = TextEditingController();
  final _roomsController = TextEditingController(text: '1');
  final _typeController = TextEditingController(text: 'Студия');
  final _totalAreaController = TextEditingController(text: '45.0');
  final _livingAreaController = TextEditingController(text: '26.0');
  final _kitchenAreaController = TextEditingController(text: '10.0');
  final _pricePerM2Controller = TextEditingController(text: '800');
  final _totalPriceController = TextEditingController(text: '36000');

  // Parking fields
  String _parkingType = 'Подземная';
  int? _linkedApartmentId;

  // Copy to floors feature (TZ section 3)
  bool _copyToFloors = false;
  final _copyFloorsController = TextEditingController(text: '2-9');

  ApartmentStatus _status = ApartmentStatus.available;

  @override
  void initState() {
    super.initState();
    _isParking = widget.isParkingMode || widget.existingParking != null;

    final controller = ChessGridController.instance;
    _buildingKey = widget.existingApartment?.buildingKey ??
        widget.existingParking?.buildingKey ??
        widget.initialBuildingKey ??
        (controller.complex.buildings.isNotEmpty ? controller.complex.buildings.first.key : 'A');

    _entrance = widget.existingApartment?.entrance ?? widget.initialEntrance ?? 1;
    _floor = widget.existingApartment?.floor ?? widget.initialFloor ?? 1;
    _position = widget.existingApartment?.position ?? widget.initialPosition ?? 0;

    if (widget.existingApartment != null) {
      final a = widget.existingApartment!;
      _numberController.text = a.number;
      _roomsController.text = '${a.rooms}';
      _typeController.text = a.type;
      _totalAreaController.text = '${a.totalArea}';
      _livingAreaController.text = '${a.livingArea}';
      _kitchenAreaController.text = '${a.kitchenArea}';
      _pricePerM2Controller.text = a.pricePerSqm.toStringAsFixed(0);
      _totalPriceController.text = a.totalPrice.toStringAsFixed(0);
      _status = a.status;
    } else if (widget.existingParking != null) {
      final p = widget.existingParking!;
      _numberController.text = p.number;
      _totalAreaController.text = '${p.area}';
      _totalPriceController.text = p.price.toStringAsFixed(0);
      _parkingType = p.type;
      _linkedApartmentId = p.linkedApartmentId;
      _status = p.status;
    } else {
      _autoGenerateNumber();
    }
  }

  void _autoGenerateNumber() {
    final controller = ChessGridController.instance;
    final b = controller.complex.buildings.firstWhere((x) => x.key == _buildingKey, orElse: () => controller.complex.buildings.first);
    if (_isParking) {
      _numberController.text = 'П-${(controller.parkingSpots.length + 1).toString().padLeft(2, '0')}';
    } else {
      final slotNo = (_entrance - 1) * b.floorCount * b.apartsPerFloor + (_floor - 1) * b.apartsPerFloor + _position + 1;
      _numberController.text = '$slotNo';
    }
  }

  void _calculatePriceFromM2() {
    final area = double.tryParse(_totalAreaController.text) ?? 0;
    final m2 = double.tryParse(_pricePerM2Controller.text) ?? 0;
    if (area > 0 && m2 > 0) {
      _totalPriceController.text = (area * m2).round().toString();
    }
  }

  void _calculateM2FromPrice() {
    final area = double.tryParse(_totalAreaController.text) ?? 0;
    final total = double.tryParse(_totalPriceController.text) ?? 0;
    if (area > 0 && total > 0) {
      _pricePerM2Controller.text = (total / area).round().toString();
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _roomsController.dispose();
    _typeController.dispose();
    _totalAreaController.dispose();
    _livingAreaController.dispose();
    _kitchenAreaController.dispose();
    _pricePerM2Controller.dispose();
    _totalPriceController.dispose();
    _copyFloorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = ChessGridController.instance;
    final isEditing = widget.existingApartment != null || widget.existingParking != null;

    final building = controller.complex.buildings.firstWhere(
      (b) => b.key == _buildingKey,
      orElse: () => controller.complex.buildings.first,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                  isEditing ? 'Редактировать товар' : 'Добавить в номенклатуру',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
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
                  // Item Type Switcher (Only when adding)
                  if (!isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Квартира')),
                            selected: !_isParking,
                            onSelected: (val) {
                              setState(() {
                                _isParking = false;
                                _autoGenerateNumber();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Парковочное место')),
                            selected: _isParking,
                            onSelected: (val) {
                              setState(() {
                                _isParking = true;
                                _autoGenerateNumber();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Common: Building selector & Number
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown<String>(
                          label: 'Корпус',
                          value: _buildingKey,
                          items: controller.complex.buildings.map((b) {
                            return DropdownMenuItem(value: b.key, child: Text(b.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _buildingKey = val;
                                _autoGenerateNumber();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _numberController,
                          label: 'Номер *',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status
                  _buildDropdown<ApartmentStatus>(
                    label: 'Статус',
                    value: _status,
                    items: ApartmentStatus.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(s.labelRu),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // APARTMENT FIELDS
                  if (!_isParking) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown<int>(
                            label: 'Подъезд',
                            value: _entrance.clamp(1, building.entranceCount),
                            items: List.generate(
                              building.entranceCount,
                              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _entrance = val;
                                  _autoGenerateNumber();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown<int>(
                            label: 'Этаж',
                            value: _floor.clamp(1, building.floorCount),
                            items: List.generate(
                              building.floorCount,
                              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _floor = val;
                                  _autoGenerateNumber();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _roomsController,
                            label: 'Комнат',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _typeController,
                      label: 'Тип квартиры (отделка)',
                      hint: 'Студия, Евроремонт, Черновая',
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _totalAreaController,
                            label: 'Общая, м² *',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculatePriceFromM2(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _livingAreaController,
                            label: 'Жилая, м²',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _kitchenAreaController,
                            label: 'Кухня, м²',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _pricePerM2Controller,
                            label: 'Цена за м², \$ *',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculatePriceFromM2(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _totalPriceController,
                            label: 'Общая цена, \$ *',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculateM2FromPrice(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Copy to other floors feature (from TZ section 3)
                    if (!isEditing) ...[
                      CheckboxListTile(
                        value: _copyToFloors,
                        onChanged: (val) => setState(() => _copyToFloors = val ?? false),
                        title: const Text(
                          'Скопировать на другие этажи этого подъезда',
                          style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Данные сохранятся, номера присвоятся автоматически',
                          style: TextStyle(fontFamily: 'Golos', fontSize: 11),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_copyToFloors) ...[
                        _buildTextField(
                          controller: _copyFloorsController,
                          label: 'Номера этажей (например: 2-9 или 2,4,6)',
                          hint: '2-9',
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ] else ...[
                    // PARKING FIELDS
                    _buildDropdown<String>(
                      label: 'Тип парковки',
                      value: _parkingType,
                      items: ['Подземная', 'Открытая', 'Закрытая'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _parkingType = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _totalAreaController,
                            label: 'Площадь, м²',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _totalPriceController,
                            label: 'Цена, \$ *',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Linked apartment selector
                    _buildDropdown<int?>(
                      label: 'Привязка к квартире',
                      value: _linkedApartmentId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Без привязки')),
                        ...controller.apartments.where((a) => a.buildingKey == _buildingKey).map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('Кв. № ${a.number} (${a.floor} эт.)'),
                          );
                        }),
                      ],
                      onChanged: (val) => setState(() => _linkedApartmentId = val),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isEditing ? 'Сохранить изменения' : 'Добавить',
                        style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14),
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

  void _handleSave() {
    final controller = ChessGridController.instance;
    final no = _numberController.text.trim();
    if (no.isEmpty) {
      showCustomSnackBar(context: context, message: 'Укажите номер или название', isSuccess: false);
      return;
    }

    final price = double.tryParse(_totalPriceController.text) ?? 0;
    final area = double.tryParse(_totalAreaController.text) ?? 0;

    if (price <= 0) {
      showCustomSnackBar(context: context, message: 'Укажите корректную цену', isSuccess: false);
      return;
    }

    if (_isParking) {
      if (widget.existingParking != null) {
        controller.updateParkingSpot(widget.existingParking!.copyWith(
          number: no,
          buildingKey: _buildingKey,
          type: _parkingType,
          price: price,
          area: area,
          status: _status,
          linkedApartmentId: _linkedApartmentId,
        ));
      } else {
        int maxId = controller.parkingSpots.map((p) => p.id).fold(0, (a, b) => a > b ? a : b);
        controller.addParkingSpot(ParkingSpot(
          id: maxId + 1,
          number: no,
          type: _parkingType,
          buildingKey: _buildingKey,
          price: price,
          area: area,
          status: _status,
          linkedApartmentId: _linkedApartmentId,
        ));
      }
      Navigator.pop(context);
      showCustomSnackBar(context: context, message: 'Парковочное место сохранено', isSuccess: true);
      return;
    }

    // Apartment save
    final rooms = int.tryParse(_roomsController.text) ?? 1;
    final type = _typeController.text.trim().isNotEmpty ? _typeController.text.trim() : 'Студия';
    final live = double.tryParse(_livingAreaController.text) ?? (area * 0.58);
    final kit = double.tryParse(_kitchenAreaController.text) ?? 10.0;
    final pm = double.tryParse(_pricePerM2Controller.text) ?? (area > 0 ? price / area : 800);

    final b = controller.complex.buildings.firstWhere((x) => x.key == _buildingKey);

    if (widget.existingApartment != null) {
      controller.updateApartment(widget.existingApartment!.copyWith(
        number: no,
        buildingKey: _buildingKey,
        buildingName: b.name,
        entrance: _entrance,
        floor: _floor,
        rooms: rooms,
        type: type,
        totalArea: area,
        livingArea: live,
        kitchenArea: kit,
        pricePerSqm: pm,
        totalPrice: price,
        status: _status,
      ));
    } else {
      int maxId = controller.apartments.map((a) => a.id).fold(0, (x, y) => x > y ? x : y);
      List<int>? copyFloorsList;
      if (_copyToFloors) {
        copyFloorsList = _parseFloors(_copyFloorsController.text, b.floorCount);
      }

      controller.addApartment(
        Apartment(
          id: maxId + 1,
          number: no,
          buildingKey: _buildingKey,
          buildingName: b.name,
          entrance: _entrance,
          floor: _floor,
          position: _position,
          rooms: rooms,
          type: type,
          totalArea: area,
          livingArea: live,
          kitchenArea: kit,
          pricePerSqm: pm,
          totalPrice: price,
          currency: '\$',
          status: _status,
        ),
        copyToFloors: copyFloorsList,
      );
    }

    Navigator.pop(context);
    showCustomSnackBar(
      context: context,
      message: widget.existingApartment != null ? 'Квартира обновлена' : 'Квартира успешно добавлена',
      isSuccess: true,
    );
  }

  List<int> _parseFloors(String str, int maxFloor) {
    final result = <int>{};
    final parts = str.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final bounds = trimmed.split('-');
        if (bounds.length == 2) {
          final start = int.tryParse(bounds[0]) ?? 1;
          final end = int.tryParse(bounds[1]) ?? maxFloor;
          for (int f = start; f <= end; f++) {
            if (f >= 1 && f <= maxFloor) result.add(f);
          }
        }
      } else {
        final f = int.tryParse(trimmed);
        if (f != null && f >= 1 && f <= maxFloor) result.add(f);
      }
    }
    return result.toList();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Golos', fontSize: 11.5, color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(fontFamily: 'Golos', fontSize: 13, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: colors.surfaceElevated.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
          ),
        ),
      ],
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
        Text(
          label,
          style: TextStyle(fontFamily: 'Golos', fontSize: 11.5, color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

