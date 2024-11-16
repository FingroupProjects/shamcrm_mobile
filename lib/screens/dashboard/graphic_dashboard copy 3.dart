import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';

class GraphicCircleDashboardProject extends StatelessWidget {
  const GraphicCircleDashboardProject({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return _buildContainer(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DashboardError) {
          return _buildContainer(
            child: Center(
              child: Text(
                'Ошибка загрузки данных',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (state is DashboardLoaded) {
          return Row(
            children: [
              Expanded(
                child: _buildProjectCard('Sham'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProjectCard('1212'),
              ),
            ],
          );
        }

        return _buildContainer(
          child: Center(
            child: Text(
              'Нет данных для отображения',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(String title) {
    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                sections: [
                  PieChartSectionData(
                    value: 45, // Просроченные
                    color: const Color.fromARGB(255, 255, 0, 0),
                    title: '',
                    radius: 70,
                  ),
                  PieChartSectionData(
                    value: 45, // Готовый
                    color: const Color.fromARGB(255, 0, 202, 74),
                    title: '',
                    radius: 70,
                  ),
                  PieChartSectionData(
                    value: 10, // Активный
                    color: const Color.fromARGB(255, 36, 118, 218),
                    title: '',
                    radius: 70,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('Активный', Color(0xFF60A5FA)),
        _buildLegendItem('Готовый', Color(0xFF4ADE80)),
        _buildLegendItem('Просроченные', Color(0xFFF87171)),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            color: Color(0xFF718096),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      height: 350,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
            color: Color.fromARGB(255, 244, 247, 254),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}