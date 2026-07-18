import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:crm_task_manager/app_feature_flags.dart';
import 'package:crm_task_manager/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sip_screen.dart';
import 'sip_service.dart';
import 'sip_state.dart';

class SipCallOverlayHost extends StatefulWidget {
  final Widget child;

  const SipCallOverlayHost({
    super.key,
    required this.child,
  });

  @override
  State<SipCallOverlayHost> createState() => _SipCallOverlayHostState();
}

class _SipCallOverlayHostState extends State<SipCallOverlayHost>
    with SingleTickerProviderStateMixin {
  static const String _sipPinRequiredAfterCallKey =
      'sip_pin_required_after_call_v1';

  final SipService _sipService = SipService();
  final AudioPlayer _overlayPlayer = AudioPlayer();

  static const String _operatorConnectingAsset = 'audio/operator_1.mp3';
  static const String _connectingBeepAsset = 'audio/get.mp3';

  late final AnimationController _pulseController;
  Timer? _durationTimer;
  StreamSubscription<void>? _feedbackCompletionSub;
  SipCallUiStatus? _lastObservedStatus;
  String? _activeFeedbackAsset;
  DateTime? _connectedAt;
  Duration _connectedDuration = Duration.zero;
  double _incomingAnswerDrag = 0;
  Offset _miniCallOffset = Offset.zero;
  bool _isMiniCallDragging = false;
  bool _isMiniCallDockedAway = false;
  bool _hadVisibleCallOverlay = false;
  bool _pinRedirectInProgress = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _configurePlayer();
    unawaited(_sipService.initialize());
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _feedbackCompletionSub?.cancel();
    _pulseController.dispose();
    unawaited(_overlayPlayer.stop());
    _overlayPlayer.dispose();
    super.dispose();
  }

  Future<void> _configurePlayer() async {
    try {
      await _overlayPlayer.setReleaseMode(ReleaseMode.loop);
      await _overlayPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _overlayPlayer.setVolume(1);
    } catch (_) {}
  }

  bool _shouldShowOverlay(SipUiState state) {
    if (!kShowSip) return false;
    return !_sipService.isSipScreenVisible &&
        (state.callStatus == SipCallUiStatus.incoming ||
            state.callStatus == SipCallUiStatus.calling ||
            state.callStatus == SipCallUiStatus.ringing ||
            state.callStatus == SipCallUiStatus.inCall);
  }

  void _syncFeedback(SipUiState state, bool visible) {
    if (!visible) {
      _lastObservedStatus = null;
      _stopDurationTicker(reset: true);
      unawaited(_stopFeedbackLoop());
      if (_hadVisibleCallOverlay) {
        _hadVisibleCallOverlay = false;
        unawaited(_redirectToPinIfDeferredBySipCall());
      }
      return;
    }

    _hadVisibleCallOverlay = true;

    if (_lastObservedStatus == state.callStatus) {
      return;
    }
    _lastObservedStatus = state.callStatus;

    switch (state.callStatus) {
      case SipCallUiStatus.incoming:
        _stopDurationTicker();
        unawaited(_playFeedbackLoop(_connectingBeepAsset));
        break;
      case SipCallUiStatus.calling:
      case SipCallUiStatus.ringing:
        _stopDurationTicker();
        unawaited(_playOperatorThenBeep());
        break;
      case SipCallUiStatus.inCall:
        _startDurationTicker();
        unawaited(_stopFeedbackLoop());
        break;
      case SipCallUiStatus.idle:
      case SipCallUiStatus.ended:
      case SipCallUiStatus.failed:
        _stopDurationTicker(reset: true);
        unawaited(_stopFeedbackLoop());
        break;
    }
  }

  Future<void> _playOperatorThenBeep() async {
    if (_activeFeedbackAsset == _operatorConnectingAsset) return;
    _activeFeedbackAsset = _operatorConnectingAsset;

    try {
      await _feedbackCompletionSub?.cancel();
      _feedbackCompletionSub = _overlayPlayer.onPlayerComplete.listen((_) {
        if (_activeFeedbackAsset != _operatorConnectingAsset) return;
        unawaited(_playFeedbackLoop(_connectingBeepAsset));
      });

      await _overlayPlayer.stop();
      await _overlayPlayer.setReleaseMode(ReleaseMode.stop);
      await _overlayPlayer.play(AssetSource(_operatorConnectingAsset));
    } catch (_) {}
  }

  Future<void> _playFeedbackLoop(String assetPath) async {
    if (_activeFeedbackAsset == assetPath) return;
    _activeFeedbackAsset = assetPath;
    try {
      await _feedbackCompletionSub?.cancel();
      _feedbackCompletionSub = null;
      await _overlayPlayer.stop();
      await _overlayPlayer.setReleaseMode(ReleaseMode.loop);
      await _overlayPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> _stopFeedbackLoop() async {
    _activeFeedbackAsset = null;
    try {
      await _feedbackCompletionSub?.cancel();
      _feedbackCompletionSub = null;
      await _overlayPlayer.stop();
    } catch (_) {}
  }

  void _startDurationTicker() {
    _connectedAt =
        _sipService.currentCallStartedAt ?? _connectedAt ?? DateTime.now();
    _connectedDuration = _sipService.currentCallDuration;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _connectedDuration = _sipService.currentCallDuration;
      });
    });
  }

  void _stopDurationTicker({bool reset = false}) {
    _durationTimer?.cancel();
    _durationTimer = null;
    if (reset) {
      _connectedAt = null;
      _connectedDuration = Duration.zero;
    }
  }

  String _displayIdentity(SipUiState state) {
    final raw = state.remoteIdentity?.trim().isNotEmpty == true
        ? state.remoteIdentity!.trim()
        : state.sipId.trim();
    if (raw.isEmpty) return 'Неизвестный номер';

    var normalized = raw;
    if (normalized.startsWith('sip:')) {
      normalized = normalized.substring(4);
    }
    if (normalized.contains('@')) {
      normalized = normalized.split('@').first;
    }
    return normalized.isEmpty ? 'Неизвестный номер' : normalized;
  }

  String _callLabel(SipCallUiStatus status) {
    switch (status) {
      case SipCallUiStatus.incoming:
        return 'Входящий звонок';
      case SipCallUiStatus.calling:
        return 'Соединяем звонок';
      case SipCallUiStatus.ringing:
        return 'Подключаем вас к клиенту';
      case SipCallUiStatus.inCall:
        return 'Разговор';
      case SipCallUiStatus.ended:
        return 'Звонок завершен';
      case SipCallUiStatus.failed:
        return 'Ошибка звонка';
      case SipCallUiStatus.idle:
        return 'Ожидание';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool _isDarkSipTheme(BuildContext context) {
    // Временно скрываем тёмную SIP-тему и overlay от пользователей,
    // даже если системная тема устройства тёмная.
    return false;
  }

  Color _accent(SipCallUiStatus status) {
    switch (status) {
      case SipCallUiStatus.incoming:
        return const Color(0xFFF59E0B);
      case SipCallUiStatus.calling:
      case SipCallUiStatus.ringing:
        return const Color(0xFF2563EB);
      case SipCallUiStatus.inCall:
        return const Color(0xFF10B981);
      case SipCallUiStatus.failed:
        return const Color(0xFFEF4444);
      case SipCallUiStatus.idle:
      case SipCallUiStatus.ended:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _openSipScreen() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (_isProtectedSipCallActive()) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const SipScreen(),
          fullscreenDialog: true,
          settings: const RouteSettings(name: '/sip_call_only'),
        ),
        (route) => false,
      );
      return;
    }

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const SipScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  bool _isProtectedSipCallActive() {
    final status = _sipService.state.callStatus;
    return status == SipCallUiStatus.incoming ||
        status == SipCallUiStatus.calling ||
        status == SipCallUiStatus.ringing ||
        status == SipCallUiStatus.inCall;
  }

  Future<void> _redirectToPinIfDeferredBySipCall() async {
    if (_pinRedirectInProgress) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldRequirePin =
          prefs.getBool(_sipPinRequiredAfterCallKey) ?? false;
      if (!shouldRequirePin) return;

      _pinRedirectInProgress = true;
      await prefs.remove(_sipPinRequiredAfterCallKey);

      final navigator = navigatorKey.currentState;
      if (navigator == null || !mounted) return;

      navigator.pushNamedAndRemoveUntil('/pin_screen', (route) => false);
    } finally {
      _pinRedirectInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sipService,
      builder: (context, _) {
        final state = _sipService.state;
        final showOverlay = _shouldShowOverlay(state);
        _syncFeedback(state, showOverlay);

        if (!showOverlay) {
          return widget.child;
        }

        if (state.callStatus == SipCallUiStatus.incoming) {
          return Stack(
            children: [
              widget.child,
              Positioned.fill(child: _incomingOverlayView(state)),
            ],
          );
        }

        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: _activeCallMiniOverlay(state),
            ),
          ],
        );
      },
    );
  }

  Widget _activeCallMiniOverlay(SipUiState state) {
    final isDark = _isDarkSipTheme(context);
    final accent = _accent(state.callStatus);
    final identity = _displayIdentity(state);
    final statusText = state.callStatus == SipCallUiStatus.inCall
        ? _formatDuration(_connectedDuration)
        : _callLabel(state.callStatus);
    final compactMode = _isMiniCallDragging || _isMiniCallDockedAway;
    final displayText = state.callStatus == SipCallUiStatus.inCall
        ? _formatDuration(_connectedDuration)
        : statusText;

    return IgnorePointer(
      ignoring: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final topInset = MediaQuery.of(context).padding.top + 6;
          final capsuleWidth = compactMode ? 220.0 : 240.0;
          final capsuleHeight = compactMode ? 38.0 : 40.0;
          final defaultLeft = (constraints.maxWidth - capsuleWidth) / 2;
          final defaultTop = topInset;
          final maxLeft =
              math.max(0.0, constraints.maxWidth - capsuleWidth - 12);
          final maxTop =
              math.max(defaultTop, constraints.maxHeight - capsuleHeight - 24);
          final left = (defaultLeft + _miniCallOffset.dx).clamp(12.0, maxLeft);
          final top =
              (defaultTop + _miniCallOffset.dy).clamp(defaultTop, maxTop);

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openSipScreen,
                  onPanStart: (_) {
                    if (!mounted) return;
                    setState(() {
                      _isMiniCallDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    if (!mounted) return;
                    setState(() {
                      _miniCallOffset += details.delta;
                    });
                  },
                  onPanEnd: (_) {
                    if (!mounted) return;
                    final shouldSnapBack = _miniCallOffset.distance <= 56;
                    setState(() {
                      _isMiniCallDragging = false;
                      if (shouldSnapBack) {
                        _miniCallOffset = Offset.zero;
                        _isMiniCallDockedAway = false;
                      } else {
                        _isMiniCallDockedAway = true;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: compactMode ? null : 240.0,
                    height: capsuleHeight,
                    constraints: BoxConstraints(
                      minWidth: compactMode ? 76.0 : 240.0,
                      maxWidth: compactMode ? 220.0 : 240.0,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: compactMode ? 12 : 16,
                      vertical: compactMode ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF101826).withValues(alpha: 0.94)
                          : Colors.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFE1EAF6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF111827)
                              .withValues(alpha: compactMode ? 0.10 : 0.08),
                          blurRadius: compactMode ? 16 : 14,
                          offset: Offset(0, compactMode ? 8 : 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: compactMode ? 24 : 26,
                          height: compactMode ? 22 : 24,
                          decoration: BoxDecoration(
                            color:
                                accent.withValues(alpha: isDark ? 0.22 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.phone_fill,
                            color: accent,
                            size: compactMode ? 12 : 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (compactMode)
                          Text(
                            displayText,
                            maxLines: 1,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              displayText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        if (!compactMode) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              identity,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.74)
                                    : const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _incomingOverlayView(SipUiState state) {
    final identity = _displayIdentity(state);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.35, 0.65, 1],
            colors: [
              Color(0xFF6A676C),
              Color(0xFF535D8F),
              Color(0xFF3D6E82),
              Color(0xFF2B7D88),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0x223D8EFF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0x1F2563EB),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D8EFF)
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              CupertinoIcons.sparkles,
                              color: Color(0xFF3D8EFF),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Аудиовызов shamCRM',
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3D8EFF), Color(0xFF2563EB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF3D8EFF).withValues(alpha: 0.4),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color:
                                const Color(0xFF3D8EFF).withValues(alpha: 0.2),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      identity,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1.6,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            final delay = i * 0.28;
                            final t = (_pulseController.value - delay)
                                .clamp(0.0, 1.0);
                            final opacity =
                                (math.sin(t * math.pi)).clamp(0.2, 1.0);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: opacity),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Входящий звонок',
                      style: const TextStyle(
                        color: Color(0xAAFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.alarm,
                                color: const Color(0xCCFFFFFF),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Напомнить',
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _incomingOverlayAnswerSlider(),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _sipService.decline,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          'Отклонить',
                          style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incomingOverlayAnswerSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const knobSize = 80.0;
        const horizontalPadding = 10.0;
        final maxDrag = math.max(
            0.0, constraints.maxWidth - knobSize - horizontalPadding * 2);
        final knobOffset = (_incomingAnswerDrag * maxDrag).clamp(0.0, maxDrag);

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (maxDrag <= 0) return;
            setState(() {
              _incomingAnswerDrag =
                  (_incomingAnswerDrag + details.delta.dx / maxDrag)
                      .clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_incomingAnswerDrag >= 0.82) {
              _incomingAnswerDrag = 0;
              _sipService.acceptCall();
              return;
            }
            setState(() {
              _incomingAnswerDrag = 0;
            });
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(52),
              border: Border.all(
                color: const Color(0x3300D9FF),
                width: 0.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: 1 - (_incomingAnswerDrag * 0.9),
                      child: Text(
                        'Ответьте',
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: horizontalPadding + knobOffset,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x33000000),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.chevron_forward,
                      color: Color(0xFF2563EB),
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
