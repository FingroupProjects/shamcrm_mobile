import 'dart:async';
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/workday/workday_status_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/services/workday_capture_service.dart';
import 'package:crm_task_manager/services/workday_profile_redirect_service.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkdayCard extends StatefulWidget {
  final String? organizationId;

  const WorkdayCard({
    super.key,
    required this.organizationId,
  });

  @override
  State<WorkdayCard> createState() => _WorkdayCardState();
}

class _WorkdayCardState extends State<WorkdayCard> {
  final ApiService _apiService = ApiService();
  final WorkdayCaptureService _captureService = const WorkdayCaptureService();

  WorkdayStatusResponse? _status;
  bool _isVisible = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant WorkdayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    final isVisible = await _apiService.canReadTimesheet();
    if (!mounted) return;

    if (!isVisible) {
      setState(() {
        _isVisible = false;
        _status = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isVisible = true;
    });

    await _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _apiService.getWorkdayStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static const _noticeKey = 'workday_selfie_notice_shown';

  Future<bool> _showPhotoNoticeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_noticeKey) ?? false;
    if (alreadyShown) return true;

    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = ctx.appColors;
        final textStyles = ctx.appTextStyles;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: colors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_front_outlined,
                    size: 34,
                    color: colors.buttonPrimaryBg,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Фото при отметке',
                  style: textStyles.titleLg.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'При нажатии «Начать работу» или «Завершить работу» приложение автоматически сделает селфи с фронтальной камеры.\n\nФото вместе с геопозицией сохраняется в системе. Руководители и администраторы могут просматривать его в разделе «Табель».',
                  style: textStyles.bodySm.copyWith(
                    color: colors.textSecondary,
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Понятно, продолжить'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    'Отмена',
                    style: textStyles.bodySm.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await prefs.setBool(_noticeKey, true);
      return true;
    }
    return false;
  }

  Future<void> _handleAction({required bool isStart}) async {
    if (_isSubmitting) return;

    if (isStart) {
      final proceed = await _showPhotoNoticeIfNeeded();
      if (!proceed) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    File? photoFile;

    try {
      await _ensureCameraPermission();
      await _ensureLocationPermission();

      final results = await Future.wait<dynamic>([
        _captureService.capturePhoto(),
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        ),
      ]);

      photoFile = results[0] as File;
      final position = results[1] as Position;

      final response = isStart
          ? await _apiService.startWorkday(
              latitude: position.latitude,
              longitude: position.longitude,
              photo: photoFile,
            )
          : await _apiService.endWorkday(
              latitude: position.latitude,
              longitude: position.longitude,
              photo: photoFile,
            );

      if (!mounted) return;

      setState(() {
        _status = response;
      });

      if (isStart) {
        WorkdayProfileRedirectService.closeProfileBlock();
      }

      showCustomSnackBar(
        context: context,
        message: isStart
            ? 'Рабочий день успешно начат'
            : 'Рабочий день успешно завершен',
      );
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: _formatError(e),
        isSuccess: false,
      );
    } finally {
      if (photoFile != null && await photoFile.exists()) {
        unawaited(_deleteTempFile(photoFile));
      }
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return;

    status = await Permission.camera.request();
    if (status.isGranted) return;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }

    throw Exception('Разрешите доступ к камере, чтобы отметить рабочий день');
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Включите геолокацию, чтобы отметить рабочий день');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
    }

    throw Exception(
        'Разрешите доступ к геолокации, чтобы отметить рабочий день');
  }

  String _formatError(Object error) {
    if (error is WorkdayAccessException) {
      return error.message;
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Не удалось выполнить действие' : message;
  }

  Future<void> _deleteTempFile(File file) async {
    try {
      await file.delete();
    } catch (_) {
      return;
    }
  }

  String _buildSubtitle() {
    if (_isLoading) {
      return 'Проверяем статус рабочего дня...';
    }

    final record = _status?.result;
    if (record == null) {
      return 'Нажмите «Начать», когда приступаете к работе.';
    }

    if (record.isActive) {
      return 'Рабочий день начат в ${_formatTime(record.startedAt!)} · фото отправлено';
    }

    if (record.isCompleted) {
      return 'Рабочий день завершён в ${_formatTime(record.endedAt!)} · фото отправлено';
    }

    return 'Нажмите «Начать», когда приступаете к работе.';
  }

  IconData _workdayIcon() {
    final record = _status?.result;

    if (record?.isActive == true) {
      return Icons.work_history_outlined;
    }

    if (record?.isCompleted == true) {
      return Icons.task_alt_outlined;
    }

    // До ответа сервера и при отсутствии записи рабочий день ещё не начат.
    return Icons.work_outline;
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final canStart = !_isSubmitting && !(_status?.isActive ?? false);
    final canEnd = !_isSubmitting && (_status?.isActive ?? false);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.42),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.work_history_outlined,
                color: colors.buttonPrimaryBg,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Рабочий день',
                  style: textStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (_isLoading || _isSubmitting)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: colors.buttonPrimaryBg,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                title: 'Начать работу',
                backgroundColor: colors.buttonPrimaryBg,
                disabledColor: colors.fieldBorder,
                onPressed: canStart ? () => _handleAction(isStart: true) : null,
              ),
              _ActionButton(
                title: 'Завершить работу',
                backgroundColor: colors.error,
                disabledColor: colors.fieldBorder,
                onPressed: canEnd ? () => _handleAction(isStart: false) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _buildSubtitle(),
            style: textStyles.bodySm.copyWith(
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.camera_front_outlined,
                size: 14,
                color: colors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Селфи и геопозиция фиксируются при каждой отметке и доступны руководителю в табеле',
                  style: textStyles.bodySm.copyWith(
                    fontSize: 11,
                    color: colors.textSecondary.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color disabledColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.title,
    required this.backgroundColor,
    required this.disabledColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          backgroundColor: onPressed == null ? disabledColor : backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(title),
      ),
    );
  }
}
