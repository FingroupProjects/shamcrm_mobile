import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/stats_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class LeadConversionChart extends StatefulWidget {
  const LeadConversionChart({Key? key}) : super(key: key);

  @override
  State<LeadConversionChart> createState() => _LeadConversionChartState();
}

class _LeadConversionChartState extends State<LeadConversionChart>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Инициализация анимации
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    // Загрузка данных при инициализации
    context.read<DashboardConversionBloc>().add(LoadLeadConversionData());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardConversionBloc, DashboardConversionState>(
      listener: (context, state) {
        if (state is DashboardConversionLoaded) {
          _animationController.forward(from: 0.0);
        }
      },
      builder: (context, state) {
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
                'Конверсия лидов',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildChart(state),
              ),
              const SizedBox(height: 16),
              if (state is DashboardConversionLoaded) _buildLegend(state.leadConversionData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(DashboardConversionState state) {
    if (state is DashboardConversionLoading) {
      // return const Center(child: CircularProgressIndicator());
    } else if (state is DashboardConversionError) {
      return Center(
        child: Text(
          'Ошибка загрузки данных: ${state.message}',
          textAlign: TextAlign.center,
        ),
      );
    } else if (state is DashboardConversionLoaded) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return PieChart(
            PieChartData(
              startDegreeOffset: -90,
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
              sections: _showingSections(state.leadConversionData, _animation.value),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  List<PieChartSectionData> _showingSections(LeadConversion data, double animationValue) {
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 0.0;
      final radius = isTouched ? 45.0 : 40.0;
      final value = data.data[i] * animationValue;

      return PieChartSectionData(
        color: i == 0
            ? const Color(0xFF60A5FA).withOpacity(isTouched ? 1 : 0.6)
            : const Color.fromARGB(255, 33, 41, 188).withOpacity(isTouched ? 1 : 0.6),
        value: value,
        title: isTouched ? '${value.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegend(LeadConversion data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          'Новые (${data.newLeads.toStringAsFixed(1)}%)',
          const Color(0xFF60A5FA),
        ),
        const SizedBox(width: 24),
        _buildLegendItem(
          'Повторные (${data.repeatedLeads.toStringAsFixed(1)}%)',
          const Color.fromARGB(255, 33, 41, 188),
        ),
      ],
    );
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