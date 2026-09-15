import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

/// Laravel often returns mixed messages such as
/// "Поле start date обязательно для заполнения."
/// The sentence is localized, but the field name stays English.
/// This helper maps that field name into the current app language.
String localizeApiValidationMessage(
  String message,
  AppLocalizations? loc,
) {
  if (loc == null) return message;

  final trimmed = message.trim();
  if (trimmed.isEmpty) return message;

  // Laravel "required" in Russian:
  // "Поле start date обязательно для заполнения."
  final ruRequired = RegExp(
    r'^Поле\s+[«"“]?(.+?)[»"”]?\s+обязательно для заполнения\.?$',
    caseSensitive: false,
  );
  final ruMatch = ruRequired.firstMatch(trimmed);
  if (ruMatch != null) {
    return _requiredFieldMessage(loc, ruMatch.group(1)!);
  }

  // Laravel "required" in English:
  // "The start date field is required."
  final enRequired = RegExp(
    r'^the\s+(.+?)\s+field is required\.?$',
    caseSensitive: false,
  );
  final enMatch = enRequired.firstMatch(trimmed);
  if (enMatch != null) {
    return _requiredFieldMessage(loc, enMatch.group(1)!);
  }

  // Any leftover English field tokens inside a mixed sentence.
  return _replaceKnownFieldNames(trimmed, loc);
}

String _requiredFieldMessage(AppLocalizations loc, String rawField) {
  final field = _localizeFieldName(rawField, loc);
  return loc.translate('field_required_named').replaceAll('{field}', field);
}

String _localizeFieldName(String rawField, AppLocalizations loc) {
  final normalized = rawField.trim().toLowerCase().replaceAll('_', ' ');
  final key = _fieldAliasToKey[normalized];
  if (key != null) {
    return loc.translate(key);
  }

  // Unknown field: try the snake_case key, then keep a readable label.
  final snakeKey = normalized.replaceAll(' ', '_');
  final translated = loc.translate(snakeKey);
  if (translated.isNotEmpty && translated != snakeKey) {
    return translated;
  }
  return rawField.trim();
}

String _replaceKnownFieldNames(String message, AppLocalizations loc) {
  var result = message;
  final aliases = _fieldAliasToKey.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final alias in aliases) {
    result = result.replaceAllMapped(
      RegExp(RegExp.escape(alias), caseSensitive: false),
      (_) => loc.translate(_fieldAliasToKey[alias]!),
    );
  }
  return result;
}

/// Laravel prints attributes as "start date" (spaces) or "start_date".
/// Map those labels onto existing translation keys.
const Map<String, String> _fieldAliasToKey = {
  'start date': 'start_date',
  'end date': 'end_date',
  'due date': 'deadline',
  'status id': 'status',
  'status': 'status',
  'phone': 'phone',
  'email': 'email',
  'deadline': 'deadline',
};
