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
  late ScrollController _scrollController;
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
  int? _daysWithoutActivity;
  List<Map<String, dynamic>> _directoryValues = [];
  List<Map<String, dynamic>> _initialDirectoryValues = [];

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

  @override
  void initState() {
    super.initState();
    print('LeadScreen: initState started');
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    context.read<GetAllSourceBloc>().add(GetAllSourceEv());
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
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
                  });
                  _scrollToActiveTab();
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  context.read<LeadBloc>().add(FetchLeads(
                    currentStatusId,
                    salesFunnelId: _selectedFunnel?.id,
                    ignoreCache: true,
                  ));
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

  Future<void> _loadFeatureState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitch = prefs.getBool('switchContact') ?? false;
      print('LeadScreen: _loadFeatureState - _isSwitch set to: $_isSwitch');
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final leadBloc = BlocProvider.of<LeadBloc>(context);
      if (leadBloc.state is LeadDataLoaded) {
        final state = leadBloc.state as LeadDataLoaded;
        if (!leadBloc.allLeadsFetched) {
          final currentStatusId = _tabTitles[_currentTabIndex]['id'];
          leadBloc.add(FetchMoreLeads(
            currentStatusId,
            state.currentPage,
          ));
        }
      }
    }
  }

  Future<void> _onRefresh(int currentStatusId) async {
    print('LeadScreen: _onRefresh called for statusId: $currentStatusId');
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    await LeadCache.clearLeadsForStatus(currentStatusId);
    print('LeadScreen: _onRefresh - Cleared cache for statusId: $currentStatusId');
    leadBloc.add(FetchLeads(
      currentStatusId,
      salesFunnelId: _selectedFunnel?.id,
      ignoreCache: true,
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
      daysWithoutActivity: _daysWithoutActivity,
      directoryValues: _directoryValues,
    ));
    print('LeadScreen: _onRefresh - FetchLeads dispatched for statusId: $currentStatusId');
  }

  void _initTutorialTargets() {
    targets.clear();
    targets.addAll([
      createTarget(
        identify: "LeadSearchIcon",
        keyTarget: keySearchIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_task_screen_search_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_lead_screen_search_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "LeadMenuIcon",
        keyTarget: keyMenuIcon,
        title: AppLocalizations.of(context)!
            .translate('tutorial_task_screen_menu_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_lead_screen_menu_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "FloatingActionButton",
        keyTarget: keyFloatingActionButton,
        title: AppLocalizations.of(context)!.translate('tutorial_lead_button_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_lead_button_description'),
        align: ContentAlign.top,
        context: context,
      ),
    ]);
  }

  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('leadStatus.read');
    final canCreate = await _apiService.hasPermission('leadStatus.create');
    final canUpdate = await _apiService.hasPermission('leadStatus.update');
    final canDelete = await _apiService.hasPermission('leadStatus.delete');
    if (mounted) {
      setState(() {
        _canReadLeadStatus = canRead;
        _canCreateLeadStatus = canCreate;
        _canUpdateLeadStatus = canUpdate;
        _canDeleteLeadStatus = canDelete;
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
        _initTutorialTargets();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showTutorial();
          }
        });
      }
    } catch (e) {
      print('LeadScreen: Error fetching tutorial progress: $e');
    }
  }

  void showTutorial() async {
    if (_isTutorialShown) {
      print('LeadScreen: Tutorial already shown for LeadScreen, skipping');
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
        print('LeadScreen: Tutorial skipped for LeadScreen');
        prefs.setBool('isTutorialShownLeadSearchIconAppBar', true);
        if (mounted) {
          setState(() {
            _isTutorialShown = true;
            _isLeadScreenTutorialCompleted = true;
          });
        }
        return true;
      },
      onFinish: () {
        print('LeadScreen: Tutorial finished for LeadScreen');
        prefs.setBool('isTutorialShownLeadSearchIconAppBar', true);
        if (mounted) {
          setState(() {
            _isTutorialShown = true;
            _isLeadScreenTutorialCompleted = true;
          });
        }
      },
    ).show(context: context);
  }

  Future<void> _searchLeads(String query, int currentStatusId) async {
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    await LeadCache.clearLeadsForStatus(currentStatusId);
    print('LeadScreen: Searching leads with query: $query');
    leadBloc.add(FetchLeads(
      currentStatusId,
      query: query,
      managerIds: _selectedManagers.map((manager) => manager.id).toList(),
      regionsIds: _selectedRegions.map((region) => region.id).toList(),
      sourcesIds: _selectedSources.map((sources) => sources.id).toList(),
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
      daysWithoutActivity: _daysWithoutActivity,
      directoryValues: _directoryValues,
      salesFunnelId: _selectedFunnel?.id,
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
        _daysWithoutActivity = null;
        _directoryValues = [];
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
        _initialDaysWithoutActivity = null;
        _initialDirectoryValues = [];
        _lastSearchQuery = '';
        _searchController.clear();
      });
    }
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatuses());
  }

  Future<void> _handleManagerSelected(Map managers) async {
    if (mounted) {
      setState(() {
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
        _daysWithoutActivity = managers['daysWithoutActivity'];
        _directoryValues = managers['directory_values'] ?? [];
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
        _initialDaysWithoutActivity = managers['daysWithoutActivity'];
        _initialDirectoryValues = managers['directory_values'] ?? [];
      });
    }

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
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
      daysWithoutActivity: _daysWithoutActivity,
      directoryValues: _directoryValues,
      salesFunnelId: _selectedFunnel?.id,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
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
    print('LeadScreen: Entering _buildTitleWidget');
    return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
      builder: (context, state) {
        print('LeadScreen: _buildTitleWidget - Current SalesFunnelBloc state: $state');
        String title = AppLocalizations.of(context)!.translate('appbar_leads');
        SalesFunnel? selectedFunnel;
        if (state is SalesFunnelLoading) {
          print('LeadScreen: _buildTitleWidget - State is SalesFunnelLoading');
          title = AppLocalizations.of(context)!.translate('appbar_leads');
        } else if (state is SalesFunnelLoaded) {
          print('LeadScreen: _buildTitleWidget - State is SalesFunnelLoaded, funnels: ${state.funnels}, selectedFunnel: ${state.selectedFunnel}');
          selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
          _selectedFunnel = selectedFunnel;
          print('LeadScreen: _buildTitleWidget - Selected funnel set to: $selectedFunnel');
          title = selectedFunnel?.name ?? AppLocalizations.of(context)!.translate('appbar_leads');
          print('LeadScreen: _buildTitleWidget - Title set to: $title');
        } else if (state is SalesFunnelError) {
          print('LeadScreen: _buildTitleWidget - State is SalesFunnelError: ${state.message}');
          title = 'Ошибка загрузки';
        } else {
          print('LeadScreen: _buildTitleWidget - Unexpected state: $state');
        }
        print('LeadScreen: _buildTitleWidget - Rendering title: $title');
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
                    print('LeadScreen: _buildTitleWidget - Selected new funnel: ${funnel.name} (ID: ${funnel.id})');
                    try {
                      setState(() {
                        _isSwitchingFunnel = true;
                        print('LeadScreen: _buildTitleWidget - _isSwitchingFunnel set to true');
                      });
                      await _apiService.saveSelectedSalesFunnel(funnel.id.toString());
                      print('LeadScreen: _buildTitleWidget - Saved funnel ID ${funnel.id} to SharedPreferences');
                      await LeadCache.clearAllLeads();
                      await LeadCache.clearCache();
                      print('LeadScreen: _buildTitleWidget - Cleared lead cache and statuses');
                      _resetFilters();
                      print('LeadScreen: _buildTitleWidget - Reset filters');
                      if (mounted) {
                        setState(() {
                          _selectedFunnel = funnel;
                          _isSearching = false;
                          _searchController.clear();
                          _lastSearchQuery = '';
                          print('LeadScreen: _buildTitleWidget - Updated _selectedFunnel: $_selectedFunnel, cleared search');
                        });
                      }
                      context.read<SalesFunnelBloc>().add(SelectSalesFunnel(funnel));
                      await Future.delayed(Duration(milliseconds: 100));
                      if (mounted) {
                        setState(() {
                          _tabTitles.clear();
                          _tabController = TabController(length: 0, vsync: this);
                        });
                      }
                      context.read<LeadBloc>().add(FetchLeadStatuses());
                    } catch (e) {
                      print('LeadScreen: Error switching funnel: $e');
                      setState(() {
                        _isSwitchingFunnel = false;
                      });
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
                    print('LeadScreen: _buildTitleWidget - Building PopupMenu with funnels: ${state.funnels}');
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

  @override
  Widget build(BuildContext context) {
    print('LeadScreen: Building widget tree, _tabTitles: $_tabTitles, _currentTabIndex: $_currentTabIndex');
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
              print('LeadScreen: Profile avatar clicked, isClickAvatarIcon: $isClickAvatarIcon');
              if (mounted) {
                setState(() {
                  isClickAvatarIcon = !isClickAvatarIcon;
                });
              }
            },
            onChangedSearchInput: (String value) {
              print('LeadScreen: Search input changed: $value');
              if (value.isNotEmpty) {
                if (mounted) {
                  setState(() {
                    _isSearching = true;
                  });
                }
                print('LeadScreen: Search mode activated');
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
            initialManagerLeadDaysWithoutActivity: _initialDaysWithoutActivity,
            initialDirectoryValuesLead: _initialDirectoryValues,
            onLeadResetFilters: _resetFilters,
            textEditingController: textEditingController,
            focusNode: focusNode,
            showMenuIcon: _showCustomTabBar,
            showFilterIconOnSelectLead: !_showCustomTabBar,
            showFilterTaskIcon: false,
            showMyTaskIcon: true,
            showCallCenter: true,
            showFilterIconDeal: false,
            showEvent: true,
            clearButtonClick: (value) {
              print('LeadScreen: Clear button clicked, isSearching: $value');
              if (value == false) {
                if (mounted) {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _lastSearchQuery = '';
                    print('LeadScreen: Search cleared, resetting state');
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
                      _directoryValues.isEmpty) {
                    if (mounted) {
                      setState(() {
                        _showCustomTabBar = true;
                      });
                    }
                    print('LeadScreen: Showing custom tab bar after clear');
                    final taskBloc = BlocProvider.of<LeadBloc>(context);
                    taskBloc.add(FetchLeadStatuses());
                    print('LeadScreen: FetchLeadStatuses dispatched after clear');
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
                      daysWithoutActivity: _daysWithoutActivity,
                      directoryValues: _directoryValues,
                      salesFunnelId: _selectedFunnel?.id,
                    ));
                    print('LeadScreen: FetchLeads dispatched with filters after clear, salesFunnelId: ${_selectedFunnel?.id}');
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
                  print('LeadScreen: FetchLeads dispatched with managerIds after clear, salesFunnelId: ${_selectedFunnel?.id}');
                }
              }
            },
            clearButtonClickFiltr: (value) {
              print('LeadScreen: Filter clear button clicked: $value');
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
        floatingActionButton: _tabTitles.isNotEmpty
            ? FloatingActionButton(
                key: keyFloatingActionButton,
                onPressed: () {
                  print('LeadScreen: FloatingActionButton pressed');
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
    final currentStatusId = _tabTitles.isNotEmpty ? _tabTitles[_currentTabIndex]['id'] : 0;
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
          AppLocalizations.of(context)!.translate('no_leads_for_selected_manager'),
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
          AppLocalizations.of(context)!.translate('nothing_lead_for_manager'),
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
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LeadCard(
              lead: lead,
              title: lead.leadStatus?.title ?? "",
              statusId: lead.statusId,
              onStatusUpdated: () {
                print('LeadScreen: Lead status updated');
              },
              onStatusId: (StatusLeadId) {
                print('LeadScreen: onStatusId called with id: $StatusLeadId');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildManagerView() {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        final currentStatusId = _tabTitles.isNotEmpty ? _tabTitles[_tabController.index]['id'] : 0;
        if (state is LeadDataLoaded) {
          final List<Lead> leads = state.leads;
          final statusId = _tabTitles[_tabController.index]['id'];
          final filteredLeads = leads.where((lead) => lead.statusId == statusId).toList();

          if (filteredLeads.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _onRefresh(currentStatusId),
              color: const Color(0xff1E2E52),
              backgroundColor: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Text(
                    _selectedManagers != null
                        ? AppLocalizations.of(context)!.translate('selected_manager_has_any_lead')
                        : AppLocalizations.of(context)!.translate('nothing_found'),
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
              controller: _scrollController,
              itemCount: filteredLeads.length,
              itemBuilder: (context, index) {
                final lead = filteredLeads[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LeadCard(
                    lead: lead,
                    title: lead.leadStatus?.title ?? "",
                    statusId: lead.statusId,
                    onStatusUpdated: () {},
                    onStatusId: (StatusLeadId) {},
                  ),
                );
              },
            ),
          );
        }
        if (state is LeadLoading) {
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

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        int leadCount = 0;

        if (state is LeadLoaded) {
          final statusId = _tabTitles[index]['id'];
          final leadStatus = state.leadStatuses.firstWhere(
            (status) => status.id == statusId,
            orElse: () => LeadStatus(
                id: 0, title: '', leadsCount: 0, isSuccess: false, position: 1, isFailure: false),
          );
          leadCount = leadStatus.leadsCount ?? 0;
        }

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
      },
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
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) async {
        if (state is LeadLoaded) {
          await LeadCache.cacheLeadStatuses(
              state.leadStatuses.map((status) => {'id': status.id, 'title': status.title}).toList());
          if (mounted) {
            setState(() {
              _tabTitles = state.leadStatuses
                  .where((status) => _canReadLeadStatus)
                  .map((status) => {'id': status.id, 'title': status.title})
                  .toList();
              _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
              _isSwitchingFunnel = false;
              print('LeadScreen: _buildTabBarView - _isSwitchingFunnel set to false, statuses loaded');

              if (_tabTitles.isNotEmpty) {
                _tabController = TabController(length: _tabTitles.length, vsync: this);
                _tabController.addListener(() {
                  if (!_tabController.indexIsChanging) {
                    setState(() {
                      _currentTabIndex = _tabController.index;
                    });
                    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                    if (_scrollController.hasClients) {
                      _scrollToActiveTab();
                    }
                    context.read<LeadBloc>().add(FetchLeads(
                      currentStatusId,
                      salesFunnelId: _selectedFunnel?.id,
                      ignoreCache: true,
                    ));
                  }
                });
                int initialIndex = state.leadStatuses
                    .indexWhere((status) => status.id == widget.initialStatusId);
                if (initialIndex != -1) {
                  _tabController.index = initialIndex;
                  _currentTabIndex = initialIndex;
                } else {
                  _tabController.index = _currentTabIndex;
                }

                if (_scrollController.hasClients) {
                  _scrollToActiveTab();
                }

                if (navigateToEnd) {
                  navigateToEnd = false;
                  _tabController.animateTo(_tabTitles.length - 1);
                }

                if (navigateAfterDelete) {
                  navigateAfterDelete = false;
                  if (_deletedIndex != null) {
                    if (_deletedIndex == 0 && _tabTitles.length > 1) {
                      _tabController.animateTo(1);
                    } else if (_deletedIndex == _tabTitles.length) {
                      _tabController.animateTo(_tabTitles.length - 1);
                    } else {
                      _tabController.animateTo(_deletedIndex! - 1);
                    }
                  }
                }
              }
            });
          }
        } else if (state is LeadError) {
          setState(() {
            _isSwitchingFunnel = false;
          });
          if (state.message.contains(AppLocalizations.of(context)!.translate('unauthorized_access'))) {
            ApiService apiService = ApiService();
            await apiService.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
            );
          } else if (state.message.contains(
              AppLocalizations.of(context)!.translate('no_internet_connection'))) {
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
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: Stack(
        children: [
          BlocBuilder<LeadBloc, LeadState>(
            builder: (context, state) {
              if (_tabTitles.isEmpty && !_isSwitchingFunnel) {
                return RefreshIndicator(
                  onRefresh: () => _onRefresh(0),
                  color: const Color(0xff1E2E52),
                  backgroundColor: Colors.white,
                  child: const Center(
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Text(''),
                    ),
                  ),
                );
              }
              if (state is LeadDataLoaded) {
                return RefreshIndicator(
                  onRefresh: () => _onRefresh(_tabTitles[_currentTabIndex]['id']),
                  color: const Color(0xff1E2E52),
                  backgroundColor: Colors.white,
                  child: searchWidget(state.leads),
                );
              }
              if (state is LeadLoading && !_isSwitchingFunnel) {
                return const Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              }
              return TabBarView(
                controller: _tabController,
                children: _tabTitles.map((status) {
                  return RefreshIndicator(
                    onRefresh: () => _onRefresh(status['id']),
                    color: const Color(0xff1E2E52),
                    backgroundColor: Colors.white,
                    child: LeadColumn(
                      isLeadScreenTutorialCompleted: _isLeadScreenTutorialCompleted,
                      statusId: status['id'],
                      title: status['title'],
                      onStatusId: (newStatusId) {
                        print('LeadScreen: onStatusId called with id: $newStatusId');
                        final index =
                            _tabTitles.indexWhere((status) => status['id'] == newStatusId);
                        if (index != -1) {
                          _tabController.animateTo(index);
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (_isSwitchingFunnel)
            const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            ),
        ],
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