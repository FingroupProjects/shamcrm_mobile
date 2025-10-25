import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_lead_edit.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/lead_status_list.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_status_list_edit.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/price_type_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/sales_funnel_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:crm_task_manager/models/directory_model.dart' as directory_model;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class LeadEditScreen extends StatefulWidget {
  final int leadId;
  final String leadName;
  final String? region;
  final String? manager;
  final String? sourceId;
  final String? birthday;
  final String? createAt;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? whatsApp;
  final String? email;
  final String? description;
  final int statusId;
  final List<LeadCustomFieldsById> leadCustomFields;
  final List<DirectoryValue> directoryValues;
  final List<LeadFiles>? files;
  final String? priceTypeId;
  final String? priceTypeName;
  final String? salesFunnelId;

  LeadEditScreen({
    required this.leadId,
    required this.leadName,
    required this.statusId,
    this.region,
    this.manager,
    this.sourceId,
    this.birthday,
    this.createAt,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.whatsApp,
    this.email,
    this.description,
    required this.leadCustomFields,
    required this.directoryValues,
    this.files,
    this.priceTypeId,
    this.priceTypeName,
    this.salesFunnelId,
  });

  @override
  _LeadEditScreenState createState() => _LeadEditScreenState();
}

enum DuplicateOption { duplicate, transferAndDelete }

class _LeadEditScreenState extends State<LeadEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsAppController = TextEditingController();
  final TextEditingController instaLoginController = TextEditingController();
  final TextEditingController facebookLoginController = TextEditingController();
  final TextEditingController telegramController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int? _selectedStatuses;
  String? selectedRegion;
  String? selectedSource;
  String? selectedManager;
  String? _selectedPriceType;
  String selectedDialCode = '+992';
  String selectedWhatsAppDialCode = '+992';
  String? _fullWhatsAppNumber; // Новая переменная для хранения полного номера WhatsApp
  bool _isPhoneEdited = false;
  bool _isWhatsAppEdited = false;
  bool _showAdditionalFields = false;
  List<CustomField> customFields = [];
  final ApiService _apiService = ApiService();
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  List<LeadFiles> existingFiles = [];
  List<String> newFiles = [];
  String? selectedSalesFunnel;
  DuplicateOption? _duplicateOption;
  bool _showDuplicateOptions = false;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.leadName;
    _selectedStatuses = widget.statusId;
    _selectedPriceType = widget.priceTypeId;
    selectedSalesFunnel = widget.salesFunnelId;

    if (selectedSalesFunnel != null && selectedSalesFunnel != widget.salesFunnelId) {
      _showDuplicateOptions = true;
      _duplicateOption = DuplicateOption.duplicate;
    }

    if (widget.phone != null) {
      String phoneNumber = widget.phone!;
      for (var code in countryCodes) {
        if (phoneNumber.startsWith(code)) {
          setState(() {
            selectedDialCode = code;
            phoneController.text = phoneNumber.substring(code.length);
          });
          break;
        }
      }
      if (phoneController.text.isEmpty) {
        phoneController.text = phoneNumber;
      }
    }

    if (widget.whatsApp != null) {
      String whatsAppNumber = widget.whatsApp!;
      for (var code in countryCodes) {
        if (whatsAppNumber.startsWith(code)) {
          setState(() {
            selectedWhatsAppDialCode = code;
            whatsAppController.text = whatsAppNumber.substring(code.length);
            _fullWhatsAppNumber = whatsAppNumber; // Инициализируем полный номер
          });
          break;
        }
      }
      if (whatsAppController.text.isEmpty) {
        whatsAppController.text = whatsAppNumber;
        _fullWhatsAppNumber = whatsAppNumber;
      }
    }

    instaLoginController.text = widget.instagram ?? '';
    facebookLoginController.text = widget.facebook ?? '';
    telegramController.text = widget.telegram ?? '';
    birthdayController.text = widget.birthday ?? '';
    emailController.text = widget.email ?? '';
    descriptionController.text = widget.description ?? '';
    selectedRegion = widget.region;
    selectedSource = widget.sourceId;
    selectedManager = widget.manager;

    for (int i = 0; i < widget.leadCustomFields.length; i++) {
      var customField = widget.leadCustomFields[i];
      customFields.add(CustomField(
        fieldName: customField.key,
        controller: TextEditingController(text: customField.value),
        uniqueId: '${Uuid().v4()}_init_custom_$i',
        type: customField.type ?? 'string',
      ));
    }

    for (int i = 0; i < widget.directoryValues.length; i++) {
      var dirValue = widget.directoryValues[i];
      if (dirValue.entry != null) {
        customFields.add(CustomField(
          fieldName: dirValue.entry!.directory.name,
          controller: TextEditingController(text: dirValue.entry!.values['value'] ?? ''),
          isDirectoryField: true,
          directoryId: dirValue.entry!.directory.id,
          entryId: dirValue.entry!.id,
          uniqueId: '${Uuid().v4()}_init_dir_$i',
        ));
      } else {
        print('DirectoryValue with id ${dirValue.id} has null entry, skipping...');
      }
    }

    if (widget.files != null) {
      existingFiles = widget.files!;
      setState(() {
        fileNames.addAll(existingFiles.map((file) => file.name));
        fileSizes.addAll(existingFiles.map((file) => '${(file.path.length / 1024).toStringAsFixed(3)}KB'));
        selectedFiles.addAll(existingFiles.map((file) => file.path));
      });
    }
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
    context.read<LeadBloc>().add(FetchLeadStatuses());
    _fetchAndAddDirectoryFields();
  }

  @override
  void dispose() {
    titleController.dispose();
    phoneController.dispose();
    whatsAppController.dispose();
    instaLoginController.dispose();
    facebookLoginController.dispose();
    telegramController.dispose();
    birthdayController.dispose();
    createdAtController.dispose();
    emailController.dispose();
    authorController.dispose();
    descriptionController.dispose();

    for (var field in customFields) {
      field.dispose();
    }

    super.dispose();
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
        controller: TextEditingController(),
        isDirectoryField: isDirectory,
        directoryId: directoryId,
        uniqueId: '${Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}',
        type: type ?? 'string',
      ));
    });
  }

  void _fetchAndAddDirectoryFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final directoryLinkData = await _apiService.getLeadDirectoryLinks();
        if (directoryLinkData.data != null) {
          final List<CustomField> fieldsToAdd = [];

          for (var link in directoryLinkData.data!) {
            bool directoryExists = customFields.any((field) =>
                field.isDirectoryField && field.directoryId == link.directory.id);

            if (!directoryExists) {
              DirectoryValue? existingValue;
              try {
                existingValue = widget.directoryValues.firstWhere(
                  (dirValue) => dirValue.entry != null && dirValue.entry!.directory.id == link.directory.id,
                );
              } catch (e) {
                existingValue = null;
              }

              String controllerText = '';
              int? entryId;

              if (existingValue != null && existingValue.entry != null) {
                controllerText = existingValue.entry!.values['value'] ?? '';
                entryId = existingValue.entry!.id != 0 ? existingValue.entry!.id : null;
              }

              fieldsToAdd.add(CustomField(
                fieldName: link.directory.name,
                controller: TextEditingController(text: controllerText),
                isDirectoryField: true,
                directoryId: link.directory.id,
                entryId: entryId,
                uniqueId: '${Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}',
              ));
            }
          }

          if (fieldsToAdd.isNotEmpty) {
            setState(() {
              customFields.addAll(fieldsToAdd);
            });
          }
        }
      } catch (e) {
        print('Error in _fetchAndAddDirectoryFields: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('error_fetching_directories'),
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
    });
  }

  void _showAddFieldDialog() {
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
              onAddDirectory: (directory_model.Directory directory) {
                _addCustomField(directory.name, isDirectory: true, directoryId: directory.id);
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


/// Строит иконку файла или превью изображения
Widget _buildFileIcon(String fileName, String fileExtension) {
  // Список расширений изображений
  final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'];
  
  // Если файл - изображение, показываем превью
  if (imageExtensions.contains(fileExtension)) {
    final filePath = selectedFiles[fileNames.indexOf(fileName)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(filePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Если не удалось загрузить превью, показываем иконку
          return Image.asset(
            'assets/icons/files/file.png',
            width: 60,
            height: 60,
          );
        },
      ),
    );
  } else {
    // Для остальных типов файлов показываем иконку по расширению
    return Image.asset(
      'assets/icons/files/$fileExtension.png',
      width: 60,
      height: 60,
      errorBuilder: (context, error, stackTrace) {
        // Если нет иконки для этого типа, показываем общую иконку файла
        return Image.asset(
          'assets/icons/files/file.png',
          width: 60,
          height: 60,
        );
      },
    );
  }
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
            AppLocalizations.of(context)!.translate('edit_lead'),
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
      ),
      body: BlocListener<LeadBloc, LeadState>(
        listener: (context, state) {
          if (state is LeadError) {
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
                backgroundColor: Colors.red,
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
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
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
                        CustomTextField(
                          controller: titleController,
                          hintText: AppLocalizations.of(context)!.translate('enter_name_list'),
                          label: AppLocalizations.of(context)!.translate('name_list'),
                          validator: (value) => value!.isEmpty
                              ? AppLocalizations.of(context)!.translate('field_required')
                              : null,
                        ),
                        const SizedBox(height: 8),
                        LeadStatusEditpWidget(
  selectedStatus: _selectedStatuses?.toString(), // Проверяем, что это не null
  salesFunnelId: selectedSalesFunnel, // Убеждаемся, что передаем salesFunnelId
  onSelectStatus: (LeadStatus selectedStatusData) {
    setState(() {
      _selectedStatuses = selectedStatusData.id;
    });
  },
),
                        const SizedBox(height: 8),
                        CustomPhoneNumberInput(
                          controller: phoneController,
                          selectedDialCode: selectedDialCode,
                          onInputChanged: (String number) {
                            setState(() {
                              _isPhoneEdited = true;
                            });
                          },
                          label: AppLocalizations.of(context)!.translate('phone'),
                        ),
                        const SizedBox(height: 8),
                        ManagerRadioGroupWidget(
                          selectedManager: selectedManager,
                          onSelectManager: (ManagerData selectedManagerData) {
                            setState(() {
                              selectedManager = selectedManagerData.id.toString();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        RegionRadioGroupWidget(
                          selectedRegion: selectedRegion,
                          onSelectRegion: (RegionData selectedRegionData) {
                            setState(() {
                              selectedRegion = selectedRegionData.id.toString();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        SourceLeadWidget(
                          selectedSourceLead: selectedSource,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSource = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        SalesFunnelWidget(
                          selectedSalesFunnel: selectedSalesFunnel,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSalesFunnel = newValue;
                              _showDuplicateOptions = newValue != null && newValue != widget.salesFunnelId;
                              if (_showDuplicateOptions && _duplicateOption == null) {
                                _duplicateOption = DuplicateOption.duplicate;
                              } else if (!_showDuplicateOptions) {
                                _duplicateOption = null;
                              }
                            });
                          },
                        ),
                        if (_showDuplicateOptions) ...[
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate('duplicate_options'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                              RadioListTile<DuplicateOption>(
                                title: Text(
                                  AppLocalizations.of(context)!.translate('duplicate'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                                value: DuplicateOption.duplicate,
                                groupValue: _duplicateOption,
                                onChanged: (DuplicateOption? value) {
                                  setState(() {
                                    _duplicateOption = value;
                                  });
                                },
                                activeColor: Color(0xff4759FF),
                              ),
                              RadioListTile<DuplicateOption>(
                                title: Text(
                                  AppLocalizations.of(context)!.translate('transfer_and_delete'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                                value: DuplicateOption.transferAndDelete,
                                groupValue: _duplicateOption,
                                onChanged: (DuplicateOption? value) {
                                  setState(() {
                                    _duplicateOption = value;
                                  });
                                },
                                activeColor: Color(0xff4759FF),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        CustomPhoneNumberInput(
                          controller: whatsAppController,
                          selectedDialCode: selectedWhatsAppDialCode,
                          onInputChanged: (String number) {
                            setState(() {
                              _isWhatsAppEdited = true;
                              _fullWhatsAppNumber = number; // Сохраняем полный номер
                            });
                          },
                          label: 'WhatsApp',
                        ),
                        const SizedBox(height: 8),
                        if (!_showAdditionalFields)
                          CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('additionally'),
                            buttonColor: Color(0xff1E2E52),
                            textColor: Colors.white,
                            onPressed: () {
                              setState(() {
                                _showAdditionalFields = true;
                              });
                            },
                          )
                        else ...[
                          CustomTextField(
                            controller: instaLoginController,
                            hintText: AppLocalizations.of(context)!.translate('enter_instagram_username'),
                            label: AppLocalizations.of(context)!.translate('instagram'),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: facebookLoginController,
                            hintText: AppLocalizations.of(context)!.translate('enter_facebook_username'),
                            label: AppLocalizations.of(context)!.translate('Facebook'),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: telegramController,
                            hintText: AppLocalizations.of(context)!.translate('enter_telegram_username'),
                            label: AppLocalizations.of(context)!.translate('telegram'),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: emailController,
                            hintText: AppLocalizations.of(context)!.translate('enter_email'),
                            label: AppLocalizations.of(context)!.translate('email'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 8),
                          CustomTextFieldDate(
                            controller: birthdayController,
                            label: AppLocalizations.of(context)!.translate('birth_date'),
                            withTime: false,
                          ),
                          if (widget.priceTypeId != null) ...[
                            const SizedBox(height: 8),
                            PriceTypeWidget(
                              selectedPriceType: _selectedPriceType,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedPriceType = newValue;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: descriptionController,
                            hintText: AppLocalizations.of(context)!.translate('description_details_lead_edit'),
                            label: AppLocalizations.of(context)!.translate('description_details_lead_add'),
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 8),
                          _buildFileSelection(),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              for (int index = 0; index < customFields.length; index++)
                                Container(
                                  key: ValueKey('${customFields[index].uniqueId}_$index'),
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: customFields[index].isDirectoryField && customFields[index].directoryId != null
                                      ? MainFieldDropdownWidget(
                                          key: ValueKey('dropdown_${customFields[index].uniqueId}_$index'),
                                          directoryId: customFields[index].directoryId!,
                                          directoryName: customFields[index].fieldName,
                                          selectedField: customFields[index].entryId != null
                                              ? MainField(id: customFields[index].entryId!, value: customFields[index].controller.text)
                                              : null,
                                          onSelectField: (MainField selectedField) {
                                            setState(() {
                                              customFields[index] = customFields[index].copyWith(
                                                entryId: selectedField.id,
                                                controller: TextEditingController(text: selectedField.value),
                                              );
                                            });
                                          },
                                          controller: customFields[index].controller,
                                          onSelectEntryId: (int entryId) {
                                            setState(() {
                                              customFields[index] = customFields[index].copyWith(entryId: entryId);
                                            });
                                          },
                                          onRemove: () {
                                            setState(() {
                                              customFields[index].dispose();
                                              customFields.removeAt(index);
                                            });
                                          },
                                          initialEntryId: customFields[index].entryId,
                                        )
                                      : CustomFieldWidget(
                                          key: ValueKey('field_${customFields[index].uniqueId}_$index'),
                                          fieldName: customFields[index].fieldName,
                                          valueController: customFields[index].controller,
                                          onRemove: () {
                                            setState(() {
                                              customFields[index].dispose();
                                              customFields.removeAt(index);
                                            });
                                          },
                                          type: customFields[index].type,
                                        ),
                                ),
                            ],
                          ),
                          CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('add_field'),
                            buttonColor: Color(0xff1E2E52),
                            textColor: Colors.white,
                            onPressed: _showAddFieldDialog,
                          ),
                        ],
                        const SizedBox(height: 20),
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
                              buttonColor: const Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  print('whatsAppToSend: $_fullWhatsAppNumber'); // Логирование для отладки
                                  String phoneToSend = selectedDialCode + phoneController.text;
                                  String? whatsAppToSend = _fullWhatsAppNumber; // Используем полный номер

                                  DateTime? parsedBirthday;
                                  if (birthdayController.text.isNotEmpty) {
                                    try {
                                      parsedBirthday = DateFormat('dd/MM/yyyy').parseStrict(birthdayController.text);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)!.translate('error_enter_birth_day'),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  List<Map<String, dynamic>> customFieldList = [];
                                  List<Map<String, int>> directoryValues = [];

                                  for (var field in customFields) {
                                    String fieldName = field.fieldName.trim();
                                    String fieldValue = field.controller.text.trim();
                                    String? fieldType = field.type;

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
                                        DateTime parsedDate;
                                        if (fieldValue.contains('GMT+0500')) {
                                          parsedDate = DateFormat("EEE MMM dd yyyy HH:mm:ss 'GMT+0500 (Таджикистан)'").parse(fieldValue);
                                        } else {
                                          parsedDate = fieldType == 'date'
                                              ? DateFormat('dd/MM/yyyy').parse(fieldValue)
                                              : DateFormat('dd/MM/yyyy HH:mm').parse(fieldValue);
                                        }
                                        fieldValue = fieldType == 'date'
                                            ? DateFormat('dd/MM/yyyy').format(parsedDate)
                                            : DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!.translate('enter_valid_$fieldType'),
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
                                      customFieldList.add({
                                        'key': fieldName,
                                        'value': fieldValue,
                                        'type': fieldType ?? 'string',
                                      });
                                    }
                                  }

                                  String? duplicateValue;
                                  if (_showDuplicateOptions && _duplicateOption != null) {
                                    duplicateValue = _duplicateOption == DuplicateOption.duplicate ? "1" : "0";
                                    print('duplicateValue set to: $duplicateValue');
                                  } else {
                                    print('duplicateValue not set: _showDuplicateOptions=$_showDuplicateOptions, _duplicateOption=$_duplicateOption');
                                  }

                                  bool isSystemManager = selectedManager == "-1" || selectedManager == "0";
                                  final leadBloc = context.read<LeadBloc>();
                                  final localizations = AppLocalizations.of(context)!;
                                  leadBloc.add(UpdateLead(
                                    leadId: widget.leadId,
                                    name: titleController.text,
                                    phone: phoneToSend,
                                    waPhone: whatsAppToSend,
                                    regionId: selectedRegion != null ? int.tryParse(selectedRegion!) : null,
                                    managerId: !isSystemManager && selectedManager != null ? int.tryParse(selectedManager!) : null,
                                    sourseId: selectedSource != null ? int.tryParse(selectedSource!) : null,
                                    instaLogin: instaLoginController.text.isEmpty ? null : instaLoginController.text,
                                    facebookLogin: facebookLoginController.text.isEmpty ? null : facebookLoginController.text,
                                    tgNick: telegramController.text.isEmpty ? null : telegramController.text,
                                    birthday: parsedBirthday,
                                    email: emailController.text.isEmpty ? null : emailController.text,
                                    description: descriptionController.text.isEmpty ? null : descriptionController.text,
                                    leadStatusId: _selectedStatuses!.toInt(),
                                    customFields: customFieldList,
                                    directoryValues: directoryValues,
                                    localizations: localizations,
                                    isSystemManager: isSystemManager,
                                    filePaths: newFiles,
                                    existingFiles: existingFiles,
                                    priceTypeId: _selectedPriceType,
                                    salesFunnelId: selectedSalesFunnel,
                                    duplicate: duplicateValue,
                                  ));
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
                                      backgroundColor: Colors.red,
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}