import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/http/socket_inspector.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Одно Pusher-соединение на `presence-user.{uniqueId}`.
///
/// Раньше лиды, сделки, чаты и шапка каждый раз в initState открывали свой
/// сокет. Оболочка держит на экране только текущую вкладку, поэтому переход
/// между разделами заново звал `/broadcasting/auth`.
/// Экраны только слушают события. Повторная авторизация канала при этом не идёт.
class UserRealtimeSocket {
  UserRealtimeSocket._();

  static final UserRealtimeSocket instance = UserRealtimeSocket._();

  final ApiService _api = ApiService();

  PusherChannelsClient? _client;
  PresenceChannel? _userChannel;
  StreamSubscription<PusherChannelsClientLifeCycleState>? _lifecycleSub;
  StreamSubscription<void>? _establishedSub;
  String? _sessionKey;
  Future<bool>? _pending;
  int _generation = 0;
  bool _established = false;

  bool get isEstablished => _established;

  /// Уже подписанный presence-user. Новый auth из этого метода не уходит.
  Future<PresenceChannel?> userChannel() async {
    final ready = await ensureReady();
    if (!ready) return null;
    return _userChannel;
  }

  /// Подписка на событие пользовательского канала. Сокет создаётся один раз.
  Future<StreamSubscription<ChannelReadEvent>?> listen(
    String eventName,
    void Function(ChannelReadEvent event) onData,
  ) async {
    final ready = await ensureReady();
    final channel = _userChannel;
    if (!ready || channel == null) return null;
    return channel.bind(eventName).listen(onData);
  }

  Future<bool> ensureReady() {
    final pending = _pending;
    if (pending != null) return pending;
    final run = _ensure();
    _pending = run;
    return run.whenComplete(() {
      if (identical(_pending, run)) _pending = null;
    });
  }

  /// Закрыть сокет при выходе из аккаунта. Повторный вызов безопасен.
  Future<void> close() async {
    _generation += 1;
    await _releaseClient();
  }

  Future<bool> _ensure() async {
    final session = await _loadSession();
    if (session == null) return false;
    if (_client != null &&
        !_client!.isDisposed &&
        _userChannel != null &&
        _sessionKey == session.key) {
      return true;
    }
    await _releaseClient();
    return _connect(session);
  }

  Future<bool> _connect(_RealtimeSession session) async {
    final generation = _generation;
    final options = PusherChannelsOptions.custom(
      uriResolver: (_) =>
          Uri.parse('wss://soketi.${session.mainDomain}/app/app-key'),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    final client = createLoggedPusherClient(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint('UserRealtimeSocket: connection error: $exception');
        // Пакет сам переподключится. Второй connect() снова авторизует канал.
        refresh();
      },
      minimumReconnectDelayDuration: const Duration(seconds: 3),
    );

    final channelName = 'presence-user.${session.userUniqueId}';
    final channel = client.presenceChannel(
      channelName,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(session.authUrl),
        headers: {
          'Authorization': 'Bearer ${session.token}',
          'X-Tenant': session.tenant,
        },
        onAuthFailed: (exception, trace) {
          debugPrint(
            'UserRealtimeSocket: auth failed for $channelName: $exception',
          );
        },
      ),
    );

    _lifecycleSub = client.lifecycleStream.listen((state) {
      _established =
          state == PusherChannelsClientLifeCycleState.establishedConnection;
    });
    // Новый socket id бывает только при реконнекте, не при открытии экрана.
    _establishedSub = client.onConnectionEstablished.listen((_) {
      channel.subscribeIfNotUnsubscribed();
    });

    try {
      await client.connect();
    } catch (error) {
      debugPrint('UserRealtimeSocket: connect failed: $error');
      await _establishedSub?.cancel();
      _establishedSub = null;
      await _lifecycleSub?.cancel();
      _lifecycleSub = null;
      client.dispose();
      return false;
    }

    if (generation != _generation) {
      client.dispose();
      return false;
    }

    _client = client;
    _userChannel = channel;
    _sessionKey = session.key;
    return true;
  }

  Future<void> _releaseClient() async {
    _established = false;
    _sessionKey = null;
    _userChannel = null;
    await _establishedSub?.cancel();
    _establishedSub = null;
    await _lifecycleSub?.cancel();
    _lifecycleSub = null;
    final client = _client;
    _client = null;
    client?.dispose();
  }

  Future<_RealtimeSession?> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userUniqueId = prefs.getString('unique_id');
    if (token == null ||
        token.isEmpty ||
        userUniqueId == null ||
        userUniqueId.isEmpty) {
      return null;
    }

    final entered = await _api.getEnteredDomain();
    var mainDomain = entered['enteredMainDomain'];
    var domain = entered['enteredDomain'];

    if (mainDomain == null ||
        mainDomain.isEmpty ||
        domain == null ||
        domain.isEmpty) {
      final verified = await _api.getVerifiedDomain();
      if (verified != null && verified.contains('-back.')) {
        final parts = verified.split('-back.');
        domain = parts.first;
        mainDomain = parts.sublist(1).join('-back.');
      } else {
        await _api.initialize();
        final baseUrl = await _api.getDynamicBaseUrl();
        final match =
            RegExp(r'https://(.+?)-back\.(.+?)(/|$)').firstMatch(baseUrl);
        domain = match?.group(1);
        mainDomain = match?.group(2);
      }
    }

    if (mainDomain == null ||
        mainDomain.isEmpty ||
        domain == null ||
        domain.isEmpty) {
      return null;
    }

    final tenant = '$domain-back';
    return _RealtimeSession(
      key: '$tenant|$userUniqueId',
      token: token,
      userUniqueId: userUniqueId,
      mainDomain: mainDomain,
      tenant: tenant,
      authUrl: 'https://$tenant.$mainDomain/broadcasting/auth',
    );
  }
}

class _RealtimeSession {
  const _RealtimeSession({
    required this.key,
    required this.token,
    required this.userUniqueId,
    required this.mainDomain,
    required this.tenant,
    required this.authUrl,
  });

  final String key;
  final String token;
  final String userUniqueId;
  final String mainDomain;
  final String tenant;
  final String authUrl;
}
