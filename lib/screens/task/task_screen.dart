import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
import 'package:crm_task_manager/screens/task/task_details/task_column.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_add.dart';
import 'package:crm_task_manager/screens/task/task_status_delete.dart';
import 'package:crm_task_manager/screens/task/task_status_edit.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TaskScreen extends StatefulWidget {
  final int? initialStatusId;

  TaskScreen({this.initialStatusId});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _tabTitles = [];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  bool _isUser = false;

  final TextEditingController _searchController = TextEditingController();
  bool _canReadTaskStatus = false;
  bool _canCreateTaskStatus = false;
  bool _canDeleteTaskStatus = false;
  final ApiService _apiService = ApiService();
  bool navigateToEnd = false;
  bool navigateAfterDelete = false;
  int? _deletedIndex;
  int? _selectedUserId;
  List<String> userRoles = [];
  bool showFilter = false;
  List<int>? _selectedUserIds;
  bool _showCustomTabBar = true;
  bool _hasPermissionToAddTask = false;
  bool _canUpdateTaskStatus = false; // Добавляем право на редактирование статусов
  List<Map<String, dynamic>> _selectedDirectoryValues = []; // Добавляем directoryValues
  bool _isFilterLoading = false;
  bool _shouldShowLoader = false;
  bool _skipNextTabListener = false; // КРИТИЧНО: Флаг для пропуска TabListener при фильтрации

  String _lastSearchQuery = "";

  List<UserData> _selectedUsers = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _deadlinefromDate;
  DateTime? _deadlinetoDate;
  bool _isOverdue = false;
  bool _hasFile = false;
  bool _hasDeal = false;
  bool _isUrgent = false;
  String? _selectedProject;
  List<String>? authors;
  List<UserData> _initialselectedUsers = [];
  int? _initialSelStatus;
  DateTime? _intialFromDate;
  DateTime? _intialToDate;
  DateTime? _intialDeadlineFromDate;
  DateTime? _intialDeadlineToDate;
  List<Map<String, dynamic>> _initialDirectoryValues = []; // Добавляем initialDirectoryValues
  bool _initialOverdue = false;
  bool _initialHasFile = false;
  bool _initialHasDeal = false;
  bool _initialUrgent = false;
  List<String> _selectedAuthors = [];
  List<String> _initialSelectedAuthors = [];
  List<String> _selectedProjects = [];
  List<String> _initialSelectedProjects = [];
  String? _selectedDepartment;
  String? _initialSelectedDepartment;
  final GlobalKey keySearchIcon = GlobalKey();
  final GlobalKey keyMenuIcon = GlobalKey();

  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;

  bool _isTaskScreenTutorialCompleted = false;
  Map<String, dynamic>? tutorialProgress;
  
  // ОПТИМИЗАЦИЯ: Debounce timer для поиска
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounce = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    
    // ← КРИТИЧНО: Инициализируем пустой TabController
    _tabController = TabController(length: 0, vsync: this);
    
    // ОПТИМИЗАЦИЯ: Запускаем GetAllClientBloc асинхронно, не блокируя UI
    Future.microtask(() {
      if (mounted) {
    context.read<GetAllClientBloc>().add(GetAllClientEv());
      }
    });
    
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // ОПТИМИЗАЦИЯ: Загружаем роли и разрешения асинхронно
    Future.microtask(() {
      if (mounted) {
    _loadUserRoles();
        _checkPermissions();
      }
    });
    
    // НЕ загружаем состояние фильтров - каждый раз начинаем с чистого листа
    
    // Запускаем загрузку статусов
    BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());
  }

void _onScroll() {
  if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
    final taskBloc = BlocProvider.of<TaskBloc>(context);
    if (taskBloc.state is TaskDataLoaded) {
      final state = taskBloc.state as TaskDataLoaded;
      if (!taskBloc.allTasksFetched) {
        final currentStatusId = _tabTitles[_currentTabIndex]['id'];
        // Преобразуем project_ids в List<int>
        List<int>? projectIdsList = _selectedProjects.isNotEmpty
            ? _selectedProjects.map((id) => int.parse(id)).toList()
            : null;
        taskBloc.add(FetchMoreTasks(
          currentStatusId,
          state.currentPage,
          query: _lastSearchQuery,
          userIds: _selectedUsers.map((user) => user.id).toList(),
          statusIds: _selectedStatuses,
          fromDate: _fromDate,
          toDate: _toDate,
          overdue: _isOverdue,
          hasFile: _hasFile,
          hasDeal: _hasDeal,
          urgent: _isUrgent,
          deadlinefromDate: _deadlinefromDate,
          deadlinetoDate: _deadlinetoDate,
          projectIds: projectIdsList,
          authors: _selectedAuthors,
          department: _selectedDepartment,
          directoryValues: _selectedDirectoryValues, // Передаем directoryValues
        ));
      }
    }
  }
  }
  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRoles() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // ОПТИМИЗАЦИЯ: Проверяем кэш ролей
      final cachedRoles = prefs.getStringList('cached_user_roles');
      final cacheTime = prefs.getInt('cached_user_roles_time');
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Если кэш свежий (< 1 часа), используем его
      if (cachedRoles != null && cacheTime != null && (now - cacheTime) < 3600000) {
        if (mounted) {
          setState(() {
            userRoles = cachedRoles;
          });
        }
        return;
      }
      
      String userId = prefs.getString('userID') ?? '';
      if (userId.isEmpty) {
        if (mounted) {
        setState(() { userRoles = ['No user ID found']; });
        }
        return;
      }
      
      // Загружаем с сервера с timeout
      UserByIdProfile userProfile = await ApiService()
          .getUserById(int.parse(userId))
          .timeout(Duration(seconds: 5), onTimeout: () {
        throw Exception('Timeout loading user profile');
      });
      
      final roles = userProfile.role?.map((role) => role.name).toList() ?? ['No role assigned'];
      
      // Сохраняем в кэш
      await prefs.setStringList('cached_user_roles', roles);
      await prefs.setInt('cached_user_roles_time', now);
      
      if (mounted) {
        setState(() {
          userRoles = roles;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { userRoles = ['Error loading roles']; });
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // ОПТИМИЗАЦИЯ: Проверяем кэш разрешений
      final cacheTime = prefs.getInt('cached_permissions_time');
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Если кэш свежий (< 30 минут), используем его
      if (cacheTime != null && (now - cacheTime) < 1800000) {
        if (!mounted) return;
        setState(() {
          _canReadTaskStatus = prefs.getBool('cached_canReadTaskStatus') ?? false;
          _canCreateTaskStatus = prefs.getBool('cached_canCreateTaskStatus') ?? false;
          _canUpdateTaskStatus = prefs.getBool('cached_canUpdateTaskStatus') ?? false;
          _canDeleteTaskStatus = prefs.getBool('cached_canDeleteTaskStatus') ?? false;
          _hasPermissionToAddTask = prefs.getBool('cached_hasPermissionToAddTask') ?? false;
          showFilter = _hasPermissionToAddTask;
        });
        
        bool isTutorialShown = prefs.getBool('isTutorialShownTaskSearchIconAppBar') ?? false;
        setState(() { _isTutorialShown = isTutorialShown; });

        // ✅ Если статусы уже пришли, но табы пустые — повторно обработаем статусы
        if (mounted && _canReadTaskStatus && _tabTitles.isEmpty) {
          final taskBloc = context.read<TaskBloc>();
          if (taskBloc.state is TaskLoaded) {
            taskBloc.add(FetchTaskStatuses());
          }
        }
        return;
      }
      
      // Загружаем с сервера с timeout
      final results = await Future.wait([
        _apiService.hasPermission('taskStatus.read'),
        _apiService.hasPermission('taskStatus.create'),
        _apiService.hasPermission('taskStatus.update'),
        _apiService.hasPermission('taskStatus.delete'),
        _apiService.hasPermission('task.create'),
        _apiService.hasPermission('task.createForMySelf'),
        _apiService.getTutorialProgress(),
      ]).timeout(Duration(seconds: 10), onTimeout: () {
        // Возвращаем кэшированные значения при timeout
        return [
          prefs.getBool('cached_canReadTaskStatus') ?? false,
          prefs.getBool('cached_canCreateTaskStatus') ?? false,
          prefs.getBool('cached_canUpdateTaskStatus') ?? false,
          prefs.getBool('cached_canDeleteTaskStatus') ?? false,
          prefs.getBool('cached_hasPermissionToAddTask') ?? false,
          prefs.getBool('cached_hasPermissionToAddTask') ?? false,
          {'result': null},
        ];
      });
      
      final canRead = results[0] as bool;
      final canCreate = results[1] as bool;
      final canUpdate = results[2] as bool;
      final canDelete = results[3] as bool;
      final canCreateTask = results[4] as bool;
      final canCreateTaskForMySelf = results[5] as bool;
      final hasPermission = canCreateTask || canCreateTaskForMySelf;
      final progress = results[6] as Map<String, dynamic>;
      
      // Сохраняем в кэш
      await prefs.setBool('cached_canReadTaskStatus', canRead);
      await prefs.setBool('cached_canCreateTaskStatus', canCreate);
      await prefs.setBool('cached_canUpdateTaskStatus', canUpdate);
      await prefs.setBool('cached_canDeleteTaskStatus', canDelete);
      await prefs.setBool('cached_hasPermissionToAddTask', hasPermission);
      await prefs.setInt('cached_permissions_time', now);
      
    if (!mounted) return;
    setState(() {
      _canReadTaskStatus = canRead;
      _canCreateTaskStatus = canCreate;
      _canUpdateTaskStatus = canUpdate;
      _canDeleteTaskStatus = canDelete;
      _hasPermissionToAddTask = hasPermission;
      showFilter = hasPermission;
      tutorialProgress = progress['result'];
    });

    bool isTutorialShown = prefs.getBool('isTutorialShownTaskSearchIconAppBar') ?? false;
    setState(() { _isTutorialShown = isTutorialShown; });

    // ✅ ВАЖНО: если статусы уже загружены, но права пришли позже,
    // табы могли остаться пустыми → триггерим повторную обработку статусов
    if (mounted && _canReadTaskStatus && _tabTitles.isEmpty) {
      final taskBloc = context.read<TaskBloc>();
      if (taskBloc.state is TaskLoaded) {
        taskBloc.add(FetchTaskStatuses());
      }
    }

    if (tutorialProgress != null && tutorialProgress!['tasks']?['index'] == false && !_isTutorialShown && mounted) {
      _initTutorialTargets();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          //showTutorial();
        }
        });
      }
    } catch (e) {
      // При ошибке используем кэшированные значения
      if (!mounted) return;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _canReadTaskStatus = prefs.getBool('cached_canReadTaskStatus') ?? false;
        _canCreateTaskStatus = prefs.getBool('cached_canCreateTaskStatus') ?? false;
        _canUpdateTaskStatus = prefs.getBool('cached_canUpdateTaskStatus') ?? false;
        _canDeleteTaskStatus = prefs.getBool('cached_canDeleteTaskStatus') ?? false;
        _hasPermissionToAddTask = prefs.getBool('cached_hasPermissionToAddTask') ?? false;
        showFilter = _hasPermissionToAddTask;
      });
    }
  }

  void _initTutorialTargets() {
    targets.clear();
    targets.addAll([
      createTarget(
        identify: "TaskSearchIcon",
        keyTarget: keySearchIcon,
        title: AppLocalizations.of(context)!.translate('tutorial_task_screen_search_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_task_screen_search_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "TaskMenuIcon",
        keyTarget: keyMenuIcon,
        title: AppLocalizations.of(context)!.translate('tutorial_task_screen_menu_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_task_screen_menu_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
    ]);
  }

  void showTutorial() async {
    if (_isTutorialShown) {
      //print('Tutorial already shown for TaskScreen, skipping');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(milliseconds: 500));

    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
        ],
      ),
      colorShadow: Color(0xff1E2E52),
      onSkip: () {
        //print('Tutorial skipped for TaskScreen');
        prefs.setBool('isTutorialShownTaskSearchIconAppBar', true);
        setState(() {
          _isTutorialShown = true;
          _isTaskScreenTutorialCompleted = true;
        });
        return true;
      },
      onFinish: () {
        //print('Tutorial finished for TaskScreen');
        prefs.setBool('isTutorialShownTaskSearchIconAppBar', true);
        setState(() {
          _isTutorialShown = true;
          _isTaskScreenTutorialCompleted = true;
        });
      },
    ).show(context: context);
  }

  Future<void> _onRefresh(int currentStatusId) async {
    try {
      await TaskCache.clearAllData();
      await TaskCache.clearPersistentCounts();

      if (mounted) {
        setState(() {
          _isSearching = false;
          _lastSearchQuery = '';
          _searchController.clear();
          _showCustomTabBar = true;
          _isFilterLoading = false;
          _shouldShowLoader = false;

          _selectedUsers.clear();
          _selectedStatuses = null;
          _fromDate = null;
          _toDate = null;
          _deadlinefromDate = null;
          _deadlinetoDate = null;
          _isOverdue = false;
          _hasFile = false;
          _hasDeal = false;
          _isUrgent = false;
          _selectedProject = null;
          _selectedAuthors.clear();
          _selectedProjects.clear();
          _selectedDirectoryValues.clear();
          _selectedDepartment = null;

          _initialselectedUsers.clear();
          _initialSelStatus = null;
          _intialFromDate = null;
          _intialToDate = null;
          _intialDeadlineFromDate = null;
          _intialDeadlineToDate = null;
          _initialOverdue = false;
          _initialHasFile = false;
          _initialHasDeal = false;
          _initialUrgent = false;
          _initialSelectedAuthors.clear();
          _initialSelectedProjects.clear();
          _initialSelectedDepartment = null;
          _initialDirectoryValues.clear();

          _tabTitles.clear();
          _tabKeys.clear();
          _currentTabIndex = 0;

          if (_tabController.length > 0) {
            _tabController.dispose();
          }
          _tabController = TabController(length: 0, vsync: this);
        });
      }

      final taskBloc = BlocProvider.of<TaskBloc>(context);
      await taskBloc.clearAllCountsAndCache();
      taskBloc.add(FetchTaskStatuses(forceRefresh: true));

    } catch (e) {
      // ✅ УБРАНО: Не показываем SnackBar с кнопкой "Повторить"
      debugPrint('TaskScreen: Ошибка при обновлении данных: $e');
      
      if (mounted) {
        final taskBloc = BlocProvider.of<TaskBloc>(context);
        taskBloc.add(FetchTaskStatuses(forceRefresh: false));
      }
    }
  }

  Future<void> _searchTasks(String query, int currentStatusId) async {
    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true;
      });
    }

    final taskBloc = BlocProvider.of<TaskBloc>(context);
    await TaskCache.clearTasksForStatus(currentStatusId);

    // Преобразуем project_ids в List<int>
    List<int>? projectIdsList = _selectedProjects.isNotEmpty
        ? _selectedProjects.map((id) => int.parse(id)).toList()
        : (_selectedProject != null ? [int.parse(_selectedProject!)] : null);

    taskBloc.add(FetchTasks(
      currentStatusId,
      query: query,
      userIds: _selectedUsers.isNotEmpty
          ? _selectedUsers.map((user) => user.id).toList()
          : null,
      statusIds: _selectedStatuses,
      fromDate: _fromDate,
      toDate: _toDate,
      overdue: _isOverdue,
      hasFile: _hasFile,
      hasDeal: _hasDeal,
      urgent: _isUrgent,
      deadlinefromDate: _deadlinefromDate,
      deadlinetoDate: _deadlinetoDate,
      projectIds: projectIdsList,
      authors: _selectedAuthors.isNotEmpty ? _selectedAuthors : null,
      department: _selectedDepartment,
      directoryValues: _selectedDirectoryValues.isNotEmpty
          ? _selectedDirectoryValues
          : null,
    ));
  }

  Future<void> _handleUserSelected(Map filterData) async {
    debugPrint('TaskScreen: _handleUserSelected - START WITH NEW LOGIC');
    
    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true;
        _showCustomTabBar = true;
        _skipNextTabListener = true; // ← КРИТИЧНО: Пропускаем следующий TabListener!
        _isSearching = false; // Выключаем режим поиска
        _searchController.clear();
        _lastSearchQuery = '';

        _selectedUsers = filterData['users'] ?? [];
        _selectedStatuses = filterData['statuses'];
        _fromDate = filterData['fromDate'];
        _toDate = filterData['toDate'];
        _deadlinefromDate = filterData['deadlinefromDate'];
        _deadlinetoDate = filterData['deadlinetoDate'];
        _isOverdue = filterData['overdue'] ?? false;
        _hasFile = filterData['hasFile'] ?? false;
        _hasDeal = filterData['hasDeal'] ?? false;
        _isUrgent = filterData['urgent'] ?? false;
        _selectedProject = filterData['project'];
        _selectedAuthors = filterData['authors'] ?? [];
        
        // Обработка project_ids
        if (filterData['project_ids'] != null) {
          if (filterData['project_ids'] is List) {
            _selectedProjects = (filterData['project_ids'] as List).map((id) => id.toString()).toList();
          } else {
            _selectedProjects = [];
          }
        } else {
          _selectedProjects = [];
        }
        
        _selectedDirectoryValues = (filterData['directory_values'] as List?)?.map((item) => {
            'directory_id': item['directory_id'],
            'entry_id': item['entry_id'],
          }).toList() ?? [];
        _selectedDepartment = filterData['department'];

        // Сохраняем initial значения
        _initialselectedUsers = filterData['users'] ?? [];
        _initialSelStatus = filterData['statuses'];
        _intialFromDate = filterData['fromDate'];
        _intialToDate = filterData['toDate'];
        _intialDeadlineFromDate = filterData['deadlinefromDate'];
        _intialDeadlineToDate = filterData['deadlinetoDate'];
        _initialOverdue = filterData['overdue'] ?? false;
        _initialHasFile = filterData['hasFile'] ?? false;
        _initialHasDeal = filterData['hasDeal'] ?? false;
        _initialUrgent = filterData['urgent'] ?? false;
        _initialSelectedAuthors = filterData['authors'] ?? [];
        _initialSelectedProjects = List.from(_selectedProjects);
        _initialSelectedDepartment = filterData['department'];
        _initialDirectoryValues = List.from(_selectedDirectoryValues);
      });
    }

    // ОПТИМИЗАЦИЯ: Убираем задержку - она не нужна
    // await Future.delayed(Duration(milliseconds: 50));

    final taskBloc = BlocProvider.of<TaskBloc>(context);
    
    // Преобразуем project_ids в List<int>
    List<int>? projectIdsList = _selectedProjects.isNotEmpty
        ? _selectedProjects.map((id) => int.parse(id)).toList()
        : (_selectedProject != null ? [int.parse(_selectedProject!)] : null);

    taskBloc.add(FetchTaskStatusesWithFilters(
      userIds: _selectedUsers.isNotEmpty
          ? _selectedUsers.map((user) => user.id).toList()
          : null,
      statusIds: _selectedStatuses,
      fromDate: _fromDate,
      toDate: _toDate,
      overdue: _isOverdue,
      hasFile: _hasFile,
      hasDeal: _hasDeal,
      urgent: _isUrgent,
      deadlinefromDate: _deadlinefromDate,
      deadlinetoDate: _deadlinetoDate,
      projectIds: projectIdsList,
      authors: _selectedAuthors.isNotEmpty ? _selectedAuthors : null,
      department: _selectedDepartment,
      directoryValues: _selectedDirectoryValues.isNotEmpty ? _selectedDirectoryValues : null,
    ));

    debugPrint('TaskScreen: _handleUserSelected - Dispatched FetchTaskStatusesWithFilters');
  }

  // Метод для проверки наличия активных фильтров
  bool _hasActiveFilters() {
    return _selectedUsers.isNotEmpty ||
        _selectedStatuses != null ||
        _fromDate != null ||
        _toDate != null ||
        _isOverdue == true ||
        _hasFile == true ||
        _hasDeal == true ||
        _isUrgent == true ||
        _deadlinefromDate != null ||
        _deadlinetoDate != null ||
        _selectedProjects.isNotEmpty ||
        (_selectedProject != null && _selectedProject!.isNotEmpty) ||
        _selectedAuthors.isNotEmpty ||
        (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) ||
        _selectedDirectoryValues.isNotEmpty;
  }

  Future _handleStatusSelected(int? selectedStatusId) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatusId;

      _initialSelStatus = selectedStatusId;
    });

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTasks(
      currentStatusId,
      statusIds: _selectedStatuses,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
      directoryValues: _selectedDirectoryValues, // Передаем directoryValues
    ));
  }

  Future _handleDateSelected(DateTime? fromDate, DateTime? toDate) async {
    setState(() {
      _showCustomTabBar = false;
      _fromDate = fromDate;
      _toDate = toDate;

      _intialFromDate = fromDate;
      _intialToDate = toDate;
    });

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTasks(
      currentStatusId,
      fromDate: _fromDate,
      toDate: _toDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
      directoryValues: _selectedDirectoryValues, // Передаем directoryValues
    ));
  }

  Future _handleStatusAndDateSelected(
      int? selectedStatus, DateTime? fromDate, DateTime? toDate) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatus;
      _fromDate = fromDate;
      _toDate = toDate;

      _initialSelStatus = selectedStatus;
      _intialFromDate = fromDate;
      _intialToDate = toDate;
    });

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTasks(
      currentStatusId,
      statusIds: selectedStatus,
      fromDate: _fromDate,
      toDate: _toDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
      directoryValues: _selectedDirectoryValues, // Передаем directoryValues
    ));
  }

  void _resetFilters() {
    setState(() {
      _showCustomTabBar = true;
      _selectedUsers = [];
      _selectedStatuses = null;
      _fromDate = null;
      _toDate = null;
      _lastSearchQuery = '';
      _searchController.clear();

      _isOverdue = false;
      _hasFile = false;
      _hasDeal = false;
      _isUrgent = false;
      _deadlinefromDate = null;
      _deadlinetoDate = null;
      _selectedProject = null;
      _selectedAuthors = [];
      _selectedProjects = [];
      _selectedDirectoryValues = []; // Очищаем directoryValues
      _initialselectedUsers = [];
      _initialSelStatus = null;
      _intialFromDate = null;
      _intialToDate = null;
      _initialOverdue = false;
      _initialHasFile = false;
      _initialHasDeal = false;
      _initialUrgent = false;
      _intialDeadlineFromDate = null;
      _intialDeadlineToDate = null;
      _initialSelectedAuthors = [];
      _initialSelectedProjects = [];
      _selectedDepartment = null;
      _initialSelectedDepartment = null;
    });

    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTaskStatuses());
  }

  void _onSearch(String query) {
    _lastSearchQuery = query;
    
    // ОПТИМИЗАЦИЯ: Отменяем предыдущий таймер debounce
    _searchDebounceTimer?.cancel();
    
    // Если строка пустая, выполняем поиск сразу
    if (query.isEmpty) {
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchTasks(query, currentStatusId);
      return;
    }
    
    // ОПТИМИЗАЦИЯ: Используем debounce для непустых запросов
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (mounted && _tabTitles.isNotEmpty) {
        final currentStatusId = _tabTitles[_currentTabIndex]['id'];
        _searchTasks(query, currentStatusId);
      }
    });
  }

  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();
  ValueChanged<String>? onChangedSearchInput;

  bool isClickAvatarIcon = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: (!isClickAvatarIcon &&
              (_isSearching || _hasActiveFilters()) &&
              _hasPermissionToAddTask &&
              _getCreateTaskStatusId() != null)
          ? FloatingActionButton(
              onPressed: _openCreateTaskFromFilteredView,
              backgroundColor: const Color(0xff1E2E52),
              child: Image.asset('assets/icons/tabBar/add.png',
                  width: 24, height: 24),
            )
          : null,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
            SearchIconKey: keySearchIcon,
            menuIconKey: keyMenuIcon,
            title: isClickAvatarIcon
                ? localizations!.translate('appbar_settings')
                : localizations!.translate('appbar_tasks'),
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
            },
            onChangedSearchInput: (String value) {
              if (value.isNotEmpty) {
                setState(() {
                  _isSearching = true;
                });
              }
              _onSearch(value);
            },
            onUsersSelected: _handleUserSelected,
            onStatusSelected: _handleStatusSelected,
            onDateRangeSelected: _handleDateSelected,
            onStatusAndDateRangeSelected: _handleStatusAndDateSelected,
            initialUsers: _initialselectedUsers,
            initialStatuses: _initialSelStatus,
            initialAuthors: _initialSelectedAuthors,
            initialProjects: _initialSelectedProjects,
            initialDepartment: _initialSelectedDepartment,
            initialFromDate: _intialFromDate,
            initialToDate: _intialToDate,
            initialDeadlineFromDate: _intialDeadlineFromDate,
            initialDeadlineToDate: _intialDeadlineToDate,
            initialTaskIsOverdue: _initialOverdue,
            initialTaskHasFile: _initialHasFile,
            initialTaskHasDeal: _initialHasDeal,
            initialTaskIsUrgent: _initialUrgent,
            initialDirectoryValuesTask: _initialDirectoryValues, // Передаем initialDirectoryValues
            onResetFilters: _resetFilters,
            textEditingController: textEditingController,
            focusNode: focusNode,
            showMenuIcon: _showCustomTabBar,
            showFilterIconOnSelectTask: !_showCustomTabBar,
            hasActiveTaskFilters: _hasActiveFilters(),
            showFilterIcon: false,
            showCallCenter: true,
            showMyTaskIcon: true,
            showFilterIconDeal: false,
            showEvent: false,
            showFilterTaskIcon: showFilter,
            clearButtonClick: (value) {
              if (value == false) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _lastSearchQuery = '';
                });
                if (_searchController.text.isEmpty) {
                  if (_selectedUsers.isEmpty &&
                      _selectedAuthors.isEmpty &&
                      _selectedStatuses == null &&
                      _hasDeal == false &&
                      _hasFile == false &&
                      _fromDate == null &&
                      _toDate == null &&
                      _deadlinefromDate == null &&
                      _deadlinetoDate == null) {
                    //print("IF SEARCH EMPTY AND NO FILTERS");
                    setState(() {
                      _showCustomTabBar = true;
                    });
                    final taskBloc = BlocProvider.of<TaskBloc>(context);
                    taskBloc.add(FetchTaskStatuses());
                  } else {
                    //print("IF SEARCH EMPTY BUT FILTERS EXIST");
                    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                    final taskBloc = BlocProvider.of<TaskBloc>(context);
                    taskBloc.add(FetchTasks(
                      currentStatusId,
                      userIds: _selectedUsers.isNotEmpty
                          ? _selectedUsers.map((user) => user.id).toList()
                          : null,
                      statusIds: _selectedStatuses,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      overdue: _initialOverdue,
                      hasFile: _initialHasFile,
                      hasDeal: _initialHasDeal,
                      urgent: _initialUrgent,
                      deadlinefromDate: _fromDate,
                      deadlinetoDate: _toDate,
                      authors: _selectedAuthors,
                      department: _selectedDepartment,
                      directoryValues: _selectedDirectoryValues, // Передаем directoryValues
                    ));
                  }
                } else if (_selectedUserIds != null &&
                    _selectedUserIds!.isNotEmpty) {
                  //print("ELSE IF SEARCH NOT EMPTY");

                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  final taskBloc = BlocProvider.of<TaskBloc>(context);
                  taskBloc.add(FetchTasks(
                    currentStatusId,
                    userIds: _selectedUserIds,
                    query: _searchController.text.isNotEmpty
                        ? _searchController.text
                        : null,
                  ));
                }
              }
            },
            clearButtonClickFiltr: (value) {}),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Column(
        children: [
          const SizedBox(height: 15),
          if (!_isSearching && _showCustomTabBar)
            _buildCustomTabBar(),
          Expanded(
            child: _isSearching || _hasActiveFilters()
                ? _buildUserView()
                : _buildTabBarView(),
          ),
        ],
      ),
    );
  }

  int? _getCreateTaskStatusId() {
    if (_selectedStatuses != null) {
      return _selectedStatuses;
    }
    if (_tabTitles.isNotEmpty && _currentTabIndex < _tabTitles.length) {
      return _tabTitles[_currentTabIndex]['id'];
    }
    return null;
  }

  void _openCreateTaskFromFilteredView() {
    final statusId = _getCreateTaskStatusId();
    if (statusId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskAddScreen(statusId: statusId),
      ),
    ).then((_) {
      if (!mounted) return;
      final taskBloc = context.read<TaskBloc>();

      if (_isSearching || _hasActiveFilters()) {
        // Преобразуем project_ids в List<int>
        List<int>? projectIdsList = _selectedProjects.isNotEmpty
            ? _selectedProjects.map((id) => int.parse(id)).toList()
            : (_selectedProject != null ? [int.parse(_selectedProject!)] : null);

        taskBloc.add(FetchTasks(
          statusId,
          query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
          userIds: _selectedUsers.isNotEmpty
              ? _selectedUsers.map((user) => user.id).toList()
              : null,
          statusIds: _selectedStatuses,
          fromDate: _fromDate,
          toDate: _toDate,
          overdue: _isOverdue,
          hasFile: _hasFile,
          hasDeal: _hasDeal,
          urgent: _isUrgent,
          deadlinefromDate: _deadlinefromDate,
          deadlinetoDate: _deadlinetoDate,
          projectIds: projectIdsList,
          authors: _selectedAuthors,
          department: _selectedDepartment,
          directoryValues: _selectedDirectoryValues,
        ));
      } else {
        taskBloc.add(FetchTasks(statusId));
      }
    });
  }

  Widget searchWidget(List<Task> tasks) {
    final currentStatusId = _tabTitles.isNotEmpty
        ? _tabTitles[_currentTabIndex]['id']
        : 0;

    if (_isFilterLoading || _shouldShowLoader) {
      return const Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }

    if (_isSearching && tasks.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('nothing_found'),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    } else if (_isUser && tasks.isEmpty) {
      return Center(
        child: Text(
          _selectedUsers.isNotEmpty
              ? 'У выбранного пользователя нет задач'
              : 'По запросу ничего не найдено',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    } else if (tasks.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('nothing_task_for_manager'),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(currentStatusId),
      color: const Color(0xff1E2E52),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TaskCard(
              task: task,
              name: task.taskStatus?.taskStatus?.name ?? "",
              statusId: task.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusTaskId) {
                final index = _tabTitles.indexWhere(
                        (status) => status['id'] == StatusTaskId);
                if (index != -1) {
                  _tabController.animateTo(index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserView() {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        debugPrint('TaskScreen: _buildUserView listener - state: ${state.runtimeType}');
        // Сбрасываем флаги когда данные загружены или произошла ошибка
        if ((state is TaskDataLoaded || state is TaskError) &&
            mounted &&
            (_isFilterLoading || _shouldShowLoader)) {
          debugPrint('TaskScreen: _buildUserView - Resetting loader flags');
          setState(() {
            _isFilterLoading = false;
            _shouldShowLoader = false;
          });
        }
      },
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          final currentStatusId = _tabTitles.isNotEmpty
              ? _tabTitles[_tabController.index]['id']
              : 0;

          // Показываем лоадер только если флаги активны ИЛИ состояние - TaskLoading
          if (state is TaskLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          }

          if (state is TaskDataLoaded) {
            // ИСПРАВЛЕНО: Принудительно сбрасываем флаги если данные загружены
            if (_shouldShowLoader || _isFilterLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _shouldShowLoader = false;
                    _isFilterLoading = false;
                  });
                }
              });
            }
            
            final List<Task> tasks = state.tasks;
            final statusId = _tabTitles[_tabController.index]['id'];
            final filteredTasks = tasks
                .where((task) => task.statusId == statusId)
                .toList();

            if (filteredTasks.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _onRefresh(currentStatusId),
                color: const Color(0xff1E2E52),
                backgroundColor: Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Text(
                      _selectedUsers.isNotEmpty
                          ? 'У выбранного пользователя нет задач'
                          : AppLocalizations.of(context)!
                          .translate('nothing_found'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _onRefresh(currentStatusId),
              color: const Color(0xff1E2E52),
              backgroundColor: Colors.white,
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: TaskCard(
                      task: task,
                      name: task.taskStatus?.taskStatus?.name ?? "",
                      statusId: task.statusId,
                      onStatusUpdated: () {},
                      onStatusId: (StatusTaskId) {
                        final index = _tabTitles.indexWhere(
                                (status) => status['id'] == StatusTaskId);
                        if (index != -1) {
                          _tabController.animateTo(index);
                        }
                      },
                    ),
                  );
                },
              ),
            );
          }

          // Если состояние TaskError - показываем ошибку
          if (state is TaskError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: [
          ...List.generate(_tabTitles.length, (index) {
            if (_tabKeys.length <= index) {
              _tabKeys.add(GlobalKey());
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildTabButton(index),
            );
          }),
          if (_canCreateTaskStatus)
            IconButton(
              icon: Image.asset('assets/icons/tabBar/add_black.png',
                  width: 24, height: 24),
              onPressed: _addNewTab,
            ),
        ],
      ),
    );
  }

  void _addNewTab() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => CreateStatusDialog(),
    );

    if (result == true) {
      // ОПТИМИЗАЦИЯ: Убираем дублирование вызова FetchTaskStatuses
      final taskBloc = BlocProvider.of<TaskBloc>(context);
      taskBloc.add(FetchTaskStatuses());

      setState(() {
        navigateToEnd = true;
      });
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return FutureBuilder<int>(
      future: TaskCache.getPersistentTaskCount(_tabTitles[index]['id']),
      builder: (context, snapshot) {
        // Сначала пробуем получить count из постоянного кэша
        int taskCount = snapshot.data ?? 0;

        // Если в постоянном кэше нет данных, пробуем другие источники
        if (taskCount == 0) {
          return BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              // Используем данные из состояния только если нет постоянного счетчика
              if (state is TaskLoaded) {
                final statusId = _tabTitles[index]['id'];
                final taskStatus = state.taskStatuses.firstWhere(
                  (status) => status.id == statusId,
                  orElse: () => TaskStatus(
                    id: 0,
                    tasksCount: "0",
                    color: '#000000',
                    needsPermission: false,
                    finalStep: false,
                    checkingStep: false,
                    roles: [],
                  ),
                );
                taskCount = int.tryParse(taskStatus.tasksCount) ?? 0;

                // Сразу сохраняем в постоянный кэш
                TaskCache.setPersistentTaskCount(statusId, taskCount);
              } else if (state is TaskDataLoaded && state.taskCounts.containsKey(_tabTitles[index]['id'])) {
                taskCount = state.taskCounts[_tabTitles[index]['id']] ?? 0;

                // Сразу сохраняем в постоянный кэш
                TaskCache.setPersistentTaskCount(_tabTitles[index]['id'], taskCount);
              }

              return _buildTabButtonUI(index, isActive, taskCount);
            },
          );
        }

        // Если есть постоянный счетчик, используем его напрямую
        return _buildTabButtonUI(index, isActive, taskCount);
      },
    );
  }

  // Вспомогательный метод для построения UI кнопки табы
  Widget _buildTabButtonUI(int index, bool isActive, int taskCount) {
    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
      },
      onLongPress: () {
        _showStatusOptions(context, index);
      },
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tabTitles[index]['title'],
              style: TaskStyles.tabTextStyle.copyWith(
                color: isActive
                    ? TaskStyles.activeColor
                    : TaskStyles.inactiveColor,
              ),
            ),
            Transform.translate(
              offset: const Offset(12, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xff1E2E52)
                        : const Color(0xff99A4BA),
                    width: 1,
                  ),
                ),
                child: Text(
                  taskCount.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.black : const Color(0xff99A4BA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusOptions(BuildContext context, int index) {
    final RenderBox renderBox = _tabKeys[index].currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + renderBox.size.height,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height * 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      color: Colors.white,
      items: [
        if (_canUpdateTaskStatus)
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: Color(0xff99A4BA)),
              title: Text(
                'Изменить',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
        if (_canDeleteTaskStatus)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Color(0xff99A4BA)),
              title: Text(
                'Удалить',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _editTaskStatus(index);
      } else if (value == 'delete') {
        _showDeleteDialog(index);
      }
    });
  }

  void _editTaskStatus(int index) {
    final taskStatus = _tabTitles[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskStatusEditScreen(
          taskStatusId: taskStatus['id'],
        ),
      ),
    ).then((_) {
      // Обновляем статусы после редактирования
      context.read<TaskBloc>().add(FetchTaskStatuses());
    });
  }

  void _showDeleteDialog(int index) async {
    final taskStatusId = _tabTitles[index]['id'];
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteTaskStatusDialog(taskStatusId: taskStatusId);
      },
    );

    if (result != null && result) {
      setState(() {
        setState(() {
          _deletedIndex = _currentTabIndex;
          navigateAfterDelete = true;
        });
        _tabTitles.removeAt(index);
        _tabKeys.removeAt(index);
        _tabController = TabController(length: _tabTitles.length, vsync: this);
        _currentTabIndex = 0;

        _isSearching = false;
        _searchController.clear();

        context.read<TaskBloc>().add(FetchTasks(_currentTabIndex));
      });

      if (_tabTitles.isEmpty) {
        await TaskCache.clearAllTasks();
        await TaskCache.clearCache();
      }

      final taskBloc = BlocProvider.of<TaskBloc>(context);
      taskBloc.add(FetchTaskStatuses());
    }
  }

Widget _buildTabBarView() {
  return BlocListener<TaskBloc, TaskState>(
    listener: (context, state) async {
      debugPrint('TaskScreen: _buildTabBarView listener - state: ${state.runtimeType}');
      // Сбрасываем флаги загрузки когда получены данные
      if (state is TaskDataLoaded || state is TaskError) {
        if (mounted && _isFilterLoading) {
          debugPrint('TaskScreen: _buildTabBarView - Resetting loader flags');
          setState(() {
            _isFilterLoading = false;
            _shouldShowLoader = false;
          });
        }
      }
      
      if (state is TaskLoaded) {
        await TaskCache.cacheTaskStatuses(state.taskStatuses
            .map((status) =>
        {'id': status.id, 'title': status.taskStatus?.name ?? ""})
            .toList());

        if (mounted) {
          setState(() {
            // Обновляем табы с новыми данными
            _tabTitles = state.taskStatuses
                .where((status) => _canReadTaskStatus)
                .map((status) =>
            {'id': status.id, 'title': status.taskStatus?.name ?? ""})
                .toList();
            _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

            if (_tabTitles.isNotEmpty) {
              // Проверяем, нужно ли создавать новый контроллер
              bool needNewController = _tabController.length != _tabTitles.length;

                if (needNewController) {
                  // Dispose старого контроллера если он существует
                  if (_tabController.length > 0) {
                    _tabController.dispose();
                  }

                  // Создаем новый контроллер
                  _tabController = TabController(length: _tabTitles.length, vsync: this);
                  
                  // ← КРИТИЧНО: Добавляем listener ТОЛЬКО при создании нового контроллера!
                  _tabController.addListener(() {
                if (!_tabController.indexIsChanging) {
                  // ← КРИТИЧНО: Проверяем флаг пропуска!
                  if (_skipNextTabListener) {
                    debugPrint('TaskScreen: TabController listener - SKIPPED (filter just applied)');
                    setState(() {
                      _skipNextTabListener = false;
                      _currentTabIndex = _tabController.index;
                    });
                    return; // ← ВЫХОДИМ БЕЗ ЗАПРОСА!
                  }

                  debugPrint('TaskScreen: TabController listener triggered, new index: ${_tabController.index}');
                  
                  final currentStatusId = _tabTitles[_tabController.index]['id'];
                  bool hasActiveFilters = _hasActiveFilters();
                  
                  // ИСПРАВЛЕНО: Устанавливаем флаг загрузки при переключении табов
                  setState(() {
                    _currentTabIndex = _tabController.index;
                    // Показываем лоадер только если есть активные фильтры или поиск
                    if (hasActiveFilters || _lastSearchQuery.isNotEmpty) {
                      _shouldShowLoader = true;
                    }
                  });
                  
                  if (_scrollController.hasClients) {
                    _scrollToActiveTab();
                  }
                  
                  // Преобразуем project_ids в List<int>
                  List<int>? projectIdsList = _selectedProjects.isNotEmpty
                      ? _selectedProjects.map((id) => int.parse(id)).toList()
                      : null;

                  context.read<TaskBloc>().add(FetchTasks(
                    currentStatusId,
                    query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,

                    userIds: hasActiveFilters && _selectedUsers.isNotEmpty
                        ? _selectedUsers.map((user) => user.id).toList()
                        : null,
                    statusIds: hasActiveFilters ? currentStatusId : null,
                    fromDate: hasActiveFilters ? _fromDate : null,
                    toDate: hasActiveFilters ? _toDate : null,
                    overdue: hasActiveFilters ? _isOverdue : null,
                    hasFile: hasActiveFilters ? _hasFile : null,
                    hasDeal: hasActiveFilters ? _hasDeal : null,
                    urgent: hasActiveFilters ? _isUrgent : null,
                    deadlinefromDate: hasActiveFilters ? _deadlinefromDate : null,
                    deadlinetoDate: hasActiveFilters ? _deadlinetoDate : null,
                    projectIds: hasActiveFilters ? projectIdsList : null,
                    authors: hasActiveFilters && _selectedAuthors.isNotEmpty ? _selectedAuthors : null,
                    department: hasActiveFilters ? _selectedDepartment : null,
                    directoryValues: hasActiveFilters && _selectedDirectoryValues.isNotEmpty
                        ? _selectedDirectoryValues
                        : null,
                    ));

                    debugPrint('TaskScreen: FetchTasks dispatched for statusId: $currentStatusId');
                  }
                  }); // ← Закрываем listener здесь, только для нового контроллера!
                }

                // Установка правильного индекса
                if (needNewController) {
                if (_currentTabIndex < _tabTitles.length && _currentTabIndex >= 0) {
                  _tabController.index = _currentTabIndex;
                } else {
                  _tabController.index = 0;
                  _currentTabIndex = 0;
                }
              } else {
                int initialIndex = state.taskStatuses
                    .indexWhere((status) => status.id == widget.initialStatusId);
                if (initialIndex != -1 && initialIndex != _currentTabIndex) {
                  _tabController.index = initialIndex;
                  _currentTabIndex = initialIndex;
                } else if (_tabTitles.isNotEmpty) {
                  int safeIndex = _currentTabIndex < _tabTitles.length ? _currentTabIndex : 0;
                  _tabController.index = safeIndex;
                  _currentTabIndex = safeIndex;
                }
              }

              // Прокручиваем к активному табу
              if (_scrollController.hasClients) {
                _scrollToActiveTab();
              }

              // Обрабатываем специальные навигации
              if (navigateToEnd) {
                navigateToEnd = false;
                Future.delayed(Duration(milliseconds: 100), () {
                  if (mounted && _tabTitles.isNotEmpty) {
                    _tabController.animateTo(_tabTitles.length - 1);
                  }
                });
              }

              if (navigateAfterDelete && _tabTitles.isNotEmpty) {
                navigateAfterDelete = false;
                if (_deletedIndex != null) {
                  int newIndex = _deletedIndex! >= _tabTitles.length ? _tabTitles.length - 1 : _deletedIndex!;
                  newIndex = newIndex < 0 ? 0 : newIndex;
                  Future.delayed(Duration(milliseconds: 100), () {
                    if (mounted) {
                      _tabController.animateTo(newIndex);
                      _currentTabIndex = newIndex;
                    }
                  });
                }
              }

              // ОПТИМИЗАЦИЯ: Убираем задержку и проверяем состояние перед загрузкой
              // Автоматически загружаем задачи для активного статуса после refresh только если нет активных фильтров
              if (_tabTitles.isNotEmpty) {
                final activeStatusId = _tabTitles[_currentTabIndex]['id'];
                final bool hasActiveFilters = _hasActiveFilters();
                final taskBloc = context.read<TaskBloc>();

                // Загружаем только если нет активных фильтров И нет уже загруженных данных
                if (!hasActiveFilters) {
                  // Проверяем есть ли уже данные для этого статуса
                  if (taskBloc.state is TaskDataLoaded) {
                    final currentState = taskBloc.state as TaskDataLoaded;
                    final hasTasksForStatus = currentState.tasks.any((task) => task.statusId == activeStatusId);
                    
                    // Загружаем только если нет данных
                    if (!hasTasksForStatus) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          taskBloc.add(FetchTasks(activeStatusId));
                        }
                      });
                    }
                  } else {
                    // Если нет состояния TaskDataLoaded, загружаем
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        taskBloc.add(FetchTasks(activeStatusId));
                      }
                    });
                  }
                } else {
                  debugPrint('TaskScreen: Skip auto FetchTasks due to active filters');
                }
              }

            } else {
              // Если табы пустые, создаем пустой контроллер
              if (_tabController.length > 0) {
                _tabController.dispose();
              }
              _tabController = TabController(length: 0, vsync: this);
              _currentTabIndex = 0;
            }
          });
        }
      } else if (state is TaskError) {
        if (state.message.contains(
          AppLocalizations.of(context)!.translate('unauthorized_access'),
        )) {
          ApiService apiService = ApiService();
          await apiService.logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          // ✅ УБРАНО: Не показываем SnackBar с кнопкой "Повторить"
          // Переведенные сообщения об ошибках будут показаны в других местах
          if (kDebugMode) {
            debugPrint('TaskScreen: Error state - ${state.message}');
          }
          // Можно показать простое сообщение БЕЗ кнопки повторить, если нужно
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text(
          //         state.message,
          //         style: TextStyle(
          //           fontFamily: 'Gilroy',
          //           fontSize: 14,
          //           color: Colors.white,
          //         ),
          //       ),
          //       backgroundColor: Colors.red,
          //       duration: Duration(seconds: 2),
          //     ),
          //   );
          // }
        }
      } else if (state is TaskSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (state is TaskDeleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    },
    child: _tabTitles.isEmpty
        ? const Center(
      child: PlayStoreImageLoading(
        size: 80.0,
        duration: Duration(milliseconds: 1000),
      ),
    )
        : TabBarView(
      controller: _tabController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: _tabTitles.map((status) {
        return RefreshIndicator(
          onRefresh: () => _onRefresh(status['id']),
          color: const Color(0xff1E2E52),
          backgroundColor: Colors.white,
          child: TaskColumn(
            isTaskScreenTutorialCompleted: _isTaskScreenTutorialCompleted,
            statusId: status['id'],
            name: status['title'],
            userId: _selectedUserId,
            onStatusId: (newStatusId) {
              final index = _tabTitles.indexWhere((s) => s['id'] == newStatusId);
              if (index != -1) {
                _tabController.animateTo(index);

                // Проверяем, есть ли уже данные для этого статуса
                final currentTaskBloc = context.read<TaskBloc>();
                if (currentTaskBloc.state is TaskDataLoaded) {
                  final currentState = currentTaskBloc.state as TaskDataLoaded;
                  final hasTasksForStatus = currentState.tasks.any((task) => task.statusId == newStatusId);

                  // Загружаем только если нет данных для этого статуса
                  if (!hasTasksForStatus) {
                    // Преобразуем project_ids в List<int>
                    List<int>? projectIdsList = _selectedProjects.isNotEmpty
                        ? _selectedProjects.map((id) => int.parse(id)).toList()
                        : (_selectedProject != null ? [int.parse(_selectedProject!)] : null);

                    currentTaskBloc.add(FetchTasks(
                      newStatusId,
                      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
                      userIds: _selectedUsers.isNotEmpty
                          ? _selectedUsers.map((user) => user.id).toList()
                          : null,
                      statusIds: _selectedStatuses,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      overdue: _isOverdue,
                      hasFile: _hasFile,
                      hasDeal: _hasDeal,
                      urgent: _isUrgent,
                      deadlinefromDate: _deadlinefromDate,
                      deadlinetoDate: _deadlinetoDate,
                      projectIds: projectIdsList,
                      authors: _selectedAuthors,
                      department: _selectedDepartment,
                      directoryValues: _selectedDirectoryValues,
                    ));
                  }
                } else {
                  // Если нет состояния TaskDataLoaded, загружаем данные
                  currentTaskBloc.add(FetchTasks(newStatusId));
                }
              }
            },
          ),
        );
      }).toList(),
    ),
  );
}

  void _scrollToActiveTab() {
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position =
      box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;

      if (position.dx < 0 ||
          (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
        double targetOffset = _scrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);

        if (targetOffset != _scrollController.offset) {
          _scrollController.animateTo(
            targetOffset,
            duration: Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      }
    }
  }
}
