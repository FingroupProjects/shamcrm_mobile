import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/page_2/goods/goods_screen.dart';
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/empty_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:crm_task_manager/page_2/category/category_screen.dart';
import 'package:crm_task_manager/screens/page_test.dart';
import 'package:crm_task_manager/screens/placeholder_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = -1;  
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
    if (await _apiService.hasPermission('section.dashboard')) {
      widgets.add(DashboardScreen());
      titleKeys.add('appbar_dashboard');
      navBarTitleKeys.add('appbar_dashboard');
      activeIcons.add('assets/icons/MyNavBar/dashboard_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/dashboard_OFF.png');
      hasAvailableScreens = true;
    }

    // Задачи
    if (await _apiService.hasPermission('task.read')) {
    widgets.add(TaskScreen());
    titleKeys.add('appbar_tasks');
    navBarTitleKeys.add('appbar_tasks');
    activeIcons.add('assets/icons/MyNavBar/tasks_ON.png');
    inactiveIcons.add('assets/icons/MyNavBar/tasks_OFF.png');
    hasAvailableScreens = true;
    }
    // Лиды
    if (await _apiService.hasPermission('lead.read')) {
      widgets.add(LeadScreen());
      titleKeys.add('appbar_leads');
      navBarTitleKeys.add('appbar_leads');
      activeIcons.add('assets/icons/MyNavBar/clients_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/clients_OFF.png');
      hasAvailableScreens = true;
    }

    // Сделки
    if (await _apiService.hasPermission('deal.read')) {
      widgets.add(DealScreen());
      titleKeys.add('appbar_deals');
      navBarTitleKeys.add('appbar_deals');
      activeIcons.add('assets/icons/MyNavBar/deal_ON.png');
      inactiveIcons.add('assets/icons/MyNavBar/deal_OFF.png');
      hasAvailableScreens = true;
    }
    
    // Чаты
    widgets.add(ChatsScreen());
    titleKeys.add('appbar_chats');
    navBarTitleKeys.add('appbar_chats');
    activeIcons.add('assets/icons/MyNavBar/chats_ON.png');
    inactiveIcons.add('assets/icons/MyNavBar/chats_OFF.png');
    hasAvailableScreens = true;

    // PAGE 1
    widgets.add(PlaceHolderTest(message: 'Страница 1',));
    titleKeys.add('Дашборд');
    navBarTitleKeys.add('Дашборд');
    activeIcons.add('assets/icons/MyNavBar/clients_ON.png');
    inactiveIcons.add('assets/icons/MyNavBar/clients_OFF.png');
    hasAvailableScreens = true;
    // Категории 
    widgets.add(CategoryScreen());
    titleKeys.add('Категории');
    navBarTitleKeys.add('Категории');
    activeIcons.add('assets/icons/MyNavBar/category_ON.png');
    inactiveIcons.add('assets/icons/MyNavBar/category_OFF.png');
    hasAvailableScreens = true;
    
    // Товары
    widgets.add(GoodsScreen());
    titleKeys.add('Товары');
    navBarTitleKeys.add('Товары');
    activeIcons.add('assets/icons/MyNavBar/goods_ON.png');

    inactiveIcons.add('assets/icons/MyNavBar/goods_OFF.png');
    hasAvailableScreens = true;
    // PAGE 4
    widgets.add(OrderScreen());
    titleKeys.add('Заказы');
    navBarTitleKeys.add('Заказы');
    activeIcons.add('assets/icons/MyNavBar/orderon.png');
    inactiveIcons.add('assets/icons/MyNavBar/order_OFF.png');
    hasAvailableScreens = true;

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
      if (mounted) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        setState(() {
          if (args != null && args['screenIndex'] != null) {
            _selectedIndex = args['screenIndex'];
          } else if (_widgetOptions.isNotEmpty) {
            _selectedIndex = -1;
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
        _selectedIndex = -1; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == -1 
          ? EmptyScreen() 
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
                  .toList(),
              activeIcons: _activeIcons,
              inactiveIcons: _inactiveIcons,
            )
          : null,
    );
  }
}
