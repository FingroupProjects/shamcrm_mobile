import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/deal/deal_status_delete.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_card.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_column.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_add.dart';

import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class DealScreen extends StatefulWidget {
  final int? initialStatusId;

  DealScreen({this.initialStatusId});

  @override
  _DealScreenState createState() => _DealScreenState();
}

class _DealScreenState extends State<DealScreen> with TickerProviderStateMixin {
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
    BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
    print("Инициализация: отправлен запрос на получение статусов сделки");
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final dealBloc = BlocProvider.of<DealBloc>(context);
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];

    if (query.isEmpty) {
      // dealBloc.add(FetchDeals(currentStatusId));
      print("Поиск: пустой запрос, выводим сделки по статусу id = $currentStatusId");
    } else {
      // dealBloc.add(FetchDeals(currentStatusId, query: query));
      print("Поиск: текущий статус сделки id = $currentStatusId, поисковый запрос = '$query'");
    }
  }

  bool isClickAvatarIcon = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: CustomAppBar(
          title: 'Поиск Сделки',
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          onChangedSearchInput: (value) {
            setState(() => _isSearching = value.isNotEmpty);
            _onSearch(value);
          },
          textEditingController: _searchController,
          focusNode: FocusNode(),
          clearButtonClick: (value) {
            if (!value) {
              BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
              setState(() => _isSearching = false);
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

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: [
          ...List.generate(_tabTitles.length, (index) {
            _tabKeys.add(GlobalKey());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildTabButton(index),
            );
          }),
          IconButton(
            icon: Image.asset('assets/icons/tabBar/add_black.png', width: 24, height: 24),
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
        print("Переключение на таб с индексом: $index, статус сделки id = ${_tabTitles[index]['id']}");
        _tabController.animateTo(index);
      },
      onLongPress: () => _showDeleteDialog(index),
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Center(
          child: Text(
            _tabTitles[index]['title'],
            style: TaskStyles.tabTextStyle.copyWith(
              color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(int index) async {
    final dealStatusId = _tabTitles[index]['id'];
    print("Удаление: попытка удалить статус лида с id = $dealStatusId");

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => DeleteDealStatusDialog(dealStatusId: dealStatusId),
    );

    if (result != null && result) {
      setState(() {
        print("Удаление: статус лида с id = $dealStatusId успешно удален");
        _tabTitles.removeAt(index);
        _tabKeys.removeAt(index);
        _tabController = TabController(length: _tabTitles.length, vsync: this);
        _currentTabIndex = 0;
      });
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<DealBloc, DealState>(
      listener: (context, state) {
        if (state is DealLoaded) {
          setState(() {
            _tabTitles = state.dealStatuses.map((status) => {'id': status.id, 'title': status.title}).toList();
            _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

            if (_tabTitles.isNotEmpty) {
              _tabController = TabController(length: _tabTitles.length, vsync: this);
              _tabController.addListener(() {
                setState(() => _currentTabIndex = _tabController.index);

                if (_scrollController.hasClients) {
                  _scrollToActiveTab();
                }
              });

              int initialIndex = state.dealStatuses.indexWhere((status) => status.id == widget.initialStatusId);
              if (initialIndex != -1) {
                _tabController.index = initialIndex;
                _currentTabIndex = initialIndex;
              }
            }
          });
        }
      },
      child: BlocBuilder<DealBloc, DealState>(
        builder: (context, state) {
          if (state is DealDataLoaded) {
            return _buildLeadList(state.deals);
          }
          if (state is DealLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is DealLoaded) {
            if (_tabTitles.isEmpty) {
              return const Center(child: Text('Нет статусов для отображения'));
            }
            return TabBarView(
              controller: _tabController,
              key: UniqueKey(),
              children: _tabTitles.map((tab) => DealColumn(statusId: tab['id'], title: tab['title'])).toList(),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLeadList(List<Deal> deals) {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: deals.length,
        itemBuilder: (context, index) {
          final statusId = _tabTitles[index]['id'];
          final title = _tabTitles[index]['title'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DealCard(
              deal: deals[index],
              title: title,
              statusId: statusId,
              onStatusUpdated: () => context.read<DealBloc>().add(FetchDeals(statusId)),
            ),
          );
        },
      ),
    );
  }

  void _scrollToActiveTab() {
    final key = _tabKeys[_currentTabIndex];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!, duration: const Duration(milliseconds: 300));
    }
  }
}



// import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
// import 'package:crm_task_manager/bloc/deal/deal_event.dart';
// import 'package:crm_task_manager/bloc/deal/deal_state.dart';
// import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
// import 'package:crm_task_manager/screens/deal/deal_status_delete.dart';
// import 'package:crm_task_manager/screens/deal/tabBar/deal_column.dart';
// import 'package:crm_task_manager/screens/deal/tabBar/deal_status_add.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

// class DealScreen extends StatefulWidget {
//   final int? initialStatusId;

//   DealScreen({this.initialStatusId});

//   @override
//   _DealScreenState createState() => _DealScreenState();
// }

// class _DealScreenState extends State<DealScreen> with TickerProviderStateMixin {
//   late TabController _tabController;
//   late ScrollController _scrollController;
//   List<Map<String, dynamic>> _tabTitles = [];
//   int _currentTabIndex = 0;
//   List<GlobalKey> _tabKeys = [];
//   bool _isSearching = false;
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _onSearch(String query) {
//     final dealBloc = BlocProvider.of<DealBloc>(context);
//     final currentStatusId = _tabTitles[_currentTabIndex]['id'];

//     if (query.isEmpty) {
//       dealBloc.add(FetchDeals(currentStatusId)); // Fetch without search filter
//     } else {
//       dealBloc.add(FetchDeals(currentStatusId, query: query)); // Fetch with search filter
//     }
//   }

//   bool isClickAvatarIcon = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: CustomAppBar(
//           title: 'Поиск Сделки',
//           onClickProfileAvatar: () {
//             setState(() {
//               isClickAvatarIcon = !isClickAvatarIcon;
//             });
//           },
//           onChangedSearchInput: (value) {
//             setState(() => _isSearching = value.isNotEmpty);
//             _onSearch(value);
//           },
//           textEditingController: _searchController,
//           focusNode: FocusNode(),
//           clearButtonClick: (value) {
//             if (!value) {
//               BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
//               setState(() => _isSearching = false);
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
//     final dealStatusId = _tabTitles[index]['id'];

//     final result = await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return DeleteDealStatusDialog(dealStatusId: dealStatusId);
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
//     return BlocListener<DealBloc, DealState>(
//       listener: (context, state) {
//         if (state is DealLoaded) {
//           setState(() {
//             _tabTitles = state.dealStatuses
//                 .map((status) => {'id': status.id, 'title': status.title})
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

//               int initialIndex = state.dealStatuses
//                   .indexWhere((status) => status.id == widget.initialStatusId);
//               if (initialIndex != -1) {
//                 _tabController.index = initialIndex;
//                 _currentTabIndex = initialIndex;
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
//       child: BlocBuilder<DealBloc, DealState>(
//         builder: (context, state) {
//           if (state is DealLoading) {
//             return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
//           } else if (state is DealLoaded) {
//             if (_tabTitles.isEmpty) {
//               return const Center(child: Text('Нет статусов для отображения'));
//             }
//             return TabBarView(
//               controller: _tabController,
//               children: List.generate(_tabTitles.length, (index) {
//                 final statusId = _tabTitles[index]['id'];
//                 final title = _tabTitles[index]['title'];
//                 return DealColumn(statusId: statusId, title: title);
//               }),
//             );
//           } else if (state is DealError) {
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
//       final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
//       final tabWidth = box.size.width;

//       if (position.dx < 0 || (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
//         double targetOffset = _scrollController.offset + position.dx - (MediaQuery.of(context).size.width / 2) + (tabWidth / 2);

//         if (targetOffset != _scrollController.offset) {
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
