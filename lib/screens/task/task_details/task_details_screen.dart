import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_state.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/screens/task/task_details/task_delete.dart';
import 'package:crm_task_manager/screens/task/task_details/task_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
  final int? priority;

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
    this.priority,
  });

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  List<Map<String, String>> details = [];
  TaskById? currentTask;
  bool _canEditTask = false;
  bool _canDeleteTask = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
      context.read<TaskByIdBloc>().add(FetchTaskByIdEvent(taskId: int.parse(widget.taskId)));
  }

  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canEdit = await _apiService.hasPermission('task.update');
    final canDelete = await _apiService.hasPermission('task.delete');
    setState(() {
      _canEditTask = canEdit;
      _canDeleteTask = canDelete;
    });
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

  // Обновление данных задачи
  void _updateDetails(TaskById task) {
    currentTask = task;
    details = [
      {'label': 'Название задачи:', 'value': task.name}, 
      {'label': 'От:', 'value': task.startDate != null && task.startDate!.isNotEmpty 
          ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.startDate!))
          : 'Не указано'},
      {'label': 'До:', 'value': task.endDate != null && task.endDate!.isNotEmpty
          ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!))
          : 'Не указано'},
      {
        'label': 'Статус:',
        'value': task.taskStatus?.taskStatus.name ?? 'Не указано',
      },
      // {'label': 'Приоритет:', 'value': task.priority.toString()},
      
      {'label': 'Проект:', 'value': task.project?.name ?? 'Не указано'},
      {'label': 'Пользователь:', 'value': task.user?.name ?? 'Не указано'},


      {'label': 'Описание:', 'value': task.description?.isNotEmpty == true ? task.description! : 'Не указано'},
    ];
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
      appBar: _buildAppBar(context, 'Просмотр Задачи'),
      backgroundColor: Colors.white,
      body: BlocListener<TaskByIdBloc, TaskByIdState>(
        listener: (context, state) {
          if (state is TaskByIdLoaded) {
            print("Задача Data: ${state.task.toString()}");
          } else if (state is TaskByIdError) {
            print("Ошибка получения задачи: ${state.message}");
          }
        },
        child: BlocBuilder<TaskByIdBloc, TaskByIdState>(
          builder: (context, state) {
            if (state is TaskByIdLoading) {
              return Center(
                  child: CircularProgressIndicator(color: Color(0xff1E2E52)));
            } else if (state is TaskByIdLoaded) {
              TaskById task = state.task;
              _updateDetails(task);
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: ListView(
                  children: [
                    _buildDetailsList(),
                    const SizedBox(height: 16),
                    ActionHistoryWidgetTask(taskId: int.parse(widget.taskId)),
                  ],
                ),
              );
            } else if (state is TaskByIdError) {
              return Center(child: Text('Ошибка: ${state.message}'));
            }
            return Center(child: Text(''));
          },
        ),
      ));
}



  // Функция для построения AppBar
  AppBar _buildAppBar(BuildContext context, String title) {
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
        title,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        // Кнопка редактирования, если есть разрешение
        if (_canEditTask)
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
                   final shouldUpdate = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskEditScreen(
                        taskId: currentTask!.id,
                        taskName: currentTask!.name,
                        taskStatus: currentTask!.taskStatus?.taskStatus.toString() ?? '',
                        project: currentTask!.project?.id.toString(),
                        user: currentTask!.user?.id.toString(),
                        statusId: currentTask!.statusId,
                        description: currentTask!.description,
                        startDate: currentTask!.startDate,
                        endDate: currentTask!.endDate,
                      ),
                    ),
                  );

                   if (shouldUpdate == true) {
                      // Перезагружаем данные лида
                      context.read<TaskByIdBloc>().add(
                          FetchTaskByIdEvent(taskId: int.parse(widget.taskId)));
                      context.read<TaskBloc>().add(FetchTaskStatuses());
                    }
                }
              },
            ),
          ),
        // Кнопка удаления, если есть разрешение
        if (_canDeleteTask)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Image.asset(
                'assets/icons/delete.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                // Show delete confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => DeleteTaskDialog(taskId: currentTask!.id),
                );
              },
            ),
          ),
      ],
    );
  }

  // Построение списка деталей задачи
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

  // Построение одной строки с деталями задачи
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

  // Построение метки
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

  // Построение значения
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