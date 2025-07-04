import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_bloc.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_state.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_withPriority.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/status_list.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TaskAddFromDeal extends StatefulWidget {
  final int dealId;

  const TaskAddFromDeal({Key? key, required this.dealId}) : super(key: key);

  @override
  _TaskAddFromDealState createState() => _TaskAddFromDealState();
}

class _TaskAddFromDealState extends State<TaskAddFromDeal> {
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
  int? selectedStatusId;
  List<String>? selectedUsers;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
  bool _showAdditionalFields = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
    _setDefaultValues();
    _fetchAndAddCustomFields();
  }

  void _fetchAndAddCustomFields() async {
    try {
      //print('TaskAddFromDeal: Fetching custom fields and directories');
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
          //print('TaskAddFromDeal: Added custom fields: ${customFields.length}');
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
          //print('TaskAddFromDeal: Added directory fields: ${customFields.length}');
        });
      }
    } catch (e) {
      //print('TaskAddFromDeal: Error fetching custom fields: $e');
    }
  }

  void _setDefaultValues() {
    selectedPriority = 1;
    final now = DateTime.now();
    startDateController.text = DateFormat('dd/MM/yyyy').format(now);
  }

  void _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId, String? type}) {
    //print('TaskAddFromDeal: Adding field: $fieldName, isDirectory: $isDirectory, directoryId: $directoryId, type: $type');
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        //print('TaskAddFromDeal: Directory with ID $directoryId already exists, skipping');
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
      //print('TaskAddFromDeal: Added custom field: $fieldName');
    });
  }

  void _showAddFieldMenu() {
    //print('TaskAddFromDeal: Showing add field menu');
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
      //print('TaskAddFromDeal: Menu selected value: $value');
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
                //print('TaskAddFromDeal: Selected directory: ${directory.name}, id: ${directory.id}');
                _addCustomField(directory.name, isDirectory: true, directoryId: directory.id);
                ApiService().linkDirectory(
                  directoryId: directory.id,
                  modelType: 'task',
                  organizationId: ApiService().getSelectedOrganization().toString(),
                ).then((_) {
                  //print('TaskAddFromDeal: Directory linked to task model');
                }).catchError((e) {
                  //print('TaskAddFromDeal: Error linking directory: $e');
                });
              },
            );
          },
        );
      }
    });
  }

  Widget _buildFileSelection() {
    //print('TaskAddFromDeal: Building file selection with ${fileNames.length} files');
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
              //print('TaskAddFromDeal: Displaying file: $fileName');
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
                            //print('TaskAddFromDeal: Removed file: $fileName');
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
      //print('TaskAddFromDeal: FilePicker result: ${result?.files.map((f) => f.name).toList()}');
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
          //print('TaskAddFromDeal: File size exceeds 50MB limit');
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
          //print('TaskAddFromDeal: Added files: $fileNames');
        });
      }
    } catch (e) {
      //print('TaskAddFromDeal: Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('file_selection_error')),
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

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              buttonText: AppLocalizations.of(context)!.translate('cancel'),
              buttonColor: const Color(0xffF4F7FD),
              textColor: Colors.black,
              onPressed: () {
                //print('TaskAddFromDeal: Cancel button pressed');
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<TaskAddFromDealBloc, TaskAddFromDealState>(
              builder: (context, state) {
                //print('TaskAddFromDeal: TaskAddFromDealBloc builder state: $state');
                return state is TaskAddFromDealLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff1E2E52),
                        ),
                      )
                    : CustomButton(
                        buttonText: AppLocalizations.of(context)!.translate('add'),
                        buttonColor: const Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: _submitForm,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    //print('TaskAddFromDeal: Submitting form with name: ${nameController.text}, statusId: $selectedStatusId');
    if (_formKey.currentState!.validate()) {
      if (selectedStatusId == null) {
        //print('TaskAddFromDeal: Status not selected');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('please_select_status_task')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _createTask();
    } else {
      //print('TaskAddFromDeal: Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('fill_required_fields')),
          backgroundColor: Colors.red,
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
        //print('TaskAddFromDeal: Invalid start date format: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('enter_valid_date')),
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
        //print('TaskAddFromDeal: Invalid end date format: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('enter_valid_date')),
          ),
        );
        return;
      }
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      setState(() {
        isEndDateInvalid = true;
      });
      //print('TaskAddFromDeal: Start date is after end date');
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
        //print('TaskAddFromDeal: Added directory value: ${field.directoryId}, ${field.entryId}');
      } else if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
        customFieldMap.add({
          'key': fieldName,
          'value': fieldValue,
          'type': fieldType ?? 'string',
        });
        //print('TaskAddFromDeal: Added custom field: $fieldName = $fieldValue, type: $fieldType');
      }
    }

    context.read<TaskAddFromDealBloc>().add(
          CreateTaskFromDeal(
            dealId: widget.dealId,
            name: name,
            statusId: selectedStatusId!,
            taskStatusId: selectedStatusId!,
            priority: selectedPriority ?? 1,
            startDate: startDate,
            endDate: endDate,
            projectId: selectedProject != null ? int.parse(selectedProject!) : null,
            userId: selectedUsers?.map((id) => int.parse(id)).toList(),
            description: description,
            customFields: customFieldMap,
            filePaths: selectedFiles,
            directoryValues: directoryValues,
          ),
    );
    //print('TaskAddFromDeal: Dispatched CreateTaskFromDeal event');
  }

  @override
  Widget build(BuildContext context) {
    //print('TaskAddFromDeal: Building with selectedProject: $selectedProject, selectedUsers: $selectedUsers');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            //print('TaskAddFromDeal: Back button pressed');
            Navigator.pop(context, widget.dealId);
            context.read<TaskAddFromDealBloc>().add(FetchTaskDealStatuses());
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('new_task'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => MainFieldBloc()),
        ],
        child: BlocListener<TaskAddFromDealBloc, TaskAddFromDealState>(
          listener: (context, state) {
            //print('TaskAddFromDeal: TaskAddFromDealBloc state changed: $state');
            if (state is TaskAddFromDealError) {
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
            } else if (state is TaskAddFromDealSuccess) {
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
              Navigator.pop(context, widget.dealId);
              context.read<TaskAddFromDealBloc>().add(FetchTaskDealStatuses());
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      //print('TaskAddFromDeal: Unfocusing on tap');
                      FocusScope.of(context).unfocus();
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TaskStatusRadioGroupWidget(
                            selectedStatus: selectedStatusId?.toString(),
                            onSelectStatus: (TaskStatus selectedStatusData) {
                              setState(() {
                                selectedStatusId = selectedStatusData.id;
                                //print('TaskAddFromDeal: Selected status: ${selectedStatusData.id}');
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          CustomTextFieldWithPriority(
                            controller: nameController,
                            hintText: AppLocalizations.of(context)!.translate('enter_category_name'),
                            label: AppLocalizations.of(context)!.translate('category_name'),
                            showPriority: true,
                            isPrioritySelected: selectedPriority == 3,
                            onPriorityChanged: (bool? value) {
                              setState(() {
                                selectedPriority = value == true ? 3 : 1;
                                //print('TaskAddFromDeal: Priority changed to: $selectedPriority');
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
                          UserMultiSelectWidget(
                            selectedUsers: selectedUsers,
                            onSelectUsers: (List<UserData> selectedUsersData) {
                              setState(() {
                                selectedUsers = selectedUsersData.map((user) => user.id.toString()).toList();
                                //print('TaskAddFromDeal: Selected users: $selectedUsers');
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          ProjectTaskGroupWidget(
                            selectedProject: selectedProject,
                            onSelectProject: (ProjectTask selectedProjectData) {
                              setState(() {
                                selectedProject = selectedProjectData.id.toString();
                                //print('TaskAddFromDeal: Selected project: ${selectedProjectData.id}');
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
                                  //print('TaskAddFromDeal: Additional fields toggled');
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
                                              //print('TaskAddFromDeal: Directory field updated: ${field.fieldName}');
                                            });
                                          },
                                          controller: field.controller,
                                          onSelectEntryId: (int entryId) {
                                            setState(() {
                                              customFields[index] = field.copyWith(
                                                entryId: entryId,
                                              );
                                              //print('TaskAddFromDeal: Directory entry ID updated: $entryId');
                                            });
                                          },
                                          onRemove: () {
                                            setState(() {
                                              customFields.removeAt(index);
                                              //print('TaskAddFromDeal: Removed custom field at index: $index');
                                            });
                                          },
                                        )
                                      : CustomFieldWidget(
                                          fieldName: field.fieldName,
                                          valueController: field.controller,
                                          onRemove: () {
                                            setState(() {
                                              customFields.removeAt(index);
                                              //print('TaskAddFromDeal: Removed custom field: ${field.fieldName}');
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
}



  // Widget _buildPriorityDropdown() {
  //   final Map<int, String> priorityLevels = {
  //       1: AppLocalizations.of(context)!.translate('normal'),
  //       2: AppLocalizations.of(context)!.translate('important'),
  //       3: AppLocalizations.of(context)!.translate('urgent'),
  //     };
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         AppLocalizations.of(context)!.translate('priority_level'),
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w500,
  //           fontFamily: 'Gilroy',
  //           color: Color(0xff1E2E52),
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       Container(
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF4F7FD),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Theme(
  //           data: Theme.of(context).copyWith(
  //             canvasColor: Colors.white,
  //           ),
  //           child: DropdownButtonFormField<int>(
  //             value: selectedPriority ?? 1,
  //             items: priorityLevels.entries.map((entry) {
  //               final priorityColor = entry.key == 2
  //                   ? Colors.yellow
  //                   : entry.key == 3
  //                       ? Colors.red
  //                       : Colors.green;
  //               return DropdownMenuItem(
  //                 value: entry.key,
  //                 child: Row(
  //                   children: [
  //                     Container(
  //                       width: 10,
  //                       height: 10,
  //                       decoration: BoxDecoration(
  //                         color: priorityColor,
  //                         shape: BoxShape.circle,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       entry.value,
  //                       style: const TextStyle(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w500,
  //                         fontFamily: 'Gilroy',
  //                         color: Color(0xff1E2E52),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               );
  //             }).toList(),
  //             onChanged: (int? newValue) {
  //               setState(() {
  //                 selectedPriority = newValue;
  //               });
  //             },
  //             decoration: _inputDecoration(),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }