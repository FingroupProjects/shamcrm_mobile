import 'dart:async';

import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

const List<double> voicePlaybackSpeeds = [1.0, 1.5, 2.0];

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
        unawaited(stop());
        return;
      }
      _notifyListenersSafely();
    });
    _positionSub = _player.positionStream.listen((position) {
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
  int _playGeneration = 0;
  int? _foregroundChatId;

  ChatVoiceTrack? get track => _track;
  Duration get position => _position;
  Duration get duration {
    if (_duration > Duration.zero) return _duration;
    return _track?.duration ?? Duration.zero;
  }

  double get speed => _speed;
  bool get isActive => _track != null;
  bool get isPlaying => _player.playing && isActive;
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

  Future<void> play(ChatVoiceTrack track) async {
    final generation = ++_playGeneration;
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
      await _player.play();
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
    await _player.pause();
    _notifyListenersSafely();
  }

  Future<void> resume() async {
    if (!isActive) return;
    await _player.play();
    _notifyListenersSafely();
  }

  Future<void> cycleSpeed() async {
    _speed = nextVoicePlaybackSpeed(_speed);
    await _player.setSpeed(_speed);
    _notifyListenersSafely();
  }

  Future<void> stop() async {
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
