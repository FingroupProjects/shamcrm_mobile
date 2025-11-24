import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_copy_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_delete.dart';
import 'package:crm_task_manager/screens/task/task_details/task_edit_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_navigate_to_chat.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'dropdown_history_task.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final int? taskNumber;
  final String taskName;
  final String taskStatus;
  final int? statusId;
  final String? project;
  final int? projectId;
  final List<int>? userId;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String? sum;
  final int? priority;
  final List<CustomFields> customFields;
  final String? taskFile;
  final List<TaskFiles>? files;
  final DateTime? initialDate;

  TaskDetailsScreen({
    required this.taskId,
    this.taskNumber,
    required this.taskName,
    required this.taskStatus,
    this.statusId,
    this.project,
    this.projectId,
    this.userId,
    this.description,
    this.startDate,
    this.endDate,
    this.sum,
    this.files,
    this.priority,
    required this.customFields,
    this.taskFile,
    this.initialDate,
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
  bool _canCreateTask = false;
  bool _hasTaskCreateForMySelfPermission = false;
  int? _currentUserId;
  bool _isAuthor = false;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isDownloading = false;
  Map<int, double> _downloadProgress = {};

  final GlobalKey keyTaskEdit = GlobalKey();
  final GlobalKey keyTaskDelete = GlobalKey();
  final GlobalKey keyTaskNavigateChat = GlobalKey();
  final GlobalKey keyTaskForReview = GlobalKey();
  final GlobalKey keyTaskHistory = GlobalKey();

  //
  List<FieldConfiguration> _fieldConfiguration = [];
  bool _isConfigurationLoaded = false;

  // List<TargetFocus> targets = [];
  // bool _isTutorialShown = false;
  // bool _isTutorialInProgress = false;
  // Map<String, dynamic>? tutorialProgress;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(FetchTaskStatuses());
    _checkPermissions();
    context
        .read<TaskByIdBloc>()
        .add(FetchTaskByIdEvent(taskId: int.parse(widget.taskId)));
    _loadFieldConfiguration();
    // _fetchTutorialProgress();
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'tasks');
      if (!mounted) return;

      // Фильтруем только активные поля и сортируем по position
      final activeFields = response.result.where((field) => field.isActive).toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      setState(() {
        _fieldConfiguration = activeFields;
        _isConfigurationLoaded = true;
      });
    } catch (e) {
      // В случае ошибки показываем поля в стандартном порядке
      if (mounted) {
        setState(() {
          _isConfigurationLoaded = true;
        });
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userID');
      final int? userId = userIdString != null ? int.tryParse(userIdString) : null;

      final results = await Future.wait([
        _apiService.hasPermission('task.update'),
        _apiService.hasPermission('task.delete'),
        _apiService.hasPermission('task.create'),
        _apiService.hasPermission('task.createForMySelf'),
      ]);

      setState(() {
        _canEditTask = results[0] as bool;
        _canDeleteTask = results[1] as bool;
        _canCreateTask = results[2] as bool;
        _hasTaskCreateForMySelfPermission = results[3] as bool;
        _currentUserId = userId;
        // _isAuthor обновляется в _updateDetails, чтобы избежать зависимости от null currentTask
      });
    } catch (e) {
      //print('TaskDetailsScreen: Error checking permissions or userID: $e');
      setState(() {
        _canEditTask = false;
        _canDeleteTask = false;
        _canCreateTask = false;
        _hasTaskCreateForMySelfPermission = false;
        _currentUserId = null;
        _isAuthor = false;
      });
    }
  }

  // void _initTutorialTargets() {
  //   targets.addAll([
  //     createTarget(
  //       identify: "TaskEdit",
  //       keyTarget: keyTaskEdit,
  //       title: AppLocalizations.of(context)!.translate('tutorial_task_details_edit_title'),
  //       description: AppLocalizations.of(context)!.translate('tutorial_task_details_edit_description'),
  //       align: ContentAlign.bottom,
  //       context: context,
  //       contentPosition: ContentPosition.above,
  //     ),
  //     if (_canDeleteTask || (_hasTaskCreateForMySelfPermission && _isAuthor))
  //       createTarget(
  //         identify: "TaskDelete",
  //         keyTarget: keyTaskDelete,
  //         title: AppLocalizations.of(context)!.translate('tutorial_task_details_delete_title'),
  //         description: AppLocalizations.of(context)!.translate('tutorial_task_details_delete_description'),
  //         align: ContentAlign.bottom,
  //         context: context,
  //         contentPosition: ContentPosition.above,
  //       ),
  //     createTarget(
  //       identify: "TaskNavigateChat",
  //       keyTarget: keyTaskNavigateChat,
  //       title: AppLocalizations.of(context)!.translate('tutorial_task_details_chat_title'),
  //       description: AppLocalizations.of(context)!.translate('tutorial_task_details_chat_description'),
  //       align: ContentAlign.bottom,
  //       context: context,
  //     ),
  //     createTarget(
  //       identify: "TaskForReview",
  //       keyTarget: keyTaskForReview,
  //       title: AppLocalizations.of(context)!.translate('tutorial_task_details_review_title'),
  //       description: AppLocalizations.of(context)!.translate('tutorial_task_details_review_description'),
  //       align: ContentAlign.bottom,
  //       context: context,
  //     ),
  //     createTarget(
  //         identify: "TaskHistory",
  //         keyTarget: keyTaskHistory,
  //         title: AppLocalizations.of(context)!.translate('tutorial_task_details_history_title'),
  //         description: AppLocalizations.of(context)!.translate('tutorial_task_details_history_description'),
  //         align: ContentAlign.top,
  //         context: context,
  //         contentPosition: ContentPosition.above,
  //         contentPadding: EdgeInsets.only(bottom: 70)),
  //   ]);
  // }

  // void showTutorial() async {
  //   if (_isTutorialInProgress) {
  //     return;
  //   }

  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   bool isTutorialShown = prefs.getBool('isTutorialShownTasksDet') ?? false;

  //   if (tutorialProgress == null ||
  //       tutorialProgress!['tasks']?['view'] == true ||
  //       isTutorialShown ||
  //       _isTutorialShown) {
  //     return;
  //   }

  //   setState(() {
  //     _isTutorialInProgress = true;
  //   });
  //   await Future.delayed(const Duration(milliseconds: 500));

  //   TutorialCoachMark(
  //     targets: targets,
  //     textSkip: AppLocalizations.of(context)!.translate('skip'),
  //     textStyleSkip: TextStyle(
  //       color: Colors.white,
  //       fontFamily: 'Gilroy',
  //       fontSize: 20,
  //       fontWeight: FontWeight.w600,
  //       shadows: [
  //         Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
  //         Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
  //         Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
  //         Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
  //       ],
  //     ),
  //     colorShadow: Color(0xff1E2E52),
  //     onSkip: () {
  //       prefs.setBool('isTutorialShownTasksDet', true);
  //       _apiService.markPageCompleted("tasks", "view").catchError((e) {});
  //       setState(() {
  //         _isTutorialShown = true;
  //         _isTutorialInProgress = false;
  //       });
  //       return true;
  //     },
  //     onFinish: () {
  //       prefs.setBool('isTutorialShownTasksDet', true);
  //       _apiService.markPageCompleted("tasks", "view").catchError((e) {});
  //       setState(() {
  //         _isTutorialShown = true;
  //         _isTutorialInProgress = false;
  //       });
  //     },
  //   ).show(context: context);
  // }

  // Future<void> _fetchTutorialProgress() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final progress = await _apiService.getTutorialProgress();
  //     setState(() {
  //       tutorialProgress = progress['result'];
  //     });
  //     await prefs.setString('tutorial_progress', json.encode(progress['result']));

  //     bool isTutorialShown = prefs.getBool('isTutorialShownTasksDet') ?? false;
  //     setState(() {
  //       _isTutorialShown = isTutorialShown;
  //     });

  //     _initTutorialTargets();

  //     if (tutorialProgress != null &&
  //         tutorialProgress!['tasks']?['view'] == false &&
  //         !isTutorialShown &&
  //         !_isTutorialInProgress &&
  //         targets.isNotEmpty &&
  //         mounted) {
  //       //showTutorial();
  //     }
  //   } catch (e) {
  //     final prefs = await SharedPreferences.getInstance();
  //     final savedProgress = prefs.getString('tutorial_progress');
  //     if (savedProgress != null) {
  //       setState(() {
  //         tutorialProgress = json.decode(savedProgress);
  //       });
  //       bool isTutorialShown = prefs.getBool('isTutorialShownTasksDet') ?? false;
  //       setState(() {
  //         _isTutorialShown = isTutorialShown;
  //       });

  //       _initTutorialTargets();

  //       if (tutorialProgress != null &&
  //           tutorialProgress!['tasks']?['view'] == false &&
  //           !isTutorialShown &&
  //           !_isTutorialInProgress &&
  //           targets.isNotEmpty &&
  //           mounted) {
  //         //showTutorial();
  //       }
  //     }
  //   }
  // }

  // void _updateDetails(TaskById? task) {
  //   if (task == null) {
  //     currentTask = null;
  //     details.clear();
  //     _isAuthor = false; // Обновляем _isAuthor
  //     return;
  //   }
  //
  //   currentTask = task;
  //   _isAuthor = _currentUserId != null && task.author?.id != null && _currentUserId == task.author!.id;
  //
  //   final Map<int, String> priorityLevels = {
  //     1: AppLocalizations.of(context)!.translate('normal'),
  //     2: AppLocalizations.of(context)!.translate('normal'),
  //     3: AppLocalizations.of(context)!.translate('urgent'),
  //   };
  //
  //   details = [
  //     {
  //       'label': AppLocalizations.of(context)!.translate('task_name'),
  //       'value': task.name ?? ''
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('priority_level_colon'),
  //       'value': priorityLevels[task.priority] ?? AppLocalizations.of(context)!.translate('normal'),
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('description_details'),
  //       'value': task.description?.isNotEmpty == true ? task.description! : ''
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('assignee'),
  //       'value': task.user != null && task.user!.isNotEmpty
  //           ? task.user!.map((user) => '${user.name} ${user.lastname ?? ''}').join(', ')
  //           : '',
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('project_details'),
  //       'value': task.project?.name ?? ''
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('dead_line'),
  //       'value': task.endDate != null && task.endDate!.isNotEmpty
  //           ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!))
  //           : ''
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('status_details'),
  //       'value': task.taskStatus?.taskStatus?.name ?? '',
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('author_details'),
  //       'value': task.author?.name ?? ''
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('creation_date_details'),
  //       'value': formatDate(task.createdAt)
  //     },
  //     if (task.deal != null && (task.deal?.name?.isNotEmpty == true))
  //       {
  //         'label': AppLocalizations.of(context)!.translate('task_by_deal'),
  //         'value': task.deal!.name!
  //       },
  //     if (task.files != null && task.files!.isNotEmpty)
  //       {
  //         'label': AppLocalizations.of(context)!.translate('files_details'),
  //         'value': task.files!.length.toString() + ' ' + AppLocalizations.of(context)!.translate('files'),
  //       },
  //   ];
  //
  //   for (var field in task.taskCustomFields) {
  //     details.add({'label': '${field.name}:', 'value': field.value});
  //   }
  //
  //   if (task.directoryValues != null && task.directoryValues!.isNotEmpty) {
  //     for (var dirValue in task.directoryValues!) {
  //       final values = dirValue.entry.values;
  //       final fieldValue = values.isNotEmpty ? values.first.value : '';
  //
  //       details.add({
  //         'label': '${dirValue.entry.directory.name}:',
  //         'value': fieldValue,
  //       });
  //     }
  //   }
  // }

  void _updateDetails(TaskById? task) {

    debugPrint("Custom Fields");
    debugPrint("${task?.customFields.map((e) => e.name).toList()}");
    debugPrint("${task?.customFields.map((e) => e.id).toList()}");
    debugPrint("${task?.customFields.map((e) => e.value).toList()}");
    debugPrint("${task?.customFields.map((e) => e.type).toList()}");

    currentTask = task;
    details.clear();

    if (task == null || !_isConfigurationLoaded) {
      _isAuthor = false;
      return;
    }

    _isAuthor = _currentUserId != null &&
        task.author?.id != null &&
        _currentUserId == task.author!.id;

    for (var fc in _fieldConfiguration) {
      // Пропускаем поле 'files', так как оно всегда показывается в конце
      if (fc.fieldName == 'files') {
        continue;
      }
      
      final value = _getFieldValue(fc, task);
      final label = _getFieldName(fc);

      details.add({'label': label, 'value': value});
    }

    // Всегда добавляем файлы в конец списка, если они есть
    if (task.files != null && task.files!.isNotEmpty) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('files_details'),
        'value': '${task.files!.length} ${AppLocalizations.of(context)!.translate('files')}',
      });
    }
  }

  String _getFieldName(FieldConfiguration fc) {
    if (fc.isCustomField || fc.isDirectory) {
      return '${fc.fieldName}:';
    }

    switch (fc.fieldName) {
      case 'name':          return AppLocalizations.of(context)!.translate('task_name');
      case 'task_status_id':return AppLocalizations.of(context)!.translate('priority_level_colon');
      case 'description':   return AppLocalizations.of(context)!.translate('description_details');
      case 'executor':      return AppLocalizations.of(context)!.translate('assignee');
      case 'project':       return AppLocalizations.of(context)!.translate('project_details');
      case 'deadline':      return AppLocalizations.of(context)!.translate('dead_line');
      case 'taskStatus':    return AppLocalizations.of(context)!.translate('status_details');
      case 'author':        return AppLocalizations.of(context)!.translate('author_details');
      case 'createdAt':     return AppLocalizations.of(context)!.translate('creation_date_details');
      case 'deal':          return AppLocalizations.of(context)!.translate('task_by_deal');
      default:              return '${fc.fieldName}:';
    }
  }

  String _getFieldValue(FieldConfiguration fc, TaskById task) {
    if (fc.isCustomField && fc.customFieldId != null) {
      for (final field in task.customFields) {
        if (field.name == fc.fieldName) {
          if (field.value.isNotEmpty) {
            return field.value;
          }
          break;
        }
      }
      return '';
    }

    if (fc.isDirectory && fc.directoryId != null) {
      for (var dirValue in task.directoryValues ?? []) {
        if (dirValue.entry.directory.id == fc.directoryId) {

          List<String> values = [];
          for (var fieldValue in dirValue.entry.values) {
            if (fieldValue.value.isNotEmpty) {
              values.add(fieldValue.value);
            }
          }

          if (values.isNotEmpty) {
            return values.join(', ');
          }
        }
      }
      return '';
    }

    final priorityLevels = {
      1: AppLocalizations.of(context)!.translate('normal'),
      2: AppLocalizations.of(context)!.translate('normal'),
      3: AppLocalizations.of(context)!.translate('urgent'),
    };

    switch (fc.fieldName) {
      case 'name':        return task.name ?? '';
      case 'task_status_id':    return priorityLevels[task.priority] ?? AppLocalizations.of(context)!.translate('normal');
      case 'description': return task.description ?? '';
      case 'executor':
        if (task.user == null || task.user!.isEmpty) return '';
        return task.user!.map((u) => '${u.name} ${u.lastname ?? ''}').join(', ');
      case 'project':     return task.project?.name ?? '';
      case 'deadline':
        if (task.endDate == null || task.endDate!.isEmpty) return '';
        return DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!));
      case 'taskStatus':  return task.taskStatus?.taskStatus?.name ?? '';
      case 'author':      return task.author?.name ?? '';
      case 'createdAt':   return formatDate(task.createdAt);
      case 'deal':        return task.deal?.name ?? '';
      default:            return '';
    }
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    // Закомментирован код туториала
    // if (!_isTutorialShown) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     //showTutorial();
    //     setState(() {
    //       _isTutorialShown = true;
    //     });
    //   });
    // }
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
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
        offset: const Offset(-10, 0),
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
            if (_canCreateTask || (_hasTaskCreateForMySelfPermission && _isAuthor))
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Image.asset(
                  'assets/icons/copy.png',
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
                        builder: (context) => TaskCopyScreen(
                          taskId: currentTask!.id,
                          taskName: currentTask!.name,
                          priority: currentTask!.priority,
                          taskStatus:
                          currentTask!.taskStatus?.taskStatus.toString() ??
                              '',
                          project: currentTask!.project?.id.toString(),
                          user: currentTask!.user != null &&
                              currentTask!.user!.isNotEmpty
                              ? currentTask!.user!
                              .map((user) => user.id)
                              .toList()
                              : null,
                          statusId: currentTask!.taskStatus?.id ?? 0,
                          description: currentTask!.description,
                          startDate: currentTask!.startDate,
                          endDate: currentTask!.endDate,
                          createdAt: createdAtString,
                          taskCustomFields: currentTask!.customFields,
                          files: currentTask!.files,
                          directoryValues: currentTask!.directoryValues,
                        ),
                      ),
                    );
                    if (shouldUpdate == true) {
                      context
                          .read<TaskByIdBloc>()
                          .add(FetchTaskByIdEvent(taskId: currentTask!.id));
                      context.read<TaskBloc>().add(FetchTaskStatuses());
                      context.read<CalendarBloc>().add(FetchCalendarEvents(
                          widget.initialDate?.month ?? DateTime.now().month,
                          widget.initialDate?.year ?? DateTime.now().year));
                    }
                  }
                },
              ),
            if (_canEditTask || (_hasTaskCreateForMySelfPermission && _isAuthor))
              IconButton(
                key: keyTaskEdit,
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
                          taskStatus:
                              currentTask!.taskStatus?.taskStatus.toString() ??
                                  '',
                          project: currentTask!.project?.id.toString(),
                          user: currentTask!.user != null &&
                                  currentTask!.user!.isNotEmpty
                              ? currentTask!.user!
                                  .map((user) => user.id)
                                  .toList()
                              : null,
                          statusId: currentTask!.taskStatus?.id ?? 0,
                          description: currentTask!.description,
                          startDate: currentTask!.startDate,
                          endDate: currentTask!.endDate,
                          createdAt: createdAtString,
                          taskCustomFields: currentTask!.customFields,
                          files: currentTask!.files,
                          directoryValues: currentTask!.directoryValues,
                        ),
                      ),
                    );
                    if (shouldUpdate == true) {
                      context
                          .read<TaskByIdBloc>()
                          .add(FetchTaskByIdEvent(taskId: currentTask!.id));
                      context.read<TaskBloc>().add(FetchTaskStatuses());
                      context.read<CalendarBloc>().add(FetchCalendarEvents(
                          widget.initialDate?.month ?? DateTime.now().month,
                          widget.initialDate?.year ?? DateTime.now().year));
                    }
                  }
                },
              ),
            if (_canDeleteTask || (_hasTaskCreateForMySelfPermission && _isAuthor))
              IconButton(
                key: keyTaskDelete,
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
    if (label == AppLocalizations.of(context)!.translate('task_name') ||
        label == AppLocalizations.of(context)!.translate('description_details') ||
        label == AppLocalizations.of(context)!.translate('project_details') ||
        label == AppLocalizations.of(context)!.translate('author_details') ||
        label == AppLocalizations.of(context)!.translate('status_details')) {
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
            height: 120,
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
                        FileUtils.showFile(
                          context: context,
                          fileUrl: file.path,
                          fileId: file.id,
                          setState: setState,
                          downloadProgress: _downloadProgress,
                          isDownloading: _isDownloading,
                          apiService: _apiService,
                        );
                      }
                    },
                    child: Container(
                      width: 100,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
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
                  statusId: 0,
                  sum: '',
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
    final priorityColors = {
      AppLocalizations.of(context)!.translate('normal'): Color(0xFFE8F5E9),
      AppLocalizations.of(context)!.translate('normal'): Color(0xFFE8F5E9),
      AppLocalizations.of(context)!.translate('urgent'): Color(0xFFFFEBEE),
    };
    return priorityColors[priority] ?? Color(0xFFE8F5E9);
  }

  Color _getPriorityBorderColor(String priority) {
    final priorityBorderColors = {
      AppLocalizations.of(context)!.translate('normal'): Colors.green,
      AppLocalizations.of(context)!.translate('normal'): Colors.green,
      AppLocalizations.of(context)!.translate('urgent'): Colors.red,
    };
    return priorityBorderColors[priority] ?? Color(0xFF2E7D32);
  }

  Color _getPriorityColor(String priority) {
    final priorityColors = {
      AppLocalizations.of(context)!.translate('normal'): Color(0xFF2E7D32),
      AppLocalizations.of(context)!.translate('normal'): Color(0xFF2E7D32),
      AppLocalizations.of(context)!.translate('urgent'): Color(0xFFC62828),
    };
    return priorityColors[priority] ?? Color(0xFF2E7D32);
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
                  itemExtent: 56,
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0),
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

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
    }
  }

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
                    textAlign: TextAlign.justify,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskByIdBloc, TaskByIdState>(
      listener: (context, state) {
        if (state is TaskByIdError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
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
          // Удаляем вызов _updateDetails из BlocBuilder, чтобы избежать setState
          // if (state is TaskByIdLoaded) {
          //   // Обновляем данные без setState
          //   currentTask = state.task;
          //   _isAuthor = _currentUserId != null && state.task.author?.id != null && _currentUserId == state.task!.author!.id;
          //
          //   final Map<int, String> priorityLevels = {
          //     1: AppLocalizations.of(context)!.translate('normal'),
          //     2: AppLocalizations.of(context)!.translate('normal'),
          //     3: AppLocalizations.of(context)!.translate('urgent'),
          //   };
          //
          //   details = [
          //     {
          //       'label': AppLocalizations.of(context)!.translate('task_name'),
          //       'value': state.task!.name ?? ''
          //     },
          //     {
          //       'label': AppLocalizations.of(context)!.translate('priority_level_colon'),
          //       'value': priorityLevels[state.task!.priority] ?? AppLocalizations.of(context)!.translate('normal'),
          //     },
          //     {
          //       'label': AppLocalizations.of(context)!.translate('description_details'),
          //       'value': state.task!.description?.isNotEmpty == true ? state.task!.description! : ''
          //     },
          //     {
          //       'label': AppLocalizations.of(context)!.translate('assignee'),
          //       'value': state.task!.user != null && state.task!.user!.isNotEmpty
          //           ? state.task!.user!.map((user) => '${user.name} ${user.lastname ?? ''}').join(', ')
          //           : '',
          //     },
          //     {
          //       'label': AppLocalizations.of(context)!.translate('project_details'),
          //       'value': state.task!.project?.name ?? ''
          //     },
          //     {
          //       'label': AppLocalizations.of(context)!.translate('dead_line'),
          //       'value': state.task!.endDate != null && state.task!.endDate!.isNotEmpty
          //           ? DateFormat('dd.MM.yyyy').format(DateTime.parse(state.task!.endDate!))
          //           : ''
          //     },
          //     {
          //       'label': AppLocalizations.of(context)!.translate('status_details'),
          //       'value': state.task!.taskStatus?.taskStatus?.name ?? '',
          //     },
          //     {
          //       'label': AppLocalizations.of(context)!.translate('author_details'),
          //       'value': state.task!.author?.name ?? ''
          //     },
          //     {
          //       'label': AppLocalizations.of(context)!.translate('creation_date_details'),
          //       'value': formatDate(state.task!.createdAt)
          //     },
          //     if (state.task!.deal != null && (state.task!.deal?.name?.isNotEmpty == true))
          //       {
          //         'label': AppLocalizations.of(context)!.translate('task_by_deal'),
          //         'value': state.task!.deal!.name!
          //       },
          //     if (state.task!.files != null && state.task!.files!.isNotEmpty)
          //       {
          //         'label': AppLocalizations.of(context)!.translate('files_details'),
          //         'value': state.task!.files!.length.toString() + ' ' + AppLocalizations.of(context)!.translate('files'),
          //       },
          //   ];
          //
          //   for (var field in state.task!.taskCustomFields) {
          //     details.add({'label': '${field.name}:', 'value': field.value});
          //   }
          //
          //   if (state.task.directoryValues != null && state.task!.directoryValues!.isNotEmpty) {
          //     for (var dirValue in state.task.directoryValues!) {
          //       final values = dirValue.entry.values; // This is a List
          //       final fieldValue = values.isNotEmpty ? values.first.value : ''; // take first value safely
          //
          //       details.add({
          //         'label': '${dirValue.entry.directory.name}:',
          //         'value': fieldValue,
          //       });
          //     }
          //   }
          //
          // }
          if (state is TaskByIdLoaded) {
            _updateDetails(state.task);
          } else {
            currentTask = null;
            details.clear();
            _isAuthor = false;
          }

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

            return Scaffold(
              appBar: _buildAppBar(context, '${AppLocalizations.of(context)!.translate('view_task')} №${task.taskNumber ?? ""}'),
              backgroundColor: Colors.white,
              body: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListView(
                  children: [
                    _buildDetailsList(),
   if (task.chat != null || task.isFinished == 0)
  Row(
    children: [
      if (task.chat != null)
        Expanded(
          key: keyTaskNavigateChat,
          flex: task.isFinished == 1 ? 100 : 55,
          child: TaskNavigateToChat(
            chatId: task.chat!.id,
            taskName: widget.taskName,
            canSendMessage: task.chat!.canSendMessage,
          ),
        ),
      if (task.isFinished == 0) ...[
        if (task.chat != null) SizedBox(width: 8, height: 60),
        Expanded(
          key: keyTaskForReview,
          flex: task.chat != null ? 45 : 100,
          child: ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                title: Text(
                  AppLocalizations.of(context)!.translate('confirm_task_completion'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w500),
                ),
                content: Container(
                  width: double.maxFinite,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size(80, 48),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.translate('cancel'),
                            style: TextStyle(color: Colors.white, fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: StatefulBuilder(
                          builder: (context, setState) => TextButton(
                            onPressed: _isLoading ? null : () async {
                              setState(() => _isLoading = true);
                              final taskId = int.parse(widget.taskId);
                              try {
                                final result = await context.read<ApiService>().finishTask(taskId);
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? '', style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                    elevation: 3,
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                if (result['success'] == true) {
                                  context.read<CalendarBloc>().add(FetchCalendarEvents(widget.initialDate?.month ?? DateTime.now().month, widget.initialDate?.year ?? DateTime.now().year));
                                  context.read<TaskBloc>().add(FetchTaskStatuses());
                                }
                              } catch (e) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString(), style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)), backgroundColor: Colors.red),
                                );
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Color(0xff1E2E52),
                              minimumSize: Size(130, 48),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isLoading
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(AppLocalizations.of(context)!.translate('confirm'), style: TextStyle(color: Colors.white, fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Color(0xFF1E2E52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('for_review'),
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Gilroy'),
            ),
          ),
        ),
      ],
    ],
  ),
                    const SizedBox(height: 16),
                    ActionHistoryWidgetTask(
                        taskId: int.parse(widget.taskId), key: keyTaskHistory),
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
}