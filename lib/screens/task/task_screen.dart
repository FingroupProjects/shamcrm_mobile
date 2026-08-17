import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/task/task_model.dart';
import 'package:crm_task_manager/models/user/user_byId_model..dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
import 'package:crm_task_manager/screens/task/task_details/task_column.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_add.dart';
import 'package:crm_task_manager/screens/task/task_status_delete.dart';
import 'package:crm_task_manager/screens/task/task_status_edit.dart';
import 'package:crm_task_manager/screens/task/project_screen.dart';
import 'package:crm_task_manager/services/app_logout_service.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TaskScreen extends StatefulWidget {
  final int? initialStatusId;
  final int? projectId;
  final String? projectName;

  TaskScreen({this.initialStatusId, this.projectId, this.projectName});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _tabScrollController;
  late ScrollController _listScrollController;
  List<Map<String, dynamic>> _tabTitles = [];
  final Map<int, int> _projectTaskCounts = {};
  final Set<int> _validatedProjectStatusIds = <int>{};
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
  bool _canUpdateTaskStatus =
      false; // Добавляем право на редактирование статусов
  List<Map<String, dynamic>> _selectedDirectoryValues =
      []; // Добавляем directoryValues
  bool _isFilterLoading = false;
  bool _shouldShowLoader = false;
  bool _skipNextTabListener =
      false; // КРИТИЧНО: Флаг для пропуска TabListener при фильтрации
  int? _skipNextTabListenerIndex;
  int? _pendingStatusIdAfterHardRefresh;

  String _lastSearchQuery = "";
  int? get _projectContextId => widget.projectId;
  bool get _isProjectContext => _projectContextId != null;

  List<int>? _projectFilterIds() {
    if (_selectedProjects.isNotEmpty) {
      return _selectedProjects.map((id) => int.parse(id)).toList();
    }
    if (_selectedProject != null) {
      return [int.parse(_selectedProject!)];
    }
    return null;
  }

  List<UserData> _selectedUsers = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _deadlinefromDate;
  DateTime? _deadlinetoDate;
  DateTime? _completedFromDate;
  DateTime? _completedToDate;
  bool _isOverdue = false;
  bool _hasFile = false;
  bool _hasDeal = false;
  bool _isUrgent = false;
  List<int> _selectedReasonForRefusalIds = [];
  String? _selectedProject;
  List<String>? authors;
  List<UserData> _initialselectedUsers = [];
  int? _initialSelStatus;
  DateTime? _intialFromDate;
  DateTime? _intialToDate;
  DateTime? _intialDeadlineFromDate;
  DateTime? _intialDeadlineToDate;
  DateTime? _initialCompletedFromDate;
  DateTime? _initialCompletedToDate;
  List<Map<String, dynamic>> _initialDirectoryValues =
      []; // Добавляем initialDirectoryValues
  bool _initialOverdue = false;
  bool _initialHasFile = false;
  bool _initialHasDeal = false;
  bool _initialUrgent = false;
  List<int> _initialReasonForRefusalIds = [];
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

    _tabScrollController = ScrollController();
    _listScrollController = ScrollController();
    _listScrollController.addListener(_onScroll);

    // ОПТИМИЗАЦИЯ: Загружаем роли и разрешения асинхронно
    Future.microtask(() {
      if (mounted) {
        _loadUserRoles();
        _checkPermissions();
      }
    });

    // НЕ загружаем состояние фильтров - каждый раз начинаем с чистого листа

    // Запускаем загрузку статусов
    BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses(
      forceRefresh: _isProjectContext,
      projectId: _projectContextId,
    ));
  }

  void _onScroll() {
    if (!_listScrollController.hasClients) return;
    if (_listScrollController.position.maxScrollExtent <= 0) return;

    final position = _listScrollController.position;
    final reachedPaginationThreshold =
        position.pixels >= (position.maxScrollExtent - 200);

    if (reachedPaginationThreshold) {
      final taskBloc = BlocProvider.of<TaskBloc>(context);
      if (taskBloc.state is TaskDataLoaded) {
        final state = taskBloc.state as TaskDataLoaded;
        if (!taskBloc.allTasksFetched &&
            !state.isLoadingMore &&
            !taskBloc.isFetching &&
            _tabTitles.isNotEmpty &&
            _currentTabIndex < _tabTitles.length) {
          final currentStatusId = _tabTitles[_currentTabIndex]['id'];
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
            completedFromDate: _completedFromDate,
            completedToDate: _completedToDate,
            projectIds: _projectFilterIds(),
            projectId: _projectContextId,
            authors: _selectedAuthors,
            department: _selectedDepartment,
            directoryValues:
                _selectedDirectoryValues, // Передаем directoryValues
          ));
        }
      }
    }
  }

  void _ensureFilteredPaginationCanContinue(TaskDataLoaded state) {
    if (!mounted || !_listScrollController.hasClients) return;
    if (state.tasks.isEmpty ||
        state.isLoadingMore ||
        context.read<TaskBloc>().allTasksFetched ||
        context.read<TaskBloc>().isFetching) {
      return;
    }
    if (_tabTitles.isEmpty || _currentTabIndex >= _tabTitles.length) return;
    if (_listScrollController.position.maxScrollExtent > 0) return;

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    final taskBloc = context.read<TaskBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = taskBloc.state;
      if (currentState is! TaskDataLoaded) return;
      if (currentState.isLoadingMore ||
          taskBloc.allTasksFetched ||
          taskBloc.isFetching) {
        return;
      }
      taskBloc.add(FetchMoreTasks(
        currentStatusId,
        currentState.currentPage,
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
        completedFromDate: _completedFromDate,
        completedToDate: _completedToDate,
        projectIds: _projectFilterIds(),
        projectId: _projectContextId,
        authors: _selectedAuthors.isNotEmpty ? _selectedAuthors : null,
        department: _selectedDepartment,
        directoryValues: _selectedDirectoryValues.isNotEmpty
            ? _selectedDirectoryValues
            : null,
      ));
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _listScrollController.removeListener(_onScroll);
    _listScrollController.dispose();
    _tabScrollController.dispose();
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
      if (cachedRoles != null &&
          cacheTime != null &&
          (now - cacheTime) < 3600000) {
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
          setState(() {
            userRoles = ['No user ID found'];
          });
        }
        return;
      }

      // Загружаем с сервера с timeout
      UserByIdProfile userProfile = await ApiService()
          .getUserById(int.parse(userId))
          .timeout(Duration(seconds: 5), onTimeout: () {
        throw Exception('Timeout loading user profile');
      });

      final roles = userProfile.role?.map((role) => role.name).toList() ??
          ['No role assigned'];

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
        setState(() {
          userRoles = ['Error loading roles'];
        });
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
          _canReadTaskStatus =
              prefs.getBool('cached_canReadTaskStatus') ?? false;
          _canCreateTaskStatus =
              prefs.getBool('cached_canCreateTaskStatus') ?? false;
          _canUpdateTaskStatus =
              prefs.getBool('cached_canUpdateTaskStatus') ?? false;
          _canDeleteTaskStatus =
              prefs.getBool('cached_canDeleteTaskStatus') ?? false;
          _hasPermissionToAddTask =
              prefs.getBool('cached_hasPermissionToAddTask') ?? false;
          showFilter = _hasPermissionToAddTask;
        });

        bool isTutorialShown =
            prefs.getBool('isTutorialShownTaskSearchIconAppBar') ?? false;
        setState(() {
          _isTutorialShown = isTutorialShown;
        });

        // Если права пришли позже статусов, повторно запрашиваем статусы,
        // даже если bloc уже успел уйти из TaskLoaded в другое состояние.
        if (mounted &&
            !_isProjectContext &&
            _canReadTaskStatus &&
            _tabTitles.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<TaskBloc>().add(FetchTaskStatuses(
                    forceRefresh: _isProjectContext,
                    projectId: _projectContextId,
                  ));
            }
          });
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

      bool isTutorialShown =
          prefs.getBool('isTutorialShownTaskSearchIconAppBar') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });

      // Если права пришли позже статусов, повторно запрашиваем статусы,
      // даже если bloc уже успел переключиться в TaskLoading/TaskDataLoaded.
      if (mounted &&
          !_isProjectContext &&
          _canReadTaskStatus &&
          _tabTitles.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<TaskBloc>().add(FetchTaskStatuses(
                  forceRefresh: _isProjectContext,
                  projectId: _projectContextId,
                ));
          }
        });
      }

      if (tutorialProgress != null &&
          tutorialProgress!['tasks']?['index'] == false &&
          !_isTutorialShown &&
          mounted) {
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
        _canCreateTaskStatus =
            prefs.getBool('cached_canCreateTaskStatus') ?? false;
        _canUpdateTaskStatus =
            prefs.getBool('cached_canUpdateTaskStatus') ?? false;
        _canDeleteTaskStatus =
            prefs.getBool('cached_canDeleteTaskStatus') ?? false;
        _hasPermissionToAddTask =
            prefs.getBool('cached_hasPermissionToAddTask') ?? false;
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
        title: AppLocalizations.of(context)!
            .translate('tutorial_task_screen_search_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_task_screen_search_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "TaskMenuIcon",
        keyTarget: keyMenuIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_task_screen_menu_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_task_screen_menu_description'),
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
      textStyleSkip: context.appTextStyles.titleMd.copyWith(
        color: context.appColors.textInverse,
      ),
      colorShadow: context.appColors.overlay,
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
      if (!_isProjectContext) {
        await TaskCache.clearAllData();
        await TaskCache.clearPersistentCounts();
      }

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
          _completedFromDate = null;
          _completedToDate = null;
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
          _initialCompletedFromDate = null;
          _initialCompletedToDate = null;
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
      await taskBloc.clearAllCountsAndCache(
        clearPersistentCache: !_isProjectContext,
      );
      ApiService.clearAnalyticsResponseCache();
      taskBloc.add(FetchTaskStatuses(
        forceRefresh: true,
        projectId: _projectContextId,
      ));
    } catch (e) {
      // ✅ УБРАНО: Не показываем SnackBar с кнопкой "Повторить"
      debugPrint('TaskScreen: Ошибка при обновлении данных: $e');

      if (mounted) {
        final taskBloc = BlocProvider.of<TaskBloc>(context);
        taskBloc.add(FetchTaskStatuses(
          forceRefresh: false,
          projectId: _projectContextId,
        ));
      }
    }
  }

  Future<void> _hardRefreshAfterTaskChange(int targetStatusId) async {
    try {
      _pendingStatusIdAfterHardRefresh = targetStatusId;

      if (mounted) {
        setState(() {
          _tabTitles.clear();
          _tabKeys.clear();
          _currentTabIndex = 0;
        });

        if (_tabController.length > 0) {
          _tabController.dispose();
        }
        _tabController = TabController(length: 0, vsync: this);
      }

      final taskBloc = context.read<TaskBloc>();
      await taskBloc.clearAllCountsAndCache(
        clearPersistentCache: !_isProjectContext,
      );
      ApiService.clearAnalyticsResponseCache();
      taskBloc.add(FetchTaskStatuses(
        forceRefresh: true,
        projectId: _projectContextId,
      ));
    } catch (e) {
      debugPrint('TaskScreen: hard refresh after task change failed: $e');
      if (mounted) {
        context.read<TaskBloc>().add(FetchTaskStatuses(
              forceRefresh: true,
              projectId: _projectContextId,
            ));
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
    if (!_isProjectContext) {
      await TaskCache.clearTasksForStatus(currentStatusId);
    }

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
      reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
          ? _selectedReasonForRefusalIds
          : null,
      deadlinefromDate: _deadlinefromDate,
      deadlinetoDate: _deadlinetoDate,
      projectIds: _projectFilterIds(),
      projectId: _projectContextId,
      authors: _selectedAuthors.isNotEmpty ? _selectedAuthors : null,
      department: _selectedDepartment,
      directoryValues:
          _selectedDirectoryValues.isNotEmpty ? _selectedDirectoryValues : null,
    ));
  }

  Future<void> _handleUserSelected(Map filterData) async {
    debugPrint('TaskScreen: _handleUserSelected - START WITH NEW LOGIC');
    final int? currentStatusIdBeforeFilter =
        _tabTitles.isNotEmpty && _currentTabIndex < _tabTitles.length
            ? _tabTitles[_currentTabIndex]['id'] as int
            : null;
    debugPrint(
        'TaskScreen: _handleUserSelected - currentStatusIdBeforeFilter=$currentStatusIdBeforeFilter');
    debugPrint('TaskScreen: _handleUserSelected - raw filterData=$filterData');

    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true;
        _showCustomTabBar = true;
        _skipNextTabListener =
            true; // ← КРИТИЧНО: Пропускаем следующий TabListener!
        _skipNextTabListenerIndex = _currentTabIndex;
        _isSearching = false; // Выключаем режим поиска
        _searchController.clear();
        _lastSearchQuery = '';

        _selectedUsers = filterData['users'] ?? [];
        _selectedStatuses = filterData['statuses'];
        _fromDate = filterData['fromDate'];
        _toDate = filterData['toDate'];
        _deadlinefromDate = filterData['deadlinefromDate'];
        _deadlinetoDate = filterData['deadlinetoDate'];
        _completedFromDate = filterData['completedFromDate'];
        _completedToDate = filterData['completedToDate'];
        _isOverdue = filterData['overdue'] ?? false;
        _hasFile = filterData['hasFile'] ?? false;
        _hasDeal = filterData['hasDeal'] ?? false;
        _isUrgent = filterData['urgent'] ?? false;
        _selectedReasonForRefusalIds =
            (filterData['reason_for_refusal_ids'] as List?)
                    ?.map((id) => int.tryParse(id.toString()) ?? 0)
                    .where((id) => id != 0)
                    .toList() ??
                [];
        _selectedProject = filterData['project'];
        _selectedAuthors = filterData['authors'] ?? [];

        // Обработка project_ids
        if (filterData['project_ids'] != null) {
          if (filterData['project_ids'] is List) {
            _selectedProjects = (filterData['project_ids'] as List)
                .map((id) => id.toString())
                .toList();
          } else {
            _selectedProjects = [];
          }
        } else {
          _selectedProjects = [];
        }

        _selectedDirectoryValues = (filterData['directory_values'] as List?)
                ?.map((item) => {
                      'directory_id': item['directory_id'],
                      'entry_id': item['entry_id'],
                    })
                .toList() ??
            [];
        _selectedDepartment = filterData['department'];

        // Сохраняем initial значения
        _initialselectedUsers = filterData['users'] ?? [];
        _initialSelStatus = filterData['statuses'];
        _intialFromDate = filterData['fromDate'];
        _intialToDate = filterData['toDate'];
        _intialDeadlineFromDate = filterData['deadlinefromDate'];
        _intialDeadlineToDate = filterData['deadlinetoDate'];
        _initialCompletedFromDate = filterData['completedFromDate'];
        _initialCompletedToDate = filterData['completedToDate'];
        _initialOverdue = filterData['overdue'] ?? false;
        _initialHasFile = filterData['hasFile'] ?? false;
        _initialHasDeal = filterData['hasDeal'] ?? false;
        _initialUrgent = filterData['urgent'] ?? false;
        _initialReasonForRefusalIds =
            List<int>.from(_selectedReasonForRefusalIds);
        _initialSelectedAuthors = filterData['authors'] ?? [];
        _initialSelectedProjects = List.from(_selectedProjects);
        _initialSelectedDepartment = filterData['department'];
        _initialDirectoryValues = List.from(_selectedDirectoryValues);
      });
    }

    // ОПТИМИЗАЦИЯ: Убираем задержку - она не нужна
    // await Future.delayed(Duration(milliseconds: 50));

    final taskBloc = BlocProvider.of<TaskBloc>(context);
    debugPrint(
        'TaskScreen: _handleUserSelected - clearing TaskBloc cache and ApiService cache before filtering');
    await taskBloc.clearAllCountsAndCache(
      clearPersistentCache: !_isProjectContext,
    );
    if (!_isProjectContext) {
      await _apiService.clearTaskStatusesPersistentCache();
    }
    ApiService.clearAnalyticsResponseCache();
    debugPrint(
        'TaskScreen: _handleUserSelected - cache cleared, dispatching filtered statuses request');

    debugPrint(
        'TaskScreen: _handleUserSelected - normalized filters: users=${_selectedUsers.map((e) => e.id).toList()}, selectedStatuses=$_selectedStatuses, projectIds=${_projectFilterIds()}, projectId=$_projectContextId, authors=$_selectedAuthors, department=$_selectedDepartment, directoryValues=$_selectedDirectoryValues');

    taskBloc.add(FetchTaskStatusesWithFilters(
      preferredStatusId: currentStatusIdBeforeFilter,
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
      reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
          ? _selectedReasonForRefusalIds
          : null,
      deadlinefromDate: _deadlinefromDate,
      deadlinetoDate: _deadlinetoDate,
      completedFromDate: _completedFromDate,
      completedToDate: _completedToDate,
      projectIds: _projectFilterIds(),
      projectId: _projectContextId,
      authors: _selectedAuthors.isNotEmpty ? _selectedAuthors : null,
      department: _selectedDepartment,
      directoryValues:
          _selectedDirectoryValues.isNotEmpty ? _selectedDirectoryValues : null,
    ));

    debugPrint(
        'TaskScreen: _handleUserSelected - Dispatched FetchTaskStatusesWithFilters');
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
        _selectedReasonForRefusalIds.isNotEmpty ||
        _deadlinefromDate != null ||
        _deadlinetoDate != null ||
        _completedFromDate != null ||
        _completedToDate != null ||
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
      reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
          ? _selectedReasonForRefusalIds
          : null,
      directoryValues: _selectedDirectoryValues, // Передаем directoryValues
      projectIds: _projectFilterIds(),
      projectId: _projectContextId,
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
      reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
          ? _selectedReasonForRefusalIds
          : null,
      directoryValues: _selectedDirectoryValues, // Передаем directoryValues
      projectIds: _projectFilterIds(),
      projectId: _projectContextId,
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
      reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
          ? _selectedReasonForRefusalIds
          : null,
      directoryValues: _selectedDirectoryValues, // Передаем directoryValues
      projectIds: _projectFilterIds(),
      projectId: _projectContextId,
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
      _selectedReasonForRefusalIds = [];
      _deadlinefromDate = null;
      _deadlinetoDate = null;
      _completedFromDate = null;
      _completedToDate = null;
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
      _initialReasonForRefusalIds = [];
      _intialDeadlineFromDate = null;
      _intialDeadlineToDate = null;
      _initialCompletedFromDate = null;
      _initialCompletedToDate = null;
      _initialSelectedAuthors = [];
      _initialSelectedProjects = [];
      _selectedDepartment = null;
      _initialSelectedDepartment = null;
    });

    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTaskStatuses(projectId: _projectContextId));
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
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      floatingActionButton: (!isClickAvatarIcon &&
              (_isSearching || _hasActiveFilters()) &&
              _hasPermissionToAddTask &&
              _getCreateTaskStatusId() != null)
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openCreateTaskFromFilteredView,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: 54,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.buttonPrimaryBg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: colors.buttonPrimaryFg),
                      const SizedBox(width: 8),
                      Text(
                        'Создать',
                        style: context.appTextStyles.labelLg.copyWith(
                          color: colors.buttonPrimaryFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: CustomAppBar(
            SearchIconKey: keySearchIcon,
            menuIconKey: keyMenuIcon,
            title: isClickAvatarIcon
                ? localizations!.translate('appbar_settings')
                : widget.projectName ??
                    localizations!.translate('appbar_tasks'),
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
            initialCompletedFromDate: _initialCompletedFromDate,
            initialCompletedToDate: _initialCompletedToDate,
            initialTaskIsOverdue: _initialOverdue,
            initialTaskHasFile: _initialHasFile,
            initialTaskHasDeal: _initialHasDeal,
            initialTaskIsUrgent: _initialUrgent,
            initialReasonForRefusalIdsTask: _initialReasonForRefusalIds,
            initialDirectoryValuesTask:
                _initialDirectoryValues, // Передаем initialDirectoryValues
            onResetFilters: _resetFilters,
            textEditingController: textEditingController,
            focusNode: focusNode,
            showMenuIcon: _showCustomTabBar,
            showProjectsMenuItem: _showCustomTabBar && !_isProjectContext,
            onProjectsPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProjectScreen()),
                ),
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
                      _selectedReasonForRefusalIds.isEmpty &&
                      _selectedStatuses == null &&
                      _hasDeal == false &&
                      _hasFile == false &&
                      _fromDate == null &&
                      _toDate == null &&
                      _deadlinefromDate == null &&
                      _deadlinetoDate == null &&
                      _completedFromDate == null &&
                      _completedToDate == null) {
                    //print("IF SEARCH EMPTY AND NO FILTERS");
                    setState(() {
                      _showCustomTabBar = true;
                    });
                    final taskBloc = BlocProvider.of<TaskBloc>(context);
                    taskBloc
                        .add(FetchTaskStatuses(projectId: _projectContextId));
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
                      reasonForRefusalIds:
                          _selectedReasonForRefusalIds.isNotEmpty
                              ? _selectedReasonForRefusalIds
                              : null,
                      deadlinefromDate: _fromDate,
                      deadlinetoDate: _toDate,
                      completedFromDate: _completedFromDate,
                      completedToDate: _completedToDate,
                      authors: _selectedAuthors,
                      department: _selectedDepartment,
                      directoryValues:
                          _selectedDirectoryValues, // Передаем directoryValues
                      projectIds: _projectFilterIds(),
                      projectId: _projectContextId,
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
                    reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
                        ? _selectedReasonForRefusalIds
                        : null,
                    projectIds: _projectFilterIds(),
                    projectId: _projectContextId,
                  ));
                }
              }
            },
            clearButtonClickFiltr: (value) {}),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Stack(
              fit: StackFit.expand,
              children: [
                const AppBackgroundOverlay(
                  preset: AppBackgroundPreset.aurora,
                ),
                Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).padding.top +
                          kToolbarHeight +
                          15,
                    ),
                    if (!_isSearching && _showCustomTabBar)
                      _buildCustomTabBar(),
                    Expanded(
                      child: _isSearching || _hasActiveFilters()
                          ? _buildUserView()
                          : _buildTabBarView(),
                    ),
                  ],
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
        builder: (context) => TaskAddScreen(
          statusId: statusId,
          initialProjectId: _projectContextId,
          lockProject: false,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      final taskBloc = context.read<TaskBloc>();

      if (_isSearching || _hasActiveFilters()) {
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
          reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
              ? _selectedReasonForRefusalIds
              : null,
          deadlinefromDate: _deadlinefromDate,
          deadlinetoDate: _deadlinetoDate,
          completedFromDate: _completedFromDate,
          completedToDate: _completedToDate,
          projectIds: _projectFilterIds(),
          projectId: _projectContextId,
          authors: _selectedAuthors,
          department: _selectedDepartment,
          directoryValues: _selectedDirectoryValues,
        ));
      } else {
        taskBloc.add(FetchTasks(
          statusId,
          projectIds: _projectFilterIds(),
          projectId: _projectContextId,
          reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
              ? _selectedReasonForRefusalIds
              : null,
        ));
      }
    });
  }

  Widget searchWidget(List<Task> tasks) {
    final currentStatusId =
        _tabTitles.isNotEmpty ? _tabTitles[_currentTabIndex]['id'] : 0;

    if (_isFilterLoading || _shouldShowLoader) {
      return const Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }

    if (_isSearching && tasks.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return HelpfulEmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.translate('empty_search_title'),
        subtitle: l10n.translate('empty_search_subtitle'),
      );
    } else if (_isUser && tasks.isEmpty) {
      return HelpfulEmptyState(
        icon: Icons.person_search_rounded,
        title: _selectedUsers.isNotEmpty
            ? 'У выбранного пользователя нет задач'
            : AppLocalizations.of(context)!.translate('empty_search_title'),
      );
    } else if (tasks.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final statusId = _tabTitles.isNotEmpty
          ? _tabTitles[_currentTabIndex]['id'] as int
          : null;
      return HelpfulEmptyState(
        icon: Icons.task_alt_rounded,
        title: l10n.translate('empty_tasks_title'),
        subtitle: l10n.translate('empty_tasks_subtitle'),
        actionLabel: statusId != null ? l10n.translate('empty_tasks_action') : null,
        onAction: statusId != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskAddScreen(
                      statusId: statusId,
                      initialProjectId: _projectContextId,
                    ),
                  ),
                );
              }
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(currentStatusId),
      color: context.appColors.buttonPrimaryBg,
      backgroundColor: context.appColors.surfacePrimary,
      child: ListView.builder(
        controller: _listScrollController,
        padding: EdgeInsets.zero,
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
                _hardRefreshAfterTaskChange(StatusTaskId);
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
        debugPrint(
            'TaskScreen: _buildUserView listener - state: ${state.runtimeType}');
        // Сбрасываем флаги когда данные загружены или произошла ошибка
        if ((state is TaskDataLoaded || state is TaskError) &&
            mounted &&
            (_isFilterLoading || _shouldShowLoader)) {
          debugPrint('TaskScreen: _buildUserView - Resetting loader flags');
          setState(() {
            _isFilterLoading = false;
            _shouldShowLoader = false;
            _skipNextTabListener = false;
            _skipNextTabListenerIndex = null;
          });
        }

        if (state is TaskDataLoaded) {
          if (_isProjectContext && _tabTitles.isNotEmpty) {
            final statusId = _tabTitles[_tabController.index]['id'] as int;
            final hasChangedCount = state.taskCounts.entries.any(
                  (entry) => _projectTaskCounts[entry.key] != entry.value,
                ) ||
                !_validatedProjectStatusIds.contains(statusId);
            if (mounted && hasChangedCount) {
              setState(() {
                _projectTaskCounts.addAll(state.taskCounts);
                _validatedProjectStatusIds.add(statusId);
              });
            }
          }
          _ensureFilteredPaginationCanContinue(state);
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
            final filteredTasks =
                tasks.where((task) => task.statusId == statusId).toList();
            final bool showPaginationLoader =
                state.isLoadingMore && filteredTasks.isNotEmpty;

            if (filteredTasks.isEmpty) {
              final l10n = AppLocalizations.of(context)!;
              return HelpfulEmptyState.refreshable(
                context: context,
                onRefresh: () => _onRefresh(currentStatusId),
                child: HelpfulEmptyState(
                  icon: _selectedUsers.isNotEmpty
                      ? Icons.person_search_rounded
                      : Icons.search_off_rounded,
                  title: _selectedUsers.isNotEmpty
                      ? 'У выбранного пользователя нет задач'
                      : l10n.translate('empty_search_title'),
                  subtitle: _selectedUsers.isNotEmpty
                      ? null
                      : l10n.translate('empty_search_subtitle'),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _onRefresh(currentStatusId),
              color: context.appColors.buttonPrimaryBg,
              backgroundColor: context.appColors.surfacePrimary,
              child: ListView.builder(
                controller: _listScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount:
                    filteredTasks.length + (showPaginationLoader ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= filteredTasks.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: PlayStoreImageLoading(
                          size: 56.0,
                          duration: Duration(milliseconds: 1000),
                        ),
                      ),
                    );
                  }

                  final task = filteredTasks[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TaskCard(
                      task: task,
                      name: task.taskStatus?.taskStatus?.name ?? "",
                      statusId: task.statusId,
                      onStatusUpdated: () {},
                      onStatusId: (StatusTaskId) {
                        _hardRefreshAfterTaskChange(StatusTaskId);
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
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: context.appColors.error,
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _tabScrollController,
        child: Row(
          children: [
            ...List.generate(_tabTitles.length, (index) {
              if (_tabKeys.length <= index) {
                _tabKeys.add(GlobalKey());
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildTabButton(index),
              );
            }),
            if (_canCreateTaskStatus)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _addNewTab,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.appColors.surfacePrimary,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: context.appColors.borderSubtle
                              .withValues(alpha: 0.52),
                        ),
                      ),
                      child: Image.asset(
                        'assets/icons/tabBar/add_black.png',
                        width: 20,
                        height: 20,
                        color: context.appColors.iconPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addNewTab() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          CreateStatusDialog(projectId: _projectContextId),
    );

    if (result == true) {
      // ОПТИМИЗАЦИЯ: Убираем дублирование вызова FetchTaskStatuses
      final taskBloc = BlocProvider.of<TaskBloc>(context);
      taskBloc.add(FetchTaskStatuses(projectId: _projectContextId));

      setState(() {
        navigateToEnd = true;
      });
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    if (_isProjectContext) {
      final statusId = _tabTitles[index]['id'] as int;
      return _buildTabButtonUI(
        index,
        isActive,
        _validatedProjectStatusIds.contains(statusId)
            ? (_projectTaskCounts[statusId] ?? 0)
            : 0,
      );
    }

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
                if (!_isProjectContext) {
                  final taskStatus = state.taskStatuses.firstWhere(
                    (status) => status.id == statusId,
                    orElse: () => TaskStatus(
                      id: 0,
                      tasksCount: "0",
                      color: '#000000',
                      needsPermission: false,
                      finalStep: false,
                      checkingStep: false,
                      isUnassembled: false,
                      roles: [],
                    ),
                  );
                  taskCount = int.tryParse(taskStatus.tasksCount) ?? 0;
                }

                if (!_isProjectContext) {
                  TaskCache.setPersistentTaskCount(statusId, taskCount);
                }
              } else if (state is TaskDataLoaded &&
                  state.taskCounts.containsKey(_tabTitles[index]['id'])) {
                taskCount = state.taskCounts[_tabTitles[index]['id']] ?? 0;

                // Сразу сохраняем в постоянный кэш
                if (!_isProjectContext) {
                  TaskCache.setPersistentTaskCount(
                      _tabTitles[index]['id'], taskCount);
                }
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
    final title = (_tabTitles[index]['title'] as String?)?.trim() ?? '';

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        if (_tabController.index != index) {
          setState(() {
            _isFilterLoading = true;
            _shouldShowLoader = true;
          });
        }
        _tabController.animateTo(index);
      },
      onLongPress: () {
        _showStatusOptions(context, index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isActive
              ? context.appColors.buttonPrimaryBg
              : context.appColors.surfacePrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? context.appColors.buttonPrimaryBg
                : context.appColors.borderSubtle.withValues(alpha: 0.58),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: context.appColors.buttonPrimaryBg
                        .withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                title.isEmpty ? 'Статус' : title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive
                      ? context.appColors.buttonPrimaryFg
                      : context.appColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? context.appColors.buttonPrimaryFg.withValues(alpha: 0.18)
                    : context.appColors.buttonPrimaryBg.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? context.appColors.buttonPrimaryBg
                          .withValues(alpha: 0.85)
                      : context.appColors.textInverse.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: Text(
                taskCount.toString(),
                style: TextStyle(
                  color: isActive
                      ? context.appColors.buttonPrimaryFg
                      : context.appColors.textPrimary,
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusOptions(BuildContext context, int index) {
    final RenderBox renderBox =
        _tabKeys[index].currentContext!.findRenderObject() as RenderBox;
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
      color: context.appColors.surfacePrimary,
      items: [
        if (_canUpdateTaskStatus)
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: Color(0xff99A4BA)),
              // keep action colors aligned with theme
              title: Text(
                'Изменить',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
          ),
        if (_canDeleteTaskStatus)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading:
                  Icon(Icons.delete, color: context.appColors.iconSecondary),
              title: Text(
                'Удалить',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
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
      context
          .read<TaskBloc>()
          .add(FetchTaskStatuses(projectId: _projectContextId));
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

        if (_tabTitles.isNotEmpty) {
          final activeStatusId = _tabTitles[_currentTabIndex]['id'];
          context.read<TaskBloc>().add(FetchTasks(
                activeStatusId,
                projectIds: _projectFilterIds(),
                projectId: _projectContextId,
                reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
                    ? _selectedReasonForRefusalIds
                    : null,
              ));
        }
      });

      if (_tabTitles.isEmpty && !_isProjectContext) {
        await TaskCache.clearAllTasks();
        await TaskCache.clearCache();
      }

      final taskBloc = BlocProvider.of<TaskBloc>(context);
      taskBloc.add(FetchTaskStatuses(projectId: _projectContextId));
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) async {
        debugPrint(
            'TaskScreen: _buildTabBarView listener - state: ${state.runtimeType}');
        // Сбрасываем флаги загрузки когда получены данные
        if (state is TaskDataLoaded || state is TaskError) {
          if (mounted && _isFilterLoading) {
            debugPrint('TaskScreen: _buildTabBarView - Resetting loader flags');
            setState(() {
              _isFilterLoading = false;
              _shouldShowLoader = false;
              _skipNextTabListener = false;
              _skipNextTabListenerIndex = null;
            });
          }
        }

        if (state is TaskLoaded) {
          if (_isProjectContext) {
            for (final status in state.taskStatuses) {
              _projectTaskCounts[status.id] =
                  int.tryParse(status.tasksCount) ?? 0;
            }
          }

          if (!_isProjectContext) {
            await TaskCache.cacheTaskStatuses(state.taskStatuses
                .map((status) => {
                      'id': status.id,
                      'title': status.taskStatus?.name ?? "",
                      'is_unassembled': status.isUnassembled,
                    })
                .toList());
          }

          if (mounted) {
            setState(() {
              final previousActiveStatusId =
                  _tabTitles.isNotEmpty && _currentTabIndex < _tabTitles.length
                      ? _tabTitles[_currentTabIndex]['id'] as int
                      : null;

              // Обновляем табы с новыми данными
              _tabTitles = state.taskStatuses
                  .where((status) => _canReadTaskStatus)
                  .map((status) =>
                      {'id': status.id, 'title': status.taskStatus?.name ?? ""})
                  .toList();
              _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

              if (_tabTitles.isNotEmpty) {
                // Проверяем, нужно ли создавать новый контроллер
                bool needNewController =
                    _tabController.length != _tabTitles.length;

                if (needNewController) {
                  // Dispose старого контроллера если он существует
                  if (_tabController.length > 0) {
                    _tabController.dispose();
                  }

                  // Создаем новый контроллер
                  _tabController =
                      TabController(length: _tabTitles.length, vsync: this);

                  // ← КРИТИЧНО: Добавляем listener ТОЛЬКО при создании нового контроллера!
                  _tabController.addListener(() {
                    if (!_tabController.indexIsChanging) {
                      // ← КРИТИЧНО: Проверяем флаг пропуска!
                      if (_skipNextTabListener &&
                          _skipNextTabListenerIndex == _tabController.index) {
                        debugPrint(
                            'TaskScreen: TabController listener - SKIPPED (filter just applied)');
                        setState(() {
                          _skipNextTabListener = false;
                          _skipNextTabListenerIndex = null;
                          _currentTabIndex = _tabController.index;
                        });
                        return; // ← ВЫХОДИМ БЕЗ ЗАПРОСА!
                      }

                      debugPrint(
                          'TaskScreen: TabController listener triggered, new index: ${_tabController.index}');

                      setState(() {
                        _currentTabIndex = _tabController.index;
                        _isFilterLoading = true;
                        _shouldShowLoader = true;
                      });

                      if (_tabScrollController.hasClients) {
                        _scrollToActiveTab();
                      }

                      if (_tabTitles.isEmpty ||
                          _currentTabIndex >= _tabTitles.length) {
                        return;
                      }

                      final currentStatusId =
                          _tabTitles[_currentTabIndex]['id'];
                      final hasActiveFilters = _hasActiveFilters();

                      context.read<TaskBloc>().add(FetchTasks(
                            currentStatusId,
                            query: _lastSearchQuery.isNotEmpty
                                ? _lastSearchQuery
                                : null,
                            userIds:
                                hasActiveFilters && _selectedUsers.isNotEmpty
                                    ? _selectedUsers
                                        .map((user) => user.id)
                                        .toList()
                                    : null,
                            statusIds:
                                hasActiveFilters ? currentStatusId : null,
                            fromDate: hasActiveFilters ? _fromDate : null,
                            toDate: hasActiveFilters ? _toDate : null,
                            overdue: hasActiveFilters ? _isOverdue : null,
                            hasFile: hasActiveFilters ? _hasFile : null,
                            hasDeal: hasActiveFilters ? _hasDeal : null,
                            urgent: hasActiveFilters ? _isUrgent : null,
                            reasonForRefusalIds: hasActiveFilters &&
                                    _selectedReasonForRefusalIds.isNotEmpty
                                ? _selectedReasonForRefusalIds
                                : null,
                            deadlinefromDate:
                                hasActiveFilters ? _deadlinefromDate : null,
                            deadlinetoDate:
                                hasActiveFilters ? _deadlinetoDate : null,
                            completedFromDate:
                                hasActiveFilters ? _completedFromDate : null,
                            completedToDate:
                                hasActiveFilters ? _completedToDate : null,
                            projectIds: _projectFilterIds(),
                            projectId: _projectContextId,
                            authors: hasActiveFilters &&
                                    _selectedAuthors.isNotEmpty
                                ? _selectedAuthors
                                : null,
                            department:
                                hasActiveFilters ? _selectedDepartment : null,
                            directoryValues: hasActiveFilters &&
                                    _selectedDirectoryValues.isNotEmpty
                                ? _selectedDirectoryValues
                                : null,
                          ));

                      debugPrint(
                          'TaskScreen: tab changed to index ${_tabController.index}');
                    }
                  }); // ← Закрываем listener здесь, только для нового контроллера!
                }

                // Установка правильного индекса
                if (needNewController) {
                  final preservedIndex = previousActiveStatusId != null
                      ? _tabTitles.indexWhere(
                          (status) => status['id'] == previousActiveStatusId,
                        )
                      : -1;

                  if (preservedIndex != -1) {
                    _tabController.index = preservedIndex;
                    _currentTabIndex = preservedIndex;
                  } else if (_currentTabIndex < _tabTitles.length &&
                      _currentTabIndex >= 0) {
                    _tabController.index = _currentTabIndex;
                  } else {
                    _tabController.index = 0;
                    _currentTabIndex = 0;
                  }
                } else {
                  int initialIndex = state.taskStatuses.indexWhere(
                      (status) => status.id == widget.initialStatusId);
                  if (initialIndex != -1 && initialIndex != _currentTabIndex) {
                    _tabController.index = initialIndex;
                    _currentTabIndex = initialIndex;
                  } else if (_tabTitles.isNotEmpty) {
                    int safeIndex = _currentTabIndex < _tabTitles.length
                        ? _currentTabIndex
                        : 0;
                    _tabController.index = safeIndex;
                    _currentTabIndex = safeIndex;
                  }
                }

                // Прокручиваем к активному табу
                if (_tabScrollController.hasClients) {
                  _scrollToActiveTab();
                }

                if (_skipNextTabListener) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _skipNextTabListener) {
                      setState(() {
                        _skipNextTabListener = false;
                        _skipNextTabListenerIndex = null;
                      });
                    }
                  });
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
                    int newIndex = _deletedIndex! >= _tabTitles.length
                        ? _tabTitles.length - 1
                        : _deletedIndex!;
                    newIndex = newIndex < 0 ? 0 : newIndex;
                    Future.delayed(Duration(milliseconds: 100), () {
                      if (mounted) {
                        _tabController.animateTo(newIndex);
                        _currentTabIndex = newIndex;
                      }
                    });
                  }
                }

                if (_pendingStatusIdAfterHardRefresh != null) {
                  final pendingIndex = _tabTitles.indexWhere(
                    (status) =>
                        status['id'] == _pendingStatusIdAfterHardRefresh,
                  );

                  if (pendingIndex != -1) {
                    _currentTabIndex = pendingIndex;
                    _tabController.index = pendingIndex;
                  }

                  _pendingStatusIdAfterHardRefresh = null;
                }

                if (_tabTitles.isNotEmpty) {
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  final hasActiveFilters = _hasActiveFilters();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _tabTitles.isEmpty) return;
                    context.read<TaskBloc>().add(FetchTasks(
                          currentStatusId,
                          query: _lastSearchQuery.isNotEmpty
                              ? _lastSearchQuery
                              : null,
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
                          reasonForRefusalIds: hasActiveFilters &&
                                  _selectedReasonForRefusalIds.isNotEmpty
                              ? _selectedReasonForRefusalIds
                              : null,
                          deadlinefromDate:
                              hasActiveFilters ? _deadlinefromDate : null,
                          deadlinetoDate:
                              hasActiveFilters ? _deadlinetoDate : null,
                          completedFromDate:
                              hasActiveFilters ? _completedFromDate : null,
                          completedToDate:
                              hasActiveFilters ? _completedToDate : null,
                          projectIds: _projectFilterIds(),
                          projectId: _projectContextId,
                          authors:
                              hasActiveFilters && _selectedAuthors.isNotEmpty
                                  ? _selectedAuthors
                                  : null,
                          department:
                              hasActiveFilters ? _selectedDepartment : null,
                          directoryValues: hasActiveFilters &&
                                  _selectedDirectoryValues.isNotEmpty
                              ? _selectedDirectoryValues
                              : null,
                        ));
                  });
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
            await AppLogoutService.logoutAndReset(
              context: context,
              restartApp: false,
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
                    color: context.appColors.textInverse,
                  ),
                ),
                backgroundColor: context.appColors.success,
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
                    color: context.appColors.textInverse,
                  ),
                ),
                backgroundColor: context.appColors.success,
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
              children: List.generate(_tabTitles.length, (index) {
                final status = _tabTitles[index];
                return TaskColumn(
                  isTaskScreenTutorialCompleted:
                      _isTaskScreenTutorialCompleted,
                  statusId: status['id'],
                  name: status['title'],
                  userId: _selectedUserId,
                  projectId: _projectContextId,
                  isActive: index == _tabController.index,
                  onStatusId: (newStatusId) {
                    _hardRefreshAfterTaskChange(newStatusId);
                  },
                );
              }),
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
        double targetOffset = _tabScrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);

        if (targetOffset != _tabScrollController.offset) {
          _tabScrollController.animateTo(
            targetOffset,
            duration: Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      }
    }
  }
}
