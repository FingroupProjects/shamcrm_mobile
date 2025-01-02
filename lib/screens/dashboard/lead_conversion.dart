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

class _LeadConversionChartState extends State<LeadConversionChart> {
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    // Загрузка данных
    context.read<DashboardConversionBloc>().add(LoadLeadConversionData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardConversionBloc, DashboardConversionState>(
      listener: (context, state) {
        if (state is DashboardConversionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.message}',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DashboardConversionLoading) {
          // return const Center(
          //   child: Text(
          //     'Загрузка данных...',
          //     style: TextStyle(
          //       fontSize: 16,
          //       fontFamily: "Gilroy",
          //       fontWeight: FontWeight.w500,
          //       color: Colors.black,
          //     ),
          //   ),
          // );
        } else if (state is DashboardConversionError) {
          return const Center(
            child: Text(
              'Ошибка загрузки данных',
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Gilroy",
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          );
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
          Expanded(
            child: _buildChart(state),
          ),
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

    return PieChart(
      PieChartData(
        startDegreeOffset: -90,
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: _showingSections(data),
        // Добавление анимации
        borderData: FlBorderData(show: false),
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
      ),
    );
  }
  return const SizedBox.shrink();
}

List<PieChartSectionData> _showingSections(LeadConversion data) {
  return [
    PieChartSectionData(
      color: const Color(0xFF3935E7),
      value: data.newLeads,
      title: '${data.newLeads.toInt()}',
      radius: 40,
      titleStyle: const TextStyle(
        fontSize: 14,
        fontFamily: "Gilroy",
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
    PieChartSectionData(
      color: const Color(0xFF27A945),
      value: data.repeatedLeads,
      title: '${data.repeatedLeads.toInt()}',
      radius: 40,
      titleStyle: const TextStyle(
        fontSize: 14,
        fontFamily: "Gilroy",
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
  ];
}

  Widget _buildLegend(LeadConversion data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          'Новые: ${data.newLeads.toInt()}',
          const Color(0xFF3935E7),
        ),
        const SizedBox(width: 24),
        _buildLegendItem(
          'Повторные: ${data.repeatedLeads.toInt()}',
          const Color(0xFF27A945),
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