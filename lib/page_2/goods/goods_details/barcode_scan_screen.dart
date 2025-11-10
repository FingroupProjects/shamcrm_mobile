// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// class _BarcodeScannerScreen extends StatefulWidget {
//   @override
//   _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
// }

// class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen>
//     with TickerProviderStateMixin {
//   MobileScannerController controller = MobileScannerController();
//   bool isScanned = false;
//   bool isFlashOn = false;
  
//   late AnimationController _scanLineController;
//   late AnimationController _pulseController;
//   late Animation<double> _scanLineAnimation;
//   late Animation<double> _pulseAnimation;

//   @override
//   void initState() {
//     super.initState();
    
//     // Анимация сканирующей линии
//     _scanLineController = AnimationController(
//       duration: Duration(seconds: 2),
//       vsync: this,
//     )..repeat();
    
//     _scanLineAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _scanLineController,
//       curve: Curves.easeInOut,
//     ));
    
//     // Анимация пульсации углов
//     _pulseController = AnimationController(
//       duration: Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     _pulseAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Камера на весь экран
//           MobileScanner(
//             controller: controller,
//             onDetect: (capture) {
//               if (!isScanned) {
//                 isScanned = true;
//                 // Вибрация при успешном сканировании
//                 HapticFeedback.lightImpact();
//                 final List<Barcode> barcodes = capture.barcodes;
//                 if (barcodes.isNotEmpty) {
//                   final String code = barcodes.first.rawValue ?? '';
//                   Navigator.of(context).pop(code);
//                 }
//               }
//             },
//           ),
          
//           // Темный оверлей с вырезом для сканирования
//           _buildScanOverlay(),
          
//           // Верхняя панель
//           _buildTopBar(),
          
//           // Нижняя панель
//           _buildBottomPanel(),
//         ],
//       ),
//     );
//   }

//   Widget _buildScanOverlay() {
//     return CustomPaint(
//       painter: ScanOverlayPainter(),
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: Center(
//           child: Container(
//             width: 280,
//             height: 280,
//             child: Stack(
//               children: [
//                 // Анимированные углы рамки
//                 AnimatedBuilder(
//                   animation: _pulseAnimation,
//                   builder: (context, child) {
//                     return CustomPaint(
//                       painter: ScanFramePainter(_pulseAnimation.value),
//                       size: Size(280, 280),
//                     );
//                   },
//                 ),
                
//                 // Сканирующая линия
//                 AnimatedBuilder(
//                   animation: _scanLineAnimation,
//                   builder: (context, child) {
//                     return Positioned(
//                       top: _scanLineAnimation.value * 260 + 10,
//                       left: 20,
//                       right: 20,
//                       child: Container(
//                         height: 3,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               Colors.transparent,
//                               Color(0xFF00FF88),
//                               Color(0xFF00FF88),
//                               Colors.transparent,
//                             ],
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Color(0xFF00FF88).withOpacity(0.8),
//                               blurRadius: 8,
//                               spreadRadius: 1,
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTopBar() {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: Container(
//         padding: EdgeInsets.only(
//           top: MediaQuery.of(context).padding.top + 8,
//           left: 16,
//           right: 16,
//           bottom: 16,
//         ),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.black.withOpacity(0.8),
//               Colors.transparent,
//             ],
//           ),
//         ),
//         child: Row(
//           children: [
//             // Кнопка назад
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.2),
//                 ),
//               ),
//               child: IconButton(
//                 icon: Icon(Icons.arrow_back, color: Colors.white),
//                 onPressed: () => Navigator.of(context).pop('-1'),
//               ),
//             ),
            
//             Expanded(
//               child: Text(
//                 'Сканер штрих-кода',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
            
//             // Кнопка фонарика
//             Container(
//               decoration: BoxDecoration(
//                 color: isFlashOn 
//                     ? Color(0xFF00FF88).withOpacity(0.2)
//                     : Colors.white.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: isFlashOn 
//                       ? Color(0xFF00FF88)
//                       : Colors.white.withOpacity(0.2),
//                 ),
//               ),
//               child: IconButton(
//                 icon: Icon(
//                   isFlashOn ? Icons.flash_on : Icons.flash_off,
//                   color: isFlashOn ? Color(0xFF00FF88) : Colors.white,
//                 ),
//                 onPressed: () {
//                   controller.toggleTorch();
//                   setState(() {
//                     isFlashOn = !isFlashOn;
//                   });
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomPanel() {
//     return Positioned(
//       bottom: 0,
//       left: 0,
//       right: 0,
//       child: Container(
//         padding: EdgeInsets.only(
//           top: 32,
//           left: 24,
//           right: 24,
//           bottom: MediaQuery.of(context).padding.bottom + 24,
//         ),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.bottomCenter,
//             end: Alignment.topCenter,
//             colors: [
//               Colors.black.withOpacity(0.9),
//               Colors.transparent,
//             ],
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Инструкция
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.2),
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.qr_code_scanner,
//                     color: Color(0xFF00FF88),
//                     size: 20,
//                   ),
//                   SizedBox(width: 8),
//                   Text(
//                     'Наведите камеру на штрих-код',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             SizedBox(height: 24),
            
//             // Кнопки действий
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Кнопка галереи
//                 _buildActionButton(
//                   icon: Icons.photo_library,
//                   label: 'Галерея',
//                   onPressed: () {
//                     // Здесь можно добавить выбор изображения из галереи
//                   },
//                 ),
                
//                 // Центральная кнопка отмены
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.15),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.3),
//                       width: 2,
//                     ),
//                   ),
//                   child: IconButton(
//                     icon: Icon(
//                       Icons.close,
//                       color: Colors.white,
//                       size: 32,
//                     ),
//                     onPressed: () => Navigator.of(context).pop('-1'),
//                   ),
//                 ),
                
//                 // Кнопка истории (если нужно)
//                 _buildActionButton(
//                   icon: Icons.history,
//                   label: 'История',
//                   onPressed: () {
//                     // Здесь можно показать историю сканирований
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           width: 56,
//           height: 56,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.white.withOpacity(0.15),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.2),
//             ),
//           ),
//           child: IconButton(
//             icon: Icon(icon, color: Colors.white),
//             onPressed: onPressed,
//           ),
//         ),
//         SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.8),
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _scanLineController.dispose();
//     _pulseController.dispose();
//     controller.dispose();
//     super.dispose();
//   }
// }

// // Класс для рисования оверлея с вырезом
// class ScanOverlayPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.black.withOpacity(0.6)
//       ..style = PaintingStyle.fill;

//     final rect = Rect.fromLTWH(0, 0, size.width, size.height);
//     final scanRect = Rect.fromCenter(
//       center: Offset(size.width / 2, size.height / 2),
//       width: 280,
//       height: 280,
//     );

//     final path = Path()
//       ..addRect(rect)
//       ..addRRect(RRect.fromRectAndRadius(scanRect, Radius.circular(20)))
//       ..fillType = PathFillType.evenOdd;

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// // Класс для рисования анимированной рамки
// class ScanFramePainter extends CustomPainter {
//   final double animationValue;

//   ScanFramePainter(this.animationValue);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Color(0xFF00FF88).withOpacity(animationValue)
//       ..strokeWidth = 4
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round;

//     final cornerLength = 30.0;
//     final cornerRadius = 20.0;

//     // Верхний левый угол
//     canvas.drawPath(
//       Path()
//         ..moveTo(cornerRadius, 0)
//         ..lineTo(cornerLength, 0)
//         ..moveTo(0, cornerRadius)
//         ..lineTo(0, cornerLength),
//       paint,
//     );

//     // Верхний правый угол
//     canvas.drawPath(
//       Path()
//         ..moveTo(size.width - cornerLength, 0)
//         ..lineTo(size.width - cornerRadius, 0)
//         ..moveTo(size.width, cornerRadius)
//         ..lineTo(size.width, cornerLength),
//       paint,
//     );

//     // Нижний левый угол
//     canvas.drawPath(
//       Path()
//         ..moveTo(0, size.height - cornerLength)
//         ..lineTo(0, size.height - cornerRadius)
//         ..moveTo(cornerRadius, size.height)
//         ..lineTo(cornerLength, size.height),
//       paint,
//     );

//     // Нижний правый угол
//     canvas.drawPath(
//       Path()
//         ..moveTo(size.width, size.height - cornerLength)
//         ..lineTo(size.width, size.height - cornerRadius)
//         ..moveTo(size.width - cornerRadius, size.height)
//         ..lineTo(size.width - cornerLength, size.height),
//       paint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }