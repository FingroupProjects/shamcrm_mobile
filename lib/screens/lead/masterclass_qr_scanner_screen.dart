import 'dart:convert';
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MasterclassQrScannerScreen extends StatefulWidget {
  const MasterclassQrScannerScreen({super.key});

  @override
  State<MasterclassQrScannerScreen> createState() =>
      _MasterclassQrScannerScreenState();
}

class _MasterclassQrScannerScreenState
    extends State<MasterclassQrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.stop();
    controller.dispose();
    super.dispose();
  }

  String? _extractTicketQr(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['qr'] != null) {
          final qr = decoded['qr'].toString().trim();
          if (qr.startsWith('shamcrm:masterclass-ticket:')) {
            return qr;
          }
        }
      } catch (_) {}
    }

    if (trimmed.startsWith('shamcrm:masterclass-ticket:')) {
      return trimmed;
    }

    return null;
  }

  Future<void> _onDetect(BarcodeCapture barcodeCapture) async {
    if (_isProcessing || barcodeCapture.barcodes.isEmpty) return;
    final scanData = barcodeCapture.barcodes.first.rawValue;
    if (scanData == null || scanData.isEmpty) return;
    await _processQrCode(scanData);
  }

  Future<void> _processQrCode(String rawValue) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await controller.stop();

    final localizations = AppLocalizations.of(context);
    final qr = _extractTicketQr(rawValue);

    try {
      if (qr == null) {
        _showLocalizedMessage(
          localizations?.translate('invalid_qr_format') ??
              'Неверный формат QR-кода',
          isSuccess: false,
        );
        return;
      }

      final result = await _apiService.checkInMasterclassTicket(qr);
      final statusCode = result['statusCode'] as int? ?? 0;
      final isSuccess = statusCode >= 200 && statusCode < 300;
      _showApiMessage(
        _buildCheckInMessage(result, isSuccess, localizations),
        isSuccess: isSuccess,
      );
    } catch (e) {
      _showLocalizedMessage(
        localizations?.translate('masterclass_ticket_check_in_failed') ??
            'Не удалось проверить билет',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() => _isProcessing = false);
        try {
          await controller.start();
        } catch (_) {}
      }
    }
  }

  Future<void> _pickFile() async {
    if (_isProcessing) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final barcodeCapture = await controller.analyzeImage(file.path);
    if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
      final qrCode = barcodeCapture.barcodes.first.rawValue;
      if (qrCode != null) {
        await _processQrCode(qrCode);
        return;
      }
    }

    _showLocalizedMessage(
      AppLocalizations.of(context)?.translate('qr_not_found_in_image') ??
          'QR-код не найден на изображении',
      isSuccess: false,
    );
  }

  String _buildCheckInMessage(
    Map<String, dynamic> result,
    bool isSuccess,
    AppLocalizations? localizations,
  ) {
    final texts = (result['texts'] as List?)
            ?.map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList() ??
        [];
    final phone = (result['phone'] as String?)?.trim();
    final fallback = localizations?.translate(
          isSuccess
              ? 'masterclass_ticket_checked_in'
              : 'masterclass_ticket_check_in_failed',
        ) ??
        (isSuccess ? 'Гость отмечен' : 'Не удалось проверить билет');

    final lines = <String>[
      texts.isNotEmpty ? texts.join(' ') : fallback,
    ];
    if (phone != null && phone.isNotEmpty) {
      final label =
          localizations?.translate('phone_number') ?? 'Номер телефона:';
      lines.add('$label $phone');
    }
    return lines.join('\n');
  }

  void _showLocalizedMessage(String message, {required bool isSuccess}) {
    if (!mounted || message.isEmpty) return;
    showCustomSnackBar(
      context: context,
      message: message,
      isSuccess: isSuccess,
    );
  }

  void _showApiMessage(String message, {required bool isSuccess}) {
    if (!mounted || message.isEmpty) return;
    final bottom = MediaQuery.paddingOf(context).bottom;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(12, 8, 12, bottom + 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor:
              isSuccess ? const Color(0xff16A34A) : const Color(0xffDC2626),
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 4),
        ),
      );
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
          localizations?.translate('masterclass_qr_scanner') ?? 'Сканер QR',
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: controller,
                              onDetect: _onDetect,
                            ),
                            if (_isProcessing)
                              ColoredBox(
                                color: Colors.black.withValues(alpha: 0.45),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations?.translate('masterclass_qr_scan_prompt') ??
                          'Отсканируйте QR-код билета',
                      textAlign: TextAlign.center,
                      style: textStyles.bodyLg.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickFile,
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
