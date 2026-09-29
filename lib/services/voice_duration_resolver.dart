import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Узнаёт настоящую длину голосового по файлу, без воспроизведения.
/// Результат запоминается, чтобы при скролле не читать файл снова.
class VoiceDurationResolver {
  VoiceDurationResolver._();

  static final VoiceDurationResolver instance = VoiceDurationResolver._();

  final Map<String, Duration> _known = {};
  final Map<String, Future<Duration?>> _pending = {};
  final List<void Function()> _queue = [];
  int _active = 0;

  // Несколько плееров сразу, но не десяток: так список заполняется быстро
  // и не отбирает звук у текущего воспроизведения.
  static const int _maxActive = 4;

  Duration? peek(String source) {
    if (source.isEmpty) return null;
    return _known[source];
  }

  void remember(String source, Duration duration) {
    if (source.isEmpty || duration <= Duration.zero) return;
    _known[source] = duration;
  }

  Future<Duration?> resolve(String source) {
    if (source.isEmpty) return Future.value(null);
    final known = _known[source];
    if (known != null) return Future.value(known);

    final pending = _pending[source];
    if (pending != null) return pending;

    final future = _schedule(source);
    _pending[source] = future;
    return future.whenComplete(() => _pending.remove(source));
  }

  Future<Duration?> _schedule(String source) {
    final done = Completer<Duration?>();

    void start() {
      _active++;
      _probe(source).then((duration) {
        if (!done.isCompleted) done.complete(duration);
      }).catchError((Object error) {
        debugPrint('VoiceDurationResolver: $error');
        if (!done.isCompleted) done.complete(null);
      }).whenComplete(() {
        _active--;
        if (_queue.isNotEmpty) {
          final next = _queue.removeAt(0);
          next();
        }
      });
    }

    if (_active < _maxActive) {
      start();
    } else {
      _queue.add(start);
    }
    return done.future;
  }

  Future<Duration?> _probe(String source) async {
    // Пробный плеер не включает звук и не перехватывает аудиосессию звонка.
    final player = AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
    );
    try {
      Duration? duration;
      if (source.startsWith('http://') || source.startsWith('https://')) {
        duration = await player.setUrl(source).timeout(
              const Duration(seconds: 15),
            );
      } else {
        final path = source.replaceFirst('file://', '');
        duration = await player.setFilePath(path).timeout(
              const Duration(seconds: 8),
            );
      }

      if (duration == null || duration <= Duration.zero) {
        duration = await player.durationStream
            .firstWhere((value) => value != null && value > Duration.zero)
            .then((value) => value)
            .timeout(const Duration(seconds: 8));
      }

      if (duration == null || duration <= Duration.zero) return null;
      _known[source] = duration;
      return duration;
    } catch (error) {
      debugPrint('VoiceDurationResolver probe failed: $error');
      return null;
    } finally {
      await player.dispose();
    }
  }
}
