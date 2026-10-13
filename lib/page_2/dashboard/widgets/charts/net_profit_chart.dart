import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/dashboard/net_profit_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'chart_scale.dart';
import 'example_chart_frame.dart';

class NetProfitChart extends StatefulWidget {
  const NetProfitChart(this.netProfitData, {super.key});

  final List<AllNetProfitData> netProfitData;

  @override
  State<NetProfitChart> createState() => _NetProfitChartState();
}

class _NetProfitChartState extends State<NetProfitChart> {
  NetProfitPeriod selectedPeriod = NetProfitPeriod.year;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
  }

  AllNetProfitData? _getCurrentPeriodData() {
    try {
      return widget.netProfitData.firstWhere(
        (data) => data.period == selectedPeriod,
      );
    } catch (e) {
      return null;
    }
  }

  void onPeriodChanged(NetProfitPeriod? period) {
    if (period != null && selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
      });

      // Вызываем перезагрузку данных через Bloc
      context.read<SalesDashboardBloc>().add(ReloadNetProfitData(period));
    }
  }

  String getPeriodText(NetProfitPeriod period, AppLocalizations localizations) {
    switch (period) {
      case NetProfitPeriod.year:
        return localizations.translate('current_year');
      case NetProfitPeriod.last_year:
        return localizations.translate('last_year');
    }
  }

  // void _handleDownload(DownloadFormat format) async {
  //   setState(() {
  //     isDownloading = true;
  //   });
  //
  //   try {
  //     await Future.delayed(const Duration(seconds: 2));
  //   } catch (e) {
  //     // Handle error silently
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         isDownloading = false;
  //       });
  //     }
  //   }
  // }

  double _parseNetProfit(String netProfit) {
    return parseChartNumber(netProfit);
  }


  /// Те же 12 столбцов, что появятся, когда сервер пришлёт суммы.
  List<NetProfitMonth> _exampleMonths() {
    const amounts = <int>[40, 55, 48, 72, 36, 90, 84, 60, 110, 96, 130, 118];
    return List.generate(
      amounts.length,
      (index) => NetProfitMonth(
        month: index + 1,
        monthName: '${index + 1}',
        netProfit: '${amounts[index]}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currentData = _getCurrentPeriodData();
    final realMonths = currentData?.data.result.months ?? [];
    final showExample = !realMonths
        .map((month) => _parseNetProfit(month.netProfit))
        .any((value) => value != 0);
    // Пример рисуется тем же графиком, что и живые суммы.
    final months = showExample ? _exampleMonths() : realMonths;
    final values = months.map((month) => _parseNetProfit(month.netProfit));
    final scale = ChartScale.fromValues(values, allowNegative: true);
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

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
                localizations.translate('net_profit'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              // Transform.translate(
              //   offset: const Offset(16, 0),
              //   child: DownloadPopupMenu(
              //     onDownload: _handleDownload,
              //     loading: isDownloading,
              //     formats: const [
              //       DownloadFormat.png,
              //       DownloadFormat.svg,
              //       DownloadFormat.csv,
              //     ],
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(child: _buildPeriodDropdown()),
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
            child: ExampleChartFrame(
              show: showExample,
              label: localizations.translate('no_data_to_display'),
              child: ClipRect(
                    child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 16),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: scale.maxY,
                        minY: scale.minY,
                        groupsSpace: 20,
                        backgroundColor: Colors.transparent,
                        barTouchData: BarTouchData(
                          enabled: !showExample,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            tooltipMargin: 8,
                            fitInsideVertically: true,
                            fitInsideHorizontally: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${localizedShortMonth(months[groupIndex].monthName, localizations)}\n',
                                const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(
                                    text: formatChartAxis(rod.toY, localizations),
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
                                final index = value.toInt();
                                if (value < 0 ||
                                    index < 0 ||
                                    index >= months.length) {
                                  return const SizedBox.shrink();
                                }
                                return chartAxisLabel(
                                  localizedShortMonth(
                                    months[index].monthName,
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
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          horizontalInterval: scale.interval,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color:
                                  colors.borderSubtle.withValues(alpha: 0.38),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          months.length,
                          (index) {
                            final value =
                                _parseNetProfit(months[index].netProfit);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value,
                                  color: value >= 0
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFF5252),
                                  width: 16,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(8),
                                    topRight: const Radius.circular(8),
                                    bottomLeft: value < 0
                                        ? const Radius.circular(8)
                                        : Radius.zero,
                                    bottomRight: value < 0
                                        ? const Radius.circular(8)
                                        : Radius.zero,
                                  ),
                                ),
                              ],
                            );
                          },
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
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        DetailedReportScreen(currentTabIndex: 7)));
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



  Widget _buildPeriodDropdown() {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return CustomDropdown<NetProfitPeriod>(
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
      items: NetProfitPeriod.values,
      initialItem: selectedPeriod,
      onChanged: (NetProfitPeriod? value) {
        if (value != null) {
          onPeriodChanged(value);
        }
      },
      hintBuilder: (context, hint, enabled) {
        final localizations = AppLocalizations.of(context)!;
        return Text(
          getPeriodText(selectedPeriod, localizations),
          style: textStyles.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        );
      },
      headerBuilder: (context, selectedItem, enabled) {
        final localizations = AppLocalizations.of(context)!;
        return Text(
          getPeriodText(selectedItem, localizations),
          style: textStyles.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        );
      },
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        final localizations = AppLocalizations.of(context)!;
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
