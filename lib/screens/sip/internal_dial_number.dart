import 'package:crm_task_manager/custom_widget/country_data_list.dart';

import 'calling_codes.dart';

/// Номер для исходящего SIP-звонка.
///
/// Внутренняя АТС уже подставляет код страны организации.
/// +992927777777 уходит как +992992927777777, и станция сбрасывает вызов.
/// Местный номер 927777777 при этом проходит.
///
/// Код снимается только здесь, в фоне. Карточка лида и поле набора
/// по-прежнему хранят номер с кодом. Звонок с телефона (tel:) не трогаем:
/// мобильная сеть код страны как раз ждёт.
String stripCountryCodeForInternalCall(
  String raw, {
  String? homeDialCode,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  // Короткий SIP-адрес, добавочный с * и # не являются городским номером.
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('sip:') ||
      lower.startsWith('sips:') ||
      trimmed.contains('@') ||
      trimmed.contains('*') ||
      trimmed.contains('#')) {
    return trimmed;
  }

  if (!RegExp(r'^[+0-9\s().-]+$').hasMatch(trimmed)) {
    return trimmed;
  }

  final compact = trimmed.replaceAll(RegExp(r'[\s().-]'), '');
  final explicitInternational =
      compact.startsWith('+') || compact.startsWith('00');

  var digits = compact.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  if (digits.isEmpty) return trimmed;

  // Свой код организации важнее: чужой код не превращаем в местный номер.
  // Если настройка ещё не пришла, код узнаём по самому номеру.
  final homeCode = resolveHomeCallingCode(homeDialCode);
  final code = homeCode ?? longestCallingCodePrefix(digits);
  if (code == null) return digits;

  return _stripKnownCode(
    digits,
    code,
    explicitInternational: explicitInternational,
  );
}

/// Код страны организации: "+992", "992" или код ISO вроде "TJ".
String? resolveHomeCallingCode(String? savedDialCode) {
  final trimmed = savedDialCode?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final compact = trimmed.replaceAll(RegExp(r'[\s().-]'), '');
  final upper = compact.toUpperCase();
  if (upper.startsWith('+') || RegExp(r'^\d+$').hasMatch(compact)) {
    final digits = compact.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (kCallingCodeNationalLength.containsKey(digits)) return digits;
    if (digits.length > 4) return longestCallingCodePrefix(digits);
    // Код ещё не внесён в таблицу — всё равно снимаем его как есть.
    return digits;
  }

  for (final country in countries) {
    final fullName = (country.fullname ?? '').toUpperCase();
    if (country.name.toUpperCase() == upper || fullName == upper) {
      final digits = country.dialCode.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) return digits;
    }
  }
  return null;
}

/// Самый длинный код из 1–3 цифр. Иначе 927... читается как Пакистан +92.
String? longestCallingCodePrefix(String digits) {
  if (digits.length >= 3) {
    final code = digits.substring(0, 3);
    if (kCallingCodeNationalLength.containsKey(code)) return code;
  }
  if (digits.length >= 2) {
    final code = digits.substring(0, 2);
    if (kCallingCodeNationalLength.containsKey(code)) return code;
  }
  if (digits.isNotEmpty &&
      kCallingCodeNationalLength.containsKey(digits.substring(0, 1))) {
    return digits.substring(0, 1);
  }
  return null;
}

String _stripKnownCode(
  String digits,
  String code, {
  required bool explicitInternational,
}) {
  final national = kCallingCodeNationalLength[code] ?? 10;
  // У коротких нумераций (4–5 цифр) порог ниже, чтобы не съесть добавочный.
  final minRest = national <= 5 ? national : 6;
  final maxRest = national + 3;
  var current = digits;
  var allowShort = explicitInternational;

  for (var attempt = 0; attempt < 3; attempt++) {
    if (!current.startsWith(code)) break;
    final rest = current.substring(code.length);
    final exactLocal = rest.length == national;
    final international = allowShort &&
        rest.length >= minRest &&
        rest.length <= maxRest;
    // Повтор кода: 992992927777777. Снимаем, пока остаток ещё с тем же кодом.
    final nested = rest.startsWith(code) ? rest.substring(code.length) : '';
    final duplicated = nested.isNotEmpty &&
        (nested.length == national ||
            (allowShort &&
                nested.length >= minRest &&
                nested.length <= maxRest));
    if (!exactLocal && !international && !duplicated) break;
    current = rest;
    allowShort = false;
  }
  return current;
}
