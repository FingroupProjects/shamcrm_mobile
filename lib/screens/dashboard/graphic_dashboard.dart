
// graphics_dashboard.dart

import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';

class GraphicsDashboard extends StatelessWidget {
  const GraphicsDashboard({Key? key}) : super(key: key);

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

        if (state is DashboardLoaded && state.chartData.isNotEmpty) {
          return _buildContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Контрагенты',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false, // Убираем вертикальные линии
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Изменяем месяцы на период Май-Ноябрь
                              const months = ['Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Ноя'];
                              if (value.toInt() < months.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    months[value.toInt()],
                                    style: TextStyle(
                                      color: Color(0xFF718096),
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Оставляем только одну линию
                        LineChartBarData(
                          spots: [
                            FlSpot(0, 40), // Май
                            FlSpot(1, 55), // Июн
                            FlSpot(2, 45), // Июл
                            FlSpot(3, 60), // Авг
                            FlSpot(4, 50), // Сен
                            FlSpot(5, 65), // Ноя
                          ],
                          isCurved: true,
                          color: Color(0xFF6366F1),
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: Color(0xFF6366F1),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: false, // Убираем заливку под графиком
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: 5,
                      minY: 0,
                      maxY: 100,
                      backgroundColor: Colors.transparent, // Прозрачный фон
                    ),
                  ),
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

  Widget _buildContainer({required Widget child}) {
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent, // Убираем фоновый цвет
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
