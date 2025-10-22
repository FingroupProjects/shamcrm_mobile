
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
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
import 'package:crm_task_manager/models/directory_model.dart' as directory_model;
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_list_edit.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  final List<TaskCustomFieldsById> taskCustomFields;
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

  // Конфигурация полей
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;
  Map<String, Widget> fieldWidgets = {};
  List<String> fieldOrder = [];

  String? selectedProject;
  List<String>? selectedUsers;
  int? selectedPriority;
  int? _selectedStatuses;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
  bool _showAdditionalFields = false;
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  final ApiService _apiService = ApiService();
  List<TaskFiles> existingFiles = [];
  bool _shouldShowAdditionalFieldsButton = true;
  bool _canUpdateTask = false;
  bool _hasTaskCreateForMySelfPermission = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    
    // Загружаем конфигурацию после build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFieldConfiguration();
      }
    });
    
    _checkPermissions();
    _initializeControllers();
    _loadInitialData();
    _checkAdditionalFields();
    selectedPriority ??= 1;
    if (widget.files != null) {
      existingFiles = widget.files!;
      fileNames = existingFiles.map((file) => file.name).toList();
    }
    _fetchAndAddCustomFields();
  }

  Future<void> _checkPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userID');
      final int? userId = userIdString != null ? int.tryParse(userIdString) : null;

      final results = await Future.wait([
        _apiService.hasPermission('task.update'),
        _apiService.hasPermission('task.createForMySelf'),
      ]);

      setState(() {
        _canUpdateTask = results[0] as bool;
        _hasTaskCreateForMySelfPermission = results[1] as bool;
        _currentUserId = userId;
      });

      print('TaskEditScreen: Permissions - task.update: $_canUpdateTask, task.createForMySelf: $_hasTaskCreateForMySelfPermission, userID: $_currentUserId');
    } catch (e) {
      print('TaskEditScreen: Error checking permissions or userID: $e');
      setState(() {
        _canUpdateTask = false;
        _hasTaskCreateForMySelfPermission = false;
        _currentUserId = null;
      });
    }
  }

  void _fetchAndAddCustomFields() async {
    try {
      final directoryLinkData = await _apiService.getTaskDirectoryLinks();
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

  void _checkAdditionalFields() {
    bool hasDataInAdditionalFields = false;

    if (fileNames.isNotEmpty) {
      hasDataInAdditionalFields = true;
    }

    for (var field in customFields) {
      if (field.controller.text.isNotEmpty) {
        hasDataInAdditionalFields = true;
        break;
      }
    }

    if (hasDataInAdditionalFields) {
      setState(() {
        _showAdditionalFields = true;
      });
    } else {
      setState(() {
        _showAdditionalFields = false;
      });
    }

    if (fileNames.isNotEmpty &&
        customFields.every((field) => field.controller.text.isNotEmpty)) {
      setState(() {
        _shouldShowAdditionalFieldsButton = false;
      });
    } else {
      setState(() {
        _shouldShowAdditionalFieldsButton = true;
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
    
    if (!_canUpdateTask && _hasTaskCreateForMySelfPermission && _currentUserId != null) {
      selectedUsers = [_currentUserId.toString()];
    } else {
      selectedUsers = widget.user?.map((e) => e.toString()).toList() ?? [];
    }
    
    selectedPriority = widget.priority ?? 1;

    for (var customField in widget.taskCustomFields) {
      final controller = TextEditingController(text: customField.value);
      customFields.add(CustomField(
        fieldName: customField.key,
        controller: controller,
        uniqueId: Uuid().v4(),
        type: customField.type ?? 'string',
      ));
    }

    if (widget.directoryValues != null && widget.directoryValues!.isNotEmpty) {
      final seen = <String>{};
      final uniqueDirectoryValues = widget.directoryValues!.where((dirValue) {
        final key = '${dirValue.entry.directory.id}_${dirValue.entry.id}';
        return seen.add(key);
      }).toList();

      for (var dirValue in uniqueDirectoryValues) {
        final controller =
            TextEditingController(text: dirValue.entry.values['value'] ?? '');
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

  void _loadInitialData() {
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('TaskEditScreen: Loading field configuration');
    }
    
    if (mounted) {
      context.read<FieldConfigurationBloc>().add(
        FetchFieldConfiguration('tasks')
      );
    }
  }

  void _buildFieldsFromConfiguration() {
    if (kDebugMode) {
      print('TaskEditScreen: Building fields from configuration with ${fieldConfigurations.length} fields');
    }
    
    fieldWidgets.clear();
    fieldOrder.clear();

    for (var config in fieldConfigurations) {
      if (!config.isActive) {
        if (kDebugMode) {
          print('TaskEditScreen: Skipping inactive field: ${config.fieldName}');
        }
        continue;
      }

      Widget? widget = _buildFieldWidget(config);
      if (widget != null) {
        fieldWidgets[config.fieldName] = widget;
        fieldOrder.add(config.fieldName);
        
        if (kDebugMode) {
          print('TaskEditScreen: Added field widget for: ${config.fieldName} at position ${config.position}');
        }
      }
    }
    
    if (kDebugMode) {
      print('TaskEditScreen: Total field widgets: ${fieldWidgets.length}');
    }
  }

  Widget? _buildFieldWidget(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'name':
        return CustomTextFieldWithPriority(
          controller: nameController,
          hintText: AppLocalizations.of(context)!
              .translate('enter_title'),
          label: AppLocalizations.of(context)!
              .translate('event_name'),
          showPriority: true,
          isPrioritySelected: selectedPriority == 3,
          onPriorityChanged: (bool? value) {
            setState(() {
              selectedPriority = value == true ? 3 : 1;
            });
          },
          priorityText: AppLocalizations.of(context)!
              .translate('urgent'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!
                  .translate('field_required');
            }
            return null;
          },
        );
        
      case 'status_id':
        return TaskStatusEditWidget(
          selectedStatus: _selectedStatuses?.toString(),
          onSelectStatus: (TaskStatus selectedStatusData) {
            setState(() {
              _selectedStatuses = selectedStatusData.id;
            });
          },
        );
        
      case 'description':
        return CustomTextField(
          controller: descriptionController,
          hintText: AppLocalizations.of(context)!
              .translate('enter_description'),
          label: AppLocalizations.of(context)!
              .translate('description_list'),
          maxLines: 5,
          keyboardType: TextInputType.multiline,
        );
        
      case 'user_id':
        if (_canUpdateTask) {
          return UserMultiSelectWidget(
            selectedUsers: selectedUsers,
            onSelectUsers: (List<UserData> selectedUsersData) {
              setState(() {
                selectedUsers = selectedUsersData
                    .map((user) => user.id.toString())
                    .toList();
              });
            },
          );
        }
        return null;
        
      case 'project_id':
        return ProjectTaskGroupWidget(
          selectedProject: selectedProject,
          onSelectProject: (ProjectTask selectedProjectData) {
            setState(() {
              selectedProject = selectedProjectData.id.toString();
            });
          },
        );
        
      case 'end_date':
        return CustomTextFieldDate(
          controller: endDateController,
          label: AppLocalizations.of(context)!
              .translate('deadline'),
          hasError: isEndDateInvalid,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!
                  .translate('field_required');
            }
            return null;
          },
        );
        
      default:
        if (kDebugMode) {
          print('TaskEditScreen: Unknown field: ${config.fieldName}');
        }
        return null;
    }
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

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: InputBorder.none,
      filled: true,
      fillColor: Color(0xFFF4F7FD),
    );
  }

  void _toggleAdditionalFields() {
    setState(() {
      _showAdditionalFields = !_showAdditionalFields;
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
                                          buttonText:
                                              AppLocalizations.of(context)!
                                                  .translate('cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          buttonColor: Colors.red,
                                          textColor: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: CustomButton(
                                          buttonText:
                                              AppLocalizations.of(context)!
                                                  .translate('unpin'),
                                          onPressed: () async {
                                            if (isExistingFile) {
                                              try {
                                                final result = await _apiService
                                                    .deleteTaskFile(
                                                        existingFiles[index]
                                                            .id);
                                                if (result['result'] ==
                                                    'Success') {
                                                  setState(() {
                                                    existingFiles
                                                        .removeAt(index);
                                                    fileNames.removeAt(index);
                                                  });
                                                  Navigator.of(context)
                                                      .pop(true);
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
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 8),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                      elevation: 3,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 12,
                                                              horizontal: 16),
                                                      duration:
                                                          Duration(seconds: 3),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                Navigator.of(context)
                                                    .pop(false);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .translate(
                                                              'failed_to_delete_file'),
                                                      style: TextStyle(
                                                        fontFamily: 'Gilroy',
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    elevation: 3,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 12,
                                                            horizontal: 16),
                                                    duration:
                                                        Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            } else {
                                              setState(() {
                                                selectedFiles.removeAt(index -
                                                    existingFiles.length);
                                                fileNames.removeAt(index);
                                                fileSizes.removeAt(index -
                                                    existingFiles.length);
                                              });
                                              Navigator.of(context).pop(true);
                                            }
                                            _checkAdditionalFields();
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
        _checkAdditionalFields();
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
            AppLocalizations.of(context)!.translate('task_edit'),
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
        child: MultiBlocListener(
          listeners: [
            BlocListener<TaskBloc, TaskState>(
              listener: (context, state) {
                if (state is TaskSuccess) {
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
                  Navigator.pop(context, true);
                }
              },
            ),
            BlocListener<FieldConfigurationBloc, FieldConfigurationState>(
              listener: (context, configState) {
                if (kDebugMode) {
                  print('TaskEditScreen: FieldConfigurationBloc state changed: ${configState.runtimeType}');
                }
                
                if (configState is FieldConfigurationLoaded) {
                  if (kDebugMode) {
                    print('TaskEditScreen: Configuration loaded with ${configState.fields.length} fields');
                  }
                  
                  if (mounted) {
                    setState(() {
                      fieldConfigurations = configState.fields;
                      isConfigurationLoaded = true;
                    });
                    
                    _buildFieldsFromConfiguration();
                  }
                } else if (configState is FieldConfigurationError) {
                  if (kDebugMode) {
                    print('TaskEditScreen: Configuration error: ${configState.message}');
                  }
                  
                  if (mounted) {
                    setState(() {
                      isConfigurationLoaded = false;
                    });
                  }
                }
              },
            ),
          ],
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
                          // Используем конфигурацию если загружена
                          if (isConfigurationLoaded && fieldWidgets.isNotEmpty) ...[
                            for (var fieldName in fieldOrder) ...[
                              fieldWidgets[fieldName]!,
                              const SizedBox(height: 8),
                            ],
                          ] else ...[
                            // Fallback: показываем все поля как раньше
                            CustomTextFieldWithPriority(
                              controller: nameController,
                              hintText: AppLocalizations.of(context)!
                                  .translate('enter_title'),
                              label: AppLocalizations.of(context)!
                                  .translate('event_name'),
                              showPriority: true,
                              isPrioritySelected: selectedPriority == 3,
                              onPriorityChanged: (bool? value) {
                                setState(() {
                                  selectedPriority = value == true ? 3 : 1;
                                });
                              },
                              priorityText: AppLocalizations.of(context)!
                                  .translate('urgent'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .translate('field_required');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            TaskStatusEditWidget(
                              selectedStatus: _selectedStatuses?.toString(),
                              onSelectStatus: (TaskStatus selectedStatusData) {
                                setState(() {
                                  _selectedStatuses = selectedStatusData.id;
                                });
                              },
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
                            if (_canUpdateTask)
                              UserMultiSelectWidget(
                                selectedUsers: selectedUsers,
                                onSelectUsers: (List<UserData> selectedUsersData) {
                                  setState(() {
                                    selectedUsers = selectedUsersData
                                        .map((user) => user.id.toString())
                                        .toList();
                                  });
                                },
                              ),
                            const SizedBox(height: 8),
                            ProjectTaskGroupWidget(
                              selectedProject: selectedProject,
                              onSelectProject: (ProjectTask selectedProjectData) {
                                setState(() {
                                  selectedProject =
                                      selectedProjectData.id.toString();
                                });
                              },
                            ),
                            CustomTextFieldDate(
                              controller: endDateController,
                              label: AppLocalizations.of(context)!
                                  .translate('deadline'),
                              hasError: isEndDateInvalid,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .translate('field_required');
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (fileNames.isNotEmpty) _buildFileSelection(),
                          if (_shouldShowAdditionalFieldsButton &&
                              !_showAdditionalFields)
                            CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('additionally'),
                              buttonColor: Color(0xff1E2E52),
                              textColor: Colors.white,
                              onPressed: _toggleAdditionalFields,
                            ),
                          if (_showAdditionalFields) ...[
                            if (fileNames.isEmpty) _buildFileSelection(),
                            const SizedBox(height: 8),
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
                                          selectedField: null,
                                          onSelectField:
                                              (MainField selectedField) {
                                            setState(() {
                                              customFields[index] =
                                                  field.copyWith(
                                                entryId: selectedField.id,
                                                controller:
                                                    TextEditingController(
                                                        text: selectedField
                                                            .value),
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
                                              _checkAdditionalFields();
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
                                              _checkAdditionalFields();
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
                          buttonText:
                              AppLocalizations.of(context)!.translate('cancel'),
                          buttonColor: const Color(0xffF4F7FD),
                          textColor: Colors.black,
                          onPressed: () => Navigator.pop(context, null),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BlocBuilder<TaskBloc, TaskState>(
                          builder: (context, state) {
                            if (state is TaskLoading) {
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
                                  if (_formKey.currentState!.validate()) {
                                    DateTime? startDate;
                                    DateTime? endDate;
                                    try {
                                      if (startDateController.text.isNotEmpty) {
                                        startDate = DateFormat('dd/MM/yyyy')
                                            .parseStrict(
                                                startDateController.text);
                                      }
                                      if (endDateController.text.isNotEmpty) {
                                        endDate = DateFormat('dd/MM/yyyy')
                                            .parseStrict(
                                                endDateController.text);
                                      }
                                      if (startDate != null &&
                                          endDate != null &&
                                          startDate.isAfter(endDate)) {
                                        setState(() {
                                          isEndDateInvalid = true;
                                        });
                                        _showErrorSnackBar(
                                          AppLocalizations.of(context)!
                                              .translate(
                                                  'start_date_after_end_date'),
                                        );
                                        return;
                                      }

                                      List<Map<String, dynamic>>
                                          customFieldList = [];
                                      List<Map<String, int>> directoryValues =
                                          [];

                                      for (var field in customFields) {
                                        String fieldName =
                                            field.fieldName.trim();
                                        String fieldValue =
                                            field.controller.text.trim();
                                        String? fieldType = field.type;

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

                                        if ((fieldType == 'date' ||
                                                fieldType == 'datetime') &&
                                            fieldValue.isNotEmpty) {
                                          try {
                                            if (fieldType == 'date') {
                                              DateFormat('dd/MM/yyyy')
                                                  .parse(fieldValue);
                                            } else {
                                              DateFormat('dd/MM/yyyy HH:mm')
                                                  .parse(fieldValue);
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  AppLocalizations.of(context)!
                                                      .translate(
                                                          'enter_valid_${fieldType}'),
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

                                      context.read<TaskBloc>().add(
                                            UpdateTask(
                                              taskId: widget.taskId,
                                              name: nameController.text,
                                              statusId:
                                                  _selectedStatuses!.toInt(),
                                              taskStatusId:
                                                  _selectedStatuses!.toInt(),
                                              startDate: startDate,
                                              endDate: endDate,
                                              projectId: selectedProject != null
                                                  ? int.parse(selectedProject!)
                                                  : null,
                                              userId: selectedUsers != null
                                                  ? selectedUsers!
                                                      .map(
                                                          (id) => int.parse(id))
                                                      .toList()
                                                  : null,
                                              priority:
                                                  selectedPriority?.toString(),
                                              description:
                                                  descriptionController.text,
                                              customFields: customFieldList,
                                              filePaths: selectedFiles,
                                              directoryValues: directoryValues,
                                              localizations: localizations,
                                              existingFiles: existingFiles,
                                            ),
                                          );
                                    } catch (e) {
                                      _showErrorSnackBar(
                                        AppLocalizations.of(context)!
                                            .translate('error_format_date'),
                                      );
                                    }
                                  } else {
                                    _showErrorSnackBar(
                                      AppLocalizations.of(context)!
                                          .translate('fill_required_fields'),
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
  final String? type;

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
