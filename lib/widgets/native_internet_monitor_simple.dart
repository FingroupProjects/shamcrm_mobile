import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 🚀 НАТИВНЫЙ мониторинг интернета
/// Использует Platform Channels для связи с iOS/Android
class NativeInternetMonitor with WidgetsBindingObserver {
  static final NativeInternetMonitor _instance = NativeInternetMonitor._internal();
  factory NativeInternetMonitor() => _instance;
  NativeInternetMonitor._internal();

  // ✅ Event Channel для получения событий от нативного кода
  static const EventChannel _eventChannel = EventChannel('com.shamcrm/network_status');
  static const MethodChannel _methodChannel =
      MethodChannel('com.shamcrm/network_status/methods');

  final _internetStatusController = StreamController<bool>.broadcast();
  Stream<bool> get internetStatus => _internetStatusController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  StreamSubscription? _nativeSubscription;
  bool _isInitialized = false;
  bool _isObserverAttached = false;
  int _readyRetries = 0;

  bool get _supportsNativeNetworkChannel {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Инициализация мониторинга
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    debugPrint('🚀 NativeInternetMonitor: Инициализация...');

    if (!_isObserverAttached) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAttached = true;
    }

    if (!_supportsNativeNetworkChannel) {
      debugPrint(
        '🚀 NativeInternetMonitor: native channel is not supported on this platform',
      );
      _markInitializedAsConnected();
      return;
    }

    final nativeReady = await _isNativeChannelReady();
    if (!nativeReady) {
      if (_readyRetries < 5) {
        _readyRetries += 1;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return initialize();
      }

      debugPrint(
        '🚀 NativeInternetMonitor: native channel is not registered, fallback to connected state',
      );
      _markInitializedAsConnected();
      return;
    }

    _isInitialized = true;
    
    try {
      // ✅ Подписываемся на НАТИВНЫЕ события
      _nativeSubscription = _eventChannel
          .receiveBroadcastStream()
          .handleError((dynamic error) {
            if (error is MissingPluginException) {
              debugPrint(
                '🚀 NativeInternetMonitor: native stream is unavailable, fallback to connected state',
              );
              _isConnected = true;
              _internetStatusController.add(true);
              return;
            }

            throw error;
          })
          .listen(
            (dynamic isConnected) {
              if (isConnected is bool) {
                debugPrint('🚀 NativeInternetMonitor: Получено событие -> $isConnected');
                
                if (_isConnected != isConnected) {
                  _isConnected = isConnected;
                  _internetStatusController.add(_isConnected);
                  
                  debugPrint('🚀 NativeInternetMonitor: 🔔 Статус изменен -> ${_isConnected ? "✅ ПОДКЛЮЧЕН" : "❌ ОТКЛЮЧЕН"}');
                }
              }
            },
            onError: (dynamic error) {
              if (error is MissingPluginException) {
                debugPrint(
                  '🚀 NativeInternetMonitor: native stream missing, fallback to connected state',
                );
                _isConnected = true;
                _internetStatusController.add(true);
                return;
              }

              debugPrint('🚀 NativeInternetMonitor: ❌ Ошибка: $error');
            },
          );
      
      debugPrint('🚀 NativeInternetMonitor: ✅ Инициализирован успешно');
      
    } catch (e) {
      debugPrint('🚀 NativeInternetMonitor: ❌ Ошибка инициализации: $e');
      _markInitializedAsConnected();
    }
  }

  void _markInitializedAsConnected() {
    _isInitialized = true;
    _isConnected = true;
    _internetStatusController.add(true);
  }

  Future<bool> _isNativeChannelReady() async {
    try {
      final ready = await _methodChannel.invokeMethod<bool>('isReady');
      return ready == true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🚀 NativeInternetMonitor: App lifecycle -> $state');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nativeSubscription?.cancel();
    _internetStatusController.close();
    debugPrint('🚀 NativeInternetMonitor: Disposed');
  }
}
