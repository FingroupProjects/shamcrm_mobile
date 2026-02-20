import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/analytics/widgets/analytics_stat_card.dart';
import 'package:crm_task_manager/screens/analytics/widgets/analytics_filter_sheet.dart';
import 'package:crm_task_manager/screens/analytics/charts/conversion_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/sources_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/managers_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/speed_gauge.dart';
import 'package:crm_task_manager/screens/analytics/charts/goals_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/kpi_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/orders_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/products_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/lead_conversion_statuses_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/replies_messages_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/telephony_events_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/task_stats_by_project_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/connected_accounts_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/advertising_roi_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/targeted_ads_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/telephony_by_hour_chart.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/models/dashboard_setting_item.dart';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    Key? key,
    this.showAppBar = true,
    this.filterTrigger = 0,
    this.chartSettingsTrigger = 0,
    this.showStatistics = true,
  }) : super(key: key);

  final bool showAppBar;
  final int filterTrigger;
  final int chartSettingsTrigger;
  final bool showStatistics;

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const String _defaultPeriodKey = 'current_year';
  static const String _allPeriodKey = 'all';
  static const Set<String> _defaultHiddenChartKeys = {
    'replies_to_messages',
    'task_statistics_by_project',
    'targeted_advertising',
    'connected_accounts',
    'advertising_effectiveness',
    'calls_by_hour',
  };
  static const Map<String, String> _fallbackChartTitles = {
    'conversion': 'Конверсия лидов',
    'lead_sources': 'Источник лидов',
    'manager_deals': 'Сделки по менеджерам',
    'speed_chart': 'Средняя скорость обработки лидов',
    'achieving_goals': 'Выполнение целей',
    'achieving_tasks': 'Выполнение задач (KPI)',
    'online_store_orders': 'Заказы интернет-магазина',
    'top_selling_products': 'ТОП продаваемых товаров',
    'telephony_and_events': 'Телефония и события',
    'replies_to_messages': 'Ответы на сообщения',
    'task_statistics_by_project': 'Статистика задач по проектам',
    'project_statistics': 'Статистика по проектам',
    'targeted_advertising': 'Таргетированная реклама (Meta Ads)',
    'connected_accounts': 'Подключённые аккаунты (по каналам)',
    'advertising_effectiveness': 'Эффективность рекламы (ROI)',
    'conversion_by_statuses': 'Конверсия и количество по статусам',
    'calls_by_hour': 'Аналитика звонков по часам',
  };

  String? _selectedPeriodKey;
  List<String> _selectedManagerIds = [];
  List<String> _selectedFunnelIds = [];
  List<String> _selectedSourceIds = [];
  int _chartsVersion = 0;
  bool _isLoadingChartSettings = true;
  String? _chartSettingsError;
  final Map<String, String> _chartTitlesByKey = {};
  final Set<String> _availableChartKeys = {};
  List<DashboardSettingItem> _orderedChartSettings = [];

  // Stats data
  bool _hasLoadedStatsOnce = false;
  String _totalLeads = '0';
  String _closedDeals = '0';
  String _totalRevenue = '0';
  String _conversionRate = '0%';
  double _leadsChange = 0.0;
  double _dealsChange = 0.0;
  double _revenueChange = 0.0;
  double _conversionChange = 0.0;
  int _lastFilterTrigger = 0;
  int _lastChartSettingsTrigger = 0;
  bool _isLoadingLocalChartPrefs = true;
  Map<String, bool> _chartVisibility = {};

  @override
  void initState() {
    super.initState();
    _lastFilterTrigger = widget.filterTrigger;
    _lastChartSettingsTrigger = widget.chartSettingsTrigger;
    _selectedPeriodKey = _defaultPeriodKey;
    _initializeDefaultFilters();
    _loadStats();
    _loadDashboardSettings();
    _loadChartVisibilityPrefs();
  }

  Future<void> _initializeDefaultFilters() async {
    final apiService = ApiService();
    final organizationId = await apiService.getSelectedOrganization() ?? '1';
    final salesFunnelId = await apiService.getSelectedSalesFunnel();

    if (salesFunnelId != null && salesFunnelId.isNotEmpty && mounted) {
      setState(() {
        _selectedFunnelIds = [salesFunnelId];
      });
    }

    final payload = <String, dynamic>{
      'organization_id': organizationId,
      'period': _defaultPeriodKey,
      if (salesFunnelId != null && salesFunnelId.isNotEmpty)
        'sales_funnel_id': salesFunnelId,
      if (salesFunnelId != null && salesFunnelId.isNotEmpty)
        'salesFunnels': [salesFunnelId],
    };

    ApiService.setAnalyticsFilters(payload);
  }

  @override
  void didUpdateWidget(covariant AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showAppBar && widget.filterTrigger != _lastFilterTrigger) {
      _lastFilterTrigger = widget.filterTrigger;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showFilterSheet();
        }
      });
    }
    if (!widget.showAppBar &&
        widget.chartSettingsTrigger != _lastChartSettingsTrigger) {
      _lastChartSettingsTrigger = widget.chartSettingsTrigger;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showChartSettingsSheet();
        }
      });
    }
  }

  Future<String> _chartVisibilityPrefsKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID') ?? '0';
    final organizationId = prefs.getString('selectedOrganization') ?? '0';
    return 'crm_dashboard_chart_visibility_v1_${userId}_$organizationId';
  }

  Future<void> _loadChartVisibilityPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _chartVisibilityPrefsKey();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _chartVisibility = {};
          _isLoadingLocalChartPrefs = false;
        });
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        if (!mounted) return;
        setState(() {
          _chartVisibility = {};
          _isLoadingLocalChartPrefs = false;
        });
        return;
      }

      final map = <String, bool>{};
      decoded.forEach((k, v) {
        if (k is String && v is bool) {
          map[k] = v;
        }
      });

      if (!mounted) return;
      setState(() {
        _chartVisibility = map;
        _isLoadingLocalChartPrefs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chartVisibility = {};
        _isLoadingLocalChartPrefs = false;
      });
    }
  }

  Future<void> _saveChartVisibilityPrefs(Map<String, bool> value) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _chartVisibilityPrefsKey();
    await prefs.setString(key, jsonEncode(value));
  }

  bool _isChartEnabled(String canonicalKey) {
    final saved = _chartVisibility[canonicalKey];
    if (saved != null) return saved;
    return !_defaultHiddenChartKeys.contains(canonicalKey);
  }

  List<_ChartVisibilitySettingEntry> _buildChartSettingsEntries() {
    final entries = <_ChartVisibilitySettingEntry>[];
    final added = <String>{};

    for (final item in _orderedChartSettings) {
      final rawKey = item.nameEn.trim();
      if (rawKey.isEmpty) continue;
      final canonicalKey = _chartCanonicalKey(rawKey);
      if (canonicalKey == null || added.contains(canonicalKey)) {
        continue;
      }
      added.add(canonicalKey);
      entries.add(
        _ChartVisibilitySettingEntry(
          key: canonicalKey,
          title: item.name.trim().isNotEmpty
              ? item.name.trim()
              : (_fallbackChartTitles[canonicalKey] ?? canonicalKey),
        ),
      );
    }

    return entries;
  }

  Future<void> _loadDashboardSettings() async {
    setState(() {
      _isLoadingChartSettings = true;
      _chartSettingsError = null;
    });

    try {
      final apiService = ApiService();
      final settings = await apiService.getDashboardSettingsV2();

      final titlesByKey = <String, String>{};
      final keys = <String>{};
      final orderedSettings = <DashboardSettingItem>[];

      for (final DashboardSettingItem item in settings) {
        final key = item.nameEn.trim();
        if (key.isEmpty) continue;
        keys.add(key);
        titlesByKey[key] = item.name;
        orderedSettings.add(item);
      }

      orderedSettings.sort((a, b) {
        final aPos = a.position > 0 ? a.position : 1 << 30;
        final bPos = b.position > 0 ? b.position : 1 << 30;
        if (aPos != bPos) return aPos.compareTo(bPos);
        return a.id.compareTo(b.id);
      });

      if (!mounted) return;
      setState(() {
        _availableChartKeys
          ..clear()
          ..addAll(keys);
        _chartTitlesByKey
          ..clear()
          ..addAll(titlesByKey);
        _orderedChartSettings = orderedSettings;
        _isLoadingChartSettings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chartSettingsError = 'Не удалось загрузить настройки графиков.';
        _orderedChartSettings = [];
        _isLoadingChartSettings = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final apiService = ApiService();

      final stats = await apiService.getDashboardStatisticsV2();

      setState(() {
        _totalLeads = _formatCount(stats.leads.count);
        _closedDeals = _formatCount(stats.deals.count);
        _totalRevenue = _formatMoney(stats.totalSum.count);
        _conversionRate = '${stats.conversion.count.toStringAsFixed(2)}%';
        _leadsChange = stats.leads.percent;
        _dealsChange = stats.deals.percent;
        _revenueChange = stats.totalSum.percent;
        _conversionChange = stats.conversion.percent;
        _hasLoadedStatsOnce = true;
      });
    } catch (e) {
      // Keep default values on error
    }
  }

  String _formatCount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return _formatCount(value);
  }

  Future<void> _refreshData({bool reloadCharts = true}) async {
    ApiService.clearAnalyticsResponseCache();
    await Future.wait([
      _loadStats(),
      _loadDashboardSettings(),
    ]);

    if (reloadCharts) {
      // Hard reload for filter changes: recreate chart widgets.
      setState(() {
        _chartsVersion++;
      });
    }
  }

  String? _chartCanonicalKey(String key) {
    const aliases = <String, String>{
      'conversion': 'conversion',
      'lead_sources': 'lead_sources',
      'manager_deals': 'manager_deals',
      'speed_chart': 'speed_chart',
      'achieving_goals': 'achieving_goals',
      'achieving_tasks': 'achieving_tasks',
      'kpi_tasks': 'achieving_tasks',
      'task_kpi': 'achieving_tasks',
      'task_chart': 'achieving_tasks',
      'online_store_orders': 'online_store_orders',
      'top_selling_products': 'top_selling_products',
      'telephony_and_events': 'telephony_and_events',
      'replies_to_messages': 'replies_to_messages',
      'message_replies': 'replies_to_messages',
      'task_statistics_by_project': 'task_statistics_by_project',
      'task_stats_by_project': 'task_statistics_by_project',
      'project_statistics': 'task_statistics_by_project',
      'targeted_advertising': 'targeted_advertising',
      'connected_accounts': 'connected_accounts',
      'advertising_effectiveness': 'advertising_effectiveness',
      'conversion_by_statuses': 'conversion_by_statuses',
      'calls_by_hour': 'calls_by_hour',
      'telephony_and_events_by_hour': 'calls_by_hour',
    };
    return aliases[key];
  }

  Widget _buildStatsSkeletonCard() {
    return ShimmerWave(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffE5E7EB),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  List<Widget> _buildChartWidgets() {
    if (_isLoadingChartSettings || _isLoadingLocalChartPrefs) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xff1E2E52)),
          ),
        ),
      ];
    }

    if (_chartSettingsError != null && _availableChartKeys.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                _chartSettingsError!,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadDashboardSettings,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    final addedCanonicalKeys = <String>{};

    for (final item in _orderedChartSettings) {
      final rawKey = item.nameEn.trim();
      if (rawKey.isEmpty) continue;

      final canonicalKey = _chartCanonicalKey(rawKey);
      if (canonicalKey == null || addedCanonicalKeys.contains(canonicalKey)) {
        continue;
      }
      if (!_isChartEnabled(canonicalKey)) continue;

      final title = item.name.trim().isNotEmpty
          ? item.name
          : (_fallbackChartTitles[canonicalKey] ?? canonicalKey);

      Widget? chartWidget;
      switch (canonicalKey) {
        case 'conversion':
          chartWidget = ConversionChart(
              key: ValueKey('conversion_$_chartsVersion'), title: title);
          break;
        case 'lead_sources':
          chartWidget = SourcesChart(
              key: ValueKey('sources_$_chartsVersion'), title: title);
          break;
        case 'manager_deals':
          chartWidget = ManagersChart(
              key: ValueKey('managers_$_chartsVersion'), title: title);
          break;
        case 'speed_chart':
          chartWidget =
              SpeedGauge(key: ValueKey('speed_$_chartsVersion'), title: title);
          break;
        case 'achieving_goals':
          chartWidget =
              GoalsChart(key: ValueKey('goals_$_chartsVersion'), title: title);
          break;
        case 'achieving_tasks':
          chartWidget =
              KpiChart(key: ValueKey('kpi_$_chartsVersion'), title: title);
          break;
        case 'online_store_orders':
          chartWidget = OrdersChart(
              key: ValueKey('orders_$_chartsVersion'), title: title);
          break;
        case 'top_selling_products':
          chartWidget = ProductsChart(
              key: ValueKey('products_$_chartsVersion'), title: title);
          break;
        case 'telephony_and_events':
          chartWidget = TelephonyEventsChart(
            key: ValueKey('telephony_$_chartsVersion'),
            title: title,
          );
          break;
        case 'replies_to_messages':
          chartWidget = RepliesMessagesChart(
            key: ValueKey('replies_$_chartsVersion'),
            title: title,
          );
          break;
        case 'task_statistics_by_project':
          chartWidget = TaskStatsByProjectChart(
            key: ValueKey('task_stats_$_chartsVersion'),
            title: title,
          );
          break;
        case 'targeted_advertising':
          chartWidget = TargetedAdsChart(
            key: ValueKey('targeted_ads_$_chartsVersion'),
            title: title,
          );
          break;
        case 'connected_accounts':
          chartWidget = ConnectedAccountsChart(
            key: ValueKey('connected_$_chartsVersion'),
            title: title,
          );
          break;
        case 'advertising_effectiveness':
          chartWidget = AdvertisingRoiChart(
              key: ValueKey('roi_$_chartsVersion'), title: title);
          break;
        case 'conversion_by_statuses':
          chartWidget = LeadConversionStatusesChart(
            key: ValueKey('lead_statuses_$_chartsVersion'),
            title: title,
          );
          break;
        case 'calls_by_hour':
          chartWidget = TelephonyByHourChart(
            key: ValueKey('telephony_hour_$_chartsVersion'),
            title: title,
          );
          break;
      }

      if (chartWidget == null) continue;
      addedCanonicalKeys.add(canonicalKey);
      widgets.add(_KeepAliveChart(child: chartWidget));
    }

    if (widgets.isNotEmpty) return widgets;

    return const [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Нет включенных графиков',
          style: TextStyle(
            color: Color(0xff64748B),
            fontSize: 14,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
    ];
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AnalyticsFilterSheet(
          selectedPeriodKey: _selectedPeriodKey ?? _defaultPeriodKey,
          selectedManagers: _selectedManagerIds,
          selectedFunnels: _selectedFunnelIds,
          selectedSources: _selectedSourceIds,
          onApply: _applyAnalyticsFilters,
        ),
      ),
    );
  }

  void _showChartSettingsSheet() {
    final entries = _buildChartSettingsEntries();
    final tempVisibility = <String, bool>{
      for (final entry in entries) entry.key: _isChartEnabled(entry.key),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final maxHeight = MediaQuery.of(context).size.height * 0.82;

            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xffCBD5E1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Настройки CRM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1E2E52),
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Включите или выключите отображение графиков',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xff64748B),
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: entries.isEmpty
                          ? const Center(
                              child: Text(
                                'Нет доступных графиков',
                                style: TextStyle(
                                  color: Color(0xff64748B),
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                final enabled =
                                    tempVisibility[entry.key] ?? false;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    setSheetState(() {
                                      tempVisibility[entry.key] = !enabled;
                                    });
                                  },
                                  child: Ink(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xffE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Transform.scale(
                                          scale: 1.05,
                                          child: Switch(
                                            value: enabled,
                                            onChanged: (value) {
                                              setSheetState(() {
                                                tempVisibility[entry.key] =
                                                    value;
                                              });
                                            },
                                            activeThumbColor: Colors.white,
                                            inactiveThumbColor: Colors.white,
                                            activeTrackColor:
                                                const Color(0xff4F40EC),
                                            inactiveTrackColor:
                                                const Color(0xffD9D9D9),
                                            trackOutlineColor:
                                                WidgetStateProperty.resolveWith(
                                              (states) {
                                                if (states.contains(
                                                    WidgetState.selected)) {
                                                  return const Color(
                                                      0xff4F40EC);
                                                }
                                                return const Color(0xff8E8E93);
                                              },
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            entry.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xff1E2E52),
                                              fontFamily: 'Gilroy',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final saveMap = <String, bool>{
                            for (final entry in entries)
                              entry.key: tempVisibility[entry.key] ?? false,
                          };
                          await _saveChartVisibilityPrefs(saveMap);
                          if (!mounted) return;
                          setState(() {
                            _chartVisibility = saveMap;
                            _chartsVersion++;
                          });
                          if (Navigator.of(sheetContext).canPop()) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E2E52),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Gilroy',
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
      },
    );
  }

  Future<void> _applyAnalyticsFilters(
    String? periodKey,
    List<String> managerIds,
    List<String> funnelIds,
    List<String> sourceIds,
  ) async {
    final appliedPeriodKey = (periodKey != null && periodKey.isNotEmpty)
        ? periodKey
        : _defaultPeriodKey;
    final hasSpecificPeriod = appliedPeriodKey != _allPeriodKey;

    setState(() {
      _selectedPeriodKey = appliedPeriodKey;
      _selectedManagerIds = managerIds;
      _selectedFunnelIds = funnelIds;
      _selectedSourceIds = sourceIds;
    });

    final apiService = ApiService();
    final organizationId = await apiService.getSelectedOrganization() ?? '1';
    final selectedSalesFunnelId = funnelIds.isNotEmpty
        ? funnelIds.first
        : await apiService.getSelectedSalesFunnel();

    final payload = <String, dynamic>{
      'organization_id': organizationId,
      if (selectedSalesFunnelId != null && selectedSalesFunnelId.isNotEmpty)
        'sales_funnel_id': selectedSalesFunnelId,
      if (hasSpecificPeriod) 'period': appliedPeriodKey,
      if (managerIds.isNotEmpty) 'managers': managerIds,
      if (funnelIds.isNotEmpty) 'salesFunnels': funnelIds,
      if (sourceIds.isNotEmpty) 'sources': sourceIds,
    };

    if (kDebugMode) {
      debugPrint('🔵 AnalyticsScreen: Applying filters with payload: $payload');
    }

    ApiService.setAnalyticsFilters(payload);

    if (kDebugMode) {
      debugPrint(
          '🟢 AnalyticsScreen: Filters set globally, refreshing charts...');
    }

    await _refreshData(reloadCharts: true);
  }

  Widget _buildAnalyticsBody(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 360;

    final horizontalPadding = isTablet ? 24.0 : (isSmallPhone ? 12.0 : 16.0);
    final gridCrossAxisCount = isTablet ? 4 : 2;
    final cardSpacing = isTablet ? 20.0 : (isSmallPhone ? 12.0 : 16.0);
    final chartSpacing = isTablet ? 20.0 : (isSmallPhone ? 12.0 : 16.0);

    return RefreshIndicator(
      color: const Color(0xff1E2E52),
      backgroundColor: Colors.white,
      onRefresh: () => _refreshData(reloadCharts: false),
      child: Builder(
        builder: (context) {
          final chartWidgets = _buildChartWidgets();
          final viewportHeight = MediaQuery.of(context).size.height;

          final showStatsSection = widget.showStatistics;

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(horizontalPadding),
            cacheExtent: viewportHeight * 1.2,
            itemCount: (showStatsSection ? 1 : 0) + chartWidgets.length,
            itemBuilder: (context, index) {
              if (showStatsSection && index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = (constraints.maxWidth -
                                (cardSpacing * (gridCrossAxisCount - 1))) /
                            gridCrossAxisCount;
                        final cardHeight = cardWidth * 0.85;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: gridCrossAxisCount,
                          mainAxisSpacing: cardSpacing,
                          crossAxisSpacing: cardSpacing,
                          childAspectRatio: cardWidth / cardHeight,
                          children: _hasLoadedStatsOnce
                              ? [
                                  AnalyticsStatCard(
                                    title: localizations
                                            ?.translate('stat_total_leads') ??
                                        'Всего лидов',
                                    value: _totalLeads,
                                    change:
                                        '${_leadsChange.toStringAsFixed(2)}%',
                                    isPositive: _leadsChange >= 0,
                                    icon: Icons.people_outline,
                                    iconColor: const Color(0xff6366F1),
                                  ),
                                  AnalyticsStatCard(
                                    title: localizations
                                            ?.translate('stat_closed_deals') ??
                                        'Закрытых сделок',
                                    value: _closedDeals,
                                    change:
                                        '${_dealsChange.toStringAsFixed(2)}%',
                                    isPositive: _dealsChange >= 0,
                                    icon: Icons.handshake_outlined,
                                    iconColor: const Color(0xff10B981),
                                  ),
                                  AnalyticsStatCard(
                                    title: localizations
                                            ?.translate('stat_total_revenue') ??
                                        'Общая выручка',
                                    value: _totalRevenue,
                                    change:
                                        '${_revenueChange.toStringAsFixed(2)}%',
                                    isPositive: _revenueChange >= 0,
                                    icon: Icons.attach_money,
                                    iconColor: const Color(0xffF59E0B),
                                  ),
                                  AnalyticsStatCard(
                                    title: localizations
                                            ?.translate('stat_conversion') ??
                                        'Конверсия',
                                    value: _conversionRate,
                                    change:
                                        '${_conversionChange.toStringAsFixed(2)}%',
                                    isPositive: _conversionChange >= 0,
                                    icon: Icons.trending_up,
                                    iconColor: const Color(0xffEC4899),
                                  ),
                                ]
                              : [
                                  _buildStatsSkeletonCard(),
                                  _buildStatsSkeletonCard(),
                                  _buildStatsSkeletonCard(),
                                  _buildStatsSkeletonCard(),
                                ],
                        );
                      },
                    ),
                    SizedBox(height: chartSpacing * 1.5),
                  ],
                );
              }

              final chartIndex = index - 1;
              final resolvedChartIndex = showStatsSection ? chartIndex : index;
              final isLast = resolvedChartIndex == chartWidgets.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : chartSpacing),
                child: chartWidgets[resolvedChartIndex],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) {
      return Container(
        color: const Color(0xffF8FAFC),
        child: _buildAnalyticsBody(context),
      );
    }

    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Adaptive values based on screen width
    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 360;

    final horizontalPadding = isTablet ? 24.0 : (isSmallPhone ? 12.0 : 16.0);
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          localizations?.translate('appbar_analytics') ?? 'Аналитика',
          style: TextStyle(
            fontSize: isSmallPhone ? 18 : 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xff1E2E52),
            fontFamily: 'Gilroy',
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(
              right: horizontalPadding,
              top: 8,
              bottom: 8,
            ),
            child: ElevatedButton.icon(
              onPressed: _showFilterSheet,
              icon: const Icon(Icons.filter_list, size: 18),
              label: Text(
                localizations?.translate('filters') ?? 'Фильтры',
                style: TextStyle(
                  fontSize: isSmallPhone ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1E2E52),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallPhone ? 12 : 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xffE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: _buildAnalyticsBody(context),
    );
  }
}

class _KeepAliveChart extends StatefulWidget {
  final Widget child;

  const _KeepAliveChart({required this.child});

  @override
  State<_KeepAliveChart> createState() => _KeepAliveChartState();
}

class _KeepAliveChartState extends State<_KeepAliveChart>
    with AutomaticKeepAliveClientMixin<_KeepAliveChart> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _ChartVisibilitySettingEntry {
  final String key;
  final String title;

  const _ChartVisibilitySettingEntry({
    required this.key,
    required this.title,
  });
}
