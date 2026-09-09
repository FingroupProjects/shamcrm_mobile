import 'dart:convert';

/// Safe type conversion for API JSON payloads.
/// Prevents TypeError crashes when server types differ from Dart models
/// (e.g. int vs String, null vs non-null, double vs int).
class SafeConverters {
  SafeConverters._();

  /// Convert any value to [double]. Returns [defaultValue] on failure/null.
  static double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.').replaceAll(' ', '');
      if (cleaned.isEmpty) return defaultValue;
      return double.tryParse(cleaned) ?? defaultValue;
    }
    if (value is bool) return value ? 1.0 : 0.0;
    return defaultValue;
  }

  /// Nullable [double]. Returns null when value is null/empty/unparseable.
  static double? toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.').replaceAll(' ', '');
      if (cleaned.isEmpty) return null;
      return double.tryParse(cleaned);
    }
    if (value is bool) return value ? 1.0 : 0.0;
    return null;
  }

  /// Convert any value to [int]. Returns [defaultValue] on failure/null.
  static int toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.').replaceAll(' ', '');
      if (cleaned.isEmpty) return defaultValue;
      final asInt = int.tryParse(cleaned);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(cleaned);
      return asDouble?.toInt() ?? defaultValue;
    }
    if (value is bool) return value ? 1 : 0;
    return defaultValue;
  }

  /// Nullable [int]. Returns null when value is null/empty/unparseable.
  static int? toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.').replaceAll(' ', '');
      if (cleaned.isEmpty) return null;
      final asInt = int.tryParse(cleaned);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(cleaned);
      return asDouble?.toInt();
    }
    if (value is bool) return value ? 1 : 0;
    return null;
  }

  /// Convert any value to [num]. Returns [defaultValue] on failure/null.
  static num toNum(dynamic value, {num defaultValue = 0}) {
    return toNumOrNull(value) ?? defaultValue;
  }

  /// Nullable [num].
  static num? toNumOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      if (value is double && value == value.toInt()) return value.toInt();
      return value;
    }
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.').replaceAll(' ', '');
      if (cleaned.isEmpty) return null;
      final asInt = int.tryParse(cleaned);
      if (asInt != null) return asInt;
      return double.tryParse(cleaned);
    }
    if (value is bool) return value ? 1 : 0;
    return null;
  }

  /// Always returns a non-null [String].
  static String toSafeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Nullable [String]. Null/empty (optional) stay null.
  static String? toStringOrNull(dynamic value, {bool emptyAsNull = false}) {
    if (value == null) return null;
    final result = value.toString();
    if (emptyAsNull && result.isEmpty) return null;
    return result;
  }

  /// Convert to [bool]. Handles 0/1, "true"/"false", "1"/"0".
  static bool toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final cleaned = value.trim().toLowerCase();
      if (cleaned.isEmpty) return defaultValue;
      if (cleaned == 'true' || cleaned == '1' || cleaned == 'yes') return true;
      if (cleaned == 'false' || cleaned == '0' || cleaned == 'no') return false;
    }
    return defaultValue;
  }

  /// Nullable [bool].
  static bool? toBoolOrNull(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final cleaned = value.trim().toLowerCase();
      if (cleaned.isEmpty) return null;
      if (cleaned == 'true' || cleaned == '1' || cleaned == 'yes') return true;
      if (cleaned == 'false' || cleaned == '0' || cleaned == 'no') return false;
    }
    return null;
  }

  /// Parse [DateTime] from ISO/string/epoch. Returns null on failure.
  static DateTime? toDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      // Heuristic: ms vs seconds
      if (value > 9999999999) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      return toDateTimeOrNull(value.toInt());
    }
    if (value is String) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) return null;
      return DateTime.tryParse(cleaned);
    }
    return null;
  }

  /// Parse [DateTime] with fallback.
  static DateTime toDateTime(dynamic value, {DateTime? defaultValue}) {
    return toDateTimeOrNull(value) ?? defaultValue ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Color int from hex string "#RRGGBB" / "RRGGBB".
  static int toColorInt(dynamic value, {int defaultColor = 0xFF4ae6b3}) {
    if (value == null) return defaultColor;
    final hexString = value.toString().replaceAll('#', '').trim();
    if (hexString.length == 6) {
      return int.tryParse('FF$hexString', radix: 16) ?? defaultColor;
    }
    if (hexString.length == 8) {
      return int.tryParse(hexString, radix: 16) ?? defaultColor;
    }
    return defaultColor;
  }

  /// Safely get element from list at index.
  static T elementAtOrDefault<T>(List<T>? list, int index, T defaultValue) {
    if (list == null || index < 0 || index >= list.length) {
      return defaultValue;
    }
    return list[index];
  }

  /// Convert dynamic list to [List]<[double]>.
  static List<double> toDoubleList(dynamic value, {int expectedLength = 0}) {
    if (value is! List) {
      return expectedLength > 0 ? List.filled(expectedLength, 0.0) : <double>[];
    }
    final result = value.map(toDouble).toList();
    if (expectedLength > 0 && result.length < expectedLength) {
      result.addAll(List.filled(expectedLength - result.length, 0.0));
    }
    return result;
  }

  /// Convert dynamic list to [List]<[int]>.
  static List<int> toIntList(dynamic value, {int expectedLength = 0}) {
    if (value is! List) {
      return expectedLength > 0 ? List.filled(expectedLength, 0) : <int>[];
    }
    final result = value.map(toInt).toList();
    if (expectedLength > 0 && result.length < expectedLength) {
      result.addAll(List.filled(expectedLength - result.length, 0));
    }
    return result;
  }

  /// Convert dynamic to [Map]<[String], [dynamic]> or null.
  static Map<String, dynamic>? toMapOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        try {
          return toMapOrNull(jsonDecode(trimmed));
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  /// Convert dynamic to [Map]<[String], [dynamic]> or empty map.
  static Map<String, dynamic> toMap(dynamic value) {
    return toMapOrNull(value) ?? <String, dynamic>{};
  }

  /// Convert dynamic to [List]<[dynamic]> or empty list.
  static List<dynamic> toList(dynamic value) {
    if (value is List) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) return decoded;
        } catch (_) {
          return const [];
        }
      }
    }
    return const [];
  }

  /// Parse a nested model. Returns null if [value] is not a map
  /// (string / int / list / null) or if [fromJson] throws.
  static T? toModelOrNull<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final map = toMapOrNull(value);
    if (map == null) return null;
    try {
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Parse a list of models, skipping items that are not maps.
  static List<T> toModelList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final result = <T>[];
    for (final item in toList(value)) {
      final model = toModelOrNull(item, fromJson);
      if (model != null) result.add(model);
    }
    return result;
  }
}
