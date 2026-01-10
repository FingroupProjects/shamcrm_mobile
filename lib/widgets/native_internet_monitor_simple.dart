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
  bool _isAppInForeground = true;

  /// Инициализация мониторинга
  Future<void> initialize() async {
    debugPrint('🚀 NativeInternetMonitor: Инициализация...');
    
    WidgetsBinding.instance.addObserver(this);
    
    try {
      // ✅ Подписываемся на НАТИВНЫЕ события
      _nativeSubscription = _eventChannel
          .receiveBroadcastStream()
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
    
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
    } else if (state == AppLifecycleState.paused) {
      _isAppInForeground = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nativeSubscription?.cancel();
    _internetStatusController.close();
    debugPrint('🚀 NativeInternetMonitor: Disposed');
  }
}