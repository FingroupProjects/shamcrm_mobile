import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/page_2/warehouse/openings/cash_register/cash_register_content.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_name_list.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_list_edit.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:crm_task_manager/models/deal_model.dart';

class LeadDealAddScreen extends StatefulWidget {
  final int leadId;
  final int? managerId;

  LeadDealAddScreen({required this.leadId, this.managerId});

  @override
  _LeadDealAddScreenState createState() => _LeadDealAddScreenState();
}

class _LeadDealAddScreenState extends State<LeadDealAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController sumController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedManager;
  int? selectedDealStatusId;
  List<CustomField> customFields = [];
  bool isStartDateInvalid = false;
  bool isEndDateInvalid = false;
  bool isTitleInvalid = false;
  bool isManagerInvalid = false;
  bool isStatusInvalid = false;
  List<FileHelper> files = [];
  bool _hasDealUsers = false;
  List<UserData> _selectedUsers = [];

  // Режим настроек
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations;
  final GlobalKey _addFieldButtonKey = GlobalKey();

  // Конфигурация полей с сервера
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) => context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) => context.appColors.borderSubtle;
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.fieldBg;
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _screenSurfaceElevated(BuildContext context) =>
      context.appColors.surfaceElevated;
  Color _screenFooterBackground(BuildContext context) =>
      context.appColors.surfacePrimary;

  void _showScreenSnackBar(
    String message, {
    bool isSuccess = false,
  }) {
    if (!mounted || message.isEmpty) return;

    final colors = context.appColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.textInverse,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: isSuccess ? colors.success : colors.error,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('LeadDealAddScreen: initState started');
    }
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<DealBloc>().add(FetchDealStatuses());
    
    if (widget.managerId != null) {
      setState(() {
        selectedManager = widget.managerId.toString();
        if (kDebugMode) {
          print('LeadDealAddScreen: Auto-selected managerId: ${widget.managerId}');
        }
      });
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
    _loadHasDealUsersSetting();
  }

  Future<void> _loadHasDealUsersSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('has_deal_users') ?? false;

    if (mounted) {
      setState(() {
        _hasDealUsers = value;
      });
    }
    
    if (kDebugMode) {
      print('LeadDealAddScreen: has_deal_users = $value');
    }
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('LeadDealAddScreen: Loading field configuration for deals');
    }
    context.read<FieldConfigurationBloc>().add(FetchFieldConfiguration('deals'));
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
        tableName: 'deals',
        updates: updates,
      );

      if (kDebugMode) {
        print('LeadDealAddScreen: Field positions saved to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LeadDealAddScreen: Error saving field positions: $e');
      }
      if (mounted) {
        _showScreenSnackBar('Ошибка сохранения настроек полей');
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
    final fieldName = config.fieldName.toLowerCase();

    switch (fieldName) {
      case 'name':
        return DealNameSelectionWidget(
          selectedDealName: titleController.text,
          onSelectDealName: (String dealName) {
            setState(() {
              titleController.text = dealName;
              isTitleInvalid = dealName.isEmpty;
            });
          },
          hasError: isTitleInvalid,
        );

      case 'deal_status_id':
        return DealStatusEditWidget(
          selectedStatus: selectedDealStatusId?.toString(),
          onSelectStatus: (DealStatus selectedStatusData) {
            setState(() {
              selectedDealStatusId = selectedStatusData.id;
              isStatusInvalid = false;
            });
          },
          hasError: isStatusInvalid,
        );

      case 'manager_id':
        return ManagerForLead(
          selectedManager: selectedManager,
          onSelectManager: (ManagerData selectedManagerData) {
            setState(() {
              selectedManager = selectedManagerData.id.toString();
              isManagerInvalid = false;
            });
          },
          hasError: isManagerInvalid,
        );

      case 'start_date':
        return CustomTextFieldDate(
          controller: startDateController,
          label: AppLocalizations.of(context)!.translate('start_date'),
          withTime: false,
          hasError: isStartDateInvalid,
        );

      case 'end_date':
        return CustomTextFieldDate(
          controller: endDateController,
          label: AppLocalizations.of(context)!.translate('end_date'),
          withTime: false,
          hasError: isEndDateInvalid,
        );

      case 'sum':
        return CustomTextField(
          controller: sumController,
          hintText: AppLocalizations.of(context)!.translate('enter_summ'),
          label: AppLocalizations.of(context)!.translate('summ'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
        );

      case 'description':
        return CustomTextField(
          controller: descriptionController,
          hintText: AppLocalizations.of(context)!.translate('enter_description'),
          label: AppLocalizations.of(context)!.translate('description_list'),
          maxLines: 5,
          keyboardType: TextInputType.multiline,
        );

      case 'user_ids':
        return _hasDealUsers ? UserMultiSelectWidget(
          selectedUsers: null,
          onSelectUsers: (List<UserData> users) {
            setState(() {
              _selectedUsers = users;
            });
            if (kDebugMode) {
              print('LeadDealAddScreen: Выбрано пользователей: ${users.length}');
            }
          },
        ) : SizedBox.shrink();

      default:
        return SizedBox.shrink();
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
    return _withVerticalSpacing(widgets, spacing: 8);
  }

  Future<void> _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId, String? type}) async {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        showCustomSnackBar(context: context, message: 'Справочник уже добавлен', isSuccess: true);
        debugPrint("LeadDealAddScreen: Directory with ID $directoryId already exists.");
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
          
          context.read<FieldConfigurationBloc>().add(
            FetchFieldConfiguration('deals'),
          );

          _showScreenSnackBar('Справочник успешно добавлен', isSuccess: true);
        }
      } catch (e) {
        _showScreenSnackBar('Ошибка добавления справочника: $e');
      }
      return;
    }

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
      _showScreenSnackBar('Ошибка добавления поля: $e');
    }
  }

  void _showAddFieldMenu() {
    final RenderBox? renderBox = _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final colors = context.appColors;
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
        showAbove ? MediaQuery.of(context).size.height - offset.dy + verticalOffset : MediaQuery.of(context).size.height - offset.dy - size.height - 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
            AppLocalizations.of(context)!.translate('position_changes_will_not_be_saved'),
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
                    buttonText: AppLocalizations.of(context)!.translate('cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    buttonColor: colors.buttonSecondaryBg,
                    textColor: colors.buttonSecondaryFg,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('dont_save'),
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
    ) ?? false;
  }

  Widget _buildSettingsMode() {
    final colors = context.appColors;
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
                      shadowColor: colors.shadowColor.withOpacity(0.28),
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
                    buttonColor: colors.buttonSecondaryBg,
                    textColor: colors.buttonSecondaryFg,
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
                  color: colors.surfacePrimary.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.borderPrimary,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowColor.withOpacity(0.12),
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
                      color: colors.textSecondary,
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
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: colors.buttonPrimaryFg,
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withOpacity(0.96),
            border: Border(top: BorderSide(color: colors.borderPrimary)),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withOpacity(0.08),
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
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
                              colors.buttonPrimaryFg,
                            ),
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

                        _showScreenSnackBar(
                          'Настройки полей сохранены',
                          isSuccess: true,
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('LeadDealAddScreen: Error in save button: $e');
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
        return loc.translate('deal_name');
      case 'manager_id':
        return loc.translate('manager');
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
      case 'user_ids':
        return loc.translate('assignees_list');
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
    final fileTextColor = _screenPrimaryText(context);
    final fileBorderColor = _screenBorder(context);
    final fileCardColor = _screenFieldBackground(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addFileIconAsset = isDark
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
              if (files.isEmpty || index == files.length) {
                return Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: fileCardColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: fileBorderColor),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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

              final fileName = files[index].name;
              final fileExtension = fileName.split('.').last.toLowerCase();

              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: fileCardColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: fileBorderColor),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
                            color: _screenSurfaceBackground(context),
                            shape: BoxShape.circle,
                            border: Border.all(color: fileBorderColor),
                            boxShadow: [
                              BoxShadow(
                                color: context.appColors.shadowColor.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.close, size: 16, color: fileTextColor),
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
    final colors = context.appColors;
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);
    final formSurface = _screenSurfaceBackground(context);
    final footerSurface = _screenFooterBackground(context);

    final screenTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.buttonPrimaryBg,
        selectionColor: colors.buttonPrimaryBg.withOpacity(0.22),
        selectionHandleColor: colors.buttonPrimaryBg,
      ),
      cardColor: formSurface,
      dialogTheme: DialogThemeData(backgroundColor: formSurface),
    );

    return Theme(
      data: screenTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 96,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: AppBarShell(
              leading: AppBarShell.capsule(
                context,
                width: AppBarShell.orbSize,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.center,
                  splashRadius: 22,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 22,
                    color: primaryText,
                  ),
                  onPressed: () {
                    Navigator.pop(context, widget.leadId);
                    context.read<DealBloc>().add(FetchDealStatuses());
                  },
                ),
              ),
              center: AppBarShell.capsule(
                context,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate('new_deal'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                ),
              ),
              trailing: AppBarShell.capsule(
                context,
                width: AppBarShell.orbSize,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.center,
                  splashRadius: 22,
                  icon: Icon(
                    isSettingsMode ? Icons.close_rounded : Icons.settings_rounded,
                    size: 24,
                    color: primaryText,
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
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            const AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
            ),
            SafeArea(
              child: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
        listener: (context, configState) {
          if (configState is FieldConfigurationLoaded) {
            if (kDebugMode) {
              print('LeadDealAddScreen: Configuration loaded with ${configState.fields.length} fields');
            }
            setState(() {
              fieldConfigurations = configState.fields;
              isConfigurationLoaded = true;
            });
          } else if (configState is FieldConfigurationError) {
            if (kDebugMode) {
              print('LeadDealAddScreen: Configuration error: ${configState.message}');
            }
            _showScreenSnackBar('Ошибка загрузки конфигурации: ${configState.message}');
          }
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
                    color: colors.buttonPrimaryBg,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Загрузка конфигурации...',
                    style: TextStyle(color: colors.textSecondary),
                  ),
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
            child: BlocListener<DealBloc, DealState>(
              listener: (context, state) {
                if (state is DealError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showScreenSnackBar(
                      AppLocalizations.of(context)!.translate(state.message),
                    );
                  });
                } else if (state is DealSuccess) {
                  _showScreenSnackBar(
                    AppLocalizations.of(context)!.translate('deal_created_successfully'),
                    isSuccess: true,
                  );
                  Navigator.pop(context, widget.leadId);
                  context.read<LeadDealsBloc>().add(FetchLeadDeals(widget.leadId));
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
                              Container(
                                decoration: BoxDecoration(
                                  color: formSurface.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: subtleBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.shadowColor.withOpacity(0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                  ],
                                ),
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: footerSurface.withOpacity(0.96),
                        border: Border(top: BorderSide(color: subtleBorder)),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowColor.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('cancel'),
                              buttonColor: colors.buttonSecondaryBg,
                              textColor: colors.buttonSecondaryFg,
                              borderColor: colors.borderPrimary,
                              borderWidth: 1,
                              onPressed: () {
                                Navigator.pop(context, widget.leadId);
                                context.read<DealBloc>().add(FetchDealStatuses());
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: BlocBuilder<DealBloc, DealState>(
                              builder: (context, state) {
                                if (state is DealLoading) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: colors.buttonPrimaryBg,
                                    ),
                                  );
                                } else {
                                  return CustomButton(
                                    buttonText: AppLocalizations.of(context)!.translate('add'),
                                    buttonColor: colors.buttonPrimaryBg,
                                    textColor: colors.buttonPrimaryFg,
                                    onPressed: _submitForm,
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
              ),
            ),
          );
        },
      ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    setState(() {
      isTitleInvalid = titleController.text.isEmpty;
      isManagerInvalid = selectedManager == null;
      isStatusInvalid = selectedDealStatusId == null;
    });
    
    if (_formKey.currentState!.validate() && titleController.text.isNotEmpty && selectedManager != null && selectedDealStatusId != null) {
      _createLeadDeal();
    } else {
      _showScreenSnackBar(
        AppLocalizations.of(context)!.translate('fill_required_fields'),
      );
    }
  }

  void _createLeadDeal() {
    DateTime? startDate;
    DateTime? endDate;
    try {
      if (startDateController.text.isNotEmpty) {
        startDate = DateFormat('dd/MM/yyyy').parseStrict(startDateController.text);
      }
      if (endDateController.text.isNotEmpty) {
        endDate = DateFormat('dd/MM/yyyy').parseStrict(endDateController.text);
      }
    } catch (e) {
      setState(() {
        isStartDateInvalid = true;
        isEndDateInvalid = true;
      });
      _showScreenSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_date'),
      );
      return;
    }
    
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      setState(() {
        isStartDateInvalid = true;
        isEndDateInvalid = true;
      });
      _showScreenSnackBar(
        AppLocalizations.of(context)!.translate('start_date_after_end_date'),
      );
      return;
    }

    List<Map<String, dynamic>> customFieldMap = [];
    List<Map<String, int>> directoryValues = [];

    for (var field in customFields) {
      String fieldName = field.fieldName.trim();
      String fieldValue = field.controller.text.trim();
      String? fieldType = field.type;

      if (fieldType == 'number' && fieldValue.isNotEmpty) {
        if (!RegExp(r'^\d+$').hasMatch(fieldValue)) {
          _showScreenSnackBar(
            AppLocalizations.of(context)!.translate('enter_valid_number'),
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
          _showScreenSnackBar(
            AppLocalizations.of(context)!.translate('enter_valid_${fieldType}'),
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
          'type': fieldType ?? 'string',
        });
      }
    }

    final String name = titleController.text;
    final localizations = AppLocalizations.of(context)!;
    final userIds = _selectedUsers.map((user) => user.id).toList();

    context.read<DealBloc>().add(CreateDeal(
      name: name,
      dealStatusId: selectedDealStatusId!,
      managerId: int.parse(selectedManager!),
      leadId: widget.leadId,
      dealtypeId: 1,
      startDate: startDate,
      endDate: endDate,
      sum: sumController.text,
      description: descriptionController.text.isEmpty ? null : descriptionController.text,
      customFields: customFieldMap,
      directoryValues: directoryValues,
      files: files,
      localizations: localizations,
      userIds: userIds.isNotEmpty ? userIds : null,
    ));
  }
}
