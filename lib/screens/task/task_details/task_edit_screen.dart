import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class TaskEditScreen extends StatefulWidget {
  final int taskId;
  final String taskName;
  final String taskStatus;
  final int statusId;
  final String? project;
  final String? user;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int? priority;
  final String? fail; // Добавляем поле для файла

  TaskEditScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.project,
    this.user,
    this.startDate,
    this.endDate,
    this.description,
    this.priority,
    this.fail, // Добавляем в конструктор
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
  String? selectedFile; // Добавляем переменную для хранения выбранного файла
  String? selectedProject;
  String? selectedUser;
  int? selectedPriority;
  bool isUpdated = false;
  String? fail;
  String? fileName;  // Добавить
String? fileSize;  // Добавить

  final Map<int, String> priorityLevels = {
    1: 'Обычный',
    2: 'Критический',
    3: 'Сложный'
  };

  @override
  void initState() {
    super.initState();
    nameController.text = widget.taskName;
    startDateController.text = widget.startDate ?? '';
    endDateController.text = widget.endDate ?? '';
    descriptionController.text = widget.description ?? '';
    selectedProject = widget.project;
    selectedUser = widget.user;
    selectedPriority = widget.priority;
    selectedFile = widget.fail; // Инициализируем значение файла
    context.read<ProjectBloc>().add(FetchProjects());
    context.read<UserTaskBloc>().add(FetchUsers());
  }

  Future<void> _pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.single.path!;
        fileName = result.files.single.name;
        fileSize = '${(result.files.single.size / 1024).toStringAsFixed(3)}KB';
      });
    }
  } catch (e) {
    print('Ошибка при выборе файла: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ошибка при выборе файла'),
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
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Редактирование Задачи',
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
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TaskSuccess) {
            isUpdated = true;
            final updatedTask = {
              'taskName': nameController.text,
              'taskStatus': widget.taskStatus,
              'statusId': widget.statusId,
              'project': selectedProject,
              'user': selectedUser,
              'startDate': startDateController.text,
              'endDate': endDateController.text,
              'description': descriptionController.text,
              'priority': selectedPriority,
            };
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Задача успешно обновлена'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, updatedTask);
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
                      CustomTextField(
                        controller: nameController,
                        hintText: 'Введите название',
                        label: 'Название',
                        validator: (value) => value!.isEmpty
                            ? 'Поле обязательно для заполнения'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildPriorityDropdown(),
                      const SizedBox(height: 16),
                      CustomTextFieldDate(
                        controller: startDateController,
                        label: 'От',
                      ),
                      const SizedBox(height: 16),
                      CustomTextFieldDate(
                        controller: endDateController,
                        label: 'До',
                      ),
                      const SizedBox(height: 8),
                      ProjectWidget(
                        selectedProject: selectedProject,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedProject = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      UserWidget(
                        selectedUser: selectedUser,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedUser = newValue;
                          });
                        },
                      ),
                      
   Column(
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
                        : Colors.grey,
                  ),
                ),
              ),
              Icon(
                Icons.attach_file,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
      if (fileName != null) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Файл: ',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Здесь можно добавить логику предпросмотра файла
              },
              child: Text(
                fileName!,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  color: Color(0xff4759FF),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: 'Введите описание',
                        label: 'Описание',
                        maxLines: 5,
                      ),
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
                        buttonText: 'Отмена',
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        buttonText: 'Сохранить',
                        buttonColor: const Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            DateTime? startDate;
                            if (startDateController.text.isNotEmpty) {
                              try {
                                startDate = DateFormat('dd/MM/yyyy')
                                    .parse(startDateController.text);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ошибка: ${e.toString()}'),
                                  ),
                                );
                                return;
                              }
                            }

                            DateTime? endDate;
                            if (endDateController.text.isNotEmpty) {
                              try {
                                endDate = DateFormat('dd/MM/yyyy')
                                    .parse(endDateController.text);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ошибка: ${e.toString()}'),
                                  ),
                                );
                                return;
                              }
                            }
// Подготовка данных о файле
                  TaskFile? fileData;
                  if (selectedFile != null) {
                    fileData = TaskFile(
                        name: fileName ?? "unknown", size: fileSize ?? "0KB");
                            final taskBloc = context.read<TaskBloc>();
                            context.read<TaskBloc>().add(FetchTaskStatuses());
                            taskBloc.add(UpdateTask(
                              taskId: widget.taskId,
                              name: nameController.text,
                              statusId: widget.statusId,
                              taskStatusId: widget.statusId,
                              startDate: startDate,
                              endDate: endDate,
                              projectId: selectedProject != null
                                  ? int.parse(selectedProject!)
                                  : null,
                              userId: selectedUser != null
                                  ? int.parse(selectedUser!)
                                  : null,
                              priority: selectedPriority?.toString(),
                              description: descriptionController.text,
                              // file: fileData, // Добавляем файл в запрос
                              
                            ));
                          }
                        }
  }),
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
            color: Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white,
            ),
            child: DropdownButtonFormField<int>(
              value: selectedPriority,
              items: priorityLevels.entries.map((entry) {
                final priorityColor = entry.key == 2
                    ? Colors.red
                    : entry.key == 3
                        ? Colors.yellow
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
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedPriority = newValue;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}