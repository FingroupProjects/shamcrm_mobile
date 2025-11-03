import 'package:crm_task_manager/models/page_2/call_summary_stats_model.dart';
import 'package:flutter/material.dart';

class OperatorChartRating extends StatelessWidget {
  final int operatorId;
  final CallSummaryStats summaryStats;

  const OperatorChartRating({
    Key? key,
    required this.operatorId,
    required this.summaryStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final averageCallDuration = _formatDuration(summaryStats.result.averageCallDuration);
    final averageDailyDuration = _formatDailyDuration(summaryStats.result.averageDailyDuration);

    final List<Map<String, dynamic>> cardData = [
      {
        'title': 'В среднем на один звонок',
        'mainValue': averageCallDuration['minutes'].toString(),
        'mainUnit': 'мин',
        'secondaryValue': averageCallDuration['seconds'].toString(),
        'secondaryUnit': 'сек',
        'backgroundColor': const Color(0xFFBFDBFE),
        'textColor': const Color(0xFF1E40AF),
        'icon': Icons.chat_bubble_outline,
        'details': [
          {'label': 'Самый долгий', 'value': '45 мин'},
          {'label': 'Самый короткий', 'value': '30 сек'},
          {'label': 'Медиана', 'value': '22 мин'},
        ],
      },
      {
        'title': 'В среднем в день',
        'mainValue': averageDailyDuration['hours'].toString(),
        'mainUnit': 'час',
        'secondaryValue': averageDailyDuration['minutes'].toString(),
        'secondaryUnit': 'мин',
        'backgroundColor': const Color(0xFFBBF7D0),
        'textColor': const Color(0xFF047857),
        'icon': Icons.access_time_outlined,
        'details': [
          {'label': 'Максимум в день', 'value': '12 час 30 мин'},
          {'label': 'Минимум в день', 'value': '8 час 15 мин'},
          {'label': 'Всего за неделю', 'value': '72 час 20 мин'},
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            '    Длительность разговора',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(
            children: cardData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == 0 ? 8 : 0,
                    left: index == 1 ? 8 : 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: data['backgroundColor'],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              data['icon'],
                              color: data['textColor'],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['title'],
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: data['textColor'].withOpacity(0.8),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      data['mainValue'],
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 32,
                                        color: data['textColor'],
                                        height: 0.9,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      data['mainUnit'],
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: data['textColor'].withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      data['secondaryValue'],
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 24,
                                        color: data['textColor'],
                                        height: 0.9,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      data['secondaryUnit'],
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: data['textColor'].withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Map<String, int> _formatDuration(double seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = (seconds % 60).round();
    return {'minutes': minutes, 'seconds': remainingSeconds};
  }

  Map<String, int> _formatDailyDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int remainingMinutes = (seconds % 3600) ~/ 60;
    return {'hours': hours, 'minutes': remainingMinutes};
  }
}