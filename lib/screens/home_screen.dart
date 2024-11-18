import 'package:crm_task_manager/api/service/api_service.dart';
<<<<<<< HEAD
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
=======
>>>>>>> main
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:crm_task_manager/screens/placeholder_screen.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

<<<<<<< HEAD
  // Добавьте экран профиля в список виджетов
  final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    ClientsScreen(),
    LeadScreen(),
    BlocProvider(
      create: (context) => ChatsBloc(ApiService()),
      child: ChatsScreen(),
    ),
    DealScreen(),
    ProfileScreen(), // Добавьте экран профиля
  ];
=======
  List<Widget> _widgetOptions = [];
  List<String> _titles = [];
  List<String> _navBarTitles = [];
  List<String> _activeIcons = [];
  List<String> _inactiveIcons = [];
>>>>>>> main

  @override
  void initState() {
    super.initState();
    initializeScreensWithPermissions();
  }

  Future<void> initializeScreensWithPermissions() async {
    List<Widget> widgets = [];
    List<String> titles = [];
    List<String> navBarTitles = [];
    List<String> activeIcons = [];
    List<String> inactiveIcons = [];

    bool hasAvailableScreens = false;

    if (await _apiService.hasPermission('dashboard.read')) {
      widgets.add(DashboardScreen());
      titles.add('Дашборд');
      navBarTitles.add('Дашборд');
      activeIcons.add('assets/icons/MyNavBar/dashboard_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/dashboard_OFF.png');
      hasAvailableScreens = true;
    } else {
      widgets.add(PlaceholderScreen(message: 'Экран Дашборд недоступен вам.'));
      titles.add('Дашборд');
      navBarTitles.add('Дашборд');
      activeIcons.add('assets/icons/MyNavBar/dashboard_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/dashboard_OFF.png');
    }

    // if ( await _apiService.hasPermission('task.read')) {
    if (!hasAvailableScreens || await _apiService.hasPermission('task.read')) {
      widgets.add(TaskScreen());
      titles.add('Задачи');
      navBarTitles.add('Задачи');
      activeIcons.add('assets/icons/MyNavBar/tasks_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/tasks_OFF.png');
      hasAvailableScreens = true;
    }

    if (await _apiService.hasPermission('lead.read')) {
      widgets.add(LeadScreen());
      titles.add('Лиды');
      navBarTitles.add('Лиды');
      activeIcons.add('assets/icons/MyNavBar/clients_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/clients_OFF.png');
      hasAvailableScreens = true;
    }
    if (await _apiService.hasPermission('chat.read')) {
      widgets.add(ChatsScreen());
      titles.add('Чаты');
      navBarTitles.add('Чаты');
      activeIcons.add('assets/icons/MyNavBar/chats_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/chats_OFF.png');
      hasAvailableScreens = true;
    }
    if (await _apiService.hasPermission('deal.read')) {
      widgets.add(DealScreen());
      titles.add('Сделки');
      navBarTitles.add('Сделки');
      activeIcons.add('assets/icons/MyNavBar/deal_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/deal_OFF.png');
      hasAvailableScreens = true;
    }

    setState(() {
      _widgetOptions = widgets;
      _titles = titles;
      _navBarTitles = navBarTitles;
      _activeIcons = activeIcons;
      _inactiveIcons = inactiveIcons;

      if (_widgetOptions.isNotEmpty) {
        _selectedIndex = 0;
      }
    });

    // If no screens are available, show a placeholder
    if (!hasAvailableScreens) {
      setState(() {
        _widgetOptions = [PlaceholderScreen(message: 'Нет доступных экранов.')];
        _titles = ['Нет доступных экранов'];
        _navBarTitles = [];
        _activeIcons = [];
        _inactiveIcons = [];
        _selectedIndex = 0; // Show placeholder screen
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   forceMaterialTransparency: true,
<<<<<<< HEAD
      //   title: CustomAppBar(title: 'title', onClickProfileAvatar: () {
      //
      //   },),
      //   backgroundColor: Colors.white,
      // ),
      body: _widgetOptions[
          _selectedIndex], // Теперь отображаем профиль вместе с другими экранами
=======
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.start,
      //     children: [
      //       if (_selectedIndex == -1) // Профиль
      //         IconButton(
      //           icon: Image.asset('assets/icons/arrow-left.png',
      //               width: 24, height: 24),
      //           onPressed: () {
      //             setState(() {
      //               _selectedIndex = 0;
      //             });
      //           },
      //         ),
      //       Container(
      //         width: 40,
      //         height: 40,
      //         child: IconButton(
      //           padding: EdgeInsets.zero,
      //           icon: Image.asset('assets/images/avatar.png'),
      //           onPressed: () {
      //             setState(() {
      //               _selectedIndex = -1; // Переход на экран профиля
      //             });
      //           },
      //         ),
      //       ),
      //       SizedBox(width: 8),
      //       _isSearching
      //           ? Expanded(
      //               child: TextField(
      //                 controller: _searchController,
      //                 autofocus: true,
      //                 decoration: InputDecoration(
      //                   hintText: 'Поиск...',
      //                   border: InputBorder.none,
      //                 ),
      //                 style: TextStyle(
      //                   fontSize: 20,
      //                   fontFamily: 'Gilroy',
      //                   fontWeight: FontWeight.w600,
      //                 ),
      //                 onSubmitted: (query) {
      //                   setState(() {
      //                     _isSearching = false;
      //                   });
      //                 },
      //               ),
      //             )
      //           : Text(
      //               _titles.isNotEmpty &&
      //                       _selectedIndex >= 0 &&
      //                       _selectedIndex < _titles.length
      //                   ? _titles[_selectedIndex]
      //                   : 'Профиль',
      //               style: TextStyle(
      //                   fontSize: 20,
      //                   fontFamily: 'Gilroy',
      //                   fontWeight: FontWeight.w600),
      //             ),
      //       Spacer(),
      //       Row(
      //         children: [
      //           IconButton(
      //             icon: Image.asset(
      //               'assets/icons/AppBar/notification.png',
      //               width: 24,
      //               height: 24,
      //             ),
      //             onPressed: () {},
      //           ),
      //           if (_selectedIndex != 0)
      //             IconButton(
      //               icon: Image.asset(
      //                 'assets/icons/AppBar/search.png',
      //                 width: 24,
      //                 height: 24,
      //               ),
      //               onPressed: () {
      //                 setState(() {
      //                   _isSearching = !_isSearching;
      //                   if (!_isSearching) {
      //                     _searchController.clear();
      //                   }
      //                 });
      //               },
      //             ),
      //         ],
      //       ),
      //     ],
      //   ),
      //   backgroundColor: Colors.white,
      // ),
      body: _selectedIndex == -1 // Экран профиля
          ? ProfileScreen()
          : (_widgetOptions.isNotEmpty &&
                  _selectedIndex >= 0 &&
                  _selectedIndex < _widgetOptions.length
              ? _widgetOptions[_selectedIndex]
              : Center(child: Text('Нет доступных экранов'))),
>>>>>>> main
      backgroundColor: Colors.white,
      bottomNavigationBar: _widgetOptions.isNotEmpty
          ? MyNavBar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  _isSearching = false;
                });
              },
              navBarTitles: _navBarTitles,
              activeIcons: _activeIcons,
              inactiveIcons: _inactiveIcons,
            )
          : null,
    );
  }
}