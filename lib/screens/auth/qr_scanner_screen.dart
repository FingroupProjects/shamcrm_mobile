import 'dart:convert';
import 'dart:typed_data';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class QrScannerScreen extends StatefulWidget {
  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.stop();
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isInitialized = false;
  }

  void _onDetect(BarcodeCapture barcodeCapture) async {
    if (!isInitialized && barcodeCapture.barcodes.isNotEmpty) {
      isInitialized = true;
      final String? scanData = barcodeCapture.barcodes.first.rawValue;

      if (scanData != null) {
        await _processQrCode(scanData);
      }
    }
  }

  Future<void> _processQrCode(String base64String) async {
    try {
      Uint8List bytes = base64Decode(base64String);
      String decodedString = utf8.decode(bytes);
      String cleanedResult = decodedString.replaceAll('-back?', '?');
      List<String> qrParts = cleanedResult.split('?');

      if (qrParts.length < 6) {
        _showError('Неверный формат QR-кода');
        return;
      }

      String token = qrParts[0];
      String mainDomain = qrParts[1];
      String domain = qrParts[2];
      String userId = qrParts[3];
      String login = qrParts[4];
      String organizationId = qrParts[5];

      final apiService = context.read<ApiService>();

      // Инициализируем домен и сохраняем данные
      await apiService.initializeWithDomain(domain, mainDomain);
      await apiService.saveQrData(domain, mainDomain, login, token, userId, organizationId);

      await controller.stop();

      // Важно: НЕ отправляем FCM-токен здесь!
      // Он будет отправлен позже — в PinSetupScreen, после полной инициализации

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PinSetupScreen()),
        );
      }
    } catch (e) {
      _showError('Ошибка обработки QR-кода');
      debugPrint('QrScannerScreen: Ошибка: $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final barcodeCapture = await controller.analyzeImage(file.path);

      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final qrCode = barcodeCapture.barcodes.first.rawValue;
        if (qrCode != null) {
          await _processQrCode(qrCode);
        }
      } else {
        _showError('QR-код не найден на изображении');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сканер QR-кода', style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xff1E2E52)),
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
              child: MobileScanner(controller: controller, onDetect: _onDetect),
            ),
            SizedBox(height: 20),
            Text('Сканируйте QR-код', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Gilroy')),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: Icon(Icons.file_upload),
              label: Text('Загрузить файл с QR-кодом'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1E2E52),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}