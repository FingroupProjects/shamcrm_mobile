import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_bloc.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_bloc.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_event.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/status_list.dart';
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

  String? selectedFile;
  String? fileName;
  String? fileSize;
  int? selectedPriority;
  String? selectedProject;
  int? selectedStatusId;
  List<String>? selectedUsers;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;

  final Map<int, String> priorityLevels = {
    1: 'Обычный',
    2: 'Важный',
    3: 'Срочный'
  };

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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          selectedFile = result.files.single.path!;
          fileName = result.files.single.name;
          fileSize =
              '${(result.files.single.size / 1024).toStringAsFixed(3)}KB';
        });
      }
    } catch (e) {
      print('Ошибка при выборе файла!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при выборе файла'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFileSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Файл',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF4F7FD)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fileName ?? 'Выберите файл',
                    style: TextStyle(
                      color: fileName != null
                          ? const Color(0xff1E2E52)
                          : const Color(0xff99A4BA),
                    ),
                  ),
                ),
                const Icon(
                  Icons.attach_file,
                  color: Color(0xff99A4BA),
                ),
              ],
            ),
          ),
        ),
        if (fileName != null) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Уровень приоритета',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white,
            ),
            child: DropdownButtonFormField<int>(
              value: selectedPriority ?? 1,
              items: priorityLevels.entries.map((entry) {
                final priorityColor = entry.key == 2
                    ? Colors.yellow
                    : entry.key == 3
                        ? Colors.red
                        : Colors.green;
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedPriority = newValue;
                });
              },
              decoration: _inputDecoration(),
            ),
          ),
        ),
      ],
    );
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
              buttonText: 'Отмена',
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
                        buttonText: 'Добавить',
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
          const SnackBar(
            content: Text('Пожалуйста, выберите статус задачи'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
            const SnackBar(
              content: Text('Дата начала не может быть позже даты завершения!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

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
                startDate: startDate,
                endDate: endDate,
                projectId: selectedProject != null
                    ? int.parse(selectedProject!)
                    : null,
                userId: selectedUsers?.map((id) => int.parse(id)).toList(),
                description: descriptionController.text,
                customFields: customFieldMap,
                filePath: selectedFile,
              ),
            );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании задачи!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все обязательные поля!'),
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
        title: const Text(
          'Новая задача',
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
                  state.message,
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
                  '${state.message}',
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

                      CustomTextField(
                        controller: nameController,
                        hintText: 'Введите название',
                        label: 'Название',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildPriorityDropdown(),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: startDateController,
                        label: 'От',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: endDateController,
                        label: 'До',
                        hasError: isEndDateInvalid,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
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
                      CustomTextField(
                        controller: descriptionController,
                        hintText: 'Введите описание',
                        label: 'Описание',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      _buildFileSelection(), // Добавляем виджет выбора файла
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
// Динамические поля с сервера
                      // ListView.builder(
                      //   shrinkWrap: true,
                      //   physics: NeverScrollableScrollPhysics(),
                      //   itemCount: customFields.length,
                      //   itemBuilder: (context, index) {
                      //     return CustomTextField(
                      //       controller: customFields[index].controller,
                      //       hintText: 'Введите значение',
                      //       label: customFields[index]
                      //           .fieldName, // Устанавливаем метку из данных
                      //       validator: (value) {
                      //         if (value == null || value.isEmpty) {
                      //           return 'Поле обязательно для заполнения';
                      //         }
                      //         return null;
                      //       },
                      //     );
                      //   },
                      // ),
                      const SizedBox(height: 8),

                      CustomButton(
                        buttonText: 'Добавить поле',
                        buttonColor: Color(0xff1E2E52),
                        textColor: Colors.white,
                        onPressed: _showAddFieldDialog,
                      ),
                      const SizedBox(height: 8),
                      // _buildFileSelection(), // Добавляем виджет выбора файла
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
          const SnackBar(
            content: Text('Введите корректную дату в формате ДД/ММ/ГГГГ'),
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
          const SnackBar(
            content: Text('Введите корректную дату в формате ДД/ММ/ГГГГ'),
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
            'Дата начала не может быть позже даты завершения!',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    TaskFile? fileData;
    if (selectedFile != null) {
      fileData = TaskFile(
        name: fileName ?? "unknown",
        size: fileSize ?? "0KB",
      );
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
    print("fileData: $fileData");

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
            const SnackBar(
              content: Text('Дата начала не может быть позже даты завершения!'),
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
                filePath: selectedFile,
              ),
            );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании задачи!'),
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
