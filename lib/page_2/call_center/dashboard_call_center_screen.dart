// lib/page_2/call_center/dashboard_screen.dart
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/call_analytics_model.dart';
import 'package:crm_task_manager/models/page_2/call_statistics1_model.dart'; // Added import
import 'package:crm_task_manager/page_2/call_center/call_log_item.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_not_called.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_called.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_waiting.dart';
import 'package:crm_task_manager/page_2/call_center/statistic_chart_1.dart'; // Added import
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
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter appBarSetState) {
            return AppBar(
              backgroundColor: Colors.white,
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
                          color: Colors.grey.shade500,
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
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearchActive && _tabController.index == 1
                        ? Icons.close
                        : Icons.search,
                    color: Colors.black,
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
                labelColor: const Color(0xFF6C5CE7),
                unselectedLabelColor: Colors.grey.shade600,
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
                indicatorColor: const Color(0xFF6C5CE7),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Added StatisticChart1
            FutureBuilder<CallStatistics>(
              future: _apiService.getCallStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка загрузки данных: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  );
                } else if (snapshot.hasData &&
                    snapshot.data!.result.isNotEmpty) {
                  return StatisticChart1(statistics: snapshot.data!);
                } else {
                  return const Center(
                    child: Text(
                      'Нет данных для отображения',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  );
                }
              },
            ),
            const Divider(thickness: 1, color: Colors.grey),
            // Existing pie charts
            FutureBuilder<CallAnalytics>(
              future: _apiService.getCallAnalytics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка загрузки данных: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  );
                } else if (snapshot.hasData &&
                    snapshot.data!.result.isNotEmpty) {
                  return Column(
                    children: [
                      
                      PieChartNotCalled(statistics: snapshot.data!.result),
                      Divider(thickness: 1, color: Colors.grey[300]),
                      PieChartAllCalls(statistics: snapshot.data!.result),
                      Divider(thickness: 1, color: Colors.grey[300]),
                      PieChartCalled(statistics: snapshot.data!.result),
                    ],
                  );
                } else {
                  return const Center(
                    child: Text(
                      'Нет данных для отображения',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return CallReportList(searchQuery: _searchController.text);
  }
}