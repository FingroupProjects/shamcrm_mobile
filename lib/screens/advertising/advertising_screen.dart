import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/widgets/channel_source_icon.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/advertising/advertising_models.dart';
import 'package:crm_task_manager/models/sales_funnel/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/advertising/widgets/advertising_details_sheet.dart';
import 'package:crm_task_manager/screens/advertising/widgets/advertising_lead_form_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/return_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

enum AdvertisingMainTab { metaAds, otherCampaigns }

enum MetaAdsLevel { campaigns, adsets, ads }

enum DatePreset {
  last30Days,
  today,
  last7Days,
  currentMonth,
  lastMonth,
  last90Days,
  custom,
}

class AdvertisingScreen extends StatefulWidget {
  const AdvertisingScreen({super.key});

  @override
  State<AdvertisingScreen> createState() => _AdvertisingScreenState();
}

class _AdvertisingScreenState extends State<AdvertisingScreen> {
  final ApiService _apiService = ApiService();

  AdvertisingMainTab _mainTab = AdvertisingMainTab.metaAds;
  MetaAdsLevel _metaLevel = MetaAdsLevel.campaigns;
  DatePreset _datePreset = DatePreset.last30Days;

  late DateTime _startDate;
  late DateTime _endDate;

  SalesFunnel? _selectedFunnel;
  int? _selectedOrganizationId;

  // Filter drill-down
  MetaAdsCampaign? _filteredCampaign;
  MetaAdsAdSet? _filteredAdSet;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data
  bool _isLoadingSummary = false;
  MetaAdsSummary? _summary;

  bool _isLoadingList = false;
  List<MetaAdsCampaign> _campaigns = [];
  List<MetaAdsAdSet> _adsets = [];
  List<MetaAdsAd> _ads = [];
  List<OtherAdvertisingCampaign> _otherCampaigns = [];

  // CRM campaigns map (for lead linking external_id -> CRM id)
  Map<String, OtherAdvertisingCampaign> _crmCampaignsByExternalId = {};

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _applyPreset(DatePreset.last30Days, shouldRefresh: false);
    _searchController.addListener(_onSearchChanged);
    _initAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _initAndLoad() async {
    final funnelState = context.read<SalesFunnelBloc>().state;
    if (funnelState is SalesFunnelLoaded) {
      _selectedFunnel =
          funnelState.selectedFunnel ?? funnelState.funnels.firstOrNull;
    }

    final orgIdStr = await _apiService.getSelectedOrganization();
    if (orgIdStr != null) {
      _selectedOrganizationId = int.tryParse(orgIdStr);
    }

    _loadData();
    _loadCrmCampaignsLookup();
  }

  Future<void> _loadCrmCampaignsLookup() async {
    try {
      final list = await _apiService.getAllCrmAdvertisingCampaigns(
        salesFunnelId: _selectedFunnel?.id,
        organizationId: _selectedOrganizationId,
      );
      final map = <String, OtherAdvertisingCampaign>{};
      for (final item in list) {
        if (item.externalAdId != null && item.externalAdId!.isNotEmpty) {
          map[item.externalAdId!] = item;
        }
      }
      if (mounted) {
        setState(() {
          _crmCampaignsByExternalId = map;
        });
      }
    } catch (_) {}
  }

  void _applyPreset(DatePreset preset, {bool shouldRefresh = true}) {
    final now = DateTime.now();
    _datePreset = preset;

    switch (preset) {
      case DatePreset.today:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case DatePreset.last7Days:
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case DatePreset.last30Days:
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
        break;
      case DatePreset.last90Days:
        _startDate = now.subtract(const Duration(days: 90));
        _endDate = now;
        break;
      case DatePreset.currentMonth:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case DatePreset.lastMonth:
        final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
        final lastDayOfPrevMonth =
            firstDayOfCurrentMonth.subtract(const Duration(days: 1));
        _startDate = DateTime(
            lastDayOfPrevMonth.year, lastDayOfPrevMonth.month, 1);
        _endDate = lastDayOfPrevMonth;
        break;
      case DatePreset.custom:
        break;
    }

    if (shouldRefresh && mounted) {
      setState(() {});
      _loadData();
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        final colors = context.appColors;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.buttonPrimaryBg,
              onPrimary: Colors.white,
              surface: colors.surfacePrimary,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _datePreset = DatePreset.custom;
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  String get _formattedStartDate =>
      DateFormat('yyyy-MM-dd').format(_startDate);
  String get _formattedEndDate => DateFormat('yyyy-MM-dd').format(_endDate);

  Future<void> _loadData() async {
    setState(() {
      _errorMessage = null;
    });

    if (_mainTab == AdvertisingMainTab.metaAds) {
      await Future.wait([
        _fetchMetaSummary(),
        _fetchMetaList(),
      ]);
    } else {
      await _fetchOtherCampaigns();
    }
  }

  Future<void> _fetchMetaSummary() async {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _fetchMetaList() async {
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
          break;

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
          break;

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
          break;
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

  String _formatCurrency(double amount, [String currency = 'USD']) {
    final f = NumberFormat('#,##0.00', 'ru_RU');
    final formatted = f.format(amount).replaceAll(',', '.');
    if (currency == 'USD') return '$formatted \$';
    return '$formatted $currency';
  }

  String _formatInt(int count) {
    return NumberFormat('#,###', 'ru_RU').format(count).replaceAll(',', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary.withValues(alpha: 0.94),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: colors.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.translate('advertising'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          _buildFunnelButton(context),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                size: 22, color: colors.iconSecondary),
            onPressed: () {
              _loadData();
              _loadCrmCampaignsLookup();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: colors.buttonPrimaryBg,
        onRefresh: () async {
          await _loadData();
          await _loadCrmCampaignsLookup();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 10),

            // Top floating Custom TabBar (Meta Ads vs Прочие кампании)
            _buildCustomTabBar(context),

            const SizedBox(height: 4),

            // Date Preset Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDatePresets(context),
            ),

            const SizedBox(height: 14),

            // KPI Summary Cards
            if (_mainTab == AdvertisingMainTab.metaAds) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSummarySection(context),
              ),
              const SizedBox(height: 16),
            ],

            // Meta Ads Sub-Tabs (Кампании, Группы объявлений, Объявления)
            if (_mainTab == AdvertisingMainTab.metaAds) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMetaLevelTabs(context),
              ),
              const SizedBox(height: 12),
            ],

            // Breadcrumbs / Filter tags
            if (_filteredCampaign != null || _filteredAdSet != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBreadcrumbs(context),
              ),
              const SizedBox(height: 10),
            ],

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(context),
            ),

            const SizedBox(height: 14),

            // Cards Content List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoadingList
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                            color: colors.buttonPrimaryBg),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorState(context)
                      : _buildItemsList(context),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP CUSTOM TABBAR (Like lead_screen.dart)
  // ==========================================

  Widget _buildCustomTabBar(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    final isMeta = _mainTab == AdvertisingMainTab.metaAds;
    final isOther = _mainTab == AdvertisingMainTab.otherCampaigns;

    final metaCount = _metaLevel == MetaAdsLevel.campaigns
        ? _campaigns.length
        : _metaLevel == MetaAdsLevel.adsets
            ? _adsets.length
            : _ads.length;
    final otherCount = _otherCampaigns.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMainTabButtonUI(
              title: t.translate('meta_ads'),
              isActive: isMeta,
              count: metaCount,
              onTap: () {
                if (_mainTab != AdvertisingMainTab.metaAds) {
                  setState(() => _mainTab = AdvertisingMainTab.metaAds);
                  _loadData();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMainTabButtonUI(
              title: t.translate('other_campaigns'),
              isActive: isOther,
              count: otherCount,
              onTap: () {
                if (_mainTab != AdvertisingMainTab.otherCampaigns) {
                  setState(() => _mainTab = AdvertisingMainTab.otherCampaigns);
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabButtonUI({
    required String title,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? colors.buttonPrimaryBg : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.58),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? colors.buttonPrimaryFg : colors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.buttonPrimaryFg.withValues(alpha: 0.22)
                      : colors.buttonPrimaryBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? colors.buttonPrimaryFg.withValues(alpha: 0.35)
                        : colors.buttonPrimaryBg.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color:
                        isActive ? colors.buttonPrimaryFg : colors.buttonPrimaryBg,
                    fontSize: 11,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FUNNEL SELECTOR BUTTON
  // ==========================================

  Widget _buildFunnelButton(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
      builder: (context, state) {
        if (state is SalesFunnelLoaded && state.funnels.isNotEmpty) {
          final currentFunnel =
              _selectedFunnel ?? state.selectedFunnel ?? state.funnels.first;

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: colors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(Icons.filter_alt_outlined,
                  size: 16, color: colors.buttonPrimaryBg),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  currentFunnel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
              onPressed: () => _openFunnelPicker(context, state.funnels),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _openFunnelPicker(BuildContext context, List<SalesFunnel> funnels) {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Выберите воронку',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: funnels.length,
                  itemBuilder: (context, index) {
                    final f = funnels[index];
                    final isSel = _selectedFunnel?.id == f.id;
                    return ListTile(
                      title: Text(
                        f.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? colors.buttonPrimaryBg
                              : colors.textPrimary,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                      trailing: isSel
                          ? Icon(Icons.check, color: colors.buttonPrimaryBg)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedFunnel = f;
                          _filteredCampaign = null;
                          _filteredAdSet = null;
                        });
                        Navigator.pop(context);
                        context.read<SalesFunnelBloc>().add(SelectSalesFunnel(f));
                        _loadData();
                        _loadCrmCampaignsLookup();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // DATE PRESETS
  // ==========================================

  Widget _buildDatePresets(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    final presets = [
      {'label': t.translate('period_30_days'), 'preset': DatePreset.last30Days},
      {'label': t.translate('today'), 'preset': DatePreset.today},
      {'label': t.translate('period_7_days'), 'preset': DatePreset.last7Days},
      {'label': 'Текущий месяц', 'preset': DatePreset.currentMonth},
      {'label': 'Прошлый месяц', 'preset': DatePreset.lastMonth},
      {'label': t.translate('period_90_days'), 'preset': DatePreset.last90Days},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...presets.map((item) {
            final preset = item['preset'] as DatePreset;
            final isSelected = _datePreset == preset;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _applyPreset(preset),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.buttonPrimaryBg
                        : colors.surfacePrimary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? colors.buttonPrimaryBg
                          : colors.borderSubtle.withValues(alpha: 0.5),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.buttonPrimaryBg.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
            );
          }),
          // Custom Calendar Picker Chip
          InkWell(
            onTap: _pickCustomDateRange,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _datePreset == DatePreset.custom
                    ? colors.buttonPrimaryBg
                    : colors.surfacePrimary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _datePreset == DatePreset.custom
                      ? colors.buttonPrimaryBg
                      : colors.borderSubtle.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: _datePreset == DatePreset.custom
                        ? Colors.white
                        : colors.iconSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _datePreset == DatePreset.custom
                        ? '$_formattedStartDate – $_formattedEndDate'
                        : 'Период',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _datePreset == DatePreset.custom
                          ? Colors.white
                          : colors.textPrimary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SUMMARY SECTION (Styled with TaskCardStyles)
  // ==========================================

  Widget _buildSummarySection(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;
    final s = _summary;

    if (_isLoadingSummary && s == null) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: colors.buttonPrimaryBg),
      );
    }

    if (s == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Top 2 cards: Spend & New Leads
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                title: t.translate('stat_spend'),
                value: _formatCurrency(s.spend, s.currency),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                context,
                title: t.translate('stat_new_leads'),
                value: '${s.newLeads}',
                subtext: s.returningLeads > 0
                    ? '+${s.returningLeads} ${t.translate('recurring_leads_suffix')}'
                    : null,
                icon: Icons.group_add_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Bottom 3 cards: CPL, Revenue, ROI
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                title: t.translate('stat_cpl'),
                value: s.cpl != null
                    ? _formatCurrency(s.cpl!, s.currency)
                    : '—',
                icon: Icons.price_check_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                context,
                title: t.translate('stat_revenue'),
                value: _formatCurrency(s.revenue, s.revenueCurrency),
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                context,
                title: t.translate('stat_roi'),
                value: s.roi != null ? '${s.roi!.toInt()}%' : '—',
                icon: Icons.analytics_outlined,
                valueColor: s.roi != null && s.roi! >= 0
                    ? colors.success
                    : colors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtext,
    required IconData icon,
    Color? valueColor,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: TaskCardStyles.taskCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: colors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.textPrimary,
              fontFamily: 'Gilroy',
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 3),
            Text(
              subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: colors.buttonPrimaryBg,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // META LEVEL SUB-TABS (Кампании, Группы, Объявления)
  // ==========================================

  Widget _buildMetaLevelTabs(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    final levels = [
      {
        'level': MetaAdsLevel.campaigns,
        'title': t.translate('meta_campaigns'),
        'count': _campaigns.length,
      },
      {
        'level': MetaAdsLevel.adsets,
        'title': t.translate('meta_adsets'),
        'count': _adsets.length,
      },
      {
        'level': MetaAdsLevel.ads,
        'title': t.translate('meta_ads_tab'),
        'count': _ads.length,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: levels.map((item) {
          final level = item['level'] as MetaAdsLevel;
          final isSel = _metaLevel == level;
          final count = item['count'] as int;

          return Expanded(
            child: InkWell(
              onTap: () {
                if (_metaLevel != level) {
                  setState(() => _metaLevel = level);
                  _fetchMetaList();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? colors.buttonPrimaryBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: colors.buttonPrimaryBg.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        item['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                          color: isSel ? Colors.white : colors.textPrimary,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                    if (count > 0 && isSel) ...[
                      const SizedBox(width: 5),
                      Text(
                        '($count)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // BREADCRUMBS
  // ==========================================

  Widget _buildBreadcrumbs(BuildContext context) {
    final colors = context.appColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_filteredCampaign != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                backgroundColor: colors.surfaceElevated,
                deleteIconColor: colors.buttonPrimaryBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.borderSubtle),
                ),
                label: Text(
                  'Кампания: ${_filteredCampaign!.name}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Gilroy',
                  ),
                ),
                onDeleted: () {
                  setState(() {
                    _filteredCampaign = null;
                    _filteredAdSet = null;
                  });
                  _fetchMetaList();
                },
              ),
            ),
          if (_filteredAdSet != null)
            Chip(
              backgroundColor: colors.surfaceElevated,
              deleteIconColor: colors.buttonPrimaryBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.borderSubtle),
              ),
              label: Text(
                'Группа: ${_filteredAdSet!.name}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'Gilroy',
                ),
              ),
              onDeleted: () {
                setState(() => _filteredAdSet = null);
                _fetchMetaList();
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // SEARCH BAR
  // ==========================================

  Widget _buildSearchBar(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.42),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 14,
          color: colors.textPrimary,
          fontFamily: 'Gilroy',
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          hintText: t.translate('search'),
          hintStyle: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            fontFamily: 'Gilroy',
          ),
          prefixIcon:
              Icon(Icons.search_rounded, size: 20, color: colors.iconSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  color: colors.iconSecondary,
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ==========================================
  // ITEMS LIST
  // ==========================================

  Widget _buildItemsList(BuildContext context) {
    if (_mainTab == AdvertisingMainTab.otherCampaigns) {
      final filtered = _otherCampaigns.where((c) {
        if (_searchQuery.isEmpty) return true;
        return c.name.toLowerCase().contains(_searchQuery);
      }).toList();

      if (filtered.isEmpty) return _buildEmptyState(context);

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) =>
            _buildOtherCampaignCard(ctx, filtered[idx]),
      );
    }

    switch (_metaLevel) {
      case MetaAdsLevel.campaigns:
        final filtered = _campaigns.where((c) {
          if (_searchQuery.isEmpty) return true;
          return c.name.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState(context);

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => _buildCampaignCard(ctx, filtered[idx]),
        );

      case MetaAdsLevel.adsets:
        final filtered = _adsets.where((a) {
          if (_searchQuery.isEmpty) return true;
          return a.name.toLowerCase().contains(_searchQuery) ||
              (a.campaignName?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState(context);

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => _buildAdSetCard(ctx, filtered[idx]),
        );

      case MetaAdsLevel.ads:
        final filtered = _ads.where((a) {
          if (_searchQuery.isEmpty) return true;
          return a.name.toLowerCase().contains(_searchQuery) ||
              (a.campaignName?.toLowerCase().contains(_searchQuery) ?? false) ||
              (a.adsetName?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState(context);

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => _buildAdCard(ctx, filtered[idx]),
        );
    }
  }

  // ==========================================
  // CARDS IMPLEMENTATION (Strictly matching LeadCard / TaskCard)
  // ==========================================

  Widget _buildCampaignCard(BuildContext context, MetaAdsCampaign item) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;
    final crmMatch = _crmCampaignsByExternalId[item.externalId];

    final spendStr = _formatCurrency(item.spend);
    final resultsStr = item.results != null ? '${item.results}' : '—';
    final costPerResultStr = item.costPerResult != null
        ? '${_formatCurrency(item.costPerResult!)} за рез.'
        : null;
    final leadsStr = '${item.newLeads ?? 0}';
    final recurringLeadsStr = (item.returningLeads ?? 0) > 0
        ? '+${item.returningLeads} повторн.'
        : null;
    final cplStr = item.cpl != null ? _formatCurrency(item.cpl!) : '—';
    final impressionsStr = _formatInt(item.impressions);
    final reachStr = item.reach != null ? _formatInt(item.reach!) : null;

    return ReturnHighlightBox(
      section: 'advertising',
      itemId: 'campaign_${item.id}',
      child: GestureDetector(
        onTap: () {
          AdvertisingDetailsSheet.show(
            context,
            title: item.name,
            hierarchy: item.name,
            status: item.effectiveStatus,
            isActive: item.isActive,
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
            revenue: item.revenue ?? 0,
            currency: 'USD',
            crmCampaignId: crmMatch?.id,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(16),
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title + Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.appTextStyles.bodyLg.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        if (item.budgetAmount != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${_formatCurrency(item.budgetAmount!)} ${t.translate('per_day')}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusPill(context, item.isActive, item.effectiveStatus),
                ],
              ),

              const SizedBox(height: 12),

              // Row 2: Level indicator ("Уровень: Кампания")
              Row(
                children: [
                  Text(
                    'Уровень:',
                    style: context.appTextStyles.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: TaskCardStyles.dropdownDecoration(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Кампания',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Row 3: Metrics Grid (styled with Gilroy and clean card)
              _buildMetricsContainer(
                context,
                spend: spendStr,
                results: resultsStr,
                costPerResult: costPerResultStr,
                leads: leadsStr,
                recurringLeads: recurringLeadsStr,
                impressions: impressionsStr,
                reach: reachStr,
                cpl: cplStr,
              ),

              const SizedBox(height: 14),

              // Row 4: Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Drill-down button to adsets
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _filteredCampaign = item;
                        _metaLevel = MetaAdsLevel.adsets;
                      });
                      _fetchMetaList();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Группы объявлений (${item.adsCount ?? 0})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.buttonPrimaryBg,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: colors.buttonPrimaryBg,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Details sheet button
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      AdvertisingDetailsSheet.show(
                        context,
                        title: item.name,
                        hierarchy: item.name,
                        status: item.effectiveStatus,
                        isActive: item.isActive,
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
                        revenue: item.revenue ?? 0,
                        currency: 'USD',
                        crmCampaignId: crmMatch?.id,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Детали и лиды',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.buttonPrimaryBg,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: colors.buttonPrimaryBg,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdSetCard(BuildContext context, MetaAdsAdSet item) {
    final colors = context.appColors;
    final crmMatch = _crmCampaignsByExternalId[item.externalId];

    final spendStr = _formatCurrency(item.spend);
    final resultsStr = item.results != null ? '${item.results}' : '—';
    final costPerResultStr = item.costPerResult != null
        ? '${_formatCurrency(item.costPerResult!)} за рез.'
        : null;
    final leadsStr = '${item.newLeads ?? 0}';
    final recurringLeadsStr = (item.returningLeads ?? 0) > 0
        ? '+${item.returningLeads} повторн.'
        : null;
    final cplStr = item.cpl != null ? _formatCurrency(item.cpl!) : '—';
    final impressionsStr = _formatInt(item.impressions);
    final reachStr = item.reach != null ? _formatInt(item.reach!) : null;

    return ReturnHighlightBox(
      section: 'advertising',
      itemId: 'adset_${item.id}',
      child: GestureDetector(
        onTap: () {
          AdvertisingDetailsSheet.show(
            context,
            title: item.name,
            hierarchy: '${item.campaignName ?? ''} → ${item.name}',
            status: item.effectiveStatus,
            isActive: item.isActive,
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
            currency: 'USD',
            crmCampaignId: crmMatch?.id,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(16),
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title + Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.bodyLg.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusPill(context, item.isActive, item.effectiveStatus),
                ],
              ),

              // Hierarchy line (like TaskCard's taskProject)
              if (item.campaignName != null &&
                  item.campaignName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.campaignName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTextStyles.bodySm.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Row 2: Level indicator
              Row(
                children: [
                  Text(
                    'Уровень:',
                    style: context.appTextStyles.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: TaskCardStyles.dropdownDecoration(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Группа объявлений',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Row 3: Metrics Grid
              _buildMetricsContainer(
                context,
                spend: spendStr,
                results: resultsStr,
                costPerResult: costPerResultStr,
                leads: leadsStr,
                recurringLeads: recurringLeadsStr,
                impressions: impressionsStr,
                reach: reachStr,
                cpl: cplStr,
              ),

              const SizedBox(height: 14),

              // Row 4: Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Drill-down button to ads
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _filteredAdSet = item;
                        _metaLevel = MetaAdsLevel.ads;
                      });
                      _fetchMetaList();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Объявления (${item.adsCount ?? 0})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.buttonPrimaryBg,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: colors.buttonPrimaryBg,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Details sheet button
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      AdvertisingDetailsSheet.show(
                        context,
                        title: item.name,
                        hierarchy:
                            '${item.campaignName ?? ''} → ${item.name}',
                        status: item.effectiveStatus,
                        isActive: item.isActive,
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
                        currency: 'USD',
                        crmCampaignId: crmMatch?.id,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Детали и лиды',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.buttonPrimaryBg,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: colors.buttonPrimaryBg,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, MetaAdsAd item) {
    final colors = context.appColors;
    final crmMatch = _crmCampaignsByExternalId[item.externalId];

    final hierarchy =
        '${item.campaignName ?? ''}${item.campaignName != null && item.adsetName != null ? ' → ' : ''}${item.adsetName ?? ''}';

    final spendStr = _formatCurrency(item.spend);
    final resultsStr = item.results != null ? '${item.results}' : '—';
    final costPerResultStr = item.costPerResult != null
        ? '${_formatCurrency(item.costPerResult!)} за рез.'
        : null;
    final leadsStr = '${item.newLeads ?? 0}';
    final recurringLeadsStr = (item.returningLeads ?? 0) > 0
        ? '+${item.returningLeads} повторн.'
        : null;
    final cplStr = item.cpl != null ? _formatCurrency(item.cpl!) : '—';
    final impressionsStr = _formatInt(item.impressions);
    final reachStr = item.reach != null ? _formatInt(item.reach!) : null;

    final hasLeadForm =
        item.leadFormId != null || item.leadFormConfigured;

    return ReturnHighlightBox(
      section: 'advertising',
      itemId: 'ad_${item.id}',
      child: GestureDetector(
        onTap: () {
          AdvertisingDetailsSheet.show(
            context,
            title: item.name,
            hierarchy: hierarchy,
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
            currency: 'USD',
            crmCampaignId: crmMatch?.id,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(16),
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Creative image + Title + Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creative Thumbnail (Clean 44x44 rounded)
                  if (item.thumbnailUrl != null &&
                      item.thumbnailUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.thumbnailUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.campaign_rounded,
                              color: colors.iconSecondary, size: 22),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.campaign_rounded,
                          color: colors.iconSecondary, size: 22),
                    ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.bodyLg.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  _buildStatusPill(context, item.isActive, item.effectiveStatus),
                ],
              ),

              // Hierarchy line (campaign -> adset)
              if (hierarchy.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  hierarchy,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTextStyles.bodySm.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Row 2: Level indicator + Lead form button
              Row(
                children: [
                  Text(
                    'Уровень:',
                    style: context.appTextStyles.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: TaskCardStyles.dropdownDecoration(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Объявление',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (hasLeadForm)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        AdvertisingLeadFormDialog.show(
                          context,
                          formId: item.leadFormId ?? item.id.toString(),
                          formTitle: item.name,
                          adsCount: 1,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.borderSubtle.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded,
                                size: 14, color: colors.buttonPrimaryBg),
                            const SizedBox(width: 5),
                            Text(
                              'Лид-форма',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.buttonPrimaryBg,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Row 3: Metrics Grid
              _buildMetricsContainer(
                context,
                spend: spendStr,
                results: resultsStr,
                costPerResult: costPerResultStr,
                leads: leadsStr,
                recurringLeads: recurringLeadsStr,
                impressions: impressionsStr,
                reach: reachStr,
                cpl: cplStr,
              ),

              const SizedBox(height: 14),

              // Row 4: Details button
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    AdvertisingDetailsSheet.show(
                      context,
                      title: item.name,
                      hierarchy: hierarchy,
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
                      currency: 'USD',
                      crmCampaignId: crmMatch?.id,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Детали и лиды',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.buttonPrimaryBg,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colors.buttonPrimaryBg,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherCampaignCard(
      BuildContext context, OtherAdvertisingCampaign item) {
    final colors = context.appColors;

    final dateStr = item.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(item.createdAt!)
        : '—';

    return ReturnHighlightBox(
      section: 'advertising',
      itemId: 'other_${item.id}',
      child: GestureDetector(
        onTap: () {
          AdvertisingDetailsSheet.show(
            context,
            title: item.name,
            status: item.status ?? 'active',
            isActive: item.isActive,
            spend: item.cost,
            results: item.leadsCount,
            newLeads: item.leadsCount,
            returningLeads: 0,
            impressions: 0,
            revenue: 0,
            crmCampaignId: item.id,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(16),
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Source Icon + Title + Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChannelSourceIcon(
                    sourceName: item.source ?? 'other',
                    size: 32,
                    background: colors.surfacePrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.appTextStyles.bodyLg.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        if (item.source != null &&
                            item.source!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.source!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusPill(
                      context, item.isActive, item.status ?? 'active'),
                ],
              ),

              const SizedBox(height: 12),

              // Row 2: Level indicator
              Row(
                children: [
                  Text(
                    'Уровень:',
                    style: context.appTextStyles.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: TaskCardStyles.dropdownDecoration(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Кампания',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Row 3: Metrics Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfacePrimary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: colors.borderSubtle.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        context,
                        label: 'Лиды',
                        value: '${item.leadsCount}',
                        icon: Icons.group_outlined,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 30,
                        color: colors.borderSubtle.withValues(alpha: 0.4)),
                    Expanded(
                      child: _buildMetricItem(
                        context,
                        label: 'Клиенты',
                        value: '${item.clientsCount}',
                        icon: Icons.person_outline,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 30,
                        color: colors.borderSubtle.withValues(alpha: 0.4)),
                    Expanded(
                      child: _buildMetricItem(
                        context,
                        label: 'Расход',
                        value: _formatCurrency(item.cost),
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 30,
                        color: colors.borderSubtle.withValues(alpha: 0.4)),
                    Expanded(
                      child: _buildMetricItem(
                        context,
                        label: 'Дата',
                        value: dateStr,
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Row 4: Details button
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    AdvertisingDetailsSheet.show(
                      context,
                      title: item.name,
                      status: item.status ?? 'active',
                      isActive: item.isActive,
                      spend: item.cost,
                      results: item.leadsCount,
                      newLeads: item.leadsCount,
                      returningLeads: 0,
                      impressions: 0,
                      revenue: 0,
                      crmCampaignId: item.id,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Детали и лиды',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.buttonPrimaryBg,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colors.buttonPrimaryBg,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SHARED METRICS CONTAINER
  // ==========================================

  Widget _buildMetricsContainer(
    BuildContext context, {
    required String spend,
    required String results,
    String? costPerResult,
    required String leads,
    String? recurringLeads,
    required String impressions,
    String? reach,
    required String cpl,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Потрачено',
                  value: spend,
                  icon: Icons.payments_outlined,
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: colors.borderSubtle.withValues(alpha: 0.4)),
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Результат',
                  value: results,
                  subtext: costPerResult,
                  icon: Icons.flag_outlined,
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: colors.borderSubtle.withValues(alpha: 0.4)),
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Лиды',
                  value: leads,
                  subtext: recurringLeads,
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
              height: 1, color: colors.borderSubtle.withValues(alpha: 0.35)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Показы',
                  value: impressions,
                  icon: Icons.visibility_outlined,
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: colors.borderSubtle.withValues(alpha: 0.4)),
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Охват',
                  value: reach ?? '—',
                  icon: Icons.people_outline,
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: colors.borderSubtle.withValues(alpha: 0.4)),
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Цена лида',
                  value: cpl,
                  icon: Icons.price_check_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    String? subtext,
    required IconData icon,
  }) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFamily: 'Gilroy',
          ),
        ),
        if (subtext != null) ...[
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              fontFamily: 'Gilroy',
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // STATUS PILL (Matching TaskCard Priority & ShamCRM Web)
  // ==========================================

  Widget _buildStatusPill(
      BuildContext context, bool isActive, String statusText) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    final isAct = isActive ||
        statusText.toUpperCase() == 'ACTIVE' ||
        statusText.toLowerCase() == 'active';

    String label;
    if (isAct) {
      label = t.translate('ad_status_active');
    } else if (statusText.toUpperCase() == 'CAMPAIGN_PAUSED') {
      label = 'Кампания остановлена';
    } else {
      label = t.translate('ad_status_paused');
    }

    final activeColor = const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAct
            ? activeColor.withValues(alpha: 0.16)
            : colors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isAct
              ? activeColor.withValues(alpha: 0.45)
              : colors.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAct ? activeColor : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAct ? activeColor : colors.textSecondary,
              fontFamily: 'Gilroy',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.campaign_outlined,
                size: 48, color: colors.iconSecondary),
            const SizedBox(height: 12),
            Text(
              t.translate('no_data_for_period'),
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 40, color: colors.error),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Ошибка загрузки данных',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: 'Gilroy',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.buttonPrimaryBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _loadData,
              child: const Text('Повторить',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
