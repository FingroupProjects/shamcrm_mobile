import 'dart:io';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/widgets/required_field_slot.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  int? _selectedEntranceId;
  late int _floor;
  late int _position;
  List<Entrance> _entrances = [];
  bool _isLoadingEntrances = false;

  final _numberController = TextEditingController();
  final _roomsController = TextEditingController();
  final _typeController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _livingAreaController = TextEditingController();
  final _kitchenAreaController = TextEditingController();
  final _pricePerM2Controller = TextEditingController();
  final _totalPriceController = TextEditingController();

  // TZ section 3 new fields
  final _layoutTypeController = TextEditingController(text: 'A');
  final _balconiesController = TextEditingController(text: '0');
  final _bathroomsController = TextEditingController(text: '1');
  String _currency = '\$';
  final List<String> _planImages = [];
  final Map<int, TextEditingController> _customFieldControllers = {};

  // Parking fields
  String _parkingType = 'Подземная';
  int? _linkedApartmentId;

  // Copy to floors feature (TZ section 3)
  bool _copyToFloors = false;
  final _copyFloorsController = TextEditingController();

  ApartmentStatus _status = ApartmentStatus.available;

  // Required fields validation like LeadAddScreen
  Set<String> _missingFields = {};
  String? _firstMissingField;
  int _fieldErrorPulse = 0;

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
    _selectedEntranceId = widget.existingApartment?.entranceId;
    _floor = widget.existingApartment?.floor ?? widget.initialFloor ?? 1;
    _position = widget.existingApartment?.position ?? widget.initialPosition ?? 0;

    _fetchEntrances();

    // Initialize custom field controllers
    for (final cf in controller.customFields.where((f) => f.scope == 'flat')) {
      final initialVal = widget.existingApartment?.customFields[cf.id] ?? '';
      _customFieldControllers[cf.id] = TextEditingController(text: initialVal);
    }

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
      _layoutTypeController.text = a.layoutType ?? 'A';
      _balconiesController.text = '${a.balconiesCount}';
      _bathroomsController.text = '${a.combinedBathroomsCount}';
      _currency = a.currency.isNotEmpty ? a.currency : '\$';
      _planImages.addAll(a.plans);
      _status = a.status;
    } else if (widget.existingParking != null) {
      final p = widget.existingParking!;
      _numberController.text = p.number;
      _totalAreaController.text = '${p.area}';
      _totalPriceController.text = p.price.toStringAsFixed(0);
      _parkingType = p.type;
      _linkedApartmentId = p.linkedApartmentId;
      _status = p.status;
    }
  }

  Future<void> _fetchEntrances() async {
    final controller = ChessGridController.instance;
    final buildings = controller.complex.buildings;
    if (buildings.isEmpty) return;
    final b = buildings.firstWhereOrNull((x) => x.key == _buildingKey) ?? buildings.first;
    if (b.id == null) return;

    setState(() => _isLoadingEntrances = true);
    try {
      final fetched = await controller.loadBuildingEntrances(b.id!);
      if (mounted) {
        setState(() {
          _entrances = fetched;
          if (_entrances.isNotEmpty) {
            Entrance? match;
            if (_selectedEntranceId != null) {
              match = _entrances.firstWhereOrNull((e) => e.id == _selectedEntranceId);
            }
            match ??= _entrances.firstWhereOrNull((e) => e.number == _entrance) ?? _entrances.first;
            _selectedEntranceId = match.id;
            _entrance = match.number;
          }
        });
      }
    } catch (_) {
      // ignore, fallback to default entrance counts
    } finally {
      if (mounted) setState(() => _isLoadingEntrances = false);
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

  Future<void> _pickPlanImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _planImages.addAll(images.map((img) => img.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
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
    _layoutTypeController.dispose();
    _balconiesController.dispose();
    _bathroomsController.dispose();
    _copyFloorsController.dispose();
    for (final c in _customFieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = ChessGridController.instance;
    final isEditing = widget.existingApartment != null || widget.existingParking != null;

    final buildings = controller.complex.buildings;
    final Building? building = buildings.firstWhereOrNull((b) => b.key == _buildingKey) ??
        (buildings.isNotEmpty ? buildings.first : null);

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
                        _buildTypeTab(
                          label: 'Квартира',
                          icon: Icons.apartment_rounded,
                          isSelected: !_isParking,
                          onTap: () {
                            if (_isParking) {
                              setState(() => _isParking = false);
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildTypeTab(
                          label: 'Парковка',
                          icon: Icons.local_parking_rounded,
                          isSelected: _isParking,
                          onTap: () {
                            if (!_isParking) {
                              setState(() => _isParking = true);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Common: Building selector & Number (каждое поле на отдельной строке)
                  _buildDropdown<String>(
                    label: 'Корпус',
                    value: _buildingKey,
                    items: controller.complex.buildings.map((b) {
                      return DropdownMenuItem(value: b.key, child: Text(b.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _buildingKey = val;
                          _selectedEntranceId = null;
                        });
                        _fetchEntrances();
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  RequiredFieldSlot(
                    invalid: _missingFields.contains('number'),
                    focus: _firstMissingField == 'number',
                    pulse: _fieldErrorPulse,
                    message: 'Укажите номер',
                    child: CustomTextField(
                      controller: _numberController,
                      label: 'Номер *',
                      hintText: 'Введите номер',
                      hasError: _missingFields.contains('number'),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty && _missingFields.contains('number')) {
                          setState(() {
                            _missingFields.remove('number');
                            if (_firstMissingField == 'number') _firstMissingField = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

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

                  // APARTMENT FIELDS (каждое поле на отдельной строке)
                  if (!_isParking) ...[
                    _entrances.isNotEmpty
                        ? _buildDropdown<int>(
                            label: _isLoadingEntrances ? 'Подъезд...' : 'Подъезд',
                            value: _selectedEntranceId ?? _entrances.first.id,
                            items: _entrances.map((e) {
                              return DropdownMenuItem<int>(
                                value: e.id,
                                child: Text(e.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final ent = _entrances.firstWhereOrNull((e) => e.id == val);
                                setState(() {
                                  _selectedEntranceId = val;
                                  _entrance = ent?.number ?? 1;
                                });
                              }
                            },
                          )
                        : _buildDropdown<int>(
                            label: _isLoadingEntrances ? 'Подъезд...' : 'Подъезд',
                            value: _entrance.clamp(1, building?.entranceCount ?? 1),
                            items: List.generate(
                              building?.entranceCount ?? 1,
                              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _entrance = val;
                                });
                              }
                            },
                          ),
                    const SizedBox(height: 14),

                    _buildDropdown<int>(
                      label: 'Этаж',
                      value: _floor.clamp(1, building?.floorCount ?? 9),
                      items: List.generate(
                        building?.floorCount ?? 9,
                        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _floor = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _roomsController,
                      label: 'Комнат',
                      hintText: 'Введите кол-во',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    // [Тип квартиры закомментирован по требованию]
                    // CustomTextField(
                    //   controller: _typeController,
                    //   label: 'Тип квартиры (отделка)',
                    //   hintText: 'Введите тип отделки',
                    // ),
                    // const SizedBox(height: 14),

                    RequiredFieldSlot(
                      invalid: _missingFields.contains('totalArea'),
                      focus: _firstMissingField == 'totalArea',
                      pulse: _fieldErrorPulse,
                      message: 'Укажите площадь',
                      child: CustomTextField(
                        controller: _totalAreaController,
                        label: 'Общая, м² *',
                        hintText: 'Введите площадь',
                        keyboardType: TextInputType.number,
                        hasError: _missingFields.contains('totalArea'),
                        onChanged: (_) {
                          if (_totalAreaController.text.trim().isNotEmpty &&
                              _missingFields.contains('totalArea')) {
                            setState(() {
                              _missingFields.remove('totalArea');
                              if (_firstMissingField == 'totalArea') _firstMissingField = null;
                            });
                          }
                          _calculatePriceFromM2();
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _livingAreaController,
                      label: 'Жилая, м²',
                      hintText: 'Введите площадь',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _kitchenAreaController,
                      label: 'Кухня, м²',
                      hintText: 'Введите площадь',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _layoutTypeController,
                      label: 'Тип планировки',
                      hintText: 'A, B, C...',
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _balconiesController,
                      label: 'Балконов / лоджий',
                      hintText: '0, 1...',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _bathroomsController,
                      label: 'Санузлов',
                      hintText: '1, 2...',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    RequiredFieldSlot(
                      invalid: _missingFields.contains('pricePerM2'),
                      focus: _firstMissingField == 'pricePerM2',
                      pulse: _fieldErrorPulse,
                      message: 'Укажите цену',
                      child: CustomTextField(
                        controller: _pricePerM2Controller,
                        label: 'Цена за м² *',
                        hintText: 'Введите цену',
                        keyboardType: TextInputType.number,
                        hasError: _missingFields.contains('pricePerM2'),
                        onChanged: (_) {
                          if (_pricePerM2Controller.text.trim().isNotEmpty &&
                              _missingFields.contains('pricePerM2')) {
                            setState(() {
                              _missingFields.remove('pricePerM2');
                              if (_firstMissingField == 'pricePerM2') _firstMissingField = null;
                            });
                          }
                          _calculatePriceFromM2();
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    RequiredFieldSlot(
                      invalid: _missingFields.contains('totalPrice'),
                      focus: _firstMissingField == 'totalPrice',
                      pulse: _fieldErrorPulse,
                      message: 'Укажите сумму',
                      child: CustomTextField(
                        controller: _totalPriceController,
                        label: 'Общая цена *',
                        hintText: 'Введите сумму',
                        keyboardType: TextInputType.number,
                        hasError: _missingFields.contains('totalPrice'),
                        onChanged: (_) {
                          if (_totalPriceController.text.trim().isNotEmpty &&
                              _missingFields.contains('totalPrice')) {
                            setState(() {
                              _missingFields.remove('totalPrice');
                              if (_firstMissingField == 'totalPrice') _firstMissingField = null;
                            });
                          }
                          _calculateM2FromPrice();
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildDropdown<String>(
                      label: 'Валюта',
                      value: _currency,
                      items: const [
                        DropdownMenuItem(value: '\$', child: Text('\$ (USD)')),
                        DropdownMenuItem(value: 'сом.', child: Text('сом.')),
                        DropdownMenuItem(value: 'руб.', child: Text('руб.')),
                        DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _currency = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Photos of Floor Plan Section (TZ Section 3)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Фотографии планировки (${_planImages.length})',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: colors.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _pickPlanImages,
                              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                              label: const Text('Добавить', style: TextStyle(fontFamily: 'Gilroy', fontSize: 12.5)),
                              style: TextButton.styleFrom(foregroundColor: colors.buttonPrimaryBg),
                            ),
                          ],
                        ),
                        if (_planImages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 70,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _planImages.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (ctx, idx) {
                                final path = _planImages[idx];
                                final isLocal = File(path).existsSync();
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        color: colors.surfaceElevated,
                                        child: isLocal
                                            ? Image.file(File(path), fit: BoxFit.cover)
                                            : Image.network(
                                                path,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Icon(
                                                  Icons.broken_image_rounded,
                                                  color: colors.iconSecondary,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _planImages.removeAt(idx)),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),

                    // Custom fields section (TZ Section 5.5)
                    if (_customFieldControllers.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Дополнительные поля',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: colors.buttonPrimaryBg,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final cf in controller.customFields.where((f) => f.scope == 'flat')) ...[
                        if (cf.isRequired)
                          RequiredFieldSlot(
                            invalid: _missingFields.contains('custom_${cf.id}'),
                            focus: _firstMissingField == 'custom_${cf.id}',
                            pulse: _fieldErrorPulse,
                            message: 'Поле «${cf.name}» обязательно',
                            child: CustomTextField(
                              controller: _customFieldControllers[cf.id]!,
                              label: '${cf.name} *',
                              hintText: 'Введите ${cf.name.toLowerCase()}',
                              keyboardType: cf.type == 'number' ? TextInputType.number : TextInputType.text,
                              hasError: _missingFields.contains('custom_${cf.id}'),
                              onChanged: (val) {
                                if (val.trim().isNotEmpty && _missingFields.contains('custom_${cf.id}')) {
                                  setState(() {
                                    _missingFields.remove('custom_${cf.id}');
                                    if (_firstMissingField == 'custom_${cf.id}') _firstMissingField = null;
                                  });
                                }
                              },
                            ),
                          )
                        else
                          CustomTextField(
                            controller: _customFieldControllers[cf.id]!,
                            label: cf.name,
                            hintText: 'Введите ${cf.name.toLowerCase()}',
                            keyboardType: cf.type == 'number' ? TextInputType.number : TextInputType.text,
                          ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 6),
                    ],
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
                        CustomTextField(
                          controller: _copyFloorsController,
                          label: 'Номера этажей (например: 2-9 или 2,4,6)',
                          hintText: 'Введите этажи',
                        ),
                        const SizedBox(height: 14),
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
                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _totalAreaController,
                            label: 'Площадь, м²',
                            hintText: 'Введите площадь',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RequiredFieldSlot(
                            invalid: _missingFields.contains('parkingPrice'),
                            focus: _firstMissingField == 'parkingPrice',
                            pulse: _fieldErrorPulse,
                            message: 'Укажите цену',
                            child: CustomTextField(
                              controller: _totalPriceController,
                              label: 'Цена *',
                              hintText: 'Введите цену',
                              keyboardType: TextInputType.number,
                              hasError: _missingFields.contains('parkingPrice'),
                              onChanged: (val) {
                                if (val.trim().isNotEmpty && _missingFields.contains('parkingPrice')) {
                                  setState(() {
                                    _missingFields.remove('parkingPrice');
                                    if (_firstMissingField == 'parkingPrice') _firstMissingField = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

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
    final price = double.tryParse(_totalPriceController.text) ?? 0;
    final area = double.tryParse(_totalAreaController.text) ?? 0;

    final missing = <String>[];
    if (no.isEmpty) missing.add('number');

    if (!_isParking) {
      if (area <= 0) missing.add('totalArea');
      final pm = double.tryParse(_pricePerM2Controller.text) ?? 0;
      if (pm <= 0) missing.add('pricePerM2');
      if (price <= 0) missing.add('totalPrice');
      for (final cf in controller.customFields.where((f) => f.scope == 'flat' && f.isRequired)) {
        final ctrl = _customFieldControllers[cf.id];
        if (ctrl == null || ctrl.text.trim().isEmpty) {
          missing.add('custom_${cf.id}');
        }
      }
    } else {
      if (price <= 0) missing.add('parkingPrice');
    }

    if (missing.isNotEmpty) {
      setState(() {
        _missingFields = missing.toSet();
        _firstMissingField = missing.first;
        _fieldErrorPulse++;
      });
      showCustomSnackBar(
        context: context,
        message: 'Заполните обязательные поля',
        isSuccess: false,
      );
      return;
    }

    if (_missingFields.isNotEmpty) {
      setState(() {
        _missingFields = {};
        _firstMissingField = null;
      });
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

    final buildings = controller.complex.buildings;
    final b = buildings.firstWhereOrNull((x) => x.key == _buildingKey) ??
        (buildings.isNotEmpty ? buildings.first : null);
    final bName = b?.name ?? 'Корпус';

    final customFieldMap = <int, String>{};
    for (final e in _customFieldControllers.entries) {
      if (e.value.text.trim().isNotEmpty) {
        customFieldMap[e.key] = e.value.text.trim();
      }
    }

    final layoutType = _layoutTypeController.text.trim().isNotEmpty ? _layoutTypeController.text.trim() : 'A';
    final balconies = int.tryParse(_balconiesController.text) ?? 0;
    final bathrooms = int.tryParse(_bathroomsController.text) ?? 1;

    if (widget.existingApartment != null) {
      controller.updateApartment(widget.existingApartment!.copyWith(
        number: no,
        buildingKey: _buildingKey,
        buildingName: bName,
        entrance: _entrance,
        entranceId: _selectedEntranceId,
        floor: _floor,
        rooms: rooms,
        type: type,
        totalArea: area,
        livingArea: live,
        kitchenArea: kit,
        pricePerSqm: pm,
        totalPrice: price,
        currency: _currency,
        layoutType: layoutType,
        balconiesCount: balconies,
        combinedBathroomsCount: bathrooms,
        plans: _planImages,
        customFields: customFieldMap,
        status: _status,
      ));
    } else {
      int maxId = controller.apartments.map((a) => a.id).fold(0, (x, y) => x > y ? x : y);
      List<int>? copyFloorsList;
      if (_copyToFloors) {
        copyFloorsList = _parseFloors(_copyFloorsController.text, b?.floorCount ?? 9);
      }

      controller.addApartment(
        Apartment(
          id: maxId + 1,
          number: no,
          buildingKey: _buildingKey,
          buildingName: bName,
          entrance: _entrance,
          entranceId: _selectedEntranceId,
          floor: _floor,
          position: _position,
          rooms: rooms,
          type: type,
          totalArea: area,
          livingArea: live,
          kitchenArea: kit,
          pricePerSqm: pm,
          totalPrice: price,
          currency: _currency,
          layoutType: layoutType,
          balconiesCount: balconies,
          combinedBathroomsCount: bathrooms,
          plans: _planImages,
          customFields: customFieldMap,
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

  Widget _buildTypeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.surfaceElevated.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? colors.buttonPrimaryFg : colors.iconSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final hasMatch = items.any((item) => item.value == value);
    final effectiveValue = hasMatch ? value : (items.isNotEmpty ? items.first.value : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        DropdownButtonFormField<T>(
          key: ValueKey(effectiveValue),
          initialValue: effectiveValue,
          isExpanded: true,
          isDense: true,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            color: colors.textPrimary,
          ),
          dropdownColor: colors.surfacePrimary,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconSecondary),
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
        ),
      ],
    );
  }
}

