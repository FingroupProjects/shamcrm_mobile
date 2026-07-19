// Этот файл отвечает за интерфейс активного и входящего SIP-звонка.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipCallViewsExtension on _SipScreenState {
  Widget _activeCallView(BuildContext context, SipUiState state) {
    final target = _displayIdentity(state);
    final isConnected = state.callStatus == SipCallUiStatus.inCall;
    final statusText =
        isConnected ? _formatDuration(_connectedDuration) : _callHint(state);
    final isDark = _isDarkSipTheme(context);

    if (state.callStatus == SipCallUiStatus.incoming) {
      return _incomingCallView(
        context,
        target: target,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _callGradient(isDark)
              .map((color) => color.withValues(alpha: isDark ? 0.42 : 0.16))
              .toList(growable: false),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 760;
              if (_showInCallKeypad) {
                return _activeCallKeypadView(
                  context,
                  state,
                  compact: compact,
                  isConnected: isConnected,
                  isDark: isDark,
                );
              }

              return Column(
                children: [
                  _buildActiveCallTopBar(context, isDark: isDark),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 18 : 34),
                        _GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          borderRadius: 20,
                          color: _callGlassFill(isDark),
                          borderColor: _callGlassBorder(isDark),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isConnected ? _G.green : _G.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isConnected ? _G.green : _G.accent)
                                              .withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isConnected
                                    ? 'Вызов активен'
                                    : _resolvedCallLabel(context, state),
                                style: TextStyle(
                                  color: _callSecondaryText(isDark),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 16),
                        Text(
                          target,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _callPrimaryText(isDark),
                            fontSize: compact ? 40 : 50,
                            height: 0.96,
                            fontWeight: FontWeight.w300,
                            letterSpacing: compact ? -1.8 : -2.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _callTertiaryText(isDark),
                            fontSize: compact ? 16 : 18,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        _iosCallControls(
                          context,
                          state,
                          compact: compact,
                          isDark: isDark,
                        ),
                        SizedBox(height: compact ? 4 : 8),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _activeCallKeypadView(
    BuildContext context,
    SipUiState state, {
    required bool compact,
    required bool isConnected,
    required bool isDark,
  }) {
    final headline = _inCallDigits.isNotEmpty
        ? _inCallDigits
        : (isConnected
            ? _formatDuration(_connectedDuration)
            : _resolvedCallLabel(context, state));
    final subtitle =
        _inCallDigits.isNotEmpty ? 'Тональный набор' : (isConnected ? '' : '');

    return Column(
      children: [
        _buildActiveCallTopBar(context, isDark: isDark),
        Expanded(
          child: Column(
            children: [
              SizedBox(height: compact ? 6 : 14),
              _GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 20,
                color: _callGlassFill(isDark),
                borderColor: _callGlassBorder(isDark),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? _G.green : _G.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected ? _G.green : _G.accent)
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected
                          ? 'Вызов активен'
                          : _resolvedCallLabel(context, state),
                      style: TextStyle(
                        color: _callSecondaryText(isDark),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 18 : 22),
              Text(
                headline,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _callPrimaryText(isDark),
                  fontSize: _inCallDigits.isNotEmpty
                      ? (compact ? 36 : 42)
                      : (isConnected
                          ? (compact ? 38 : 46)
                          : (compact ? 28 : 32)),
                  fontWeight: FontWeight.w300,
                  letterSpacing:
                      _inCallDigits.isNotEmpty || isConnected ? -1.2 : -0.6,
                  height: 1,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _callTertiaryText(isDark),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              SizedBox(height: compact ? 12 : 22),
              Expanded(
                child: _nativeInCallKeypadGrid(
                  compact: compact,
                  isDark: isDark,
                ),
              ),
              SizedBox(height: compact ? 12 : 20),
              _iosCallControls(
                context,
                state,
                compact: compact,
                keypadVisible: true,
                isDark: isDark,
              ),
              SizedBox(height: compact ? 6 : 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nativeInCallKeypadGrid({
    required bool compact,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = compact ? 12.0 : 18.0;
        final widthBased = (constraints.maxWidth - spacing * 2) / 3;
        final heightBased = (constraints.maxHeight - spacing * 3) / 4;
        final buttonSize = math.min(widthBased, heightBased).clamp(64.0, 104.0);
        final totalWidth = buttonSize * 3 + spacing * 2;

        return Center(
          child: SizedBox(
            width: totalWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (row) {
                final start = row * 3;
                return Padding(
                  padding: EdgeInsets.only(bottom: row == 3 ? 0 : spacing),
                  child: Row(
                    children: List.generate(3, (col) {
                      final item = _SipScreenState._dialPadItems[start + col];
                      return Padding(
                        padding: EdgeInsets.only(right: col == 2 ? 0 : spacing),
                        child: _nativeInCallKeypadButton(
                          value: item['key']!,
                          letters: item['letters']!,
                          size: buttonSize,
                          isDark: isDark,
                          onTap: () => _handleInCallTone(item['key']!),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _nativeInCallKeypadButton({
    required String value,
    required String letters,
    required double size,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFE1EAF6),
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDark ? _G.textPrimary : _G.lightText,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w300,
                height: 1,
              ),
            ),
            if (letters.isNotEmpty) ...[
              SizedBox(height: size * 0.05),
              Text(
                letters,
                style: TextStyle(
                  color: isDark ? _G.textTertiary : const Color(0xFF7C8CA5),
                  fontSize: math.max(10, size * 0.11),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _incomingCallView(
    BuildContext context, {
    required String target,
  }) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.45, 1],
          colors: [
            colors.backgroundPrimary.withValues(alpha: isDark ? 0.62 : 0.24),
            colors.surfaceAccent.withValues(alpha: isDark ? 0.48 : 0.18),
            colors.backgroundSecondary.withValues(alpha: isDark ? 0.66 : 0.28),
          ],
        ),
      ),
      child: Stack(
        children: [
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
                            color: _G.accent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            CupertinoIcons.sparkles,
                            color: _G.accent,
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
                          color: const Color(0xFF3D8EFF).withValues(alpha: 0.4),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFF3D8EFF).withValues(alpha: 0.2),
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
                    target,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                          final t =
                              (_pulseController.value - delay).clamp(0.0, 1.0);
                          final opacity =
                              (math.sin(t * math.pi)).clamp(0.2, 1.0);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(
                                alpha: opacity,
                              ),
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
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.alarm,
                              color: Color(0xCCFFFFFF),
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
                  _incomingAnswerSlider(),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _sipRuntime.decline,
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
    );
  }

  Widget _buildActiveCallTopBar(BuildContext context, {required bool isDark}) {
    return Row(
      children: [
        _GlassButton(
          onPressed: () => Navigator.of(context).maybePop(),
          padding: const EdgeInsets.all(10),
          borderRadius: 16,
          color: _callGlassFill(isDark),
          borderColor: _callGlassBorder(isDark),
          child: Icon(
            CupertinoIcons.chevron_back,
            color: _callPrimaryText(isDark),
            size: 22,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44, height: 44),
      ],
    );
  }

  Widget _iosCallControls(
    BuildContext context,
    SipUiState state, {
    bool compact = false,
    bool keypadVisible = false,
    // Временно держим светлый стиль по умолчанию, пока тёмную тему прячем.
    bool isDark = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final buttonSize = keypadVisible ? (compact ? 72.0 : 78.0) : 84.0;
    final iconSize = keypadVisible ? 28.0 : 30.0;
    final labelFontSize = keypadVisible ? 13.0 : 15.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _iosCircleAction(
                icon: CupertinoIcons.speaker_3_fill,
                label: l10n.translate('sip_speaker'),
                onTap: _sipRuntime.toggleSpeaker,
                active: state.isSpeakerOn,
                size: buttonSize,
                iconSize: iconSize,
                labelFontSize: labelFontSize,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _iosCircleAction(
                icon: CupertinoIcons.circle_grid_3x3_fill,
                label: 'Клавиши',
                onTap: _toggleInCallKeypad,
                active: keypadVisible,
                size: buttonSize,
                iconSize: iconSize,
                labelFontSize: labelFontSize,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _iosCircleAction(
                icon: state.isMuted
                    ? CupertinoIcons.mic_slash_fill
                    : CupertinoIcons.mic_fill,
                label: state.isMuted
                    ? l10n.translate('sip_unmute')
                    : l10n.translate('sip_mute'),
                onTap: _sipRuntime.toggleMute,
                size: buttonSize,
                iconSize: iconSize,
                labelFontSize: labelFontSize,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: compact && keypadVisible ? 18 : 30),
        Center(
          child: _iosCircleAction(
            icon: CupertinoIcons.phone_down_fill,
            label: 'Отбой',
            onTap: _sipRuntime.hangup,
            destructive: true,
            size: keypadVisible ? (compact ? 80 : 84) : 84,
            iconSize: 32,
            labelFontSize: labelFontSize,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Future<void> _handleInCallTone(String tone) async {
    _updateView(() {
      _inCallDigits = '$_inCallDigits$tone';
    });
    await _sipRuntime.sendDtmf(tone);
  }

  void _toggleInCallKeypad() {
    _updateView(() {
      _showInCallKeypad = !_showInCallKeypad;
      if (!_showInCallKeypad) {
        _inCallDigits = '';
      }
    });
  }

  Widget _iosCircleAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    bool destructive = false,
    double size = 84,
    double iconSize = 30,
    double labelFontSize = 15,
    // Временно оставляем только светлую визуальную ветку SIP.
    bool isDark = false,
  }) {
    final activeBackground = isDark ? Colors.white : _G.lightText;
    final activeBorder = isDark ? Colors.white : _G.lightText;
    final activeIconColor = Colors.white;
    final inactiveBackground = isDark ? _G.glassFill : const Color(0xDFFFFFFF);
    final inactiveBorder = isDark ? _G.glassBorder : const Color(0xFFE1EAF6);
    final inactiveIconColor = isDark ? _G.textPrimary : _G.lightText;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          destructive
              ? Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: _G.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _G.red.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: iconSize),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(size / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: active ? activeBackground : inactiveBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? activeBorder : inactiveBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: active ? activeIconColor : inactiveIconColor,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
          SizedBox(height: size < 80 ? 8 : 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? _G.textSecondary : _G.lightSubtext,
              fontSize: labelFontSize,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomingAnswerSlider() {
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
            _updateView(() {
              _incomingAnswerDrag =
                  (_incomingAnswerDrag + details.delta.dx / maxDrag)
                      .clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_incomingAnswerDrag >= 0.82) {
              _incomingAnswerDrag = 0;
              _sipRuntime.acceptCall();
              return;
            }
            _updateView(() {
              _incomingAnswerDrag = 0;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(52),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
                        child: Icon(
                          CupertinoIcons.chevron_forward,
                          color: _incomingAnswerDrag > 0.5
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF2563EB),
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
