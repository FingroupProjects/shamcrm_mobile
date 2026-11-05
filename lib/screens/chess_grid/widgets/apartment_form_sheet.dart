import 'dart:io';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization/localization_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/field/field_configuration.dart';
import 'package:crm_task_manager/models/field/main_field_model.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart' as crm_fields;
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
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
  List<SupplierCurrency> _currencies = [];
  SupplierCurrency? _selectedCurrency;
  bool _isCurrenciesLoading = true;
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

  static const String _fieldTable = 'goods';
  static const String _fieldModelType = 'good';
  final _apiService = ApiService();
  final GlobalKey _addFieldButtonKey = GlobalKey();
  bool _isSettingsMode = false;
  bool _isSavingFieldOrder = false;
  bool _isFieldsLoading = false;
  List<FieldConfiguration> _fieldConfigurations = [];
  List<FieldConfiguration>? _originalFieldConfigurations;
  final List<crm_fields.CustomField> _crmFields = [];

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
    _loadCurrencies();
    _loadGoodsFieldConfiguration();

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

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await ApiService().getCurrencies();
      final localizationCurrencyId = await LocalizationService.getCurrencyId();
      if (!mounted) return;

      SupplierCurrency? matched;
      final saved = widget.existingApartment?.currency.trim().toLowerCase() ?? '';
      if (saved.isNotEmpty) {
        for (final currency in currencies) {
          final name = (currency.name ?? '').trim().toLowerCase();
          final symbol = (currency.symbolCode ?? '').trim().toLowerCase();
          if (saved == name ||
              saved == symbol ||
              saved == '$name ($symbol)' ||
              (saved == '\$' && (symbol == 'usd' || symbol == '\$')) ||
              (saved == '€' && (symbol == 'eur' || symbol == '€')) ||
              (saved == 'сом.' && symbol.contains('tjs')) ||
              (saved == 'руб.' && (symbol == 'rub' || symbol == 'руб'))) {
            matched = currency;
            break;
          }
        }
      }
      if (matched == null && localizationCurrencyId != null) {
        for (final currency in currencies) {
          if (currency.id == localizationCurrencyId) {
            matched = currency;
            break;
          }
        }
      }

      setState(() {
        _currencies = currencies;
        _selectedCurrency = matched ?? (currencies.isNotEmpty ? currencies.first : null);
        if (_selectedCurrency != null) {
          _currency = _currencyCodeOf(_selectedCurrency!);
        }
      });
    } catch (_) {
      // Список валют не должен блокировать сохранение квартиры.
    } finally {
      if (mounted) setState(() => _isCurrenciesLoading = false);
    }
  }

  String _currencyCodeOf(SupplierCurrency currency) {
    final symbol = currency.symbolCode?.trim() ?? '';
    if (symbol.isNotEmpty) return symbol;
    final name = currency.name?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return _currency;
  }

  String _currencyTitleOf(SupplierCurrency currency) {
    final name = currency.name?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final symbol = currency.symbolCode?.trim() ?? '';
    if (symbol.isNotEmpty) return symbol;
    return '-';
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

  Widget _buildPlanPhotoTile(int idx) {
    final colors = context.appColors;
    final path = _planImages[idx];
    final isLocal = File(path).existsSync();
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 88,
              height: 88,
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
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _planImages.removeAt(idx)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.overlay,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: colors.textInverse, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
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
    for (final field in _crmFields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGoodsFieldConfiguration() async {
    setState(() => _isFieldsLoading = true);
    try {
      final response = await _apiService.getFieldPositions(tableName: _fieldTable);
      if (!mounted) return;
      setState(() {
        _fieldConfigurations = response.result.toList()
          ..sort((a, b) => a.position.compareTo(b.position));
      });
    } catch (error) {
      debugPrint('ApartmentFormSheet fields: $error');
    } finally {
      if (mounted) setState(() => _isFieldsLoading = false);
    }
  }

  FieldConfiguration _copyField(
    FieldConfiguration config, {
    int? position,
    bool? isActive,
  }) {
    return FieldConfiguration(
      id: config.id,
      tableName: config.tableName,
      fieldName: config.fieldName,
      position: position ?? config.position,
      required: false,
      isActive: isActive ?? config.isActive,
      isCustomField: config.isCustomField,
      createdAt: config.createdAt,
      updatedAt: config.updatedAt,
      customFieldId: config.customFieldId,
      directoryId: config.directoryId,
      type: config.type,
      isDirectory: config.isDirectory,
      showOnTable: config.showOnTable,
      showOnSite: config.showOnSite,
      originalRequired: config.originalRequired,
    );
  }

  bool _hasFieldChanges() {
    final original = _originalFieldConfigurations;
    if (original == null) return false;
    if (original.length != _fieldConfigurations.length) return true;
    for (final current in _fieldConfigurations) {
      final previous = original.cast<FieldConfiguration?>().firstWhere(
            (field) => field?.id == current.id,
            orElse: () => null,
          );
      if (previous == null) return true;
      if (current.position != previous.position || current.isActive != previous.isActive) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _confirmLeaveSettings() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.appColors;
        return AlertDialog(
          backgroundColor: colors.surfacePrimary,
          title: Text(
            context.tr('warning', fallback: 'Внимание'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            context.tr(
              'position_changes_will_not_be_saved',
              fallback: 'Изменения позиций полей не сохранятся',
            ),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: colors.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('cancel', fallback: 'Отмена')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('dont_save', fallback: 'Не сохранять')),
            ),
          ],
        );
      },
    );
    return leave ?? false;
  }

  Future<void> _toggleFieldSettings() async {
    if (_isSettingsMode) {
      if (_hasFieldChanges()) {
        final leave = await _confirmLeaveSettings();
        if (!leave || !mounted) return;
        final original = _originalFieldConfigurations;
        setState(() {
          if (original != null) {
            final fresh = _fieldConfigurations.where(
              (current) => !original.any((saved) => saved.id == current.id),
            );
            _fieldConfigurations = [
              ...original,
              ...fresh.map((field) => _copyField(field)),
            ];
          }
          _originalFieldConfigurations = null;
          _isSettingsMode = false;
        });
      } else {
        setState(() {
          _originalFieldConfigurations = null;
          _isSettingsMode = false;
        });
      }
      return;
    }

    setState(() {
      _originalFieldConfigurations = _fieldConfigurations.map(_copyField).toList();
      _isSettingsMode = true;
    });
  }

  Future<void> _saveFieldOrder() async {
    setState(() => _isSavingFieldOrder = true);
    try {
      await _apiService.updateFieldPositions(
        tableName: _fieldTable,
        updates: [
          for (final config in _fieldConfigurations)
            {
              'id': config.id,
              'position': config.position,
              'is_active': config.isActive ? 1 : 0,
              'is_required': config.originalRequired ? 1 : 0,
              'show_on_table': config.showOnTable ? 1 : 0,
            },
        ],
      );
      if (!mounted) return;
      setState(() {
        _originalFieldConfigurations = null;
        _isSettingsMode = false;
      });
      showCustomSnackBar(
        context: context,
        message: context.tr('field_settings_saved', fallback: 'Настройки полей сохранены'),
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: context.tr('field_settings_save_error', fallback: 'Ошибка сохранения настроек полей'),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isSavingFieldOrder = false);
    }
  }

  crm_fields.CustomField _crmFieldFor(FieldConfiguration config) {
    if (config.isDirectory && config.directoryId != null) {
      final existing = _crmFields.cast<crm_fields.CustomField?>().firstWhere(
            (field) => field?.directoryId == config.directoryId,
            orElse: () => null,
          );
      if (existing != null) return existing;
      final created = crm_fields.CustomField(
        fieldName: config.fieldName,
        isDirectoryField: true,
        directoryId: config.directoryId,
        controller: TextEditingController(),
      );
      _crmFields.add(created);
      return created;
    }

    final existing = _crmFields.cast<crm_fields.CustomField?>().firstWhere(
          (field) => field?.isCustomField == true && field?.fieldName == config.fieldName,
          orElse: () => null,
        );
    if (existing != null) return existing;
    final created = crm_fields.CustomField(
      fieldName: config.fieldName,
      controller: TextEditingController(),
      type: config.type,
      isCustomField: true,
    );
    _crmFields.add(created);
    return created;
  }

  Future<void> _addCrmField(
    String fieldName, {
    bool isDirectory = false,
    int? directoryId,
    String? type,
  }) async {
    if (isDirectory && directoryId != null) {
      final alreadyAdded = _fieldConfigurations.any(
        (field) => field.isDirectory && field.directoryId == directoryId,
      );
      if (alreadyAdded) {
        showCustomSnackBar(
          context: context,
          message: context.tr('directory_already_added', fallback: 'Справочник уже добавлен'),
          isSuccess: false,
        );
        return;
      }
      try {
        final organizationId = await _apiService.getSelectedOrganization();
        await _apiService.linkDirectory(
          directoryId: directoryId,
          modelType: _fieldModelType,
          organizationId: organizationId ?? '',
        );
        if (!mounted) return;
        showCustomSnackBar(
          context: context,
          message: context.tr('directory_added', fallback: 'Справочник успешно добавлен'),
          isSuccess: true,
        );
        await _loadGoodsFieldConfiguration();
      } catch (error) {
        if (!mounted) return;
        showCustomSnackBar(context: context, message: error.toString(), isSuccess: false);
      }
      return;
    }

    try {
      await _apiService.addNewField(
        tableName: _fieldTable,
        fieldName: fieldName,
        fieldType: type ?? 'string',
      );
      if (!mounted) return;
      await _loadGoodsFieldConfiguration();
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: '${context.tr('add_field_error', fallback: 'Ошибка при добавлении поля')}: $error',
        isSuccess: false,
      );
    }
  }

  Future<void> _showAddFieldMenu() async {
    final box = _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    RelativeRect position = const RelativeRect.fromLTRB(24, 120, 24, 0);
    if (box != null && overlay != null) {
      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
      position = RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy + box.size.height + 8,
        overlay.size.width - topLeft.dx - box.size.width,
        overlay.size.height - topLeft.dy - box.size.height,
      );
    }

    final choice = await showMenu<String>(
      context: context,
      position: position,
      color: context.appColors.fieldBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'manual',
          child: Text(
            context.tr('manual_input', fallback: 'Ручной ввод'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'directory',
          child: Text(
            context.tr('directory', fallback: 'Справочник'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
      ],
    );
    if (!mounted || choice == null) return;

    if (choice == 'manual') {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AddCustomFieldDialog(
          onAddField: (fieldName, {String? type}) {
            if (type != null) _addCrmField(fieldName, type: type);
          },
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AddCustomDirectoryDialog(
        onAddDirectory: (directory) {
          _addCrmField(directory.name, isDirectory: true, directoryId: directory.id);
        },
      ),
    );
  }

  String _fieldTypeLabel(FieldConfiguration config) {
    if (config.isDirectory) return context.tr('directory', fallback: 'Справочник');
    if (config.isCustomField) return context.tr('custom_field', fallback: 'Пользовательское поле');
    return context.tr('system_field', fallback: 'Системное поле');
  }

  Widget _buildConfiguredFields() {
    final visible = _fieldConfigurations.where(
      (field) => field.isActive && (field.isCustomField || field.isDirectory),
    );
    if (_isFieldsLoading || visible.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final config in visible) ...[
          if (config.isDirectory && config.directoryId != null)
            MainFieldDropdownWidget(
              directoryId: config.directoryId!,
              directoryName: config.fieldName,
              selectedField: null,
              controller: _crmFieldFor(config).controller,
              initialEntryIds: _crmFieldFor(config).selectedEntryIds,
              onSelectField: (List<MainField> selected) {
                final current = _crmFieldFor(config);
                final index = _crmFields.indexWhere((field) => field.directoryId == config.directoryId);
                if (index == -1) return;
                setState(() {
                  _crmFields[index] = current.copyWith(
                    entryIds: selected.map((item) => item.id).toList(),
                    controller: TextEditingController(
                      text: selected.map((item) => item.value).join(', '),
                    ),
                  );
                });
              },
              onSelectEntryId: (List<int> entryIds) {
                final current = _crmFieldFor(config);
                final index = _crmFields.indexWhere((field) => field.directoryId == config.directoryId);
                if (index == -1) return;
                setState(() {
                  _crmFields[index] = current.copyWith(entryIds: entryIds);
                });
              },
            )
          else
            CustomFieldWidget(
              fieldName: config.fieldName,
              valueController: _crmFieldFor(config).controller,
              type: config.type,
              isCustomField: true,
            ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildFieldSettings() {
    final colors = context.appColors;
    final sorted = [..._fieldConfigurations]..sort((a, b) => a.position.compareTo(b.position));

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: sorted.length + 1,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex >= sorted.length) return;
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                if (newIndex >= sorted.length) newIndex = sorted.length - 1;
                final item = sorted.removeAt(oldIndex);
                sorted.insert(newIndex, item);
                _fieldConfigurations = [
                  for (var i = 0; i < sorted.length; i++) _copyField(sorted[i], position: i + 1),
                ];
              });
            },
            itemBuilder: (context, index) {
              if (index == sorted.length) {
                return Container(
                  key: _addFieldButtonKey,
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  child: CustomButton(
                    buttonText: context.tr('add_field', fallback: 'Добавить поле'),
                    buttonColor: colors.fieldBg,
                    textColor: colors.textPrimary,
                    onPressed: _showAddFieldMenu,
                  ),
                );
              }

              final config = sorted[index];
              return Container(
                key: ValueKey('goods_field_${config.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.drag_handle, color: colors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.fieldName,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fieldTypeLabel(config),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                final updated = _copyField(config, isActive: !config.isActive);
                                final fieldIndex = _fieldConfigurations.indexWhere((field) => field.id == config.id);
                                if (fieldIndex != -1) _fieldConfigurations[fieldIndex] = updated;
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: config.isActive ? colors.buttonPrimaryBg : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: config.isActive ? colors.buttonPrimaryBg : colors.borderSubtle,
                                      width: 2,
                                    ),
                                  ),
                                  child: config.isActive
                                      ? Icon(Icons.check_rounded, size: 16, color: colors.textInverse)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  context.tr('show_field', fallback: 'Показать поле'),
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: CustomButton(
            buttonText: _isSavingFieldOrder
                ? context.tr('saving', fallback: 'Сохранение...')
                : context.tr('save', fallback: 'Сохранить'),
            buttonColor: colors.buttonPrimaryBg,
            textColor: colors.buttonPrimaryFg,
            onPressed: _isSavingFieldOrder ? () {} : _saveFieldOrder,
          ),
        ),
      ],
    );
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
                Expanded(
                  child: Text(
                    _isSettingsMode
                        ? context.tr('field_settings', fallback: 'Настройка полей')
                        : isEditing
                            ? context.tr('chess_grid_edit_item', fallback: 'Редактировать товар')
                            : context.tr('chess_grid_add_to_catalog', fallback: 'Добавить в номенклатуру'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _isSettingsMode
                      ? context.tr('close', fallback: 'Закрыть')
                      : context.tr('settings', fallback: 'Настройки'),
                  onPressed: _toggleFieldSettings,
                  icon: Icon(
                    _isSettingsMode ? Icons.close_rounded : Icons.settings_rounded,
                    color: colors.iconSecondary,
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
            child: _isSettingsMode
                ? _buildFieldSettings()
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Type Switcher (Only when adding)
                  if (!isEditing) ...[
                    Row(
                      children: [
                        _buildTypeTab(
                          label: context.tr('chess_grid_apartment_tab', fallback: 'Квартира'),
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
                          label: context.tr('chess_grid_parking_tab', fallback: 'Парковка'),
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
                    label: context.tr('chess_grid_building', fallback: 'Корпус'),
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
                    message: _isParking
                        ? context.tr('chess_grid_specify_number', fallback: 'Укажите номер')
                        : context.tr('chess_grid_specify_apt_number', fallback: 'Укажите номер квартиры'),
                    child: CustomTextField(
                      controller: _numberController,
                      label: _isParking
                          ? context.tr('chess_grid_parking_number_required', fallback: 'Номер парковки *')
                          : context.tr('chess_grid_apt_number', fallback: 'Номер квартиры *'),
                      hintText: _isParking
                          ? context.tr('chess_grid_enter_number', fallback: 'Введите номер')
                          : context.tr('chess_grid_enter_apt_number', fallback: 'Введите номер квартиры'),
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
                    label: context.tr('chess_grid_status', fallback: 'Статус'),
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
                            Text(s.localizedLabel(context)),
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
                            label: _isLoadingEntrances
                                ? '${context.tr('chess_grid_entrance_label', fallback: 'Подъезд')}...'
                                : context.tr('chess_grid_entrance_label', fallback: 'Подъезд'),
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
                        : _buildNumberSearchDropdown(
                            label: _isLoadingEntrances
                                ? '${context.tr('chess_grid_entrance_label', fallback: 'Подъезд')}...'
                                : context.tr('chess_grid_entrance_label', fallback: 'Подъезд'),
                            value: _entrance,
                            count: building?.entranceCount ?? 1,
                            onChanged: (val) => setState(() => _entrance = val),
                          ),
                    const SizedBox(height: 14),

                    _buildNumberSearchDropdown(
                      label: context.tr('chess_grid_floor', fallback: 'Этаж'),
                      value: _floor,
                      count: building?.floorCount ?? 9,
                      onChanged: (val) => setState(() => _floor = val),
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _roomsController,
                      label: context.tr('chess_grid_rooms_count_label', fallback: 'Количество комнат'),
                      hintText: context.tr('chess_grid_enter_count', fallback: 'Введите кол-во'),
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
                      message: context.tr('chess_grid_specify_area', fallback: 'Укажите площадь'),
                      child: CustomTextField(
                        controller: _totalAreaController,
                        label: '${context.tr('chess_grid_total_area', fallback: 'Общая')}, м² *',
                        hintText: context.tr('chess_grid_enter_area', fallback: 'Введите площадь'),
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
                      label: '${context.tr('chess_grid_living_area', fallback: 'Жилая')}, м²',
                      hintText: context.tr('chess_grid_enter_area', fallback: 'Введите площадь'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _kitchenAreaController,
                      label: '${context.tr('chess_grid_kitchen_area', fallback: 'Кухня')}, м²',
                      hintText: context.tr('chess_grid_enter_area', fallback: 'Введите площадь'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),

                    // [Тип планировки, балконы и санузлы скрыты по требованию]
                    // CustomTextField(
                    //   controller: _layoutTypeController,
                    //   label: context.tr('chess_grid_layout_type', fallback: 'Тип планировки'),
                    //   hintText: 'A, B, C...',
                    // ),
                    // const SizedBox(height: 14),
                    //
                    // CustomTextField(
                    //   controller: _balconiesController,
                    //   label: context.tr('chess_grid_balconies', fallback: 'Балконов / лоджий'),
                    //   hintText: '0, 1...',
                    //   keyboardType: TextInputType.number,
                    // ),
                    // const SizedBox(height: 14),
                    //
                    // CustomTextField(
                    //   controller: _bathroomsController,
                    //   label: context.tr('chess_grid_bathrooms', fallback: 'Санузлов'),
                    //   hintText: '1, 2...',
                    //   keyboardType: TextInputType.number,
                    // ),
                    // const SizedBox(height: 14),

                    RequiredFieldSlot(
                      invalid: _missingFields.contains('pricePerM2'),
                      focus: _firstMissingField == 'pricePerM2',
                      pulse: _fieldErrorPulse,
                      message: context.tr('chess_grid_specify_price', fallback: 'Укажите цену'),
                      child: CustomTextField(
                        controller: _pricePerM2Controller,
                        label: '${context.tr('chess_grid_price_per_sqm', fallback: 'Цена за м²')} *',
                        hintText: context.tr('chess_grid_specify_price', fallback: 'Введите цену'),
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
                      message: context.tr('chess_grid_specify_amount', fallback: 'Укажите сумму'),
                      child: CustomTextField(
                        controller: _totalPriceController,
                        label: '${context.tr('chess_grid_total_price', fallback: 'Общая цена')} *',
                        hintText: context.tr('chess_grid_enter_amount', fallback: 'Введите сумму'),
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

                    _buildCurrencyDropdown(),
                    const SizedBox(height: 14),

                    // Photos of Floor Plan Section — same drop zone as goods create
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('chess_grid_layout_photos', fallback: 'Фотографии планировки'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _pickPlanImages,
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(minHeight: _planImages.isEmpty ? 140 : 0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.borderSubtle, width: 1.5),
                            ),
                            child: _planImages.isEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, color: colors.textMuted, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('pick_image', fallback: 'Нажмите для загрузки фото'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  )
                                : Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      for (var idx = 0; idx < _planImages.length; idx++)
                                        _buildPlanPhotoTile(idx),
                                      GestureDetector(
                                        onTap: _pickPlanImages,
                                        child: Container(
                                          width: 88,
                                          height: 88,
                                          decoration: BoxDecoration(
                                            color: colors.backgroundSecondary,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: colors.borderSubtle),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo, color: colors.textMuted, size: 28),
                                              const SizedBox(height: 4),
                                              Text(
                                                context.tr('add', fallback: 'Добавить'),
                                                style: TextStyle(fontSize: 10, color: colors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // [Дополнительные поля скрыты по требованию: вид из окна, высота потолков]
                    // if (_customFieldControllers.isNotEmpty) ...[
                    //   const SizedBox(height: 6),
                    //   Text(
                    //     'Дополнительные поля',
                    //     style: TextStyle(
                    //       fontFamily: 'Gilroy',
                    //       fontWeight: FontWeight.w700,
                    //       fontSize: 13.5,
                    //       color: colors.buttonPrimaryBg,
                    //     ),
                    //   ),
                    //   const SizedBox(height: 8),
                    //   for (final cf in controller.customFields.where((f) => f.scope == 'flat')) ...[
                    //     if (cf.isRequired)
                    //       RequiredFieldSlot(
                    //         invalid: _missingFields.contains('custom_${cf.id}'),
                    //         focus: _firstMissingField == 'custom_${cf.id}',
                    //         pulse: _fieldErrorPulse,
                    //         message: 'Поле «${cf.name}» обязательно',
                    //         child: CustomTextField(
                    //           controller: _customFieldControllers[cf.id]!,
                    //           label: '${cf.name} *',
                    //           hintText: 'Введите ${cf.name.toLowerCase()}',
                    //           keyboardType: cf.type == 'number' ? TextInputType.number : TextInputType.text,
                    //           hasError: _missingFields.contains('custom_${cf.id}'),
                    //           onChanged: (val) {
                    //             if (val.trim().isNotEmpty && _missingFields.contains('custom_${cf.id}')) {
                    //               setState(() {
                    //                 _missingFields.remove('custom_${cf.id}');
                    //                 if (_firstMissingField == 'custom_${cf.id}') _firstMissingField = null;
                    //               });
                    //             }
                    //           },
                    //         ),
                    //       )
                    //     else
                    //       CustomTextField(
                    //         controller: _customFieldControllers[cf.id]!,
                    //         label: cf.name,
                    //         hintText: 'Введите ${cf.name.toLowerCase()}',
                    //         keyboardType: cf.type == 'number' ? TextInputType.number : TextInputType.text,
                    //       ),
                    //     const SizedBox(height: 10),
                    //   ],
                    //   const SizedBox(height: 6),
                    // ],
                    _buildConfiguredFields(),
                    const SizedBox(height: 14),

                    // Copy to other floors feature (from TZ section 3)
                    if (!isEditing) ...[
                      CheckboxListTile(
                        value: _copyToFloors,
                        onChanged: (val) => setState(() => _copyToFloors = val ?? false),
                        title: Text(
                          context.tr('chess_grid_copy_to_other_floors', fallback: 'Скопировать на другие этажи этого подъезда'),
                          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          context.tr('chess_grid_copy_floors_subtitle', fallback: 'Данные сохранятся, номера присвоятся автоматически'),
                          style: const TextStyle(fontFamily: 'Golos', fontSize: 11),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_copyToFloors) ...[
                        CustomTextField(
                          controller: _copyFloorsController,
                          label: context.tr('chess_grid_floor_numbers_label', fallback: 'Номера этажей (например: 2-9 или 2,4,6)'),
                          hintText: context.tr('chess_grid_enter_floors', fallback: 'Введите этажи'),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ] else ...[
                    // PARKING FIELDS
                    _buildDropdown<String>(
                      label: context.tr('chess_grid_parking_type', fallback: 'Тип парковки'),
                      value: _parkingType,
                      items: [
                        DropdownMenuItem(
                          value: 'Подземная',
                          child: Text(context.tr('chess_grid_parking_underground', fallback: 'Подземная')),
                        ),
                        DropdownMenuItem(
                          value: 'Открытая',
                          child: Text(context.tr('chess_grid_parking_open', fallback: 'Открытая')),
                        ),
                        DropdownMenuItem(
                          value: 'Закрытая',
                          child: Text(context.tr('chess_grid_parking_closed', fallback: 'Закрытая')),
                        ),
                      ],
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
                            label: '${context.tr('chess_grid_area', fallback: 'Площадь')}, м²',
                            hintText: context.tr('chess_grid_enter_area', fallback: 'Введите площадь'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RequiredFieldSlot(
                            invalid: _missingFields.contains('parkingPrice'),
                            focus: _firstMissingField == 'parkingPrice',
                            pulse: _fieldErrorPulse,
                            message: context.tr('chess_grid_specify_price', fallback: 'Укажите цену'),
                            child: CustomTextField(
                              controller: _totalPriceController,
                              label: '${context.tr('chess_grid_price', fallback: 'Цена')} *',
                              hintText: context.tr('chess_grid_specify_price', fallback: 'Введите цену'),
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
                      label: context.tr('chess_grid_link_to_apartment', fallback: 'Привязка к квартире'),
                      value: _linkedApartmentId,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.tr('chess_grid_no_link', fallback: 'Без привязки')),
                        ),
                        ...controller.apartments.where((a) => a.buildingKey == _buildingKey).map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${context.tr('chess_grid_apartment_num', fallback: 'Кв. №')} ${a.number} (${a.floor} ${context.tr('chess_grid_floor_short', fallback: 'эт.')})'),
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
                        isEditing
                            ? context.tr('chess_grid_save_changes', fallback: 'Сохранить изменения')
                            : context.tr('chess_grid_action_add', fallback: 'Добавить'),
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

  Future<void> _saveParking({
    required ChessGridController controller,
    required String number,
    required double price,
    required double area,
  }) async {
    final building = controller.complex.buildings.firstWhereOrNull((item) => item.key == _buildingKey);
    if (widget.existingParking == null && building?.id == null) {
      showCustomSnackBar(
        context: context,
        message: 'У корпуса нет building_id, парковку создать нельзя',
        isSuccess: false,
      );
      return;
    }

    try {
      if (widget.existingParking != null) {
        controller.updateParkingSpot(widget.existingParking!.copyWith(
          number: number,
          buildingKey: _buildingKey,
          buildingId: building?.id,
          type: _parkingType,
          price: price,
          area: area,
          status: _status,
          linkedApartmentId: _linkedApartmentId,
        ));
      } else {
        await controller.addParkingSpot(ParkingSpot(
          id: 0,
          complexId: controller.complex.id,
          buildingId: building?.id,
          number: number,
          type: _parkingType,
          buildingKey: _buildingKey,
          price: price,
          area: area,
          status: _status,
          linkedApartmentId: _linkedApartmentId,
        ));
      }
      if (!mounted) return;
      Navigator.pop(context);
      showCustomSnackBar(context: context, message: 'Парковочное место сохранено', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    }
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
      // Дополнительные поля скрыты, обязательность по ним не проверяем.
      // for (final cf in controller.customFields.where((f) => f.scope == 'flat' && f.isRequired)) {
      //   final ctrl = _customFieldControllers[cf.id];
      //   if (ctrl == null || ctrl.text.trim().isEmpty) {
      //     missing.add('custom_${cf.id}');
      //   }
      // }
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
        message: context.tr('chess_grid_fill_required', fallback: 'Заполните обязательные поля'),
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
      _saveParking(
        controller: controller,
        number: no,
        price: price,
        area: area,
      );
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

  Widget _buildCurrencyDropdown() {
    final colors = context.appColors;
    final label = context.tr('chess_grid_currency_label', fallback: 'Валюта');
    SupplierCurrency? initialCurrency;
    if (_selectedCurrency?.id != null) {
      for (final currency in _currencies) {
        if (currency.id == _selectedCurrency!.id) {
          initialCurrency = currency;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (_isCurrenciesLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: colors.fieldBg,
              borderRadius: AppFieldStyle.radius,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Text(
              context.tr('loading', fallback: 'Загрузка...'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          )
        else
          CustomDropdown<SupplierCurrency>.search(
            key: ValueKey('currency-${initialCurrency?.id}-${_currencies.length}'),
            items: _currencies,
            initialItem: initialCurrency,
            enabled: _currencies.isNotEmpty,
            excludeSelected: false,
            canClear: false,
            overlayHeight: 240,
            searchHintText: context.tr('search', fallback: 'Поиск'),
            noResultFoundText: context.tr('nothing_found', fallback: 'Ничего не найдено'),
            listItemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: AppFieldStyle.dropdownDecoration(context),
            listItemBuilder: (context, item, isSelected, onItemSelect) => Text(
              _currencyTitleOf(item),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            ),
            headerBuilder: (context, selectedItem, enabled) => Text(
              selectedItem == null
                  ? context.tr('select_currency', fallback: 'Выберите валюту')
                  : _currencyTitleOf(selectedItem),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            hintBuilder: (context, hint, enabled) => Text(
              _currencies.isEmpty
                  ? context.tr('nothing_found', fallback: 'Ничего не найдено')
                  : context.tr('select_currency', fallback: 'Выберите валюту'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textSecondary,
              ),
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedCurrency = value;
                _currency = _currencyCodeOf(value);
              });
            },
          ),
      ],
    );
  }

  Widget _buildNumberSearchDropdown({
    required String label,
    required int value,
    required int count,
    required ValueChanged<int> onChanged,
  }) {
    final colors = context.appColors;
    final total = count < 1 ? 1 : count;
    final selected = value.clamp(1, total);
    final items = List<int>.generate(total, (index) => index + 1);

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
        CustomDropdown<int>.search(
          key: ValueKey('$label-$total-$selected'),
          items: items,
          initialItem: selected,
          excludeSelected: false,
          canClear: false,
          overlayHeight: 240,
          listItemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          searchHintText: context.tr('search', fallback: 'Поиск'),
          noResultFoundText: context.tr('nothing_found', fallback: 'Ничего не найдено'),
          decoration: AppFieldStyle.dropdownDecoration(context),
          onChanged: (picked) {
            if (picked != null) onChanged(picked);
          },
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
          menuMaxHeight: 240,
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

