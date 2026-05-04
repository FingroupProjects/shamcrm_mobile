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

  final _internetStatusController = StreamController<bool>.broadcast();
  Stream<bool> get internetStatus => _internetStatusController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  StreamSubscription? _nativeSubscription;
  bool _isInitialized = false;

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
    _isInitialized = true;

    debugPrint('🚀 NativeInternetMonitor: Инициализация...');
    
    WidgetsBinding.instance.addObserver(this);

    if (!_supportsNativeNetworkChannel) {
      debugPrint(
        '🚀 NativeInternetMonitor: native channel is not supported on this platform',
      );
      _isConnected = true;
      _internetStatusController.add(true);
      return;
    }
    
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
      _isConnected = true;
      _internetStatusController.add(true);
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
