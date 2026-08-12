import 'dart:async';
import 'dart:math' as math;

import 'package:crm_task_manager/app_feature_flags.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/app/app_keys.dart';
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

String _restoreTajikPlusForDisplay(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.startsWith('+')) {
    return trimmed;
  }

  final phoneFormattedOnly = RegExp(r'^[0-9\s().-]+$').hasMatch(trimmed);
  if (!phoneFormattedOnly) {
    return trimmed;
  }

  final digits = trimmed.replaceAll(RegExp(r'[\s().-]'), '');
  if (RegExp(r'^992\d{9}$').hasMatch(digits)) {
    return '+$digits';
  }

  return trimmed;
}

class _SipCallOverlayHostState extends State<SipCallOverlayHost>
    with SingleTickerProviderStateMixin {
  static const String _sipPinRequiredAfterCallKey =
      'sip_pin_required_after_call_v1';

  final SipService _sipService = SipService();
  late final AnimationController _pulseController;
  Timer? _durationTimer;
  SipCallUiStatus? _lastObservedStatus;
  DateTime? _connectedAt;
  Duration _connectedDuration = Duration.zero;
  double _incomingAnswerDrag = 0;
  Offset _miniCallOffset = Offset.zero;
  bool _isMiniCallDragging = false;
  bool _isMiniCallDockedAway = false;
  bool _hadVisibleCallOverlay = false;
  bool _pinRedirectInProgress = false;
  bool _fullCallUiOpenInProgress = false;
  int _lastHandledCallUiRequestSerial = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    unawaited(_sipService.initialize());
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  bool _shouldShowOverlay(SipUiState state) {
    if (!kShowSip) return false;
    // isSipScreenOpenClaimed covers the gap after lead/CRM claims the UI but
    // before SipScreen.setSipScreenVisible(true) runs — otherwise the mini
    // overlay flashes and can trigger deferred PIN redirect mid-call.
    return !_sipService.isSipScreenVisible &&
        !_sipService.isSipScreenOpenClaimed &&
        (state.callStatus == SipCallUiStatus.incoming ||
            state.callStatus == SipCallUiStatus.calling ||
            state.callStatus == SipCallUiStatus.ringing ||
            state.callStatus == SipCallUiStatus.inCall);
  }

  void _syncFeedback(SipUiState state, bool visible) {
    if (!visible) {
      _lastObservedStatus = null;
      _stopDurationTicker(reset: true);
      if (_hadVisibleCallOverlay) {
        _hadVisibleCallOverlay = false;
        // Only ask for PIN after a call fully ended. If overlay hid because
        // SipScreen opened (or claim flipped), redirecting now would
        // pushNamedAndRemoveUntil('/pin_screen') and tear down the call UI.
        if (!_isProtectedSipCallActive()) {
          unawaited(_redirectToPinIfDeferredBySipCall());
        }
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
        break;
      case SipCallUiStatus.calling:
      case SipCallUiStatus.ringing:
        _stopDurationTicker();
        break;
      case SipCallUiStatus.inCall:
        _startDurationTicker();
        break;
      case SipCallUiStatus.idle:
      case SipCallUiStatus.ended:
      case SipCallUiStatus.failed:
        _stopDurationTicker(reset: true);
        break;
    }
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
    final callDisplayName = _sipService.currentCallDisplayName?.trim();
    final callTarget = _sipService.currentCallTarget?.trim();
    final raw = callDisplayName?.isNotEmpty == true
        ? callDisplayName!
        : state.remoteIdentity?.trim().isNotEmpty == true
            ? state.remoteIdentity!.trim()
            : callTarget?.isNotEmpty == true
                ? callTarget!
                : state.sipId.trim();
    if (raw.isEmpty) return 'Неизвестный номер';

    var normalized = raw;
    if (normalized.startsWith('sip:')) {
      normalized = normalized.substring(4);
    }
    if (normalized.contains('@')) {
      normalized = normalized.split('@').first;
    }
    return normalized.isEmpty
        ? 'Неизвестный номер'
        : _restoreTajikPlusForDisplay(normalized);
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

  Future<bool> _openSipScreen() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null || _sipService.isSipScreenVisible) return false;
    if (!_sipService.claimSipScreenOpen()) return false;

    try {
      unawaited(navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const SipScreen(),
          fullscreenDialog: true,
          settings: const RouteSettings(name: '/sip_call'),
        ),
      ));
      return true;
    } catch (_) {
      _sipService.releaseSipScreenOpenClaim();
      rethrow;
    }
  }

  void _handleNativeCallUiRequest(SipUiState state) {
    final serial = _sipService.callUiOpenRequestSerial;
    if (serial == 0 || serial == _lastHandledCallUiRequestSerial) return;

    final active = state.callStatus == SipCallUiStatus.incoming ||
        state.callStatus == SipCallUiStatus.calling ||
        state.callStatus == SipCallUiStatus.ringing ||
        state.callStatus == SipCallUiStatus.inCall;
    if (!active) {
      _lastHandledCallUiRequestSerial = serial;
      unawaited(_sipService.recordUiDiagnostic(
        'CALL_UI_IGNORED_INACTIVE_STATE',
        <String, Object?>{
          'serial': serial,
          'call_state': state.callStatus.name,
          'registration_state': state.registrationStatus.name,
        },
      ));
      return;
    }
    _lastHandledCallUiRequestSerial = serial;
    if (_fullCallUiOpenInProgress ||
        _sipService.isSipScreenVisible ||
        _sipService.isSipScreenOpenClaimed) {
      unawaited(_sipService.recordUiDiagnostic(
        'CALL_UI_ALREADY_VISIBLE',
        <String, Object?>{
          'serial': serial,
          'sip_screen_visible': _sipService.isSipScreenVisible,
          'open_in_progress': _fullCallUiOpenInProgress,
        },
      ));
      return;
    }

    _fullCallUiOpenInProgress = true;
    unawaited(_sipService.recordUiDiagnostic(
      'CALL_UI_OPEN_SCHEDULED',
      <String, Object?>{
        'serial': serial,
        'call_state': state.callStatus.name,
        'replacing_visible_sip_screen': _sipService.isSipScreenVisible,
      },
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || !_isProtectedSipCallActive()) {
          await _sipService.recordUiDiagnostic(
            'CALL_UI_OPEN_ABORTED',
            <String, Object?>{
              'serial': serial,
              'mounted': mounted,
              'call_state': _sipService.state.callStatus.name,
            },
          );
          return;
        }
        final opened = await _openSipScreen();
        await _sipService.recordUiDiagnostic(
          opened ? 'CALL_UI_OPENED' : 'CALL_UI_OPEN_SKIPPED_CLAIMED',
          <String, Object?>{'serial': serial},
        );
      } catch (error) {
        await _sipService.recordUiDiagnostic(
          'CALL_UI_OPEN_FAILED',
          <String, Object?>{
            'serial': serial,
            'error': error,
          },
        );
      } finally {
        _fullCallUiOpenInProgress = false;
      }
    });
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
        _handleNativeCallUiRequest(state);
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
    final colors = context.appColors;
    final accent = switch (state.callStatus) {
      SipCallUiStatus.incoming => colors.warning,
      SipCallUiStatus.calling || SipCallUiStatus.ringing => colors.info,
      SipCallUiStatus.inCall => colors.success,
      SipCallUiStatus.failed => colors.error,
      SipCallUiStatus.idle || SipCallUiStatus.ended => colors.textMuted,
    };
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
                      color: colors.surfaceElevated.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.72),
                      ),
                      boxShadow: context.appShadows.floating,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: compactMode ? 24 : 26,
                          height: compactMode ? 22 : 24,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
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
                              color: colors.textPrimary,
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
                                color: colors.textPrimary,
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
                                color: colors.textSecondary,
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
            stops: [0, 0.48, 1],
            colors: [
              Color(0xFF080C18),
              Color(0xFF0D1730),
              Color(0xFF0A1A2E),
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
                      // Рабочая кнопка напоминания живёт на полном экране
                      // звонка, поэтому из оверлея просто открываем его.
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _openSipScreen,
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
          onTap: () {
            _incomingAnswerDrag = 0;
            unawaited(_sipService.acceptCall());
          },
          onHorizontalDragUpdate: (details) {
            if (maxDrag <= 0) return;
            setState(() {
              _incomingAnswerDrag =
                  (_incomingAnswerDrag + details.delta.dx / maxDrag)
                      .clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_incomingAnswerDrag >= 0.60) {
              _incomingAnswerDrag = 0;
              unawaited(_sipService.acceptCall());
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
