class IncomeCategoryData {
  final int id;
  final String name;

  IncomeCategoryData({
    required this.id,
    required this.name,
  });

  factory IncomeCategoryData.fromJson(Map<String, dynamic> json) {
    return IncomeCategoryData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}