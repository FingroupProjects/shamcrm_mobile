import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class ConversionChart extends StatefulWidget {
  const ConversionChart({super.key, required this.title});

  final String title;

  @override
  State<ConversionChart> createState() => _ConversionChartState();
}

class _ConversionChartState extends State<ConversionChart> {
  bool _isLoading = true;
  String? _error;
  List<double> _conversionData = [];

  String get _title => widget.title;

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

  static const List<String> _fullMonthNames = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь'
  ];

  static const List<double> _previewData = [
    18.2,
    21.5,
    19.8,
    24.1,
    22.4,
    25.3,
    27.6,
    29.1,
    26.8,
    28.0,
    27.2,
    26.4
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
      final response = await apiService.getLeadConversionDataV2();

      setState(() {
        _conversionData = response.monthlyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  double get _averagePercentage {
    if (_conversionData.isEmpty) return 0.0;
    return _conversionData.reduce((a, b) => a + b) / _conversionData.length;
  }

  double get _maxPercentage {
    if (_conversionData.isEmpty) return 0.0;
    return _conversionData.reduce((a, b) => a > b ? a : b);
  }

  int get _bestMonthIndex {
    if (_conversionData.isEmpty) return 0;
    double maxValue = _conversionData[0];
    int maxIndex = 0;

    for (int i = 1; i < _conversionData.length; i++) {
      if (_conversionData[i] > maxValue) {
        maxValue = _conversionData[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  String get _bestMonth {
    final index = _bestMonthIndex;
    return index < _fullMonthNames.length
        ? _fullMonthNames[index]
        : 'Неизвестно';
  }

  void _showDetails() {
    if (_conversionData.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title,
                style: TextStyle(
                  fontSize: ResponsiveHelper(context).titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                  fontFamily: 'Golos',
                ),
              ),
              SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _conversionData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final monthName = index < _fullMonthNames.length
                        ? _fullMonthNames[index]
                        : 'Месяц ${index + 1}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        monthName,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${_conversionData[index].toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff6366F1),
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

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty =
        _conversionData.isEmpty || _conversionData.every((v) => v == 0);
    final chartData = isEmpty ? _previewData : _conversionData;
    final maxPercentage = chartData.isEmpty
        ? 0.0
        : chartData.reduce((a, b) => a > b ? a : b);

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
                      colors: [Color(0xff6366F1), Color(0xff8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff0F172A),
                    fontFamily: 'Golos',
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showDetails,
                  icon: Icon(Icons.crop_free, color: Color(0xff64748B), size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xffF1F5F9),
                    minimumSize: Size(44, 44),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
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
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Color(0xffEF4444)),
                            SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Color(0xff64748B),
                                fontSize: responsive.bodyFontSize,
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
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: GestureDetector(
                          onTap: _showDetails,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 20, left: 10, bottom: 20),
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxPercentage + 5,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => Colors.white,
                                    tooltipBorder: const BorderSide(
                                        color: Color(0xffE2E8F0)),
                                    tooltipRoundedRadius: 8,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${rod.toY.toStringAsFixed(1)}%',
                                        TextStyle(
                                          color: Color(0xff0F172A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: responsive.bodyFontSize,
                                          fontFamily: 'Golos',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < chartData.length) {
                                          return RotatedBox(
                                            quarterTurns: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                _monthNames[value.toInt()],
                                                style: TextStyle(
                                                  color: Color(0xff64748B),
                                                  fontSize: responsive.smallFontSize,
                                                  fontFamily: 'Golos',
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}%',
                                          style: TextStyle(
                                            color: Color(0xff64748B),
                                            fontSize: responsive.smallFontSize,
                                            fontFamily: 'Golos',
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
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 5,
                                  getDrawingHorizontalLine: (value) {
                                    return const FlLine(
                                      color: Color(0xffE2E8F0),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: chartData
                                    .asMap()
                                    .entries
                                    .map((entry) =>
                                        _makeGroupData(entry.key, entry.value))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
          // Footer
          if (!_isLoading && _error == null && _conversionData.isNotEmpty)
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
                      Text(
                        'Средняя конверсия',
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_averagePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
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
                      Text(
                        'Лучший период',
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _bestMonth,
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
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

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xff6366F1), Color(0xff8B5CF6)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}
