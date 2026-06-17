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
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
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
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart'
    as task_status_sheet;
import 'package:crm_task_manager/screens/task/task_details/task_edit_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_navigate_to_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dropdown_history_task.dart';
import 'task_history_dialog.dart';

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
  late final int _initialStatusId;
  int? _currentStatusId;
  bool _statusChangedFromDetails = false;
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

  // Field configuration
  List<FieldConfiguration> _fieldConfiguration = [];
  bool _isConfigurationLoaded = false;

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) => context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) => context.appColors.borderSubtle;
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.surfaceElevated;
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _screenSurfaceElevated(BuildContext context) =>
      context.appColors.surfaceElevated;
  Color _screenAccent(BuildContext context) =>
      context.appColors.buttonPrimaryBg;

  String _getTaskErrorMessage(String error) {
    if (error.toLowerCase().contains('интернет')) {
      return error;
    }
    return 'Задача была удалена';
  }

  @override
  void initState() {
    super.initState();
    _initialStatusId = widget.statusId ?? 0;
    _currentStatusId = widget.statusId;
    context.read<TaskBloc>().add(FetchTaskStatuses(forceRefresh: true));
    _checkPermissions();
    context
        .read<TaskByIdBloc>()
        .add(FetchTaskByIdEvent(taskId: int.parse(widget.taskId)));
    _loadFieldConfiguration();
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'tasks');
      if (!mounted) return;

      // Фильтруем только активные поля и сортируем по position
      final activeFields = response.result
          .where((field) => field.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      setState(() {
        _fieldConfiguration = activeFields;
        _isConfigurationLoaded = true;
      });

      // Если данные уже загружены, обновляем детали с новой конфигурацией
      if (currentTask != null) {
        _updateDetails(currentTask);
      }
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
      final int? userId =
          userIdString != null ? int.tryParse(userIdString) : null;

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
      });
    } catch (e) {
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

  Map<String, dynamic> _buildNavigationResult() {
    return {
      'refresh': _statusChangedFromDetails,
      'statusId': _initialStatusId,
      'newStatusId': _currentStatusId ?? _initialStatusId,
    };
  }

  Future<bool> _handleBackNavigation() async {
    if (!mounted) return false;
    Navigator.pop(context, _buildNavigationResult());
    return false;
  }

  void _refreshTaskView() {
    if (currentTask == null) return;
    final taskId = currentTask!.id;
    setState(() {
      currentTask = null;
      details.clear();
      _isAuthor = false;
      _isConfigurationLoaded = false;
    });
    _loadFieldConfiguration();
    context.read<TaskByIdBloc>().add(FetchTaskByIdEvent(taskId: taskId));
    context.read<TaskBloc>().add(FetchTaskStatuses(forceRefresh: true));
    context.read<CalendarBloc>().add(FetchCalendarEvents(
        widget.initialDate?.month ?? DateTime.now().month,
        widget.initialDate?.year ?? DateTime.now().year));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<TaskByIdBloc>().add(FetchTaskByIdEvent(taskId: taskId));
      context.read<TaskBloc>().add(FetchTaskStatuses(forceRefresh: true));
    });
  }

  void _openStatusChangeSheet() {
    if (currentTask == null) return;

    final task = Task(
      id: currentTask!.id,
      taskNumber: currentTask!.taskNumber,
      name: currentTask!.name,
      startDate: currentTask!.startDate,
      endDate: currentTask!.endDate,
      description: currentTask!.description,
      statusId:
          currentTask!.taskStatus?.id ?? _currentStatusId ?? _initialStatusId,
      priority: currentTask!.priority,
      customFields: const [],
    );

    task_status_sheet.DropdownBottomSheet(
      context,
      currentTask!.taskStatus?.taskStatus?.name ?? widget.taskStatus,
      (String _, int newStatusId) {
        if (!mounted) return;
        setState(() {
          _statusChangedFromDetails = true;
          _currentStatusId = newStatusId;
        });
        _refreshTaskView();
      },
      task,
    );
  }

  void _openTaskHistoryDialog() {
    if (currentTask == null) return;
    showDialog(
      context: context,
      builder: (BuildContext context) => TaskHistoryDialog(
        taskId: currentTask!.id,
      ),
    );
  }

  Future<void> _openTaskCopyScreen() async {
    if (currentTask == null) return;

    final createdAtString =
        currentTask?.createdAt != null && currentTask!.createdAt!.isNotEmpty
            ? DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(currentTask!.createdAt!))
            : null;

    final shouldUpdate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskCopyScreen(
          taskId: currentTask!.id,
          taskName: currentTask!.name,
          priority: currentTask!.priority,
          taskStatus: currentTask!.taskStatus?.taskStatus.toString() ?? '',
          project: currentTask!.project?.id.toString(),
          user: currentTask!.user != null && currentTask!.user!.isNotEmpty
              ? currentTask!.user!.map((user) => user.id).toList()
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
      setState(() {
        _statusChangedFromDetails = true;
      });
      _loadFieldConfiguration();
      context
          .read<TaskByIdBloc>()
          .add(FetchTaskByIdEvent(taskId: currentTask!.id));
      context.read<TaskBloc>().add(FetchTaskStatuses(forceRefresh: true));
      context.read<CalendarBloc>().add(FetchCalendarEvents(
          widget.initialDate?.month ?? DateTime.now().month,
          widget.initialDate?.year ?? DateTime.now().year));
    }
  }

  Future<void> _openTaskEditScreen() async {
    if (currentTask == null) return;

    final createdAtString =
        currentTask?.createdAt != null && currentTask!.createdAt!.isNotEmpty
            ? DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(currentTask!.createdAt!))
            : null;

    final shouldUpdate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(
          taskId: currentTask!.id,
          taskName: currentTask!.name,
          priority: currentTask!.priority,
          taskStatus: currentTask!.taskStatus?.taskStatus.toString() ?? '',
          project: currentTask!.project?.id.toString(),
          user: currentTask!.user != null && currentTask!.user!.isNotEmpty
              ? currentTask!.user!.map((user) => user.id).toList()
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
      setState(() {
        _statusChangedFromDetails = true;
      });
      _loadFieldConfiguration();
      context
          .read<TaskByIdBloc>()
          .add(FetchTaskByIdEvent(taskId: currentTask!.id));
      context.read<TaskBloc>().add(FetchTaskStatuses(forceRefresh: true));
      context.read<CalendarBloc>().add(FetchCalendarEvents(
          widget.initialDate?.month ?? DateTime.now().month,
          widget.initialDate?.year ?? DateTime.now().year));
    }
  }

  void _openTaskDeleteDialog() {
    if (currentTask == null) return;
    showDialog(
      context: context,
      builder: (context) => DeleteTaskDialog(taskId: currentTask!.id),
    );
  }

  Future<void> _handleAppBarMenuAction(String value) async {
    switch (value) {
      case 'history':
        _openTaskHistoryDialog();
        break;
      case 'copy':
        await _openTaskCopyScreen();
        break;
      case 'edit':
        await _openTaskEditScreen();
        break;
      case 'delete':
        _openTaskDeleteDialog();
        break;
    }
  }

  void _updateDetails(TaskById? task) {
    currentTask = task;
    details.clear();

    if (task == null || !_isConfigurationLoaded) {
      _isAuthor = false;
      return;
    }

    _isAuthor = _currentUserId != null &&
        task.author?.id != null &&
        _currentUserId == task.author!.id;

    bool authorAdded = false;
    bool createdAtAdded = false;
    bool dealAdded = false;
    bool statusAdded = false;

    for (var fc in _fieldConfiguration) {
      // Пропускаем поле 'files', так как оно всегда показывается в конце
      if (fc.fieldName == 'files') {
        continue;
      }

      // Отмечаем, если поле 'author' или 'createdAt' были добавлены из конфигурации
      if (fc.fieldName == 'author') {
        authorAdded = true;
      } else if (fc.fieldName == 'createdAt') {
        createdAtAdded = true;
      } else if (fc.fieldName == 'deal') {
        dealAdded = true;
      } else if (fc.fieldName == 'task_status_id' ||
          fc.fieldName == 'taskStatus') {
        statusAdded = true;
      }

      final value = _getFieldValue(fc, task);
      final label = _getFieldName(fc);

      details.add({
        'label': label,
        'value': value,
        'fieldName': fc.fieldName,
      });
    }

    // Всегда добавляем поле 'author', если оно не было добавлено из конфигурации
    if (!authorAdded && task.author != null) {
      final authorName = task.author!.fullName ??
          (task.author!.name != null && task.author!.lastname != null
              ? '${task.author!.name} ${task.author!.lastname}'
              : task.author!.name ?? '');
      if (authorName.isNotEmpty) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('author_details'),
          'value': authorName,
          'fieldName': 'author',
        });
      }
    }

    // Всегда добавляем дату создания, если она не была добавлена из конфигурации
    if (!createdAtAdded &&
        task.createdAt != null &&
        task.createdAt!.isNotEmpty) {
      details.add({
        'label':
            AppLocalizations.of(context)!.translate('creation_date_details'),
        'value': formatDate(task.createdAt),
        'fieldName': 'createdAt',
      });
    }

    // Всегда добавляем сделку, если задача создана на основе сделки,
    // но поле 'deal' отсутствует в конфигурации
    if (!dealAdded && task.deal != null && task.deal!.id != 0) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('task_by_deal'),
        'value': task.deal!.name,
        'fieldName': 'deal',
      });
    }

    // Всегда добавляем статус, если он не был добавлен из конфигурации
    if (!statusAdded) {
      final statusName = task.taskStatus?.taskStatus?.name ?? widget.taskStatus;
      if (statusName.isNotEmpty) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('status_details'),
          'value': statusName,
          'fieldName': 'task_status_id',
        });
      }
    }

    final refusalReason = (task.refusalReasonText ?? '').trim();
    final refusalComment = (task.reasonForRefusalComment ?? '').trim();
    if (refusalReason.isNotEmpty || refusalComment.isNotEmpty) {
      details.add({
        'label': 'Причина отказа:',
        'value': refusalReason.isNotEmpty ? refusalReason : refusalComment,
        'fieldName': 'reason_for_refusal',
      });
      if (refusalReason.isNotEmpty && refusalComment.isNotEmpty) {
        details.add({
          'label': 'Комментарий отказа:',
          'value': refusalComment,
          'fieldName': 'reason_for_refusal_comment',
        });
      }
    }

    // Всегда добавляем файлы в конец списка, если они есть
    if (task.files != null && task.files!.isNotEmpty) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('files_details'),
        'value':
            '${task.files!.length} ${AppLocalizations.of(context)!.translate('files')}',
        'fieldName': 'files',
      });
    }
  }

  String _getFieldName(FieldConfiguration fc) {
    if (fc.isCustomField || fc.isDirectory) {
      return '${fc.fieldName}:';
    }

    switch (fc.fieldName) {
      case 'name':
        return AppLocalizations.of(context)!.translate('task_name');
      case 'task_status_id':
        return AppLocalizations.of(context)!.translate('status_details');
      case 'description':
        return AppLocalizations.of(context)!.translate('description_details');
      case 'executor':
        return AppLocalizations.of(context)!.translate('assignee');
      case 'project':
        return AppLocalizations.of(context)!.translate('project_details');
      case 'deadline':
        return AppLocalizations.of(context)!.translate('dead_line');
      case 'taskStatus':
        return AppLocalizations.of(context)!.translate('status_details');
      case 'priority':
      case 'priority_level':
        return AppLocalizations.of(context)!.translate('priority_level_colon');
      case 'author':
        return AppLocalizations.of(context)!.translate('author_details');
      case 'createdAt':
        return AppLocalizations.of(context)!.translate('creation_date_details');
      case 'deal':
        return AppLocalizations.of(context)!.translate('task_by_deal');
      default:
        return '${fc.fieldName}:';
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
      case 'name':
        return task.name ?? '';
      case 'task_status_id':
        return task.taskStatus?.taskStatus?.name ?? widget.taskStatus;
      case 'description':
        return task.description ?? '';
      case 'executor':
        if (task.user == null || task.user!.isEmpty) return '';
        return task.user!
            .map((u) => '${u.name} ${u.lastname ?? ''}')
            .join(', ');
      case 'project':
        return task.project?.name ?? '';
      case 'deadline':
        if (task.endDate == null || task.endDate!.isEmpty) return '';
        return DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!));
      case 'taskStatus':
        return task.taskStatus?.taskStatus?.name ?? widget.taskStatus;
      case 'priority':
      case 'priority_level':
        return priorityLevels[task.priority] ??
            AppLocalizations.of(context)!.translate('normal');
      case 'author':
        if (task.author == null) return '';
        return task.author!.fullName ??
            (task.author!.name != null && task.author!.lastname != null
                ? '${task.author!.name} ${task.author!.lastname}'
                : task.author!.name ?? '');
      case 'createdAt':
        return formatDate(task.createdAt);
      case 'deal':
        return task.deal?.name ?? '';
      default:
        return '';
    }
  }

  Widget _buildExpandableText(String label, String value, double maxWidth) {
    final TextStyle style = TextStyle(
      fontSize: 16,
      fontFamily: 'Gilroy',
      fontWeight: FontWeight.w500,
      color: _screenPrimaryText(context),
      backgroundColor: context.appColors.overlay.withValues(alpha: 0),
    );

    return GestureDetector(
      onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ??
                  'Скопировано',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            backgroundColor: context.appColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Text(
        value,
        style: style.copyWith(
          decoration: TextDecoration.underline,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final baseColors = context.appColors;
    final baseTextStyles = context.appTextStyles;
    final baseShadows = context.appShadows;
    final screenTheme = baseTheme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        baseColors.copyWith(
          surfacePrimary: _screenSurfaceBackground(context),
          surfaceElevated: _screenSurfaceElevated(context),
          textPrimary: _screenPrimaryText(context),
          textSecondary: _screenSecondaryText(context),
          textMuted: _screenHintText(context),
          textInverse: _screenPrimaryText(context),
          iconPrimary: _screenPrimaryText(context),
          iconSecondary: _screenSecondaryText(context),
          borderPrimary: _screenBorder(context),
          borderSubtle: _screenBorder(context),
          buttonSecondaryBg: _screenFieldBackground(context),
          buttonSecondaryFg: _screenPrimaryText(context),
          fieldBg: _screenFieldBackground(context),
          fieldBorder: _screenBorder(context),
          fieldHint: _screenHintText(context),
          overlay: baseColors.overlay,
        ),
        baseTextStyles.copyWith(
          titleLg: baseTextStyles.titleLg
              .copyWith(color: _screenPrimaryText(context)),
          titleMd: baseTextStyles.titleMd
              .copyWith(color: _screenPrimaryText(context)),
          bodyLg: baseTextStyles.bodyLg
              .copyWith(color: _screenPrimaryText(context)),
          bodyMd: baseTextStyles.bodyMd.copyWith(
            color: _screenSecondaryText(context),
          ),
          bodySm: baseTextStyles.bodySm.copyWith(
            color: _screenSecondaryText(context),
          ),
          labelLg: baseTextStyles.labelLg
              .copyWith(color: _screenPrimaryText(context)),
          labelMd: baseTextStyles.labelMd.copyWith(
            color: _screenSecondaryText(context),
          ),
          caption:
              baseTextStyles.caption.copyWith(color: _screenHintText(context)),
        ),
        baseShadows,
      ],
    );
    final primaryText = _screenPrimaryText(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Theme(
        data: screenTheme,
        child: BlocListener<TaskByIdBloc, TaskByIdState>(
          listener: (context, state) {
            if (state is TaskByIdError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: context.appColors.error,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }
          },
          child: BlocBuilder<TaskByIdBloc, TaskByIdState>(
            builder: (context, state) {
              if (state is TaskByIdLoaded) {
                _updateDetails(state.task);
              } else {
                currentTask = null;
                details.clear();
                _isAuthor = false;
              }

              if (state is TaskByIdLoading || !_isConfigurationLoaded) {
                return Scaffold(
                  appBar: _buildAppBar(
                    context,
                    '${AppLocalizations.of(context)!.translate('view_task')} №${widget.taskNumber ?? ""}',
                  ),
                  backgroundColor:
                      context.appColors.overlay.withValues(alpha: 0),
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      const AppBackgroundOverlay(
                        preset: AppBackgroundPreset.aurora,
                      ),
                      Center(
                        child: CircularProgressIndicator(color: primaryText),
                      ),
                    ],
                  ),
                );
              } else if (state is TaskByIdLoaded) {
                if (state.task == null) {
                  return Scaffold(
                    appBar: _buildAppBar(
                      context,
                      '${AppLocalizations.of(context)!.translate('view_task')} №${widget.taskNumber ?? ""}',
                    ),
                    backgroundColor:
                        context.appColors.overlay.withValues(alpha: 0),
                    body: Stack(
                      fit: StackFit.expand,
                      children: [
                        const AppBackgroundOverlay(
                          preset: AppBackgroundPreset.aurora,
                        ),
                        Center(
                          child: Text(
                            AppLocalizations.of(context)!
                                .translate('task_data_unavailable'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                TaskById task = state.task!;
                final subtleBorder = _screenBorder(context);
                final formSurface = _screenSurfaceBackground(context);

                return Scaffold(
                  extendBodyBehindAppBar: false,
                  backgroundColor:
                      context.appColors.overlay.withValues(alpha: 0),
                  appBar: _buildAppBar(
                    context,
                    '${AppLocalizations.of(context)!.translate('view_task')} №${task.taskNumber ?? ""}',
                  ),
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      const AppBackgroundOverlay(
                        preset: AppBackgroundPreset.aurora,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        child: ListView(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 18, 18, 22),
                              decoration: BoxDecoration(
                                color: formSurface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: subtleBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.appColors.shadow
                                        .withValues(alpha: 0.14),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Container(
                                  //   padding: const EdgeInsets.symmetric(
                                  //     horizontal: 12,
                                  //     vertical: 8,
                                  //   ),
                                  //   decoration: BoxDecoration(
                                  //     color: _screenAccent(context)
                                  //         .withValues(alpha: 0.12),
                                  //     borderRadius: BorderRadius.circular(14),
                                  //     border: Border.all(
                                  //       color: _screenAccent(context)
                                  //           .withValues(alpha: 0.18),
                                  //     ),
                                  //   ),
                                  //   child: Row(
                                  //     mainAxisSize: MainAxisSize.min,
                                  //     children: [
                                  //       Icon(
                                  //         Icons.visibility_rounded,
                                  //         size: 18,
                                  //         color: _screenAccent(context),
                                  //       ),
                                  //       const SizedBox(width: 8),
                                  //       Text(
                                  //         AppLocalizations.of(context)!
                                  //             .translate('view_task'),
                                  //         style: TextStyle(
                                  //           fontSize: 15,
                                  //           fontFamily: 'Gilroy',
                                  //           fontWeight: FontWeight.w700,
                                  //           color: _screenAccent(context),
                                  //         ),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                  // const SizedBox(height: 16),
                                  _buildDetailsList(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (task.chat != null || task.isFinished == 0)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                decoration: BoxDecoration(
                                  color: formSurface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: subtleBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.appColors.shadow
                                          .withValues(alpha: 0.1),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: _screenAccent(context)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons
                                                .playlist_add_check_circle_rounded,
                                            size: 18,
                                            color: _screenAccent(context),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Выполнение',
                                          style: TextStyle(
                                            color: _screenPrimaryText(context),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Gilroy',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        if (task.chat != null)
                                          Expanded(
                                            key: keyTaskNavigateChat,
                                            flex:
                                                task.isFinished == 1 ? 100 : 55,
                                            child: TaskNavigateToChat(
                                              chatId: task.chat!.id,
                                              taskName: widget.taskName,
                                              canSendMessage:
                                                  task.chat!.canSendMessage,
                                            ),
                                          ),
                                        if (task.isFinished == 0) ...[
                                          if (task.chat != null)
                                            const SizedBox(
                                                width: 8, height: 56),
                                          Expanded(
                                            key: keyTaskForReview,
                                            flex: task.chat != null ? 45 : 100,
                                            child: SizedBox(
                                              height: 48,
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _showFinishTaskDialog(task),
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 0,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                                  backgroundColor:
                                                      _screenAccent(context),
                                                  foregroundColor: context
                                                      .appColors
                                                      .buttonPrimaryFg,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                ),
                                                icon: Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 18,
                                                  color: context.appColors
                                                      .buttonPrimaryFg,
                                                ),
                                                label: Text(
                                                  AppLocalizations.of(context)!
                                                      .translate('for_review'),
                                                  style: TextStyle(
                                                    color: context.appColors
                                                        .buttonPrimaryFg,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'Gilroy',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ActionHistoryWidgetTask(
                              taskId: int.parse(widget.taskId),
                              key: keyTaskHistory,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is TaskByIdError) {
                return Scaffold(
                  backgroundColor:
                      context.appColors.overlay.withValues(alpha: 0),
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      const AppBackgroundOverlay(
                        preset: AppBackgroundPreset.aurora,
                      ),
                      Center(
                        child: Text(
                          _getTaskErrorMessage(state.message),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ],
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
        ),
      ),
    );
  }

  void _showFinishTaskDialog(TaskById task) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _screenSurfaceBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _screenBorder(context)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        title: Text(
          AppLocalizations.of(context)!.translate('confirm_task_completion'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _screenPrimaryText(context),
          ),
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
                    backgroundColor: context.appColors.buttonDangerBg,
                    minimumSize: Size(80, 48),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('cancel'),
                    style: TextStyle(
                      color: context.appColors.buttonDangerFg,
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setState) => TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            final taskId = int.parse(widget.taskId);
                            try {
                              final result = await context
                                  .read<ApiService>()
                                  .finishTask(taskId);
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(this.context)!
                                        .translate(result['message'] ?? ''),
                                    style:
                                        context.appTextStyles.bodyMd.copyWith(
                                      color: context.appColors.textPrimary,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: result['success'] == true
                                      ? context.appColors.success
                                      : context.appColors.error,
                                  elevation: 3,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              if (result['success'] == true) {
                                this.context.read<CalendarBloc>().add(
                                    FetchCalendarEvents(
                                        widget.initialDate?.month ??
                                            DateTime.now().month,
                                        widget.initialDate?.year ??
                                            DateTime.now().year));
                                this
                                    .context
                                    .read<TaskBloc>()
                                    .add(FetchTaskStatuses(forceRefresh: true));
                              }
                            } catch (e) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(this.context)!
                                        .translate('error_task_finish'),
                                    style:
                                        context.appTextStyles.bodyMd.copyWith(
                                      color: context.appColors.textPrimary,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: context.appColors.error,
                                  elevation: 3,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                    style: TextButton.styleFrom(
                      backgroundColor: context.appColors.buttonPrimaryBg,
                      minimumSize: Size(130, 48),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: context.appColors.buttonPrimaryFg,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.translate('confirm'),
                            style: TextStyle(
                              color: context.appColors.buttonPrimaryFg,
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    final appBarGradient = [
      _screenSurfaceElevated(context),
      _screenFieldBackground(context),
    ];
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);
    final menuTextColor = _screenPrimaryText(context);
    final menuMutedColor = _screenSecondaryText(context);
    const menuDangerColor = Color(0xFFD92D20);

    PopupMenuItem<String> buildMenuItem({
      required String value,
      required IconData icon,
      required String label,
      Color? iconColor,
      Color? textColor,
    }) {
      return PopupMenuItem<String>(
        value: value,
        height: 46,
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: iconColor ?? menuMutedColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: textColor ?? menuTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: context.appColors.overlay.withValues(alpha: 0),
      forceMaterialTransparency: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: context.appColors.overlay.withValues(alpha: 0),
      shadowColor: context.appColors.overlay.withValues(alpha: 0),
      centerTitle: false,
      toolbarHeight: 74,
      titleSpacing: 16,
      title: AppBarShell(
        leading: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: IconButton(
            onPressed: _handleBackNavigation,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: primaryText,
            ),
          ),
        ),
        center: AppBarShell.capsule(
          context,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                color: primaryText,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                tooltip: '',
                color: _screenFieldBackground(context),
                surfaceTintColor: _screenFieldBackground(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: _handleAppBarMenuAction,
                itemBuilder: (context) => [
                  buildMenuItem(
                    value: 'history',
                    icon: Icons.history_rounded,
                    label: AppLocalizations.of(context)!.translate('history'),
                  ),
                  if (_canCreateTask ||
                      (_hasTaskCreateForMySelfPermission && _isAuthor))
                    buildMenuItem(
                      value: 'copy',
                      icon: Icons.content_copy_rounded,
                      label:
                          AppLocalizations.of(context)!.translate('copy_task'),
                    ),
                  if (_canEditTask ||
                      (_hasTaskCreateForMySelfPermission && _isAuthor))
                    buildMenuItem(
                      value: 'edit',
                      icon: Icons.edit_rounded,
                      label:
                          AppLocalizations.of(context)!.translate('task_edit'),
                    ),
                  if (_canDeleteTask ||
                      (_hasTaskCreateForMySelfPermission && _isAuthor))
                    const PopupMenuDivider(height: 8),
                  if (_canDeleteTask ||
                      (_hasTaskCreateForMySelfPermission && _isAuthor))
                    buildMenuItem(
                      value: 'delete',
                      icon: Icons.delete_outline_rounded,
                      label: AppLocalizations.of(context)!.translate('delete'),
                      iconColor: menuDangerColor,
                      textColor: menuDangerColor,
                    ),
                ],
                child: Center(
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: primaryText,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            details[index]['fieldName'] ?? '',
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, String fieldName) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (fieldName == 'task_status_id' || fieldName == 'taskStatus') {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openStatusChangeSheet,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: _screenPrimaryText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _screenPrimaryText(context),
                        size: 16,
                      ),
                    ],
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
                    final fileExtension =
                        file.name.split('.').last.toLowerCase();

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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            color: _screenFieldBackground(context),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _screenBorder(context)),
                          ),
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
                                      backgroundColor: context.appColors.overlay
                                          .withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _screenPrimaryText(context),
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
                                  color: _screenPrimaryText(context),
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

        if (fieldName == 'priority' || fieldName == 'priority_level') {
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

        if (fieldName == 'deal') {
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
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)
                            ?.translate('copied_to_clipboard') ??
                        'Скопировано',
                    style: context.appTextStyles.bodyMd.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  backgroundColor: context.appColors.success,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
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
                      color: _screenPrimaryText(context),
                      decoration:
                          value.isNotEmpty && currentTask?.deal?.id != null
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

        String effectiveLabel = label;
        if (fieldName == 'executor' && value.contains(',')) {
          effectiveLabel = AppLocalizations.of(context)!.translate('assignees');
        }

        if (fieldName == 'executor' &&
            effectiveLabel ==
                AppLocalizations.of(context)!.translate('assignees')) {
          return GestureDetector(
            onTap: () => _showUsersDialog(value),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)
                            ?.translate('copied_to_clipboard') ??
                        'Скопировано',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: context.appColors.success,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(effectiveLabel),
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
                      color: _screenPrimaryText(context),
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
              child: (fieldName == 'name' ||
                      fieldName == 'description' ||
                      fieldName == 'project')
                  ? _buildExpandableText(label, value, constraints.maxWidth)
                  : _buildValue(value),
            ),
          ],
        );
      },
    );
  }

  Color _getPriorityBackgroundColor(String priority) {
    if (priority == AppLocalizations.of(context)!.translate('urgent')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF16A34A);
  }

  Color _getPriorityColor(String priority) {
    if (priority == AppLocalizations.of(context)!.translate('urgent')) {
      return Colors.white;
    }
    return Colors.white;
  }

  void _showUsersDialog(String users) {
    List<String> userList =
        users.split(',').map((user) => user.trim()).toList();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _screenSurfaceBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _screenBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.translate('assignee_list'),
                  style: TextStyle(
                    color: _screenPrimaryText(context),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      title: Text(
                        '${index + 1}. ${userList[index]}',
                        style: TextStyle(
                          color: _screenPrimaryText(context),
                          fontSize: 16,
                          fontFamily: 'Gilroy',
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
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
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
        fontSize: 14,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: _screenHintText(context),
      ),
    );
  }

  Widget _buildValue(String value) {
    if (value.isEmpty) {
      return Container();
    }
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ??
                  'Скопировано',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: context.appColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: _screenPrimaryText(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
          backgroundColor: _screenSurfaceBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _screenBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: _screenPrimaryText(context),
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
                      color: _screenPrimaryText(context),
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
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
