// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// enum NetworkQuality {
//   excellent,  // Отлично
//   good,       // Хорошо
//   slow,       // Медленно
//   none,       // Нет связи
// }

// class NetworkSpeedService {
//   static final NetworkSpeedService _instance = NetworkSpeedService._internal();
//   factory NetworkSpeedService() => _instance;
//   NetworkSpeedService._internal();

//   final _qualityController = StreamController<NetworkQuality>.broadcast();
//   Stream<NetworkQuality> get qualityStream => _qualityController.stream;

//   NetworkQuality _currentQuality = NetworkQuality.excellent;
//   NetworkQuality get currentQuality => _currentQuality;

//   Timer? _checkTimer;
//   bool _isChecking = false;

//   // ✅ ИСПРАВЛЕНО: Используем маленький тестовый файл
//   final String _testUrl = 'https://httpbin.org/bytes/50000'; // 50KB
  
//   // ✅ ИСПРАВЛЕНО: Более мягкие пороги
//   final int _slowPing = 500; // мс - если ping > 500ms = медленно
//   final double _slowSpeed = 0.2; // MB/s - если скорость < 0.2 MB/s = медленно

//   /// Инициализация проверки скорости
//   Future<void> initialize() async {
//     debugPrint('🚀 NetworkSpeed: Инициализация...');
    
//     // ✅ Первая проверка через 5 секунд (не сразу)
//     await Future.delayed(const Duration(seconds: 5));
//     await checkSpeed();
    
//     // ✅ Периодическая проверка каждые 60 секунд (не 30)
//     _checkTimer = Timer.periodic(
//       const Duration(seconds: 60),
//       (_) => checkSpeed(),
//     );
    
//     debugPrint('🚀 NetworkSpeed: Инициализирован');
//   }

//   /// Проверка скорости интернета
//   Future<NetworkQuality> checkSpeed() async {
//     if (_isChecking) return _currentQuality;
//     _isChecking = true;

//     try {
//       debugPrint('📊 NetworkSpeed: Начинаем проверку...');

//       // ШАГ 1: Проверяем ping
//       final pingResult = await _checkPing();
      
//       if (pingResult == null) {
//         debugPrint('❌ NetworkSpeed: Нет связи');
//         _updateQuality(NetworkQuality.none);
//         return NetworkQuality.none;
//       }

//       debugPrint('📊 NetworkSpeed: Ping = ${pingResult}ms');

//       // ШАГ 2: Проверяем скорость загрузки
//       final speedResult = await _checkDownloadSpeed();
      
//       if (speedResult != null) {
//         debugPrint('📊 NetworkSpeed: Скорость = ${speedResult.toStringAsFixed(2)} MB/s');
//       }

//       // ШАГ 3: Определяем качество
//       final quality = _determineQuality(pingResult, speedResult);
//       _updateQuality(quality);

//       return quality;
//     } catch (e) {
//       debugPrint('❌ NetworkSpeed: Ошибка проверки: $e');
//       // ✅ При ошибке считаем что всё нормально (не показываем баннер)
//       _updateQuality(NetworkQuality.good);
//       return NetworkQuality.good;
//     } finally {
//       _isChecking = false;
//     }
//   }

//   /// Проверка ping (время отклика)
//   Future<int?> _checkPing() async {
//     try {
//       final stopwatch = Stopwatch()..start();
      
//       final result = await InternetAddress.lookup('8.8.8.8')
//           .timeout(const Duration(seconds: 3));
      
//       stopwatch.stop();
      
//       if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
//         return stopwatch.elapsedMilliseconds;
//       }
      
//       return null;
//     } catch (e) {
//       debugPrint('❌ NetworkSpeed: Ping ошибка: $e');
//       return null;
//     }
//   }

//   /// Проверка скорости загрузки
//   Future<double?> _checkDownloadSpeed() async {
//     try {
//       final stopwatch = Stopwatch()..start();
      
//       final response = await http.get(
//         Uri.parse(_testUrl),
//       ).timeout(const Duration(seconds: 8));
      
//       stopwatch.stop();
      
//       if (response.statusCode == 200) {
//         final bytes = response.contentLength ?? response.bodyBytes.length;
//         final seconds = stopwatch.elapsedMilliseconds / 1000;
        
//         // ✅ Защита от деления на ноль
//         if (seconds == 0) return null;
        
//         final speedMBps = (bytes / 1024 / 1024) / seconds;
        
//         return speedMBps;
//       }
      
//       return null;
//     } catch (e) {
//       debugPrint('❌ NetworkSpeed: Скорость ошибка: $e');
//       return null;
//     }
//   }

//   /// Определение качества сети
//   NetworkQuality _determineQuality(int ping, double? speed) {
//     // ✅ ИСПРАВЛЕНО: Более умная логика
    
//     // Если ping очень большой ИЛИ скорость очень маленькая = МЕДЛЕННО
//     if (ping > _slowPing) {
//       debugPrint('🐌 NetworkSpeed: Медленно (ping: ${ping}ms)');
//       return NetworkQuality.slow;
//     }
    
//     if (speed != null && speed < _slowSpeed) {
//       debugPrint('🐌 NetworkSpeed: Медленно (скорость: ${speed.toStringAsFixed(2)} MB/s)');
//       return NetworkQuality.slow;
//     }

//     // ✅ Иначе всё хорошо
//     debugPrint('✅ NetworkSpeed: Хорошо');
//     return NetworkQuality.good;
//   }

//   /// Обновление качества
//   void _updateQuality(NetworkQuality quality) {
//     if (_currentQuality != quality) {
//       _currentQuality = quality;
//       _qualityController.add(quality);
      
//       final emoji = quality == NetworkQuality.excellent 
//           ? '🚀' 
//           : quality == NetworkQuality.good 
//               ? '✅' 
//               : quality == NetworkQuality.slow 
//                   ? '🐌' 
//                   : '❌';
      
//       debugPrint('$emoji NetworkSpeed: Качество изменилось -> $quality');
//     }
//   }

//   /// Очистка ресурсов
//   void dispose() {
//     _checkTimer?.cancel();
//     _qualityController.close();
//     debugPrint('🚀 NetworkSpeed: Disposed');
//   }
// }