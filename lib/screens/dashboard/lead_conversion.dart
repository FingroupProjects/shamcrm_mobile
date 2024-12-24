import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
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

    // context.read<DashboardConversionBloc>().add(LoadLeadConversionData());
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
        } else if (state is DashboardConversionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.message}',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DashboardConversionLoading) {
        } else if (state is DashboardConversionError) {
          return Container(); 
        } else if (state is DashboardConversionLoaded) {
          return _buildLoadedStateWidget(state);
        }
        return const SizedBox.shrink(); 
      },
    );
  }


  Widget _buildLoadedStateWidget(DashboardConversionLoaded state) {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Конверсия лидов',
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Gilroy",
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          // const SizedBox(height: 16),
          Expanded(
            child: _buildChart(state),
          ),
          // const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildLegend(state.leadConversionData),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(DashboardConversionState state) {
    if (state is DashboardConversionLoaded) {
      final data = state.leadConversionData;

      if (data.newLeads == 0.0 && data.repeatedLeads == 0.0) {
        return const Center(
          child: Text(
            'Нет данных для отображения',
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Gilroy",
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        );
      }

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
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: _showingSections(data, _animation.value),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  List<PieChartSectionData> _showingSections(
      LeadConversion data, double animationValue) {
    if (data.newLeads == 0.0 && data.repeatedLeads == 0.0) {
      return [];
    }

    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 0.0;
      final radius = isTouched ? 45.0 : 40.0;
      final value = data.data[i] * animationValue;

      return PieChartSectionData(
        color: i == 0
            ? const Color(0xFF3935E7).withOpacity(isTouched ? 0.8 : 1)
            : const Color(0xFF27A945)
                .withOpacity(isTouched ? 0.8 : 1),
        value: value,
        title: isTouched ? '${value.toStringAsFixed(1)}' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontFamily: "Gilroy",
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegend(LeadConversion data) {
    if (data.newLeads == 0.0 && data.repeatedLeads == 0.0) {
      return const Center(
        child: Text(
          '',
          style: TextStyle(
            fontSize: 16,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      );
    }

   return Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    _buildLegendItem(
      'Новые (${data.newLeads.toStringAsFixed(1)})',
      const Color(0xFF3935E7), // Используется шестнадцатеричный цветовой код
    ),
    const SizedBox(width: 24),
    _buildLegendItem(
      'Повторные (${data.repeatedLeads.toStringAsFixed(1)})',
      const Color(0xFF27A945), // Исправленный код для ARGB
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
           style: TextStyle(
              fontSize: 14,
              fontFamily: "Gilroy",
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
        ),
      ],
    );
  }
}
