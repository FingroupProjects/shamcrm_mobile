import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:new_version_plus/new_version_plus.dart';

enum InAppUpdateStage {
  idle,
  pending,
  downloading,
  downloaded,
  installing,
  installed,
  canceled,
  failed,
  unavailable,
}

class InAppUpdateProgress {
  const InAppUpdateProgress({
    required this.stage,
    required this.progressPercent,
    this.downloadedBytes,
    this.totalBytes,
    this.message,
  });

  final InAppUpdateStage stage;
  final int progressPercent;
  final int? downloadedBytes;
  final int? totalBytes;
  final String? message;

  bool get isActive =>
      stage == InAppUpdateStage.pending ||
      stage == InAppUpdateStage.downloading ||
      stage == InAppUpdateStage.installing;

  bool get canInstall => stage == InAppUpdateStage.downloaded;

  static InAppUpdateProgress fromMap(Map<Object?, Object?> map) {
    return InAppUpdateProgress(
      stage: _stageFromRaw(map['status']?.toString()),
      progressPercent: _toInt(map['progress']),
      downloadedBytes: _nullableInt(map['downloadedBytes']),
      totalBytes: _nullableInt(map['totalBytes']),
      message: map['message']?.toString(),
    );
  }

  static InAppUpdateStage _stageFromRaw(String? raw) {
    switch (raw) {
      case 'pending':
        return InAppUpdateStage.pending;
      case 'downloading':
        return InAppUpdateStage.downloading;
      case 'downloaded':
        return InAppUpdateStage.downloaded;
      case 'installing':
        return InAppUpdateStage.installing;
      case 'installed':
        return InAppUpdateStage.installed;
      case 'canceled':
        return InAppUpdateStage.canceled;
      case 'failed':
        return InAppUpdateStage.failed;
      case 'unavailable':
        return InAppUpdateStage.unavailable;
      default:
        return InAppUpdateStage.idle;
    }
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableInt(Object? value) {
    if (value == null) return null;
    return _toInt(value);
  }
}

class InAppUpdateService {
  InAppUpdateService._();

  static final InAppUpdateService instance = InAppUpdateService._();

  static const MethodChannel _methodChannel =
      MethodChannel('com.shamcrm/in_app_update/methods');
  static const EventChannel _eventChannel =
      EventChannel('com.shamcrm/in_app_update/events');

  Stream<InAppUpdateProgress>? _progressStream;
  StreamSubscription<InAppUpdateProgress>? _progressSubscription;
  final ValueNotifier<InAppUpdateProgress?> progressNotifier =
      ValueNotifier<InAppUpdateProgress?>(null);

  bool get canUseNativeInAppUpdate => !kIsWeb && Platform.isAndroid;

  Future<void> ensureListening() async {
    _progressSubscription ??= progressStream().listen((event) {
      progressNotifier.value = event;

      if (event.stage == InAppUpdateStage.installed ||
          event.stage == InAppUpdateStage.canceled ||
          event.stage == InAppUpdateStage.failed ||
          event.stage == InAppUpdateStage.unavailable) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (progressNotifier.value == event) {
            clearProgress();
          }
        });
      }
    });
  }

  Future<bool> isSupported() async {
    if (!canUseNativeInAppUpdate) {
      return false;
    }

    try {
      final result = await _methodChannel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startFlexibleUpdate() async {
    if (!canUseNativeInAppUpdate) {
      return false;
    }

    try {
      final result =
          await _methodChannel.invokeMethod<bool>('startFlexibleUpdate');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeFlexibleUpdate() async {
    if (!canUseNativeInAppUpdate) {
      return false;
    }

    try {
      final result =
          await _methodChannel.invokeMethod<bool>('completeFlexibleUpdate');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startUpdateOrOpenStore(VersionStatus status) async {
    if (!canUseNativeInAppUpdate) {
      await NewVersionPlus().launchAppStore(status.appStoreLink);
      return false;
    }

    await ensureListening();
    progressNotifier.value = const InAppUpdateProgress(
      stage: InAppUpdateStage.pending,
      progressPercent: 0,
      message: 'Подготавливаем загрузку обновления...',
    );

    final supported = await isSupported();
    if (supported) {
      final started = await startFlexibleUpdate();
      if (started) {
        return true;
      }
    }

    clearProgress();
    await NewVersionPlus().launchAppStore(status.appStoreLink);
    return false;
  }

  Future<void> installDownloadedUpdate() async {
    await completeFlexibleUpdate();
  }

  void clearProgress() {
    progressNotifier.value = null;
  }

  Stream<InAppUpdateProgress> progressStream() {
    return _progressStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) =>
            InAppUpdateProgress.fromMap((event as Map<Object?, Object?>)))
        .asBroadcastStream();
  }
}
