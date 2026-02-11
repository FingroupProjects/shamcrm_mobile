import 'package:flutter/material.dart';
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
import 'package:crm_task_manager/screens/analytics/charts/lead_statuses_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/deal_stats_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/lead_conversion_statuses_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/lead_channels_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/message_stats_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/replies_messages_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/completed_tasks_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/telephony_events_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/task_stats_by_project_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/connected_accounts_chart.dart';
import 'package:crm_task_manager/screens/analytics/charts/advertising_roi_chart.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Последние 30 дней';
  String _selectedManager = 'Все менеджеры';
  String _selectedFunnel = 'Все воронки';
  String _selectedSource = 'Все источники';

  // Stats data
  bool _isLoadingStats = true;
  String _totalLeads = '0';
  String _closedDeals = '0';
  String _totalRevenue = '0';
  String _conversionRate = '0%';
  double _leadsChange = 0.0;
  double _dealsChange = 0.0;
  double _revenueChange = 0.0;
  double _conversionChange = 0.0;

  // Keys for refreshing charts
  final GlobalKey<State> _conversionChartKey = GlobalKey();
  final GlobalKey<State> _sourcesChartKey = GlobalKey();
  final GlobalKey<State> _managersChartKey = GlobalKey();
  final GlobalKey<State> _speedGaugeKey = GlobalKey();
  final GlobalKey<State> _goalsChartKey = GlobalKey();
  final GlobalKey<State> _kpiChartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

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
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
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

  Future<void> _refreshData() async {
    // Reload stats
    await _loadStats();

    // Force rebuild of all charts by updating their keys
    setState(() {
      // Charts will rebuild automatically when parent rebuilds
    });
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
          selectedPeriod: _selectedPeriod,
          selectedManager: _selectedManager,
          selectedFunnel: _selectedFunnel,
          selectedSource: _selectedSource,
          onApply: (period, manager, funnel, source) {
            setState(() {
              _selectedPeriod = period;
              _selectedManager = manager;
              _selectedFunnel = funnel;
              _selectedSource = source;
            });
            // TODO: Apply filters to API calls
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Adaptive values based on screen width
    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 360;

    final horizontalPadding = isTablet ? 24.0 : (isSmallPhone ? 12.0 : 16.0);
    final gridCrossAxisCount = isTablet ? 4 : 2;
    final cardSpacing = isTablet ? 20.0 : (isSmallPhone ? 12.0 : 16.0);
    final chartSpacing = isTablet ? 20.0 : (isSmallPhone ? 12.0 : 16.0);

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
            fontFamily: 'Golos',
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
                  fontFamily: 'Golos',
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Grid - Responsive with real data
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth -
                          (cardSpacing * (gridCrossAxisCount - 1))) /
                      gridCrossAxisCount;
                  final cardHeight = cardWidth * 1.15; // Aspect ratio

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: gridCrossAxisCount,
                    mainAxisSpacing: cardSpacing,
                    crossAxisSpacing: cardSpacing,
                    childAspectRatio: cardWidth / cardHeight,
                    children: [
                      AnalyticsStatCard(
                        title: localizations?.translate('stat_total_leads') ??
                            'Всего лидов',
                        value: _isLoadingStats ? '...' : _totalLeads,
                        change: _isLoadingStats
                            ? '...'
                            : '${_leadsChange.toStringAsFixed(2)}%',
                        isPositive: !_isLoadingStats && _leadsChange >= 0,
                        icon: Icons.people_outline,
                        iconColor: const Color(0xff6366F1),
                      ),
                      AnalyticsStatCard(
                        title: localizations?.translate('stat_closed_deals') ??
                            'Закрытых сделок',
                        value: _isLoadingStats ? '...' : _closedDeals,
                        change: _isLoadingStats
                            ? '...'
                            : '${_dealsChange.toStringAsFixed(2)}%',
                        isPositive: !_isLoadingStats && _dealsChange >= 0,
                        icon: Icons.handshake_outlined,
                        iconColor: const Color(0xff10B981),
                      ),
                      AnalyticsStatCard(
                        title: localizations?.translate('stat_total_revenue') ??
                            'Общая выручка',
                        value: _isLoadingStats ? '...' : _totalRevenue,
                        change: _isLoadingStats
                            ? '...'
                            : '${_revenueChange.toStringAsFixed(2)}%',
                        isPositive: !_isLoadingStats && _revenueChange >= 0,
                        icon: Icons.attach_money,
                        iconColor: const Color(0xffF59E0B),
                      ),
                      AnalyticsStatCard(
                        title: localizations?.translate('stat_conversion') ??
                            'Конверсия',
                        value: _isLoadingStats ? '...' : _conversionRate,
                        change: _isLoadingStats
                            ? '...'
                            : '${_conversionChange.toStringAsFixed(2)}%',
                        isPositive:
                            !_isLoadingStats && _conversionChange >= 0,
                        icon: Icons.trending_up,
                        iconColor: const Color(0xffEC4899),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: chartSpacing * 1.5),

              // Charts - All responsive with keys for refresh
              ConversionChart(key: _conversionChartKey),
              SizedBox(height: chartSpacing),

              SourcesChart(key: _sourcesChartKey),
              SizedBox(height: chartSpacing),

              ManagersChart(key: _managersChartKey),
              SizedBox(height: chartSpacing),

              SpeedGauge(key: _speedGaugeKey),
              SizedBox(height: chartSpacing),

              GoalsChart(key: _goalsChartKey),
              SizedBox(height: chartSpacing),

              KpiChart(key: _kpiChartKey),
              SizedBox(height: chartSpacing),

              const OrdersChart(),
              SizedBox(height: chartSpacing),

              const ProductsChart(),
              SizedBox(height: chartSpacing),

              const LeadStatusesChart(),
              SizedBox(height: chartSpacing),

              const DealStatsChart(),
              SizedBox(height: chartSpacing),

              const LeadConversionStatusesChart(),
              SizedBox(height: chartSpacing),

              const LeadChannelsChart(),
              SizedBox(height: chartSpacing),

              const MessageStatsChart(),
              SizedBox(height: chartSpacing),

              const RepliesMessagesChart(),
              SizedBox(height: chartSpacing),

              const CompletedTasksChart(),
              SizedBox(height: chartSpacing),

              const TelephonyEventsChart(),
              SizedBox(height: chartSpacing),

              const TaskStatsByProjectChart(),
              SizedBox(height: chartSpacing),

              const ConnectedAccountsChart(),
              SizedBox(height: chartSpacing),

              const AdvertisingRoiChart(),
              SizedBox(height: chartSpacing),
            ],
          ),
        ),
      ),
    );
  }

}
