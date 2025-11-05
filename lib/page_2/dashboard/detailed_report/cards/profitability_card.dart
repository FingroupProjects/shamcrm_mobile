import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/page_2/dashboard/profitability_content_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';

class ProfitabilityCard extends StatelessWidget {
  final MonthData monthData;

  const ProfitabilityCard({
    Key? key,
    required this.monthData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthData.monthName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${localizations.translate('profitability')}: ${parseNumberToString(monthData.profitabilityPercentage)}%',
                  style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
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
