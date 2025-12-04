// import 'dart:async';
// import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/widgets.dart';

// /// 🌐 Улучшенный сервис мониторинга интернета
// /// 
// /// Исправлены проблемы:
// /// ✅ Увеличены таймауты для мобильных сетей
// /// ✅ Умная дебаунс-логика для предотвращения ложных срабатываний
// /// ✅ Раздельная логика для iOS/Android
// /// ✅ HTTP-проверка вместо Socket (надежнее)
// /// ✅ Exponential backoff для повторных проверок
// class InternetMonitorService with WidgetsBindingObserver {
//   static final InternetMonitorService _instance = InternetMonitorService._internal();
//   factory InternetMonitorService() => _instance;
//   InternetMonitorService._internal();

//   final _internetStatusController = StreamController<bool>.broadcast();
//   Stream<bool> get internetStatus => _internetStatusController.stream;

//   bool _isConnected = true;
//   bool get isConnected => _isConnected;

//   Timer? _checkTimer;
//   Timer? _debounceTimer; // ✅ НОВОЕ: Дебаунс таймер
//   StreamSubscription? _connectivitySubscription;
  
//   bool _isAppInForeground = true;
//   bool _isChecking = false; // ✅ НОВОЕ: Флаг активной проверки

//   // ✅ ИЗМЕНЕНО: HTTP endpoints вместо raw sockets
//   final List<String> _checkUrls = [
//     'https://www.google.com/generate_204',  // Google Captive Portal (самый быстрый)
//     'https://connectivitycheck.gstatic.com/generate_204', // Google CDN
//     'https://www.cloudflare.com/cdn-cgi/trace', // Cloudflare
//   ];

//   // ✅ НОВОЕ: Exponential backoff для retry
//   int _failureCount = 0;
//   static const int _maxRetries = 3;
//   static const Duration _baseRetryDelay = Duration(seconds: 2);

//   /// Инициализация мониторинга
//   Future<void> initialize() async {
//     debugPrint('🌐 InternetMonitor: Инициализация...');
    
//     WidgetsBinding.instance.addObserver(this);
    
//     // ✅ ПЕРВАЯ проверка с retry
//     _isConnected = await _checkWithRetry();
//     _internetStatusController.add(_isConnected);

//     // ✅ Подписка на connectivity с дебаунсом
//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
//       (List<ConnectivityResult> results) {
//         debugPrint('🌐 InternetMonitor: Connectivity изменился: $results');
        
//         if (_isAppInForeground) {
//           // ✅ НЕ проверяем сразу - ждем 2 секунды (дебаунс)
//           _scheduleDebounceCheck();
//         }
//       },
//     );

//     // ✅ ИЗМЕНЕНО: Более редкие проверки (каждые 15 секунд)
//     _startPeriodicChecks();

//     debugPrint('🌐 InternetMonitor: Инициализирован успешно');
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     debugPrint('🌐 InternetMonitor: App lifecycle changed to $state');
    
//     if (state == AppLifecycleState.resumed) {
//       _isAppInForeground = true;
//       debugPrint('🌐 InternetMonitor: Приложение resumed - жду 3 сек перед проверкой');
      
//       // ✅ КРИТИЧНО: Ждем 3 секунды перед проверкой (iOS нужно время на восстановление сокетов)
//       Future.delayed(const Duration(seconds: 3), () {
//         if (_isAppInForeground) {
//           _checkInternetConnection();
//         }
//       });
      
//       _startPeriodicChecks();
      
//     } else if (state == AppLifecycleState.paused || 
//                state == AppLifecycleState.inactive) {
//       _isAppInForeground = false;
//       debugPrint('🌐 InternetMonitor: Приложение paused - останавливаем проверки');
//       _stopPeriodicChecks();
//       _failureCount = 0; // Сброс счетчика
//     }
//   }

//   // ✅ НОВОЕ: Дебаунс-проверка (избегаем множественных вызовов)
//   void _scheduleDebounceCheck() {
//     _debounceTimer?.cancel();
    
//     _debounceTimer = Timer(const Duration(seconds: 2), () {
//       if (_isAppInForeground) {
//         _checkInternetConnection();
//       }
//     });
//   }

//   void _startPeriodicChecks() {
//     _stopPeriodicChecks();
    
//     // ✅ ИЗМЕНЕНО: 15 секунд вместо 5 (меньше нагрузки)
//     _checkTimer = Timer.periodic(
//       const Duration(seconds: 15),
//       (_) {
//         if (_isAppInForeground && !_isChecking) {
//           _checkInternetConnection();
//         }
//       },
//     );
//   }

//   void _stopPeriodicChecks() {
//     _checkTimer?.cancel();
//     _checkTimer = null;
//     _debounceTimer?.cancel();
//     _debounceTimer = null;
//   }

//   // ✅ НОВОЕ: Проверка с retry логикой
//   Future<bool> _checkWithRetry() async {
//     for (int attempt = 0; attempt < _maxRetries; attempt++) {
//       final result = await _checkInternetConnectionInternal();
      
//       if (result) {
//         _failureCount = 0;
//         return true;
//       }
      
//       // Exponential backoff: 2s, 4s, 8s
//       if (attempt < _maxRetries - 1) {
//         final delay = _baseRetryDelay * (1 << attempt);
//         debugPrint('🌐 InternetMonitor: Retry ${attempt + 1}/$_maxRetries через ${delay.inSeconds}s');
//         await Future.delayed(delay);
//       }
//     }
    
//     _failureCount++;
//     return false;
//   }

//   /// Реальная проверка доступности интернета
//   Future<void> _checkInternetConnection() async {
//     if (!_isAppInForeground || _isChecking) {
//       return;
//     }

//     _isChecking = true;
    
//     try {
//       final hasConnection = await _checkWithRetry();

//       // ✅ ИЗМЕНЕНО: Обновляем статус только если уверены в изменении
//       if (_isConnected != hasConnection) {
//         // ✅ Дополнительная проверка через 1 секунду для уверенности
//         await Future.delayed(const Duration(seconds: 1));
//         final confirmCheck = await _checkInternetConnectionInternal();
        
//         if (hasConnection == confirmCheck) {
//           _isConnected = hasConnection;
//           _internetStatusController.add(_isConnected);
          
//           debugPrint('🌐 InternetMonitor: ✅ ПОДТВЕРЖДЕННОЕ изменение -> ${_isConnected ? "ПОДКЛЮЧЕН" : "ОТКЛЮЧЕН"}');
//         } else {
//           debugPrint('🌐 InternetMonitor: ⚠️ Противоречивые результаты - игнорируем');
//         }
//       }
//     } finally {
//       _isChecking = false;
//     }
//   }

//   /// ✅ НОВОЕ: Внутренний метод проверки (HTTP вместо Socket)
//   Future<bool> _checkInternetConnectionInternal() async {
//     try {
//       // 1️⃣ Сначала проверяем connectivity (быстро)
//       final connectivityResults = await Connectivity()
//           .checkConnectivity()
//           .timeout(const Duration(seconds: 3));
      
//       if (connectivityResults.contains(ConnectivityResult.none)) {
//         debugPrint('🌐 InternetMonitor: Connectivity = none');
//         return false;
//       }

//       // 2️⃣ Реальная HTTP-проверка
//       return await _httpCheck();
      
//     } catch (e) {
//       debugPrint('🌐 InternetMonitor: ❌ Ошибка проверки: $e');
//       return false;
//     }
//   }

//   /// ✅ НОВОЕ: HTTP-проверка (надежнее чем Socket)
//   Future<bool> _httpCheck() async {
//     final client = HttpClient();
    
//     // ✅ УВЕЛИЧЕНЫ таймауты для мобильных сетей
//     client.connectionTimeout = const Duration(seconds: 10); // было 5
    
//     try {
//       // Пробуем подключиться к первому доступному endpoint
//       for (final url in _checkUrls) {
//         try {
//           final uri = Uri.parse(url);
//           final request = await client
//               .getUrl(uri)
//               .timeout(const Duration(seconds: 10)); // было 5
          
//           final response = await request.close()
//               .timeout(const Duration(seconds: 10)); // было 5
          
//           // 204 No Content = успешное подключение
//           if (response.statusCode == 204 || response.statusCode == 200) {
//             debugPrint('🌐 InternetMonitor: ✅ HTTP успешен к $url');
//             client.close();
//             return true;
//           }
          
//         } catch (e) {
//           debugPrint('🌐 InternetMonitor: ⚠️ HTTP неудачен к $url: $e');
//           continue;
//         }
//       }
      
//       return false;
      
//     } finally {
//       client.close(force: true);
//     }
//   }

//   /// Ручная проверка (для использования в UI)
//   Future<bool> checkNow() async {
//     if (_isChecking) {
//       debugPrint('🌐 InternetMonitor: Проверка уже идет - пропуск');
//       return _isConnected;
//     }
    
//     await _checkInternetConnection();
//     return _isConnected;
//   }

//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _stopPeriodicChecks();
//     _connectivitySubscription?.cancel();
//     _internetStatusController.close();
//     debugPrint('🌐 InternetMonitor: Disposed');
//   }
// }