import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:crm_task_manager/screens/placeholder_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Widget> _widgetOptions = [];
  List<String> _titleKeys = [];
  List<String> _navBarTitleKeys = [];
  List<String> _activeIcons = [];
  List<String> _inactiveIcons = [];

  @override
  void initState() {
    super.initState();

    initializeScreensWithPermissions();
  }

  Future<void> initializeScreensWithPermissions() async {
  List<Widget> widgets = [];
  List<String> titleKeys = [];
  List<String> navBarTitleKeys = [];
  List<String> activeIcons = [];
  List<String> inactiveIcons = [];

  bool hasAvailableScreens = false;

  // Дашборд
  widgets.add(DashboardScreen());
  titleKeys.add('appbar_dashboard');
  navBarTitleKeys.add('appbar_dashboard');
  activeIcons.add('assets/icons/MyNavBar/dashboard_ON.png');
  inactiveIcons.add('assets/icons/MyNavBar/dashboard_OFF.png');
  hasAvailableScreens = true;

  // Задачи
  widgets.add(TaskScreen());
  titleKeys.add('appbar_tasks');
  navBarTitleKeys.add('appbar_tasks');
  activeIcons.add('assets/icons/MyNavBar/tasks_ON.png');
  inactiveIcons.add('assets/icons/MyNavBar/tasks_OFF.png');
  hasAvailableScreens = true;

  // Лиды
  if (await _apiService.hasPermission('lead.read')) {
    widgets.add(LeadScreen());
    titleKeys.add('appbar_leads');
    navBarTitleKeys.add('appbar_leads');
    activeIcons.add('assets/icons/MyNavBar/clients_ON.png');
    inactiveIcons.add('assets/icons/MyNavBar/clients_OFF.png');
    hasAvailableScreens = true;
  }

  // Чаты
  widgets.add(ChatsScreen());
  titleKeys.add('appbar_chats');
  navBarTitleKeys.add('appbar_chats');
  activeIcons.add('assets/icons/MyNavBar/chats_ON.png');
  inactiveIcons.add('assets/icons/MyNavBar/chats_OFF.png');
  hasAvailableScreens = true;

  // Сделки
  if (await _apiService.hasPermission('deal.read')) {
    widgets.add(DealScreen());
    titleKeys.add('appbar_deals');
    navBarTitleKeys.add('appbar_deals');
    activeIcons.add('assets/icons/MyNavBar/deal_ON.png');
    inactiveIcons.add('assets/icons/MyNavBar/deal_OFF.png');
    hasAvailableScreens = true;
  }

    // Проверяем, смонтирован ли виджет перед вызовом setState
  if (mounted) {
    setState(() {
      _widgetOptions = widgets;
      _titleKeys = titleKeys;
      _navBarTitleKeys = navBarTitleKeys;
      _activeIcons = activeIcons;
      _inactiveIcons = inactiveIcons;
    });
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Проверяем, смонтирован ли виджет перед вызовом setState
    if (mounted) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      setState(() {
        if (args != null && args['screenIndex'] != null) {
          _selectedIndex = args['screenIndex'];
        } else if (_widgetOptions.isNotEmpty) {
          _selectedIndex = 0;
        }
      });
    }
  });

  if (!hasAvailableScreens && mounted) {
    setState(() {
      _widgetOptions = [PlaceholderScreen(message: 'Нет доступных экранов.')];
      _titleKeys = ['no_available_screens'];
      _navBarTitleKeys = [];
      _activeIcons = [];
      _inactiveIcons = [];
      _selectedIndex = 0;
    });
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: _selectedIndex == -1 // Экран профиля
        ? ProfileScreen()
        : (_widgetOptions.isNotEmpty &&
                _selectedIndex >= 0 &&
                _selectedIndex < _widgetOptions.length
            ? _widgetOptions[_selectedIndex]
            : Center(
                child: Text(AppLocalizations.of(context)!.translate('no_available_screens')),
              )),
    backgroundColor: Colors.white,
    bottomNavigationBar: _widgetOptions.isNotEmpty
        ? MyNavBar(
            currentIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _isSearching = false;
              });
            },
            navBarTitles: _navBarTitleKeys
                .map((key) => AppLocalizations.of(context)!.translate(key))
                .toList(), // Локализация заголовков NavBar
            activeIcons: _activeIcons,
            inactiveIcons: _inactiveIcons,
          )
        : null,
  );
}
}