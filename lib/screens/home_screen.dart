import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/widget_service.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/bloc/permission/permession_state.dart';
import 'package:crm_task_manager/page_2/online_shop.dart';
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/warehouse_screen.dart';
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/background_data_loader_service.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/empty_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndexGroup1 = 0; // ✅ ИСПРАВЛЕНИЕ: Начинаем с 0 вместо -1
  int _selectedIndexGroup2 = -1;
  final TextEditingController _searchController = TextEditingController();
  bool _isPushHandled = false;
  bool _isBackgroundLoading = false;
  bool _isInitialized = false; // ✅ НОВОЕ: Флаг инициализации
  DateTime? _lastPermissionUpdate; // Для оптимизации обновления разрешений

  List<Widget> _widgetOptionsGroup1 = [];
  List<Widget> _widgetOptionsGroup2 = [];
  List<String> _navBarTitleKeysGroup1 = [];
  List<String> _navBarTitleKeysGroup2 = [];
  List<String> _activeIconsGroup1 = [];
  List<String> _activeIconsGroup2 = [];
  List<String> _inactiveIconsGroup1 = [];
  List<String> _inactiveIconsGroup2 = [];

  @override
  void initState() {
    super.initState();

    // ✅ ИСПРАВЛЕНИЕ: Инициализируем экраны СИНХРОННО
    _initializeScreensSync();

    // ✅ Подписываемся на события от виджета
    WidgetService.onNavigateFromWidget = (group, screenIndex) {
      if (mounted) {
        setState(() {
          if (group == 1 && screenIndex < _widgetOptionsGroup1.length) {
            _selectedIndexGroup1 = screenIndex;
            _selectedIndexGroup2 = -1;
          } else if (group == 2 && screenIndex < _widgetOptionsGroup2.length) {
            _selectedIndexGroup2 = screenIndex;
            _selectedIndexGroup1 = -1;
          }
        });
      }
    };

    // 🚀 Запускаем фоновую загрузку ПОСЛЕ отрисовки первого кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isBackgroundLoading) {
        _loadDataInBackground(); // ✅ загрузка разрешений в фоновом режиме

      }
    });
  }

  @override
  void dispose() {
    WidgetService.onNavigateFromWidget = null;
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ✅ СИНХРОННАЯ ИНИЦИАЛИЗАЦИЯ ЭКРАНОВ (БЕЗ МОРГАНИЯ)
  // ==========================================================================

  void _initializeScreensSync() {
    // ✅ Добавляем заглушку сразу, чтобы не было моргания
    _widgetOptionsGroup1 = [EmptyScreen()];
    _isInitialized = false;

    // Запускаем асинхронную загрузку разрешений
    initializeScreensWithPermissions();
  }

  // ==========================================================================
  // 🚀 ФОНОВАЯ ЗАГРУЗКА ДАННЫХ
  // ==========================================================================

  Future<void> _loadDataInBackground() async {
    if (_isBackgroundLoading) return;

    setState(() {
      _isBackgroundLoading = true;
    });

    try {
      //print('HomeScreen: 🚀 Начало фоновой загрузки данных');

      final apiService = context.read<ApiService>();
      final backgroundLoader = BackgroundDataLoaderService(
        apiService: apiService,
        context: context,
      );

      await backgroundLoader.loadAllDataInBackground();

      //print('HomeScreen: ✅ Фоновая загрузка завершена успешно');
    } catch (e) {
      //print('HomeScreen: ❌ Ошибка фоновой загрузки: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBackgroundLoading = false;
        });
      }
    }
  }

  // ==========================================================================
  // ИНИЦИАЛИЗАЦИЯ ЭКРАНОВ С РАЗРЕШЕНИЯМИ
  // ==========================================================================

  Future<void> initializeScreensWithPermissions() async {
    if (!mounted) return;

    // Ждем загрузки разрешений из PermissionsBloc
    final permissionsBloc = context.read<PermissionsBloc>();

    // Если разрешения еще не загружены, загружаем их
    if (permissionsBloc.state is! PermissionsLoaded) {
      permissionsBloc.add(FetchPermissionsEvent());
      // Ждем загрузки разрешений
      await permissionsBloc.stream.firstWhere(
        (state) => state is PermissionsLoaded || state is PermissionsError,
      );
    }

    if (!mounted) return;

    // Проверяем разрешения из PermissionsBloc
    bool hasPermission(String permission) => permissionsBloc.hasPermission(permission); // ✅ Проверяем разрешения из PermissionsBloc

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

    // Дашборд
    if (hasPermission('section.dashboard')) {
      widgetsGroup1.add(DashboardScreen());
      titleKeysGroup1.add('appbar_dashboard');
      navBarTitleKeysGroup1.add('appbar_dashboard');
      activeIconsGroup1.add('assets/icons/MyNavBar/dashboard_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/dashboard_OFF.png');
    }

    // Задачи
    if (hasPermission('task.read')) {
      widgetsGroup1.add(TaskScreen());
      titleKeysGroup1.add('appbar_tasks');
      navBarTitleKeysGroup1.add('appbar_tasks');
      activeIconsGroup1.add('assets/icons/MyNavBar/tasks_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/tasks_OFF.png');
    }

    // Лиды
    if (hasPermission('lead.read')) {
      widgetsGroup1.add(LeadScreen());
      titleKeysGroup1.add('appbar_leads');
      navBarTitleKeysGroup1.add('appbar_leads');
      activeIconsGroup1.add('assets/icons/MyNavBar/clients_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/clients_OFF.png');
    }

    // Сделки
    if (hasPermission('deal.read')) {
      widgetsGroup1.add(DealScreen());
      titleKeysGroup1.add('appbar_deals');
      navBarTitleKeysGroup1.add('appbar_deals');
      activeIconsGroup1.add('assets/icons/MyNavBar/deal_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/deal_OFF.png');
    }

    // Чаты
    widgetsGroup1.add(ChatsScreen());
    titleKeysGroup1.add('appbar_chats');
    navBarTitleKeysGroup1.add('appbar_chats');
    activeIconsGroup1.add('assets/icons/MyNavBar/chats_ON.png');
    inactiveIconsGroup1.add('assets/icons/MyNavBar/chats_OFF.png');

    // ========== КЛЮЧЕВАЯ ЛОГИКА ==========

    bool hasWarehouseAccess = false;
    if (hasPermission('accounting_of_goods') ||
        hasPermission('accounting_money')) {
      hasWarehouseAccess = true;
    }

    bool hasOrderAccess = hasPermission('order.read');

    if (hasWarehouseAccess) {
      widgetsGroup1.add(WarehouseAccountingScreen());
      titleKeysGroup1.add('appbar_warehouse');
      navBarTitleKeysGroup1.add('appbar_warehouse');
      activeIconsGroup1.add('assets/icons/MyNavBar/money_on_.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/google-docs (5).png');

      if (hasOrderAccess) {
        widgetsGroup2.add(OrderScreen());
        titleKeysGroup2.add('appbar_orders');
        navBarTitleKeysGroup2.add('appbar_orders');
        activeIconsGroup2.add('assets/icons/MyNavBar/orderon.png');
        inactiveIconsGroup2.add('assets/icons/MyNavBar/order_OFF.png');
      }

    } else {
      if (hasOrderAccess) {
        widgetsGroup2.add(OnlineStoreScreen());
        titleKeysGroup2.add('appbar_online_store');
        navBarTitleKeysGroup2.add('appbar_online_store');
        activeIconsGroup2.add('assets/icons/MyNavBar/category_ON.png');
        inactiveIconsGroup2.add('assets/icons/MyNavBar/category_OFF.png');
      }
    }

    // ✅ ИСПРАВЛЕНИЕ: Если нет экранов в группе 1, добавляем EmptyScreen
    if (widgetsGroup1.isEmpty) {
      widgetsGroup1.add(EmptyScreen());
      titleKeysGroup1.add('');
      navBarTitleKeysGroup1.add('');
    }

    if (mounted) {
      setState(() {
        _widgetOptionsGroup1 = widgetsGroup1;
        _widgetOptionsGroup2 = widgetsGroup2;
        _navBarTitleKeysGroup1 = navBarTitleKeysGroup1;
        _navBarTitleKeysGroup2 = navBarTitleKeysGroup2;
        _activeIconsGroup1 = activeIconsGroup1;
        _activeIconsGroup2 = activeIconsGroup2;
        _inactiveIconsGroup1 = inactiveIconsGroup1;
        _inactiveIconsGroup2 = inactiveIconsGroup2;
        _isInitialized = true;

        // ✅ Если выбранный индекс больше чем количество экранов, сбрасываем
        if (_selectedIndexGroup1 >= widgetsGroup1.length) {
          _selectedIndexGroup1 = 0;
        }

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

    if (args != null && !_isPushHandled && _isInitialized) {
      setState(() {
        if (args['group'] == 1) {
          _selectedIndexGroup1 = args['screenIndex'] ?? 0;
          _selectedIndexGroup2 = -1;
        } else if (args['group'] == 2) {
          if (_widgetOptionsGroup2.isNotEmpty) {
            _selectedIndexGroup2 = args['screenIndex'] ?? 0;
            _selectedIndexGroup1 = -1;
          } else {
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
    return BlocListener<PermissionsBloc, PermissionsState>(
      listener: (context, state) {
        // При изменении состояния разрешений пересоздаем экраны
        if (state is PermissionsLoaded || state is PermissionsError) {
          if (_isInitialized && mounted) {
            // Вызываем асинхронно, чтобы не блокировать listener
            initializeScreensWithPermissions();
          }
        }
      },
      child: BlocBuilder<PermissionsBloc, PermissionsState>(
        builder: (context, permissionsState) {
          Widget currentWidget;

          // ✅ ИСПРАВЛЕНИЕ: Всегда показываем валидный виджет
          if (_selectedIndexGroup1 != -1 && _selectedIndexGroup1 < _widgetOptionsGroup1.length) {
            currentWidget = _widgetOptionsGroup1[_selectedIndexGroup1];
          } else if (_selectedIndexGroup2 != -1 && _selectedIndexGroup2 < _widgetOptionsGroup2.length) {
            currentWidget = _widgetOptionsGroup2[_selectedIndexGroup2];
          } else if (_widgetOptionsGroup1.isNotEmpty) {
            currentWidget = _widgetOptionsGroup1[0];
          } else {
            currentWidget = EmptyScreen();
          }

          Widget safeBody = SafeArea(
            bottom: true,
            child: currentWidget,
          );

          return Scaffold(
            body: safeBody,
            backgroundColor: Colors.white,
            bottomNavigationBar: _isInitialized
                ? MyNavBar(
                    currentIndexGroup1: _selectedIndexGroup1,
                    currentIndexGroup2: _selectedIndexGroup2,
                    onItemSelected: (groupIndex, itemIndex) {
                      // Обновляем разрешения при переключении табов (с ограничением частоты)
                      final now = DateTime.now();
                      if (_lastPermissionUpdate == null || now.difference(_lastPermissionUpdate!) > const Duration(seconds: 5)) {
                        context.read<PermissionsBloc>().add(FetchPermissionsEvent());
                        _lastPermissionUpdate = now;
                      }

                      setState(() {
                        if (groupIndex == 1) {
                          _selectedIndexGroup1 = itemIndex;
                          _selectedIndexGroup2 = -1;
                        } else if (groupIndex == 2) {
                          _selectedIndexGroup2 = itemIndex;
                          _selectedIndexGroup1 = -1;
                        }
                      });
                    },
                    navBarTitlesGroup1: _navBarTitleKeysGroup1
                        .map((key) => key.isEmpty ? '' : AppLocalizations.of(context)!.translate(key))
                        .toList(),
                    navBarTitlesGroup2: _navBarTitleKeysGroup2
                        .map((key) => key.isEmpty ? '' : AppLocalizations.of(context)!.translate(key))
                        .toList(),
                    activeIconsGroup1: _activeIconsGroup1,
                    activeIconsGroup2: _activeIconsGroup2,
                    inactiveIconsGroup1: _inactiveIconsGroup1,
                    inactiveIconsGroup2: _inactiveIconsGroup2,
                  )
                : SizedBox.shrink(), // Скрываем навбар пока не инициализировано
          );
        },
      ),
    );
  }
}