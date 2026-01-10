class OutcomeCategoryData {
  final int id;
  final String name;

  OutcomeCategoryData({
    required this.id,
    required this.name,
  });

  factory OutcomeCategoryData.fromJson(Map<String, dynamic> json) {
    return OutcomeCategoryData(
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