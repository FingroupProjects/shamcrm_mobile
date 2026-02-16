/// Safe type conversion utilities to prevent crashes from type mismatches
/// Handles int ↔ double ↔ String conversions gracefully
class SafeConverters {
  /// Convert any numeric type to double safely
  /// Handles: int, double, String, null
  /// Returns defaultValue on conversion failure
  static double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }

    // Fallback for any other type
    return defaultValue;
  }

  /// Convert any numeric type to int safely
  /// Handles: int, double, String, null
  /// Returns defaultValue on conversion failure
  static int toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is double) return value.toInt();

    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }

    // Fallback for any other type
    return defaultValue;
  }

  /// Safe string conversion
  /// Always returns a string, never null
  static String toSafeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Convert to Color from hex string safely
  /// Handles: "#RRGGBB", "RRGGBB", null
  /// Returns defaultColor on conversion failure
  static int toColorInt(dynamic value, {int defaultColor = 0xFF4ae6b3}) {
    if (value == null) return defaultColor;

    String hexString = value.toString().replaceAll('#', '');

    if (hexString.length == 6) {
      try {
        return int.parse('FF$hexString', radix: 16);
      } catch (e) {
        return defaultColor;
      }
    }

    return defaultColor;
  }

  /// Safely get element from list at index
  /// Returns defaultValue if index out of bounds or list is null
  static T elementAtOrDefault<T>(List<T>? list, int index, T defaultValue) {
    if (list == null || index < 0 || index >= list.length) {
      return defaultValue;
    }
    return list[index];
  }

  /// Convert dynamic list to List<double> safely
  static List<double> toDoubleList(dynamic value, {int expectedLength = 0}) {
    if (value == null) {
      return List.filled(expectedLength, 0.0);
    }

    if (value is! List) {
      return List.filled(expectedLength, 0.0);
    }

    final result = value.map((e) => toDouble(e)).toList();

    // Pad with zeros if shorter than expected
    if (expectedLength > 0 && result.length < expectedLength) {
      result.addAll(List.filled(expectedLength - result.length, 0.0));
    }

    return result;
  }

  /// Convert dynamic list to List<int> safely
  static List<int> toIntList(dynamic value, {int expectedLength = 0}) {
    if (value == null) {
      return List.filled(expectedLength, 0);
    }

    if (value is! List) {
      return List.filled(expectedLength, 0);
    }

    final result = value.map((e) => toInt(e)).toList();

    // Pad with zeros if shorter than expected
    if (expectedLength > 0 && result.length < expectedLength) {
      result.addAll(List.filled(expectedLength - result.length, 0));
    }

    return result;
  }
}
