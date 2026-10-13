import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/dashboard/profitability_dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'chart_scale.dart';
import 'example_chart_frame.dart';

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

  String getPeriodText(
      ProfitabilityTimePeriod period, AppLocalizations localizations) {
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
    return parseChartNumber(value);
  }

  void onPeriodChanged(ProfitabilityTimePeriod period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
      });

      context.read<SalesDashboardBloc>().add(ReloadProfitabilityData(period));
    }
  }



  List<ProfitabilityMonth> _exampleMonths() {
    const amounts = <int>[8, 12, 10, 15, 11, 18, 16, 14, 21, 19, 24, 22];
    return List.generate(
      amounts.length,
      (index) => ProfitabilityMonth(
        month: index + 1,
        monthName: '${index + 1}',
        profitabilityPercentage: amounts[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final periodData = _getSelectedPeriodData();
    final realMonths = periodData?.data.result.months ?? [];
    final showExample = !realMonths
        .map((month) => _parseProfitabilityValue(month.profitabilityPercentage))
        .any((value) => value != 0);
    final months = showExample ? _exampleMonths() : realMonths;
    final values = months.map(
      (month) => _parseProfitabilityValue(month.profitabilityPercentage),
    );
    final scale = ChartScale.fromValues(values, allowNegative: true);
    final textStyles = context.appTextStyles;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('profitability_sales'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Text(
                    localizations.translate('compare'),
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
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
                ? Center(
                    child: CircularProgressIndicator(
                      color: colors.buttonPrimaryBg,
                    ),
                  )
                : ExampleChartFrame(
                    show: showExample,
                    label: localizations.translate('no_data_to_display'),
                    child: ClipRect(
                        child: Padding(
                        padding: const EdgeInsets.only(
                            right: 16, top: 16, bottom: 8),
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.transparent,
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: false,
                              horizontalInterval: scale.interval,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: colors.borderSubtle
                                      .withValues(alpha: 0.38),
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
                                    final monthName =
                                        months[value.toInt()].monthName;
                                    return chartAxisLabel(
                                      localizedShortMonth(
                                        monthName,
                                        localizations,
                                      ),
                                      colors.textSecondary,
                                      meta,
                                    );
                                  },
                                  reservedSize: 36,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return chartValueLabel(
                                      formatChartAxis(value, localizations),
                                      colors.textSecondary,
                                      meta,
                                    );
                                  },
                                  reservedSize: 48,
                                  interval: scale.interval,
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
                            minX: months.length <= 1 ? -0.5 : -0.4,
                            maxX: months.length <= 1
                                ? 0.5
                                : (months.length - 1).toDouble() + 0.4,
                            minY: scale.minY,
                            maxY: scale.maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  months.length,
                                  (index) => FlSpot(
                                    index.toDouble(),
                                    _parseProfitabilityValue(
                                        months[index].profitabilityPercentage),
                                  ),
                                ),
                                isCurved: false,
                                color: colors.buttonPrimaryBg,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: colors.buttonPrimaryBg,
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
                                      colors.buttonPrimaryBg
                                          .withValues(alpha: 0.3),
                                      colors.buttonPrimaryBg
                                          .withValues(alpha: 0.0),
                                    ],
                                  ),
                                  cutOffY: scale.minY,
                                  applyCutOffY: true,
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: !showExample,
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
                                            text:
                                                '${touchedSpot.y.toStringAsFixed(1)}%',
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
                    builder: (context) =>
                        DetailedReportScreen(currentTabIndex: 8),
                  ),
                );
              },
              child: Text(
                localizations.translate('more_details'),
                style: textStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.buttonPrimaryBg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return CustomDropdown<ProfitabilityTimePeriod>(
      canClear: false,
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: colors.borderSubtle),
        expandedBorder: Border.all(color: colors.borderSubtle),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: colors.surfaceElevated.withValues(alpha: 0.72),
        expandedFillColor: colors.surfacePrimary,
        hintStyle: textStyles.bodySm.copyWith(color: colors.textSecondary),
        headerStyle: textStyles.bodySm.copyWith(color: colors.textPrimary),
        listItemStyle: textStyles.bodySm.copyWith(color: colors.textPrimary),
      ),
      items: ProfitabilityTimePeriod.values,
      initialItem: selectedPeriod,
      onChanged: (ProfitabilityTimePeriod? value) {
        if (value != null) {
          onPeriodChanged(value);
        }
      },
      hintBuilder: (context, hint, enabled) => Text(
        getPeriodText(selectedPeriod, AppLocalizations.of(context)!),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Gilroy',
          color: context.appColors.textPrimary,
        ),
      ),
      headerBuilder: (context, selectedItem, enabled) {
        return Text(
          getPeriodText(selectedItem, localizations),
          style: textStyles.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        );
      },
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return Text(
          getPeriodText(item, localizations),
          style: textStyles.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        );
      },
    );
  }
}
