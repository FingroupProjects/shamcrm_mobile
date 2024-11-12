import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

class LeadScreen extends StatefulWidget {
  final int? initialStatusId;

  LeadScreen({this.initialStatusId});

  @override
  _LeadScreenState createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _tabTitles = [];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatuses());
    print("Инициализация: отправлен запрос на получение статусов лидов");
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLeads(String query, int currentStatusId) async {
  final leadBloc = BlocProvider.of<LeadBloc>(context);

  if (query.isEmpty) {
    leadBloc.add(FetchLeads(currentStatusId));
    print("Поиск: пустой запрос, выводим лидов по статусу id = $currentStatusId");
  } else {
    leadBloc.add(FetchLeads(currentStatusId, query: query));
    print("Поиск: текущий статус лида id = $currentStatusId, поисковый запрос = '$query'");
    print("--------------------------------------------------------------------");

  }
}

  void _onSearch(String query) {
  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
  _searchLeads(query, currentStatusId);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 15),
          _buildSearchBar(),
          _buildCustomTabBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (_isSearching)
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  border: InputBorder.none,
                ),
                style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600),
                onChanged: (query) {
                  _onSearch(query);
                },
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.search, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _onSearch('');
                  final leadBloc = BlocProvider.of<LeadBloc>(context);
                  leadBloc.add(FetchLeadStatuses());
                });
              },
            ),
        ],
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
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => CreateStatusDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _tabTitles.add({'id': _tabTitles.length + 1, 'title': result});
        _tabKeys.add(GlobalKey());
      });
      print("Добавлен новый таб со статусом: id = ${_tabTitles.length}, название = '$result'");
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        print("Переключение на таб с индексом: $index, статус лида id = ${_tabTitles[index]['id']}");
        _tabController.animateTo(index);
      },
      onLongPress: () {
        _showDeleteDialog(index);
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
    final leadStatusId = _tabTitles[index]['id'];
    print("Удаление: попытка удалить статус лида с id = $leadStatusId");

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteLeadStatusDialog(leadStatusId: leadStatusId);
      },
    );

    if (result != null && result) {
      setState(() {
        print("Удаление: статус лида с id = $leadStatusId успешно удален");
        _tabTitles.removeAt(index);
        _tabKeys.removeAt(index);
        _tabController = TabController(length: _tabTitles.length, vsync: this);
        _currentTabIndex = 0;
      });
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadLoaded) {
          setState(() {
            _tabTitles = state.leadStatuses
                .map((status) => {'id': status.id, 'title': status.title})
                .toList();
            print("Получены статусы лидов: ${_tabTitles.map((status) => 'id: ${status['id']}, title: ${status['title']}').join('; ')}");
            _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

            if (_tabTitles.isNotEmpty) {
              _tabController =
                  TabController(length: _tabTitles.length, vsync: this);
              _tabController.addListener(() {
                setState(() {
                  _currentTabIndex = _tabController.index;
                });

                final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                print(
                    "Переключение на новый статус лида с id = $currentStatusId");

                if (_scrollController.hasClients) {
                  _scrollToActiveTab();
                }
              });

              int initialIndex = state.leadStatuses
                  .indexWhere((status) => status.id == widget.initialStatusId);
              if (initialIndex != -1) {
                _tabController.index = initialIndex;
                _currentTabIndex = initialIndex;
                print(
                    "Инициализация: установлен начальный статус с индексом $initialIndex и id = ${widget.initialStatusId}");
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
      child: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is LeadLoaded) {
    print("----------------------------------------------------------------------------------------------------------------");

            if (_tabTitles.isEmpty) {
              return const Center(child: Text('Нет статусов для отображения'));
            }
            return TabBarView(
              controller: _tabController,
              children: List.generate(_tabTitles.length, (index) {
                final statusId = _tabTitles[index]['id'];
                final title = _tabTitles[index]['title'];
                print(
                    "Отображение вкладки с id = $statusId, названием = '$title'");
                return LeadColumn(statusId: statusId, title: title);
              }),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _scrollToActiveTab() {
    final key = _tabKeys[_currentTabIndex];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!,
          duration: const Duration(milliseconds: 300));
    }
  }
}


// import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
// import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
// import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
// import 'package:crm_task_manager/bloc/lead/lead_event.dart';
// import 'package:crm_task_manager/bloc/lead/lead_state.dart';
// import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

// class LeadScreen extends StatefulWidget {
//   final int? initialStatusId;

//   LeadScreen({this.initialStatusId});
//   @override
//   _LeadScreenState createState() => _LeadScreenState();
// }

// class _LeadScreenState extends State<LeadScreen> with TickerProviderStateMixin {
//   late TabController _tabController;
//   late ScrollController _scrollController;
//   List<Map<String, dynamic>> _tabTitles = [];
//   int _currentTabIndex = 0;
//   List<GlobalKey> _tabKeys = [];

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     final leadBloc = BlocProvider.of<LeadBloc>(context);
//     leadBloc.add(FetchLeadStatuses());
//     print("Инициализация: отправлен запрос на получение статусов лидов");
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _tabController.dispose();
//     super.dispose();
//   }

//   void _onSearch(String query) {
//     final leadBloc = BlocProvider.of<LeadBloc>(context);
//     final currentStatusId = _tabTitles[_currentTabIndex]['id'];
//     print("Поиск: текущий статус лида id = $currentStatusId, поисковый запрос = '$query'");
//     leadBloc.add(FetchLeads(currentStatusId, query: query));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           const SizedBox(height: 15),
//           _buildCustomTabBar(),
//           Expanded(child: _buildTabBarView()),
//         ],
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
//             icon: Image.asset('assets/icons/tabBar/add_black.png',
//                 width: 24, height: 24),
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
//         _tabTitles.add({'id': _tabTitles.length + 1, 'title': result});
//         _tabKeys.add(GlobalKey());
//       });
//       print("Добавлен новый таб со статусом: id = ${_tabTitles.length}, название = '$result'");
//     }
//   }

//   Widget _buildTabButton(int index) {
//     bool isActive = _tabController.index == index;
//     return GestureDetector(
//       key: _tabKeys[index],
//       onTap: () {
//         print("Переключение на таб с индексом: $index, статус лида id = ${_tabTitles[index]['id']}");
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
//               color:
//                   isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showDeleteDialog(int index) async {
//     final leadStatusId = _tabTitles[index]['id'];
//     print("Удаление: попытка удалить статус лида с id = $leadStatusId");

//     final result = await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return DeleteLeadStatusDialog(leadStatusId: leadStatusId);
//       },
//     );

//     if (result != null && result) {
//       setState(() {
//         print("Удаление: статус лида с id = $leadStatusId успешно удален");
//         _tabTitles.removeAt(index);
//         _tabKeys.removeAt(index);
//         _tabController = TabController(length: _tabTitles.length, vsync: this);
//         _currentTabIndex = 0;
//       });
//     }
//   }

//   Widget _buildTabBarView() {
//     return BlocListener<LeadBloc, LeadState>(
//       listener: (context, state) {
//         if (state is LeadLoaded) {
//           setState(() {
//             _tabTitles = state.leadStatuses
//                 .map((status) => {'id': status.id, 'title': status.title})
//                 .toList();
//             print("Получены статусы лидов: ${_tabTitles.map((status) => 'id: ${status['id']}, title: ${status['title']}').join('; ')}");
//             _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
//             if (_tabTitles.isNotEmpty) {
//               _tabController =
//                   TabController(length: _tabTitles.length, vsync: this);
//               _tabController.addListener(() {
//                 setState(() {
//                   _currentTabIndex = _tabController.index;
//                 });

//                 final currentStatusId = _tabTitles[_currentTabIndex]['id'];
//                 print("Переключение на новый статус лида с id = $currentStatusId");

//                 if (_scrollController.hasClients) {
//                   _scrollToActiveTab();
//                 }
//               });

//               int initialIndex = state.leadStatuses
//                   .indexWhere((status) => status.id == widget.initialStatusId);
//               if (initialIndex != -1) {
//                 _tabController.index = initialIndex;
//                 _currentTabIndex = initialIndex;
//                 print("Инициализация: установлен начальный статус с индексом $initialIndex и id = ${widget.initialStatusId}");
//               } else {
//                 _tabController.index = _currentTabIndex;
//               }

//               if (_scrollController.hasClients) {
//                 _scrollToActiveTab();
//               }
//             }
//           });
//         }
//       },
//       child: BlocBuilder<LeadBloc, LeadState>(
//         builder: (context, state) {
//           if (state is LeadLoading) {
//             return const Center(
//                 child: CircularProgressIndicator(color: Color(0xff1E2E52)));
//           } else if (state is LeadLoaded) {
//             if (_tabTitles.isEmpty) {
//               return const Center(child: Text('Нет статусов для отображения'));
//             }
//             return TabBarView(
//               controller: _tabController,
//               children: List.generate(_tabTitles.length, (index) {
//                 final statusId = _tabTitles[index]['id'];
//                 final title = _tabTitles[index]['title'];
//                 print("Отображение таба с id = $statusId, заголовок = '$title'");
//                 return LeadColumn(statusId: statusId, title: title);
//               }),
//             );
//           } else if (state is LeadError) {
//             print("Ошибка: ${state.message}");
//             return Center(child: Text(state.message));
//           }
//           return const SizedBox();
//         },
//       ),
//     );
//   }

//   void _scrollToActiveTab() {
//     final keyContext = _tabKeys[_currentTabIndex].currentContext;
//     if (keyContext != null) {
//       final box = keyContext.findRenderObject() as RenderBox;
//       final position =
//           box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
//       final tabWidth = box.size.width;

//       if (position.dx < 0 ||
//           (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
//         double targetOffset = _scrollController.offset +
//             position.dx -
//             (MediaQuery.of(context).size.width / 2) +
//             (tabWidth / 2);

//         if (targetOffset != _scrollController.offset) {
//           print("Скролл: перемещение к активному табу с индексом $_currentTabIndex");
//           _scrollController.animateTo(
//             targetOffset,
//             duration: Duration(milliseconds: 1),
//             curve: Curves.easeInOut,
//           );
//         }
//       }
//     }
//   }
// }

//----------------------------------TABBARRRRRRR ONLY ----------------------------------------------------------------------///////
// import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
// import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
// import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
// import 'package:crm_task_manager/bloc/lead/lead_event.dart';
// import 'package:crm_task_manager/bloc/lead/lead_state.dart';
// import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

// class LeadScreen extends StatefulWidget {
//   final int? initialStatusId;

//   LeadScreen({this.initialStatusId});
//   @override
//   _LeadScreenState createState() => _LeadScreenState();
// }

// class _LeadScreenState extends State<LeadScreen> with TickerProviderStateMixin {
//   late TabController _tabController;
//   late ScrollController _scrollController; 
//   List<Map<String, dynamic>> _tabTitles = [];
//   int _currentTabIndex = 0;
//   List<GlobalKey> _tabKeys = []; 

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     final leadBloc = BlocProvider.of<LeadBloc>(context);
//     leadBloc.add(FetchLeadStatuses());
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           const SizedBox(height: 15),
//           _buildCustomTabBar(),
//           Expanded(child: _buildTabBarView()),
//         ],
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
//         _tabTitles.add({'id': _tabTitles.length + 1, 'title': result});
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
//     final leadStatusId = _tabTitles[index]['id'];

//     final result = await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return DeleteLeadStatusDialog(leadStatusId: leadStatusId);
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
//     return BlocListener<LeadBloc, LeadState>(
//       listener: (context, state) {
//         if (state is LeadLoaded) {
//           setState(() {
//             _tabTitles = state.leadStatuses.map((status) => {'id': status.id, 'title': status.title}).toList();
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

//               int initialIndex = state.leadStatuses
//                   .indexWhere((status) => status.id == widget.initialStatusId);
//               if (initialIndex != -1) {
//                 _tabController.index = initialIndex;
//                 _currentTabIndex = initialIndex;
//               } else {
//                 _tabController.index = _currentTabIndex;
//               }

//               // Прокручиваем таббар к активной вкладке сразу при загрузке
//               if (_scrollController.hasClients) {
//                 _scrollToActiveTab();
//               }
//             }
//           });
//         }
//       },
//       child: BlocBuilder<LeadBloc, LeadState>(
//         builder: (context, state) {
//           if (state is LeadLoading) {
//             return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
//           } else if (state is LeadLoaded) {
//             if (_tabTitles.isEmpty) {
//               return const Center(child: Text('Нет статусов для отображения'));
//             }
//             return TabBarView(
//               controller: _tabController,
//               children: List.generate(_tabTitles.length, (index) {
//                 final statusId = _tabTitles[index]['id'];
//                 final title = _tabTitles[index]['title'];
//                 return LeadColumn(statusId: statusId, title: title);
//               }),
//             );
//           } else if (state is LeadError) {
//             return Center(child: Text(state.message));
//           }
//           return const SizedBox();
//         },
//       ),
//     );
//   }
//   void _scrollToActiveTab() {
//   final keyContext = _tabKeys[_currentTabIndex].currentContext;
//   if (keyContext != null) {
//     final box = keyContext.findRenderObject() as RenderBox;
//     final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
//     final tabWidth = box.size.width;

//     // Проверяем, что вкладка не полностью видима
//     if (position.dx < 0 || (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
//       // Рассчитываем новое смещение для прокрутки
//       double targetOffset = _scrollController.offset + position.dx - (MediaQuery.of(context).size.width / 2) + (tabWidth / 2);

//       // Прокручиваем только в том случае, если новая позиция отличается от текущей
//       if (targetOffset != _scrollController.offset) {
//         _scrollController.animateTo(
//           targetOffset,
//           duration: Duration(milliseconds: 1),
//           curve: Curves.easeInOut,
//         );
//       }
//     }
//   }
// }
// }
