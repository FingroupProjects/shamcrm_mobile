import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/dashboard/sales_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'download_popup_menu.dart';

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
          period: _getShortMonthName(monthData.monthName),
          value: double.tryParse(monthData.totalAmount) ?? 0.0,
        );
      }).toList();
    } catch (e) {
      // Если данных для периода нет, возвращаем пустой список
      return [];
    }
  }

  String _getShortMonthName(String fullName) {
    final monthMap = {
      'Январь': 'Янв',
      'Февраль': 'Фев',
      'Март': 'Мар',
      'Апрель': 'Апр',
      'Май': 'Май',
      'Июнь': 'Июн',
      'Июль': 'Июл',
      'Август': 'Авг',
      'Сентябрь': 'Сен',
      'Октябрь': 'Окт',
      'Ноябрь': 'Ноя',
      'Декабрь': 'Дек',
    };
    return monthMap[fullName] ?? fullName.substring(0, 3);
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

  String getPeriodText(SalesDynamicsTimePeriod period, AppLocalizations localizations) {
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
                localizations.translate('sales_dynamics'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
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

          // Chart content
          SizedBox(
            height: 300,
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3935E7),
              ),
            )
                : salesData.isEmpty
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
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(),
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
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= salesData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                salesData[value.toInt()].period,
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
                        reservedSize: 50,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatAxisValue(value),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          );
                        },
                        reservedSize: 40,
                        interval: _calculateInterval(),
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: (salesData.length - 1).toDouble(),
                  minY: 0,
                  maxY: _calculateMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        salesData.length,
                            (index) => FlSpot(
                          index.toDouble(),
                          salesData[index].value,
                        ),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: const Color(0xFF00E676),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF00E676),
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
                            const Color(0xFF00E676).withOpacity(0.3),
                            const Color(0xFF00E676).withOpacity(0.0),
                          ],
                        ),
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
                          if (index >= 0 && index < salesData.length) {
                            return LineTooltipItem(
                              '${salesData[index].period}\n',
                              const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(
                                  text: _formatValue(touchedSpot.y),
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
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailedReportScreen(currentTabIndex: 6)));
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

  double _calculateMaxY() {
    if (salesData.isEmpty) return 100;
    final maxValue = salesData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return 100;
    return maxValue * 1.2;
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    // Более детальные интервалы для красивого UI
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 25;
    if (maxY <= 500) return 50;
    if (maxY <= 1000) return 100;
    if (maxY <= 2000) return 200;
    if (maxY <= 5000) return 500;
    if (maxY <= 10000) return 1000;
    if (maxY <= 20000) return 2000;
    return 5000;
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _formatAxisValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toInt()}k';
    }
    return value.toInt().toString();
  }

  Widget _buildPeriodDropdown() {
    return CustomDropdown<SalesDynamicsTimePeriod>(
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
      ),
      items: SalesDynamicsTimePeriod.values,
      initialItem: selectedPeriod,
      onChanged: (SalesDynamicsTimePeriod? value) {
        if (value != null) {
          onPeriodChanged(value);
        }
      },
      headerBuilder: (context, selectedItem, enabled) {
        final localizations = AppLocalizations.of(context)!;
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
        final localizations = AppLocalizations.of(context)!;
        return Text(
          getPeriodText(item, localizations),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );
      },
    );
  }
}