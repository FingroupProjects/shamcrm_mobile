import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/delete_file_dialog.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_name_list.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_list_edit.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';

class DealAddScreen extends StatefulWidget {
  final int statusId;

  DealAddScreen({required this.statusId});

  @override
  _DealAddScreenState createState() => _DealAddScreenState();
}

class _DealAddScreenState extends State<DealAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController sumController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedManager;
  String? selectedLead;
  int? _selectedStatusId; // ✅ НОВОЕ: для хранения выбранного статуса
  List<int> _selectedStatusIds = []; // ✅ НОВОЕ: список выбранных ID (для мультивыбора)
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
  bool isTitleInvalid = false;
  bool isManagerInvalid = false;
  bool isManagerManuallySelected = false;
  List<FileHelper> files = [];
  bool _hasDealUsers = false;
  List<UserData> _selectedUsers = [];

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
    //print('DealAddScreen: initState started');
    _selectedStatusId = widget.statusId; // ✅ НОВОЕ: инициализируем выбранный статус
    _selectedStatusIds = [widget.statusId]; // ✅ НОВОЕ: инициализируем список статусов
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    //print('DealAddScreen: Dispatched GetAllManagerEv and GetAllLeadEv');
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

    print('DealAddScreen: has_deal_users = $value');
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('DealAddScreen: Loading field configuration for deals');
    }
    context.read<FieldConfigurationBloc>().add(FetchFieldConfiguration('deals'));
  }

  // Метод для отправки позиций полей на бэкенд
  Future<void> _saveFieldOrderToBackend() async {
    try {
      // Подготовка данных для отправки
      final List<Map<String, dynamic>> updates = [];
      for (var config in fieldConfigurations) {
        updates.add({
          'id': config.id,
          'position': config.position,
          'is_active': config.isActive ? 1 : 0,
          'is_required': config.originalRequired ? 1 : 0, // Используем originalRequired
          'show_on_table': config.showOnTable ? 1 : 0,
        });
      }

      // Отправка на бэкенд
      await _apiService.updateFieldPositions(
        tableName: 'deals',
        updates: updates,
      );

      if (kDebugMode) {
        print('DealAddScreen: Field positions saved to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DealAddScreen: Error saving field positions: $e');
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

  // Вспомогательный метод для создания/получения кастомного поля
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

  // Вспомогательный метод для создания/получения поля-справочника
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

  // Метод для построения стандартных системных полей
  Widget? _buildStandardField(FieldConfiguration config) {
    final fieldName = config.fieldName.toLowerCase();

    switch (fieldName) {
      case 'name':
        return _buildDealNameField();
      case 'lead_id':
        return _buildLeadField();
      case 'manager_id':
        return _buildManagerField();
      case 'start_date':
        return _buildStartDateField();
      case 'end_date':
        return _buildEndDateField();
      case 'sum':
        return _buildSumField();
      case 'description':
        return _buildDescriptionField();
      case 'deal_status_id':
        return DealStatusEditWidget(
          selectedStatus: _selectedStatusId?.toString(),
          onSelectStatus: (DealStatus selectedStatusData) {
            if (_selectedStatusId != selectedStatusData.id) {
              setState(() {
                _selectedStatusId = selectedStatusData.id;
                _selectedStatusIds = [selectedStatusData.id];
              });
            }
          },
          onSelectMultipleStatuses: (List<int> selectedIds) {
            if (_selectedStatusIds.length != selectedIds.length ||
                !_selectedStatusIds.toSet().containsAll(selectedIds) ||
                !selectedIds.toSet().containsAll(_selectedStatusIds)) {
              setState(() {
                _selectedStatusIds = selectedIds;
                if (selectedIds.isNotEmpty) {
                  _selectedStatusId = selectedIds.first;
                }
              });
            }
          },
        );
      case 'user_ids':
        return _hasDealUsers ? UserMultiSelectWidget(
          selectedUsers: null,
          onSelectUsers: (List<UserData> users) {
            setState(() {
              _selectedUsers = users;
            });
            print('DealAddScreen: Выбрано пользователей: ${users.length}');
          },
        ) : SizedBox.shrink();
      // case 'file':
      //   // Поле выбора файлов: отображаем согласно позиции в конфигурации
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
              customFields[index] = directoryField.copyWith(
                entryId: entryId,
              );
            }
          });
        },
      );
    }

    // Иначе это стандартное системное поле
    return _buildStandardField(config);
  }

  Widget _buildDealNameField() {
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
  }

  Widget _buildLeadField() {
    return  LeadWithManager(
      selectedLead: selectedLead,
      onSelectLead: (LeadData selectedLeadData) {
        //print('DealAddScreen: Lead selected: ${selectedLeadData.id}, managerId: ${selectedLeadData.managerId}');
        if (selectedLead == selectedLeadData.id.toString()) {
          //print('DealAddScreen: Lead ${selectedLeadData.id} already selected, skipping');
          return;
        }
        setState(() {
          selectedLead = selectedLeadData.id.toString();
          //print('DealAddScreen: isManagerManuallySelected: $isManagerManuallySelected');
          if (!isManagerManuallySelected && selectedLeadData.managerId != null) {
            //print('DealAddScreen: Attempting to auto-select manager');
            final managerBlocState = context.read<GetAllManagerBloc>().state;
            //print('DealAddScreen: ManagerBloc state: $managerBlocState');
            if (managerBlocState is GetAllManagerSuccess) {
              final managers = managerBlocState.dataManager.result ?? [];
              //print('DealAddScreen: Available managers: ${managers.map((m) => m.id)}');
              try {
                final matchingManager = managers.firstWhere(
                      (manager) => manager.id == selectedLeadData.managerId,
                );
                selectedManager = matchingManager.id.toString();
                //print('DealAddScreen: Auto-selected manager: ${matchingManager.id} (${matchingManager.name})');
              } catch (e) {
                //print('DealAddScreen: Manager not found for ID ${selectedLeadData.managerId}, skipping auto-select');
                selectedManager = null;
              }
            } else {
              //print('DealAddScreen: ManagerBloc not in success state, skipping auto-select');
            }
          } else {
            //print('DealAddScreen: Manager already manually selected or no managerId, skipping auto-select');
          }
        });
      },
    );
  }

  Widget _buildManagerField() {
    return ManagerForLead(
      selectedManager: selectedManager,
      onSelectManager: (ManagerData selectedManagerData) {
        setState(() {
          selectedManager = selectedManagerData.id.toString();
          isManagerInvalid = false;
          isManagerManuallySelected = true;
        });
      },
      hasError: isManagerInvalid,
    );
  }

  Widget _buildStartDateField() {
    return CustomTextFieldDate(
      controller: startDateController,
      label: AppLocalizations.of(context)!.translate('start_date'),
      withTime: false,
    );
  }

  Widget _buildEndDateField() {
    return CustomTextFieldDate(
      controller: endDateController,
      label: AppLocalizations.of(context)!.translate('end_date'),
      hasError: isEndDateInvalid,
      withTime: false,
    );
  }

  Widget _buildSumField() {
    return CustomTextField(
      controller: sumController,
      hintText: AppLocalizations.of(context)!.translate('enter_summ'),
      label: AppLocalizations.of(context)!.translate('summ'),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
    );
  }

  Widget _buildDescriptionField() {
    return CustomTextField(
      controller: descriptionController,
      hintText: AppLocalizations.of(context)!.translate('enter_description'),
      label: AppLocalizations.of(context)!.translate('description_list'),
      maxLines: 5,
      keyboardType: TextInputType.multiline,
    );
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
    // Фильтруем только активные поля и сортируем по позициям
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
    return _withVerticalSpacing(widgets, spacing: 16);
  }

  List<Widget> _buildDefaultDealWidgets() {
    return _withVerticalSpacing([
      _buildDealNameField(),
      _buildLeadField(),
      _buildManagerField(),
      _buildStartDateField(),
      _buildEndDateField(),
      _buildSumField(),
      _buildDescriptionField(),
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
        await _apiService.linkDirectory(
          directoryId: directoryId,
          modelType: 'deal',
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
      await _apiService.addNewField(
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

  // Проверка, были ли изменения в конфигурации полей
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
                    originalRequired: config.originalRequired, // Сохраняем оригинальное значение
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

              if (config.fieldName == 'deal_status_id') {
                return SizedBox(
                  key: ValueKey('field_${config.id}'),
                );
              }

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
                            ],
                          ),
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
                                    required: false, // Всегда false в UI
                                    isActive: !config.isActive,
                                    isCustomField: config.isCustomField,
                                    createdAt: config.createdAt,
                                    updatedAt: config.updatedAt,
                                    customFieldId: config.customFieldId,
                                    directoryId: config.directoryId,
                                    type: config.type,
                                    isDirectory: config.isDirectory,
                                    showOnTable: config.showOnTable,
                                    originalRequired: config.originalRequired, // Сохраняем оригинальное значение
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
                    } catch (e) {
                      if (kDebugMode) {
                        print('DealAddScreen: Error in save button: $e');
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
          // selectedFiles.add(file.path);
          // fileNames.add(file.name);
          // fileSizes.add(file.sizeKB);

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
                          // НОВОЕ: Используем метод _buildFileIcon для показа превью или иконки
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

  // Получение отображаемого названия поля
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
      // case 'file':
      //   return loc.translate('file');
      default:
        return config.fieldName;
    }
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

  @override
  Widget build(BuildContext context) {
    //print('DealAddScreen: Building with selectedLead: $selectedLead, selectedManager: $selectedManager');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('new_deal'),
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
              icon: Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
              onPressed: () {
                Navigator.pop(context, widget.statusId);
                context.read<DealBloc>().add(FetchDealStatuses());
              },
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
                            required: false, // Всегда false в UI
                            isActive: newFields[i].isActive,
                            isCustomField: newFields[i].isCustomField,
                            createdAt: newFields[i].createdAt,
                            updatedAt: newFields[i].updatedAt,
                            customFieldId: newFields[i].customFieldId,
                            directoryId: newFields[i].directoryId,
                            type: newFields[i].type,
                            isDirectory: newFields[i].isDirectory,
                            showOnTable: newFields[i].showOnTable,
                            originalRequired: newFields[i].originalRequired, // Сохраняем оригинальное значение
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
                      originalRequired: config.originalRequired, // Сохраняем оригинальное значение
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
          //         FetchFieldConfiguration('deals')
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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(listener: (context, configState) {
        if (kDebugMode) {
          print('DealAddScreen: FieldConfigurationBloc state changed: ${configState.runtimeType}');
        }

        if (configState is FieldConfigurationLoaded) {
          if (kDebugMode) {
            print('DealAddScreen: Configuration loaded with ${configState.fields.length} fields');
          }
          setState(() {
            fieldConfigurations = configState.fields;
            isConfigurationLoaded = true;
          });
        } else if (configState is FieldConfigurationError) {
          if (kDebugMode) {
            print('DealAddScreen: Configuration error: ${configState.message}');
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
      }, builder: (context, configState) {
        if (kDebugMode) {
          print('DealAddScreen: Building with state: ${configState.runtimeType}, isLoaded: $isConfigurationLoaded');
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

        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => MainFieldBloc()),
          ],
          child: BlocListener<DealBloc, DealState>(
            listener: (context, state) {
              if (state is DealError) {
                showCustomSnackBar(
                  context: context,
                  message: AppLocalizations.of(context)!.translate(state.message),
                  isSuccess: false,
                );
              } else if (state is DealSuccess) {
                showCustomSnackBar(
                  context: context,
                  message: AppLocalizations.of(context)!.translate(state.message),
                  isSuccess: true,
                );
                if (context.mounted) {
                  Navigator.pop(context, widget.statusId);
                  context.read<DealBloc>().add(FetchDealStatuses());
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
                              return _buildDefaultDealWidgets();
                            })(),

                            // ТОЛЬКО пользовательские поля (те, которые добавлены через кнопку "Добавить поле")
                            ...customFields.where((field) {
                              // Исключаем поля, которые уже есть в серверной конфигурации
                              return !fieldConfigurations.any((config) =>
                              (config.isCustomField && config.fieldName == field.fieldName) ||
                                  (config.isDirectory && config.directoryId == field.directoryId)
                              );
                            }).map((field) {
                              return Column(
                                children: [
                                  field.isDirectoryField && field.directoryId != null
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
                                      }
                                  )
                                      : CustomFieldWidget(
                                    fieldName: field.fieldName,
                                    valueController: field.controller,
                                    type: field.type,
                                    isDirectory: false,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),

                            // Файлы (всегда показываем)
                            _buildFileSelection(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('cancel'),
                            buttonColor: Color(0xffF4F7FD),
                            textColor: Colors.black,
                            onPressed: () {
                              //print('DealAddScreen: Cancel button pressed');
                              Navigator.pop(context, widget.statusId);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: BlocBuilder<DealBloc, DealState>(
                            builder: (context, state) {
                              //print('DealAddScreen: DealBloc builder state: $state');
                              if (state is DealLoading) {
                                return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
                              } else {
                                return CustomButton(
                                  buttonText: AppLocalizations.of(context)!.translate('add'),
                                  buttonColor: Color(0xff4759FF),
                                  textColor: Colors.white,
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
      }),
    );
  }

  void _createDeal() {
    final String name = titleController.text.trim();
    final String? startDateString = startDateController.text.isEmpty ? null : startDateController.text;
    final String? endDateString = endDateController.text.isEmpty ? null : endDateController.text;
    final String sum = sumController.text;
    final String? description = descriptionController.text.isEmpty ? null : descriptionController.text;

    //print('DealAddScreen: Creating deal with name: $name, leadId: $selectedLead, managerId: $selectedManager');

    DateTime? startDate;
    if (startDateString != null && startDateString.isNotEmpty) {
      try {
        startDate = DateFormat('dd/MM/yyyy').parse(startDateString);
      } catch (e) {
        //print('DealAddScreen: Invalid start date format: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('enter_valid_date')),
            backgroundColor: Colors.red,
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
        //print('DealAddScreen: Invalid end date format: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('enter_valid_date')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      setState(() {
        isEndDateInvalid = true;
      });
      //print('DealAddScreen: Start date is after end date');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('start_date_after_end_date'),
            style: TextStyle(color: Colors.white),
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

      // Валидация для number
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

      // Валидация и форматирование для date и datetime
      if ((fieldType == 'date' || fieldType == 'datetime') &&
          fieldValue.isNotEmpty) {
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
                AppLocalizations.of(context)!
                    .translate('enter_valid_${fieldType}'),
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
        //print('DealAddScreen: Added directory value: ${field.directoryId}, ${field.entryId}');
      } else if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
        customFieldMap.add({
          'key': fieldName,
          'value': fieldValue,
          'type': fieldType ?? 'string',
        });
        //print('DealAddScreen: Added custom field: $fieldName = $fieldValue, type: $fieldType');
      }
    }

    final localizations = AppLocalizations.of(context)!;
      final userIds = _selectedUsers.map((user) => user.id).toList();


    context.read<DealBloc>().add(CreateDeal(
      name: name,
      dealStatusId: _selectedStatusId ?? widget.statusId, // ✅ НОВОЕ: используем выбранный статус
      managerId: int.parse(selectedManager!),
      leadId: int.parse(selectedLead!),
      dealtypeId: 1,
      startDate: startDate,
      endDate: endDate,
      sum: sum,
      description: description,
      customFields: customFieldMap,
      directoryValues: directoryValues,
      files: files,
      localizations: localizations,
      userIds: userIds.isNotEmpty ? userIds : null, // ✅ НОВОЕ
    ));
    //print('DealAddScreen: Dispatched CreateDeal event');
  }

  void _submitForm() {
    //print('DealAddScreen: Submitting form with title: ${titleController.text}, lead: $selectedLead, manager: $selectedManager');
    setState(() {
      isTitleInvalid = titleController.text.isEmpty;
      isManagerInvalid = selectedManager == null;
    });

    if (_formKey.currentState!.validate() && titleController.text.isNotEmpty && selectedManager != null && selectedLead != null) {
      _createDeal();
    } else {
      //print('DealAddScreen: Form validation failed');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}