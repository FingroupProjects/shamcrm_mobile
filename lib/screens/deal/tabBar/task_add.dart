import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_bloc.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_withPriority.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/status_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';

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
      final data = await ApiService().getCustomFields();
      if (data['result'] != null) {
        setState(() {
          customFields = data['result']
              .map<CustomField>((value) => CustomField(fieldName: value))
              .toList();
        });
      }
    } catch (e) {
      print('Ошибка!');
    }
  }

  void _setDefaultValues() {
    selectedPriority = 1;
    final now = DateTime.now();
    startDateController.text = DateFormat('dd/MM/yyyy').format(now);
  }

  void _addCustomField(String fieldName) {
    setState(() {
      customFields.add(CustomField(fieldName: fieldName));
    });
  }

  /// Переключает видимость дополнительных полей
  void _toggleAdditionalFields() {
    setState(() {
      _showAdditionalFields = true;
    });
  }

  void _showAddFieldDialog() {
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

// Функция выбора файла остается такой же как у вас
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            selectedFiles.add(file.path!);
            fileNames.add(file.name);
            fileSizes.add('${(file.size / 1024).toStringAsFixed(3)}KB');
          }
        });
      }
    } catch (e) {
      print('Ошибка при выборе файла!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.translate('file_selection_error')),
          backgroundColor: Colors.red,
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<TaskAddFromDealBloc, TaskAddFromDealState>(
              builder: (context, state) {
                return state is TaskAddFromDealLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff1E2E52),
                        ),
                      )
                    : CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('add'),
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
    if (_formKey.currentState!.validate()) {
      if (selectedStatusId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .translate('please_select_status_task')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        // final DateTime? startDate = startDateController.text.isNotEmpty
        //     ? DateFormat('dd/MM/yyyy').parse(startDateController.text)
        //     : null;

        final DateTime? endDate = endDateController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(endDateController.text)
            : null;

        // if (startDate != null &&
        //     endDate != null &&
        //     startDate.isAfter(endDate)) {
        //   setState(() {
        //     isEndDateInvalid = true;
        //   });
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(AppLocalizations.of(context)!
        //           .translate('start_date_after_end_date')),
        //       backgroundColor: Colors.red,
        //     ),
        //   );
        //   return;
        // }

        final List<Map<String, String>> customFieldMap = customFields
            .where((field) =>
                field.fieldName.isNotEmpty && field.controller.text.isNotEmpty)
            .map((field) => {field.fieldName: field.controller.text})
            .toList();

        context.read<TaskAddFromDealBloc>().add(
              CreateTaskFromDeal(
                dealId: widget.dealId,
                name: nameController.text,
                statusId: selectedStatusId!,
                taskStatusId: selectedStatusId!,
                priority: selectedPriority ?? 1,
                // startDate: startDate,
                endDate: endDate,
                projectId: selectedProject != null
                    ? int.parse(selectedProject!)
                    : null,
                userId: selectedUsers?.map((id) => int.parse(id)).toList(),
                description: descriptionController.text,
                customFields: customFieldMap,
                filePaths: selectedFiles, // Передаем список путей к файлам
              ),
            );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('error_create_task')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.translate('fill_required_fields')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: BlocListener<TaskAddFromDealBloc, TaskAddFromDealState>(
        listener: (context, state) {
          if (state is TaskAddFromDealError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate(state.message), // Локализация сообщения
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
                  AppLocalizations.of(context)!
                      .translate(state.message), // Локализация сообщения
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
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      CustomTextFieldWithPriority(
                        controller: nameController,
                        hintText: AppLocalizations.of(context)!
                            .translate('enter_name_list'),
                        label: AppLocalizations.of(context)!
                            .translate('name_list'),
                        showPriority: true,
                        isPrioritySelected: selectedPriority == 3,
                        onPriorityChanged: (bool? value) {
                          setState(() {
                            selectedPriority = value == true ? 3 : 1;
                          });
                        },
                        priorityText:
                            AppLocalizations.of(context)!.translate('urgent'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .translate('field_required');
                          }
                          return null;
                        },
                      ),
                      // const SizedBox(height: 8),
                      // CustomTextFieldDate(
                      //   controller: startDateController,
                      //   label: AppLocalizations.of(context)!.translate('from_list'),
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return AppLocalizations.of(context)!.translate('field_required');
                      //     }
                      //     return null;
                      //   },
                      // ),
                      const SizedBox(height: 8),
                      // Поле описания задачи
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
                      // Выбор пользователей
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
                      // Выбор проекта
                      ProjectTaskGroupWidget(
                        selectedProject: selectedProject,
                        onSelectProject: (ProjectTask selectedProjectData) {
                          setState(() {
                            selectedProject = selectedProjectData.id.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Дата окончания задачи
                      CustomTextFieldDate(
                        controller: endDateController,
                        label:
                            AppLocalizations.of(context)!.translate('deadline'),
                        hasError: isEndDateInvalid,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .translate('field_required');
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      // Если дополнительные поля скрыты – показываем кнопку "Дополнительно"
                      if (!_showAdditionalFields)
                        CustomButton(
                          buttonText: AppLocalizations.of(context)!
                              .translate('additionally'),
                          buttonColor: Color(0xff1E2E52),
                          textColor: Colors.white,
                          onPressed: () {
                            setState(() {
                              _showAdditionalFields = true;
                            });
                          },
                        )
                      else ...[
                        // Если дополнительные поля раскрыты, показываем виджет выбора файла,
                        // список дополнительных полей и кнопку для добавления нового поля
                        _buildFileSelection(),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: customFields.length,
                          itemBuilder: (context, index) {
                            return CustomFieldWidget(
                              fieldName: customFields[index].fieldName,
                              valueController: customFields[index].controller,
                              onRemove: () {
                                setState(() {
                                  customFields.removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                          buttonText: AppLocalizations.of(context)!
                              .translate('add_field'),
                          buttonColor: Color(0xff1E2E52),
                          textColor: Colors.white,
                          onPressed: _showAddFieldDialog,
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  void _createTask() {
    final String name = nameController.text;
    final String? startDateString =
        startDateController.text.isEmpty ? null : startDateController.text;
    final String? endDateString =
        endDateController.text.isEmpty ? null : endDateController.text;
    final String? description =
        descriptionController.text.isEmpty ? null : descriptionController.text;

    DateTime? startDate;
    if (startDateString != null && startDateString.isNotEmpty) {
      try {
        startDate = DateFormat('dd/MM/yyyy').parse(startDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('enter_valid_date')),
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
                AppLocalizations.of(context)!.translate('enter_valid_date')),
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
            AppLocalizations.of(context)!
                .translate('start_date_after_end_date'),
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
    // Создание задачи
    List<Map<String, String>> customFieldMap = [];
    for (var field in customFields) {
      String fieldName = field.fieldName.trim();
      String fieldValue = field.controller.text.trim();
      if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
        customFieldMap.add({fieldName: fieldValue});
      }
    }
    // print("fileData: $fileData");

    void _createTask() {
      try {
        final DateTime? startDate = startDateController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(startDateController.text)
            : null;

        final DateTime? endDate = endDateController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(endDateController.text)
            : null;

        if (startDate != null &&
            endDate != null &&
            startDate.isAfter(endDate)) {
          setState(() {
            isEndDateInvalid = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .translate('start_date_after_end_date')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        List<Map<String, String>> customFieldMap = customFields
            .where((field) => field.controller.text.isNotEmpty)
            .map((field) => {field.fieldName: field.controller.text})
            .toList();

        context.read<TaskAddFromDealBloc>().add(
              CreateTaskFromDeal(
                dealId: widget.dealId,
                name: nameController.text,
                statusId: selectedStatusId!,
                taskStatusId: selectedStatusId!,
                priority: selectedPriority,
                startDate: startDate,
                endDate: endDate,
                projectId: selectedProject != null
                    ? int.parse(selectedProject!)
                    : null,
                userId: selectedUsers?.map((id) => int.parse(id)).toList(),
                description: descriptionController.text,
                customFields: customFieldMap,
                filePaths: selectedFiles, // Передаем список путей к файлам
              ),
            );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('error_create_task')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    Widget _buildCustomFields() {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: customFields.length,
        itemBuilder: (context, index) {
          return CustomFieldWidget(
            fieldName: customFields[index].fieldName,
            valueController: customFields[index].controller,
            onRemove: () {
              setState(() {
                customFields.removeAt(index);
              });
            },
          );
        },
      );
    }
  }
}

class CustomField {
  final String fieldName;
  final TextEditingController controller = TextEditingController();

  CustomField({required this.fieldName});
}
