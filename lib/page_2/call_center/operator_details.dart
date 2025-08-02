import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/call_summary_stats_model.dart';
import 'package:crm_task_manager/models/page_2/monthly_call_stats.dart';
import 'package:crm_task_manager/page_2/call_center/operator_chart_1.dart';
import 'package:crm_task_manager/page_2/call_center/operator_chart_2.dart';
import 'package:crm_task_manager/page_2/call_center/operator_chart_3.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class OperatorDetailsScreen extends StatefulWidget {
  final String operatorName;
  final int rating;
  final int operatorId;

  const OperatorDetailsScreen({
    Key? key,
    required this.operatorName,
    required this.rating,
    required this.operatorId,
  }) : super(key: key);

  @override
  State<OperatorDetailsScreen> createState() => _OperatorDetailsScreenState();
}

class _OperatorDetailsScreenState extends State<OperatorDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.operatorName,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: List.generate(5, (starIndex) {
                return Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Image.asset(
                    starIndex < widget.rating && widget.rating > 0
                        ? 'assets/icons/AppBar/star_on.png'
                        : 'assets/icons/AppBar/star_off.png',
                    width: 20,
                    height: 20,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          ApiService().getCallSummaryStats(widget.operatorId),
          ApiService().getMonthlyCallStats(widget.operatorId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Показываем анимацию загрузки
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
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            // Данные загружены успешно
            final callSummaryStats = snapshot.data![0] as CallSummaryStats;
            final monthlyCallStats = snapshot.data![1] as MonthlyCallStats;

            // Проверка на наличие данных
            if (callSummaryStats.result.totalCalls == 0 && monthlyCallStats.result.isEmpty) {
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

            // Отображаем все графики одновременно
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OperatorChartRating(
                    operatorId: widget.operatorId,
                    summaryStats: callSummaryStats,
                  ),
                  Divider(thickness: 1, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  OperatorChart2(
                    operatorId: widget.operatorId,
                    summaryStats: callSummaryStats,
                  ),
                  Divider(thickness: 1, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  OperatorChart3(
                    operatorId: widget.operatorId,
                    monthlyStats: monthlyCallStats.result,  
                  ),
                ],
              ),
            );
          } else {
            // На случай, если snapshot.data == null
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
    );
  }
}