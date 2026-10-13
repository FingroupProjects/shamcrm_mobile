/// Ответ `POST /forgot-password`.
/// Сервер кладёт в `result` список: сначала карточку пользователя, затем код.
/// Пример: `[{... "id": 8, "email": "..."}, 8762]`.
class ForgotPasswordChallenge {
  final int userId;
  final String code;
  final String email;

  const ForgotPasswordChallenge({
    required this.userId,
    required this.code,
    required this.email,
  });
}

/// Разбирает `result` из `/forgot-password`.
/// Код потом сравнивается на устройстве, как временный PIN в «Забыли PIN».
ForgotPasswordChallenge parseForgotPasswordResult(
  Object? result, {
  String fallbackEmail = '',
}) {
  if (result is! List || result.length < 2 || result.first is! Map) {
    throw const FormatException('forgot_password_bad_result');
  }

  final user = Map<String, dynamic>.from(result.first as Map);
  final userId = _asInt(user['id']);
  final code = resetCodeText(result[1]);
  if (userId == null || code.isEmpty) {
    throw const FormatException('forgot_password_bad_result');
  }

  final rawEmail = user['email']?.toString().trim() ?? '';
  return ForgotPasswordChallenge(
    userId: userId,
    code: code,
    email: rawEmail.isNotEmpty ? rawEmail : fallbackEmail.trim(),
  );
}

/// Число `8762` и строка `"8762"` должны совпасть с тем, что ввёл человек.
String resetCodeText(Object? value) {
  if (value is int) return value.toString();
  if (value is num && value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value?.toString().trim() ?? '';
}

bool passwordCodesMatch(String entered, String expected) {
  final left = entered.trim();
  final right = expected.trim();
  return left.isNotEmpty && left == right;
}

/// `changePassword` и `setPassword` отвечают `{ "result": "Success", "errors": null }`.
bool passwordApiSucceeded(int statusCode, Object? decoded) {
  if (statusCode != 200 && statusCode != 201) return false;
  if (decoded is! Map) return false;

  if (_hasErrors(decoded['errors'])) return false;

  final result = decoded['result'];
  if (result is String) return result.toLowerCase() == 'success';
  return result == true;
}

/// Берём первую ошибку поля. Общее "The given data was invalid." менее полезно.
String passwordApiErrorText(
  Object? decoded, {
  String fallback = 'password_change_error',
}) {
  if (decoded is Map) {
    final fieldError = _firstError(decoded['errors']);
    if (fieldError != null && fieldError.isNotEmpty) return fieldError;

    final message = decoded['message']?.toString().trim() ?? '';
    if (message.isNotEmpty && !_isGenericValidationMessage(message)) {
      return message;
    }
  }
  return fallback;
}

bool _hasErrors(Object? errors) {
  if (errors == null || errors == false) return false;
  if (errors is String) return errors.trim().isNotEmpty;
  if (errors is List) return errors.isNotEmpty;
  if (errors is Map) return errors.isNotEmpty;
  return true;
}

String? _firstError(Object? errors) {
  if (errors is List) {
    for (final item in errors) {
      final text = item?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }
  if (errors is String) {
    final text = errors.trim();
    return text.isEmpty ? null : text;
  }
  if (errors is Map) {
    for (final value in errors.values) {
      final nested = _firstError(value);
      if (nested != null && nested.isNotEmpty) return nested;
    }
  }
  return null;
}

bool _isGenericValidationMessage(String message) {
  final lower = message.toLowerCase();
  return lower == 'the given data was invalid.' ||
      lower == 'validation failed' ||
      lower == 'unprocessable entity';
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
