import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
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
  bool _canReadLeadStatus = false;
  bool _canCreateLeadStatus = false;
  bool _canDeleteLeadStatus = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatuses());
    print("Инициализация: отправлен запрос на получение статусов лидов");
     _checkPermissions();
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
    } else {
      leadBloc.add(FetchLeads(currentStatusId, query: query));
    }
  }

  void _onSearch(String query) {
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchLeads(query, currentStatusId);
  }

 // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('leadStatus.read');
    final canCreate = await _apiService.hasPermission('leadStatus.create');
    final canDelete = await _apiService.hasPermission('leadStatus.delete');
    setState(() {
      _canReadLeadStatus = canRead;
      _canCreateLeadStatus = canCreate;
      _canDeleteLeadStatus = canDelete;
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
        title: 'Лиды',
        onClickProfileAvatar: () {
          setState(() {
            final leadBloc = BlocProvider.of<LeadBloc>(context);
            leadBloc.add(FetchLeadStatuses());
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
            final leadBloc = BlocProvider.of<LeadBloc>(context);
            leadBloc.add(FetchLeadStatuses());
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

  Widget searchWidget(List<Lead> leads) {
    if (_isSearching && leads.isEmpty) {
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
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final statusId = _tabTitles[_currentTabIndex]['id'];
          final title = _tabTitles[_currentTabIndex]['title'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LeadCard(
              lead: leads[index],
              title: title,
              statusId: statusId,
              onStatusUpdated: () {
                context.read<LeadBloc>().add(FetchLeads(statusId));
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
        // Показываем кнопку добавления только если есть разрешение
        if (_canCreateLeadStatus)
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
      if (_canDeleteLeadStatus) {
        _showDeleteDialog(index);
      }
    },
    child: Container(
      decoration: TaskStyles.tabButtonDecoration(isActive),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              _tabTitles[index]['title'],
              style: TaskStyles.tabTextStyle.copyWith(
                color:
                    isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showDeleteDialog(int index) async {
    final leadStatusId = _tabTitles[index]['id'];
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteLeadStatusDialog(leadStatusId: leadStatusId);
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

        context.read<LeadBloc>().add(FetchLeads(_currentTabIndex));
      });
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadLoaded) {
          setState(() {
            _tabTitles = state.leadStatuses
            .where((status) => _canReadLeadStatus) // Только те статусы, которые можно читать
                .map((status) => {'id': status.id, 'title': status.title})
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
              int initialIndex = state.leadStatuses
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
        } else if (state is LeadError) {
          // Показываем сообщение об ошибке через SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(
                 '${state.message}',
                 style: TextStyle(
                   fontFamily: 'Gilroy',
                   fontSize: 16, // Размер шрифта совпадает с CustomTextField
                   fontWeight: FontWeight.w500, // Жирность текста
                   color: Colors.white, // Цвет текста для читаемости
                 ),
               ),
               behavior: SnackBarBehavior.floating,
               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12), // Радиус, как у текстового поля
               ),
               backgroundColor: Colors.red, // Цвет фона, как у текстового поля
               elevation: 3,
               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Паддинг для комфортного восприятия
             ),
          );
        }
      },
      child: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          print('state: ${state.runtimeType}');
          if (state is LeadDataLoaded) {
            final List<Lead> leads = state.leads;
            print(leads);
            return searchWidget(leads);
          }
          if (state is LeadLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is LeadLoaded) {
            if (_tabTitles.isEmpty) {
              return const Center(child: Text('Нет статусов для отображения'));
            }
            return TabBarView(
              controller: _tabController,
              // key: UniqueKey(),
              children: List.generate(_tabTitles.length, (index) {
                final statusId = _tabTitles[index]['id'];
                final title = _tabTitles[index]['title'];
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

// void _scrollToActiveTab() {
//   final key = _tabKeys[_currentTabIndex];
//   if (key.currentContext != null) {
//     Scrollable.ensureVisible(key.currentContext!,
//         duration: const Duration(milliseconds: 800));
//   }
// }

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/internetCheck/internetCheck_cubit.dart';
// import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
// import 'package:crm_task_manager/models/lead_model.dart';
// import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
// import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
// import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
// import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
// import 'package:crm_task_manager/screens/profile/profile_screen.dart';
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
//   bool _isSearching = false;
//   final TextEditingController _searchController = TextEditingController();
//   bool _canReadLeadStatus = false;
//   bool _canCreateLeadStatus = false;
//   bool _canDeleteLeadStatus = false;
//   final ApiService _apiService = ApiService();

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     final leadBloc = BlocProvider.of<LeadBloc>(context);
//     leadBloc.add(FetchLeadStatuses());
//     print("Инициализация: отправлен запрос на получение статусов лидов");
//     _checkPermissions();
//   }

//   Future<void> _checkInitialConnection() async {
//     final connectivityResult = await Connectivity().checkConnectivity();
//     if (connectivityResult == ConnectivityResult.none) {
//       context.read<ConnectivityCubit>().emit(ConnectivityStatus.disconnected);
//     } else {
//       context.read<ConnectivityCubit>().emit(ConnectivityStatus.connected);
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _searchLeads(String query, int currentStatusId) async {
//     final leadBloc = BlocProvider.of<LeadBloc>(context);

//     if (query.isEmpty) {
//       leadBloc.add(FetchLeads(currentStatusId));
//     } else {
//       leadBloc.add(FetchLeads(currentStatusId, query: query));
//     }
//   }

//   void _onSearch(String query) {
//     final currentStatusId = _tabTitles[_currentTabIndex]['id'];
//     _searchLeads(query, currentStatusId);
//   }

//   // Метод для проверки разрешений
//   Future<void> _checkPermissions() async {
//     final canRead = await _apiService.hasPermission('leadStatus.read');
//     final canCreate = await _apiService.hasPermission('leadStatus.create');
//     final canDelete = await _apiService.hasPermission('leadStatus.delete');
//     setState(() {
//       _canReadLeadStatus = canRead;
//       _canCreateLeadStatus = canCreate;
//       _canDeleteLeadStatus = canDelete;
//     });
//   }

//   FocusNode focusNode = FocusNode();
//   TextEditingController textEditingController = TextEditingController();
//   ValueChanged<String>? onChangedSearchInput;

//   bool isClickAvatarIcon = false;
//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<ConnectivityCubit, ConnectivityStatus>(
//       listener: (context, state) {
//         final snackBar = SnackBar(
//           content: Row(
//             children: [
//               Icon(
//                 state == ConnectivityStatus.disconnected
//                     ? Icons.error
//                     : Icons.check_circle,
//                 color: Colors.white, // Белая иконка для контраста на фоне
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   state == ConnectivityStatus.disconnected
//                       ? 'Нет подключения к интернету!'
//                       : 'Подключение восстановлено.',
//                   style: TextStyle(
//                     fontFamily: 'Gilroy',
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors
//                         .white, // Белый текст для читаемости на темном фоне
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           backgroundColor: state == ConnectivityStatus.disconnected
//               ? Color(0xffE74C3C) // Красный фон при отсутствии подключения
//               : Color(0xff27AE60), // Зеленый фон при подключении
//           behavior: SnackBarBehavior.floating,
//           margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 3,
//         );

//         ScaffoldMessenger.of(context).showSnackBar(snackBar);
//       },
//       child: Scaffold(
//           backgroundColor: Colors.white,
//           appBar: AppBar(
//             forceMaterialTransparency: true,
//             title: CustomAppBar(
//               title: 'Лиды',
//               onClickProfileAvatar: () {
//                 setState(() {
//                   final leadBloc = BlocProvider.of<LeadBloc>(context);
//                   leadBloc.add(FetchLeadStatuses());
//                   isClickAvatarIcon = !isClickAvatarIcon;
//                 });
//               },
//               onChangedSearchInput: (String value) {
//                 if (value.isNotEmpty) {
//                   setState(() {
//                     _isSearching = true;
//                   });
//                 }

//                 _onSearch(value);
//               },
//               textEditingController: textEditingController,
//               focusNode: focusNode,
//               clearButtonClick: (value) {
//                 if (value == false) {
//                   final leadBloc = BlocProvider.of<LeadBloc>(context);
//                   leadBloc.add(FetchLeadStatuses());
//                   setState(() {
//                     _isSearching = false;
//                   });
//                 }
//               },
//             ),
//           ),
//           body: BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
//             builder: (context, connectivityStatus) {
//               if (connectivityStatus == ConnectivityStatus.disconnected) {
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Image.asset(
//                       //   'assets/no_internet.png',
//                       //   height: 100,
//                       //   color: Colors.red,
//                       // ),
//                       const SizedBox(height: 20),
//                       const Text(
//                         'Нет подключения к интернету',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontFamily: 'Gilroy',
//                           fontWeight: FontWeight.w500,
//                           color: Color(0xff99A4BA),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                         ),
//                         onPressed: () async {
//                           final leadBloc = BlocProvider.of<LeadBloc>(context);
//                           leadBloc.add(FetchLeadStatuses());
//                           final connectivityResult =
//                               await Connectivity().checkConnectivity();
//                           if (connectivityResult != ConnectivityResult.none) {
//                             context
//                                 .read<ConnectivityCubit>()
//                                 .emit(ConnectivityStatus.connected);
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                     'Подключение отсутствует. Повторите попытку.'),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                           }
//                         },
//                         child: const Text('Обновить'),
//                       ),
//                     ],
//                   ),
//                 );
//               }

//               // Если подключение активно, показываем основной интерфейс
//               return isClickAvatarIcon
//                   ? ProfileScreen()
//                   : Column(
//                       children: [
//                         const SizedBox(height: 15),
//                         if (!_isSearching) _buildCustomTabBar(),
//                         Expanded(child: _buildTabBarView()),
//                       ],
//                     );
//             },
//           )),
//     );
//   }

//   Widget searchWidget(List<Lead> leads) {
//     if (_isSearching && leads.isEmpty) {
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
//         itemCount: leads.length,
//         itemBuilder: (context, index) {
//           final statusId = _tabTitles[_currentTabIndex]['id'];
//           final title = _tabTitles[_currentTabIndex]['title'];
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: LeadCard(
//               lead: leads[index],
//               title: title,
//               statusId: statusId,
//               onStatusUpdated: () {
//                 context.read<LeadBloc>().add(FetchLeads(statusId));
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
//           // Показываем кнопку добавления только если есть разрешение
//           if (_canCreateLeadStatus)
//             IconButton(
//               icon: Image.asset('assets/icons/tabBar/add_black.png',
//                   width: 24, height: 24),
//               onPressed: _addNewTab,
//             ),
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
//         // Показываем диалог удаления только если есть разрешение
//         if (_canDeleteLeadStatus) {
//           _showDeleteDialog(index);
//         }
//       },
//       child: Container(
//         decoration: TaskStyles.tabButtonDecoration(isActive),
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Center(
//               child: Text(
//                 _tabTitles[index]['title'],
//                 style: TaskStyles.tabTextStyle.copyWith(
//                   color: isActive
//                       ? TaskStyles.activeColor
//                       : TaskStyles.inactiveColor,
//                 ),
//               ),
//             ),
//           ],
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

//         _isSearching = false;
//         _searchController.clear();

//         context.read<LeadBloc>().add(FetchLeads(_currentTabIndex));
//       });
//     }
//   }

//   Widget _buildTabBarView() {
//     return BlocListener<LeadBloc, LeadState>(
//       listener: (context, state) {
//         if (state is LeadLoaded) {
//           setState(() {
//             _tabTitles = state.leadStatuses
//                 .where((status) =>
//                     _canReadLeadStatus && status.lead_status_id == null)
//                 .map((status) => {'id': status.id, 'title': status.title})
//                 .toList();

//             _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

//             if (_tabTitles.isNotEmpty) {
//               _tabController =
//                   TabController(length: _tabTitles.length, vsync: this);
//               _tabController.addListener(() {
//                 setState(() {
//                   _currentTabIndex = _tabController.index;
//                 });
//                 final currentStatusId = _tabTitles[_currentTabIndex]['id'];
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

//               if (_scrollController.hasClients) {
//                 _scrollToActiveTab();
//               }
//             }
//           });
//         } else if (state is LeadError) {
//           // Показываем сообщение об ошибке через SnackBar
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Ошибка при загрузке данных: ${state.message}',
//                 style: TextStyle(
//                   fontFamily: 'Gilroy',
//                   fontSize: 14, // Используем тот же размер шрифта
//                   fontWeight: FontWeight.w500, // То же значение жирности
//                   color: Colors.white, // Белый текст для читаемости
//                 ),
//               ),
//               behavior: SnackBarBehavior.floating,
//               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 3,
//             ),
//           );
//         }
//       },
//       child: BlocBuilder<LeadBloc, LeadState>(
//         builder: (context, state) {
//           if (state is LeadDataLoaded) {
//             final List<Lead> leads = state.leads;
//             return searchWidget(leads);
//           }
//           if (state is LeadLoading) {
//             return const Center(
//                 child: CircularProgressIndicator(color: Color(0xff1E2E52)));
//           } else if (state is LeadLoaded) {
//             // Если нет статусов, показываем сообщение
//             if (_tabTitles.isEmpty) {
//               return Center(
//                 child: Text(
//                   'Нет статусов для отображения',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontFamily: 'Gilroy',
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xff99A4BA),
//                   ),
//                 ),
//               );
//             }

//             return TabBarView(
//               controller: _tabController,
//               children: List.generate(_tabTitles.length, (index) {
//                 final statusId = _tabTitles[index]['id'];
//                 final title = _tabTitles[index]['title'];
//                 return LeadColumn(statusId: statusId, title: title);
//               }),
//             );
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
//           _scrollController.animateTo(
//             targetOffset,
//             duration: Duration(milliseconds: 10),
//             curve: Curves.easeInOut,
//           );
//         }
//       }
//     }
//   }
// }


//   // void _scrollToActiveTab() {
//   //   final key = _tabKeys[_currentTabIndex];
//   //   if (key.currentContext != null) {
//   //     Scrollable.ensureVisible(key.currentContext!,
//   //         duration: const Duration(milliseconds: 800));
//   //   }
//   // }