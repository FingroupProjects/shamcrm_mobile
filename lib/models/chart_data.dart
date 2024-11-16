// // models/chart_data.dart
// class ChartData {
//   final DateTime date;
//   final int neizvestniy; // Неизвестный
//   final int vRabote;     // В работе
//   final int client;      // Клиент
//   final int holodnoe;    // Холодное обращение

//   ChartData({
//     required this.date,
//     required this.neizvestniy,
//     required this.vRabote,
//     required this.client,
//     required this.holodnoe,
//   });

//   factory ChartData.fromJson(Map<String, dynamic> json) {
//     return ChartData(
//       date: DateTime.parse(json['date']),
//       neizvestniy: json['neizvestniy'] ?? 0,
//       vRabote: json['v_rabote'] ?? 0,
//       client: json['client'] ?? 0,
//       holodnoe: json['holodnoe'] ?? 0,
//     );
//   }

//   String get monthName {
//     const months = [
//       'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
//       'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
//     ];
//     return months[date.month - 1];
//   }
// }
