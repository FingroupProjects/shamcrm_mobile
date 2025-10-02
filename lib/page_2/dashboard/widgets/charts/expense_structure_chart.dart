import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/dashboard/expense_structure.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import 'download_popup_menu.dart';

class ExpenseStructureChart extends StatefulWidget {
  const ExpenseStructureChart(this.expenseStructureData, {Key? key}) : super(key: key);

  final List<AllExpensesData> expenseStructureData;

  @override
  State<ExpenseStructureChart> createState() => _ExpenseStructureChartState();
}

class _ExpenseStructureChartState extends State<ExpenseStructureChart> with SingleTickerProviderStateMixin {
  ExpensePeriodEnum selectedPeriod = ExpensePeriodEnum.month;
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
    }
  }

  String getPeriodText(BuildContext context, ExpensePeriodEnum period) {
    switch (period) {
      case ExpensePeriodEnum.today:
        return 'Сегодня';
      case ExpensePeriodEnum.week:
        return 'Неделя';
      case ExpensePeriodEnum.month:
        return 'Текущий месяц';
      case ExpensePeriodEnum.quarter:
        return 'Квартал';
      case ExpensePeriodEnum.year:
        return 'Год';
    }
  }

  void _handleDownload(DownloadFormat format) async {
    setState(() {
      isDownloading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  Widget _buildPeriodDropdown() {
    return CustomDropdown<ExpensePeriodEnum>(
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
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
          getPeriodText(context, item),
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

  Widget _buildChart(AppLocalizations localizations, List<ExpenseItem> expenseStructure) {
    if (expenseStructure.isEmpty) {
      return Center(
        child: Text(
          localizations.translate('no_data_to_display'),
          style: const TextStyle(
            fontSize: 16,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w500,
            color: Colors.black54,
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
              style: const TextStyle(
                fontSize: 14,
                fontFamily: "Gilroy",
                fontWeight: FontWeight.w500,
                color: Colors.black54,
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
                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
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

  List<PieChartSectionData> _showingSections(List<ExpenseItem> expenseStructure) {
    return List.generate(expenseStructure.length, (i) {
      final isTouched = i == touchedIndex;
      final opacity = isTouched ? 0.8 : 1.0;
      final radius = isTouched ? 20.0 : 15.0;

      return PieChartSectionData(
        color: _getColorForIndex(i).withOpacity(opacity),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('expense_structure'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Transform.translate(
                offset: const Offset(16, 0),
                child: DownloadPopupMenu(
                  onDownload: _handleDownload,
                  loading: isDownloading,
                  formats: const [
                    DownloadFormat.png,
                    DownloadFormat.svg,
                    DownloadFormat.csv,
                  ],
                ),
              ),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: "Gilroy",
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
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
}