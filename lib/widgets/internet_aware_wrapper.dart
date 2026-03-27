// import 'package:crm_task_manager/widgets/internet_overlay_widget.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import '../api/service/internet_monitor_service.dart';

// /// 🛡️ Обертка для отслеживания интернет-соединения
// /// 
// /// Улучшения:
// /// ✅ Защита от ложных срабатываний (grace period)
// /// ✅ Умная логика при resume приложения
// /// ✅ Дебаунс для предотвращения мерцания overlay
// /// ✅ Использует ваш красивый дизайн из internet_overlay_widget_localized.dart
// class InternetAwareWrapper extends StatefulWidget {
//   final Widget child;

//   const InternetAwareWrapper({
//     Key? key,
//     required this.child,
//   }) : super(key: key);

//   @override
//   State<InternetAwareWrapper> createState() => _InternetAwareWrapperState();
// }

// class _InternetAwareWrapperState extends State<InternetAwareWrapper> 
//     with WidgetsBindingObserver {
//   final _internetMonitor = InternetMonitorService();
  
//   bool _isConnected = true;
//   bool _showOverlay = false; // ✅ Отдельный флаг для UI
  
//   Timer? _graceTimer; // ✅ "Период прощения" перед показом overlay
//   DateTime? _lastDisconnectTime; // ✅ Время последнего отключения
  
//   // ✅ НАСТРОЙКИ - можете изменить под свои нужды
//   static const Duration _gracePeriod = Duration(seconds: 5); // 5 секунд перед показом
//   static const Duration _minDisconnectDuration = Duration(seconds: 3); // Минимум 3 секунды отключения

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeMonitoring();
//   }

//   @override
//   void dispose() {
//     _graceTimer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
    
//     if (state == AppLifecycleState.resumed) {
//       debugPrint('🌐 InternetAwareWrapper: Приложение resumed');
      
//       // ✅ НЕ показываем overlay сразу - ждем подтверждения от сервиса
//       _graceTimer?.cancel();
      
//       // ✅ КРИТИЧНО для iOS: Скрываем overlay при resume
//       if (_showOverlay) {
//         setState(() {
//           _showOverlay = false;
//         });
//         debugPrint('🌐 InternetAwareWrapper: Overlay скрыт при resume');
//       }
      
//     } else if (state == AppLifecycleState.paused) {
//       debugPrint('🌐 InternetAwareWrapper: Приложение paused');
//       _graceTimer?.cancel();
//     }
//   }

//   Future<void> _initializeMonitoring() async {
//     // ✅ Получаем начальный статус
//     _isConnected = _internetMonitor.isConnected;
//     debugPrint('🌐 InternetAwareWrapper: Начальный статус -> $_isConnected');

//     // ✅ Слушаем изменения с умной логикой
//     _internetMonitor.internetStatus.listen((isConnected) {
//       if (!mounted) return;
      
//       debugPrint('🌐 InternetAwareWrapper: Получен статус -> $isConnected (текущий: $_isConnected)');
      
//       if (_isConnected != isConnected) {
//         _isConnected = isConnected;
        
//         if (!isConnected) {
//           // ❌ Интернет пропал - запускаем grace period
//           _handleDisconnect();
//         } else {
//           // ✅ Интернет восстановлен - сразу скрываем overlay
//           _handleReconnect();
//         }
//       }
//     });
//   }

//   /// ❌ Обработка отключения интернета
//   void _handleDisconnect() {
//     _lastDisconnectTime = DateTime.now();
    
//     // ✅ Отменяем предыдущий таймер
//     _graceTimer?.cancel();
    
//     debugPrint('🌐 InternetAwareWrapper: ⚠️ Отключение обнаружено - жду ${_gracePeriod.inSeconds}s перед показом overlay...');
    
//     // ✅ НОВОЕ: Ждем N секунд перед показом overlay (защита от false positive)
//     _graceTimer = Timer(_gracePeriod, () {
//       if (!mounted) return;
      
//       // ✅ Проверяем, что отключение длится достаточно долго
//       if (_lastDisconnectTime != null) {
//         final disconnectDuration = DateTime.now().difference(_lastDisconnectTime!);
        
//         if (disconnectDuration >= _minDisconnectDuration && !_isConnected) {
//           debugPrint('🌐 InternetAwareWrapper: ❌ ПОКАЗЫВАЕМ OVERLAY (отключено ${disconnectDuration.inSeconds}s)');
          
//           setState(() {
//             _showOverlay = true;
//           });
//         } else {
//           debugPrint('🌐 InternetAwareWrapper: ℹ️ Отключение слишком короткое (${disconnectDuration.inSeconds}s) - игнорируем');
//         }
//       }
//     });
//   }

//   /// ✅ Обработка восстановления интернета
//   void _handleReconnect() {
//     _graceTimer?.cancel();
//     _lastDisconnectTime = null;
    
//     debugPrint('🌐 InternetAwareWrapper: ✅ Подключение восстановлено');
    
//     // ✅ Сразу скрываем overlay (без задержки)
//     if (_showOverlay) {
//       setState(() {
//         _showOverlay = false;
//       });
//       debugPrint('🌐 InternetAwareWrapper: Overlay скрыт');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // ✅ Основной контент приложения
//         widget.child,
        
//         // ✅ Ваш красивый overlay (показываем только когда нужно)
//         if (_showOverlay)
//           const Positioned.fill(
//             child: InternetOverlayWidget(), // ✅ ВАШ ДИЗАЙН
//           ),
//       ],
//     );
//   }
// }