// import 'package:flutter/material.dart';
// import 'dart:async';
// import '../api/service/network_speed_service.dart';

// class SlowInternetBanner extends StatefulWidget {
//   const SlowInternetBanner({Key? key}) : super(key: key);

//   @override
//   State<SlowInternetBanner> createState() => _SlowInternetBannerState();
// }

// class _SlowInternetBannerState extends State<SlowInternetBanner> 
//     with SingleTickerProviderStateMixin {
//   final _speedService = NetworkSpeedService();
//   NetworkQuality _quality = NetworkQuality.excellent;
//   bool _isVisible = false;
//   bool _isDismissed = false; // ✅ Флаг закрытия вручную
  
//   late AnimationController _animationController;
//   late Animation<double> _slideAnimation;
  
//   StreamSubscription? _subscription;

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 400),
//       vsync: this,
//     );

//     _slideAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutCubic,
//     ));

//     _quality = _speedService.currentQuality;
//     _updateVisibility();

//     _subscription = _speedService.qualityStream.listen((quality) {
//       if (mounted) {
//         setState(() {
//           _quality = quality;
//         });
//         _updateVisibility();
//       }
//     });
//   }

//   void _updateVisibility() {
//     // ✅ Показываем только если медленно И не закрыто вручную
//     final shouldShow = _quality == NetworkQuality.slow && !_isDismissed;
    
//     if (shouldShow != _isVisible) {
//       setState(() {
//         _isVisible = shouldShow;
//       });
      
//       if (shouldShow) {
//         _animationController.forward();
//       } else {
//         _animationController.reverse();
//         // ✅ Сбрасываем флаг закрытия когда интернет восстановился
//         if (_quality != NetworkQuality.slow) {
//           _isDismissed = false;
//         }
//       }
//     }
//   }

//   void _dismiss() {
//     setState(() {
//       _isDismissed = true;
//       _isVisible = false;
//     });
//     _animationController.reverse();
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _slideAnimation,
//       builder: (context, child) {
//         if (_slideAnimation.value == 0.0) {
//           return const SizedBox.shrink();
//         }

//         return Transform.translate(
//           offset: Offset(0, -60 * (1 - _slideAnimation.value)),
//           child: Opacity(
//             opacity: _slideAnimation.value,
//             child: child,
//           ),
//         );
//       },
//       child: Material(
//         color: Colors.transparent,
//         child: Container(
//           margin: const EdgeInsets.only(top: 0), // ✅ Прямо сверху под статус-баром
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Color(0xFFFF9800),
//                 Color(0xFFFFA726),
//               ],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.15),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: SafeArea(
//             bottom: false,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: Row(
//                 children: [
//                   // ✅ Анимированная иконка
//                   TweenAnimationBuilder<double>(
//                     tween: Tween(begin: 0.0, end: 1.0),
//                     duration: const Duration(seconds: 2),
//                     builder: (context, value, child) {
//                       return Transform.rotate(
//                         angle: value * 6.28, // 360 градусов
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.25),
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.signal_wifi_bad,
//                             color: Colors.white,
//                             size: 22,
//                           ),
//                         ),
//                       );
//                     },
//                     onEnd: () {
//                       if (mounted) setState(() {});
//                     },
//                   ),
                  
//                   const SizedBox(width: 14),
                  
//                   // ✅ Текст
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Text(
//                           'Медленное соединение',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             fontFamily: 'Gilroy',
//                             letterSpacing: 0.3,
//                           ),
//                         ),
//                         const SizedBox(height: 3),
//                         Text(
//                           'Некоторые функции могут работать медленнее',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.white.withOpacity(0.95),
//                             fontFamily: 'Golos',
//                             height: 1.3,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
                  
//                   const SizedBox(width: 8),
                  
//                   // ✅ Кнопка закрытия
//                   Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       onTap: _dismiss,
//                       borderRadius: BorderRadius.circular(20),
//                       child: Container(
//                         padding: const EdgeInsets.all(6),
//                         child: const Icon(
//                           Icons.close,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }