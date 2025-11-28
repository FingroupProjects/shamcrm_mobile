import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/api/service/widget_service.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/bloc/permission/permession_state.dart';
import 'package:crm_task_manager/page_2/online_shop.dart';
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/page_2/money/money_income/money_income_screen.dart';
import 'package:crm_task_manager/page_2/money/money_outcome/money_outcome_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier_return_document/supplier_return_document_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/warehouse_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_screen.dart';
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/background_data_loader_service.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/empty_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndexGroup1 = 0;
  int _selectedIndexGroup2 = -1;
  final TextEditingController _searchController = TextEditingController();
  bool _isPushHandled = false;
  bool _isBackgroundLoading = false;
  bool _isInitialized = false;
  DateTime? _lastPermissionUpdate;

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
    
    // ✅ Подписываемся на изменения жизненного цикла приложения
    WidgetsBinding.instance.addObserver(this);

    // ✅ Инициализируем экраны синхронно
    _initializeScreensSync();

    // ✅ Устанавливаем callback'и для навигации от виджета
    _setupWidgetNavigationCallbacks();

    // ✅ Запускаем фоновую загрузку и обработку push после отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isBackgroundLoading) {
        _loadDataInBackground();
        _handleInitialMessage();
        _checkPendingWidgetNavigation();
      }
    });
  }
  
  // ==========================================================================
  // ✅ SETUP WIDGET NAVIGATION CALLBACKS
  // ==========================================================================
  
  void _setupWidgetNavigationCallbacks() {
    // ✅ Подписываемся на события от виджета (legacy Android формат)
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

    // ✅ Подписываемся на события от виджета (screen identifier - iOS and Android)
    WidgetService.onNavigateFromWidgetByScreen = (screenIdentifier) {
      if (mounted) {
        debugPrint('HomeScreen: Callback triggered for: $screenIdentifier');
        _navigateToScreenByIdentifier(screenIdentifier);
      }
    };
  }
  
  // ==========================================================================
  // ✅ APP LIFECYCLE OBSERVER
  // ==========================================================================
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('HomeScreen: App lifecycle changed to $state');
    
    if (state == AppLifecycleState.resumed) {
      // ✅ Когда приложение возобновляется, проверяем pending navigation
      // и убеждаемся, что callback установлен
      if (mounted) {
        _setupWidgetNavigationCallbacks();
        
        // Проверяем pending navigation с небольшой задержкой
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _checkPendingWidgetNavigation();
          }
        });
      }
    }
  }
  
  // ==========================================================================
  // ✅ CHECK PENDING WIDGET NAVIGATION (for cold start from widget)
  // ==========================================================================
  
  void _checkPendingWidgetNavigation() {
    debugPrint('HomeScreen: === _checkPendingWidgetNavigation() ===');
    debugPrint('HomeScreen: _isInitialized = $_isInitialized');
    debugPrint('HomeScreen: _widgetOptionsGroup1.length = ${_widgetOptionsGroup1.length}');
    
    final pendingScreen = WidgetService.consumePendingNavigation();
    debugPrint('HomeScreen: pendingScreen from WidgetService: $pendingScreen');
    
    if (pendingScreen != null) {
      debugPrint('HomeScreen: Found pending widget navigation: $pendingScreen');
      _navigateToScreenByIdentifier(pendingScreen);
    } else {
      debugPrint('HomeScreen: No pending navigation');
    }
  }

  @override
  void dispose() {
    // ✅ Отписываемся от изменений жизненного цикла
    WidgetsBinding.instance.removeObserver(this);
    
    WidgetService.onNavigateFromWidget = null;
    WidgetService.onNavigateFromWidgetByScreen = null;
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ✅ НАВИГАЦИЯ ПО ИДЕНТИФИКАТОРУ ЭКРАНА (iOS)
  // ==========================================================================

  void _navigateToScreenByIdentifier(String screenIdentifier) {
    debugPrint('HomeScreen: === _navigateToScreenByIdentifier($screenIdentifier) ===');
    debugPrint('HomeScreen: _isInitialized = $_isInitialized');
    debugPrint('HomeScreen: mounted = $mounted');
    
    if (!_isInitialized) {
      debugPrint('HomeScreen: Not initialized yet, scheduling retry in 500ms');
      // Если экраны еще не инициализированы, ждем и пробуем снова
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          debugPrint('HomeScreen: Retrying navigation after delay');
          _navigateToScreenByIdentifier(screenIdentifier);
        }
      });
      return;
    }

    // Маппинг идентификаторов экранов на их типы
    int? targetIndexGroup1;
    int? targetIndexGroup2;
    
    // Handle accounting document screen identifiers
    final accountingScreenIdentifiers = [
      'client_sale',
      'client_return',
      'income_goods',
      'transfer',
      'write_off',
      'supplier_return',
      'money_income',
      'money_outcome'
    ];
    
    if (accountingScreenIdentifiers.contains(screenIdentifier)) {
      debugPrint('HomeScreen: Accounting screen identifier detected: $screenIdentifier');
      
      // First, navigate to warehouse screen
      int? warehouseIndex;
      for (int i = 0; i < _widgetOptionsGroup1.length; i++) {
        final widget = _widgetOptionsGroup1[i];
        if (widget is WarehouseAccountingScreen) {
          warehouseIndex = i;
          break;
        }
      }
      
      if (warehouseIndex != null) {
        setState(() {
          _selectedIndexGroup1 = warehouseIndex!;
          _selectedIndexGroup2 = -1;
        });
        
        // Then navigate to specific document screen after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          
          Widget? targetScreen;
          switch (screenIdentifier) {
            case 'client_sale':
              targetScreen = ClientSaleScreen();
              break;
            case 'client_return':
              targetScreen = ClientReturnScreen();
              break;
            case 'income_goods':
              targetScreen = IncomingScreen();
              break;
            case 'transfer':
              targetScreen = MovementScreen(organizationId: 1);
              break;
            case 'write_off':
              targetScreen = WriteOffScreen();
              break;
            case 'supplier_return':
              targetScreen = SupplierReturnScreen();
              break;
            case 'money_income':
              targetScreen = MoneyIncomeScreen();
              break;
            case 'money_outcome':
              targetScreen = MoneyOutcomeScreen();
              break;
          }
          
          if (targetScreen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen!),
            );
            debugPrint('HomeScreen: ✅ Navigated to accounting document: $screenIdentifier');
          }
        });
        
        return;
      } else {
        debugPrint('HomeScreen: ⚠️ Warehouse screen not found, cannot navigate to accounting document');
      }
    }
    
    debugPrint('HomeScreen: Searching in Group1 (${_widgetOptionsGroup1.length} screens)');
    
    // Ищем экран в группе 1
    for (int i = 0; i < _widgetOptionsGroup1.length; i++) {
      final widget = _widgetOptionsGroup1[i];
      debugPrint('HomeScreen: Group1[$i] = ${widget.runtimeType}');
      
      // Проверяем тип виджета по его runtimeType
      if (screenIdentifier == 'dashboard' && widget is DashboardScreen) {
        targetIndexGroup1 = i;
        debugPrint('HomeScreen: Found dashboard at index $i');
        break;
      } else if (screenIdentifier == 'tasks' && widget is TaskScreen) {
        targetIndexGroup1 = i;
        debugPrint('HomeScreen: Found tasks at index $i');
        break;
      } else if (screenIdentifier == 'leads' && widget is LeadScreen) {
        targetIndexGroup1 = i;
        debugPrint('HomeScreen: Found leads at index $i');
        break;
      } else if (screenIdentifier == 'deals' && widget is DealScreen) {
        targetIndexGroup1 = i;
        debugPrint('HomeScreen: Found deals at index $i');
        break;
      } else if (screenIdentifier == 'chats' && widget is ChatsScreen) {
        targetIndexGroup1 = i;
        debugPrint('HomeScreen: Found chats at index $i');
        break;
      } else if (screenIdentifier == 'warehouse' && widget is WarehouseAccountingScreen) {
        targetIndexGroup1 = i;
        debugPrint('HomeScreen: Found warehouse at index $i');
        break;
      }
    }

    // Ищем экран в группе 2 (Orders, Online Store)
    if (targetIndexGroup1 == null) {
      debugPrint('HomeScreen: Not found in Group1, searching Group2 (${_widgetOptionsGroup2.length} screens)');
      for (int i = 0; i < _widgetOptionsGroup2.length; i++) {
        final widget = _widgetOptionsGroup2[i];
        debugPrint('HomeScreen: Group2[$i] = ${widget.runtimeType}');
        
        if (screenIdentifier == 'orders' && widget is OrderScreen) {
          targetIndexGroup2 = i;
          debugPrint('HomeScreen: Found orders at index $i');
          break;
        } else if (screenIdentifier == 'online_store' && widget is OnlineStoreScreen) {
          targetIndexGroup2 = i;
          debugPrint('HomeScreen: Found online_store at index $i');
          break;
        }
      }
    }

    debugPrint('HomeScreen: targetIndexGroup1 = $targetIndexGroup1');
    debugPrint('HomeScreen: targetIndexGroup2 = $targetIndexGroup2');

    if (targetIndexGroup1 != null) {
      debugPrint('HomeScreen: Setting _selectedIndexGroup1 = $targetIndexGroup1');
      setState(() {
        _selectedIndexGroup1 = targetIndexGroup1!;
        _selectedIndexGroup2 = -1;
      });
      debugPrint('HomeScreen: ✅ Navigated to Group1 screen=$screenIdentifier at index=$targetIndexGroup1');
    } else if (targetIndexGroup2 != null) {
      debugPrint('HomeScreen: Setting _selectedIndexGroup2 = $targetIndexGroup2');
      setState(() {
        _selectedIndexGroup2 = targetIndexGroup2!;
        _selectedIndexGroup1 = -1;
      });
      debugPrint('HomeScreen: ✅ Navigated to Group2 screen=$screenIdentifier at index=$targetIndexGroup2');
    } else {
      debugPrint('HomeScreen: ❌ Screen $screenIdentifier not found or not available');
    }
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
      debugPrint('HomeScreen: 🚀 Начало фоновой загрузки данных');

      final apiService = context.read<ApiService>();
      final backgroundLoader = BackgroundDataLoaderService(
        apiService: apiService,
        context: context,
      );

      await backgroundLoader.loadAllDataInBackground();

      debugPrint('HomeScreen: ✅ Фоновая загрузка завершена успешно');
    } catch (e) {
      debugPrint('HomeScreen: ❌ Ошибка фоновой загрузки: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBackgroundLoading = false;
        });
      }
    }
  }

  // ==========================================================================
  // ✅ ОБРАБОТКА PUSH УВЕДОМЛЕНИЯ (НОВОЕ)
  // ==========================================================================

  Future<void> _handleInitialMessage() async {
    try {
      debugPrint('HomeScreen: 🔍 Проверка наличия initialMessage');

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final RemoteMessage? initialMessage = args?['initialMessage'] as RemoteMessage?;

      if (initialMessage != null) {
        debugPrint('HomeScreen: ✅ Получено initialMessage из PinScreen');
        debugPrint('HomeScreen: 📦 Data: ${initialMessage.data}');

        // ✅ КРИТИЧНО: Ждем пока HomeScreen полностью загрузится
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) {
          debugPrint('HomeScreen: ⚠️ Widget unmounted');
          return;
        }

        // ✅ ИСПРАВЛЕНИЕ: Сразу обрабатываем сообщение
        FirebaseApi? firebaseApi;
        if (Firebase.apps.isNotEmpty) {
          try {
            Firebase.app();
            firebaseApi = FirebaseApi();
            debugPrint('HomeScreen: ✅ FirebaseApi создан');
          } catch (e) {
            debugPrint('HomeScreen: ❌ Ошибка FirebaseApi: $e');
          }
        }

        if (firebaseApi != null) {
          try {
            debugPrint('HomeScreen: 🚀 Обработка initialMessage');
            await firebaseApi.handleMessage(initialMessage);
            debugPrint('HomeScreen: ✅ initialMessage обработано');
          } catch (e) {
            debugPrint('HomeScreen: ❌ Ошибка обработки: $e');
          }
        }
      } else {
        debugPrint('HomeScreen: ℹ️ Нет initialMessage (обычный запуск)');
      }
    } catch (e, stackTrace) {
      debugPrint('HomeScreen: ❌ Критическая ошибка: $e');
      debugPrint('StackTrace: $stackTrace');
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
    bool hasPermission(String permission) => permissionsBloc.hasPermission(permission);

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

  // ==========================================================================
  // DID CHANGE DEPENDENCIES
  // ==========================================================================

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

  // ==========================================================================
  // BUILD
  // ==========================================================================

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