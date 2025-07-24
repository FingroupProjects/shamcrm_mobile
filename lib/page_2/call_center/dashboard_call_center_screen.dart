import 'package:crm_task_manager/page_2/call_center/call_log_item.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_not_called.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_waiting.dart';
import 'package:crm_task_manager/page_2/call_center/pie_chart_called.dart';
import 'package:crm_task_manager/page_2/call_center/statistic_chart_1.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
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
            Tab(text: AppLocalizations.of(context)!.translate('statistics')),
            Tab(text: AppLocalizations.of(context)!.translate('reports')),
          ],
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
          children: const [
            StatisticChart1(),
            PieChartNotCalled(),
            // PieChartWaiting(),
            PieChartCalled(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return const CallReportList();
  }
}