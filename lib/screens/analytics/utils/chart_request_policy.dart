import 'dart:async';

import 'package:crm_task_manager/models/common/api_exception_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ChartReadyNotification extends Notification {
  const ChartReadyNotification();
}

class AnalyticsChartRequestPolicy {
  static const Set<int> _fatalStatusCodes = {409, 422, 500};
  static final Map<String, int> _attemptsByChart = {};
  static final Map<String, Timer> _retryTimersByChart = {};

  static String chartIdForState(State state) =>
      '${state.widget.runtimeType}_${identityHashCode(state)}';

  static void cancelPendingRetry(String chartId) {
    _retryTimersByChart.remove(chartId)?.cancel();
  }

  static void reset(String chartId, {State? readyState}) {
    cancelPendingRetry(chartId);
    _attemptsByChart.remove(chartId);
    _dispatchReady(readyState);
  }

  static void _dispatchReady(State? readyState) {
    if (readyState == null || !readyState.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!readyState.mounted) return;
      const ChartReadyNotification().dispatch(readyState.context);
    });
  }

  static Future<void> handleLoadError({
    required State state,
    required StateSetter setStateCallback,
    required String chartId,
    required Object error,
    StackTrace? stackTrace,
    required VoidCallback onFatalError,
    required Future<void> Function() retry,
  }) async {
    if (_shouldShowUserFacingError(error)) {
      reset(chartId);
      if (!state.mounted) {
        return;
      }
      setStateCallback(onFatalError);
      _dispatchReady(state);
      return;
    }

    final attempt = (_attemptsByChart[chartId] ?? 0) + 1;
    _attemptsByChart[chartId] = attempt;
    final delay = _retryDelay(attempt);

    if (kDebugMode) {
      debugPrint(
        'AnalyticsChartRequestPolicy: transient error for $chartId, '
        'retry #$attempt in ${delay.inSeconds}s: $error',
      );
      if (stackTrace != null) {
        debugPrint(
          'AnalyticsChartRequestPolicy: stackTrace for $chartId: $stackTrace',
        );
      }
    }

    cancelPendingRetry(chartId);
    final timer = Timer(delay, () async {
      _retryTimersByChart.remove(chartId);
      if (!state.mounted) {
        reset(chartId);
        return;
      }
      await retry();
    });
    _retryTimersByChart[chartId] = timer;
  }

  static String userFacingMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    final normalized = error.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        );
    if (normalized.trim().isNotEmpty) {
      return normalized.trim();
    }

    return 'analytics_chart_load_failed';
  }

  static bool _shouldShowUserFacingError(Object error) {
    final statusCode = _extractStatusCode(error);
    return statusCode != null && _fatalStatusCodes.contains(statusCode);
  }

  static int? _extractStatusCode(Object error) {
    if (error is ApiException) {
      return error.statusCode;
    }

    final match = RegExp(r'\b(409|422|500)\b').firstMatch(error.toString());
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  static Duration _retryDelay(int attempt) {
    if (attempt <= 1) {
      return const Duration(seconds: 2);
    }
    if (attempt == 2) {
      return const Duration(seconds: 4);
    }
    if (attempt == 3) {
      return const Duration(seconds: 8);
    }
    if (attempt == 4) {
      return const Duration(seconds: 12);
    }
    return const Duration(seconds: 20);
  }
}
