import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class PieChartCalled extends StatelessWidget {
  const PieChartCalled({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
            AppLocalizations.of(context)!.translate('called_during'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black,
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
                        color: const Color(0xFF6C5CE7),
                        value: 90,
                        radius: 15,
                        showTitle: false, // Отключаем текст на секторе
                      ),
                      PieChartSectionData(
                        color: Colors.grey.shade300,
                        value: 10,
                        radius: 15,
                        showTitle: false, // Отключаем текст на секторе
                      ),
                    ],
                  ),
                ),
                Text(
                  '90%',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C5CE7),
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