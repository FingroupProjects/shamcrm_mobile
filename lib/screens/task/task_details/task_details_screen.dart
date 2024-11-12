import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/task/task_details/task_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../bloc/history_task/task_history_event.dart';
import 'dropdown_history_task.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final String taskStatus;
  final int statusId;
  final String? project;
  final int? projectId;
  final String? user;
  final int? userId;
  // final String? projectName;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String? sum;

  TaskDetailsScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.project,
    this.projectId,
    this.user,
    this.userId,
    this.description,
    this.startDate,
    this.endDate,
    this.sum,
    // this.projectName,
  });

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  List<Map<String, String>> details = [];
  Task? currentTask;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(FetchTasks(widget.statusId));
  }
// Функция для форматирования даты
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Не указано';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Неверный формат';
    }
  }
  void _updateDetails(Task task) {
    currentTask = task;
    details = [
      {'label': 'Название задачи:', 'value': task.name}, 
      {'label': 'От:', 'value': task.startDate != null && task.startDate!.isNotEmpty 
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(task.startDate!))
          : 'Не указано'},
      {'label': 'До:', 'value': task.endDate != null && task.endDate!.isNotEmpty
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(task.endDate!))
          : 'Не указано'},
      {
        'label': 'Статус:',
        'value': task.taskStatus?.taskStatus.name ?? 'Не указано',
      },
      // {'label': 'Приоритет:', 'value': task.priority.toString()},
      {'label': 'Проект:', 'value': task.project?.name ?? 'Не указано'},
      {'label': 'Пользователь:', 'value': task.user?.name ?? 'Не указано'},
      {
        'label': 'Описание:',
        'value': task.description?.isNotEmpty == true
            ? task.description!
            : 'Не указано'
      },
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, 'Просмотр Задачи'),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskSuccess) {
            context.read<TaskBloc>().add(FetchTasks(1));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TaskLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (state is TaskDataLoaded) {
                Task? task;
                try {
                  task = state.tasks.firstWhere(
                    (task) => task.id.toString() == widget.taskId,
                  );
                } catch (e) {
                  task = null;
                }

                if (task != null) {
                  _updateDetails(task);
                } else {
                  return Center(child: Text('Задача не найдена'));
                }

                return ListView(
                  children: [
                    _buildDetailsList(),
                    const SizedBox(height: 16),
                    ActionHistoryWidgetTask(taskId: int.parse(widget.taskId)),
                  ],
                );
              } else if (state is TaskError) {
                return Center(child: Text('Ошибка: ${state.message}'));
              }
              return Center(child: Text(''));
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String name) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Image.asset(
          'assets/icons/arrow-left.png',
          width: 24,
          height: 24,
        ),
        onPressed: () {
          Navigator.pop(context);
              context.read<TaskBloc>().add(FetchTaskStatuses());

        },
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/edit.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              if (currentTask != null) {
                final updatedTask = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskEditScreen(
                      taskId: currentTask!.id,
                      taskName: currentTask!.name,
                      taskStatus:
                          currentTask!.taskStatus?.taskStatus.toString() ?? '',
                      project: currentTask!.project?.id.toString(),
                      user: currentTask!.user?.id.toString(),
                      statusId: currentTask!.statusId,
                      description: currentTask!.description,
                      startDate: currentTask!.startDate,
                      endDate: currentTask!.endDate,
                    ),
                  ),
                );

                if (updatedTask != null) {
                  context.read<TaskBloc>().add(FetchTasks(1));
                  context
                      .read<HistoryBlocTask>()
                      .add(FetchTaskHistory(int.parse(widget.taskId)));
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(width: 8),
        Expanded(
          child: _buildValue(value),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }
}
