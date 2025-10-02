import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/dashboard/net_profit_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import 'download_popup_menu.dart';

enum ProfitPeriod { year, previousYear }

class ProfitData {
  final String month;
  final double value;

  ProfitData({required this.month, required this.value});
}

class NetProfitChart extends StatefulWidget {
  const NetProfitChart(this.netProfitData, {super.key});

  final NetProfitResponse netProfitData;

  @override
  State<NetProfitChart> createState() => _NetProfitChartState();
}

class _NetProfitChartState extends State<NetProfitChart> {
  ProfitPeriod selectedPeriod = ProfitPeriod.year;
  List<ProfitData> profitData = [];

  @override
  void initState() {
    super.initState();
    profitData = _getDataForPeriod(selectedPeriod);
  }

  @override
  void didUpdateWidget(NetProfitChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.netProfitData != widget.netProfitData) {
      setState(() {
        profitData = _getDataForPeriod(selectedPeriod);
      });
    }
  }

  List<ProfitData> _getDataForPeriod(ProfitPeriod period) {
    final months = widget.netProfitData.result.months;

    switch (period) {
      case ProfitPeriod.year:
      // Get all 12 months for current year
        return months.map((month) => ProfitData(
          month: _getShortMonthName(month.monthName),
          value: month.netProfit.toDouble(),
        )).toList();

      case ProfitPeriod.previousYear:
      // For previous year, you would need to fetch data from backend
      // For now, returning empty list or placeholder data
      // You should call API to get previous year data
        return [];
    }
  }

  String _getShortMonthName(String fullName) {
    // Convert full month names to short versions
    final monthMap = {
      'Январь': 'Янв',
      'Февраль': 'Фев',
      'Март': 'Мар',
      'Апрель': 'Апр',
      'Май': 'Май',
      'Июнь': 'Июн',
      'Июль': 'Июл',
      'Август': 'Авг',
      'Сентябрь': 'Сен',
      'Октябрь': 'Окт',
      'Ноябрь': 'Ноя',
      'Декабрь': 'Дек',
    };
    return monthMap[fullName] ?? fullName.substring(0, 3);
  }

  void onPeriodChanged(ProfitPeriod? period) {
    if (period != null && selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
        profitData = _getDataForPeriod(period);
      });
    }
  }

  String getPeriodText(ProfitPeriod period) {
    final currentYear = widget.netProfitData.result.year;
    switch (period) {
      case ProfitPeriod.year:
        return 'текущий год';
      case ProfitPeriod.previousYear:
        return 'прошлый год';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and menu icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('net_profit'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Transform.translate(
                  offset: const Offset(16, 0),
                  child: DownloadPopupMenu(onDownload: (DownloadFormat type) {})),
            ],
          ),

          const SizedBox(height: 16),

          // Period dropdown and Compare button
          Row(
            children: [
              Flexible(child: _buildPeriodDropdown()),
              const SizedBox(width: 12),
              Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      localizations.translate('compare'),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  )),
            ],
          ),

          const SizedBox(height: 24),

          // Chart content
          SizedBox(
            height: 300,
            child: profitData.isEmpty
                ? Center(
              child: Text(
                localizations.translate('no_data_to_display'),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: "Gilroy",
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.only(right: 16, top: 16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(),
                  minY: 0,
                  groupsSpace: 8,
                  backgroundColor: Colors.transparent,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tooltipMargin: 8,
                      fitInsideVertically: true,
                      fitInsideHorizontally: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${profitData[groupIndex].month}\n',
                          const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: _formatValue(rod.toY),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= profitData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                profitData[value.toInt()].month,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatAxisValue(value),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          );
                        },
                        reservedSize: 40,
                        interval: _calculateInterval(),
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: List.generate(
                    profitData.length,
                        (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: profitData[index].value,
                          color: const Color(0xFF4CAF50),
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Text(
                localizations.translate('more_details'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY() {
    if (profitData.isEmpty) return 100;
    final maxValue = profitData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    // If all values are 0, show a default scale
    if (maxValue == 0) return 100;
    return maxValue * 1.2;
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    return 500;
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _formatAxisValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toInt()}k';
    }
    return value.toInt().toString();
  }

  Widget _buildPeriodDropdown() {
    return CustomDropdown<ProfitPeriod>(
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
      ),
      items: ProfitPeriod.values,
      initialItem: selectedPeriod,
      onChanged: (ProfitPeriod? value) {
        if (value != null) {
          onPeriodChanged(value);
        }
      },
      headerBuilder: (context, selectedItem, enabled) {
        return Text(
          getPeriodText(selectedItem),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );
      },
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return Text(
          getPeriodText(item),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );
      },
    );
  }
}