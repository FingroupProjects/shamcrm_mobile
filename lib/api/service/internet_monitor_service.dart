import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class InternetMonitorService {
  static final InternetMonitorService _instance = InternetMonitorService._internal();
  factory InternetMonitorService() => _instance;
  InternetMonitorService._internal();

  final _internetStatusController = StreamController<bool>.broadcast();
  Stream<bool> get internetStatus => _internetStatusController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Timer? _checkTimer;
  StreamSubscription? _connectivitySubscription;

  final List<InternetAddress> _checkHosts = [
    InternetAddress('8.8.8.8', type: InternetAddressType.IPv4),
    InternetAddress('1.1.1.1', type: InternetAddressType.IPv4),
  ];

  /// Инициализация мониторинга
  Future<void> initialize() async {
    debugPrint('🌐 InternetMonitor: Инициализация...');
    
    // ✅ МГНОВЕННАЯ первая проверка
    _isConnected = await _checkInternetConnectionSync();
    _internetStatusController.add(_isConnected);

    // Подписка на изменения connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        debugPrint('🌐 InternetMonitor: Connectivity изменился: $results');
        _checkInternetConnection();
      },
    );

    // Периодическая проверка каждые 5 секунд
    _checkTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkInternetConnection(),
    );

    debugPrint('🌐 InternetMonitor: Инициализирован успешно');
  }

  /// Синхронная быстрая проверка (БЕЗ задержки)
  Future<bool> _checkInternetConnectionSync() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Быстрая проверка одного хоста
      try {
        final result = await InternetAddress.lookup('8.8.8.8')
            .timeout(const Duration(seconds: 2));
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('🌐 InternetMonitor: Ошибка быстрой проверки: $e');
      return false;
    }
  }

  /// Реальная проверка доступности интернета
  Future<void> _checkInternetConnection() async {
    bool hasConnection = false;

    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      
      if (connectivityResults.contains(ConnectivityResult.none)) {
        hasConnection = false;
      } else {
        hasConnection = await _pingHosts();
      }
    } catch (e) {
      debugPrint('🌐 InternetMonitor: Ошибка проверки: $e');
      hasConnection = false;
    }

    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _internetStatusController.add(_isConnected);
      
      debugPrint('🌐 InternetMonitor: Статус изменился -> ${_isConnected ? "ПОДКЛЮЧЕН ✅" : "ОТКЛЮЧЕН ❌"}');
    }
  }

  /// Проверка доступности хостов
  Future<bool> _pingHosts() async {
    for (final host in _checkHosts) {
      try {
        final result = await InternetAddress.lookup(host.address)
            .timeout(const Duration(seconds: 5));
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          final socket = await Socket.connect(
            host.address,
            53,
            timeout: const Duration(seconds: 5),
          );
          socket.destroy();
          
          debugPrint('🌐 InternetMonitor: Ping успешен к ${host.address}');
          return true;
        }
      } catch (e) {
        debugPrint('🌐 InternetMonitor: Ping неудачен к ${host.address}: $e');
        continue;
      }
    }
    
    return false;
  }

  /// Ручная проверка (можно вызвать из UI)
  Future<bool> checkNow() async {
    await _checkInternetConnection();
    return _isConnected;
  }

  /// Очистка ресурсов
  void dispose() {
    _checkTimer?.cancel();
    _connectivitySubscription?.cancel();
    _internetStatusController.close();
    debugPrint('🌐 InternetMonitor: Disposed');
  }
}