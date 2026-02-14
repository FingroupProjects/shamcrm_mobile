/// Модель для хранения информации об HTTP запросе/ответе
class HttpLogModel {
  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final Map<String, String>? requestHeaders;
  final String? requestBody;
  final int? statusCode;
  final Map<String, String>? responseHeaders;
  final String? responseBody;
  final Duration? duration;
  final String? error;

  HttpLogModel({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseHeaders,
    this.responseBody,
    this.duration,
    this.error,
  });

  /// Создает копию с обновленными полями (для добавления response данных)
  HttpLogModel copyWith({
    int? statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
    Duration? duration,
    String? error,
  }) {
    return HttpLogModel(
      id: id,
      timestamp: timestamp,
      method: method,
      url: url,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      duration: duration ?? this.duration,
      error: error ?? this.error,
    );
  }

  /// Получить короткий URL (без query параметров)
  String get shortUrl {
    try {
      final uri = Uri.parse(url);
      return uri.path;
    } catch (e) {
      return url;
    }
  }

  /// Получить цвет статуса (для UI)
  String get statusColor {
    if (error != null) return 'red';
    if (statusCode == null) return 'grey';
    if (statusCode! >= 200 && statusCode! < 300) return 'green';
    if (statusCode! >= 300 && statusCode! < 400) return 'yellow';
    if (statusCode! >= 400 && statusCode! < 500) return 'orange';
    return 'red';
  }

  /// Проверка успешности запроса
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  @override
  String toString() {
    return 'HttpLogModel(id: $id, method: $method, url: $url, status: $statusCode)';
  }
}
