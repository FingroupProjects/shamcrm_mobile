import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/source_of_leads_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class SourcesChart extends StatefulWidget {
  const SourcesChart({Key? key}) : super(key: key);

  @override
  State<SourcesChart> createState() => _SourcesChartState();
}

class _SourcesChartState extends State<SourcesChart> {
  int _touchedIndex = -1;
  bool _isLoading = true;
  String? _error;
  List<LeadSourceItem> _channels = [];
  String _bestSource = '';
  int _totalSources = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getSourceOfLeadsChartV2();

      setState(() {
        _channels = response.activeSources;
        _bestSource = response.bestSource;
        _totalSources =
            response.totalSources > 0 ? response.totalSources : _channels.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  // Predefined colors for channels
  final List<Color> _channelColors = [
    Color(0xffE1306C), // Instagram pink
    Color(0xff25D366), // WhatsApp green
    Color(0xff0088CC), // Telegram blue
    Color(0xff6366F1), // Indigo
    Color(0xffF59E0B), // Amber
    Color(0xff10B981), // Emerald
    Color(0xffEF4444), // Red
    Color(0xff8B5CF6), // Purple
    Color(0xff64748B), // Slate
    Color(0xff94A3B8), // Gray
  ];

  Color _getColorForIndex(int index) {
    return _channelColors[index % _channelColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: const Color(0xffE2E8F0)),
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
          // Header
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff10B981), Color(0xff059669)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Источники лидов',
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff0F172A),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff10B981),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Color(0xffEF4444)),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 14,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _channels.isEmpty
                        ? const Center(
                            child: Text(
                              'Нет данных',
                              style: TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 14,
                                fontFamily: 'Golos',
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(responsive.cardPadding),
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 60,
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sections:
                                    List.generate(_channels.length, (index) {
                                  final isTouched = index == _touchedIndex;
                                  final channel = _channels[index];
                                  final color = _getColorForIndex(index);

                                  return PieChartSectionData(
                                    value: channel.count.toDouble(),
                                    title: isTouched
                                        ? '${channel.name}\n${channel.count}'
                                        : '',
                                    color: color,
                                    radius: isTouched ? 65 : 60,
                                    titleStyle: TextStyle(
                                      fontSize: isTouched ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Golos',
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
          ),
          // Footer
          if (!_isLoading && _error == null && _channels.isNotEmpty)
            Container(
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xffE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Топ источник',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _bestSource.isNotEmpty
                            ? _bestSource
                            : (_channels.isNotEmpty ? _channels.first.name : '-'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Всего источников',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_totalSources',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
