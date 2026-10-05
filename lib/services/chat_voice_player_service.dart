import 'dart:async';

import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<double> voicePlaybackSpeeds = [1.0, 1.5, 2.0];

/// Скорость помним между заходами в чат.
const String chatVoiceSpeedPrefsKey = 'chat_voice_playback_speed';

/// Каталог голосовых подставляет сюда «следующую» запись.
/// Сервис не знает про каталог, чтобы файлы не ссылались друг на друга.
ChatVoiceTrack? Function(ChatVoiceTrack current)? chatVoiceNextResolver;

double nextVoicePlaybackSpeed(double current) {
  final index = voicePlaybackSpeeds.indexWhere(
    (speed) => (speed - current).abs() < 0.01,
  );
  if (index < 0) return voicePlaybackSpeeds.first;
  return voicePlaybackSpeeds[(index + 1) % voicePlaybackSpeeds.length];
}

String formatVoiceSpeedLabel(double speed) {
  if ((speed - speed.roundToDouble()).abs() < 0.01) {
    return '${speed.round()}x';
  }
  return '${speed}x';
}

String formatVoiceClock(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String chatVoiceTrackKey({
  required int chatId,
  required int messageId,
  required String filePath,
}) {
  return '$chatId:$messageId:$filePath';
}

/// Пока переключаем запись, плеер ещё раз присылает «закончилось».
/// Это не конец новой записи, очередь из‑за этого перескакивать нельзя.
bool shouldIgnoreVoiceCompletion({required bool switchingTrack}) {
  return switchingTrack;
}

bool shouldShowChatVoiceMiniPlayer({
  required bool isActive,
  required int? trackChatId,
  required int? foregroundChatId,
}) {
  return isActive && trackChatId != null && trackChatId != foregroundChatId;
}

String formatChatVoiceSentAt(String raw, {DateTime? now}) {
  var value = raw;
  if (value.endsWith('Z')) {
    value = value.substring(0, value.length - 1);
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) return raw;

  final local = parsed.add(DateTime.now().timeZoneOffset);
  final current = now ?? DateTime.now();
  final localDate = DateTime(local.year, local.month, local.day);
  final today = DateTime(current.year, current.month, current.day);
  final timeLabel = DateFormat('HH:mm').format(local);

  if (localDate == today) return timeLabel;
  return '${DateFormat('dd.MM').format(local)} $timeLabel';
}

class ChatVoiceTrack {
  final int messageId;
  final int chatId;
  final String filePath;
  final String localPath;
  final String senderName;
  final String sentAtLabel;
  final Duration duration;
  final ChatItem? chatItem;
  final String endPointInTab;
  final bool canSendMessage;
  final String? chatUniqueId;
  final String? channelName;

  const ChatVoiceTrack({
    required this.messageId,
    required this.chatId,
    required this.filePath,
    required this.localPath,
    required this.senderName,
    required this.sentAtLabel,
    required this.duration,
    required this.endPointInTab,
    this.chatItem,
    this.canSendMessage = true,
    this.chatUniqueId,
    this.channelName,
  });

  String get key => chatVoiceTrackKey(
        chatId: chatId,
        messageId: messageId,
        filePath: filePath,
      );
}

class ChatVoicePlayerService extends ChangeNotifier {
  ChatVoicePlayerService._() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (shouldIgnoreVoiceCompletion(switchingTrack: _switchingTrack)) {
          return;
        }
        unawaited(_handleCompleted());
        return;
      }
      // Новая запись уже грузится. Следующее «закончилось» будет настоящим.
      if (_switchingTrack &&
          state.processingState != ProcessingState.idle &&
          state.processingState != ProcessingState.completed) {
        _switchingTrack = false;
      }
      if (state.playing) {
        _keepPauseIcon = false;
      }
      // Пауза перед перемоткой не должна мигать кнопкой play.
      if (_seekInFlight || _pendingSeek != null || _keepPauseIcon) return;
      _notifyListenersSafely();
    });
    _positionSub = _player.positionStream.listen((position) {
      final pending = _pendingSeek;
      if (pending != null) {
        final gap = (position - pending).inMilliseconds.abs();
        // Старая позиция приходит раньше, чем плеер примет перемотку.
        if (gap > 450) return;
        _pendingSeek = null;
      }
      _position = position;
      _notifyListenersSafely();
    });
    _durationSub = _player.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        _notifyListenersSafely();
      }
    });
  }

  static final ChatVoicePlayerService instance = ChatVoicePlayerService._();

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  bool _notifyPostFrameScheduled = false;

  ChatVoiceTrack? _track;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _speedLoaded = false;
  bool _handlingComplete = false;
  bool _switchingTrack = false;
  int _playGeneration = 0;
  int? _foregroundChatId;
  // Пока перемотка не доехала, поток позиции ещё шлёт старое место.
  // Если его принять, линия прыгает назад и мигает.
  Duration? _pendingSeek;
  bool _seekInFlight = false;
  Duration? _queuedSeek;
  bool _resumeAfterSeek = false;
  // На время скрытой паузы перед перемоткой кнопка остаётся «пауза».
  bool _keepPauseIcon = false;

  ChatVoiceTrack? get track => _track;
  Duration get position => _position;
  Duration get duration {
    if (_duration > Duration.zero) return _duration;
    return _track?.duration ?? Duration.zero;
  }

  double get speed => _speed;
  bool get isActive => _track != null;
  bool get isPlaying => isActive && (_player.playing || _keepPauseIcon);
  int? get foregroundChatId => _foregroundChatId;
  bool get shouldShowMiniPlayer => shouldShowChatVoiceMiniPlayer(
        isActive: isActive,
        trackChatId: _track?.chatId,
        foregroundChatId: _foregroundChatId,
      );

  void setForegroundChatId(int? chatId) {
    if (_foregroundChatId == chatId) return;
    _foregroundChatId = chatId;
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      if (_notifyPostFrameScheduled) return;
      _notifyPostFrameScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notifyPostFrameScheduled = false;
        notifyListeners();
      });
      return;
    }

    notifyListeners();
  }
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  bool isCurrent({
    required int chatId,
    required int messageId,
    required String filePath,
  }) {
    return _track?.key ==
        chatVoiceTrackKey(
          chatId: chatId,
          messageId: messageId,
          filePath: filePath,
        );
  }

  Future<void> play(ChatVoiceTrack track, {double? startFraction}) async {
    // Ставим до любого await: stop() внутри play сразу шлёт старое «закончилось».
    _switchingTrack = true;
    final generation = ++_playGeneration;
    await _ensureSpeedLoaded();
    _track = track;
    _position = Duration.zero;
    if (track.duration > Duration.zero) {
      _duration = track.duration;
    }
    _notifyListenersSafely();

    try {
      await _player.stop();
      if (track.localPath.startsWith('http://') ||
          track.localPath.startsWith('https://')) {
        await _player.setUrl(track.localPath);
      } else {
        await _player.setFilePath(track.localPath);
      }
      await _player.setSpeed(_speed);
      if (generation != _playGeneration) return;
      final start = startFraction;
      if (start != null) {
        final totalMs = (_player.duration ?? duration).inMilliseconds;
        if (totalMs > 0) {
          final at = Duration(
            milliseconds: (totalMs * start.clamp(0.0, 1.0)).round(),
          );
          _position = at;
          await _player.seek(at);
        }
      }
      if (generation != _playGeneration) return;
      // Не ждём конец записи. Конец ловит поток состояния и включает следующую.
      unawaited(_player.play().catchError((Object error) {
        debugPrint('ChatVoicePlayerService playback error: $error');
      }));
    } catch (error) {
      debugPrint('ChatVoicePlayerService play error: $error');
      if (generation != _playGeneration) return;
      await stop();
    }
  }

  Future<void> toggle() async {
    if (!isActive) return;
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> pause() async {
    _keepPauseIcon = false;
    _resumeAfterSeek = false;
    await _player.pause();
    _notifyListenersSafely();
  }

  Future<void> resume() async {
    if (!isActive) return;
    await _player.play();
    _notifyListenersSafely();
  }

  Future<void> cycleSpeed() async {
    await _ensureSpeedLoaded();
    _speed = nextVoicePlaybackSpeed(_speed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(chatVoiceSpeedPrefsKey, _speed);
    await _player.setSpeed(_speed);
    _notifyListenersSafely();
  }

  /// Доля от 0 до 1. Нажатие по полоске мини-плеера.
  ///
  /// just_audio во время play молча откладывает seek, пока не будет паузы.
  /// Поэтому сначала держим линию на месте нажатия, ставим паузу,
  /// перематываем и сразу продолжаем, если запись играла.
  Future<void> seekToFraction(double fraction) async {
    if (!isActive) return;
    final total = duration.inMilliseconds;
    if (total <= 0) return;
    final safe = fraction.clamp(0.0, 1.0);
    final target = Duration(milliseconds: (total * safe).round());
    _pendingSeek = target;
    _queuedSeek = target;
    final keepPlaying = _resumeAfterSeek || _player.playing || _keepPauseIcon;
    _resumeAfterSeek = keepPlaying;
    _keepPauseIcon = keepPlaying;
    _position = target;
    _notifyListenersSafely();
    if (_seekInFlight) return;
    _seekInFlight = true;
    try {
      while (_queuedSeek != null && isActive) {
        final next = _queuedSeek!;
        _queuedSeek = null;
        final shouldResume = _resumeAfterSeek;
        _resumeAfterSeek = false;
        if (_player.playing) {
          await _player.pause();
        }
        if (!isActive) return;
        _pendingSeek = next;
        _position = next;
        await _player.seek(next);
        _position = next;
        _notifyListenersSafely();
        if (shouldResume && isActive && _queuedSeek == null) {
          _keepPauseIcon = true;
          unawaited(_player.play().catchError((Object error) {
            debugPrint('ChatVoicePlayerService resume after seek error: $error');
            _keepPauseIcon = false;
            _notifyListenersSafely();
          }));
        } else if (_queuedSeek != null) {
          _resumeAfterSeek = shouldResume || _resumeAfterSeek;
          _keepPauseIcon = _resumeAfterSeek;
        } else {
          _keepPauseIcon = false;
        }
      }
    } catch (error) {
      debugPrint('ChatVoicePlayerService seek error: $error');
    } finally {
      _seekInFlight = false;
      // Не сбрасываем цель, пока плеер сам не подтвердит новую позицию.
      // Иначе старый кадр снова отбросит линию в начало.
      if (_queuedSeek != null && isActive) {
        unawaited(seekToFraction(
          duration.inMilliseconds == 0
              ? 0
              : _queuedSeek!.inMilliseconds / duration.inMilliseconds,
        ));
      }
    }
  }

  Future<void> _ensureSpeedLoaded() async {
    if (_speedLoaded) return;
    _speedLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(chatVoiceSpeedPrefsKey);
      if (stored == null) return;
      final known = voicePlaybackSpeeds.any(
        (speed) => (speed - stored).abs() < 0.01,
      );
      if (!known) return;
      _speed = stored;
    } catch (error) {
      debugPrint('ChatVoicePlayerService speed load error: $error');
    }
  }

  /// Запись доиграла. Если в чате есть следующее голосовое — включаем его.
  Future<void> _handleCompleted() async {
    if (_handlingComplete || _switchingTrack) return;
    _handlingComplete = true;
    _switchingTrack = true;
    final generation = _playGeneration;
    final current = _track;
    final next = current == null ? null : chatVoiceNextResolver?.call(current);
    _handlingComplete = false;
    if (generation != _playGeneration) return;
    if (next != null) {
      await play(next);
      return;
    }
    await stop();
  }

  Future<void> stop() async {
    _switchingTrack = true;
    _playGeneration++;
    _track = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    try {
      await _player.stop();
    } catch (error) {
      debugPrint('ChatVoicePlayerService stop error: $error');
    }
    _notifyListenersSafely();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
