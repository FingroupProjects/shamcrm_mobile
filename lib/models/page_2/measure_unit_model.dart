import 'package:crm_task_manager/utils/safe_converters.dart';

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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      createdAt: SafeConverters.toDateTime(json['created_at']),
      updatedAt: SafeConverters.toDateTime(json['updated_at']),
      shortName: SafeConverters.toStringOrNull(json['short_name']),
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
        .map((e) => MeasureUnitModel.fromJson(SafeConverters.toMap(e)))
        .toList();
