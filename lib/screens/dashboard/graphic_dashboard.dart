import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GraphicsDashboard extends StatefulWidget {
  final Key? lineChartKey;

  const GraphicsDashboard({
    Key? key,
    this.lineChartKey,
  }) : super(key: key);

  @override
  _GraphicsDashboardState createState() => _GraphicsDashboardState();
}

class _GraphicsDashboardState extends State<GraphicsDashboard> {
  int currentPage = 0;
  final int itemsPerPage = 5;
  int? selectedIndex;
  int? selectedLineIndex;
  final Map<String, bool> _lineVisibility = {};

  @override
  void initState() {
    super.initState();
    context.read<DashboardChartBloc>().add(LoadLeadChartData());
  }

  bool _isAllZeros(List<ChartData> data) {
    return data.every((chartData) => chartData.data.every((value) => value == 0));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<DashboardChartBloc, DashboardChartState>(
      builder: (context, state) {
        if (state is DashboardChartLoading) {
          return const Center(child: CircularProgressIndicator()); // Показываем загрузку
        }

        if (state is DashboardChartError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   // SnackBar(
            //   //   content: Text(
            //   //     state.message,
            //   //     style: const TextStyle(
            //   //       fontFamily: 'Gilroy',
            //   //       fontSize: 16,
            //   //       fontWeight: FontWeight.w500,
            //   //       color: Colors.white,
            //   //     ),
            //   //   ),
            //   //   behavior: SnackBarBehavior.floating,
            //   //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   //   shape: RoundedRectangleBorder(
            //   //     borderRadius: BorderRadius.circular(12),
            //   //   ),
            //   //   backgroundColor: Colors.red,
            //   //   elevation: 3,
            //   //   padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            //   //   duration: const Duration(seconds: 3),
            //   // ),
            // );
          });
        }

        // Обработка состояния с данными (включая пустой массив)
        List<ChartData> chartData = [];
        if (state is DashboardChartLoaded) {
          chartData = state.chartData;
        }

        // Инициализация видимости линий даже при пустых данных
        for (var data in chartData) {
          _lineVisibility.putIfAbsent(data.label, () => true);
        }

        List<List<ChartData>> paginatedData = _paginateData(chartData);

        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                key: widget.lineChartKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('clients'),
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: chartData.isEmpty
                        ? Stack(
                            children: [
                              LineChart(
                                _buildEmptyChartData(),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
                              ),
                            ],
                          )
                        : _isAllZeros(chartData)
                            ? Stack(
                                children: [
                                  LineChart(
                                    _buildEmptyChartData(),
                                  ),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
                                  ),
                                ],
                              )
                            : LineChart(
                                _buildChartData(chartData),
                              ),
                  ),
                ],
              ),
              if (chartData.isNotEmpty) // Показываем статистику и пагинацию только если есть данные
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsList(paginatedData[currentPage]),
                      _buildPagination(paginatedData),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  LineChartData _buildEmptyChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 5,
      lineBarsData: [
        LineChartBarData(
          spots: [
            const FlSpot(0, 0),
            const FlSpot(11, 0),
          ],
          color: Colors.grey.withOpacity(0.1), // Прозрачная линия для предпросмотра
          barWidth: 3,
          isCurved: false,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.grey.withOpacity(0.05),
          ),
        ),
      ],
    );
  }

  List<List<ChartData>> _paginateData(List<ChartData> chartData) {
    List<List<ChartData>> paginatedData = [];
    for (int i = 0; i < chartData.length; i += itemsPerPage) {
      paginatedData.add(chartData.sublist(
          i, i + itemsPerPage > chartData.length ? chartData.length : i + itemsPerPage));
    }
    return paginatedData;
  }

  LineChartData _buildChartData(List<ChartData> chartData) {
    final localizations = AppLocalizations.of(context)!;
    List<LineChartBarData> lineBars = chartData.asMap().entries.map((entry) {
      int lineIndex = entry.key;
      ChartData data = entry.value;

      if (!(_lineVisibility[data.label] ?? true)) {
        return LineChartBarData(spots: [], show: false, dotData: const FlDotData(show: false));
      }

      List<FlSpot> spots = data.data.asMap().entries.map((entry) {
        double x = entry.key.toDouble();
        double y = entry.value < 0 ? 0 : entry.value.toDouble();
        return FlSpot(x, y);
      }).toList();

      Color lineColor;
      try {
        lineColor = Color(int.parse(data.color.replaceFirst('#', '0xff')));
      } catch (e) {
        lineColor = Colors.black;
      }

      return LineChartBarData(
        spots: spots,
        isCurved: false,
        color: lineColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            bool isSelected = lineIndex == selectedLineIndex && index == selectedIndex;
            return FlDotCirclePainter(
              radius: isSelected ? 6 : 4,
              color: isSelected ? const Color.fromARGB(255, 25, 2, 47) : lineColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    double maxY = chartData.expand((data) => data.data).reduce((a, b) => a > b ? a : b).toDouble();
    double horizontalInterval = maxY / 5;
    if (horizontalInterval == 0) horizontalInterval = 1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: horizontalInterval,
        verticalInterval: 1,
      ),
      titlesData: FlTitlesData(
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Text(
                (value.toInt() + 1).toString(),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: horizontalInterval,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: horizontalInterval,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final months = [
                localizations.translate('jan'),
                localizations.translate('feb'),
                localizations.translate('mar'),
                localizations.translate('apr'),
                localizations.translate('may'),
                localizations.translate('jun'),
                localizations.translate('jul'),
                localizations.translate('aug'),
                localizations.translate('sep'),
                localizations.translate('oct'),
                localizations.translate('nov'),
                localizations.translate('dec'),
              ];
              return Text(
                months[value.toInt() % 12],
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: maxY * 1.1,
      lineBarsData: lineBars,
      lineTouchData: LineTouchData(
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          if (event is FlTapUpEvent && touchResponse?.lineBarSpots != null) {
            final firstSpot = touchResponse!.lineBarSpots!.first;
            setState(() {
              selectedLineIndex = chartData.indexWhere((data) => data.data.contains(firstSpot.y.toInt()));
              selectedIndex = firstSpot.spotIndex;
            });
          }
        },
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (List<LineBarSpot> spots) {
            return spots.map((spot) {
              final lineData = chartData[spot.barIndex];
              if (!(_lineVisibility[lineData.label] ?? true)) return null;
              final label = lineData.label;
              return LineTooltipItem(
                '$label: ${spot.y.toInt()}',
                const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildStatsList(List<ChartData> chartData) {
    final localizations = AppLocalizations.of(context)!;
    List<Widget> stats = chartData.map((data) {
      Color color = Color(int.parse(data.color.replaceFirst('#', '0xff')));
      bool isVisible = _lineVisibility[data.label] ?? true;

      return GestureDetector(
        onTap: () {
          setState(() {
            _lineVisibility[data.label] = !isVisible;
            if (!isVisible) {
              selectedIndex = null;
              selectedLineIndex = null;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                color: color.withOpacity(isVisible ? 1.0 : 0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(isVisible ? 1.0 : 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('statuses'),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        ...stats,
      ],
    );
  }

  Widget _buildPagination(List<List<ChartData>> paginatedData) {
    int totalPages = paginatedData.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: currentPage > 0
              ? () => setState(() => currentPage--)
              : null,
        ),
        Text(
          '${currentPage + 1}/$totalPages',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_right),
          onPressed: currentPage < totalPages - 1
              ? () => setState(() => currentPage++)
              : null,
        ),
      ],
    );
  }
}