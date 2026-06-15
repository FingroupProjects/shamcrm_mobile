import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/dashboard/expense_structure.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';

class ExpenseStructureChart extends StatefulWidget {
  const ExpenseStructureChart(this.expenseStructureData, {Key? key})
      : super(key: key);

  final List<AllExpensesData> expenseStructureData;

  @override
  State<ExpenseStructureChart> createState() => _ExpenseStructureChartState();
}

class _ExpenseStructureChartState extends State<ExpenseStructureChart>
    with SingleTickerProviderStateMixin {
  ExpensePeriodEnum selectedPeriod = ExpensePeriodEnum.year;
  bool isDownloading = false;
  int touchedIndex = -1;

  // Generate colors based on index
  final List<Color> pieColors = [
    const Color(0xFF3935E7),
    const Color(0xFF00E676),
    const Color(0xFFFF9800),
    const Color(0xFFF44336),
    const Color(0xFF9C27B0),
    const Color(0xFF2196F3),
    const Color(0xFF00BCD4),
    const Color(0xFFFFEB3B),
    const Color(0xFF4CAF50),
    const Color(0xFFE91E63),
  ];

  @override
  void initState() {
    super.initState();
  }

  AllExpensesData? _getCurrentPeriodData() {
    try {
      return widget.expenseStructureData.firstWhere(
        (data) => data.period == selectedPeriod,
      );
    } catch (e) {
      return null;
    }
  }

  Color _getColorForIndex(int index) {
    return pieColors[index % pieColors.length];
  }

  void onPeriodChanged(ExpensePeriodEnum period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
        touchedIndex = -1;
      });

      // Вызываем перезагрузку данных через Bloc
      context
          .read<SalesDashboardBloc>()
          .add(ReloadExpenseStructureData(period));
    }
  }

  String getPeriodText(BuildContext context, ExpensePeriodEnum period) {
    final localizations = AppLocalizations.of(context)!;
    switch (period) {
      case ExpensePeriodEnum.today:
        return localizations.translate('today');
      case ExpensePeriodEnum.week:
        return localizations.translate('week');
      case ExpensePeriodEnum.month:
        return localizations.translate('current_month');
      case ExpensePeriodEnum.quarter:
        return localizations.translate('quarter');
      case ExpensePeriodEnum.year:
        return localizations.translate('year');
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

  Widget _buildPeriodDropdown() {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return CustomDropdown<ExpensePeriodEnum>(
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: colors.borderSubtle),
        expandedBorder: Border.all(color: colors.borderSubtle),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: colors.surfaceElevated.withValues(alpha: 0.72),
        expandedFillColor: colors.surfacePrimary,
        hintStyle: textStyles.bodySm.copyWith(color: colors.textSecondary),
        headerStyle: textStyles.bodySm.copyWith(color: colors.textPrimary),
        listItemStyle: textStyles.bodyMd.copyWith(color: colors.textPrimary),
      ),
      items: ExpensePeriodEnum.values,
      initialItem: selectedPeriod,
      onChanged: (ExpensePeriodEnum? value) {
        if (value != null) {
          onPeriodChanged(value);
        }
      },
      headerBuilder: (context, selectedItem, enabled) {
        return Text(
          getPeriodText(context, selectedItem),
          style: textStyles.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        );
      },
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return Text(
          getPeriodText(context, item),
          style: textStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        );
      },
    );
  }

  Widget _buildChart(
      AppLocalizations localizations, List<ExpenseItem> expenseStructure) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    if (expenseStructure.isEmpty) {
      return Center(
        child: Text(
          localizations.translate('no_data_to_display'),
          style: textStyles.bodyLg.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    bool allZeros = expenseStructure.every((item) => item.percentage == 0);

    if (allZeros) {
      return Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: Center(
            child: Text(
              localizations.translate('no_data'),
              style: textStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      width: 160,
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: _showingSections(expenseStructure),
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections(
      List<ExpenseItem> expenseStructure) {
    return List.generate(expenseStructure.length, (i) {
      final isTouched = i == touchedIndex;
      final opacity = isTouched ? 0.8 : 1.0;
      final radius = isTouched ? 20.0 : 15.0;

      return PieChartSectionData(
        color: _getColorForIndex(i).withValues(alpha: opacity),
        value: expenseStructure[i].percentage.toDouble(),
        title: isTouched ? '${expenseStructure[i].percentage}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontFamily: "Gilroy",
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    });
  }

  Widget _buildLegend(List<ExpenseItem> expenseStructure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: expenseStructure.asMap().entries.map((entry) {
        int index = entry.key;
        ExpenseItem item = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getColorForIndex(index),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.articleName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: "Gilroy",
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A202C),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currentData = _getCurrentPeriodData();
    final expenseStructure = currentData?.data.result.expenseStructure ?? [];
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
                localizations.translate('expense_structure'),
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

          const SizedBox(height: 24),

          // Chart and Legend
          expenseStructure.isEmpty
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      localizations.translate('no_data_to_display'),
                      style: textStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Chart
                    Expanded(
                      flex: 1,
                      child: _buildChart(localizations, expenseStructure),
                    ),
                    const SizedBox(width: 24),
                    // Legend
                    Expanded(
                      flex: 1,
                      child: _buildLegend(expenseStructure),
                    ),
                  ],
                ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                debugPrint("Подробнее pressed");
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        DetailedReportScreen(currentTabIndex: 9)));
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
}
