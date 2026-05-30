import 'dart:async';
import 'dart:convert';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/bloc/source_list/source_bloc.dart';
import 'package:crm_task_manager/models/city_model.dart';
import 'package:crm_task_manager/models/lead_filter_channel_model.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/models/advertising_campaign_model.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
import 'package:crm_task_manager/screens/lead/lead_status_edit.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/services/app_logout_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
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
  late ScrollController _tabScrollController;
  late ScrollController _listScrollController;
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
  bool _permissionsInitialized = false;
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
  RegionData? _selectedState;
  List<CityData> _selectedCities = [];
  List<SourceData> _selectedSources = [];
  List<LeadFilterChannelData> _selectedChannels = [];
  List<AdvertisingCampaignData> _selectedAdvertisingCampaigns = [];
  List<int> _selectedReasonForRefusalIds = [];
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
  int? _numberOfDaysDeal;
  List<Map<String, dynamic>> _directoryValues = [];
  List<Map<String, dynamic>> _initialDirectoryValues = [];
  Map<String, List<String>> _selectedCustomFieldFilters = {};
  Map<String, List<String>> _initialCustomFieldFilters = {};
  List<ManagerData> _initialSelectedManagers = [];
  List<RegionData> _initialSelectedRegions = [];
  RegionData? _initialSelectedState;
  List<CityData> _initialSelectedCities = [];
  List<SourceData> _initialSelectedSources = [];
  List<LeadFilterChannelData> _initialSelectedChannels = [];
  List<AdvertisingCampaignData> _initialSelectedAdvertisingCampaigns = [];
  List<int> _initialReasonForRefusalIds = [];
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
  int? _initialNumberOfDaysDeal;
  final GlobalKey keySearchIcon = GlobalKey();
  final GlobalKey keyMenuIcon = GlobalKey();
  final GlobalKey keyFloatingActionButton = GlobalKey();
  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isLeadScreenTutorialCompleted = false;
  Map<String, dynamic>? tutorialProgress;
  SalesFunnel? _selectedFunnel;
  List<int>? _selectedManagerIds;
  bool _isFilterLoading = false;
  bool _shouldShowLoader = false;
  bool _skipNextTabListener = false;
  int? _skipNextTabListenerIndex;
  PusherChannelsClient? _leadSocketClient;
  final List<StreamSubscription<dynamic>> _leadSocketSubscriptions = [];

  void _resetLeadLoaderFlags() {
    if (!mounted) return;
    setState(() {
      _isFilterLoading = false;
      _shouldShowLoader = false;
      _isSwitchingFunnel = false;
      _skipNextTabListener = false;
      _skipNextTabListenerIndex = null;
    });
  }

  Map<String, List<String>> _cloneCustomFieldFilters(
      Map<String, List<String>> source) {
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

  bool get _hasActiveCustomFieldFilters =>
      _selectedCustomFieldFilters.values.any((values) => values.isNotEmpty);

  // Метод для проверки наличия активных фильтров
  bool _hasActiveFilters() {
    return _selectedManagers.isNotEmpty ||
        _selectedRegions.isNotEmpty ||
        _selectedState != null ||
        _selectedCities.isNotEmpty ||
        _selectedSources.isNotEmpty ||
        _selectedChannels.isNotEmpty ||
        _selectedAdvertisingCampaigns.isNotEmpty ||
        _selectedReasonForRefusalIds.isNotEmpty ||
        _selectedStatuses != null ||
        _fromDate != null ||
        _toDate != null ||
        _hasSuccessDeals == true ||
        _hasInProgressDeals == true ||
        _hasFailureDeals == true ||
        _hasNotices == true ||
        _hasContact == true ||
        _hasChat == true ||
        _hasNoReplies == true ||
        _hasUnreadMessages == true ||
        _hasDeal == true ||
        _hasOrders == true ||
        _daysWithoutActivity != null ||
        _numberOfDaysDeal != null ||
        _directoryValues.isNotEmpty ||
        _hasActiveCustomFieldFilters;
  }

  @override
  void initState() {
    super.initState();

    // ← КРИТИЧНО: Инициализируем пустой TabController
    _tabController = TabController(length: 0, vsync: this);

    _initializeSalesFunnel();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    context.read<GetAllSourceBloc>().add(GetAllSourceEv());
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
    _tabScrollController = ScrollController();
    _listScrollController = ScrollController();
    _listScrollController.addListener(_onScroll);
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

        // Просто загружаем статусы, listener будет создан в BlocListener
        context.read<LeadBloc>().add(FetchLeadStatuses());
      }
    });

    _checkPermissions();
    _setupLeadSocket();
  }

  Future<void> _initializeSalesFunnel() async {
    try {
      final savedFunnelId = await _apiService.getSelectedSalesFunnel();

      if (savedFunnelId == null || savedFunnelId.isEmpty) {
        debugPrint('⚠️ No saved funnel, will use first available');
        return;
      }

      context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
    } catch (e) {
      debugPrint('❌ _initializeSalesFunnel error: $e');
    }
  }

  Future<void> _loadFeatureState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitch = prefs.getBool('switchContact') ?? false;
    });
  }

  void _onScroll() {
    if (!_listScrollController.hasClients || _tabTitles.isEmpty) return;

    final state = context.read<LeadBloc>().state;
    if (state is! LeadDataLoaded || state.isLoadingMore) return;

    final bloc = context.read<LeadBloc>();
    if (bloc.allLeadsFetched || bloc.isFetching) return;

    final threshold = _listScrollController.position.maxScrollExtent - 200;
    if (_listScrollController.position.pixels < threshold) return;

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    bloc.add(FetchMoreLeads(currentStatusId, state.currentPage));
  }

  Future<void> _setupLeadSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('unique_id');

    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      debugPrint('LeadScreen: socket init skipped, token or userId is missing');
      return;
    }

    final enteredDomainMap = await _apiService.getEnteredDomain();
    final enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    final enteredDomain = enteredDomainMap['enteredDomain'];

    if (enteredMainDomain == null ||
        enteredMainDomain.isEmpty ||
        enteredDomain == null ||
        enteredDomain.isEmpty) {
      debugPrint('LeadScreen: socket init skipped, domain is missing');
      return;
    }

    final customOptions = PusherChannelsOptions.custom(
      uriResolver: (metadata) =>
          Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    final socketClient = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint('LeadScreen: socket connection error: $exception');
        refresh();
      },
      minimumReconnectDelayDuration: const Duration(seconds: 1),
    );

    final presenceChannel = socketClient.presenceChannel(
      'presence-user.$userId',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(
          'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': '$enteredDomain-back',
        },
        onAuthFailed: (exception, trace) {
          debugPrint('LeadScreen: socket auth failed: $exception');
        },
      ),
    );

    _leadSocketSubscriptions.add(
      socketClient.onConnectionEstablished.listen((_) {
        presenceChannel.subscribeIfNotUnsubscribed();
      }),
    );

    _leadSocketSubscriptions.add(
      presenceChannel.bind('lead.created').listen((event) async {
        await _handleLeadCreatedSocketEvent(event.data);
      }),
    );

    _leadSocketClient = socketClient;

    try {
      await socketClient.connect();
    } catch (e) {
      debugPrint('LeadScreen: socket connect failed: $e');
    }
  }

  Future<void> _handleLeadCreatedSocketEvent(dynamic rawData) async {
    try {
      final payload = _decodeSocketPayload(rawData);
      final leadJson = payload['lead'];

      if (leadJson is! Map<String, dynamic>) {
        debugPrint('LeadScreen: invalid lead.created payload: $rawData');
        return;
      }

      final leadStatusId =
          int.tryParse(leadJson['lead_status_id']?.toString() ?? '') ?? 0;
      final salesFunnelId =
          int.tryParse(leadJson['sales_funnel_id']?.toString() ?? '');

      if (leadStatusId == 0) {
        debugPrint('LeadScreen: lead.created skipped, lead_status_id is empty');
        return;
      }

      if (_selectedFunnel != null &&
          salesFunnelId != null &&
          salesFunnelId != _selectedFunnel!.id) {
        return;
      }

      if (!mounted) return;

      context.read<LeadBloc>().add(
            LeadCreatedFromSocket(
              lead: Lead.fromJson(leadJson, leadStatusId),
              activeStatusId: _tabTitles.isNotEmpty
                  ? _tabTitles[_currentTabIndex]['id'] as int?
                  : null,
              hasActiveFilters: _hasActiveFilters(),
            ),
          );
    } catch (e) {
      debugPrint('LeadScreen: failed to process lead.created: $e');
    }
  }

  Map<String, dynamic> _decodeSocketPayload(dynamic rawData) {
    dynamic decoded = rawData;

    if (decoded is String) {
      decoded = json.decode(decoded);
    }

    if (decoded is Map && decoded['data'] is String) {
      decoded = json.decode(decoded['data'] as String);
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    throw const FormatException('Unsupported socket payload');
  }

  Future<void> _onRefresh(int currentStatusId) async {
    try {
      await LeadCache.clearAllData();
      await LeadCache.clearPersistentCounts();

      if (mounted) {
        setState(() {
          _isSearching = false;
          _lastSearchQuery = '';
          _searchController.clear();
          _showCustomTabBar = true;
          _isSwitchingFunnel = false;

          _selectedManagers.clear();
          _selectedRegions.clear();
          _selectedSources.clear();
          _selectedAdvertisingCampaigns.clear();
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
          _numberOfDaysDeal = null;
          _directoryValues.clear();

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
          _initialNumberOfDaysDeal = null;
          _initialDirectoryValues.clear();

          _tabTitles.clear();
          _tabKeys.clear();
          _currentTabIndex = 0;

          if (_tabController.length > 0) {
            _tabController.dispose();
          }
          _tabController = TabController(length: 0, vsync: this);
        });
      }

      final leadBloc = BlocProvider.of<LeadBloc>(context);
      await leadBloc.clearAllCountsAndCache();
      leadBloc.add(FetchLeadStatuses(forceRefresh: true));
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
        _permissionsInitialized = true;
      });
    }

    if (mounted && canRead) {
      final leadState = context.read<LeadBloc>().state;
      if (leadState is LeadInitial ||
          (leadState is LeadLoaded && _tabTitles.isEmpty)) {
        context.read<LeadBloc>().add(FetchLeadStatuses());
      }
    } else if (mounted && !canRead) {
      _resetLeadLoaderFlags();
    }

    try {
      final progress = await _apiService.getTutorialProgress();
      if (mounted) {
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
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isTutorialShown =
          prefs.getBool('isTutorialShownLeadSearchIconAppBar') ?? false;
      if (mounted) {
        setState(() {
          _isTutorialShown = isTutorialShown;
        });
      }

      if (tutorialProgress != null &&
          tutorialProgress!['leads']?['index'] == false &&
          !_isTutorialShown &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // showTutorial();
          }
        });
      }
    } catch (e) {
      debugPrint('LeadScreen: Error fetching tutorial progress: $e');
    }
  }

  Future<void> _searchLeads(String query, int currentStatusId) async {
    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true;
      });
    }

    final leadBloc = BlocProvider.of<LeadBloc>(context);
    await LeadCache.clearLeadsForStatus(currentStatusId);
    leadBloc.add(FetchLeads(
      currentStatusId,
      query: query,
      managerIds: _selectedManagers.map((manager) => manager.id).toList(),
      regionsIds: _selectedRegions.map((region) => region.id).toList(),
      regionId: _selectedState?.id,
      cityIds: _selectedCities.map((city) => city.id).toList(),
      sourcesIds: _selectedSources.map((source) => source.id).toList(),
      channelIds: _selectedChannels.map((channel) => channel.id).toList(),
      advertisingCampaignIds:
          _selectedAdvertisingCampaigns.map((campaign) => campaign.id).toList(),
      reasonForRefusalIds: _selectedReasonForRefusalIds,
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
      numberOfDaysDeal: _numberOfDaysDeal,
      directoryValues: _directoryValues,
      salesFunnelId: _selectedFunnel?.id,
      ignoreCache: true,
    ));
  }

  void _resetFilters() {
    if (mounted) {
      setState(() {
        _showCustomTabBar = true;
        _isFilterLoading = true;
        _shouldShowLoader = true;
        _selectedManagers = [];
        _selectedRegions = [];
        _selectedState = null;
        _selectedCities = [];
        _selectedSources = [];
        _selectedChannels = [];
        _selectedAdvertisingCampaigns = [];
        _selectedReasonForRefusalIds = [];
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
        _numberOfDaysDeal = null;
        _directoryValues = [];
        _selectedCustomFieldFilters = {};

        _initialSelectedManagers = [];
        _initialSelectedRegions = [];
        _initialSelectedState = null;
        _initialSelectedCities = [];
        _initialSelectedSources = [];
        _initialSelectedChannels = [];
        _initialSelectedAdvertisingCampaigns = [];
        _initialReasonForRefusalIds = [];
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
        _initialNumberOfDaysDeal = null;
        _initialDirectoryValues = [];
        _initialCustomFieldFilters = {};
        _lastSearchQuery = '';
        _searchController.clear();
      });
    }

    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatuses(forceRefresh: true));
  }

  Future<void> _handleManagerSelected(Map managers) async {
    debugPrint('LeadScreen: _handleManagerSelected - START WITH NEW LOGIC');
    debugPrint('LeadScreen: Received managers: ${managers['managers']}');
    debugPrint('LeadScreen: Received regions: ${managers['regions']}');
    debugPrint('LeadScreen: Received sources: ${managers['sources']}');
    debugPrint('LeadScreen: hasContact: ${managers['hasContact']}');
    debugPrint('LeadScreen: hasOrders: ${managers['hasOrders']}');

    final customFieldFiltersRaw =
        managers['custom_field_filters'] as Map<String, dynamic>?;
    final parsedCustomFieldFilters =
        _parseCustomFieldFilters(customFieldFiltersRaw);
    final currentStatusIdBeforeFilter = _tabTitles.isNotEmpty
        ? _tabTitles[_currentTabIndex]['id'] as int
        : null;

    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true;
        _showCustomTabBar = true;
        _skipNextTabListener = true;
        _skipNextTabListenerIndex = _currentTabIndex;

        _selectedManagers = managers['managers'];
        _selectedRegions = managers['regions'];
        _selectedState = managers['state'] as RegionData?;
        _selectedCities = (managers['cities'] as List?)?.cast<CityData>() ?? [];
        _selectedSources = managers['sources'];
        _selectedChannels =
            (managers['channels'] as List?)?.cast<LeadFilterChannelData>() ??
                [];
        _selectedAdvertisingCampaigns =
            (managers['advertising_campaigns'] as List?)
                    ?.cast<AdvertisingCampaignData>() ??
                [];
        _selectedReasonForRefusalIds =
            (managers['reason_for_refusal_ids'] as List?)
                    ?.map((id) => int.tryParse(id.toString()) ?? 0)
                    .where((id) => id != 0)
                    .toList() ??
                [];
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
        _numberOfDaysDeal = managers['numberOfDaysDeal'];
        _directoryValues = managers['directory_values'] ?? [];
        _selectedCustomFieldFilters =
            _cloneCustomFieldFilters(parsedCustomFieldFilters);

        _initialSelectedManagers = managers['managers'];
        _initialSelectedRegions = managers['regions'];
        _initialSelectedState = _selectedState;
        _initialSelectedCities = List<CityData>.from(_selectedCities);
        _initialSelectedSources = managers['sources'];
        _initialSelectedChannels =
            List<LeadFilterChannelData>.from(_selectedChannels);
        _initialSelectedAdvertisingCampaigns =
            (managers['advertising_campaigns'] as List?)
                    ?.cast<AdvertisingCampaignData>() ??
                [];
        _initialReasonForRefusalIds =
            List<int>.from(_selectedReasonForRefusalIds);
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
        _initialNumberOfDaysDeal = managers['numberOfDaysDeal'];
        _initialDirectoryValues = managers['directory_values'] ?? [];
        _initialCustomFieldFilters =
            _cloneCustomFieldFilters(parsedCustomFieldFilters);
      });
    }

    await Future.delayed(Duration(milliseconds: 50));

    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatusesWithFilters(
      managerIds: _selectedManagers.isNotEmpty
          ? _selectedManagers.map((manager) => manager.id).toList()
          : null,
      regionsIds: _selectedRegions.isNotEmpty
          ? _selectedRegions.map((region) => region.id).toList()
          : null,
      regionId: _selectedState?.id,
      cityIds: _selectedCities.isNotEmpty
          ? _selectedCities.map((city) => city.id).toList()
          : null,
      sourcesIds: _selectedSources.isNotEmpty
          ? _selectedSources.map((source) => source.id).toList()
          : null,
      channelIds: _selectedChannels.isNotEmpty
          ? _selectedChannels.map((channel) => channel.id).toList()
          : null,
      advertisingCampaignIds: _selectedAdvertisingCampaigns.isNotEmpty
          ? _selectedAdvertisingCampaigns
              .map((campaign) => campaign.id)
              .toList()
          : null,
      reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
          ? _selectedReasonForRefusalIds
          : null,
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
      numberOfDaysDeal: _numberOfDaysDeal,
      directoryValues: _directoryValues,
      salesFunnelId: _selectedFunnel?.id,
      preferredStatusId: currentStatusIdBeforeFilter,
    ));

    debugPrint(
        'LeadScreen: _handleManagerSelected - Dispatched FetchLeadStatusesWithFilters');
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

        return Row(
          children: [
            if (state is SalesFunnelLoaded && state.funnels.length > 1)
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final RenderBox overlay = Navigator.of(context)
                        .overlay!
                        .context
                        .findRenderObject() as RenderBox;
                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(Offset.zero, ancestor: overlay),
                        button.localToGlobal(
                            button.size.bottomRight(Offset.zero),
                            ancestor: overlay),
                      ),
                      Offset.zero & overlay.size,
                    );

                    final selected = await showMenu<SalesFunnel>(
                      context: context,
                      position: position,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      elevation: 8,
                      items: state.funnels
                          .map((f) => PopupMenuItem<SalesFunnel>(
                                value: f,
                                child: Text(f.name,
                                    style:
                                        const TextStyle(fontFamily: 'Gilroy')),
                              ))
                          .toList(),
                    );

                    if (selected != null) {
                      try {
                        setState(() => _isSwitchingFunnel = true);
                        await _apiService
                            .saveSelectedSalesFunnel(selected.id.toString());
                        await LeadCache.clearAllLeads();
                        await LeadCache.clearCache();
                        _resetFilters();

                        if (mounted) {
                          setState(() {
                            _selectedFunnel = selected;
                            _isSearching = false;
                            _searchController.clear();
                            _lastSearchQuery = '';
                          });
                        }

                        context
                            .read<SalesFunnelBloc>()
                            .add(SelectSalesFunnel(selected));
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (mounted) {
                          setState(() {
                            _tabTitles.clear();
                            _tabController =
                                TabController(length: 0, vsync: this);
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
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.expand_more,
                            color: Color(0xff1E2E52), size: 24),
                        const SizedBox(width: 4),
                        Flexible(
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
                      ],
                    ),
                  ),
                ),
              )
            else
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            initialManagersLeadState: _initialSelectedState,
            initialManagersLeadCities: _initialSelectedCities,
            initialManagersLeadSources: _initialSelectedSources,
            initialManagersLeadChannels: _initialSelectedChannels,
            initialManagersLeadAdvertisingCampaigns:
                _initialSelectedAdvertisingCampaigns,
            initialManagersLeadReasonForRefusalIds: _initialReasonForRefusalIds,
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
            initialManagerLeadNumberOfDaysDeal: _initialNumberOfDaysDeal,
            initialDirectoryValuesLead: _initialDirectoryValues,
            initialLeadCustomFields: _initialCustomFieldFilters,
            onLeadResetFilters: _resetFilters,
            textEditingController: textEditingController,
            focusNode: focusNode,
            showMenuIcon: _showCustomTabBar,
            showFilterIconOnSelectLead: !_showCustomTabBar,
            hasActiveLeadFilters: _hasActiveFilters(),
            showFilterTaskIcon: false,
            showMyTaskIcon: true,
            showCallCenter: true,
            showFilterIconDeal: false,
            showEvent: true,
            clearButtonClick: (value) {
              if (value == false) {
                if (mounted) {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _lastSearchQuery = '';
                  });
                }
                if (_searchController.text.isEmpty) {
                  if (_selectedManagers.isEmpty &&
                      _selectedRegions.isEmpty &&
                      _selectedState == null &&
                      _selectedCities.isEmpty &&
                      _selectedSources.isEmpty &&
                      _selectedChannels.isEmpty &&
                      _selectedAdvertisingCampaigns.isEmpty &&
                      _selectedReasonForRefusalIds.isEmpty &&
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
                    final taskBloc = BlocProvider.of<LeadBloc>(context);
                    taskBloc.add(FetchLeadStatuses());
                  } else {
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
                      regionId: _selectedState?.id,
                      cityIds: _selectedCities.isNotEmpty
                          ? _selectedCities.map((city) => city.id).toList()
                          : null,
                      sourcesIds: _selectedSources.isNotEmpty
                          ? _selectedSources.map((source) => source.id).toList()
                          : null,
                      channelIds: _selectedChannels.isNotEmpty
                          ? _selectedChannels
                              .map((channel) => channel.id)
                              .toList()
                          : null,
                      advertisingCampaignIds:
                          _selectedAdvertisingCampaigns.isNotEmpty
                              ? _selectedAdvertisingCampaigns
                                  .map((campaign) => campaign.id)
                                  .toList()
                              : null,
                      reasonForRefusalIds:
                          _selectedReasonForRefusalIds.isNotEmpty
                              ? _selectedReasonForRefusalIds
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
                      numberOfDaysDeal: _numberOfDaysDeal,
                      directoryValues: _directoryValues,
                      customFieldFilters: _selectedCustomFieldFilters,
                      salesFunnelId: _selectedFunnel?.id,
                    ));
                  }
                } else if (_selectedManagerIds != null &&
                    _selectedManagerIds!.isNotEmpty) {
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  final taskBloc = BlocProvider.of<LeadBloc>(context);
                  taskBloc.add(FetchLeads(
                    currentStatusId,
                    managerIds: _selectedManagerIds,
                    query: _searchController.text.isNotEmpty
                        ? _searchController.text
                        : null,
                    directoryValues: _directoryValues,
                    customFieldFilters: _selectedCustomFieldFilters,
                    salesFunnelId: _selectedFunnel?.id,
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
        floatingActionButton: _tabTitles.isNotEmpty &&
                _hasPermissionToAddLead &&
                !isClickAvatarIcon
            ? FloatingActionButton(
                key: keyFloatingActionButton,
                onPressed: () {
                  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                  if (_isSwitch) {
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (BuildContext context) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('add_for_current_status'),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('new_lead_in_switch'),
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
                                      builder: (context) => LeadAddScreen(
                                          statusId: currentStatusId),
                                    ),
                                  ).then((_) => context.read<LeadBloc>().add(
                                        FetchLeads(
                                          currentStatusId,
                                          salesFunnelId: _selectedFunnel?.id,
                                          advertisingCampaignIds:
                                              _selectedAdvertisingCampaigns
                                                      .isNotEmpty
                                                  ? _selectedAdvertisingCampaigns
                                                      .map((campaign) =>
                                                          campaign.id)
                                                      .toList()
                                                  : null,
                                          reasonForRefusalIds:
                                              _selectedReasonForRefusalIds
                                                      .isNotEmpty
                                                  ? _selectedReasonForRefusalIds
                                                  : null,
                                        ),
                                      ));
                                },
                              ),
                              ListTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('import_contact'),
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
                                      builder: (context) => ContactsScreen(
                                          statusId: currentStatusId),
                                    ),
                                  ).then((_) => context.read<LeadBloc>().add(
                                        FetchLeads(
                                          currentStatusId,
                                          salesFunnelId: _selectedFunnel?.id,
                                          advertisingCampaignIds:
                                              _selectedAdvertisingCampaigns
                                                      .isNotEmpty
                                                  ? _selectedAdvertisingCampaigns
                                                      .map((campaign) =>
                                                          campaign.id)
                                                      .toList()
                                                  : null,
                                          reasonForRefusalIds:
                                              _selectedReasonForRefusalIds
                                                      .isNotEmpty
                                                  ? _selectedReasonForRefusalIds
                                                  : null,
                                        ),
                                      ));
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
                        builder: (context) =>
                            LeadAddScreen(statusId: currentStatusId),
                      ),
                    ).then((_) => context.read<LeadBloc>().add(
                          FetchLeads(
                            currentStatusId,
                            salesFunnelId: _selectedFunnel?.id,
                            advertisingCampaignIds:
                                _selectedAdvertisingCampaigns.isNotEmpty
                                    ? _selectedAdvertisingCampaigns
                                        .map((campaign) => campaign.id)
                                        .toList()
                                    : null,
                            reasonForRefusalIds:
                                _selectedReasonForRefusalIds.isNotEmpty
                                    ? _selectedReasonForRefusalIds
                                    : null,
                          ),
                        ));
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
    final currentStatusId =
        _tabTitles.isNotEmpty ? _tabTitles[_currentTabIndex]['id'] : 0;

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
        controller: _listScrollController,
        itemCount: leads.length +
            ((context.watch<LeadBloc>().state is LeadDataLoaded &&
                    (context.watch<LeadBloc>().state as LeadDataLoaded)
                        .isLoadingMore)
                ? 1
                : 0),
        itemBuilder: (context, index) {
          final state = context.watch<LeadBloc>().state;
          if (state is LeadDataLoaded &&
              state.isLoadingMore &&
              index >= leads.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: PlayStoreImageLoading(
                  size: 56.0,
                  duration: Duration(milliseconds: 1000),
                ),
              ),
            );
          }
          final lead = leads[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LeadCard(
              lead: lead,
              title: lead.leadStatus?.title ?? "",
              statusId: lead.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusLeadId) {
                final index = _tabTitles
                    .indexWhere((status) => status['id'] == StatusLeadId);
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
        if ((state is LeadDataLoaded ||
                state is LeadLoaded ||
                state is LeadError) &&
            mounted &&
            (_isFilterLoading || _shouldShowLoader)) {
          _resetLeadLoaderFlags();
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
            final filteredLeads =
                leads.where((lead) => lead.statusId == statusId).toList();

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
                controller: _listScrollController,
                itemCount: filteredLeads.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= filteredLeads.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: PlayStoreImageLoading(
                          size: 56.0,
                          duration: Duration(milliseconds: 1000),
                        ),
                      ),
                    );
                  }
                  final lead = filteredLeads[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          if (state is LeadLoaded) {
            if (!_permissionsInitialized) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            }

            if (!_canReadLeadStatus) {
              return const Center(
                child: Text(
                  'Нет доступа к статусам лидов',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff99A4BA),
                  ),
                ),
              );
            }

            if (_tabTitles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Не удалось подготовить список статусов',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.read<LeadBloc>().add(FetchLeadStatuses());
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }
          }

          return const Center(
            child: PlayStoreImageLoading(
              size: 80.0,
              duration: Duration(milliseconds: 1000),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _tabScrollController,
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
      if (mounted) {
        setState(() {
          navigateToEnd = true;
        });
      }
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
    final statusId = _tabTitles[index]['id'] as int;

    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        int leadCount = (_tabTitles[index]['leads_count'] as int?) ?? 0;

        if (state is LeadLoaded) {
          leadCount = state.leadCounts[statusId] ??
              state.leadStatuses
                  .firstWhere(
                    (status) => status.id == statusId,
                    orElse: () => LeadStatus(
                      id: 0,
                      title: '',
                      leadsCount: 0,
                      isSuccess: false,
                      position: 1,
                      isFailure: false,
                      isUnassembled: false,
                    ),
                  )
                  .leadsCount;
        } else if (state is LeadDataLoaded) {
          leadCount = state.leadCounts[statusId] ?? leadCount;
        }

        LeadCache.setPersistentLeadCount(statusId, leadCount);
        return _buildTabButtonUI(index, isActive, leadCount);
      },
    );
  }

// Вспомогательный метод для построения UI кнопки табы
  Widget _buildTabButtonUI(int index, bool isActive, int leadCount) {
    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        if (_tabController.index != index) {
          setState(() {
            _isFilterLoading = true;
            _shouldShowLoader = true;
          });
        }
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
          _tabController =
              TabController(length: _tabTitles.length, vsync: this);
          _currentTabIndex = 0;
          _isSearching = false;
          _searchController.clear();
          if (_tabTitles.isNotEmpty) {
            final activeStatusId = _tabTitles[_currentTabIndex]['id'];
            context.read<LeadBloc>().add(FetchLeads(
                  activeStatusId,
                  salesFunnelId: _selectedFunnel?.id,
                  advertisingCampaignIds:
                      _selectedAdvertisingCampaigns.isNotEmpty
                          ? _selectedAdvertisingCampaigns
                              .map((campaign) => campaign.id)
                              .toList()
                          : null,
                  reasonForRefusalIds: _selectedReasonForRefusalIds.isNotEmpty
                      ? _selectedReasonForRefusalIds
                      : null,
                ));
          }
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
        if ((state is LeadDataLoaded ||
                state is LeadLoaded ||
                state is LeadError) &&
            mounted &&
            (_isFilterLoading || _shouldShowLoader)) {
          _resetLeadLoaderFlags();
        }
        if (state is LeadLoaded) {
          if (!_permissionsInitialized) {
            return;
          }

          if (!_canReadLeadStatus) {
            if (mounted) {
              setState(() {
                _tabTitles.clear();
                _tabKeys.clear();
                _currentTabIndex = 0;
              });
            }
            return;
          }

          //print('LeadScreen: LeadLoaded state, caching lead statuses: ${state.leadStatuses}');
          await LeadCache.cacheLeadStatuses(state.leadStatuses);

          if (mounted) {
            setState(() {
              // Обновляем табы с новыми данными
              _tabTitles = state.leadStatuses
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
                bool needNewController =
                    _tabController.length != _tabTitles.length;

                if (needNewController) {
                  // Сохраняем текущий индекс перед созданием нового контроллера
                  int savedTabIndex = _currentTabIndex;

                  // Dispose старого контроллера если он существует
                  if (_tabController.length > 0) {
                    _tabController.dispose();
                  }

                  // Создаем новый контроллер
                  _tabController =
                      TabController(length: _tabTitles.length, vsync: this);
                  //print('LeadScreen: Created new TabController with length: ${_tabTitles.length}');

                  // ← КРИТИЧНО: Добавляем listener ТОЛЬКО при создании нового контроллера!
                  _tabController.addListener(() {
                    if (!_tabController.indexIsChanging) {
                      // ← КРИТИЧНО: Проверяем флаг пропуска!
                      if (_skipNextTabListener &&
                          _skipNextTabListenerIndex == _tabController.index) {
                        debugPrint(
                            'LeadScreen: TabController listener - SKIPPED (filter just applied)');
                        setState(() {
                          _skipNextTabListener = false;
                          _skipNextTabListenerIndex = null;
                          _currentTabIndex = _tabController.index;
                        });
                        return; // ← ВЫХОДИМ БЕЗ ЗАПРОСА!
                      }

                      debugPrint(
                          'LeadScreen: TabController listener triggered, new index: ${_tabController.index}');
                      setState(() {
                        _currentTabIndex = _tabController.index;
                      });
                      final currentStatusId =
                          _tabTitles[_currentTabIndex]['id'];
                      if (_tabScrollController.hasClients) {
                        _scrollToActiveTab();
                      }

                      bool hasActiveFilters = _selectedManagers.isNotEmpty ||
                          _selectedRegions.isNotEmpty ||
                          _selectedSources.isNotEmpty ||
                          _selectedAdvertisingCampaigns.isNotEmpty ||
                          _selectedReasonForRefusalIds.isNotEmpty ||
                          _selectedStatuses != null ||
                          _fromDate != null ||
                          _toDate != null ||
                          _hasSuccessDeals == true ||
                          _hasInProgressDeals == true ||
                          _hasFailureDeals == true ||
                          _hasNotices == true ||
                          _hasContact == true ||
                          _hasChat == true ||
                          _hasNoReplies == true ||
                          _hasUnreadMessages == true ||
                          _hasDeal == true ||
                          _hasOrders == true ||
                          _daysWithoutActivity != null ||
                          _numberOfDaysDeal != null ||
                          _directoryValues.isNotEmpty;

                      if (mounted) {
                        setState(() {
                          _isFilterLoading = true;
                          _shouldShowLoader = true;
                        });
                      }

                      context.read<LeadBloc>().add(FetchLeads(
                            currentStatusId,
                            salesFunnelId: _selectedFunnel?.id,
                            ignoreCache: false,
                            query: _lastSearchQuery.isNotEmpty
                                ? _lastSearchQuery
                                : null,

                            managerIds:
                                hasActiveFilters && _selectedManagers.isNotEmpty
                                    ? _selectedManagers
                                        .map((manager) => manager.id)
                                        .toList()
                                    : null,
                            regionsIds:
                                hasActiveFilters && _selectedRegions.isNotEmpty
                                    ? _selectedRegions
                                        .map((region) => region.id)
                                        .toList()
                                    : null,
                            sourcesIds:
                                hasActiveFilters && _selectedSources.isNotEmpty
                                    ? _selectedSources
                                        .map((source) => source.id)
                                        .toList()
                                    : null,
                            advertisingCampaignIds: hasActiveFilters &&
                                    _selectedAdvertisingCampaigns.isNotEmpty
                                ? _selectedAdvertisingCampaigns
                                    .map((campaign) => campaign.id)
                                    .toList()
                                : null,
                            reasonForRefusalIds: hasActiveFilters &&
                                    _selectedReasonForRefusalIds.isNotEmpty
                                ? _selectedReasonForRefusalIds
                                : null,
                            // ВАЖНО: всегда пробрасываем текущий статус вкладки,
                            // чтобы в каждом запросе присутствовал lead_status_id
                            statusIds: currentStatusId,
                            fromDate: hasActiveFilters ? _fromDate : null,
                            toDate: hasActiveFilters ? _toDate : null,
                            hasSuccessDeals:
                                hasActiveFilters ? _hasSuccessDeals : null,
                            hasInProgressDeals:
                                hasActiveFilters ? _hasInProgressDeals : null,
                            hasFailureDeals:
                                hasActiveFilters ? _hasFailureDeals : null,
                            hasNotices: hasActiveFilters ? _hasNotices : null,
                            hasContact: hasActiveFilters ? _hasContact : null,
                            hasChat: hasActiveFilters ? _hasChat : null,
                            hasNoReplies:
                                hasActiveFilters ? _hasNoReplies : null,
                            hasUnreadMessages:
                                hasActiveFilters ? _hasUnreadMessages : null,
                            hasDeal: hasActiveFilters ? _hasDeal : null,
                            hasOrders: hasActiveFilters ? _hasOrders : null,
                            daysWithoutActivity:
                                hasActiveFilters ? _daysWithoutActivity : null,
                            numberOfDaysDeal:
                                hasActiveFilters ? _numberOfDaysDeal : null,
                            directoryValues:
                                hasActiveFilters && _directoryValues.isNotEmpty
                                    ? _directoryValues
                                    : null,
                          ));

                      if (kDebugMode) {
                        debugPrint(
                            'LeadScreen: FetchLeads dispatched for statusId: $currentStatusId');
                        debugPrint(
                            'LeadScreen: hasActiveFilters: $hasActiveFilters');
                        if (hasActiveFilters) {
                          debugPrint(
                              'LeadScreen: Applied filters - managers: ${_selectedManagers.length}, regions: ${_selectedRegions.length}');
                        }
                      }
                    }
                  }); // ← Закрываем listener здесь, только для нового контроллера!
                }

                // Установка правильного индекса
                if (needNewController) {
                  // При создании нового контроллера восстанавливаем индекс или ставим 0
                  if (_currentTabIndex < _tabTitles.length &&
                      _currentTabIndex >= 0) {
                    _tabController.index = _currentTabIndex;
                    //print('LeadScreen: Restored tab index to: $_currentTabIndex');
                  } else {
                    _tabController.index = 0;
                    _currentTabIndex = 0;
                    //print('LeadScreen: Reset tab index to: 0');
                  }
                } else {
                  // При обновлении существующего контроллера проверяем initialStatusId
                  int initialIndex = state.leadStatuses.indexWhere(
                      (status) => status.id == widget.initialStatusId);
                  if (initialIndex != -1 && initialIndex != _currentTabIndex) {
                    _tabController.index = initialIndex;
                    _currentTabIndex = initialIndex;
                    //print('LeadScreen: Set initial tab index to: $initialIndex');
                  } else if (_tabTitles.isNotEmpty) {
                    int safeIndex = _currentTabIndex < _tabTitles.length
                        ? _currentTabIndex
                        : 0;
                    _tabController.index = safeIndex;
                    _currentTabIndex = safeIndex;
                    //print('LeadScreen: Set safe tab index to: $safeIndex');
                  }
                }

                // Прокручиваем к активному табу
                if (_tabScrollController.hasClients) {
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
                    int newIndex = _deletedIndex! >= _tabTitles.length
                        ? _tabTitles.length - 1
                        : _deletedIndex!;
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
            await AppLogoutService.logoutAndReset(
              context: context,
              restartApp: false,
            );
          } else {
            // ✅ УБРАНО: Не показываем непереведенный SnackBar с кнопкой "Повторить"
            // Переведенные сообщения показываются в других местах
            if (kDebugMode) {
              debugPrint('LeadScreen: Error state - ${state.message}');
            }
          }
        }
      },
      child: Builder(
        builder: (context) {
          final state = context.watch<LeadBloc>().state;

          if (_tabTitles.isEmpty) {
            if (!_permissionsInitialized || state is LeadLoading) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            }

            if (!_canReadLeadStatus) {
              return const Center(
                child: Text(
                  'Нет доступа к статусам лидов',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff99A4BA),
                  ),
                ),
              );
            }

            if (state is LeadError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (state is LeadLoaded) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Список статусов пуст',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.read<LeadBloc>().add(FetchLeadStatuses());
                      },
                      child: const Text('Обновить'),
                    ),
                  ],
                ),
              );
            }

            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          }

          return TabBarView(
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
                    final index =
                        _tabTitles.indexWhere((s) => s['id'] == newStatusId);
                    if (index != -1) {
                      _tabController.animateTo(index);
                      //print('LeadScreen: Animated to tab index: $index for statusId: $newStatusId');

                      // Проверяем, есть ли уже данные для этого статуса
                      final currentLeadBloc = context.read<LeadBloc>();
                      if (currentLeadBloc.state is LeadDataLoaded) {
                        final currentState =
                            currentLeadBloc.state as LeadDataLoaded;
                        final hasLeadsForStatus = currentState.leads
                            .any((lead) => lead.statusId == newStatusId);

                        // Загружаем только если нет данных для этого статуса
                        if (!hasLeadsForStatus) {
                          if (mounted) {
                            setState(() {
                              _shouldShowLoader = true;
                            });
                          }
                          currentLeadBloc.add(FetchLeads(
                            newStatusId,
                            salesFunnelId: _selectedFunnel?.id,
                            ignoreCache: false,
                            query: _lastSearchQuery.isNotEmpty
                                ? _lastSearchQuery
                                : null,
                            managerIds: _selectedManagers.isNotEmpty
                                ? _selectedManagers
                                    .map((manager) => manager.id)
                                    .toList()
                                : null,
                            regionsIds: _selectedRegions.isNotEmpty
                                ? _selectedRegions
                                    .map((region) => region.id)
                                    .toList()
                                : null,
                            regionId: _selectedState?.id,
                            cityIds: _selectedCities.isNotEmpty
                                ? _selectedCities
                                    .map((city) => city.id)
                                    .toList()
                                : null,
                            sourcesIds: _selectedSources.isNotEmpty
                                ? _selectedSources
                                    .map((source) => source.id)
                                    .toList()
                                : null,
                            channelIds: _selectedChannels.isNotEmpty
                                ? _selectedChannels
                                    .map((channel) => channel.id)
                                    .toList()
                                : null,
                            advertisingCampaignIds:
                                _selectedAdvertisingCampaigns.isNotEmpty
                                    ? _selectedAdvertisingCampaigns
                                        .map((campaign) => campaign.id)
                                        .toList()
                                    : null,
                            reasonForRefusalIds:
                                _selectedReasonForRefusalIds.isNotEmpty
                                    ? _selectedReasonForRefusalIds
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
                            numberOfDaysDeal: _numberOfDaysDeal,
                            directoryValues: _directoryValues,
                          ));
                          //print('LeadScreen: FetchLeads dispatched for statusId: $newStatusId (no cached data found)');
                        } else {
                          //print('LeadScreen: Using cached data for statusId: $newStatusId');
                        }
                      } else {
                        // Если нет состояния LeadDataLoaded, загружаем данные
                        if (mounted) {
                          setState(() {
                            _shouldShowLoader = true;
                          });
                        }
                        currentLeadBloc.add(FetchLeads(
                          newStatusId,
                          salesFunnelId: _selectedFunnel?.id,
                          ignoreCache: false,
                          managerIds: _selectedManagers.isNotEmpty
                              ? _selectedManagers
                                  .map((manager) => manager.id)
                                  .toList()
                              : null,
                          regionsIds: _selectedRegions.isNotEmpty
                              ? _selectedRegions
                                  .map((region) => region.id)
                                  .toList()
                              : null,
                          regionId: _selectedState?.id,
                          cityIds: _selectedCities.isNotEmpty
                              ? _selectedCities.map((city) => city.id).toList()
                              : null,
                          sourcesIds: _selectedSources.isNotEmpty
                              ? _selectedSources
                                  .map((source) => source.id)
                                  .toList()
                              : null,
                          channelIds: _selectedChannels.isNotEmpty
                              ? _selectedChannels
                                  .map((channel) => channel.id)
                                  .toList()
                              : null,
                          advertisingCampaignIds:
                              _selectedAdvertisingCampaigns.isNotEmpty
                                  ? _selectedAdvertisingCampaigns
                                      .map((campaign) => campaign.id)
                                      .toList()
                                  : null,
                          reasonForRefusalIds:
                              _selectedReasonForRefusalIds.isNotEmpty
                                  ? _selectedReasonForRefusalIds
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
                          numberOfDaysDeal: _numberOfDaysDeal,
                          directoryValues: _directoryValues,
                          customFieldFilters: _selectedCustomFieldFilters,
                        ));
                        //print('LeadScreen: FetchLeads dispatched for statusId: $newStatusId (no LeadDataLoaded state)');
                      }
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _scrollToActiveTab() {
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null && _tabScrollController.hasClients) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;

      if (position.dx < 0 ||
          (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
        double targetOffset = _tabScrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);

        _tabScrollController.animateTo(
          targetOffset,
          duration: Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      }
    }
  }

  @override
  void dispose() {
    for (final subscription in _leadSocketSubscriptions) {
      subscription.cancel();
    }
    _leadSocketClient?.disconnect();
    _listScrollController.removeListener(_onScroll);
    _listScrollController.dispose();
    _tabScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
