import 'package:crm_task_manager/utils/safe_converters.dart';

class MyStatusName {
  final int id;
  final String name;
  final String? needsPermission;

  MyStatusName({
    required this.id,
    required this.name,
    this.needsPermission,
  });

  factory MyStatusName.fromJson(Map<String, dynamic> json) {
    return MyStatusName(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      needsPermission: SafeConverters.toStringOrNull(json['needs_permission']),
    );
  }

  @override
  String toString() {
    return 'StatusName(id: $id, name: $name, needsPermission: $needsPermission)';
  }
}
