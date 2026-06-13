import 'dart:convert';
import 'dart:typed_data';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
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
        _showError(
          AppLocalizations.of(context)?.translate('invalid_qr_format') ??
              'Неверный формат QR-кода',
        );
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
      await apiService.saveQrData(
          domain, mainDomain, login, token, userId, organizationId);

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
      _showError(
        AppLocalizations.of(context)?.translate('qr_processing_error') ??
            'Ошибка обработки QR-кода',
      );
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
        _showError(
          AppLocalizations.of(context)?.translate('qr_not_found_in_image') ??
              'QR-код не найден на изображении',
        );
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
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          localizations?.translate('qr_scanner_title') ?? 'Сканер QR-кода',
          style: textStyles.titleLg.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.iconPrimary),
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfacePrimary.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colors.borderSubtle.withValues(alpha: 0.42),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 350,
                      decoration: BoxDecoration(
                        color: colors.backgroundPrimary.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colors.buttonPrimaryBg.withValues(alpha: 0.6),
                          width: 1.4,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: MobileScanner(
                          controller: controller,
                          onDetect: _onDetect,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations?.translate('scan_qr_prompt') ??
                          'Сканируйте QR-код',
                      textAlign: TextAlign.center,
                      style: textStyles.bodyLg.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.file_upload),
                      label: Text(
                        localizations?.translate('upload_qr_file') ??
                            'Загрузить файл с QR-кодом',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
