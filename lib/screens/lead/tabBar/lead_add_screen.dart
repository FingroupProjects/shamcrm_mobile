import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/delete_file_dialog.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_status_list_edit.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class LeadAddScreen extends StatefulWidget {
  final int statusId;

  LeadAddScreen({required this.statusId});

  @override
  _LeadAddScreenState createState() => _LeadAddScreenState();
}

class _LeadAddScreenState extends State<LeadAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Контроллеры для стандартных полей
  final TextEditingController titleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController instaLoginController = TextEditingController();
  final TextEditingController facebookLoginController = TextEditingController();
  final TextEditingController tgNickController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Выбранные значения
  String? selectedRegion;
  String? selectedManager;
  String? selectedSourceLead;
  String selectedDialCode = '';
  String selectedDialCodeWhatsapp = '';
  int? _selectedStatuses;
  String? selectedSalesFunnel;

  // Кастомные поля
  List<CustomField> customFields = [];

  // Конфигурация полей с сервера
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  // Переменные для файлов
  List<FileHelper> files = [];

  // Режим настроек
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations; // Для отслеживания изменений
  final GlobalKey _addFieldButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedStatuses = widget.statusId;
    context.read<SourceLeadBloc>().add(FetchSourceLead());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());

    // ВАЖНО: Добавляем небольшую задержку чтобы context был готов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('LeadAddScreen: Loading field configuration for leads');
    }
    context.read<FieldConfigurationBloc>().add(
        FetchFieldConfiguration('leads')
    );
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
          'is_active': config.originalIsActive ?? (config.isActive ? 1 : 0),
          'is_required': config.originalRequired ?? (config.required ? 1 : 0),
          'show_on_table': config.showOnTable ? 1 : 0,
        });
      }

      // Отправка на бэкенд
      await _apiService.updateFieldPositions(
        tableName: 'leads',
        updates: updates,
      );

      if (kDebugMode) {
        print('LeadAddScreen: Field positions saved to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LeadAddScreen: Error saving field positions: $e');
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
  Widget _buildStandardField(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'name':
        return CustomTextField(
          controller: titleController,
          hintText: AppLocalizations.of(context)!.translate('enter_name_list'),
          label: AppLocalizations.of(context)!.translate('name_list'),
        );

      case 'phone':
        return CustomPhoneNumberInput(
          controller: phoneController,
          onInputChanged: (String number) {
            setState(() {
              selectedDialCode = number;
            });
          },
          label: AppLocalizations.of(context)!.translate('phone'),
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

      case 'region_id':
        return RegionRadioGroupWidget(
          selectedRegion: selectedRegion,
          onSelectRegion: (RegionData selectedRegionData) {
            setState(() {
              selectedRegion = selectedRegionData.id.toString();
            });
          },
        );

      case 'source_id':
        return SourceLeadWidget(
          selectedSourceLead: selectedSourceLead,
          onChanged: (String? newValue) {
            setState(() {
              selectedSourceLead = newValue;
            });
          },
        );

      case 'wa_phone':
        return CustomPhoneNumberInput(
          controller: whatsappController,
          onInputChanged: (String number) {
            setState(() {
              selectedDialCodeWhatsapp = number;
            });
          },
          label: 'Whatsapp',
        );

      case 'tg_nick':
        return CustomTextField(
          controller: tgNickController,
          hintText: AppLocalizations.of(context)!.translate('enter_telegram_username'),
          label: AppLocalizations.of(context)!.translate('telegram'),
        );

      case 'insta_login':
        return CustomTextField(
          controller: instaLoginController,
          hintText: AppLocalizations.of(context)!.translate('enter_instagram_username'),
          label: AppLocalizations.of(context)!.translate('instagram'),
        );

      case 'facebook_login':
        return CustomTextField(
          controller: facebookLoginController,
          hintText: AppLocalizations.of(context)!.translate('enter_facebook_username'),
          label: AppLocalizations.of(context)!.translate('Facebook'),
        );

      case 'email':
        return CustomTextField(
          controller: emailController,
          hintText: AppLocalizations.of(context)!.translate('enter_email'),
          label: AppLocalizations.of(context)!.translate('email'),
          keyboardType: TextInputType.emailAddress,
        );

      case 'lead_status_id':
        return LeadStatusEditpWidget(
          selectedStatus: _selectedStatuses?.toString(), // Проверяем, что это не null
          salesFunnelId: selectedSalesFunnel, // Убеждаемся, что передаем salesFunnelId
          onSelectStatus: (LeadStatus selectedStatusData) {
            setState(() {
              _selectedStatuses = selectedStatusData.id;
            });
          },
        );

      default:
        return SizedBox.shrink();
    }
  }

  // Метод для построения виджета на основе конфигурации поля
  Widget _buildFieldWidget(FieldConfiguration config) {
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
            final index = customFields.indexWhere(
                    (f) => f.directoryId == config.directoryId
            );
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
            final index = customFields.indexWhere(
                    (f) => f.directoryId == config.directoryId
            );
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

  Future<void> _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId, String? type}) async {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        showCustomSnackBar(context: context, message: 'Справочник уже добавлен', isSuccess: true);
        debugPrint("Directory with ID $directoryId already exists.");
        return;
      }
      try {
        // Сначала связываем справочник через API
        await _apiService.linkDirectory(
          directoryId: directoryId,
          modelType: 'lead',
          organizationId: _apiService.getSelectedOrganization().toString(),
        );

        showCustomSnackBar(context: context, message: 'Справочник успешно добавлен', isSuccess: true);

        // Добавляем справочник локально сразу после успешного связывания
        if (mounted) {
          setState(() {
            customFields.add(CustomField(
              fieldName: fieldName,
              uniqueId: Uuid().v4(),
              isDirectoryField: true,
              directoryId: directoryId,
              type: null,
              controller: TextEditingController(),
              isCustomField: false,
            ));
          });
        }

        // После успешного добавления справочника перезагружаем конфигурацию полей
        // Конфигурация с сервера уже будет содержать этот справочник
        if (mounted) {
          context.read<FieldConfigurationBloc>().add(
              FetchFieldConfiguration('leads')
          );
        }

        if (kDebugMode) {
          print('LeadAddScreen: Successfully linked directory: $fieldName');
        }
      } catch (e) {
        if (kDebugMode) {
          print('LeadAddScreen: Error linking directory: $e');
        }

        // Показываем ошибку пользователю
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString(),
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
      return;
    }

    // Если это не справочник, сначала добавляем через API
    try {
      await _apiService.addNewField(
        tableName: 'leads',
        fieldName: fieldName,
        fieldType: type ?? 'string',
      );

      // КЭШИРОВАНИЕ ОТКЛЮЧЕНО
      // // Очищаем кэш перед перезагрузкой
      // await ApiService().clearFieldConfigurationCacheForTable('leads');

      // После успешного добавления перезагружаем конфигурацию полей
      if (mounted) {
        context.read<FieldConfigurationBloc>().add(
            FetchFieldConfiguration('leads')
        );
      }

      // Добавляем поле локально только после успешного добавления на backend
      if (mounted) {
        setState(() {
          customFields.add(CustomField(
            fieldName: fieldName,
            uniqueId: Uuid().v4(),
            isDirectoryField: false,
            directoryId: null,
            type: type ?? 'string',
            controller: TextEditingController(),
            isCustomField: true,
          ));
        });
      }

      if (kDebugMode) {
        print('LeadAddScreen: Successfully added custom field: $fieldName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LeadAddScreen: Error adding custom field: $e');
      }

      // Показываем ошибку пользователю
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при добавлении поля: $e',
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
                if (type != null) {
                  _addCustomField(fieldName, type: type);
                }
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
    ) ?? false;
  }

  // Получение отображаемого названия поля
  String _getFieldDisplayName(FieldConfiguration config) {
    final localizations = AppLocalizations.of(context);
    switch (config.fieldName) {
      case 'name':
        return localizations!.translate('name_list');
      case 'phone':
        return localizations!.translate('phone');
      case 'manager_id':
        return localizations!.translate('manager');
      case 'region_id':
        return localizations!.translate('region');
      case 'source_id':
        return localizations!.translate('source');
      case 'wa_phone':
        return 'Whatsapp';
      case 'tg_nick':
        return localizations!.translate('telegram');
      case 'insta_login':
        return localizations!.translate('instagram');
      case 'facebook_login':
        return localizations!.translate('Facebook');
      case 'email':
        return localizations!.translate('email');
      case 'lead_status_id':
        return localizations!.translate('lead_status');
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

  // Режим настроек - отображение списка полей с возможностью изменения порядка
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
                    originalIsActive: config.originalIsActive,
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

              if (config.fieldName == 'lead_status_id') {
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
                                  originalIsActive: config.originalIsActive,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('new_lead'),
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
              onPressed: () {
                Navigator.pop(context, widget.statusId);
                context.read<LeadBloc>().add(FetchLeadStatuses());
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
                        int maxPosition = fieldConfigurations.isEmpty ? 0 : fieldConfigurations.map((e) => e.position).reduce((a, b) => a > b ? a : b);
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
                            originalIsActive: newFields[i].originalIsActive,
                            originalRequired: newFields[i].originalRequired,
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
                      originalIsActive: config.originalIsActive,
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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
        listener: (context, configState) {
          if (kDebugMode) {
            print('LeadAddScreen: FieldConfigurationBloc state changed: ${configState.runtimeType}');
          }

          if (configState is FieldConfigurationLoaded) {
            if (kDebugMode) {
              print('LeadAddScreen: Configuration loaded with ${configState.fields.length} fields');
            }
            // Используем порядок с сервера
            setState(() {
              fieldConfigurations = configState.fields;
              isConfigurationLoaded = true;
            });
          } else if (configState is FieldConfigurationError) {
            if (kDebugMode) {
              print('LeadAddScreen: Configuration error: ${configState.message}');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ошибка загрузки конфигурации: ${configState.message}',
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
        },
        builder: (context, configState) {
          if (kDebugMode) {
            print('LeadAddScreen: Building with state: ${configState.runtimeType}, isLoaded: $isConfigurationLoaded');
          }

          if (configState is FieldConfigurationLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Color(0xff1E2E52),
              ),
            );
          }

          if (!isConfigurationLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xff1E2E52),
                  ),
                  SizedBox(height: 16),
                  Text('Загрузка конфигурации...'),
                ],
              ),
            );
          }

          // Условное отображение: режим настроек или обычный режим
          if (isSettingsMode) {
            return _buildSettingsMode();
          }

          return BlocListener<LeadBloc, LeadState>(
            listener: (context, state) {
              if (state is LeadError) {
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
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    backgroundColor: Colors.red,
                    elevation: 0,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else if (state is LeadSuccess) {
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
                Navigator.pop(context, widget.statusId);
                context.read<LeadBloc>().add(FetchLeadStatuses());
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
                            // Динамическое построение полей на основе конфигурации с сервера
                            // Сортируем по position перед отображением
                            ...(() {
                              final sorted = [...fieldConfigurations]
                                ..sort((a, b) => a.position.compareTo(b.position));
                              
                              // Пропускаем поле lead_status_id
                              final filteredFields = sorted.where((config) {
                                return config.fieldName != 'lead_status_id';
                              }).toList();

                              return filteredFields.map((config) {
                                return Column(
                                  children: [
                                    _buildFieldWidget(config),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              }).toList();
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
                              Navigator.pop(context, widget.statusId);
                              context.read<LeadBloc>().add(FetchLeadStatuses());
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: BlocBuilder<LeadBloc, LeadState>(
                            builder: (context, state) {
                              if (state is LeadLoading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xff1E2E52),
                                  ),
                                );
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
          );
        },
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _createLead();
    } else {
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
    }
  }

  void _createLead() {
    if (_formKey.currentState!.validate()) {
      final String name = titleController.text;
      final String phone = selectedDialCode;
      final String? instaLogin =
      instaLoginController.text.isEmpty ? null : instaLoginController.text;
      final String? facebookLogin = facebookLoginController.text.isEmpty
          ? null
          : facebookLoginController.text;
      final String? tgNick =
      tgNickController.text.isEmpty ? null : tgNickController.text;
      final String? whatsapp =
      whatsappController.text.isEmpty || selectedDialCodeWhatsapp.isEmpty
          ? null
          : selectedDialCodeWhatsapp;
      final String? email =
      emailController.text.isEmpty ? null : emailController.text;
      final String? description =
      descriptionController.text.isEmpty ? null : descriptionController.text;

      // Собираем кастомные поля и справочники
      List<Map<String, dynamic>> customFieldMap = [];
      List<Map<String, int>> directoryValues = [];

      for (var field in customFields) {
        String fieldName = field.fieldName.trim();
        String fieldValue = field.controller.text.trim();
        String? fieldType = field.type;

        // ВАЖНО: Нормализуем тип поля - преобразуем "text" в "string"
        if (fieldType == 'text') {
          fieldType = 'string';
        }
        // Если type null, устанавливаем string по умолчанию
        fieldType ??= 'string';

        // Валидация для number
        if (fieldType == 'number' && fieldValue.isNotEmpty) {
          if (!RegExp(r'^\d+$').hasMatch(fieldValue)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate('enter_valid_number'),
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

        // Валидация для date и datetime
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
            'type': fieldType, // Теперь гарантированно один из: string, number, date, datetime
          });
        }
      }

      if (kDebugMode) {
        print('LeadAddScreen: Creating lead with data:');
        print('  customFields: $customFieldMap');
        print('  directoryValues: $directoryValues');
      }

      final localizations = AppLocalizations.of(context)!;

      bool isSystemManager = selectedManager == "-1";

      context.read<LeadBloc>().add(CreateLead(
        name: name,
        leadStatusId: _selectedStatuses ?? widget.statusId,
        phone: phone,
        regionId: selectedRegion != null ? int.parse(selectedRegion!) : null,
        managerId: !isSystemManager && selectedManager != null
            ? int.parse(selectedManager!)
            : null,
        sourceId: selectedSourceLead != null
            ? int.parse(selectedSourceLead!)
            : null,
        instaLogin: instaLogin,
        facebookLogin: facebookLogin,
        tgNick: tgNick,
        waPhone: whatsapp,
        birthday: null,
        email: email,
        description: description,
        customFields: customFieldMap,
        directoryValues: directoryValues,
        localizations: localizations,
        files: files,
        isSystemManager: isSystemManager,
      ));
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
  void dispose() {
    titleController.dispose();
    phoneController.dispose();
    instaLoginController.dispose();
    facebookLoginController.dispose();
    tgNickController.dispose();
    whatsappController.dispose();
    birthdayController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    for (var field in customFields) {
      field.controller.dispose();
    }
    super.dispose();
  }
}
