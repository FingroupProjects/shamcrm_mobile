import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/screens/task/task_details/task_delete.dart';
import 'package:crm_task_manager/screens/task/task_details/task_edit_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_navigate_to_chat.dart';
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
  // final String? user;
  final List<int>? userId;
  // final String? projectName;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String? sum;
  final int? priority;
  final List<TaskCustomField> taskCustomFields;

  TaskDetailsScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.project,
    this.projectId,
    // this.user,
    this.userId,
    this.description,
    this.startDate,
    this.endDate,
    this.sum,
    // this.projectName,
    this.priority,
    required this.taskCustomFields,
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
  bool _isTextExpanded = false; // New state variable for expanding text

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    context
        .read<TaskByIdBloc>()
        .add(FetchTaskByIdEvent(taskId: int.parse(widget.taskId)));
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
      return DateFormat('dd.MM.yyyy').format(parsedDate);
    } catch (e) {
      return 'Неверный формат';
    }
  }

  // Обновление данных задачи
  void _updateDetails(TaskById? task) {
    if (task == null) {
      currentTask = null;
      details.clear();
      return;
    }

      // Карта уровней приоритета
  final Map<int, String> priorityLevels = {
    1: 'Обычный',
    3: 'Критический',
    2: 'Сложный'
  };

    currentTask = task;
    details = [
      // {'label': 'ID задачи:', 'value': task.id.toString()},
      {'label': 'Название задачи:', 'value': task.name},
      {
        'label': 'Уровень приоритета:',
        'value': priorityLevels[task.priority] ?? 'Не указано',
      },      {
        'label': 'От:',
        'value': task.startDate != null && task.startDate!.isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.startDate!))
            : 'Не указано'
      },
      {
        'label': 'До:',
        'value': task.endDate != null && task.endDate!.isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!))
            : 'Не указано'
      },
       {'label': 'Проект:', 'value': task.project?.name ?? 'Не указано'},
          {
        'label': 'Исполнитель:',
        'value': task.user != null && task.user!.isNotEmpty
            ? task.user!.map((user) => user.name).join(', ')
            : 'Не указано',
      },
        {
        'label': 'Описание:',
        'value': task.description?.isNotEmpty == true
            ? task.description!
            : 'Не указано'
      },
      {
        'label': 'Статус:',
        'value': task.taskStatus?.taskStatus.name ?? 'Не указано',
      },
      {'label': 'Автор:', 'value': task.author?.name ?? 'Не указано'},
      {'label': 'Дата создания:', 'value': formatDate(task.createdAt)},
    ];

    for (var field in task.taskCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(context, 'Просмотр задачи'),
        backgroundColor: Colors.white,
        body: BlocListener<TaskByIdBloc, TaskByIdState>(
          listener: (context, state) {
            if (state is TaskByIdLoaded) {
              print("Задача Data: ${state.task.toString()}");
            } else if (state is TaskByIdError) {
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
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: BlocBuilder<TaskByIdBloc, TaskByIdState>(
            builder: (context, state) {
              if (state is TaskByIdLoading) {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xff1E2E52)),
                );
              } else if (state is TaskByIdLoaded) {
                TaskById task = state.task;
                if (task == null) {
                  return Center(child: Text('Task data is not available.'));
                }
                _updateDetails(task);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListView(
                    children: [
                      _buildDetailsList(),
                      Row(
                        children: [
                          Expanded(
                            flex: 55,
                            child: TaskNavigateToChat(
                              chatId: task.chat!.id,
                              taskName: widget.taskName,
                              canSendMessage: task.chat!.canSendMessage,
                            ),
                          ),
                          SizedBox(
                            width: 8,
                            height: 60,
                          ),
                          Expanded(
                            flex: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: Text(
                                      'Хотите завершить задачу?',
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Отмена',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Gilroy',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          minimumSize: Size(120,
                                              48), // Увеличена ширина кнопки
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final taskId =
                                              int.parse(widget.taskId);
                                          context
                                              .read<ApiService>()
                                              .finishTask(taskId)
                                              .then((result) {
                                            if (result['success']) {
                                              Navigator.pop(
                                                  context); // Закрываем диалог
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    result['message'],
                                                    style: TextStyle(
                                                      fontFamily: 'Gilroy',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  margin: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  elevation: 3,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 12,
                                                    horizontal: 16,
                                                  ),
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                              Navigator.pop(context);
                                              context
                                                  .read<TaskBloc>()
                                                  .add(FetchTaskStatuses());
                                            } else {
                                              Navigator.pop(
                                                  context); // Закрываем диалог
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    result['message'],
                                                    style: TextStyle(
                                                      fontFamily: 'Gilroy',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  margin: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  elevation: 3,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 12,
                                                    horizontal: 16,
                                                  ),
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          });
                                        },
                                        child: Text(
                                          'Подтвердить',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Gilroy',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Color(0xff1E2E52),
                                          minimumSize: Size(120,
                                              48), // Увеличена ширина кнопки
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                    backgroundColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Color(0xFF1E2E52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Готов',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Gilroy',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ActionHistoryWidgetTask(taskId: int.parse(widget.taskId)),
                    ],
                  ),
                );
              } else if (state is TaskByIdError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
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
                      backgroundColor: Colors.red,
                      elevation: 3,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      duration: Duration(seconds: 2),
                    ),
                  );
                });
              }
              return Center(child: Text(''));
            },
          ),
        ));
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
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
        if (_canEditTask || _canDeleteTask)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditTask)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/edit.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () async {
                    final createdAtString = currentTask!.createdAt != null &&
                            currentTask!.createdAt!.isNotEmpty
                        ? DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(currentTask!.createdAt!))
                        : null;

                    if (currentTask != null) {
                      final shouldUpdate = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskEditScreen(
                            taskId: currentTask!.id,
                            taskName: currentTask!.name,
                            taskStatus: currentTask!.taskStatus?.taskStatus
                                    .toString() ??
                                '',
                            project: currentTask!.project?.id.toString(),
                            user: currentTask!.user != null &&
                                    currentTask!.user!.isNotEmpty
                                ? currentTask!.user!
                                    .map((user) => user.id)
                                    .toList()
                                : null,
                            statusId: currentTask!.statusId,
                            description: currentTask!.description,
                            startDate: currentTask!.startDate,
                            endDate: currentTask!.endDate,
                            createdAt: createdAtString,
                            taskCustomFields: currentTask!.taskCustomFields,
                          ),
                        ),
                      );

                      if (shouldUpdate == true) {
                        context
                            .read<TaskByIdBloc>()
                            .add(FetchTaskByIdEvent(taskId: currentTask!.id));
                        context.read<TaskBloc>().add(FetchTaskStatuses());
                      }
                    }
                  },
                ),
              if (_canDeleteTask)
                IconButton(
                  padding: EdgeInsets.only(right: 8),
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/delete.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          DeleteTaskDialog(taskId: currentTask!.id),
                    );
                  },
                ),
            ],
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

  Widget _buildDetailItem(String label, String value) {
    // Проверка на наличие запятой в значении, чтобы определить множественное число
    if (label == 'Исполнитель:' && value.contains(',')) {
      label = 'Исполнители:';
    }

    if (label == 'Исполнители:') {
      return GestureDetector(
        onTap: () => _showUsersDialog(value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value.split(',').take(3).join(', ') +
                    (value.split(',').length > 3
                        ? ' и еще ${value.split(',').length - 3}...'
                        : ''),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

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

  void _showUsersDialog(String users) {
    List<String> userList =
        users.split(',').map((user) => user.trim()).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Список исполнителей',
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemExtent: 40, // Уменьшаем высоту элемента
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2), // Минимальный вертикальный отступ
                      title: Text(
                        '${index + 1}. ${userList[index]}',
                        style: TextStyle(
                          color: Color(0xff1E2E52),
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: CustomButton(
                  buttonText: 'Закрыть',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
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
