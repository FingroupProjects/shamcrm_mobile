import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/dashboard/sales_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'chart_scale.dart';
import 'example_chart_frame.dart';

class SalesData {
  final String period;
  final double value;

  SalesData({required this.period, required this.value});
}

class SalesDynamicsLineChart extends StatefulWidget {
  const SalesDynamicsLineChart(this.allSalesDynamicsData, {super.key});

  final List<AllSalesDynamicsData> allSalesDynamicsData;

  @override
  State<SalesDynamicsLineChart> createState() => _SalesDynamicsLineChartState();
}

class _SalesDynamicsLineChartState extends State<SalesDynamicsLineChart> {
  SalesDynamicsTimePeriod selectedPeriod = SalesDynamicsTimePeriod.year;
  List<SalesData> salesData = [];

  @override
  void initState() {
    super.initState();
    salesData = _getDataForPeriod(selectedPeriod);
  }

  @override
  void didUpdateWidget(SalesDynamicsLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allSalesDynamicsData != widget.allSalesDynamicsData) {
      setState(() {
        salesData = _getDataForPeriod(selectedPeriod);
      });
    }
  }

  List<SalesData> _getDataForPeriod(SalesDynamicsTimePeriod period) {
    try {
      // Находим данные для выбранного периода
      final periodData = widget.allSalesDynamicsData.firstWhere(
        (item) => item.period == period,
      );

      // Преобразуем данные месяцев в формат для графика
      return periodData.data.result.months.map((monthData) {
        return SalesData(
          // Полное имя месяца. Короткую подпись собираем при отрисовке,
          // чтобы она следовала языку приложения, а не языку ответа сервера.
          period: monthData.monthName,
          value: parseChartNumber(monthData.totalAmount),
        );
      }).toList();
    } catch (e) {
      // Если данных для периода нет, возвращаем пустой список
      return [];
    }
  }

  void onPeriodChanged(SalesDynamicsTimePeriod? period) {
    if (period != null && selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
        salesData = _getDataForPeriod(period);
      });

      // Вызываем перезагрузку данных через Bloc
      context.read<SalesDashboardBloc>().add(ReloadSalesDynamicsData(period));
    }
  }

  String getPeriodText(
      SalesDynamicsTimePeriod period, AppLocalizations localizations) {
    switch (period) {
      case SalesDynamicsTimePeriod.year:
        return localizations.translate('current_year_lowercase');
      case SalesDynamicsTimePeriod.previousYear:
        return localizations.translate('previous_year');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isLoading = widget.allSalesDynamicsData.isEmpty;
    final hasValues = salesData.any((item) => item.value != 0);
    // Пустой период показывает пример графика, как в CRM.
    final showExample = !isLoading && !hasValues;
    final points = showExample ? _exampleSales() : salesData;
    // Отрицательная сумма тоже входит в шкалу. Иначе столбец
    // рисуется ниже нуля и залезает на «Подробнее».
    final scale = ChartScale.fromValues(
      points.map((item) => item.value),
      allowNegative: true,
    );
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
                localizations.translate('sales_dynamics'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              // Transform.translate(
              //   offset: const Offset(16, 0),
              //   child: DownloadPopupMenu(onDownload: (DownloadFormat type) {}),
              // ),
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

          const SizedBox(height: 12),

          // Столбцы, а не линия по нулю: высота каждого месяца — его сумма.
          SizedBox(
            height: 220,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3935E7),
                    ),
                  )
                : ExampleChartFrame(
                    show: showExample,
                    label: localizations.translate('no_data_to_display'),
                    // Обрезаем столбец по карточке, чтобы он не лёг на «Подробнее».
                    child: ClipRect(
                      child: Padding(
                      padding: const EdgeInsets.only(right: 4, top: 4),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final slot = points.isEmpty
                              ? 16.0
                              : constraints.maxWidth / points.length;
                          final barWidth = (slot * 0.42).clamp(8.0, 18.0);
                          return BarChart(
                            _salesBars(
                              points: points,
                              localizations: localizations,
                              plotMin: scale.minY,
                              plotMax: scale.maxY,
                              interval: scale.interval,
                              barWidth: barWidth,
                              interactive: !showExample,
                            ),
                          );
                        },
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
                        DetailedReportScreen(currentTabIndex: 6)));
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

  /// Пример на 12 месяцев. Цифры не с сервера, только форма будущего графика.
  List<SalesData> _exampleSales() {
    const amounts = <double>[
      42, 58, 51, 73, 88, 96, 110, 104, 128, 121, 146, 138,
    ];
    return List.generate(
      amounts.length,
      (index) => SalesData(period: '${index + 1}', value: amounts[index]),
    );
  }

  /// Три буквы месяца. «Июнь» не влезает в ячейку и уезжает вниз карточки.
  String _axisMonth(String name, AppLocalizations localizations) {
    final label = localizedShortMonth(name, localizations);
    if (label.length <= 3) return label;
    return label.substring(0, 3);
  }

  BarChartData _salesBars({
    required List<SalesData> points,
    required AppLocalizations localizations,
    required double plotMin,
    required double plotMax,
    required double interval,
    required double barWidth,
    required bool interactive,
  }) {
    final colors = context.appColors;
    final safeInterval = interval <= 0 ? (plotMax - plotMin).abs() : interval;
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: plotMin,
      maxY: plotMax,
      groupsSpace: 8,
      backgroundColor: Colors.transparent,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: safeInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: colors.borderSubtle.withValues(alpha: 0.38),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: interactive,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipMargin: 6,
          fitInsideVertically: true,
          fitInsideHorizontally: true,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            if (groupIndex < 0 || groupIndex >= points.length) return null;
            final month = points[groupIndex];
            return BarTooltipItem(
              '${_axisMonth(month.period, localizations)}\n',
              const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: formatChartAxis(month.value, localizations),
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: safeInterval,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  formatChartAxis(value, localizations),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _axisMonth(points[index].period, localizations),
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(points.length, (index) {
        final value = points[index].value;
        final belowZero = value < 0;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              width: barWidth,
              color: belowZero
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF00C853),
              borderRadius: BorderRadius.vertical(
                top: belowZero ? Radius.zero : const Radius.circular(4),
                bottom: belowZero ? const Radius.circular(4) : Radius.zero,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPeriodDropdown() {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return CustomDropdown<SalesDynamicsTimePeriod>(
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
      items: SalesDynamicsTimePeriod.values,
      initialItem: selectedPeriod,
      onChanged: (SalesDynamicsTimePeriod? value) {
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
