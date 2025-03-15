import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/source_list/source_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
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
  bool _canDeleteLeadStatus = false;
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
  bool? _hasDeal = false;
  int? _daysWithoutActivity;

  List<ManagerData> _initialselectedManagers = [];
  List<RegionData> _initialselectedRegions = [];
  List<SourceData> _initialselectedSources = [];
  int? _initialSelStatus;
  DateTime? _intialFromDate;
  DateTime? _intialToDate;
  bool? _initialHasSuccessDeals;
  bool? _initialHasInProgressDeals;
  bool? _initialHasFailureDeals;
  bool? _initialHasNotices;
  bool? _initialHasContact;
  bool? _initialHasChat;
  bool? _initialHasDeal;
  int? _initialDaysWithoutActivity;
  List<int>? _selectedManagerIds;

  final GlobalKey keySearchIcon = GlobalKey();
  final GlobalKey keyMenuIcon = GlobalKey();

List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isLeadScreenTutorialCompleted = false;
  Map<String, dynamic>? tutorialProgress;

 @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    context.read<GetAllSourceBloc>().add(GetAllSourceEv());
    _scrollController = ScrollController();
    
    LeadCache.getLeadStatuses().then((cachedStatuses) {
      if (cachedStatuses.isNotEmpty) {
        setState(() {    
          _tabTitles = cachedStatuses
              .map((status) => {'id': status['id'], 'title': status['title']})
              .toList();
          _tabController = TabController(length: _tabTitles.length, vsync: this);
          _tabController.index = _currentTabIndex;

          _tabController.addListener(() {
            setState(() {
              _currentTabIndex = _tabController.index;
            });
            _scrollToActiveTab();
          });
        });
      } else {
        final leadBloc = BlocProvider.of<LeadBloc>(context);
        leadBloc.add(FetchLeadStatuses());
      }
    });

    LeadCache.getLeadsForStatus(widget.initialStatusId).then((cachedLeads) {
      if (cachedLeads.isNotEmpty) {
        print('Leads loaded from cache.');
      }
    });
    _checkPermissions();
  }

  void _initTutorialTargets() {
    targets.clear();
    targets.addAll([
      createTarget(
        identify: "LeadSearchIcon",
        keyTarget: keySearchIcon,
        title: AppLocalizations.of(context)!.translate('tutorial_task_screen_search_title'), 
        description: AppLocalizations.of(context)!.translate('tutorial_lead_screen_search_description'), 
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "LeadMenuIcon",
        keyTarget: keyMenuIcon,
        title: AppLocalizations.of(context)!.translate('tutorial_task_screen_menu_title'), 
        description: AppLocalizations.of(context)!.translate('tutorial_lead_screen_menu_description'), 
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
    ]);
  }

  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('leadStatus.read');
    final canCreate = await _apiService.hasPermission('leadStatus.create');
    final canDelete = await _apiService.hasPermission('leadStatus.delete');
    setState(() {
      _canReadLeadStatus = canRead;
      _canCreateLeadStatus = canCreate;
      _canDeleteLeadStatus = canDelete;
    });

    try {
      final progress = await _apiService.getTutorialProgress();
      print('Tutorial Progress for leads: $progress');
      
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
      bool isTutorialShown = prefs.getBool('isTutorialShownLeadSearchIconAppBar') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });

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
      } else {
        print('Tutorial not shown for LeadScreen. Reasons:');
        print('tutorialProgress: $tutorialProgress');
        print('leads/index: ${tutorialProgress?['leads']?['index']}');
        print('isTutorialShown: $_isTutorialShown');
      }
    } catch (e) {
      print('Error fetching tutorial progress: $e');
    }
  }

  void showTutorial() async {
    if (_isTutorialShown) {
      print('Tutorial already shown for LeadScreen, skipping');
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
        print('Tutorial skipped for LeadScreen');
        prefs.setBool('isTutorialShownLeadSearchIconAppBar', true);
        setState(() {
          _isTutorialShown = true;
          _isLeadScreenTutorialCompleted = true; // Устанавливаем флаг для LeadColumn
        });
        return true;
      },
      onFinish: () {
        print('Tutorial finished for LeadScreen');
        prefs.setBool('isTutorialShownLeadSearchIconAppBar', true);
        setState(() {
          _isTutorialShown = true;
          _isLeadScreenTutorialCompleted = true; // Устанавливаем флаг для LeadColumn
        });
      },
    ).show(context: context);
  }
  
  Future<void> _searchLeads(String query, int currentStatusId) async {
    final leadBloc = BlocProvider.of<LeadBloc>(context);

    await LeadCache.clearAllLeads();
    print('ПОИСК+++++++++++++++++++++++++++++++++++++++++++++++');

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
      hasDeal: _hasDeal,
      daysWithoutActivity: _daysWithoutActivity,
    ));
  }

  void _resetFilters() {
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
      _hasDeal = false;
      _daysWithoutActivity = null;
      _initialselectedManagers = [];
      _initialselectedRegions = [];
      _initialselectedSources = [];
      _initialSelStatus = null;
      _intialFromDate = null;
      _intialToDate = null;
      _initialHasSuccessDeals = false;
      _initialHasInProgressDeals = false;
      _initialHasFailureDeals = false;
      _initialHasNotices = false;
      _initialHasContact = false;
      _initialHasChat = false;
      _initialHasDeal = false;
      _initialDaysWithoutActivity = null;
      _lastSearchQuery = '';
      _searchController.clear();
    });
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatuses());
  }

  Future<void> _handleManagerSelected(Map managers) async {
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
      _hasDeal = managers['hasDeal'];
      _daysWithoutActivity = managers['daysWithoutActivity'];

      _initialselectedManagers = managers['managers'];
      _initialselectedRegions = managers['regions'];
      _initialselectedSources = managers['sources'];
      _initialSelStatus = managers['statuses'];
      _intialFromDate = managers['fromDate'];
      _intialToDate = managers['toDate'];
      _initialHasSuccessDeals = managers['hasSuccessDeals'];
      _initialHasInProgressDeals = managers['hasInProgressDeals'];
      _initialHasFailureDeals = managers['hasFailureDeals'];
      _initialHasNotices = managers['hasNotices'];
      _initialHasContact = managers['hasContact'];
      _initialHasChat = managers['hasChat'];
      _initialHasDeal = managers['hasDeal'];
      _initialDaysWithoutActivity = managers['daysWithoutActivity'];
    });

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
      hasDeal: _hasDeal,
      daysWithoutActivity: _daysWithoutActivity,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  void _onSearch(String query) {
    _lastSearchQuery = query;
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchLeads(query, currentStatusId);
  }

  // Метод для проверки разрешений
  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();
  ValueChanged<String>? onChangedSearchInput;

  bool isClickAvatarIcon = false;
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          SearchIconKey: keySearchIcon,
          menuIconKey: keyMenuIcon,
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('appbar_leads'),
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
          onManagersLeadSelected: _handleManagerSelected,
          initialManagersLead: _initialselectedManagers,
          initialManagersLeadRegions: _initialselectedRegions,
          initialManagersLeadSources: _initialselectedSources,
          initialManagerLeadStatuses: _initialSelStatus,
          initialManagerLeadFromDate: _intialFromDate,
          initialManagerLeadToDate: _intialToDate,
          initialManagerLeadHasSuccessDeals: _initialHasSuccessDeals,
          initialManagerLeadHasInProgressDeals: _initialHasInProgressDeals,
          initialManagerLeadHasFailureDeals: _initialHasFailureDeals,
          initialManagerLeadHasNotices: _initialHasNotices,
          initialManagerLeadHasContact: _initialHasContact,
          initialManagerLeadHasChat: _initialHasChat,
          initialManagerLeadHasDeal: _initialHasDeal,
          initialManagerLeadDaysWithoutActivity: _initialDaysWithoutActivity,
          onLeadResetFilters: _resetFilters,
          textEditingController: textEditingController,
          focusNode: focusNode,
          showMenuIcon: _showCustomTabBar,
          showFilterIconOnSelectLead: !_showCustomTabBar,
          showFilterTaskIcon: false,
          showMyTaskIcon: true,
          showFilterIconDeal: false,
          showEvent: true,
          clearButtonClick: (value) {
            if (value == false) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _lastSearchQuery = '';
              });
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
                    _hasDeal == false) {
                  print("IF SEARCH EMPTY AND NO FILTERS");
                  setState(() {
                    _showCustomTabBar = true;
                  });
                  final taskBloc = BlocProvider.of<LeadBloc>(context);
                  taskBloc.add(FetchLeadStatuses());
                } else {
                  print("IF SEARCH EMPTY BUT FILTERS EXIST");
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  final taskBloc = BlocProvider.of<LeadBloc>(context);
                  taskBloc.add(FetchLeads(
                    currentStatusId,
                    managerIds: _selectedManagers.isNotEmpty
                        ? _selectedManagers
                            .map((manager) => manager.id)
                            .toList()
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
                    hasDeal: _hasDeal,
                    daysWithoutActivity: _daysWithoutActivity,
                  ));
                }
              } else if (_selectedManagerIds != null &&
                  _selectedManagerIds!.isNotEmpty) {
                print("ELSE IF SEARCH NOT EMPTY");

                final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                final taskBloc = BlocProvider.of<LeadBloc>(context);
                taskBloc.add(FetchLeads(
                  currentStatusId,
                  managerIds: _selectedManagerIds,
                  query: _searchController.text.isNotEmpty
                      ? _searchController.text
                      : null,
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
                if (!_isSearching &&
                    _selectedManagerIds == null &&
                    _showCustomTabBar)
                  _buildCustomTabBar(),
                Expanded(
                  child: _isSearching || _selectedManagerIds != null
                      ? _buildManagerView()
                      : _buildTabBarView(),
                ),
              ],
            ),
    );
  }

  Widget searchWidget(List<Lead> leads) {
    // Если идёт поиск и ничего не найдено
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
    }
    // Если это менеджер и список лидов пуст
    else if (_isManager && leads.isEmpty) {
      return Center(
        child: Text(
          'У выбранного менеджера нет лидов',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }
    // Если лидов вообще нет
    else if (leads.isEmpty) {
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
    // Если лиды есть, показываем список
    return Flexible(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          print('Отображение лида: $lead');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LeadCard(
              lead: lead,
              title: lead.leadStatus?.title ?? "",
              statusId: lead.statusId,
              onStatusUpdated: () {
                print('Статус лида обновлён');
              },
              onStatusId: (StatusLeadId) {
                print('onStatusId вызван с id: $StatusLeadId');
              },
            ),
          );
        },
      ),
    );
  }

// Обновляем метод _buildManagerView для корректной обработки обоих случаев
  Widget _buildManagerView() {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        if (state is LeadDataLoaded) {
          final List<Lead> leads = state.leads;

          // Filtrujeme podle vybraného statusu
          final statusId = _tabTitles[_tabController.index]['id'];
          final filteredLeads =
              leads.where((lead) => lead.statusId == statusId).toList();

          if (filteredLeads.isEmpty) {
            return Center(
              child: Text(
                _selectedManagers != null
                    ? AppLocalizations.of(context)!
                        .translate('selected_manager_has_any_lead')
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

          return Flexible(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredLeads.length,
              itemBuilder: (context, index) {
                final lead = filteredLeads[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      context.read<LeadBloc>().add(FetchLeadStatuses());

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
            // orElse: () => 1,
          );
          leadCount = leadStatus?.leadsCount ?? 0; // Используем leadsCount
        }

        return GestureDetector(
          key: _tabKeys[index],
          onTap: () {
            _tabController.animateTo(index);
          },
          onLongPress: () {
            if (_canDeleteLeadStatus) {
              _showStatusOptions(context, index);
            }
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      leadCount.toString(),
                      style: TextStyle(
                        color:
                            isActive ? Colors.black : const Color(0xff99A4BA),
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
    // Вызываем вашу существующую логику удаления
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

      context.read<LeadBloc>().add(FetchLeadStatuses());
    }
  }

  void _editLeadStatus(int index) {
    // Extract lead status data if needed for editing
    final leadStatus = _tabTitles[
        index]; // Assuming _tabTitles holds the relevant data for the lead

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditLeadStatusScreen(
          leadStatusId: leadStatus['id'], // Pass the lead status ID for editing
        );
      },
    );
  }

  Widget _buildTabBarView() {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) async {
        if (state is LeadLoaded) {
          await LeadCache.cacheLeadStatuses(state.leadStatuses
              .map((status) => {'id': status.id, 'title': status.title})
              .toList());
          setState(() {
            _tabTitles = state.leadStatuses
                .where((status) => _canReadLeadStatus)
                .map((status) => {'id': status.id, 'title': status.title})
                .toList();

            _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

            if (_tabTitles.isNotEmpty) {
              _tabController =
                  TabController(length: _tabTitles.length, vsync: this);
              _tabController.addListener(() {
                setState(() {
                  _currentTabIndex = _tabController.index;
                });
                final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                if (_scrollController.hasClients) {
                  _scrollToActiveTab();
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

              //Логика для перехода к созданн статусе
              if (navigateToEnd) {
                navigateToEnd = false;
                if (_tabController != null) {
                  _tabController.animateTo(_tabTitles.length - 1);
                }
              }

              //Логика для перехода к после удаления статусе на лево
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

              // Сохраняем данные в кеш
              // LeadCache.cacheLeadStatuses(_tabTitles);
            }
          });
        } else if (state is LeadError) {
          if (state.message.contains(
              AppLocalizations.of(context)!.translate('unauthorized_access'))) {
            ApiService apiService = ApiService();
            await apiService.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
            );
          } else if (state.message.contains(AppLocalizations.of(context)!
              .translate('no_internet_connection'))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate(state.message), // Локализация сообщения
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
      child: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          // print('state: ${state.runtimeType}');
          if (state is LeadDataLoaded) {
            final List<Lead> leads = state.leads;
            print(leads);
            return searchWidget(leads);
          }
          if (state is LeadLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is LeadLoaded) {
            if (_tabTitles.isEmpty) {
              return const Center(child: Text(''));
            }
            return TabBarView(
              controller: _tabController,
              children: List.generate(_tabTitles.length, (index) {
                final statusId = _tabTitles[index]['id'];
                final title = _tabTitles[index]['title'];
                return LeadColumn(
                  isLeadScreenTutorialCompleted: _isLeadScreenTutorialCompleted,
                  statusId: statusId,
                  title: title,
                  onStatusId: (newStatusId) {
                    print('Status ID changed: $newStatusId');
                    final index = _tabTitles
                        .indexWhere((status) => status['id'] == newStatusId);

                    if (index != -1) {
                      _tabController.animateTo(index);
                    }
                  },
                );
              }),
            );
          }
          return const SizedBox();
        },
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
