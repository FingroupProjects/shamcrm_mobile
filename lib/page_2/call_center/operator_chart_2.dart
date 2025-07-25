import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OperatorChart2 extends StatefulWidget {
  const OperatorChart2({Key? key}) : super(key: key);

  @override
  State<OperatorChart2> createState() => _OperatorChart2State();
}

class _OperatorChart2State extends State<OperatorChart2> {
  int? selectedSectionIndex;

  final List<Color> sectionColors = [
    const Color(0xFF3B82F6), // Синий
    const Color(0xFF10B981), // Зеленый  
    const Color(0xFFF59E0B), // Оранжевый
    const Color(0xFFEF4444), // Красный
  ];

  final List<String> sectionLabels = [
    'Входящие',
    'Исходящие',
    'Исходящие без ответа',
    'Пропущенные'
  ];

  final List<double> sectionValues = [40, 35, 10, 15];
  final List<int> actualCounts = [50, 43, 12, 19];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
          Text(
            'Количество разговора',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (selectedSectionIndex != null &&
                              selectedSectionIndex! >= 0 &&
                              selectedSectionIndex! < sectionLabels.length)
                          ? sectionLabels[selectedSectionIndex!]
                          : 'В среднем в день',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: (selectedSectionIndex != null &&
                                selectedSectionIndex! >= 0 &&
                                selectedSectionIndex! < sectionColors.length)
                            ? sectionColors[selectedSectionIndex!]
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        (selectedSectionIndex != null &&
                                selectedSectionIndex! >= 0 &&
                                selectedSectionIndex! < actualCounts.length)
                            ? actualCounts[selectedSectionIndex!].toString()
                            : '124',
                        key: ValueKey(selectedSectionIndex),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 48,
                          color: (selectedSectionIndex != null &&
                                  selectedSectionIndex! >= 0 &&
                                  selectedSectionIndex! < sectionColors.length)
                              ? sectionColors[selectedSectionIndex!]
                              : const Color(0xFF2D3748),
                          height: 1.0,
                        ),
                      ),
                    ),
                    if (selectedSectionIndex != null &&
                        selectedSectionIndex! >= 0 &&
                        selectedSectionIndex! < sectionValues.length) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${sectionValues[selectedSectionIndex!].toInt()}% от общего',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (event is FlTapUpEvent && pieTouchResponse != null) {
                            final touchedIndex = pieTouchResponse.touchedSection?.touchedSectionIndex;

                            setState(() {
                              if (touchedIndex != null &&
                                  touchedIndex >= 0 &&
                                  touchedIndex < sectionValues.length) {
                                selectedSectionIndex = touchedIndex == selectedSectionIndex ? null : touchedIndex;
                              } else {
                                selectedSectionIndex = null;
                              }
                            });
                          }
                        },
                      ),
                      sections: _buildInteractivePieChartSections(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInteractiveLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildInteractivePieChartSections() {
    return sectionValues.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      final isSelected = selectedSectionIndex == index;

      return PieChartSectionData(
        color: sectionColors[index],
        value: value,
        title: isSelected ? '${value.toInt()}%' : '',
        radius: isSelected ? 32 : 25,
        titleStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Widget _buildInteractiveLegend() {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: sectionLabels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = selectedSectionIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedSectionIndex = isSelected ? null : index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 0,
              vertical: isSelected ? 8 : 0,
            ),
            decoration: BoxDecoration(
              color: isSelected ? sectionColors[index].withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: sectionColors[index].withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 16 : 12,
                  height: isSelected ? 16 : 12,
                  decoration: BoxDecoration(
                    color: sectionColors[index],
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: sectionColors[index].withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                    color: isSelected ? sectionColors[index] : const Color(0xFF4A5568),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: sectionColors[index],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      actualCounts[index].toString(),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
}
