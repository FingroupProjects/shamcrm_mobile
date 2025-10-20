  import 'package:crm_task_manager/api/service/api_service.dart';
  import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
  import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
  import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
  import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
  import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
  import 'package:crm_task_manager/bloc/lead/lead_state.dart';
  import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
  import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart';
  import 'package:crm_task_manager/custom_widget/custom_button.dart';
  import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
  import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
  import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
  import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
  import 'package:crm_task_manager/models/main_field_model.dart';
  import 'package:crm_task_manager/models/manager_model.dart';
  import 'package:crm_task_manager/models/page_2/field_configuration.dart';
  import 'package:crm_task_manager/models/region_model.dart';
  import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
  import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
  import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
  import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
  import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
  import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
  import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
  import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
  import 'package:crm_task_manager/bloc/lead/lead_event.dart';
  import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
  import 'package:intl/intl.dart';
  import 'package:uuid/uuid.dart';
  import 'dart:io';
  import 'package:file_picker/file_picker.dart';
  import 'package:flutter/foundation.dart';

  class LeadAddScreen extends StatefulWidget {
    final int statusId;

    LeadAddScreen({required this.statusId});

    @override
    _LeadAddScreenState createState() => _LeadAddScreenState();
  }

  class _LeadAddScreenState extends State<LeadAddScreen> {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    
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
    
    // Кастомные поля
    List<CustomField> customFields = [];
    
    // Конфигурация полей с сервера
    List<FieldConfiguration> fieldConfigurations = [];
    bool isConfigurationLoaded = false;
    
    // Переменные для файлов
    List<String> selectedFiles = [];
    List<String> fileNames = [];
    List<String> fileSizes = [];

    @override
    void initState() {
      super.initState();
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
            validator: config.required ? (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.translate('field_required');
              }
              return null;
            } : null,
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
      try {
        FilePickerResult? result =
            await FilePicker.platform.pickFiles(allowMultiple: true);

        if (result != null) {
          double totalSize = selectedFiles.fold<double>(
            0.0,
            (sum, file) => sum + File(file).lengthSync() / (1024 * 1024),
          );

          double newFilesSize = result.files.fold<double>(
            0.0,
            (sum, file) => sum + file.size / (1024 * 1024),
          );

          if (totalSize + newFilesSize > 50) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate('file_size_too_large'),
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

          setState(() {
            for (var file in result.files) {
              selectedFiles.add(file.path!);
              fileNames.add(file.name);
              fileSizes.add('${(file.size / 1024).toStringAsFixed(3)}KB');
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка при выборе файла!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    void _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId, String? type}) {
      if (isDirectory && directoryId != null) {
        bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
        if (directoryExists) {
          return;
        }
      }
      setState(() {
        customFields.add(CustomField(
          fieldName: fieldName,
          uniqueId: Uuid().v4(),
          isDirectoryField: isDirectory,
          directoryId: directoryId,
          type: type,
          controller: TextEditingController(),
          isCustomField: !isDirectory,
        ));
      });
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
                onAddDirectory: (directory) {
                  _addCustomField(directory.name, isDirectory: true, directoryId: directory.id);
                  ApiService().linkDirectory(
                    directoryId: directory.id,
                    modelType: 'lead',
                    organizationId: ApiService().getSelectedOrganization().toString(),
                  ).then((_) {
                    // Успешно связано
                  }).catchError((e) {
                    // Ошибка
                  });
                },
              );
            },
          );
        }
      });
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
                              ...fieldConfigurations.map((config) {
                                return Column(
                                  children: [
                                    _buildFieldWidget(config),
                                    const SizedBox(height: 15),
                                  ],
                                );
                              }).toList(),
                              
                              // Описание (всегда показываем)
                              CustomTextField(
                                controller: descriptionController,
                                hintText: AppLocalizations.of(context)!
                                    .translate('description_details_lead_edit'),
                                label: AppLocalizations.of(context)!
                                    .translate('description_details_lead_add'),
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                              ),
                              const SizedBox(height: 15),
                              
                              // Файлы (всегда показываем)
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
                                buttonText: AppLocalizations.of(context)!
                                    .translate('add_field'),
                                buttonColor: Color(0xff1E2E52),
                                textColor: Colors.white,
                                onPressed: _showAddFieldMenu,
                              ),
                              const SizedBox(height: 20),
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
      leadStatusId: widget.statusId,
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
      filePaths: selectedFiles,
      isSystemManager: isSystemManager,
    ));
  }
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