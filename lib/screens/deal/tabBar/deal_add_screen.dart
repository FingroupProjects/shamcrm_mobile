import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
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
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_name_list.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../lead/tabBar/lead_details/custom_field_model.dart';

class DealAddScreen extends StatefulWidget {
  final int statusId;

  DealAddScreen({required this.statusId});

  @override
  _DealAddScreenState createState() => _DealAddScreenState();
}

class _DealAddScreenState extends State<DealAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController sumController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedManager;
  String? selectedLead;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
  bool isTitleInvalid = false;
  bool isManagerInvalid = false;
  bool _showAdditionalFields = false;
  bool isManagerManuallySelected = false;
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  
  // Конфигурация полей с сервера
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  @override
  void initState() {
    super.initState();
    //print('DealAddScreen: initState started');
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    //print('DealAddScreen: Dispatched GetAllManagerEv and GetAllLeadEv');
    _fetchAndAddCustomFields();
    
    // ВАЖНО: Добавляем небольшую задержку чтобы context был готов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
  }
  
  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('DealAddScreen: Loading field configuration for deals');
    }
    context.read<FieldConfigurationBloc>().add(FetchFieldConfiguration('deals'));
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

      case 'lead_id':
        return LeadWithManager(
          selectedLead: selectedLead,
          onSelectLead: (LeadData selectedLeadData) {
            if (selectedLead == selectedLeadData.id.toString()) {
              return;
            }
            setState(() {
              selectedLead = selectedLeadData.id.toString();
              if (!isManagerManuallySelected && selectedLeadData.managerId != null) {
                final managerBlocState = context.read<GetAllManagerBloc>().state;
                if (managerBlocState is GetAllManagerSuccess) {
                  final managers = managerBlocState.dataManager.result ?? [];
                  try {
                    final matchingManager = managers.firstWhere(
                      (manager) => manager.id == selectedLeadData.managerId,
                    );
                    selectedManager = matchingManager.id.toString();
                  } catch (e) {
                    selectedManager = null;
                  }
                }
              }
            });
          },
        );

      case 'manager_id':
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
        onRemove: () {}, // Пустая функция, так как серверные поля нельзя удалить
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
        onRemove: () {},
      );
    }

    // Иначе это стандартное системное поле
    return _buildStandardField(config);
  }

 Future<void> _pickFile() async {
  // Вычисляем текущий общий размер файлов
  double totalSize = selectedFiles.fold<double>(
    0.0,
    (sum, file) => sum + File(file).lengthSync() / (1024 * 1024),
  );

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
Widget _buildFileIcon(String fileName, String fileExtension) {
  // Проверяем, является ли файл изображением
  final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'];
  
  if (imageExtensions.contains(fileExtension)) {
    // Для изображений показываем превью
    final filePath = selectedFiles[fileNames.indexOf(fileName)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(filePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/icons/files/file.png', width: 60, height: 60);
        },
      ),
    );
  } else {
    // Для остальных файлов показываем иконку по типу
    return Image.asset(
      'assets/icons/files/$fileExtension.png',
      width: 60,
      height: 60,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('assets/icons/files/file.png', width: 60, height: 60);
      },
    );
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
            // Кнопка добавления файла
            if (fileNames.isEmpty || index == fileNames.length) {
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
                        // НОВОЕ: Используем метод _buildFileIcon для показа превью или иконки
                        _buildFileIcon(fileName, fileExtension),
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
                        setState(() {
                          selectedFiles.removeAt(index);
                          fileNames.removeAt(index);
                          fileSizes.removeAt(index);
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

  void _fetchAndAddCustomFields() async {
    try {
      //print('DealAddScreen: Fetching custom fields and directories');
      final customFieldsData = await ApiService().getCustomFieldsdeal();
      if (customFieldsData['result'] != null) {
        setState(() {
          customFields.addAll(customFieldsData['result'].map<CustomField>((value) {
            return CustomField(
              fieldName: value,
              controller: TextEditingController(),
              uniqueId: Uuid().v4(),
            );
          }).toList());
          //print('DealAddScreen: Added custom fields: ${customFields.length}');
        });
      }

      final directoryLinkData = await ApiService().getDealDirectoryLinks();
      if (directoryLinkData.data != null) {
        setState(() {
          customFields.addAll(directoryLinkData.data!.map<CustomField>((link) {
            return CustomField(
              fieldName: link.directory.name,
              controller: TextEditingController(),
              isDirectoryField: true,
              directoryId: link.directory.id,
              uniqueId: Uuid().v4(),
            );
          }).toList());
          //print('DealAddScreen: Added directory fields: ${customFields.length}');
        });
      }
    } catch (e) {
      //print('DealAddScreen: Error fetching custom fields: $e');
    }
  }

  void _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId, String? type}) {
    //print('DealAddScreen: Adding field: $fieldName, isDirectory: $isDirectory, directoryId: $directoryId, type: $type');
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        //print('DealAddScreen: Directory with ID $directoryId already exists, skipping');
        return;
      }
    }
    setState(() {
      customFields.add(CustomField(
        fieldName: fieldName,
        controller: TextEditingController(),
        isDirectoryField: isDirectory,
        directoryId: directoryId,
        type: type,
        uniqueId: Uuid().v4(),
      ));
      //print('DealAddScreen: Added custom field: $fieldName');
    });
  }

  void _showAddFieldMenu() {
    //print('DealAddScreen: Showing add field menu');
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(300, 650, 200, 300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      //print('DealAddScreen: Menu selected value: $value');
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
              onAddDirectory: (directory) {
                //print('DealAddScreen: Selected directory: ${directory.name}, id: ${directory.id}');
                _addCustomField(directory.name, isDirectory: true, directoryId: directory.id);
                ApiService().linkDirectory(
                  directoryId: directory.id,
                  modelType: 'deal',
                  organizationId: ApiService().getSelectedOrganization().toString(),
                ).then((_) {
                  //print('DealAddScreen: Directory linked successfully');
                }).catchError((e) {
                  //print('DealAddScreen: Error linking directory: $e');
                });
              },
            );
          },
        );
      }
    });
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
                //print('DealAddScreen: Back button pressed');
                Navigator.pop(context, widget.statusId);
                context.read<DealBloc>().add(FetchDealStatuses());
              },
            ),
          ),
        ),
        leadingWidth: 40,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
        listener: (context, configState) {
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
            print('DealAddScreen: Building with state: ${configState.runtimeType}, isLoaded: $isConfigurationLoaded');
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

          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => MainFieldBloc()),
            ],
            child: BlocListener<DealBloc, DealState>(
              listener: (context, state) {
                //print('DealAddScreen: DealBloc state changed: $state');
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
                      //print('DealAddScreen: Unfocusing on tap');
                      FocusScope.of(context).unfocus();
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Динамическое построение полей на основе конфигурации с сервера
                          ...fieldConfigurations.map((config) {
                            return Column(
                              children: [
                                _buildFieldWidget(config),
                                const SizedBox(height: 15),
                              ],
                            );
                          }).toList(),
                          
                          const SizedBox(height: 16),
                          if (!_showAdditionalFields)
                            CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('additionally'),
                              buttonColor: Color(0xff1E2E52),
                              textColor: Colors.white,
                              onPressed: () {
                                setState(() {
                                  _showAdditionalFields = true;
                                  //print('DealAddScreen: Additional fields toggled');
                                });
                              },
                            )
                          else ...[
                            _buildFileSelection(),
                            const SizedBox(height: 15),
                            
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
                                                controller: TextEditingController(text: selectedField.value),
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
                                          onRemove: () {
                                            setState(() {
                                              customFields.remove(field);
                                            });
                                          },
                                        )
                                      : CustomFieldWidget(
                                          fieldName: field.fieldName,
                                          valueController: field.controller,
                                          onRemove: () {
                                            setState(() {
                                              customFields.remove(field);
                                            });
                                          },
                                          type: field.type,
                                          isDirectory: false,
                                        ),
                                  const SizedBox(height: 15),
                                ],
                              );
                            }).toList(),
                            
                            // Кнопка добавления дополнительных полей
                            CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('add_field'),
                              buttonColor: Color(0xff1E2E52),
                              textColor: Colors.white,
                              onPressed: _showAddFieldMenu,
                            ),
                          ],
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
        },
      ),
    );
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
          'type': fieldType, // Теперь гарантированно один из: string, number, date, datetime
        });
        //print('DealAddScreen: Added custom field: $fieldName = $fieldValue, type: $fieldType');
      }
    }

    final localizations = AppLocalizations.of(context)!;

    context.read<DealBloc>().add(CreateDeal(
      name: name,
      dealStatusId: widget.statusId,
      managerId: int.parse(selectedManager!),
      leadId: int.parse(selectedLead!),
      dealtypeId: 1,
      startDate: startDate,
      endDate: endDate,
      sum: sum,
      description: description,
      customFields: customFieldMap,
      directoryValues: directoryValues,
      filePaths: selectedFiles,
      localizations: localizations,
    ));
    //print('DealAddScreen: Dispatched CreateDeal event');
  }
}