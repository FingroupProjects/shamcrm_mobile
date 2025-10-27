import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/dashboard/net_profit_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import '../../detailed_report/detailed_report_screen.dart';
import 'download_popup_menu.dart';

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

  double _parseNetProfit(String netProfit) {
    try {
      return double.parse(netProfit.trim());
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildMockChart(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    // Mock data for empty state visualization (12 months)
    final List<double> mockData = [150, 50, 200, 100, 30, 250, 180, 120, 20, 300, 220, 280];
    final List<String> mockMonthNames = [
      localizations.translate('january'),
      localizations.translate('february'),
      localizations.translate('march'),
      localizations.translate('april'),
      localizations.translate('may'),
      localizations.translate('june'),
      localizations.translate('july'),
      localizations.translate('august'),
      localizations.translate('september'),
      localizations.translate('october'),
      localizations.translate('november'),
      localizations.translate('december'),
    ];
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 350,
              minY: 0,
              groupsSpace: 12,
              backgroundColor: Colors.transparent,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= mockMonthNames.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            mockMonthNames[value.toInt()],
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
                    interval: 50,
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
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                mockData.length,
                (index) {
                  final value = mockData[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: Colors.grey[300],
                        width: 16,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(8),
                          topRight: const Radius.circular(8),
                          bottomLeft: value < 0 ? const Radius.circular(8) : Radius.zero,
                          bottomRight: value < 0 ? const Radius.circular(8) : Radius.zero,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Text(
          localizations.translate('no_data_to_display'),
          style: const TextStyle(
            fontSize: 16,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currentData = _getCurrentPeriodData();
    final months = currentData?.data.result.months ?? [];

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

          SizedBox(
            height: 300,
            child: months.isEmpty || months.every((m) => _parseNetProfit(m.netProfit) == 0)
                ? _buildMockChart(context)
                : Padding(
              padding: const EdgeInsets.only(right: 16, top: 16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(months),
                  minY: _calculateMinY(months),
                  groupsSpace: 20,
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
                          '${months[groupIndex].monthName}\n',
                          const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: _formatValue(rod.toY),
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
                          if (value < 0 || value >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                months[value.toInt()].monthName,
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
                        interval: _calculateInterval(months),
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
                    horizontalInterval: _calculateInterval(months),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    months.length,
                        (index) {
                      final value = _parseNetProfit(months[index].netProfit);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value,
                            color: value >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
                            width: 16,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(8),
                              topRight: const Radius.circular(8),
                              bottomLeft: value < 0 ? const Radius.circular(8) : Radius.zero,
                              bottomRight: value < 0 ? const Radius.circular(8) : Radius.zero,
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

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                debugPrint("Подробнее pressed");
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailedReportScreen(currentTabIndex: 7)));
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

  double _calculateMinY(List<NetProfitMonth> months) {
    if (months.isEmpty) return 0;

    final minValue = months
        .map((m) => _parseNetProfit(m.netProfit))
        .reduce((a, b) => a < b ? a : b);

    // If all values are positive, return 0
    if (minValue >= 0) return 0;

    // Add 20% padding for negative values
    return minValue * 1.2;
  }

  double _calculateMaxY(List<NetProfitMonth> months) {
    if (months.isEmpty) return 100;

    final maxValue = months
        .map((m) => _parseNetProfit(m.netProfit))
        .reduce((a, b) => a > b ? a : b);

    // If all values are negative, return 0
    if (maxValue <= 0) return 0;

    return maxValue * 1.2;
  }

  double _calculateInterval(List<NetProfitMonth> months) {
    if (months.isEmpty) return 10;

    final values = months.map((m) => _parseNetProfit(m.netProfit)).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs();

    // Более детальные интервалы для красивого UI
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 200) return 25;
    if (range <= 500) return 50;
    if (range <= 1000) return 100;
    if (range <= 2000) return 200;
    if (range <= 5000) return 500;
    if (range <= 10000) return 1000;
    if (range <= 20000) return 2000;
    return 5000;
  }

  String _formatValue(double value) {
    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';

    if (absValue >= 1000000) {
      return '$sign${(absValue / 1000000).toStringAsFixed(1)}M';
    }
    if (absValue >= 1000) {
      return '$sign${(absValue / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _formatAxisValue(double value) {
    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';

    if (absValue >= 1000000) {
      return '$sign${(absValue / 1000000).toInt()}M';
    }
    if (absValue >= 1000) {
      return '$sign${(absValue / 1000).toInt()}k';
    }
    return value.toInt().toString();
  }

  Widget _buildPeriodDropdown() {
    return CustomDropdown<NetProfitPeriod>(
      decoration: CustomDropdownDecoration(
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedBorderRadius: BorderRadius.circular(8),
        expandedBorderRadius: BorderRadius.circular(8),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
      ),
      items: NetProfitPeriod.values,
      initialItem: selectedPeriod,
      onChanged: (NetProfitPeriod? value) {
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