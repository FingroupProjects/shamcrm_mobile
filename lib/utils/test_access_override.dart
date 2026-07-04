import 'package:shared_preferences/shared_preferences.dart';

class TestAccessOverride {
  static const String testerRole = 'user';
  static const String elevatedRole = 'admin';

  static List<String> elevateRoles(Iterable<String> roles) {
    final normalizedRoles = roles
        .map((role) => role.trim())
        .where((role) => role.isNotEmpty)
        .toSet();

    final lowerRoles =
        normalizedRoles.map((role) => role.toLowerCase()).toSet();
    if (lowerRoles.contains(testerRole) && !lowerRoles.contains(elevatedRole)) {
      normalizedRoles.add(elevatedRole);
    }

    return normalizedRoles.toList();
  }

  static bool hasElevatedAccessFromRoles(Iterable<String> roles) {
    final lowerRoles = roles
        .map((role) => role.trim().toLowerCase())
        .where((role) => role.isNotEmpty)
        .toSet();
    return lowerRoles.contains(elevatedRole) || lowerRoles.contains(testerRole);
  }

  static Future<bool> isTesterAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final rawRoles = <String>{
      ...?prefs.getStringList('cached_user_roles'),
      ...(prefs.getString('userRoles') ?? '').split(','),
      ...(prefs.getString('userAllRoles') ?? '').split(','),
      prefs.getString('userRoleName') ?? '',
    };

    return hasElevatedAccessFromRoles(rawRoles);
  }
}
