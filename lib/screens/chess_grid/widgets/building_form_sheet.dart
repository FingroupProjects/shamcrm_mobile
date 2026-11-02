import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/widgets/required_field_slot.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class BuildingFormSheet extends StatefulWidget {
  final Building? existingBuilding;

  const BuildingFormSheet({super.key, this.existingBuilding});

  static Future<void> show({
    required BuildContext context,
    Building? existingBuilding,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BuildingFormSheet(existingBuilding: existingBuilding),
      ),
    );
  }

  @override
  State<BuildingFormSheet> createState() => _BuildingFormSheetState();
}

class _BuildingFormSheetState extends State<BuildingFormSheet> {
  final _nameController = TextEditingController();
  final _entranceController = TextEditingController();
  final _floorController = TextEditingController();
  final _perFloorController = TextEditingController();
  final _customTypeController = TextEditingController();
  bool _isSaving = false;

  // Required fields validation like LeadAddScreen
  Set<String> _missingFields = {};
  String? _firstMissingField;
  int _fieldErrorPulse = 0;

  // static const List<String> _defaultTypes = ['Студия', 'Евроремонт', 'Предчистовая', 'Черновая'];
  final List<String> _availableTypes = ['Студия', 'Евроремонт', 'Предчистовая', 'Черновая'];
  final Set<String> _selectedTypes = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingBuilding != null) {
      final b = widget.existingBuilding!;
      _nameController.text = b.name;
      _entranceController.text = '${b.entranceCount}';
      _floorController.text = '${b.floorCount}';
      _perFloorController.text = '${b.apartsPerFloor}';
      _selectedTypes.clear();
      _selectedTypes.addAll(b.apartmentTypes);
      for (final t in b.apartmentTypes) {
        if (!_availableTypes.contains(t)) _availableTypes.add(t);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _perFloorController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  /*
  void _addCustomType() {
    final text = _customTypeController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      final existingIndex = _availableTypes.indexWhere(
        (t) => t.toLowerCase() == text.toLowerCase(),
      );
      if (existingIndex != -1) {
        _selectedTypes.add(_availableTypes[existingIndex]);
      } else {
        _availableTypes.add(text);
        _selectedTypes.add(text);
      }
      _customTypeController.clear();
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEditing = widget.existingBuilding != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Редактировать корпус' : 'Новый корпус ЖК',
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

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RequiredFieldSlot(
                    invalid: _missingFields.contains('name'),
                    focus: _firstMissingField == 'name',
                    pulse: _fieldErrorPulse,
                    message: 'Укажите название корпуса',
                    child: CustomTextField(
                      controller: _nameController,
                      label: 'Название корпуса *',
                      hintText: 'Введите название корпуса',
                      hasError: _missingFields.contains('name'),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty && _missingFields.contains('name')) {
                          setState(() {
                            _missingFields.remove('name');
                            if (_firstMissingField == 'name') _firstMissingField = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Каждое поле на отдельной строке
                  RequiredFieldSlot(
                    invalid: _missingFields.contains('entrance'),
                    focus: _firstMissingField == 'entrance',
                    pulse: _fieldErrorPulse,
                    message: 'Укажите кол-во',
                    child: CustomTextField(
                      controller: _entranceController,
                      label: 'Подъездов *',
                      hintText: 'Введите кол-во',
                      keyboardType: TextInputType.number,
                      hasError: _missingFields.contains('entrance'),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty && _missingFields.contains('entrance')) {
                          setState(() {
                            _missingFields.remove('entrance');
                            if (_firstMissingField == 'entrance') _firstMissingField = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  RequiredFieldSlot(
                    invalid: _missingFields.contains('floor'),
                    focus: _firstMissingField == 'floor',
                    pulse: _fieldErrorPulse,
                    message: 'Укажите кол-во',
                    child: CustomTextField(
                      controller: _floorController,
                      label: 'Этажей *',
                      hintText: 'Введите кол-во',
                      keyboardType: TextInputType.number,
                      hasError: _missingFields.contains('floor'),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty && _missingFields.contains('floor')) {
                          setState(() {
                            _missingFields.remove('floor');
                            if (_firstMissingField == 'floor') _firstMissingField = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  RequiredFieldSlot(
                    invalid: _missingFields.contains('perFloor'),
                    focus: _firstMissingField == 'perFloor',
                    pulse: _fieldErrorPulse,
                    message: 'Укажите кол-во',
                    child: CustomTextField(
                      controller: _perFloorController,
                      label: 'Кв. на этаже *',
                      hintText: 'Введите кол-во',
                      keyboardType: TextInputType.number,
                      hasError: _missingFields.contains('perFloor'),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty && _missingFields.contains('perFloor')) {
                          setState(() {
                            _missingFields.remove('perFloor');
                            if (_firstMissingField == 'perFloor') _firstMissingField = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // [Тип квартир закомментирован по требованию]
                  /*
                  RequiredFieldSlot(
                    invalid: _missingFields.contains('types'),
                    focus: _firstMissingField == 'types',
                    pulse: _fieldErrorPulse,
                    message: 'Выберите хотя бы один тип квартир',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Тип квартир *',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _missingFields.contains('types')
                                ? Colors.red
                                : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ..._availableTypes.map((t) {
                              final isSelected = _selectedTypes.contains(t);
                              final isCustom = !_defaultTypes.contains(t);
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(t),
                                    if (isCustom) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _availableTypes.remove(t);
                                            _selectedTypes.remove(t);
                                          });
                                        },
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: isSelected
                                              ? colors.buttonPrimaryFg
                                              : colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedTypes.add(t);
                                    } else {
                                      _selectedTypes.remove(t);
                                    }
                                    if (_selectedTypes.isNotEmpty &&
                                        _missingFields.contains('types')) {
                                      _missingFields.remove('types');
                                      if (_firstMissingField == 'types') {
                                        _firstMissingField = null;
                                      }
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Add custom type
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _customTypeController,
                          label: '',
                          hintText: 'Введите тип (напр. Пентхаус)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addCustomType,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Добавить',
                          style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: colors.buttonPrimaryFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  */
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isEditing ? 'Сохранить корпус' : 'Создать корпус',
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

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final ent = int.tryParse(_entranceController.text) ?? 0;
    final fl = int.tryParse(_floorController.text) ?? 0;
    final per = int.tryParse(_perFloorController.text) ?? 0;

    final missing = <String>[];
    if (name.isEmpty) missing.add('name');
    if (ent <= 0) missing.add('entrance');
    if (fl <= 0) missing.add('floor');
    if (per <= 0) missing.add('perFloor');
    // if (_selectedTypes.isEmpty) missing.add('types');

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

    final controller = ChessGridController.instance;
    setState(() => _isSaving = true);

    try {
      if (widget.existingBuilding != null) {
        controller.updateBuilding(widget.existingBuilding!.copyWith(
          name: name,
          entranceCount: ent,
          floorCount: fl,
          apartsPerFloor: per,
          apartmentTypes: _selectedTypes.toList(),
        ));
      } else {
        final keys = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
        final existingKeys = controller.complex.buildings.map((b) => b.key).toSet();
        final newKey = keys.firstWhere((k) => !existingKeys.contains(k), orElse: () => '${controller.complex.buildings.length + 1}');

        await controller.addBuilding(Building(
          key: newKey,
          name: name,
          residentialComplexId: controller.complex.id,
          entranceCount: ent,
          floorCount: fl,
          apartsPerFloor: per,
          apartmentTypes: _selectedTypes.toList(),
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        showCustomSnackBar(context: context, message: 'Корпус успешно сохранён', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final errText = e.toString().replaceFirst('Exception: ', '');
        showCustomSnackBar(context: context, message: errText, isSuccess: false);
      }
    }
  }
}
