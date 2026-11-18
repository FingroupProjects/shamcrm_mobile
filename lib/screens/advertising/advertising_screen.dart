import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/advertising/advertising_models.dart';
import 'package:crm_task_manager/models/sales_funnel/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/advertising/widgets/advertising_details_sheet.dart';
import 'package:crm_task_manager/screens/advertising/widgets/advertising_period_filter.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/hold_to_read_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

enum AdvertisingMainTab { metaAds, otherCampaigns }

enum MetaAdsLevel { campaigns, adsets, ads }

class AdvertisingScreen extends StatefulWidget {
  const AdvertisingScreen({super.key});

  @override
  State<AdvertisingScreen> createState() => _AdvertisingScreenState();
}

class _AdvertisingScreenState extends State<AdvertisingScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  AdvertisingMainTab _mainTab = AdvertisingMainTab.metaAds;
  MetaAdsLevel _metaLevel = MetaAdsLevel.campaigns;
  AdvertisingDatePreset _datePreset = AdvertisingDatePreset.last30Days;

  late DateTime _startDate;
  late DateTime _endDate;

  SalesFunnel? _selectedFunnel;
  int? _selectedOrganizationId;

  MetaAdsCampaign? _filteredCampaign;
  MetaAdsAdSet? _filteredAdSet;

  String _searchQuery = '';

  bool _isLoadingSummary = false;
  MetaAdsSummary? _summary;

  bool _isLoadingList = false;
  List<MetaAdsCampaign> _campaigns = [];
  List<MetaAdsAdSet> _adsets = [];
  List<MetaAdsAd> _ads = [];
  List<OtherAdvertisingCampaign> _otherCampaigns = [];

  Map<String, OtherAdvertisingCampaign> _crmCampaignsByExternalId = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 30));
    _endDate = now;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _initAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initAndLoad() async {
    final funnelState = context.read<SalesFunnelBloc>().state;
    if (funnelState is SalesFunnelLoaded && funnelState.funnels.isNotEmpty) {
      _selectedFunnel =
          funnelState.selectedFunnel ?? funnelState.funnels.first;
    }

    final orgIdStr = await _apiService.getSelectedOrganization();
    _selectedOrganizationId = int.tryParse(orgIdStr ?? '');
    await Future.wait([
      _loadData(),
      _loadCrmCampaignsLookup(),
    ]);
  }

  Future<void> _loadCrmCampaignsLookup() async {
    try {
      final list = await _apiService.getAllCrmAdvertisingCampaigns(
        salesFunnelId: _selectedFunnel?.id,
        organizationId: _selectedOrganizationId,
      );
      final map = <String, OtherAdvertisingCampaign>{};
      for (final item in list) {
        final externalId = item.externalAdId;
        if (externalId != null && externalId.isNotEmpty) {
          map[externalId] = item;
        }
      }
      if (mounted) setState(() => _crmCampaignsByExternalId = map);
    } catch (_) {}
  }

  String get _formattedStartDate => DateFormat('yyyy-MM-dd').format(_startDate);
  String get _formattedEndDate => DateFormat('yyyy-MM-dd').format(_endDate);

  bool get _hasActiveFilter =>
      _datePreset != AdvertisingDatePreset.last30Days;

  bool get _canLeaveScreen {
    if (_metaLevel == MetaAdsLevel.ads &&
        (_filteredAdSet != null || _filteredCampaign != null)) {
      return false;
    }
    if (_metaLevel == MetaAdsLevel.adsets && _filteredCampaign != null) {
      return false;
    }
    return true;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _errorMessage = null);
    if (_mainTab == AdvertisingMainTab.metaAds) {
      await Future.wait([_fetchMetaSummary(), _fetchMetaList()]);
    } else {
      await _fetchOtherCampaigns();
    }
  }

  Future<void> _fetchMetaSummary() async {
    if (!mounted) return;
    setState(() => _isLoadingSummary = true);
    try {
      final summary = await _apiService.getMetaAdsSummary(
        dateFrom: _formattedStartDate,
        dateTo: _formattedEndDate,
        salesFunnelId: _selectedFunnel?.id,
        organizationId: _selectedOrganizationId,
      );
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _fetchMetaList() async {
    if (!mounted) return;
    setState(() => _isLoadingList = true);
    try {
      switch (_metaLevel) {
        case MetaAdsLevel.campaigns:
          final res = await _apiService.getMetaAdsCampaigns(
            dateFrom: _formattedStartDate,
            dateTo: _formattedEndDate,
            salesFunnelId: _selectedFunnel?.id,
            organizationId: _selectedOrganizationId,
          );
          if (mounted) {
            setState(() {
              _campaigns =
                  (res['data'] as List<dynamic>? ?? []).cast<MetaAdsCampaign>();
              _isLoadingList = false;
            });
          }
        case MetaAdsLevel.adsets:
          final res = await _apiService.getMetaAdsAdsets(
            dateFrom: _formattedStartDate,
            dateTo: _formattedEndDate,
            campaignId: _filteredCampaign?.id,
            salesFunnelId: _selectedFunnel?.id,
            organizationId: _selectedOrganizationId,
          );
          if (mounted) {
            setState(() {
              _adsets =
                  (res['data'] as List<dynamic>? ?? []).cast<MetaAdsAdSet>();
              _isLoadingList = false;
            });
          }
        case MetaAdsLevel.ads:
          final res = await _apiService.getMetaAdsAds(
            dateFrom: _formattedStartDate,
            dateTo: _formattedEndDate,
            campaignId: _filteredCampaign?.id,
            adsetId: _filteredAdSet?.id,
            salesFunnelId: _selectedFunnel?.id,
            organizationId: _selectedOrganizationId,
          );
          if (mounted) {
            setState(() {
              _ads = (res['data'] as List<dynamic>? ?? []).cast<MetaAdsAd>();
              _isLoadingList = false;
            });
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingList = false;
        });
      }
    }
  }

  Future<void> _fetchOtherCampaigns() async {
    if (!mounted) return;
    setState(() => _isLoadingList = true);
    try {
      final res = await _apiService.getOtherAdvertisingCampaigns(
        salesFunnelId: _selectedFunnel?.id,
        organizationId: _selectedOrganizationId,
      );
      if (mounted) {
        setState(() {
          _otherCampaigns = (res['data'] as List<dynamic>? ?? [])
              .cast<OtherAdvertisingCampaign>();
          _isLoadingList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingList = false;
        });
      }
    }
  }

  void _goBackLevel() {
    if (_metaLevel == MetaAdsLevel.ads &&
        (_filteredAdSet != null || _filteredCampaign != null)) {
      setState(() {
        _metaLevel = MetaAdsLevel.adsets;
        _filteredAdSet = null;
      });
      _fetchMetaList();
      return;
    }
    if (_metaLevel == MetaAdsLevel.adsets && _filteredCampaign != null) {
      setState(() {
        _metaLevel = MetaAdsLevel.campaigns;
        _filteredCampaign = null;
        _filteredAdSet = null;
      });
      _fetchMetaList();
    }
  }

  void _openCampaign(MetaAdsCampaign item) {
    setState(() {
      _filteredCampaign = item;
      _filteredAdSet = null;
      _metaLevel = MetaAdsLevel.adsets;
    });
    _fetchMetaList();
  }

  void _openAdSet(MetaAdsAdSet item) {
    setState(() {
      _filteredAdSet = item;
      final campaignId = item.campaignId;
      if (campaignId != null &&
          (_filteredCampaign == null || _filteredCampaign!.id != campaignId)) {
        _filteredCampaign = MetaAdsCampaign(
          id: campaignId,
          level: 'campaign',
          externalId: '',
          name: item.campaignName ?? '',
          effectiveStatus: '',
          spend: 0,
          impressions: 0,
          clicks: 0,
          linkClicks: 0,
        );
      }
      _metaLevel = MetaAdsLevel.ads;
    });
    _fetchMetaList();
  }

  void _switchLevel(MetaAdsLevel level) {
    if (_metaLevel == level) return;
    setState(() {
      _metaLevel = level;
      if (level == MetaAdsLevel.campaigns) {
        _filteredCampaign = null;
        _filteredAdSet = null;
      } else if (level == MetaAdsLevel.adsets) {
        _filteredAdSet = null;
      }
    });
    _fetchMetaList();
  }

  Future<void> _openFilter() async {
    final result = await Navigator.push<AdvertisingFilterResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AdvertisingPeriodFilter(
          preset: _datePreset,
          start: _startDate,
          end: _endDate,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _datePreset = result.preset;
      _startDate = result.start;
      _endDate = result.end;
    });
    await _loadData();
  }

  Future<void> _changeFunnel(SalesFunnel selected) async {
    setState(() {
      _selectedFunnel = selected;
      _filteredCampaign = null;
      _filteredAdSet = null;
      _metaLevel = MetaAdsLevel.campaigns;
    });
    context.read<SalesFunnelBloc>().add(SelectSalesFunnel(selected));
    await Future.wait([_loadData(), _loadCrmCampaignsLookup()]);
  }

  String _money(double amount, [String currency = 'USD']) {
    final formatted = NumberFormat('#,##0.00', 'ru_RU').format(amount);
    if (currency == 'USD') return '$formatted \$';
    return '$formatted $currency';
  }

  String _count(int value) {
    return NumberFormat('#,###', 'ru_RU').format(value);
  }

  String _budgetText(AppLocalizations t, double? amount, String? type) {
    if (amount == null) return '—';
    final money = _money(amount);
    if (type == 'daily') return '$money ${t.translate('per_day')}';
    return money;
  }

  String _revenueText(double? revenue) {
    if (revenue == null || revenue == 0) return '—';
    return _money(revenue, _summary?.revenueCurrency ?? 'TJS');
  }

  String _budgetLabel(AppLocalizations t) {
    final tr = t.translate('sp_field_budget');
    if (tr != 'sp_field_budget') return tr;
    final tr2 = t.translate('budget');
    if (tr2 != 'budget') return tr2;
    switch (t.locale.languageCode) {
      case 'uz':
        return 'Byudjet';
      case 'en':
        return 'Budget';
      default:
        return 'Бюджет';
    }
  }

  String _leadPriceLabel(AppLocalizations t) {
    final tr = t.translate('lead_price');
    if (tr != 'Lead price' && tr != 'lead_price') return tr;
    switch (t.locale.languageCode) {
      case 'uz':
        return 'Lid narxi';
      case 'en':
        return 'Lead price';
      default:
        return 'Цена лида';
    }
  }

  List<_Metric> _webMetrics(
    AppLocalizations t, {
    required String budget,
    required String spend,
    required String impressions,
    required String reach,
    required String results,
    required String leadPrice,
    required String revenue,
    String? clients,
  }) {
    return [
      _Metric(_budgetLabel(t), budget),
      _Metric(t.translate('stat_spend'), spend),
      _Metric(t.translate('stat_impressions'), impressions),
      _Metric(t.translate('stat_reach'), reach),
      _Metric(t.translate('stat_results'), results),
      _Metric(_leadPriceLabel(t), leadPrice),
      _Metric(t.translate('stat_revenue'), revenue),
      if (clients != null) _Metric(t.translate('clients'), clients),
    ];
  }

  String _statusLabel(BuildContext context, String status, bool isActive) {
    final t = AppLocalizations.of(context)!;
    if (isActive) return t.translate('ad_status_active');
    final normalized = status.toUpperCase();
    if (normalized.contains('PAUSE') || normalized == 'PAUSED') {
      return t.translate('ad_status_paused');
    }
    if (status.trim().isEmpty) return t.translate('ad_status_paused');
    return status;
  }

  bool _matches(String? value) {
    if (_searchQuery.isEmpty) return true;
    return (value ?? '').toLowerCase().contains(_searchQuery);
  }

  Widget _buildFunnelTitle(BuildContext context) {
    return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
      builder: (context, state) {
        var title = AppLocalizations.of(context)!.translate('advertising');
        var funnels = <SalesFunnel>[];
        if (state is SalesFunnelLoaded && state.funnels.isNotEmpty) {
          funnels = state.funnels;
          final selected =
              _selectedFunnel ?? state.selectedFunnel ?? state.funnels.first;
          title = selected.name;
        }

        final titleStyle = TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: context.appColors.buttonPrimaryBg,
        );

        if (funnels.length <= 1) {
          return HoldToReadText(text: title, style: titleStyle);
        }

        return InkWell(
          onTap: () => _pickFunnel(context, funnels),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.expand_more,
                  color: context.appColors.buttonPrimaryBg,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: HoldToReadText(text: title, style: titleStyle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFunnel(
    BuildContext context,
    List<SalesFunnel> funnels,
  ) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<SalesFunnel>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: context.appColors.surfacePrimary,
      elevation: 10,
      items: funnels
          .map(
            (funnel) => PopupMenuItem<SalesFunnel>(
              value: funnel,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      funnel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_selectedFunnel?.id == funnel.id)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: context.appColors.buttonPrimaryBg,
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
    if (selected != null) await _changeFunnel(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _canLeaveScreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBackLevel();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          forceMaterialTransparency: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          titleSpacing: 16,
          title: CustomAppBar(
            title: '',
            titleWidget: _buildFunnelTitle(context),
            leading: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: colors.iconPrimary,
              ),
              onPressed: () {
                if (_canLeaveScreen) {
                  Navigator.pop(context);
                } else {
                  _goBackLevel();
                }
              },
            ),
            onClickProfileAvatar: () {},
            onChangedSearchInput: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
            textEditingController: _searchController,
            focusNode: _focusNode,
            showMenuIcon: false,
            showFilterIconOnSelectLead: true,
            showFilterTaskIcon: false,
            showMyTaskIcon: false,
            showCallCenter: false,
            showMasterclassQrScanner: false,
            showNotification: false,
            showNotificationInMenu: false,
            showFilterIconDeal: false,
            showEvent: false,
            showCalendar: false,
            showAdvertising: false,
            hasActiveLeadFilters: _hasActiveFilter,
            activeFilterCount: 0,
            onLeadFilterPressed: _openFilter,
            clearButtonClick: (isSearching) {
              if (!isSearching) {
                setState(() => _searchQuery = '');
              }
            },
            clearButtonClickFiltr: (_) {},
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
            ),
            Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).padding.top +
                      kToolbarHeight +
                      10,
                ),
                _buildMainTabs(context),
                const SizedBox(height: 6),
                Expanded(
                  child: RefreshIndicator(
                    color: colors.buttonPrimaryBg,
                    onRefresh: () async {
                      await _loadData();
                      await _loadCrmCampaignsLookup();
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_mainTab == AdvertisingMainTab.metaAds) ...[
                          SliverToBoxAdapter(child: _buildSummary(context)),
                          const SliverToBoxAdapter(child: SizedBox(height: 6)),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _SliverHeaderDelegate(
                              height: 52,
                              backgroundColor: colors.backgroundPrimary,
                              child: _buildLevelTabs(context),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 6)),
                        ],
                        if (_isLoadingList)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorMessage != null)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildMessage(
                              context,
                              _errorMessage!,
                              action: t.translate('retry'),
                              onAction: _loadData,
                            ),
                          )
                        else
                          _buildList(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _tabShell(
      context,
      children: [
        Expanded(
          child: _tabButton(
            context,
            title: t.translate('meta_ads'),
            active: _mainTab == AdvertisingMainTab.metaAds,
            expand: true,
            onTap: () {
              if (_mainTab == AdvertisingMainTab.metaAds) return;
              setState(() => _mainTab = AdvertisingMainTab.metaAds);
              _loadData();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tabButton(
            context,
            title: t.translate('other_campaigns'),
            active: _mainTab == AdvertisingMainTab.otherCampaigns,
            expand: true,
            onTap: () {
              if (_mainTab == AdvertisingMainTab.otherCampaigns) return;
              setState(() => _mainTab = AdvertisingMainTab.otherCampaigns);
              _loadData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLevelTabs(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _tabShell(
      context,
      scroll: true,
      children: [
        _tabButton(
          context,
          title: t.translate('campaigns'),
          active: _metaLevel == MetaAdsLevel.campaigns,
          onTap: () => _switchLevel(MetaAdsLevel.campaigns),
        ),
        const SizedBox(width: 8),
        _tabButton(
          context,
          title: t.translate('adsets'),
          active: _metaLevel == MetaAdsLevel.adsets,
          onTap: () => _switchLevel(MetaAdsLevel.adsets),
        ),
        const SizedBox(width: 8),
        _tabButton(
          context,
          title: t.translate('ads'),
          active: _metaLevel == MetaAdsLevel.ads,
          onTap: () => _switchLevel(MetaAdsLevel.ads),
        ),
        if (_filteredCampaign != null) ...[
          const SizedBox(width: 8),
          _filterChip(
            context,
            label: _filteredCampaign!.name,
            onRemove: () {
              setState(() {
                _filteredCampaign = null;
                _filteredAdSet = null;
                _metaLevel = MetaAdsLevel.campaigns;
              });
              _fetchMetaList();
            },
          ),
        ],
        if (_filteredAdSet != null) ...[
          const SizedBox(width: 6),
          _filterChip(
            context,
            label: _filteredAdSet!.name,
            onRemove: () {
              setState(() {
                _filteredAdSet = null;
                _metaLevel = MetaAdsLevel.adsets;
              });
              _fetchMetaList();
            },
          ),
        ],
      ],
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
  }) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.buttonPrimaryBg.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.buttonPrimaryBg.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: colors.buttonPrimaryBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabShell(
    BuildContext context, {
    required List<Widget> children,
    bool scroll = false,
  }) {
    final colors = context.appColors;
    final row = Row(
      mainAxisSize: scroll ? MainAxisSize.min : MainAxisSize.max,
      children: children,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.48)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: scroll
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: row,
            )
          : row,
    );
  }

  Widget _tabButton(
    BuildContext context, {
    required String title,
    required bool active,
    required VoidCallback onTap,
    bool expand = false,
  }) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: expand ? double.infinity : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: active ? colors.buttonPrimaryBg : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.58),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? colors.buttonPrimaryFg : colors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'Gilroy',
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final summary = _summary;
    final currency = summary?.currency ?? 'USD';
    final revenueCurrency = summary?.revenueCurrency ?? 'TJS';
    final items = [
      _SummaryItem(
        title: t.translate('stat_spend'),
        value: summary == null ? '—' : _money(summary.spend, currency),
        color: const Color(0xFFF59E0B),
      ),
      _SummaryItem(
        title: t.translate('stat_new_leads'),
        value: summary == null ? '—' : _count(summary.newLeads),
        color: const Color(0xFF3B82F6),
      ),
      _SummaryItem(
        title: t.translate('stat_cpl'),
        value: summary?.cpl == null ? '—' : _money(summary!.cpl!, currency),
        color: const Color(0xFF8B5CF6),
      ),
      _SummaryItem(
        title: t.translate('stat_revenue'),
        value: summary == null
            ? '—'
            : _money(summary.revenue, revenueCurrency),
        color: const Color(0xFF22C55E),
      ),
      _SummaryItem(
        title: t.translate('stat_roi'),
        value: summary?.roi == null
            ? '—'
            : '${summary!.roi!.toStringAsFixed(0)}%',
        color: (summary?.roi ?? 0) < 0
            ? const Color(0xFFEF4444)
            : const Color(0xFF22C55E),
      ),
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _SummaryTile(
            item: items[index],
            loading: _isLoadingSummary && summary == null,
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_mainTab == AdvertisingMainTab.otherCampaigns) {
      final items = _otherCampaigns
          .where((item) =>
              _matches(item.name) || _matches(item.description) || _matches(item.source))
          .toList();
      if (items.isEmpty) return _emptySliver(context);
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _buildOtherCard(context, items[index]),
        ),
      );
    }

    switch (_metaLevel) {
      case MetaAdsLevel.campaigns:
        final items = _campaigns.where((item) => _matches(item.name)).toList();
        if (items.isEmpty) return _emptySliver(context);
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildCampaignCard(context, items[index]),
          ),
        );
      case MetaAdsLevel.adsets:
        final items = _adsets
            .where((item) =>
                _matches(item.name) || _matches(item.campaignName))
            .toList();
        if (items.isEmpty) return _emptySliver(context);
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildAdSetCard(context, items[index]),
          ),
        );
      case MetaAdsLevel.ads:
        final items = _ads
            .where((item) =>
                _matches(item.name) ||
                _matches(item.campaignName) ||
                _matches(item.adsetName))
            .toList();
        if (items.isEmpty) return _emptySliver(context);
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildAdCard(context, items[index]),
          ),
        );
    }
  }

  Widget _emptySliver(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: _buildMessage(
        context,
        AppLocalizations.of(context)!.translate('no_data_for_period'),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    String text, {
    String? action,
    VoidCallback? onAction,
  }) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(action)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, MetaAdsCampaign item) {
    final t = AppLocalizations.of(context)!;
    return _entityCard(
      context,
      title: item.name,
      status: _statusLabel(context, item.effectiveStatus, item.isActive),
      isActive: item.isActive,
      rows: _webMetrics(
        t,
        budget: _budgetText(t, item.budgetAmount, item.budgetType),
        spend: _money(item.spend),
        impressions: _count(item.impressions),
        reach: item.reach != null ? _count(item.reach!) : '—',
        results: item.results == null ? '—' : _count(item.results!),
        leadPrice: item.cpl == null ? '—' : _money(item.cpl!),
        revenue: _revenueText(item.revenue),
      ),
      onTap: () => _openCampaign(item),
    );
  }

  Widget _buildAdSetCard(BuildContext context, MetaAdsAdSet item) {
    final t = AppLocalizations.of(context)!;
    return _entityCard(
      context,
      title: item.name,
      subtitle: item.campaignName,
      status: _statusLabel(context, item.effectiveStatus, item.isActive),
      isActive: item.isActive,
      rows: _webMetrics(
        t,
        budget: '—',
        spend: _money(item.spend),
        impressions: _count(item.impressions),
        reach: item.reach != null ? _count(item.reach!) : '—',
        results: item.results == null ? '—' : _count(item.results!),
        leadPrice: item.cpl == null ? '—' : _money(item.cpl!),
        revenue: _revenueText(item.revenue),
      ),
      onTap: () => _openAdSet(item),
    );
  }

  Widget _buildAdCard(BuildContext context, MetaAdsAd item) {
    final t = AppLocalizations.of(context)!;
    final crm = _crmCampaignsByExternalId[item.externalId];
    return _entityCard(
      context,
      title: item.name,
      subtitle: item.adsetName ?? item.campaignName,
      status: _statusLabel(context, item.effectiveStatus, item.isActive),
      isActive: item.isActive,
      leading: item.thumbnailUrl,
      rows: _webMetrics(
        t,
        budget: '—',
        spend: _money(item.spend),
        impressions: _count(item.impressions),
        reach: item.reach != null ? _count(item.reach!) : '—',
        results: item.results == null ? '—' : _count(item.results!),
        leadPrice: item.cpl == null ? '—' : _money(item.cpl!),
        revenue: _revenueText(item.revenue),
      ),
      onTap: () {
        AdvertisingDetailsSheet.show(
          context,
          title: item.name,
          hierarchy: [
            item.campaignName,
            item.adsetName,
          ].whereType<String>().where((part) => part.isNotEmpty).join(' → '),
          status: item.effectiveStatus,
          isActive: item.isActive,
          thumbnailUrl: item.thumbnailUrl,
          previewUrl: item.previewUrl,
          dateFrom: _formattedStartDate,
          dateTo: _formattedEndDate,
          spend: item.spend,
          results: item.results,
          resultType: item.resultType,
          costPerResult: item.costPerResult,
          newLeads: item.newLeads ?? 0,
          returningLeads: item.returningLeads ?? 0,
          cpl: item.cpl,
          impressions: item.impressions,
          reach: item.reach,
          revenue: 0,
          crmCampaignId: crm?.id,
        );
      },
    );
  }

  Widget _buildOtherCard(BuildContext context, OtherAdvertisingCampaign item) {
    final t = AppLocalizations.of(context)!;
    final active = item.isActive;
    return _entityCard(
      context,
      title: item.name,
      subtitle: item.description,
      status: _statusLabel(context, item.status ?? '', active),
      isActive: active,
      rows: _webMetrics(
        t,
        budget: item.cost > 0 ? _money(item.cost) : '—',
        spend: _money(item.cost),
        impressions: '—',
        reach: '—',
        results: item.leadsCount > 0 ? _count(item.leadsCount) : '—',
        leadPrice: (item.leadsCount > 0 && item.cost > 0)
            ? _money(item.cost / item.leadsCount)
            : '—',
        revenue: '—',
        clients: item.clientsCount > 0 ? _count(item.clientsCount) : null,
      ),
      onTap: () {
        AdvertisingDetailsSheet.show(
          context,
          title: item.name,
          subtitle: item.description,
          status: item.status ?? '',
          isActive: active,
          spend: item.cost,
          newLeads: item.leadsCount,
          returningLeads: 0,
          impressions: 0,
          revenue: 0,
          crmCampaignId: item.id,
        );
      },
    );
  }

  Widget _entityCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String status,
    required bool isActive,
    required List<_Metric> rows,
    required VoidCallback onTap,
    String? leading,
  }) {
    final colors = context.appColors;
    final statusColor = isActive ? colors.success : colors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: TaskCardStyles.taskCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null && leading.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      leading,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null && subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (var start = 0; start < rows.length; start += 3) ...[
                if (start > 0) const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = start; i < start + 3 && i < rows.length; i++) ...[
                      if (i > start) const SizedBox(width: 8),
                      Expanded(child: _metricCell(context, rows[i])),
                    ],
                    for (var i = rows.length; i < start + 3; i++) ...[
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricCell(BuildContext context, _Metric metric) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metric.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Metric {
  final String label;
  final String value;
  const _Metric(this.label, this.value);
}

class _SummaryItem {
  final String title;
  final String value;
  final Color color;
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.color,
  });
}

class _SummaryTile extends StatelessWidget {
  final _SummaryItem item;
  final bool loading;

  const _SummaryTile({required this.item, required this.loading});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 132,
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(width: 4, color: item.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: loading
                    ? Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.buttonPrimaryBg,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.15,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color backgroundColor;

  _SliverHeaderDelegate({
    required this.child,
    required this.height,
    required this.backgroundColor,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      color: overlapsContent
          ? backgroundColor.withValues(alpha: 0.94)
          : Colors.transparent,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
