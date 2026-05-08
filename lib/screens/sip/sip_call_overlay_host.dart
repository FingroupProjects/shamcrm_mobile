import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  final SipService _sipService = SipService();
  final AudioPlayer _overlayPlayer = AudioPlayer();

  late final AnimationController _pulseController;
  Timer? _durationTimer;
  SipCallUiStatus? _lastObservedStatus;
  String? _activeFeedbackAsset;
  DateTime? _connectedAt;
  Duration _connectedDuration = Duration.zero;
  double _incomingAnswerDrag = 0;

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
      return;
    }

    if (_lastObservedStatus == state.callStatus) {
      return;
    }
    _lastObservedStatus = state.callStatus;

    switch (state.callStatus) {
      case SipCallUiStatus.incoming:
        _stopDurationTicker();
        unawaited(_playFeedbackLoop('audio/get.mp3'));
        break;
      case SipCallUiStatus.calling:
      case SipCallUiStatus.ringing:
        _stopDurationTicker();
        unawaited(_stopFeedbackLoop());
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

  Future<void> _playFeedbackLoop(String assetPath) async {
    if (_activeFeedbackAsset == assetPath) return;
    _activeFeedbackAsset = assetPath;
    try {
      await _overlayPlayer.stop();
      await _overlayPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> _stopFeedbackLoop() async {
    _activeFeedbackAsset = null;
    try {
      await _overlayPlayer.stop();
    } catch (_) {}
  }

  void _startDurationTicker() {
    _connectedAt ??= DateTime.now();
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _connectedAt == null) return;
      setState(() {
        _connectedDuration = DateTime.now().difference(_connectedAt!);
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
        return 'Исходящий звонок';
      case SipCallUiStatus.ringing:
        return 'Ждём ответ';
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
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  List<Color> _callGradient(bool isDark) {
    return isDark
        ? const [
            Color(0xFF0A0E1A),
            Color(0xFF0F1E4A),
            Color(0xFF112960),
            Color(0xFF0D1F45),
          ]
        : const [
            Color(0xFFF8FAFD),
            Color(0xFFEFF4FF),
            Color(0xFFF4F8FF),
            Color(0xFFF7FAFD),
          ];
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
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SipScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sipService,
      builder: (context, _) {
        final state = _sipService.state;
        final showOverlay = _shouldShowOverlay(state);
        _syncFeedback(state, showOverlay);
        final isDark = _isDarkSipTheme(context);

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

        final accent = _accent(state.callStatus);
        final identity = _displayIdentity(state);
        final pulse = CurvedAnimation(
          parent: _pulseController,
          curve: Curves.easeInOut,
        );

        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: Material(
                color: isDark
                    ? const Color(0xFF071120).withValues(alpha: 0.76)
                    : const Color(0xFFF4F8FF).withValues(alpha: 0.94),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : const Color(0xFFE1EAF6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.phone_fill,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'SHAMCRM SIP',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _openSipScreen,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : const Color(0xFFE1EAF6),
                                  ),
                                ),
                                child: Text(
                                  'Открыть SIP',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          _callLabel(state.callStatus),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.88)
                                : const Color(0xFF64748B),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          identity,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 38,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: pulse,
                          builder: (context, child) {
                            final outerScale = 0.92 + pulse.value * 0.14;
                            final midScale = 0.96 + pulse.value * 0.08;
                            return SizedBox(
                              width: 230,
                              height: 230,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: outerScale,
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent.withValues(
                                          alpha: isDark ? 0.10 : 0.06,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: midScale,
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent.withValues(
                                          alpha: isDark ? 0.16 : 0.10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 118,
                                    height: 118,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          accent.withValues(alpha: 0.95),
                                          accent.withValues(alpha: 0.72),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.42),
                                          blurRadius: 28,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      state.callStatus ==
                                              SipCallUiStatus.incoming
                                          ? CupertinoIcons.phone_down_fill
                                          : CupertinoIcons.phone_fill,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        if (state.callStatus == SipCallUiStatus.inCall)
                          Text(
                            _formatDuration(_connectedDuration),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.96)
                                  : const Color(0xFF0F172A),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          Text(
                            state.callStatus == SipCallUiStatus.incoming
                                ? 'Примите или отклоните вызов'
                                : 'Поддерживаем звонок внутри CRM',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.76)
                                  : const Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const Spacer(),
                        if (state.callStatus == SipCallUiStatus.incoming)
                          Row(
                            children: [
                              Expanded(
                                child: _actionButton(
                                  label: 'Отклонить',
                                  color: const Color(0xFFEF4444),
                                  icon: CupertinoIcons.phone_down_fill,
                                  onPressed: _sipService.decline,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _actionButton(
                                  label: 'Ответить',
                                  color: const Color(0xFF22C55E),
                                  icon: CupertinoIcons.phone_fill,
                                  onPressed: _sipService.acceptCall,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniControl(
                                      label: state.isMuted
                                          ? 'Микрофон выкл'
                                          : 'Микрофон',
                                      icon: state.isMuted
                                          ? CupertinoIcons.mic_slash_fill
                                          : CupertinoIcons.mic_fill,
                                      active: state.isMuted,
                                      onPressed: _sipService.toggleMute,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _miniControl(
                                      label: 'Динамик',
                                      icon: CupertinoIcons.speaker_3_fill,
                                      active: state.isSpeakerOn,
                                      onPressed: _sipService.toggleSpeaker,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: _actionButton(
                                  label: 'Завершить',
                                  color: const Color(0xFFEF4444),
                                  icon: CupertinoIcons.phone_down_fill,
                                  onPressed: _sipService.hangup,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _incomingOverlayView(SipUiState state) {
    final identity = _displayIdentity(state);
    final isDark = _isDarkSipTheme(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.35, 0.65, 1],
            colors: _callGradient(isDark),
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
                  gradient: RadialGradient(
                    colors: [
                      isDark
                          ? const Color(0x303D8EFF)
                          : const Color(0x143D8EFF),
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
                  gradient: RadialGradient(
                    colors: [
                      isDark
                          ? const Color(0x252563EB)
                          : const Color(0x102563EB),
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
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFE1EAF6),
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
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xAAFFFFFF)
                                  : const Color(0xFF64748B),
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
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                color: (isDark
                                        ? Colors.white
                                        : const Color(0xFF64748B))
                                    .withValues(alpha: opacity),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Входящий звонок',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0x66FFFFFF)
                            : const Color(0xFF7C8CA5),
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
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFE1EAF6),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.alarm,
                                color: isDark
                                    ? const Color(0xAAFFFFFF)
                                    : const Color(0xFF64748B),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Напомнить',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xAAFFFFFF)
                                  : const Color(0xFF64748B),
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
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFE1EAF6),
                          ),
                        ),
                        child: Text(
                          'Отклонить',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xAAFFFFFF)
                                : const Color(0xFF64748B),
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
        final isDark = _isDarkSipTheme(context);
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
              color: isDark ? const Color(0x14FFFFFF) : Colors.white,
              borderRadius: BorderRadius.circular(52),
              border: Border.all(
                color:
                    isDark ? const Color(0x28FFFFFF) : const Color(0xFFE1EAF6),
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
                        style: TextStyle(
                          color: isDark
                              ? const Color(0x99FFFFFF)
                              : const Color(0xFF7C8CA5),
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
                          color: isDark
                              ? const Color(0x33000000)
                              : const Color(0x140F172A),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.chevron_forward,
                      color: Color(0xFF3D8EFF),
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

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.34),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniControl({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.22 : 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: active ? 0.24 : 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
