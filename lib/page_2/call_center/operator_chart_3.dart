import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/monthly_call_stats.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OperatorChart3 extends StatefulWidget {
  final int operatorId;

  const OperatorChart3({Key? key, required this.operatorId}) : super(key: key);

  @override
  State<OperatorChart3> createState() => _OperatorChart3State();
}

class _OperatorChart3State extends State<OperatorChart3> {
  int? selectedBarIndex;
  int? selectedSegmentIndex;
  List<MonthlyCallStat>? monthlyStats;
  bool isLoading = true;
  String? errorMessage;

  // Оригинальные цвета
  final List<Color> segmentColors = [
    const Color(0xFF3B82F6), // Входящие - синий
    const Color(0xFF10B981), // Исходящие - зеленый
    const Color(0xFFF59E0B), // Без ответа - оранжевый
    const Color(0xFFEF4444), // Пропущенные - красный
  ];

  final List<String> segmentLabels = [
    'Входящие',
    'Исходящие',
    'Исходящие без ответа',
    'Пропущенные'
  ];

  final List<String> monthNames = [
    'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
    'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
  ];

  @override
  void initState() {
    super.initState();
    _fetchMonthlyStats();
  }

  Future<void> _fetchMonthlyStats() async {
    try {
      final apiService = ApiService();
      final stats = await apiService.getMonthlyCallStats(widget.operatorId);
      setState(() {
        monthlyStats = stats.result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Эффективность работы',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 24),
          _buildInteractiveLegend(),
          const SizedBox(height: 20),
          Stack(
            children: [
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: _getMaxY(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (event is FlTapUpEvent && barTouchResponse != null) {
                          final touchedGroup = barTouchResponse.spot?.touchedBarGroup;
                          if (touchedGroup != null) {
                            _handleBarTap(touchedGroup.x, event.localPosition);
                          }
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 25,
                          getTitlesWidget: (value, meta) {
                            final monthIndex = value.toInt();
                            if (monthIndex >= 0 && monthIndex < monthNames.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthNames[monthIndex],
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 10,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: _getYAxisInterval(),
                          getTitlesWidget: (value, meta) {
                            if (value > _getMaxY()) return const SizedBox.shrink();
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getYAxisInterval(),
                      getDrawingHorizontalLine: (value) {
                        if (value > _getMaxY()) return const FlLine(color: Colors.transparent);
                        return FlLine(
                          color: const Color(0xFFF8F9FA),
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    barGroups: _buildInteractiveBarGroups(),
                  ),
                ),
              ),
              _buildInteractiveChartLabels(),
              if (selectedBarIndex != null && selectedSegmentIndex != null)
                _buildValuePopup(),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (monthlyStats == null || monthlyStats!.isEmpty) return 100;
    
    // Создаем полный массив данных для всех 12 месяцев
    final chartData = _getChartData();
    final maxTotal = chartData.map((values) => values.reduce((a, b) => a + b)).reduce((a, b) => a > b ? a : b);
    
    if (maxTotal == 0) return 100; // Минимальное значение для пустого графика
    return (maxTotal * 1.2).ceilToDouble(); // Добавляем 20% запаса
  }

  double _getYAxisInterval() {
    final maxY = _getMaxY();
    if (maxY <= 50) return 25;
    if (maxY <= 100) return 25;
    if (maxY <= 200) return 50;
    if (maxY <= 500) return 100;
    return (maxY / 4).ceilToDouble();
  }

  List<List<int>> _getChartData() {
    // Инициализируем данные для всех 12 месяцев нулями
    List<List<int>> chartData = List.generate(12, (index) => [0, 0, 0, 0]);
    
    if (monthlyStats != null && monthlyStats!.isNotEmpty) {
      for (var stat in monthlyStats!) {
        final index = stat.month - 1; // Месяцы с 1 до 12, индексы с 0 до 11
        if (index >= 0 && index < 12) {
          chartData[index] = [
            stat.incoming,
            stat.outgoing,
            stat.unanswered,
            stat.missed,
          ];
        }
      }
    }
    return chartData;
  }

  Widget _buildInteractiveLegend() {
    final chartData = _getChartData();
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: segmentLabels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = selectedSegmentIndex == index;

        return GestureDetector(
          onTap: () => _handleLegendTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 8 : 0,
              vertical: isSelected ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: isSelected ? segmentColors[index].withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(
                      color: segmentColors[index].withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 14 : 12,
                  height: isSelected ? 14 : 12,
                  decoration: BoxDecoration(
                    color: segmentColors[index],
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: segmentColors[index].withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                    color: isSelected ? segmentColors[index] : const Color(0xFF4A5568),
                  ),
                ),
                if (isSelected && selectedBarIndex != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: segmentColors[index],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chartData[selectedBarIndex!][index].toString(),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<BarChartGroupData> _buildInteractiveBarGroups() {
    final chartData = _getChartData();
    return chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final values = entry.value;
      final total = values.reduce((a, b) => a + b);
      final isSelected = selectedBarIndex == index;

      // Если total равен 0, создаем очень маленький столбец для визуализации
      final displayTotal = total == 0 ? 0.1 : total.toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: displayTotal,
            color: total == 0 ? Colors.grey.withOpacity(0.2) : Colors.transparent,
            width: isSelected ? 24 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            rodStackItems: total == 0 ? [] : [
              if (values[0] > 0) BarChartRodStackItem(0, values[0].toDouble(), segmentColors[0]),
              if (values[1] > 0) BarChartRodStackItem(
                values[0].toDouble(), 
                (values[0] + values[1]).toDouble(), 
                segmentColors[1]
              ),
              if (values[2] > 0) BarChartRodStackItem(
                (values[0] + values[1]).toDouble(), 
                (values[0] + values[1] + values[2]).toDouble(), 
                segmentColors[2]
              ),
              if (values[3] > 0) BarChartRodStackItem(
                (values[0] + values[1] + values[2]).toDouble(), 
                total.toDouble(), 
                segmentColors[3]
              ),
            ],
          ),
        ],
        showingTooltipIndicators: [],
      );
    }).toList();
  }

  Widget _buildInteractiveChartLabels() {
    final chartData = _getChartData();
    final totals = chartData.map((values) => values.reduce((a, b) => a + b)).toList();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartWidth = constraints.maxWidth - 35;
          final barWidth = chartWidth / 12; // 12 месяцев
          final maxY = _getMaxY();

          return Stack(
            children: totals.asMap().entries.map((entry) {
              final index = entry.key;
              final total = entry.value;
              final barCenterX = 35 + (index + 0.5) * barWidth;
              final isSelected = selectedBarIndex == index;

              // Не показываем лейблы для нулевых значений
              if (total == 0) return const SizedBox.shrink();

              final topPosition = constraints.maxHeight - 
                  (total / maxY * (constraints.maxHeight - 50)) - 
                  (isSelected ? 28 : 20);

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                left: barCenterX - 8,
                top: topPosition.clamp(0.0, constraints.maxHeight - 40),
                child: GestureDetector(
                  onTap: () => _handleTotalTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 8 : 4,
                      vertical: isSelected ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2D3748) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
                          blurRadius: isSelected ? 6 : 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      total.toString(),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: isSelected ? 13 : 12,
                        color: isSelected ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildValuePopup() {
    final chartData = _getChartData();
    if (selectedBarIndex == null || selectedSegmentIndex == null) {
      return const SizedBox.shrink();
    }
    
    final selectedValue = chartData[selectedBarIndex!][selectedSegmentIndex!];

    return Positioned(
      top: 10,
      right: 10,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: segmentColors[selectedSegmentIndex!],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: segmentColors[selectedSegmentIndex!].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              segmentLabels[selectedSegmentIndex!],
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              selectedValue.toString(),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              monthNames[selectedBarIndex!],
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBarTap(int barIndex, Offset localPosition) {
    final values = _getChartData()[barIndex];
    final total = values.reduce((a, b) => a + b);
    
    // Если столбец пустой, не обрабатываем тап
    if (total == 0) return;

    setState(() {
      selectedBarIndex = barIndex;

      final relativeY = localPosition.dy / 250;
      final tapPosition = (1 - relativeY) * total;

      int segmentIndex = 0;
      double cumulative = 0;
      for (int i = 0; i < values.length; i++) {
        cumulative += values[i];
        if (tapPosition <= cumulative && values[i] > 0) {
          segmentIndex = i;
          break;
        }
      }

      selectedSegmentIndex = segmentIndex;
    });
  }

  void _handleLegendTap(int segmentIndex) {
    setState(() {
      if (selectedSegmentIndex == segmentIndex) {
        selectedSegmentIndex = null;
        selectedBarIndex = null;
      } else {
        selectedSegmentIndex = segmentIndex;
        // Находим первый месяц с данными для этого сегмента
        final chartData = _getChartData();
        int? firstNonZeroMonth;
        for (int i = 0; i < chartData.length; i++) {
          if (chartData[i][segmentIndex] > 0) {
            firstNonZeroMonth = i;
            break;
          }
        }
        selectedBarIndex = firstNonZeroMonth ?? 0;
      }
    });
  }

  void _handleTotalTap(int barIndex) {
    final chartData = _getChartData();
    final total = chartData[barIndex].reduce((a, b) => a + b);
    
    // Если столбец пустой, не обрабатываем тап
    if (total == 0) return;

    setState(() {
      selectedBarIndex = selectedBarIndex == barIndex ? null : barIndex;
      if (selectedBarIndex != null && selectedSegmentIndex == null) {
        // Находим первый ненулевой сегмент
        for (int i = 0; i < chartData[barIndex].length; i++) {
          if (chartData[barIndex][i] > 0) {
            selectedSegmentIndex = i;
            break;
          }
        }
      }
    });
  }
}