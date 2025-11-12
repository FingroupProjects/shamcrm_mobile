// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/api/service/background_init_service.dart';
// import 'package:crm_task_manager/api/service/fast_startup_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:local_auth/local_auth.dart';
// import 'package:vibration/vibration.dart';

// /// Быстрый PIN экран - показывается МГНОВЕННО
// /// Вся тяжёлая инициализация происходит В ФОНЕ
// class FastPinScreen extends StatefulWidget {
//   final SessionData sessionData;

//   const FastPinScreen({Key? key, required this.sessionData}) : super(key: key);

//   @override
//   _FastPinScreenState createState() => _FastPinScreenState();
// }

// class _FastPinScreenState extends State<FastPinScreen> {
//   String _pin = '';
//   bool _isWrongPin = false;
//   bool _isInitialized = false;
  
//   final LocalAuthentication _auth = LocalAuthentication();

//   @override
//   void initState() {
//     super.initState();
    
//     // ✅ МГНОВЕННО ПОКАЗЫВАЕМ UI
//     // Вся инициализация в фоне
//     _initializeInBackground();
//   }

//   /// 🔥 ВСЯ ТЯЖЁЛАЯ РАБОТА ЗДЕСЬ - НЕ БЛОКИРУЕТ UI
//   Future<void> _initializeInBackground() async {
//     // ✅ Запускаем фоновую инициализацию
//     final backgroundInit = BackgroundInitService();
    
//     // Эти операции НЕ блокируют UI
//     backgroundInit.initializeFirebase();
//     backgroundInit.initializeFirebaseMessaging();
//     backgroundInit.checkForUpdates(context);
//     backgroundInit.requestTrackingPermission();
    
//     // Биометрия
//     _tryBiometricAuth();
    
//     setState(() {
//       _isInitialized = true;
//     });
//   }

//   Future<void> _tryBiometricAuth() async {
//     try {
//       final canCheck = await _auth.canCheckBiometrics;
//       if (!canCheck) return;
      
//       final availableBiometrics = await _auth.getAvailableBiometrics();
//       if (availableBiometrics.isEmpty) return;
      
//       final didAuthenticate = await _auth.authenticate(
//         localizedReason: 'Подтвердите вход',
//         options: const AuthenticationOptions(
//           biometricOnly: true,
//           stickyAuth: true,
//         ),
//       );
      
//       if (didAuthenticate && mounted) {
//         _navigateToHome();
//       }
//     } catch (e) {
//       // Игнорируем ошибки биометрии
//     }
//   }

//   void _onNumberPressed(String number) async {
//     if (_pin.length < 4) {
//       setState(() => _pin += number);
      
//       try {
//         if (await Vibration.hasVibrator() ?? false) {
//           Vibration.vibrate(duration: 50);
//         }
//       } catch (e) {}

//       if (_pin.length == 4) {
//         final prefs = await SharedPreferences.getInstance();
//         final savedPin = prefs.getString('user_pin');

//         if (_pin == savedPin) {
//           _navigateToHome();
//         } else {
//           _triggerErrorEffect();
//         }
//       }
//     }
//   }

//   void _triggerErrorEffect() async {
//     try {
//       if (await Vibration.hasVibrator() ?? false) {
//         Vibration.vibrate(duration: 200);
//       }
//     } catch (e) {}
    
//     setState(() {
//       _isWrongPin = true;
//       _pin = '';
//     });

//     await Future.delayed(const Duration(milliseconds: 200));
//     if (mounted) {
//       setState(() => _isWrongPin = false);
//     }
//   }

//   void _navigateToHome() {
//     if (!mounted) return;
//     Navigator.of(context).pushReplacementNamed('/home');
//   }

//   void _onDelete() {
//     if (_pin.isNotEmpty) {
//       setState(() {
//         _pin = _pin.substring(0, _pin.length - 1);
//         _isWrongPin = false;
//       });
//     }
//   }

//   String _getGreeting() {
//     final hour = DateTime.now().hour;
//     final name = widget.sessionData.userName;
    
//     if (hour >= 5 && hour < 11) return 'Доброе утро, $name!';
//     if (hour >= 11 && hour < 18) return 'Добрый день, $name!';
//     if (hour >= 18 && hour < 22) return 'Добрый вечер, $name!';
//     return 'Доброй ночи, $name!';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 30.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SizedBox(height: MediaQuery.of(context).size.height * 0.12),
              
//               // ✅ Логотип (из кэша, загружается мгновенно)
//               Image.asset('assets/icons/playstore.png', height: 150),
              
//               const SizedBox(height: 20),
              
//               // ✅ Приветствие (из кэша)
//               Text(
//                 _getGreeting(),
//                 style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
              
//               const SizedBox(height: 8),
              
//               Text(
//                 _isWrongPin ? 'Неверный PIN' : 'Введите PIN-код',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: _isWrongPin ? Colors.red : Colors.grey,
//                 ),
//               ),
              
//               const SizedBox(height: 24),
              
//               // ✅ PIN индикаторы
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(
//                   4,
//                   (index) => Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 8.0),
//                     width: 12,
//                     height: 12,
//                     decoration: BoxDecoration(
//                       color: _isWrongPin
//                           ? Colors.red
//                           : (index < _pin.length ? Colors.blue : Colors.grey.shade300),
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 24),
              
//               // ✅ Клавиатура
//               Expanded(
//                 child: GridView.count(
//                   crossAxisCount: 3,
//                   shrinkWrap: true,
//                   childAspectRatio: 1.5,
//                   children: [
//                     for (var i = 1; i <= 9; i++)
//                       TextButton(
//                         onPressed: () => _onNumberPressed(i.toString()),
//                         child: Text(
//                           i.toString(),
//                           style: const TextStyle(fontSize: 24, color: Colors.black),
//                         ),
//                       ),
//                     TextButton(
//                       onPressed: () => SystemNavigator.pop(),
//                       child: const Text('Выход', style: TextStyle(fontSize: 16)),
//                     ),
//                     TextButton(
//                       onPressed: () => _onNumberPressed('0'),
//                       child: const Text('0', style: TextStyle(fontSize: 24)),
//                     ),
//                     TextButton(
//                       onPressed: _pin.isEmpty ? _tryBiometricAuth : _onDelete,
//                       child: Icon(
//                         _pin.isEmpty ? Icons.fingerprint : Icons.backspace_outlined,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }