/// Replaces invalid UTF-16 code units with the replacement character.
///
/// Native text APIs reject lone surrogate code units, while malformed server or
/// device-contact data can still contain them. Keeping this at the data boundary
/// prevents one bad value from crashing Flutter text layout.
String sanitizeUtf16(String value) {
  final codeUnits = value.codeUnits;
  var hasInvalidCodeUnit = false;
  final sanitized = <int>[];

  for (var index = 0; index < codeUnits.length; index++) {
    final unit = codeUnits[index];
    final isHighSurrogate = unit >= 0xD800 && unit <= 0xDBFF;
    final isLowSurrogate = unit >= 0xDC00 && unit <= 0xDFFF;

    if (isHighSurrogate) {
      final hasLowSurrogateAfter = index + 1 < codeUnits.length &&
          codeUnits[index + 1] >= 0xDC00 &&
          codeUnits[index + 1] <= 0xDFFF;
      if (hasLowSurrogateAfter) {
        sanitized.add(unit);
        sanitized.add(codeUnits[++index]);
      } else {
        hasInvalidCodeUnit = true;
        sanitized.add(0xFFFD);
      }
    } else if (isLowSurrogate) {
      hasInvalidCodeUnit = true;
      sanitized.add(0xFFFD);
    } else {
      sanitized.add(unit);
    }
  }

  return hasInvalidCodeUnit ? String.fromCharCodes(sanitized) : value;
}
