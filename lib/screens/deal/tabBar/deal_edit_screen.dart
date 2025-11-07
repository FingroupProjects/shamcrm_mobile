import 'dart:io';

import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
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
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_list_edit.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_name_list.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:crm_task_manager/models/directory_model.dart' as directory_model;

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
  final List<DealCustomFieldsById> dealCustomFields;
  final List<DirectoryValue>? directoryValues;
  final List<DealFiles>? files;
  final List<DealStatusById>? dealStatuses; // ✅ НОВОЕ: массив статусов
  final DealById? dealById; // ✅ НОВОЕ: добавьте полный объект deal

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
    required this.dealCustomFields,
    this.directoryValues,
    this.files,
    this.dealStatuses, // ✅ ДОБАВЬТЕ ЭТУ СТРОКУ В КОНСТРУКТОР!
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
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  List<DealFiles> existingFiles = [];
  List<String> newFiles = [];
  List<int> _selectedStatusIds = []; // ✅ НОВОЕ: список выбранных ID

  // Конфигурация полей (как в лидах)

  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations;


  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
    _fetchAndAddDirectoryFields();
    // Загружаем конфигурацию после первого кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFieldConfiguration();
      }
    });
    if (widget.files != null) {
      existingFiles = widget.files!;
      setState(() {
        fileNames.addAll(existingFiles.map((file) => file.name));
        fileSizes.addAll(existingFiles.map(
            (file) => '${(file.path.length / 1024).toStringAsFixed(3)}KB'));
        selectedFiles.addAll(existingFiles.map((file) => file.path));
      });
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
    selectedLead = widget.lead;
    startDateController.text = widget.startDate ?? '';
    endDateController.text = widget.endDate ?? '';
    sumController.text = widget.sum ?? '';

    // Initialize from deal_custom_fields (old format)
    for (var customField in widget.dealCustomFields) {
      customFields.add(CustomField(
        fieldName: customField.key,
        controller: TextEditingController(text: customField.value),
        uniqueId: Uuid().v4(),
        type: customField.type ?? 'string',
      ));
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

    // Initialize selected status IDs
    if (widget.dealStatuses != null && widget.dealStatuses!.isNotEmpty) {
      _selectedStatusIds = widget.dealStatuses!.map((s) => s.id).toList();
    } else {
      _selectedStatusIds = [widget.statusId];
    }

    // Initialize directory values...
    // (rest of your code)
  }

  void _fetchAndAddDirectoryFields() async {
    try {
      final directoryLinkData = await _apiService.getDealDirectoryLinks();
      if (directoryLinkData.data != null) {
        setState(() {
          for (var link in directoryLinkData.data!) {
            bool directoryExists = customFields.any((field) =>
                field.isDirectoryField && field.directoryId == link.directory.id);
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
      _showErrorSnackBar(
          AppLocalizations.of(context)!.translate('error_fetching_directories'));
    }
  }

  void _loadInitialData() {
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
  }

  Future<void> _addCustomField(String fieldName,
      {bool isDirectory = false, int? directoryId, String? type}) async {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) =>
          field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        showCustomSnackBar(context: context, message: 'Справочник уже добавлен');
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
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
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
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(300, 650, 200, 300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: Colors.white,
      items: [
        PopupMenuItem(
          value: 'manual',
          child: Text(
            AppLocalizations.of(context)!.translate('manual_input'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
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
              color: Color(0xff1E2E52),
            ),
          ),
        ),
      ],
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
      final List<Map<String, dynamic>> updates = [];
      for (var config in fieldConfigurations) {
        updates.add({
          'id': config.id,
          'position': config.position,
          'is_active': config.isActive ? 1 : 0,
          'is_required': config.required ? 1 : 0,
          'show_on_table': config.showOnTable ? 1 : 0,
        });
      }

      await ApiService().updateFieldPositions(
        tableName: 'deals',
        updates: updates,
      );
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)!
          .translate('error_saving_field_settings'));
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
      (field) => field.isDirectoryField && field.directoryId == config.directoryId,
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
        return LeadRadioGroupWidget(
          selectedLead: selectedLead,
          onSelectLead: (LeadData selectedLeadData) {
            setState(() {
              selectedLead = selectedLeadData.id.toString();
            });
          },
        );
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
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
          ],
        );
      case 'description':
        return CustomTextField(
          controller: descriptionController,
          hintText: AppLocalizations.of(context)!.translate('enter_description'),
          label: AppLocalizations.of(context)!.translate('description_list'),
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
      case 'file':
        // Показ блока файлов согласно позиции в конфигурации
        return _buildFileSelection();
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
            ? MainField(id: directoryField.entryId!, value: directoryField.controller.text)
            : null,
        onSelectField: (MainField selectedField) {
          setState(() {
            final idx = customFields.indexWhere((f) => f.directoryId == config.directoryId);
            if (idx != -1) {
              customFields[idx] = directoryField.copyWith(
                entryId: selectedField.id,
                controller: TextEditingController(text: selectedField.value),
              );
            }
          });
        },
        controller: directoryField.controller,
        onSelectEntryId: (int entryId) {
          setState(() {
            final idx = customFields.indexWhere((f) => f.directoryId == config.directoryId);
            if (idx != -1) {
              customFields[idx] = directoryField.copyWith(entryId: entryId);
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
      case 'start_date':
        return loc.translate('start_date');
      case 'end_date':
        return loc.translate('end_date');
      case 'sum':
        return loc.translate('summ');
      case 'description':
        return loc.translate('description_list');
      case 'deal_status_id':
        return loc.translate('status');
      case 'file':
        return loc.translate('file');
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
    // Сортируем поля по position перед отображением
    final sortedFields = [...fieldConfigurations]..sort((a, b) => a.position.compareTo(b.position));

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedFields.length + 1,
            // +1 для кнопки "Добавить поле"
            proxyDecorator: (child, index, animation) {
              // Добавляем тень и увеличение при перетаскивании
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  final double animValue = Curves.easeInOut.transform(animation.value);
                  final double scale = 1.0 + (animValue * 0.05); // Увеличение на 5%
                  final double elevation = animValue * 12.0; // Тень до 12

                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: elevation,
                      shadowColor: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) {
              // Игнорируем перемещение кнопки "Добавить поле" (последний элемент)
              if (oldIndex == sortedFields.length || newIndex == sortedFields.length + 1) {
                return;
              }

              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }

                // Не позволяем переместить на место кнопки
                if (newIndex >= sortedFields.length) {
                  newIndex = sortedFields.length - 1;
                }

                final item = sortedFields.removeAt(oldIndex);
                sortedFields.insert(newIndex, item);

                // Обновляем fieldConfigurations и position для всех полей
                final updatedFields = <FieldConfiguration>[];
                for (int i = 0; i < sortedFields.length; i++) {
                  final config = sortedFields[i];
                  updatedFields.add(FieldConfiguration(
                    id: config.id,
                    tableName: config.tableName,
                    fieldName: config.fieldName,
                    position: i + 1,
                    required: config.required,
                    isActive: config.isActive,
                    isCustomField: config.isCustomField,
                    createdAt: config.createdAt,
                    updatedAt: config.updatedAt,
                    customFieldId: config.customFieldId,
                    directoryId: config.directoryId,
                    type: config.type,
                    isDirectory: config.isDirectory,
                    showOnTable: config.showOnTable,
                  ));
                }

                // Обновляем fieldConfigurations
                fieldConfigurations = updatedFields;
              });
            },
            itemBuilder: (context, index) {
              // Последний элемент - кнопка "Добавить поле"
              if (index == sortedFields.length) {
                return Container(
                  key: ValueKey('add_field_button'),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('add_field'),
                    buttonColor: Color(0xff1E2E52),
                    textColor: Colors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xffE5E9F2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: Color(0xff99A4BA),
                      size: 24,
                    ),
                    SizedBox(width: 16),
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
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (config.required)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xffFFE5E5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('required'),
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xffFF4757),
                          ),
                        ),
                      ),
                    // Закомментировано - красная кнопка удаления пока не нужна
                    // Понадобится позже для удаления кастомных полей
                    // SizedBox(width: 8),
                    // IconButton(
                    //   icon: Icon(Icons.remove_circle, color: Colors.red),
                    //   onPressed: () {},
                    // ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: isSavingFieldOrder
              ? Container(
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xff4759FF).withOpacity(0.7),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.translate('saving'),
                    style: TextStyle(
                      color: Colors.white,
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
            buttonColor: Color(0xff4759FF),
            textColor: Colors.white,
            onPressed: () async {
              setState(() {
                isSavingFieldOrder = true;
              });

              try {
                // Сохраняем позиции полей на бэкенд
                await _saveFieldOrderToBackend();

                if (mounted) {
                  setState(() {
                    originalFieldConfigurations = null; // Очищаем снимок после сохранения
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
                          color: Colors.white,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green,
                      elevation: 3,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
    if (originalFieldConfigurations!.length != fieldConfigurations.length) return true;

    for (int i = 0; i < fieldConfigurations.length; i++) {
      final current = fieldConfigurations[i];
      final original = originalFieldConfigurations!.firstWhere(
            (f) => f.id == current.id,
        orElse: () => current,
      );

      if (current.position != original.position) return true;
    }

    return false;
  }

  Future<bool> _showExitSettingsDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            AppLocalizations.of(context)!.translate('warning'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.translate('position_changes_will_not_be_saved'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    buttonColor: Color(0xff1E2E52),
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('dont_save'),
                    onPressed: () => Navigator.of(context).pop(true),
                    buttonColor: Colors.red,
                    textColor: Colors.white,
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
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
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
    double totalSize = selectedFiles.fold<double>
      (0.0, (sum, file) => sum + File(file).lengthSync() / (1024 * 1024),);

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
      fileSizeTooLargeMessage: AppLocalizations.of(context)!.translate('file_size_too_large'),
      errorPickingFileMessage: AppLocalizations.of(context)!.translate('error_picking_file'),
    );

    // Если файлы выбраны, добавляем их
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          selectedFiles.add(file.path);
          fileNames.add(file.name);
          fileSizes.add(file.sizeKB);
        }
      });
    }
  }

  Widget _buildFileSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('file'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileNames.isEmpty ? 1 : fileNames.length + 1,
            itemBuilder: (context, index) {
              if (fileNames.isEmpty || index == fileNames.length) {
                return Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: 100,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/icons/files/add.png',
                            width: 60,
                            height: 60,
                          ),
                          SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('add_file'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final fileName = fileNames[index];
              final fileExtension = fileName.split('.').last.toLowerCase();

              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/icons/files/$fileExtension.png',
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/icons/files/file.png',
                                width: 60,
                                height: 60,
                              );
                            },
                          ),
                          SizedBox(height: 8),
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -6,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFiles.removeAt(index);
                            fileNames.removeAt(index);
                            fileSizes.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xff1E2E52),
                          ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('edit_deal'),
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: IconButton(
              icon: Image.asset(
                'assets/icons/arrow-left.png',
                width: 24,
                height: 24,
              ),
              onPressed: () => Navigator.pop(context, null),
            ),
          ),
        ),
        leadingWidth: 40,
        actions: [
          IconButton(
            icon: Icon(
              isSettingsMode ? Icons.close : Icons.settings,
              color: Color(0xff1E2E52),
            ),
            onPressed: () async {
              if (isSettingsMode) {
                // Выходим из режима настроек
                if (_hasFieldChanges()) {
                  // Есть несохраненные изменения - показываем диалог
                  final shouldExit = await _showExitSettingsDialog();
                  if (!shouldExit) return;

                  // Восстанавливаем позиции, но сохраняем новые добавленные поля
                  if (originalFieldConfigurations != null) {
                    setState(() {
                      // Находим новые поля (которые есть в текущей конфигурации, но нет в оригинальной)
                      final newFields = fieldConfigurations.where((current) {
                        return !originalFieldConfigurations!.any((original) => original.id == current.id);
                      }).toList();

                      // Восстанавливаем оригинальную конфигурацию
                      fieldConfigurations = [...originalFieldConfigurations!];

                      // Добавляем новые поля в конец списка
                      if (newFields.isNotEmpty) {
                        int maxPosition = fieldConfigurations.isEmpty
                            ? 0
                            : fieldConfigurations.map((e) => e.position).reduce((a, b) => a > b ? a : b);
                        for (int i = 0; i < newFields.length; i++) {
                          fieldConfigurations.add(FieldConfiguration(
                            id: newFields[i].id,
                            tableName: newFields[i].tableName,
                            fieldName: newFields[i].fieldName,
                            position: maxPosition + i + 1,
                            required: newFields[i].required,
                            isActive: newFields[i].isActive,
                            isCustomField: newFields[i].isCustomField,
                            createdAt: newFields[i].createdAt,
                            updatedAt: newFields[i].updatedAt,
                            customFieldId: newFields[i].customFieldId,
                            directoryId: newFields[i].directoryId,
                            type: newFields[i].type,
                            isDirectory: newFields[i].isDirectory,
                            showOnTable: newFields[i].showOnTable,
                          ));
                        }
                      }

                      originalFieldConfigurations = null;
                      isSettingsMode = false;
                    });
                  }
                } else {
                  // Нет изменений - просто выходим
                  setState(() {
                    originalFieldConfigurations = null;
                    isSettingsMode = false;
                  });
                }
              } else {
                // Входим в режим настроек - сохраняем снимок конфигурации
                setState(() {
                  originalFieldConfigurations = fieldConfigurations.map((config) {
                    return FieldConfiguration(
                      id: config.id,
                      tableName: config.tableName,
                      fieldName: config.fieldName,
                      position: config.position,
                      required: config.required,
                      isActive: config.isActive,
                      isCustomField: config.isCustomField,
                      createdAt: config.createdAt,
                      updatedAt: config.updatedAt,
                      customFieldId: config.customFieldId,
                      directoryId: config.directoryId,
                      type: config.type,
                      isDirectory: config.isDirectory,
                      showOnTable: config.showOnTable,
                    );
                  }).toList();
                  isSettingsMode = true;
                });
              }
            },
            tooltip: isSettingsMode
                ? AppLocalizations.of(context)!.translate('close')
                : AppLocalizations.of(context)!.translate('appbar_settings'),
          ),
          // IconButton(
          //   icon: Icon(Icons.refresh, color: Color(0xff1E2E52)),
          //   onPressed: () async {
          //     // Очищаем кэш и загружаем заново
          //     await ApiService().clearFieldConfigurationCache();
          //     await ApiService().loadAndCacheAllFieldConfigurations();
          //
          //     // Перезагружаем конфигурацию
          //     context.read<FieldConfigurationBloc>().add(
          //         FetchFieldConfiguration('leads')
          //     );
          //
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         content: Text('Конфигурация обновлена'),
          //         backgroundColor: Colors.green,
          //       ),
          //     );
          //   },
          //   tooltip: 'Обновить структуру полей',
          // ),
        ],
      ),
      body: MultiBlocProvider(
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
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.pop(context, true);
            }
          },
          child: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
            listener: (context, configState) {
              if (configState is FieldConfigurationLoaded) {
                setState(() {
                  fieldConfigurations = configState.fields;
                  isConfigurationLoaded = true;
                });
              } else if (configState is FieldConfigurationError) {
                _showErrorSnackBar('Ошибка загрузки конфигурации: ${configState.message}');
              }
            },
            builder: (context, configState) {
              if (configState is FieldConfigurationLoading || !isConfigurationLoaded) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xff1E2E52)),
                );
              }

              if (isSettingsMode) {
                return _buildSettingsMode();
              }              

              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () { FocusScope.of(context).unfocus(); },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Динамические поля по конфигурации
                              ...(() {
                                final sorted = [...fieldConfigurations]..sort((a, b) => a.position.compareTo(b.position));
                                return sorted.map((config) {
                                  return Column(
                                    children: [
                                      _buildFieldWidget(config),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                }).toList();
                              })(),

                              // Пользовательские поля, которых нет в конфигурации сервера
                              ...customFields.where((field) {
                                return !fieldConfigurations.any((config) =>
                                  (config.isCustomField && config.fieldName == field.fieldName) ||
                                  (config.isDirectory && config.directoryId == field.directoryId)
                                );
                              }).map((field) {
                                final index = customFields.indexOf(field);
                                return Container(
                                  key: ValueKey(field.uniqueId),
                                  child: field.isDirectoryField && field.directoryId != null
                                      ? MainFieldDropdownWidget(
                                          directoryId: field.directoryId!,
                                          directoryName: field.fieldName,
                                          selectedField: field.entryId != null
                                              ? MainField(id: field.entryId!, value: field.controller.text)
                                              : null,
                                          onSelectField: (MainField selectedField) {
                                            setState(() {
                                              customFields[index] = field.copyWith(
                                                entryId: selectedField.id,
                                                controller: TextEditingController(text: selectedField.value),
                                              );
                                            });
                                          },
                                          controller: field.controller,
                                          onSelectEntryId: (int entryId) {
                                            setState(() {
                                              customFields[index] = field.copyWith(entryId: entryId);
                                            });
                                          },
                                          onRemove: () {
                                            setState(() { customFields.removeAt(index); });
                                          },
                                          initialEntryId: field.entryId,
                                        )
                                      : CustomFieldWidget(
                                          fieldName: field.fieldName,
                                          valueController: field.controller,
                                          onRemove: () {
                                            setState(() { customFields.removeAt(index); });
                                          },
                                          type: field.type,
                                        ),
                                );
                              }).toList(),

                              
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('cancel'),
                              buttonColor: const Color(0xffF4F7FD),
                              textColor: Colors.black,
                              onPressed: () => Navigator.pop(context, null),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: BlocBuilder<DealBloc, DealState>(
                              builder: (context, state) {
                                if (state is DealLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(color: Color(0xff1E2E52)),
                                  );
                                } else {
                                  return CustomButton(
                                    buttonText: AppLocalizations.of(context)!.translate('save'),
                                    buttonColor: const Color(0xff4759FF),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      if (_formKey.currentState!.validate() &&
                                          selectedManager != null &&
                                          selectedLead != null) {
                                        DateTime? parsedStartDate;
                                        DateTime? parsedEndDate;

                                        if (startDateController.text.isNotEmpty) {
                                          try {
                                            parsedStartDate = DateFormat('dd/MM/yyyy').parseStrict(startDateController.text);
                                          } catch (e) {
                                            _showErrorSnackBar(AppLocalizations.of(context)!.translate('error_parsing_date'));
                                            return;
                                          }
                                        }
                                        if (endDateController.text.isNotEmpty) {
                                          try {
                                            parsedEndDate = DateFormat('dd/MM/yyyy').parseStrict(endDateController.text);
                                          } catch (e) {
                                            _showErrorSnackBar(AppLocalizations.of(context)!.translate('error_parsing_date'));
                                            return;
                                          }
                                        }

                                        if (parsedStartDate != null && parsedEndDate != null && parsedStartDate.isAfter(parsedEndDate)) {
                                          setState(() { isEndDateInvalid = true; });
                                          _showErrorSnackBar(AppLocalizations.of(context)!.translate('start_date_after_end_date'));
                                          return;
                                        }

                                        List<Map<String, dynamic>> customFieldList = [];
                                        List<Map<String, int>> directoryValues = [];

                                        for (var field in customFields) {
                                          String fieldName = field.fieldName.trim();
                                          String fieldValue = field.controller.text.trim();
                                          String? fieldType = field.type;

                                          if (fieldType == 'number' && fieldValue.isNotEmpty) {
                                            if (!RegExp(r'^\d+$').hasMatch(fieldValue)) {
                                              _showErrorSnackBar(AppLocalizations.of(context)!.translate('enter_valid_number'));
                                              return;
                                            }
                                          }

                                          if ((fieldType == 'date' || fieldType == 'datetime') && fieldValue.isNotEmpty) {
                                            try {
                                              if (fieldType == 'date') {
                                                DateFormat('dd/MM/yyyy').parse(fieldValue);
                                              } else {
                                                DateFormat('dd/MM/yyyy HH:mm').parse(fieldValue);
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(context)!.translate('enter_valid_${fieldType}'),
                                                    style: const TextStyle(
                                                      fontFamily: 'Gilroy',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }
                                          }

                                          if (field.isDirectoryField && field.directoryId != null && field.entryId != null) {
                                            directoryValues.add({
                                              'directory_id': field.directoryId!,
                                              'entry_id': field.entryId!,
                                            });
                                          } else if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
                                            customFieldList.add({
                                              'key': fieldName,
                                              'value': fieldValue,
                                              'type': fieldType ?? 'string',
                                            });
                                          }
                                        }

                                        final localizations = AppLocalizations.of(context)!;
                                        context.read<DealBloc>().add(UpdateDeal(
                                          dealId: widget.dealId,
                                          name: titleController.text,
                                          dealStatusId: _selectedStatuses!.toInt(),
                                          managerId: selectedManager != null ? int.parse(selectedManager!) : null,
                                          leadId: selectedLead != null ? int.parse(selectedLead!) : null,
                                          description: descriptionController.text.isEmpty ? null : descriptionController.text,
                                          startDate: parsedStartDate,
                                          endDate: parsedEndDate,
                                          sum: sumController.text.isEmpty ? null : sumController.text,
                                          dealtypeId: 1,
                                          customFields: customFieldList,
                                          directoryValues: directoryValues,
                                          localizations: localizations,
                                          filePaths: newFiles,
                                          existingFiles: existingFiles,
                                          dealStatusIds: _selectedStatusIds,
                                        ));
                                      } else {
                                        _showErrorSnackBar(AppLocalizations.of(context)!.translate('fill_required_fields'));
                                      }
                                    },
                                  );
                                }
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
    );
  }
}

class CustomField {
  final String fieldName;
  final TextEditingController controller;
  final bool isDirectoryField;
  final int? directoryId;
  final int? entryId;
  final String uniqueId;
  final String? type; // Добавлено поле type

  CustomField({
    required this.fieldName,
    TextEditingController? controller,
    this.isDirectoryField = false,
    this.directoryId,
    this.entryId,
    required this.uniqueId,
    this.type,
  }) : controller = controller ?? TextEditingController();

  CustomField copyWith({
    String? fieldName,
    TextEditingController? controller,
    bool? isDirectoryField,
    int? directoryId,
    int? entryId,
    String? uniqueId,
    String? type,
  }) {
    return CustomField(
      fieldName: fieldName ?? this.fieldName,
      controller: controller ?? this.controller,
      isDirectoryField: isDirectoryField ?? this.isDirectoryField,
      directoryId: directoryId ?? this.directoryId,
      entryId: entryId ?? this.entryId,
      uniqueId: uniqueId ?? this.uniqueId,
      type: type ?? this.type,
    );
  }
}