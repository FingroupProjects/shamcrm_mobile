// lib/page_2/call_center/pie_chart_all_calls.dart
import 'package:crm_task_manager/models/page_2/call_analytics_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class PieChartAllCalls extends StatefulWidget {
  final CallAnalyticsResult statistics;
  const PieChartAllCalls({Key? key, required this.statistics}) : super(key: key);

  @override
  _PieChartAllCallsState createState() => _PieChartAllCallsState();
}

class _PieChartAllCallsState extends State<PieChartAllCalls> {
  int touchedIndex = -1;

  List<PieChartSectionData> _getSections() {
    final outgoing = widget.statistics.todaysTotalOutgoingCalls.toDouble();
    final missed = widget.statistics.todaysTotalMissedCalls.toDouble();

    return [
      PieChartSectionData(
        color: touchedIndex == 0
            ? const Color.fromARGB(255, 0, 184, 6)
            : const Color.fromARGB(200, 0, 184, 6),
        value: outgoing,
        radius: touchedIndex == 0 ? 25 : 20,
        showTitle: touchedIndex == 0,
        title: touchedIndex == 0 ? '$outgoing' : '',
        titleStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: touchedIndex == 1
            ? const Color.fromARGB(255, 255, 0, 0)
            : const Color.fromARGB(200, 255, 0, 0),
        value: missed,
        radius: touchedIndex == 1 ? 25 : 20,
        showTitle: touchedIndex == 1,
        title: touchedIndex == 1 ? '$missed' : '',
        titleStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ];
  }

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
            AppLocalizations.of(context)!.translate('all_calls'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _getSections(),
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (event is FlLongPressStart || event is FlTapDownEvent) {
                        if (pieTouchResponse != null &&
                            pieTouchResponse.touchedSection != null) {
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        }
                      } else if (event is FlLongPressEnd || event is FlTapUpEvent) {
                        touchedIndex = -1;
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                context,
                color: const Color.fromARGB(255, 0, 184, 6),
                label:
                    '${AppLocalizations.of(context)!.translate('outgoing')} (${widget.statistics.todaysTotalOutgoingCalls})',
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                context,
                color: const Color.fromARGB(255, 255, 0, 0),
                label:
                    '${AppLocalizations.of(context)!.translate('missed')} (${widget.statistics.todaysTotalMissedCalls})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context,
      {required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}