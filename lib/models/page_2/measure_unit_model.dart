class MeasureUnitModel {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? shortName;

  MeasureUnitModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.shortName,
  });

  factory MeasureUnitModel.fromJson(Map<String, dynamic> json) {
    return MeasureUnitModel(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      shortName: json['short_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'short_name': shortName,
    };
  }
}

// Helper for list parsing
List<MeasureUnitModel> measureUnitListFromJson(List<dynamic> jsonList) =>
    jsonList
        .map((e) => MeasureUnitModel.fromJson(e as Map<String, dynamic>))
        .toList();
