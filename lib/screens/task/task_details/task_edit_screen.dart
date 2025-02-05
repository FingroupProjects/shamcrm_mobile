import 'package:crm_task_manager/api/service/api_service.dart';
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
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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
  final List<TaskFiles>? files; // вместо String? taskFile

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

  String? selectedProject;
  List<String>? selectedUsers;
  int? selectedPriority;
  List<CustomField> customFields = [];
  // Добавьте эти переменные в класс _TaskEditScreenState
  // String? selectedFile;
  // String? fileName;
  // String? fileSize;
  bool isEndDateInvalid = false;
  bool _showAdditionalFields = false;
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
    selectedPriority ??=
        1; // или другое значение по умолчанию из priorityLevels
    // Преобразуем список TaskFiles в список имен файлов   
  if (widget.files != null) {
    fileNames = widget.files!.map((file) => file.name).toList();
  }
}

  void _initializeControllers() {
    nameController.text = widget.taskName;
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
    selectedUsers = widget.user?.map((e) => e.toString()).toList() ?? [];

    selectedPriority = widget.priority ?? 1;
    for (var customField in widget.taskCustomFields) {
      customFields.add(CustomField(fieldName: customField.key)
        ..controller.text = customField.value);
    }
  }

  void _loadInitialData() {
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
    context.read<TaskBloc>().add(FetchTaskStatuses());
  }

  void _addCustomField(String fieldName) {
    setState(() {
      customFields.add(CustomField(fieldName: fieldName));
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

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: InputBorder.none,
      filled: true,
      fillColor: Color(0xFFF4F7FD),
    );
  }

// Функция переключения отображения дополнительных полей
  void _toggleAdditionalFields() {
    setState(() {
      _showAdditionalFields = !_showAdditionalFields;
    });
  }
  // Widget _buildLabel(String label) {
  //   return Text(
  //     label,
  //     style: TextStyle(
  //       fontSize: 14,
  //       fontWeight: FontWeight.w500,
  //       fontFamily: 'Gilroy',
  //       color: Color(0xff1E2E52),
  //     ),
  //   );
  // }

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
            // Если есть файлы, показываем их + кнопку добавления, иначе только кнопку
            itemCount: fileNames.isEmpty ? 1 : fileNames.length + 1,
            itemBuilder: (context, index) {
              // Кнопка добавления (показывается либо одна, либо в конце списка)
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

              // Отображение выбранного файла
              final fileName = fileNames[index];
              final fileExtension = fileName.split('.').last.toLowerCase();

              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Container(
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

//  Widget _buildPriorityDropdown() {
//           final Map<int, String> priorityLevels = {
//               1: AppLocalizations.of(context)!.translate('normal'),
//               2: AppLocalizations.of(context)!.translate('important'),
//               3: AppLocalizations.of(context)!.translate('urgent'),
//             };
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           AppLocalizations.of(context)!.translate('priority_level'),
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             fontFamily: 'Gilroy',
//             color: Color(0xff1E2E52),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFFF4F7FD),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Theme(
//             data: Theme.of(context).copyWith(
//               canvasColor: Colors.white,
//             ),
//             child: DropdownButtonFormField<int>(
//               value: selectedPriority,
//               items: priorityLevels.entries.map((entry) {
//                 Color priorityColor;
//                 switch (entry.key) {
//                   case 3:
//                     priorityColor = Colors.red;
//                     break;
//                   case 2:
//                     priorityColor = Colors.yellow;
//                     break;
//                   default:
//                     priorityColor = Colors.green;
//                 }

//                 return DropdownMenuItem<int>(
//                   value: entry.key,
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 10,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           color: priorityColor,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         entry.value,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                           fontFamily: 'Gilroy',
//                           color: Color(0xff1E2E52),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//               onChanged: (int? newValue) {
//                 if (newValue != null) {
//                   setState(() {
//                     selectedPriority = newValue;
//                   });
//                 }
//               },
//               decoration: _inputDecoration(),
//               validator: (value) =>
//                   value == null ? AppLocalizations.of(context)!.translate('field_required') : null,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('task_edit'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          // if (state is TaskError) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text(state.message),
          //       duration: const Duration(seconds: 3),
          //       backgroundColor: Colors.red,
          //     ),
          //   );
          // } else
          if (state is TaskSuccess) {
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
                duration: Duration(seconds: 3), // Установлено на 2 секунды
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 8),
                      // Здесь могут располагаться другие поля (например, выбор проекта, пользователей и т.д.)
                      CustomTextField(
                        controller: descriptionController,
                        hintText: AppLocalizations.of(context)!
                            .translate('enter_description'),
                        label: AppLocalizations.of(context)!
                            .translate('description_list'),
                        maxLines: 5,
                      ),
                      // const SizedBox(height: 16),
                      // _buildPriorityDropdown(),
                      // const SizedBox(height: 16),
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
                      UserMultiSelectWidget(
                        selectedUsers: selectedUsers,
                        onSelectUsers: (List<UserData> selectedUsersData) {
                          setState(() {
                            // Update selected user IDs
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
                            selectedProject = selectedProjectData.id.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
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
                      // Если дополнительные поля ещё не показаны, выводим кнопку "Дополнительно"
                      if (!_showAdditionalFields)
                        CustomButton(
                          buttonText: AppLocalizations.of(context)!
                              .translate('additionally'),
                          buttonColor: Color(0xff1E2E52),
                          textColor: Colors.white,
                          onPressed: _toggleAdditionalFields,
                        ),
                      // Если дополнительные поля раскрыты, отображаем их
                      if (_showAdditionalFields) ...[
                        _buildFileSelection(),
                        const SizedBox(height: 20),
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
                        CustomButton(
                          buttonText: AppLocalizations.of(context)!
                              .translate('add_field'),
                          buttonColor: Color(0xff1E2E52),
                          textColor: Colors.white,
                          onPressed: _showAddFieldDialog,
                        ),
                      ],
                      // Другие элементы формы можно разместить здесь
                    ],
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
                                    // // Пример разбора дат (при наличии соответствующих контроллеров)
                                    // if (startDateController.text.isNotEmpty) {
                                    //   startDate = DateFormat('dd/MM/yyyy')
                                    //       .parseStrict(startDateController.text);
                                    // }
                                    if (endDateController.text.isNotEmpty) {
                                      endDate = DateFormat('dd/MM/yyyy')
                                          .parseStrict(endDateController.text);
                                    }
                                    if (startDate != null &&
                                        endDate != null &&
                                        startDate.isAfter(endDate)) {
                                      setState(() {
                                        isEndDateInvalid = true;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)!
                                                .translate(
                                                    'start_date_after_end_date'),
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    List<Map<String, String>> customFieldList =
                                        [];
                                    for (var field in customFields) {
                                      String fieldName = field.fieldName.trim();
                                      String fieldValue =
                                          field.controller.text.trim();
                                      if (fieldName.isNotEmpty &&
                                          fieldValue.isNotEmpty) {
                                        customFieldList
                                            .add({fieldName: fieldValue});
                                      }
                                    }
                                    final localizations =
                                        AppLocalizations.of(context)!;

                                    context.read<TaskBloc>().add(
                                          UpdateTask(
                                            taskId: widget.taskId,
                                            name: nameController.text,
                                            statusId: widget.statusId,
                                            taskStatusId: widget.statusId,
                                            startDate: startDate,
                                            endDate: endDate,
                                            projectId: selectedProject != null
                                                ? int.parse(selectedProject!)
                                                : null,
                                            userId: selectedUsers != null
                                                ? selectedUsers!
                                                    .map((id) => int.parse(id))
                                                    .toList()
                                                : null,
                                            priority:
                                                selectedPriority?.toString(),
                                            description:
                                                descriptionController.text,
                                            customFields: customFieldList,
                                            filePaths:
                                                selectedFiles, // Передаем список путей к файлам
                                            localizations: localizations,
                                          ),
                                        );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)!
                                              .translate('error_format_date'),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .translate('fill_required_fields'),
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.red,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      duration: Duration(seconds: 3),
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
