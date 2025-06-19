import 'dart:io';

import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_list_edit.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_name_list.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:crm_task_manager/models/directory_model.dart' as directory_model;

class DealEditScreen extends StatefulWidget {
  final int dealId;
  final String dealName;
  final String? manager;
  final String? currency;
  final String? lead;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? description;
  final String? sum;
  final int statusId;
  final List<DealCustomFieldsById> dealCustomFields;
  final List<DirectoryValue>? directoryValues;
final List<DealFiles>? files; // Добавляем поле для файлов
  DealEditScreen({
    required this.dealId,
    required this.dealName,
    required this.statusId,
    this.manager,
    this.currency,
    this.lead,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.description,
    this.sum,
    required this.dealCustomFields,
    this.directoryValues,
    this.files, // Добавляем в конструктор
  });

  @override
  _DealEditScreenState createState() => _DealEditScreenState();
}

class _DealEditScreenState extends State<DealEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController sumController = TextEditingController();
  final ApiService _apiService = ApiService();

  int? _selectedStatuses;
  String? selectedManager;
  String? selectedLead;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
    List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  List<DealFiles> existingFiles = []; // Для хранения файлов с сервера
  List<String> newFiles = []; // Новый список для хранения путей к новым файлам

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
    _fetchAndAddDirectoryFields();
    // Инициализация файлов
    if (widget.files != null) {
      existingFiles = widget.files!;
      setState(() {
        fileNames.addAll(existingFiles.map((file) => file.name));
        fileSizes.addAll(existingFiles.map(
            (file) => '${(file.path.length / 1024).toStringAsFixed(3)}KB'));
        selectedFiles.addAll(existingFiles.map((file) => file.path));
      });
    }
  }
  

  void _initializeControllers() {
    titleController.text = widget.dealName;
    _selectedStatuses = widget.statusId;
    descriptionController.text = widget.description ?? '';
    selectedManager = widget.manager;
    selectedLead = widget.lead;
    startDateController.text = widget.startDate ?? '';
    endDateController.text = widget.endDate ?? '';
    sumController.text = widget.sum ?? '';
    print('SELECTEED LEAD _____________');
    print(selectedLead);

    for (var customField in widget.dealCustomFields) {
      customFields.add(CustomField(
        fieldName: customField.key,
        controller: TextEditingController(text: customField.value),
        uniqueId: Uuid().v4(),
      ));
    }

    if (widget.directoryValues != null && widget.directoryValues!.isNotEmpty) {
      final seen = <String>{};
      final uniqueDirectoryValues = widget.directoryValues!.where((dirValue) {
        final key = '${dirValue.entry.directory.id}_${dirValue.entry.id}';
        return seen.add(key);
      }).toList();

      for (var dirValue in uniqueDirectoryValues) {
        customFields.add(CustomField(
          fieldName: dirValue.entry.directory.name,
          controller: TextEditingController(text: dirValue.entry.values['value'] ?? ''),
          isDirectoryField: true,
          directoryId: dirValue.entry.directory.id,
          entryId: dirValue.entry.id,
          uniqueId: Uuid().v4(),
        ));
      }
    }
  }

  void _fetchAndAddDirectoryFields() async {
    try {
      final directoryLinkData = await _apiService.getDealDirectoryLinks();
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
        });
      }
    } catch (e) {
      print('Ошибка при получении данных справочников: $e');
    }
  }

  void _loadInitialData() {
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
  }

  void _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId}) {
    print('Добавление поля: $fieldName, isDirectory: $isDirectory, directoryId: $directoryId');
    if (isDirectory && directoryId != null) {
      // Проверяем, существует ли уже поле с таким directoryId
      bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        print('Справочник с directoryId: $directoryId уже добавлен, пропускаем');
        return; // Игнорируем добавление, если справочник уже существует
      }
    }
    setState(() {
      customFields.add(CustomField(
        fieldName: fieldName,
        controller: TextEditingController(),
        isDirectoryField: isDirectory,
        directoryId: directoryId,
        uniqueId: Uuid().v4(),
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
              onAddField: (fieldName) {
                _addCustomField(fieldName);
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
Future<void> _pickFile() async {
  try {
    print('DealEditScreen: Starting file picker');
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        if (file.path != null && file.name != null) {
          final filePath = file.path!;
          print('DealEditScreen: Picked file path: $filePath');
          final fileObject = File(filePath);
          if (await fileObject.exists()) {
            final fileName = file.name;
            // Проверяем, не существует ли файл уже в existingFiles или newFiles
            if (!existingFiles.any((f) => f.name == fileName) &&
                !newFiles.contains(filePath)) {
              final fileSize = await fileObject.length();
              print(
                  'DealEditScreen: Adding new file, name: $fileName, size: $fileSize bytes');
              setState(() {
                newFiles.add(filePath); // Добавляем в newFiles
                fileNames.add(fileName);
                fileSizes.add('${(fileSize / 1024).toStringAsFixed(3)}KB');
                selectedFiles.add(filePath); // Для отображения в UI
              });
            } else {
              print('DealEditScreen: File $fileName already exists, skipping');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate('file_already_exists'),
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
          } else {
            print('DealEditScreen: File does not exist at path: $filePath');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate('file_not_found'),
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
        } else {
          print(
              'DealEditScreen: File path or name is null for file: ${file.name}');
        }
      }
    } else {
      print('DealEditScreen: File picker cancelled or no files selected');
    }
  } catch (e, stackTrace) {
    print('DealEditScreen: Error picking file: $e');
    print('Stack trace: $stackTrace');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate('error_picking_file'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
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
            final isExistingFile = index < existingFiles.length;

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
                      onTap: () async {
                        bool? confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              title: Center(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .translate('delete_file'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                              ),
                              content: Text(
                                AppLocalizations.of(context)!
                                    .translate('confirm_delete_file'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
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
                                        buttonText: AppLocalizations.of(context)!
                                            .translate('cancel'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        buttonColor: Colors.red,
                                        textColor: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: CustomButton(
                                        buttonText: AppLocalizations.of(context)!
                                            .translate('unpin'),
                                        onPressed: () async {
                                          if (isExistingFile) {
                                            try {
                                              final result = await _apiService
                                                  .deleteTaskFile(
                                                      existingFiles[index].id);
                                              if (result['result'] ==
                                                  'Success') {
                                                setState(() {
                                                  existingFiles.removeAt(index);
                                                  fileNames.removeAt(index);
                                                  selectedFiles.remove(
                                                      existingFiles[index].path);
                                                });
                                                Navigator.of(context).pop(true);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .translate(
                                                              'file_deleted_successfully'),
                                                      style: TextStyle(
                                                        fontFamily: 'Gilroy',
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              Navigator.of(context).pop(false);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(context)!
                                                        .translate(
                                                            'failed_to_delete_file'),
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } else {
                                            setState(() {
                                              final newFileIndex =
                                                  index - existingFiles.length;
                                              newFiles.removeAt(newFileIndex);
                                              fileNames.removeAt(index);
                                              fileSizes.removeAt(newFileIndex);
                                              selectedFiles.removeAt(index);
                                            });
                                            Navigator.of(context).pop(true);
                                          }
                                        },
                                        buttonColor: Color(0xff1E2E52),
                                        textColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed != true) return;
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
        forceMaterialTransparency: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('edit_deal'),
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
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => MainFieldBloc()),
        ],
        child: BlocListener<DealBloc, DealState>(
          listener: (context, state) {
            if (state is DealError) {
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
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 3),
                ),
              );
            } else if (state is DealSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate('deal_updated_successfully'),
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
                          DealNameSelectionWidget(
                            selectedDealName: titleController.text,
                            onSelectDealName: (String dealName) {
                              setState(() {
                                titleController.text = dealName;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          DealStatusEditWidget(
                            selectedStatus: _selectedStatuses?.toString(),
                            onSelectStatus: (DealStatus selectedStatusData) {
                              setState(() {
                                _selectedStatuses = selectedStatusData.id;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          LeadRadioGroupWidget(
                            selectedLead: selectedLead,
                            onSelectLead: (LeadData selectedRegionData) {
                              setState(() {
                                selectedLead = selectedRegionData.id.toString();
                              });
                            },
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
                          CustomTextFieldDate(
                            controller: startDateController,
                            label: AppLocalizations.of(context)!.translate('start_date'),
                            withTime: false,
                          ),
                          const SizedBox(height: 8),
                          CustomTextFieldDate(
                            controller: endDateController,
                            label: AppLocalizations.of(context)!.translate('end_date'),
                            hasError: isEndDateInvalid,
                            withTime: false,
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: sumController,
                            hintText: AppLocalizations.of(context)!.translate('enter_summ'),
                            label: AppLocalizations.of(context)!.translate('summ'),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: descriptionController,
                            hintText: AppLocalizations.of(context)!.translate('enter_description'),
                            label: AppLocalizations.of(context)!.translate('description_list'),
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 8),
      _buildFileSelection(), // Добавляем выбор файлов
                          const SizedBox(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: customFields.length,
                            itemBuilder: (context, index) {
                              final field = customFields[index];
                              return Container(
                                key: ValueKey(field.uniqueId),
                                child: field.isDirectoryField && field.directoryId != null
                                    ? MainFieldDropdownWidget(
                                        directoryId: field.directoryId!,
                                        directoryName: field.fieldName,
                                        selectedField: null,
                                        onSelectField: (MainField selectedField) {
                                          setState(() {
                                            customFields[index] = field.copyWith(
                                              entryId: selectedField.id,
                                              controller: TextEditingController(text: selectedField.value),
                                            );
                                          });
                                        },
                                        controller: field.controller,
                                        onSelectEntryId: (int entryId) {
                                          setState(() {
                                            customFields[index] = field.copyWith(
                                              entryId: entryId,
                                            );
                                          });
                                        },
                                        onRemove: () {
                                          setState(() {
                                            customFields.removeAt(index);
                                          });
                                        },
                                        initialEntryId: field.entryId,
                                      )
                                    : CustomFieldWidget(
                                        fieldName: field.fieldName,
                                        valueController: field.controller,
                                        onRemove: () {
                                          setState(() {
                                            customFields.removeAt(index);
                                          });
                                        },
                                      ),
                              );
                            },
                          ),
                          CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('add_field'),
                            buttonColor: Color(0xff1E2E52),
                            textColor: Colors.white,
                            onPressed: _showAddFieldMenu,
                          ),
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
                        child: BlocBuilder<DealBloc, DealState>(
                          builder: (context, state) {
                            if (state is DealLoading) {
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
                                  if (_formKey.currentState!.validate() &&
                                      selectedManager != null &&
                                      selectedLead != null) {
                                    DateTime? parsedStartDate;
                                    DateTime? parsedEndDate;

                                    if (startDateController.text.isNotEmpty) {
                                      try {
                                        parsedStartDate = DateFormat('dd/MM/yyyy')
                                            .parseStrict(startDateController.text);
                                      } catch (e) {
                                        _showErrorSnackBar(
                                          AppLocalizations.of(context)!.translate('error_parsing_date'),
                                        );
                                        return;
                                      }
                                    }
                                    if (endDateController.text.isNotEmpty) {
                                      try {
                                        parsedEndDate = DateFormat('dd/MM/yyyy')
                                            .parseStrict(endDateController.text);
                                      } catch (e) {
                                        _showErrorSnackBar(
                                          AppLocalizations.of(context)!.translate('error_parsing_date'),
                                        );
                                        return;
                                      }
                                    }

                                    if (parsedStartDate != null &&
                                        parsedEndDate != null &&
                                        parsedStartDate.isAfter(parsedEndDate)) {
                                      setState(() {
                                        isEndDateInvalid = true;
                                      });
                                      _showErrorSnackBar(
                                        AppLocalizations.of(context)!
                                            .translate('start_date_after_end_date'),
                                      );
                                      return;
                                    }

                                    List<Map<String, String>> customFieldList = [];
                                    List<Map<String, int>> directoryValues = [];

                                    for (var field in customFields) {
                                      String fieldName = field.fieldName.trim();
                                      String fieldValue = field.controller.text.trim();

                                      if (field.isDirectoryField &&
                                          field.directoryId != null &&
                                          field.entryId != null) {
                                        directoryValues.add({
                                          'directory_id': field.directoryId!,
                                          'entry_id': field.entryId!,
                                        });
                                      } else if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
                                        customFieldList.add({fieldName: fieldValue});
                                      }
                                    }

                                    final localizations = AppLocalizations.of(context)!;
                                    context.read<DealBloc>().add(UpdateDeal(
                                          dealId: widget.dealId,
                                          name: titleController.text,
                                          dealStatusId: _selectedStatuses!.toInt(),
                                          managerId: selectedManager != null
                                              ? int.parse(selectedManager!)
                                              : null,
                                          leadId: selectedLead != null
                                              ? int.parse(selectedLead!)
                                              : null,
                                          description: descriptionController.text,
                                          startDate: parsedStartDate,
                                          endDate: parsedEndDate,
                                          sum: sumController.text,
                                          dealtypeId: 1,
                                          customFields: customFieldList,
                                          directoryValues: directoryValues,
                                          localizations: localizations,
                                          filePaths: newFiles, // Передаем новые файлы
                                          existingFiles: existingFiles, // Передаем существующие файлы
                                        ));
                                  } else {
                                    _showErrorSnackBar(
                                      AppLocalizations.of(context)!.translate('fill_required_fields'),
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
      ),
    );
  }
}

class CustomField {
  final String fieldName;
  final TextEditingController controller;
  final bool isDirectoryField;
  final int? directoryId;
  final int? entryId;
  final String uniqueId;

  CustomField({
    required this.fieldName,
    TextEditingController? controller,
    this.isDirectoryField = false,
    this.directoryId,
    this.entryId,
    required this.uniqueId,
  }) : controller = controller ?? TextEditingController();

  CustomField copyWith({
    String? fieldName,
    TextEditingController? controller,
    bool? isDirectoryField,
    int? directoryId,
    int? entryId,
    String? uniqueId,
  }) {
    return CustomField(
      fieldName: fieldName ?? this.fieldName,
      controller: controller ?? this.controller,
      isDirectoryField: isDirectoryField ?? this.isDirectoryField,
      directoryId: directoryId ?? this.directoryId,
      entryId: entryId ?? this.entryId,
      uniqueId: uniqueId ?? this.uniqueId,
    );
  }
}