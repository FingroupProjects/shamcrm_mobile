import 'dart:async';
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/workday_status_model.dart';
import 'package:crm_task_manager/services/workday_capture_service.dart';
import 'package:crm_task_manager/services/workday_profile_redirect_service.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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

    final isVisible = await _apiService.isWorkdayFeatureEnabled();
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

  Future<void> _handleAction({required bool isStart}) async {
    if (_isSubmitting) return;

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
      return 'Рабочий день начат в ${_formatTime(record.startedAt!)}';
    }

    if (record.isCompleted) {
      return 'Рабочий день уже завершен в ${_formatTime(record.endedAt!)}';
    }

    return 'Нажмите «Начать», когда приступаете к работе.';
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

    final canStart = !_isSubmitting && !(_status?.isActive ?? false);
    final canEnd = !_isSubmitting && (_status?.isActive ?? false);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E2E52),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_history_outlined, color: Color(0xFF4A3DF0)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Рабочий день',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2E52),
                  ),
                ),
              ),
              if (_isLoading || _isSubmitting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
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
                backgroundColor: const Color(0xFF4A3DF0),
                disabledColor: const Color(0xFFB7B0F9),
                onPressed: canStart ? () => _handleAction(isStart: true) : null,
              ),
              _ActionButton(
                title: 'Завершить работу',
                backgroundColor: const Color(0xFFE34848),
                disabledColor: const Color(0xFFF1A7A7),
                onPressed: canEnd ? () => _handleAction(isStart: false) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _buildSubtitle(),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5F6B84),
            ),
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
