import 'dart:collection';

import 'package:crm_task_manager/offline/core/request_priority.dart';
import 'package:flutter/foundation.dart';

class OfflineTelemetrySnapshot {
  const OfflineTelemetrySnapshot({
    required this.responseSizeByKey,
    required this.requestCountByScreen,
    required this.latencySamplesByKey,
    required this.successRateByNetworkType,
    required this.outboxDepth,
    required this.syncFailureRate,
  });

  final Map<String, List<int>> responseSizeByKey;
  final Map<String, int> requestCountByScreen;
  final Map<String, List<int>> latencySamplesByKey;
  final Map<String, List<bool>> successRateByNetworkType;
  final int outboxDepth;
  final double syncFailureRate;
}

class OfflineTelemetryService {
  final Map<String, List<int>> _responseSizes = {};
  final Map<String, int> _requestCountByScreen = {};
  final Map<String, List<int>> _latencySamples = {};
  final Map<String, List<bool>> _successRateByNetwork = {};
  final Queue<bool> _recentSyncResults = Queue<bool>();

  int _outboxDepth = 0;

  void recordRequest({
    required String screen,
    required String metricKey,
    required int responseSizeBytes,
    required Duration latency,
    required bool success,
    required String networkType,
    required RequestPriority priority,
  }) {
    _requestCountByScreen.update(screen, (value) => value + 1,
        ifAbsent: () => 1);
    _responseSizes.putIfAbsent(metricKey, () => []).add(responseSizeBytes);
    _latencySamples
        .putIfAbsent('${metricKey}_${priority.name}', () => [])
        .add(latency.inMilliseconds);
    _successRateByNetwork.putIfAbsent(networkType, () => []).add(success);
  }

  void setOutboxDepth(int depth) {
    _outboxDepth = depth;
  }

  void recordSyncResult(bool success) {
    _recentSyncResults.add(success);
    while (_recentSyncResults.length > 100) {
      _recentSyncResults.removeFirst();
    }
  }

  OfflineTelemetrySnapshot snapshot() {
    final syncResults = _recentSyncResults.toList(growable: false);
    final failures = syncResults.where((success) => !success).length;
    final syncFailureRate =
        syncResults.isEmpty ? 0.0 : failures / syncResults.length;

    return OfflineTelemetrySnapshot(
      responseSizeByKey: Map.unmodifiable(_responseSizes),
      requestCountByScreen: Map.unmodifiable(_requestCountByScreen),
      latencySamplesByKey: Map.unmodifiable(_latencySamples),
      successRateByNetworkType: Map.unmodifiable(_successRateByNetwork),
      outboxDepth: _outboxDepth,
      syncFailureRate: syncFailureRate,
    );
  }

  void debugDump() {
    if (!kDebugMode) {
      return;
    }
    final snapshot = this.snapshot();
    debugPrint(
      'OfflineTelemetry: requests=${snapshot.requestCountByScreen} outbox=${snapshot.outboxDepth} syncFailureRate=${snapshot.syncFailureRate}',
    );
  }
}
