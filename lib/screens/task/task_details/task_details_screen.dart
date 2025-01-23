import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_delete.dart';
import 'package:crm_task_manager/screens/task/task_details/task_edit_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_navigate_to_chat.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
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
  final String? taskFile; // Добавлено поле для файла

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
    this.taskFile, // Инициализация опционального параметра
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
  bool _isLoading = false;
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
  // String formatDate(String? dateString) {
  //   if (dateString == null || dateString.isEmpty) return '';
  //   try {
  //     final parsedDate = DateTime.parse(dateString);
  //     return DateFormat('dd.MM.yyyy').format(parsedDate);
  //   } catch (e) {
  //     return 'Неверный формат';
  //   }
  // }
  // Функция для форматирования даты
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
    }
  }

  // Функция для показа диалогового окна с полным текстом
  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.justify, // Выровнять текст по ширине

                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
                  onPressed: () => Navigator.pop(context),
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

  // Обновление данных задачи
  void _updateDetails(TaskById? task) {
    if (task == null) {
      currentTask = null;
      details.clear();
      return;
    }


    final Map<int, String> priorityLevels = {
  1: AppLocalizations.of(context)!.translate('normal'), 
  2: AppLocalizations.of(context)!.translate('important'),
  3: AppLocalizations.of(context)!.translate('urgent'), 
};

    currentTask = task;
    details = [
      {'label': AppLocalizations.of(context)!.translate('task_name'), 'value': task?.name ?? ""},
      {
        'label': AppLocalizations.of(context)!.translate('priority_level'),
        'value': priorityLevels[task.priority] ?? AppLocalizations.of(context)!.translate('normal'),
      },
      {
        'label': AppLocalizations.of(context)!.translate('from_details'),
        'value': task.startDate != null && task.startDate!.isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.startDate!))
            : ''
      },
      {
        'label':  AppLocalizations.of(context)!.translate('to_details'),
        'value': task.endDate != null && task.endDate!.isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!))
            : ''
      },
      {'label': AppLocalizations.of(context)!.translate('project_details'),  'value': task.project?.name ?? ''},
      {
        'label': AppLocalizations.of(context)!.translate('assignee'),
        'value': task.user != null && task.user!.isNotEmpty
            ? task.user!.map((user) => user.name).join(', ')
            : '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('description_details'),
        'value': task.description?.isNotEmpty == true ? task.description! : ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('status_details'),
        'value': task.taskStatus?.taskStatus.name ?? '',
      },
      {'label': AppLocalizations.of(context)!.translate('author_details'),'value': task.author?.name ?? ''},
      {'label':  AppLocalizations.of(context)!.translate('creation_date_details'), 'value': formatDate(task.createdAt)},
      if (task.taskFile != null && task.taskFile!.isNotEmpty)
        {'label': AppLocalizations.of(context)!.translate('file_details'), 'value': AppLocalizations.of(context)!.translate('link'),},
    ];

    for (var field in task.taskCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }

    // Вывод каждой детали в консоль
    for (var detail in details) {
      print("${detail['label']} ${detail['value']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(context, AppLocalizations.of(context)!.translate('view_task'),),
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
                  duration: Duration(seconds: 3),
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
                if (state.task == null) {
                  return Center(child: Text(AppLocalizations.of(context)!.translate('task_data_unavailable'),));
                }
                TaskById task = state.task!;
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
                              flex: task.isFinished == 1 ? 100 : 55,
                              child: TaskNavigateToChat(
                                chatId: task.chat!.id,
                                taskName: widget.taskName,
                                canSendMessage: task.chat!.canSendMessage,
                              ),
                            ),
                            if (task.isFinished == 0) ...[
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
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 20),
                                        title: Text(
                                         AppLocalizations.of(context)!.translate('confirm_task_completion'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        content: Container(
                                          width: double.maxFinite,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    AppLocalizations.of(context)!.translate('cancel'),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Gilroy',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    minimumSize: Size(80, 48),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: StatefulBuilder(
                                                  builder: (BuildContext
                                                          context,
                                                      StateSetter setState) {
                                                    return TextButton(
                                                      onPressed: _isLoading
                                                          ? null
                                                          : () async {
                                                              setState(() {
                                                                _isLoading =
                                                                    true;
                                                              });

                                                              final taskId = int
                                                                  .parse(widget
                                                                      .taskId);
                                                              final result =
                                                                  await context
                                                                      .read<
                                                                          ApiService>()
                                                                      .finishTask(
                                                                          taskId);

                                                              if (result[
                                                                  'success']) {
                                                                Navigator.pop(
                                                                    context);
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content:
                                                                        Text(
                                                                      result[
                                                                          'message'],
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            'Gilroy',
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                    behavior:
                                                                        SnackBarBehavior
                                                                            .floating,
                                                                    margin: EdgeInsets
                                                                        .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          8,
                                                                    ),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .green,
                                                                    elevation:
                                                                        3,
                                                                    padding:
                                                                        EdgeInsets
                                                                            .symmetric(
                                                                      vertical:
                                                                          12,
                                                                      horizontal:
                                                                          16,
                                                                    ),
                                                                    duration: Duration(
                                                                        seconds:
                                                                            2),
                                                                  ),
                                                                );
                                                                Navigator.pop(
                                                                    context);
                                                                context
                                                                    .read<
                                                                        TaskBloc>()
                                                                    .add(
                                                                        FetchTaskStatuses());
                                                              } else {
                                                                Navigator.pop(
                                                                    context);
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content:
                                                                        Text(
                                                                      result[
                                                                          'message'],
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            'Gilroy',
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                    behavior:
                                                                        SnackBarBehavior
                                                                            .floating,
                                                                    margin: EdgeInsets
                                                                        .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          8,
                                                                    ),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                    elevation:
                                                                        3,
                                                                    padding:
                                                                        EdgeInsets
                                                                            .symmetric(
                                                                      vertical:
                                                                          12,
                                                                      horizontal:
                                                                          16,
                                                                    ),
                                                                    duration: Duration(
                                                                        seconds:
                                                                            2),
                                                                  ),
                                                                );
                                                              }

                                                              setState(() {
                                                                _isLoading =
                                                                    false;
                                                              });
                                                            },
                                                      child: _isLoading
                                                          ? SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                                strokeWidth: 2,
                                                              ),
                                                            )
                                                          : Text(
                                                              AppLocalizations.of(context)!.translate('confirm'),
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    'Gilroy',
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor:
                                                            Color(0xff1E2E52),
                                                        minimumSize:
                                                            Size(130, 48),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor:
                                            Color.fromARGB(255, 255, 255, 255),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    backgroundColor: Color(0xFF1E2E52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.translate('for_review'),
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        ActionHistoryWidgetTask(
                            taskId: int.parse(widget.taskId)),
                      ],
                    ));
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
                      duration: Duration(seconds: 3),
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
          Navigator.pop(context, widget.statusId);
          // context.read<TaskBloc>().add(FetchTaskStatuses());
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
                    final createdAtString = currentTask?.createdAt != null &&
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
                            priority: currentTask!.priority,
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
                            file: currentTask!.taskFile,
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
    // Специальная обработка для названия и описания
    if (label == AppLocalizations.of(context)!.translate('task_name') || label == AppLocalizations.of(context)!.translate('description_details')) {
      return GestureDetector(
        onTap: () {
          if (value.isNotEmpty) {
            _showFullTextDialog(
              label.replaceAll(':', ''),
              value,
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                  decoration:
                      value.isNotEmpty ? TextDecoration.underline : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (label == AppLocalizations.of(context)!.translate('assignee') && value.contains(',')) {
      label = AppLocalizations.of(context)!.translate('assignees');
    }

    if (label == AppLocalizations.of(context)!.translate('assignees')) {
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

    if (label == AppLocalizations.of(context)!.translate('file_details')) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (currentTask?.taskFile != null) {
                _showFile(currentTask!.taskFile!);
              }
            },
            child: Text(
              AppLocalizations.of(context)!.translate('link'),
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    if (label == AppLocalizations.of(context)!.translate('priority_level_colon')) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IntrinsicWidth(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: _getPriorityBackgroundColor(value),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: _getPriorityColor(value),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
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

  Color _getPriorityBackgroundColor(String priority) {
    switch (priority) {
      case 'Срочный':
        return Color(0xFFFFEBEE);
      case 'Важный':
        return Color(0xFFFFF3E0);
      case 'Обычный':
        return Color(0xFFE8F5E9);
      default:
        return Color(0xFFE8F5E9);
    }
  }

  Color _getPriorityBorderColor(String priority) {
    switch (priority) {
      case 'Срочный':
        return Colors.red;
      case 'Важный':
        return Colors.orange;
      case 'Обычный':
        return Colors.green;
      default:
        return Color(0xFF2E7D32);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Срочный':
        return Color(0xFFC62828);
      case 'Важный':
        return Color(0xFFEF6C00);
      case 'Обычный':
        return Color(0xFF2E7D32);
      default:
        return Color(0xFF2E7D32);
    }
  }

  void _showFile(String fileUrl) async {
    try {
      print('Входящий fileUrl: $fileUrl');

      // Получаем базовый домен из ApiService
      // Получаем базовый домен из ApiService
    final enteredDomainMap = await ApiService().getEnteredDomain();
  // Извлекаем значения из Map
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain']; 
         print('Полученный базовый домен: $enteredDomain');

      // Формируем полный URL файла
      final fullUrl =
          Uri.parse('https://$enteredDomain-back.$enteredMainDomain/storage/$fileUrl');
      print('Сформированный полный URL: $fullUrl');

      // Путь для сохранения файла
      final directory = await getApplicationDocumentsDirectory();
      final fileName = fileUrl.split('/').last;
      final filePath = '${directory.path}/$fileName';

      // Загружаем файл
      final dio = Dio();
      await dio.download(fullUrl.toString(), filePath);

      print('Файл успешно скачан в $filePath');

      // Открываем файл
      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.error) {
        print('Не удалось открыть файл: ${result.message}');
        _showErrorSnackBar(AppLocalizations.of(context)!.translate('failed_to_open_file'));
      } else {
        print('Файл открыт успешно.');
      }
    } catch (e) {
      print('Ошибка при скачивании или открытии файла!');
      _showErrorSnackBar(AppLocalizations.of(context)!.translate('file_download_or_open_error'));
    }
  }

// Функция для показа ошибки
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
                  AppLocalizations.of(context)!.translate('assignee_list'),
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
                  buttonText: AppLocalizations.of(context)!.translate('close'),
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
