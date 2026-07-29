// Этот файл отвечает за основные SIP-экраны: авторизация, набор, журнал и верхняя панель.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipMainViewsExtension on _SipScreenState {
  Widget _buildTopBar(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;
    final isRegistered =
        state.registrationStatus == SipRegistrationUiStatus.registered;
    final showCompactStatus =
        isRegistered && state.callStatus != SipCallUiStatus.incoming;
    final isReconnectInProgress = _isReconnectInProgress(state);
    final isNetworkUnavailable = _isNetworkUnavailableState(state);
    final hasActiveCall = state.callStatus == SipCallUiStatus.incoming ||
        state.callStatus == SipCallUiStatus.calling ||
        state.callStatus == SipCallUiStatus.ringing ||
        state.callStatus == SipCallUiStatus.inCall;
    final subtitle = hasActiveCall
        ? _resolvedCallLabel(context, state)
        : isReconnectInProgress
            ? l10n.translate('sip_reconnect_compact')
            : isNetworkUnavailable
                ? l10n.translate('sip_network_lost')
                : isRegistered
                    ? l10n.translate('sip_line_ready')
                    : l10n.translate('sip_line_background_hint');

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Column(
        children: [
          Row(
            children: [
              _buildTopIconButton(
                icon: CupertinoIcons.back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('appbar_sip'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (showCompactStatus) ...[
                          const SizedBox(width: 8),
                          _buildRegisteredIndicator(context),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildTopIconButton(
                icon: CupertinoIcons.search,
                onPressed: _openSearchTab,
              ),
            ],
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS) ...[
            // const SizedBox(height: 10),
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFFFF7E8),
            //     borderRadius: BorderRadius.circular(14),
            //     border: Border.all(color: const Color(0xFFF5D8A8)),
            //   ),
            //   child: const Row(
            //     children: [
            //       Icon(
            //         CupertinoIcons.exclamationmark_triangle_fill,
            //         size: 16,
            //         color: Color(0xFFC27A00),
            //       ),
            //       SizedBox(width: 8),
            //       Expanded(
            //         child: Text(
            //           'На iPhone не закрывайте приложение свайпом из недавних. Для входящих держите его просто свернутым.',
            //           style: TextStyle(
            //             fontSize: 12,
            //             fontWeight: FontWeight.w600,
            //             color: Color(0xFF8A5A00),
            //             height: 1.25,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFF0F0F0),
          ),
        ),
        child: Icon(icon, size: 21, color: const Color(0xFF374151)),
      ),
    );
  }

  void _openSearchTab() {
    _updateView(() {
      _bottomTabIndex = 3;
      _liquidNavDragIndex = null;
      _isLiquidNavPressed = false;
      _expandedCallLogId = null;
    });
  }

  Widget _buildRegisteredIndicator(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCFE9D8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 12,
            color: Color(0xFF22C55E),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.translate('sip_online'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorizationView(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;
    final isRegistering =
        state.registrationStatus == SipRegistrationUiStatus.registering;
    final hasInlineStatusMessage =
        state.registrationStatus == SipRegistrationUiStatus.failed &&
            state.errorMessage != null &&
            state.errorMessage!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Row(
                  children: [
                    _buildTopIconButton(
                      icon: CupertinoIcons.back,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.translate('appbar_sip'),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff1E2E52).withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xffEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          CupertinoIcons.phone_fill,
                          color: Color(0xff4F40EC),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('sip_welcome_title'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.translate('sip_welcome_subtitle'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff99A4BA),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff1E2E52).withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('sip_settings'),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _serverController,
                        hintText: l10n.translate('sip_server'),
                        label: l10n.translate('sip_server'),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _loginController,
                        hintText: l10n.translate('sip_login'),
                        label: l10n.translate('sip_login'),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _passwordController,
                        hintText: l10n.translate('sip_password'),
                        label: l10n.translate('sip_password'),
                        isPassword: true,
                      ),
                      const SizedBox(height: 12),
                      _projectTransportSelector(context),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _portController,
                        hintText: l10n.translate('sip_port'),
                        label: l10n.translate('sip_port'),
                        keyboardType: TextInputType.number,
                      ),
                      if (hasInlineStatusMessage) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF1F1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xffFFD4D4),
                            ),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xffE45454),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      CustomButton(
                        buttonText: isRegistering
                            ? l10n.translate('sip_connecting')
                            : l10n.translate('sip_connect'),
                        buttonColor: const Color(0xff4F40EC),
                        textColor: Colors.white,
                        isLoading: isRegistering,
                        onPressed: isRegistering
                            ? null
                            : () async {
                                await _saveDraft();
                                await _sipRuntime.connect();
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _projectTransportSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(SipTransportUi, String)>[
      (SipTransportUi.ws, l10n.translate('sip_transport_ws')),
      (SipTransportUi.udp, l10n.translate('sip_transport_udp')),
      (SipTransportUi.tcp, l10n.translate('sip_transport_tcp')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('sip_transport'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _updateView(() {
                        _selectedTransport = items[i].$1;
                        if (_portController.text.trim().isEmpty) {
                          _portController.text =
                              items[i].$1 == SipTransportUi.ws
                                  ? '7443'
                                  : '5060';
                        }
                      });
                      _handleDraftChanged();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedTransport == items[i].$1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedTransport == items[i].$1
                            ? [
                                BoxShadow(
                                  color: const Color(0xff1E2E52)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        items[i].$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _selectedTransport == items[i].$1
                              ? const Color(0xff1E2E52)
                              : const Color(0xff5A6B87),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBanner(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;

    final isRegistered =
        state.registrationStatus == SipRegistrationUiStatus.registered;
    final isRegistering =
        state.registrationStatus == SipRegistrationUiStatus.registering;
    final isReconnectInProgress = _isReconnectInProgress(state);
    final isNetworkUnavailable = _isNetworkUnavailableState(state);
    final hasActiveCall = state.callStatus == SipCallUiStatus.calling ||
        state.callStatus == SipCallUiStatus.ringing ||
        state.callStatus == SipCallUiStatus.inCall;
    if (hasActiveCall ||
        (isRegistered && state.callStatus != SipCallUiStatus.incoming)) {
      return const SizedBox.shrink();
    }

    final toneColor = state.callStatus == SipCallUiStatus.incoming
        ? const Color(0xFFF59E0B)
        : isReconnectInProgress
            ? const Color(0xFF2563EB)
            : isNetworkUnavailable
                ? const Color(0xFFF59E0B)
                : isRegistered
                    ? const Color(0xFF22C55E)
                    : state.registrationStatus == SipRegistrationUiStatus.failed
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF9CA3AF);
    final title = isReconnectInProgress
        ? l10n.translate('sip_reconnecting_title')
        : isNetworkUnavailable
            ? l10n.translate('sip_network_unavailable')
            : isRegistered
                ? l10n.translate('sip_connected')
                : l10n.translate('sip_not_connected');
    final subtitle = isReconnectInProgress
        ? l10n.translate('sip_network_restored_reconnecting')
        : isNetworkUnavailable
            ? l10n.translate('sip_network_auto_connect')
            : '${l10n.translate('sip_call_state')}: ${_resolvedCallLabel(context, state)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              state.callStatus == SipCallUiStatus.incoming
                  ? CupertinoIcons.phone_fill_arrow_down_left
                  : isRegistered
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.antenna_radiowaves_left_right,
              size: 18,
              color: toneColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (state.registrationStatus != SipRegistrationUiStatus.registered &&
              state.callStatus != SipCallUiStatus.incoming)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: isRegistering
                  ? null
                  : () async {
                      await _saveDraft();
                      await _sipRuntime.connect();
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRegistering) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CupertinoActivityIndicator(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isRegistering
                          ? l10n.translate('sip_connecting')
                          : l10n.translate('sip_connect'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.callStatus == SipCallUiStatus.incoming)
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _sipRuntime.acceptCall,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.translate('sip_accept'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _sipRuntime.decline,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.translate('sip_decline'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dialPadView(BuildContext context, SipUiState state) {
    return LayoutBuilder(
      key: const ValueKey('dial'),
      builder: (context, constraints) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _isDialPanelCollapsed
              ? Align(
                  key: const ValueKey('dial_collapsed'),
                  alignment: Alignment.bottomCenter,
                  child: _collapsedDialPanel(context, state),
                )
              : SizedBox.expand(
                  key: const ValueKey('dial_expanded'),
                  child: _ios26DialPanel(context, state, constraints),
                ),
        );
      },
    );
  }

  double _fitDialTextFontSize({
    required String text,
    required double maxWidth,
    required double maxFontSize,
    required double minFontSize,
    required FontWeight fontWeight,
  }) {
    if (text.trim().isEmpty || maxWidth <= 0) return maxFontSize;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: maxFontSize,
          fontWeight: fontWeight,
        ),
      ),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    if (painter.width <= maxWidth) return maxFontSize;

    return (maxFontSize * maxWidth / painter.width)
        .clamp(minFontSize, maxFontSize);
  }

  _DialPadMetrics _dialPadMetrics(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.sizeOf(context).width;
    final maxHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : MediaQuery.sizeOf(context).height * 0.68;
    final isVeryCompact = maxHeight < 560 || maxWidth < 360;
    final isCompact = isVeryCompact || maxHeight < 620 || maxWidth < 395;

    final horizontalPadding = isVeryCompact
        ? 14.0
        : isCompact
            ? 18.0
            : 24.0;
    final rowGap = isVeryCompact
        ? 5.0
        : isCompact
            ? 7.0
            : 10.0;
    final headerHeight = isVeryCompact
        ? 38.0
        : isCompact
            ? 44.0
            : 52.0;
    // Keep this space reserved even before the first digit is entered.
    // Otherwise the suggestion panel grows after typing and pushes the
    // number header upward.
    final suggestionHeight = isVeryCompact
        ? 52.0
        : isCompact
            ? 62.0
            : 104.0;
    final bottomPadding = isVeryCompact
        ? 4.0
        : isCompact
            ? 6.0
            : 10.0;

    final widthKeySize =
        ((maxWidth - (horizontalPadding * 2) - (rowGap * 2)) / 3)
            .clamp(58.0, 92.0);
    final reservedHeight =
        headerHeight + suggestionHeight + bottomPadding + (rowGap * 4);
    final heightKeySize =
        ((maxHeight - reservedHeight) / 4.76).clamp(58.0, 92.0);
    final keyOuterSize = math.min(widthKeySize, heightKeySize);
    final actionButtonSize = (keyOuterSize * 0.76).clamp(46.0, 68.0);
    final actionIconSize = (actionButtonSize * 0.42).clamp(21.0, 32.0);

    return _DialPadMetrics(
      horizontalPadding: horizontalPadding,
      rowGap: rowGap,
      headerHeight: headerHeight,
      suggestionHeight: suggestionHeight,
      keyOuterSize: keyOuterSize,
      actionButtonSize: actionButtonSize,
      actionIconSize: actionIconSize,
      bottomPadding: bottomPadding,
      isCompact: isCompact,
      isVeryCompact: isVeryCompact,
    );
  }

  Widget _inlineDialSuggestion(
    BoxConstraints constraints, {
    required double height,
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final query = _sipIdController.text.trim();
    if (query.isEmpty || height <= 4) {
      return SizedBox(height: height);
    }

    final isNarrow = constraints.maxWidth < 395;
    final horizontalPadding = isVeryCompact ? 12.0 : 16.0;
    final bottomPadding = isVeryCompact
        ? 4.0
        : isCompact
            ? 6.0
            : 8.0;
    final containerHeight = (height - bottomPadding).clamp(42.0, height);
    final hasSuggestion = _dialSuggestions.isNotEmpty;
    final suggestion = hasSuggestion ? _dialSuggestions.first : null;
    final extraResults =
        hasSuggestion ? math.max(0, _dialSuggestionTotalCount - 1) : 0;
    final showExtraRow = !isCompact && extraResults > 0;
    final contentHeight = math.max(0.0, containerHeight - 2);
    final dividerHeight = showExtraRow ? 1.0 : 0.0;
    final rowHeight = showExtraRow
        ? math.max(0.0, (contentHeight - dividerHeight) * 0.56)
        : contentHeight;
    final extraRowHeight = showExtraRow
        ? math.max(0.0, contentHeight - rowHeight - dividerHeight)
        : 0.0;
    final iconSize = isVeryCompact
        ? 16.0
        : isCompact
            ? 17.0
            : 18.0;
    final gap = isVeryCompact ? 7.0 : 10.0;
    final nameStyle = TextStyle(
      color: const Color(0xFF6B7280),
      fontSize: isVeryCompact
          ? 11.0
          : isCompact
              ? 12.0
              : 13.0,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );
    final phoneStyle = TextStyle(
      color: const Color(0xFF111827),
      fontSize: isVeryCompact
          ? 12.0
          : isCompact
              ? 13.0
              : 14.0,
      fontWeight: FontWeight.w600,
      height: 1.1,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding),
      child: SizedBox(
        height: containerHeight,
        child: Align(
          alignment: Alignment.topCenter,
          child: suggestion == null
              ? const SizedBox.shrink()
              : Container(
                  height: containerHeight,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF111827).withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFF0F0F0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openDialerWithNumber(suggestion.phone),
                        child: SizedBox(
                          height: rowHeight,
                          child: isNarrow
                              ? Row(
                                  children: [
                                    Icon(
                                      suggestion.sourceLabel == 'Контакт'
                                          ? CupertinoIcons.person_crop_circle
                                          : suggestion.sourceLabel == 'Лид'
                                              ? CupertinoIcons
                                                  .person_crop_circle_badge_plus
                                              : CupertinoIcons.phone_fill,
                                      size: iconSize,
                                      color: const Color(0xFF374151),
                                    ),
                                    SizedBox(width: gap),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: nameStyle,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${suggestion.phone} • ${suggestion.sourceLabel}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: phoneStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      suggestion.sourceLabel == 'Контакт'
                                          ? CupertinoIcons.person_crop_circle
                                          : suggestion.sourceLabel == 'Лид'
                                              ? CupertinoIcons
                                                  .person_crop_circle_badge_plus
                                              : CupertinoIcons.phone_fill,
                                      size: iconSize,
                                      color: const Color(0xFF374151),
                                    ),
                                    SizedBox(width: gap),
                                    Expanded(
                                      child: Text(
                                        suggestion.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: nameStyle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${suggestion.phone} • ${suggestion.sourceLabel}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                        style: phoneStyle,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (showExtraRow) ...[
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF0F0F0),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openUnifiedSearchWithQuery(
                            _sipIdController.text,
                            preferredSource: _contactsEnabled
                                ? _SipSearchSource.contacts
                                : _SipSearchSource.calls,
                          ),
                          child: SizedBox(
                            height: extraRowHeight,
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.search,
                                  size: iconSize,
                                  color: const Color(0xFF111827),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: Text(
                                    'Еще $extraResults ${_declineSearchResultsLabel(extraResults)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF6B7280),
                                      fontSize: isVeryCompact ? 11.0 : 13.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _ios26DialPanel(
    BuildContext context,
    SipUiState state,
    BoxConstraints constraints,
  ) {
    final isRegistered =
        state.registrationStatus == SipRegistrationUiStatus.registered;
    final metrics = _dialPadMetrics(constraints);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: metrics.headerHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                metrics.isVeryCompact ? 0 : 2,
                20,
                metrics.isVeryCompact ? 0 : 2,
              ),
              child: _dialNumberHeader(constraints, metrics),
            ),
          ),
          if (isRegistered)
            _inlineDialSuggestion(
              constraints,
              height: metrics.suggestionHeight,
              isCompact: metrics.isCompact,
              isVeryCompact: metrics.isVeryCompact,
            )
          else
            SizedBox(height: metrics.suggestionHeight),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
            child: Column(
              children: List.generate(4, (row) {
                final start = row * 3;
                return Padding(
                  padding: EdgeInsets.only(bottom: metrics.rowGap),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (col) {
                      final item = _SipScreenState._dialPadItems[start + col];
                      final key = item['key']!;
                      return _ios26DialKey(
                        value: key,
                        letters: item['letters']!,
                        outerSize: metrics.keyOuterSize,
                        onTap: () => _insertDialText(key),
                        onLongPress:
                            key == '0' ? () => _insertDialText('+') : null,
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: metrics.horizontalPadding + 2,
              right: metrics.horizontalPadding + 2,
              top: 0,
              bottom: metrics.bottomPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: metrics.actionButtonSize,
                  height: metrics.actionButtonSize,
                  child: _sipIdController.text.isNotEmpty
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _showAddDialDestinationSheet,
                          child: Icon(
                            CupertinoIcons.person_crop_circle_badge_plus,
                            color: Color(0xFF6B7280),
                            size: metrics.actionIconSize,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                GestureDetector(
                  onTap: isRegistered ? _startDialCall : null,
                  child: Container(
                    width: metrics.actionButtonSize,
                    height: metrics.actionButtonSize,
                    decoration: BoxDecoration(
                      color: isRegistered
                          ? const Color(0xFF34C759)
                          : const Color(0xFFD1D5DB),
                      shape: BoxShape.circle,
                      boxShadow: isRegistered
                          ? [
                              BoxShadow(
                                color: const Color(0xFF34C759).withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      CupertinoIcons.phone_fill,
                      color: Colors.white,
                      size: metrics.actionIconSize + 2,
                    ),
                  ),
                ),
                SizedBox(
                  width: metrics.actionButtonSize,
                  height: metrics.actionButtonSize,
                  child: _sipIdController.text.isNotEmpty
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _backspaceDial,
                          onLongPress: _clearDial,
                          child: Icon(
                            CupertinoIcons.delete_left_fill,
                            color: Color(0xFF6B7280),
                            size: metrics.actionIconSize - 1,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialNumberHeader(
    BoxConstraints constraints,
    _DialPadMetrics metrics,
  ) {
    final typedNumber = _sipIdController.text.trim();
    final maxFontSize = metrics.isVeryCompact
        ? 28.0
        : metrics.isCompact
            ? 32.0
            : 38.0;
    final minFontSize = metrics.isVeryCompact ? 20.0 : 22.0;
    final fontSize = _fitDialTextFontSize(
      text: typedNumber,
      maxWidth: constraints.maxWidth - 40,
      maxFontSize: maxFontSize,
      minFontSize: minFontSize,
      fontWeight: FontWeight.w300,
    );
    final placeholderSize = metrics.isVeryCompact
        ? 19.0
        : metrics.isCompact
            ? 22.0
            : 27.0;
    final cursorHeight = fontSize;
    return GestureDetector(
      onTap: _expandDialPanel,
      onLongPress: _showDialActions,
      child: CupertinoTextField(
        controller: _sipIdController,
        focusNode: _dialFocusNode,
        readOnly: true,
        showCursor: true,
        cursorColor: const Color(0xFF111827),
        cursorWidth: 2,
        cursorHeight: cursorHeight,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: const Color(0xFF111827),
          letterSpacing: 0,
        ),
        placeholder: 'Введите номер',
        placeholderStyle: TextStyle(
          fontSize: placeholderSize,
          fontWeight: FontWeight.w300,
          color: const Color(0xFFD1D5DB),
        ),
        magnifierConfiguration: TextMagnifierConfiguration.disabled,
        contextMenuBuilder: (menuContext, editableTextState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            editableTextState.hideToolbar();
            if (mounted) {
              _showDialActions();
            }
          });
          return const SizedBox.shrink();
        },
        padding: EdgeInsets.symmetric(
          horizontal: metrics.isVeryCompact ? 2 : 6,
          vertical: metrics.isVeryCompact ? 0 : 2,
        ),
        decoration: const BoxDecoration(),
      ),
    );
  }

  Widget _ios26DialKey({
    required String value,
    required String letters,
    required double outerSize,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final isTight = outerSize < 84;
    final innerInset = isTight ? 4.0 : 8.0;
    final innerSize = (outerSize - innerInset).clamp(52.0, 88.0);
    final digitSize = (outerSize * 0.37).clamp(24.0, 34.0);
    final letterSize = (outerSize * 0.11).clamp(7.0, 10.0);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: outerSize,
        height: outerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFF3F4F6),
                  width: 1,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: digitSize,
                    height: 1.0,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (letters.isNotEmpty)
                  Text(
                    letters,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: letterSize,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                      height: isTight ? 1.05 : 1.12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _collapsedDialPanel(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _expandDialPanel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF0F0F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.circle_grid_3x3_fill,
                      size: 18,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.translate('sip_tab_keypad'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          _sipIdController.text.trim().isEmpty
                              ? l10n.translate('sip_open_keypad')
                              : _sipIdController.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              state.registrationStatus == SipRegistrationUiStatus.registered
                  ? _startDialCall
                  : _expandDialPanel,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  state.registrationStatus == SipRegistrationUiStatus.registered
                      ? const Color(0xFF34C759)
                      : const Color(0xFF374151),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              state.registrationStatus == SipRegistrationUiStatus.registered
                  ? CupertinoIcons.phone_fill
                  : CupertinoIcons.chevron_up,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ─── НОВЫЙ iOS 26 Liquid NavBar ─────────────────────────────────────────────
  // Зеркальный стиль: таблетка с вкладками слева + кнопка поиска справа
  Widget _ios26LiquidNavBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navItems = <({
      int index,
      String iconAsset,
      String activeIconAsset,
      String label,
    })>[
      (
        index: 0,
        iconAsset: 'assets/icons/sip/keypad_off.png',
        activeIconAsset: 'assets/icons/sip/keypad_on.png',
        label: l10n.translate('sip_tab_keypad'),
      ),
      (
        index: 1,
        iconAsset: 'assets/icons/sip/recents_off.png',
        activeIconAsset: 'assets/icons/sip/recents_on.png',
        label: l10n.translate('sip_tab_calls'),
      ),
      if (_hasContactsTab)
        (
          index: 2,
          iconAsset: 'assets/icons/sip/contact_off.png',
          activeIconAsset: 'assets/icons/sip/contact_on.png',
          label: l10n.translate('sip_tab_contacts'),
        ),
    ];
    final segmentCount = navItems.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = 5.0;
                  const innerGap = 4.0;
                  final maxIndex = segmentCount - 1;
                  final currentNavPosition = navItems
                      .indexWhere((item) => item.index == _bottomTabIndex);
                  final hasSegmentSelection = currentNavPosition >= 0;
                  final fallbackNavPosition = navItems.indexWhere(
                    (item) => item.index == 1,
                  );
                  final selectedIndex = (_liquidNavDragIndex ??
                          (currentNavPosition >= 0
                              ? currentNavPosition.toDouble()
                              : math.max(0, fallbackNavPosition).toDouble()))
                      .clamp(0.0, maxIndex.toDouble());
                  final usableWidth =
                      constraints.maxWidth - (horizontalPadding * 2);
                  final segmentWidth =
                      (usableWidth - innerGap * (segmentCount - 1)) /
                          segmentCount;
                  final thumbLeft = selectedIndex * (segmentWidth + innerGap);
                  final highlightedIndex =
                      selectedIndex.round().clamp(0, maxIndex);
                  final thumbTop = _isLiquidNavPressed ? 2.0 : 4.0;
                  final thumbHeight = _isLiquidNavPressed ? 66.0 : 62.0;

                  Widget buildItemsRow(bool Function(int index) isSelected) {
                    return Row(
                      children: [
                        for (var i = 0; i < navItems.length; i++) ...[
                          if (i > 0) const SizedBox(width: innerGap),
                          Expanded(
                            child: _liquidNavItem(
                              iconAsset: navItems[i].iconAsset,
                              activeIconAsset: navItems[i].activeIconAsset,
                              label: navItems[i].label,
                              selected: isSelected(i),
                            ),
                          ),
                        ],
                      ],
                    );
                  }

                  void snapToLocalPosition(double localDx) {
                    final safeDx = localDx.clamp(0.0, usableWidth);
                    final nextPosition = (safeDx / (usableWidth / segmentCount))
                        .floor()
                        .clamp(0, maxIndex);
                    final nextIndex = navItems[nextPosition].index;
                    _updateView(() {
                      _bottomTabIndex = nextIndex;
                      _liquidNavDragIndex = nextPosition.toDouble();
                    });
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      final dragStartPosition = currentNavPosition >= 0
                          ? currentNavPosition
                          : math.max(0, fallbackNavPosition);
                      _updateView(() {
                        _isLiquidNavPressed = true;
                        _liquidNavDragIndex = dragStartPosition.toDouble();
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      final safeDx =
                          (details.localPosition.dx - horizontalPadding)
                              .clamp(0.0, usableWidth);
                      final dragIndex = safeDx / (usableWidth / segmentCount);
                      _updateView(() {
                        _liquidNavDragIndex =
                            dragIndex.clamp(0.0, maxIndex.toDouble());
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      final snappedPosition =
                          (_liquidNavDragIndex ?? _bottomTabIndex.toDouble())
                              .round()
                              .clamp(0, maxIndex);
                      final snappedIndex = navItems[snappedPosition].index;
                      _updateView(() {
                        _isLiquidNavPressed = false;
                        _bottomTabIndex = snappedIndex;
                        _liquidNavDragIndex = snappedPosition.toDouble();
                      });
                    },
                    onHorizontalDragCancel: () {
                      final resetPosition = currentNavPosition >= 0
                          ? currentNavPosition
                          : math.max(0, fallbackNavPosition);
                      _updateView(() {
                        _isLiquidNavPressed = false;
                        _liquidNavDragIndex = resetPosition.toDouble();
                      });
                    },
                    onTapDown: (details) {
                      _updateView(() {
                        _isLiquidNavPressed = true;
                      });
                      snapToLocalPosition(
                        details.localPosition.dx - horizontalPadding,
                      );
                    },
                    onTapUp: (_) {
                      _updateView(() {
                        _isLiquidNavPressed = false;
                      });
                    },
                    onTapCancel: () {
                      _updateView(() {
                        _isLiquidNavPressed = false;
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(42),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                        child: Container(
                          height: 78,
                          padding: const EdgeInsets.all(horizontalPadding),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.82),
                                Colors.white.withValues(alpha: 0.66),
                                const Color(0xFFEAF2FF).withValues(alpha: 0.52),
                              ],
                              stops: const [0.0, 0.58, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(42),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.86),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.80),
                                blurRadius: 14,
                                offset: const Offset(0, -2),
                              ),
                              BoxShadow(
                                color: const Color(0xFF111827).withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 32,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 18,
                                right: 18,
                                top: 5,
                                height: 16,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.82),
                                        Colors.white.withValues(alpha: 0.10),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 4,
                                height: 18,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: RadialGradient(
                                      center: Alignment.bottomCenter,
                                      radius: 1.5,
                                      colors: [
                                        const Color(0xFF0A84FF)
                                            .withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.05),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (hasSegmentSelection)
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeOutCubic,
                                  left: thumbLeft,
                                  top: thumbTop,
                                  width: segmentWidth,
                                  height: thumbHeight,
                                  child: _liquidMirrorThumb(
                                    isPressed: _isLiquidNavPressed,
                                  ),
                                ),
                              IgnorePointer(
                                child: buildItemsRow(
                                  (index) =>
                                      hasSegmentSelection &&
                                      index == highlightedIndex,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            _liquidSettingsButton(
              onTap: _showSettingsSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _liquidNavItem({
    required String iconAsset,
    required String activeIconAsset,
    required String label,
    required bool selected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Image.asset(
              selected ? activeIconAsset : iconAsset,
              key: ValueKey(selected),
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? const Color(0xFF0A84FF) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liquidMirrorThumb({required bool isPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isPressed ? 30 : 24,
              sigmaY: isPressed ? 30 : 24,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.98 : 0.94),
                    const Color(0xFFF9FCFF).withValues(alpha: 0.90),
                    const Color(0xFFE9F2FF).withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.56, 1.0],
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isPressed ? 1.0 : 0.90),
                  width: isPressed ? 2.2 : 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.white.withValues(alpha: isPressed ? 1.0 : 0.86),
                    blurRadius: isPressed ? 26 : 15,
                    spreadRadius: isPressed ? 2.0 : 0.5,
                    offset: const Offset(0, -2),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(
                      alpha: isPressed ? 0.70 : 0.32,
                    ),
                    blurRadius: isPressed ? 24 : 12,
                    spreadRadius: isPressed ? 1.8 : 0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(
                      alpha: isPressed ? 0.09 : 0.07,
                    ),
                    blurRadius: isPressed ? 24 : 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.65),
                  radius: 1.25,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.58 : 0.46),
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 5,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.98 : 0.92),
                    Colors.white.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 17,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.6,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.36 : 0.26),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: isPressed ? 8 : 13,
            right: isPressed ? 8 : 13,
            bottom: isPressed ? 2 : 4,
            height: isPressed ? 20 : 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: isPressed ? 1.65 : 1.4,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.48 : 0.20),
                    Colors.white.withValues(alpha: isPressed ? 0.16 : 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          if (isPressed)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.42),
                    width: 5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _liquidSettingsButton({
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 68,
            height: 78,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.62),
                  const Color(0xFFEAF2FF).withValues(alpha: 0.46),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.88),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 7,
                  left: 15,
                  right: 15,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.88),
                          Colors.white.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.gear_alt_fill,
                  color: Colors.black,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
}

class _DialPadMetrics {
  const _DialPadMetrics({
    required this.horizontalPadding,
    required this.rowGap,
    required this.headerHeight,
    required this.suggestionHeight,
    required this.keyOuterSize,
    required this.actionButtonSize,
    required this.actionIconSize,
    required this.bottomPadding,
    required this.isCompact,
    required this.isVeryCompact,
  });

  final double horizontalPadding;
  final double rowGap;
  final double headerHeight;
  final double suggestionHeight;
  final double keyOuterSize;
  final double actionButtonSize;
  final double actionIconSize;
  final double bottomPadding;
  final bool isCompact;
  final bool isVeryCompact;
}
