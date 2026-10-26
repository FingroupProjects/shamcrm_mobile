import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
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
  final _entranceController = TextEditingController(text: '2');
  final _floorController = TextEditingController(text: '9');
  final _perFloorController = TextEditingController(text: '4');
  final _customTypeController = TextEditingController();
  bool _isSaving = false;

  static const List<String> _defaultTypes = ['Студия', 'Евроремонт', 'Предчистовая', 'Черновая'];
  final List<String> _availableTypes = ['Студия', 'Евроремонт', 'Предчистовая', 'Черновая'];
  final Set<String> _selectedTypes = {'Студия', 'Евроремонт'};

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
    } else {
      final controller = ChessGridController.instance;
      final nextLetter = ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З'][controller.complex.buildings.length % 8];
      _nameController.text = 'Корпус $nextLetter';
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
                  _buildTextField(
                    controller: _nameController,
                    label: 'Название корпуса *',
                    hint: 'Блок А, Корпус 1 и т.д.',
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _entranceController,
                          label: 'Подъездов *',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _floorController,
                          label: 'Этажей *',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _perFloorController,
                          label: 'Кв. на этаже *',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Apartment Types Multiselect (TZ section 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Тип квартир (мульти-селект) *',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Выбрано: ${_selectedTypes.length}',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Interactive chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTypes.map((t) => _buildTypeChip(t)).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Add custom type
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customTypeController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addCustomType(),
                          style: TextStyle(fontFamily: 'Golos', fontSize: 13, color: colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Свой тип, например: Пентхаус',
                            hintStyle: TextStyle(fontFamily: 'Golos', fontSize: 13, color: colors.textSecondary),
                            isDense: true,
                            filled: true,
                            fillColor: colors.surfaceElevated.withValues(alpha: 0.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.borderSubtle),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.borderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.buttonPrimaryBg, width: 1.5),
                            ),
                          ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildTypeChip(String type) {
    final colors = context.appColors;
    final isSelected = _selectedTypes.contains(type);
    final isCustom = !_defaultTypes.contains(type);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTypes.remove(type);
          } else {
            _selectedTypes.add(type);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonPrimaryBg
              : colors.surfaceElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_rounded,
                size: 15,
                color: colors.buttonPrimaryFg,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              type,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
              ),
            ),
            if (isCustom) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _availableTypes.remove(type);
                    _selectedTypes.remove(type);
                  });
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: isSelected
                      ? colors.buttonPrimaryFg.withValues(alpha: 0.8)
                      : colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showCustomSnackBar(context: context, message: 'Укажите название корпуса', isSuccess: false);
      return;
    }

    final ent = int.tryParse(_entranceController.text) ?? 1;
    final fl = int.tryParse(_floorController.text) ?? 9;
    final per = int.tryParse(_perFloorController.text) ?? 4;

    if (ent <= 0) {
      showCustomSnackBar(context: context, message: 'Количество подъездов должно быть больше 0', isSuccess: false);
      return;
    }
    if (fl <= 0) {
      showCustomSnackBar(context: context, message: 'Количество этажей должно быть больше 0', isSuccess: false);
      return;
    }
    if (per <= 0) {
      showCustomSnackBar(context: context, message: 'Количество квартир на этаже должно быть больше 0', isSuccess: false);
      return;
    }
    if (_selectedTypes.isEmpty) {
      showCustomSnackBar(context: context, message: 'Выберите хотя бы один тип квартир', isSuccess: false);
      return;
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.buttonPrimaryBg, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
