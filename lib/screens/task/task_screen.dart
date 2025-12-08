import 'dart:convert';

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
import 'package:crm_task_manager/screens/task/task_details/task_status_add.dart';
import 'package:crm_task_manager/screens/task/task_status_delete.dart';
import 'package:crm_task_manager/screens/task/task_status_edit.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
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

  @override
  void initState() {
    super.initState();
    
    // ← КРИТИЧНО: Инициализируем пустой TabController
    _tabController = TabController(length: 0, vsync: this);
    
    context.read<GetAllClientBloc>().add(GetAllClientEv());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadUserRoles();
    // НЕ загружаем состояние фильтров - каждый раз начинаем с чистого листа
    
    // Запускаем загрузку статусов
    BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());
    
    _checkPermissions();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedUsers = (jsonDecode(prefs.getString('task_selected_users') ?? '[]') as List)
          .map((u) => UserData.fromJson(u))
          .toList();
      _selectedStatuses = prefs.getInt('task_selected_statuses');
      _fromDate = prefs.getString('task_from_date') != null
          ? DateTime.parse(prefs.getString('task_from_date')!)
          : null;
      _toDate = prefs.getString('task_to_date') != null
          ? DateTime.parse(prefs.getString('task_to_date')!)
          : null;
      _deadlinefromDate = prefs.getString('task_deadline_from_date') != null
          ? DateTime.parse(prefs.getString('task_deadline_from_date')!)
          : null;
      _deadlinetoDate = prefs.getString('task_deadline_to_date') != null
          ? DateTime.parse(prefs.getString('task_deadline_to_date')!)
          : null;
      _isOverdue = prefs.getBool('task_is_overdue') ?? false;
      _hasFile = prefs.getBool('task_has_file') ?? false;
      _hasDeal = prefs.getBool('task_has_deal') ?? false;
      _isUrgent = prefs.getBool('task_is_urgent') ?? false;
      _selectedProject = prefs.getString('task_selected_project');
      _selectedAuthors = (jsonDecode(prefs.getString('task_selected_authors') ?? '[]') as List).cast<String>();
      _selectedDepartment = prefs.getString('task_selected_department');
      _selectedDirectoryValues = (jsonDecode(prefs.getString('task_selected_directory_values') ?? '[]') as List)
          .map((d) => Map<String, dynamic>.from(d))
          .toList();

      _initialselectedUsers = List.from(_selectedUsers);
      _initialSelStatus = _selectedStatuses;
      _intialFromDate = _fromDate;
      _intialToDate = _toDate;
      _intialDeadlineFromDate = _deadlinefromDate;
      _intialDeadlineToDate = _deadlinetoDate;
      _initialOverdue = _isOverdue;
      _initialHasFile = _hasFile;
      _initialHasDeal = _hasDeal;
      _initialUrgent = _isUrgent;
      _initialSelectedAuthors = List.from(_selectedAuthors);
      _initialSelectedDepartment = _selectedDepartment;
      _initialDirectoryValues = List.from(_selectedDirectoryValues);

    });
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
            : (_selectedProject != null ? [int.parse(_selectedProject!)] : null);
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
Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('task_selected_users', jsonEncode(_selectedUsers.map((u) => u.toJson()).toList()));
    await prefs.setInt('task_selected_statuses', _selectedStatuses ?? 0);
    await prefs.setString('task_from_date', _fromDate?.toIso8601String() ?? '');
    await prefs.setString('task_to_date', _toDate?.toIso8601String() ?? '');
    await prefs.setString('task_deadline_from_date', _deadlinefromDate?.toIso8601String() ?? '');
    await prefs.setString('task_deadline_to_date', _deadlinetoDate?.toIso8601String() ?? '');
    await prefs.setBool('task_is_overdue', _isOverdue);
    await prefs.setBool('task_has_file', _hasFile);
    await prefs.setBool('task_has_deal', _hasDeal);
    await prefs.setBool('task_is_urgent', _isUrgent);
    await prefs.setString('task_selected_project', _selectedProject ?? '');
    await prefs.setString('task_selected_authors', jsonEncode(_selectedAuthors));
    await prefs.setString('task_selected_department', _selectedDepartment ?? '');
    await prefs.setString('task_selected_directory_values', jsonEncode(_selectedDirectoryValues));
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRoles() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';
      if (userId.isEmpty) {
        setState(() { userRoles = ['No user ID found']; });
        return;
      }
      UserByIdProfile userProfile = await ApiService().getUserById(int.parse(userId));
      if (mounted) {
        setState(() {
          userRoles = userProfile.role?.map((role) => role.name).toList() ?? ['No role assigned'];
        });
      }
    } catch (e) {
      //print('Error loading user roles: $e');
      if (mounted) {
        setState(() { userRoles = ['Error loading roles']; });
      }
    }
  }

  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('taskStatus.read');
    final canCreate = await _apiService.hasPermission('taskStatus.create');
    final canUpdate = await _apiService.hasPermission('taskStatus.update');
    final canDelete = await _apiService.hasPermission('taskStatus.delete');
    final hasPermission = await _apiService.hasPermission('task.create');
    final progress = await _apiService.getTutorialProgress();
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

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownTaskSearchIconAppBar') ?? false;
    setState(() { _isTutorialShown = isTutorialShown; });

    if (tutorialProgress != null && tutorialProgress!['tasks']?['index'] == false && !_isTutorialShown && mounted) {
      _initTutorialTargets();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          //showTutorial();
        }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при обновлении данных: ${e.toString()}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () => _onRefresh(currentStatusId),
            ),
          ),
        );

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

    await Future.delayed(Duration(milliseconds: 50));

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
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchTasks(query, currentStatusId);
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
          if (_shouldShowLoader || _isFilterLoading || state is TaskLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          }

          if (state is TaskDataLoaded) {
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
                          ? AppLocalizations.of(context)!
                          .translate('selected_manager_has_any_lead')
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
      BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());

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
            {'id': status.id, 'title': status.taskStatus!.name ?? ""})
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
                  setState(() {
                    _currentTabIndex = _tabController.index;
                  });
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  if (_scrollController.hasClients) {
                    _scrollToActiveTab();
                  }

                  bool hasActiveFilters = _hasActiveFilters();
                  
                  // Преобразуем project_ids в List<int>
                  List<int>? projectIdsList = _selectedProjects.isNotEmpty
                      ? _selectedProjects.map((id) => int.parse(id)).toList()
                      : (_selectedProject != null ? [int.parse(_selectedProject!)] : null);

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

              // Автоматически загружаем задачи для активного статуса после refresh
              Future.delayed(Duration(milliseconds: 150), () {
                if (mounted && _tabTitles.isNotEmpty) {
                  final activeStatusId = _tabTitles[_currentTabIndex]['id'];

                  final bool hasActiveFilters = _hasActiveFilters();

                  if (!hasActiveFilters) {
                    context.read<TaskBloc>().add(FetchTasks(
                      activeStatusId,
                    ));
                  } else {
                    debugPrint('TaskScreen: Skip auto FetchTasks due to active filters');
                  }
                }
              });

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
          if (mounted) {
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
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Повторить',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<TaskBloc>().add(FetchTaskStatuses(forceRefresh: true));
                  },
                ),
              ),
            );
          }
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
