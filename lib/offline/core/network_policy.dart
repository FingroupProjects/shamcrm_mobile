import 'dart:math';

import 'package:crm_task_manager/offline/core/network_profile.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';

class NetworkPolicy {
  const NetworkPolicy({
    required this.requestTimeout,
    required this.maxRetries,
    required this.baseBackoff,
    required this.maxBackoff,
    required this.jitterFactor,
    required this.maxParallelRequests,
    required this.allowHeavyBackgroundWork,
  });

  final Duration requestTimeout;
  final int maxRetries;
  final Duration baseBackoff;
  final Duration maxBackoff;
  final double jitterFactor;
  final int maxParallelRequests;
  final bool allowHeavyBackgroundWork;

  Duration backoffForAttempt(int attempt) {
    final exponentialMs = baseBackoff.inMilliseconds * pow(2, attempt).toInt();
    final boundedMs = min(exponentialMs, maxBackoff.inMilliseconds);
    final jitterRange = boundedMs * jitterFactor;
    final jitterMs = ((Random().nextDouble() * 2 - 1) * jitterRange).round();
    return Duration(milliseconds: max(0, boundedMs + jitterMs));
  }

  factory NetworkPolicy.forRequest({
    required RequestPriority priority,
    required NetworkProfile profile,
  }) {
    final timeout = profile.lowBandwidthMode
        ? const Duration(seconds: 25)
        : const Duration(seconds: 15);
    final retries = switch (priority) {
      RequestPriority.critical => 4,
      RequestPriority.high => 3,
      RequestPriority.normal => 2,
      RequestPriority.low => 1,
      RequestPriority.background => 0,
    };

    return NetworkPolicy(
      requestTimeout: timeout,
      maxRetries: retries,
      baseBackoff: const Duration(seconds: 1),
      maxBackoff: const Duration(seconds: 30),
      jitterFactor: 0.25,
      maxParallelRequests: profile.maxParallelRequests,
      allowHeavyBackgroundWork: profile.allowsHeavyBackgroundWork,
    );
  }
}
