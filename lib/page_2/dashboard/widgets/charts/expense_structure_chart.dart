import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import 'download_popup_menu.dart';

enum TimePeriod { month, quarter, year }

class ExpenseCategory {
  final String name;
  final double value;
  final Color color;

  ExpenseCategory({
    required this.name,
    required this.value,
    required this.color,
  });
}

class ExpenseStructureChart extends StatefulWidget {
  const ExpenseStructureChart({Key? key}) : super(key: key);

  @override
  State<ExpenseStructureChart> createState() => _ExpenseStructureChartState();
}

class _ExpenseStructureChartState extends State<ExpenseStructureChart> with SingleTickerProviderStateMixin {
  TimePeriod selectedPeriod = TimePeriod.month;
  bool isLoading = false;
  bool isDownloading = false;
  int touchedIndex = -1;
  List<ExpenseCategory> expenseData = [];

  @override
  void initState() {
    super.initState();
    loadExpenseData();
  }

  // Simulate data loading
  Future<void> loadExpenseData() async {
    setState(() {
      isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      expenseData = _getDataForPeriod(selectedPeriod);
      isLoading = false;
    });
  }

  List<ExpenseCategory> _getDataForPeriod(TimePeriod period) {
    // Mock data for different time periods
    switch (period) {
      case TimePeriod.month:
        return [
          ExpenseCategory(name: 'Закупка товаров', value: 24.8, color: const Color(0xFF3935E7)),
          ExpenseCategory(name: 'Аренда', value: 19.8, color: const Color(0xFF00E676)),
          ExpenseCategory(name: 'Зарплаты', value: 14.9, color: const Color(0xFFFF9800)),
          ExpenseCategory(name: 'Маркетинг', value: 14.6, color: const Color(0xFFF44336)),
          ExpenseCategory(name: 'Логистика', value: 19.8, color: const Color(0xFF9C27B0)),
          ExpenseCategory(name: 'Прочее', value: 6.1, color: const Color(0xFF2196F3)),
        ];
      case TimePeriod.quarter:
        return [
          ExpenseCategory(name: 'Закупка товаров', value: 28.5, color: const Color(0xFF3935E7)),
          ExpenseCategory(name: 'Аренда', value: 22.3, color: const Color(0xFF00E676)),
          ExpenseCategory(name: 'Зарплаты', value: 16.8, color: const Color(0xFFFF9800)),
          ExpenseCategory(name: 'Маркетинг', value: 12.4, color: const Color(0xFFF44336)),
          ExpenseCategory(name: 'Логистика', value: 15.2, color: const Color(0xFF9C27B0)),
          ExpenseCategory(name: 'Прочее', value: 4.8, color: const Color(0xFF2196F3)),
        ];
      case TimePeriod.year:
        return [
          ExpenseCategory(name: 'Закупка товаров', value: 32.1, color: const Color(0xFF3935E7)),
          ExpenseCategory(name: 'Аренда', value: 25.6, color: const Color(0xFF00E676)),
          ExpenseCategory(name: 'Зарплаты', value: 18.9, color: const Color(0xFFFF9800)),
          ExpenseCategory(name: 'Маркетинг', value: 10.2, color: const Color(0xFFF44336)),
          ExpenseCategory(name: 'Логистика', value: 8.7, color: const Color(0xFF9C27B0)),
          ExpenseCategory(name: 'Прочее', value: 4.5, color: const Color(0xFF2196F3)),
        ];
    }
  }

  void onPeriodChanged(TimePeriod period) {
    if (selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
      });
      loadExpenseData();
    }
  }

  String getPeriodText(BuildContext context, TimePeriod period) {
    switch (period) {
      case TimePeriod.month:
        return 'Текущий месяц';
      case TimePeriod.quarter:
        return 'Квартал';
      case TimePeriod.year:
        return 'Год';
    }
  }

  void _handleDownload(DownloadFormat format) async {
    setState(() {
      isDownloading = true;
    });

    try {
      // Simulate download process
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
    return CustomDropdown<TimePeriod>(
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
      ),
      items: TimePeriod.values,
      initialItem: selectedPeriod,
      onChanged: (TimePeriod? value) {
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

  Widget _buildChart(AppLocalizations localizations) {
    if (expenseData.isEmpty) {
      return Center(
        child: Text(
          localizations.translate('no_data_to_display'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      );
    }

    bool allZeros = expenseData.every((category) => category.value == 0);

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
              style: TextStyle(
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
          sections: _showingSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(expenseData.length, (i) {
      final isTouched = i == touchedIndex;
      final opacity = isTouched ? 0.8 : 1.0;
      final radius = isTouched ? 20.0 : 15.0;

      return PieChartSectionData(
        color: expenseData[i].color.withOpacity(opacity),
        value: expenseData[i].value,
        title: isTouched ? '${expenseData[i].value.toStringAsFixed(1)}%' : '',
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

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: expenseData.map((category) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: "Gilroy",
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A202C),
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
              DownloadPopupMenu(
                onDownload: _handleDownload,
                loading: isDownloading,
                formats: const [
                  DownloadFormat.png,
                  DownloadFormat.svg,
                  DownloadFormat.csv,
                ],
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
          if (isLoading)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3935E7),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Chart
                Expanded(
                  flex: 1,
                  child: _buildChart(localizations),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  flex: 1,
                  child: _buildLegend(),
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
