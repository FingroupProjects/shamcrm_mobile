import 'dart:async';

import 'package:crm_task_manager/offline/core/network_profile_service.dart';
import 'package:crm_task_manager/offline/core/request_priority.dart';

typedef ScheduledRequest<T> = Future<T> Function();

class RequestScheduler {
  RequestScheduler({
    required this.networkProfileService,
  });

  final NetworkProfileService networkProfileService;
  final List<_ScheduledTask<dynamic>> _queue = [];

  int _runningTasks = 0;
  int _sequence = 0;

  Future<T> schedule<T>({
    required RequestPriority priority,
    required ScheduledRequest<T> task,
    bool isHeavy = false,
  }) {
    final completer = Completer<T>();
    _queue.add(
      _ScheduledTask<T>(
        sequence: _sequence++,
        priority: priority,
        isHeavy: isHeavy,
        task: task,
        completer: completer,
      ),
    );
    _pump();
    return completer.future;
  }

  void _pump() {
    if (_queue.isEmpty) {
      return;
    }

    final profile = networkProfileService.currentProfile;
    final maxParallel = profile.maxParallelRequests;
    if (maxParallel <= 0 || _runningTasks >= maxParallel) {
      return;
    }

    _queue.sort((a, b) {
      final priorityCompare = a.priority.weight.compareTo(b.priority.weight);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.sequence.compareTo(b.sequence);
    });

    final nextIndex = _queue.indexWhere(
      (task) => !task.isHeavy || profile.allowsHeavyBackgroundWork,
    );
    if (nextIndex == -1) {
      return;
    }

    final nextTask = _queue.removeAt(nextIndex);
    _runningTasks++;
    unawaited(_execute(nextTask));
    if (_runningTasks < maxParallel) {
      _pump();
    }
  }

  Future<void> _execute<T>(_ScheduledTask<T> task) async {
    try {
      final result = await task.task();
      task.completer.complete(result);
    } catch (error, stackTrace) {
      task.completer.completeError(error, stackTrace);
    } finally {
      _runningTasks--;
      _pump();
    }
  }
}

class _ScheduledTask<T> {
  const _ScheduledTask({
    required this.sequence,
    required this.priority,
    required this.isHeavy,
    required this.task,
    required this.completer,
  });

  final int sequence;
  final RequestPriority priority;
  final bool isHeavy;
  final ScheduledRequest<T> task;
  final Completer<T> completer;
}
