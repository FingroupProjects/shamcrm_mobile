import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_withPriority.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/models/directory_model.dart' as directory_model;
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/directory_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskAddScreen extends StatefulWidget {
  final int statusId;

  const TaskAddScreen({Key? key, required this.statusId}) : super(key: key);

  @override
  _TaskAddScreenState createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  int? selectedPriority;
  String? selectedProject;
  String? selectedStatus;
  List<String>? selectedUsers;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
  bool _showAdditionalFields = false;
  bool _hasTaskCreatePermission = false;
  bool _hasTaskCreateForMySelfPermission = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
    _setDefaultValues();
    _fetchAndAddCustomFields();
    _checkPermissionsAndUser();
  }

  Future<void> _checkPermissionsAndUser() async {
    try {
      final apiService = ApiService();
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userID');

      // Параллельно проверяем разрешения
      final results = await Future.wait([
        apiService.hasPermission('task.create'),
        apiService.hasPermission('task.createForMySelf'),
      ]);

      setState(() {
        _hasTaskCreatePermission = results[0] as bool;
        _hasTaskCreateForMySelfPermission = results[1] as bool;
        _currentUserId = userIdString != null ? int.tryParse(userIdString) : null;
      });

      // Логируем для отладки
      print('TaskAddScreen: Permissions - task.create: $_hasTaskCreatePermission, task.createForMySelf: $_hasTaskCreateForMySelfPermission, userID: $_currentUserId');
    } catch (e) {
      print('TaskAddScreen: Ошибка при проверке разрешений или получении userID: $e');
      setState(() {
        _hasTaskCreatePermission = false;
        _hasTaskCreateForMySelfPermission = false;
        _currentUserId = null;
      });
    }
  }

  void _fetchAndAddCustomFields() async {
    try {
      final customFieldsData = await ApiService().getCustomFields();
      if (customFieldsData['result'] != null) {
        setState(() {
          customFields.addAll(customFieldsData['result'].map<CustomField>((value) {
            return CustomField(
              fieldName: value,
              controller: TextEditingController(),
              uniqueId: Uuid().v4(),
            );
          }).toList());
        });
      }

      final directoryLinkData = await ApiService().getTaskDirectoryLinks();
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
      print('TaskAddScreen: Error fetching custom fields: $e');
    }
  }

  void _setDefaultValues() {
    selectedPriority = 1;
    final now = DateTime.now();
    startDateController.text = DateFormat('dd/MM/yyyy').format(now);
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
        type: type,
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(12),
      ),
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
            AppLocalizations.of(context)!.translate('new_task'),
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
                context.read<TaskBloc>().add(FetchTaskStatuses());
              },
            ),
          ),
        ),
        leadingWidth: 40,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => MainFieldBloc()),
        ],
        child: BlocListener<TaskBloc, TaskState>(
          listener: (context, state) {
            if (state is TaskError) {
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
            } else if (state is TaskSuccess) {
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
              context.read<TaskBloc>().add(FetchTaskStatuses());
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
                          CustomTextFieldWithPriority(
                            controller: nameController,
                            hintText: AppLocalizations.of(context)!.translate('enter_title'),
                            label: AppLocalizations.of(context)!.translate('event_name'),
                            showPriority: true,
                            isPrioritySelected: selectedPriority == 3,
                            onPriorityChanged: (bool? value) {
                              setState(() {
                                selectedPriority = value == true ? 3 : 1;
                              });
                            },
                            priorityText: AppLocalizations.of(context)!.translate('urgent'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.translate('field_required');
                              }
                              return null;
                            },
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
                          // Условно отображаем UserMultiSelectWidget
                          if (_hasTaskCreatePermission || !_hasTaskCreateForMySelfPermission)
                            UserMultiSelectWidget(
                              selectedUsers: selectedUsers,
                              onSelectUsers: (List<UserData> selectedUsersData) {
                                setState(() {
                                  selectedUsers = selectedUsersData.map((user) => user.id.toString()).toList();
                                });
                              },
                            ),
                          const SizedBox(height: 8),
                          ProjectTaskGroupWidget(
                            selectedProject: selectedProject,
                            onSelectProject: (ProjectTask selectedProjectData) {
                              setState(() {
                                selectedProject = selectedProjectData.id.toString();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          CustomTextFieldDate(
                            controller: endDateController,
                            label: AppLocalizations.of(context)!.translate('deadline'),
                            hasError: isEndDateInvalid,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.translate('field_required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                            _buildFileSelection(),
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 8),
                            CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('add_field'),
                              buttonColor: Color(0xff1E2E52),
                              textColor: Colors.white,
                              onPressed: _showAddFieldMenu,
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              buttonText: AppLocalizations.of(context)!.translate('cancel'),
              buttonColor: const Color(0xffF4F7FD),
              textColor: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xff1E2E52),
                    ),
                  );
                } else {
                  return CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('add'),
                    buttonColor: const Color(0xff4759FF),
                    textColor: Colors.white,
                    onPressed: _submitForm,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_hasTaskCreatePermission && _hasTaskCreateForMySelfPermission && _currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('user_id_not_found'),
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
      _createTask();
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

  void _createTask() {
    final String name = nameController.text.trim();
    final String? startDateString = startDateController.text.isEmpty ? null : startDateController.text;
    final String? endDateString = endDateController.text.isEmpty ? null : endDateController.text;
    final String? description = descriptionController.text.isEmpty ? null : descriptionController.text;

    DateTime? startDate;
    if (startDateString != null && startDateString.isNotEmpty) {
      try {
        startDate = DateFormat('dd/MM/yyyy').parse(startDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('enter_valid_date'),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('enter_valid_date'),
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('start_date_after_end_date'),
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<TaskFile> files = [];
    for (int i = 0; i < selectedFiles.length; i++) {
      files.add(TaskFile(
        name: fileNames[i],
        size: fileSizes[i],
      ));
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
      if ((fieldType == 'date' || fieldType == 'datetime') && fieldValue.isNotEmpty) {
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
                AppLocalizations.of(context)!.translate('enter_valid_${fieldType}'),
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
        customFieldMap.add({
          'key': fieldName,
          'value': fieldValue,
          'type': fieldType ?? 'string',
        });
      }
    }

    final localizations = AppLocalizations.of(context)!;

    // Определяем userId в зависимости от разрешений
    List<int>? userIds;
    if (!_hasTaskCreatePermission && _hasTaskCreateForMySelfPermission && _currentUserId != null) {
      // Если есть только task.createForMySelf, отправляем ID текущего пользователя
      userIds = [_currentUserId!];
    } else {
      // Иначе используем выбранных пользователей из UserMultiSelectWidget
      userIds = selectedUsers != null ? selectedUsers!.map((id) => int.parse(id)).toList() : null;
    }

    context.read<TaskBloc>().add(CreateTask(
      name: name,
      statusId: widget.statusId,
      taskStatusId: widget.statusId,
      startDate: startDate,
      endDate: endDate,
      projectId: selectedProject != null ? int.parse(selectedProject!) : null,
      userId: userIds,
      priority: selectedPriority,
      description: description,
      customFields: customFieldMap,
      filePaths: selectedFiles,
      directoryValues: directoryValues,
      localizations: localizations,
    ));
  }
}