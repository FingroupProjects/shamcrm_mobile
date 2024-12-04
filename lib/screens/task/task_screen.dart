
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
import 'package:crm_task_manager/screens/task/task_details/task_column.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_add.dart';
import 'package:crm_task_manager/screens/task/task_status_delete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTaskStatuses());
    print("Инициализация: отправлен запрос на получение статусов задачи");
    _checkPermissions();
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
      taskBloc.add(FetchTasks(currentStatusId, query: query));
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: 'Задачи',
          onClickProfileAvatar: () {
            setState(() {
              final taskBloc = BlocProvider.of<TaskBloc>(context);
              taskBloc.add(FetchTaskStatuses());
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
          clearButtonClick: (value) {
            if (value == false) {
              final taskBloc = BlocProvider.of<TaskBloc>(context);
              taskBloc.add(FetchTaskStatuses());
              setState(() {
                _isSearching = false;
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
                if (!_isSearching) _buildCustomTabBar(),
                Expanded(child: _buildTabBarView()),
              ],
            ),
    );
  }

  Widget searchWidget(List<Task> tasks) {
    if (_isSearching && tasks.isEmpty) {
      return Center(
        child: Text(
          'По запросу ничего не найдено',
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
          final statusId = _tabTitles[_currentTabIndex]['id'];
          final title = _tabTitles[_currentTabIndex]['title'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TaskCard(
              task: tasks[index],
              name: title,
              statusId: statusId,
              onStatusUpdated: () {
                context.read<TaskBloc>().add(FetchTasks(statusId));
              },
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
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => CreateStatusDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _tabTitles.add({'id': _tabTitles.length + 1, 'title': result});
        _tabKeys.add(GlobalKey());
      });
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
      },
       onLongPress: () {
      // Показываем диалог удаления только если есть разрешение
      if (_canDeleteTaskStatus) {
        _showDeleteDialog(index);
      }
    },
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Center(
          child: Text(
            _tabTitles[index]['title'],
            style: TaskStyles.tabTextStyle.copyWith(
              color:
                  isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
            ),
          ),
        ),
      ),
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
        _tabTitles.removeAt(index);
        _tabKeys.removeAt(index);
        _tabController = TabController(length: _tabTitles.length, vsync: this);
        _currentTabIndex = 0;

        _isSearching = false;
        _searchController.clear();

        context.read<TaskBloc>().add(FetchTasks(_currentTabIndex));
      });
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskLoaded) {
          setState(() {
            _tabTitles = state.taskStatuses
                .where((status) => _canReadTaskStatus) 
                .map((status) => {'id': status.id, 'title': status.taskStatus.name})
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
            }
          });
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
                child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is TaskLoaded) {
            if (_tabTitles.isEmpty) {
              return const Center(child: Text('Нет статусов для отображения'));
            }
            return TabBarView(
              controller: _tabController,
              // key: UniqueKey(),
              children: List.generate(_tabTitles.length, (index) {
                final statusId = _tabTitles[index]['id'];
                final title = _tabTitles[index]['title'];
                return TaskColumn(statusId: statusId, name: title);
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
      final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;

      if (position.dx < 0 || (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
        double targetOffset = _scrollController.offset + position.dx - (MediaQuery.of(context).size.width / 2) + (tabWidth / 2);

        if (targetOffset != _scrollController.offset) {
          _scrollController.animateTo(
            targetOffset,
            duration: Duration(milliseconds: 10),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }
}

// import 'package:crm_task_manager/bloc/task/task_bloc.dart';
// import 'package:crm_task_manager/bloc/task/task_event.dart';
// import 'package:crm_task_manager/bloc/task/task_state.dart';
// import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
// import 'package:crm_task_manager/models/task_model.dart';
// import 'package:crm_task_manager/screens/deal/tabBar/deal_status_add.dart';
// import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
// import 'package:crm_task_manager/screens/task/task_details/task_column.dart';
// import 'package:crm_task_manager/screens/task/task_status_delete.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

// class TaskScreen extends StatefulWidget {
//   final int? initialStatusId;

//   TaskScreen({this.initialStatusId});
//   @override
//   _TaskScreenState createState() => _TaskScreenState();
// }

// class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
//   late TabController _tabController;
//   late ScrollController _scrollController;
//   List<Map<String, dynamic>> _tabTitles = [];
//   List<GlobalKey> _tabKeys = [];
//   int _currentTabIndex = 0;
//   bool _isSearching = false; // Track whether we are searching
//   final TextEditingController _searchController = TextEditingController(); // Controller for search input

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     final taskBloc = BlocProvider.of<TaskBloc>(context);
//     taskBloc.add(FetchTaskStatuses());
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   // Search logic
//   Future<void> _searchTasks(String query, int currentStatusId) async {
//     final taskBloc = BlocProvider.of<TaskBloc>(context);
//     if (query.isEmpty) {
//       taskBloc.add(FetchTasks(currentStatusId)); // Fetch all tasks if search query is empty
//     } else {
//       taskBloc.add(FetchTasks(currentStatusId, query: query)); // Fetch tasks with search query
//     }
//   }

//   void _onSearch(String query) {
//     final currentStatusId = _tabTitles[_currentTabIndex]['id'];
//     _searchTasks(query, currentStatusId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         forceMaterialTransparency: true,
//         title: CustomAppBar(
//           title: 'Задачи',
//           onClickProfileAvatar: () {},
//           onChangedSearchInput: (String value) {
//             setState(() {
//               _isSearching = value.isNotEmpty;
//             });
//             _onSearch(value); // Trigger search on input change
//           },
//           textEditingController: _searchController,
//           focusNode: FocusNode(),
//           clearButtonClick: (value) {
//             if (value == false) {
//               final taskBloc = BlocProvider.of<TaskBloc>(context);
//               taskBloc.add(FetchTaskStatuses());
//               setState(() {
//                 _isSearching = false;
//               });
//             }
//           },
//         ),
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 15),
//           if (!_isSearching) _buildCustomTabBar(),
//           Expanded(child: _buildTabBarView()),
//         ],
//       ),
//     );
//   }

//   Widget searchWidget(List<Task> tasks) {
//     if (_isSearching && tasks.isEmpty) {
//       return Center(
//         child: Text(
//           'По запросу ничего не найдено',
//           style: const TextStyle(
//             fontSize: 18,
//             fontFamily: 'Gilroy',
//             fontWeight: FontWeight.w500,
//             color: Color(0xff99A4BA),
//           ),
//         ),
//       );
//     }

//     return Flexible(
//       child: ListView.builder(
//         controller: _scrollController,
//         itemCount: tasks.length,
//         itemBuilder: (context, index) {
//           final statusId = _tabTitles[_currentTabIndex]['id'];
//           final title = _tabTitles[_currentTabIndex]['title'];
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: TaskCard(
//               task: tasks[index],
//               name: title,
//               statusId: statusId,
//               onStatusUpdated: () {
//                 context.read<TaskBloc>().add(FetchTasks(statusId));
//               }, 
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCustomTabBar() {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       controller: _scrollController,
//       child: Row(
//         children: [
//           ...List.generate(_tabTitles.length, (index) {
//             if (_tabKeys.length <= index) {
//               _tabKeys.add(GlobalKey());
//             }
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               child: _buildTabButton(index),
//             );
//           }),
//           IconButton(
//             icon: Image.asset('assets/icons/tabBar/add_black.png', width: 24, height: 24),
//             onPressed: _addNewTab,
//           ),
//         ],
//       ),
//     );
//   }

//   void _addNewTab() async {
//     final result = await showDialog<String>(
//       context: context,
//       builder: (BuildContext context) => CreateStatusDialog(),
//     );

//     if (result != null && result.isNotEmpty) {
//       setState(() {
//         _tabTitles.add({'id': _tabTitles.length + 1, 'name': result});
//         _tabKeys.add(GlobalKey());
//       });
//     }
//   }

//   Widget _buildTabButton(int index) {
//     bool isActive = _tabController.index == index;
//     return GestureDetector(
//       key: _tabKeys[index],
//       onTap: () {
//         _tabController.animateTo(index);
//       },
//       onLongPress: () {
//         _showDeleteDialog(index);
//       },
//       child: Container(
//         decoration: TaskStyles.tabButtonDecoration(isActive),
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//         child: Center(
//           child: Text(
//             _tabTitles[index]['title'],
//             style: TaskStyles.tabTextStyle.copyWith(
//               color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showDeleteDialog(int index) async {
//     final taskStatusId = _tabTitles[index]['id'];

//     final result = await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return DeleteTaskStatusDialog(taskStatusId: taskStatusId);
//       },
//     );

//     if (result != null && result) {
//       setState(() {
//         _tabTitles.removeAt(index);
//         _tabKeys.removeAt(index);
//         _tabController = TabController(length: _tabTitles.length, vsync: this);
//         _currentTabIndex = 0;
//       });
//     }
//   }

//   Widget _buildTabBarView() {
//     return BlocListener<TaskBloc, TaskState>(
//       listener: (context, state) {
//         if (state is TaskLoaded) {
//           setState(() {
//             _tabTitles = state.taskStatuses
//                 .map((status) => {'id': status.id, 'title': status.taskStatus.name})
//                 .toList();
//             _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
//             if (_tabTitles.isNotEmpty) {
//               _tabController = TabController(length: _tabTitles.length, vsync: this);
//               _tabController.addListener(() {
//                 setState(() {
//                   _currentTabIndex = _tabController.index;
//                 });

//                 if (_scrollController.hasClients) {
//                   _scrollToActiveTab();
//                 }
//               });

//               int initialIndex = state.taskStatuses
//                   .indexWhere((status) => status.id == widget.initialStatusId);
//               if (initialIndex != -1) {
//                 _tabController.index = initialIndex;
//                 _currentTabIndex = initialIndex;
//               } else {
//                 _tabController.index = _currentTabIndex;
//               }

//               // Scroll to active tab on load
//               if (_scrollController.hasClients) {
//                 _scrollToActiveTab();
//               }
//             }
//           });
//         }
//       },
//       child: BlocBuilder<TaskBloc, TaskState>(
//         builder: (context, state) {
//           if (state is TaskLoading) {
//             return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
//           } else if (state is TaskLoaded) {
//             if (_tabTitles.isEmpty) {
//               return const Center(child: Text('Нет статусов для отображения.'));
//             }
//             if (_isSearching) {
//               return searchWidget(state.tasks);
//             }
//             return TabBarView(
//               controller: _tabController,
//               children: List.generate(_tabTitles.length, (index) {
//                 final taskStatus = state.taskStatuses[index];
//                 final statusId = taskStatus.id;
//                 final name = taskStatus.taskStatus.name;

//                 return TaskColumn(statusId: statusId, name: name);
//               }),
//             );
//           } else if (state is TaskError) {
//             return Center(child: Text(state.message));
//           } else {
//             return const Center(child: Text('Неизвестное состояние!'));
//           }
//         },
//       ),
//     );
//   }

//    void _scrollToActiveTab() {
//     final key = _tabKeys[_currentTabIndex];
//     if (key.currentContext != null) {
//       Scrollable.ensureVisible(key.currentContext!,
//           duration: const Duration(milliseconds: 300));
//     }
//   }
// }
