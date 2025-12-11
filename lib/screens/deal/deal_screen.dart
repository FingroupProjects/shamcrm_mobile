import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/deal_name_list.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/deal/deal_status_delete.dart';
import 'package:crm_task_manager/screens/deal/deal_status_edit.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_card.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_column.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_add.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
  bool _isManager = false;

  final TextEditingController _searchController = TextEditingController();
  bool _canReadDealStatus = false;
  bool _canCreateDealStatus = false;
  bool _canUpdateDealStatus = false;
  bool _canDeleteDealStatus = false;
  final ApiService _apiService = ApiService();
  bool navigateToEnd = false;
  bool navigateAfterDelete = false;
  int? _deletedIndex;
  List<int>? _selectedManagerIds;
  int? _selectedManagerId;
  late final DealBloc _dealBloc;

  bool _showCustomTabBar = true;
  bool _isFilterLoading = false;
  bool _shouldShowLoader = false;
  bool _skipNextTabListener = false; // КРИТИЧНО: Флаг для пропуска TabListener при фильтрации
  String _lastSearchQuery = "";

  List<ManagerData> _selectedManagers = [];
  List<LeadData> _selectedLeads = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _daysWithoutActivity;
  bool? _hasTasks = false;
  List<Map<String, dynamic>> _selectedDirectoryValues = [];
  Map<String, List<String>>? _selectedDealCustomFieldFilters;

  List<ManagerData> _initialselectedManagers = [];

  List<LeadData> _initialselectedLeads = [];
  int? _initialSelStatus;
  DateTime? _intialFromDate;
  DateTime? _intialToDate;
  bool? _initialHasTasks;
  int? _initialDaysWithoutActivity;
  List<Map<String, dynamic>> _initialDirectoryValues = [];
  List<DealNameData> _initialSelectedDealNames = [];
  List<DealNameData> _selectedDealNames = [];
  final GlobalKey keySearchIcon = GlobalKey();
  final GlobalKey keyMenuIcon = GlobalKey();

  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isDealScreenTutorialCompleted = false;
  Map<String, dynamic>? tutorialProgress;
  SalesFunnel? _selectedFunnel;

 @override
void initState() {
  super.initState();
  debugPrint('🔧 DealScreen: initState started');
  
  // ← КРИТИЧНО: Инициализируем пустой TabController
  _tabController = TabController(length: 0, vsync: this);
  
  _dealBloc = context.read<DealBloc>();
  context.read<GetAllManagerBloc>().add(GetAllManagerEv());
  context.read<SalesFunnelBloc>().add(FetchSalesFunnels());

  _scrollController = ScrollController();
  _scrollController.addListener(_onScroll);
  // НЕ загружаем состояние фильтров - каждый раз начинаем с чистого листа
  _checkPermissions();

  _apiService.getSelectedDealSalesFunnel().then((funnelId) {
    debugPrint('🔍 DealScreen: Loaded saved funnelId: $funnelId');
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

      // Просто загружаем статусы, listener будет создан в BlocListener
      _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
    }
  });
}

  Future<void> _onRefresh(int currentStatusId) async {
    try {
      await DealCache.clearAllData();
      await DealCache.clearPersistentCounts();

      if (mounted) {
        setState(() {
          _isSearching = false;
          _lastSearchQuery = '';
          _searchController.clear();
          _showCustomTabBar = true;
          _isFilterLoading = false;
          _shouldShowLoader = false;

          _selectedManagers.clear();
          _selectedLeads.clear();
          _selectedStatuses = null;
          _fromDate = null;
          _toDate = null;
          _hasTasks = false;
          _daysWithoutActivity = null;
          _selectedDirectoryValues.clear();
          _selectedDealNames.clear();
          _selectedDealCustomFieldFilters = null;

          _initialselectedManagers.clear();
          _initialselectedLeads.clear();
          _initialSelStatus = null;
          _intialFromDate = null;
          _intialToDate = null;
          _initialHasTasks = false;
          _initialDaysWithoutActivity = null;
          _initialDirectoryValues.clear();
          _initialSelectedDealNames.clear();

          _tabTitles.clear();
          _tabKeys.clear();
          _currentTabIndex = 0;

          if (_tabController.length > 0) {
            _tabController.dispose();
          }
          _tabController = TabController(length: 0, vsync: this);
        });
      }

      final dealBloc = BlocProvider.of<DealBloc>(context);
      await dealBloc.clearAllCountsAndCache();
      dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id, forceRefresh: true));

    } catch (e) {
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

        final dealBloc = BlocProvider.of<DealBloc>(context);
        dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id, forceRefresh: false));
      }
    }
  }


 Widget _buildTitleWidget(BuildContext context) {
  return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
    builder: (context, state) {
      String title = AppLocalizations.of(context)!.translate('appbar_deals');
      SalesFunnel? selectedFunnel;

      if (state is SalesFunnelLoaded) {
        selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
        _selectedFunnel = selectedFunnel;
        if (selectedFunnel != null) {
          title = selectedFunnel.name;
        }
      }
      // Если Loading или Error — просто оставляем "Сделки", без паники

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
                onSelected: (SalesFunnel funnel) async {
                  try {
                    await _apiService.saveSelectedDealSalesFunnel(funnel.id.toString());
                    await DealCache.clearAllDeals();
                    await DealCache.clearCache();
                    _resetFilters();

                    setState(() {
                      _selectedFunnel = funnel;
                      _isSearching = false;
                      _searchController.clear();
                      _lastSearchQuery = '';
                    });

                    context.read<SalesFunnelBloc>().add(SelectSalesFunnel(funnel));
                    setState(() {
                      _tabTitles.clear();
                      _tabController = TabController(length: 0, vsync: this);
                    });
                    _dealBloc.add(FetchDealStatuses(salesFunnelId: funnel.id));
                  } catch (e) {
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
  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedManagers =
          (jsonDecode(prefs.getString('deal_selected_managers') ?? '[]')
                  as List)
              .map((m) => ManagerData.fromJson(m))
              .toList();
      _selectedLeads =
          (jsonDecode(prefs.getString('deal_selected_leads') ?? '[]') as List)
              .map((l) => LeadData.fromJson(l))
              .toList();
      _selectedStatuses = prefs.getInt('deal_selected_statuses');
      
      // Безопасный парсинг дат
      final fromDateStr = prefs.getString('deal_from_date');
      _fromDate = (fromDateStr != null && fromDateStr.isNotEmpty && fromDateStr != 'null')
          ? DateTime.tryParse(fromDateStr)
          : null;
      
      final toDateStr = prefs.getString('deal_to_date');
      _toDate = (toDateStr != null && toDateStr.isNotEmpty && toDateStr != 'null')
          ? DateTime.tryParse(toDateStr)
          : null;
      
      _daysWithoutActivity = prefs.getInt('deal_days_without_activity');
      _hasTasks = prefs.getBool('deal_has_tasks') ?? false;
      _selectedDirectoryValues =
          (jsonDecode(prefs.getString('deal_selected_directory_values') ?? '[]')
                  as List)
              .map((d) => Map<String, dynamic>.from(d))
              .toList();
      _selectedDealNames =
          (jsonDecode(prefs.getString('deal_selected_names') ?? '[]') as List)
              .map((name) => DealNameData(id: 0, title: name))
              .toList();
      _initialselectedManagers = List.from(_selectedManagers);
      _initialselectedLeads = List.from(_selectedLeads);
      _initialSelStatus = _selectedStatuses;
      _intialFromDate = _fromDate;
      _intialToDate = _toDate;
      _initialHasTasks = _hasTasks;
      _initialDaysWithoutActivity = _daysWithoutActivity;
      _initialDirectoryValues = List.from(_selectedDirectoryValues);
      _initialSelectedDealNames = List.from(_selectedDealNames);
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deal_selected_managers',
        jsonEncode(_selectedManagers.map((m) => m.toJson()).toList()));
    await prefs.setString('deal_selected_leads',
        jsonEncode(_selectedLeads.map((l) => l.toJson()).toList()));
    await prefs.setInt('deal_selected_statuses', _selectedStatuses ?? 0);
    await prefs.setString('deal_from_date', _fromDate?.toIso8601String() ?? '');
    await prefs.setString('deal_to_date', _toDate?.toIso8601String() ?? '');
    await prefs.setInt('deal_days_without_activity', _daysWithoutActivity ?? 0);
    await prefs.setBool('deal_has_tasks', _hasTasks ?? false);
    await prefs.setString(
        'deal_selected_directory_values', jsonEncode(_selectedDirectoryValues));
    await prefs.setString(
        'deal_selected_names',
        jsonEncode(
            _selectedDealNames.map((dealName) => dealName.title).toList()));
  }

  // Метод для проверки наличия активных фильтров
  bool _hasActiveFilters() {
    return _selectedManagers.isNotEmpty ||
        _selectedLeads.isNotEmpty ||
        _selectedStatuses != null ||
        _fromDate != null ||
        _toDate != null ||
        _hasTasks == true ||
        _daysWithoutActivity != null ||
        _selectedDirectoryValues.isNotEmpty ||
        _selectedDealNames.isNotEmpty ||
        (_selectedDealCustomFieldFilters != null && _selectedDealCustomFieldFilters!.isNotEmpty);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final dealBloc = BlocProvider.of<DealBloc>(context);
      if (dealBloc.state is DealDataLoaded) {
        final state = dealBloc.state as DealDataLoaded;
        if (!dealBloc.allDealsFetched && _tabTitles.isNotEmpty && _currentTabIndex < _tabTitles.length) {
          final currentStatusId = _tabTitles[_currentTabIndex]['id'];
          dealBloc.add(FetchMoreDeals(currentStatusId, state.currentPage));
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initTutorialTargets() {
    targets.clear();
    targets.addAll([
      createTarget(
        identify: "DealSearchIcon",
        keyTarget: keySearchIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_task_screen_search_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_deal_screen_search_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "DealMenuIcon",
        keyTarget: keyMenuIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_task_screen_menu_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_deal_screen_menu_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
    ]);
  }

  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('dealStatus.read');
    final canCreate = await _apiService.hasPermission('dealStatus.create');
    final canUpdate = await _apiService.hasPermission('dealStatus.update');
    final canDelete = await _apiService.hasPermission('dealStatus.delete');
    setState(() {
      _canReadDealStatus = canRead;
      _canCreateDealStatus = canCreate;
      _canUpdateDealStatus = canUpdate;
      _canDeleteDealStatus = canDelete;
    });

    try {
      final progress = await _apiService.getTutorialProgress();
      if (progress is Map<String, dynamic> &&
          progress['result'] is Map<String, dynamic>) {
        setState(() {
          tutorialProgress = progress['result'];
        });
      } else {
        setState(() {
          tutorialProgress = null;
        });
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isTutorialShown =
          prefs.getBool('isTutorialShownDealSearchIconAppBar') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });

      if (tutorialProgress != null &&
          tutorialProgress!['deals']?['index'] == false &&
          !_isTutorialShown &&
          mounted) {
        _initTutorialTargets();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            //showTutorial();
          }
        });
      } else {
        ////debugPrint('DealScreen: Tutorial not shown. Reasons:');
        ////debugPrint('tutorialProgress: $tutorialProgress');
        ////debugPrint('deals/index: ${tutorialProgress?['deals']?['index']}');
        ////debugPrint('isTutorialShown: $_isTutorialShown');
      }
    } catch (e) {
      ////debugPrint('DealScreen: Error fetching tutorial progress: $e');
    }
  }

  void showTutorial() async {
    if (_isTutorialShown) {
      ////debugPrint('DealScreen: Tutorial already shown, skipping');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(milliseconds: 500));

    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
        ],
      ),
      colorShadow: Color(0xff1E2E52),
      onSkip: () {
        ////debugPrint('DealScreen: Tutorial skipped');
        prefs.setBool('isTutorialShownDealSearchIconAppBar', true);
        setState(() {
          _isTutorialShown = true;
          _isDealScreenTutorialCompleted = true;
        });
        return true;
      },
      onFinish: () {
        ////debugPrint('DealScreen: Tutorial finished');
        prefs.setBool('isTutorialShownDealSearchIconAppBar', true);
        setState(() {
          _isTutorialShown = true;
          _isDealScreenTutorialCompleted = true;
        });
      },
    ).show(context: context);
  }

  Future<void> _searchDeals(String query, int currentStatusId) async {
    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true;
      });
    }

    await DealCache.clearDealsForStatus(currentStatusId);
    
    _dealBloc.add(FetchDeals(
      currentStatusId,
      query: query,
      managerIds: _selectedManagers.isNotEmpty
          ? _selectedManagers.map((manager) => manager.id).toList()
          : null,
      leadIds: _selectedLeads.isNotEmpty
          ? _selectedLeads.map((lead) => lead.id).toList()
          : null,
      statusIds: _selectedStatuses,
      fromDate: _fromDate,
      toDate: _toDate,
      daysWithoutActivity: _daysWithoutActivity,
      hasTasks: _hasTasks,
      directoryValues: _selectedDirectoryValues.isNotEmpty
          ? _selectedDirectoryValues
          : null,
      names: _selectedDealNames.isNotEmpty
          ? _selectedDealNames.map((dealName) => dealName.title).toList()
          : null,
      salesFunnelId: _selectedFunnel?.id,
      customFieldFilters: _selectedDealCustomFieldFilters,
    ));
  }

  void _resetFilters() {
    if (mounted) {
      setState(() {
        _showCustomTabBar = true;
        _isSearching = false;
        _selectedManagers = [];
        _selectedLeads = [];
        _selectedStatuses = null;
        _fromDate = null;
        _toDate = null;
        _hasTasks = false;
        _daysWithoutActivity = null;
        _selectedDirectoryValues = [];
        _selectedDealNames = [];
        _selectedDealCustomFieldFilters = null;
        _initialselectedManagers = [];
        _initialselectedLeads = [];
        _initialSelStatus = null;
        _intialFromDate = null;
        _intialToDate = null;
        _lastSearchQuery = '';
        _searchController.clear();
        _initialHasTasks = false;
        _initialDaysWithoutActivity = null;
        _initialDirectoryValues = [];
        _initialSelectedDealNames = [];
      });
    }

    final dealBloc = BlocProvider.of<DealBloc>(context);
    dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
  }

Future<void> _handleManagerSelected(Map managers) async {
  debugPrint('DealScreen: _handleManagerSelected - START WITH NEW LOGIC');
  
  if (mounted) {
    setState(() {
      _isFilterLoading = true;
      _shouldShowLoader = true;
      _showCustomTabBar = true;
      _skipNextTabListener = true; // ← КРИТИЧНО: Пропускаем следующий TabListener!
      _isSearching = false;
      _searchController.clear();
      _lastSearchQuery = '';

      _selectedManagers = managers['managers'] ?? [];
      _selectedLeads = managers['leads'] ?? [];
      _selectedStatuses = managers['statuses'];
      _fromDate = managers['fromDate'];
      _toDate = managers['toDate'];
      _hasTasks = managers['hasTask'];
      _daysWithoutActivity = managers['daysWithoutActivity'];
      _selectedDealNames = (managers['names'] as List?)?.map((name) => DealNameData(id: 0, title: name)).toList() ?? [];
      _selectedDirectoryValues = (managers['directory_values'] as List?)
              ?.map((item) => {
                    'directory_id': item['directory_id'],
                    'entry_id': item['entry_id'],
                  })
              .toList() ??
          [];
      final Map<String, dynamic>? rawCustom = managers['custom_field_filters'] as Map<String, dynamic>?;
      _selectedDealCustomFieldFilters = rawCustom?.map((k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()));

      // Сохраняем initial значения
      _initialselectedManagers = managers['managers'] ?? [];
      _initialselectedLeads = managers['leads'] ?? [];
      _initialSelStatus = managers['statuses'];
      _intialFromDate = managers['fromDate'];
      _intialToDate = managers['toDate'];
      _initialHasTasks = managers['hasTask'];
      _initialDaysWithoutActivity = managers['daysWithoutActivity'];
      _initialDirectoryValues = List.from(_selectedDirectoryValues);
      _initialSelectedDealNames = List.from(_selectedDealNames);
    });
  }

  await Future.delayed(Duration(milliseconds: 50));

  _dealBloc.add(FetchDealStatusesWithFilters(
    managerIds: _selectedManagers.isNotEmpty
        ? _selectedManagers.map((manager) => manager.id).toList()
        : null,
    leadIds: _selectedLeads.isNotEmpty
        ? _selectedLeads.map((lead) => lead.id).toList()
        : null,
    statusIds: _selectedStatuses,
    fromDate: _fromDate,
    toDate: _toDate,
    hasTasks: _hasTasks,
    daysWithoutActivity: _daysWithoutActivity,
    directoryValues: _selectedDirectoryValues.isNotEmpty ? _selectedDirectoryValues : null,
    names: _selectedDealNames.isNotEmpty 
        ? _selectedDealNames.map((dealName) => dealName.title).toList()
        : null,
    salesFunnelId: _selectedFunnel?.id,
    customFieldFilters: _selectedDealCustomFieldFilters,
  ));

  debugPrint('DealScreen: _handleManagerSelected - Dispatched FetchDealStatusesWithFilters');
}

  Future _handleStatusSelected(int? selectedStatusId) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatusId;
      _initialSelStatus = selectedStatusId;
    });

    if (_tabTitles.isEmpty || _currentTabIndex >= _tabTitles.length) return;
    
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _dealBloc.add(FetchDeals(
      currentStatusId,
      statusIds: _selectedStatuses,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
      salesFunnelId: _selectedFunnel?.id,
      customFieldFilters: _selectedDealCustomFieldFilters,
    ));
  }

  Future _handleDateSelected(DateTime? fromDate, DateTime? toDate) async {
    setState(() {
      _showCustomTabBar = false;
      _fromDate = fromDate;
      _toDate = toDate;
      _intialFromDate = fromDate;
      _intialToDate = toDate;
    });

    if (_tabTitles.isEmpty || _currentTabIndex >= _tabTitles.length) return;
    
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _dealBloc.add(FetchDeals(
      currentStatusId,
      fromDate: _fromDate,
      toDate: _toDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
      salesFunnelId: _selectedFunnel?.id,
      customFieldFilters: _selectedDealCustomFieldFilters,
    ));
  }

  Future _handleStatusAndDateSelected(
      int? selectedStatus, DateTime? fromDate, DateTime? toDate) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatus;
      _fromDate = fromDate;
      _toDate = toDate;
      _initialSelStatus = selectedStatus;
      _intialFromDate = fromDate;
      _intialToDate = toDate;
    });

    if (_tabTitles.isEmpty || _currentTabIndex >= _tabTitles.length) return;
    
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _dealBloc.add(FetchDeals(
      currentStatusId,
      statusIds: _selectedStatuses,
      fromDate: _fromDate,
      toDate: _toDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
      salesFunnelId: _selectedFunnel?.id,
      customFieldFilters: _selectedDealCustomFieldFilters,
    ));
  }

  void _onSearch(String query) {
    _lastSearchQuery = query;
    if (_tabTitles.isEmpty || _currentTabIndex >= _tabTitles.length) return;
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchDeals(query, currentStatusId);
  }

  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();
  ValueChanged<String>? onChangedSearchInput;

  bool isClickAvatarIcon = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    ////debugPrint('DealScreen: Building widget tree');
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dealBloc),
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
              setState(() {
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
            onManagersDealSelected: _handleManagerSelected,
            onStatusDealSelected: _handleStatusSelected,
            onDateRangeDealSelected: _handleDateSelected,
            onStatusAndDateRangeDealSelected: _handleStatusAndDateSelected,
            initialManagersDeal: _initialselectedManagers,
            initialLeadsDeal: _initialselectedLeads,
            initialManagerDealStatuses: _initialSelStatus,
            initialManagerDealFromDate: _intialFromDate,
            initialManagerDealToDate: _intialToDate,
            initialManagerDealDaysWithoutActivity: _initialDaysWithoutActivity,
            initialManagerDealHasTasks: _initialHasTasks,
            initialDirectoryValuesDeal: _initialDirectoryValues,
            initialDealNames: _initialSelectedDealNames
                .map((dealName) => dealName.title)
                .toList(), // Передаем начальные имена
            onDealResetFilters: _resetFilters,
            textEditingController: textEditingController,
            focusNode: focusNode,
            showMenuIcon: _showCustomTabBar,
            showFilterIconOnSelectDeal: !_showCustomTabBar,
            hasActiveDealFilters: _hasActiveFilters(),
            showFilterTaskIcon: false,
            showFilterIcon: false,
            showFilterIconDeal: true,
            showEvent: true,
            showMyTaskIcon: true,
            showCallCenter: true,
            clearButtonClick: (value) {
              if (value == false) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _lastSearchQuery = '';
                });
                if (_searchController.text.isEmpty) {
                  if (_selectedManagers.isEmpty &&
                      _selectedStatuses == null &&
                      _fromDate == null &&
                      _toDate == null &&
                      _selectedLeads.isEmpty &&
                      _hasTasks == false &&
                      _daysWithoutActivity == null &&
                      _selectedDealNames.isEmpty) {
                    ////debugPrint("DealScreen: IF SEARCH EMPTY AND NO FILTERS");
                    setState(() {
                      _showCustomTabBar = true;
                    });
                    _dealBloc.add(
                        FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
                  } else {
                    if (_tabTitles.isEmpty || _currentTabIndex >= _tabTitles.length) return;
                    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                    _dealBloc.add(FetchDeals(
                      currentStatusId,
                      managerIds: _selectedManagers.isNotEmpty
                          ? _selectedManagers
                              .map((manager) => manager.id)
                              .toList()
                          : null,
                      statusIds: _selectedStatuses,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      daysWithoutActivity: _daysWithoutActivity,
                      hasTasks: _hasTasks,
                      leadIds: _selectedLeads.isNotEmpty
                          ? _selectedLeads.map((lead) => lead.id).toList()
                          : null,
                      salesFunnelId: _selectedFunnel?.id,
                    ));
                  }
                } else if (_selectedManagerIds != null &&
                    _selectedManagerIds!.isNotEmpty) {
                  if (_tabTitles.isEmpty || _currentTabIndex >= _tabTitles.length) return;
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  _dealBloc.add(FetchDeals(
                    currentStatusId,
                    managerIds: _selectedManagerIds,
                    query: _searchController.text.isNotEmpty
                        ? _searchController.text
                        : null,
                    salesFunnelId: _selectedFunnel?.id,
                    customFieldFilters: _selectedDealCustomFieldFilters,
                  ));
                }
              }
            },
            clearButtonClickFiltr: (value) {},
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : Column(
                children: [
                  const SizedBox(height: 15),
                  if (!_isSearching && _showCustomTabBar)
                    _buildCustomTabBar(),
                  Expanded(
                    child: _isSearching || _hasActiveFilters()
                        ? _buildManagerView()
                        : _buildTabBarView(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget searchWidget(List<Deal> deals) {
    final currentStatusId = _tabTitles.isNotEmpty && _currentTabIndex < _tabTitles.length
        ? _tabTitles[_currentTabIndex]['id']
        : 0;

    if (_isFilterLoading || _shouldShowLoader) {
      return const Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }

    if (_isSearching && deals.isEmpty) {
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
    } else if (_isManager && deals.isEmpty) {
      return Center(
        child: Text(
          'У выбранного менеджера нет сделок',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    } else if (deals.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('nothing_deal_for_manager'),
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
        controller: _scrollController,
        itemCount: deals.length,
        itemBuilder: (context, index) {
          final deal = deals[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DealCard(
              deal: deal,
              title: deal.dealStatus?.title ?? "",
              statusId: deal.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusDealId) {
                final index = _tabTitles.indexWhere(
                        (status) => status['id'] == StatusDealId);
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
    return BlocListener<DealBloc, DealState>(
      listener: (context, state) {
        debugPrint('DealScreen: _buildManagerView listener - state: ${state.runtimeType}');
        // Сбрасываем флаги когда данные загружены или произошла ошибка
        if ((state is DealDataLoaded || state is DealError) &&
            mounted &&
            (_isFilterLoading || _shouldShowLoader)) {
          debugPrint('DealScreen: _buildManagerView - Resetting loader flags');
          setState(() {
            _isFilterLoading = false;
            _shouldShowLoader = false;
          });
        }
      },
      child: BlocBuilder<DealBloc, DealState>(
        builder: (context, state) {
          // Безопасное получение currentStatusId
          final currentStatusId = _tabTitles.isNotEmpty && _tabController.index < _tabTitles.length
              ? _tabTitles[_tabController.index]['id']
              : 0;

          // Показываем лоадер только если флаги активны ИЛИ состояние - DealLoading
          if (_shouldShowLoader || _isFilterLoading || state is DealLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          }

          if (state is DealDataLoaded) {
            final List<Deal> deals = state.deals;
            
            // Безопасное получение statusId
            final statusId = _tabTitles.isNotEmpty && _tabController.index < _tabTitles.length
                ? _tabTitles[_tabController.index]['id']
                : (deals.isNotEmpty ? deals.first.statusId : 0);
            
            final filteredDeals = deals
                .where((deal) => deal.statusId == statusId)
                .toList();

            if (filteredDeals.isEmpty) {
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
                          .translate('no_manager_in_deal')
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
                itemCount: filteredDeals.length,
                itemBuilder: (context, index) {
                  final deal = filteredDeals[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: DealCard(
                      deal: deal,
                      title: deal.dealStatus?.title ?? "",
                      statusId: deal.statusId,
                      onStatusUpdated: () {},
                      onStatusId: (StatusDealId) {
                        final index = _tabTitles.indexWhere(
                                (status) => status['id'] == StatusDealId);
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

          // Если состояние DealError - показываем ошибку
          if (state is DealError) {
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
          if (_canCreateDealStatus)
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
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => CreateStatusDialog(),
    );

    if (result == true) {
      _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
      setState(() {
        navigateToEnd = true;
      });
    }
  }

  void _showStatusOptions(BuildContext context, int index) {
    final RenderBox renderBox =
        _tabKeys[index].currentContext!.findRenderObject() as RenderBox;
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
        if (_canUpdateDealStatus)
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
        if (_canDeleteDealStatus)
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
        _showEditDealStatusDialog(index);
      } else if (value == 'delete') {
        _showDeleteDialog(index);
      }
    });
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return FutureBuilder<int>(
      future: DealCache.getPersistentDealCount(_tabTitles[index]['id']),
      builder: (context, snapshot) {
        // Сначала пробуем получить count из постоянного кэша
        int dealCount = snapshot.data ?? 0;

        // Если в постоянном кэше нет данных, пробуем другие источники
        if (dealCount == 0) {
          return BlocBuilder<DealBloc, DealState>(
            builder: (context, state) {
              // Используем данные из состояния только если нет постоянного счетчика
              if (state is DealLoaded) {
                final statusId = _tabTitles[index]['id'];
                final dealStatus = state.dealStatuses.firstWhere(
                  (status) => status.id == statusId,
                  orElse: () => DealStatus(
                    id: 0,
                    title: '',
                    color: '#000000',
                    dealsCount: 0,
                    isSuccess: false,
                    isFailure: false,
                    showOnMainPage: false,
                  ),
                );
                dealCount = dealStatus.dealsCount ?? 0;

                // Сразу сохраняем в постоянный кэш
                DealCache.setPersistentDealCount(statusId, dealCount);
              } else if (state is DealDataLoaded && state.dealCounts.containsKey(_tabTitles[index]['id'])) {
                dealCount = state.dealCounts[_tabTitles[index]['id']] ?? 0;

                // Сразу сохраняем в постоянный кэш
                DealCache.setPersistentDealCount(_tabTitles[index]['id'], dealCount);
              }

              return _buildTabButtonUI(index, isActive, dealCount);
            },
          );
        }

        // Если есть постоянный счетчик, используем его напрямую
        return _buildTabButtonUI(index, isActive, dealCount);
      },
    );
  }

  // Вспомогательный метод для построения UI кнопки табы
  Widget _buildTabButtonUI(int index, bool isActive, int dealCount) {
    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
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
                color: isActive
                    ? TaskStyles.activeColor
                    : TaskStyles.inactiveColor,
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
                    color: isActive
                        ? const Color(0xff1E2E52)
                        : const Color(0xff99A4BA),
                    width: 1,
                  ),
                ),
                child: Text(
                  dealCount.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.black : const Color(0xff99A4BA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showEditDealStatusDialog(int index) {
    final dealStatus = _tabTitles[index];
    ////debugPrint("DealScreen: Showing edit dialog for status: $dealStatus");
    showDialog(
      context: context,
      builder: (context) => EditDealStatusScreen(
        dealStatusId: dealStatus['id'],
      ),
    ).then((_) {
      _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
    });
  }

  void _showDeleteDialog(int index) async {
    final dealStatusId = _tabTitles[index]['id'];
    ////debugPrint("DealScreen: Showing delete dialog for status: $dealStatusId");

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteDealStatusDialog(dealStatusId: dealStatusId);
      },
    );

    if (result != null && result) {
      setState(() {
        _deletedIndex = _currentTabIndex;
        navigateAfterDelete = true;
        _tabTitles.removeAt(index);
        _tabKeys.removeAt(index);
        _tabController = TabController(length: _tabTitles.length, vsync: this);
        _currentTabIndex = 0;
        _isSearching = false;
        _searchController.clear();
        ////debugPrint("DealScreen: After delete: TabTitles: $_tabTitles");
      });

      if (_tabTitles.isEmpty) {
        await DealCache.clearAllDeals();
        await DealCache.clearCache();
      }

      _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<DealBloc, DealState>(
      listener: (context, state) async {
        debugPrint('DealScreen: _buildTabBarView listener - state: ${state.runtimeType}');
        
        // Сбрасываем флаги загрузки когда получены данные
        if (state is DealDataLoaded || state is DealError) {
          if (mounted && _isFilterLoading) {
            debugPrint('DealScreen: _buildTabBarView - Resetting loader flags');
            setState(() {
              _isFilterLoading = false;
              _shouldShowLoader = false;
            });
          }
        }
        
        if (state is DealLoaded) {
          await DealCache.cacheDealStatuses(state.dealStatuses
              .map((status) => {
                    'id': status.id,
                    'title': status.title,
                    'deals_count': status.dealsCount,
                  })
              .toList());

          if (mounted) {
            setState(() {
              // Обновляем табы с новыми данными
              _tabTitles = state.dealStatuses
                  .where((status) => _canReadDealStatus)
                  .map((status) => {
                        'id': status.id,
                        'title': status.title,
                        'deals_count': status.dealsCount,
                      })
                  .toList();
              _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

              if (_tabTitles.isNotEmpty) {
                // Проверяем, нужно ли создавать новый контроллер
                bool needNewController = _tabController.length != _tabTitles.length;

                if (needNewController) {
                  // Dispose старого контроллера если он существует
                  if (_tabController.length > 0) {
                    _tabController.dispose();
                  }

                  // Создаем новый контроллер
                  _tabController = TabController(length: _tabTitles.length, vsync: this);
                  
                  // ← КРИТИЧНО: Добавляем listener ТОЛЬКО при создании нового контроллера!
                  _tabController.addListener(() {
                  if (!_tabController.indexIsChanging) {
                    // ← КРИТИЧНО: Проверяем флаг пропуска!
                    if (_skipNextTabListener) {
                      debugPrint('DealScreen: TabController listener - SKIPPED (filter just applied)');
                      setState(() {
                        _skipNextTabListener = false;
                        _currentTabIndex = _tabController.index;
                      });
                      return; // ← ВЫХОДИМ БЕЗ ЗАПРОСА!
                    }

                    debugPrint('DealScreen: TabController listener triggered, new index: ${_tabController.index}');
                    setState(() {
                      _currentTabIndex = _tabController.index;
                    });
                    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                    if (_scrollController.hasClients) {
                      _scrollToActiveTab();
                    }

                    bool hasActiveFilters = _hasActiveFilters();

                    _dealBloc.add(FetchDeals(
                      currentStatusId,
                      salesFunnelId: _selectedFunnel?.id,
                      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,

                      managerIds: hasActiveFilters && _selectedManagers.isNotEmpty
                          ? _selectedManagers.map((manager) => manager.id).toList()
                          : null,
                      leadIds: hasActiveFilters && _selectedLeads.isNotEmpty
                          ? _selectedLeads.map((lead) => lead.id).toList()
                          : null,
                      statusIds: hasActiveFilters ? currentStatusId : null,
                      fromDate: hasActiveFilters ? _fromDate : null,
                      toDate: hasActiveFilters ? _toDate : null,
                      hasTasks: hasActiveFilters ? _hasTasks : null,
                      daysWithoutActivity: hasActiveFilters ? _daysWithoutActivity : null,
                      directoryValues: hasActiveFilters && _selectedDirectoryValues.isNotEmpty
                          ? _selectedDirectoryValues
                          : null,
                      names: hasActiveFilters && _selectedDealNames.isNotEmpty
                          ? _selectedDealNames.map((dealName) => dealName.title).toList()
                          : null,
                      customFieldFilters: hasActiveFilters ? _selectedDealCustomFieldFilters : null,
                    ));

                    debugPrint('DealScreen: FetchDeals dispatched for statusId: $currentStatusId');
                  }
                  }); // ← Закрываем listener здесь, только для нового контроллера!
                }

                // Установка правильного индекса
                if (needNewController) {
                  if (_currentTabIndex < _tabTitles.length && _currentTabIndex >= 0) {
                    _tabController.index = _currentTabIndex;
                  } else {
                    _tabController.index = 0;
                    _currentTabIndex = 0;
                  }
                } else {
                  int initialIndex = state.dealStatuses
                      .indexWhere((status) => status.id == widget.initialStatusId);
                  if (initialIndex != -1 && initialIndex != _currentTabIndex) {
                    _tabController.index = initialIndex;
                    _currentTabIndex = initialIndex;
                  } else if (_tabTitles.isNotEmpty) {
                    int safeIndex = _currentTabIndex < _tabTitles.length ? _currentTabIndex : 0;
                    _tabController.index = safeIndex;
                    _currentTabIndex = safeIndex;
                  }
                }

                // Прокручиваем к активному табу
                if (_scrollController.hasClients) {
                  _scrollToActiveTab();
                }

                // Обрабатываем специальные навигации
                if (navigateToEnd) {
                  navigateToEnd = false;
                  Future.delayed(Duration(milliseconds: 100), () {
                    if (mounted && _tabTitles.isNotEmpty) {
                      _tabController.animateTo(_tabTitles.length - 1);
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
                      }
                    });
                  }
                }

                // Автоматически загружаем сделки для активного статуса после refresh
                Future.delayed(Duration(milliseconds: 150), () {
                  if (mounted && _tabTitles.isNotEmpty && _currentTabIndex < _tabTitles.length) {
                    final activeStatusId = _tabTitles[_currentTabIndex]['id'];

                    final bool hasActiveFilters = _hasActiveFilters();

                    if (!hasActiveFilters) {
                      _dealBloc.add(FetchDeals(
                        activeStatusId,
                        salesFunnelId: _selectedFunnel?.id,
                      ));
                    } else {
                      debugPrint('DealScreen: Skip auto FetchDeals due to active filters');
                    }
                  }
                });

              } else {
                // Если табы пустые, создаем пустой контроллер
                if (_tabController.length > 0) {
                  _tabController.dispose();
                }
                _tabController = TabController(length: 0, vsync: this);
                _currentTabIndex = 0;
              }
            });
          }
        } else if (state is DealError) {
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
            // ✅ УБРАНО: Не показываем непереведенный SnackBar с кнопкой "Повторить"
            // Переведенные сообщения показываются в других местах
            if (kDebugMode) {
              debugPrint('DealScreen: Error state - ${state.message}');
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
          return RefreshIndicator(
            onRefresh: () => _onRefresh(status['id']),
            color: const Color(0xff1E2E52),
            backgroundColor: Colors.white,
            child: DealColumn(
              isDealScreenTutorialCompleted: _isDealScreenTutorialCompleted,
              statusId: status['id'],
              title: status['title'],
              salesFunnelId: _selectedFunnel?.id,
              onStatusId: (newStatusId) {
                final index = _tabTitles.indexWhere((s) => s['id'] == newStatusId);
                if (index != -1) {
                  _tabController.animateTo(index);

                  // Проверяем, есть ли уже данные для этого статуса
                  final currentDealBloc = context.read<DealBloc>();
                  if (currentDealBloc.state is DealDataLoaded) {
                    final currentState = currentDealBloc.state as DealDataLoaded;
                    final hasDealsForStatus = currentState.deals.any((deal) => deal.statusId == newStatusId);

                    // Загружаем только если нет данных для этого статуса
                    if (!hasDealsForStatus) {
                      currentDealBloc.add(FetchDeals(
                        newStatusId,
                        salesFunnelId: _selectedFunnel?.id,
                        query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
                        managerIds: _selectedManagers.isNotEmpty
                            ? _selectedManagers.map((manager) => manager.id).toList()
                            : null,
                        leadIds: _selectedLeads.isNotEmpty
                            ? _selectedLeads.map((lead) => lead.id).toList()
                            : null,
                        statusIds: _selectedStatuses,
                        fromDate: _fromDate,
                        toDate: _toDate,
                        hasTasks: _hasTasks,
                        daysWithoutActivity: _daysWithoutActivity,
                        directoryValues: _selectedDirectoryValues,
                        names: _selectedDealNames.isNotEmpty
                            ? _selectedDealNames.map((dealName) => dealName.title).toList()
                            : null,
                        customFieldFilters: _selectedDealCustomFieldFilters,
                      ));
                    }
                  } else {
                    // Если нет состояния DealDataLoaded, загружаем данные
                    currentDealBloc.add(FetchDeals(
                      newStatusId,
                      salesFunnelId: _selectedFunnel?.id,
                    ));
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
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;

      if (position.dx < 0 ||
          (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
        double targetOffset = _scrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);
        if (targetOffset != _scrollController.offset) {
          _scrollController.animateTo(
            targetOffset,
            duration: Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      }
    }
  }
}
