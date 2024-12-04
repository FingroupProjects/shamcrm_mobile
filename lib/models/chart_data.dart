// class ChartData {
//   final String month;
//   final int unknown;
//   final int inProgress;
//   final int client;
//   final int coldCall;

//   ChartData({
//     required this.month,
//     required this.unknown,
//     required this.inProgress,
//     required this.client,
//     required this.coldCall,
//   });

//   factory ChartData.fromJson(Map<String, dynamic> json) {
//     return ChartData(
//       month: json['month'] ?? '',
//       unknown: json['unknown'] ?? 0,
//       inProgress: json['in_progress'] ?? 0,
//       client: json['client'] ?? 0,
//       coldCall: json['cold_call'] ?? 0,
//     );
//   }
// }