import 'dart:async';

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
        unawaited(_playFeedbackLoop('audio/send.mp3'));
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

        if (!showOverlay) {
          return widget.child;
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
                color: const Color(0xFF071120).withValues(alpha: 0.76),
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
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.phone_fill,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'SHAMCRM SIP',
                                    style: TextStyle(
                                      color: Colors.white,
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
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Text(
                                  'Открыть SIP',
                                  style: TextStyle(
                                    color: Colors.white,
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
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          identity,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
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
                                        color: accent.withValues(alpha: 0.10),
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
                                        color: accent.withValues(alpha: 0.16),
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
                              color: Colors.white.withValues(alpha: 0.96),
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
                              color: Colors.white.withValues(alpha: 0.76),
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
                                      label: state.isSpeakerOn
                                          ? 'Динамик'
                                          : 'Трубка',
                                      icon: state.isSpeakerOn
                                          ? CupertinoIcons.speaker_3_fill
                                          : CupertinoIcons.speaker_1_fill,
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
