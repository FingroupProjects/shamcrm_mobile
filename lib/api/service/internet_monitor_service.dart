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

  // Список надежных серверов для проверки
  final List<InternetAddress> _checkHosts = [
    InternetAddress('8.8.8.8', type: InternetAddressType.IPv4), // Google DNS
    InternetAddress('1.1.1.1', type: InternetAddressType.IPv4), // Cloudflare DNS
  ];

  /// Инициализация мониторинга
  Future<void> initialize() async {
    debugPrint('🌐 InternetMonitor: Инициализация...');
    
    // Первая проверка
    await _checkInternetConnection();

    // Подписка на изменения connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        debugPrint('🌐 InternetMonitor: Connectivity изменился: $results');
        _checkInternetConnection();
      },
    );

    // Периодическая проверка каждые 10 секунд
    _checkTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkInternetConnection(),
    );

    debugPrint('🌐 InternetMonitor: Инициализирован успешно');
  }

  /// Реальная проверка доступности интернета
  Future<void> _checkInternetConnection() async {
    bool hasConnection = false;

    try {
      // Проверяем connectivity
      final connectivityResults = await Connectivity().checkConnectivity();
      
      // Если нет connectivity вообще - сразу false
      if (connectivityResults.contains(ConnectivityResult.none)) {
        hasConnection = false;
      } else {
        // Есть connectivity - проверяем реальный интернет
        hasConnection = await _pingHosts();
      }
    } catch (e) {
      debugPrint('🌐 InternetMonitor: Ошибка проверки: $e');
      hasConnection = false;
    }

    // Обновляем статус только если изменился
    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _internetStatusController.add(_isConnected);
      
      debugPrint('🌐 InternetMonitor: Статус изменился -> ${_isConnected ? "ПОДКЛЮЧЕН ✅" : "ОТКЛЮЧЕН ❌"}');
    }
  }

  /// Проверка доступности хостов (ping)
  Future<bool> _pingHosts() async {
    for (final host in _checkHosts) {
      try {
        final result = await InternetAddress.lookup(host.address)
            .timeout(const Duration(seconds: 5));
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          // Дополнительная проверка через socket
          final socket = await Socket.connect(
            host.address,
            53, // DNS port
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