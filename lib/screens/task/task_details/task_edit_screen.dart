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
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/delete_file_dialog.dart'
    show DeleteFileDialog;
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';
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

  bool isExecutorInvalid = false;
  bool isProjectInvalid = false;
  List<FileHelper> files = [];
  final ApiService _apiService = ApiService();
  List<TaskFiles> existingFiles = [];
  bool _canUpdateTask = false;
  bool _hasTaskCreateForMySelfPermission = false;
  int? _currentUserId;
  bool _askReasonForRefusal = false;
  TaskStatus? _selectedTaskStatusData;
  bool _isSubmittingSave = false;

  Map<String, Widget> fieldWidgets = {};
  List<String> fieldOrder = [];

  late MainFieldBloc _mainFieldBloc;

  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations;
  final GlobalKey _addFieldButtonKey = GlobalKey();

  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initializeControllers();
    _loadInitialData();
    _loadAskReasonForRefusal();
    selectedPriority ??= 1;
    if (widget.files != null) {
      files = widget.files!.map((file) {
        return FileHelper(
          id: file.id,
          name: file.name,
          path: file.path,
          size: null,
        );
      }).toList();
      existingFiles = List.from(widget.files!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
    _mainFieldBloc = MainFieldBloc();
  }

  @override
  void dispose() {
    _mainFieldBloc.close();
    nameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userID');
      final int? userId =
          userIdString != null ? int.tryParse(userIdString) : null;

      final results = await Future.wait([
        _apiService.hasPermission('task.update'),
        _apiService.hasPermission('task.createForMySelf'),
      ]);

      setState(() {
        _canUpdateTask = results[0];
        _hasTaskCreateForMySelfPermission = results[1];
        _currentUserId = userId;
      });
    } catch (e) {
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
      startDateController.text =
          DateFormat('dd/MM/yyyy').format(parsedStartDate);
    }
    if (widget.endDate != null) {
      DateTime parsedEndDate = DateTime.parse(widget.endDate!);
      endDateController.text = DateFormat('dd/MM/yyyy').format(parsedEndDate);
    }
    descriptionController.text = widget.description ?? '';
    selectedProject = widget.project;

    if (!_canUpdateTask &&
        _hasTaskCreateForMySelfPermission &&
        _currentUserId != null) {
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

  Future<void> _loadAskReasonForRefusal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _askReasonForRefusal = prefs.getBool('ask_reason_for_refusal') ?? false;
    });
  }

  Future<TaskStatus?> _resolveSelectedTaskStatusData() async {
    if (_selectedStatuses == null) return null;
    if (_selectedTaskStatusData?.id == _selectedStatuses) {
      return _selectedTaskStatusData;
    }
    try {
      final status = await _apiService.getTaskStatus(_selectedStatuses!);
      if (!mounted) return status;
      setState(() {
        _selectedTaskStatusData = status;
      });
      return status;
    } catch (_) {
      return _selectedTaskStatusData;
    }
  }

  Future<ReasonForRefusalSubmitData?> _collectReasonForRefusalIfNeeded() async {
    final bool statusChanged =
        _selectedStatuses != null && _selectedStatuses != widget.statusId;
    final targetStatus = await _resolveSelectedTaskStatusData();
    final bool requiresReason =
        _askReasonForRefusal && targetStatus?.isUnassembled == true;

    if (!statusChanged || !requiresReason) {
      return null;
    }

    return showReasonForRefusalDialog(
      context: context,
      type: 'task',
    );
  }

  Future<void> _loadFieldConfiguration() async {
    context
        .read<FieldConfigurationBloc>()
        .add(FetchFieldConfiguration('tasks'));
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

      await _apiService.updateFieldPositions(
        tableName: 'tasks',
        updates: updates,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка сохранения настроек полей',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.appColors.textInverse,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: context.appColors.error,
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
      final existingField = customFields[existingFieldIndex];
      final configType = config.type;

      if (existingField.type == null ||
          existingField.type!.isEmpty ||
          (configType != null &&
              configType.isNotEmpty &&
              existingField.type != configType)) {
        customFields[existingFieldIndex] = existingField.copyWith(
          type: configType ?? 'string',
        );
        return customFields[existingFieldIndex];
      }
      return existingField;
    } else {
      final newField = CustomField(
        fieldName: config.fieldName,
        uniqueId: Uuid().v4(),
        controller: TextEditingController(),
        type: config.type ?? 'string',
        isCustomField: true,
      );
      customFields.add(newField);
      return newField;
    }
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

  Widget? _buildStandardField(FieldConfiguration config) {
    final colors = context.appColors;

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
        );

      case 'description':
        return CustomTextField(
          controller: descriptionController,
          hintText:
              AppLocalizations.of(context)!.translate('enter_description'),
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
                selectedUsers = selectedUsersData
                    .map((user) => user.id.toString())
                    .toList();
                isExecutorInvalid = false;
              });
            },
            hasError: isExecutorInvalid,
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
              isProjectInvalid = false;
            });
          },
          errorText: isProjectInvalid
              ? AppLocalizations.of(context)!.translate('field_required')
              : null,
        );

      case 'deadline':
        return CustomTextFieldDate(
          controller: endDateController,
          label: AppLocalizations.of(context)!.translate('deadline'),
          hasError: isEndDateInvalid,
        );

      case 'task_status_id':
        return TaskStatusEditWidget(
          selectedStatus: _selectedStatuses?.toString(),
          onSelectStatus: (TaskStatus selectedStatusData) {
            setState(() {
              _selectedStatuses = selectedStatusData.id;
              _selectedTaskStatusData = selectedStatusData;
            });
          },
        );

      default:
        return null;
    }
  }

  Widget? _buildFieldWidget(FieldConfiguration config) {
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
        onSelectField: (MainField selectedField) {
          setState(() {
            final index = customFields
                .indexWhere((f) => f.directoryId == config.directoryId);
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
            final index = customFields
                .indexWhere((f) => f.directoryId == config.directoryId);
            if (index != -1) {
              customFields[index] = directoryField.copyWith(entryId: entryId);
            }
          });
        },
        initialEntryId: directoryField.entryId,
      );
    }

    return _buildStandardField(config);
  }

  List<Widget> _withVerticalSpacing(List<Widget> widgets,
      {double spacing = 16}) {
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

  List<Widget> _buildConfiguredFieldWidgets() {
    final sorted = fieldConfigurations
        .where((config) => config.isActive)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final widgets = <Widget>[];
    for (final config in sorted) {
      final fieldWidget = _buildFieldWidget(config);
      if (fieldWidget != null) {
        widgets.add(fieldWidget);
      }
    }
    return widgets;
  }

  List<Widget> _buildDefaultTaskWidgets() {
    return [
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
      SizedBox(height: 16),
      CustomTextField(
        controller: descriptionController,
        hintText: AppLocalizations.of(context)!.translate('enter_description'),
        label: AppLocalizations.of(context)!.translate('description_list'),
        maxLines: 5,
        keyboardType: TextInputType.multiline,
      ),
      SizedBox(height: 16),
      if (!_hasTaskCreateForMySelfPermission) ...[
        UserMultiSelectWidget(
          selectedUsers: selectedUsers,
          onSelectUsers: (List<UserData> selectedUsersData) {
            setState(() {
              selectedUsers =
                  selectedUsersData.map((user) => user.id.toString()).toList();
              isExecutorInvalid = false;
            });
          },
          hasError: isExecutorInvalid,
        ),
        SizedBox(height: 16),
      ],
      ProjectTaskGroupWidget(
        selectedProject: selectedProject,
        onSelectProject: (ProjectTask selectedProjectData) {
          setState(() {
            selectedProject = selectedProjectData.id.toString();
            isProjectInvalid = false;
          });
        },
        errorText: isProjectInvalid
            ? AppLocalizations.of(context)!.translate('field_required')
            : null,
      ),
      SizedBox(height: 16),
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
    ];
  }

  void _showErrorSnackBar(String message) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: textStyles.bodyMd.copyWith(color: colors.textInverse),
        ),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _addCustomField(String fieldName,
      {bool isDirectory = false, int? directoryId, String? type}) async {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) =>
          field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        showCustomSnackBar(
            context: context,
            message: 'Справочник уже добавлен',
            isSuccess: true);
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
          context.read<FieldConfigurationBloc>().add(
                FetchFieldConfiguration('tasks'),
              );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Справочник успешно добавлен',
                style: context.appTextStyles.bodyMd
                    .copyWith(color: context.appColors.textInverse),
              ),
              backgroundColor: context.appColors.success,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
      return;
    }

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
    final colors = context.appColors;
    final RenderBox? renderBox =
        _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
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
            color: colors.textPrimary,
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
            color: colors.textPrimary,
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
        showAbove
            ? MediaQuery.of(context).size.height - offset.dy + verticalOffset
            : MediaQuery.of(context).size.height -
                offset.dy -
                size.height -
                8,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: colors.surfacePrimary,
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
    final colors = context.appColors;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: colors.surfacePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.borderPrimary),
              ),
              title: Text(
                AppLocalizations.of(context)!.translate('warning'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              content: Text(
                AppLocalizations.of(context)!
                    .translate('position_changes_will_not_be_saved'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
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
                        buttonColor: colors.buttonSecondaryBg,
                        textColor: colors.buttonSecondaryFg,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        buttonText: AppLocalizations.of(context)!
                            .translate('dont_save'),
                        onPressed: () => Navigator.of(context).pop(true),
                        buttonColor: colors.error,
                        textColor: colors.buttonPrimaryFg,
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
    final colors = context.appColors;
    final sortedFields = [...fieldConfigurations]
      ..sort((a, b) => a.position.compareTo(b.position));

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                      shadowColor: colors.shadow.withOpacity(0.28),
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
              if (oldIndex == sortedFields.length ||
                  newIndex == sortedFields.length + 1) return;
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                if (newIndex >= sortedFields.length)
                  newIndex = sortedFields.length - 1;
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
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('add_field'),
                    buttonColor: colors.surfaceElevated,
                    textColor: colors.textPrimary,
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
                  color: colors.surfaceElevated.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderPrimary, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.12),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.drag_handle,
                        color: colors.textSecondary, size: 24),
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
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (config.fieldName != 'name' &&
                              config.fieldName != 'description' &&
                              config.fieldName != 'executor' &&
                              config.fieldName != 'project' &&
                              config.fieldName != 'deadline' &&
                              config.fieldName != 'task_status_id')
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
                                            ? colors.buttonPrimaryBg
                                            : colors.fieldBackground,
                                        border: Border.all(
                                          color: config.isActive
                                              ? colors.buttonPrimaryBg
                                              : colors.borderPrimary,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: AnimatedOpacity(
                                        duration: Duration(milliseconds: 200),
                                        opacity: config.isActive ? 1.0 : 0.0,
                                        child: Icon(Icons.check_rounded,
                                            size: 16,
                                            color: colors.buttonPrimaryFg),
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
                                            ? colors.textPrimary
                                            : colors.textSecondary,
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
        // Settings footer
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withOpacity(0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.borderPrimary),
          ),
          child: isSavingFieldOrder
              ? Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: colors.buttonPrimaryBg.withOpacity(0.7),
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
                                colors.buttonPrimaryFg),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.translate('saving'),
                          style: TextStyle(
                            color: colors.buttonPrimaryFg,
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
                  buttonColor: colors.buttonPrimaryBg,
                  textColor: colors.buttonPrimaryFg,
                  onPressed: () async {
                    setState(() => isSavingFieldOrder = true);
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
                                color: context.appColors.textInverse,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: context.appColors.success,
                            elevation: 3,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) print('TaskEditScreen: Error saving: $e');
                    } finally {
                      if (mounted) setState(() => isSavingFieldOrder = false);
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFileSelection() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('file'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.fieldBackground.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.borderPrimary),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            ThemeData.estimateBrightnessForColor(
                                      colors.fieldBackground.withOpacity(0.92),
                                    ) ==
                                    Brightness.dark
                                ? 'assets/icons/files/add_for_dark.png'
                                : 'assets/icons/files/add.png',
                            width: 54,
                            height: 54,
                          ),
                          SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('add_file'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                color: colors.textSecondary,
                              ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.fieldBackground.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.borderPrimary),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Center(
                              child:
                                  buildFileIcon(files, fileName, fileExtension),
                            ),
                          ),
                          SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              fileName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                color: colors.textPrimary,
                              ),
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
                          showDeleteFileDialog(
                            fileId: files[index].id,
                            index: index,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.surfacePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.close,
                              size: 16, color: colors.textPrimary),
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

  Future<void> _pickFile() async {
    double totalSize = files.fold<double>(0.0, (sum, file) {
      if (file.path.startsWith('http://') ||
          file.path.startsWith('https://')) {
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

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
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
              setState(() => files.removeAt(index));
              Navigator.of(context).pop(true);
              return;
            }

            isDeleting = true;
            setState(() {});

            final response = await _apiService.deleteTaskFile(fileId);
            if (response['result'] == 'Success') {
              setState(() => files.removeAt(index));
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
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  void _handleSettingsToggle() async {
    if (isSettingsMode) {
      if (_hasFieldChanges()) {
        final shouldExit = await _showExitSettingsDialog();
        if (!shouldExit) return;

        if (originalFieldConfigurations != null) {
          setState(() {
            final newFields = fieldConfigurations.where((current) {
              return !originalFieldConfigurations!
                  .any((original) => original.id == current.id);
            }).toList();

            fieldConfigurations = [...originalFieldConfigurations!];

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
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final appBarGradient = [
      colors.surfaceElevated,
      colors.fieldBackground,
    ];
    final subtleBorder = colors.borderPrimary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: !isSettingsMode,
      // ── AppBar styled like LeadEditScreen ──────────────────────────────
      appBar: AppBar(
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
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
                color: colors.textPrimary,
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
                AppLocalizations.of(context)!.translate('task_edit'),
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
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
                isSettingsMode ? Icons.close_rounded : Icons.settings_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
              onPressed: _handleSettingsToggle,
              tooltip: isSettingsMode
                  ? AppLocalizations.of(context)!.translate('close')
                  : AppLocalizations.of(context)!.translate('appbar_settings'),
            ),
          ),
        ),
        centerTitle: false,
      ),
      // ── Body ──────────────────────────────────────────────────────────
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(
            preset: AppBackgroundPreset.aurora,
          ),
          BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
            listenWhen: (previous, current) {
              if (previous is FieldConfigurationLoaded &&
                  current is FieldConfigurationLoaded) {
                return !_areFieldConfigurationsEqual(
                    previous.fields, current.fields);
              }
              return true;
            },
            listener: (context, configState) {
              if (configState is FieldConfigurationLoaded) {
                setState(() {
                  fieldConfigurations = configState.fields;
                  isConfigurationLoaded = true;

                  if (customFields.isEmpty) {
                    for (var customField in widget.taskCustomFields) {
                      final matchingConfig = fieldConfigurations
                          .where(
                            (config) =>
                                config.isCustomField &&
                                config.fieldName == customField.name,
                          )
                          .firstOrNull;

                      final fieldType = (customField.type.isEmpty &&
                              matchingConfig?.type != null)
                          ? matchingConfig!.type
                          : (customField.type.isNotEmpty
                              ? customField.type
                              : null);

                      final controller =
                          TextEditingController(text: customField.value);
                      customFields.add(CustomField(
                        fieldName: customField.name,
                        controller: controller,
                        uniqueId: Uuid().v4(),
                        type: fieldType,
                        isCustomField: true,
                      ));
                    }

                    if (widget.directoryValues != null &&
                        widget.directoryValues!.isNotEmpty) {
                      final seen = <String>{};
                      final uniqueDirectoryValues =
                          widget.directoryValues!.where((dirValue) {
                        final key =
                            '${dirValue.entry.directory.id}_${dirValue.entry.id}';
                        return seen.add(key);
                      }).toList();

                      for (var dirValue in uniqueDirectoryValues) {
                        final exists = customFields.any((f) =>
                            f.isDirectoryField &&
                            f.directoryId == dirValue.entry.directory.id);
                        if (!exists) {
                          final controller = TextEditingController(
                            text: dirValue.entry.values.isNotEmpty
                                ? dirValue.entry.values.first.value
                                : '',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ошибка загрузки конфигурации: ${configState.message}',
                      style: context.appTextStyles.bodyMd
                          .copyWith(color: context.appColors.textInverse),
                    ),
                    backgroundColor: context.appColors.error,
                  ),
                );
              }
            },
            buildWhen: (previous, current) {
              if (previous is FieldConfigurationLoaded &&
                  current is FieldConfigurationLoaded) {
                return !_areFieldConfigurationsEqual(
                    previous.fields, current.fields);
              }
              return previous.runtimeType != current.runtimeType;
            },
            builder: (context, configState) {
              if (configState is FieldConfigurationLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: colors.buttonPrimaryBg,
                  ),
                );
              }

              if (!isConfigurationLoaded) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          color: colors.buttonPrimaryBg),
                      SizedBox(height: 16),
                      Text(
                        'Загрузка конфигурации...',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontFamily: 'Gilroy',
                        ),
                      ),
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
                        message: AppLocalizations.of(context)!
                            .translate(state.message),
                        isSuccess: false,
                      );
                    } else if (state is TaskSuccess) {
                      showCustomSnackBar(
                        context: context,
                        message: AppLocalizations.of(context)!
                            .translate(state.message),
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
                        // Top safe-area spacer (like LeadEditScreen)
                        SizedBox(
                          height: MediaQuery.of(context).padding.top + 10,
                        ),
                        // ── Scrollable form in a card ──────────────────
                        Expanded(
                          child: GestureDetector(
                            onTap: () => FocusScope.of(context).unfocus(),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                    18, 18, 18, 22),
                                decoration: BoxDecoration(
                                  color: colors.surfacePrimary
                                      .withOpacity(0.84),
                                  borderRadius: BorderRadius.circular(30),
                                  border:
                                      Border.all(color: colors.borderPrimary),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colors.shadow.withOpacity(0.14),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Configured fields from server
                                    ...(() {
                                      final configured =
                                          _buildConfiguredFieldWidgets();
                                      if (configured.isNotEmpty) {
                                        final spaced = <Widget>[];
                                        for (int i = 0;
                                            i < configured.length;
                                            i++) {
                                          spaced.add(configured[i]);
                                          if (i !=
                                              configured.length - 1) {
                                            spaced.add(
                                                const SizedBox(height: 16));
                                          }
                                        }
                                        return spaced;
                                      }
                                      return _buildDefaultTaskWidgets();
                                    })(),

                                    // Extra custom fields not in server config
                                    ...(() {
                                      final extraFields =
                                          customFields.where((field) {
                                        return !fieldConfigurations.any(
                                            (config) =>
                                                (config.isCustomField &&
                                                    config.fieldName ==
                                                        field.fieldName) ||
                                                (config.isDirectory &&
                                                    config.directoryId ==
                                                        field.directoryId));
                                      }).toList();

                                      if (extraFields.isEmpty)
                                        return <Widget>[];

                                      final extraWidgets =
                                          extraFields.map((field) {
                                        return field.isDirectoryField &&
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
                                                onSelectField: (MainField
                                                    selectedField) {
                                                  setState(() {
                                                    final idx = customFields
                                                        .indexOf(field);
                                                    customFields[idx] =
                                                        field.copyWith(
                                                      entryId:
                                                          selectedField.id,
                                                      controller:
                                                          TextEditingController(
                                                              text:
                                                                  selectedField
                                                                      .value),
                                                    );
                                                  });
                                                },
                                                controller: field.controller,
                                                onSelectEntryId:
                                                    (int entryId) {
                                                  setState(() {
                                                    final idx = customFields
                                                        .indexOf(field);
                                                    customFields[idx] =
                                                        field.copyWith(
                                                            entryId: entryId);
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
                                                isDirectory: false,
                                              );
                                      }).toList();

                                      final result = <Widget>[
                                        const SizedBox(height: 16)
                                      ];
                                      for (int i = 0;
                                          i < extraWidgets.length;
                                          i++) {
                                        result.add(extraWidgets[i]);
                                        if (i != extraWidgets.length - 1) {
                                          result.add(
                                              const SizedBox(height: 16));
                                        }
                                      }
                                      return result;
                                    })(),

                                    // File picker always at bottom
                                    const SizedBox(height: 16),
                                    _buildFileSelection(),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // ── Footer action buttons (floating rounded) ───
                        _buildActionButtons(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              buttonText: AppLocalizations.of(context)!.translate('cancel'),
              buttonColor: colors.buttonSecondaryBg,
              textColor: colors.buttonSecondaryFg,
              onPressed: () => Navigator.pop(context, null),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading || _isSubmittingSave) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.buttonPrimaryBg,
                    ),
                  );
                }
                return CustomButton(
                  buttonText:
                      AppLocalizations.of(context)!.translate('save'),
                  buttonColor: colors.buttonPrimaryBg,
                  textColor: colors.buttonPrimaryFg,
                  onPressed: () async {
                    if (_isSubmittingSave) return;
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isSubmittingSave = true);
                      DateTime? startDate;
                      DateTime? endDate;
                      try {
                        if (startDateController.text.isNotEmpty) {
                          startDate = DateFormat('dd/MM/yyyy')
                              .parseStrict(startDateController.text);
                        }
                        if (endDateController.text.isNotEmpty) {
                          endDate = DateFormat('dd/MM/yyyy')
                              .parseStrict(endDateController.text);
                        }
                        if (startDate != null &&
                            endDate != null &&
                            startDate.isAfter(endDate)) {
                          setState(() {
                            isEndDateInvalid = true;
                            _isSubmittingSave = false;
                          });
                          _showErrorSnackBar(
                            AppLocalizations.of(context)!
                                .translate('start_date_after_end_date'),
                          );
                          return;
                        }

                        if (!_hasTaskCreateForMySelfPermission &&
                            (selectedUsers == null ||
                                selectedUsers!.isEmpty)) {
                          setState(() {
                            isExecutorInvalid = true;
                            _isSubmittingSave = false;
                          });
                          _showErrorSnackBar(
                            '${AppLocalizations.of(context)!.translate('assignees_list')} - ${AppLocalizations.of(context)!.translate('field_required')}',
                          );
                          return;
                        }

                        if (selectedProject == null ||
                            selectedProject!.isEmpty) {
                          setState(() {
                            isProjectInvalid = true;
                            _isSubmittingSave = false;
                          });
                          _showErrorSnackBar(
                            '${AppLocalizations.of(context)!.translate('project')} - ${AppLocalizations.of(context)!.translate('field_required')}',
                          );
                          return;
                        }

                        List<Map<String, dynamic>> customFieldList = [];
                        List<Map<String, int>> directoryValues = [];

                        for (var field in customFields) {
                          String fieldName = field.fieldName.trim();
                          String fieldValue =
                              field.controller.text.trim();
                          String? fieldType = field.type;

                          if (fieldType == null || fieldType.isEmpty) {
                            fieldType = 'string';
                          }

                          if (fieldType == 'number' &&
                              fieldValue.isNotEmpty) {
                            if (!RegExp(r'^\d+$').hasMatch(fieldValue)) {
                              setState(() => _isSubmittingSave = false);
                              _showErrorSnackBar(
                                  AppLocalizations.of(context)!
                                      .translate('enter_valid_number'));
                              return;
                            }
                          }

                          if ((fieldType == 'date' ||
                                  fieldType == 'datetime') &&
                              fieldValue.isNotEmpty) {
                            try {
                              if (fieldType == 'date') {
                                DateFormat('dd/MM/yyyy').parse(fieldValue);
                              } else {
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .parse(fieldValue);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.translate(
                                        'enter_valid_${fieldType}'),
                                    style: context.appTextStyles.bodyMd
                                        .copyWith(
                                            color:
                                                context.appColors.textInverse),
                                  ),
                                  backgroundColor: context.appColors.error,
                                ),
                              );
                              setState(() => _isSubmittingSave = false);
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
                          } else if (fieldName.isNotEmpty &&
                              fieldValue.isNotEmpty) {
                            customFieldList.add({
                              'key': fieldName,
                              'value': fieldValue,
                              'type': fieldType,
                            });
                          }
                        }

                        final newFilePaths = files
                            .where((f) => f.id == 0)
                            .map((f) => f.path)
                            .toList();

                        final keptExistingFiles =
                            files.where((f) => f.id != 0).map((f) {
                          return existingFiles.firstWhere(
                            (ef) => ef.id == f.id,
                            orElse: () => TaskFiles(
                              id: f.id,
                              name: f.name,
                              path: f.path,
                            ),
                          );
                        }).toList();

                        final localizations =
                            AppLocalizations.of(context)!;
                        final refusalData =
                            await _collectReasonForRefusalIfNeeded();

                        if (!mounted) return;
                        if (_selectedStatuses != widget.statusId &&
                            _askReasonForRefusal &&
                            (await _resolveSelectedTaskStatusData())
                                    ?.isUnassembled ==
                                true &&
                            refusalData == null) {
                          setState(() => _isSubmittingSave = false);
                          return;
                        }

                        context.read<TaskBloc>().add(
                              UpdateTask(
                                taskId: widget.taskId,
                                name: nameController.text,
                                statusId: _selectedStatuses!.toInt(),
                                taskStatusId: _selectedStatuses!.toInt(),
                                startDate: startDate,
                                endDate: endDate,
                                projectId: selectedProject != null
                                    ? int.parse(selectedProject!)
                                    : null,
                                userId: selectedUsers != null
                                    ? selectedUsers!
                                        .map((id) => int.parse(id))
                                        .toList()
                                    : null,
                                priority: selectedPriority?.toString(),
                                description: descriptionController.text,
                                customFields: customFieldList,
                                filePaths: newFilePaths.isNotEmpty
                                    ? newFilePaths
                                    : null,
                                directoryValues: directoryValues,
                                localizations: localizations,
                                existingFiles: keptExistingFiles.isNotEmpty
                                    ? keptExistingFiles
                                    : null,
                                reasonForRefusalId: refusalData?.reasonId,
                                reasonForRefusal: refusalData?.comment,
                              ),
                            );
                        if (mounted) {
                          setState(() => _isSubmittingSave = false);
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isSubmittingSave = false);
                        }
                        _showErrorSnackBar(
                          AppLocalizations.of(context)!
                              .translate('error_format_date'),
                        );
                      }
                    } else {
                      if (mounted) {
                        setState(() => _isSubmittingSave = false);
                      }
                      _showErrorSnackBar(
                        AppLocalizations.of(context)!
                            .translate('fill_required_fields'),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── CustomField model ──────────────────────────────────────────────────────
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
