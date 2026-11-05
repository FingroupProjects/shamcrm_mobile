import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_form_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/building_form_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/work_schedule_selector.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class ChessGridAdminView extends StatefulWidget {
  final ChessGridController controller;

  const ChessGridAdminView({super.key, required this.controller});

  @override
  State<ChessGridAdminView> createState() => _ChessGridAdminViewState();
}

class _ChessGridAdminViewState extends State<ChessGridAdminView> {
  int _selectedSubTab = 0; // 0=ЖК, 1=Дома, 2=Номенклатура, 3=Доп. поля

  // Complex Form Controllers
  late TextEditingController _complexNameController;
  late TextEditingController _complexAddrController;
  late TextEditingController _complexLatController;
  late TextEditingController _complexLngController;
  late TextEditingController _salesAddrController;
  late TextEditingController _salesMailController;
  late TextEditingController _salesPhoneController;
  Country? _selectedSalesCountry;
  String _formattedSalesPhone = '';
  late TextEditingController _salesHoursController;

  // Nomenclature filter
  String _nomType = 'all'; // all, flat, park
  final _nomSearchController = TextEditingController();

  // Custom field creation
  final _newFieldNameController = TextEditingController();
  String _newFieldScope = 'flat';
  String _newFieldType = 'текст';
  bool _newFieldRequired = false;

  @override
  void initState() {
    super.initState();
    final c = widget.controller.complex;
    _complexNameController = TextEditingController(text: c.name);
    _complexAddrController = TextEditingController(text: c.address);
    _complexLatController = TextEditingController(text: '${c.lat}');
    _complexLngController = TextEditingController(text: '${c.lng}');
    _salesAddrController = TextEditingController(text: c.salesOffice.address);
    _salesMailController = TextEditingController(text: c.salesOffice.email);

    final parsedPhone = parsePhoneCountryAndNumber(c.salesOffice.phone);
    _selectedSalesCountry = parsedPhone.country;
    _salesPhoneController = TextEditingController(text: parsedPhone.localNumber);
    _formattedSalesPhone = c.salesOffice.phone;

    _salesHoursController = TextEditingController(
      text: ResidentialComplex.formatScheduleString(c.salesOffice.workingHours),
    );
  }

  @override
  void dispose() {
    _complexNameController.dispose();
    _complexAddrController.dispose();
    _complexLatController.dispose();
    _complexLngController.dispose();
    _salesAddrController.dispose();
    _salesMailController.dispose();
    _salesPhoneController.dispose();
    _salesHoursController.dispose();
    _nomSearchController.dispose();
    _newFieldNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // Sub-tabs bar: [ ЖК ] [ Дома ] [ Номенклатура ] [ Доп. поля ]
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildSubTab(0, 'Жилой комплекс'),
              const SizedBox(width: 8),
              _buildSubTab(1, 'Дома (Корпуса)'),
              const SizedBox(width: 8),
              _buildSubTab(2, 'Номенклатура'),
              const SizedBox(width: 8),
              _buildSubTab(3, 'Доп. поля'),
            ],
          ),
        ),

        // Sub-tab content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            child: _buildSubTabContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTab(int index, String label) {
    final colors = context.appColors;
    final isSelected = _selectedSubTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colors.buttonPrimaryBg : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12.5,
            color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabContent(BuildContext context) {
    switch (_selectedSubTab) {
      case 0:
        return _buildComplexTab(context);
      case 1:
        return _buildBuildingsTab(context);
      case 2:
        return _buildNomenclatureTab(context);
      case 3:
        return _buildCustomFieldsTab(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: RESIDENTIAL COMPLEX (ЖК)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildComplexTab(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCard(
          title: 'Параметры жилого комплекса (ЖК)',
          child: Column(
            children: [
              _buildTextField(_complexNameController, 'Название ЖК *'),
              const SizedBox(height: 10),
              _buildTextField(_complexAddrController, 'Адрес ЖК *'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_complexLatController, 'Широта', keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(_complexLngController, 'Долгота', keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Блок: Отдел продаж',
                style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildTextField(_salesAddrController, 'Адрес офиса'),
              const SizedBox(height: 10),
              _buildTextField(_salesMailController, 'Email'),
              const SizedBox(height: 10),
              CustomPhoneNumberInput(
                controller: _salesPhoneController,
                label: 'Телефон',
                initialCountry: _selectedSalesCountry,
                onInputChanged: (val) {
                  _formattedSalesPhone = val;
                },
              ),
              const SizedBox(height: 10),
              _buildWorkingHoursField(context),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final localPhone = _salesPhoneController.text.trim();
                    final dial = _selectedSalesCountry?.dialCode ?? '';
                    final phoneToSave = _formattedSalesPhone.isNotEmpty
                        ? _formattedSalesPhone
                        : (dial.isNotEmpty && localPhone.isNotEmpty
                            ? '$dial$localPhone'
                            : localPhone);

                    final hoursToSave = ResidentialComplex.formatScheduleString(
                      _salesHoursController.text.trim(),
                    );

                    String startTime = controller.complex.startTime ?? '09:00';
                    String endTime = controller.complex.endTime ?? '18:00';
                    if (hoursToSave.contains('–') || hoursToSave.contains('-')) {
                      final sep = hoursToSave.contains('–') ? '–' : '-';
                      final parts = hoursToSave.split(sep);
                      if (parts.length >= 2) {
                        final s = ResidentialComplex.parseTime(parts[0], startTime);
                        final e = ResidentialComplex.parseTime(parts[1], endTime);
                        if (s.isNotEmpty) startTime = s;
                        if (e.isNotEmpty) endTime = e;
                      }
                    }

                    final updated = controller.complex.copyWith(
                      name: _complexNameController.text.trim(),
                      address: _complexAddrController.text.trim(),
                      lat: double.tryParse(_complexLatController.text) ?? controller.complex.lat,
                      lng: double.tryParse(_complexLngController.text) ?? controller.complex.lng,
                      salesOffice: controller.complex.salesOffice.copyWith(
                        address: _salesAddrController.text.trim(),
                        email: _salesMailController.text.trim(),
                        phone: phoneToSave,
                        workingHours: hoursToSave,
                      ),
                      startTime: startTime,
                      endTime: endTime,
                    );

                    await controller.updateComplex(updated);

                    try {
                      await controller.editComplex(
                        id: updated.id,
                        name: updated.name,
                        address: updated.address,
                        buildingCount: updated.buildingCount,
                        phone: phoneToSave,
                        email: updated.salesOffice.email,
                        salesAddress: updated.salesOffice.address,
                        workingHours: hoursToSave,
                        startTime: startTime,
                        endTime: endTime,
                        lat: updated.lat,
                        lng: updated.lng,
                      );
                    } catch (_) {}

                    if (mounted) {
                      showCustomSnackBar(context: context, message: 'Данные ЖК успешно сохранены', isSuccess: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.buttonPrimaryBg,
                    foregroundColor: colors.buttonPrimaryFg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Сохранить данные ЖК'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: BUILDINGS (ДОМА)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBuildingsTab(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;
    final buildings = controller.complex.buildings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Список корпусов (${buildings.length})',
              style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary),
            ),
            ElevatedButton.icon(
              onPressed: () => BuildingFormSheet.show(context: context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить корпус'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.buttonPrimaryBg,
                foregroundColor: colors.buttonPrimaryFg,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        for (final b in buildings) ...[
          GestureDetector(
            onTap: () => BuildingFormSheet.show(context: context, existingBuilding: b),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfacePrimary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.buttonPrimaryBg.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.domain_rounded, color: colors.buttonPrimaryBg, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name,
                          style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary),
                        ),
                        Text(
                          '${b.entranceCount} подъезда · ${b.floorCount} этажей · ${b.apartsPerFloor} кв. на этаже',
                          style: TextStyle(fontFamily: 'Golos', fontSize: 12, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Добавлено квартир: ${controller.apartments.where((a) => a.buildingKey == b.key).length} из ${b.entranceCount * b.floorCount * b.apartsPerFloor}',
                          style: TextStyle(fontFamily: 'Golos', fontSize: 11.5, color: colors.buttonPrimaryBg, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 18, color: colors.iconSecondary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3: NOMENCLATURE (НОМЕНКЛАТУРА)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNomenclatureTab(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;

    final query = _nomSearchController.text.trim().toLowerCase();

    final flatItems = controller.apartments.where((a) {
      if (_nomType == 'park') return false;
      if (query.isNotEmpty && !a.number.toLowerCase().contains(query)) return false;
      return true;
    }).toList();

    final parkItems = controller.parkingSpots.where((p) {
      if (_nomType == 'flat') return false;
      if (query.isNotEmpty && !p.number.toLowerCase().contains(query)) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top filter bar
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('Все')),
                  ButtonSegment(value: 'flat', label: Text('Квартиры')),
                  ButtonSegment(value: 'park', label: Text('Парковка')),
                ],
                selected: {_nomType},
                onSelectionChanged: (val) => setState(() => _nomType = val.first),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nomSearchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Поиск по номеру...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: colors.surfacePrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => ApartmentFormSheet.show(context: context, isParkingMode: _nomType == 'park'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.buttonPrimaryBg,
                foregroundColor: colors.buttonPrimaryFg,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of items
        for (final a in flatItems) ...[
          _buildNomRow(
            context,
            title: 'Квартира № ${a.number}',
            subtitle: '${a.buildingName}, ${a.floor} эт., ${a.rooms}к, ${a.totalArea} м²',
            price: '${a.totalPrice.toStringAsFixed(0)} \$',
            status: a.status,
            onEdit: () => ApartmentFormSheet.show(context: context, existingApartment: a),
            onDelete: () {
              final ok = controller.deleteApartment(a.id);
              if (ok) {
                showCustomSnackBar(context: context, message: 'Квартира удалена', isSuccess: true);
              } else {
                showCustomSnackBar(context: context, message: 'Нельзя удалить: есть активный заказ', isSuccess: false);
              }
            },
          ),
        ],

        for (final p in parkItems) ...[
          _buildNomRow(
            context,
            title: 'Место ${p.number}',
            subtitle: '${p.type} парковка · Корпус ${p.buildingKey} · ${p.area} м²',
            price: '${p.price.toStringAsFixed(0)} \$',
            status: p.status,
            onEdit: () => ApartmentFormSheet.show(context: context, existingParking: p),
            onDelete: () {
              final ok = controller.deleteParkingSpot(p.id);
              if (ok) {
                showCustomSnackBar(context: context, message: 'Парковка удалена', isSuccess: true);
              } else {
                showCustomSnackBar(context: context, message: 'Нельзя удалить: есть активный заказ', isSuccess: false);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNomRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required ApartmentStatus status,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13.5, color: colors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: 'Golos', fontSize: 11.5, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13.5, color: colors.buttonPrimaryBg),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: colors.iconSecondary),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: colors.error),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 4: CUSTOM FIELDS (ДОП. ПОЛЯ)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCustomFieldsTab(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;
    final fields = controller.customFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCard(
          title: 'Дополнительные поля (${fields.length})',
          child: Column(
            children: [
              for (final f in fields) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 13, color: colors.textPrimary),
                          ),
                          Text(
                            'Форма: ${f.scope == "flat" ? "Квартира" : "Заказ"} · Тип: ${f.type}',
                            style: TextStyle(fontFamily: 'Golos', fontSize: 11.5, color: colors.textSecondary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: colors.error),
                        onPressed: () {
                          controller.deleteCustomField(f.id);
                          showCustomSnackBar(context: context, message: 'Поле удалено', isSuccess: true);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildCard(
          title: 'Создать новое поле',
          child: Column(
            children: [
              _buildTextField(_newFieldNameController, 'Название поля *'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _newFieldScope,
                      decoration: const InputDecoration(labelText: 'Форма', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'flat', child: Text('Квартира')),
                        DropdownMenuItem(value: 'order', child: Text('Заказ')),
                      ],
                      onChanged: (val) => setState(() => _newFieldScope = val ?? 'flat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _newFieldType,
                      decoration: const InputDecoration(labelText: 'Тип поля', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'текст', child: Text('Текст')),
                        DropdownMenuItem(value: 'число', child: Text('Число')),
                        DropdownMenuItem(value: 'дата', child: Text('Дата')),
                        DropdownMenuItem(value: 'флажок', child: Text('Флажок')),
                      ],
                      onChanged: (val) => setState(() => _newFieldType = val ?? 'текст'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text('Обязательно для заполнения', style: TextStyle(fontFamily: 'Golos', fontSize: 12)),
                value: _newFieldRequired,
                onChanged: (val) => setState(() => _newFieldRequired = val ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = _newFieldNameController.text.trim();
                    if (name.isEmpty) {
                      showCustomSnackBar(context: context, message: 'Укажите название поля', isSuccess: false);
                      return;
                    }
                    controller.addCustomField(CustomField(
                      id: DateTime.now().millisecondsSinceEpoch,
                      scope: _newFieldScope,
                      name: name,
                      type: _newFieldType,
                      isRequired: _newFieldRequired,
                    ));
                    _newFieldNameController.clear();
                    showCustomSnackBar(context: context, message: 'Поле добавлено', isSuccess: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.buttonPrimaryBg,
                    foregroundColor: colors.buttonPrimaryFg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Добавить поле'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildWorkingHoursField(BuildContext context) {
    final colors = context.appColors;
    return CustomTextField(
      controller: _salesHoursController,
      label: 'Режим работы',
      hintText: 'Например: Пн–Пт: 09:00 – 18:00',
      suffixIcon: IconButton(
        icon: Icon(Icons.edit_calendar_rounded, color: colors.buttonPrimaryBg, size: 20),
        tooltip: 'Настроить режим работы',
        onPressed: () async {
          final res = await WorkScheduleSelector.showPickerBottomSheet(
            context: context,
            currentSchedule: _salesHoursController.text.trim(),
          );
          if (res != null && res.isNotEmpty) {
            setState(() {
              _salesHoursController.text = res;
            });
          }
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: 'Введите ${label.toLowerCase()}',
      keyboardType: keyboardType ?? TextInputType.text,
    );
  }
}
