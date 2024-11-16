// graphic_circle_dashboard.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';

class GraphicCircleDashboard extends StatelessWidget {
  const GraphicCircleDashboard({Key? key}) : super(key: key);

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
          return _buildContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Конверсия',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Color(0xFF4299E1), // Синий для повторных
                          value: 75, // Пример значения для повторных клиентов
                          title: '', // Убираем подпись внутри сектора
                          radius: 40,
                        ),
                        PieChartSectionData(
                          color: Color(0xFFF56565), // Красный для новых
                          value: 25, // Пример значения для новых клиентов
                          title: '', // Убираем подпись внутри сектора
                          radius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Легенда
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Новый', Color(0xFFF56565)),
                    SizedBox(width: 24),
                    _buildLegendItem('Повторные', Color(0xFF4299E1)),
                  ],
                ),
              ],
            ),
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
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Color(0xFF718096),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
            color: Color.fromARGB(255, 244, 247, 254),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}