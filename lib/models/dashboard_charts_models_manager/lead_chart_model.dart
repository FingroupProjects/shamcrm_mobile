class ChartDataManager {
  final String label;
  final List<double> data;
  final String color;

  ChartDataManager({
    required this.label,
    required this.data,
    required this.color,
  });

  factory ChartDataManager.fromJson(Map<String, dynamic> json) {
    return ChartDataManager(
      label: json['label'] ?? json['status'] ?? '',
      data: (json['data'] as List<dynamic>)
          .map((x) => (x as num).toDouble())
          .toList(),
      color: json['color'] ?? '#000000',
    );
  }

  // toJson method to convert ChartDataManager instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'data': data.map((x) => x).toList(), // List<double> to JSON-compatible list
      'color': color,
    };
  }
}
