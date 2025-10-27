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
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_list_edit.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
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
  final List<DealFiles>? files;
  final List<DealStatusById>? dealStatuses; // ✅ НОВОЕ: массив статусов

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
    this.files,
    this.dealStatuses, // ✅ ДОБАВЬТЕ ЭТУ СТРОКУ В КОНСТРУКТОР!
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
  List<DealFiles> existingFiles = [];
  List<String> newFiles = [];
    List<int> _selectedStatusIds = []; // ✅ НОВОЕ: список выбранных ID


  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
    _fetchAndAddDirectoryFields();
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

    for (var customField in widget.dealCustomFields) {
      customFields.add(CustomField(
        fieldName: customField.key,
        controller: TextEditingController(text: customField.value),
        uniqueId: Uuid().v4(),
        type: customField.type ?? 'string', // Инициализация с типом
      ));
    }
  // ✅ НОВОЕ: Инициализируем список ID
  if (widget.dealStatuses != null && widget.dealStatuses!.isNotEmpty) {
    _selectedStatusIds = widget.dealStatuses!.map((s) => s.id).toList();
  } else {
    _selectedStatusIds = [widget.statusId];
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
          controller:
              TextEditingController(text: dirValue.entry.values['value'] ?? ''),
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
          for (var link in directoryLinkData.data!) {
            bool directoryExists = customFields.any((field) =>
                field.isDirectoryField && field.directoryId == link.directory.id);
            if (!directoryExists) {
              customFields.add(CustomField(
                fieldName: link.directory.name,
                controller: TextEditingController(),
                isDirectoryField: true,
                directoryId: link.directory.id,
                uniqueId: Uuid().v4(),
              ));
            }
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar(
          AppLocalizations.of(context)!.translate('error_fetching_directories'));
    }
  }

  void _loadInitialData() {
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
  }

  void _addCustomField(String fieldName,
      {bool isDirectory = false, int? directoryId, String? type}) {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) =>
          field.isDirectoryField && field.directoryId == directoryId);
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
        uniqueId: Uuid().v4(),
        type: type ?? 'string',
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
              onAddDirectory: (directory_model.Directory directory) {
                _addCustomField(directory.name,
                    isDirectory: true, directoryId: directory.id);
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
  // ✅ ИСПРАВЛЕНИЕ: Вычисляем размер только для НОВЫХ файлов
  double totalSize = 0.0;
  
  // Считаем размер только новых файлов (которые есть локально)
  for (var filePath in newFiles) {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        totalSize += file.lengthSync() / (1024 * 1024);
      }
    } catch (e) {
      print('Error calculating file size: $e');
    }
  }

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
        newFiles.add(file.path);
      }
    });
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
            final filePath = selectedFiles[index];
            final fileExtension = fileName.split('.').last.toLowerCase();
            
       return Padding(
  padding: EdgeInsets.only(right: 24), // ✅ Увеличили с 16 до 24
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 100,
        child: Column(
          children: [
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
        right: -2,  // Оставляем как было
        top: -6,    // Оставляем как было
        child: GestureDetector(
          onTap: () {
            setState(() {
              final removedPath = selectedFiles[index];
              
              bool isExistingFile = existingFiles.any((f) => f.path == removedPath);
              
              if (isExistingFile) {
                existingFiles.removeWhere((f) => f.path == removedPath);
              } else {
                newFiles.remove(removedPath);
              }
              
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
              _showErrorSnackBar(
                  AppLocalizations.of(context)!.translate(state.message));
            } else if (state is DealSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!
                        .translate('deal_updated_successfully'),
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
    dealStatuses: widget.dealStatuses,
    onSelectStatus: (DealStatus selectedStatusData) {
      if (_selectedStatuses != selectedStatusData.id) {
        setState(() {
          _selectedStatuses = selectedStatusData.id;
        });
      }
    },
    onSelectMultipleStatuses: (List<int> selectedIds) {
      if (_selectedStatusIds.length != selectedIds.length ||
          !_selectedStatusIds.toSet().containsAll(selectedIds) ||
          !selectedIds.toSet().containsAll(_selectedStatusIds)) {
        setState(() {
          _selectedStatusIds = selectedIds;
        });
      }
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
                                selectedManager =
                                    selectedManagerData.id.toString();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          CustomTextFieldDate(
                            controller: startDateController,
                            label: AppLocalizations.of(context)!
                                .translate('start_date'),
                            withTime: false,
                          ),
                          const SizedBox(height: 8),
                          CustomTextFieldDate(
                            controller: endDateController,
                            label:
                                AppLocalizations.of(context)!.translate('end_date'),
                            hasError: isEndDateInvalid,
                            withTime: false,
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: sumController,
                            hintText: AppLocalizations.of(context)!
                                .translate('enter_summ'),
                            label:
                                AppLocalizations.of(context)!.translate('summ'),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\.,]')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: descriptionController,
                            hintText: AppLocalizations.of(context)!
                                .translate('enter_description'),
                            label: AppLocalizations.of(context)!
                                .translate('description_list'),
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 8),
                          _buildFileSelection(),
                          const SizedBox(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: customFields.length,
                            itemBuilder: (context, index) {
                              final field = customFields[index];
                              return Container(
                                key: ValueKey(field.uniqueId),
                                child: field.isDirectoryField &&
                                        field.directoryId != null
                                    ? MainFieldDropdownWidget(
                                        directoryId: field.directoryId!,
                                        directoryName: field.fieldName,
                                        selectedField: field.entryId != null
                                            ? MainField(
                                                id: field.entryId!,
                                                value: field.controller.text)
                                            : null,
                                        onSelectField:
                                            (MainField selectedField) {
                                          setState(() {
                                            customFields[index] =
                                                field.copyWith(
                                              entryId: selectedField.id,
                                              controller: TextEditingController(
                                                  text: selectedField.value),
                                            );
                                          });
                                        },
                                        controller: field.controller,
                                        onSelectEntryId: (int entryId) {
                                          setState(() {
                                            customFields[index] =
                                                field.copyWith(
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
                                        type: field.type,
                                      ),
                              );
                            },
                          ),
                          CustomButton(
                            buttonText: AppLocalizations.of(context)!
                                .translate('add_field'),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          buttonText: AppLocalizations.of(context)!
                              .translate('cancel'),
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
                                buttonText: AppLocalizations.of(context)!
                                    .translate('save'),
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
                                            .parseStrict(
                                                startDateController.text);
                                      } catch (e) {
                                        _showErrorSnackBar(
                                            AppLocalizations.of(context)!
                                                .translate('error_parsing_date'));
                                        return;
                                      }
                                    }
                                    if (endDateController.text.isNotEmpty) {
                                      try {
                                        parsedEndDate = DateFormat('dd/MM/yyyy')
                                            .parseStrict(endDateController.text);
                                      } catch (e) {
                                        _showErrorSnackBar(
                                            AppLocalizations.of(context)!
                                                .translate('error_parsing_date'));
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
                                          AppLocalizations.of(context)!.translate(
                                              'start_date_after_end_date'));
                                      return;
                                    }

                                    List<Map<String, dynamic>> customFieldList =
                                        [];
                                    List<Map<String, int>> directoryValues = [];

                                    for (var field in customFields) {
                                      String fieldName = field.fieldName.trim();
                                      String fieldValue =
                                          field.controller.text.trim();
                                      String? fieldType = field.type;

                                      // Валидация для number
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
                                          'type': fieldType ?? 'string',
                                        });
                                      }
                                    }

                                    final localizations =
                                        AppLocalizations.of(context)!;
                                    context.read<DealBloc>().add(UpdateDeal(
                                          dealId: widget.dealId,
                                          name: titleController.text,
                                          dealStatusId:
                                              _selectedStatuses!.toInt(),
                                          managerId: selectedManager != null
                                              ? int.parse(selectedManager!)
                                              : null,
                                          leadId: selectedLead != null
                                              ? int.parse(selectedLead!)
                                              : null,
                                          description:
                                              descriptionController.text.isEmpty
                                                  ? null
                                                  : descriptionController.text,
                                          startDate: parsedStartDate,
                                          endDate: parsedEndDate,
                                          sum: sumController.text.isEmpty
                                              ? null
                                              : sumController.text,
                                          dealtypeId: 1,
                                          customFields: customFieldList,
                                          directoryValues: directoryValues,
                                          localizations: localizations,
                                          filePaths: newFiles,
                                          existingFiles: existingFiles,
                                          dealStatusIds: _selectedStatusIds, // ✅ ПЕРЕДАЁМ МАССИВ
                                        ));
                                  } else {
                                    _showErrorSnackBar(
                                        AppLocalizations.of(context)!
                                            .translate('fill_required_fields'));
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
  final String? type; // Добавлено поле type

  CustomField({
    required this.fieldName,
    TextEditingController? controller,
    this.isDirectoryField = false,
    this.directoryId,
    this.entryId,
    required this.uniqueId,
    this.type,
  }) : controller = controller ?? TextEditingController();

  CustomField copyWith({
    String? fieldName,
    TextEditingController? controller,
    bool? isDirectoryField,
    int? directoryId,
    int? entryId,
    String? uniqueId,
    String? type,
  }) {
    return CustomField(
      fieldName: fieldName ?? this.fieldName,
      controller: controller ?? this.controller,
      isDirectoryField: isDirectoryField ?? this.isDirectoryField,
      directoryId: directoryId ?? this.directoryId,
      entryId: entryId ?? this.entryId,
      uniqueId: uniqueId ?? this.uniqueId,
      type: type ?? this.type,
    );
  }
}