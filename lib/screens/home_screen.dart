import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase/firebase_api.dart';
import 'package:crm_task_manager/api/service/device/widget_service.dart';
import 'package:crm_task_manager/app/app_feature_flags.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/bloc/permission/permession_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/page_2/online_shop.dart';
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/page_2/category/category_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_screen.dart';
import 'package:crm_task_manager/page_2/money/money_income/money_income_screen.dart';
import 'package:crm_task_manager/page_2/money/money_outcome/money_outcome_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/cash_desk/cash_desk_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/expense/expense_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/income/income_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/openings/openings_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/references_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supplier_creen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier_return_document/supplier_return_document_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/ware_house/ware_house_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/warehouse_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_screen.dart';
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:crm_task_manager/screens/background_data_loader_service.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/dashboard/dashboard_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_screen.dart';
import 'package:crm_task_manager/screens/empty_screen.dart';
import 'package:crm_task_manager/screens/no_access_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_screen.dart';
import 'package:crm_task_manager/screens/task/task_screen.dart';
import 'package:crm_task_manager/services/chat_unread_counter_service.dart';
import 'package:crm_task_manager/services/workday_profile_redirect_service.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final bool initialShowProfileScreen;

  const HomeScreen({
    super.key,
    this.initialShowProfileScreen = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndexGroup1 = 0;
  int _selectedIndexGroup2 = -1;
  bool _showProfileScreen = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isPushHandled = false;
  bool _didApplyWorkdayRouteArgument = false;
  bool _isBackgroundLoading = false;
  bool _isInitialized = false;
  int _dashboardReloadNonce = 0;
  String _lastScreensStructureKey = '';
  DateTime? _lastPermissionUpdate;
  DateTime? _lastResumeSyncAt;
  String _profileHeaderName = 'Профиль';

  List<Widget> _widgetOptionsGroup1 = [];
  List<Widget> _widgetOptionsGroup2 = [];
  List<String> _navBarTitleKeysGroup1 = [];
  List<String> _navBarTitleKeysGroup2 = [];
  List<String> _activeIconsGroup1 = [];
  List<String> _activeIconsGroup2 = [];
  List<String> _inactiveIconsGroup1 = [];
  List<String> _inactiveIconsGroup2 = [];

  void _refreshChatUnreadCounters() {
    ChatUnreadCounterService.instance.refreshCounts(silent: true);
  }

  bool _shouldSkipResumeSideEffects() {
    final now = DateTime.now();
    if (_lastResumeSyncAt != null &&
        now.difference(_lastResumeSyncAt!) < const Duration(seconds: 2)) {
      debugPrint('HomeScreen: resume side effects skipped due to debounce');
      return true;
    }

    _lastResumeSyncAt = now;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _showProfileScreen = widget.initialShowProfileScreen;

    // ✅ Подписываемся на изменения жизненного цикла приложения
    WidgetsBinding.instance.addObserver(this);
    WorkdayProfileRedirectService.requestCounter
        .addListener(_handleWorkdayProfileRequest);
    WorkdayProfileRedirectService.closeCounter
        .addListener(_handleWorkdayProfileClose);
    _consumePendingWorkdayProfileRequest();

    // ✅ Инициализируем экраны синхронно
    _initializeScreensSync();
    _loadProfileHeaderName();

    // ✅ Устанавливаем callback'и для навигации от виджета
    _setupWidgetNavigationCallbacks();

    // ✅ Запускаем фоновую загрузку и обработку push после отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isBackgroundLoading) {
        ChatUnreadCounterService.instance.initialize();
        // Запрашиваем permission после появления HomeScreen, а не во время
        // перехода с PIN/авторизации — так системный диалог показывается уже
        // при первом входе и не теряется между маршрутами.
        unawaited(FirebaseApi().initNotifications());
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
        context.read<PermissionsBloc>().add(FetchPermissionsEvent());
        _refreshChatUnreadCounters();
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
        context.read<PermissionsBloc>().add(FetchPermissionsEvent());
        debugPrint('HomeScreen: Callback triggered for: $screenIdentifier');
        _refreshChatUnreadCounters();
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
            if (_shouldSkipResumeSideEffects()) {
              return;
            }
            ChatUnreadCounterService.instance.refreshCounts(silent: true);
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
    debugPrint(
        'HomeScreen: _widgetOptionsGroup1.length = ${_widgetOptionsGroup1.length}');

    final pendingScreen = WidgetService.consumePendingNavigation();
    debugPrint('HomeScreen: pendingScreen from WidgetService: $pendingScreen');

    if (pendingScreen != null) {
      context.read<PermissionsBloc>().add(FetchPermissionsEvent());
      debugPrint('HomeScreen: Found pending widget navigation: $pendingScreen');
      _refreshChatUnreadCounters();
      _navigateToScreenByIdentifier(pendingScreen);
    } else {
      debugPrint('HomeScreen: No pending navigation');
    }
  }

  @override
  void dispose() {
    // ✅ Отписываемся от изменений жизненного цикла
    WidgetsBinding.instance.removeObserver(this);
    WorkdayProfileRedirectService.requestCounter
        .removeListener(_handleWorkdayProfileRequest);
    WorkdayProfileRedirectService.closeCounter
        .removeListener(_handleWorkdayProfileClose);

    WidgetService.onNavigateFromWidget = null;
    WidgetService.onNavigateFromWidgetByScreen = null;
    FirebaseApi().markHomeNotReady();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ✅ НАВИГАЦИЯ ПО ИДЕНТИФИКАТОРУ ЭКРАНА (iOS)
  // ==========================================================================

  void _navigateToScreenByIdentifier(String screenIdentifier) {
    debugPrint(
        'HomeScreen: === _navigateToScreenByIdentifier($screenIdentifier) ===');
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

    if (_showProfileScreen) {
      setState(() {
        _showProfileScreen = false;
      });
    }

    // Маппинг идентификаторов экранов на их типы
    int? targetIndexGroup1;
    int? targetIndexGroup2;

    if (sipEnabled &&
        (screenIdentifier == 'sip_journal' ||
            screenIdentifier == 'sip' ||
            screenIdentifier == 'sip_dial')) {
      debugPrint(
          'HomeScreen: SIP screen identifier detected: $screenIdentifier');

      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SipScreen(
              initialTab: screenIdentifier == 'sip_journal'
                  ? SipScreenInitialTab.journal
                  : SipScreenInitialTab.dial,
            ),
          ),
        );
        debugPrint(
          'HomeScreen: ✅ Navigated to SIP screen: $screenIdentifier',
        );
      });

      return;
    }

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

    // Handle references screen - close all reference screens and return to references
    if (screenIdentifier == 'references') {
      debugPrint('HomeScreen: References screen identifier detected');

      // Close all pushed reference screens and navigate to ReferencesScreen
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }

      // Navigate to ReferencesScreen
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReferencesScreen()),
        );
        debugPrint('HomeScreen: ✅ Navigated to references screen');
      });

      return;
    }

    // Handle warehouse screen - close all document screens and return to warehouse
    if (screenIdentifier == 'warehouse') {
      debugPrint('HomeScreen: Warehouse screen identifier detected');

      // Find warehouse screen index
      int? warehouseIndex;
      for (int i = 0; i < _widgetOptionsGroup1.length; i++) {
        final widget = _widgetOptionsGroup1[i];
        if (widget is WarehouseAccountingScreen) {
          warehouseIndex = i;
          break;
        }
      }

      if (warehouseIndex != null) {
        // Navigate to warehouse tab first
        _refreshChatUnreadCounters();
        setState(() {
          _selectedIndexGroup1 = warehouseIndex!;
          _selectedIndexGroup2 = -1;
        });

        // Close all pushed document screens and return to warehouse
        // Pop until we reach the HomeScreen (which contains warehouse)
        if (Navigator.canPop(context)) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }

        debugPrint('HomeScreen: ✅ Navigated to warehouse screen');
        return;
      } else {
        debugPrint('HomeScreen: ⚠️ Warehouse screen not found');
      }
    }

    // Handle reference screen identifiers
    final referenceScreenIdentifiers = [
      'reference_warehouse',
      'reference_supplier',
      'reference_product',
      'reference_category',
      'reference_openings',
      'reference_cash_desk',
      'reference_expense_article',
      'reference_income_article'
    ];

    if (referenceScreenIdentifiers.contains(screenIdentifier)) {
      debugPrint(
          'HomeScreen: Reference screen identifier detected: $screenIdentifier');

      // Close all pushed screens first
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }

      // Then navigate to specific reference screen after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        Widget? targetScreen;
        switch (screenIdentifier) {
          case 'reference_warehouse':
            targetScreen = WareHouseScreen();
            break;
          case 'reference_supplier':
            targetScreen = const SupplierCreen();
            break;
          case 'reference_product':
            targetScreen = GoodsScreen();
            break;
          case 'reference_category':
            targetScreen = CategoryScreen();
            break;
          case 'reference_openings':
            targetScreen = const OpeningsScreen();
            break;
          case 'reference_cash_desk':
            targetScreen = CashDeskScreen();
            break;
          case 'reference_expense_article':
            targetScreen = ExpenseScreen();
            break;
          case 'reference_income_article':
            targetScreen = IncomeScreen();
            break;
        }

        if (targetScreen != null) {
          // Always use pushReplacement to replace current reference screen
          if (Navigator.canPop(context)) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => targetScreen!),
            );
          } else {
            // If we can't pop, just push (first time opening a reference)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen!),
            );
          }
          debugPrint('HomeScreen: ✅ Navigated to reference: $screenIdentifier');
        }
      });

      return;
    }

    // Handle accounting document screen identifiers
    if (accountingScreenIdentifiers.contains(screenIdentifier)) {
      debugPrint(
          'HomeScreen: Accounting screen identifier detected: $screenIdentifier');

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
        _refreshChatUnreadCounters();
        setState(() {
          _selectedIndexGroup1 = warehouseIndex!;
          _selectedIndexGroup2 = -1;
        });

        // Then navigate to specific document screen after a short delay
        // Use pushReplacement to replace current screen instead of pushing
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
            // Always use pushReplacement to replace current document screen
            // This prevents stacking multiple document screens
            if (Navigator.canPop(context)) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => targetScreen!),
              );
            } else {
              // If we can't pop, just push (first time opening a document)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => targetScreen!),
              );
            }
            debugPrint(
                'HomeScreen: ✅ Navigated to accounting document: $screenIdentifier');
          }
        });

        return;
      } else {
        debugPrint(
            'HomeScreen: ⚠️ Warehouse screen not found, cannot navigate to accounting document');
      }
    }

    debugPrint(
        'HomeScreen: Searching in Group1 (${_widgetOptionsGroup1.length} screens)');

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
      } else if (screenIdentifier == 'analytics' && widget is DashboardScreen) {
        targetIndexGroup1 = i;
        debugPrint(
            'HomeScreen: Found dashboard (analytics mapped) at index $i');
        break;
      } else if (screenIdentifier == 'warehouse' &&
          widget is WarehouseAccountingScreen) {
        targetIndexGroup1 = i;
        debugPrint('HomeScreen: Found warehouse at index $i');
        break;
      }
    }

    // Ищем экран в группе 2 (Orders, Online Store)
    if (targetIndexGroup1 == null) {
      debugPrint(
          'HomeScreen: Not found in Group1, searching Group2 (${_widgetOptionsGroup2.length} screens)');
      for (int i = 0; i < _widgetOptionsGroup2.length; i++) {
        final widget = _widgetOptionsGroup2[i];
        debugPrint('HomeScreen: Group2[$i] = ${widget.runtimeType}');

        if (screenIdentifier == 'orders' && widget is OrderScreen) {
          targetIndexGroup2 = i;
          debugPrint('HomeScreen: Found orders at index $i');
          break;
        } else if (screenIdentifier == 'online_store' &&
            widget is OnlineStoreScreen) {
          targetIndexGroup2 = i;
          debugPrint('HomeScreen: Found online_store at index $i');
          break;
        }
      }
    }

    debugPrint('HomeScreen: targetIndexGroup1 = $targetIndexGroup1');
    debugPrint('HomeScreen: targetIndexGroup2 = $targetIndexGroup2');

    if (targetIndexGroup1 != null) {
      debugPrint(
          'HomeScreen: Setting _selectedIndexGroup1 = $targetIndexGroup1');
      _refreshChatUnreadCounters();
      setState(() {
        _selectedIndexGroup1 = targetIndexGroup1!;
        _selectedIndexGroup2 = -1;
      });
      debugPrint(
          'HomeScreen: ✅ Navigated to Group1 screen=$screenIdentifier at index=$targetIndexGroup1');
    } else if (targetIndexGroup2 != null) {
      debugPrint(
          'HomeScreen: Setting _selectedIndexGroup2 = $targetIndexGroup2');
      _refreshChatUnreadCounters();
      setState(() {
        _selectedIndexGroup2 = targetIndexGroup2!;
        _selectedIndexGroup1 = -1;
      });
      debugPrint(
          'HomeScreen: ✅ Navigated to Group2 screen=$screenIdentifier at index=$targetIndexGroup2');
    } else {
      debugPrint(
          'HomeScreen: ❌ Screen $screenIdentifier not found or not available');
    }
  }

  void _handleWorkdayProfileRequest() {
    if (!WorkdayProfileRedirectService.consumePendingOpenProfile()) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _showProfileScreen = true;
    });
  }

  void _handleWorkdayProfileClose() {
    if (!mounted) return;
    final shouldRefresh = _showProfileScreen;
    setState(() {
      _showProfileScreen = false;
      if (shouldRefresh) {
        _dashboardReloadNonce++;
      }
      _selectDashboardTabIfAvailable();
    });
    if (shouldRefresh) {
      initializeScreensWithPermissions();
    }
  }

  void _selectDashboardTabIfAvailable() {
    final dashboardIndex = _widgetOptionsGroup1.indexWhere(
      (widget) => widget is DashboardScreen,
    );

    if (dashboardIndex != -1) {
      _selectedIndexGroup1 = dashboardIndex;
      _selectedIndexGroup2 = -1;
    }
  }

  void _consumePendingWorkdayProfileRequest() {
    if (!WorkdayProfileRedirectService.consumePendingOpenProfile()) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _showProfileScreen = true;
      });
    });
  }

  Future<void> _loadProfileHeaderName() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userNameProfile') ??
        prefs.getString('userName') ??
        'Профиль';
    if (!mounted) return;
    setState(() {
      _profileHeaderName = userName.isEmpty ? 'Профиль' : userName;
    });
  }

  String _currentSectionTitle(AppLocalizations localizations) {
    if (_showProfileScreen) {
      return _profileHeaderName;
    }

    if (_selectedIndexGroup1 != -1 &&
        _selectedIndexGroup1 < _navBarTitleKeysGroup1.length) {
      return localizations
          .translate(_navBarTitleKeysGroup1[_selectedIndexGroup1]);
    }

    if (_selectedIndexGroup2 != -1 &&
        _selectedIndexGroup2 < _navBarTitleKeysGroup2.length) {
      return localizations
          .translate(_navBarTitleKeysGroup2[_selectedIndexGroup2]);
    }

    return 'shamCRM';
  }

  Widget _buildEmbeddedProfileOverlay(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: AppBackgroundOverlay(
                preset: AppBackgroundPreset.aurora,
                forceRender: true,
              ),
            ),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colors.buttonPrimaryBg,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _profileHeaderName.isNotEmpty
                                  ? _profileHeaderName
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'P',
                              style: textStyles.titleLg.copyWith(
                                color: colors.textInverse,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentSectionTitle(localizations),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.titleLg.copyWith(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.search,
                                color: colors.iconSecondary),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.notifications_none,
                                color: colors.iconSecondary),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.more_vert,
                                color: colors.iconSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: ProfileScreen(embedded: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final RemoteMessage? initialMessage =
          args?['initialMessage'] as RemoteMessage?;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) {
        debugPrint('HomeScreen: ⚠️ Widget unmounted');
        return;
      }

      final firebaseApi = FirebaseApi();
      firebaseApi.markHomeReady();
      await firebaseApi.consumePendingPushNavigation();

      if (initialMessage != null) {
        debugPrint('HomeScreen: ✅ Получено initialMessage из PinScreen');
        debugPrint('HomeScreen: 📦 Data: ${initialMessage.data}');
        await firebaseApi.handleMessage(initialMessage);
        debugPrint('HomeScreen: ✅ initialMessage обработано');
      } else {
        debugPrint('HomeScreen: ℹ️ Нет FCM initialMessage');
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

    final bool wasOnGroup2 = _selectedIndexGroup2 != -1 &&
        _selectedIndexGroup2 < _widgetOptionsGroup2.length;
    final int previousGroup2Index = _selectedIndexGroup2;
    final int previousGroup1Index = _selectedIndexGroup1;

    // Ждем загрузки разрешений из PermissionsBloc
    final permissionsBloc = context.read<PermissionsBloc>();

    // Если разрешения еще не загружены, загружаем их
    if (permissionsBloc.state is! PermissionsLoaded &&
        permissionsBloc.state is! PermissionsNoAccess) {
      permissionsBloc.add(FetchPermissionsEvent());
      // Ждем загрузки разрешений (включая новые состояния)
      await permissionsBloc.stream.firstWhere(
        (state) =>
            state is PermissionsLoaded ||
            state is PermissionsError ||
            state is PermissionsNoAccess ||
            state is PermissionsNetworkError,
      );
    }

    if (!mounted) return;

    // ✅ КЛЮЧЕВАЯ ЛОГИКА: Если нет доступа (пустой массив) - показываем экран
    if (permissionsBloc.state is PermissionsNoAccess) {
      if (mounted) {
        setState(() {
          _widgetOptionsGroup1 = [NoAccessScreen()];
          _widgetOptionsGroup2 = [];
          _navBarTitleKeysGroup1 = [];
          _navBarTitleKeysGroup2 = [];
          _activeIconsGroup1 = [];
          _activeIconsGroup2 = [];
          _inactiveIconsGroup1 = [];
          _inactiveIconsGroup2 = [];
          _isInitialized = true;
          _selectedIndexGroup1 = 0;
          _selectedIndexGroup2 = -1;
        });
      }
      return;
    }

    // ✅ Если сетевая ошибка - не показываем экран "нет доступа", используем сохраненные permissions
    bool isNetworkError = permissionsBloc.state is PermissionsNetworkError;
    List<String> savedPermissions = [];

    if (isNetworkError) {
      if (kDebugMode) {
        debugPrint(
            'HomeScreen: Сетевая ошибка, используем сохраненные permissions');
      }
      // Загружаем сохраненные permissions из SharedPreferences
      final apiService = context.read<ApiService>();
      savedPermissions = await apiService.getPermissions();
      if (savedPermissions.isEmpty) {
        // Если нет сохраненных permissions, показываем загрузку
        if (kDebugMode) {
          debugPrint(
              'HomeScreen: Нет сохраненных permissions, показываем загрузку');
        }
        if (mounted) {
          setState(() {
            _widgetOptionsGroup1 = [EmptyScreen()];
            _widgetOptionsGroup2 = [];
            _isInitialized = true;
          });
        }
        return;
      } else {
        if (kDebugMode) {
          debugPrint(
              'HomeScreen: Используем ${savedPermissions.length} сохраненных permissions');
        }
      }
    }

    // Проверяем разрешения из PermissionsBloc или сохраненные permissions
    bool hasPermission(String permission) {
      if (isNetworkError && savedPermissions.isNotEmpty) {
        // При сетевой ошибке используем сохраненные permissions
        return savedPermissions.contains(permission);
      }
      return permissionsBloc.hasPermission(permission);
    }

    bool hasAnyPermissionWithPrefix(String prefix) {
      final allPermissions = isNetworkError && savedPermissions.isNotEmpty
          ? savedPermissions
          : permissionsBloc.getAllPermissions();
      return allPermissions.any((permission) => permission.startsWith(prefix));
    }

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
      widgetsGroup1.add(
        DashboardScreen(
          key: ValueKey('dashboard_$_dashboardReloadNonce'),
        ),
      );
      titleKeysGroup1.add('appbar_dashboard');
      navBarTitleKeysGroup1.add('appbar_dashboard');
      activeIconsGroup1.add('assets/icons/MyNavBar/dashboard_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/dashboard_OFF.png');
    }

    // Задачи
    if (hasPermission('task.read')) {
      widgetsGroup1.add(TaskScreen(key: const ValueKey('home_tasks')));
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

    // Чаты - показываем если есть доступ хотя бы к одной из вкладок
    if (hasPermission('chat.read') ||
        hasPermission('task.read') ||
        hasPermission('corporateChat.read')) {
      widgetsGroup1.add(ChatsScreen());
      titleKeysGroup1.add('appbar_chats');
      navBarTitleKeysGroup1.add('appbar_chats');
      activeIconsGroup1.add('assets/icons/MyNavBar/chats_ON.png');
      inactiveIconsGroup1.add('assets/icons/MyNavBar/chats_OFF.png');
    }

    // ========== КЛЮЧЕВАЯ ЛОГИКА ==========

    final hasWarehouseDocumentAccess = hasPermission('accounting_of_goods') ||
        hasPermission('accounting_money') ||
        hasPermission('income_document.read') ||
        hasPermission('movement_document.read') ||
        hasPermission('manufacture.read') ||
        hasPermission('manufacture_document.read') ||
        hasPermission('write_off_document.read') ||
        hasPermission('expense_document.read') ||
        hasPermission('client_return_document.read') ||
        hasPermission('supplier_return_document.read') ||
        hasPermission('checking_account_pko.read') ||
        hasPermission('checking_account_rko.read');
    final hasWarehouseReferenceAccess = hasPermission('storage.read') ||
        hasPermission('unit.read') ||
        hasPermission('supplier.read') ||
        hasPermission('product.read') ||
        hasPermission('price_type.read') ||
        hasPermission('category.read') ||
        hasPermission('lead.read') ||
        hasPermission('initial_balance.read') ||
        hasPermission('cash_register.read') ||
        hasPermission('rko_article.read') ||
        hasPermission('pko_article.read');
    final bool hasWarehouseAccess =
        hasWarehouseDocumentAccess || hasWarehouseReferenceAccess;

    // Показываем раздел заказов, если есть любой order.* доступ
    bool hasOrderAccess = hasAnyPermissionWithPrefix('order.');
    // Онлайн-магазин показываем, если есть доступ хотя бы к одному из его разделов
    bool hasOnlineStoreAccess = hasPermission('category.read') ||
        hasPermission('product.read') ||
        hasOrderAccess;

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
      if (hasOnlineStoreAccess) {
        widgetsGroup2.add(OnlineStoreScreen());
        titleKeysGroup2.add('appbar_online_store');
        navBarTitleKeysGroup2.add('appbar_online_store');
        activeIconsGroup2.add('assets/icons/MyNavBar/category_ON.png');
        inactiveIconsGroup2.add('assets/icons/MyNavBar/category_OFF.png');
      }
    }

    // ✅ ИСПРАВЛЕНИЕ: Если нет экранов вообще - показываем экран с сообщением об отсутствии доступа
    // НО только если это не сетевая ошибка (при сетевой ошибке используем сохраненные permissions)
    if (widgetsGroup1.isEmpty && widgetsGroup2.isEmpty && !isNetworkError) {
      widgetsGroup1.add(NoAccessScreen());
      titleKeysGroup1.add('');
    }

    final structureKey = <String>[
      ...navBarTitleKeysGroup1,
      '::',
      ...navBarTitleKeysGroup2,
      '::',
      '$_dashboardReloadNonce',
    ].join('|');
    if (_isInitialized && structureKey == _lastScreensStructureKey) {
      return;
    }
    _lastScreensStructureKey = structureKey;

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

        // ✅ Корректно поддерживаем сценарий, когда доступны только экраны group2.
        if (widgetsGroup1.isEmpty && widgetsGroup2.isNotEmpty) {
          _selectedIndexGroup1 = -1;
          if (_selectedIndexGroup2 < 0 ||
              _selectedIndexGroup2 >= widgetsGroup2.length) {
            _selectedIndexGroup2 = 0;
          }
        } else if (widgetsGroup1.isNotEmpty) {
          if (wasOnGroup2 && widgetsGroup2.isNotEmpty) {
            _selectedIndexGroup2 = previousGroup2Index < widgetsGroup2.length
                ? previousGroup2Index
                : 0;
            _selectedIndexGroup1 = -1;
          } else {
            if (previousGroup1Index >= 0 &&
                previousGroup1Index < widgetsGroup1.length) {
              _selectedIndexGroup1 = previousGroup1Index;
            } else {
              _selectedIndexGroup1 = 0;
            }
          }

          if (!wasOnGroup2 && widgetsGroup2.isEmpty) {
            _selectedIndexGroup2 = -1;
          }
        } else {
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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (!_didApplyWorkdayRouteArgument &&
        args?['showWorkdayProfile'] == true &&
        mounted) {
      _didApplyWorkdayRouteArgument = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showProfileScreen = true;
        });
      });
    }

    if (args != null && !_isPushHandled && _isInitialized) {
      _refreshChatUnreadCounters();
      setState(() {
        if (args['group'] == 1) {
          if (_widgetOptionsGroup1.isNotEmpty) {
            _selectedIndexGroup1 = args['screenIndex'] ?? 0;
            _selectedIndexGroup2 = -1;
          } else if (_widgetOptionsGroup2.isNotEmpty) {
            _selectedIndexGroup2 = 0;
            _selectedIndexGroup1 = -1;
          }
        } else if (args['group'] == 2) {
          if (_widgetOptionsGroup2.isNotEmpty) {
            _selectedIndexGroup2 = args['screenIndex'] ?? 0;
            _selectedIndexGroup1 = -1;
          } else {
            _selectedIndexGroup1 = _widgetOptionsGroup1.isNotEmpty ? 0 : -1;
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
        if (state is PermissionsLoaded ||
            state is PermissionsError ||
            state is PermissionsNoAccess ||
            state is PermissionsNetworkError) {
          if (_isInitialized && mounted) {
            // Вызываем асинхронно, чтобы не блокировать listener
            initializeScreensWithPermissions();
          }
        }
      },
      child: BlocBuilder<PermissionsBloc, PermissionsState>(
        builder: (context, permissionsState) {
          Widget currentWidget;
          final bool hasNavBarItems = _navBarTitleKeysGroup1.isNotEmpty ||
              _navBarTitleKeysGroup2.isNotEmpty;

          // ✅ ИСПРАВЛЕНИЕ: Всегда показываем валидный виджет
          if (_selectedIndexGroup1 != -1 &&
              _selectedIndexGroup1 < _widgetOptionsGroup1.length) {
            currentWidget = _widgetOptionsGroup1[_selectedIndexGroup1];
          } else if (_selectedIndexGroup2 != -1 &&
              _selectedIndexGroup2 < _widgetOptionsGroup2.length) {
            currentWidget = _widgetOptionsGroup2[_selectedIndexGroup2];
          } else if (_widgetOptionsGroup1.isNotEmpty) {
            currentWidget = _widgetOptionsGroup1[0];
          } else if (_widgetOptionsGroup2.isNotEmpty) {
            currentWidget = _widgetOptionsGroup2[0];
          } else {
            currentWidget = EmptyScreen();
          }

          Widget safeBody = Stack(
            children: [
              SafeArea(
                bottom: true,
                child: currentWidget,
              ),
              if (_showProfileScreen) _buildEmbeddedProfileOverlay(context),
            ],
          );

          return Scaffold(
            body: safeBody,
            backgroundColor: Colors.transparent,
            extendBody: true,
            bottomNavigationBar: currentWidget is NoAccessScreen
                ? const SizedBox.shrink()
                : SizedBox(
                    // Skeleton и MyNavBar имеют одинаковую внутреннюю
                    // высоту. Фиксируем внешний размер вместе с safe-area,
                    // чтобы загрузка графика не двигала верхний край панели.
                    height: 60 + MediaQuery.of(context).viewPadding.bottom,
                    child: ValueListenableBuilder<ChatUnreadCounts>(
                      valueListenable:
                          ChatUnreadCounterService.instance.counts,
                      builder: (context, chatCounts, _) {
                        final unreadCountsGroup1 = _navBarTitleKeysGroup1
                            .map((key) =>
                                key == 'appbar_chats' ? chatCounts.total : 0)
                            .toList();
                        final unreadCountsGroup2 =
                            _navBarTitleKeysGroup2.map((_) => 0).toList();

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _isInitialized && hasNavBarItems
                              ? MyNavBar(
                                key: const ValueKey('main_nav_bar'),
                                currentIndexGroup1: _selectedIndexGroup1,
                                currentIndexGroup2: _selectedIndexGroup2,
                                onItemSelected: (groupIndex, itemIndex) {
                                  if (_showProfileScreen) {
                                    showCustomSnackBar(
                                      context: context,
                                      message: 'Сначала начните работу',
                                      isSuccess: false,
                                    );
                                    return;
                                  }

                                  final now = DateTime.now();
                                  if (_lastPermissionUpdate == null ||
                                      now.difference(_lastPermissionUpdate!) >
                                          const Duration(seconds: 5)) {
                                    context
                                        .read<PermissionsBloc>()
                                        .add(FetchPermissionsEvent());
                                    _lastPermissionUpdate = now;
                                  }

                                  _refreshChatUnreadCounters();

                                  setState(() {
                                    _showProfileScreen = false;
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
                                    .map((key) => key.isEmpty
                                        ? ''
                                        : AppLocalizations.of(context)!
                                            .translate(key))
                                    .toList(),
                                navBarTitlesGroup2: _navBarTitleKeysGroup2
                                    .map((key) => key.isEmpty
                                        ? ''
                                        : AppLocalizations.of(context)!
                                            .translate(key))
                                    .toList(),
                                activeIconsGroup1: _activeIconsGroup1,
                                activeIconsGroup2: _activeIconsGroup2,
                                inactiveIconsGroup1: _inactiveIconsGroup1,
                                inactiveIconsGroup2: _inactiveIconsGroup2,
                                unreadCountsGroup1: unreadCountsGroup1,
                                unreadCountsGroup2: unreadCountsGroup2,
                              )
                              : const NavBarShimmerSkeleton(
                                  key: ValueKey('nav_bar_skeleton'),
                                ),
                        );
                      },
                    ),
                  ),
          );
        },
      ),
    );
  }
}
