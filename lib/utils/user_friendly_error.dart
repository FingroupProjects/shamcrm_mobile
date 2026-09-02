import 'dart:io';

/// Converts technical exceptions into short messages that are safe to show
/// in the app UI. The original exception is still available for logging.
String friendlyError(Object error,
    {String fallback = 'Не удалось выполнить операцию. Попробуйте ещё раз.'}) {
  final raw = error.toString().trim();
  final normalized = raw.toLowerCase();

  if (error is SocketException ||
      normalized.contains('socketexception') ||
      normalized.contains('timeoutexception') ||
      normalized.contains('connection') ||
      normalized.contains('network')) {
    return 'Проблема с подключением к интернету. Проверьте сеть и попробуйте ещё раз.';
  }

  if (normalized.contains('401') ||
      normalized.contains('unauthorized') ||
      normalized.contains('неавториз')) {
    return 'Сессия завершилась. Пожалуйста, войдите в приложение снова.';
  }

  if (normalized.contains('403') || normalized.contains('forbidden')) {
    return 'Недостаточно прав для выполнения этого действия.';
  }

  if (normalized.contains('404') || normalized.contains('not found')) {
    return 'Запрашиваемые данные не найдены.';
  }

  if (normalized.contains('500') || normalized.contains('server error')) {
    return 'Сервис временно недоступен. Попробуйте ещё раз позже.';
  }

  // Keep useful server text, but remove Dart's technical "Exception: " prefix
  // and never expose an empty/technical-only value to the user.
  final cleaned = raw
      .replaceFirst(
          RegExp(r'^\s*(?:[A-Za-z_][A-Za-z0-9_.]*Exception|Error)\s*:\s*',
              caseSensitive: false),
          '')
      .replaceFirst(RegExp(r'^\s*@e\s*', caseSensitive: false), '')
      .trim();

  if (cleaned.isEmpty || _looksTechnical(cleaned)) return fallback;
  return _localizeServerMessage(cleaned);
}

String _localizeServerMessage(String message) {
  final lower = message.toLowerCase().trim();

  if (lower == 'duplicate request' ||
      lower.contains('duplicate request') ||
      lower.contains('duplicaterequest') ||
      lower.contains('duplicate_request')) {
    return 'Запрос уже отправлен. Не нажимайте повторно.';
  }
  if (lower.contains('too many requests') || lower.contains('too many attempt')) {
    return 'Слишком много запросов. Подождите немного и попробуйте снова.';
  }
  if (lower == 'unauthenticated' || lower.contains('unauthenticated')) {
    return 'Сессия завершилась. Пожалуйста, войдите в приложение снова.';
  }
  if (lower == 'validation failed' || lower.contains('the given data was invalid')) {
    return 'Проверьте введённые данные и попробуйте снова.';
  }

  return message;
}

bool _looksTechnical(String value) {
  final text = value.toLowerCase();
  return text == 'exception' ||
      text == 'error' ||
      text.contains('stack trace') ||
      text.contains(' at package:') ||
      text.contains('dart:') ||
      text.startsWith('instance of ');
}
