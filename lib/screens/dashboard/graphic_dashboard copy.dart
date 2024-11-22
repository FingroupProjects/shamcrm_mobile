// // graphic_bar_dashboard.dart

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/bloc/dashboard/dashboard_bloc.dart';
// import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';

// class GraphicBarDashboard extends StatelessWidget {
//   const GraphicBarDashboard({Key? key}) : super(key: key);

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
//                   'Сделки',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2D3748),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Expanded(
//                   child: BarChart(
//                     BarChartData(
//                       alignment: BarChartAlignment.spaceAround,
//                       maxY: 16,
//                       minY: 0,
//                       gridData: FlGridData(
//                         show: true,
//                         horizontalInterval: 2,
//                         drawVerticalLine: false,
//                         getDrawingHorizontalLine: (value) {
//                           return FlLine(
//                             color: Colors.grey.withOpacity(0.2),
//                             strokeWidth: 1,
//                           );
//                         },
//                       ),
//                       titlesData: FlTitlesData(
//                         show: true,
//                         rightTitles: AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                         topTitles: AxisTitles(
//                           sideTitles: SideTitles(showTitles: false),
//                         ),
//                         leftTitles: AxisTitles(
//                           sideTitles: SideTitles(
//                             showTitles: true,
//                             interval: 2,
//                             getTitlesWidget: (value, meta) {
//                               return Text(
//                                 value.toInt().toString(),
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
//                             getTitlesWidget: (value, meta) {
//                               const months = [
//                                 'January', 'March',  'May', 
//                                  'July',  'September', 
//                                 'November',
//                               ];
//                               if (value.toInt() < months.length) {
//                                 return Padding(
//                                   padding: const EdgeInsets.only(top: 8.0),
//                                   child: Text(
//                                     months[value.toInt()],
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
//                       borderData: FlBorderData(
//                         show: false,
//                       ),
//                       barGroups: [
//                         _generateBarData(0, 0), // January
//                         _generateBarData(2, 0), // March
//                         _generateBarData(4, 0), // May
//                         _generateBarData(6, 0), // July
//                         _generateBarData(8, 0), // September
//                         _generateBarData(10, 16), // November
//                       ],
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

//   BarChartGroupData _generateBarData(int x, double y) {
//     return BarChartGroupData(
//       x: x,
//       barRods: [
//         BarChartRodData(
//           toY: y,
//           color: Color(0xFFE2E8F0),
//           width: 32,
//           borderRadius: BorderRadius.vertical(
//             top: Radius.circular(4),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildContainer({required Widget child}) {
//     return Container(
//       height: 400, // Увеличенная высота для лучшей читаемости
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
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