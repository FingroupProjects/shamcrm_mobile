// import 'package:flutter/material.dart';
// import '../screens/profile/languages/app_localizations.dart';
// import 'dart:math' as math;

// class InternetOverlayWidgetLocalized extends StatefulWidget {
//   const InternetOverlayWidgetLocalized({Key? key}) : super(key: key);

//   @override
//   State<InternetOverlayWidgetLocalized> createState() => _InternetOverlayWidgetLocalizedState();
// }

// class _InternetOverlayWidgetLocalizedState extends State<InternetOverlayWidgetLocalized>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 400),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
//     );

//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final localizations = AppLocalizations.of(context);
    
//     return WillPopScope(
//       onWillPop: () async => false,
//       child: Material(
//         color: Colors.transparent,
//         child: Stack(
//           children: [
//             FadeTransition(
//               opacity: _fadeAnimation,
//               child: Container(
//                 color: Colors.black.withOpacity(0.85),
//                 width: double.infinity,
//                 height: double.infinity,
//               ),
//             ),
//             Center(
//               child: ScaleTransition(
//                 scale: _scaleAnimation,
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 40),
//                     child: Container(
//                       padding: const EdgeInsets.all(32),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(24),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.3),
//                             blurRadius: 20,
//                             spreadRadius: 5,
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           _buildAnimatedIcon(),
//                           const SizedBox(height: 24),
//                           Text(
//                             localizations?.translate('no_internet_title') ?? 'Нет интернета',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.red[700],
//                               fontFamily: 'Gilroy',
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             localizations?.translate('no_internet_message') ?? 
//                             'Проверьте подключение к интернету\nи попробуйте снова',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey[700],
//                               fontFamily: 'Golos',
//                               height: 1.5,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 24),
//                           SizedBox(
//                             width: 40,
//                             height: 40,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 3,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]!),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             localizations?.translate('waiting_connection') ?? 'Ожидание подключения...',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                               fontFamily: 'Golos',
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAnimatedIcon() {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: const Duration(seconds: 2),
//       builder: (context, value, child) {
//         return Transform.rotate(
//           angle: value * 2 * math.pi,
//           child: Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: Colors.red[50],
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.wifi_off_rounded,
//               size: 48,
//               color: Colors.red[700],
//             ),
//           ),
//         );
//       },
//       onEnd: () {
//         if (mounted) setState(() {});
//       },
//     );
//   }
// }