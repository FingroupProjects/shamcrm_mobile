import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/dashboard/profitability_dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'download_popup_menu.dart';

class ProfitabilityChart extends StatefulWidget {
  const ProfitabilityChart({super.key, required this.profitabilityData});

  final List<AllProfitabilityData> profitabilityData;

  @override
  State<ProfitabilityChart> createState() => _ProfitabilityChartState();
}

class _ProfitabilityChartState extends State<ProfitabilityChart> {
  ProfitabilityTimePeriod selectedPeriod = ProfitabilityTimePeriod.year;
  bool isLoading = false;
  bool isDownloading = false;

  String getPeriodText(ProfitabilityTimePeriod period, AppLocalizations localizations) {
    switch (period) {
      case ProfitabilityTimePeriod.last_year:
        return localizations.translate('last_year');
      case ProfitabilityTimePeriod.year:
        return localizations.translate('year');
    }
  }

  AllProfitabilityData? _getSelectedPeriodData() {
    try {
      return widget.profitabilityData.firstWhere(
            (data) => data.period == selectedPeriod,
      );
    } catch (e) {
      return null;
    }
  }

  double _parseProfitabilityValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  void onPeriodChanged(ProfitabilityTimePeriod period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
      });

      context.read<SalesDashboardBloc>().add(ReloadProfitabilityData(period));
    }
  }

  Map<String, double> _calculateYAxisRange(List<ProfitabilityMonth> months) {
    if (months.isEmpty) {
      return {'minY': 0, 'maxY': 100, 'interval': 20};
    }

    final values = months
        .map((m) => _parseProfitabilityValue(m.profitabilityPercentage))
        .toList();

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    final range = maxValue - minValue;
    final padding = range > 0 ? range * 0.2 : 10;

    double calculatedMin = minValue - padding;
    double calculatedMax = maxValue + padding;

    if (minValue >= 0) {
      calculatedMin = 0;
    }

    if (maxValue <= 0) {
      calculatedMax = 0;
    }

    if ((calculatedMax - calculatedMin) < 10) {
      final center = (calculatedMax + calculatedMin) / 2;
      calculatedMin = center - 5;
      calculatedMax = center + 5;
    }

    calculatedMin = (calculatedMin / 5).floor() * 5.0;
    calculatedMax = (calculatedMax / 5).ceil() * 5.0;

    final totalRange = calculatedMax - calculatedMin;
    double interval;
    if (totalRange <= 5) {
      interval = 1;
    } else if (totalRange <= 10) {
      interval = 2;
    } else if (totalRange <= 20) {
      interval = 5;
    } else if (totalRange <= 50) {
      interval = 10;
    } else if (totalRange <= 100) {
      interval = 20;
    } else if (totalRange <= 200) {
      interval = 25;
    } else if (totalRange <= 500) {
      interval = 50;
    } else {
      interval = 100;
    }

    return {
      'minY': calculatedMin,
      'maxY': calculatedMax,
      'interval': interval,
    };
  }

  Widget _buildMockChart(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final List<double> mockData = [5, 2, 8, 4, 1, 10, 7, 5, 1, 12, 9, 11];
    final List<String> mockMonthNames = [
      localizations.translate('january'),
      localizations.translate('february'),
      localizations.translate('march'),
      localizations.translate('april'),
      localizations.translate('may'),
      localizations.translate('june'),
      localizations.translate('july'),
      localizations.translate('august'),
      localizations.translate('september'),
      localizations.translate('october'),
      localizations.translate('november'),
      localizations.translate('december'),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.transparent,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= mockMonthNames.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Transform.rotate(
                          angle: -0.4,
                          child: Text(
                            mockMonthNames[value.toInt()],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      );
                    },
                    reservedSize: 70,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      );
                    },
                    reservedSize: 40,
                    interval: 5,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: 15,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    mockData.length,
                        (index) => FlSpot(index.toDouble(), mockData[index]),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: Colors.grey[300],
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.grey[300]!,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey[300]!.withOpacity(0.3),
                        Colors.grey[300]!.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(enabled: false),
            ),
          ),
        ),
        Text(
          localizations.translate('no_data_to_display'),
          style: const TextStyle(
            fontSize: 16,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final periodData = _getSelectedPeriodData();
    final months = periodData?.data.result.months ?? [];
    final yAxisRange = _calculateYAxisRange(months);

    // Check if all values are zero
    final hasData = months.isNotEmpty &&
        months.any((m) => _parseProfitabilityValue(m.profitabilityPercentage) != 0.0);

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('profitability_sales'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Flexible(child: _buildPeriodDropdown(localizations)),
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
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 300,
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3935E7),
              ),
            )
                : !hasData
                ? _buildMockChart(context)
                : Padding(
              padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: yAxisRange['interval'],
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final monthName = months[value.toInt()].monthName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.4,
                              child: Text(
                                localizations.translate(monthName.toLowerCase()),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          );
                        },
                        reservedSize: 70,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          );
                        },
                        reservedSize: 40,
                        interval: yAxisRange['interval'],
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (months.length - 1).toDouble(),
                  minY: yAxisRange['minY']!,
                  maxY: yAxisRange['maxY']!,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        months.length,
                            (index) => FlSpot(
                          index.toDouble(),
                          _parseProfitabilityValue(months[index].profitabilityPercentage),
                        ),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: const Color(0xFF5D5FEF),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF5D5FEF),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF5D5FEF).withOpacity(0.3),
                            const Color(0xFF5D5FEF).withOpacity(0.0),
                          ],
                        ),
                        cutOffY: yAxisRange['minY']!,
                        applyCutOffY: true,
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      tooltipMargin: 8,
                      fitInsideVertically: true,
                      fitInsideHorizontally: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final index = touchedSpot.x.toInt();
                          if (index >= 0 && index < months.length) {
                            final monthName = months[index].monthName;
                            return LineTooltipItem(
                              '${localizations.translate(monthName.toLowerCase())}\n',
                              const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(
                                  text: '${touchedSpot.y.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          }
                          return null;
                        }).toList();
                      },
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
              onTap: () {
                debugPrint("Подробнее pressed");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DetailedReportScreen(currentTabIndex: 8),
                  ),
                );
              },
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

  Widget _buildPeriodDropdown(AppLocalizations localizations) {
    return CustomDropdown<ProfitabilityTimePeriod>(
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
      ),
      items: ProfitabilityTimePeriod.values,
      initialItem: selectedPeriod,
      onChanged: (ProfitabilityTimePeriod? value) {
        if (value != null) {
          onPeriodChanged(value);
        }
      },
      headerBuilder: (context, selectedItem, enabled) {
        return Text(
          getPeriodText(selectedItem, localizations),
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
          getPeriodText(item, localizations),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );
      },
    );
  }
}