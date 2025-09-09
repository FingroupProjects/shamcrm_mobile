import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_status_edit.dart';
import 'package:crm_task_manager/screens/my-task/my_task_cache.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_card.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_column.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_status_add.dart';
import 'package:crm_task_manager/screens/my-task/task_status_delete.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTaskScreen extends StatefulWidget {
  final int? initialStatusId;

  MyTaskScreen({this.initialStatusId});

  @override
  _MyTaskScreenState createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  late ScrollController _scrollController;
  List<Map<String, dynamic>> _tabTitles = [];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _canDeleteMyTaskStatus = false;
  bool navigateToEnd = false;
  bool navigateAfterDelete = false;
  int? _deletedIndex;
  int? _selectedUserId;
  List<String> userRoles = [];
  bool showFilter = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadUserRoles();
    MyTaskCache.getMyTaskStatuses().then((cachedStatuses) {
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
        BlocProvider.of<MyTaskBloc>(context).add(FetchMyTaskStatuses());

        //print("Инициализация: отправлен запрос на получение статусов лидов");
      }
    });
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
      //print('Error loading user roles!');
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

  Future<void> _searchMyTasks(String query, int currentStatusId) async {
    final taskBloc = BlocProvider.of<MyTaskBloc>(context);

    if (query.isEmpty) {
      taskBloc.add(FetchMyTasks(currentStatusId));
    } else {
      await MyTaskCache.clearAllMyTasks();

      taskBloc.add(FetchMyTasks(
        currentStatusId,
        query: query,
      ));
    }
  }

  void _onSearch(String query) {
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchMyTasks(query, currentStatusId);
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
              : localizations!.translate('appbar_my_tasks'),
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
          textEditingController: textEditingController,
          focusNode: focusNode,
          showFilterIcon: false,
          showFilterTaskIcon: false,
          showEvent: false,
          showMenuIcon: false,
          showNotification: false,
          clearButtonClick: (value) {
            if (value == false) {
              final taskBloc = BlocProvider.of<MyTaskBloc>(context);
              taskBloc.add(FetchMyTaskStatuses());

              setState(() {
                _isSearching = false;
                _selectedUserId = null;
              });
            }
          },
          clearButtonClickFiltr: (bool) {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Column(
              children: [
                const SizedBox(height: 15),
                if (!_isSearching && _selectedUserId == null)
                  _buildCustomTabBar(),
                // Оборачиваем TabBarView в Expanded
                Expanded(
                  child: _selectedUserId != null
                      ? _buildUserView()
                      : _buildTabBarView(),
                ),
              ],
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
      color: Colors.white,
      items: [
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
        _editMyTaskStatus(index);
      } else if (value == 'delete') {
        _showDeleteDialog(index);
      }
    });
  }

  void _editMyTaskStatus(int index) {
    // Extract lead status data if needed for editing
    final myTaskStatus = _tabTitles[
        index]; // Assuming _tabTitles holds the relevant data for the lead

    // Show the Edit Lead Status Screen as a modal dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditMyTaskStatusScreen(
          myTaskStatusId:
              myTaskStatus['id'], // Pass the lead status ID for editing
        );
      },
    );
  }

  Widget searchWidget(List<MyTask> tasks) {
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
            child: MyTaskCard(
              task: task,
              name: task.taskStatus?.title ?? "",
              statusId: task.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusMyTaskId) {},
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserView() {
    return BlocBuilder<MyTaskBloc, MyTaskState>(
      builder: (context, state) {
        if (state is MyTaskDataLoaded) {
          final List<MyTask> tasks = state.tasks;
          return userWidget(tasks);
        }
        if (state is MyTaskLoading) {
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

  Widget userWidget(List<MyTask> tasks) {
    if (_selectedUserId != null && tasks.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_tasks_for_user'),
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
            child: MyTaskCard(
              task: task,
              name: task.taskStatus?.title ?? "",
              statusId: task.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusMyTaskId) {},
            ),
          );
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
      BlocProvider.of<MyTaskBloc>(context).add(FetchMyTaskStatuses());

      final taskBloc = BlocProvider.of<MyTaskBloc>(context);
      taskBloc.add(FetchMyTaskStatuses());

      setState(() {
        navigateToEnd = true;
      });
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return BlocBuilder<MyTaskBloc, MyTaskState>(
      builder: (context, state) {
        int taskCount = 0;

        if (state is MyTaskLoaded) {
          final statusId = _tabTitles[index]['id'];
          final taskStatus = state.taskStatuses.firstWhere(
            (status) => status.id == statusId,
            // orElse: () => null,
          );
          taskCount = taskStatus?.tasksCount ?? 0; // Используем tasksCount
        }

        return GestureDetector(
          key: _tabKeys[index],
          onTap: () {
            _tabController.animateTo(index);
          },
          onLongPress: () {
            {
              _showStatusOptions(context, index);
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

    // Показываем диалог подтверждения удаления
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteMyTaskStatusDialog(taskStatusId: taskStatusId);
      },
    );

    if (result != null && result) {
      // Удаляем статус

      setState(() {
        _deletedIndex = _currentTabIndex;
        navigateAfterDelete = true;

        _tabTitles.removeAt(index);
        _tabKeys.removeAt(index);
        _tabController = TabController(length: _tabTitles.length, vsync: this);
        _currentTabIndex = 0;

        _isSearching = false;
        _searchController.clear();
      });

      // Проверяем количество оставшихся статусов
      if (_tabTitles.isEmpty) {
        // Если нет оставшихся статусов, очищаем кэш
        await MyTaskCache.clearAllMyTasks(); // Очищаем задачи из кэша
        await MyTaskCache.clearCache(); // Очищаем статусы из кэша
        //print('Кэш полностью очищен, так как все статусы удалены.');
      } else if (_tabTitles.length == 1) {
        // Если остался только один статус, удаляем его из кэша
        final remainingStatusId = _tabTitles.first['id'];
        await MyTaskCache
            .clearMyTaskStatuses(); // Удаляем все связанные статусы
        await MyTaskCache.cacheMyTaskStatuses(
            _tabTitles); // Перезаписываем оставшийся статус
        //print('Кэш обновлён: один статус остался после удаления.');
      }

      // Обновляем данные через Bloc
      final taskBloc = BlocProvider.of<MyTaskBloc>(context);
      taskBloc.add(FetchMyTaskStatuses());
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<MyTaskBloc, MyTaskState>(
      listener: (context, state) async {
        if (state is MyTaskLoaded) {
          await MyTaskCache.cacheMyTaskStatuses(state.taskStatuses
              .map((status) => {'id': status.id, 'title': status.title ?? ""})
              .toList());

          setState(() {
            _tabTitles = state.taskStatuses
                .map((status) => {'id': status.id, 'title': status.title ?? ""})
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
        } else if (state is MyTaskError) {
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
        }
      },
      child: BlocBuilder<MyTaskBloc, MyTaskState>(
        builder: (context, state) {
          // //print('state: ${state.runtimeType}');
          if (state is MyTaskDataLoaded) {
            final List<MyTask> tasks = state.tasks;
            return searchWidget(tasks);
          }
          if (state is MyTaskLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is MyTaskLoaded) {
            if (_tabTitles.isEmpty) {
              return const Center(child: Text(''));
            }
            return TabBarView(
              controller: _tabController,
              children: List.generate(_tabTitles.length, (index) {
                final statusId = _tabTitles[index]['id'];
                final title = _tabTitles[index]['title'];
                return MyTaskColumn(
                  statusId: statusId,
                  name: title,
                  userId: _selectedUserId,
                  onStatusId: (newStatusId) {
                    //print('Status ID changed: $newStatusId');
                    final index = _tabTitles
                        .indexWhere((status) => status['id'] == newStatusId);

                    final taskBloc = BlocProvider.of<MyTaskBloc>(context);
                    taskBloc.add(FetchMyTaskStatuses());

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
