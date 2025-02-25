import 'dart:convert';
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'dropdown_history_task.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final int? taskNumber;
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
  final List<TaskFiles>? files; // вместо String? taskFile

  TaskDetailsScreen({
    required this.taskId,
    this.taskNumber,
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
    this.files,
    // this.projectName,
    this.priority,
    required this.taskCustomFields,
    this.taskFile, // Инициализация опционального параметра
  });

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class FileCacheManager {
  static final FileCacheManager _instance = FileCacheManager._internal();
  factory FileCacheManager() => _instance;
  FileCacheManager._internal();

  static const String CACHE_INFO_KEY = 'file_cache_info';
  late SharedPreferences _prefs;
  final Map<int, String> _cachedFiles = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheInfo();
    _initialized = true;
  }

  Future<void> _loadCacheInfo() async {
    final String? cacheInfo = _prefs.getString(CACHE_INFO_KEY);
    if (cacheInfo != null) {
      final Map<String, dynamic> cacheMap = json.decode(cacheInfo);
      cacheMap.forEach((key, value) {
        _cachedFiles[int.parse(key)] = value.toString();
      });
    }
  }

  Future<void> _saveCacheInfo() async {
    final Map<String, dynamic> cacheMap = {};
    _cachedFiles.forEach((key, value) {
      cacheMap[key.toString()] = value;
    });
    await _prefs.setString(CACHE_INFO_KEY, json.encode(cacheMap));
  }

  Future<String?> getCachedFilePath(int fileId) async {
    await init();
    if (_cachedFiles.containsKey(fileId)) {
      final file = File(_cachedFiles[fileId]!);
      if (await file.exists()) {
        return _cachedFiles[fileId];
      } else {
        _cachedFiles.remove(fileId);
        await _saveCacheInfo();
      }
    }
    return null;
  }

  Future<void> cacheFile(int fileId, String filePath) async {
    await init();
    _cachedFiles[fileId] = filePath;
    await _saveCacheInfo();
  }

  Future<void> clearCache() async {
    await init();
    for (var filePath in _cachedFiles.values) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _cachedFiles.clear();
    await _saveCacheInfo();
  }

  // Метод для получения размера кэша
  Future<int> getCacheSize() async {
    await init();
    int totalSize = 0;
    for (var filePath in _cachedFiles.values) {
      final file = File(filePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  List<Map<String, String>> details = [];
  TaskById? currentTask;
  bool _canEditTask = false;
  bool _canDeleteTask = false;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isDownloading = false;
  Map<int, double> _downloadProgress = {};
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
      return DateFormat('dd.MM.yyyy').format(parsedDate);
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
      2: AppLocalizations.of(context)!.translate('normal'),
      3: AppLocalizations.of(context)!.translate('urgent'),
    };

    currentTask = task;
    details = [
      {
        'label': AppLocalizations.of(context)!.translate('task_name'),
        'value': task?.name ?? ""
      },
      {
        'label':
            AppLocalizations.of(context)!.translate('priority_level_colon'),
        'value': priorityLevels[task.priority] ??
            AppLocalizations.of(context)!.translate('normal'),
      },
      {
        'label': AppLocalizations.of(context)!.translate('description_details'),
        'value': task.description?.isNotEmpty == true ? task.description! : ''
      },

      {
        'label': AppLocalizations.of(context)!.translate('assignee'),
        'value': task.user != null && task.user!.isNotEmpty
            ? task.user!
                .map((user) => '${user.name} ${user.lastname ?? ''}')
                .join(', ')
            : '',
      },

      {
        'label': AppLocalizations.of(context)!.translate('project_details'),
        'value': task.project?.name ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('dead_line'),
        'value': task.endDate != null && task.endDate!.isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!))
            : ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('status_details'),
        'value': task.taskStatus?.taskStatus.name ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('author_details'),
        'value': task.author?.name ?? ''
      },
      {
        'label':
            AppLocalizations.of(context)!.translate('creation_date_details'),
        'value': formatDate(task.createdAt)
      },
    if (task.deal != null && (task.deal?.name?.isNotEmpty == true))
      {
        'label': AppLocalizations.of(context)!.translate('task_by_deal'),
        'value': task.deal!.name!
      },
      if (task.files != null && task.files!.isNotEmpty)
        {
          'label': AppLocalizations.of(context)!.translate('files_details'),
          'value': task.files!.length.toString() +
              ' ' +
              AppLocalizations.of(context)!.translate('files'),
        },
    ];

    for (var field in task.taskCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }
  }

@override
Widget build(BuildContext context) {
  return BlocListener<TaskByIdBloc, TaskByIdState>(
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
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)),
            ),
          );
        } else if (state is TaskByIdLoaded) {
          if (state.task == null) {
            return Scaffold(
              body: Center(
                child: Text(
                  AppLocalizations.of(context)!.translate('task_data_unavailable'),
                ),
              ),
            );
          }
          TaskById task = state.task!;
          _updateDetails(task);

          return Scaffold(
            appBar: _buildAppBar(
              context, 
              '${AppLocalizations.of(context)!.translate('view_task')} №${task.taskNumber ?? ""}'
            ),
            backgroundColor: Colors.white,
            body: Padding(
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
                                builder: (BuildContext dialogContext) =>
                                    AlertDialog(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 20),
                                  title: Text(
                                    AppLocalizations.of(context)!
                                        .translate('confirm_task_completion'),
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
                                                Navigator.pop(dialogContext),
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .translate('cancel'),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Gilroy',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              minimumSize: Size(80, 48),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: StatefulBuilder(
                                            builder: (BuildContext context,
                                                StateSetter setState) {
                                              return TextButton(
                                                onPressed: _isLoading
                                                    ? null
                                                    : () async {
                                                        setState(() {
                                                          _isLoading = true;
                                                        });

                                                        final taskId =
                                                            int.parse(widget.taskId);
                                                        try {
                                                          final result =
                                                              await context
                                                                  .read<ApiService>()
                                                                  .finishTask(taskId);

                                                          if (result['success'] == true) {
                                                            Navigator.pop(dialogContext);
                                                            ScaffoldMessenger.of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  result['message'] ?? '',
                                                                  style: TextStyle(
                                                                    fontFamily: 'Gilroy',
                                                                    fontSize: 16,
                                                                    fontWeight:
                                                                        FontWeight.w500,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                                behavior: SnackBarBehavior
                                                                    .floating,
                                                                margin: EdgeInsets
                                                                    .symmetric(
                                                                  horizontal: 16,
                                                                  vertical: 8,
                                                                ),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(12),
                                                                ),
                                                                backgroundColor:
                                                                    Colors.green,
                                                                elevation: 3,
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                  vertical: 12,
                                                                  horizontal: 16,
                                                                ),
                                                                duration:
                                                                    Duration(seconds: 2),
                                                              ),
                                                            );
                                                            context.read<TaskBloc>().add(
                                                                FetchTaskStatuses());
                                                          } else {
                                                            Navigator.pop(dialogContext);
                                                            ScaffoldMessenger.of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  result['message'] ?? '',
                                                                  style: TextStyle(
                                                                    fontFamily: 'Gilroy',
                                                                    fontSize: 16,
                                                                    fontWeight:
                                                                        FontWeight.w500,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                                behavior: SnackBarBehavior
                                                                    .floating,
                                                                margin: EdgeInsets
                                                                    .symmetric(
                                                                  horizontal: 16,
                                                                  vertical: 8,
                                                                ),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(12),
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                                elevation: 3,
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                  vertical: 12,
                                                                  horizontal: 16,
                                                                ),
                                                                duration:
                                                                    Duration(seconds: 2),
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          Navigator.pop(dialogContext);
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                e.toString(),
                                                                style: TextStyle(
                                                                  fontFamily: 'Gilroy',
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight.w500,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        } finally {
                                                          setState(() {
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      },
                                                child: _isLoading
                                                    ? SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : Text(
                                                        AppLocalizations.of(context)!
                                                            .translate('confirm'),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: 'Gilroy',
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                style: TextButton.styleFrom(
                                                  backgroundColor:
                                                      Color(0xff1E2E52),
                                                  minimumSize: Size(130, 48),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8),
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Color(0xFF1E2E52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('for_review'),
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
                  ActionHistoryWidgetTask(taskId: int.parse(widget.taskId)),
                ],
              ),
            ),
          );
        } else if (state is TaskByIdError) {
          return Scaffold(
            body: Center(
              child: Text(state.message),
            ),
          );
        }
        return Scaffold(
          body: Center(
            child: Text(''),
          ),
        );
      },
    ),
  );
}

  AppBar _buildAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    forceMaterialTransparency: true, // Добавлено
    elevation: 0,
    centerTitle: false,
    leadingWidth: 40,
    leading: Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Transform.translate(
        offset: const Offset(0, -2),  // Добавлен правильный offset как в первом варианте
        child: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 40,
            height: 40,
          ),
          onPressed: () {
            Navigator.pop(context, widget.statusId);
          },
        ),
      ),
    ),
    title: Transform.translate(
      offset: const Offset(-10, 0),  // Добавлен правильный offset как в первом варианте
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
    ),
    actions: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                            // file: currentTask!.taskFile,
                            files: currentTask!.files,
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
    if (label == AppLocalizations.of(context)!.translate('task_name') ||
        label ==
            AppLocalizations.of(context)!.translate('description_details')) {
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

    if (label == AppLocalizations.of(context)!.translate('assignee') &&
        value.contains(',')) {
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
    if (label == AppLocalizations.of(context)!.translate('files_details')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          SizedBox(height: 8),
          Container(
            height: 120, // Высота контейнера для файлов
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentTask?.files?.length ?? 0,
              itemBuilder: (context, index) {
                final file = currentTask!.files![index];
                final fileExtension = file.name.split('.').last.toLowerCase();

                return Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      if (!_isDownloading) {
                        _showFile(file.path, file.id);
                      }
                    },
                    child: Container(
                      width: 100,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Иконка файла
                              Image.asset(
                                'assets/icons/files/$fileExtension.png',
                                width: 60,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/icons/files/file.png', // Дефолтная иконка
                                    width: 60,
                                    height: 60,
                                  );
                                },
                              ),
                              // Индикатор загрузки
                              if (_downloadProgress.containsKey(file.id))
                                CircularProgressIndicator(
                                  value: _downloadProgress[file.id],
                                  strokeWidth: 3,
                                  backgroundColor: Colors.grey.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xff1E2E52),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            file.name,
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
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (label ==
        AppLocalizations.of(context)!.translate('priority_level_colon')) {
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
 if (label == AppLocalizations.of(context)!.translate('task_by_deal')) {
      return GestureDetector(
        onTap: () {
          if (currentTask?.deal?.id != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => DealDetailsScreen(
                  dealId: currentTask!.deal!.id.toString(),
                  dealName: value,
                  dealStatus: "",
                  statusId: 0, sum: '', dealCustomFields: [],
                ),
              ),
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
                  decoration: value.isNotEmpty && currentTask?.deal?.id != null 
                      ? TextDecoration.underline 
                      : null,
                ),
                maxLines: 1,
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

  Color _getPriorityBackgroundColor(String priority) {
    // Создаем Map для сопоставления приоритетов и цветов
    final priorityColors = {
      AppLocalizations.of(context)!.translate('urgent'):
          Color(0xFFFFEBEE), // Срочный
      AppLocalizations.of(context)!.translate('normal'):
          Color(0xFFE8F5E9), // Важный
      AppLocalizations.of(context)!.translate('normal'):
          Color(0xFFE8F5E9), // Обычный
    };
    // Возвращаем цвет из Map, либо цвет по умолчанию
    return priorityColors[priority] ?? Color(0xFFE8F5E9);
  }

  Color _getPriorityBorderColor(String priority) {
    // Map для сопоставления приоритетов и цветов рамки
    final priorityBorderColors = {
      AppLocalizations.of(context)!.translate('urgent'): Colors.red, // Срочный
      AppLocalizations.of(context)!.translate('normal'): Colors.green, // Важный
      AppLocalizations.of(context)!.translate('normal'):
          Colors.green, // Обычный
    };
    // Возвращаем цвет из Map, либо цвет по умолчанию
    return priorityBorderColors[priority] ?? Color(0xFF2E7D32);
  }

  Color _getPriorityColor(String priority) {
    // Map для сопоставления приоритетов и основных цветов
    final priorityColors = {
      AppLocalizations.of(context)!.translate('urgent'):
          Color(0xFFC62828), // Срочный
      AppLocalizations.of(context)!.translate('normal'):
          Color(0xFF2E7D32), // Важный
      AppLocalizations.of(context)!.translate('normal'):
          Color(0xFF2E7D32), // Обычный
    };
    // Возвращаем цвет из Map, либо цвет по умолчанию
    return priorityColors[priority] ?? Color(0xFF2E7D32);
  }

  Future<void> _showFile(String fileUrl, int fileId) async {
    try {
      if (_isDownloading) return;

      // Проверяем наличие файла в постоянном кэше
      final cachedFilePath = await FileCacheManager().getCachedFilePath(fileId);
      if (cachedFilePath != null) {
        final result = await OpenFile.open(cachedFilePath);
        if (result.type == ResultType.error) {
          _showErrorSnackBar(
              AppLocalizations.of(context)!.translate('failed_to_open_file'));
        }
        return;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress[fileId] = 0;
      });

      final enteredDomainMap = await ApiService().getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];

      final fullUrl = Uri.parse(
          'https://$enteredDomain-back.$enteredMainDomain/storage/$fileUrl');

      // Создаём постоянную директорию для файлов
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cached_files');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final fileName =
          '${fileId}_${fileUrl.split('/').last}'; // Добавляем fileId к имени файла
      final filePath = '${cacheDir.path}/$fileName';

      final dio = Dio();
      await dio.download(fullUrl.toString(), filePath,
          onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _downloadProgress[fileId] = received / total;
          });
        }
      });

      // Сохраняем информацию о файле в постоянном кэше
      await FileCacheManager().cacheFile(fileId, filePath);

      setState(() {
        _downloadProgress.remove(fileId);
        _isDownloading = false;
      });

      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.error) {
        _showErrorSnackBar(
            AppLocalizations.of(context)!.translate('failed_to_open_file'));
      }
    } catch (e) {
      setState(() {
        _downloadProgress.remove(fileId);
        _isDownloading = false;
      });

      _showErrorSnackBar(AppLocalizations.of(context)!
          .translate('file_download_or_open_error'));
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
