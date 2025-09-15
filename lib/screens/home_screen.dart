import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/page_2/goods/goods_screen.dart';
import 'package:crm_task_manager/page_2/online_shop.dart';
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/warehouse_screen.dart';
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/empty_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:crm_task_manager/page_2/category/category_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:flutter/material.dart';
import '../page_2/money/money_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndexGroup1 = -1;  
  int _selectedIndexGroup2 = -1;  
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isPushHandled = false;  

  List<Widget> _widgetOptionsGroup1 = [];
  List<Widget> _widgetOptionsGroup2 = [];
  List<String> _titleKeysGroup1 = [];
  List<String> _titleKeysGroup2 = [];
  List<String> _navBarTitleKeysGroup1 = [];
  List<String> _navBarTitleKeysGroup2 = [];
  List<String> _activeIconsGroup1 = [];
  List<String> _activeIconsGroup2 = [];
  List<String> _inactiveIconsGroup1 = [];
  List<String> _inactiveIconsGroup2 = [];

  @override
  void initState() {
    super.initState();
    initializeScreensWithPermissions();
  }

  Future<void> initializeScreensWithPermissions() async {
    List<Widget> widgetsGroup1 = [];
    List<Widget> widgetsGroup2 = [];
    List<String> titleKeysGroup1 = [];
    List<String> titleKeysGroup2 = [];
    List<String> navBarTitleKeysGroup1 = [];
    List<String> navBarTitleKeysGroup2 = [];
    List<String> activeIconsGroup1 = [];
    List<String> activeIconsGroup2 = [];
    List<String> inactiveIconsGroup1 = [];
    List<String> inactiveIconsGroup2 = [];

    bool hasAvailableScreens = false;

    // Дашборд
    if (await _apiService.hasPermission('section.dashboard')) {
      widgetsGroup1.add(DashboardScreen());
      titleKeysGroup1.add('appbar_dashboard');
      navBarTitleKeysGroup1.add('appbar_dashboard');
      activeIconsGroup1.add('assets/icons/MyNavBar/dashboard_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/dashboard_OFF.png');
      hasAvailableScreens = true;
    }

    // Задачи
    if (await _apiService.hasPermission('task.read')) {
      widgetsGroup1.add(TaskScreen());
      titleKeysGroup1.add('appbar_tasks');
      navBarTitleKeysGroup1.add('appbar_tasks');
      activeIconsGroup1.add('assets/icons/MyNavBar/tasks_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/tasks_OFF.png');
      hasAvailableScreens = true;
    }

    // Лиды
    if (await _apiService.hasPermission('lead.read')) {
      widgetsGroup1.add(LeadScreen());
      titleKeysGroup1.add('appbar_leads');
      navBarTitleKeysGroup1.add('appbar_leads');
      activeIconsGroup1.add('assets/icons/MyNavBar/clients_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/clients_OFF.png');
      hasAvailableScreens = true;
    }

    // Сделки
    if (await _apiService.hasPermission('deal.read')) {
      widgetsGroup1.add(DealScreen());
      titleKeysGroup1.add('appbar_deals');
      navBarTitleKeysGroup1.add('appbar_deals');
      activeIconsGroup1.add('assets/icons/MyNavBar/deal_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/deal_OFF.png');
      hasAvailableScreens = true;
    }

    // Чаты
    widgetsGroup1.add(ChatsScreen());
    titleKeysGroup1.add('appbar_chats');
    navBarTitleKeysGroup1.add('appbar_chats');
    activeIconsGroup1.add('assets/icons/MyNavBar/chats_ON.png');
    inactiveIconsGroup1.add('assets/icons/MyNavBar/chats_OFF.png');
    hasAvailableScreens = true;

    // ИЗМЕНЕНО: Онлайн магазин (вместо отдельных Category, Goods, Orders)
    // Проверяем, есть ли доступ к любой части онлайн магазина
    bool hasOnlineStoreAccess = false;
    if (await _apiService.hasPermission('product.read') || 
        await _apiService.hasPermission('order.read')) {
      hasOnlineStoreAccess = true;
    }

    if (hasOnlineStoreAccess) {
      widgetsGroup2.add(OnlineStoreScreen());
      titleKeysGroup2.add('appbar_online_store');
      navBarTitleKeysGroup2.add('appbar_online_store');
      activeIconsGroup2.add('assets/icons/MyNavBar/category_ON.png'); // Используем иконку категории
      inactiveIconsGroup2.add('assets/icons/MyNavBar/category_OFF.png');
      hasAvailableScreens = true;
    }

    // НОВЫЙ: Учет склада
    // Проверяем, есть ли доступ к складским операциям
    bool hasWarehouseAccess = false;
    if (await _apiService.hasPermission('product.read') || 
        await _apiService.hasPermission('order.read')) {
      hasWarehouseAccess = true;
    }

    if (hasWarehouseAccess) {
      widgetsGroup2.add(WarehouseAccountingScreen());
      titleKeysGroup2.add('appbar_warehouse');
      navBarTitleKeysGroup2.add('appbar_warehouse');
      activeIconsGroup2.add('assets/icons/MyNavBar/goods_ON.png'); // Используем иконку товаров
      inactiveIconsGroup2.add('assets/icons/MyNavBar/goods_OFF.png');
      hasAvailableScreens = true;
    }

    // "Деньги"
    widgetsGroup2.add(MoneyScreen());
    titleKeysGroup2.add('dengi');
    navBarTitleKeysGroup2.add('dengi');
    activeIconsGroup2.add('assets/icons/MyNavBar/goods_ON.png'); // Добавьте иконку в assets
    inactiveIconsGroup2.add('assets/icons/MyNavBar/goods_OFF.png');


    // Удаляем старые отдельные экраны (они теперь доступны через OnlineStoreScreen):
    /*
    // Категории 
    if (await _apiService.hasPermission('product.read')) {
      widgetsGroup2.add(CategoryScreen());
      titleKeysGroup2.add('appbar_categories');
      navBarTitleKeysGroup2.add('appbar_categories');
      activeIconsGroup2.add('assets/icons/MyNavBar/category_ON.png');
      inactiveIconsGroup2.add('assets/icons/MyNavBar/category_OFF.png');
      hasAvailableScreens = true;
    }
    
    if (await _apiService.hasPermission('product.read')) {
      // Товары
      widgetsGroup2.add(GoodsScreen());
      titleKeysGroup2.add('appbar_goods');
      navBarTitleKeysGroup2.add('appbar_goods');
      activeIconsGroup2.add('assets/icons/MyNavBar/goods_ON.png');
      inactiveIconsGroup2.add('assets/icons/MyNavBar/goods_OFF.png');
      hasAvailableScreens = true;
    }
    
    // Заказы
    if (await _apiService.hasPermission('order.read')) {
      widgetsGroup2.add(OrderScreen());
      titleKeysGroup2.add('appbar_orders');
      navBarTitleKeysGroup2.add('appbar_orders');
      activeIconsGroup2.add('assets/icons/MyNavBar/order_off_2.png');
      inactiveIconsGroup2.add('assets/icons/MyNavBar/order_on_2.png');
      hasAvailableScreens = true;
    }
    */

    if (mounted) {
      setState(() {
        _widgetOptionsGroup1 = widgetsGroup1;
        _widgetOptionsGroup2 = widgetsGroup2;
        _titleKeysGroup1 = titleKeysGroup1;
        _titleKeysGroup2 = titleKeysGroup2;
        _navBarTitleKeysGroup1 = navBarTitleKeysGroup1;
        _navBarTitleKeysGroup2 = navBarTitleKeysGroup2;
        _activeIconsGroup1 = activeIconsGroup1;
        _activeIconsGroup2 = activeIconsGroup2;
        _inactiveIconsGroup1 = inactiveIconsGroup1;
        _inactiveIconsGroup2 = inactiveIconsGroup2;
        
        // Если текущий пользователь находится во второй группе, но она пуста,
        // переключаем на первую группу
        if (_selectedIndexGroup2 != -1 && widgetsGroup2.isEmpty) {
          _selectedIndexGroup1 = 0;
          _selectedIndexGroup2 = -1;
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && !_isPushHandled) {
      setState(() {
        if (args['group'] == 1) {
          _selectedIndexGroup1 = args['screenIndex'] ?? 0;
          _selectedIndexGroup2 = -1;
        } else if (args['group'] == 2) {
          // Проверяем, есть ли элементы во второй группе
          if (_widgetOptionsGroup2.isNotEmpty) {
            _selectedIndexGroup2 = args['screenIndex'] ?? 0;
            _selectedIndexGroup1 = -1;
          } else {
            // Если нет элементов во второй группе, переключаемся на первую
            _selectedIndexGroup1 = 0;
            _selectedIndexGroup2 = -1;
          }
        }
        _isPushHandled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndexGroup1 == -1 && _selectedIndexGroup2 == -1
          ? EmptyScreen() 
          : (_selectedIndexGroup1 != -1
              ? _widgetOptionsGroup1[_selectedIndexGroup1]
              : _widgetOptionsGroup2[_selectedIndexGroup2]),
      backgroundColor: Colors.white,
      bottomNavigationBar: MyNavBar(
        currentIndexGroup1: _selectedIndexGroup1,
        currentIndexGroup2: _selectedIndexGroup2,
        onItemSelectedGroup1: (index) {
          setState(() {
            _selectedIndexGroup1 = index;
            _selectedIndexGroup2 = -1;
            _isSearching = false;
          });
        },
        onItemSelectedGroup2: (index) {
          setState(() {
            _selectedIndexGroup2 = index;
            _selectedIndexGroup1 = -1;
            _isSearching = false;
          });
        },
        navBarTitlesGroup1: _navBarTitleKeysGroup1
            .map((key) => AppLocalizations.of(context)!.translate(key))
            .toList(),
        navBarTitlesGroup2: _navBarTitleKeysGroup2
            .map((key) => AppLocalizations.of(context)!.translate(key))
            .toList(),
        activeIconsGroup1: _activeIconsGroup1,
        activeIconsGroup2: _activeIconsGroup2,
        inactiveIconsGroup1: _inactiveIconsGroup1,
        inactiveIconsGroup2: _inactiveIconsGroup2,
      ),
    );
  }
}