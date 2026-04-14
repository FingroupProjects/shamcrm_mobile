import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';

import 'sip_state.dart';

class SipService extends ChangeNotifier
    with WidgetsBindingObserver
    implements SipUaHelperListener {
  SipService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _serverKey = 'sip_server';
  static const String _loginKey = 'sip_login';
  static const String _passwordKey = 'sip_password';
  static const String _sipIdKey = 'sip_target_sip_id';
  static const String _transportKey = 'sip_transport';
  static const String _portKey = 'sip_port';

  final SIPUAHelper _helper = SIPUAHelper();
  final Connectivity _connectivity = Connectivity();

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  SipUiState _state = SipUiState.initial();
  SipUiState get state => _state;

  bool _initialized = false;
  bool _renderersReady = false;
  bool get renderersReady => _renderersReady;
  bool _shouldStayConnected = false;
  bool _networkAvailable = true;
  bool _reconnectInProgress = false;
  DateTime? _lastReconnectAttemptAt;
  Timer? _reconnectTimer;
  Timer? _registrationWatchdogTimer;
  Timer? _keepAliveTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Call? _activeCall;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  SipCallDirection _currentCallDirection = SipCallDirection.outgoing;
  DateTime? _currentCallStartedAt;
  String? _currentCallTarget;

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
    final transportRaw = await _storage.read(key: _transportKey) ?? 'ws';
    final portRaw = await _storage.read(key: _portKey) ?? '7443';
    final parsedPort = int.tryParse(portRaw) ?? 7443;
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
    _startConnectivityMonitoring();
    _startRegistrationWatchdog();
    notifyListeners();
  }

  Future<void> saveDraft({
    required String server,
    required String login,
    required String password,
    required String sipId,
    required SipTransportUi transport,
    required int port,
  }) async {
    _state = _state.copyWith(
      server: server.trim(),
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

  Future<void> connect() async {
    if (!_hasSipCredentials()) {
      _setError('SIP config is incomplete. Fill server, login and password.');
      return;
    }

    if (!_networkAvailable) {
      _setError('No internet connection. SIP registration paused.');
      return;
    }

    _shouldStayConnected = true;
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

    final settings = UaSettings();
    if (_state.transport == SipTransportUi.ws) {
      settings.webSocketUrl = _toWebSocketUrl(_state.server, _state.port);
      settings.webSocketSettings.allowBadCertificate = true;
      settings.transportType = TransportType.WS;
    } else if (_state.transport == SipTransportUi.tcp) {
      settings.host = domain;
      settings.port = _state.port.toString();
      settings.transportType = TransportType.TCP;
      settings.registrarServer = 'sip:$domain:${_state.port}';
    } else {
      settings.host = domain;
      settings.port = _state.port.toString();
      settings.transportType = TransportType.UDP;
      settings.registrarServer = 'sip:$domain:${_state.port}';
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

    _lastReconnectAttemptAt = DateTime.now();
    await _helper.start(settings);
  }

  Future<void> disconnect() async {
    _shouldStayConnected = false;
    _cancelReconnect();
    _stopKeepAlive();

    try {
      _activeCall?.hangup(<String, dynamic>{'status_code': 603});
    } catch (_) {}

    _activeCall = null;
    if (_helper.registered) {
      _helper.unregister(true);
    }
    _helper.stop();
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
    final success = await _helper.call(target, voiceOnly: false);

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
    final call = _activeCall;
    if (call == null) return;

    final granted = await _ensureMediaPermissions();
    if (!granted) {
      _setError('Camera and microphone permissions are required.');
      return;
    }

    final remoteHasVideo = call.remote_has_video;

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': remoteHasVideo
          ? <String, dynamic>{
              'mandatory': <String, dynamic>{
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': <dynamic>[],
            }
          : false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    call.answer(_helper.buildCallOptions(!remoteHasVideo), mediaStream: stream);

    _state = _state.copyWith(
      callStatus: SipCallUiStatus.inCall,
      clearError: true,
    );
    notifyListeners();
  }

  void hangup() {
    if (_activeCall == null) return;
    _activeCall!.hangup(<String, dynamic>{'status_code': 603});
  }

  void decline() {
    if (_activeCall == null) return;
    _activeCall!.hangup(<String, dynamic>{'status_code': 486});
  }

  void toggleMute() {
    if (_activeCall == null) return;

    final targetMuted = !_state.isMuted;
    if (targetMuted) {
      _activeCall!.mute(true, false);
    } else {
      _activeCall!.unmute(true, false);
    }

    _state = _state.copyWith(isMuted: targetMuted);
    notifyListeners();
  }

  void toggleSpeaker() {
    final track = _localStream?.getAudioTracks().isNotEmpty == true
        ? _localStream!.getAudioTracks().first
        : null;

    if (track == null) return;

    final targetSpeaker = !_state.isSpeakerOn;
    track.enableSpeakerphone(targetSpeaker);

    _state = _state.copyWith(isSpeakerOn: targetSpeaker);
    notifyListeners();
  }

  bool _hasSipCredentials() {
    return _state.server.trim().isNotEmpty &&
        _state.login.trim().isNotEmpty &&
        _state.password.isNotEmpty;
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
      final target = 'sip:$domain';
      try {
        _helper.sendOptions(target, '', null);
      } catch (_) {}
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  Future<bool> _ensureMediaPermissions() async {
    final micStatus = await Permission.microphone.request();
    final camStatus = await Permission.camera.request();
    return micStatus.isGranted && camStatus.isGranted;
  }

  String _toWebSocketUrl(String server, int port) {
    final value = server.trim();
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
    final normalized =
        server.trim().startsWith('ws://') || server.trim().startsWith('wss://')
            ? server.trim()
            : 'wss://${server.trim()}';

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host;
    }

    final cleaned = server.replaceAll(RegExp(r'^wss?://'), '').split('/').first;
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
    _state = _state.copyWith(
      errorMessage: message,
      registrationStatus: _state.registrationStatus,
      callStatus: _state.callStatus,
    );
    notifyListeners();
  }

  @override
  void registrationStateChanged(RegistrationState state) {
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
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.failed,
          errorMessage: callState.cause?.toString() ?? 'Call failed',
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
    _releaseStreams();

    localRenderer.dispose();
    remoteRenderer.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldStayConnected) return;
    if (state == AppLifecycleState.resumed) {
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
