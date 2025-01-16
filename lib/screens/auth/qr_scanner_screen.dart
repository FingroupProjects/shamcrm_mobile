import 'dart:convert';
import 'dart:typed_data';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:scan/scan.dart';

class QrScannerScreen extends StatefulWidget {
  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code != null) {
        print('Сканированный QR-код: ${scanData.code}');

        try {
          String base64String = scanData.code!;
          Uint8List bytes = base64Decode(base64String);

          String decodedString = utf8.decode(bytes);

          print('Декодированная строка: $decodedString');

          // Очистка строки от лишнего -back-
          String cleanedResult = decodedString.replaceAll('-back-', '-');

          // Разделяем строку на части
          List<String> qrParts = cleanedResult.split('-');

          // Извлекаем нужные данные
          String token = qrParts[0];
          String domain = qrParts[1];
          String userId = qrParts[2];
          String login = qrParts[3];
          String organizationId = qrParts[4];

          // Выводим результат
          print('Token: $token');
          print('Domain: $domain');
          print('User ID: $userId');
          print('Login: $login');
          print('Organization ID: $organizationId');

          await context.read<ApiService>().initializeWithDomain(domain);

          // Сохраняем данные из QR-кода
          await context
              .read<ApiService>()
              .saveQrData(domain, login, token, userId, organizationId);

          await controller.pauseCamera();

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => PinSetupScreen()));

        } catch (e) {
          print('Ошибка при декодировании Base64: $e');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR-код не найден!',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red,
            elevation: 3,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final file = File(result.files.single.path!);
      print('Файл выбран: ${file.path}');

      // Используем библиотеку scan для считывания QR-кода из изображения
      String? qrCode = await Scan.parse(file.path);

      if (qrCode != null) {
        print('QR-код из изображения: $qrCode');

        try {
          String base64String = qrCode;
          Uint8List bytes = base64Decode(base64String);

          String decodedString = utf8.decode(bytes);

          print('Декодированная строка: $decodedString');

          // Очистка строки от лишнего -back-
          String cleanedResult = decodedString.replaceAll('-back-', '-');

          // Разделяем строку на части
          List<String> qrParts = cleanedResult.split('-');

          // Извлекаем нужные данные
          String token = qrParts[0];
          String domain = qrParts[1];
          String userId = qrParts[2];
          String login = qrParts[3];
          String organizationId = qrParts[4];

          // Выводим результат
          print('Token: $token');
          print('Domain: $domain');
          print('User ID: $userId');
          print('Login: $login');
          print('Organization ID: $organizationId');

          await context.read<ApiService>().initializeWithDomain(domain);
          await context.read<ApiService>().saveQrData(domain, login, token, userId, organizationId);

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => PinSetupScreen()));
        } catch (e) {
          print('Ошибка при декодировании Base64: $e');
        }
      } else {
        print('QR-код не найден');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR-код не найден в изображении!',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red,
            elevation: 3,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Сканер QR-кода',
          style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xff1E2E52)),
          forceMaterialTransparency: true,
          leading: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
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
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(0),
              ),
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Сканируйте QR-код',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: Icon(Icons.file_upload),
              label: Text('Загрузить файл с QR-кодом'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1E2E52),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
