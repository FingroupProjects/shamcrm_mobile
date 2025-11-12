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
  final ApiService _apiService = ApiService();
  bool navigateToEnd = false;
  bool navigateAfterDelete = false;
  int? _deletedIndex;
  List<int>? _selectedManagerIds;
  int? _selectedManagerId;
  late final DealBloc _dealBloc;

  bool _showCustomTabBar = true;
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
    ////print('DealScreen: initState started');
    _dealBloc = context.read<DealBloc>();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadFilterState();
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.getSelectedDealSalesFunnel().then((funnelId) {
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
        DealCache.getDealStatuses().then((cachedStatuses) {
  if (cachedStatuses.isNotEmpty && mounted) {
    setState(() {
      _tabTitles = cachedStatuses
          .map((status) => {
                'id': status['id'],
                'title': status['title'],
                'deals_count': status['deals_count'] ?? 0,
              })
          .toList();
      ////print('DealScreen: Loaded cached statuses: $_tabTitles');
      _initializeTabController();
      final currentStatusId = _tabTitles.isNotEmpty ? _tabTitles[_currentTabIndex]['id'] : 0;
      _dealBloc.add(FetchDeals(
        currentStatusId,
        salesFunnelId: _selectedFunnel?.id,
      ));
      // Запрашиваем актуальные статусы для обновления deals_count
      _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
    });
  }
}


);
        }
      });
    });
  }
// Замените существующий метод _onRefresh() в DealScreen на этот:
Future<void> _onRefresh() async {
  //print('DealScreen: Refresh triggered');
  
  // Очищаем кэш
  await DealCache.clearAllDeals();
  await DealCache.clearCache();

  // Сбрасываем состояние поиска
  setState(() {
    _isSearching = false;
    _searchController.clear();
    _lastSearchQuery = '';
  });

  // Запрашиваем обновленные данные
  _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
  
  // Простая задержка для завершения операций
  await Future.delayed(Duration(milliseconds: 500));
}

  void _initializeTabController() {
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.index = _currentTabIndex;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _scrollToActiveTab();
        final currentStatusId = _tabTitles[_currentTabIndex]['id'];
        _dealBloc.add(FetchDeals(
          currentStatusId,
          salesFunnelId: _selectedFunnel?.id,
        ));
      }
    });
  }

  Widget _buildTitleWidget(BuildContext context) {
    ////print('DealScreen: Entering _buildTitleWidget');
    return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
      builder: (context, state) {
        ////print('DealScreen: _buildTitleWidget - Current SalesFunnelBloc state: $state');
        String title = AppLocalizations.of(context)!.translate('appbar_deals');
        SalesFunnel? selectedFunnel;
        if (state is SalesFunnelLoading) {
          ////print('DealScreen: _buildTitleWidget - State is SalesFunnelLoading');
          title = AppLocalizations.of(context)!.translate('appbar_deals');
        } else if (state is SalesFunnelLoaded) {
          ////print('DealScreen: _buildTitleWidget - State is SalesFunnelLoaded, funnels: ${state.funnels}, selectedFunnel: ${state.selectedFunnel}');
          selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
          _selectedFunnel = selectedFunnel;
          ////print('DealScreen: _buildTitleWidget - Selected funnel set to: $selectedFunnel');
          title = selectedFunnel?.name ?? AppLocalizations.of(context)!.translate('appbar_deals');
          ////print('DealScreen: _buildTitleWidget - Title set to: $title');
        } else if (state is SalesFunnelError) {
          ////print('DealScreen: _buildTitleWidget - State is SalesFunnelError: ${state.message}');
          title = 'Ошибка загрузки';
        }
        ////print('DealScreen: _buildTitleWidget - Rendering title: $title');
        return Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
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
                  icon: Icon(Icons.arrow_drop_down, color: Color(0xff1E2E52)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  color: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.2),
                  offset: Offset(0, 40),
                  onSelected: (SalesFunnel funnel) async {
                    ////print('DealScreen: _buildTitleWidget - Selected new funnel: ${funnel.name} (ID: ${funnel.id})');
                    try {
                      await _apiService.saveSelectedDealSalesFunnel(funnel.id.toString());
                      ////print('DealScreen: _buildTitleWidget - Saved funnel ID ${funnel.id} to SharedPreferences');
                      await DealCache.clearAllDeals();
                      await DealCache.clearCache();
                      ////print('DealScreen: _buildTitleWidget - Cleared deal cache and statuses');
                      _resetFilters();
                      ////print('DealScreen: _buildTitleWidget - Reset filters');
                      setState(() {
                        _selectedFunnel = funnel;
                        _isSearching = false;
                        _searchController.clear();
                        _lastSearchQuery = '';
                        ////print('DealScreen: _buildTitleWidget - Updated _selectedFunnel: $_selectedFunnel, cleared search');
                      });
                      context.read<SalesFunnelBloc>().add(SelectSalesFunnel(funnel));
                      setState(() {
                        _tabTitles.clear();
                        _tabController = TabController(length: 0, vsync: this);
                      });
                      _dealBloc.add(FetchDealStatuses(salesFunnelId: funnel.id));
                    } catch (e) {
                      ////print('DealScreen: Error switching funnel: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ошибка при смене воронки',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    ////print('DealScreen: _buildTitleWidget - Building PopupMenu with funnels: ${state.funnels}');
                    return state.funnels
                        .map((funnel) => PopupMenuItem<SalesFunnel>(
                              value: funnel,
                              child: Text(
                                funnel.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff1E2E52),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList();
                  },
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
    _selectedManagers = (jsonDecode(prefs.getString('deal_selected_managers') ?? '[]') as List)
        .map((m) => ManagerData.fromJson(m))
        .toList();
    _selectedLeads = (jsonDecode(prefs.getString('deal_selected_leads') ?? '[]') as List)
        .map((l) => LeadData.fromJson(l))
        .toList();
    _selectedStatuses = prefs.getInt('deal_selected_statuses');
    _fromDate = prefs.getString('deal_from_date') != null
        ? DateTime.parse(prefs.getString('deal_from_date')!)
        : null;
    _toDate = prefs.getString('deal_to_date') != null
        ? DateTime.parse(prefs.getString('deal_to_date')!)
        : null;
    _daysWithoutActivity = prefs.getInt('deal_days_without_activity');
    _hasTasks = prefs.getBool('deal_has_tasks') ?? false;
    _selectedDirectoryValues = (jsonDecode(prefs.getString('deal_selected_directory_values') ?? '[]') as List)
        .map((d) => Map<String, dynamic>.from(d))
        .toList();
    _selectedDealNames = (jsonDecode(prefs.getString('deal_selected_names') ?? '[]') as List)
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
  await prefs.setString('deal_selected_managers', jsonEncode(_selectedManagers.map((m) => m.toJson()).toList()));
  await prefs.setString('deal_selected_leads', jsonEncode(_selectedLeads.map((l) => l.toJson()).toList()));
  await prefs.setInt('deal_selected_statuses', _selectedStatuses ?? 0);
  await prefs.setString('deal_from_date', _fromDate?.toIso8601String() ?? '');
  await prefs.setString('deal_to_date', _toDate?.toIso8601String() ?? '');
  await prefs.setInt('deal_days_without_activity', _daysWithoutActivity ?? 0);
  await prefs.setBool('deal_has_tasks', _hasTasks ?? false);
  await prefs.setString('deal_selected_directory_values', jsonEncode(_selectedDirectoryValues));
  await prefs.setString('deal_selected_names', jsonEncode(_selectedDealNames.map((dealName) => dealName.title).toList()));
}

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final dealBloc = BlocProvider.of<DealBloc>(context);
      if (dealBloc.state is DealDataLoaded) {
        final state = dealBloc.state as DealDataLoaded;
        if (!dealBloc.allDealsFetched) {
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
        title: AppLocalizations.of(context)!.translate('tutorial_task_screen_search_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_deal_screen_search_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "DealMenuIcon",
        keyTarget: keyMenuIcon,
        title: AppLocalizations.of(context)!.translate('tutorial_task_screen_menu_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_deal_screen_menu_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
    ]);
  }

  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('dealStatus.read');
    final canCreate = await _apiService.hasPermission('dealStatus.create');
    setState(() {
      _canReadDealStatus = canRead;
      _canCreateDealStatus = canCreate;
    });

    try {
      final progress = await _apiService.getTutorialProgress();
      if (progress is Map<String, dynamic> && progress['result'] is Map<String, dynamic>) {
        setState(() {
          tutorialProgress = progress['result'];
        });
      } else {
        setState(() {
          tutorialProgress = null;
        });
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isTutorialShown = prefs.getBool('isTutorialShownDealSearchIconAppBar') ?? false;
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
        ////print('DealScreen: Tutorial not shown. Reasons:');
        ////print('tutorialProgress: $tutorialProgress');
        ////print('deals/index: ${tutorialProgress?['deals']?['index']}');
        ////print('isTutorialShown: $_isTutorialShown');
      }
    } catch (e) {
      ////print('DealScreen: Error fetching tutorial progress: $e');
    }
  }

  void showTutorial() async {
    if (_isTutorialShown) {
      ////print('DealScreen: Tutorial already shown, skipping');
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
        ////print('DealScreen: Tutorial skipped');
        prefs.setBool('isTutorialShownDealSearchIconAppBar', true);
        setState(() {
          _isTutorialShown = true;
          _isDealScreenTutorialCompleted = true;
        });
        return true;
      },
      onFinish: () {
        ////print('DealScreen: Tutorial finished');
        prefs.setBool('isTutorialShownDealSearchIconAppBar', true);
        setState(() {
          _isTutorialShown = true;
          _isDealScreenTutorialCompleted = true;
        });
      },
    ).show(context: context);
  }

  Future<void> _searchDeals(String query, int currentStatusId) async {
    ////print('DealScreen: Searching deals with query: $query, salesFunnelId: ${_selectedFunnel?.id}');
    await DealCache.clearDealsForStatus(currentStatusId);
    _dealBloc.add(FetchDeals(
      currentStatusId,
      query: query,
      managerIds: _selectedManagers.map((manager) => manager.id).toList(),
      leadIds: _selectedLeads.map((lead) => lead.id).toList(),
      statusIds: _selectedStatuses,
      fromDate: _fromDate,
      toDate: _toDate,
      daysWithoutActivity: _daysWithoutActivity,
      hasTasks: _hasTasks,
      directoryValues: _selectedDirectoryValues,
      salesFunnelId: _selectedFunnel?.id,
      customFieldFilters: _selectedDealCustomFieldFilters,
    ));
    await _saveFilterState();
  }

void _resetFilters() {
  setState(() {
    _showCustomTabBar = true;
    _selectedManagers = [];
    _selectedLeads = [];
    _selectedStatuses = null;
    _fromDate = null;
    _toDate = null;
    _hasTasks = false;
    _daysWithoutActivity = null;
    _selectedDirectoryValues = [];
    _selectedDealNames = [];
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
  _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
}

Future<void> _handleManagerSelected(Map managers) async {
  setState(() {
    _showCustomTabBar = false;
    _selectedManagers = managers['managers'] ?? [];
    _selectedLeads = managers['leads'] ?? [];
    _selectedStatuses = managers['statuses'];
    _fromDate = managers['fromDate'];
    _toDate = managers['toDate'];
    _hasTasks = managers['hasTask'];
    _daysWithoutActivity = managers['daysWithoutActivity'];
    _selectedDealNames = (managers['names'] as List?)?.map((name) => DealNameData(id: 0, title: name)).toList() ?? [];
    _initialHasTasks = managers['hasTask'];
    _initialselectedLeads = managers['leads'] ?? [];
    _initialDaysWithoutActivity = managers['daysWithoutActivity'];
    _initialselectedManagers = managers['managers'] ?? [];
    _initialSelStatus = managers['statuses'];
    _intialFromDate = managers['fromDate'];
    _intialToDate = managers['toDate'];
    _selectedDirectoryValues = (managers['directory_values'] as List?)
            ?.map((item) => {
                  'directory_id': item['directory_id'],
                  'entry_id': item['entry_id'],
                })
            .toList() ??
        [];
    final Map<String, dynamic>? rawCustom = managers['custom_field_filters'] as Map<String, dynamic>?;
    _selectedDealCustomFieldFilters = rawCustom?.map((k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()));
    _initialDirectoryValues = List.from(_selectedDirectoryValues);
    _initialSelectedDealNames = List.from(_selectedDealNames);
  });

  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
  _dealBloc.add(FetchDeals(
    currentStatusId,
    managerIds: _selectedManagers.map((manager) => manager.id).toList(),
    statusIds: _selectedStatuses,
    fromDate: _fromDate,
    toDate: _toDate,
    hasTasks: _hasTasks,
    leadIds: _selectedLeads.map((lead) => lead.id).toList(),
    daysWithoutActivity: _daysWithoutActivity,
    query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    directoryValues: _selectedDirectoryValues,
    names: _selectedDealNames.map((dealName) => dealName.title).toList(), // Передаем names
    salesFunnelId: _selectedFunnel?.id,
    customFieldFilters: _selectedDealCustomFieldFilters,
  ));
  await _saveFilterState();
}

  Future _handleStatusSelected(int? selectedStatusId) async {
    setState(() {
      ////print("DealScreen: Handling status selection: $selectedStatusId");
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatusId;
      _initialSelStatus = selectedStatusId;
    });

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
      ////print("DealScreen: Handling date selection: from $fromDate to $toDate");
      _showCustomTabBar = false;
      _fromDate = fromDate;
      _toDate = toDate;
      _intialFromDate = fromDate;
      _intialToDate = toDate;
    });

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

  Future _handleStatusAndDateSelected(int? selectedStatus, DateTime? fromDate, DateTime? toDate) async {
    setState(() {
      ////print("DealScreen: Handling status and date selection: status $selectedStatus, from $fromDate to $toDate");
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatus;
      _fromDate = fromDate;
      _toDate = toDate;
      _initialSelStatus = selectedStatus;
      _intialFromDate = fromDate;
      _intialToDate = toDate;
    });

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
    ////print('DealScreen: Building widget tree');
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
            initialDealNames: _initialSelectedDealNames.map((dealName) => dealName.title).toList(), // Передаем начальные имена
            onDealResetFilters: _resetFilters,
            textEditingController: textEditingController,
            focusNode: focusNode,
            showMenuIcon: _showCustomTabBar,
            showFilterIconOnSelectDeal: !_showCustomTabBar,
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
                      _daysWithoutActivity == null&&
            _selectedDealNames.isEmpty) {
                    ////print("DealScreen: IF SEARCH EMPTY AND NO FILTERS");
                    setState(() {
                      _showCustomTabBar = true;
                    });
                    _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
                  } else {
                    ////print("DealScreen: IF SEARCH EMPTY BUT FILTERS EXIST");
                    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                    _dealBloc.add(FetchDeals(
                      currentStatusId,
                      managerIds: _selectedManagers.isNotEmpty
                          ? _selectedManagers.map((manager) => manager.id).toList()
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
                    customFieldFilters: _selectedDealCustomFieldFilters,
                    ));
                  }
                } else if (_selectedManagerIds != null && _selectedManagerIds!.isNotEmpty) {
                  ////print("DealScreen: ELSE IF SEARCH NOT EMPTY");
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  _dealBloc.add(FetchDeals(
                    currentStatusId,
                    managerIds: _selectedManagerIds,
                    query: _searchController.text.isNotEmpty ? _searchController.text : null,
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
                  if (!_isSearching && _selectedManagerId == null && _showCustomTabBar)
                    _buildCustomTabBar(),
                  Expanded(
                    // TODO should be checked
                    // child: _isSearching || _selectedManagerId != null
                    child: _isSearching || !_showCustomTabBar
                        ? _buildManagerView()
                        : _buildTabBarView(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget searchWidget(List<Deal> deals) {
    if (_isSearching) {
      return const Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
    if (_isManager && deals.isEmpty) {
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
    }
    if (deals.isNotEmpty) {
      return ListView.builder(
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
              onStatusUpdated: () {
                _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
              },
              onStatusId: (StatusDealId) {},
            ),
          );
        },
      );
    }
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

  Widget _buildManagerView() {
    return BlocBuilder<DealBloc, DealState>(
      builder: (context, state) {
        if (state is DealDataLoaded) {
          final List<Deal> deals = state.deals;
          if (deals.isEmpty) {
            return Center(
              child: Text(
                _selectedManagerIds?.isNotEmpty == true
                    ? AppLocalizations.of(context)!.translate('no_manager_in_deal')
                    : AppLocalizations.of(context)!.translate('nothing_found'),
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff99A4BA),
                ),
              ),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            itemCount: deals.length,
            itemBuilder: (context, index) {
              final deal = deals[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DealCard(
                  deal: deal,
                  title: deal.dealStatus?.title ?? "",
                  statusId: deal.statusId,
                  onStatusUpdated: () {
                    _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
                  },
                  onStatusId: (StatusDealId) {},
                ),
              );
            },
          );
        }
        if (state is DealLoading) {
          return const Center(
            child: PlayStoreImageLoading(
              size: 80.0,
              duration: Duration(milliseconds: 1000),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget managerWidget(List<Deal> deals) {
    if (_selectedManagerId != null && deals.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_manager_in_deals'),
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
        itemCount: deals.length,
        itemBuilder: (context, index) {
          final deal = deals[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DealCard(
              deal: deal,
              title: deal.dealStatus?.title ?? "",
              statusId: deal.statusId,
              onStatusUpdated: () {
                _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
              },
              onStatusId: (StatusDealId) {},
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
          if (_canCreateDealStatus)
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
      _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
      setState(() {
        navigateToEnd = true;
      });
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
                  _tabTitles[index]['deals_count'].toString(),
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
    ////print("DealScreen: Showing edit dialog for status: $dealStatus");
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
    ////print("DealScreen: Showing delete dialog for status: $dealStatusId");

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
        ////print("DealScreen: After delete: TabTitles: $_tabTitles");
      });

      if (_tabTitles.isEmpty) {
        await DealCache.clearAllDeals();
        await DealCache.clearCache();
      }

      _dealBloc.add(FetchDealStatuses(salesFunnelId: _selectedFunnel?.id));
    }
  }

Widget _buildTabBarView() {
  //print('🏗️ DealScreen: Rendering _buildTabBarView, _tabTitles: ${_tabTitles.length}');
  bool isFetchingStatuses = false; // Флаг для предотвращения дублирующихся запросов

  return BlocListener<DealBloc, DealState>(
    listener: (context, state) async {
      //print('📡 DealScreen: BlocListener state: ${state.runtimeType}');
      if (state is DealLoaded) {
        //print('📋 DealLoaded: statuses count: ${state.dealStatuses.length}');
        await DealCache.cacheDealStatuses(state.dealStatuses
            .map((status) => {
                  'id': status.id,
                  'title': status.title,
                  'deals_count': status.dealsCount,
                })
            .toList());
        if (mounted) {
          setState(() {
            _tabTitles = state.dealStatuses
                .where((status) => _canReadDealStatus)
                .map((status) => {
                      'id': status.id,
                      'title': status.title,
                      'deals_count': status.dealsCount,
                    })
                .toList();
            //print('DealScreen: Updated _tabTitles with deals_count: $_tabTitles');
            _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
            if (_tabTitles.isNotEmpty) {
              _tabController = TabController(length: _tabTitles.length, vsync: this);
              _tabController.addListener(() {
                if (!_tabController.indexIsChanging) {
                  //print('DealScreen: TabController listener triggered, new index: ${_tabController.index}');
                  setState(() {
                    _currentTabIndex = _tabController.index;
                  });
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  if (_scrollController.hasClients) {
                    _scrollToActiveTab();
                  }
                  _dealBloc.add(FetchDeals(
                    currentStatusId,
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
                    daysWithoutActivity: _daysWithoutActivity,
                    hasTasks: _hasTasks,
                    directoryValues: _selectedDirectoryValues,
                    customFieldFilters: _selectedDealCustomFieldFilters,
                  ));
                  //print('DealScreen: FetchDeals dispatched for statusId: $currentStatusId');
                }
              });
              int initialIndex = state.dealStatuses
                  .indexWhere((status) => status.id == widget.initialStatusId);
              if (initialIndex != -1) {
                _tabController.index = initialIndex;
                _currentTabIndex = initialIndex;
                //print('DealScreen: Set initial tab index to: $initialIndex');
              } else {
                _tabController.index = _currentTabIndex;
              }
              if (_scrollController.hasClients) {
                _scrollToActiveTab();
              }
              if (navigateToEnd) {
                navigateToEnd = false;
                _tabController.animateTo(_tabTitles.length - 1);
                //print('DealScreen: Navigated to last tab');
              }
              if (navigateAfterDelete) {
                navigateAfterDelete = false;
                if (_deletedIndex != null) {
                  if (_deletedIndex == 0 && _tabTitles.length > 1) {
                    _tabController.animateTo(1);
                    //print('DealScreen: Navigated to tab 1 after delete');
                  } else if (_deletedIndex == _tabTitles.length) {
                    _tabController.animateTo(_tabTitles.length - 1);
                    //print('DealScreen: Navigated to last tab after delete');
                  } else {
                    _tabController.animateTo(_deletedIndex! - 1);
                    //print('DealScreen: Navigated to tab ${_deletedIndex! - 1} after delete');
                  }
                }
              }
            }
          });
        }
      }  else if (state is DealError) {
        //print('❌ DealError: ${state.message}');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (state is DealWarning) {
        //print('⚠️ DealWarning: ${state.message}');
      }
    },
    child: _tabTitles.isEmpty
        ? Center(
            child: Text(
              AppLocalizations.of(context)!.translate('no_statuses_available'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff99A4BA),
              ),
            ),
          )
        : RefreshIndicator(
            color: Color(0xff1E2E52),
            backgroundColor: Colors.white,
            onRefresh: _onRefresh,
            child: TabBarView(
              controller: _tabController,
              physics: const AlwaysScrollableScrollPhysics(),
              // В методе _buildTabBarView() обновите создание DealColumn:
children: _tabTitles.map((status) {
  //print('📑 DealScreen: Building TabBarView child for status: ${status['title']}');
  return DealColumn(
    isDealScreenTutorialCompleted: _isDealScreenTutorialCompleted,
    statusId: status['id'],
    title: status['title'],
    salesFunnelId: _selectedFunnel?.id, // Передаем salesFunnelId
    onStatusId: (newStatusId) {
      //print('DealScreen: onStatusId called with id: $newStatusId');
      final index = _tabTitles.indexWhere((s) => s['id'] == newStatusId);
      if (index != -1) {
        _tabController.animateTo(index);
        //print('DealScreen: Animated to tab index: $index for statusId: $newStatusId');
        _dealBloc.add(FetchDeals(
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
          daysWithoutActivity: _daysWithoutActivity,
          hasTasks: _hasTasks,
          directoryValues: _selectedDirectoryValues,
          customFieldFilters: _selectedDealCustomFieldFilters,
        ));
        //print('DealScreen: FetchDeals dispatched for statusId: $newStatusId');
      }
    },
  );
}).toList(),
            ),
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