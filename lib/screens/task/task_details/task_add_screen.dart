import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_withPriority.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_list_edit.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../bloc/field_configuration/field_configuration_bloc.dart';
import '../../../bloc/field_configuration/field_configuration_event.dart';
import '../../../models/field_configuration.dart';
import '../../../page_2/warehouse/openings/cash_register/cash_register_content.dart';

class TaskAddScreen extends StatefulWidget {
  final int statusId;
  final int? initialProjectId;
  final bool lockProject;

  const TaskAddScreen({
    Key? key,
    required this.statusId,
    this.initialProjectId,
    this.lockProject = false,
  }) : super(key: key);

  @override
  _TaskAddScreenState createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<FileHelper> files = [];
  int? selectedPriority;
  String? selectedProject;
  String? selectedStatus;
  List<String>? selectedUsers;
  List<CustomField> customFields = [];

  bool isNameInvalid = false;
  bool isExecutorInvalid = false;
  bool isProjectInvalid = false;
  bool isEndDateInvalid = false;
  bool isStatusInvalid = false;

  bool _hasTaskCreatePermission = false;
  bool _hasTaskCreateForMySelfPermission = false;
  int? _currentUserId;

  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations;
  final GlobalKey _addFieldButtonKey = GlobalKey();

  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  // ─── Screen-scoped color helpers (same pattern as LeadAddScreen) ───
  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) => context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) => context.appColors.borderSubtle;
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

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
    _setDefaultValues();
    _checkPermissionsAndUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
  }

  void _setDefaultValues() {
    selectedPriority = 1;
    final now = DateTime.now();
    startDateController.text = DateFormat('dd/MM/yyyy').format(now);
    selectedStatus = widget.statusId.toString();
    if (widget.initialProjectId != null) {
      selectedProject = widget.initialProjectId.toString();
    }
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
      await ApiService().updateFieldPositions(
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: context.appColors.error,
            elevation: 3,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  CustomField _getOrCreateCustomField(FieldConfiguration config) {
    return customFields.firstWhere(
      (f) => f.fieldName == config.fieldName && f.isCustomField,
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
  }

  CustomField _getOrCreateDirectoryField(FieldConfiguration config) {
    return customFields.firstWhere(
      (f) => f.directoryId == config.directoryId,
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
  }

  Widget _buildStandardField(FieldConfiguration config) {
    final fieldBackground = _screenFieldBackground(context);
    final fieldBorder = _screenBorder(context);
    final fieldText = _screenPrimaryText(context);
    final fieldHint = _screenHintText(context);
    final focusedBorder = _screenFocusBorder(context);

    switch (config.fieldName) {
      case 'name':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFieldWithPriority(
              controller: nameController,
              hintText: AppLocalizations.of(context)!.translate('enter_title'),
              label: AppLocalizations.of(context)!.translate('event_name'),
              showPriority: true,
              isPrioritySelected: selectedPriority == 3,
              hasError: isNameInvalid,
              // backgroundColor: fieldBackground,
              // labelColor: fieldText,
              // hintColor: fieldHint,
              // textColor: fieldText,
              // borderColor: fieldBorder,
              // focusedBorderColor: focusedBorder,
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
                  setState(() => isNameInvalid = false);
                }
              },
            ),
            if (isNameInvalid)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  AppLocalizations.of(context)!.translate('field_required'),
                  style: TextStyle(
                    color: context.appColors.error,
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
          hintText:
              AppLocalizations.of(context)!.translate('enter_description'),
          label: AppLocalizations.of(context)!.translate('description_list'),
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );

      case 'executor':
        if (_hasTaskCreatePermission || !_hasTaskCreateForMySelfPermission) {
          return UserMultiSelectWidget(
            selectedUsers: selectedUsers,
            onSelectUsers: (List<UserData> selectedUsersData) {
              setState(() {
                selectedUsers =
                    selectedUsersData.map((u) => u.id.toString()).toList();
                isExecutorInvalid = false;
              });
            },
            hasError: isExecutorInvalid,
          );
        }
        return const SizedBox.shrink();

      case 'project':
        if (widget.lockProject && widget.initialProjectId != null) {
          return const SizedBox.shrink();
        }
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
              errorText: isProjectInvalid
                  ? AppLocalizations.of(context)!.translate('field_required')
                  : null,
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
                  setState(() => isEndDateInvalid = false);
                }
              },
            ),
            if (isEndDateInvalid)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  AppLocalizations.of(context)!.translate('field_required'),
                  style: TextStyle(
                    color: context.appColors.error,
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
            TaskStatusEditWidget(
              selectedStatus: selectedStatus?.toString(),
              onSelectStatus: (TaskStatus selectedStatusData) {
                setState(() {
                  selectedStatus = selectedStatusData.id.toString();
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
                    color: context.appColors.error,
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );

      default:
        return const SizedBox.shrink();
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
        selectedField: null,
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
      );
    }

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
                  color: context.appColors.error,
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    }

    return _buildStandardField(config);
  }

  List<Widget> _buildConfiguredFieldWidgets() {
    final sorted = fieldConfigurations.where((c) => c.isActive).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    return sorted
        .map((c) => _buildFieldWidget(c))
        .whereType<Widget>()
        .map((w) => Column(children: [w, const SizedBox(height: 16)]))
        .toList();
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _addCustomField(
    String fieldName, {
    bool isDirectory = false,
    int? directoryId,
    String? type,
  }) async {
    if (isDirectory && directoryId != null) {
      bool exists = customFields
          .any((f) => f.isDirectoryField && f.directoryId == directoryId);
      if (exists) {
        showCustomSnackBar(
            context: context,
            message: 'Справочник уже добавлен',
            isSuccess: true);
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
          context
              .read<FieldConfigurationBloc>()
              .add(FetchFieldConfiguration('tasks'));
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar(e.toString());
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
        context
            .read<FieldConfigurationBloc>()
            .add(FetchFieldConfiguration('tasks'));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: _screenFieldBackground(context),
      items: menuItems,
    ).then((value) {
      if (value == 'manual') {
        showDialog(
          context: context,
          builder: (_) => AddCustomFieldDialog(
            onAddField: (fieldName, {String? type}) {
              _addCustomField(fieldName, type: type);
            },
          ),
        );
      } else if (value == 'directory') {
        showDialog(
          context: context,
          builder: (_) => AddCustomDirectoryDialog(
            onAddDirectory: (directory) async {
              await _addCustomField(
                directory.name,
                isDirectory: true,
                directoryId: directory.id,
              );
            },
          ),
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
          current.showOnTable != original.showOnTable) return true;
    }
    return false;
  }

  Future<bool> _showExitSettingsDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: context.appColors.surfacePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: context.appColors.borderPrimary),
              ),
              title: Text(
                AppLocalizations.of(context)!.translate('warning'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
              content: Text(
                AppLocalizations.of(context)!
                    .translate('position_changes_will_not_be_saved'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                        buttonColor: context.appColors.buttonSecondaryBg,
                        textColor: context.appColors.buttonSecondaryFg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        buttonText: AppLocalizations.of(context)!
                            .translate('dont_save'),
                        onPressed: () => Navigator.of(context).pop(true),
                        buttonColor: context.appColors.buttonDangerBg,
                        textColor: context.appColors.buttonDangerFg,
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

  Widget _buildSettingsMode() {
    final sortedFields = [...fieldConfigurations]
      ..sort((a, b) => a.position.compareTo(b.position));
    final cardColor = _screenFieldBackground(context);
    final cardBorder = _screenBorder(context);
    final titleColor = _screenPrimaryText(context);
    final subtitleColor = _screenSecondaryText(context);
    final mutedColor = _screenHintText(context);

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            itemCount: sortedFields.length + 1,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final animValue = Curves.easeInOut.transform(animation.value);
                  return Transform.scale(
                    scale: 1.0 + animValue * 0.05,
                    child: Material(
                      elevation: animValue * 12.0,
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
                  newIndex == sortedFields.length + 1) return;
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                if (newIndex >= sortedFields.length) {
                  newIndex = sortedFields.length - 1;
                }
                final item = sortedFields.removeAt(oldIndex);
                sortedFields.insert(newIndex, item);
                fieldConfigurations = sortedFields.asMap().entries.map((e) {
                  final c = e.value;
                  return FieldConfiguration(
                    id: c.id,
                    tableName: c.tableName,
                    fieldName: c.fieldName,
                    position: e.key + 1,
                    required: false,
                    isActive: c.isActive,
                    isCustomField: c.isCustomField,
                    createdAt: c.createdAt,
                    updatedAt: c.updatedAt,
                    customFieldId: c.customFieldId,
                    directoryId: c.directoryId,
                    type: c.type,
                    isDirectory: c.isDirectory,
                    showOnTable: c.showOnTable,
                    originalRequired: c.originalRequired,
                  );
                }).toList();
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
                    buttonColor: cardColor,
                    textColor: titleColor,
                    onPressed: _showAddFieldMenu,
                  ),
                );
              }

              final config = sortedFields[index];
              return Container(
                key: ValueKey('field_${config.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder, width: 1),
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
                    Icon(Icons.drag_handle, color: mutedColor, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFieldDisplayName(config),
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFieldTypeLabel(config),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                  final updated = FieldConfiguration(
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
                                  if (idx != -1)
                                    fieldConfigurations[idx] = updated;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
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
                                        duration:
                                            const Duration(milliseconds: 200),
                                        opacity: config.isActive ? 1.0 : 0.0,
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: context.appColors.textInverse,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
        // ─── Settings footer (same card style as lead) ───
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _screenFooterBackground(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _screenBorder(context)),
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
                              context.appColors.textInverse,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                  textColor: context.appColors.buttonPrimaryFg,
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: context.appColors.success,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) print('TaskAddScreen: Error in save: $e');
                    } finally {
                      if (mounted) setState(() => isSavingFieldOrder = false);
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
        return loc.translate('event_name');
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
    double totalSize = files.fold<double>(
        0.0, (sum, f) => sum + File(f.path).lengthSync() / (1024 * 1024));

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
        for (var f in pickedFiles) {
          files.add(
              FileHelper(id: 0, name: f.name, path: f.path, size: f.sizeKB));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final baseColors = context.appColors;
    final baseTextStyles = context.appTextStyles;
    final baseShadows = context.appShadows;

    // Override theme for this screen (same as LeadAddScreen)
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
          caption:
              baseTextStyles.caption.copyWith(color: _screenHintText(context)),
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
        backgroundColor: baseColors.overlay.withValues(alpha: 0),
        extendBodyBehindAppBar: !isSettingsMode,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          backgroundColor: baseColors.overlay.withValues(alpha: 0),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: baseColors.overlay.withValues(alpha: 0),
          shadowColor: baseColors.overlay.withValues(alpha: 0),
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
                onPressed: () {
                  Navigator.pop(context, widget.statusId);
                  context.read<TaskBloc>().add(FetchTaskStatuses());
                },
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
                  AppLocalizations.of(context)!.translate('new_task'),
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
                  isSettingsMode ? Icons.close_rounded : Icons.settings_rounded,
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
                          final newFields = fieldConfigurations.where((c) {
                            return !originalFieldConfigurations!
                                .any((o) => o.id == c.id);
                          }).toList();
                          fieldConfigurations = [
                            ...originalFieldConfigurations!
                          ];
                          if (newFields.isNotEmpty) {
                            int maxPos = fieldConfigurations.isEmpty
                                ? 0
                                : fieldConfigurations
                                    .map((e) => e.position)
                                    .reduce((a, b) => a > b ? a : b);
                            for (int i = 0; i < newFields.length; i++) {
                              final nf = newFields[i];
                              fieldConfigurations.add(FieldConfiguration(
                                id: nf.id,
                                tableName: nf.tableName,
                                fieldName: nf.fieldName,
                                position: maxPos + i + 1,
                                required: false,
                                isActive: nf.isActive,
                                isCustomField: nf.isCustomField,
                                createdAt: nf.createdAt,
                                updatedAt: nf.updatedAt,
                                customFieldId: nf.customFieldId,
                                directoryId: nf.directoryId,
                                type: nf.type,
                                isDirectory: nf.isDirectory,
                                showOnTable: nf.showOnTable,
                                originalRequired: nf.originalRequired,
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
                      originalFieldConfigurations = fieldConfigurations
                          .map((c) => FieldConfiguration(
                                id: c.id,
                                tableName: c.tableName,
                                fieldName: c.fieldName,
                                position: c.position,
                                required: false,
                                isActive: c.isActive,
                                isCustomField: c.isCustomField,
                                createdAt: c.createdAt,
                                updatedAt: c.updatedAt,
                                customFieldId: c.customFieldId,
                                directoryId: c.directoryId,
                                type: c.type,
                                isDirectory: c.isDirectory,
                                showOnTable: c.showOnTable,
                                originalRequired: c.originalRequired,
                              ))
                          .toList();
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
            const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
            BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
              listener: (context, configState) {
                if (configState is FieldConfigurationLoaded) {
                  setState(() {
                    fieldConfigurations = configState.fields;
                    isConfigurationLoaded = true;
                  });
                } else if (configState is FieldConfigurationError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ошибка загрузки конфигурации: ${configState.message}',
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
              },
              builder: (context, configState) {
                if (configState is FieldConfigurationLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryText),
                  );
                }

                if (!isConfigurationLoaded) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryText),
                        const SizedBox(height: 16),
                        Text(
                          'Загрузка конфигурации...',
                          style: TextStyle(color: primaryText),
                        ),
                      ],
                    ),
                  );
                }

                if (isSettingsMode) return _buildSettingsMode();

                return MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => MainFieldBloc()),
                  ],
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
                          Navigator.pop(context, widget.statusId);
                          context.read<TaskBloc>().add(FetchTaskStatuses());
                        }
                      }
                    },
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).padding.top + 10,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => FocusScope.of(context).unfocus(),
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 18, 18, 22),
                                  decoration: BoxDecoration(
                                    color: formSurface,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: subtleBorder),
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
                                      ..._buildConfiguredFieldWidgets(),
                                      ...customFields.where((field) {
                                        return !fieldConfigurations.any((c) =>
                                            (c.isCustomField &&
                                                c.fieldName ==
                                                    field.fieldName) ||
                                            (c.isDirectory &&
                                                c.directoryId ==
                                                    field.directoryId));
                                      }).map((field) {
                                        return Column(
                                          children: [
                                            field.isDirectoryField &&
                                                    field.directoryId != null
                                                ? MainFieldDropdownWidget(
                                                    directoryId:
                                                        field.directoryId!,
                                                    directoryName:
                                                        field.fieldName,
                                                    selectedField: null,
                                                    onSelectField:
                                                        (MainField sf) {
                                                      setState(() {
                                                        final idx = customFields
                                                            .indexOf(field);
                                                        customFields[idx] =
                                                            field.copyWith(
                                                          entryId: sf.id,
                                                          controller:
                                                              TextEditingController(
                                                                  text:
                                                                      sf.value),
                                                        );
                                                      });
                                                    },
                                                    controller:
                                                        field.controller,
                                                    onSelectEntryId:
                                                        (int entryId) {
                                                      setState(() {
                                                        final idx = customFields
                                                            .indexOf(field);
                                                        customFields[idx] =
                                                            field.copyWith(
                                                                entryId:
                                                                    entryId);
                                                      });
                                                    },
                                                  )
                                                : CustomFieldWidget(
                                                    fieldName: field.fieldName,
                                                    valueController:
                                                        field.controller,
                                                    type: field.type,
                                                    isDirectory: false,
                                                  ),
                                            const SizedBox(height: 16),
                                          ],
                                        );
                                      }).toList(),
                                      _buildFileSelection(),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // ─── Footer card (same as lead) ───
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: footerSurface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: subtleBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    buttonText: AppLocalizations.of(context)!
                                        .translate('cancel'),
                                    buttonColor:
                                        _screenFieldBackground(context),
                                    textColor: primaryText,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: BlocBuilder<TaskBloc, TaskState>(
                                    builder: (context, state) {
                                      if (state is TaskLoading) {
                                        return Center(
                                          child: CircularProgressIndicator(
                                              color: primaryText),
                                        );
                                      }
                                      return CustomButton(
                                        buttonText:
                                            AppLocalizations.of(context)!
                                                .translate('add'),
                                        buttonColor:
                                            context.appColors.buttonPrimaryBg,
                                        textColor:
                                            context.appColors.buttonPrimaryFg,
                                        onPressed: _submitForm,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelection() {
    final fileCardColor = _screenFieldBackground(context);
    final fileTextColor = _screenPrimaryText(context);
    final fileBorderColor = _screenBorder(context);
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
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.isEmpty ? 1 : files.length + 1,
            itemBuilder: (context, index) {
              if (files.isEmpty || index == files.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: fileCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: fileBorderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            addFileIconAsset,
                            width: 54,
                            height: 54,
                          ),
                          const SizedBox(height: 6),
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
                                color: fileTextColor,
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
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: fileCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: fileBorderColor),
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
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
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
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => files.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.appColors.surfacePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.appColors.shadow
                                    .withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              Icon(Icons.close, size: 16, color: fileTextColor),
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

  void _submitForm() {
    setState(() {
      isNameInvalid = false;
      isExecutorInvalid = false;
      isProjectInvalid = false;
      isEndDateInvalid = false;
      isStatusInvalid = false;
    });

    bool hasError = false;

    if (nameController.text.trim().isEmpty) {
      setState(() => isNameInvalid = true);
      hasError = true;
    }

    if (selectedStatus == null || selectedStatus!.isEmpty) {
      setState(() => isStatusInvalid = true);
      hasError = true;
    }

    if (_hasTaskCreatePermission || !_hasTaskCreateForMySelfPermission) {
      if (selectedUsers == null || selectedUsers!.isEmpty) {
        setState(() => isExecutorInvalid = true);
        hasError = true;
      }
    } else if (!_hasTaskCreatePermission &&
        _hasTaskCreateForMySelfPermission &&
        _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('user_id_not_found'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appColors.textInverse,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: context.appColors.error,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (selectedProject == null || selectedProject!.isEmpty) {
      setState(() => isProjectInvalid = true);
      hasError = true;
    }

    if (endDateController.text.trim().isEmpty) {
      setState(() => isEndDateInvalid = true);
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
              color: context.appColors.textInverse,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: context.appColors.error,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    _createTask();
  }

  void _createTask() {
    final String name = nameController.text.trim();
    final String? startDateString =
        startDateController.text.isEmpty ? null : startDateController.text;
    final String? endDateString =
        endDateController.text.isEmpty ? null : endDateController.text;
    final String? description =
        descriptionController.text.isEmpty ? null : descriptionController.text;

    DateTime? startDate;
    if (startDateString != null && startDateString.isNotEmpty) {
      try {
        startDate = DateFormat('dd/MM/yyyy').parse(startDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.translate('enter_valid_date')),
          backgroundColor: context.appColors.error,
        ));
        return;
      }
    }

    DateTime? endDate;
    if (endDateString != null && endDateString.isNotEmpty) {
      try {
        endDate = DateFormat('dd/MM/yyyy').parse(endDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.translate('enter_valid_date')),
          backgroundColor: context.appColors.error,
        ));
        return;
      }
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      setState(() => isEndDateInvalid = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate('start_date_after_end_date'),
          style: TextStyle(color: context.appColors.textInverse),
        ),
        backgroundColor: context.appColors.error,
      ));
      return;
    }

    List<Map<String, dynamic>> customFieldMap = [];
    List<Map<String, int>> directoryValues = [];

    for (var field in customFields) {
      String fieldName = field.fieldName.trim();
      String fieldValue = field.controller.text.trim();
      String? fieldType = field.type;
      if (fieldType == 'text') fieldType = 'string';
      fieldType ??= 'string';

      if (fieldType == 'number' && fieldValue.isNotEmpty) {
        if (!RegExp(r'^\d+$').hasMatch(fieldValue)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('enter_valid_number'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.error,
          ));
          return;
        }
      }

      if ((fieldType == 'date' || fieldType == 'datetime') &&
          fieldValue.isNotEmpty) {
        try {
          if (fieldType == 'date') {
            DateFormat('dd/MM/yyyy').parse(fieldValue);
          } else {
            DateFormat('dd/MM/yyyy HH:mm').parse(fieldValue);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .translate('enter_valid_${fieldType}'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.error,
          ));
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
        customFieldMap.add({
          'key': fieldName,
          'value': fieldValue,
          'type': fieldType,
        });
      }
    }

    List<int>? userIds;
    if (!_hasTaskCreatePermission &&
        _hasTaskCreateForMySelfPermission &&
        _currentUserId != null) {
      userIds = [_currentUserId!];
    } else {
      userIds = selectedUsers?.map((id) => int.parse(id)).toList();
    }

    context.read<TaskBloc>().add(CreateTask(
          name: name,
          statusId: widget.statusId,
          taskStatusId: int.parse(selectedStatus!),
          startDate: startDate,
          endDate: endDate,
          projectId:
              selectedProject != null ? int.parse(selectedProject!) : null,
          userId: userIds,
          priority: selectedPriority,
          description: description,
          customFields: customFieldMap,
          files: files.isNotEmpty ? files : null,
          directoryValues: directoryValues,
          localizations: AppLocalizations.of(context)!,
        ));
  }

  Future<void> _checkPermissionsAndUser() async {
    try {
      final apiService = ApiService();
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userID');
      final results = await Future.wait([
        apiService.hasPermission('task.create'),
        apiService.hasPermission('task.createForMySelf'),
      ]);
      setState(() {
        _hasTaskCreatePermission = results[0];
        _hasTaskCreateForMySelfPermission = results[1];
        _currentUserId =
            userIdString != null ? int.tryParse(userIdString) : null;
      });
    } catch (e) {
      setState(() {
        _hasTaskCreatePermission = false;
        _hasTaskCreateForMySelfPermission = false;
        _currentUserId = null;
      });
    }
  }
}
