import 'dart:io' show Platform;
import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sip_ua/sip_ua.dart';

import 'sip_state.dart';

class SipAudioRoute {
  const SipAudioRoute({
    required this.id,
    required this.type,
    required this.name,
    required this.selected,
  });

  final String id;
  final String type;
  final String name;
  final bool selected;

  factory SipAudioRoute.fromMap(Map<dynamic, dynamic> map) {
    return SipAudioRoute(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'other',
      name: map['name']?.toString() ?? 'Аудиоустройство',
      selected: map['selected'] == true,
    );
  }
}

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
  static const String _voipPushTokenKey = 'sip_ios_voip_push_token';
  static const String _pendingIncomingCallPushPayloadKey =
      'sip_pending_incoming_call_push_payload_v1';
  static const String _backgroundReliabilityPromptedKey =
      'sip_background_reliability_prompted_v2';
  static const String _fullScreenIncomingCallPromptedKey =
      'sip_full_screen_incoming_call_prompted_v1';
  static const String _xiaomiAutoStartPromptedKey =
      'sip_xiaomi_autostart_prompted_v1';
  static const List<String> _sipSecureStorageKeys = <String>[
    _serverKey,
    _loginKey,
    _passwordKey,
    _sipIdKey,
    _transportKey,
    _portKey,
    _enabledKey,
    _voipPushTokenKey,
  ];
  static const MethodChannel _nativeSipMethodChannel =
      MethodChannel('com.shamcrm/native_sip/methods');
  static const EventChannel _nativeSipEventChannel =
      EventChannel('com.shamcrm/native_sip/events');
  static const Duration _secureStorageReadTimeout = Duration(seconds: 3);
  static const Duration _nativeStartupStepTimeout = Duration(seconds: 4);
  static const Duration _iosVoipTokenSyncTimeout = Duration(seconds: 8);

  final SIPUAHelper _helper = SIPUAHelper();
  final Connectivity _connectivity = Connectivity();
  final ApiService _apiService = ApiService();

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  SipUiState _state = SipUiState.initial();
  SipUiState get state => _state;
  int _callUiOpenRequestSerial = 0;
  int get callUiOpenRequestSerial => _callUiOpenRequestSerial;
  int _lastNativeCallUiRequestId = 0;

  bool _initialized = false;
  bool _disposed = false;
  bool _notifyPostFrameScheduled = false;
  bool _configLoaded = false;
  Completer<void>? _initializationCompleter;
  bool _renderersReady = false;
  bool get renderersReady => _renderersReady;
  bool get isConfigLoaded => _configLoaded;
  int _sipScreenVisibilityCount = 0;
  bool get isSipScreenVisible => _sipScreenVisibilityCount > 0;
  bool _sipScreenOpenClaimed = false;
  bool get isSipScreenOpenClaimed => _sipScreenOpenClaimed;
  bool _forcePinPrompt = false;
  bool get isPinPromptForced => _forcePinPrompt;
  bool _shouldStayConnected = false;
  bool _persistentSipEnabled = false;
  bool _networkAvailable = true;
  bool _reconnectInProgress = false;
  bool _sipEnabled = false;
  bool _hardTransportFailure = false;
  String? _hardTransportFailureEndpoint;
  DateTime? _lastReconnectAttemptAt;
  Timer? _reconnectTimer;
  Timer? _registrationWatchdogTimer;
  Timer? _keepAliveTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<dynamic>? _nativeSipEventsSubscription;
  bool _nativeSipBridgeAvailable = false;
  Future<void>? _nativeSipBridgeInitializationFuture;
  Future<void>? _prepareRuntimePermissionsFuture;
  String? _lastSyncedIosVoipPushToken;
  Future<void>? _recentCallLogsRequest;
  DateTime? _recentCallLogsFetchedAt;
  int _recentCallLogsRequestToken = 0;

  Call? _activeCall;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  SipCallDirection _currentCallDirection = SipCallDirection.outgoing;
  DateTime? _currentCallStartedAt;
  DateTime? get currentCallStartedAt => _currentCallStartedAt;

  Duration get currentCallDuration {
    final startedAt = _currentCallStartedAt;
    if (startedAt == null) return Duration.zero;
    final duration = DateTime.now().difference(startedAt);
    return duration.isNegative ? Duration.zero : duration;
  }

  bool _speakerToggleInProgress = false;
  bool _audioRouteChangeInProgress = false;
  String? _currentAudioRouteType;
  String? _currentAudioRouteName;
  String? get currentAudioRouteType => _currentAudioRouteType;
  String? get currentAudioRouteName => _currentAudioRouteName;
  String? _currentCallTarget;
  String? _currentCallDisplayName;
  String? get currentCallTarget => _currentCallTarget;
  String? get currentCallDisplayName => _currentCallDisplayName;
  String? _currentInviteUri;
  final List<Map<String, dynamic>> _pendingIosCallActions =
      <Map<String, dynamic>>[];
  String? _iosSystemCallUUID;
  bool _iosSystemCallConnectedReported = false;
  String? _activeIncomingCallUUID;
  String? _activeIncomingCallId;
  String? _activeIncomingRemoteIdentity;
  String? _activeNativeCallUUID;
  String? _activeNativeCallId;
  String? _activeNativeRemoteIdentity;
  String? _lastTerminalNativeCallUUID;
  String? _lastTerminalNativeCallId;
  String? _lastTerminalNativeRemoteIdentity;
  DateTime? _lastTerminalNativeCallAt;
  bool _secureStorageRecoveryTriggered = false;
  String? _pendingStorageRecoveryMessage;
  String? _lastIncomingCallPushId;
  DateTime? _lastIncomingCallPushAt;
  final Set<String> _sentSipReadyKeys = <String>{};

  Future<void> initialize() async {
    if (_disposed) return;
    if (_configLoaded) return;
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    final completer = Completer<void>();
    _initializationCompleter = completer;

    try {
      if (!_initialized) {
        _initialized = true;
        _helper.addSipUaHelperListener(this);
        WidgetsBinding.instance.addObserver(this);
      }

      await _runStartupStep(
        'native_bridge',
        _ensureNativeSipBridgeInitialized().then((_) {}),
      );

      var server = await _readSecureStorageValue(
            _serverKey,
            fallback: '',
          ) ??
          '';
      var login = await _readSecureStorageValue(
            _loginKey,
            fallback: '',
          ) ??
          '';
      var password = await _readSecureStorageValue(
            _passwordKey,
            fallback: '',
          ) ??
          '';
      final sipId = await _readSecureStorageValue(
            _sipIdKey,
            fallback: '',
          ) ??
          '';
      var transportRaw = await _readSecureStorageValue(
            _transportKey,
            fallback: 'udp',
          ) ??
          'udp';
      var portRaw = await _readSecureStorageValue(
            _portKey,
            fallback: '5060',
          ) ??
          '5060';
      var enabledRaw = await _readSecureStorageValue(
            _enabledKey,
            fallback: 'false',
          ) ??
          'false';

      if (Platform.isAndroid) {
        final nativeConfig =
            await _invokeNativeSipMethod<Map<dynamic, dynamic>>(
                'getStoredConfig');
        if (nativeConfig != null) {
          final nativeServer = nativeConfig['server']?.toString().trim() ?? '';
          final nativeLogin = nativeConfig['login']?.toString().trim() ?? '';
          final nativePassword = nativeConfig['password']?.toString() ?? '';
          if (nativeServer.isNotEmpty &&
              nativeLogin.isNotEmpty &&
              nativePassword.isNotEmpty) {
            server = nativeServer;
            login = nativeLogin;
            password = nativePassword;
          }
          portRaw = nativeConfig['port']?.toString() ?? portRaw;
          transportRaw = nativeConfig['transport']?.toString() ?? transportRaw;
          enabledRaw = nativeConfig['enabled'] == true ? 'true' : 'false';
          await _mirrorNativeConfigToFlutterStorage(
            server: server,
            login: login,
            password: password,
            port: portRaw,
            transport: transportRaw,
            enabled: enabledRaw,
          );
        }
      }
      final parsedPort = int.tryParse(portRaw) ?? 5060;
      final hasStoredCredentials = server.trim().isNotEmpty &&
          login.trim().isNotEmpty &&
          password.isNotEmpty;
      _sipEnabled = enabledRaw == 'true' && hasStoredCredentials;
      _persistentSipEnabled = _sipEnabled;
      if (enabledRaw == 'true' && !hasStoredCredentials) {
        unawaited(_storage.write(key: _enabledKey, value: 'false'));
      }
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
        errorMessage: _pendingStorageRecoveryMessage,
        clearError: _pendingStorageRecoveryMessage == null,
        clearRemoteIdentity: true,
      );
      _pendingStorageRecoveryMessage = null;
      await _runStartupStep(
        'renderers',
        _ensureRenderersInitializedForCurrentMode(),
      );
      if (_nativeSipBridgeAvailable) {
        await _runStartupStep(
          'native_snapshot',
          _syncNativeSnapshot(),
        );
        await _runStartupStep(
          'pending_ios_call_actions',
          _consumePendingIosCallActions(),
        );
      } else if (_isNativeSipPlatform()) {
        debugPrint(
          'SipService.initialize native snapshot skipped: bridge unavailable',
        );
      }
      _startConnectivityMonitoring();
      _startRegistrationWatchdog();
      _configLoaded = true;
      unawaited(refreshRecentCallLogs(force: true));
      unawaited(_restorePersistentConnection());
      unawaited(recoverPendingIncomingCallPush());
      _notifyListenersSafely();
      completer.complete();
    } catch (error, stackTrace) {
      debugPrint('SipService.initialize failed: $error');
      debugPrint('SipService.initialize stackTrace: $stackTrace');
      _initialized = false;
      _configLoaded = true;
      _state = SipUiState.initial().copyWith(
        errorMessage:
            'Не удалось открыть сохраненные настройки телефонии. Проверьте данные и попробуйте снова.',
      );
      _notifyListenersSafely();
      if (!completer.isCompleted) {
        completer.complete();
      }
    } finally {
      _initializationCompleter = null;
    }
  }

  Future<String?> _readSecureStorageValue(
    String key, {
    String? fallback,
  }) async {
    try {
      return await _storage.read(key: key).timeout(
            _secureStorageReadTimeout,
            onTimeout: () {
              debugPrint(
                'SipService secure storage read timed out for $key',
              );
              return fallback;
            },
          ) ??
          fallback;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('SipService secure storage read failed for $key: $error');
      debugPrint('SipService secure storage read stackTrace: $stackTrace');
      if (_isSecureStorageDecryptError(error)) {
        await _resetCorruptedSipStorage();
      }
      return fallback;
    } catch (error, stackTrace) {
      debugPrint('SipService secure storage read failed for $key: $error');
      debugPrint('SipService secure storage read stackTrace: $stackTrace');
      return fallback;
    }
  }

  Future<void> _runStartupStep(
    String name,
    Future<void> future, {
    Duration timeout = _nativeStartupStepTimeout,
  }) async {
    try {
      await future.timeout(timeout);
    } on TimeoutException {
      debugPrint(
        'SipService.initialize startup step timed out [$name] after ${timeout.inSeconds}s',
      );
    } catch (error, stackTrace) {
      debugPrint('SipService.initialize startup step failed [$name]: $error');
      debugPrint(
        'SipService.initialize startup step stackTrace [$name]: $stackTrace',
      );
    }
  }

  Future<void> _mirrorNativeConfigToFlutterStorage({
    required String server,
    required String login,
    required String password,
    required String port,
    required String transport,
    required String enabled,
  }) async {
    final values = <String, String>{
      _serverKey: server,
      _loginKey: login,
      _passwordKey: password,
      _portKey: port,
      _transportKey: transport,
      _enabledKey: enabled,
    };
    for (final entry in values.entries) {
      try {
        await _storage.write(key: entry.key, value: entry.value);
      } catch (error) {
        debugPrint(
          'SipService native config mirror failed for ${entry.key}: $error',
        );
      }
    }
  }

  bool _isSecureStorageDecryptError(PlatformException error) {
    final message =
        '${error.code} ${error.message} ${error.details}'.toUpperCase();
    return message.contains('BAD_DECRYPT') ||
        message.contains('BAD PADDING') ||
        message.contains('BADPADDINGEXCEPTION');
  }

  Future<void> _resetCorruptedSipStorage() async {
    if (_secureStorageRecoveryTriggered) {
      return;
    }
    _secureStorageRecoveryTriggered = true;
    _pendingStorageRecoveryMessage =
        'Сохраненные настройки телефонии были повреждены и сброшены. Введите их заново.';

    for (final key in _sipSecureStorageKeys) {
      try {
        await _storage.delete(key: key);
      } catch (error) {
        debugPrint('SipService secure storage delete failed for $key: $error');
      }
    }
  }

  Future<void> ensureRenderersInitialized() async {
    await _ensureRenderersInitialized(force: true);
  }

  bool _shouldUseNativeSip() {
    final supportsNativeTransport = _state.transport == SipTransportUi.udp ||
        _state.transport == SipTransportUi.tcp;
    return supportsNativeTransport && (Platform.isAndroid || Platform.isIOS);
  }

  bool _isNativeSipPlatform() {
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<bool> _ensureNativeSipBridgeInitialized() async {
    if (!_isNativeSipPlatform()) {
      return false;
    }

    if (_nativeSipBridgeAvailable) {
      return true;
    }

    final inFlight = _nativeSipBridgeInitializationFuture;
    if (inFlight != null) {
      await inFlight;
      return _nativeSipBridgeAvailable;
    }

    final future = _initializeNativeSipBridge();
    _nativeSipBridgeInitializationFuture = future;

    try {
      await future;
    } finally {
      if (identical(_nativeSipBridgeInitializationFuture, future)) {
        _nativeSipBridgeInitializationFuture = null;
      }
    }

    return _nativeSipBridgeAvailable;
  }

  Future<void> _ensureRenderersInitializedForCurrentMode() async {
    if (_shouldUseNativeSip()) {
      return;
    }
    await _ensureRenderersInitialized();
  }

  Future<void> _ensureRenderersInitialized({bool force = false}) async {
    if (_renderersReady) {
      return;
    }
    if (!force && _shouldUseNativeSip()) {
      return;
    }

    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _renderersReady = true;
    } catch (error, stackTrace) {
      debugPrint('SipService: renderer initialize skipped: $error');
      debugPrint('SipService: renderer initialize stackTrace: $stackTrace');
    }
  }

  void setSipScreenVisible(bool visible) {
    final wasVisible = isSipScreenVisible;
    if (visible) {
      _sipScreenVisibilityCount += 1;
      _sipScreenOpenClaimed = true;
    } else if (_sipScreenVisibilityCount > 0) {
      _sipScreenVisibilityCount -= 1;
    }
    final nowVisible = isSipScreenVisible;
    if (!nowVisible) {
      _sipScreenOpenClaimed = false;
    }
    if (wasVisible == nowVisible) return;
    if (visible) {
      unawaited(refreshRecentCallLogs());
    }
    _notifyListenersSafely();
  }

  bool claimSipScreenOpen() {
    if (isSipScreenVisible || _sipScreenOpenClaimed) {
      return false;
    }
    _sipScreenOpenClaimed = true;
    return true;
  }

  void releaseSipScreenOpenClaim() {
    if (isSipScreenVisible) return;
    _sipScreenOpenClaimed = false;
  }

  void forcePinPrompt() {
    _forcePinPrompt = true;
  }

  void clearForcedPinPrompt() {
    _forcePinPrompt = false;
  }

  Future<void> refreshRecentCallLogs({
    CallType? callType,
    String? searchQuery,
    bool force = false,
  }) async {
    final normalizedSearchQuery = searchQuery?.trim() ?? '';
    final fetchedAt = _recentCallLogsFetchedAt;
    if (!force &&
        callType == _state.serverCallFilter &&
        normalizedSearchQuery == _state.serverCallSearchQuery &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < const Duration(seconds: 30)) {
      return;
    }

    final inFlight = _recentCallLogsRequest;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final request = _loadRecentCallLogs(
      page: 1,
      callType: callType,
      searchQuery: normalizedSearchQuery,
      append: false,
    );
    _recentCallLogsRequest = request;
    try {
      await request;
    } finally {
      if (identical(_recentCallLogsRequest, request)) {
        _recentCallLogsRequest = null;
      }
    }
  }

  Future<void> loadMoreRecentCallLogs() async {
    if (_state.isServerCallLogsLoading ||
        _state.isServerCallLogsLoadingMore ||
        _state.allServerCallLogsFetched) {
      return;
    }

    await _loadRecentCallLogs(
      page: _state.serverCallLogsCurrentPage + 1,
      callType: _state.serverCallFilter,
      searchQuery: _state.serverCallSearchQuery,
      append: true,
    );
  }

  Future<void> _loadRecentCallLogs({
    required int page,
    required CallType? callType,
    required String searchQuery,
    required bool append,
  }) async {
    final requestToken = ++_recentCallLogsRequestToken;
    _state = _state.copyWith(
      isServerCallLogsLoading: !append,
      isServerCallLogsLoadingMore: append,
      serverCallFilter: callType,
      serverCallSearchQuery: searchQuery,
      serverCallLogs: append ? null : <SipCallLogEntry>[],
      serverCallLogsCurrentPage: append ? null : 1,
      serverCallLogsTotalPages: append ? null : 1,
      allServerCallLogsFetched: append ? null : false,
    );
    _notifyListenersSafely();

    try {
      final response = await _fetchCallLogsPage(
        page: page,
        perPage: 20,
        callType: callType,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
      );
      if (requestToken != _recentCallLogsRequestToken) {
        return;
      }

      final calls = (response['calls'] as List<CallLogEntry>)
          .map(SipCallLogEntry.fromServerCall)
          .toList();
      final pagination = response['pagination'] as Map<String, dynamic>;
      final currentPage = pagination['current_page'] as int? ?? page;
      final totalPages = pagination['total_pages'] as int? ?? currentPage;
      final existing =
          append ? _state.serverCallLogs : const <SipCallLogEntry>[];
      final merged = append
          ? <SipCallLogEntry>[
              ...existing,
              ...calls.where(
                (item) => existing
                    .every((existingItem) => existingItem.id != item.id),
              ),
            ]
          : calls;

      _state = _state.copyWith(
        serverCallLogs: merged,
        isServerCallLogsLoading: false,
        isServerCallLogsLoadingMore: false,
        serverCallFilter: callType,
        serverCallSearchQuery: searchQuery,
        serverCallLogsCurrentPage: currentPage,
        serverCallLogsTotalPages: totalPages,
        allServerCallLogsFetched: merged.isEmpty || currentPage >= totalPages,
      );
      _recentCallLogsFetchedAt = DateTime.now();
    } catch (_) {
      if (requestToken != _recentCallLogsRequestToken) {
        return;
      }
      _state = _state.copyWith(
        isServerCallLogsLoading: false,
        isServerCallLogsLoadingMore: false,
      );
    }

    _notifyListenersSafely();
  }

  Future<Map<String, dynamic>> _fetchCallLogsPage({
    required int page,
    required int perPage,
    required CallType? callType,
    String? searchQuery,
  }) {
    switch (callType) {
      case CallType.incoming:
        return _apiService.getIncomingCalls(
          page: page,
          perPage: perPage,
          searchQuery: searchQuery,
        );
      case CallType.outgoing:
        return _apiService.getOutgoingCalls(
          page: page,
          perPage: perPage,
          searchQuery: searchQuery,
        );
      case CallType.missed:
        return _apiService.getMissedCalls(
          page: page,
          perPage: perPage,
          searchQuery: searchQuery,
        );
      case null:
        return _apiService.getAllCalls(
          page: page,
          perPage: perPage,
          searchQuery: searchQuery,
        );
      case CallType.outgoingMissed:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  void clearTransientError([String? expectedMessage]) {
    final currentMessage = _state.errorMessage?.trim();
    if (currentMessage == null || currentMessage.isEmpty) {
      return;
    }

    if (expectedMessage != null &&
        expectedMessage.trim().isNotEmpty &&
        currentMessage != expectedMessage.trim()) {
      return;
    }

    _state = _state.copyWith(clearError: true);
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    if (_disposed) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      if (_notifyPostFrameScheduled) return;
      _notifyPostFrameScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notifyPostFrameScheduled = false;
        if (!_disposed) {
          notifyListeners();
        }
      });
      return;
    }

    notifyListeners();
  }

  Future<void> _restorePersistentConnection() async {
    if (!_persistentSipEnabled || !_hasSipCredentials() || !_networkAvailable) {
      return;
    }
    if (_isActiveUiCallStatus(_state.callStatus)) {
      _shouldStayConnected = true;
      return;
    }

    if (_shouldUseNativeSip()) {
      await _restoreNativeRegistrationIfNeeded('cold-start');
      if (_isActiveUiCallStatus(_state.callStatus)) {
        _shouldStayConnected = true;
        return;
      }
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
    if (!_isNativeSipPlatform()) {
      return;
    }

    try {
      await _nativeSipEventsSubscription?.cancel();
      _nativeSipEventsSubscription = null;
      final initialized =
          await _invokeNativeSipMethod<bool>('initialize', null, false) ??
              false;
      if (!initialized) {
        _nativeSipBridgeAvailable = false;
        return;
      }
      _nativeSipBridgeAvailable = true;
      _nativeSipEventsSubscription =
          _nativeSipEventChannel.receiveBroadcastStream().listen(
        _handleNativeSipEvent,
        onError: (Object error) {
          debugPrint('SipService native SIP stream error: $error');
        },
      );
      await _resyncNativeBridgeState();
    } on MissingPluginException catch (error) {
      _nativeSipBridgeAvailable = false;
      debugPrint('SipService native SIP initialize failed: $error');
    } catch (error) {
      _nativeSipBridgeAvailable = false;
      debugPrint('SipService native SIP initialize failed: $error');
    }
  }

  Future<void> _resyncNativeBridgeState() async {
    if (!_nativeSipBridgeAvailable) {
      return;
    }

    await _syncNativeSnapshot();
    if (Platform.isAndroid) {
      final pendingCallUiRequest = await _invokeNativeSipMethod<Object?>(
        'consumePendingCallUiRequest',
        null,
        false,
      );
      if (pendingCallUiRequest is Map) {
        _handleNativeSipEvent(Map<String, dynamic>.from(pendingCallUiRequest));
      }
    }
    await _consumePendingIosCallActions();
  }

  Future<String?> getVoipPushToken() async {
    if (!Platform.isIOS) {
      return null;
    }

    if (!await _ensureNativeSipBridgeInitialized()) {
      return _storage.read(key: _voipPushTokenKey);
    }

    final nativeToken =
        await _invokeNativeSipMethod<String>('getVoipPushToken');
    if (nativeToken != null && nativeToken.trim().isNotEmpty) {
      await _storage.write(key: _voipPushTokenKey, value: nativeToken.trim());
      return nativeToken.trim();
    }

    return _storage.read(key: _voipPushTokenKey);
  }

  Future<bool> simulateIosIncomingCall({
    String handle = '100',
    String? callerName,
    String? callId,
    String? fromUri,
    String? toUri,
    String? sipUri,
    bool hasVideo = false,
  }) async {
    if (!Platform.isIOS) {
      return false;
    }

    final available = await _ensureNativeSipBridgeInitialized();
    if (!available) {
      return false;
    }

    return await _invokeNativeSipMethod<bool>(
          'simulateIncomingCall',
          <String, dynamic>{
            'handle': handle,
            'callerName': callerName ?? handle,
            if (callId != null && callId.trim().isNotEmpty)
              'callId': callId.trim(),
            if (fromUri != null && fromUri.trim().isNotEmpty)
              'fromUri': fromUri.trim(),
            if (toUri != null && toUri.trim().isNotEmpty) 'toUri': toUri.trim(),
            if (sipUri != null && sipUri.trim().isNotEmpty)
              'sipUri': sipUri.trim(),
            'hasVideo': hasVideo,
          },
        ) ??
        false;
  }

  Future<void> _restoreNativeRegistrationIfNeeded(String reason) async {
    if (_isActiveUiCallStatus(_state.callStatus)) {
      debugPrint(
        'SipService native restore skipped during active call -> reason=$reason, callState=${_state.callStatus.name}',
      );
      return;
    }
    if (!await _ensureNativeSipBridgeInitialized()) {
      return;
    }

    debugPrint('SipService native restore -> reason=$reason');
    await _syncNativeSnapshot(restoreIfNeeded: true);
  }

  Future<void> _syncNativeSnapshot({bool restoreIfNeeded = false}) async {
    if (!await _ensureNativeSipBridgeInitialized()) {
      return;
    }

    if (restoreIfNeeded && _shouldUseNativeSip()) {
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

  Future<void> _consumePendingIosCallActions() async {
    if (!Platform.isIOS) {
      return;
    }

    if (!await _ensureNativeSipBridgeInitialized()) {
      return;
    }

    final actions = await _invokeNativeSipMethod<List<dynamic>>(
      'consumePendingCallActions',
    );
    if (actions == null) {
      return;
    }

    for (final item in actions) {
      if (item is Map) {
        _queueIosCallAction(Map<String, dynamic>.from(item));
      }
    }

    _applyPendingIosCallActionsIfPossible();
  }

  Future<List<Map<String, dynamic>>> getNativeDiagnosticLogs() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return const <Map<String, dynamic>>[];
    }

    if (!await _ensureNativeSipBridgeInitialized()) {
      return const <Map<String, dynamic>>[];
    }

    final logs =
        await _invokeNativeSipMethod<List<dynamic>>('getDiagnosticLogs');
    if (logs == null) {
      return const <Map<String, dynamic>>[];
    }

    return logs
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> clearNativeDiagnosticLogs() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return;
    }

    if (!await _ensureNativeSipBridgeInitialized()) {
      return;
    }

    await _invokeNativeSipMethod<bool>('clearDiagnosticLogs');
  }

  Future<void> saveDraft({
    required String server,
    required String login,
    required String password,
    required String sipId,
    required SipTransportUi transport,
    required int port,
    bool notifyUi = true,
  }) async {
    final normalizedServer = _normalizeServerInput(server, transport);
    final nextEndpoint = _endpointKey(
      server: normalizedServer,
      transport: transport,
      port: port,
    );
    if (_hardTransportFailureEndpoint != nextEndpoint) {
      _hardTransportFailure = false;
      _hardTransportFailureEndpoint = null;
    }

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

    if (notifyUi) {
      _notifyListenersSafely();
    }
  }

  Future<void> handleIncomingCallPushPayload(
    Map<String, dynamic> rawPayload, {
    String source = 'unknown',
    bool persist = true,
  }) async {
    final payload =
        _normalizeIncomingCallPushPayload(rawPayload, source: source);
    if (payload == null) {
      debugPrint(
        'SipService incoming_call push ignored: invalid payload from $source -> $rawPayload',
      );
      return;
    }

    if (_isExpiredIncomingCallPush(payload)) {
      debugPrint(
        'SipService incoming_call push expired -> call_id=${payload['call_id']}, issued_at_ms=${payload['issued_at_ms']}',
      );
      return;
    }

    if (persist) {
      await _savePendingIncomingCallPushPayload(payload);
    }

    if (_isDuplicateIncomingCallPush(payload)) {
      debugPrint(
        'SipService incoming_call push deduplicated -> call_id=${payload['call_id']}, source=$source',
      );
      return;
    }

    await initialize();

    final shouldWakeSip = _sipEnabled || _persistentSipEnabled;
    final remoteIdentity =
        _normalizeRemoteIdentity(payload['remote_identity']?.toString());
    final callId = payload['call_id']?.toString();

    _lastIncomingCallPushId = callId;
    _lastIncomingCallPushAt = DateTime.now();
    _rememberIncomingFingerprint(
      callUUID: null,
      callId: callId,
      remoteIdentity: remoteIdentity,
    );

    if (_state.callStatus == SipCallUiStatus.idle ||
        _state.callStatus == SipCallUiStatus.ended ||
        _state.callStatus == SipCallUiStatus.failed) {
      _state = _state.copyWith(
        remoteIdentity: remoteIdentity,
        errorMessage: 'Входящий вызов: пробуждаем телефонию...',
      );
      _notifyListenersSafely();
    }

    if (shouldWakeSip &&
        _networkAvailable &&
        _hasSipCredentials() &&
        _state.registrationStatus != SipRegistrationUiStatus.registered &&
        _state.registrationStatus != SipRegistrationUiStatus.registering) {
      _shouldStayConnected = true;
      _persistentSipEnabled = true;
      _sipEnabled = true;
      await _storage.write(key: _enabledKey, value: 'true');
      unawaited(_syncIncomingCallPushPreference(true));

      if (_shouldUseNativeSip()) {
        unawaited(_restoreNativeRegistrationIfNeeded('incoming-call-push'));
      } else {
        unawaited(connect());
      }
    }
  }

  Future<void> recoverPendingIncomingCallPush() async {
    final payload = await _consumePendingIncomingCallPushPayload();
    if (payload == null) {
      return;
    }

    final receivedAt = payload['received_at_ms'] as int?;
    if (receivedAt != null) {
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(receivedAt),
      );
      if (age > const Duration(minutes: 2)) {
        debugPrint('SipService pending incoming_call push expired -> age=$age');
        return;
      }
    }

    await handleIncomingCallPushPayload(
      payload,
      source: payload['source']?.toString() ?? 'recovered',
      persist: false,
    );
  }

  Map<String, dynamic>? _normalizeIncomingCallPushPayload(
    Map<String, dynamic> rawPayload, {
    required String source,
  }) {
    String? pickString(List<String> keys) {
      for (final key in keys) {
        final value = rawPayload[key];
        if (value == null) {
          continue;
        }
        final normalized = value.toString().trim();
        if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
          return normalized;
        }
      }
      return null;
    }

    int? pickInt(List<String> keys) {
      final value = pickString(keys);
      return value == null ? null : int.tryParse(value);
    }

    final type = pickString(<String>['type']);
    if (type != 'incoming_call') {
      return null;
    }

    final callId = pickString(<String>['call_id', 'id']);
    final leadId = pickInt(<String>['lead_id']);
    final callerName = pickString(<String>[
      'caller_name',
      'lead_name',
      'phone',
      'from',
    ]);
    final remoteIdentity = _normalizeRemoteIdentity(pickString(<String>[
          'remote_identity',
          'phone',
          'lead_name',
          'caller_name',
          'from',
        ]) ??
        callerName);

    if ((callId == null || callId.isEmpty) &&
        (remoteIdentity == null || remoteIdentity.isEmpty)) {
      return null;
    }

    return <String, dynamic>{
      'type': 'incoming_call',
      'call_id': callId,
      'lead_id': leadId,
      'lead_name': pickString(<String>['lead_name']),
      'caller_name': callerName,
      'remote_identity': remoteIdentity,
      'issued_at_ms': _incomingPushIssuedAtMs(rawPayload),
      'source': source,
      'received_at_ms': DateTime.now().millisecondsSinceEpoch,
    };
  }

  int? _incomingPushIssuedAtMs(Map<String, dynamic> payload) {
    const keys = <String>[
      'call_started_at_ms',
      'created_at_ms',
      'sent_at_ms',
      'issued_at_ms',
      'timestamp_ms',
      'call_started_at',
      'created_at',
      'sent_at',
      'issued_at',
      'timestamp',
      'google.sent_time',
    ];
    for (final key in keys) {
      final value = payload[key];
      final parsed = value is num
          ? value.toInt()
          : int.tryParse(value?.toString().trim() ?? '');
      if (parsed != null && parsed > 0) {
        return parsed < 10000000000 ? parsed * 1000 : parsed;
      }
    }
    return null;
  }

  bool _isExpiredIncomingCallPush(Map<String, dynamic> payload) {
    final issuedAtMs = payload['issued_at_ms'] as int?;
    if (issuedAtMs == null) {
      // Until every backend sender includes a creation timestamp, a client
      // cannot distinguish a delayed delivery from a real new call.
      return false;
    }
    return DateTime.now().millisecondsSinceEpoch - issuedAtMs >
        const Duration(minutes: 2).inMilliseconds;
  }

  bool _isDuplicateIncomingCallPush(Map<String, dynamic> payload) {
    final callId = payload['call_id']?.toString().trim();
    final lastAt = _lastIncomingCallPushAt;
    if (callId == null || callId.isEmpty || lastAt == null) {
      return false;
    }

    if (_lastIncomingCallPushId != callId) {
      return false;
    }

    return DateTime.now().difference(lastAt) < const Duration(seconds: 12);
  }

  Future<void> _savePendingIncomingCallPushPayload(
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingIncomingCallPushPayloadKey,
      jsonEncode(payload),
    );
  }

  Future<Map<String, dynamic>?> _consumePendingIncomingCallPushPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingIncomingCallPushPayloadKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    await prefs.remove(_pendingIncomingCallPushPayloadKey);

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (error) {
      debugPrint(
        'SipService failed to decode pending incoming_call push payload: $error',
      );
    }

    return null;
  }

  Future<void> prepareSipRuntimePermissions() async {
    final inFlight = _prepareRuntimePermissionsFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _prepareSipRuntimePermissionsInternal();
    _prepareRuntimePermissionsFuture = future;

    try {
      await future;
    } finally {
      if (identical(_prepareRuntimePermissionsFuture, future)) {
        _prepareRuntimePermissionsFuture = null;
      }
    }
  }

  Future<void> _prepareSipRuntimePermissionsInternal() async {
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
      final promptedFullScreenIncomingCall =
          await _storage.read(key: _fullScreenIncomingCallPromptedKey);
      if (promptedFullScreenIncomingCall != 'true') {
        final opened = await _invokeNativeSipMethod<bool>(
              'requestIncomingCallFullScreenSettings',
              null,
              false,
            ) ??
            false;
        if (opened) {
          await _storage.write(
            key: _fullScreenIncomingCallPromptedKey,
            value: 'true',
          );
          // Do not immediately cover the full-screen-call permission page with
          // the battery/OEM settings screens below. They can be offered on the
          // next permissions preparation pass.
          return;
        }
      }

      final promptedBackgroundReliability =
          await _storage.read(key: _backgroundReliabilityPromptedKey);
      if (promptedBackgroundReliability != 'true') {
        final opened = await _invokeNativeSipMethod<bool>(
              'requestBackgroundReliabilitySettings',
              null,
              false,
            ) ??
            false;
        if (opened) {
          await _storage.write(
            key: _backgroundReliabilityPromptedKey,
            value: 'true',
          );
        }
      }

      final promptedXiaomiAutoStart =
          await _storage.read(key: _xiaomiAutoStartPromptedKey);
      if (promptedXiaomiAutoStart != 'true') {
        final opened = await _invokeNativeSipMethod<bool>(
              'openXiaomiSettings',
              null,
              false,
            ) ??
            false;
        if (opened) {
          await _storage.write(
            key: _xiaomiAutoStartPromptedKey,
            value: 'true',
          );
        }
      }
    }
  }

  Future<void> connect() async {
    if (_isActiveUiCallStatus(_state.callStatus)) {
      _shouldStayConnected = true;
      return;
    }
    if (!_hasSipCredentials()) {
      _setError('Заполните сервер телефонии, логин и пароль.');
      return;
    }

    final validationError = _validateSipConfiguration();
    if (validationError != null) {
      _setError(validationError);
      return;
    }

    if (!_networkAvailable) {
      _setError('Нет интернета. Подключение телефонии приостановлено.');
      return;
    }

    if (_shouldUseNativeSip()) {
      await Permission.notification.request();
    }

    if (_hardTransportFailure &&
        _hardTransportFailureEndpoint == _currentEndpointKey() &&
        _state.registrationStatus == SipRegistrationUiStatus.failed) {
      _setError(_connectionRefusedMessage());
      return;
    }

    if (_state.registrationStatus == SipRegistrationUiStatus.registering ||
        _helper.connecting) {
      return;
    }

    _shouldStayConnected = true;
    _sipEnabled = true;
    _persistentSipEnabled = true;
    _hardTransportFailure = false;
    _hardTransportFailureEndpoint = null;
    await _storage.write(key: _enabledKey, value: 'true');
    unawaited(_syncIncomingCallPushPreference(true));
    if (Platform.isIOS) {
      // VoIP token belongs to an active SIP connection. Do not register it
      // merely because the app started or SipService was initialized.
      unawaited(_syncVoipTokenAfterSipConnect());
    }
    _logSipConfig('connect');
    await _startSipRegistration();
  }

  Future<void> _startSipRegistration({bool clearError = true}) async {
    if (_isActiveUiCallStatus(_state.callStatus)) {
      _shouldStayConnected = true;
      return;
    }
    if (_state.registrationStatus == SipRegistrationUiStatus.registering ||
        _helper.connecting) {
      return;
    }

    _state = _state.copyWith(
      registrationStatus: SipRegistrationUiStatus.registering,
      callStatus: SipCallUiStatus.idle,
      clearError: clearError,
      clearRemoteIdentity: true,
    );
    _notifyListenersSafely();

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
          errorMessage: 'Не удалось подключить телефонию',
        );
        _notifyListenersSafely();
      }
      return;
    }

    await _ensureRenderersInitializedForCurrentMode();

    final settings = UaSettings();
    if (_state.transport == SipTransportUi.ws) {
      settings.webSocketUrl = _toWebSocketUrl(_state.server, _state.port);
      settings.webSocketSettings.allowBadCertificate = true;
      settings.transportType = TransportType.WS;
    } else if (_state.transport == SipTransportUi.tcp) {
      settings.transportType = TransportType.TCP;
      settings.host = domain;
      settings.port = _state.port.toString();
    } else {
      settings.transportType = TransportType.UDP;
      settings.host = domain;
      settings.port = _state.port.toString();
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
    try {
      await _helper.start(settings);
    } catch (error, stackTrace) {
      debugPrint('SipService: _helper.start failed: $error');
      debugPrint('SipService: _helper.start stackTrace: $stackTrace');
      _state = _state.copyWith(
        registrationStatus: SipRegistrationUiStatus.failed,
        errorMessage: 'Не удалось запустить телефонию: $error',
      );
      _notifyListenersSafely();
    }
  }

  Future<void> disconnect() async {
    debugPrint('SipService.disconnect invoked');
    _shouldStayConnected = false;
    _persistentSipEnabled = false;
    _sipEnabled = false;
    _hardTransportFailure = false;
    _hardTransportFailureEndpoint = null;
    await _storage.write(key: _enabledKey, value: 'false');
    unawaited(_syncIncomingCallPushPreference(false));
    unawaited(revokeVoipTokenAndClearLocal());
    _cancelReconnect();
    _stopKeepAlive();

    if (_shouldUseNativeSip()) {
      _activeCall = null;
      await _invokeNativeSipMethod('unregister');
    } else {
      try {
        _activeCall?.hangup(<String, dynamic>{'status_code': 603});
      } catch (_) {}

      _activeCall = null;

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
    _notifyListenersSafely();
  }

  Future<void> clearSavedCredentials({
    bool revokeBackendVoipToken = true,
  }) async {
    _shouldStayConnected = false;
    _persistentSipEnabled = false;
    _sipEnabled = false;
    _hardTransportFailure = false;
    _hardTransportFailureEndpoint = null;
    await _syncIncomingCallPushPreference(false);
    if (revokeBackendVoipToken) {
      await revokeVoipTokenAndClearLocal();
    } else {
      await _clearLocalVoipToken();
    }
    _cancelReconnect();
    _stopKeepAlive();

    try {
      _activeCall?.hangup(<String, dynamic>{'status_code': 603});
    } catch (_) {}

    _activeCall = null;
    if (_shouldUseNativeSip()) {
      await _invokeNativeSipMethod('unregister');
    } else {
      if (_helper.registered) {
        _helper.unregister(true);
      }
      _helper.stop();
    }
    _releaseStreams();

    for (final key in _sipSecureStorageKeys) {
      await _storage.delete(key: key);
    }

    _state = SipUiState.initial();
    _notifyListenersSafely();
  }

  Future<void> revokeVoipTokenAndClearLocal() async {
    if (Platform.isIOS) {
      try {
        final token = await getVoipPushToken();
        await _apiService
            .deleteVoipToken(voipToken: token)
            .timeout(_iosVoipTokenSyncTimeout);
      } catch (error) {
        debugPrint('SipService: VoIP token revoke skipped: $error');
      }
    }
    await _clearLocalVoipToken();
  }

  Future<void> _clearLocalVoipToken() async {
    _lastSyncedIosVoipPushToken = null;
    await _storage.delete(key: _voipPushTokenKey);
    await _apiService.clearPendingVoipToken();
  }

  bool get hasSavedCredentials => _hasSipCredentials();
  bool get isSipEnabled => _sipEnabled;

  Future<void> makeCall() async {
    await makeCallTo(_state.sipId);
  }

  Future<void> makeCallTo(
    String dialTarget, {
    String? displayName,
  }) async {
    if (_state.registrationStatus != SipRegistrationUiStatus.registered) {
      _setError('Телефония не подключена. Сначала подключите линию.');
      return;
    }

    final normalizedTarget = _restoreTajikPlusIfMissing(dialTarget);
    if (normalizedTarget.isEmpty) {
      _setError('Введите номер для звонка.');
      return;
    }

    _currentCallDirection = SipCallDirection.outgoing;
    _currentCallTarget = normalizedTarget;
    final normalizedDisplayName = displayName?.trim() ?? '';
    _currentCallDisplayName = normalizedDisplayName.isEmpty ||
            normalizedDisplayName.toLowerCase() == 'неизвестно'
        ? normalizedTarget
        : normalizedDisplayName;
    _currentCallStartedAt = null;

    final target =
        _buildTargetUri(normalizedTarget, _extractDomain(_state.server));
    _currentInviteUri = target;

    if (_shouldUseNativeSip()) {
      final granted = await _ensureMediaPermissions(includeCamera: false);
      if (!granted) {
        return;
      }

      _logSipConfig(
        'nativeMakeCall',
        extra: <String, String>{
          'target': target,
          'dialed': normalizedTarget,
        },
      );

      // Set the optimistic state before invoking Linphone. Native call events
      // may synchronously report Error/End before the method result returns;
      // writing "calling" afterwards would resurrect an already ended call.
      _state = _state.copyWith(
        callStatus: SipCallUiStatus.calling,
        remoteIdentity: normalizedTarget,
        clearError: true,
      );
      _notifyListenersSafely();

      final success = await _invokeNativeSipMethod<bool>(
            'makeCall',
            <String, dynamic>{'target': target},
          ) ??
          false;
      if (!success) {
        final status = _state.callStatus;
        if (status == SipCallUiStatus.calling ||
            status == SipCallUiStatus.ringing) {
          _state = _state.copyWith(
            callStatus: SipCallUiStatus.failed,
            errorMessage: 'Не удалось начать звонок через телефонию.',
            clearRemoteIdentity: true,
          );
          _notifyListenersSafely();
        }
        return;
      }
      return;
    }

    final granted = await _ensureMediaPermissions(includeCamera: false);
    if (!granted) {
      return;
    }

    _logSipConfig(
      'makeCall',
      extra: <String, String>{
        'target': target,
        'dialed': normalizedTarget,
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
    _notifyListenersSafely();
  }

  Future<void> acceptCall() async {
    if (_shouldUseNativeSip()) {
      final granted = await _ensureMediaPermissions(includeCamera: false);
      if (!granted) {
        return;
      }

      _state = _state.copyWith(
        callStatus: SipCallUiStatus.ringing,
        clearError: true,
      );
      _notifyListenersSafely();

      final success = await _invokeNativeSipMethod<bool>('acceptCall') ?? false;
      if (!success) {
        _setError('Не удалось ответить на звонок телефонии.');
      } else {
        _currentCallStartedAt ??= DateTime.now();
        _clearIncomingFingerprint();
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.inCall,
          clearError: true,
        );
        _notifyListenersSafely();
      }
      return;
    }

    final call = _activeCall;
    if (call == null) return;

    final granted = await _ensureMediaPermissions(includeCamera: false);
    if (!granted) {
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
    _notifyListenersSafely();
  }

  Future<void> hangup() async {
    if (_shouldUseNativeSip()) {
      final uiWasActive = _state.callStatus == SipCallUiStatus.incoming ||
          _state.callStatus == SipCallUiStatus.calling ||
          _state.callStatus == SipCallUiStatus.ringing ||
          _state.callStatus == SipCallUiStatus.inCall;
      final success = await _invokeNativeSipMethod<bool>('hangup') ?? false;
      if (!success && !uiWasActive) {
        _setError('Не удалось завершить звонок телефонии.');
        return;
      }

      // Hangup is idempotent from the UI perspective. If Linphone has already
      // released a failed/unanswered call, the local screen must still close.
      _clearIncomingFingerprint();
      _markTerminalNativeCallFingerprint();
      _currentInviteUri = null;
      _currentCallStartedAt = null;
      _currentCallTarget = null;
      _currentCallDisplayName = null;
      _state = _state.copyWith(
        callStatus: SipCallUiStatus.ended,
        clearRemoteIdentity: true,
        clearError: true,
        isMuted: false,
        isSpeakerOn: false,
      );
      _notifyListenersSafely();
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
    _notifyListenersSafely();
  }

  Future<void> toggleSpeaker() async {
    if (_speakerToggleInProgress || !_isActiveUiCallStatus(_state.callStatus)) {
      return;
    }

    final targetSpeaker = !_state.isSpeakerOn;
    final previousSpeaker = _state.isSpeakerOn;
    debugPrint(
      'SipService toggleSpeaker -> current=${_state.isSpeakerOn}, target=$targetSpeaker, callStatus=${_state.callStatus}',
    );
    _speakerToggleInProgress = true;
    _state = _state.copyWith(isSpeakerOn: targetSpeaker);
    _notifyListenersSafely();

    try {
      if (_shouldUseNativeSip()) {
        final success = await _invokeNativeSipMethod<bool>(
              'setSpeaker',
              <String, dynamic>{'speakerOn': targetSpeaker},
            ) ??
            false;
        debugPrint(
          'SipService toggleSpeaker native result -> success=$success, target=$targetSpeaker',
        );
        if (!success) {
          _state = _state.copyWith(isSpeakerOn: previousSpeaker);
          _notifyListenersSafely();
          _setError('Не удалось изменить аудиовыход звонка.');
        }
        return;
      }

      final track = _localStream?.getAudioTracks().isNotEmpty == true
          ? _localStream!.getAudioTracks().first
          : null;
      if (track == null) {
        _state = _state.copyWith(isSpeakerOn: previousSpeaker);
        _notifyListenersSafely();
        return;
      }
      track.enableSpeakerphone(targetSpeaker);
    } catch (error) {
      _state = _state.copyWith(isSpeakerOn: previousSpeaker);
      _notifyListenersSafely();
      _setError('Не удалось изменить аудиовыход звонка: $error');
    } finally {
      _speakerToggleInProgress = false;
    }
  }

  Future<List<SipAudioRoute>> getAvailableAudioRoutes() async {
    if (!_shouldUseNativeSip()) {
      return const <SipAudioRoute>[];
    }

    final rawRoutes = await _invokeNativeSipMethod<List<dynamic>>(
          'getAudioRoutes',
          null,
          false,
        ) ??
        const <dynamic>[];
    final routes = rawRoutes
        .whereType<Map<dynamic, dynamic>>()
        .map(SipAudioRoute.fromMap)
        .where((route) => route.id.isNotEmpty && route.type != 'microphone')
        .toList(growable: false);
    final selectedRoute = routes.where((route) => route.selected).firstOrNull;
    if (selectedRoute != null) {
      _currentAudioRouteType = selectedRoute.type;
      _currentAudioRouteName = selectedRoute.name;
    }
    return routes;
  }

  Future<bool> selectAudioRoute(SipAudioRoute route) async {
    if (_audioRouteChangeInProgress ||
        !_isActiveUiCallStatus(_state.callStatus)) {
      return false;
    }

    _audioRouteChangeInProgress = true;
    final previousSpeaker = _state.isSpeakerOn;
    final previousRouteType = _currentAudioRouteType;
    final previousRouteName = _currentAudioRouteName;
    _currentAudioRouteType = route.type;
    _currentAudioRouteName = route.name;
    _state = _state.copyWith(isSpeakerOn: route.type == 'speaker');
    _notifyListenersSafely();

    try {
      final success = await _invokeNativeSipMethod<bool>(
            'setAudioRoute',
            <String, dynamic>{'deviceId': route.id},
            false,
          ) ??
          false;
      if (!success) {
        _currentAudioRouteType = previousRouteType;
        _currentAudioRouteName = previousRouteName;
        _state = _state.copyWith(isSpeakerOn: previousSpeaker);
        _notifyListenersSafely();
        _setError('Не удалось переключить аудиовыход звонка.');
      }
      return success;
    } catch (error) {
      _currentAudioRouteType = previousRouteType;
      _currentAudioRouteName = previousRouteName;
      _state = _state.copyWith(isSpeakerOn: previousSpeaker);
      _notifyListenersSafely();
      _setError('Не удалось переключить аудиовыход звонка: $error');
      return false;
    } finally {
      _audioRouteChangeInProgress = false;
    }
  }

  Future<void> sendDtmf(String tone) async {
    final normalized = tone.trim();
    if (normalized.isEmpty) {
      return;
    }

    if (_shouldUseNativeSip()) {
      final sent = await _invokeNativeSipMethod<bool>(
        'sendDtmf',
        <String, dynamic>{'tone': normalized},
        false,
      );
      if (sent == false) {
        debugPrint('Native SIP DTMF was not sent: $normalized');
      }
      return;
    }

    if (_activeCall == null) {
      return;
    }

    _activeCall!.sendDTMF(normalized);
  }

  bool _hasSipCredentials() {
    return _state.server.trim().isNotEmpty &&
        _state.login.trim().isNotEmpty &&
        _state.password.isNotEmpty;
  }

  String? _validateSipConfiguration() {
    final server = _state.server.trim();
    if (server.isEmpty) {
      return 'Сервер телефонии не указан.';
    }

    final isWsAddress =
        server.startsWith('ws://') || server.startsWith('wss://');

    if (_state.transport == SipTransportUi.ws && !isWsAddress) {
      return 'Для WS/WSS нужен полный адрес `ws://` или `wss://`. Для обычной телефонии используйте UDP или TCP.';
    }

    if (_state.transport != SipTransportUi.ws && isWsAddress) {
      return 'Этот адрес похож на WebSocket endpoint. Переключите transport на WS/WSS.';
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
    bool disableBridgeOnMissing = true,
  ]) async {
    if (!_isNativeSipPlatform()) {
      return null;
    }

    if (method != 'initialize' && !await _ensureNativeSipBridgeInitialized()) {
      return null;
    }

    try {
      return await _nativeSipMethodChannel
          .invokeMethod<T>(method, arguments)
          .timeout(_nativeMethodTimeoutFor(method));
    } on TimeoutException {
      debugPrint(
        'SipService native SIP method timed out [$method] after ${_nativeMethodTimeoutFor(method).inSeconds}s',
      );
      if (method == 'initialize') {
        _nativeSipBridgeAvailable = false;
      }
    } on MissingPluginException catch (error) {
      if (!disableBridgeOnMissing) {
        debugPrint('Optional native SIP method unavailable [$method]: $error');
        return null;
      }
      _nativeSipBridgeAvailable = false;
      unawaited(_nativeSipEventsSubscription?.cancel());
      _nativeSipEventsSubscription = null;
      final message =
          'Телефония недоступна в этой версии приложения. Полностью закройте приложение и установите актуальную сборку.';
      debugPrint('SipService native SIP missing plugin [$method]: $message');
      _state = _state.copyWith(
        registrationStatus: SipRegistrationUiStatus.failed,
        errorMessage: message,
      );
      _notifyListenersSafely();
    } on PlatformException catch (error) {
      debugPrint(
        'SipService native SIP method error [$method]: ${error.code} ${error.message}',
      );
    } catch (error) {
      debugPrint('SipService native SIP method error [$method]: $error');
    }
    return null;
  }

  Duration _nativeMethodTimeoutFor(String method) {
    return switch (method) {
      'register' || 'restoreRegistrationIfNeeded' => const Duration(seconds: 8),
      'makeCall' ||
      'acceptCall' ||
      'declineCall' ||
      'hangup' ||
      'unregister' ||
      'endSystemCall' =>
        const Duration(seconds: 5),
      _ => _nativeStartupStepTimeout,
    };
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
      return;
    }

    if (type == 'push_token') {
      _handleNativePushTokenEvent(payload);
      return;
    }

    if (type == 'push_token_invalidated') {
      _handleNativePushTokenInvalidatedEvent();
      return;
    }

    if (type == 'pending_call_actions') {
      _handlePendingIosCallActionsEvent(payload);
      return;
    }

    if (type == 'call_action') {
      _handleNativeCallActionEvent(payload);
      return;
    }

    if (type == 'sip_ready') {
      _handleNativeSipReadyEvent(payload);
      return;
    }

    if (type == 'audio_session') {
      _handleNativeAudioSessionEvent(payload);
      return;
    }

    if (type == 'call_ui_request') {
      final requestId =
          int.tryParse(payload['requestId']?.toString() ?? '') ?? 0;
      if (requestId > 0 && requestId == _lastNativeCallUiRequestId) {
        return;
      }
      if (requestId > 0) {
        _lastNativeCallUiRequestId = requestId;
      }
      _applyNativeSnapshot(payload);
      _callUiOpenRequestSerial += 1;
      unawaited(recordUiDiagnostic(
        'CALL_UI_EVENT_RECEIVED',
        <String, Object?>{
          'serial': _callUiOpenRequestSerial,
          'source': payload['source'],
          'request_id': requestId,
          'call_state': payload['callState'],
          'registration_state': payload['registrationState'],
        },
      ));
      debugPrint(
        'SipService native call UI requested -> serial=$_callUiOpenRequestSerial, source=${payload['source']}, callState=${payload['callState']}, registrationState=${payload['registrationState']}',
      );
      _notifyListenersSafely();
      return;
    }
  }

  void _handleNativePushTokenEvent(Map<String, dynamic> payload) {
    final token = payload['token']?.toString();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    final normalizedToken = token.trim();
    debugPrint(
      'SipService native push token event -> provider=${payload['provider']}, token=${normalizedToken.length > 20 ? '${normalizedToken.substring(0, 20)}...' : normalizedToken}',
    );
    unawaited(_storage.write(key: _voipPushTokenKey, value: normalizedToken));
    // PushKit can issue a token even for users who never enabled SIP. Keep it
    // locally and sync it only after the user explicitly connects SIP.
    if (_shouldStayConnected && _sipEnabled) {
      unawaited(_syncIosVoipPushTokenWithBackend(normalizedToken));
    }
  }

  Future<void> _syncVoipTokenAfterSipConnect() async {
    if (!Platform.isIOS || !_shouldStayConnected || !_sipEnabled) {
      return;
    }

    try {
      final token = await getVoipPushToken();
      if (token != null && token.trim().isNotEmpty) {
        await _syncIosVoipPushTokenWithBackend(token, force: true)
            .timeout(_iosVoipTokenSyncTimeout);
      } else {
        // This covers a token that was received before authorization or while
        // the backend was unavailable. Do not send an old pending token when
        // a newer current token is already available.
        await _apiService
            .sendPendingVoipTokenIfNeeded()
            .timeout(_iosVoipTokenSyncTimeout);
      }
    } catch (error) {
      // sendVoipToken keeps the token pending; it will be retried on the next
      // explicit SIP connect, never during ordinary app startup.
      debugPrint(
          'SipService VoIP token sync after SIP connect skipped: $error');
    }
  }

  void _handleNativePushTokenInvalidatedEvent() {
    debugPrint('SipService native push token invalidated');
    unawaited(_clearLocalVoipToken());
  }

  void _handleNativeSipReadyEvent(Map<String, dynamic> payload) {
    if (!Platform.isIOS) {
      return;
    }

    final callId = payload['callId']?.toString().trim() ?? '';
    final callUUID = payload['callUUID']?.toString().trim() ?? '';
    final sipCallId = payload['sipCallId']?.toString().trim();
    final extension =
        payload['extension']?.toString().trim() ?? _state.login.trim();

    if (callId.isEmpty && callUUID.isEmpty) {
      debugPrint('SipService sip-ready ignored: missing call identifiers');
      return;
    }

    final readyKey = '$callId|$callUUID|$extension';
    if (_sentSipReadyKeys.contains(readyKey)) {
      debugPrint('SipService sip-ready duplicate skipped -> $readyKey');
      return;
    }

    _sentSipReadyKeys.add(readyKey);
    unawaited(_sendSipReadyToBackend(
      callId: callId,
      callUUID: callUUID,
      sipCallId: sipCallId == null || sipCallId.isEmpty ? null : sipCallId,
      extension: extension,
      readyKey: readyKey,
    ));
  }

  Future<void> _sendSipReadyToBackend({
    required String callId,
    required String callUUID,
    String? sipCallId,
    required String extension,
    required String readyKey,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _appendNativeDiagnosticLog('[VOIP] SIP_READY_REQUEST', {
        'call_id': callId,
        'call_uuid': callUUID,
        'sip_call_id': sipCallId ?? '',
        'extension': extension,
      });
      final statusCode = await _apiService.sendSipReady(
        callId: callId,
        callUUID: callUUID,
        sipCallId: sipCallId,
        extension: extension,
      );
      await _appendNativeDiagnosticLog('[VOIP] SIP_READY_RESPONSE', {
        'call_id': callId,
        'call_uuid': callUUID,
        'sip_call_id': sipCallId ?? '',
        'extension': extension,
        'status': statusCode ?? '',
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
      debugPrint(
        '[VOIP] SIP_READY_RESPONSE status=$statusCode duration_ms=${stopwatch.elapsedMilliseconds} call_id=$callId call_uuid=$callUUID sip_call_id=${sipCallId ?? ''} extension=$extension',
      );
    } catch (error, stackTrace) {
      _sentSipReadyKeys.remove(readyKey);
      await _appendNativeDiagnosticLog('[VOIP] SIP_READY_RESPONSE', {
        'call_id': callId,
        'call_uuid': callUUID,
        'sip_call_id': sipCallId ?? '',
        'extension': extension,
        'status': 'failed',
        'duration_ms': stopwatch.elapsedMilliseconds,
        'error': error,
      });
      debugPrint('SipService sip-ready failed: $error');
      debugPrint('SipService sip-ready stackTrace: $stackTrace');
    }
  }

  Future<void> _appendNativeDiagnosticLog(
    String event,
    Map<String, Object?> details,
  ) async {
    if (!_isNativeSipPlatform()) return;

    try {
      await _nativeSipMethodChannel.invokeMethod<bool>('appendDiagnosticLog', {
        'event': event,
        'details': details.map((key, value) => MapEntry(key, '${value ?? ''}')),
      });
    } catch (error) {
      debugPrint('SipService append native diagnostic failed: $error');
    }
  }

  Future<void> recordUiDiagnostic(
    String event, [
    Map<String, Object?> details = const <String, Object?>{},
  ]) {
    return _appendNativeDiagnosticLog(event, details);
  }

  Future<void> _syncIosVoipPushTokenWithBackend(
    String token, {
    bool force = false,
  }) async {
    if (!Platform.isIOS || token.trim().isEmpty) {
      return;
    }

    final normalizedToken = token.trim();
    if (!force && _lastSyncedIosVoipPushToken == normalizedToken) {
      return;
    }

    try {
      await _apiService.sendVoipToken(normalizedToken);
      _lastSyncedIosVoipPushToken = normalizedToken;
    } catch (error) {
      debugPrint('SipService: failed to sync iOS VoIP token: $error');
    }
  }

  String? _normalizeRemoteIdentity(String? value) {
    if (value == null) {
      return null;
    }

    var normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.toLowerCase().startsWith('sip:')) {
      normalized = normalized.substring(4);
    }

    final semicolonIndex = normalized.indexOf(';');
    if (semicolonIndex > 0) {
      normalized = normalized.substring(0, semicolonIndex);
    }

    final atIndex = normalized.indexOf('@');
    if (atIndex > 0) {
      normalized = normalized.substring(0, atIndex);
    }

    normalized = normalized.trim();
    normalized = _restoreTajikPlusIfMissing(normalized);
    return normalized.isEmpty ? null : normalized;
  }

  String _restoreTajikPlusIfMissing(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('+')) {
      return trimmed;
    }

    final phoneFormattedOnly = RegExp(r'^[0-9\s().-]+$').hasMatch(trimmed);
    if (!phoneFormattedOnly) {
      return trimmed;
    }

    final digits = trimmed.replaceAll(RegExp(r'[\s().-]'), '');
    if (RegExp(r'^992\d{9}$').hasMatch(digits)) {
      return '+$digits';
    }

    return trimmed;
  }

  bool _isRemoteDeclineCause(String? rawCause) {
    if (rawCause == null) {
      return false;
    }

    final normalized = rawCause.toLowerCase();
    return normalized.contains('486') ||
        normalized.contains('603') ||
        normalized.contains('decline') ||
        normalized.contains('declined') ||
        normalized.contains('busy here') ||
        normalized.contains('busy') ||
        normalized.contains('canceled') ||
        normalized.contains('cancelled') ||
        normalized.contains('request terminated');
  }

  bool _isElsewhereTerminationMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return false;
    }

    return normalized.contains('answered elsewhere') ||
        normalized.contains('declined elsewhere') ||
        normalized.contains('answered_elsewhere') ||
        normalized.contains('declined_elsewhere');
  }

  bool _isTerminalUiCallStatus(SipCallUiStatus status) {
    return status == SipCallUiStatus.idle ||
        status == SipCallUiStatus.ended ||
        status == SipCallUiStatus.failed;
  }

  SipCallUiStatus _mapNativeCallStateToUiStatus(String? callState) {
    return switch (callState) {
      'incoming' => SipCallUiStatus.incoming,
      'calling' => SipCallUiStatus.calling,
      'ringing' => SipCallUiStatus.ringing,
      'in_call' => SipCallUiStatus.inCall,
      'ended' => SipCallUiStatus.ended,
      'failed' => SipCallUiStatus.failed,
      _ => SipCallUiStatus.idle,
    };
  }

  bool _isDuplicateIncomingEvent({
    required String? callUUID,
    required String? callId,
    required String? remoteIdentity,
  }) {
    final normalizedUuid = callUUID?.trim();
    final normalizedCallId = callId?.trim();
    final normalizedRemote = remoteIdentity?.trim();

    if (_state.callStatus != SipCallUiStatus.incoming) {
      return false;
    }

    if (normalizedUuid != null &&
        normalizedUuid.isNotEmpty &&
        normalizedUuid == _activeIncomingCallUUID) {
      return true;
    }

    if (normalizedCallId != null &&
        normalizedCallId.isNotEmpty &&
        normalizedCallId == _activeIncomingCallId) {
      return true;
    }

    if ((normalizedUuid == null || normalizedUuid.isEmpty) &&
        (normalizedCallId == null || normalizedCallId.isEmpty) &&
        normalizedRemote != null &&
        normalizedRemote.isNotEmpty &&
        normalizedRemote == _activeIncomingRemoteIdentity) {
      return true;
    }

    return false;
  }

  void _rememberIncomingFingerprint({
    required String? callUUID,
    required String? callId,
    required String? remoteIdentity,
  }) {
    _activeIncomingCallUUID = callUUID?.trim();
    _activeIncomingCallId = callId?.trim();
    _activeIncomingRemoteIdentity = remoteIdentity?.trim();
  }

  void _clearIncomingFingerprint() {
    _activeIncomingCallUUID = null;
    _activeIncomingCallId = null;
    _activeIncomingRemoteIdentity = null;
  }

  void _rememberActiveNativeCallFingerprint({
    required String? callUUID,
    required String? callId,
    required String? remoteIdentity,
  }) {
    _activeNativeCallUUID = callUUID?.trim();
    _activeNativeCallId = callId?.trim();
    _activeNativeRemoteIdentity = remoteIdentity?.trim();
    _lastTerminalNativeCallAt = null;
  }

  void _markTerminalNativeCallFingerprint() {
    _lastTerminalNativeCallUUID = _activeNativeCallUUID;
    _lastTerminalNativeCallId = _activeNativeCallId;
    _lastTerminalNativeRemoteIdentity = _activeNativeRemoteIdentity;
    _lastTerminalNativeCallAt = DateTime.now();
    _activeNativeCallUUID = null;
    _activeNativeCallId = null;
    _activeNativeRemoteIdentity = null;
  }

  bool _matchesNativeCallFingerprint({
    required String? callUUID,
    required String? callId,
    required String? remoteIdentity,
    required String? expectedUUID,
    required String? expectedCallId,
    required String? expectedRemoteIdentity,
  }) {
    final normalizedUuid = callUUID?.trim();
    final normalizedCallId = callId?.trim();
    final normalizedRemote = remoteIdentity?.trim();

    if (normalizedUuid != null &&
        normalizedUuid.isNotEmpty &&
        expectedUUID != null &&
        expectedUUID.isNotEmpty) {
      return normalizedUuid == expectedUUID;
    }

    if (normalizedCallId != null &&
        normalizedCallId.isNotEmpty &&
        expectedCallId != null &&
        expectedCallId.isNotEmpty) {
      return normalizedCallId == expectedCallId;
    }

    if (normalizedRemote != null &&
        normalizedRemote.isNotEmpty &&
        expectedRemoteIdentity != null &&
        expectedRemoteIdentity.isNotEmpty) {
      return normalizedRemote == expectedRemoteIdentity;
    }

    return false;
  }

  bool _hasAnyNativeCallFingerprint({
    required String? callUUID,
    required String? callId,
    required String? remoteIdentity,
  }) {
    return (callUUID?.trim().isNotEmpty ?? false) ||
        (callId?.trim().isNotEmpty ?? false) ||
        (remoteIdentity?.trim().isNotEmpty ?? false);
  }

  bool _shouldIgnoreLateNativeCallEvent({
    required String nativeState,
    required String? callUUID,
    required String? callId,
    required String? remoteIdentity,
  }) {
    if (nativeState == 'incoming') {
      return false;
    }

    final hasCurrentFingerprint = _hasAnyNativeCallFingerprint(
      callUUID: _activeNativeCallUUID,
      callId: _activeNativeCallId,
      remoteIdentity: _activeNativeRemoteIdentity,
    );
    final eventHasFingerprint = _hasAnyNativeCallFingerprint(
      callUUID: callUUID,
      callId: callId,
      remoteIdentity: remoteIdentity,
    );

    if (hasCurrentFingerprint && eventHasFingerprint) {
      final matchesCurrent = _matchesNativeCallFingerprint(
        callUUID: callUUID,
        callId: callId,
        remoteIdentity: remoteIdentity,
        expectedUUID: _activeNativeCallUUID,
        expectedCallId: _activeNativeCallId,
        expectedRemoteIdentity: _activeNativeRemoteIdentity,
      );
      if (!matchesCurrent) {
        return true;
      }
    }

    final terminalAt = _lastTerminalNativeCallAt;
    if (terminalAt == null ||
        DateTime.now().difference(terminalAt) > const Duration(seconds: 5)) {
      return false;
    }

    return _matchesNativeCallFingerprint(
      callUUID: callUUID,
      callId: callId,
      remoteIdentity: remoteIdentity,
      expectedUUID: _lastTerminalNativeCallUUID,
      expectedCallId: _lastTerminalNativeCallId,
      expectedRemoteIdentity: _lastTerminalNativeRemoteIdentity,
    );
  }

  bool _wasEarlyCallStatus(SipCallUiStatus status) {
    return status == SipCallUiStatus.incoming ||
        status == SipCallUiStatus.calling ||
        status == SipCallUiStatus.ringing;
  }

  bool _shouldIgnoreLateAudioSessionEvent({
    required String? callState,
    required String? reason,
  }) {
    final eventStatus = _mapNativeCallStateToUiStatus(callState);
    final currentStatus = _state.callStatus;
    final terminalAt = _lastTerminalNativeCallAt;
    final hasRecentTerminal = terminalAt != null &&
        DateTime.now().difference(terminalAt) <= const Duration(seconds: 5);

    if (_isActiveUiCallStatus(currentStatus) &&
        _isTerminalUiCallStatus(eventStatus)) {
      return true;
    }

    if (_isTerminalUiCallStatus(currentStatus) &&
        hasRecentTerminal &&
        (reason == 'override' || reason == 'category_change')) {
      return true;
    }

    return false;
  }

  bool _isActiveUiCallStatus(SipCallUiStatus status) {
    return status == SipCallUiStatus.incoming ||
        status == SipCallUiStatus.calling ||
        status == SipCallUiStatus.ringing ||
        status == SipCallUiStatus.inCall;
  }

  void _handleNativeCallActionEvent(Map<String, dynamic> payload) {
    _trackIosSystemCall(
      callUUID: payload['callUUID']?.toString(),
      stateHint: payload['action']?.toString(),
    );
    _queueIosCallAction(payload);
    _applyPendingIosCallActionsIfPossible();

    debugPrint(
      'SipService native call action event -> action=${payload['action']}, callUUID=${payload['callUUID']}, remote=${payload['remoteIdentity']}',
    );
  }

  void _handleNativeAudioSessionEvent(Map<String, dynamic> payload) {
    final state = payload['state']?.toString();
    final output = payload['output']?.toString();
    final outputDeviceName = payload['outputDeviceName']?.toString();
    final speakerOn = payload['speakerOn'] as bool?;
    final reason = payload['reason']?.toString();
    final callState = payload['callState']?.toString();

    debugPrint(
      'SipService native audio session event -> state=$state, output=$output, speaker=$speakerOn, reason=$reason, callState=$callState',
    );

    if (_shouldIgnoreLateAudioSessionEvent(
      callState: callState,
      reason: reason,
    )) {
      debugPrint(
        'SipService late audio session event ignored -> state=$state, output=$output, reason=$reason, callState=$callState, currentCallStatus=${_state.callStatus}',
      );
      return;
    }

    if (speakerOn != null || output != null) {
      if (output != null && output.trim().isNotEmpty) {
        _currentAudioRouteType = _normalizeAudioRouteType(output);
      }
      if (outputDeviceName != null && outputDeviceName.trim().isNotEmpty) {
        _currentAudioRouteName = outputDeviceName.trim();
      }
      final resolvedSpeakerOn = _state.callStatus == SipCallUiStatus.ended ||
              _state.callStatus == SipCallUiStatus.failed ||
              _state.callStatus == SipCallUiStatus.idle
          ? false
          : (speakerOn ?? (output == 'speaker'));
      debugPrint(
        'SipService native audio session resolved -> previous=${_state.isSpeakerOn}, resolved=$resolvedSpeakerOn, output=$output, callStatus=${_state.callStatus}',
      );
      _state = _state.copyWith(isSpeakerOn: resolvedSpeakerOn);
      _notifyListenersSafely();
    }
  }

  String _normalizeAudioRouteType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('bluetooth') || normalized.contains('hearingaid')) {
      return 'bluetooth';
    }
    if (normalized.contains('speaker')) return 'speaker';
    if (normalized.contains('earpiece') || normalized.contains('telephony')) {
      return 'earpiece';
    }
    if (normalized.contains('headset') ||
        normalized.contains('headphone') ||
        normalized.contains('aux') ||
        normalized.contains('usb')) {
      return 'headset';
    }
    return normalized;
  }

  void _handlePendingIosCallActionsEvent(Map<String, dynamic> payload) {
    final actions = payload['actions'];
    if (actions is! List) {
      return;
    }

    for (final item in actions) {
      if (item is Map) {
        _queueIosCallAction(Map<String, dynamic>.from(item));
      }
    }

    _applyPendingIosCallActionsIfPossible();
  }

  void _queueIosCallAction(Map<String, dynamic> payload) {
    if (!Platform.isIOS) {
      return;
    }

    final action = payload['action']?.toString();
    if (action == null || action.isEmpty) {
      return;
    }

    final normalized = <String, dynamic>{
      'action': action,
      'callUUID': payload['callUUID']?.toString(),
      'callId': payload['callId']?.toString(),
      'remoteIdentity': payload['remoteIdentity']?.toString(),
      'callerName': payload['callerName']?.toString(),
      'fromUri': payload['fromUri']?.toString(),
      'toUri': payload['toUri']?.toString(),
      'sipUri': payload['sipUri']?.toString(),
      'timestamp': payload['timestamp'] is num
          ? (payload['timestamp'] as num).toDouble()
          : DateTime.now().millisecondsSinceEpoch / 1000.0,
    };

    final existingIndex = _pendingIosCallActions.indexWhere((existing) {
      return existing['action'] == normalized['action'] &&
          existing['callUUID'] == normalized['callUUID'];
    });

    if (existingIndex != -1) {
      _pendingIosCallActions[existingIndex] = normalized;
    } else {
      _pendingIosCallActions.add(normalized);
    }
  }

  void _applyPendingIosCallActionsIfPossible() {
    if (!Platform.isIOS || _pendingIosCallActions.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _pendingIosCallActions.removeWhere((action) {
      final timestamp = action['timestamp'] as double? ?? now;
      return now - timestamp > 120;
    });

    if (_pendingIosCallActions.isEmpty) {
      return;
    }

    final pending = List<Map<String, dynamic>>.from(_pendingIosCallActions)
      ..sort((left, right) {
        final leftTimestamp = left['timestamp'] as double? ?? now;
        final rightTimestamp = right['timestamp'] as double? ?? now;
        return leftTimestamp.compareTo(rightTimestamp);
      });
    for (final action in pending) {
      if (_tryApplyIosCallAction(action)) {
        _pendingIosCallActions.remove(action);
      }
    }
  }

  bool _tryApplyIosCallAction(Map<String, dynamic> action) {
    final actionName = action['action']?.toString();
    if (actionName == null || actionName.isEmpty) {
      return true;
    }

    final usesNativeIosSip = Platform.isIOS && _shouldUseNativeSip();

    // CallKit actions are already executed synchronously by
    // IOSNativeSipManager before this informational event reaches Flutter.
    // Replaying them here used to call acceptCall a second time and could
    // refresh REGISTER while the real INVITE was still in flight.
    if (usesNativeIosSip) {
      return true;
    }

    switch (actionName) {
      case 'answer':
        if (_state.callStatus == SipCallUiStatus.inCall) {
          return true;
        }
        if (_activeCall != null &&
            _state.callStatus == SipCallUiStatus.incoming) {
          unawaited(acceptCall());
          return true;
        }
        _ensureIosSipSessionRecovery('system-answer');
        return false;
      case 'decline':
        if (_activeCall != null &&
            _state.callStatus == SipCallUiStatus.incoming) {
          unawaited(decline());
          return true;
        }
        return _state.callStatus == SipCallUiStatus.ended ||
            _state.callStatus == SipCallUiStatus.failed ||
            _state.callStatus == SipCallUiStatus.idle;
      case 'end':
        if (_activeCall != null) {
          unawaited(hangup());
          return true;
        }
        return _state.callStatus == SipCallUiStatus.ended ||
            _state.callStatus == SipCallUiStatus.failed ||
            _state.callStatus == SipCallUiStatus.idle;
      default:
        return true;
    }
  }

  void _ensureIosSipSessionRecovery(String reason) {
    if (!Platform.isIOS ||
        !_networkAvailable ||
        !_hasSipCredentials() ||
        !_persistentSipEnabled) {
      return;
    }

    if (_state.registrationStatus == SipRegistrationUiStatus.registered ||
        _state.registrationStatus == SipRegistrationUiStatus.registering ||
        _helper.connecting) {
      return;
    }

    debugPrint('SipService iOS recovery -> reason=$reason');
    _shouldStayConnected = true;

    if (_shouldUseNativeSip()) {
      unawaited(_restoreNativeRegistrationIfNeeded(reason));
      return;
    }

    unawaited(_startSipRegistration(clearError: false));
  }

  void _trackIosSystemCall({
    required String? callUUID,
    required String? stateHint,
  }) {
    if (!Platform.isIOS) {
      return;
    }

    final normalizedUuid = callUUID?.trim();
    if (normalizedUuid != null && normalizedUuid.isNotEmpty) {
      _iosSystemCallUUID = normalizedUuid;
    }

    switch (stateHint) {
      case 'incoming':
      case 'ringing':
      case 'calling':
      case 'answer':
        _iosSystemCallConnectedReported = false;
        break;
      case 'ended':
      case 'failed':
      case 'idle':
      case 'decline':
      case 'end':
        _iosSystemCallUUID = null;
        _iosSystemCallConnectedReported = false;
        break;
      default:
        break;
    }
  }

  Future<void> _reportIosSystemCallConnectedIfNeeded() async {
    if (!Platform.isIOS ||
        _iosSystemCallUUID == null ||
        _iosSystemCallConnectedReported) {
      return;
    }

    final success = await _invokeNativeSipMethod<bool>(
      'reportCallConnected',
      <String, dynamic>{'callUUID': _iosSystemCallUUID},
    );

    if (success == true) {
      _iosSystemCallConnectedReported = true;
    }
  }

  Future<void> _reportIosSystemCallEndedIfNeeded(String reason) async {
    if (!Platform.isIOS || _iosSystemCallUUID == null) {
      return;
    }

    final callUUID = _iosSystemCallUUID;
    _iosSystemCallUUID = null;
    _iosSystemCallConnectedReported = false;
    await _invokeNativeSipMethod<bool>(
      'reportCallEnded',
      <String, dynamic>{
        'callUUID': callUUID,
        'reason': reason,
      },
    );
  }

  void _applyNativeSnapshot(
    Map<String, dynamic> snapshot, {
    bool notify = false,
  }) {
    _persistentSipEnabled = snapshot['persistentEnabled'] == true;

    final registrationState =
        snapshot['registrationState']?.toString() ?? 'disconnected';
    final callState = snapshot['callState']?.toString() ?? 'idle';
    final remoteIdentity =
        _normalizeRemoteIdentity(snapshot['remoteIdentity']?.toString());
    final message = snapshot['message']?.toString();
    final muted = snapshot['muted'] as bool? ?? false;
    final speakerOn = snapshot['speakerOn'] as bool? ?? false;
    final callUUID = snapshot['callUUID']?.toString();
    final callId = snapshot['callId']?.toString();

    _trackIosSystemCall(callUUID: callUUID, stateHint: callState);

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
    final resolvedRegistration = _isActiveUiCallStatus(mappedCall)
        ? SipRegistrationUiStatus.registered
        : mappedRegistration;

    if (mappedCall == SipCallUiStatus.inCall) {
      _currentCallStartedAt ??= DateTime.now();
    } else if (mappedCall == SipCallUiStatus.idle ||
        mappedCall == SipCallUiStatus.ended ||
        mappedCall == SipCallUiStatus.failed) {
      _currentCallStartedAt = null;
    }

    if (mappedCall == SipCallUiStatus.incoming) {
      _rememberIncomingFingerprint(
        callUUID: callUUID,
        callId: callId,
        remoteIdentity: remoteIdentity,
      );
      _rememberActiveNativeCallFingerprint(
        callUUID: callUUID,
        callId: callId,
        remoteIdentity: remoteIdentity,
      );
    } else if (mappedCall == SipCallUiStatus.calling ||
        mappedCall == SipCallUiStatus.ringing ||
        mappedCall == SipCallUiStatus.inCall) {
      _rememberActiveNativeCallFingerprint(
        callUUID: callUUID,
        callId: callId,
        remoteIdentity: remoteIdentity,
      );
    } else if (_isTerminalUiCallStatus(mappedCall)) {
      _clearIncomingFingerprint();
      _markTerminalNativeCallFingerprint();
    }

    if (_persistentSipEnabled &&
        (mappedRegistration == SipRegistrationUiStatus.registered ||
            mappedRegistration == SipRegistrationUiStatus.registering)) {
      _shouldStayConnected = true;
    }

    final resolvedSpeakerOn = mappedCall == SipCallUiStatus.ended ||
            mappedCall == SipCallUiStatus.failed ||
            mappedCall == SipCallUiStatus.idle
        ? false
        : speakerOn;
    final resolvedMessage = _sanitizeRegistrationMessage(
      message,
      registrationStatus: resolvedRegistration,
    );
    debugPrint(
      'SipService applyNativeSnapshot -> callState=$callState, mappedCall=$mappedCall, snapshotSpeaker=$speakerOn, resolvedSpeaker=$resolvedSpeakerOn',
    );

    _state = _state.copyWith(
      registrationStatus: resolvedRegistration,
      callStatus: mappedCall,
      errorMessage: resolvedMessage,
      remoteIdentity: remoteIdentity,
      isMuted: muted,
      isSpeakerOn: resolvedSpeakerOn,
      clearRemoteIdentity:
          remoteIdentity == null || remoteIdentity.trim().isEmpty,
    );

    if (notify) {
      _notifyListenersSafely();
    }
  }

  void _handleNativeRegistrationEvent(Map<String, dynamic> payload) {
    final nativeState = payload['state']?.toString() ?? 'disconnected';
    final message = payload['message']?.toString();
    debugPrint(
      'SipService native registration event -> state=$nativeState, message=$message',
    );
    if (nativeState == 'registering' &&
        _state.registrationStatus == SipRegistrationUiStatus.registered) {
      // Linphone emits Progress/Refresh registration during its periodic
      // REGISTER renewal. The existing registration remains usable while the
      // refresh is in flight, so do not flash "Подключение..." in the UI.
      unawaited(recordUiDiagnostic(
        'REGISTRATION_REFRESH_HIDDEN',
        <String, Object?>{
          'native_state': nativeState,
          'ui_state': _state.registrationStatus.name,
          'message': message,
        },
      ));
      return;
    }
    if (_isActiveUiCallStatus(_state.callStatus) &&
        nativeState != 'registered') {
      unawaited(recordUiDiagnostic(
        'REGISTRATION_EVENT_DEFERRED_DURING_CALL',
        <String, Object?>{
          'native_state': nativeState,
          'call_state': _state.callStatus.name,
          'message': message,
        },
      ));
      return;
    }

    switch (nativeState) {
      case 'registering':
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.registering,
          errorMessage: _sanitizeRegistrationMessage(
            message,
            registrationStatus: SipRegistrationUiStatus.registering,
          ),
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
        if (_shouldIgnoreTransientAuthorizationChallenge(message)) {
          debugPrint(
            'SipService native registration transient auth challenge ignored -> message=$message',
          );
          _state = _state.copyWith(
            registrationStatus: SipRegistrationUiStatus.registering,
            clearError: true,
          );
          break;
        }
        if (_isAuthorizationFailureMessage(message)) {
          _stopReconnectOnAuthorizationFailure(
            'Авторизация телефонии отклонена сервером. Проверьте логин, пароль и auth ID.',
          );
          return;
        }
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.failed,
          errorMessage: message ?? 'Не удалось подключить телефонию',
        );
        if (_shouldStayConnected) {
          _scheduleReconnect('native-registration-failed');
        }
        break;
      case 'disconnected':
      default:
        final shouldClearMessage = message == 'Registration disabled' ||
            message == 'Unregistration done';
        if (_isActiveUiCallStatus(_state.callStatus)) {
          debugPrint(
            'SipService native registration disconnected while call is active -> preserving callStatus=${_state.callStatus}',
          );
          _state = _state.copyWith(
            registrationStatus: SipRegistrationUiStatus.disconnected,
            errorMessage: shouldClearMessage ? null : message,
            clearError: shouldClearMessage,
          );
        } else {
          _state = _state.copyWith(
            registrationStatus: SipRegistrationUiStatus.disconnected,
            callStatus: SipCallUiStatus.idle,
            errorMessage: shouldClearMessage ? null : message,
            clearError: shouldClearMessage,
            clearRemoteIdentity: true,
          );
        }
        if (_shouldStayConnected) {
          _scheduleReconnect('native-disconnected');
        }
        break;
    }

    _notifyListenersSafely();
  }

  String? _sanitizeRegistrationMessage(
    String? message, {
    required SipRegistrationUiStatus registrationStatus,
  }) {
    final trimmed = message?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.toLowerCase();
    final isInformationalSuccess = normalized == 'registration successful' ||
        normalized == 'registered' ||
        normalized == 'registration in progress' ||
        normalized == 'registration disabled' ||
        normalized == 'unregistration done';

    if (isInformationalSuccess &&
        registrationStatus != SipRegistrationUiStatus.failed) {
      return null;
    }

    return trimmed;
  }

  void _handleNativeCallEvent(Map<String, dynamic> payload) {
    final nativeState = payload['state']?.toString() ?? 'idle';
    final remoteIdentity =
        _normalizeRemoteIdentity(payload['remoteIdentity']?.toString());
    final message = payload['message']?.toString();
    final muted = payload['muted'] as bool?;
    final speakerOn = payload['speakerOn'] as bool?;
    final callUUID = payload['callUUID']?.toString();
    final callId = payload['callId']?.toString();

    _trackIosSystemCall(callUUID: callUUID, stateHint: nativeState);

    debugPrint(
      'SipService native call event -> state=$nativeState, remote=$remoteIdentity, message=$message, muted=$muted, speaker=$speakerOn',
    );

    if (_shouldIgnoreLateNativeCallEvent(
      nativeState: nativeState,
      callUUID: callUUID,
      callId: callId,
      remoteIdentity: remoteIdentity,
    )) {
      debugPrint(
        'SipService late native call event ignored -> state=$nativeState, callUUID=$callUUID, callId=$callId, remote=$remoteIdentity',
      );
      return;
    }

    final wasTerminal = _isTerminalUiCallStatus(_state.callStatus);
    final treatAsEnded = _isRemoteDeclineCause(message) ||
        _isElsewhereTerminationMessage(message);

    switch (nativeState) {
      case 'incoming':
        _currentCallDisplayName = null;
        if (_isDuplicateIncomingEvent(
          callUUID: callUUID,
          callId: callId,
          remoteIdentity: remoteIdentity,
        )) {
          debugPrint(
            'SipService duplicate incoming ignored -> callUUID=$callUUID, callId=$callId, remote=$remoteIdentity',
          );
          return;
        }
        _currentCallDirection = SipCallDirection.incoming;
        _currentCallTarget = remoteIdentity ?? _state.sipId;
        _currentCallStartedAt = null;
        _rememberActiveNativeCallFingerprint(
          callUUID: callUUID,
          callId: callId,
          remoteIdentity: remoteIdentity,
        );
        _rememberIncomingFingerprint(
          callUUID: callUUID,
          callId: callId,
          remoteIdentity: remoteIdentity,
        );
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.incoming,
          remoteIdentity: remoteIdentity,
          errorMessage: message,
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: speakerOn ?? _state.isSpeakerOn,
        );
        _ensureIosSipSessionRecovery('native-incoming');
        break;
      case 'calling':
        _currentCallDirection = SipCallDirection.outgoing;
        _rememberActiveNativeCallFingerprint(
          callUUID: callUUID,
          callId: callId,
          remoteIdentity: remoteIdentity,
        );
        debugPrint(
          'SipService applying calling state -> previousSpeaker=${_state.isSpeakerOn}, incomingSpeaker=$speakerOn',
        );
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.calling,
          remoteIdentity: remoteIdentity,
          clearError: true,
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: _state.isSpeakerOn,
        );
        break;
      case 'ringing':
        _rememberActiveNativeCallFingerprint(
          callUUID: callUUID,
          callId: callId,
          remoteIdentity: remoteIdentity,
        );
        debugPrint(
          'SipService applying ringing state -> previousSpeaker=${_state.isSpeakerOn}, incomingSpeaker=$speakerOn',
        );
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.ringing,
          remoteIdentity: remoteIdentity,
          clearError: true,
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: _state.isSpeakerOn,
        );
        break;
      case 'in_call':
        _currentCallStartedAt ??= DateTime.now();
        _clearIncomingFingerprint();
        _rememberActiveNativeCallFingerprint(
          callUUID: callUUID,
          callId: callId,
          remoteIdentity: remoteIdentity,
        );
        debugPrint(
          'SipService applying in_call state -> previousSpeaker=${_state.isSpeakerOn}, incomingSpeaker=$speakerOn',
        );
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.inCall,
          remoteIdentity: remoteIdentity,
          clearError: true,
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: speakerOn ?? _state.isSpeakerOn,
        );
        break;
      case 'failed':
        _clearIncomingFingerprint();
        _markTerminalNativeCallFingerprint();
        if (!(wasTerminal &&
            (_state.callStatus == SipCallUiStatus.failed || treatAsEnded))) {
          _appendCallLog(
            treatAsEnded ? SipCallUiStatus.ended : SipCallUiStatus.failed,
            endReason: message,
          );
        }
        _currentInviteUri = null;
        _state = _state.copyWith(
          callStatus:
              treatAsEnded ? SipCallUiStatus.ended : SipCallUiStatus.failed,
          errorMessage:
              treatAsEnded ? null : (message ?? 'Не удалось выполнить звонок'),
          clearError: treatAsEnded,
          clearRemoteIdentity: true,
          isMuted: false,
          isSpeakerOn: false,
        );
        break;
      case 'ended':
        _clearIncomingFingerprint();
        _markTerminalNativeCallFingerprint();
        if (!wasTerminal || _state.callStatus == SipCallUiStatus.inCall) {
          _appendCallLog(SipCallUiStatus.ended, endReason: message);
        }
        _currentInviteUri = null;
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.ended,
          errorMessage:
              _isElsewhereTerminationMessage(message) ? message : null,
          clearRemoteIdentity: true,
          clearError: !_isElsewhereTerminationMessage(message),
          isMuted: false,
          isSpeakerOn: false,
        );
        break;
      case 'idle':
        _clearIncomingFingerprint();
        _markTerminalNativeCallFingerprint();
      default:
        _state = _state.copyWith(
          isMuted: muted ?? _state.isMuted,
          isSpeakerOn: speakerOn ?? _state.isSpeakerOn,
        );
        break;
    }

    _applyPendingIosCallActionsIfPossible();
    _notifyListenersSafely();
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
    if (_isActiveUiCallStatus(_state.callStatus)) {
      _cancelReconnect();
      debugPrint(
        'SipService connectivity update deferred during active call -> online=$online, callState=${_state.callStatus.name}',
      );
      return;
    }
    if (!online) {
      _lastReconnectAttemptAt = null;
      _cancelReconnect();
      if (_state.registrationStatus == SipRegistrationUiStatus.registered ||
          _state.registrationStatus == SipRegistrationUiStatus.registering) {
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.failed,
          errorMessage: 'Network lost. Waiting for reconnection...',
        );
        _notifyListenersSafely();
      }
      return;
    }

    if (_shouldStayConnected) {
      if (_state.registrationStatus != SipRegistrationUiStatus.registered) {
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.registering,
          errorMessage: 'Сеть восстановлена. Переподключаем телефонию...',
        );
        _notifyListenersSafely();
      }
      if (_shouldUseNativeSip()) {
        unawaited(_restoreNativeRegistrationIfNeeded('network-restored'));
      }
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
    if (!_shouldStayConnected || !_networkAvailable || !_hasSipCredentials()) {
      return;
    }
    if (_isActiveUiCallStatus(_state.callStatus)) {
      return;
    }

    if (_shouldUseNativeSip()) {
      unawaited(_checkAndRecoverNativeRegistration(reason));
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

  Future<void> _checkAndRecoverNativeRegistration(String reason) async {
    if (!_shouldStayConnected || !_networkAvailable || !_hasSipCredentials()) {
      return;
    }
    if (_isActiveUiCallStatus(_state.callStatus)) {
      return;
    }

    await _restoreNativeRegistrationIfNeeded(reason);
    if (_state.registrationStatus == SipRegistrationUiStatus.registered ||
        _state.registrationStatus == SipRegistrationUiStatus.registering) {
      return;
    }

    _scheduleReconnect(reason);
  }

  void _scheduleReconnect(String reason,
      {Duration delay = const Duration(seconds: 2)}) {
    if (!_shouldStayConnected || !_networkAvailable || !_hasSipCredentials()) {
      return;
    }
    if (_isActiveUiCallStatus(_state.callStatus)) {
      return;
    }

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
      if (_isActiveUiCallStatus(_state.callStatus)) {
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
    var micStatus = await Permission.microphone.status;
    debugPrint(
        'SipService: microphone permission before request -> $micStatus');
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }
    debugPrint('SipService: microphone permission after request -> $micStatus');

    if (!micStatus.isGranted) {
      if (micStatus.isPermanentlyDenied || micStatus.isRestricted) {
        _setError(
          'Нет доступа к микрофону. Откройте настройки iPhone и разрешите микрофон для shamCRM.',
        );
        await openAppSettings();
      } else {
        _setError('Для звонка нужен доступ к микрофону.');
      }
      return false;
    }
    if (!includeCamera) {
      return true;
    }

    var camStatus = await Permission.camera.status;
    if (!camStatus.isGranted) {
      camStatus = await Permission.camera.request();
    }
    if (!camStatus.isGranted) {
      if (camStatus.isPermanentlyDenied || camStatus.isRestricted) {
        _setError(
          'Нет доступа к камере. Откройте настройки iPhone и разрешите камеру для shamCRM.',
        );
        await openAppSettings();
      } else {
        _setError('Для видеозвонка нужен доступ к камере.');
      }
      return false;
    }
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
    if (_renderersReady) {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    }
  }

  void _setError(String message) {
    debugPrint('SipService ERROR: $message');
    _state = _state.copyWith(
      errorMessage: message,
      registrationStatus: _state.registrationStatus,
      callStatus: _state.callStatus,
    );
    _notifyListenersSafely();
  }

  Future<void> _syncIncomingCallPushPreference(bool enabled) async {
    try {
      await _apiService.setSendIncomingCallPush(enabled);
      debugPrint(
        'SipService: send_incoming_call_push synced -> enabled=$enabled',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'SipService: failed to sync send_incoming_call_push=$enabled: $error',
      );
      debugPrint(
        'SipService: send_incoming_call_push sync stackTrace: $stackTrace',
      );
    }
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

    return 'Таймаут звонка для $target через $transport. Регистрация прошла, но вызов не получил ответа от сервера. Если Zoiper работает с тем же аккаунтом, проверьте SDP/ICE/DTLS/SAVPF или потерю INVITE по UDP.';
  }

  bool _isConnectionRefusedCause(Object? cause) {
    final message = cause?.toString().toLowerCase() ?? '';
    return message.contains('connection refused');
  }

  bool _isAuthorizationFailureMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return false;
    }

    return normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('authentication failed') ||
        normalized.contains('auth failed') ||
        normalized.contains('wrong password') ||
        normalized.contains('invalid password') ||
        normalized.contains('401') ||
        normalized.contains('403');
  }

  bool _isAuthorizationChallengeMessage(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return false;
    }

    return (normalized.contains('unauthorized') ||
            normalized.contains('401')) &&
        !normalized.contains('forbidden') &&
        !normalized.contains('403');
  }

  bool _shouldIgnoreTransientAuthorizationChallenge(String? message) {
    if (!_isAuthorizationChallengeMessage(message)) {
      return false;
    }

    final startedAt = _lastReconnectAttemptAt;
    if (startedAt == null) {
      return false;
    }

    return DateTime.now().difference(startedAt) <= const Duration(seconds: 8);
  }

  String _currentEndpointKey() {
    return _endpointKey(
      server: _state.server,
      transport: _state.transport,
      port: _state.port,
    );
  }

  String _endpointKey({
    required String server,
    required SipTransportUi transport,
    required int port,
  }) {
    final transportName = switch (transport) {
      SipTransportUi.ws => 'ws',
      SipTransportUi.tcp => 'tcp',
      SipTransportUi.udp => 'udp',
    };
    return '$transportName://${_extractDomain(server)}:$port';
  }

  String _connectionRefusedMessage() {
    final transport = switch (_state.transport) {
      SipTransportUi.ws => 'WS/WSS',
      SipTransportUi.tcp => 'TCP',
      SipTransportUi.udp => 'UDP',
    };
    final endpoint = '${_extractDomain(_state.server)}:${_state.port}';
    return '$transport соединение к $endpoint отклонено сервером. Проверьте, что АТС реально слушает $transport на этом порту. Для обычной телефонии на 5060 чаще всего нужен UDP.';
  }

  bool _shouldFallbackFromTcpToUdp() {
    return Platform.isIOS &&
        !_shouldUseNativeSip() &&
        _state.transport == SipTransportUi.tcp &&
        _state.port == 5060;
  }

  void _fallbackFromTcpToUdpAfterRefused() {
    debugPrint('SipService: TCP refused on iOS, retrying SIP over UDP 5060');
    _cancelReconnect();
    _stopKeepAlive();

    try {
      _helper.stop();
    } catch (_) {}

    _state = _state.copyWith(
      transport: SipTransportUi.udp,
      registrationStatus: SipRegistrationUiStatus.disconnected,
      clearError: true,
    );
    _hardTransportFailure = false;
    _hardTransportFailureEndpoint = null;
    unawaited(_storage.write(key: _transportKey, value: 'udp'));
    _notifyListenersSafely();

    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!_shouldStayConnected ||
          !_networkAvailable ||
          _state.transport != SipTransportUi.udp) {
        return;
      }
      unawaited(_startSipRegistration(clearError: false));
    });
  }

  void _stopReconnectOnHardTransportFailure(String message) {
    _shouldStayConnected = false;
    _persistentSipEnabled = false;
    _sipEnabled = false;
    _hardTransportFailure = true;
    _hardTransportFailureEndpoint = _currentEndpointKey();
    unawaited(_storage.write(key: _enabledKey, value: 'false'));
    _cancelReconnect();
    _stopKeepAlive();

    try {
      _helper.stop();
    } catch (_) {}

    _state = _state.copyWith(
      registrationStatus: SipRegistrationUiStatus.failed,
      callStatus: SipCallUiStatus.idle,
      errorMessage: message,
      clearRemoteIdentity: true,
    );
    _notifyListenersSafely();
  }

  void _stopReconnectOnAuthorizationFailure(String message) {
    _shouldStayConnected = false;
    _persistentSipEnabled = false;
    _sipEnabled = false;
    _cancelReconnect();
    _stopKeepAlive();
    unawaited(_storage.write(key: _enabledKey, value: 'false'));

    _state = _state.copyWith(
      registrationStatus: SipRegistrationUiStatus.failed,
      errorMessage: message,
      callStatus: SipCallUiStatus.idle,
      clearRemoteIdentity: true,
    );
    _notifyListenersSafely();
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    if (_shouldUseNativeSip()) return;
    debugPrint(
      'SipService: registrationStateChanged -> state=${state.state}, cause=${state.cause}',
    );
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        _persistentSipEnabled = true;
        _shouldStayConnected = true;
        _sipEnabled = true;
        unawaited(_storage.write(key: _enabledKey, value: 'true'));
        _state = _state.copyWith(
          registrationStatus: SipRegistrationUiStatus.registered,
          clearError: true,
        );
        _startKeepAlive();
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        if (_shouldIgnoreTransientAuthorizationChallenge(
          state.cause?.toString(),
        )) {
          _state = _state.copyWith(
            registrationStatus: SipRegistrationUiStatus.registering,
            clearError: true,
          );
          break;
        }
        if (_isAuthorizationFailureMessage(state.cause?.toString())) {
          _stopReconnectOnAuthorizationFailure(
            'Авторизация телефонии отклонена сервером. Проверьте логин, пароль и auth ID.',
          );
          break;
        }
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
          registrationStatus: _shouldStayConnected
              ? SipRegistrationUiStatus.registering
              : SipRegistrationUiStatus.disconnected,
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

    _notifyListenersSafely();
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    if (_shouldUseNativeSip()) return;
    final remoteIdentity = _normalizeRemoteIdentity(call.remote_identity);
    debugPrint(
      'SipService: callStateChanged -> state=${callState.state}, direction=${call.direction}, remote=$remoteIdentity, cause=${callState.cause}',
    );
    _activeCall = call;

    if (callState.state == CallStateEnum.STREAM) {
      final stream = callState.stream;
      if (stream != null && callState.originator == 'local') {
        _localStream = stream;
        if (_renderersReady) {
          localRenderer.srcObject = stream;
        }
      }
      if (stream != null && callState.originator == 'remote') {
        _remoteStream = stream;
        if (_renderersReady) {
          remoteRenderer.srcObject = stream;
        }
      }
    }

    final previousCallStatus = _state.callStatus;

    switch (callState.state) {
      case CallStateEnum.CALL_INITIATION:
        _currentCallDirection = call.direction == 'INCOMING'
            ? SipCallDirection.incoming
            : SipCallDirection.outgoing;
        if (call.direction == 'INCOMING') {
          _currentCallDisplayName = null;
        }
        _currentCallTarget = remoteIdentity ?? _state.sipId;
        _state = _state.copyWith(
          callStatus: call.direction == 'INCOMING'
              ? SipCallUiStatus.incoming
              : SipCallUiStatus.calling,
          remoteIdentity: remoteIdentity,
          clearError: true,
        );
        if (call.direction == 'INCOMING') {
          _applyPendingIosCallActionsIfPossible();
        }
        break;
      case CallStateEnum.CONNECTING:
      case CallStateEnum.PROGRESS:
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.ringing,
          remoteIdentity: remoteIdentity,
        );
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
      case CallStateEnum.STREAM:
        _currentCallStartedAt ??= DateTime.now();
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.inCall,
          remoteIdentity: remoteIdentity,
          clearError: true,
        );
        unawaited(_reportIosSystemCallConnectedIfNeeded());
        break;
      case CallStateEnum.MUTED:
        _state = _state.copyWith(isMuted: true);
        break;
      case CallStateEnum.UNMUTED:
        _state = _state.copyWith(isMuted: false);
        break;
      case CallStateEnum.ENDED:
        _releaseStreams();
        _appendCallLog(
          SipCallUiStatus.ended,
          endReason: callState.cause?.toString(),
        );
        _activeCall = null;
        _currentInviteUri = null;
        _state = _state.copyWith(
          callStatus: SipCallUiStatus.ended,
          clearRemoteIdentity: true,
          isMuted: false,
          isSpeakerOn: false,
        );
        unawaited(_reportIosSystemCallEndedIfNeeded('remoteEnded'));
        break;
      case CallStateEnum.FAILED:
        _releaseStreams();
        final rawError = callState.cause?.toString() ?? 'Call failed';
        final remotelyDeclined = _isRemoteDeclineCause(rawError) ||
            _wasEarlyCallStatus(previousCallStatus);
        _appendCallLog(
          remotelyDeclined ? SipCallUiStatus.ended : SipCallUiStatus.failed,
          endReason: rawError,
        );
        _activeCall = null;
        final errorMessage = rawError.contains('408')
            ? '${_timeoutDiagnosticMessage()} Cause: $rawError'
            : rawError;
        if (rawError.contains('408')) {
          debugPrint('SipService DIAGNOSTIC: ${_timeoutDiagnosticMessage()}');
        }
        _currentInviteUri = null;
        _state = _state.copyWith(
          callStatus:
              remotelyDeclined ? SipCallUiStatus.ended : SipCallUiStatus.failed,
          errorMessage: remotelyDeclined ? null : errorMessage,
          clearError: remotelyDeclined,
          clearRemoteIdentity: true,
          isMuted: false,
          isSpeakerOn: false,
        );
        unawaited(
          _reportIosSystemCallEndedIfNeeded(
            remotelyDeclined ? 'remoteEnded' : 'failed',
          ),
        );
        break;
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
      case CallStateEnum.REFER:
      case CallStateEnum.NONE:
        break;
    }

    _applyPendingIosCallActionsIfPossible();
    _notifyListenersSafely();
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
        if (_isConnectionRefusedCause(state.cause)) {
          if (_shouldFallbackFromTcpToUdp()) {
            _fallbackFromTcpToUdpAfterRefused();
            return;
          }
          _stopReconnectOnHardTransportFailure(_connectionRefusedMessage());
          return;
        }
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
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _helper.removeSipUaHelperListener(this);
    _helper.stop();
    _cancelReconnect();
    _stopKeepAlive();
    _registrationWatchdogTimer?.cancel();
    _connectivitySubscription?.cancel();
    _nativeSipEventsSubscription?.cancel();
    _releaseStreams();

    if (_renderersReady) {
      localRenderer.dispose();
      remoteRenderer.dispose();
      _renderersReady = false;
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldStayConnected) return;
    if (state == AppLifecycleState.resumed) {
      if (_shouldUseNativeSip()) {
        unawaited(_restoreNativeRegistrationIfNeeded('app-resumed'));
      } else {
        unawaited(_syncNativeSnapshot());
      }
      _checkAndRecoverRegistration('app-resumed');
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_shouldUseNativeSip()) {
        unawaited(_syncNativeSnapshot());
      }
    }
  }

  void _appendCallLog(SipCallUiStatus result, {String? endReason}) {
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
        id: 'local_${now.microsecondsSinceEpoch}',
        target: target,
        dialTarget: target,
        direction: _currentCallDirection,
        result: result,
        timestamp: now,
        duration: duration,
        endReason: endReason?.trim().isEmpty == true ? null : endReason?.trim(),
        isMissed: false,
      ),
      ..._state.callLogs,
    ];

    _state = _state.copyWith(callLogs: updated);
    _currentCallStartedAt = null;
    _currentCallTarget = null;
    _currentCallDisplayName = null;
    unawaited(refreshRecentCallLogs(force: true));
  }
}
