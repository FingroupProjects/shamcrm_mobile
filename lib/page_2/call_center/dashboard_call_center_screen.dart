import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/call_analytics_model.dart';
import 'package:crm_task_manager/models/page_2/call_statistics1_model.dart';
import 'package:crm_task_manager/page_2/call_center/call_log_item.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_not_called.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_called.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_waiting.dart';
import 'package:crm_task_manager/page_2/call_center/statistic_chart_1.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter appBarSetState) {
            return AppBar(
              backgroundColor: context.appColors.surfacePrimary,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: _isSearchActive && _tabController.index == 1
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.translate('search'),
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    )
                  : Text(
                      AppLocalizations.of(context)!.translate('dashboard'),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: context.appColors.textPrimary,
                      ),
                  ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.appColors.iconPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearchActive && _tabController.index == 1
                        ? Icons.close
                        : Icons.search,
                    color: context.appColors.iconPrimary,
                  ),
                  onPressed: () {
                    appBarSetState(() {
                      if (!_isSearchActive) {
                        _isSearchActive = true;
                        if (_tabController.index != 1) {
                          _tabController.animateTo(1);
                        }
                      } else {
                        _isSearchActive = false;
                        _searchController.clear();
                        setState(() {});
                      }
                    });
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: context.appColors.buttonPrimaryBg,
                unselectedLabelColor: context.appColors.textSecondary,
                labelStyle: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                indicatorColor: context.appColors.buttonPrimaryBg,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                      text: AppLocalizations.of(context)!
                          .translate('statistics')),
                  Tab(text: AppLocalizations.of(context)!.translate('reports')),
                ],
              ),
            );
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _apiService.getCallStatistics(),
            _apiService.getCallAnalytics(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Показываем анимацию загрузки, пока данные загружаются
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              // Обработка ошибки
                  return Center(
                    child: Text(
                      'Ошибка загрузки данных: ${snapshot.error}',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: context.appColors.error,
                      ),
                    ),
                  );
            } else if (snapshot.hasData) {
              // Данные загружены успешно
              final callStatistics = snapshot.data![0] as CallStatistics;
              final callAnalytics = snapshot.data![1] as CallAnalytics;

              // Проверка на наличие данных
              if (callStatistics.result.isEmpty &&
                  !callAnalytics.result.isNotEmpty) {
                return  Center(
                  child: Text(
                      AppLocalizations.of(context)!
                              .translate('no_data_to_display'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                );
              }

              // Отображаем все графики одновременно
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (callAnalytics.result.isNotEmpty) ...[
                    PieChartNotCalled(statistics: callAnalytics.result),
                    Divider(thickness: 1, color: context.appColors.borderSubtle),
                    PieChartAllCalls(statistics: callAnalytics.result),
                    Divider(thickness: 1, color: context.appColors.borderSubtle),
                    PieChartCalled(statistics: callAnalytics.result),
                    Divider(thickness: 1, color: context.appColors.borderSubtle),
                  ],
                  if (callStatistics.result.isNotEmpty)
                    StatisticChart1(statistics: callStatistics),
                ],
              );
            } else {
              // На случай, если snapshot.data == null
              return  Center(
                child: Text(
                     AppLocalizations.of(context)!
                              .translate('no_data_to_display'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: context.appColors.textPrimary,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return CallReportList(
      searchQuery: _searchController.text,
      onResetSearch: () {},
    );
  }
}
