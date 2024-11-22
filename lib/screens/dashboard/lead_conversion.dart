import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';
import 'package:crm_task_manager/models/dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class AnimatedConversionChart extends StatefulWidget {
  final LeadConversion? data;

  const AnimatedConversionChart({
    Key? key,
    this.data,
  }) : super(key: key);

  @override
  State<AnimatedConversionChart> createState() => _AnimatedConversionChartState();
}

class _AnimatedConversionChartState extends State<AnimatedConversionChart>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<double> get chartData {
    if (widget.data != null && widget.data!.data.isNotEmpty) {
      return widget.data!.data;
    }
    return [15.2, 84.8]; // Тестовые данные
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Конверсия',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return PieChart(
                  PieChartData(
                    startDegreeOffset: -90, // Начинаем с 12 часов
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: showingSections(_animation.value),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                'Новый (${chartData[0].toStringAsFixed(1)}%)', // С плавающей точкой
                const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                'Повторные (${chartData[1].toStringAsFixed(1)}%)', // С плавающей точкой
                const Color.fromARGB(255, 51, 30, 172),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections(double animationValue) {
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 0.0;
      final radius = isTouched ? 45.0 : 40.0;

      final value = chartData[i] * animationValue;

      return PieChartSectionData(
        color: i == 0
            ? const Color(0xFF60A5FA).withOpacity(isTouched ? 1 : 0.6)
            : const Color.fromARGB(255, 33, 41, 188).withOpacity(isTouched ? 1 : 0.6),
        value: value,
        title: isTouched ? '${value.toStringAsFixed(1)}%' : '', // С плавающей точкой
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF718096),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
