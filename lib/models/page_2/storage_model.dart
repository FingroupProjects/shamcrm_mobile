import 'package:crm_task_manager/utils/safe_converters.dart';

class WareHouse {
  final int id;
  final String name;
  final bool? showOnSite;
  final String? createdAt;
  final String? updatedAt;
  final List<int>? userIds;

  WareHouse({
    required this.id,
    required this.name,
    this.showOnSite,
    this.createdAt,
    this.updatedAt,
    this.userIds,
  });

  factory WareHouse.fromJson(Map<String, dynamic> json) {
    List<int>? userIds;
    final usersList = SafeConverters.toList(json['users']);
    if (usersList.isNotEmpty) {
      userIds = usersList
          .map((user) => SafeConverters.toInt(SafeConverters.toMap(user)['user_id']))
          .toList();
    }

    return WareHouse(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      showOnSite: SafeConverters.toIntOrNull(json['show_on_site']) == 1,
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      userIds: userIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'show_on_site': showOnSite,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user_ids': userIds,
    };
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WareHouse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
