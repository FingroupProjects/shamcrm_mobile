import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_withPriority.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/custom_widget/delete_file_dialog.dart' show DeleteFileDialog;
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_list_edit.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../page_2/warehouse/openings/cash_register/cash_register_content.dart';

class TaskEditScreen extends StatefulWidget {
  final int taskId;
  final String taskName;
  final String taskStatus;
  final int statusId;
  final String? project;
  final List<int>? user;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? description;
  final int? priority;
  final List<CustomFieldsById> taskCustomFields;
  final List<TaskFiles>? files;
  final List<DirectoryValues>? directoryValues;

  TaskEditScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.project,
    this.user,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.description,
    this.priority,
    this.files,
    required this.taskCustomFields,
    this.directoryValues,
  });

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedProject;
  List<String>? selectedUsers;
  int? selectedPriority;
  int? _selectedStatuses;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
  List<FileHelper> files = [];
  final ApiService _apiService = ApiService();
  List<TaskFiles> existingFiles = []; // Для отслеживания удаленных файлов с сервера
  bool _canUpdateTask = false;
  bool _hasTaskCreateForMySelfPermission = false;
  int? _currentUserId;

  // Конфигурация полей с сервера
  Map<String, Widget> fieldWidgets = {};
  List<String> fieldOrder = [];

  late MainFieldBloc _mainFieldBloc;

  // Режим настроек
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations; // Для отслеживания изменений
  final GlobalKey _addFieldButtonKey = GlobalKey();

  // Конфигурация полей с сервера
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initializeControllers();
    _loadInitialData();
    selectedPriority ??= 1;
    if (widget.files != null) {
      files = widget.files!.map((file) {
        return FileHelper(
          id: file.id,
          name: file.name,
          path: file.path,
          size: null, // TaskFiles не имеет поля size
        );
      }).toList();
      // Сохраняем оригинальные файлы для отслеживания удалений
      existingFiles = List.from(widget.files!);
    }

    // Загружаем конфигурацию полей
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
    _mainFieldBloc = MainFieldBloc();
  }

  @override
  void dispose() {
    _mainFieldBloc.close();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userID');
      final int? userId = userIdString != null ? int.tryParse(userIdString) : null;

      final results = await Future.wait([
        _apiService.hasPermission('task.update'),
        _apiService.hasPermission('task.createForMySelf'),
      ]);

      setState(() {
        _canUpdateTask = results[0];
        _hasTaskCreateForMySelfPermission = results[1];
        _currentUserId = userId;
      });

      //print('TaskEditScreen: Permissions - task.update: $_canUpdateTask, task.createForMySelf: $_hasTaskCreateForMySelfPermission, userID: $_currentUserId');
    } catch (e) {
      //print('TaskEditScreen: Error checking permissions or userID: $e');
      setState(() {
        _canUpdateTask = false;
        _hasTaskCreateForMySelfPermission = false;
        _currentUserId = null;
      });
    }
  }

  void _initializeControllers() {
    nameController.text = widget.taskName;
    _selectedStatuses = widget.statusId;
    if (widget.startDate != null) {
      DateTime parsedStartDate = DateTime.parse(widget.startDate!);
      startDateController.text = DateFormat('dd/MM/yyyy').format(parsedStartDate);
    }
    if (widget.endDate != null) {
      DateTime parsedEndDate = DateTime.parse(widget.endDate!);
      endDateController.text = DateFormat('dd/MM/yyyy').format(parsedEndDate);
    }
    descriptionController.text = widget.description ?? '';
    selectedProject = widget.project;

    if (!_canUpdateTask && _hasTaskCreateForMySelfPermission && _currentUserId != null) {
      selectedUsers = [_currentUserId.toString()];
    } else {
      selectedUsers = widget.user?.map((e) => e.toString()).toList() ?? [];
    }

    selectedPriority = widget.priority ?? 1;
  }

  void _loadInitialData() {
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
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
                          // НОВОЕ: Используем метод buildFileIcon для показа превью или иконки
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

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('TasksAddScreen: Loading field configuration for tasks');
    }
    context.read<FieldConfigurationBloc>().add(FetchFieldConfiguration('tasks'));
  }

  Future<void> _saveFieldOrderToBackend() async {
    try {
      // Подготовка данных для отправки
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

      // Отправка на бэкенд
      await _apiService.updateFieldPositions(
        tableName: 'tasks',
        updates: updates,
      );

      if (kDebugMode) {
        print('TaskAddScreen: Field positions saved to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TaskAddScreen: Error saving field positions: $e');
      }
      // Показываем ошибку пользователю
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
    final existingFieldIndex = customFields.indexWhere(
          (field) => field.fieldName == config.fieldName && field.isCustomField,
    );

    if (existingFieldIndex != -1) {
      // Поле уже существует - обновляем type из конфигурации, если он был null или пустым
      final existingField = customFields[existingFieldIndex];
      final configType = config.type;

      if (existingField.type == null ||
          existingField.type!.isEmpty ||
          (configType != null && configType.isNotEmpty && existingField.type != configType)) {
        customFields[existingFieldIndex] = existingField.copyWith(
          type: configType ?? 'string',
        );
        return customFields[existingFieldIndex];
      }
      return existingField;
    } else {
      // ✅ Only create new field if it doesn't exist
      // This happens when user adds a NEW custom field via UI
      final newField = CustomField(
        fieldName: config.fieldName,
        uniqueId: Uuid().v4(),
        controller: TextEditingController(), // Empty for new fields
        type: config.type ?? 'string',
        isCustomField: true,
      );
      customFields.add(newField);
      return newField;
    }
  }

  CustomField _getOrCreateDirectoryField(FieldConfiguration config) {
    // First, try to find existing field in customFields
    final existingField = customFields.firstWhere(
          (field) => field.directoryId == config.directoryId,
      orElse: () {
        // ✅ Only create new field if it doesn't exist
        // This happens when user adds a NEW directory field via UI
        final newField = CustomField(
          fieldName: config.fieldName,
          isDirectoryField: true,
          directoryId: config.directoryId,
          uniqueId: Uuid().v4(),
          controller: TextEditingController(), // Empty for new fields
        );
        customFields.add(newField);
        return newField;
      },
    );

    return existingField;
  }

  // Метод для построения стандартных системных полей
  Widget? _buildStandardField(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'name':
        return CustomTextFieldWithPriority(
          controller: nameController,
          hintText: AppLocalizations.of(context)!.translate('enter_title'),
          label: AppLocalizations.of(context)!.translate('event_name'),
          showPriority: true,
          isPrioritySelected: selectedPriority == 3,
          onPriorityChanged: (bool? value) {
            setState(() {
              selectedPriority = value == true ? 3 : 1;
            });
          },
          priorityText: AppLocalizations.of(context)!.translate('urgent'),
          validator: config.required ? (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.translate('field_required');
            }
            return null;
          } : null,
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
        if (_canUpdateTask) {
          return UserMultiSelectWidget(
            selectedUsers: selectedUsers,
            onSelectUsers: (List<UserData> selectedUsersData) {
              setState(() {
                selectedUsers = selectedUsersData.map((user) => user.id.toString()).toList();
              });
            },
          );
        } else {
          return SizedBox.shrink();
        }

      case 'project':
        return ProjectTaskGroupWidget(
          selectedProject: selectedProject,
          onSelectProject: (ProjectTask selectedProjectData) {
            setState(() {
              selectedProject = selectedProjectData.id.toString();
            });
          },
        );

      case 'deadline':
        return CustomTextFieldDate(
          controller: endDateController,
          label: AppLocalizations.of(context)!.translate('deadline'),
          hasError: isEndDateInvalid,
          validator: config.required ? (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.translate('field_required');
            }
            return null;
          } : null,
        );

      case 'task_status_id':
        return TaskStatusEditWidget(
          selectedStatus: _selectedStatuses?.toString(),
          onSelectStatus: (TaskStatus selectedStatusData) {
            setState(() {
              _selectedStatuses = selectedStatusData.id;
            });
          },
        );

    // case 'file':
    //   return _buildFileSelection();
      default:
        return null;
    }
  }

  // Метод для построения виджета на основе конфигурации поля
  Widget? _buildFieldWidget(FieldConfiguration config) {
    // Сначала проверяем, является ли это кастомным полем
    if (config.isCustomField) {
      final customField = _getOrCreateCustomField(config);

      return CustomFieldWidget(
        fieldName: config.fieldName,
        valueController: customField.controller,
        type: config.type,
        isDirectory: false,
      );
    }

    // Затем проверяем, является ли это справочником
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
              customFields[index] = directoryField.copyWith(
                entryId: entryId,
              );
            }
          });
        },
        initialEntryId: directoryField.entryId,
      );
    }

    // Иначе это стандартное системное поле
    return _buildStandardField(config);
  }

  List<Widget> _withVerticalSpacing(List<Widget> widgets, {double spacing = 15}) {
    if (widgets.isEmpty) {
      return widgets;
    }
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i != widgets.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }

  List<Widget> _buildConfiguredFieldWidgets() {
    final sorted = fieldConfigurations
        .where((e) => e.isActive)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final widgets = <Widget>[];
    for (final config in sorted) {
      final fieldWidget = _buildFieldWidget(config);
      if (fieldWidget != null) {
        widgets.add(fieldWidget);
      }
    }
    return _withVerticalSpacing(widgets, spacing: 8);
  }

  List<Widget> _buildDefaultTaskWidgets() {
    return _withVerticalSpacing([
      CustomTextFieldWithPriority(
        controller: nameController,
        hintText: AppLocalizations.of(context)!.translate('enter_title'),
        label: AppLocalizations.of(context)!.translate('event_name'),
        showPriority: true,
        isPrioritySelected: selectedPriority == 3,
        onPriorityChanged: (bool? value) {
          setState(() {
            selectedPriority = value == true ? 3 : 1;
          });
        },
        priorityText: AppLocalizations.of(context)!.translate('urgent'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.translate('field_required');
          }
          return null;
        },
      ),
      CustomTextField(
        controller: descriptionController,
        hintText: AppLocalizations.of(context)!.translate('enter_description'),
        label: AppLocalizations.of(context)!.translate('description_list'),
        maxLines: 5,
        keyboardType: TextInputType.multiline,
      ),
      if (!_hasTaskCreateForMySelfPermission)
        UserMultiSelectWidget(
          selectedUsers: selectedUsers,
          onSelectUsers: (List<UserData> selectedUsersData) {
            setState(() {
              selectedUsers = selectedUsersData.map((user) => user.id.toString()).toList();
            });
          },
        ),
      ProjectTaskGroupWidget(
        selectedProject: selectedProject,
        onSelectProject: (ProjectTask selectedProjectData) {
          setState(() {
            selectedProject = selectedProjectData.id.toString();
          });
        },
      ),
      CustomTextFieldDate(
        controller: endDateController,
        label: AppLocalizations.of(context)!.translate('deadline'),
        hasError: isEndDateInvalid,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.translate('field_required');
          }
          return null;
        },
      ),
    ], spacing: 8);
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

  Future<void> _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId, String? type}) async {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        showCustomSnackBar(context: context, message: 'Справочник уже добавлен', isSuccess: true);
        debugPrint("Directory with ID $directoryId already exists.");
        return;
      }
      try {
        await _apiService.linkDirectory(
          directoryId: directoryId,
          modelType: 'task',
          organizationId: _apiService.getSelectedOrganization().toString(),
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
            FetchFieldConfiguration('tasks'),
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
      await _apiService.addNewField(
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
      _showErrorSnackBar('Error adding field: $e');
    }
  }

  void _showAddFieldMenu() {
    final RenderBox? renderBox = _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
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

    // Если элементов 5 или больше, показываем над кнопкой, иначе под кнопкой
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

  // Проверка изменений в конфигурации полей
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

  // Диалог подтверждения выхода из режима настроек без сохранения
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

  bool _areFieldConfigurationsEqual(
      List<FieldConfiguration> first,
      List<FieldConfiguration> second,
      ) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      final a = first[i];
      final b = second[i];
      if (a.id != b.id ||
          a.position != b.position ||
          a.isActive != b.isActive ||
          a.required != b.required ||
          a.showOnTable != b.showOnTable ||
          a.fieldName != b.fieldName ||
          a.directoryId != b.directoryId ||
          a.type != b.type) {
        return false;
      }
    }
    return true;
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
                          Row(
                            children: [
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff99A4BA),
                                ),
                              ),
                              if (config.required) ...[
                                Spacer(),
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
                              ]
                            ],
                          ),
                          if (!config.required) ...[
                            SizedBox(height: 12),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  final updatedConfig = FieldConfiguration(
                                    id: config.id,
                                    tableName: config.tableName,
                                    fieldName: config.fieldName,
                                    position: config.position,
                                    required: config.required,
                                    isActive: !config.isActive,
                                    isCustomField: config.isCustomField,
                                    createdAt: config.createdAt,
                                    updatedAt: config.updatedAt,
                                    customFieldId: config.customFieldId,
                                    directoryId: config.directoryId,
                                    type: config.type,
                                    isDirectory: config.isDirectory,
                                    showOnTable: config.showOnTable,
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
                  print('LeadAddScreen: Error in save button: $e');
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

  // Получение типа поля для отображения
  String _getFieldTypeLabel(FieldConfiguration config) {
    if (config.isDirectory) {
      return AppLocalizations.of(context)!.translate('directory');
    } else if (config.isCustomField) {
      return AppLocalizations.of(context)!.translate('custom_field');
    } else {
      return AppLocalizations.of(context)!.translate('system_field');
    }
  }

  // Получение отображаемого названия поля
  String _getFieldDisplayName(FieldConfiguration config) {
    final loc = AppLocalizations.of(context)!;
    switch (config.fieldName) {
      case 'name':
        return loc.translate('event_name');
      case 'description':
        return loc.translate('description_list');
      case 'executor':
        return loc.translate('assignee2');
      case 'project':
        return loc.translate('projects');
      case 'deadline':
        return loc.translate('deadline');
      case 'task_status_id':
        return loc.translate('task_status');
    // case 'file':
    //   return loc.translate('file');
      default:
        return config.fieldName;
    }
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
      fileSizeTooLargeMessage: AppLocalizations.of(context)!.translate('file_size_too_large'),
      errorPickingFileMessage: AppLocalizations.of(context)!.translate('error_picking_file'),
    );

    // Если файлы выбраны, добавляем их
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          files.add(FileHelper(id: 0, name: file.name, path: file.path, size: file.sizeKB));
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
                    AppLocalizations.of(context)!.translate('error_delete_file'),
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

            Navigator.of(context).pop(true);
          },
          onCancel: () {
            Navigator.of(context).pop(false);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //print('TaskAddScreen: Building with selectedLead: $selectedLead, selectedManager: $selectedManager');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('task_edit'),
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
        // Добавляем кнопку обновления и настройки
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
          //     await _apiService.clearFieldConfigurationCache();
          //     await _apiService.loadAndCacheAllFieldConfigurations();
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
      body: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
          listenWhen: (previous, current) {
            if (previous is FieldConfigurationLoaded && current is FieldConfigurationLoaded) {
              return !_areFieldConfigurationsEqual(previous.fields, current.fields);
            }
            return true;
          },
          listener: (context, configState) {
            if (configState is FieldConfigurationLoaded) {
              if (kDebugMode) {
                print('Task: Configuration loaded with ${configState.fields.length} fields');
              }

              setState(() {
                fieldConfigurations = configState.fields;
                isConfigurationLoaded = true;

                // ✅ ONLY initialize custom fields here, ONCE
                // Check if already initialized to prevent duplicates
                if (customFields.isEmpty) {
                  // Initialize custom fields from widget data
                  for (var customField in widget.taskCustomFields) {
                    // Ищем соответствующую конфигурацию поля
                    final matchingConfig = fieldConfigurations.where(
                          (config) => config.isCustomField && config.fieldName == customField.name,
                    ).firstOrNull;

                    // Используем type из конфигурации, если type из виджета пустой
                    final fieldType = (customField.type.isEmpty && matchingConfig?.type != null)
                        ? matchingConfig!.type
                        : (customField.type.isNotEmpty ? customField.type : null);

                    final controller = TextEditingController(text: customField.value);
                    customFields.add(CustomField(
                      fieldName: customField.name,
                      controller: controller,
                      uniqueId: Uuid().v4(),
                      type: fieldType,
                      isCustomField: true,
                    ));
                  }

                  // Initialize directory values from widget data
                  if (widget.directoryValues != null && widget.directoryValues!.isNotEmpty) {
                    final seen = <String>{};
                    final uniqueDirectoryValues = widget.directoryValues!.where((dirValue) {
                      final key = '${dirValue.entry.directory.id}_${dirValue.entry.id}';
                      return seen.add(key);
                    }).toList();

                    for (var dirValue in uniqueDirectoryValues) {
                      // Check if already exists to prevent duplicates
                      final exists = customFields.any((f) =>
                      f.isDirectoryField &&
                          f.directoryId == dirValue.entry.directory.id
                      );

                      if (!exists) {
                        final controller = TextEditingController(
                          text: (dirValue.entry.values.isNotEmpty
                              ? dirValue.entry.values.first.value
                              : ''),
                        );
                        customFields.add(CustomField(
                          fieldName: dirValue.entry.directory.name,
                          controller: controller,
                          isDirectoryField: true,
                          directoryId: dirValue.entry.directory.id,
                          entryId: dirValue.entry.id,
                          uniqueId: Uuid().v4(),
                        ));
                      }
                    }
                  }
                }
              });
            } else if (configState is FieldConfigurationError) {
              if (kDebugMode) {
                print('Task: Configuration error: ${configState.message}');
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
          buildWhen: (previous, current) {
            if (previous is FieldConfigurationLoaded && current is FieldConfigurationLoaded) {
              return !_areFieldConfigurationsEqual(previous.fields, current.fields);
            }
            return previous.runtimeType != current.runtimeType;
          },
          builder: (context, configState) {
            if (kDebugMode) {
              print('TaskAddScreen: Building with state: ${configState.runtimeType}, isLoaded: $isConfigurationLoaded');
            }

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

            return BlocProvider.value(
              value: _mainFieldBloc,
              child: BlocListener<TaskBloc, TaskState>(
                listener: (context, state) {
                  if (state is TaskError) {
                    showCustomSnackBar(
                      context: context,
                      message: AppLocalizations.of(context)!.translate(state.message),
                      isSuccess: false,
                    );
                  } else if (state is TaskSuccess) {
                    showCustomSnackBar(
                      context: context,
                      message: AppLocalizations.of(context)!.translate(state.message),
                      isSuccess: true,
                    );
                    if (context.mounted) {
                      Navigator.pop(context, true);
                      context.read<TaskBloc>().add(FetchTaskStatuses());
                    }
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
                                ...(() {
                                  final configured = _buildConfiguredFieldWidgets();
                                  if (configured.isNotEmpty) {
                                    return configured;
                                  }
                                  return _buildDefaultTaskWidgets();
                                })(),

                                // Отступ между сконфигурированными и пользовательскими полями
                                if (customFields.where((field) {
                                  return !fieldConfigurations.any((config) =>
                                  (config.isCustomField && config.fieldName == field.fieldName) ||
                                      (config.isDirectory && config.directoryId == field.directoryId));
                                }).isNotEmpty)
                                  const SizedBox(height: 16),

                                // ТОЛЬКО пользовательские поля (те, которые добавлены через кнопку "Добавить поле")
                                ...(() {
                                  final customFieldsList = customFields.where((field) {
                                    // Исключаем поля, которые уже есть в серверной конфигурации
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
                                      selectedField: field.entryId != null
                                          ? MainField(id: field.entryId!, value: field.controller.text)
                                          : null,
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
                                      },
                                      initialEntryId: field.entryId,
                                    )
                                        : CustomFieldWidget(
                                      fieldName: field.fieldName,
                                      valueController: field.controller,
                                      type: field.type,
                                      isDirectory: false,
                                    );
                                  }).toList();

                                  return _withVerticalSpacing(customFieldWidgets, spacing: 8);
                                })(),

                                // Всегда показываем выбор файлов внизу
                                const SizedBox(height: 16),
                                _buildFileSelection(),
                                const SizedBox(height: 80), // Отступ внизу для кнопок
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
          }),
    );
  }

  _buildActionButtons(BuildContext context) {
    return  Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              buttonText:
              AppLocalizations.of(context)!.translate('cancel'),
              buttonColor: const Color(0xffF4F7FD),
              textColor: Colors.black,
              onPressed: () => Navigator.pop(context, null),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff1E2E52),
                    ),
                  );
                } else {
                  return CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('save'),
                    buttonColor: const Color(0xff4759FF),
                    textColor: Colors.white,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        DateTime? startDate;
                        DateTime? endDate;
                        try {
                          if (startDateController.text.isNotEmpty) {
                            startDate = DateFormat('dd/MM/yyyy')
                                .parseStrict(
                                startDateController.text);
                          }
                          if (endDateController.text.isNotEmpty) {
                            endDate = DateFormat('dd/MM/yyyy')
                                .parseStrict(
                                endDateController.text);
                          }
                          if (startDate != null &&
                              endDate != null &&
                              startDate.isAfter(endDate)) {
                            setState(() {
                              isEndDateInvalid = true;
                            });
                            _showErrorSnackBar(
                              AppLocalizations.of(context)!
                                  .translate(
                                  'start_date_after_end_date'),
                            );
                            return;
                          }

                          List<Map<String, dynamic>> customFieldList = [];
                          List<Map<String, int>> directoryValues = [];

                          for (var field in customFields) {
                            String fieldName = field.fieldName.trim();
                            String fieldValue = field.controller.text.trim();
                            String? fieldType = field.type;

                            // Если type null или пустая строка, устанавливаем string по умолчанию
                            // НО сохраняем 'text' как 'text', не преобразуем в 'string'
                            if (fieldType == null || fieldType.isEmpty) {
                              fieldType = 'string';
                            }

                            if (fieldType == 'number' &&
                                fieldValue.isNotEmpty) {
                              if (!RegExp(r'^\d+$')
                                  .hasMatch(fieldValue)) {
                                _showErrorSnackBar(
                                    AppLocalizations.of(context)!
                                        .translate(
                                        'enter_valid_number'));
                                return;
                              }
                            }

                            if ((fieldType == 'date' ||
                                fieldType == 'datetime') &&
                                fieldValue.isNotEmpty) {
                              try {
                                if (fieldType == 'date') {
                                  DateFormat('dd/MM/yyyy')
                                      .parse(fieldValue);
                                } else {
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .parse(fieldValue);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!
                                          .translate(
                                          'enter_valid_${fieldType}'),
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

                            if (field.isDirectoryField &&
                                field.directoryId != null &&
                                field.entryId != null) {
                              directoryValues.add({
                                'directory_id': field.directoryId!,
                                'entry_id': field.entryId!,
                              });
                            } else if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
                              customFieldList.add({
                                'key': fieldName,
                                'value': fieldValue,
                                'type': fieldType,
                              });
                            }
                          }

                          // Преобразуем files в filePaths и existingFiles
                          // Новые файлы (id == 0)
                          final newFilePaths = files
                              .where((f) => f.id == 0)
                              .map((f) => f.path)
                              .toList();

                          // Существующие файлы (id != 0, которые не были удалены)
                          final keptExistingFiles = files
                              .where((f) => f.id != 0)
                              .map((f) {
                            // Находим соответствующий TaskFiles объект из оригинального списка
                            return existingFiles.firstWhere(
                                  (ef) => ef.id == f.id,
                              orElse: () => TaskFiles(
                                id: f.id,
                                name: f.name,
                                path: f.path,
                              ),
                            );
                          })
                              .toList();

                          final localizations =
                          AppLocalizations.of(context)!;

                          context.read<TaskBloc>().add(
                            UpdateTask(
                              taskId: widget.taskId,
                              name: nameController.text,
                              statusId:
                              _selectedStatuses!.toInt(),
                              taskStatusId:
                              _selectedStatuses!.toInt(),
                              startDate: startDate,
                              endDate: endDate,
                              projectId: selectedProject != null
                                  ? int.parse(selectedProject!)
                                  : null,
                              userId: selectedUsers != null
                                  ? selectedUsers!
                                  .map(
                                      (id) => int.parse(id))
                                  .toList()
                                  : null,
                              priority:
                              selectedPriority?.toString(),
                              description:
                              descriptionController.text,
                              customFields: customFieldList,
                              filePaths: newFilePaths.isNotEmpty ? newFilePaths : null,
                              directoryValues: directoryValues,
                              localizations: localizations,
                              existingFiles: keptExistingFiles.isNotEmpty ? keptExistingFiles : null,
                            ),
                          );
                        } catch (e) {
                          _showErrorSnackBar(
                            AppLocalizations.of(context)!
                                .translate('error_format_date'),
                          );
                        }
                      } else {
                        _showErrorSnackBar(
                          AppLocalizations.of(context)!
                              .translate('fill_required_fields'),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
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
  final String uniqueId;
  final String? type;

  CustomField({
    required this.fieldName,
    TextEditingController? controller,
    this.isDirectoryField = false,
    this.isCustomField = false,
    this.directoryId,
    this.entryId,
    required this.uniqueId,
    this.type,
  }) : controller = controller ?? TextEditingController();

  CustomField copyWith({
    String? fieldName,
    TextEditingController? controller,
    bool? isDirectoryField,
    bool? isCustomField,
    int? directoryId,
    int? entryId,
    String? uniqueId,
    String? type,
  }) {
    return CustomField(
      fieldName: fieldName ?? this.fieldName,
      controller: controller ?? this.controller,
      isDirectoryField: isDirectoryField ?? this.isDirectoryField,
      isCustomField: isCustomField ?? this.isCustomField,
      directoryId: directoryId ?? this.directoryId,
      entryId: entryId ?? this.entryId,
      uniqueId: uniqueId ?? this.uniqueId,
      type: type ?? this.type,
    );
  }
}