
import 'dart:convert';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/bloc/source_list/source_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
import 'package:crm_task_manager/screens/lead/lead_status_edit.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:crm_task_manager/screens/lead/tabBar/contact_list_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_add_screen.dart';

class LeadScreen extends StatefulWidget {
  final int? initialStatusId;

  LeadScreen({this.initialStatusId});

  @override
  _LeadScreenState createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController tabScrollController;
  List<Map<String, dynamic>> _tabTitles = [];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  bool _isManager = false;
  final TextEditingController _searchController = TextEditingController();
  bool _canReadLeadStatus = false;
  bool _canCreateLeadStatus = false;
  bool _canUpdateLeadStatus = false;
  bool _canDeleteLeadStatus = false;
  bool _isSwitch = false;
  bool _isSwitchingFunnel = false;
  bool _hasPermissionToAddLead = false;
  final ApiService _apiService = ApiService();
  bool navigateToEnd = false;
  bool navigateAfterDelete = false;
  int? _deletedIndex;
  bool _showCustomTabBar = true;
  String _lastSearchQuery = "";
  List<ManagerData> _selectedManagers = [];
  List<RegionData> _selectedRegions = [];
  List<SourceData> _selectedSources = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool? _hasSuccessDeals = false;
  bool? _hasInProgressDeals = false;
  bool? _hasFailureDeals = false;
  bool? _hasNotices = false;
  bool? _hasContact = false;
  bool? _hasChat = false;
  bool? _hasNoReplies = false;
  bool? _hasUnreadMessages = false;
  bool? _hasDeal = false;
  bool? _hasOrders = false;
  int? _daysWithoutActivity;
  List<Map<String, dynamic>> _directoryValues = [];
  List<Map<String, dynamic>> _initialDirectoryValues = [];
  Map<String, List<String>> _selectedCustomFieldFilters = {};
  Map<String, List<String>> _initialCustomFieldFilters = {};
  List<ManagerData> _initialSelectedManagers = [];
  List<RegionData> _initialSelectedRegions = [];
  List<SourceData> _initialSelectedSources = [];
  int? _initialSelStatus;
  DateTime? _initialFromDate;
  DateTime? _initialToDate;
  bool? _initialHasSuccessDeals;
  bool? _initialHasInProgressDeals;
  bool? _initialHasFailureDeals;
  bool? _initialHasNotices;
  bool? _initialHasContact;
  bool? _initialHasChat;
  bool? _initialHasNoReplies;
  bool? _initialHasUnreadMessages;
  bool? _initialHasDeal;
  bool? _initialHasOrders;
  int? _initialDaysWithoutActivity;
  final GlobalKey keySearchIcon = GlobalKey();
  final GlobalKey keyMenuIcon = GlobalKey();
  final GlobalKey keyFloatingActionButton = GlobalKey();
  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isLeadScreenTutorialCompleted = false;
  Map<String, dynamic>? tutorialProgress;
  SalesFunnel? _selectedFunnel;
  List<int>? _selectedManagerIds;
  bool _isFilterLoading = false; // НОВЫЙ флаг для отслеживания загрузки после фильтрации
  bool _shouldShowLoader = false; // НОВЫЙ флаг для принудительного показа лоадера


  Map<String, List<String>> _cloneCustomFieldFilters(Map<String, List<String>> source) {
    final result = <String, List<String>>{};
    source.forEach((key, value) {
      result[key] = List<String>.from(value);
    });
    return result;
  }

  Map<String, List<String>> _parseCustomFieldFilters(
      Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((e) => e.toString()).toList();
      }
    });
    return result;
  }

  bool get _hasActiveCustomFieldFilters => _selectedCustomFieldFilters.values
      .any((values) => values.isNotEmpty);


  @override
  void initState() {
    super.initState();
    _initializeSalesFunnel();
    //print('LeadScreen: initState started');
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    context.read<GetAllSourceBloc>().add(GetAllSourceEv());
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
    tabScrollController = ScrollController();
    tabScrollController.addListener(_onScroll);
    _loadFeatureState();

    _apiService.getSelectedSalesFunnel().then((funnelId) {
      if (funnelId != null && mounted) {
        context.read<SalesFunnelBloc>().add(SelectSalesFunnel(
          SalesFunnel(
            id: int.parse(funnelId),
            name: '',
            organizationId: 1,
            isActive: true,
            createdAt: '',
            updatedAt: '',
          ),
        ));
      }
    });

    context.read<SalesFunnelBloc>().stream.listen((state) {
      if (state is SalesFunnelLoaded && mounted) {
        setState(() {
          _selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
        });
        LeadCache.getLeadStatuses().then((cachedStatuses) {
          if (cachedStatuses.isNotEmpty && mounted) {
            setState(() {
              _tabTitles = cachedStatuses
                  .map((status) => {'id': status['id'], 'title': status['title']})
                  .toList();
              _tabController = TabController(length: _tabTitles.length, vsync: this);
              _tabController.index = _currentTabIndex;

              _tabController.addListener(() {
                if (!_tabController.indexIsChanging) {
                  setState(() {
                    _currentTabIndex = _tabController.index;
                    //print('LeadScreen: Tab changed to index: $_currentTabIndex');
                  });
                  _scrollToActiveTab();
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  context.read<LeadBloc>().add(FetchLeads(
                    currentStatusId,
                    salesFunnelId: _selectedFunnel?.id,
                    ignoreCache: true,
                  ));
                  //print('LeadScreen: FetchLeads dispatched for statusId: $currentStatusId');
                }
              });

              final currentStatusId = _tabTitles.isNotEmpty ? _tabTitles[_currentTabIndex]['id'] : 0;
              context.read<LeadBloc>().add(FetchLeads(
                currentStatusId,
                salesFunnelId: _selectedFunnel?.id,
                ignoreCache: true,
              ));
            });
          } else {
            context.read<LeadBloc>().add(FetchLeadStatuses());
          }
        });
      }
    });

    _checkPermissions();
  }
  Future<void> _initializeSalesFunnel() async {
  try {
    final savedFunnelId = await _apiService.getSelectedSalesFunnel();
    
    if (savedFunnelId == null || savedFunnelId.isEmpty) {
      debugPrint('⚠️ No saved funnel, will use first available');
      // Воронка установится автоматически из SalesFunnelBloc.stream
      return;
    }
    
    // Загружаем воронки
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
    
    debugPrint('✅ Initialized with funnelId: $savedFunnelId');
  } catch (e) {
    debugPrint('❌ _initializeSalesFunnel error: $e');
  }
}

  Future<void> _loadFeatureState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitch = prefs.getBool('switchContact') ?? false;
      //print('LeadScreen: _loadFeatureState - _isSwitch set to: $_isSwitch');
    });
  }

  void _onScroll() {
    // Логика прокрутки табов
  }
// Заменить метод _onRefresh в LeadScreen на этот:

  Future<void> _onRefresh(int currentStatusId) async {
    //print('LeadScreen: _onRefresh - RADICAL FULL REFRESH - clearing everything');

    try {
      // РАДИКАЛЬНАЯ очистка - удаляем ВСЕ данные связанные с лидами
      await LeadCache.clearAllData();
      await LeadCache.clearPersistentCounts(); // Очищаем и постоянные счетчики
      //print('LeadScreen: _onRefresh - Cleared ALL cache data including persistent counts');

      // Полный сброс состояния приложения
      if (mounted) {
        setState(() {
          // Сбрасываем ВЕСЬ UI в исходное состояние
          _isSearching = false;
          _lastSearchQuery = '';
          _searchController.clear();
          _showCustomTabBar = true;
          _isSwitchingFunnel = false;

          // Полный сброс всех фильтров
          _selectedManagers.clear();
          _selectedRegions.clear();
          _selectedSources.clear();
          _selectedStatuses = null;
          _fromDate = null;
          _toDate = null;
          _hasSuccessDeals = false;
          _hasInProgressDeals = false;
          _hasFailureDeals = false;
          _hasNotices = false;
          _hasContact = false;
          _hasChat = false;
          _hasNoReplies = false;
          _hasUnreadMessages = false;
          _hasDeal = false;
          _hasOrders = false;
          _daysWithoutActivity = null;
          _directoryValues.clear();

          // Сбрасываем и initial значения
          _initialSelectedManagers.clear();
          _initialSelectedRegions.clear();
          _initialSelectedSources.clear();
          _initialSelStatus = null;
          _initialFromDate = null;
          _initialToDate = null;
          _initialHasSuccessDeals = null;
          _initialHasInProgressDeals = null;
          _initialHasFailureDeals = null;
          _initialHasNotices = null;
          _initialHasContact = null;
          _initialHasChat = null;
          _initialHasNoReplies = null;
          _initialHasUnreadMessages = null;
          _initialHasDeal = null;
          _initialHasOrders = null;
          _initialDaysWithoutActivity = null;
          _initialDirectoryValues.clear();

          // Очищаем табы - начинаем с чистого листа
          _tabTitles.clear();
          _tabKeys.clear();
          _currentTabIndex = 0;

          // Создаем пустой контроллер табов
          if (_tabController.length > 0) {
            _tabController.dispose();
          }
          _tabController = TabController(length: 0, vsync: this);

          //print('LeadScreen: _onRefresh - Reset all UI state to initial');
        });
      }

      // Очищаем состояние LeadBloc полностью
      final leadBloc = BlocProvider.of<LeadBloc>(context);
      await leadBloc.clearAllCountsAndCache();
      //print('LeadScreen: _onRefresh - Cleared LeadBloc state');

      // ПРИНУДИТЕЛЬНАЯ загрузка ВСЕХ данных с сервера
      // Никаких кэшей, никаких сохраненных данных - все с нуля
      leadBloc.add(FetchLeadStatuses(forceRefresh: true));
      //print('LeadScreen: _onRefresh - Initiated FORCED reload of all data from server');

      //print('LeadScreen: _onRefresh - RADICAL refresh completed successfully');

    } catch (e) {
      //print('LeadScreen: _onRefresh error: $e');

      // При ошибке показываем пользователю и пытаемся восстановить хотя бы базовое состояние
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при обновлении данных: ${e.toString()}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () => _onRefresh(currentStatusId),
            ),
          ),
        );

        // Пытаемся восстановить минимальное рабочее состояние
        final leadBloc = BlocProvider.of<LeadBloc>(context);
        leadBloc.add(FetchLeadStatuses(forceRefresh: false));
      }
    }
  }

  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('leadStatus.read');
    final canCreate = await _apiService.hasPermission('leadStatus.create');
    final canUpdate = await _apiService.hasPermission('leadStatus.update');
    final canDelete = await _apiService.hasPermission('leadStatus.delete');
    final canAddLead = await _apiService.hasPermission('lead.create');
    if (mounted) {
      setState(() {
        _canReadLeadStatus = canRead;
        _canCreateLeadStatus = canCreate;
        _canUpdateLeadStatus = canUpdate;
        _canDeleteLeadStatus = canDelete;
        _hasPermissionToAddLead = canAddLead;
      });
    }

    try {
      final progress = await _apiService.getTutorialProgress();
      if (mounted) {
        if (progress is Map<String, dynamic> && progress['result'] is Map<String, dynamic>) {
          setState(() {
            tutorialProgress = progress['result'];
          });
        } else {
          setState(() {
            tutorialProgress = null;
          });
        }
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isTutorialShown = prefs.getBool('isTutorialShownLeadSearchIconAppBar') ?? false;
      if (mounted) {
        setState(() {
          _isTutorialShown = isTutorialShown;
        });
      }

      if (tutorialProgress != null &&
          tutorialProgress!['leads']?['index'] == false &&
          !_isTutorialShown &&
          mounted) {
        // _initTutorialTargets();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // showTutorial();
          }
        });
      }
    } catch (e) {
      //print('LeadScreen: Error fetching tutorial progress: $e');
    }
  }

  // void _initTutorialTargets() {
  //   targets.clear();
  //   targets.addAll([
  //     createTarget(
  //       identify: "LeadSearchIcon",
  //       keyTarget: keySearchIcon,
  //       title: AppLocalizations.of(context)!
  //           .translate('tutorial_task_screen_search_title'),
  //       description: AppLocalizations.of(context)!
  //           .translate('tutorial_lead_screen_search_description'),
  //       align: ContentAlign.bottom,
  //       context: context,
  //       contentPosition: ContentPosition.above,
  //     ),
  //     createTarget(
  //       identify: "LeadMenuIcon",
  //       keyTarget: keyMenuIcon,
  //       title: AppLocalizations.of(context)!
  //           .translate('tutorial_task_screen_menu_title'),
  //       description: AppLocalizations.of(context)!
  //           .translate('tutorial_lead_screen_menu_description'),
  //       align: ContentAlign.bottom,
  //       context: context,
  //       contentPosition: ContentPosition.above,
  //     ),
  //     createTarget(
  //       identify: "FloatingActionButton",
  //       keyTarget: keyFloatingActionButton,
  //       title: AppLocalizations.of(context)!.translate('tutorial_lead_button_title'),
  //       description: AppLocalizations.of(context)!.translate('tutorial_lead_button_description'),
  //       align: ContentAlign.top,
  //       context: context,
  //     ),
  //   ]);
  // }

  // void showTutorial() async {
  //   if (_isTutorialShown) {
  //     //print('LeadScreen: Tutorial already shown for LeadScreen, skipping');
  //     return;
  //   }

  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await Future.delayed(const Duration(milliseconds: 500));

  //   TutorialCoachMark(
  //     targets: targets,
  //     textSkip: AppLocalizations.of(context)!.translate('skip'),
  //     textStyleSkip: TextStyle(
  //       color: Colors.white,
  //       fontFamily: 'Gilroy',
  //       fontSize: 20,
  //       fontWeight: FontWeight.w600,
  //       shadows: [
  //         Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
  //         Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
  //         Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
  //         Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
  //       ],
  //     ),
  //     colorShadow: Color(0xff1E2E52),
  //     onSkip: () {
  //       //print('LeadScreen: Tutorial skipped for LeadScreen');
  //       prefs.setBool('isTutorialShownLeadSearchIconAppBar', true);
  //       if (mounted) {
  //         setState(() {
  //           _isTutorialShown = true;
  //           _isLeadScreenTutorialCompleted = true;
  //         });
  //       }
  //       return true;
  //     },
  //     onFinish: () {
  //       //print('LeadScreen: Tutorial finished for LeadScreen');
  //       prefs.setBool('isTutorialShownLeadSearchIconAppBar', true);
  //       if (mounted) {
  //         setState(() {
  //           _isTutorialShown = true;
  //           _isLeadScreenTutorialCompleted = true;
  //         });
  //       }
  //     },
  //   ).show(context: context);
  // }

  Future<void> _searchLeads(String query, int currentStatusId) async {
    if (mounted) {
      setState(() {
        _isFilterLoading = true; // ← НОВОЕ
        _shouldShowLoader = true; // ← НОВОЕ: принудительно показываем лоадер

      });
    }

    final leadBloc = BlocProvider.of<LeadBloc>(context);
    await LeadCache.clearLeadsForStatus(currentStatusId);
    //print('LeadScreen: Searching leads with query: $query');
    leadBloc.add(FetchLeads(
      currentStatusId,
      query: query,
      managerIds: _selectedManagers.map((manager) => manager.id).toList(),
      regionsIds: _selectedRegions.map((region) => region.id).toList(),
      sourcesIds: _selectedSources.map((source) => source.id).toList(),
      statusIds: _selectedStatuses,
      fromDate: _fromDate,
      toDate: _toDate,
      hasSuccessDeals: _hasSuccessDeals,
      hasInProgressDeals: _hasInProgressDeals,
      hasFailureDeals: _hasFailureDeals,
      hasNotices: _hasNotices,
      hasContact: _hasContact,
      hasChat: _hasChat,
      hasNoReplies: _hasNoReplies,
      hasUnreadMessages: _hasUnreadMessages,
      hasDeal: _hasDeal,
      hasOrders: _hasOrders,
      daysWithoutActivity: _daysWithoutActivity,
      directoryValues: _directoryValues,
      salesFunnelId: _selectedFunnel?.id,
      ignoreCache: true, // ← ВАЖНО!
    ));
  }

  void _resetFilters() {
    if (mounted) {
      setState(() {
        _showCustomTabBar = true;
        _selectedManagers = [];
        _selectedRegions = [];
        _selectedSources = [];
        _selectedStatuses = null;
        _fromDate = null;
        _toDate = null;
        _hasSuccessDeals = false;
        _hasInProgressDeals = false;
        _hasFailureDeals = false;
        _hasNotices = false;
        _hasContact = false;
        _hasChat = false;
        _hasNoReplies = false;
        _hasUnreadMessages = false;
        _hasDeal = false;
        _hasOrders = false;
        _daysWithoutActivity = null;
        _directoryValues = [];
        _selectedCustomFieldFilters = {};
        _initialSelectedManagers = [];
        _initialSelectedRegions = [];
        _initialSelectedSources = [];
        _initialSelStatus = null;
        _initialFromDate = null;
        _initialToDate = null;
        _initialHasSuccessDeals = false;
        _initialHasInProgressDeals = false;
        _initialHasFailureDeals = false;
        _initialHasNotices = false;
        _initialHasContact = false;
        _initialHasChat = false;
        _initialHasNoReplies = false;
        _initialHasUnreadMessages = false;
        _initialHasDeal = false;
        _initialHasOrders = false;
        _initialDaysWithoutActivity = null;
        _initialDirectoryValues = [];
        _initialCustomFieldFilters = {};
        _lastSearchQuery = '';
        _searchController.clear();
      });
    }
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatuses());
  }

  Future<void> _handleManagerSelected(Map managers) async {
    //print('LeadScreen: _handleManagerSelected - START');

    // КРИТИЧНО: Сначала показываем лоадер и скрываем старые данные
    final customFieldFiltersRaw =
    managers['custom_field_filters'] as Map<String, dynamic>?;
    final parsedCustomFieldFilters =
    _parseCustomFieldFilters(customFieldFiltersRaw);
    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true; // ← НОВОЕ: принудительно показываем лоадер
        _showCustomTabBar = false;
        _selectedManagers = managers['managers'];
        _selectedRegions = managers['regions'];
        _selectedSources = managers['sources'];
        _selectedStatuses = managers['statuses'];
        _fromDate = managers['fromDate'];
        _toDate = managers['toDate'];
        _hasSuccessDeals = managers['hasSuccessDeals'];
        _hasInProgressDeals = managers['hasInProgressDeals'];
        _hasFailureDeals = managers['hasFailureDeals'];
        _hasNotices = managers['hasNotices'];
        _hasContact = managers['hasContact'];
        _hasChat = managers['hasChat'];
        _hasNoReplies = managers['hasNoReplies'];
        _hasUnreadMessages = managers['hasUnreadMessages'];
        _hasDeal = managers['hasDeal'];
        _hasOrders = managers['hasOrders'];
        _daysWithoutActivity = managers['daysWithoutActivity'];
        _directoryValues = managers['directory_values'] ?? [];
        _selectedCustomFieldFilters =
            _cloneCustomFieldFilters(parsedCustomFieldFilters);
        _initialSelectedManagers = managers['managers'];
        _initialSelectedRegions = managers['regions'];
        _initialSelectedSources = managers['sources'];
        _initialSelStatus = managers['statuses'];
        _initialFromDate = managers['fromDate'];
        _initialToDate = managers['toDate'];
        _initialHasSuccessDeals = managers['hasSuccessDeals'];
        _initialHasInProgressDeals = managers['hasInProgressDeals'];
        _initialHasFailureDeals = managers['hasFailureDeals'];
        _initialHasNotices = managers['hasNotices'];
        _initialHasContact = managers['hasContact'];
        _initialHasChat = managers['hasChat'];
        _initialHasNoReplies = managers['hasNoReplies'];
        _initialHasUnreadMessages = managers['hasUnreadMessages'];
        _initialHasDeal = managers['hasDeal'];
        _initialHasOrders = managers['hasOrders'];
        _initialDaysWithoutActivity = managers['daysWithoutActivity'];
        _initialDirectoryValues = managers['directory_values'] ?? [];
        _initialCustomFieldFilters =
            _cloneCustomFieldFilters(parsedCustomFieldFilters);
      });
    }

    //print('LeadScreen: _handleManagerSelected - Loader shown, clearing cache');

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];

    // Очищаем кэш
    await LeadCache.clearLeadsForStatus(currentStatusId);

    //print('LeadScreen: _handleManagerSelected - Cache cleared, dispatching FetchLeads');

    // Небольшая задержка для гарантии отображения лоадера
    await Future.delayed(Duration(milliseconds: 50));

    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeads(
      currentStatusId,
      managerIds: _selectedManagers.map((manager) => manager.id).toList(),
      regionsIds: _selectedRegions.map((region) => region.id).toList(),
      sourcesIds: _selectedSources.map((source) => source.id).toList(),
      statusIds: _selectedStatuses,
      fromDate: _fromDate,
      toDate: _toDate,
      hasSuccessDeals: _hasSuccessDeals,
      hasInProgressDeals: _hasInProgressDeals,
      hasFailureDeals: _hasFailureDeals,
      hasNotices: _hasNotices,
      hasContact: _hasContact,
      hasChat: _hasChat,
      hasNoReplies: _hasNoReplies,
      hasUnreadMessages: _hasUnreadMessages,
      hasDeal: _hasDeal,
      hasOrders: _hasOrders,
      daysWithoutActivity: _daysWithoutActivity,
      directoryValues: _directoryValues,
      salesFunnelId: _selectedFunnel?.id,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
      ignoreCache: true,
    ));

    //print('LeadScreen: _handleManagerSelected - FetchLeads dispatched');
  }

  void _onSearch(String query) {
    _lastSearchQuery = query;
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchLeads(query, currentStatusId);
  }
  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();
  ValueChanged<String>? onChangedSearchInput;

  bool isClickAvatarIcon = false;

Widget _buildTitleWidget(BuildContext context) {
  return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
    builder: (context, state) {
      String title = AppLocalizations.of(context)!.translate('appbar_leads');
      SalesFunnel? selectedFunnel;

      if (state is SalesFunnelLoaded) {
        selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
        _selectedFunnel = selectedFunnel;
        if (selectedFunnel != null) {
          title = selectedFunnel.name;
        }
      }
      // Loading / Error → просто "Лиды"

      return Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (state is SalesFunnelLoaded && state.funnels.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: PopupMenuButton<SalesFunnel>(
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xff1E2E52)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                elevation: 8,
                offset: const Offset(0, 40),
                onSelected: (funnel) async {
                  try {
                    setState(() => _isSwitchingFunnel = true);
                    await _apiService.saveSelectedSalesFunnel(funnel.id.toString());
                    await LeadCache.clearAllLeads();
                    await LeadCache.clearCache();
                    _resetFilters();

                    if (mounted) {
                      setState(() {
                        _selectedFunnel = funnel;
                        _isSearching = false;
                        _searchController.clear();
                        _lastSearchQuery = '';
                      });
                    }

                    context.read<SalesFunnelBloc>().add(SelectSalesFunnel(funnel));
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted) {
                      setState(() {
                        _tabTitles.clear();
                        _tabController = TabController(length: 0, vsync: this);
                      });
                    }
                    context.read<LeadBloc>().add(FetchLeadStatuses());
                  } catch (e) {
                    setState(() => _isSwitchingFunnel = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ошибка при смене воронки'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                itemBuilder: (context) => state.funnels
                    .map((f) => PopupMenuItem<SalesFunnel>(
                          value: f,
                          child: Text(f.name, style: const TextStyle(fontFamily: 'Gilroy')),
                        ))
                    .toList(),
              ),
            ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    //print('LeadScreen: Building widget tree, _tabTitles: $_tabTitles, _currentTabIndex: $_currentTabIndex');
    final localizations = AppLocalizations.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<SalesFunnelBloc>()),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBar(
            SearchIconKey: keySearchIcon,
            menuIconKey: keyMenuIcon,
            title: '',
            titleWidget: isClickAvatarIcon
                ? Text(
              localizations!.translate('appbar_settings'),
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            )
                : _buildTitleWidget(context),
            onClickProfileAvatar: () {
              //print('LeadScreen: Profile avatar clicked, isClickAvatarIcon: $isClickAvatarIcon');
              if (mounted) {
                setState(() {
                  isClickAvatarIcon = !isClickAvatarIcon;
                });
              }
            },
            onChangedSearchInput: (String value) {
              //print('LeadScreen: Search input changed: $value');
              if (value.isNotEmpty) {
                if (mounted) {
                  setState(() {
                    _isSearching = true;
                  });
                }
                //print('LeadScreen: Search mode activated');
              }
              _onSearch(value);
            },
            onManagersLeadSelected: _handleManagerSelected,
            initialManagersLead: _initialSelectedManagers,
            initialManagersLeadRegions: _initialSelectedRegions,
            initialManagersLeadSources: _initialSelectedSources,
            initialManagerLeadStatuses: _initialSelStatus,
            initialManagerLeadFromDate: _initialFromDate,
            initialManagerLeadToDate: _initialToDate,
            initialManagerLeadHasSuccessDeals: _initialHasSuccessDeals,
            initialManagerLeadHasInProgressDeals: _initialHasInProgressDeals,
            initialManagerLeadHasFailureDeals: _initialHasFailureDeals,
            initialManagerLeadHasNotices: _initialHasNotices,
            initialManagerLeadHasContact: _initialHasContact,
            initialManagerLeadHasChat: _initialHasChat,
            initialManagerLeadHasNoReplies: _initialHasNoReplies,
            initialManagerLeadHasUnreadMessages: _initialHasUnreadMessages,
            initialManagerLeadHasDeal: _initialHasDeal,
            initialManagerLeadHasOrders: _initialHasOrders,
            initialManagerLeadDaysWithoutActivity: _initialDaysWithoutActivity,
            initialDirectoryValuesLead: _initialDirectoryValues,
            initialLeadCustomFields: _initialCustomFieldFilters,
            onLeadResetFilters: _resetFilters,
            textEditingController: textEditingController,
            focusNode: focusNode,
            showMenuIcon: _showCustomTabBar,
            showFilterIconOnSelectLead: !_showCustomTabBar,
            hasActiveLeadFilters: !_showCustomTabBar,
            showFilterTaskIcon: false,
            showMyTaskIcon: true,
            showCallCenter: true,
            showFilterIconDeal: false,
            showEvent: true,
            clearButtonClick: (value) {
              //print('LeadScreen: Clear button clicked, isSearching: $value');
              if (value == false) {
                if (mounted) {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _lastSearchQuery = '';
                    //print('LeadScreen: Search cleared, resetting state');
                  });
                }
                if (_searchController.text.isEmpty) {
                  if (_selectedManagers.isEmpty &&
                      _selectedRegions.isEmpty &&
                      _selectedSources.isEmpty &&
                      _selectedStatuses == null &&
                      _fromDate == null &&
                      _toDate == null &&
                      _hasSuccessDeals == false &&
                      _hasInProgressDeals == false &&
                      _hasFailureDeals == false &&
                      _hasNotices == false &&
                      _hasContact == false &&
                      _hasChat == false &&
                      _hasNoReplies == false &&
                      _hasUnreadMessages == false &&
                      _hasDeal == false &&
                      _hasOrders == false &&
                      _directoryValues.isEmpty &&
                      !_hasActiveCustomFieldFilters) {
                    if (mounted) {
                      setState(() {
                        _showCustomTabBar = true;
                      });
                    }
                    //print('LeadScreen: Showing custom tab bar after clear');
                    final taskBloc = BlocProvider.of<LeadBloc>(context);
                    taskBloc.add(FetchLeadStatuses());
                    //print('LeadScreen: FetchLeadStatuses dispatched after clear');
                  } else {
                    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                    final taskBloc = BlocProvider.of<LeadBloc>(context);
                    taskBloc.add(FetchLeads(
                      currentStatusId,
                      managerIds: _selectedManagers.isNotEmpty
                          ? _selectedManagers.map((manager) => manager.id).toList()
                          : null,
                      regionsIds: _selectedRegions.isNotEmpty
                          ? _selectedRegions.map((region) => region.id).toList()
                          : null,
                      sourcesIds: _selectedSources.isNotEmpty
                          ? _selectedSources.map((source) => source.id).toList()
                          : null,
                      statusIds: _selectedStatuses,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      hasSuccessDeals: _hasSuccessDeals,
                      hasInProgressDeals: _hasInProgressDeals,
                      hasFailureDeals: _hasFailureDeals,
                      hasNotices: _hasNotices,
                      hasContact: _hasContact,
                      hasChat: _hasChat,
                      hasNoReplies: _hasNoReplies,
                      hasUnreadMessages: _hasUnreadMessages,
                      hasDeal: _hasDeal,
                      hasOrders: _hasOrders,
                      daysWithoutActivity: _daysWithoutActivity,
                      directoryValues: _directoryValues,
                      salesFunnelId: _selectedFunnel?.id,
                    ));
                    //print('LeadScreen: FetchLeads dispatched with filters after clear, salesFunnelId: ${_selectedFunnel?.id}');
                  }
                } else if (_selectedManagerIds != null && _selectedManagerIds!.isNotEmpty) {
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  final taskBloc = BlocProvider.of<LeadBloc>(context);
                  taskBloc.add(FetchLeads(
                    currentStatusId,
                    managerIds: _selectedManagerIds,
                    query: _searchController.text.isNotEmpty ? _searchController.text : null,
                    directoryValues: _directoryValues,
                    salesFunnelId: _selectedFunnel?.id,
                  ));
                  //print('LeadScreen: FetchLeads dispatched with managerIds after clear, salesFunnelId: ${_selectedFunnel?.id}');
                }
              }
            },
            clearButtonClickFiltr: (value) {
              //print('LeadScreen: Filter clear button clicked: $value');
            },
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : Column(
          children: [
            const SizedBox(height: 15),
            if (!_isSearching && _selectedManagerIds == null && _showCustomTabBar)
              _buildCustomTabBar(),
            Expanded(
              child: _isSearching || _selectedManagerIds != null
                  ? _buildManagerView()
                  : _buildTabBarView(),
            ),
          ],
        ),
        floatingActionButton: _tabTitles.isNotEmpty && _hasPermissionToAddLead
            ? FloatingActionButton(
          key: keyFloatingActionButton,
          onPressed: () {
            //print('LeadScreen: FloatingActionButton pressed');
            final currentStatusId = _tabTitles[_currentTabIndex]['id'];
            if (_isSwitch) {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('add_for_current_status'),
                          style: TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 20,
                            fontFamily: "Gilroy",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Divider(color: Color(0xff1E2E52)),
                        ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate('new_lead_in_switch'),
                                style: TextStyle(
                                  color: Color(0xff1E2E52),
                                  fontSize: 16,
                                  fontFamily: "Gilroy",
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.add,
                                color: Color(0xff1E2E52),
                                size: 25,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeadAddScreen(statusId: currentStatusId),
                              ),
                            ).then((_) => context.read<LeadBloc>().add(FetchLeads(currentStatusId)));
                          },
                        ),
                        ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate('import_contact'),
                                style: TextStyle(
                                  color: Color(0xff1E2E52),
                                  fontSize: 16,
                                  fontFamily: "Gilroy",
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.contacts,
                                color: Color(0xff1E2E52),
                                size: 25,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContactsScreen(statusId: currentStatusId),
                              ),
                            ).then((_) => context.read<LeadBloc>().add(FetchLeads(currentStatusId)));
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeadAddScreen(statusId: currentStatusId),
                ),
              ).then((_) => context.read<LeadBloc>().add(FetchLeads(currentStatusId)));
            }
          },
          backgroundColor: Color(0xff1E2E52),
          child: Image.asset(
            'assets/icons/tabBar/add.png',
            width: 24,
            height: 24,
          ),
        )
            : null,
      ),
    );
  }

  Widget searchWidget(List<Lead> leads) {
    final currentStatusId = _tabTitles.isNotEmpty
        ? _tabTitles[_currentTabIndex]['id']
        : 0;

    // Показываем лоадер если флаги активны
    if (_isFilterLoading || _shouldShowLoader) {
      return const Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }

    if (_isSearching && leads.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('nothing_found'),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    } else if (_isManager && leads.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!
              .translate('no_leads_for_selected_manager'),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    } else if (leads.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!
              .translate('nothing_lead_for_manager'),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(currentStatusId),
      color: const Color(0xff1E2E52),
      backgroundColor: Colors.white,
      child: ListView.builder(
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LeadCard(
              lead: lead,
              title: lead.leadStatus?.title ?? "",
              statusId: lead.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusLeadId) {
                final index = _tabTitles.indexWhere(
                        (status) => status['id'] == StatusLeadId);
                if (index != -1) {
                  _tabController.animateTo(index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildManagerView() {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        // Сбрасываем флаги когда данные загружены или произошла ошибка
        if ((state is LeadDataLoaded || state is LeadError) &&
            mounted &&
            (_isFilterLoading || _shouldShowLoader)) {
          setState(() {
            _isFilterLoading = false;
            _shouldShowLoader = false;
            //print('LeadScreen: _buildManagerView - Loader flags reset');
          });
        }
      },
      child: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          final currentStatusId = _tabTitles.isNotEmpty
              ? _tabTitles[_tabController.index]['id']
              : 0;

          // Показываем лоадер только если флаги активны ИЛИ состояние - LeadLoading
          if (_shouldShowLoader || _isFilterLoading || state is LeadLoading) {
            //print('LeadScreen: _buildManagerView - Showing loader');
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          }

          if (state is LeadDataLoaded) {
            final List<Lead> leads = state.leads;
            final statusId = _tabTitles[_tabController.index]['id'];
            final filteredLeads = leads
                .where((lead) => lead.statusId == statusId)
                .toList();

            if (filteredLeads.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _onRefresh(currentStatusId),
                color: const Color(0xff1E2E52),
                backgroundColor: Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Text(
                      _selectedManagers.isNotEmpty
                          ? AppLocalizations.of(context)!
                          .translate('selected_manager_has_any_lead')
                          : AppLocalizations.of(context)!
                          .translate('nothing_found'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _onRefresh(currentStatusId),
              color: const Color(0xff1E2E52),
              backgroundColor: Colors.white,
              child: ListView.builder(
                itemCount: filteredLeads.length,
                itemBuilder: (context, index) {
                  final lead = filteredLeads[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: LeadCard(
                      lead: lead,
                      title: lead.leadStatus?.title ?? "",
                      statusId: lead.statusId,
                      onStatusUpdated: () {},
                      onStatusId: (StatusLeadId) {
                        final index = _tabTitles.indexWhere(
                                (status) => status['id'] == StatusLeadId);
                        if (index != -1) {
                          _tabController.animateTo(index);
                        }
                      },
                    ),
                  );
                },
              ),
            );
          }

          // Если состояние LeadError - показываем ошибку
          if (state is LeadError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: tabScrollController,
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
          if (_canCreateLeadStatus)
            IconButton(
              icon: Image.asset('assets/icons/tabBar/add_black.png', width: 24, height: 24),
              onPressed: _addNewTab,
            ),
        ],
      ),
    );
  }

  void _addNewTab() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => CreateStatusDialog(),
    );

    if (result == true) {
      context.read<LeadBloc>().add(FetchLeadStatuses());
      if (mounted) {
        setState(() {
          navigateToEnd = true;
        });
      }
    }
  }

  void _showStatusOptions(BuildContext context, int index) {
    final RenderBox renderBox = _tabKeys[index].currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + renderBox.size.height,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height * 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      color: Colors.white,
      items: [
        if (_canUpdateLeadStatus)
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: Color(0xff99A4BA)),
              title: Text(
                'Изменить',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
        if (_canDeleteLeadStatus)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Color(0xff99A4BA)),
              title: Text(
                'Удалить',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _editLeadStatus(index);
      } else if (value == 'delete') {
        _showDeleteDialog(index);
      }
    });
  }

// Обновленный метод _buildTabButton в LeadScreen
  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return FutureBuilder<int>(
      future: LeadCache.getPersistentLeadCount(_tabTitles[index]['id']),
      builder: (context, snapshot) {
        // Сначала пробуем получить count из постоянного кэша
        int leadCount = snapshot.data ?? 0;

        // Если в постоянном кэше нет данных, пробуем другие источники
        if (leadCount == 0) {
          return BlocBuilder<LeadBloc, LeadState>(
            builder: (context, state) {
              // Используем данные из состояния только если нет постоянного счетчика
              if (state is LeadLoaded) {
                final statusId = _tabTitles[index]['id'];
                final leadStatus = state.leadStatuses.firstWhere(
                      (status) => status.id == statusId,
                  orElse: () => LeadStatus(
                    id: 0,
                    title: '',
                    leadsCount: 0,
                    isSuccess: false,
                    position: 1,
                    isFailure: false,
                  ),
                );
                leadCount = leadStatus.leadsCount;

                // Сразу сохраняем в постоянный кэш
                LeadCache.setPersistentLeadCount(statusId, leadCount);
              } else if (state is LeadDataLoaded && state.leadCounts.containsKey(_tabTitles[index]['id'])) {
                leadCount = state.leadCounts[_tabTitles[index]['id']] ?? 0;

                // Сразу сохраняем в постоянный кэш
                LeadCache.setPersistentLeadCount(_tabTitles[index]['id'], leadCount);
              }

              return _buildTabButtonUI(index, isActive, leadCount);
            },
          );
        }

        // Если есть постоянный счетчик, используем его напрямую
        return _buildTabButtonUI(index, isActive, leadCount);
      },
    );
  }

// Вспомогательный метод для построения UI кнопки табы
  Widget _buildTabButtonUI(int index, bool isActive, int leadCount) {
    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
        //print('LeadScreen: Tab button tapped, index: $index');
      },
      onLongPress: () {
        _showStatusOptions(context, index);
      },
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tabTitles[index]['title'],
              style: TaskStyles.tabTextStyle.copyWith(
                color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
              ),
            ),
            Transform.translate(
              offset: const Offset(12, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? const Color(0xff1E2E52) : const Color(0xff99A4BA),
                    width: 1,
                  ),
                ),
                child: Text(
                  leadCount.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.black : const Color(0xff99A4BA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteLeadStatus(int index) {
    _showDeleteDialog(index);
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
      if (mounted) {
        setState(() {
          _deletedIndex = _currentTabIndex;
          navigateAfterDelete = true;
          _tabTitles.removeAt(index);
          _tabKeys.removeAt(index);
          _tabController = TabController(length: _tabTitles.length, vsync: this);
          _currentTabIndex = 0;
          _isSearching = false;
          _searchController.clear();
          context.read<LeadBloc>().add(FetchLeads(_currentTabIndex));
        });
      }

      if (_tabTitles.isEmpty) {
        await LeadCache.clearAllLeads();
        await LeadCache.clearCache();
      }

      context.read<LeadBloc>().add(FetchLeadStatuses());
    }
  }

  void _editLeadStatus(int index) {
    final leadStatus = _tabTitles[index];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditLeadStatusScreen(
          leadStatusId: leadStatus['id'],
        );
      },
    );
  }

  Widget _buildTabBarView() {
    //print('LeadScreen: _buildTabBarView called, _tabTitles length: ${_tabTitles.length}');
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) async {
        //print('LeadScreen: BlocListener received state: ${state.runtimeType}');
        // Сбрасываем флаг загрузки когда получены данные
        if (state is LeadDataLoaded || state is LeadError) {
          if (mounted && _isFilterLoading) {
            setState(() {
              _isFilterLoading = false; // ← НОВОЕ: сбрасываем флаг после загрузки
              _shouldShowLoader = false; // ← НОВОЕ: разрешаем показывать данные
              _isSwitchingFunnel = false; // На всякий случай


            });
          }
        }
        if (state is LeadLoaded) {
          //print('LeadScreen: LeadLoaded state, caching lead statuses: ${state.leadStatuses}');
          await LeadCache.cacheLeadStatuses(state.leadStatuses);

          if (mounted) {
            setState(() {
              // Обновляем табы с новыми данными
              _tabTitles = state.leadStatuses
                  .where((status) => _canReadLeadStatus)
                  .map((status) => {
                'id': status.id,
                'title': status.title,
                'leads_count': status.leadsCount,
              })
                  .toList();
              _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
              _isSwitchingFunnel = false;

              if (_tabTitles.isNotEmpty) {
                //print('LeadScreen: Initializing TabController with length: ${_tabTitles.length}');

                // Проверяем, нужно ли создавать новый контроллер
                bool needNewController = _tabController.length != _tabTitles.length;

                if (needNewController) {
                  // Сохраняем текущий индекс перед созданием нового контроллера
                  int savedTabIndex = _currentTabIndex;

                  // Dispose старого контроллера если он существует
                  if (_tabController.length > 0) {
                    _tabController.dispose();
                  }

                  // Создаем новый контроллер
                  _tabController = TabController(length: _tabTitles.length, vsync: this);
                  //print('LeadScreen: Created new TabController with length: ${_tabTitles.length}');
                }

                // Настраиваем слушатель (всегда обновляем)
                _tabController.addListener(() {
                  if (!_tabController.indexIsChanging) {
                    //print('LeadScreen: TabController listener triggered, new index: ${_tabController.index}');
                    setState(() {
                      _currentTabIndex = _tabController.index;
                    });
                    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                    if (tabScrollController.hasClients) {
                      _scrollToActiveTab();
                    }

                    // Загружаем лиды для выбранного статуса
                    context.read<LeadBloc>().add(FetchLeads(
                      currentStatusId,
                      salesFunnelId: _selectedFunnel?.id,
                      ignoreCache: false,
                      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
                      managerIds: _selectedManagers.isNotEmpty
                          ? _selectedManagers.map((manager) => manager.id).toList()
                          : null,
                      regionsIds: _selectedRegions.isNotEmpty
                          ? _selectedRegions.map((region) => region.id).toList()
                          : null,
                      sourcesIds: _selectedSources.isNotEmpty
                          ? _selectedSources.map((source) => source.id).toList()
                          : null,
                      statusIds: _selectedStatuses,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      hasSuccessDeals: _hasSuccessDeals,
                      hasInProgressDeals: _hasInProgressDeals,
                      hasFailureDeals: _hasFailureDeals,
                      hasNotices: _hasNotices,
                      hasContact: _hasContact,
                      hasChat: _hasChat,
                      hasNoReplies: _hasNoReplies,
                      hasUnreadMessages: _hasUnreadMessages,
                      hasDeal: _hasDeal,
                      hasOrders: _hasOrders,
                      daysWithoutActivity: _daysWithoutActivity,
                      directoryValues: _directoryValues,
                    ));
                    //print('LeadScreen: FetchLeads dispatched for statusId: $currentStatusId');
                  }
                });

                // Установка правильного индекса
                if (needNewController) {
                  // При создании нового контроллера восстанавливаем индекс или ставим 0
                  if (_currentTabIndex < _tabTitles.length && _currentTabIndex >= 0) {
                    _tabController.index = _currentTabIndex;
                    //print('LeadScreen: Restored tab index to: $_currentTabIndex');
                  } else {
                    _tabController.index = 0;
                    _currentTabIndex = 0;
                    //print('LeadScreen: Reset tab index to: 0');
                  }
                } else {
                  // При обновлении существующего контроллера проверяем initialStatusId
                  int initialIndex = state.leadStatuses
                      .indexWhere((status) => status.id == widget.initialStatusId);
                  if (initialIndex != -1 && initialIndex != _currentTabIndex) {
                    _tabController.index = initialIndex;
                    _currentTabIndex = initialIndex;
                    //print('LeadScreen: Set initial tab index to: $initialIndex');
                  } else if (_tabTitles.isNotEmpty) {
                    int safeIndex = _currentTabIndex < _tabTitles.length ? _currentTabIndex : 0;
                    _tabController.index = safeIndex;
                    _currentTabIndex = safeIndex;
                    //print('LeadScreen: Set safe tab index to: $safeIndex');
                  }
                }

                // Прокручиваем к активному табу
                if (tabScrollController.hasClients) {
                  _scrollToActiveTab();
                }

                // Обрабатываем специальные навигации
                if (navigateToEnd) {
                  navigateToEnd = false;
                  Future.delayed(Duration(milliseconds: 100), () {
                    if (mounted && _tabTitles.isNotEmpty) {
                      _tabController.animateTo(_tabTitles.length - 1);
                      //print('LeadScreen: Navigated to last tab');
                    }
                  });
                }

                if (navigateAfterDelete && _tabTitles.isNotEmpty) {
                  navigateAfterDelete = false;
                  if (_deletedIndex != null) {
                    int newIndex = _deletedIndex! >= _tabTitles.length ? _tabTitles.length - 1 : _deletedIndex!;
                    newIndex = newIndex < 0 ? 0 : newIndex;
                    Future.delayed(Duration(milliseconds: 100), () {
                      if (mounted) {
                        _tabController.animateTo(newIndex);
                        _currentTabIndex = newIndex;
                        //print('LeadScreen: Navigated to tab $newIndex after delete');
                      }
                    });
                  }
                }

                // При радикальном обновлении (после refresh) автоматически загружаем лиды для активного статуса
                Future.delayed(Duration(milliseconds: 150), () {
                  if (mounted && _tabTitles.isNotEmpty) {
                    final activeStatusId = _tabTitles[_currentTabIndex]['id'];
                    //print('LeadScreen: Auto-loading leads for active status after refresh: $activeStatusId');
                    context.read<LeadBloc>().add(FetchLeads(
                      activeStatusId,
                      salesFunnelId: _selectedFunnel?.id,
                      ignoreCache: true, // При обновлении после refresh принудительно загружаем с сервера
                    ));
                  }
                });

              } else {
                // Если табы пустые, создаем пустой контроллер
                if (_tabController.length > 0) {
                  _tabController.dispose();
                }
                _tabController = TabController(length: 0, vsync: this);
                _currentTabIndex = 0;
                //print('LeadScreen: TabController reset to length 0 (no statuses available)');
              }
            });
          }
        } else if (state is LeadError) {
          //print('LeadScreen: LeadError state received: ${state.message}');

          if (state.message.contains(
            AppLocalizations.of(context)!.translate('unauthorized_access'),
          )) {
            await _apiService.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Повторить',
                    textColor: Colors.white,
                    onPressed: () {
                      // При ошибке пробуем еще раз с принудительным обновлением
                      context.read<LeadBloc>().add(FetchLeadStatuses(forceRefresh: true));
                    },
                  ),
                ),
              );
            }
          }
        }
      },
      child: _tabTitles.isEmpty
          ? const Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: Duration(milliseconds: 1000),
        ),
      )
          : TabBarView(
        controller: _tabController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: _tabTitles.map((status) {
          //print('LeadScreen: Building TabBarView child for status: ${status['title']}');
          return RefreshIndicator(
            onRefresh: () => _onRefresh(status['id']),
            color: const Color(0xff1E2E52),
            backgroundColor: Colors.white,
            child: LeadColumn(
              isLeadScreenTutorialCompleted: _isLeadScreenTutorialCompleted,
              statusId: status['id'],
              title: status['title'],
              onStatusId: (newStatusId) {
                //print('LeadScreen: onStatusId called with id: $newStatusId');
                final index = _tabTitles.indexWhere((s) => s['id'] == newStatusId);
                if (index != -1) {
                  _tabController.animateTo(index);
                  //print('LeadScreen: Animated to tab index: $index for statusId: $newStatusId');

                  // Проверяем, есть ли уже данные для этого статуса
                  final currentLeadBloc = context.read<LeadBloc>();
                  if (currentLeadBloc.state is LeadDataLoaded) {
                    final currentState = currentLeadBloc.state as LeadDataLoaded;
                    final hasLeadsForStatus = currentState.leads.any((lead) => lead.statusId == newStatusId);

                    // Загружаем только если нет данных для этого статуса
                    if (!hasLeadsForStatus) {
                      currentLeadBloc.add(FetchLeads(
                        newStatusId,
                        salesFunnelId: _selectedFunnel?.id,
                        ignoreCache: false,
                        query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
                        managerIds: _selectedManagers.isNotEmpty
                            ? _selectedManagers.map((manager) => manager.id).toList()
                            : null,
                        regionsIds: _selectedRegions.isNotEmpty
                            ? _selectedRegions.map((region) => region.id).toList()
                            : null,
                        sourcesIds: _selectedSources.isNotEmpty
                            ? _selectedSources.map((source) => source.id).toList()
                            : null,
                        statusIds: _selectedStatuses,
                        fromDate: _fromDate,
                        toDate: _toDate,
                        hasSuccessDeals: _hasSuccessDeals,
                        hasInProgressDeals: _hasInProgressDeals,
                        hasFailureDeals: _hasFailureDeals,
                        hasNotices: _hasNotices,
                        hasContact: _hasContact,
                        hasChat: _hasChat,
                        hasNoReplies: _hasNoReplies,
                        hasUnreadMessages: _hasUnreadMessages,
                        hasDeal: _hasDeal,
                        hasOrders: _hasOrders,
                        daysWithoutActivity: _daysWithoutActivity,
                        directoryValues: _directoryValues,
                      ));
                      //print('LeadScreen: FetchLeads dispatched for statusId: $newStatusId (no cached data found)');
                    } else {
                      //print('LeadScreen: Using cached data for statusId: $newStatusId');
                    }
                  } else {
                    // Если нет состояния LeadDataLoaded, загружаем данные
                    currentLeadBloc.add(FetchLeads(
                      newStatusId,
                      salesFunnelId: _selectedFunnel?.id,
                      ignoreCache: false,
                    ));
                    //print('LeadScreen: FetchLeads dispatched for statusId: $newStatusId (no LeadDataLoaded state)');
                  }
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
  void _scrollToActiveTab() {
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null && tabScrollController.hasClients) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;

      if (position.dx < 0 || (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
        double targetOffset = tabScrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);

        tabScrollController.animateTo(
          targetOffset,
          duration: Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      }
    }
  }

  @override
  void dispose() {
    tabScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

