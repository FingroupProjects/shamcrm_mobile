import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';

import 'http_log_model.dart';
import 'http_logger.dart';

/// Создаёт Pusher-клиент и в debug пишет каждый входящий кадр в HTTP Inspector.
///
/// Пакет не перехватывает сокет сам. Поэтому все клиенты приложения
/// нужно создавать через эту функцию, а не через [PusherChannelsClient.websocket].
PusherChannelsClient createLoggedPusherClient({
  required PusherChannelsOptions options,
  required void Function(
    dynamic exception,
    StackTrace trace,
    void Function() refresh,
  ) connectionErrorHandler,
  Duration minimumReconnectDelayDuration = const Duration(seconds: 1),
}) {
  final socketUrl = options.uri.toString();
  final clientLabel = SocketInspector.nextClientLabel();

  final client = PusherChannelsClient.websocket(
    options: options,
    minimumReconnectDelayDuration: minimumReconnectDelayDuration,
    connectionErrorHandler: (exception, trace, refresh) {
      // Ошибка соединения не приходит как обычное событие канала.
      SocketInspector.log(
        socketUrl: socketUrl,
        clientLabel: clientLabel,
        eventName: 'connection_error',
        payload: '$exception',
        error: '$exception',
      );
      connectionErrorHandler(exception, trace, refresh);
    },
  );

  SocketInspector.attach(
    client,
    socketUrl: socketUrl,
    clientLabel: clientLabel,
  );
  return client;
}

/// Пишет жизненный цикл сокета и все входящие события в [HttpLogger].
class SocketInspector {
  SocketInspector._();

  static int _clients = 0;
  static int _events = 0;

  /// Короткий номер клиента, чтобы в инспекторе отличать параллельные сокеты.
  static String nextClientLabel() {
    _clients += 1;
    return 'socket-$_clients';
  }

  /// Подписывается на поток клиента. Подписка закрывается вместе с клиентом.
  static void attach(
    PusherChannelsClient client, {
    required String socketUrl,
    required String clientLabel,
  }) {
    if (!kDebugMode) return;

    client.lifecycleStream.listen((state) {
      // Саму ошибку уже пишет connectionErrorHandler, с текстом исключения.
      if (state == PusherChannelsClientLifeCycleState.connectionError) {
        return;
      }
      log(
        socketUrl: socketUrl,
        clientLabel: clientLabel,
        channel: 'lifecycle',
        eventName: state.name,
        payload: state.name,
      );
    });

    client.eventStream.listen((event) {
      final data = event.data;
      log(
        socketUrl: socketUrl,
        clientLabel: clientLabel,
        channel: event.channelName,
        eventName: event.name.isEmpty ? 'unknown' : event.name,
        payload: _payloadText(data),
        error: _isErrorEvent(event.name) ? _payloadText(data) : null,
      );
    });
  }

  /// Кладёт одну строку сокета в общий список инспектора.
  static void log({
    required String socketUrl,
    required String clientLabel,
    required String eventName,
    String? channel,
    String? payload,
    String? error,
  }) {
    if (!kDebugMode) return;

    _events += 1;
    final id = '${DateTime.now().microsecondsSinceEpoch}_$_events';
    HttpLogger().addLog(
      HttpLogModel(
        id: id,
        timestamp: DateTime.now(),
        method: 'WS',
        url: _eventUrl(socketUrl, channel, eventName),
        requestHeaders: {
          'Transport': 'WebSocket',
          'Client': clientLabel,
          if (channel != null && channel.isNotEmpty) 'Channel': channel,
          'Event': eventName,
        },
        requestBody: payload,
        statusCode: error == null ? 200 : 500,
        responseBody: error == null ? 'Socket event received' : null,
        error: error,
        duration: Duration.zero,
      ),
    );
  }

  static bool _isErrorEvent(String eventName) {
    final name = eventName.toLowerCase();
    return name.contains('error') || name == 'pusher:error';
  }

  /// Адрес, который инспектор показывает в карточке: хост + канал + событие.
  static String _eventUrl(String socketUrl, String? channel, String eventName) {
    final base = Uri.tryParse(socketUrl);
    final segments = <String>[
      'socket',
      if (channel != null && channel.isNotEmpty) channel,
      eventName,
    ];
    if (base == null || !base.hasScheme) {
      return '/${segments.join('/')}';
    }
    return base.replace(pathSegments: segments).toString();
  }

  static String? _payloadText(dynamic data) {
    if (data == null) return null;
    final text = data is String ? data : _encode(data);
    const maxLength = 20000;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}\n… truncated ${text.length - maxLength} chars';
  }

  static String _encode(dynamic data) {
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }
}
