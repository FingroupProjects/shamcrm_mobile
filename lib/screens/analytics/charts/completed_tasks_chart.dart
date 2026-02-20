import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/completed_tasks_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class CompletedTasksChart extends StatefulWidget {
  const CompletedTasksChart({super.key});

  @override
  State<CompletedTasksChart> createState() => _CompletedTasksChartState();
}

class _CompletedTasksChartState extends State<CompletedTasksChart> {
  bool _isLoading = true;
  String? _error;
  List<int> _monthly = [];

  static const List<String> _monthNames = [
    'Янв',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Июн',
    'Июл',
    'Авг',
    'Сен',
    'Окт',
    'Ноя',
    'Дек'
  ];

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
      final response = await apiService.getCompletedTasksChartV2();

      setState(() {
        _monthly = response.monthlyCompleted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  void _showDetails() {
    if (_monthly.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Выполненные задачи',
                      style: TextStyle(
                        fontSize: ResponsiveHelper(context).titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A),
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadData();
                    },
                    icon: Icon(Icons.refresh, color: Color(0xff64748B)),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper(context).smallSpacing),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _monthly.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final month = index < _monthNames.length
                        ? _monthNames[index]
                        : 'Месяц ${index + 1}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        month,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        _monthly[index].toString(),
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff22C55E),
                          fontFamily: 'Golos',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double get _maxValue {
    if (_monthly.isEmpty) return 1;
    final maxVal = _monthly.reduce((a, b) => a > b ? a : b);
    return maxVal == 0 ? 1 : maxVal.toDouble();
  }

  List<FlSpot> _spots() {
    return List.generate(_monthly.length, (index) {
      return FlSpot(index.toDouble(), _monthly[index].toDouble());
    });
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: ResponsiveHelper(context).iconSize,
                  height: ResponsiveHelper(context).iconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff22C55E), Color(0xff16A34A)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff22C55E).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: ResponsiveHelper(context).smallIconSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Expanded(
                  child: Text(
                    'Выполненные задачи по месяцам',
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff0F172A),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showDetails,
                  icon: Icon(Icons.crop_free,
                      color: Color(0xff64748B), size: ResponsiveHelper(context).smallIconSize),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xffF1F5F9),
                    minimumSize: Size(36, 36),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xffEF4444),
                            fontFamily: 'Golos',
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: LineChart(
                          LineChartData(
                            maxY: _maxValue * 1.2,
                            minY: 0,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: const Color(0xffE2E8F0),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: responsive.xSmallFontSize,
                                        color: Color(0xff64748B),
                                        fontFamily: 'Golos',
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 ||
                                        index >= _monthNames.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        _monthNames[index],
                                        style: TextStyle(
                                          fontSize: responsive.xSmallFontSize,
                                          color: Color(0xff64748B),
                                          fontFamily: 'Golos',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _spots(),
                                isCurved: true,
                                color: const Color(0xff22C55E),
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xff22C55E)
                                      .withValues(alpha: 0.12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
