// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:crm_task_manager/screens/gps/cache_gps.dart';
// import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

// class LogScreen extends StatefulWidget {
//   const LogScreen({Key? key}) : super(key: key);

//   @override
//   _LogScreenState createState() => _LogScreenState();
// }

// class _LogScreenState extends State<LogScreen> with TickerProviderStateMixin {
//   final CacheManager _cacheManager = CacheManager();
//   Map<String, List<Map<String, dynamic>>> _groupedLogs = {};
//   Map<String, bool> _expandedGroups = {};
//   Map<String, bool> _expandedLogs = {};
//   bool _isLoading = true;
//   late AnimationController _refreshController;

//   @override
//   void initState() {
//     super.initState();
//     _refreshController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _loadLogs();
//   }

//   Future<void> _loadLogs() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final groupedLogs = await _cacheManager.getGroupedLogs();
//       setState(() {
//         _groupedLogs = groupedLogs;
//         // Инициализируем состояние раскрытых групп
//         _expandedGroups = {
//           for (String status in groupedLogs.keys) status: false
//         };
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Ошибка загрузки логов: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _clearLogs() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Очистить логи'),
//         content: Text('Вы уверены, что хотите удалить все логи?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: Text('Отмена'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: Text('Удалить'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await _cacheManager.clearLogs();
//       await _loadLogs();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Логи очищены'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   void _refreshLogs() {
//     _refreshController.repeat();
//     _loadLogs().then((_) {
//       _refreshController.stop();
//       _refreshController.reset();
//     });
//   }

//   Widget _buildStatusIcon(String status) {
//     switch (status) {
//       case 'success':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.green.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(Icons.check_circle, color: Colors.green, size: 20),
//         );
//       case 'error':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.red.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(Icons.error, color: Colors.red, size: 20),
//         );
//       case 'sending':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.orange.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
//             ),
//           ),
//         );
//       case 'cached':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.blue.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(Icons.storage, color: Colors.blue, size: 20),
//         );
//       case 'no_internet':
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.grey.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(Icons.wifi_off, color: Colors.grey, size: 20),
//         );
//       default:
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.grey.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(Icons.help_outline, color: Colors.grey, size: 20),
//         );
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'success': return Colors.green;
//       case 'error': return Colors.red;
//       case 'sending': return Colors.orange;
//       case 'cached': return Colors.blue;
//       case 'no_internet': return Colors.grey;
//       default: return Colors.grey;
//     }
//   }

//   String _getStatusTitle(String status) {
//     switch (status) {
//       case 'success': return 'Отправлено';
//       case 'error': return 'Ошибка';
//       case 'sending': return 'Отправка';
//       case 'cached': return 'В кэше';
//       case 'no_internet': return 'Нет интернета';
//       default: return 'Неизвестно';
//     }
//   }

//   String _formatTimestamp(String timestamp) {
//     try {
//       final dateTime = DateTime.parse(timestamp);
//       return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return timestamp;
//     }
//   }

//   Widget _buildLogDetails(Map<String, dynamic> log) {
//     return Container(
//       margin: EdgeInsets.only(top: 8),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Детали запроса',
//             style: TextStyle(
//               fontFamily: 'Gilroy',
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//               color: Colors.grey[700],
//             ),
//           ),
//           SizedBox(height: 8),
//           _buildDetailRow('ID пользователя', log['user_id']),
//           _buildDetailRow('Широта', log['latitude']?.toString()),
//           _buildDetailRow('Долгота', log['longitude']?.toString()),
//           _buildDetailRow('Действие', log['action']),
//           _buildDetailRow('Подробности', log['details']),
//           if (log['response'] != null)
//             _buildDetailRow('Ответ сервера', log['response']),
//           if (log['error'] != null)
//             _buildDetailRow('Ошибка', log['error']),
//           if (log['updated_at'] != null)
//             _buildDetailRow('Обновлено', _formatTimestamp(log['updated_at'])),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String? value) {
//     if (value == null || value.isEmpty) return Container();
    
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontFamily: 'Gilroy',
//                 fontSize: 11,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontFamily: 'Gilroy',
//                 fontSize: 11,
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Логи GPS',
//           style: TextStyle(
//             fontFamily: 'Gilroy',
//             fontSize: 20,
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Color(0xff1E2E52),
//         iconTheme: IconThemeData(color: Colors.white),
//         elevation: 0,
//         actions: [
//           RotationTransition(
//             turns: _refreshController,
//             child: IconButton(
//               icon: Icon(Icons.refresh, color: Colors.white),
//               onPressed: _refreshLogs,
//               tooltip: 'Обновить',
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.delete_outline, color: Colors.white),
//             onPressed: _clearLogs,
//             tooltip: 'Очистить логи',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(color: Color(0xff1E2E52)),
//                   SizedBox(height: 16),
//                   Text(
//                     'Загрузка логов...',
//                     style: TextStyle(
//                       fontFamily: 'Gilroy',
//                       fontSize: 16,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : _groupedLogs.isEmpty
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.list_alt,
//                         size: 64,
//                         color: Colors.grey[400],
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'Логи отсутствуют',
//                         style: TextStyle(
//                           fontFamily: 'Gilroy',
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       Text(
//                         'Начните отслеживание GPS для создания логов',
//                         style: TextStyle(
//                           fontFamily: 'Gilroy',
//                           fontSize: 14,
//                           color: Colors.grey[500],
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : ListView.builder(
//                   padding: EdgeInsets.all(16),
//                   itemCount: _groupedLogs.keys.length,
//                   itemBuilder: (context, index) {
//                     final status = _groupedLogs.keys.elementAt(index);
//                     final logs = _groupedLogs[status]!;
//                     final isExpanded = _expandedGroups[status] ?? false;

//                     return Card(
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       margin: EdgeInsets.only(bottom: 12),
//                       child: Column(
//                         children: [
//                           ListTile(
//                             leading: _buildStatusIcon(status),
//                             title: Text(
//                               _getStatusTitle(status),
//                               style: TextStyle(
//                                 fontFamily: 'Gilroy',
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                                 color: _getStatusColor(status),
//                               ),
//                             ),
//                             subtitle: Text(
//                               '${logs.length} записей',
//                               style: TextStyle(
//                                 fontFamily: 'Gilroy',
//                                 fontSize: 14,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                             trailing: Icon(
//                               isExpanded ? Icons.expand_less : Icons.expand_more,
//                               color: Colors.grey[600],
//                             ),
//                             onTap: () {
//                               setState(() {
//                                 _expandedGroups[status] = !isExpanded;
//                               });
//                             },
//                           ),
//                           if (isExpanded)
//                             Column(
//                               children: logs.map((log) {
//                                 final logId = log['id'] ?? log['timestamp'];
//                                 final isLogExpanded = _expandedLogs[logId] ?? false;

//                                 return Container(
//                                   margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[50],
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(color: Colors.grey[200]!),
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       ListTile(
//                                         dense: true,
//                                         leading: Container(
//                                           width: 8,
//                                           height: 8,
//                                           decoration: BoxDecoration(
//                                             color: _getStatusColor(status),
//                                             shape: BoxShape.circle,
//                                           ),
//                                         ),
//                                         title: Text(
//                                           _formatTimestamp(log['timestamp']),
//                                           style: TextStyle(
//                                             fontFamily: 'Gilroy',
//                                             fontWeight: FontWeight.w500,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                         subtitle: Text(
//                                           '${log['latitude']}, ${log['longitude']}',
//                                           style: TextStyle(
//                                             fontFamily: 'Gilroy',
//                                             fontSize: 12,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                         trailing: Icon(
//                                           isLogExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                                           size: 20,
//                                           color: Colors.grey[600],
//                                         ),
//                                         onTap: () {
//                                           setState(() {
//                                             _expandedLogs[logId] = !isLogExpanded;
//                                           });
//                                         },
//                                       ),
//                                       if (isLogExpanded)
//                                         Padding(
//                                           padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
//                                           child: _buildLogDetails(log),
//                                         ),
//                                     ],
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }

//   @override
//   void dispose() {
//     _refreshController.dispose();
//     super.dispose();
//   }
// }