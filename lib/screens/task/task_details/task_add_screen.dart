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

class TaskAddScreen extends StatefulWidget {
  final int statusId;

  const TaskAddScreen({Key? key, required this.statusId}) : super(key: key);

  @override
  _TaskAddScreenState createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedPriority = 'Обычный';
  String? selectedProject;
  String ?selectedUser;
  int ?taskStatusId;
  String? startDate;
  String? endDate;
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
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
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
        elevation: 0,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
            context.read<TaskBloc>().add(FetchTasks(widget.statusId));
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
                        controller: fromController,
                        label: 'От',
                      ),
                      const SizedBox(height: 16),
                      CustomTextFieldDate(
                        controller: toController,
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
            color: Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(8),
          ),
           child: Theme(
          // Обернул в Theme чтобы изменить цвет выпадающего меню на белый
          data: Theme.of(context).copyWith(
            canvasColor: Colors.white, // Устанавливаем белый фон для выпадающего меню
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
           )
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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
                buttonColor: Color(0xffF4F7FD),
                textColor: Colors.black,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                buttonText: 'Добавить',
                buttonColor: Color(0xff4759FF),
                textColor: Colors.white,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final String name = nameController.text;
                    DateTime? startDate;
                    DateTime? endDate;

                    
                    if (toController.text.isNotEmpty) {
                      try {
                        endDate = DateFormat('dd/MM/yyyy HH:mm')
                            .parse(fromController.text);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Ошибка в дате окончания: ${e.toString()}'),
                          ),
                        );
                        return;
                      }
                    }

                    final String? description =
                        descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text;

                    context.read<TaskBloc>().add(
                          CreateTask(
                            name: name,
                            statusId: widget.statusId,
                            priority: selectedPriority,
                            taskStatusId: widget.statusId,
                            startDate:startDate,
                            endDate: endDate,
                            projectId: selectedProject != null
                                ? int.parse(selectedProject!)
                                : null,
                            userId: selectedUser != null
                                ? int.parse(selectedUser!)
                                : null,
                            description: description,
                          ),
                        );
                  }
                },
              ),
            ),
          ],
        ));
  }
}
