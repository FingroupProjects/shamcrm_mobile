class ChartData {
  final String label;
  final List<double> data;
  final String color;

  ChartData({
    required this.label,
    required this.data,
    required this.color,
  });

  // Преобразование объекта ChartData в JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'data': data,
      'color': color,
    };
  }

  // Создание объекта ChartData из JSON
  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] ?? json['status'] ?? '',
      data: (json['data'] as List<dynamic>)
          .map((x) => (x as num).toDouble())
          .toList(),
      color: json['color'] ?? '#000000',
    );
  }
}
