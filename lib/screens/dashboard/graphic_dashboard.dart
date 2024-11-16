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
                // Text(
                //   '',
                //   style: TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.w600,
                //     color: Color(0xFF2D3748),
                //   ),
                // ),
                SizedBox(height: 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('Неизвестный', Color(0xFF4299E1)),
                    _buildLegendItem('В работе', Color(0xFFFF6B6B)),
                    _buildLegendItem('Клиент', Color(0xFFFFA600)),
                    // _buildLegendItem('Холодное обращение', Color(0xFFFFD700)),
                  ],
                ),
                SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 0),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 10,
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
                              interval: 10,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Color(0xFF718096),
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['Янв', 'Фев', 'Май', 'Июн', 'Окт', 'Ноя'];
                                if (value.toInt() < months.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      months[value.toInt()],
                                      style: TextStyle(
                                        color: Color(0xFF718096),
                                        fontSize: 10,
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
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 30), FlSpot(1, 25), FlSpot(2, 15), FlSpot(3, 0), FlSpot(4, 0), FlSpot(5, 0),
                            ],
                            isCurved: true,
                            color: Color(0xFFFF6B6B),
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                          ),
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 10), FlSpot(1, 20), FlSpot(2, 15), FlSpot(3, 0), FlSpot(4, 5), FlSpot(5, 10),
                            ],
                            isCurved: true,
                            color: Color(0xFF4299E1),
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                          ),
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 20), FlSpot(1, 15), FlSpot(2, 10), FlSpot(3, 0), FlSpot(4, 5), FlSpot(5, 10),
                            ],
                            isCurved: true,
                            color: Color(0xFFFFA600),
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                          ),
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 5), FlSpot(1, 0), FlSpot(2, 10), FlSpot(3, 0), FlSpot(4, 0), FlSpot(5, 5),
                            ],
                            isCurved: true,
                            color: Color(0xFFFFD700),
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        minX: 0,
                        maxX: 5,
                        minY: 0,
                        maxY: 30,
                      ),
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
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
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}
