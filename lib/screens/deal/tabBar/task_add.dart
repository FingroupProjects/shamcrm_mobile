import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_bloc.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_state.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_withPriority.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/page_2/warehouse/openings/cash_register/cash_register_content.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/status_list.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_list_edit.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class TaskAddFromDeal extends StatefulWidget {
  final int dealId;

  const TaskAddFromDeal({Key? key, required this.dealId}) : super(key: key);

  @override
  _TaskAddFromDealState createState() => _TaskAddFromDealState();
}

class _TaskAddFromDealState extends State<TaskAddFromDeal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<FileHelper> files = [];
  
  int? selectedPriority;
  String? selectedProject;
  int? selectedStatusId;
  List<String>? selectedUsers;
  List<CustomField> customFields = [];
  
  // Флаги для валидации обязательных полей
  bool isNameInvalid = false;
  bool isExecutorInvalid = false;
  bool isProjectInvalid = false;
  bool isEndDateInvalid = false;
  bool isStatusInvalid = false;

  // Режим настроек
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations;
  final GlobalKey _addFieldButtonKey = GlobalKey();

  // Конфигурация полей с сервера
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
    _setDefaultValues();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
  }
  
  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('TaskAddFromDeal: Loading field configuration for tasks');
    }
    context.read<FieldConfigurationBloc>().add(FetchFieldConfiguration('tasks'));
  }

  Future<void> _saveFieldOrderToBackend() async {
    try {
      final List<Map<String, dynamic>> updates = [];
      for (var config in fieldConfigurations) {
        updates.add({
          'id': config.id,
          'position': config.position,
          'is_active': config.isActive ? 1 : 0,
          'is_required': config.originalRequired ? 1 : 0,
          'show_on_table': config.showOnTable ? 1 : 0,
        });
      }

      await ApiService().updateFieldPositions(
        tableName: 'tasks',
        updates: updates,
      );

      if (kDebugMode) {
        print('TaskAddFromDeal: Field positions saved to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TaskAddFromDeal: Error saving field positions: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка сохранения настроек полей',
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
            backgroundColor: Colors.red,
            elevation: 3,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  CustomField _getOrCreateCustomField(FieldConfiguration config) {
    final existingField = customFields.firstWhere(
      (field) => field.fieldName == config.fieldName && field.isCustomField,
      orElse: () {
        final newField = CustomField(
          fieldName: config.fieldName,
          uniqueId: Uuid().v4(),
          controller: TextEditingController(),
          type: config.type,
          isCustomField: true,
        );
        customFields.add(newField);
        return newField;
      },
    );
    return existingField;
  }

  CustomField _getOrCreateDirectoryField(FieldConfiguration config) {
    final existingField = customFields.firstWhere(
      (field) => field.directoryId == config.directoryId,
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

  Widget _buildStandardField(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'name':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFieldWithPriority(
              controller: nameController,
              hintText: AppLocalizations.of(context)!.translate('enter_category_name'),
              label: AppLocalizations.of(context)!.translate('category_name'),
              showPriority: true,
              isPrioritySelected: selectedPriority == 3,
              hasError: isNameInvalid,
              onPriorityChanged: (bool? value) {
                setState(() {
                  selectedPriority = value == true ? 3 : 1;
                  if (nameController.text.trim().isNotEmpty) {
                    isNameInvalid = false;
                  }
                });
              },
              priorityText: AppLocalizations.of(context)!.translate('urgent'),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    isNameInvalid = false;
                  });
                }
              },
            ),
            if (isNameInvalid)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  AppLocalizations.of(context)!.translate('field_required'),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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

      case 'executor':
        return UserMultiSelectWidget(
          selectedUsers: selectedUsers,
          onSelectUsers: (List<UserData> selectedUsersData) {
            setState(() {
              selectedUsers = selectedUsersData.map((user) => user.id.toString()).toList();
              isExecutorInvalid = false;
            });
          },
          hasError: isExecutorInvalid,
        );

      case 'project':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProjectTaskGroupWidget(
              selectedProject: selectedProject,
              onSelectProject: (ProjectTask selectedProjectData) {
                setState(() {
                  selectedProject = selectedProjectData.id.toString();
                  isProjectInvalid = false;
                });
              },
              hasError: isProjectInvalid,
            ),
            if (isProjectInvalid)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  AppLocalizations.of(context)!.translate('field_required'),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );

      case 'deadline':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFieldDate(
              controller: endDateController,
              label: AppLocalizations.of(context)!.translate('deadline'),
              hasError: isEndDateInvalid,
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    isEndDateInvalid = false;
                  });
                }
              },
            ),
            if (isEndDateInvalid)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  AppLocalizations.of(context)!.translate('field_required'),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );

      case 'task_status_id':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskStatusRadioGroupWidget(
              selectedStatus: selectedStatusId?.toString(),
              onSelectStatus: (TaskStatus selectedStatusData) {
                setState(() {
                  selectedStatusId = selectedStatusData.id;
                  isStatusInvalid = false;
                });
              },
              hasError: isStatusInvalid,
            ),
            if (isStatusInvalid)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  AppLocalizations.of(context)!.translate('field_required'),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );

      default:
        return SizedBox.shrink();
    }
  }

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
        selectedField: null,
        onSelectField: (MainField selectedField) {
          setState(() {
            final index = customFields.indexWhere((f) => f.directoryId == config.directoryId);
            if (index != -1) {
              customFields[index] = directoryField.copyWith(
                entryId: selectedField.id,
                controller: TextEditingController(text: selectedField.value),
              );
            }
          });
        },
        controller: directoryField.controller,
        onSelectEntryId: (int entryId) {
          setState(() {
            final index = customFields.indexWhere((f) => f.directoryId == config.directoryId);
            if (index != -1) {
              customFields[index] = directoryField.copyWith(entryId: entryId);
            }
          });
        },
      );
    }

    // Специальная обработка для executor - добавляем текст ошибки
    if (config.fieldName == 'executor') {
      final field = _buildStandardField(config);
      if (field is SizedBox) return field;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          field,
          if (isExecutorInvalid)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                AppLocalizations.of(context)!.translate('field_required'),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    }

    // Специальная обработка для task_status_id - всегда показываем
    if (config.fieldName == 'task_status_id') {
      final field = _buildStandardField(config);
      // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Всегда возвращаем виджет для task_status_id
      if (kDebugMode) {
        print('TaskAddFromDeal: _buildFieldWidget for task_status_id, returning widget type: ${field.runtimeType}');
      }
      return field;
    }

    return _buildStandardField(config);
  }

  List<Widget> _withVerticalSpacing(List<Widget> widgets, {double spacing = 8}) {
    if (widgets.isEmpty) return widgets;
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i != widgets.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }

  // ✅ НОВОЕ: Построение всех обязательных полей независимо от конфигурации
List<Widget> _buildAllRequiredFields() {
  final List<Widget> widgets = [];

  // 1. Название (всегда первое)
  widgets.add(_buildStandardField(FieldConfiguration(
    id: 0,
    tableName: 'tasks',
    fieldName: 'name',
    position: 1,
    required: true,
    isActive: true,
    isCustomField: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    showOnTable: false,
    originalRequired: true,
    isDirectory: false,
  )));

  // 2. Статус задачи (ОБЯЗАТЕЛЬНОЕ ПОЛЕ) ✅ ПЕРЕМЕЩЕНО СЮДА
  widgets.add(_buildStandardField(FieldConfiguration(
    id: 0,
    tableName: 'tasks',
    fieldName: 'task_status_id',
    position: 2,
    required: true,
    isActive: true,
    isCustomField: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    showOnTable: false,
    originalRequired: true,
    isDirectory: false,
  )));

  // 3. Описание
  widgets.add(_buildStandardField(FieldConfiguration(
    id: 0,
    tableName: 'tasks',
    fieldName: 'description',
    position: 3,
    required: false,
    isActive: true,
    isCustomField: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    showOnTable: false,
    originalRequired: false,
    isDirectory: false,
  )));

  // 4. Исполнители (ОБЯЗАТЕЛЬНОЕ ПОЛЕ)
  widgets.add(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildStandardField(FieldConfiguration(
        id: 0,
        tableName: 'tasks',
        fieldName: 'executor',
        position: 4,
        required: true,
        isActive: true,
        isCustomField: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        showOnTable: false,
        originalRequired: true,
        isDirectory: false,
      )),
      if (isExecutorInvalid)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            AppLocalizations.of(context)!.translate('field_required'),
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ],
  ));

  // 5. Проект (ОБЯЗАТЕЛЬНОЕ ПОЛЕ)
  widgets.add(_buildStandardField(FieldConfiguration(
    id: 0,
    tableName: 'tasks',
    fieldName: 'project',
    position: 5,
    required: true,
    isActive: true,
    isCustomField: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    showOnTable: false,
    originalRequired: true,
    isDirectory: false,
  )));

  // 6. Дедлайн (ОБЯЗАТЕЛЬНОЕ ПОЛЕ)
  widgets.add(_buildStandardField(FieldConfiguration(
    id: 0,
    tableName: 'tasks',
    fieldName: 'deadline',
    position: 6,
    required: true,
    isActive: true,
    isCustomField: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    showOnTable: false,
    originalRequired: true,
    isDirectory: false,
  )));

  return widgets;
}
 List<Widget> _buildConfiguredFieldWidgets() {
  // Сортируем поля по позиции
  final sortedFields = [...fieldConfigurations]
    ..sort((a, b) => a.position.compareTo(b.position));

  if (kDebugMode) {
    print('TaskAddFromDeal: Total fields from config: ${sortedFields.length}');
    for (var field in sortedFields) {
      print('TaskAddFromDeal: Field - name: ${field.fieldName}, position: ${field.position}, isActive: ${field.isActive}, isCustom: ${field.isCustomField}, isDirectory: ${field.isDirectory}');
    }
  }

  // Обязательные системные поля, которые всегда должны отображаться
  // ✅ КРИТИЧЕСКОЕ: task_status_id ВСЕГДА на позиции 2
  final requiredSystemFields = {
    'name': 1,
    'task_status_id': 2,  // ✅ ВСЕГДА позиция 2
    'description': 3,
    'executor': 4,
    'project': 5,
    'deadline': 6,
  };
  
  // Фильтруем активные поля + обязательные системные поля (даже если неактивны)
  final activeFields = sortedFields.where((config) {
    return config.isActive || 
           (requiredSystemFields.containsKey(config.fieldName) && !config.isCustomField && !config.isDirectory);
  }).toList();

  // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Принудительно добавляем обязательные поля, если их нет
  // И ОБЯЗАТЕЛЬНО исправляем позицию для task_status_id на 2
  final activeFieldNames = activeFields.map((f) => f.fieldName).toSet();
  
  // Сначала проверяем и исправляем task_status_id, если он уже есть
  final statusFieldIndex = activeFields.indexWhere((f) => f.fieldName == 'task_status_id');
  if (statusFieldIndex != -1) {
    // Исправляем позицию на 2 и делаем активным
    final existingStatusField = activeFields[statusFieldIndex];
    activeFields[statusFieldIndex] = FieldConfiguration(
      id: existingStatusField.id,
      tableName: existingStatusField.tableName,
      fieldName: existingStatusField.fieldName,
      position: 2, // ✅ ВСЕГДА позиция 2
      required: existingStatusField.required,
      isActive: true, // ✅ ВСЕГДА активен
      isCustomField: existingStatusField.isCustomField,
      createdAt: existingStatusField.createdAt,
      updatedAt: existingStatusField.updatedAt,
      customFieldId: existingStatusField.customFieldId,
      directoryId: existingStatusField.directoryId,
      type: existingStatusField.type,
      isDirectory: existingStatusField.isDirectory,
      showOnTable: existingStatusField.showOnTable,
      originalRequired: existingStatusField.originalRequired,
    );
    if (kDebugMode) {
      print('TaskAddFromDeal: Fixed task_status_id position to 2 and set isActive to true');
    }
  } else {
    // Добавляем task_status_id, если его нет
    final tempConfig = FieldConfiguration(
      id: 0,
      tableName: 'tasks',
      fieldName: 'task_status_id',
      position: 2, // ✅ ВСЕГДА позиция 2
      required: true,
      isActive: true, // ✅ ВСЕГДА активен
      isCustomField: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      showOnTable: false,
      originalRequired: true,
      isDirectory: false,
    );
    activeFields.add(tempConfig);
    if (kDebugMode) {
      print('TaskAddFromDeal: Added missing task_status_id field with position 2');
    }
  }
  
  // Добавляем другие обязательные поля, если их нет
  for (var entry in requiredSystemFields.entries) {
    if (entry.key != 'task_status_id' && !activeFieldNames.contains(entry.key)) {
      final tempConfig = FieldConfiguration(
        id: 0,
        tableName: 'tasks',
        fieldName: entry.key,
        position: entry.value,
        required: true,
        isActive: true,
        isCustomField: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        showOnTable: false,
        originalRequired: true,
        isDirectory: false,
      );
      activeFields.add(tempConfig);
      if (kDebugMode) {
        print('TaskAddFromDeal: Added missing required field: ${entry.key} with position ${entry.value}');
      }
    }
  }

  // Сортируем активные поля по позиции после добавления недостающих
  activeFields.sort((a, b) => a.position.compareTo(b.position));

  if (kDebugMode) {
    print('TaskAddFromDeal: Active fields count (including required): ${activeFields.length}');
    for (var field in activeFields) {
      print('TaskAddFromDeal: Active field - name: ${field.fieldName}, position: ${field.position}, isActive: ${field.isActive}');
    }
  }

  if (activeFields.isEmpty) {
    // Если с сервера ничего не пришло, показываем жёстко заданные обязательные поля
    return _withVerticalSpacing(_buildAllRequiredFields(), spacing: 8);
  }

  // Строим виджеты для активных полей
  final List<Widget> widgets = [];
  bool hasStatusWidget = false;
  Widget? statusWidget;
  
  for (var config in activeFields) {
    if (kDebugMode) {
      print('TaskAddFromDeal: Building widget for field: ${config.fieldName}');
    }
    // Специальная обработка для task_status_id - всегда показываем
    if (config.fieldName == 'task_status_id') {
      if (kDebugMode) {
        print('TaskAddFromDeal: Processing task_status_id field, isActive: ${config.isActive}, position: ${config.position}');
      }
      final widget = _buildFieldWidget(config);
      if (kDebugMode) {
        print('TaskAddFromDeal: task_status_id widget built successfully, widget type: ${widget.runtimeType}');
      }
      // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Всегда добавляем виджет для task_status_id
      widgets.add(widget);
      hasStatusWidget = true;
      statusWidget = widget;
        // statusWidgetIndex = widgets.length - 1;
    } else {
      final widget = _buildFieldWidget(config);
      // Исключаем только пустые SizedBox виджеты для других полей
      if (widget is! SizedBox) {
        widgets.add(widget);
      }
    }
  }

  // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Если task_status_id не был добавлен, добавляем его принудительно на позицию 2
  if (!hasStatusWidget || statusWidget == null) {
    if (kDebugMode) {
      print('TaskAddFromDeal: task_status_id widget was not found! Creating it now...');
    }
    final statusConfig = FieldConfiguration(
      id: 0,
      tableName: 'tasks',
      fieldName: 'task_status_id',
      position: 2,
      required: true,
      isActive: true,
      isCustomField: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      showOnTable: false,
      originalRequired: true,
      isDirectory: false,
    );
    final forcedStatusWidget = _buildFieldWidget(statusConfig);
    
    // Вставляем на позицию 2 (индекс 1, так как name должен быть на позиции 1, индекс 0)
    // Если виджетов меньше 2, просто добавляем в конец и потом отсортируем
    if (widgets.length >= 1) {
      widgets.insert(1, forcedStatusWidget); // Вставляем после первого элемента (name)
    } else {
      widgets.add(forcedStatusWidget);
    }
    
    if (kDebugMode) {
      print('TaskAddFromDeal: task_status_id widget forced to be added at position 2');
    }
  }

  if (kDebugMode) {
    print('TaskAddFromDeal: Total widgets built: ${widgets.length}');
    for (var i = 0; i < widgets.length; i++) {
      print('TaskAddFromDeal: Widget $i type: ${widgets[i].runtimeType}');
    }
    print('TaskAddFromDeal: task_status_id widget is present: ${hasStatusWidget || statusWidget != null}');
  }

  return _withVerticalSpacing(widgets, spacing: 8);
}

  void _setDefaultValues() {
    selectedPriority = 1;
    final now = DateTime.now();
    startDateController.text = DateFormat('dd/MM/yyyy').format(now);
  }

  Future<void> _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId, String? type}) async {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        showCustomSnackBar(context: context, message: 'Справочник уже добавлен', isSuccess: true);
        debugPrint("TaskAddFromDeal: Directory with ID $directoryId already exists.");
        return;
      }
      
      try {
        await ApiService().linkDirectory(
          directoryId: directoryId,
          modelType: 'task',
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
          
          context.read<FieldConfigurationBloc>().add(
            FetchFieldConfiguration('tasks'),
          );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка добавления справочника: $e',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await ApiService().addNewField(
        tableName: 'tasks',
        fieldName: fieldName,
        fieldType: type ?? 'string',
      );

      if (mounted) {
        context.read<FieldConfigurationBloc>().add(
          FetchFieldConfiguration('tasks'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка добавления поля: $e',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddFieldMenu() {
    final RenderBox? renderBox = _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final menuItems = [
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
    ];

    final showAbove = menuItems.length >= 5;
    final double verticalOffset = showAbove ? -8 : size.height + 8;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        showAbove ? offset.dy + verticalOffset : offset.dy + verticalOffset,
        MediaQuery.of(context).size.width - offset.dx - size.width,
        showAbove ? MediaQuery.of(context).size.height - offset.dy + verticalOffset : MediaQuery.of(context).size.height - offset.dy - size.height - 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: Colors.white,
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
              onAddDirectory: (directory) async {
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

  bool _hasFieldChanges() {
    if (originalFieldConfigurations == null) return false;
    if (originalFieldConfigurations!.length != fieldConfigurations.length) return true;

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
    ) ?? false;
  }

  Widget _buildSettingsMode() {
    final sortedFields = [...fieldConfigurations]..sort((a, b) => a.position.compareTo(b.position));

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
                  final double animValue = Curves.easeInOut.transform(animation.value);
                  final double scale = 1.0 + (animValue * 0.05);
                  final double elevation = animValue * 12.0;

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
              if (oldIndex == sortedFields.length || newIndex == sortedFields.length + 1) {
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
                  ));
                }

                fieldConfigurations = updatedFields;
              });
            },
            itemBuilder: (context, index) {
              if (index == sortedFields.length) {
                return Container(
                  key: _addFieldButtonKey,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: Color(0xff99A4BA),
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
                          SizedBox(height: 12),
                          // Запрещаем отключать обязательные системные поля
                          if (config.fieldName != 'name' && 
                              config.fieldName != 'task_status_id' &&
                              config.fieldName != 'executor' &&
                              config.fieldName != 'project' &&
                              config.fieldName != 'deadline' &&
                              config.fieldName != 'description')
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

                                  final idx = fieldConfigurations.indexWhere((f) => f.id == config.id);
                                  if (idx != -1) {
                                    fieldConfigurations[idx] = updatedConfig;
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: config.isActive ? Color(0xff4759FF) : Colors.white,
                                        border: Border.all(
                                          color: config.isActive ? Color(0xff4759FF) : Color(0xffCCD5E0),
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
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!.translate('show_field'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        color: config.isActive ? Color(0xff1E2E52) : Color(0xff6B7A99),
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
                      await _saveFieldOrderToBackend();

                      if (mounted) {
                        setState(() {
                          originalFieldConfigurations = null;
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
                    } catch (e) {
                      if (kDebugMode) {
                        print('TaskAddFromDeal: Error in save button: $e');
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

  String _getFieldDisplayName(FieldConfiguration config) {
    final loc = AppLocalizations.of(context)!;
    switch (config.fieldName) {
      case 'name':
        return loc.translate('category_name');
      case 'description':
        return loc.translate('description_list');
      case 'executor':
        return loc.translate('assignees_list');
      case 'project':
        return loc.translate('projects');
      case 'deadline':
        return loc.translate('deadline');
      case 'task_status_id':
        return loc.translate('task_status');
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

  Future<void> _pickFile() async {
    double totalSize = files.fold<double>(0.0, (sum, file) {
      return sum + File(file.path).lengthSync() / (1024 * 1024);
    });

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

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          files.add(FileHelper(id: 0, name: file.name, path: file.path, size: file.sizeKB));
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
            itemCount: files.isEmpty ? 1 : files.length + 1,
            itemBuilder: (context, index) {
              if (files.isEmpty || index == files.length) {
                return Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: 100,
                      child: Column(
                        children: [
                          Image.asset('assets/icons/files/add.png', width: 60, height: 60),
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
                            files.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.close, size: 16, color: Color(0xff1E2E52)),
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

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              buttonText: AppLocalizations.of(context)!.translate('cancel'),
              buttonColor: const Color(0xffF4F7FD),
              textColor: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<TaskAddFromDealBloc, TaskAddFromDealState>(
              builder: (context, state) {
                return state is TaskAddFromDealLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff1E2E52),
                        ),
                      )
                    : CustomButton(
                        buttonText: AppLocalizations.of(context)!.translate('add'),
                        buttonColor: const Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: _submitForm,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    // Сброс всех флагов ошибок
    setState(() {
      isNameInvalid = false;
      isStatusInvalid = false;
      isExecutorInvalid = false;
      isProjectInvalid = false;
      isEndDateInvalid = false;
    });

    bool hasError = false;

    // 1. Название
    if (nameController.text.trim().isEmpty) {
      setState(() {
        isNameInvalid = true;
      });
      hasError = true;
    }

    // 2. Статус задачи
    if (selectedStatusId == null) {
      setState(() {
        isStatusInvalid = true;
      });
      hasError = true;
    }

    // 3. Исполнители
    if (selectedUsers == null || selectedUsers!.isEmpty) {
      setState(() {
        isExecutorInvalid = true;
      });
      hasError = true;
    }

    // 4. Проект
    if (selectedProject == null || selectedProject!.isEmpty) {
      setState(() {
        isProjectInvalid = true;
      });
      hasError = true;
    }

    // 5. Дедлайн
    if (endDateController.text.trim().isEmpty) {
      setState(() {
        isEndDateInvalid = true;
      });
      hasError = true;
    }

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('fill_required_fields'),
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
          backgroundColor: Colors.red,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _createTask();
  }

  void _createTask() {
    final String name = nameController.text.trim();
    final String? startDateString = startDateController.text.isEmpty ? null : startDateController.text;
    final String? endDateString = endDateController.text.isEmpty ? null : endDateController.text;
    final String? description = descriptionController.text.isEmpty ? null : descriptionController.text;

    DateTime? startDate;
    if (startDateString != null && startDateString.isNotEmpty) {
      try {
        startDate = DateFormat('dd/MM/yyyy').parse(startDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('enter_valid_date')),
          ),
        );
        return;
      }
    }

    DateTime? endDate;
    if (endDateString != null && endDateString.isNotEmpty) {
      try {
        endDate = DateFormat('dd/MM/yyyy').parse(endDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('enter_valid_date')),
          ),
        );
        return;
      }
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      setState(() {
        isEndDateInvalid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('start_date_after_end_date'),
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<Map<String, dynamic>> customFieldMap = [];
    List<Map<String, int>> directoryValues = [];

    for (var field in customFields) {
      String fieldName = field.fieldName.trim();
      String fieldValue = field.controller.text.trim();
      String? fieldType = field.type;

      if (fieldType == 'text') {
        fieldType = 'string';
      }
      fieldType ??= 'string';

      if (fieldType == 'number' && fieldValue.isNotEmpty) {
        if (!RegExp(r'^\d+$').hasMatch(fieldValue)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('enter_valid_number'),
                style: TextStyle(
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
                style: TextStyle(
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
        customFieldMap.add({
          'key': fieldName,
          'value': fieldValue,
          'type': fieldType,
        });
      }
    }

    List<String> filePaths = files.map((file) => file.path).toList();

    context.read<TaskAddFromDealBloc>().add(
      CreateTaskFromDeal(
        dealId: widget.dealId,
        name: name,
        statusId: selectedStatusId!,
        taskStatusId: selectedStatusId!,
        priority: selectedPriority ?? 1,
        startDate: startDate,
        endDate: endDate,
        projectId: selectedProject != null ? int.parse(selectedProject!) : null,
        userId: selectedUsers?.map((id) => int.parse(id)).toList(),
        description: description,
        customFields: customFieldMap,
        filePaths: filePaths,
        directoryValues: directoryValues,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
              onPressed: () {
                Navigator.pop(context, widget.dealId);
                context.read<TaskAddFromDealBloc>().add(FetchTaskDealStatuses());
              },
            ),
          ),
        ),
        leadingWidth: 40,
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('new_task'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isSettingsMode ? Icons.close : Icons.settings,
              color: Color(0xff1E2E52),
            ),
            onPressed: () async {
              if (isSettingsMode) {
                if (_hasFieldChanges()) {
                  final shouldExit = await _showExitSettingsDialog();
                  if (!shouldExit) return;

                  if (originalFieldConfigurations != null) {
                    setState(() {
                      final newFields = fieldConfigurations.where((current) {
                        return !originalFieldConfigurations!.any((original) => original.id == current.id);
                      }).toList();

                      fieldConfigurations = [...originalFieldConfigurations!];

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
                            originalRequired: newFields[i].originalRequired,
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
                  originalFieldConfigurations = fieldConfigurations.map((config) {
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
            tooltip: isSettingsMode
                ? AppLocalizations.of(context)!.translate('close')
                : AppLocalizations.of(context)!.translate('appbar_settings'),
          ),
        ],
      ),
      body: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
        listener: (context, configState) {
          if (configState is FieldConfigurationLoaded) {
            if (kDebugMode) {
              print('TaskAddFromDeal: Configuration loaded with ${configState.fields.length} fields');
            }
            setState(() {
              fieldConfigurations = configState.fields;
              isConfigurationLoaded = true;
            });
          } else if (configState is FieldConfigurationError) {
            if (kDebugMode) {
              print('TaskAddFromDeal: Configuration error: ${configState.message}');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ошибка загрузки конфигурации: ${configState.message}',
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
          }
        },
        builder: (context, configState) {
          if (configState is FieldConfigurationLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff1E2E52),
              ),
            );
          }

          if (!isConfigurationLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    color: Color(0xff1E2E52),
                  ),
                  SizedBox(height: 16),
                  Text('Загрузка конфигурации...'),
                ],
              ),
            );
          }

          if (isSettingsMode) {
            return _buildSettingsMode();
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => MainFieldBloc()),
            ],
            child: BlocListener<TaskAddFromDealBloc, TaskAddFromDealState>(
              listener: (context, state) {
                if (state is TaskAddFromDealError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.translate(state.message),
                        style: const TextStyle(
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
                      backgroundColor: Colors.red,
                      elevation: 3,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else if (state is TaskAddFromDealSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.translate(state.message),
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
                      duration: Duration(seconds: 3),
                    ),
                  );
                  Navigator.pop(context, widget.dealId);
                  context.read<TaskAddFromDealBloc>().add(FetchTaskDealStatuses());
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✅ НОВОЕ: Всегда показываем обязательные поля
                              ..._buildConfiguredFieldWidgets(),

                              if (customFields.where((field) {
                                return !fieldConfigurations.any((config) =>
                                    (config.isCustomField && config.fieldName == field.fieldName) ||
                                    (config.isDirectory && config.directoryId == field.directoryId));
                              }).isNotEmpty)
                                const SizedBox(height: 16),

                              ...(() {
                                final customFieldsList = customFields.where((field) {
                                  return !fieldConfigurations.any((config) =>
                                      (config.isCustomField && config.fieldName == field.fieldName) ||
                                      (config.isDirectory && config.directoryId == field.directoryId));
                                }).toList();

                                if (customFieldsList.isEmpty) return <Widget>[];

                                final customFieldWidgets = customFieldsList.map((field) {
                                  return field.isDirectoryField && field.directoryId != null
                                      ? MainFieldDropdownWidget(
                                          directoryId: field.directoryId!,
                                          directoryName: field.fieldName,
                                          selectedField: null,
                                          onSelectField: (MainField selectedField) {
                                            setState(() {
                                              final idx = customFields.indexOf(field);
                                              customFields[idx] = field.copyWith(
                                                entryId: selectedField.id,
                                                controller: TextEditingController(
                                                    text: selectedField.value),
                                              );
                                            });
                                          },
                                          controller: field.controller,
                                          onSelectEntryId: (int entryId) {
                                            setState(() {
                                              final idx = customFields.indexOf(field);
                                              customFields[idx] = field.copyWith(
                                                entryId: entryId,
                                              );
                                            });
                                          })
                                      : CustomFieldWidget(
                                          fieldName: field.fieldName,
                                          valueController: field.controller,
                                          type: field.type,
                                          isDirectory: false,
                                        );
                                }).toList();

                                return _withVerticalSpacing(customFieldWidgets, spacing: 8);
                              })(),

                              const SizedBox(height: 16),
                              _buildFileSelection(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}