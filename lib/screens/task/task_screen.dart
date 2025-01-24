import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
import 'package:crm_task_manager/screens/task/task_details/task_column.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_add.dart';
import 'package:crm_task_manager/screens/task/task_status_delete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<int> _selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadUserRoles();
    TaskCache.getTaskStatuses().then((cachedStatuses) {
      if (cachedStatuses.isNotEmpty) {
        setState(() {
          _tabTitles = cachedStatuses;

          // Инициализация TabController только один раз
          _tabController =
              TabController(length: _tabTitles.length, vsync: this);

          int initialIndex = cachedStatuses
              .indexWhere((status) => status['id'] == widget.initialStatusId);
          if (initialIndex != -1) {
            _currentTabIndex = initialIndex;
          }
          _tabController.index = _currentTabIndex;
        });

        // Добавляем слушатель для _tabController после его инициализации
        _tabController.addListener(() {
          setState(() {
            _currentTabIndex = _tabController.index;
          });
          final currentStatusId = _tabTitles[_currentTabIndex]['id'];
          if (_scrollController.hasClients) {
            _scrollToActiveTab();
          }
        });
      } else {
        BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());

        print("Инициализация: отправлен запрос на получение статусов лидов");
      }
    });
    _checkPermissions();
  }

  Future<void> _loadUserRoles() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';
      if (userId.isEmpty) {
        setState(() {
          userRoles = ['No user ID found'];
          showFilter = false;
        });
        return;
      }
      UserByIdProfile userProfile =
          await ApiService().getUserById(int.parse(userId));
      if (mounted) {
        setState(() {
          userRoles = userProfile.role?.map((role) => role.name).toList() ??
              ['No role assigned'];
          showFilter = userRoles.any((role) =>
              role.toLowerCase() == 'admin' || role.toLowerCase() == 'manager');
        });
      }
    } catch (e) {
      print('Error loading user roles!');
      if (mounted) {
        setState(() {
          userRoles = ['Error loading roles'];
          showFilter = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchTasks(String query, int currentStatusId) async {
    final taskBloc = BlocProvider.of<TaskBloc>(context);

    if (query.isEmpty) {
      taskBloc.add(FetchTasks(currentStatusId));
    } else {
      taskBloc.add(FetchTasks(
        currentStatusId,
        query: query,
        userIds: _selectedUserIds,
      ));
    }
  }

  void _handleUserSelected(List<dynamic> users) {
    print('Raw selected users: $users');
    setState(() {
      _selectedUserIds = users
          .map((user) {
            if (user is UserTask) {
              return user.id; // Assuming UserTask has an id property
            }
            return null;
          })
          .where((id) => id != null)
          .cast<int>()
          .toList();

      print('Converted user IDs: $_selectedUserIds'); // Debug print
    });
    _refreshCurrentTab();

    // Запрашиваем обновленные данные с учетом выбранного пользователя
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTasks(
      currentStatusId,
      userIds: _selectedUserIds.isNotEmpty ? _selectedUserIds : null,
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
    ));
  }

  void _refreshCurrentTab() {
    if (_tabTitles.isNotEmpty) {
      final currentStatusId = _tabTitles[_currentTabIndex]['id'];
      final taskBloc = BlocProvider.of<TaskBloc>(context);
      taskBloc.add(FetchTasks(
        currentStatusId,
        userIds: _selectedUserIds.isNotEmpty ? _selectedUserIds : null,
        query:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      ));
    }
  }

  void _onSearch(String query) {
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchTasks(query, currentStatusId);
  }

  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('taskStatus.read');
    final canCreate = await _apiService.hasPermission('taskStatus.create');
    final canDelete = await _apiService.hasPermission('taskStatus.delete');
    setState(() {
      _canReadTaskStatus = canRead;
      _canCreateTaskStatus = canCreate;
      _canDeleteTaskStatus = canDelete;
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
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
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
          // onUsersSelected: _handleUserSelected,
          textEditingController: textEditingController,
          focusNode: focusNode,
          showFilterIcon: false,
          showMyTaskIcon: false, // Выключаем иконку My Tasks
          showFilterTaskIcon: showFilter,
          clearButtonClick: (value) {
            if (value == false) {
              final taskBloc = BlocProvider.of<TaskBloc>(context);
              taskBloc.add(FetchTaskStatuses());

              //  BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());

              setState(() {
                _isSearching = false;
                _selectedUserId = null;
              });
            }
          },
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Column(
              children: [
                const SizedBox(height: 15),
                if (!_isSearching && _selectedUserId == null)
                  _buildCustomTabBar(),
                Expanded(
                  child: _selectedUserId != null
                      ? _buildUserView()
                      : _buildTabBarView(),
                ),
              ],
            ),
    );
  }
Widget searchWidget(List<Task> tasks) {
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
  }
  return Flexible(
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
                  onStatusId: (StatusLeadId) {},
          ),
        );
      },
    ),
  );
}

Widget _buildUserView() {
  return BlocBuilder<TaskBloc, TaskState>(
    builder: (context, state) {
      if (state is TaskDataLoaded) {
        final List<Task> tasks = state.tasks;
        if (tasks.isEmpty) {
          return Center(
            child: Text(
              _selectedUserId != null
                  ? 'У выбранного менеджера нет лидов'
                  : 'По запросу ничего не найдено',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff99A4BA),
              ),
            ),
          );
        }
        return Flexible(
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
                  onStatusId: (StatusLeadId) {},
                ),
              );
            },
          ),
        );
      }
      if (state is TaskLoading) {
        return const Center(
          child: PlayStoreImageLoading(
            size: 80.0,
            duration: Duration(milliseconds: 1000),
          ),
        );
      }
      return const SizedBox();
    },
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

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        int taskCount = 0;
        print("==========================count");
        print(taskCount);
        if (state is TaskLoaded) {
          final statusId = _tabTitles[index]['id'];
          final taskStatus = state.taskStatuses.firstWhere(
            (status) => status.id == statusId,
            // orElse: () => null,
          );
          taskCount = taskStatus?.tasksCount ?? 0; // Используем tasksCount
        }
        print("==========================count");
        print(taskCount);
        return GestureDetector(
          key: _tabKeys[index],
          onTap: () {
            _tabController.animateTo(index);
          },
          onLongPress: () {
            if (_canDeleteTaskStatus) {
              _showDeleteDialog(index);
            }
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        color:
                            isActive ? Colors.black : const Color(0xff99A4BA),
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
      },
    );
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
      final taskBloc = BlocProvider.of<TaskBloc>(context);
      taskBloc.add(FetchTaskStatuses());
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) async {
        if (state is TaskLoaded) {
          await TaskCache.cacheTaskStatuses(state.taskStatuses
              .map((status) =>
                  {'id': status.id, 'title': status.taskStatus!.name ?? ""})
              .toList());

          setState(() {
            _tabTitles = state.taskStatuses
                .where((status) => _canReadTaskStatus)
                .map((status) =>
                    {'id': status.id, 'title': status.taskStatus!.name ?? ""})
                .toList();
            _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

            if (_tabTitles.isNotEmpty) {
              _tabController =
                  TabController(length: _tabTitles.length, vsync: this);
              _tabController.addListener(() {
                setState(() {
                  _currentTabIndex = _tabController.index;
                });
                final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                if (_scrollController.hasClients) {
                  _scrollToActiveTab();
                }
              });
              int initialIndex = state.taskStatuses
                  .indexWhere((status) => status.id == widget.initialStatusId);
              if (initialIndex != -1) {
                _tabController.index = initialIndex;
                _currentTabIndex = initialIndex;
              } else {
                _tabController.index = _currentTabIndex;
              }

              if (_scrollController.hasClients) {
                _scrollToActiveTab();
              }

              //Логика для перехода к созданн статусе
              if (navigateToEnd) {
                navigateToEnd = false;
                if (_tabController != null) {
                  _tabController.animateTo(_tabTitles.length - 1);
                }
              }

              //Логика для перехода к после удаления статусе на лево
              if (navigateAfterDelete) {
                navigateAfterDelete = false;
                if (_deletedIndex != null) {
                  if (_deletedIndex == 0 && _tabTitles.length > 1) {
                    _tabController.animateTo(1);
                  } else if (_deletedIndex == _tabTitles.length) {
                    _tabController.animateTo(_tabTitles.length - 1);
                  } else {
                    _tabController.animateTo(_deletedIndex! - 1);
                  }
                }
              }
            }
          });
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
          } else if (state.message.contains(
            AppLocalizations.of(context)!.translate('no_internet_connection'),
          )) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
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
        }
      },
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          print('state: ${state.runtimeType}');
          if (state is TaskDataLoaded) {
            final List<Task> tasks = state.tasks;
            print(tasks);
            return searchWidget(tasks);
          }
          if (state is TaskLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is TaskLoaded) {
            if (_tabTitles.isEmpty) {
              return const Center(child: Text(''));
            }
            return TabBarView(
              controller: _tabController,
              // key: UniqueKey(),
              children: List.generate(_tabTitles.length, (index) {
                final statusId = _tabTitles[index]['id'];
                final title = _tabTitles[index]['title'];
                return TaskColumn(
                  statusId: statusId,
                  name: title,
                  userId: _selectedUserId,
                  onStatusId: (newStatusId) {
                    print('Status ID changed: $newStatusId');
                    final index = _tabTitles
                        .indexWhere((status) => status['id'] == newStatusId);

                    // context.read<TaskBloc>().add(FetchTaskStatuses());
                    final taskBloc = BlocProvider.of<TaskBloc>(context);
                    taskBloc.add(FetchTaskStatuses());

                    if (index != -1) {
                      _tabController.animateTo(index);
                    }
                  },
                );
              }),
            );
          }
          return const SizedBox();
        },
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
