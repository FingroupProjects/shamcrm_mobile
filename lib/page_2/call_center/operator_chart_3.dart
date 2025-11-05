import 'package:crm_task_manager/models/page_2/monthly_call_stats.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OperatorChart3 extends StatefulWidget {
  final int operatorId;
  final List<MonthlyCallStat> monthlyStats;

  const OperatorChart3({
    Key? key,
    required this.operatorId,
    required this.monthlyStats,
  }) : super(key: key);

  @override
  State<OperatorChart3> createState() => _OperatorChart3State();
}

class _OperatorChart3State extends State<OperatorChart3> {
  int? selectedBarIndex;
  int? selectedSegmentIndex;

  final List<Color> segmentColors = [
    const Color(0xFF3B82F6), // Входящие - синий
    const Color(0xFF10B981), // Исходящие - зеленый
    const Color(0xFFF59E0B), // Без ответа - оранжевый
    const Color(0xFFEF4444), // Пропущенные - красный
  ];

  List<String> getCallTypes(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.translate('incoming'),
      localizations.translate('outgoing'),
      localizations.translate('unanswered'),
      localizations.translate('missed'),
    ];
  }

  List<String> getMonthNames(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.translate('jan'),
      localizations.translate('feb'),
      localizations.translate('mar'),
      localizations.translate('apr'),
      localizations.translate('may'),
      localizations.translate('jun'),
      localizations.translate('jul'),
      localizations.translate('aug'),
      localizations.translate('sep'),
      localizations.translate('oct'),
      localizations.translate('nov'),
      localizations.translate('dec'),
    ];
  }

  String formatNumber(int value, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}${localizations.translate('million')}';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}${localizations.translate('thousand')}';
    } else {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final monthNames = getMonthNames(context);
    final callTypes = getCallTypes(context);
    final chartData = _getChartData();
    final hasData = widget.monthlyStats.isNotEmpty &&
        widget.monthlyStats.any((stat) => stat.total > 0);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            localizations.translate('operator_efficiency'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 24),
          if (hasData) _buildInteractiveLegend(),
          const SizedBox(height: 20),
          Stack(
            children: [
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: _getMaxY(),
                    barTouchData: BarTouchData(
                      enabled: hasData,
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (!hasData) return;
                        if (event is FlTapUpEvent && barTouchResponse != null) {
                          final touchedGroup = barTouchResponse.spot?.touchedBarGroup;
                          if (touchedGroup != null) {
                            _handleBarTap(touchedGroup.x, event.localPosition);
                          }
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 25,
                          getTitlesWidget: (value, meta) {
                            final monthIndex = value.toInt();
                            if (monthIndex >= 0 && monthIndex < monthNames.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Transform.rotate(
                                  angle: -3.14 / 2,
                                  child: Text(
                                    monthNames[monthIndex],
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 10,
                                      color: hasData ? const Color(0xFF9CA3AF) : Colors.grey.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: _getYAxisInterval(),
                          getTitlesWidget: (value, meta) {
                            if (value > _getMaxY()) return const SizedBox.shrink();
                            return Text(
                              formatNumber(value.toInt(), context),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 11,
                                color: hasData ? const Color(0xFF9CA3AF) : Colors.grey.withOpacity(0.5),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        left: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getYAxisInterval(),
                      getDrawingHorizontalLine: (value) {
                        if (value > _getMaxY()) return const FlLine(color: Colors.transparent);
                        return FlLine(
                          color: hasData ? const Color(0xFFF8F9FA) : Colors.grey.withOpacity(0.1),
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    barGroups: _buildInteractiveBarGroups(hasData),
                  ),
                ),
              ),
              if (hasData) _buildInteractiveChartLabels(),
              if (hasData && selectedBarIndex != null && selectedSegmentIndex != null)
                _buildValuePopup(),
              if (!hasData)
                Center(
                  child: Text(
                    localizations.translate('no_data_to_display'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (widget.monthlyStats.isEmpty) return 100;

    final maxTotal = widget.monthlyStats.map((stat) => stat.total).reduce((a, b) => a > b ? a : b);

    if (maxTotal == 0) return 100;
    return (maxTotal * 1.2).ceilToDouble();
  }

  double _getYAxisInterval() {
    final maxY = _getMaxY();
    if (maxY <= 50) return 25;
    if (maxY <= 100) return 25;
    if (maxY <= 200) return 50;
    if (maxY <= 500) return 100;
    return (maxY / 4).ceilToDouble();
  }

  List<List<int>> _getChartData() {
    List<List<int>> chartData = List.generate(12, (index) => [0, 0, 0, 0]);

    if (widget.monthlyStats.isNotEmpty) {
      for (var stat in widget.monthlyStats) {
        final index = stat.month - 1;
        if (index >= 0 && index < 12) {
          chartData[index] = [
            stat.incoming,
            stat.outgoing,
            stat.unanswered,
            stat.missed,
          ];
        }
      }
    }
    return chartData;
  }

  List<BarChartGroupData> _buildInteractiveBarGroups(bool hasData) {
    final chartData = _getChartData();
    return chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final values = entry.value;
      final total = widget.monthlyStats.isNotEmpty && index < widget.monthlyStats.length
          ? widget.monthlyStats.firstWhere((stat) => stat.month == index + 1, orElse: () => MonthlyCallStat(month: index + 1, incoming: 0, outgoing: 0, unanswered: 0, missed: 0, total: 0)).total
          : 0;
      final isSelected = selectedBarIndex == index;

      final displayTotal = total == 0 ? 0.1 : total.toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: displayTotal,
            color: hasData ? Colors.transparent : Colors.grey.withOpacity(0.3),
            width: hasData && isSelected ? 24 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            rodStackItems: hasData && total > 0
                ? [
                    if (values[0] > 0) BarChartRodStackItem(0, values[0].toDouble(), segmentColors[0]),
                    if (values[1] > 0)
                      BarChartRodStackItem(
                        values[0].toDouble(),
                        (values[0] + values[1]).toDouble(),
                        segmentColors[1],
                      ),
                    if (values[2] > 0)
                      BarChartRodStackItem(
                        (values[0] + values[1]).toDouble(),
                        (values[0] + values[1] + values[2]).toDouble(),
                        segmentColors[2],
                      ),
                    if (values[3] > 0)
                      BarChartRodStackItem(
                        (values[0] + values[1] + values[2]).toDouble(),
                        total.toDouble(),
                        segmentColors[3],
                      ),
                  ]
                : [],
          ),
        ],
        showingTooltipIndicators: [],
      );
    }).toList();
  }

  Widget _buildInteractiveLegend() {
    final chartData = _getChartData();
    final callTypes = getCallTypes(context);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: callTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = selectedSegmentIndex == index;

        return GestureDetector(
          onTap: () => _handleLegendTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 8 : 0,
              vertical: isSelected ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: isSelected ? segmentColors[index].withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(
                      color: segmentColors[index].withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 14 : 12,
                  height: isSelected ? 14 : 12,
                  decoration: BoxDecoration(
                    color: segmentColors[index],
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: segmentColors[index].withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                    color: isSelected ? segmentColors[index] : const Color(0xFF4A5568),
                  ),
                ),
                if (isSelected && selectedBarIndex != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: segmentColors[index],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatNumber(chartData[selectedBarIndex!][index], context),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractiveChartLabels() {
    final chartData = _getChartData();
    final totals = widget.monthlyStats.isNotEmpty
        ? List.generate(12, (index) => widget.monthlyStats.firstWhere((stat) => stat.month == index + 1, orElse: () => MonthlyCallStat(month: index + 1, incoming: 0, outgoing: 0, unanswered: 0, missed: 0, total: 0)).total)
        : List.generate(12, (_) => 0);

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartWidth = constraints.maxWidth - 35;
          final barWidth = chartWidth / 12;
          final maxY = _getMaxY();

          return Stack(
            children: totals.asMap().entries.map((entry) {
              final index = entry.key;
              final total = entry.value;
              final barCenterX = 35 + (index + 0.5) * barWidth;
              final isSelected = selectedBarIndex == index;

              if (total == 0) return const SizedBox.shrink();

              final topPosition = constraints.maxHeight -
                  (total / maxY * (constraints.maxHeight - 50)) -
                  (isSelected ? 28 : 20);

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                left: barCenterX - 8,
                top: topPosition.clamp(0.0, constraints.maxHeight - 40),
                child: GestureDetector(
                  onTap: () => _handleTotalTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 8 : 4,
                      vertical: isSelected ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2D3748) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
                          blurRadius: isSelected ? 6 : 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      formatNumber(total, context),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: isSelected ? 13 : 12,
                        color: isSelected ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildValuePopup() {
    final chartData = _getChartData();
    final callTypes = getCallTypes(context);
    final monthNames = getMonthNames(context);
    if (selectedBarIndex == null || selectedSegmentIndex == null) {
      return const SizedBox.shrink();
    }

    final selectedValue = chartData[selectedBarIndex!][selectedSegmentIndex!];

    return Positioned(
      top: 10,
      right: 10,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: segmentColors[selectedSegmentIndex!],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: segmentColors[selectedSegmentIndex!].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              callTypes[selectedSegmentIndex!],
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatNumber(selectedValue, context),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              monthNames[selectedBarIndex!],
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBarTap(int barIndex, Offset localPosition) {
    final values = _getChartData()[barIndex];
    final total = widget.monthlyStats.isNotEmpty
        ? widget.monthlyStats.firstWhere((stat) => stat.month == barIndex + 1, orElse: () => MonthlyCallStat(month: barIndex + 1, incoming: 0, outgoing: 0, unanswered: 0, missed: 0, total: 0)).total
        : 0;

    if (total == 0) return;

    setState(() {
      selectedBarIndex = barIndex;

      final relativeY = localPosition.dy / 250;
      final tapPosition = (1 - relativeY) * total;

      int segmentIndex = 0;
      double cumulative = 0;
      for (int i = 0; i < values.length; i++) {
        cumulative += values[i];
        if (tapPosition <= cumulative && values[i] > 0) {
          segmentIndex = i;
          break;
        }
      }

      selectedSegmentIndex = segmentIndex;
    });
  }

  void _handleLegendTap(int segmentIndex) {
    setState(() {
      if (selectedSegmentIndex == segmentIndex) {
        selectedSegmentIndex = null;
        selectedBarIndex = null;
      } else {
        selectedSegmentIndex = segmentIndex;
        final chartData = _getChartData();
        int? firstNonZeroMonth;
        for (int i = 0; i < chartData.length; i++) {
          if (chartData[i][segmentIndex] > 0) {
            firstNonZeroMonth = i;
            break;
          }
        }
        selectedBarIndex = firstNonZeroMonth ?? 0;
      }
    });
  }

  void _handleTotalTap(int barIndex) {
    final chartData = _getChartData();
    final total = widget.monthlyStats.isNotEmpty
        ? widget.monthlyStats.firstWhere((stat) => stat.month == barIndex + 1, orElse: () => MonthlyCallStat(month: barIndex + 1, incoming: 0, outgoing: 0, unanswered: 0, missed: 0, total: 0)).total
        : 0;

    if (total == 0) return;

    setState(() {
      selectedBarIndex = selectedBarIndex == barIndex ? null : barIndex;
      if (selectedBarIndex != null && selectedSegmentIndex == null) {
        for (int i = 0; i < chartData[barIndex].length; i++) {
          if (chartData[barIndex][i] > 0) {
            selectedSegmentIndex = i;
            break;
          }
        }
      }
    });
  }
}