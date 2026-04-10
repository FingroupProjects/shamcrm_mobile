import 'dart:io' show Platform;
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';

import 'sip_state.dart';

class SipService extends ChangeNotifier
    with WidgetsBindingObserver
    implements SipUaHelperListener {
  SipService._internal();
  static final SipService _instance = SipService._internal();
  factory SipService() => _instance;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _serverKey = 'sip_server';
  static const String _loginKey = 'sip_login';
  static const String _passwordKey = 'sip_password';
  static const String _sipIdKey = 'sip_target_sip_id';
  static const String _transportKey = 'sip_transport';
  static const String _portKey = 'sip_port';
  static const String _enabledKey = 'sip_enabled';
  static const String _backgroundReliabilityPromptedKey =
      'sip_background_reliability_prompted';
  static const MethodChannel _nativeSipMethodChannel =
      MethodChannel('com.shamcrm/native_sip/methods');
  static const EventChannel _nativeSipEventChannel =
      EventChannel('com.shamcrm/native_sip/events');

  final SIPUAHelper _helper = SIPUAHelper();
  final Connectivity _connectivity = Connectivity();

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  SipUiState _state = SipUiState.initial();
  SipUiState get state => _state;

  bool _initialized = false;
  bool _renderersReady = false;
  bool get renderersReady => _renderersReady;
  bool _sipScreenVisible = false;
  bool get isSipScreenVisible => _sipScreenVisible;
  bool _shouldStayConnected = false;
  bool _persistentSipEnabled = false;
  bool _networkAvailable = true;
  bool _reconnectInProgress = false;
  DateTime? _lastReconnectAttemptAt;
  Timer? _reconnectTimer;
  Timer? _registrationWatchdogTimer;
  Timer? _keepAliveTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<dynamic>? _nativeSipEventsSubscription;

  Call? _activeCall;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  SipCallDirection _currentCallDirection = SipCallDirection.outgoing;
  DateTime? _currentCallStartedAt;
  String? _currentCallTarget;
  String? _currentInviteUri;

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;
    _helper.addSipUaHelperListener(this);
    WidgetsBinding.instance.addObserver(this);

    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _renderersReady = true;

    final server = await _storage.read(key: _serverKey) ?? '';
    final login = await _storage.read(key: _loginKey) ?? '';
    final password = await _storage.read(key: _passwordKey) ?? '';
    final sipId = await _storage.read(key: _sipIdKey) ?? '';
    final transportRaw = await _storage.read(key: _transportKey) ?? 'udp';
    final portRaw = await _storage.read(key: _portKey) ?? '5060';
    final enabledRaw = await _storage.read(key: _enabledKey) ?? 'false';
    final parsedPort = int.tryParse(portRaw) ?? 5060;
    _persistentSipEnabled = enabledRaw == 'true';
    final transport = switch (transportRaw) {
      'tcp' => SipTransportUi.tcp,
      'udp' => SipTransportUi.udp,
      _ => SipTransportUi.ws,
    };

    _state = _state.copyWith(
      server: server,
      login: login,
      password: password,
      sipId: sipId,
      transport: transport,
      port: parsedPort,
      clearError: true,
      clearRemoteIdentity: true,
    );
    await _initializeNativeSipBridge();
    await _syncNativeSnapshot();
    _startConnectivityMonitoring();
    _startRegistrationWatchdog();
    unawaited(_restorePersistentConnection());
    notifyListeners();
  }

  bool _shouldUseNativeSip() {
    return Platform.isAndroid &&
        (_state.transport == SipTransportUi.udp ||
            _state.transport == SipTransportUi.tcp);
  }

  void setSipScreenVisible(bool visible) {
    if (_sipScreenVisible == visible) return;
    _sipScreenVisible = visible;
    notifyListeners();
  }

  Future<void> _restorePersistentConnection() async {
    if (!_persistentSipEnabled || !_hasSipCredentials()) {
      return;
    }

    if (_shouldUseNativeSip()) {
      await _syncNativeSnapshot(restoreIfNeeded: true);
      final registration = _state.registrationStatus;
      if (registration == SipRegistrationUiStatus.registered ||
          registration == SipRegistrationUiStatus.registering) {
        _shouldStayConnected = true;
        return;
      }
    }

    await connect();
  }

  Future<void> _initializeNativeSipBridge() async {
    _nativeSipEventsSubscription?.cancel();
    _nativeSipEventsSubscription =
        _nativeSipEventChannel.receiveBroadcastStream().listen(
      _handleNativeSipEvent,
      onError: (Object error) {
        debugPrint('SipService native SIP stream error: $error');
      },
    );

    try {
      await _nativeSipMethodChannel.invokeMethod('initialize');
    } catch (error) {
      debugPrint('SipService native SIP initialize failed: $error');
    }
  }

  Future<void> _syncNativeSnapshot({bool restoreIfNeeded = false}) async {
    if (!_shouldUseNativeSip()) {
      return;
    }

    if (restoreIfNeeded) {
      await _invokeNativeSipMethod<bool>('restoreRegistrationIfNeeded');
    }

    final snapshot = await _invokeNativeSipMethod<Map<dynamic, dynamic>>(
      'getStateSnapshot',
    );
    if (snapshot == null) {
      return;
    }

    _applyNativeSnapshot(Map<String, dynamic>.from(snapshot), notify: true);
  }

  Future<void> saveDraft({
    required String server,
    required String login,
    required String password,
    required String sipId,
    required SipTransportUi transport,
    required int port,
  }) async {
    final normalizedServer = _normalizeServerInput(server, transport);

    _state = _state.copyWith(
      server: normalizedServer,
      login: login.trim(),
      password: password,
      sipId: sipId.trim(),
      transport: transport,
      port: port,
      clearError: true,
    );

    await _storage.write(key: _serverKey, value: _state.server);
    await _storage.write(key: _loginKey, value: _state.login);
    await _storage.write(key: _passwordKey, value: _state.password);
    await _storage.write(key: _sipIdKey, value: _state.sipId);
    await _storage.write(
        key: _transportKey,
        value: switch (_state.transport) {
          SipTransportUi.tcp => 'tcp',
          SipTransportUi.udp => 'udp',
          SipTransportUi.ws => 'ws',
        });
    await _storage.write(key: _portKey, value: _state.port.toString());

    notifyListeners();
  }

  Future<void> prepareSipRuntimePermissions() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await Permission.notification.request();
    } catch (_) {}

    try {
      await Permission.microphone.request();
    } catch (_) {}

    if (_shouldUseNativeSip()) {
      final prompted =
          await _storage.read(key: _backgroundReliabilityPromptedKey);
      if (prompted != 'true') {
        final opened = await _invokeNativeSipMethod<bool>(
              'requestBackgroundReliabilitySettings',
            ) ??
            false;
        if (opened) {
          await _storage.write(
            key: _backgroundReliabilityPromptedKey,
            value: 'true',
          );
        }
      }
      // Дополнительно предлагаем Xiaomi AutoStart настройки
      // (Poco X6 Pro HyperOS 2 без AutoStart убивает фоновые сервисы)
      await openXiaomiSettings();
    }
  }

  /// Открывает настройки AutoStart для Xiaomi/HyperOS.
  /// Возвращает true если экран был открыт, false если не Xiaomi устройство.
  Future<bool> openXiaomiSettings() async {
    if (!Platform.isAndroid) return false;
    return await _invokeNativeSipMethod<bool>('openXiaomiSettings') ?? false;
  }

  Future<void> connect() async {
    if (!_hasSipCredentials()) {
      _setError('SIP config is incomplete. Fill server, login and password.');
      return;
    }

    final validationError = _validateSipConfiguration();
    if (validationError != null) {
      _setError(validationError);
      return;
    }

    if (!_networkAvailable) {
      _setError('No internet connection. SIP registration paused.');
      return;
    }

    if (_shouldUseNativeSip()) {
      await Permission.notification.request();
    }

    _shouldStayConnected = true;
    _persistentSipEnabled = true;
    await _storage.write(key: _enabledKey, value: 'true');
    _logSipConfig('connect');
    await _startSipRegistration();
  }

  Future<void> _startSipRegistration({bool clearError = true}) async {
    _state = _state.copyWith(
      registrationStatus: SipRegistrationUiStatus.registering,
      callStatus: SipCallUiStatus.idle,
      clearError: clearError,
      clearRemoteIdentity: true,
    );
    notifyListeners();

    final domain = _extractDomain(_state.server);
    final authUser = _extractAuthUser(_state.login);
    final uri = _buildSipUri(_state.login, domain);
    _logSipConfig(
      '_startSipRegistration',
      extra: <String, String>{
        'domain': domain,
        'authUser': authUser,
        'uri': uri,
      },
    );

    _lastReconnectAttemptAt = DateTime.now();

    if (_shouldUseNativeSip()) {
      final success = await _invokeNativeSipMethod<bool>(
            'register',
            <String, dynamic>{
              'server': domain,
              'login': _state.login.trim(),
              'password': _state.password,
              'port': _state.port,
              'transport':
                  _state.transport == SipTransportUi.tcp ? 'tcp' : 'udp',
              'authUser': authUser,
            },
          ) ??
          false;

      if (!success) {
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.failed,
          errorMessage: 'Native SIP registration failed',
        );
        notifyListeners();
      }
      return;
    }

    final settings = UaSettings();
    if (_state.transport == SipTransportUi.ws) {
      settings.webSocketUrl = _toWebSocketUrl(_state.server, _state.port);
      settings.webSocketSettings.allowBadCertificate = true;
      settings.transportType = TransportType.WS;
    }
    settings.uri = uri;
    settings.authorizationUser = authUser;
    settings.password = _state.password;
    settings.displayName = authUser;
    settings.userAgent = 'SHAMCRM SIP';
    settings.register_expires = 300;
    settings.connectionRecoveryMinInterval = 2;
    settings.connectionRecoveryMaxInterval = 30;
    settings.register = true;
    await _helper.start(settings);
  }

  Future<void> disconnect() async {
    _shouldStayConnected = false;
    _persistentSipEnabled = false;
    await _storage.write(key: _enabledKey, value: 'false');
    _cancelReconnect();
    _stopKeepAlive();

    _activeCall = null;
    if (_shouldUseNativeSip()) {
      await _invokeNativeSipMethod('unregister');
    } else {
      try {
        _activeCall?.hangup(<String, dynamic>{'status_code': 603});
      } catch (_) {}

      if (_helper.registered) {
        _helper.unregister(true);
      }
      _helper.stop();
    }
    _releaseStreams();

    _state = _state.copyWith(
      registrationStatus: SipRegistrationUiStatus.disconnected,
      callStatus: SipCallUiStatus.idle,
      isMuted: false,
      isSpeakerOn: false,
      clearError: true,
      clearRemoteIdentity: true,
    );
    notifyListeners();
  }

  Future<void> makeCall() async {
    if (_state.registrationStatus != SipRegistrationUiStatus.registered) {
      _setError('SIP is not registered. Connect first.');
      return;
    }

    if (_state.sipId.trim().isEmpty) {
      _setError('sipId is empty.');
      return;
    }

    _currentCallDirection = SipCallDirection.outgoing;
    _currentCallTarget = _state.sipId.trim();
    _currentCallStartedAt = null;

    final target = _buildTargetUri(_state.sipId, _extractDomain(_state.server));
    _currentInviteUri = target;

    if (_shouldUseNativeSip()) {
      final granted = await _ensureMediaPermissions(includeCamera: false);
      if (!granted) {
        _setError('Microphone permission is required for SIP calls.');
        return;
      }

      _logSipConfig(
        'nativeMakeCall',
        extra: <String, String>{
          'target': target,
          'dialed': _state.sipId.trim(),
        },
      );
      final success = await _invokeNativeSipMethod<bool>(
            'makeCall',
            <String, dynamic>{'target': target},
          ) ??
          false;
      if (!success) {
        _setError('Native SIP call failed to start.');
        return;
      }

      _state = _state.copyWith(
        callStatus: SipCallUiStatus.calling,
        clearError: true,
      );
      notifyListeners();
      return;
    }

    final granted = await _ensureMediaPermissions(includeCamera: false);
    if (!granted) {
      _setError('Microphone permission is required for SIP calls.');
      return;
    }

    _logSipConfig(
      'makeCall',
      extra: <String, String>{
        'target': target,
        'dialed': _state.sipId.trim(),
      },
    );
    final success = await _helper.call(target, voiceOnly: true);

    if (!success) {
      _setError('Failed to start outgoing call.');
      return;
    }

    _state = _state.copyWith(
      callStatus: SipCallUiStatus.calling,
      clearError: true,
    );
    notifyListeners();
  }

  Future<void> acceptCall() async {
    if (_shouldUseNativeSip()) {
      final granted = await _ensureMediaPermissions(includeCamera: false);
      if (!granted) {
        _setError('Microphone permission is required for SIP calls.');
        return;
      }

      final success = await _invokeNativeSipMethod<bool>('acceptCall') ?? false;
      if (!success) {
        _setError('Failed to accept native SIP call.');
      }
      return;
    }

    final call = _activeCall;
    if (call == null) return;

    final granted = await _ensureMediaPermissions(includeCamera: false);
    if (!granted) {
      _setError('Microphone permission is required.');
      return;
    }

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    call.answer(_helper.buildCallOptions(true), mediaStream: stream);

    _state = _state.copyWith(
      callStatus: SipCallUiStatus.inCall,
      clearError: true,
    );
    notifyListeners();
  }

  Future<void> hangup() async {
    if (_shouldUseNativeSip()) {
      await _invokeNativeSipMethod('hangup');
      return;
    }

    if (_activeCall == null) return;
    _activeCall!.hangup(<String, dynamic>{'status_code': 603});
  }

  Future<void> decline() async {
    if (_shouldUseNativeSip()) {
      await _invokeNativeSipMethod('declineCall');
      return;
    }

    if (_activeCall == null) return;
    _activeCall!.hangup(<String, dynamic>{'status_code': 486});
  }

  Future<void> toggleMute() async {
    final targetMuted = !_state.isMuted;
    if (_shouldUseNativeSip()) {
      final success = await _invokeNativeSipMethod<bool>(
            'setMuted',
            <String, dynamic>{'muted': targetMuted},
          ) ??
          false;
      if (!success) {
        _setError('Failed to change mute state.');
        return;
      }
    } else {
      if (_activeCall == null) return;

      if (targetMuted) {
        _activeCall!.mute(true, false);
      } else {
        _activeCall!.unmute(true, false);
      }
    }

    _state = _state.copyWith(isMuted: targetMuted);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    final targetSpeaker = !_state.isSpeakerOn;
    if (_shouldUseNativeSip()) {
      final success = await _invokeNativeSipMethod<bool>(
            'setSpeaker',
            <String, dynamic>{'speakerOn': targetSpeaker},
          ) ??
          false;
      if (!success) {
        _setError('Failed to change speaker state.');
        return;
      }
    } else {
      final track = _localStream?.getAudioTracks().isNotEmpty == true
          ? _localStream!.getAudioTracks().first
          : null;

      if (track == null) return;
      track.enableSpeakerphone(targetSpeaker);
    }

    _state = _state.copyWith(isSpeakerOn: targetSpeaker);
    notifyListeners();
  }

  bool _hasSipCredentials() {
    return _state.server.trim().isNotEmpty &&
        _state.login.trim().isNotEmpty &&
        _state.password.isNotEmpty;
  }

  String? _validateSipConfiguration() {
    final server = _state.server.trim();
    if (server.isEmpty) {
      return 'SIP server is empty.';
    }

    final isWsAddress =
        server.startsWith('ws://') || server.startsWith('wss://');

    if (_state.transport == SipTransportUi.ws && !isWsAddress) {
      return 'WS/WSS requires a full WebSocket URL. For classic SIP providers like TTL use UDP or TCP on port 5060 unless they gave you a ws:// or wss:// address.';
    }

    if (_state.transport != SipTransportUi.ws && isWsAddress) {
      return 'This server looks like a WebSocket endpoint. Switch transport to WS/WSS.';
    }

    return null;
  }

  String _normalizeServerInput(String server, SipTransportUi transport) {
    var value = server.trim();

    if (transport == SipTransportUi.ws) {
      if (value.startsWith('http://')) {
        return 'ws://${value.substring('http://'.length)}';
      }
      if (value.startsWith('https://')) {
        return 'wss://${value.substring('https://'.length)}';
      }
      return value;
    }

    value = value.replaceFirst(
      RegExp(r'^(sip:|sips:)', caseSensitive: false),
      '',
    );
    value = value.replaceFirst(
      RegExp(r'^https?://', caseSensitive: false),
      '',
    );
    value = value.replaceFirst(
      RegExp(r'^wss?://', caseSensitive: false),
      '',
    );

    return value.split('/').first;
  }

  Future<T?> _invokeNativeSipMethod<T>(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      return await _nativeSipMethodChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException catch (error) {
      final message =
          'Native SIP bridge is not loaded in this Android build. Stop the app completely and rebuild it. Hot reload/hot restart does not load new native Kotlin code. Details: $error';
      debugPrint('SipService native SIP missing plugin [$method]: $message');
      _state = _state.copyWith(
        registrationStatus: SipRegistrationUiStatus.failed,
        errorMessage: message,
      );
      notifyListeners();
    } on PlatformException catch (error) {
      debugPrint(
        'SipService native SIP method error [$method]: ${error.code} ${error.message}',
      );
    } catch (error) {
      debugPrint('SipService native SIP method error [$method]: $error');
    }
    return null;
  }

  void _handleNativeSipEvent(dynamic event) {
    if (event is! Map) {
      debugPrint('SipService native SIP ignored event: $event');
      return;
    }

    final payload = Map<String, dynamic>.from(event);
    final type = payload['type']?.toString();

    if (type == 'registration') {
      _handleNativeRegistrationEvent(payload);
      return;
    }

    if (type == 'call') {
      _handleNativeCallEvent(payload);
    }
  }

  void _applyNativeSnapshot(
    Map<String, dynamic> snapshot, {
    bool notify = false,
  }) {
    _persistentSipEnabled = snapshot['persistentEnabled'] == true;

    final registrationState =
        snapshot['registrationState']?.toString() ?? 'disconnected';
    final callState = snapshot['callState']?.toString() ?? 'idle';
    final remoteIdentity = snapshot['remoteIdentity']?.toString();
    final message = snapshot['message']?.toString();
    final muted = snapshot['muted'] as bool? ?? false;
    final speakerOn = snapshot['speakerOn'] as bool? ?? false;

    final mappedRegistration = switch (registrationState) {
      'registering' => SipRegistrationUiStatus.registering,
      'registered' => SipRegistrationUiStatus.registered,
      'failed' => SipRegistrationUiStatus.failed,
      _ => SipRegistrationUiStatus.disconnected,
    };

    final mappedCall = switch (callState) {
      'incoming' => SipCallUiStatus.incoming,
      'calling' => SipCallUiStatus.calling,
      'ringing' => SipCallUiStatus.ringing,
      'in_call' => SipCallUiStatus.inCall,
      'ended' => SipCallUiStatus.ended,
      'failed' => SipCallUiStatus.failed,
      _ => SipCallUiStatus.idle,
    };

    if (mappedCall == SipCallUiStatus.inCall) {
      _currentCallStartedAt ??= DateTime.now();
    } else if (mappedCall == SipCallUiStatus.idle ||
        mappedCall == SipCallUiStatus.ended ||
        mappedCall == SipCallUiStatus.failed) {
      _currentCallStartedAt = null;
    }

    if (_persistentSipEnabled &&
        (mappedRegistration == SipRegistrationUiStatus.registered ||
            mappedRegistration == SipRegistrationUiStatus.registering)) {
      _shouldStayConnected = true;
    }

    _state = _state.copyWith(
      registrationStatus: mappedRegistration,
      callStatus: mappedCall,
      errorMessage: message,
      remoteIdentity: remoteIdentity,
      isMuted: muted,
      isSpeakerOn: speakerOn,
      clearRemoteIdentity:
          remoteIdentity == null || remoteIdentity.trim().isEmpty,
    );

    if (notify) {
      notifyListeners();
    }
  }

  void _handleNativeRegistrationEvent(Map<String, dynamic> payload) {
    final nativeState = payload['state']?.toString() ?? 'disconnected';
    final message = payload['message']?.toString();
    debugPrint(
      'SipService native registration event -> state=$nativeState, message=$message',
    );

    switch (nativeState) {
      case 'registering':
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.registering,
          errorMessage: message,
        );
        break;
      case 'registered':
        _persistentSipEnabled = true;
        _shouldStayConnected = true;
        unawaited(_storage.write(key: _enabledKey, value: 'true'));
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.registered,
          clearError: true,
        );
        break;
      case 'failed':
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.failed,
          errorMessage: message ?? 'Native SIP registration failed',
        );
        if (_shouldStayConnected) {
          _scheduleReconnect('native-registration-failed');
        }
        break;
      case 'disconnected':
      default:
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.disconnected,
          callStatus: SipCallUiStatus.idle,
          errorMessage: message,
          clearRemoteIdentity: true,
        );
        if (_shouldStayConnected) {
          _scheduleReconnect('native-disconnected');
        }
        break;
    }

    notifyListeners();
  }

  void _handleNativeCallEvent(Map<String, dynamic> payload) {
    final nativeState = payload['state']?.toString() ?? 'idle';
    final remoteIdentity = payload['remoteIdentity']?.toString();
    final message = payload['message']?.toString();
    final muted = payload['muted'] as bool?;
    final speakerOn = payload['speakerOn'] as bool?;

    debugPrint(
      'SipService native call event -> state=$nativeState, remote=$remoteIdentity, message=$message, muted=$muted, speaker=$speakerOn',
    );

    switch (nativeState) {
      case 'incoming':
        _currentCallDirection = SipCallDirection.incoming;
        _currentCallTarget = remoteIdentity ?? _state.sipId;
        _currentCallStartedAt = null;
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.incoming,
          remoteIdentity: remoteIdentity,
          errorMessage: message,
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: speakerOn ?? _state.isSpeakerOn,
        );
        break;
      case 'calling':
        _currentCallDirection = SipCallDirection.outgoing;
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.calling,
          remoteIdentity: remoteIdentity,
          clearError: true,
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: speakerOn ?? _state.isSpeakerOn,
        );
        break;
      case 'ringing':
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.ringing,
          remoteIdentity: remoteIdentity,
          clearError: true,
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: speakerOn ?? _state.isSpeakerOn,
        );
        break;
      case 'in_call':
        _currentCallStartedAt ??= DateTime.now();
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.inCall,
          remoteIdentity: remoteIdentity,
          clearError: true,
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: speakerOn ?? _state.isSpeakerOn,
        );
        break;
      case 'failed':
        _appendCallLog(SipCallUiStatus.failed);
        _currentInviteUri = null;
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.failed,
          errorMessage: message ?? 'Native SIP call failed',
          clearRemoteIdentity: true,
          isMuted: false,
          isSpeakerOn: false,
        );
        break;
      case 'ended':
        _appendCallLog(SipCallUiStatus.ended);
        _currentInviteUri = null;
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.ended,
          clearRemoteIdentity: true,
          clearError: true,
          isMuted: false,
          isSpeakerOn: false,
        );
        break;
      case 'idle':
      default:
        _state = _state.copyWith(
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: speakerOn ?? _state.isSpeakerOn,
        );
        break;
    }

    notifyListeners();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((result) => result != ConnectivityResult.none);
      _onNetworkAvailabilityChanged(online);
    });

    _connectivity.checkConnectivity().then((results) {
      final online = results.any((result) => result != ConnectivityResult.none);
      _onNetworkAvailabilityChanged(online);
    }).catchError((_) {});
  }

  void _onNetworkAvailabilityChanged(bool online) {
    _networkAvailable = online;
    if (!online) {
      if (_state.registrationStatus == SipRegistrationUiStatus.registered) {
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.failed,
          errorMessage: 'Network lost. Waiting for reconnection...',
        );
        notifyListeners();
      }
      return;
    }

    if (_shouldStayConnected) {
      _scheduleReconnect('network-restored', delay: const Duration(seconds: 1));
    }
  }

  void _startRegistrationWatchdog() {
    _registrationWatchdogTimer?.cancel();
    _registrationWatchdogTimer =
        Timer.periodic(const Duration(seconds: 20), (_) {
      _checkAndRecoverRegistration('watchdog');
    });
  }

  void _checkAndRecoverRegistration(String reason) {
    if (!_shouldStayConnected || !_networkAvailable) return;

    if (_shouldUseNativeSip()) {
      if (_state.registrationStatus == SipRegistrationUiStatus.registered ||
          _state.registrationStatus == SipRegistrationUiStatus.registering) {
        return;
      }

      _scheduleReconnect(reason);
      return;
    }

    if (_state.registrationStatus == SipRegistrationUiStatus.registered) {
      if (!_helper.connected) {
        _scheduleReconnect('$reason-not-connected');
      }
      return;
    }

    if (_helper.connecting) return;
    _scheduleReconnect(reason);
  }

  void _scheduleReconnect(String reason,
      {Duration delay = const Duration(seconds: 2)}) {
    if (!_shouldStayConnected || !_networkAvailable) return;

    final lastAttempt = _lastReconnectAttemptAt;
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < const Duration(seconds: 3)) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_reconnectInProgress || !_shouldStayConnected || !_networkAvailable) {
        return;
      }

      _reconnectInProgress = true;
      try {
        await _startSipRegistration(clearError: false);
      } catch (_) {
        _setError('Reconnect failed ($reason).');
      } finally {
        _reconnectInProgress = false;
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectInProgress = false;
  }

  void _startKeepAlive() {
    if (_shouldUseNativeSip()) {
      return;
    }

    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!_shouldStayConnected ||
          !_networkAvailable ||
          !_helper.connected ||
          !_helper.registered ||
          _activeCall != null) {
        return;
      }

      final domain = _extractDomain(_state.server);
      final target = _buildSipUri(_state.login, domain);
      try {
        debugPrint('SipService: keepAlive OPTIONS -> $target');
        _helper.sendOptions(target, '', null);
      } catch (_) {}
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  Future<bool> _ensureMediaPermissions({required bool includeCamera}) async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      return false;
    }
    if (!includeCamera) {
      return true;
    }

    final camStatus = await Permission.camera.request();
    return camStatus.isGranted;
  }

  String _toWebSocketUrl(String server, int port) {
    final value = server.trim();
    if (value.startsWith('http://')) {
      return 'ws://${value.substring('http://'.length)}';
    }
    if (value.startsWith('https://')) {
      return 'wss://${value.substring('https://'.length)}';
    }
    if (value.startsWith('ws://') || value.startsWith('wss://')) {
      return value;
    }
    final slashIndex = value.indexOf('/');
    final hostPart = slashIndex == -1 ? value : value.substring(0, slashIndex);
    final pathPart = slashIndex == -1 ? '' : value.substring(slashIndex);
    if (hostPart.contains(':')) {
      return 'wss://$value';
    }
    return 'wss://$hostPart:$port$pathPart';
  }

  String _extractDomain(String server) {
    final sanitized = server
        .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^wss?://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^(sip:|sips:)', caseSensitive: false), '');

    final normalized = sanitized.trim().startsWith('ws://') ||
            sanitized.trim().startsWith('wss://')
        ? sanitized.trim()
        : 'wss://${sanitized.trim()}';

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host;
    }

    final cleaned = sanitized.split('/').first;
    return cleaned.split(':').first;
  }

  String _extractAuthUser(String login) {
    final value = login.trim();
    if (value.contains('@')) {
      return value.split('@').first;
    }
    return value;
  }

  String _buildSipUri(String login, String domain) {
    final value = login.trim();
    if (value.startsWith('sip:')) {
      return value;
    }
    if (value.contains('@')) {
      return 'sip:$value';
    }
    return 'sip:$value@$domain';
  }

  String _buildTargetUri(String sipId, String domain) {
    final value = sipId.trim();
    if (value.startsWith('sip:')) {
      return value;
    }
    if (value.contains('@')) {
      return 'sip:$value';
    }
    return 'sip:$value@$domain';
  }

  void _releaseStreams() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());

    _localStream?.dispose();
    _remoteStream?.dispose();

    _localStream = null;
    _remoteStream = null;
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
  }

  void _setError(String message) {
    debugPrint('SipService ERROR: $message');
    _state = _state.copyWith(
      errorMessage: message,
      registrationStatus: _state.registrationStatus,
      callStatus: _state.callStatus,
    );
    notifyListeners();
  }

  void _logSipConfig(String stage, {Map<String, String>? extra}) {
    final domain = _extractDomain(_state.server);
    final transport = switch (_state.transport) {
      SipTransportUi.ws => 'WS/WSS',
      SipTransportUi.tcp => 'TCP',
      SipTransportUi.udp => 'UDP',
    };
    final entries = <String, String>{
      'server': _state.server,
      'domain': domain,
      'login': _state.login,
      'transport': transport,
      'port': _state.port.toString(),
      if (extra != null) ...extra,
    };

    final details =
        entries.entries.map((item) => '${item.key}=${item.value}').join(', ');
    debugPrint('SipService [$stage]: $details');
  }

  String _timeoutDiagnosticMessage() {
    final target = _currentInviteUri ?? _currentCallTarget ?? _state.sipId;
    final transport = switch (_state.transport) {
      SipTransportUi.ws => 'WS/WSS',
      SipTransportUi.tcp => 'TCP',
      SipTransportUi.udp => 'UDP',
    };

    return 'Call timeout for $target over $transport. REGISTER succeeded, but INVITE got no SIP response. If Zoiper works with the same account, this usually means the provider accepts classic SIP/RTP, while this app is sending WebRTC-style SDP (ICE/DTLS/SAVPF), or the INVITE is being lost over UDP.';
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    if (_shouldUseNativeSip()) return;
    debugPrint(
      'SipService: registrationStateChanged -> state=${state.state}, cause=${state.cause}',
    );
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.registered,
          clearError: true,
        );
        _startKeepAlive();
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.failed,
          errorMessage: state.cause?.toString() ?? 'Registration failed',
        );
        _stopKeepAlive();
        if (_shouldStayConnected) {
          _scheduleReconnect('registration-failed');
        }
        break;
      case RegistrationStateEnum.UNREGISTERED:
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.disconnected,
          callStatus: SipCallUiStatus.idle,
          clearRemoteIdentity: true,
        );
        _stopKeepAlive();
        if (_shouldStayConnected) {
          _scheduleReconnect('unregistered');
        }
        break;
      case RegistrationStateEnum.NONE:
      case null:
        break;
    }

    notifyListeners();
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    if (_shouldUseNativeSip()) return;
    debugPrint(
      'SipService: callStateChanged -> state=${callState.state}, direction=${call.direction}, remote=${call.remote_identity}, cause=${callState.cause}',
    );
    _activeCall = call;

    if (callState.state == CallStateEnum.STREAM) {
      final stream = callState.stream;
      if (stream != null && callState.originator == 'local') {
        _localStream = stream;
        localRenderer.srcObject = stream;
      }
      if (stream != null && callState.originator == 'remote') {
        _remoteStream = stream;
        remoteRenderer.srcObject = stream;
      }
    }

    switch (callState.state) {
      case CallStateEnum.CALL_INITIATION:
        _currentCallDirection = call.direction == 'INCOMING'
            ? SipCallDirection.incoming
            : SipCallDirection.outgoing;
        _currentCallTarget = call.remote_identity ?? _state.sipId;
        _state = _state.copyWith(
          callStatus: call.direction == 'INCOMING'
              ? SipCallUiStatus.incoming
              : SipCallUiStatus.calling,
          remoteIdentity: call.remote_identity,
          clearError: true,
        );
        break;
      case CallStateEnum.CONNECTING:
      case CallStateEnum.PROGRESS:
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.ringing,
          remoteIdentity: call.remote_identity,
        );
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
      case CallStateEnum.STREAM:
        _currentCallStartedAt ??= DateTime.now();
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.inCall,
          remoteIdentity: call.remote_identity,
          clearError: true,
        );
        break;
      case CallStateEnum.MUTED:
        _state = _state.copyWith(isMuted: true);
        break;
      case CallStateEnum.UNMUTED:
        _state = _state.copyWith(isMuted: false);
        break;
      case CallStateEnum.ENDED:
        _releaseStreams();
        _appendCallLog(SipCallUiStatus.ended);
        _activeCall = null;
        _currentInviteUri = null;
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.ended,
          clearRemoteIdentity: true,
          isMuted: false,
          isSpeakerOn: false,
        );
        break;
      case CallStateEnum.FAILED:
        _releaseStreams();
        _appendCallLog(SipCallUiStatus.failed);
        _activeCall = null;
        final rawError = callState.cause?.toString() ?? 'Call failed';
        final errorMessage = rawError.contains('408')
            ? '${_timeoutDiagnosticMessage()} Cause: $rawError'
            : rawError;
        if (rawError.contains('408')) {
          debugPrint('SipService DIAGNOSTIC: ${_timeoutDiagnosticMessage()}');
        }
        _currentInviteUri = null;
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.failed,
          errorMessage: errorMessage,
          clearRemoteIdentity: true,
          isMuted: false,
          isSpeakerOn: false,
        );
        break;
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
      case CallStateEnum.REFER:
      case CallStateEnum.NONE:
        break;
    }

    notifyListeners();
  }

  @override
  void transportStateChanged(TransportState state) {
    if (_shouldUseNativeSip()) return;
    debugPrint(
      'SipService: transportStateChanged -> state=${state.state}, cause=${state.cause}',
    );
    switch (state.state) {
      case TransportStateEnum.CONNECTED:
        if (_shouldStayConnected &&
            _state.registrationStatus != SipRegistrationUiStatus.registered) {
          _helper.register();
        }
        break;
      case TransportStateEnum.DISCONNECTED:
        _stopKeepAlive();
        if (_shouldStayConnected) {
          _scheduleReconnect('transport-disconnected');
        }
        break;
      case TransportStateEnum.CONNECTING:
      case TransportStateEnum.NONE:
        break;
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _helper.removeSipUaHelperListener(this);
    _helper.stop();
    _cancelReconnect();
    _stopKeepAlive();
    _registrationWatchdogTimer?.cancel();
    _connectivitySubscription?.cancel();
    _nativeSipEventsSubscription?.cancel();
    _releaseStreams();

    localRenderer.dispose();
    remoteRenderer.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldStayConnected) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncNativeSnapshot());
      _checkAndRecoverRegistration('app-resumed');
    }
  }

  void _appendCallLog(SipCallUiStatus result) {
    final now = DateTime.now();
    final startedAt = _currentCallStartedAt;
    final duration = startedAt != null ? now.difference(startedAt) : null;
    final target = (_currentCallTarget ?? _state.remoteIdentity ?? _state.sipId)
            .trim()
            .isEmpty
        ? 'Unknown'
        : (_currentCallTarget ?? _state.remoteIdentity ?? _state.sipId).trim();

    final updated = <SipCallLogEntry>[
      SipCallLogEntry(
        target: target,
        direction: _currentCallDirection,
        result: result,
        timestamp: now,
        duration: duration,
      ),
      ..._state.callLogs,
    ];

    _state = _state.copyWith(callLogs: updated);
    _currentCallStartedAt = null;
    _currentCallTarget = null;
  }
}
