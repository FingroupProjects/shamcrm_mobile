import 'package:crm_task_manager/models/page_2/call_analytics_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class PieChartNotCalled extends StatelessWidget {
  final CallAnalyticsResult statistics;
  const PieChartNotCalled({Key? key, required this.statistics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Используем unanswered_not_called_back напрямую как процент
    final unansweredPercentage = statistics.unansweredNotCalledBack.toDouble();

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('not_called'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    centerSpaceColor: Colors.transparent,
                    sections: [
                      PieChartSectionData(
                        color: context.appColors.buttonPrimaryBg,
                        value: unansweredPercentage,
                        radius: 15,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: context.appColors.borderSubtle,
                        value: 100 - unansweredPercentage,
                        radius: 15,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${unansweredPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
