// // graphic_tasks_dashboard.dart

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
// import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';

// class GraphicTasksDashboard extends StatelessWidget {
//   const GraphicTasksDashboard({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<DashboardBloc, DashboardState>(
//       builder: (context, state) {
//         if (state is DashboardLoading) {
//           return _buildContainer(
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (state is DashboardError) {
//           return _buildContainer(
//             child: Center(
//               child: Text(
//                 'Ошибка загрузки данных',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           );
//         }

//         if (state is DashboardLoaded) {
//           return _buildContainer(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Задачи',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2D3748),
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildLegendItem('Активный', Color(0xFF60A5FA)),
//                     SizedBox(width: 16),
//                     _buildLegendItem('Просроченный', Color(0xFFF87171)),
//                     SizedBox(width: 16),
//                     _buildLegendItem('Готовый', Color(0xFFFBBF24)),
//                   ],
//                 ),
//                 SizedBox(height: 16),
//                 Expanded(
//                   child: LineChart(
//                     LineChartData(
//                       gridData: FlGridData(
//                         show: true,
//                         drawVerticalLine: true,
//                         horizontalInterval: 10,
//                         verticalInterval: 1,
//                         getDrawingHorizontalLine: (value) {
//                           return FlLine(
//                             color: Colors.grey.withOpacity(0.1),
//                             strokeWidth: 1,
//                           );
//                         },
//                         getDrawingVerticalLine: (value) {
//                           return FlLine(
//                             color: Colors.grey.withOpacity(0.1),
//                             strokeWidth: 1,
//                           );
//                         },
//                       ),
//                       titlesData: FlTitlesData(
//                         rightTitles: AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                         topTitles: AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                         leftTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                             showTitles: true,
//                             interval: 20,
//                             reservedSize: 40,
//                             getTitlesWidget: (value, meta) {
//                               return Text(
//                                 '${value.toInt()}',
//                                 style: TextStyle(
//                                   color: Color(0xFF718096),
//                                   fontSize: 12,
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         bottomTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                             showTitles: true,
//                             interval: 1,
//                             getTitlesWidget: (value, meta) {
//                               const months = [
//                                 'January', 'February', 'March', 'April',
//                                 'May', 'June', 'July', 'August',
//                                 'September', 'October', 'November', 'December'
//                               ];
//                               int index = value.toInt();
//                               if (index >= 0 && index < months.length) {
//                                 return Padding(
//                                   padding: const EdgeInsets.only(top: 8.0),
//                                   child: Text(
//                                     months[index],
//                                     style: TextStyle(
//                                       color: Color(0xFF718096),
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 );
//                               }
//                               return Text('');
//                             },
//                           ),
//                         ),
//                       ),
//                       borderData: FlBorderData(show: false),
//                       lineBarsData: [
//                         // Активные задачи (синяя линия)
//                         _createLineData(
//                           const [60, 55, 80, 80, 50, 50, 40], 
//                           const Color(0xFF60A5FA),
//                         ),
//                         // Просроченные задачи (красная линия)
//                         _createLineData(
//                           const [20, 45, 30, 10, 90, 20, 100], 
//                           const Color(0xFFF87171),
//                         ),
//                         // Готовые задачи (оранжевая линия)
//                         _createLineData(
//                           const [40, 65, 50, 20, 40, 60, 80], 
//                           const Color(0xFFFBBF24),
//                         ),
//                       ],
//                       minX: 0,
//                       maxX: 6,
//                       minY: 0,
//                       maxY: 100,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return _buildContainer(
//           child: Center(
//             child: Text(
//               'Нет данных для отображения',
//               style: TextStyle(color: Color(0xFF718096)),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   LineChartBarData _createLineData(List<double> spots, Color color) {
//     return LineChartBarData(
//       spots: spots.asMap().entries.map((entry) {
//         return FlSpot(entry.key.toDouble(), entry.value);
//       }).toList(),
//       isCurved: true,
//       color: color,
//       barWidth: 2,
//       isStrokeCapRound: true,
//       dotData: FlDotData(
//         show: true,
//         getDotPainter: (spot, percent, barData, index) {
//           return FlDotCirclePainter(
//             radius: 4,
//             color: Colors.white,
//             strokeWidth: 2,
//             strokeColor: color,
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLegendItem(String title, Color color) {
//     return Row(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         SizedBox(width: 4),
//         Text(
//           title,
//           style: TextStyle(
//             color: Color(0xFF718096),
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildContainer({required Widget child}) {
//     return Container(
//       height: 400,
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//             color: Color.fromARGB(255, 244, 247, 254),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 5,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
// }