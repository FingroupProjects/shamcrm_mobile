import 'dart:io' show Platform;
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:flutter/scheduler.dart';
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
  static const String _voipPushTokenKey = 'sip_ios_voip_push_token';
  static const String _backgroundReliabilityPromptedKey =
      'sip_background_reliability_prompted_v2';
  static const String _fullScreenIntentPromptedKey =
      'sip_full_screen_intent_prompted_v1';
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
  ];
  static const MethodChannel _nativeSipMethodChannel =
      MethodChannel('com.shamcrm/native_sip/methods');
  static const EventChannel _nativeSipEventChannel =
      EventChannel('com.shamcrm/native_sip/events');

  final SIPUAHelper _helper = SIPUAHelper();
  final Connectivity _connectivity = Connectivity();
  final ApiService _apiService = ApiService();

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  SipUiState _state = SipUiState.initial();
  SipUiState get state => _state;

  bool _initialized = false;
  bool _disposed = false;
  bool _notifyPostFrameScheduled = false;
  bool _configLoaded = false;
  Completer<void>? _initializationCompleter;
  bool _renderersReady = false;
  bool get renderersReady => _renderersReady;
  bool get isConfigLoaded => _configLoaded;
  bool _sipScreenVisible = false;
  bool get isSipScreenVisible => _sipScreenVisible;
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
  String? _currentCallTarget;
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

      final server = await _readSecureStorageValue(
            _serverKey,
            fallback: '',
          ) ??
          '';
      final login = await _readSecureStorageValue(
            _loginKey,
            fallback: '',
          ) ??
          '';
      final password = await _readSecureStorageValue(
            _passwordKey,
            fallback: '',
          ) ??
          '';
      final sipId = await _readSecureStorageValue(
            _sipIdKey,
            fallback: '',
          ) ??
          '';
      final transportRaw = await _readSecureStorageValue(
            _transportKey,
            fallback: 'udp',
          ) ??
          'udp';
      final portRaw = await _readSecureStorageValue(
            _portKey,
            fallback: '5060',
          ) ??
          '5060';
      final enabledRaw = await _readSecureStorageValue(
            _enabledKey,
            fallback: 'false',
          ) ??
          'false';
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
      await _ensureRenderersInitializedForCurrentMode();
      await _initializeNativeSipBridge();
      await _syncNativeSnapshot();
      await _consumePendingIosCallActions();
      await _syncCurrentIosVoipPushTokenIfAvailable();
      if (Platform.isIOS) {
        await _apiService.sendPendingVoipTokenIfNeeded();
      }
      _startConnectivityMonitoring();
      _startRegistrationWatchdog();
      _configLoaded = true;
      unawaited(refreshRecentCallLogs(force: true));
      unawaited(_restorePersistentConnection());
      _notifyListenersSafely();
      completer.complete();
    } catch (error, stackTrace) {
      debugPrint('SipService.initialize failed: $error');
      debugPrint('SipService.initialize stackTrace: $stackTrace');
      _initialized = false;
      _configLoaded = true;
      _state = SipUiState.initial().copyWith(
        errorMessage:
            'Не удалось открыть сохраненные SIP-настройки. Проверьте данные и попробуйте снова.',
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
      return await _storage.read(key: key) ?? fallback;
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
        'Сохраненные SIP-настройки были повреждены и сброшены. Введите их заново.';

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
    if (_sipScreenVisible == visible) return;
    _sipScreenVisible = visible;
    if (visible) {
      unawaited(refreshRecentCallLogs());
    }
    _notifyListenersSafely();
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

    if (_shouldUseNativeSip()) {
      await _restoreNativeRegistrationIfNeeded('cold-start');
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
      await _nativeSipMethodChannel.invokeMethod('initialize');
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

  Future<void> _syncCurrentIosVoipPushTokenIfAvailable() async {
    if (!Platform.isIOS) {
      return;
    }

    final token = await getVoipPushToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await _syncIosVoipPushTokenWithBackend(token);
  }

  Future<void> _restoreNativeRegistrationIfNeeded(String reason) async {
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
    if (!Platform.isIOS) {
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
    if (!Platform.isIOS) {
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
      final canUseFullScreenIntent =
          await _invokeNativeSipMethod<bool>('canUseFullScreenIntent') ?? true;
      final promptedFullScreenIntent =
          await _storage.read(key: _fullScreenIntentPromptedKey);
      if (!canUseFullScreenIntent && promptedFullScreenIntent != 'true') {
        final opened = await _invokeNativeSipMethod<bool>(
              'requestFullScreenIntentPermission',
            ) ??
            false;
        if (opened) {
          await _storage.write(
            key: _fullScreenIntentPromptedKey,
            value: 'true',
          );
        }
      }

      final promptedBackgroundReliability =
          await _storage.read(key: _backgroundReliabilityPromptedKey);
      if (promptedBackgroundReliability != 'true') {
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

      final promptedXiaomiAutoStart =
          await _storage.read(key: _xiaomiAutoStartPromptedKey);
      if (promptedXiaomiAutoStart != 'true') {
        final opened =
            await _invokeNativeSipMethod<bool>('openXiaomiSettings') ?? false;
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
    if (!_hasSipCredentials()) {
      _setError('Заполните сервер, логин и пароль SIP.');
      return;
    }

    final validationError = _validateSipConfiguration();
    if (validationError != null) {
      _setError(validationError);
      return;
    }

    if (!_networkAvailable) {
      _setError('Нет интернета. Регистрация SIP приостановлена.');
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
    _logSipConfig('connect');
    await _startSipRegistration();
  }

  Future<void> _startSipRegistration({bool clearError = true}) async {
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
          errorMessage: 'Native SIP registration failed',
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
        errorMessage: 'SIP start failed: $error',
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

  Future<void> clearSavedCredentials() async {
    _shouldStayConnected = false;
    _persistentSipEnabled = false;
    _sipEnabled = false;
    _hardTransportFailure = false;
    _hardTransportFailureEndpoint = null;
    unawaited(_syncIncomingCallPushPreference(false));
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

    await _storage.delete(key: _serverKey);
    await _storage.delete(key: _loginKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _sipIdKey);
    await _storage.delete(key: _transportKey);
    await _storage.delete(key: _portKey);
    await _storage.delete(key: _enabledKey);

    _state = SipUiState.initial();
    _notifyListenersSafely();
  }

  bool get hasSavedCredentials => _hasSipCredentials();
  bool get isSipEnabled => _sipEnabled;

  Future<void> makeCall() async {
    await makeCallTo(_state.sipId);
  }

  Future<void> makeCallTo(String dialTarget) async {
    if (_state.registrationStatus != SipRegistrationUiStatus.registered) {
      _setError('SIP is not registered. Connect first.');
      return;
    }

    final normalizedTarget = dialTarget.trim();
    if (normalizedTarget.isEmpty) {
      _setError('sipId is empty.');
      return;
    }

    _currentCallDirection = SipCallDirection.outgoing;
    _currentCallTarget = normalizedTarget;
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
      _notifyListenersSafely();
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
    _notifyListenersSafely();
  }

  Future<void> toggleSpeaker() async {
    final targetSpeaker = !_state.isSpeakerOn;
    debugPrint(
      'SipService toggleSpeaker -> current=${_state.isSpeakerOn}, target=$targetSpeaker, callStatus=${_state.callStatus}',
    );
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
    debugPrint(
      'SipService toggleSpeaker local state applied -> isSpeakerOn=${_state.isSpeakerOn}',
    );
    _notifyListenersSafely();
  }

  Future<void> sendDtmf(String tone) async {
    final normalized = tone.trim();
    if (normalized.isEmpty) {
      return;
    }

    if (_shouldUseNativeSip()) {
      await _invokeNativeSipMethod<bool>('sendDtmf', {
        'tone': normalized,
      });
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
      return 'Сервер SIP не указан.';
    }

    final isWsAddress =
        server.startsWith('ws://') || server.startsWith('wss://');

    if (_state.transport == SipTransportUi.ws && !isWsAddress) {
      return 'Для WS/WSS нужен полный адрес `ws://` или `wss://`. Для обычной SIP-телефонии используйте UDP или TCP.';
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
  ]) async {
    if (!_isNativeSipPlatform()) {
      return null;
    }

    if (method != 'initialize' && !await _ensureNativeSipBridgeInitialized()) {
      return null;
    }

    try {
      return await _nativeSipMethodChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException catch (error) {
      _nativeSipBridgeAvailable = false;
      unawaited(_nativeSipEventsSubscription?.cancel());
      _nativeSipEventsSubscription = null;
      final message =
          'Native SIP bridge is not loaded in this build. Stop the app completely and rebuild it. Hot reload/hot restart does not load new native platform code. Details: $error';
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

    if (type == 'audio_session') {
      _handleNativeAudioSessionEvent(payload);
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
    unawaited(_syncIosVoipPushTokenWithBackend(normalizedToken));
  }

  void _handleNativePushTokenInvalidatedEvent() {
    debugPrint('SipService native push token invalidated');
    _lastSyncedIosVoipPushToken = null;
    unawaited(_storage.delete(key: _voipPushTokenKey));
    unawaited(_apiService.clearPendingVoipToken());
  }

  Future<void> _syncIosVoipPushTokenWithBackend(String token) async {
    if (!Platform.isIOS || token.trim().isEmpty) {
      return;
    }

    final normalizedToken = token.trim();
    if (_lastSyncedIosVoipPushToken == normalizedToken) {
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
    return normalized.isEmpty ? null : normalized;
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

    switch (actionName) {
      case 'answer':
        if (_state.callStatus == SipCallUiStatus.inCall) {
          return true;
        }
        if (usesNativeIosSip &&
            (_state.callStatus == SipCallUiStatus.incoming ||
                _state.callStatus == SipCallUiStatus.ringing)) {
          unawaited(acceptCall());
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
        if (usesNativeIosSip &&
            (_state.callStatus == SipCallUiStatus.incoming ||
                _state.callStatus == SipCallUiStatus.ringing)) {
          unawaited(decline());
          return true;
        }
        if (_activeCall != null &&
            _state.callStatus == SipCallUiStatus.incoming) {
          unawaited(decline());
          return true;
        }
        return _state.callStatus == SipCallUiStatus.ended ||
            _state.callStatus == SipCallUiStatus.failed ||
            _state.callStatus == SipCallUiStatus.idle;
      case 'end':
        if (usesNativeIosSip &&
            (_state.callStatus == SipCallUiStatus.calling ||
                _state.callStatus == SipCallUiStatus.ringing ||
                _state.callStatus == SipCallUiStatus.inCall)) {
          unawaited(hangup());
          return true;
        }
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
    final remoteIdentity = snapshot['remoteIdentity']?.toString();
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
      registrationStatus: mappedRegistration,
    );
    debugPrint(
      'SipService applyNativeSnapshot -> callState=$callState, mappedCall=$mappedCall, snapshotSpeaker=$speakerOn, resolvedSpeaker=$resolvedSpeakerOn',
    );

    _state = _state.copyWith(
      registrationStatus: mappedRegistration,
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
        if (Platform.isIOS) {
          unawaited(_syncCurrentIosVoipPushTokenIfAvailable());
          unawaited(_apiService.sendPendingVoipTokenIfNeeded());
        }
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
            'SIP авторизация отклонена сервером. Проверьте логин, пароль и auth ID.',
          );
          return;
        }
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
          errorMessage: message == 'Registration disabled' ||
                  message == 'Unregistration done'
              ? null
              : message,
          clearRemoteIdentity: true,
        );
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
              treatAsEnded ? null : (message ?? 'Native SIP call failed'),
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
          errorMessage: 'Network restored. Reconnecting SIP...',
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

    return 'Call timeout for $target over $transport. REGISTER succeeded, but INVITE got no SIP response. If Zoiper works with the same account, this usually means the provider accepts classic SIP/RTP, while this app is sending WebRTC-style SDP (ICE/DTLS/SAVPF), or the INVITE is being lost over UDP.';
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
    return '$transport соединение к $endpoint отклонено сервером. Проверьте, что АТС реально слушает $transport на этом порту. Для обычного SIP на 5060 чаще всего нужен UDP.';
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
            'SIP авторизация отклонена сервером. Проверьте логин, пароль и auth ID.',
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
    debugPrint(
      'SipService: callStateChanged -> state=${callState.state}, direction=${call.direction}, remote=${call.remote_identity}, cause=${callState.cause}',
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
        _currentCallTarget = call.remote_identity ?? _state.sipId;
        _state = _state.copyWith(
          callStatus: call.direction == 'INCOMING'
              ? SipCallUiStatus.incoming
              : SipCallUiStatus.calling,
          remoteIdentity: call.remote_identity,
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
      if (Platform.isIOS) {
        unawaited(_apiService.sendPendingVoipTokenIfNeeded());
      }
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
    unawaited(refreshRecentCallLogs(force: true));
  }
}
