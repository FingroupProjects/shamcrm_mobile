/// Возвращает полный URL файла.
/// - Если [path] уже начинается с http:// или https://, возвращается как есть.
/// - Если [path] начинается с storage/http:// или storage/https:// —
///   backend уже вернул полный путь с префиксом storage/, убираем его.
/// - Если [path] уже начинается с storage/ — конструирует URL из [baseUrl] + [path].
/// - Иначе — конструирует URL из [baseUrl] + storage/ + [path].
String resolveFileUrl(String? path, String? baseUrl) {
  if (path == null || path.isEmpty) return '';

  // Сервер уже вернул полный URL — используем как есть
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  // Убираем ведущий слеш
  final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

  // Если путь уже содержит storage/ перед http/https — backend уже добавил
  // storage/ к полному URL. Просто убираем storage/ и используем как есть.
  if (normalizedPath.startsWith('storage/http')) {
    return normalizedPath.substring(8); // убираем 'storage/'
  }

  if (baseUrl == null || baseUrl.isEmpty) return normalizedPath;

  // Нормализуем: добавляем storage/ если его нет
  final finalPath = normalizedPath.startsWith('storage/')
      ? normalizedPath
      : 'storage/$normalizedPath';

  return Uri.parse(baseUrl).resolve(finalPath).toString();
}
