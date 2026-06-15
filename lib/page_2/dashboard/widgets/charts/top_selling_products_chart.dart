import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../models/page_2/dashboard/top_selling_model.dart';
import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';

class TopSellingProductsChart extends StatefulWidget {
  const TopSellingProductsChart(this.allTopSellingData, {super.key});

  final List<AllTopSellingData> allTopSellingData;

  @override
  State<TopSellingProductsChart> createState() =>
      _TopSellingProductsChartState();
}

class _TopSellingProductsChartState extends State<TopSellingProductsChart> {
  static const double _barWidth = 16;
  static const double _groupsSpace = 12;
  static const double _chartHeight = 280;
  static const double _bottomTitlesReservedSize = 96;
  static const double _leftTitlesReservedSize = 48;
  static const double _labelWidth = 84;

  TopSellingTimePeriod selectedPeriod = TopSellingTimePeriod.year;

  List<TopSellingData> _getDataForSelectedPeriod() {
    try {
      final periodData = widget.allTopSellingData.firstWhere(
        (item) => item.period == selectedPeriod,
      );
      return periodData.data.data;
    } catch (e) {
      return [];
    }
  }

  void onPeriodChanged(TopSellingTimePeriod period) {
    if (selectedPeriod != period) {
      setState(() => selectedPeriod = period);
      context.read<SalesDashboardBloc>().add(ReloadTopSellingData(period));
    }
  }

  String getPeriodText(BuildContext context, TopSellingTimePeriod period) {
    final l = AppLocalizations.of(context)!;
    switch (period) {
      case TopSellingTimePeriod.day:
        return l.translate('day');
      case TopSellingTimePeriod.week:
        return l.translate('week');
      case TopSellingTimePeriod.month:
        return l.translate('month');
      case TopSellingTimePeriod.year:
        return l.translate('year');
    }
  }

  Widget _periodButton(TopSellingTimePeriod period) {
    final isSelected = selectedPeriod == period;
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonPrimaryBg
              : colors.surfaceElevated.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          getPeriodText(context, period),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? colors.textInverse : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta, List<String> names) {
    final index = value.toInt();
    if (value < 0 || index < 0 || index >= names.length) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: RotatedBox(
        quarterTurns: 3,
        child: SizedBox(
          width: _labelWidth,
          child: Text(
            _normalizeLabel(names[index]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ).copyWith(color: context.appColors.textSecondary),
          ),
        ),
      ),
    );
  }

  String _normalizeLabel(String label) {
    return label.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<BarChartGroupData> _buildBarGroups(List<TopSellingData> productsData) {
    return List.generate(
      productsData.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: productsData[i].totalQuantity.toDouble(),
            color: const Color(0xFF3935E7),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.appColors.buttonPrimaryBg,
                context.appColors.buttonPrimaryBg.withValues(alpha: 0.72),
              ],
            ),
            width: _barWidth,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartViewport(List<TopSellingData> productsData) {
    return _buildChart(
      barGroups: _buildBarGroups(productsData),
      maxY: _getMaxY(productsData),
      interval: _getInterval(productsData),
      names: productsData.map((e) => e.name).toList(),
      touchEnabled: true,
      getTooltipItem: (group, gi, rod, ri) {
        final p = productsData[gi];
        return BarTooltipItem(
          '${p.name}\n',
          const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          children: [
            TextSpan(
              text: rod.toY.toStringAsFixed(0),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  BarChart _buildChart({
    required List<BarChartGroupData> barGroups,
    required double maxY,
    required double interval,
    required List<String> names,
    required bool touchEnabled,
    BarTooltipItem? Function(BarChartGroupData, int, BarChartRodData, int)?
        getTooltipItem,
  }) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        groupsSpace: _groupsSpace,
        backgroundColor: Colors.transparent,
        barTouchData: touchEnabled
            ? BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tooltipMargin: 6,
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                  getTooltipItem: getTooltipItem,
                ),
              )
            : BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _bottomTitlesReservedSize,
              getTitlesWidget: (v, m) => _bottomTitle(v, m, names),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _leftTitlesReservedSize,
              interval: interval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                space: 6,
                child: Text(
                  _formatAxisValue(value),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ).copyWith(color: context.appColors.textSecondary),
                ),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          checkToShowHorizontalLine: (v) => v % interval == 0,
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.appColors.borderSubtle.withValues(alpha: 0.38),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _mockChart(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mockData = [45.0, 30, 65, 25, 55, 35];
    final mockNames = List.generate(
      mockData.length,
      (i) => '${l.translate('product')} ${'ABCDEF'[i]}',
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildChart(
          barGroups: List.generate(
            mockData.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: mockData[i].toDouble(),
                  color: Colors.grey[300],
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.appColors.borderSubtle.withValues(alpha: 0.9),
                      context.appColors.borderSubtle.withValues(alpha: 0.45),
                    ],
                  ),
                  width: _barWidth,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
          ),
          maxY: 80,
          interval: 20,
          names: mockNames,
          touchEnabled: false,
        ),
        Text(
          l.translate('no_data_to_display'),
          style: context.appTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final productsData = _getDataForSelectedPeriod();
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
          Text(
            l.translate('top_selling_products'),
            style: textStyles.titleMd.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _periodButton(TopSellingTimePeriod.day),
                const SizedBox(width: 8),
                _periodButton(TopSellingTimePeriod.week),
                const SizedBox(width: 8),
                _periodButton(TopSellingTimePeriod.month),
                const SizedBox(width: 8),
                _periodButton(TopSellingTimePeriod.year),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _chartHeight,
            child: productsData.isEmpty
                ? _mockChart(context)
                : _buildChartViewport(productsData),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DetailedReportScreen(currentTabIndex: 5),
                ));
              },
              child: Text(
                l.translate('more_details'),
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

  double _getInterval(List<TopSellingData> data) {
    if (data.isEmpty) return 1;
    final max = data
        .map((e) => e.totalQuantity.toDouble())
        .reduce((a, b) => a > b ? a : b);
    return _niceInterval(max);
  }

  double _getMaxY(List<TopSellingData> data) {
    if (data.isEmpty) return 10;
    final max = data
        .map((e) => e.totalQuantity.toDouble())
        .reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 10;
    final interval = _niceInterval(max);
    return (max / interval).ceil() * interval;
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toInt().toString();
  }

  double _niceInterval(double maxValue) {
    if (maxValue <= 0) return 1;
    final step = maxValue / 4;
    final mag = _pow10(step);
    final n = step / mag;
    if (n <= 1) return mag;
    if (n <= 2) return 2 * mag;
    if (n <= 5) return 5 * mag;
    return 10 * mag;
  }

  double _pow10(double value) {
    var m = 1.0;
    while (value >= 10) {
      value /= 10;
      m *= 10;
    }
    while (value > 0 && value < 1) {
      value *= 10;
      m /= 10;
    }
    return m;
  }
}
