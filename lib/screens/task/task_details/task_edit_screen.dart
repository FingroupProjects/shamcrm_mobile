import 'package:crm_task_manager/bloc/manager/manager_bloc.dart';
import 'package:crm_task_manager/bloc/manager/manager_event.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_event.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list.dart';
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

class TaskEditScreen extends StatefulWidget {
  final int taskId;
  final String taskName;
  final String taskStatus;
  final String? description;
  final int statusId;
  final String? user;
  final String? project;
  final String? startDate;
  final String? endDate;

  const TaskEditScreen({
    Key? key,
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.description,
    this.project,
    this.user,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController selectedUserId = TextEditingController();
  final TextEditingController selectedProjectId = TextEditingController();
  final TextEditingController selectedEndDate = TextEditingController();
  final TextEditingController selectedStartDate = TextEditingController();

  String? selectedPriority = 'Обычный';
  String? selectedProject;
  String? selectedUser;
  bool isUpdated = false;
  @override
  void initState() {
    super.initState();
    context.read<ManagerBloc>().add(FetchManagers());
    context.read<ProjectBloc>().add(FetchProjects());
    context.read<UserTaskBloc>().add(FetchUsers());
  }

  final List<String> priorityLevels = ['Обычный', 'Критический', 'Сложный'];

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
          'Редактирование задачи',
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
              'description': descriptionController.text,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
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
              _buildActionButtons(context),
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
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            // Обернул в Theme чтобы изменить цвет выпадающего меню на белый
            data: Theme.of(context).copyWith(
              canvasColor:
                  Colors.white, // Устанавливаем белый фон для выпадающего меню
            ),
            child: DropdownButtonFormField<String>(
              value: selectedPriority,
              items: priorityLevels.map((String priority) {
                Color priorityColor;
                switch (priority) {
                  case 'Критический':
                    priorityColor = Colors.red;
                    break;
                  case 'Сложный':
                    priorityColor = Colors.yellow;
                    break;
                  default:
                    priorityColor = Colors.green;
                }
                return DropdownMenuItem(
                  value: priority,
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
                      Text(priority),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPriority = newValue;
                });
              },
              decoration: _inputDecoration(),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildUserDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Пользователь',
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            // Обернул в Theme чтобы изменить цвет выпадающего меню на белый
            data: Theme.of(context).copyWith(
              canvasColor:
                  Colors.white, // Устанавливаем белый фон для выпадающего меню
            ),
            child: DropdownButtonFormField<String>(
              value: selectedUser,
              hint: const Text('Выберите пользователя'),
              items: [], // Здесь добавьте ваши элементы пользователя
              onChanged: (String? newValue) {
                setState(() {
                  selectedUser = newValue;
                });
              },
              decoration: _inputDecoration(),
            ),
          ),
        )
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(8),
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
                  DateTime? startDate, endDate;

                  if (startDateController.text.isNotEmpty) {
                    try {
                      startDate = DateFormat('dd/MM/yyyy HH:mm')
                          .parse(startDateController.text);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Ошибка в дате начала: ${e.toString()}'),
                        ),
                      );
                      return;
                    }
                  }

                  if (endDateController.text.isNotEmpty) {
                    try {
                      endDate = DateFormat('dd/MM/yyyy HH:mm')
                          .parse(endDateController.text);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Ошибка в дате окончания: ${e.toString()}'),
                        ),
                      );
                      return;
                    }
                  }

                  context.read<TaskBloc>().add(
                        UpdateTask(
                          taskId: widget.taskId,
                          name: nameController.text,
                          statusId: widget.statusId,
                          priority: selectedPriority,
                          startDate:
                              startDate, // Передаем преобразованное значение
                          endDate: endDate, // Передаем преобразованное значение
                          projectId: int.tryParse(
                              selectedProjectId.text), // Преобразование в int
                          userId: int.tryParse(
                              selectedUserId.text), // Преобразование в int
                          description: descriptionController.text,
                          taskStatusId: widget.statusId,
                          message: messageController.text,
                        ),
                      );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
