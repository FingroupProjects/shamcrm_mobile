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
        onRefresh: () async {
          // TODO: Implement data refresh
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Grid - Responsive
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
                        value: '1,847',
                        change: '+12.5%',
                        isPositive: true,
                        icon: Icons.people_outline,
                        iconColor: const Color(0xff6366F1),
                      ),
                      AnalyticsStatCard(
                        title: localizations?.translate('stat_closed_deals') ??
                            'Закрытых сделок',
                        value: '487',
                        change: '+8.2%',
                        isPositive: true,
                        icon: Icons.handshake_outlined,
                        iconColor: const Color(0xff10B981),
                      ),
                      AnalyticsStatCard(
                        title: localizations?.translate('stat_total_revenue') ??
                            'Общая выручка',
                        value: '\$284K',
                        change: '+15.3%',
                        isPositive: true,
                        icon: Icons.attach_money,
                        iconColor: const Color(0xffF59E0B),
                      ),
                      AnalyticsStatCard(
                        title: localizations?.translate('stat_conversion') ??
                            'Конверсия',
                        value: '26.4%',
                        change: '-2.1%',
                        isPositive: false,
                        icon: Icons.trending_up,
                        iconColor: const Color(0xffEC4899),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: chartSpacing * 1.5),

              // Charts - All responsive
              const ConversionChart(),
              SizedBox(height: chartSpacing),

              const SourcesChart(),
              SizedBox(height: chartSpacing),

              const ManagersChart(),
              SizedBox(height: chartSpacing),

              const SpeedGauge(),
              SizedBox(height: chartSpacing),

              const GoalsChart(),
              SizedBox(height: chartSpacing),

              const KpiChart(),
              SizedBox(height: chartSpacing),

              const OrdersChart(),
              SizedBox(height: chartSpacing),

              const ProductsChart(),
              SizedBox(height: chartSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
