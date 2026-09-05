import 'dart:io';

import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/custom_widget/delete_file_dialog.dart'
    show DeleteFileDialog;
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field/field_configuration.dart';
import 'package:crm_task_manager/models/deal/dealById_model.dart';
import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/models/common/file_helper.dart';
import 'package:crm_task_manager/models/field/main_field_model.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_list_edit.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_name_list.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:crm_task_manager/models/task/directory_model.dart'
    as directory_model;
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';

class DealEditScreen extends StatefulWidget {
  final int dealId;
  final String dealName;
  final String? manager;
  final String? currency;
  final String? lead;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? description;
  final String? sum;
  final int statusId;
  // final List<DealCustomFieldsById> dealCustomFields;
  final List<DirectoryValue>? directoryValues;
  final List<DealFiles>? files;
  final List<DealStatusById>? dealStatuses; // ✅ НОВОЕ: массив статусов
  final DealById? dealById; // ✅ НОВОЕ: добавьте полный объект deal
  final List<DealUser>? users; // ✅ НОВОЕ: список пользователей

  DealEditScreen({
    required this.dealId,
    required this.dealName,
    required this.statusId,
    this.manager,
    this.currency,
    this.lead,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.description,
    this.sum,
    // required this.dealCustomFields,
    this.directoryValues,
    this.files,
    this.dealStatuses, // ✅ ДОБАВЬТЕ ЭТУ СТРОКУ В КОНСТРУКТОР!
    this.users, // ✅ НОВОЕ
    this.dealById, // ✅ ДОБАВЬТЕ ЭТУ СТРОКУ В КОНСТРУКТОР!
  });

  @override
  _DealEditScreenState createState() => _DealEditScreenState();
}

class _DealEditScreenState extends State<DealEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController sumController = TextEditingController();
  final ApiService _apiService = ApiService();

  int? _selectedStatuses;
  String? selectedManager;
  String? selectedLead;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
  List<DealFiles> existingFiles = [];
  List<String> newFiles = [];
  List<int> _selectedStatusIds = []; // ✅ НОВОЕ: список выбранных ID
  List<String>? selectedUsers; // ✅ НОВОЕ: список выбранных пользователей
  List<FileHelper> files = [];
  // Конфигурация полей (как в лидах)
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations;
  final GlobalKey _addFieldButtonKey = GlobalKey();
  List<String>? _initialUserIds; // Для хранения начальных ID пользователей
  List<int> _initialStatusIds = [];
  bool _askReasonForRefusal = false;
  DealStatus? _selectedDealStatusData;
  bool _isSubmittingSave = false;

  // ── Тематические цвета (как в LeadEditScreen) ──────────────────────────────
  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) =>
      context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) =>
      context.appColors.borderSubtle;
  Color _screenFocusBorder(BuildContext context) =>
      context.appColors.borderPrimary;
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.fieldBg;
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _screenSurfaceElevated(BuildContext context) =>
      context.appColors.surfaceElevated;
  Color _screenFooterBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAskReasonForRefusal();
    _loadInitialData();
    _fetchAndAddDirectoryFields();
    // Загружаем конфигурацию после первого кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFieldConfiguration();
      }
    });

    if (widget.files != null) {
      files = widget.files!.map((file) {
        return FileHelper(
          id: file.id,
          name: file.name,
          path: file.path,
        );
      }).toList();
    }
  }

  Future<void> _loadFieldConfiguration() async {
    if (mounted) {
      context.read<FieldConfigurationBloc>().add(
            FetchFieldConfiguration('deals'),
          );
    }
  }

  void _initializeControllers() {
    titleController.text = widget.dealName;
    _selectedStatuses = widget.statusId;
    descriptionController.text = widget.description ?? '';
    selectedManager = widget.manager;
    selectedLead = (widget.lead != null && widget.lead!.trim().isNotEmpty)
        ? widget.lead
        : null;
    startDateController.text = widget.startDate ?? '';
    endDateController.text = widget.endDate ?? '';
    sumController.text =
        (widget.sum == null || widget.sum == 'null') ? '' : widget.sum!;

    // ✅ НОВОЕ: Инициализируем выбранных пользователей из dealById
    if (widget.dealById?.users != null && widget.dealById!.users!.isNotEmpty) {
      selectedUsers = widget.dealById!.users!
          .where((dealUser) => dealUser.userId != null)
          .map((dealUser) => dealUser.userId.toString())
          .toList();
    } else {
      selectedUsers = [];
    }

    // ✅ НОВОЕ: Initialize from customFieldValues
    if (widget.dealById?.customFieldValues != null) {
      for (var fieldValue in widget.dealById!.customFieldValues) {
        // Get the field name from custom_field info if available
        final fieldName = fieldValue.customField?.name;

        if (fieldName == null) continue;
        // Check if field doesn't already exist
        final exists = customFields.any((f) => f.fieldName == fieldName);
        if (!exists) {
          customFields.add(CustomField(
            fieldName: fieldName,
            controller: TextEditingController(text: fieldValue.value),
            uniqueId: Uuid().v4(),
            type: fieldValue.type,
          ));
        }
      }
    }
    // ✅ НОВОЕ: Инициализируем список ID
    if (widget.dealStatuses != null && widget.dealStatuses!.isNotEmpty) {
      _selectedStatusIds = widget.dealStatuses!.map((s) => s.id).toList();
    } else {
      _selectedStatusIds = [widget.statusId];
    }
    _initialStatusIds = List<int>.from(_selectedStatusIds);
    if (widget.directoryValues != null && widget.directoryValues!.isNotEmpty) {
      final seen = <String>{};
      final uniqueDirectoryValues = widget.directoryValues!.where((dirValue) {
        final key = '${dirValue.entry.directory.id}_${dirValue.entry.id}';
        return seen.add(key);
      }).toList();

      // ✅ НОВОЕ: Инициализируем список ID пользователей
      if (widget.users != null && widget.users!.isNotEmpty) {
        _initialUserIds = widget.users!
            .where((u) => u.user != null)
            .map((u) => u.userId.toString())
            .toList();

        debugPrint('DealEditScreen: Загружены пользователи: $_initialUserIds');
      }

      // TODO check dir values initialization
      final groupedDirectoryValues = <int, List<dynamic>>{};
      for (final dirValue in uniqueDirectoryValues) {
        groupedDirectoryValues
            .putIfAbsent(dirValue.entry.directory.id, () => [])
            .add(dirValue);
      }
      groupedDirectoryValues.forEach((directoryId, values) {
        final first = values.first;
        final ids = values.map((value) => value.entry.id as int).toList();
        final texts = values
            .map((value) => value.entry.values['value']?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .join(', ');
        customFields.add(CustomField(
          fieldName: first.entry.directory.name,
          controller: TextEditingController(text: texts),
          isDirectoryField: true,
          directoryId: directoryId,
          entryIds: ids,
          uniqueId: Uuid().v4(),
        ));
      });
    }
  }

  Future<void> _loadAskReasonForRefusal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _askReasonForRefusal = prefs.getBool('ask_reason_for_refusal') ?? false;
    });
  }

  Future<DealStatus?> _resolveSelectedDealStatusData() async {
    if (_selectedStatuses == null) return null;
    if (_selectedDealStatusData?.id == _selectedStatuses) {
      return _selectedDealStatusData;
    }

    try {
      final status = await _apiService.getDealStatus(_selectedStatuses!);
      if (!mounted) return status;
      setState(() {
        _selectedDealStatusData = status;
      });
      return status;
    } catch (_) {
      return _selectedDealStatusData;
    }
  }

  Future<ReasonForRefusalSubmitData?> _collectReasonForRefusalIfNeeded() async {
    final bool statusChanged =
        _selectedStatusIds.length != _initialStatusIds.length ||
            !_selectedStatusIds.toSet().containsAll(_initialStatusIds) ||
            !_initialStatusIds.toSet().containsAll(_selectedStatusIds);
    final targetStatus = await _resolveSelectedDealStatusData();
    final bool requiresReason = _askReasonForRefusal &&
        _selectedStatusIds.length == 1 &&
        targetStatus?.isFailure == true;

    if (!statusChanged || !requiresReason) {
      return null;
    }

    return showReasonForRefusalDialog(
      context: context,
      type: 'deal',
    );
  }

  void _fetchAndAddDirectoryFields() async {
    try {
      final directoryLinkData = await _apiService.getDealDirectoryLinks();
      if (directoryLinkData.data != null) {
        setState(() {
          for (var link in directoryLinkData.data!) {
            bool directoryExists = customFields.any((field) =>
                field.isDirectoryField &&
                field.directoryId == link.directory.id);
            if (!directoryExists) {
              customFields.add(CustomField(
                fieldName: link.directory.name,
                controller: TextEditingController(),
                isDirectoryField: true,
                directoryId: link.directory.id,
                uniqueId: Uuid().v4(),
              ));
            }
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)!
          .translate('error_fetching_directories'));
    }
  }

  void _loadInitialData() {
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context
        .read<GetAllClientBloc>()
        .add(GetAllClientEv()); // ✅ НОВОЕ: загружаем пользователей
  }

  Future<void> _addCustomField(String fieldName,
      {bool isDirectory = false, int? directoryId, String? type}) async {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) =>
          field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        showCustomSnackBar(
            context: context, message: 'Справочник уже добавлен');
        debugPrint("Directory with ID $directoryId already exists.");
        return;
      }
      try {
        await ApiService().linkDirectory(
          directoryId: directoryId,
          modelType: 'deal',
          organizationId: ApiService().getSelectedOrganization().toString(),
        );

        if (mounted) {
          setState(() {
            customFields.add(CustomField(
              fieldName: fieldName,
              controller: TextEditingController(),
              isDirectoryField: true,
              directoryId: directoryId,
              uniqueId: Uuid().v4(),
              type: null,
            ));
          });
          // Перезагружаем конфигурацию после успешной привязки справочника
          context.read<FieldConfigurationBloc>().add(
                FetchFieldConfiguration('deals'),
              );

          // Сообщаем об успешном добавлении справочника
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Справочник успешно добавлен',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              backgroundColor: context.appColors.success,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
      return;
    }

    // Добавление пользовательского поля через API, затем локально
    try {
      await ApiService().addNewField(
        tableName: 'deals',
        fieldName: fieldName,
        fieldType: type ?? 'string',
      );

      if (mounted) {
        context.read<FieldConfigurationBloc>().add(
              FetchFieldConfiguration('deals'),
            );
        setState(() {
          customFields.add(CustomField(
            fieldName: fieldName,
            controller: TextEditingController(),
            isDirectoryField: false,
            directoryId: null,
            uniqueId: Uuid().v4(),
            type: type ?? 'string',
          ));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error adding field: $e');
    }
  }

  void _showAddFieldMenu() {
    final RenderBox? renderBox =
        _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Список элементов меню
    final menuItems = [
      PopupMenuItem(
        value: 'manual',
        child: Text(
          AppLocalizations.of(context)!.translate('manual_input'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: _screenPrimaryText(context),
          ),
        ),
      ),
      PopupMenuItem(
        value: 'directory',
        child: Text(
          AppLocalizations.of(context)!.translate('directory'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: _screenPrimaryText(context),
          ),
        ),
      ),
    ];

    // Если элементов 5 или больше, показываем над кнопкой, иначе под кнопкой
    final showAbove = menuItems.length >= 5;
    final double verticalOffset = showAbove ? -8 : size.height + 8;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        showAbove ? offset.dy + verticalOffset : offset.dy + verticalOffset,
        MediaQuery.of(context).size.width - offset.dx - size.width,
        showAbove
            ? MediaQuery.of(context).size.height - offset.dy + verticalOffset
            : MediaQuery.of(context).size.height - offset.dy - size.height - 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: _screenFieldBackground(context),
      items: menuItems,
    ).then((value) {
      if (value == 'manual') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AddCustomFieldDialog(
              onAddField: (fieldName, {String? type}) {
                _addCustomField(fieldName, type: type);
              },
            );
          },
        );
      } else if (value == 'directory') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AddCustomDirectoryDialog(
              onAddDirectory: (directory_model.Directory directory) async {
                await _addCustomField(
                  directory.name,
                  isDirectory: true,
                  directoryId: directory.id,
                );
              },
            );
          },
        );
      }
    });
  }

  // Сохранение порядка полей на бэкенд
  Future<void> _saveFieldOrderToBackend() async {
    try {
      // Подготовка данных для отправки
      final List<Map<String, dynamic>> updates = [];
      for (var config in fieldConfigurations) {
        updates.add({
          'id': config.id,
          'position': config.position,
          'is_active': config.isActive ? 1 : 0,
          'is_required':
              config.originalRequired ? 1 : 0, // Используем originalRequired
          'show_on_table': config.showOnTable ? 1 : 0,
        });
      }

      await ApiService().updateFieldPositions(
        tableName: 'deals',
        updates: updates,
      );
    } catch (e) {
      // IGNORE ERROR, DO NOT SHOW SNACKBAR
    }
  }

  // Вспомогательные методы для соответствия config -> CustomField
  CustomField _getOrCreateCustomField(FieldConfiguration config) {
    final existingField = customFields.firstWhere(
      (field) => !field.isDirectoryField && field.fieldName == config.fieldName,
      orElse: () {
        final newField = CustomField(
          fieldName: config.fieldName,
          uniqueId: Uuid().v4(),
          controller: TextEditingController(),
          type: config.type,
        );
        customFields.add(newField);
        return newField;
      },
    );
    return existingField;
  }

  CustomField _getOrCreateDirectoryField(FieldConfiguration config) {
    final existingField = customFields.firstWhere(
      (field) =>
          field.isDirectoryField && field.directoryId == config.directoryId,
      orElse: () {
        final newField = CustomField(
          fieldName: config.fieldName,
          isDirectoryField: true,
          directoryId: config.directoryId,
          uniqueId: Uuid().v4(),
          controller: TextEditingController(),
        );
        customFields.add(newField);
        return newField;
      },
    );
    return existingField;
  }

  // Построение системных полей сделки на основе конфигурации
  Widget _buildStandardField(FieldConfiguration config) {
    final fieldBackground = _screenFieldBackground(context);
    final fieldBorder = _screenBorder(context);
    final fieldText = _screenPrimaryText(context);
    final fieldHint = _screenHintText(context);
    final focusedBorder = _screenFocusBorder(context);

    switch (config.fieldName) {
      case 'name':
        return DealNameSelectionWidget(
          selectedDealName: titleController.text,
          onSelectDealName: (String dealName) {
            setState(() {
              titleController.text = dealName;
            });
          },
        );
      case 'manager_id':
        return ManagerRadioGroupWidget(
          selectedManager: selectedManager,
          onSelectManager: (ManagerData selectedManagerData) {
            setState(() {
              selectedManager = selectedManagerData.id.toString();
            });
          },
        );
      case 'lead_id':
        // Поле "Лид" не показываем в редактировании сделки
        // (сделка уже привязана к лиду)
        return const SizedBox.shrink();
      case 'start_date':
        return CustomTextFieldDate(
          controller: startDateController,
          label: AppLocalizations.of(context)!.translate('start_date'),
          withTime: false,
        );
      case 'end_date':
        return CustomTextFieldDate(
          controller: endDateController,
          label: AppLocalizations.of(context)!.translate('end_date'),
          hasError: isEndDateInvalid,
          withTime: false,
        );
      case 'sum':
        return CustomTextField(
          controller: sumController,
          hintText: AppLocalizations.of(context)!.translate('enter_summ'),
          label: AppLocalizations.of(context)!.translate('summ'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
          ],
        );
      case 'description':
        return CustomTextField(
          controller: descriptionController,
          hintText:
              AppLocalizations.of(context)!.translate('enter_description'),
          label: AppLocalizations.of(context)!.translate('description_list'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
        );
      case 'deal_status_id':
        return DealStatusEditWidget(
          selectedStatus: _selectedStatuses?.toString(),
          dealStatuses: widget.dealStatuses,
          onSelectStatus: (DealStatus selectedStatusData) {
            if (_selectedStatuses != selectedStatusData.id) {
              setState(() {
                _selectedStatuses = selectedStatusData.id;
                _selectedDealStatusData = selectedStatusData;
              });
            }
          },
          onSelectMultipleStatuses: (List<int> selectedIds) {
            if (_selectedStatusIds.length != selectedIds.length ||
                !_selectedStatusIds.toSet().containsAll(selectedIds) ||
                !selectedIds.toSet().containsAll(_selectedStatusIds)) {
              setState(() {
                _selectedStatusIds = selectedIds;
              });
            }
          },
        );
      case 'users': // ✅ НОВОЕ: обработка поля users
      case 'user_ids': // ✅ Иногда приходит так в конфигурации
        return UserMultiSelectWidget(
          selectedUsers: selectedUsers,
          isRequired:
              false, // ✅ Исполнители не обязательны в редактировании сделки
          onSelectUsers: (List<UserData> selectedUsersData) {
            setState(() {
              selectedUsers =
                  selectedUsersData.map((user) => user.id.toString()).toList();
            });
          },
        );
      case 'city_id':
        return CustomTextField(
          controller:
              TextEditingController(), // TODO: добавить контроллер в state если нужно сохранять
          hintText: AppLocalizations.of(context)!.translate('enter_city'),
          label: AppLocalizations.of(context)!.translate('oblast'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );
      case 'region_id':
        return CustomTextField(
          controller:
              TextEditingController(), // TODO: добавить контроллер в state если нужно сохранять
          hintText: AppLocalizations.of(context)!.translate('enter_region'),
          label: AppLocalizations.of(context)!.translate('region'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );
      // case 'file':
      //   // Показ блока файлов согласно позиции в конфигурации
      //   return _buildFileSelection();
      default:
        return const SizedBox.shrink();
    }
  }

  // Построение виджета по конфигурации
  Widget _buildFieldWidget(FieldConfiguration config) {
    if (config.isCustomField) {
      final customField = _getOrCreateCustomField(config);
      return CustomFieldWidget(
        fieldName: config.fieldName,
        valueController: customField.controller,
        type: config.type,
        isDirectory: false,
      );
    }

    if (config.isDirectory && config.directoryId != null) {
      final directoryField = _getOrCreateDirectoryField(config);
      return MainFieldDropdownWidget(
        directoryId: directoryField.directoryId!,
        directoryName: directoryField.fieldName,
        selectedField: directoryField.entryId != null
            ? MainField(
                id: directoryField.entryId!,
                value: directoryField.controller.text)
            : null,
        onSelectField: (List<MainField> selectedFields) {
          setState(() {
            final idx = customFields
                .indexWhere((f) => f.directoryId == config.directoryId);
            if (idx != -1) {
              customFields[idx] = directoryField.copyWith(
                entryIds: selectedFields.map((e) => e.id).toList(),
                                                        controller: TextEditingController(
                                                          text: selectedFields.map((e) => e.value).join(', '),
                                                        ),
              );
            }
          });
        },
        controller: directoryField.controller,
        initialEntryIds: directoryField.selectedEntryIds,
        onSelectEntryId: (List<int> entryIds) {
          setState(() {
            final idx = customFields
                .indexWhere((f) => f.directoryId == config.directoryId);
            if (idx != -1) {
              customFields[idx] = directoryField.copyWith(entryIds: entryIds);
            }
          });
        },
        initialEntryId: directoryField.entryId,
      );
    }

    return _buildStandardField(config);
  }

  String _getFieldDisplayName(FieldConfiguration config) {
    final loc = AppLocalizations.of(context)!;
    switch (config.fieldName) {
      case 'name':
        return loc.translate('deal_name');
      case 'manager_id':
        return loc.translate('manager');
      case 'lead_id':
        return loc.translate('lead');
      case 'city_id':
        return loc.translate('oblast');
      case 'region_id':
        return loc.translate('region');
      case 'start_date':
        return loc.translate('start_date');
      case 'end_date':
        return loc.translate('end_date');
      case 'sum':
        return loc.translate('summ');
      case 'description':
        return loc.translate('description_list');
      case 'deal_status_id':
        return loc.translate('deal_status');
      case 'users': // ✅ НОВОЕ
        return loc.translate('assignees_list');
      case 'user_ids': // <-- ДОБАВЛЯЕМ ЭТУ СТРОКУ
        return loc.translate('assignees_list'); // <-- И ЭТУ
      // case 'file':
      //   return loc.translate('file');
      default:
        return config.fieldName;
    }
  }

  String _getFieldTypeLabel(FieldConfiguration config) {
    if (config.isDirectory) {
      return AppLocalizations.of(context)!.translate('directory');
    } else if (config.isCustomField) {
      return AppLocalizations.of(context)!.translate('custom_field');
    } else {
      return AppLocalizations.of(context)!.translate('system_field');
    }
  }

  Widget _buildSettingsMode() {
    final sortedFields = [...fieldConfigurations]
      ..sort((a, b) => a.position.compareTo(b.position));

    final cardColor = _screenFieldBackground(context);
    final cardBorder = _screenBorder(context);
    final titleColor = _screenPrimaryText(context);
    final subtitleColor = _screenHintText(context);
    final mutedColor = _screenHintText(context);

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedFields.length + 1,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  final double animValue =
                      Curves.easeInOut.transform(animation.value);
                  final double scale = 1.0 + (animValue * 0.05);
                  final double elevation = animValue * 12.0;

                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: elevation,
                      shadowColor:
                          context.appColors.shadow.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      color: context.appColors.overlay.withValues(alpha: 0),
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (oldIndex == sortedFields.length ||
                  newIndex == sortedFields.length + 1) {
                return;
              }

              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }

                if (newIndex >= sortedFields.length) {
                  newIndex = sortedFields.length - 1;
                }

                final item = sortedFields.removeAt(oldIndex);
                sortedFields.insert(newIndex, item);

                final updatedFields = <FieldConfiguration>[];
                for (int i = 0; i < sortedFields.length; i++) {
                  final config = sortedFields[i];
                  updatedFields.add(FieldConfiguration(
                    id: config.id,
                    tableName: config.tableName,
                    fieldName: config.fieldName,
                    position: i + 1,
                    required: false, // Всегда false в UI
                    isActive: config.isActive,
                    isCustomField: config.isCustomField,
                    createdAt: config.createdAt,
                    updatedAt: config.updatedAt,
                    customFieldId: config.customFieldId,
                    directoryId: config.directoryId,
                    type: config.type,
                    isDirectory: config.isDirectory,
                    showOnTable: config.showOnTable,
                    originalRequired: config
                        .originalRequired, // Сохраняем оригинальное значение
                  ));
                }

                fieldConfigurations = updatedFields;
              });
            },
            itemBuilder: (context, index) {
              if (index == sortedFields.length) {
                return Container(
                  key: _addFieldButtonKey,
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('add_field'),
                    buttonColor: _screenFieldBackground(context),
                    textColor: _screenPrimaryText(context),
                    onPressed: _showAddFieldMenu,
                  ),
                );
              }

              final config = sortedFields[index];
              final displayName = _getFieldDisplayName(config);
              final typeLabel = _getFieldTypeLabel(config);

              return Container(
                key: ValueKey('field_${config.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cardBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: mutedColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w400,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (config.fieldName != 'name' &&
                              config.fieldName != 'deal_status_id' &&
                              config.fieldName != 'manager_id')
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  final updatedConfig = FieldConfiguration(
                                    id: config.id,
                                    tableName: config.tableName,
                                    fieldName: config.fieldName,
                                    position: config.position,
                                    required: false,
                                    isActive: !config.isActive,
                                    isCustomField: config.isCustomField,
                                    createdAt: config.createdAt,
                                    updatedAt: config.updatedAt,
                                    customFieldId: config.customFieldId,
                                    directoryId: config.directoryId,
                                    type: config.type,
                                    isDirectory: config.isDirectory,
                                    showOnTable: config.showOnTable,
                                    originalRequired: config.originalRequired,
                                  );

                                  final idx = fieldConfigurations
                                      .indexWhere((f) => f.id == config.id);
                                  if (idx != -1) {
                                    fieldConfigurations[idx] = updatedConfig;
                                  }
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: config.isActive
                                            ? context.appColors.buttonPrimaryBg
                                            : context.appColors.overlay
                                                .withValues(alpha: 0),
                                        border: Border.all(
                                          color: config.isActive
                                              ? context
                                                  .appColors.buttonPrimaryBg
                                              : cardBorder,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: AnimatedOpacity(
                                        duration: Duration(milliseconds: 200),
                                        opacity: config.isActive ? 1.0 : 0.0,
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: context.appColors.textInverse,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('show_field'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        color: config.isActive
                                            ? titleColor
                                            : subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _screenFooterBackground(context),
            boxShadow: [
              BoxShadow(
                color: context.appColors.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: isSavingFieldOrder
              ? Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.appColors.buttonPrimaryBg
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                context.appColors.textInverse),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.translate('saving'),
                          style: TextStyle(
                            color: context.appColors.textInverse,
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('save'),
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.textInverse,
                  onPressed: () async {
                    setState(() {
                      isSavingFieldOrder = true;
                    });

                    try {
                      // Сохраняем позиции полей на бэкенд
                      await _saveFieldOrderToBackend();

                      if (mounted) {
                        setState(() {
                          originalFieldConfigurations =
                              null; // Очищаем снимок после сохранения
                          isSettingsMode = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Настройки полей сохранены',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textInverse,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: context.appColors.success,
                            elevation: 3,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          isSavingFieldOrder = false;
                        });
                      }
                    }
                  },
                ),
        ),
      ],
    );
  }

  bool _hasFieldChanges() {
    if (originalFieldConfigurations == null) return false;
    if (originalFieldConfigurations!.length != fieldConfigurations.length)
      return true;

    for (int i = 0; i < fieldConfigurations.length; i++) {
      final current = fieldConfigurations[i];
      final original = originalFieldConfigurations!.firstWhere(
        (f) => f.id == current.id,
        orElse: () => current,
      );

      if (current.position != original.position ||
          current.isActive != original.isActive ||
          current.showOnTable != original.showOnTable) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _showExitSettingsDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: _screenFieldBackground(context),
              title: Text(
                AppLocalizations.of(context)!.translate('warning'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _screenPrimaryText(context),
                ),
              ),
              content: Text(
                AppLocalizations.of(context)!
                    .translate('position_changes_will_not_be_saved'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _screenPrimaryText(context),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                        buttonColor: context.appColors.buttonPrimaryBg,
                        textColor: context.appColors.textInverse,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        buttonText: AppLocalizations.of(context)!
                            .translate('dont_save'),
                        onPressed: () => Navigator.of(context).pop(true),
                        buttonColor: context.appColors.error,
                        textColor: context.appColors.textInverse,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appColors.textInverse,
          ),
        ),
        backgroundColor: context.appColors.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    // Вычисляем текущий общий размер файлов
    double totalSize = files.fold<double>(0.0, (sum, file) {
      if (file.path.startsWith('http://') || file.path.startsWith('https://')) {
        int index = files.indexOf(file);
        if (index >= 0 && index < files.length) {
          final size = files[index].size;
          final parsed = num.tryParse(size.toString());
          return sum + (parsed != null ? parsed / 1024.0 : 0);
        }
        return sum;
      }

      return sum + File(file.path).lengthSync() / (1024 * 1024);
    });

    // Показываем диалог выбора типа файла
    final List<PickedFileInfo>? pickedFiles = await FilePickerDialog.show(
      context: context,
      allowMultiple: true,
      maxSizeMB: 50.0,
      currentTotalSizeMB: totalSize,
      fileLabel: AppLocalizations.of(context)!.translate('file'),
      galleryLabel: AppLocalizations.of(context)!.translate('gallery'),
      cameraLabel: AppLocalizations.of(context)!.translate('camera'),
      cancelLabel: AppLocalizations.of(context)!.translate('cancel'),
      fileSizeTooLargeMessage:
          AppLocalizations.of(context)!.translate('file_size_too_large'),
      errorPickingFileMessage:
          AppLocalizations.of(context)!.translate('error_picking_file'),
    );

    // Если файлы выбраны, добавляем их
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          // selectedFiles.add(file.path);
          // fileNames.add(file.name);
          // fileSizes.add(file.sizeKB);

          files.add(FileHelper(
              id: 0, name: file.name, path: file.path, size: file.sizeKB));
        }
      });
    }
  }

  void showDeleteFileDialog({required int fileId, required int index}) {
    bool isDeleting = false;

    showDialog<bool>(
      context: context,
      builder: (context) {
        return DeleteFileDialog(
          isDeleting: isDeleting,
          fileId: fileId,
          onDelete: (fileId) async {
            if (files[index].id == 0) {
              setState(() {
                files.removeAt(index);
              });
              Navigator.of(context).pop(true);
              return;
            }

            isDeleting = true;
            setState(() {});

            final response = await _apiService.deleteTaskFile(fileId);
            if (response['result'] == 'Success') {
              setState(() {
                files.removeAt(index);
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!
                        .translate('error_delete_file'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textInverse,
                    ),
                  ),
                  backgroundColor: context.appColors.error,
                ),
              );
            }

            Navigator.of(context).pop(true);
          },
          onCancel: () {
            Navigator.of(context).pop(false);
          },
        );
      },
    );
  }

  Widget _buildFileSelection() {
    final fileTextColor = _screenPrimaryText(context);
    final fileCardColor = _screenFieldBackground(context);
    final addFileIconAsset =
        ThemeData.estimateBrightnessForColor(fileCardColor) == Brightness.dark
            ? 'assets/icons/files/add_for_dark.png'
            : 'assets/icons/files/add.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('file'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: fileTextColor,
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.isEmpty ? 1 : files.length + 1,
            itemBuilder: (context, index) {
              // Кнопка добавления файла
              if (files.isEmpty || index == files.length) {
                return Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: 100,
                      child: Column(
                        children: [
                          Image.asset(addFileIconAsset, width: 60, height: 60),
                          SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('add_file'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              color: fileTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Отображение выбранных файлов
              final fileName = files[index].name;
              final fileExtension = fileName.split('.').last.toLowerCase();

              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      child: Column(
                        children: [
                          buildFileIcon(files, fileName, fileExtension),
                          SizedBox(height: 8),
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              color: fileTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Кнопка удаления файла
                    Positioned(
                      right: -2,
                      top: -6,
                      child: GestureDetector(
                        onTap: () {
                          showDeleteFileDialog(
                            fileId: files[index].id,
                            index: index,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.appColors.surfacePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.appColors.shadow
                                    .withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.close,
                              size: 16, color: fileTextColor),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final baseColors = context.appColors;
    final baseTextStyles = context.appTextStyles;
    final baseShadows = context.appShadows;
    final screenTheme = baseTheme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        baseColors.copyWith(
          surfacePrimary: _screenSurfaceBackground(context),
          surfaceElevated: _screenSurfaceElevated(context),
          textPrimary: _screenPrimaryText(context),
          textSecondary: _screenSecondaryText(context),
          textMuted: _screenHintText(context),
          textInverse: _screenPrimaryText(context),
          iconPrimary: _screenPrimaryText(context),
          iconSecondary: _screenSecondaryText(context),
          borderPrimary: _screenBorder(context),
          borderSubtle: _screenBorder(context),
          buttonSecondaryBg: _screenFieldBackground(context),
          buttonSecondaryFg: _screenPrimaryText(context),
          fieldBg: _screenFieldBackground(context),
          fieldBorder: _screenBorder(context),
          fieldHint: _screenHintText(context),
          overlay: baseColors.overlay,
        ),
        baseTextStyles.copyWith(
          titleLg: baseTextStyles.titleLg
              .copyWith(color: _screenPrimaryText(context)),
          titleMd: baseTextStyles.titleMd
              .copyWith(color: _screenPrimaryText(context)),
          bodyLg: baseTextStyles.bodyLg
              .copyWith(color: _screenPrimaryText(context)),
          bodyMd: baseTextStyles.bodyMd
              .copyWith(color: _screenSecondaryText(context)),
          bodySm: baseTextStyles.bodySm
              .copyWith(color: _screenSecondaryText(context)),
          labelLg: baseTextStyles.labelLg
              .copyWith(color: _screenPrimaryText(context)),
          labelMd: baseTextStyles.labelMd
              .copyWith(color: _screenSecondaryText(context)),
          caption: baseTextStyles.caption
              .copyWith(color: _screenHintText(context)),
        ),
        baseShadows,
      ],
    );
    final appBarGradient = [
      _screenSurfaceElevated(context),
      _screenFieldBackground(context),
    ];
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);
    final formSurface = _screenSurfaceBackground(context);
    final footerSurface = _screenFooterBackground(context);

    return Theme(
      data: screenTheme,
      child: Scaffold(
        backgroundColor: context.appColors.overlay.withValues(alpha: 0),
        extendBodyBehindAppBar: !isSettingsMode,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          backgroundColor: context.appColors.overlay.withValues(alpha: 0),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: context.appColors.overlay.withValues(alpha: 0),
          shadowColor: context.appColors.overlay.withValues(alpha: 0),
          toolbarHeight: 74,
          titleSpacing: 16,
          title: AppBarShell(
            leading: AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: IconButton(
                onPressed: () => Navigator.pop(context, null),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: primaryText,
                ),
              ),
            ),
            center: AppBarShell.capsule(
              context,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.translate('edit_deal'),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            trailing: AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: IconButton(
                icon: Icon(
                  isSettingsMode
                      ? Icons.close_rounded
                      : Icons.settings_rounded,
                  color: primaryText,
                  size: 20,
                ),
                onPressed: () async {
                  if (isSettingsMode) {
                    if (_hasFieldChanges()) {
                      final shouldExit = await _showExitSettingsDialog();
                      if (!shouldExit) return;

                      if (originalFieldConfigurations != null) {
                        setState(() {
                          final newFields =
                              fieldConfigurations.where((current) {
                            return !originalFieldConfigurations!
                                .any((original) => original.id == current.id);
                          }).toList();

                          fieldConfigurations = [
                            ...originalFieldConfigurations!
                          ];

                          if (newFields.isNotEmpty) {
                            int maxPosition = fieldConfigurations.isEmpty
                                ? 0
                                : fieldConfigurations
                                    .map((e) => e.position)
                                    .reduce((a, b) => a > b ? a : b);
                            for (int i = 0; i < newFields.length; i++) {
                              fieldConfigurations.add(FieldConfiguration(
                                id: newFields[i].id,
                                tableName: newFields[i].tableName,
                                fieldName: newFields[i].fieldName,
                                position: maxPosition + i + 1,
                                required: false,
                                isActive: newFields[i].isActive,
                                isCustomField: newFields[i].isCustomField,
                                createdAt: newFields[i].createdAt,
                                updatedAt: newFields[i].updatedAt,
                                customFieldId: newFields[i].customFieldId,
                                directoryId: newFields[i].directoryId,
                                type: newFields[i].type,
                                isDirectory: newFields[i].isDirectory,
                                showOnTable: newFields[i].showOnTable,
                                originalRequired:
                                    newFields[i].originalRequired,
                              ));
                            }
                          }

                          originalFieldConfigurations = null;
                          isSettingsMode = false;
                        });
                      }
                    } else {
                      setState(() {
                        originalFieldConfigurations = null;
                        isSettingsMode = false;
                      });
                    }
                  } else {
                    setState(() {
                      originalFieldConfigurations =
                          fieldConfigurations.map((config) {
                        return FieldConfiguration(
                          id: config.id,
                          tableName: config.tableName,
                          fieldName: config.fieldName,
                          position: config.position,
                          required: false,
                          isActive: config.isActive,
                          isCustomField: config.isCustomField,
                          createdAt: config.createdAt,
                          updatedAt: config.updatedAt,
                          customFieldId: config.customFieldId,
                          directoryId: config.directoryId,
                          type: config.type,
                          isDirectory: config.isDirectory,
                          showOnTable: config.showOnTable,
                          originalRequired: config.originalRequired,
                        );
                      }).toList();
                      isSettingsMode = true;
                    });
                  }
                },
              ),
            ),
          ),
          centerTitle: false,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
            ),
            MultiBlocProvider(
              providers: [
                BlocProvider(create: (context) => MainFieldBloc()),
              ],
              child: BlocListener<DealBloc, DealState>(
                listener: (context, state) {
                  if (state is DealError) {
                    _showErrorSnackBar(
                        AppLocalizations.of(context)!.translate(state.message));
                  } else if (state is DealSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('deal_updated_successfully'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textInverse,
                          ),
                        ),
                        backgroundColor: context.appColors.success,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    Navigator.pop(context, true);
                  }
                },
                child: BlocConsumer<FieldConfigurationBloc,
                    FieldConfigurationState>(
                  listener: (context, configState) {
                    if (configState is FieldConfigurationLoaded) {
                      setState(() {
                        fieldConfigurations = configState.fields;
                        isConfigurationLoaded = true;
                      });
                    } else if (configState is FieldConfigurationError) {
                      _showErrorSnackBar(
                          'Ошибка загрузки конфигурации: ${configState.message}');
                    }
                  },
                  builder: (context, configState) {
                    if (configState is FieldConfigurationLoading ||
                        !isConfigurationLoaded) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: primaryText,
                        ),
                      );
                    }

                    if (isSettingsMode) {
                      return _buildSettingsMode();
                    }

                    return Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).padding.top + 10,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                              },
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                      18, 18, 18, 22),
                                  decoration: BoxDecoration(
                                    color: formSurface,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: subtleBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.appColors.shadow
                                            .withValues(alpha: 0.14),
                                        blurRadius: 28,
                                        offset: const Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Динамические поля по конфигурации
                                      ...(() {
                                        final sorted = fieldConfigurations
                                            .where((config) =>
                                                config.isActive &&
                                                config.fieldName != 'lead_id')
                                            .toList()
                                          ..sort((a, b) =>
                                              a.position.compareTo(b.position));

                                        return sorted.map((config) {
                                          return Column(
                                            children: [
                                              _buildFieldWidget(config),
                                              const SizedBox(height: 16),
                                            ],
                                          );
                                        }).toList();
                                      })(),

                                      // Пользовательские поля, которых нет в конфигурации сервера
                                      ...customFields.where((field) {
                                        return !fieldConfigurations.any(
                                            (config) =>
                                                (config.isCustomField &&
                                                    config.fieldName ==
                                                        field.fieldName) ||
                                                (config.isDirectory &&
                                                    config.directoryId ==
                                                        field.directoryId));
                                      }).map((field) {
                                        final index =
                                            customFields.indexOf(field);
                                        return Column(
                                          children: [
                                            field.isDirectoryField &&
                                                    field.directoryId != null
                                                ? MainFieldDropdownWidget(
                                                    directoryId:
                                                        field.directoryId!,
                                                    directoryName:
                                                        field.fieldName,
                                                    selectedField:
                                                        field.entryId != null
                                                            ? MainField(
                                                                id: field
                                                                    .entryId!,
                                                                value: field
                                                                    .controller
                                                                    .text)
                                                            : null,
                                                    onSelectField: (List<MainField> selectedFields) {
                                                      setState(() {
                                                        customFields[index] =
                                                            field.copyWith(
                                                          entryIds: selectedFields.map((e) => e.id).toList(),
                                                          controller:
                                                              TextEditingController(
                                                                  text: selectedFields
                                                                      .map((e) => e.value)
                                                                      .join(', ')),
                                                        );
                                                      });
                                                    },
                                                    controller: field.controller,
                                                    initialEntryIds: field.selectedEntryIds,
                                                    onSelectEntryId: (List<int> entryIds) {
                                                      setState(() {
                                                        customFields[index] =
                                                            field.copyWith(
                                                                entryIds: entryIds);
                                                      });
                                                    },
                                                    initialEntryId:
                                                        field.entryId,
                                                  )
                                                : CustomFieldWidget(
                                                    fieldName: field.fieldName,
                                                    valueController:
                                                        field.controller,
                                                    type: field.type,
                                                  ),
                                            const SizedBox(height: 16),
                                          ],
                                        );
                                      }).toList(),

                                      // Всегда показываем выбор файлов
                                      _buildFileSelection(),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            decoration: BoxDecoration(
                              color: footerSurface,
                              boxShadow: [
                                BoxShadow(
                                  color: context.appColors.shadow
                                      .withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    buttonText: AppLocalizations.of(context)!
                                        .translate('cancel'),
                                    buttonColor: _screenFieldBackground(context),
                                    textColor: _screenPrimaryText(context),
                                    onPressed: () =>
                                        Navigator.pop(context, null),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: BlocBuilder<DealBloc, DealState>(
                                    builder: (context, state) {
                                      if (state is DealLoading ||
                                          _isSubmittingSave) {
                                        return Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: context
                                                .appColors.buttonPrimaryBg
                                                .withValues(alpha: 0.7),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        context.appColors
                                                            .textInverse),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return CustomButton(
                                        buttonText:
                                            AppLocalizations.of(context)!
                                                .translate('save'),
                                        buttonColor: context
                                            .appColors.buttonPrimaryBg,
                                        textColor:
                                            context.appColors.textInverse,
                                        onPressed: () async {
                                          if (_isSubmittingSave) return;
                                          setState(() {
                                            _isSubmittingSave = true;
                                          });

                                          if (_formKey.currentState!
                                              .validate()) {
                                            // Парсим дату начала
                                            DateTime? parsedStartDate;
                                            if (startDateController
                                                .text.isNotEmpty) {
                                              try {
                                                parsedStartDate =
                                                    DateFormat('dd.MM.yyyy')
                                                        .parse(startDateController
                                                            .text);
                                              } catch (e) {
                                                parsedStartDate = null;
                                              }
                                            }

                                            // Парсим дату завершения
                                            DateTime? parsedEndDate;
                                            if (endDateController
                                                .text.isNotEmpty) {
                                              try {
                                                parsedEndDate =
                                                    DateFormat('dd.MM.yyyy')
                                                        .parse(
                                                            endDateController
                                                                .text);
                                              } catch (e) {
                                                parsedEndDate = null;
                                              }
                                            }

                                            // Проверяем валидность даты завершения
                                            if (parsedEndDate != null &&
                                                parsedStartDate != null &&
                                                parsedEndDate
                                                    .isBefore(parsedStartDate)) {
                                              setState(() {
                                                isEndDateInvalid = true;
                                                _isSubmittingSave = false;
                                              });
                                              return;
                                            }

                                            setState(() {
                                              isEndDateInvalid = false;
                                            });

                                            // Собираем кастомные поля
                                            final List<
                                                    Map<String, dynamic>>
                                                customFieldList = [];
                                            final List<
                                                    Map<String, dynamic>>
                                                directoryValues = [];

                                            for (var field in customFields) {
                                              if (field.isDirectoryField &&
                                                  field.directoryId != null) {
                                                directoryValues.addAll(
                                                  field.toDirectoryPayloads(),
                                                );
                                              } else {
                                                final fieldName =
                                                    field.fieldName;
                                                final fieldValue =
                                                    field.controller.text;
                                                final fieldType = field.type;

                                                if (fieldValue.isNotEmpty) {
                                                  customFieldList.add({
                                                    'key': fieldName,
                                                    'value': fieldValue,
                                                    'type':
                                                        fieldType ?? 'string',
                                                  });
                                                }
                                              }
                                            }

                                            // Новые файлы (id == 0)
                                            final newFiles = files
                                                .where((f) => f.id == 0)
                                                .toList();

                                            // Существующие файлы (id != 0)
                                            final existingFileIds = files
                                                .where((f) => f.id != 0)
                                                .map((f) => f.id)
                                                .toList();

                                            final localizations =
                                                AppLocalizations.of(context)!;
                                            List<int>? userIds;
                                            if (selectedUsers != null &&
                                                selectedUsers!.isNotEmpty) {
                                              userIds = selectedUsers!
                                                  .map((id) => int.parse(id))
                                                  .toList();
                                            }

                                            final parsedLeadId = int.tryParse(
                                                    (selectedLead ?? '')
                                                        .trim()) ??
                                                widget.dealById?.lead?.id;
                                            final refusalData =
                                                await _collectReasonForRefusalIfNeeded();

                                            if (!mounted) return;
                                            final bool statusChanged =
                                                _selectedStatusIds.length !=
                                                        _initialStatusIds
                                                            .length ||
                                                    !_selectedStatusIds
                                                        .toSet()
                                                        .containsAll(
                                                            _initialStatusIds) ||
                                                    !_initialStatusIds
                                                        .toSet()
                                                        .containsAll(
                                                            _selectedStatusIds);
                                            if (statusChanged &&
                                                _askReasonForRefusal &&
                                                _selectedStatusIds.length ==
                                                    1 &&
                                                (await _resolveSelectedDealStatusData())
                                                        ?.isFailure ==
                                                    true &&
                                                refusalData == null) {
                                              setState(() {
                                                _isSubmittingSave = false;
                                              });
                                              return;
                                            }

                                            context
                                                .read<DealBloc>()
                                                .add(UpdateDeal(
                                                  dealId: widget.dealId,
                                                  name: titleController.text,
                                                  dealStatusId:
                                                      _selectedStatuses!
                                                          .toInt(),
                                                  managerId: int.tryParse(
                                                      (selectedManager ?? '')
                                                          .trim()),
                                                  leadId: parsedLeadId,
                                                  description:
                                                      descriptionController
                                                              .text.isEmpty
                                                          ? null
                                                          : descriptionController
                                                              .text,
                                                  startDate: parsedStartDate,
                                                  endDate: parsedEndDate,
                                                  sum: sumController
                                                          .text.isEmpty
                                                      ? null
                                                      : sumController.text,
                                                  dealtypeId: 1,
                                                  customFields: customFieldList,
                                                  // directoryValues:
                                                  //     directoryValues,
                                                  localizations: localizations,
                                                  files: newFiles.isNotEmpty
                                                      ? newFiles
                                                      : null,
                                                  existingFiles:
                                                      existingFileIds.isNotEmpty
                                                          ? existingFileIds
                                                          : null,
                                                  dealStatusIds:
                                                      _selectedStatusIds,
                                                  userIds: userIds,
                                                  reasonForRefusalId:
                                                      refusalData?.reasonId,
                                                  reasonForRefusal:
                                                      refusalData?.comment,
                                                ));
                                            if (mounted) {
                                              setState(() {
                                                _isSubmittingSave = false;
                                              });
                                            }
                                          } else {
                                            if (mounted) {
                                              setState(() {
                                                _isSubmittingSave = false;
                                              });
                                            }
                                            _showErrorSnackBar(
                                                AppLocalizations.of(context)!
                                                    .translate(
                                                        'fill_required_fields'));
                                          }
                                        },
                                      );
                                    },
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
            ),
          ],
        ),
      ),
    );
  }
}
class CustomField {
  final String fieldName;
  final TextEditingController controller;
  final bool isDirectoryField;
  final bool isCustomField;
  final int? directoryId;
  final int? entryId;
  final List<int> entryIds;
  final String uniqueId;
  final String? type;

  CustomField({
    required this.fieldName,
    TextEditingController? controller,
    this.isDirectoryField = false,
    this.isCustomField = false,
    this.directoryId,
    this.entryId,
    List<int>? entryIds,
    required this.uniqueId,
    this.type,
  })  : entryIds = List<int>.from(
          entryIds ?? (entryId != null ? <int>[entryId] : const <int>[]),
        ),
        controller = controller ?? TextEditingController();

  List<int> get selectedEntryIds {
    if (entryIds.isNotEmpty) return entryIds;
    if (entryId != null) return <int>[entryId!];
    return const <int>[];
  }

  List<Map<String, int>> toDirectoryPayloads() {
    if (!isDirectoryField || directoryId == null) return const [];
    return selectedEntryIds
        .map((id) => <String, int>{
              'directory_id': directoryId!,
              'entry_id': id,
            })
        .toList();
  }

  CustomField copyWith({
    String? fieldName,
    TextEditingController? controller,
    bool? isDirectoryField,
    bool? isCustomField,
    int? directoryId,
    int? entryId,
    List<int>? entryIds,
    String? uniqueId,
    String? type,
  }) {
    final nextEntryIds = entryIds ??
        (entryId != null ? <int>[entryId] : this.entryIds);
    return CustomField(
      fieldName: fieldName ?? this.fieldName,
      controller: controller ?? this.controller,
      isDirectoryField: isDirectoryField ?? this.isDirectoryField,
      isCustomField: isCustomField ?? this.isCustomField,
      directoryId: directoryId ?? this.directoryId,
      entryId: nextEntryIds.isNotEmpty ? nextEntryIds.first : null,
      entryIds: nextEntryIds,
      uniqueId: uniqueId ?? this.uniqueId,
      type: type ?? this.type,
    );
  }

  CustomField withDirectorySelection(List<MainField> selected) {
    return copyWith(
      entryIds: selected.map((field) => field.id).toList(),
      controller: TextEditingController(
        text: selected.map((field) => field.value).join(', '),
      ),
    );
  }
}
