import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OperatorChart3 extends StatefulWidget {
  const OperatorChart3({Key? key}) : super(key: key);

  @override
  State<OperatorChart3> createState() => _OperatorChart3State();
}

class _OperatorChart3State extends State<OperatorChart3> {
  int? selectedBarIndex;
  int? selectedSegmentIndex;

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

  // Данные диаграммы
  final List<List<int>> chartData = [
    [45, 13, 10, 21], // 89
    [57, 23, 15, 7],  // 102
    [41, 20, 15, 25], // 101
    [67, 8, 15, 13],  // 103
    [21, 14, 21, 22], // 78
    [43, 27, 14, 8],  // 92
  ];

  @override
  Widget build(BuildContext context) {
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
          _buildInteractiveLegend(),
          const SizedBox(height: 20),
          Stack(
            children: [
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: 115,
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
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'День ${value.toInt() + 1}',
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 10,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: 20,
                          getTitlesWidget: (value, meta) {
                            if (value > 100) return const SizedBox.shrink();
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
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        if (value > 100) return const FlLine(color: Colors.transparent);
                        return FlLine(
                          color: const Color(0xFFF3F4F6),
                          strokeWidth: 1,
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

  /// Интерактивная легенда
  Widget _buildInteractiveLegend() {
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
              border: isSelected ? Border.all(
                color: segmentColors[index].withOpacity(0.3),
                width: 1,
              ) : null,
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
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: segmentColors[index].withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
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

  /// Интерактивные столбцы
  List<BarChartGroupData> _buildInteractiveBarGroups() {
    return chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final values = entry.value;
      final total = values.reduce((a, b) => a + b);
      final isSelected = selectedBarIndex == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total.toDouble(),
            color: Colors.transparent,
            width: isSelected ? 38 : 35,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            rodStackItems: [
              BarChartRodStackItem(0, values[0].toDouble(), segmentColors[0]),
              BarChartRodStackItem(values[0].toDouble(), (values[0] + values[1]).toDouble(), segmentColors[1]),
              BarChartRodStackItem((values[0] + values[1]).toDouble(), (values[0] + values[1] + values[2]).toDouble(), segmentColors[2]),
              BarChartRodStackItem((values[0] + values[1] + values[2]).toDouble(), total.toDouble(), segmentColors[3]),
            ],
          ),
        ],
        showingTooltipIndicators: [],
      );
    }).toList();
  }

  /// Интерактивные подписи над столбцами
  Widget _buildInteractiveChartLabels() {
    final totals = chartData.map((values) => values.reduce((a, b) => a + b)).toList();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartWidth = constraints.maxWidth - 35;
          final barWidth = chartWidth / 6;

          return Stack(
            children: totals.asMap().entries.map((entry) {
              final index = entry.key;
              final total = entry.value;
              final barCenterX = 35 + (index + 0.5) * barWidth;
              final isSelected = selectedBarIndex == index;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                left: barCenterX - 12,
                top: constraints.maxHeight - (total / 115 * constraints.maxHeight) - (isSelected ? 28 : 20),
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

  /// Всплывающее окно с выбранным значением
  Widget _buildValuePopup() {
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
              'День ${selectedBarIndex! + 1}',
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

  /// Обработка нажатия на столбец
  void _handleBarTap(int barIndex, Offset localPosition) {
    setState(() {
      selectedBarIndex = barIndex;
      
      // Определяем сегмент по Y-координате нажатия
      final values = chartData[barIndex];
      final total = values.reduce((a, b) => a + b);
      final relativeY = localPosition.dy / 250; // высота чарта
      final tapPosition = (1 - relativeY) * total;
      
      int segmentIndex = 0;
      double cumulative = 0;
      for (int i = 0; i < values.length; i++) {
        cumulative += values[i];
        if (tapPosition <= cumulative) {
          segmentIndex = i;
          break;
        }
      }
      
      selectedSegmentIndex = segmentIndex;
    });
  }

  /// Обработка нажатия на легенду
  void _handleLegendTap(int segmentIndex) {
    setState(() {
      if (selectedSegmentIndex == segmentIndex) {
        selectedSegmentIndex = null;
        selectedBarIndex = null;
      } else {
        selectedSegmentIndex = segmentIndex;
        // Показываем первый столбец с этим сегментом
        selectedBarIndex = 0;
      }
    });
  }

  /// Обработка нажатия на общее значение
  void _handleTotalTap(int barIndex) {
    setState(() {
      selectedBarIndex = selectedBarIndex == barIndex ? null : barIndex;
      if (selectedBarIndex != null && selectedSegmentIndex == null) {
        selectedSegmentIndex = 0; // Показываем первый сегмент по умолчанию
      }
    });
  }
}