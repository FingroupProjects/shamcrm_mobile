import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../models/page_2/dashboard/top_selling_model.dart';
import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'chart_scale.dart';
import 'example_chart_frame.dart';

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

  List<TopSellingData> _exampleProducts() {
    TopSellingData item(int id, String name, int quantity) {
      return TopSellingData(
        id: id,
        name: name,
        category: '',
        totalQuantity: quantity,
        totalAmount: '0',
        avgPrice: '0',
      );
    }

    return [
      item(1, 'Товар 1', 18),
      item(2, 'Товар 2', 14),
      item(3, 'Товар 3', 11),
      item(4, 'Товар 4', 8),
      item(5, 'Товар 5', 6),
    ];
  }

  Widget _buildChartViewport(
    List<TopSellingData> productsData, {
    bool interactive = true,
  }) {
    final scale = ChartScale.fromValues(
      productsData.map((item) => item.totalQuantity.toDouble()),
    );
    final chart = _buildChart(
      barGroups: _buildBarGroups(productsData),
      maxY: scale.maxY,
      interval: scale.interval,
      names: productsData.map((e) => e.name).toList(),
      touchEnabled: interactive,
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
    // Последний столбик и его подпись не должны обрезаться краем карточки.
    final minWidth = productsData.length * (_barWidth + _groupsSpace + 28) +
        _leftTitlesReservedSize +
        16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = minWidth > constraints.maxWidth
            ? minWidth
            : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: chart),
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
              getTitlesWidget: (value, meta) => chartValueLabel(
                formatChartAxis(value, AppLocalizations.of(context)!),
                context.appColors.textSecondary,
                meta,
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final productsData = _getDataForSelectedPeriod();
    final showExample = productsData.isEmpty ||
        productsData.every((item) => item.totalQuantity == 0);
    final items = showExample ? _exampleProducts() : productsData;
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
            child: ExampleChartFrame(
              show: showExample,
              label: l.translate('no_data_to_display'),
              child: _buildChartViewport(
                items,
                interactive: !showExample,
              ),
            ),
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
}
