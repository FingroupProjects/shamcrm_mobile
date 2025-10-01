import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import 'download_popup_menu.dart';

enum ProfitPeriod { sixMonths, year, twoYears }

class ProfitData {
  final String month;
  final double value;

  ProfitData({required this.month, required this.value});
}

class NetProfitChart extends StatefulWidget {
  const NetProfitChart({Key? key}) : super(key: key);

  @override
  State<NetProfitChart> createState() => _NetProfitChartState();
}

class _NetProfitChartState extends State<NetProfitChart> {
  ProfitPeriod selectedPeriod = ProfitPeriod.sixMonths;
  bool isLoading = false;
  List<ProfitData> profitData = [];

  @override
  void initState() {
    super.initState();
    loadProfitData();
  }

  Future<void> loadProfitData() async {
    setState(() {
      isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      profitData = _getDataForPeriod(selectedPeriod);
      isLoading = false;
    });
  }

  List<ProfitData> _getDataForPeriod(ProfitPeriod period) {
    switch (period) {
      case ProfitPeriod.sixMonths:
        return [
          ProfitData(month: 'Июль', value: 80),
          ProfitData(month: 'Август', value: 380),
          ProfitData(month: 'Сентябрь', value: 280),
          ProfitData(month: 'Октябрь', value: 180),
          ProfitData(month: 'Ноябрь', value: 290),
          ProfitData(month: 'Декабрь', value: 480),
        ];
      case ProfitPeriod.year:
        return [
          ProfitData(month: 'Янв', value: 120),
          ProfitData(month: 'Фев', value: 180),
          ProfitData(month: 'Мар', value: 250),
          ProfitData(month: 'Апр', value: 320),
          ProfitData(month: 'Май', value: 280),
          ProfitData(month: 'Июн', value: 350),
          ProfitData(month: 'Июл', value: 80),
          ProfitData(month: 'Авг', value: 380),
          ProfitData(month: 'Сен', value: 280),
          ProfitData(month: 'Окт', value: 180),
          ProfitData(month: 'Ноя', value: 290),
          ProfitData(month: 'Дек', value: 480),
        ];
      case ProfitPeriod.twoYears:
        return [
          ProfitData(month: '2023 Q1', value: 450),
          ProfitData(month: '2023 Q2', value: 520),
          ProfitData(month: '2023 Q3', value: 380),
          ProfitData(month: '2023 Q4', value: 680),
          ProfitData(month: '2024 Q1', value: 720),
          ProfitData(month: '2024 Q2', value: 580),
          ProfitData(month: '2024 Q3', value: 450),
          ProfitData(month: '2024 Q4', value: 820),
        ];
    }
  }

  void onPeriodChanged(ProfitPeriod? period) {
    if (period != null && selectedPeriod != period) {
      setState(() {
        selectedPeriod = period;
      });
      loadProfitData();
    }
  }

  String getPeriodText(ProfitPeriod period) {
    switch (period) {
      case ProfitPeriod.sixMonths:
        return '6 месяцев';
      case ProfitPeriod.year:
        return 'Год';
      case ProfitPeriod.twoYears:
        return '2 года';
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
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : profitData.isEmpty
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
                            maxY: profitData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                            minY: 0,
                            groupsSpace: selectedPeriod == ProfitPeriod.year ? 8 : 16,
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
                                        text: '${rod.toY.toInt()}k',
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
                                  reservedSize: selectedPeriod == ProfitPeriod.year ? 50 : 30,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    );
                                  },
                                  reservedSize: 40,
                                  interval: selectedPeriod == ProfitPeriod.twoYears ? 200 : 100,
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
                              horizontalInterval: selectedPeriod == ProfitPeriod.twoYears ? 200 : 100,
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
                                    width: selectedPeriod == ProfitPeriod.year ? 16 : 24,
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );
      },
    );
  }
}
