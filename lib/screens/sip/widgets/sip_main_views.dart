// Этот файл отвечает за основные SIP-экраны: авторизация, набор, журнал и верхняя панель.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipMainViewsExtension on _SipScreenState {
  Widget _buildTopBar(BuildContext context, SipUiState state) {
    final isRegistered =
        state.registrationStatus == SipRegistrationUiStatus.registered;
    final showCompactStatus =
        isRegistered && state.callStatus != SipCallUiStatus.incoming;
    final isReconnectInProgress = _isReconnectInProgress(state);
    final isNetworkUnavailable = _isNetworkUnavailableState(state);
    final subtitle = isReconnectInProgress
        ? 'Восстанавливаем SIP-соединение...'
        : isNetworkUnavailable
            ? 'Сеть потеряна. Ждём восстановление соединения'
            : isRegistered
                ? 'Линия готова к звонкам'
                : 'Подключите линию для звонков в фоне';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
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
                const Text(
                  'Телефония',
                  style: TextStyle(
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
                      _buildRegisteredIndicator(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildTopIconButton(
            icon: CupertinoIcons.gear_alt_fill,
            onPressed: _showSettingsSheet,
          ),
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

  Widget _buildRegisteredIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCFE9D8)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 12,
            color: Color(0xFF22C55E),
          ),
          SizedBox(width: 4),
          Text(
            'В сети',
            style: TextStyle(
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF4FF), Color(0xFFF8FAFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTopIconButton(
                      icon: CupertinoIcons.back,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color(0xFF1C1C1E),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF000000).withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                CupertinoIcons.phone_circle_fill,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.translate('sip_welcome_title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('sip_welcome_subtitle'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14,
                            height: 1.4,
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
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF111827).withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('sip_settings'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _iosField(
                          controller: _serverController,
                          placeholder: l10n.translate('sip_server'),
                        ),
                        const SizedBox(height: 10),
                        _iosField(
                          controller: _loginController,
                          placeholder: l10n.translate('sip_login'),
                        ),
                        const SizedBox(height: 10),
                        _iosField(
                          controller: _passwordController,
                          placeholder: l10n.translate('sip_password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        _transportSelector(context),
                        const SizedBox(height: 10),
                        _iosField(
                          controller: _portController,
                          placeholder: l10n.translate('sip_port'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(18),
                            onPressed: isRegistering
                                ? null
                                : () async {
                                    await _saveDraft();
                                    await _sipRuntime.connect();
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isRegistering) ...[
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CupertinoActivityIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  isRegistering
                                      ? 'Подключение...'
                                      : 'Подключить телефонию',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (state.errorMessage != null &&
                            state.errorMessage!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
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
      ),
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
    if (isRegistered && state.callStatus != SipCallUiStatus.incoming) {
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
        ? 'Восстанавливаем соединение'
        : isNetworkUnavailable
            ? 'Сеть недоступна'
            : isRegistered
                ? 'Телефония подключена'
                : 'Телефония не подключена';
    final subtitle = isReconnectInProgress
        ? 'Сеть восстановлена. Переподключаем SIP-линию'
        : isNetworkUnavailable
            ? 'Как только сеть вернётся, SIP подключится автоматически'
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
                      isRegistering ? 'Подключение...' : 'Подключить',
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
        return Stack(
          children: [
            if (!_isDialPanelCollapsed)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _updateView(() {
                      _isDialPanelCollapsed = true;
                    });
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _isDialPanelCollapsed
                    ? _collapsedDialPanel(state)
                    : _ios26DialPanel(context, state, constraints),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _inlineDialSuggestion(BoxConstraints constraints) {
    final query = _sipIdController.text.trim();
    final isNarrow = constraints.maxWidth < 395;
    final isTight = constraints.maxWidth < 370;
    final horizontalPadding = isTight ? 12.0 : 16.0;
    final rowHeight = isTight ? 46.0 : 50.0;
    final extraRowHeight = isTight ? 42.0 : 46.0;
    final reservedHeight = rowHeight + 1 + extraRowHeight + 2;
    final iconSize = isTight ? 17.0 : 18.0;
    final gap = isTight ? 8.0 : 10.0;
    final hasQuery = query.isNotEmpty;
    final hasSuggestion = _dialSuggestions.isNotEmpty && hasQuery;
    final suggestion = hasSuggestion ? _dialSuggestions.first : null;
    final extraResults =
        hasSuggestion ? math.max(0, _dialSuggestionTotalCount - 1) : 0;
    final nameStyle = TextStyle(
      color: const Color(0xFF6B7280),
      fontSize: isTight ? 12.0 : 13.0,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );
    final phoneStyle = TextStyle(
      color: const Color(0xFF111827),
      fontSize: isTight ? 13.0 : 14.0,
      fontWeight: FontWeight.w600,
      height: 1.1,
    );

    if (!hasQuery) {
      return SizedBox(height: reservedHeight + 8);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SizedBox(
        height: reservedHeight,
        child: Align(
          alignment: Alignment.topCenter,
          child: suggestion == null
              ? const SizedBox.shrink()
              : Container(
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
                    mainAxisSize: MainAxisSize.min,
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
                      if (extraResults > 0) ...[
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
                                      fontSize: isTight ? 12.0 : 13.0,
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
    final isNarrow = constraints.maxWidth < 395;
    final isTight = constraints.maxWidth < 370;
    final horizontalPadding = isTight ? 18.0 : (isNarrow ? 20.0 : 24.0);
    final keyOuterSize =
        ((constraints.maxWidth - (horizontalPadding * 2) - 12) / 3)
            .clamp(80.0, 92.0);
    final actionButtonSize = (keyOuterSize * 0.76).clamp(60.0, 68.0);
    final actionIconSize = (actionButtonSize * 0.42).clamp(24.0, 32.0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
            child: _dialNumberHeader(constraints),
          ),
          if (isRegistered) _inlineDialSuggestion(constraints),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: List.generate(4, (row) {
                final start = row * 3;
                return Padding(
                  padding: EdgeInsets.only(bottom: isTight ? 10 : 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (col) {
                      final item = _SipScreenState._dialPadItems[start + col];
                      final key = item['key']!;
                      return _ios26DialKey(
                        value: key,
                        letters: item['letters']!,
                        outerSize: keyOuterSize,
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
          SizedBox(height: isTight ? 0 : 2),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding + 2,
              0,
              horizontalPadding + 2,
              isTight ? 10 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: actionButtonSize,
                  height: actionButtonSize,
                  child: _sipIdController.text.isNotEmpty
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _showAddDialDestinationSheet,
                          child: Icon(
                            CupertinoIcons.person_crop_circle_badge_plus,
                            color: Color(0xFF6B7280),
                            size: actionIconSize,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                GestureDetector(
                  onTap: isRegistered ? _startDialCall : null,
                  child: Container(
                    width: actionButtonSize,
                    height: actionButtonSize,
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
                      size: actionIconSize + 2,
                    ),
                  ),
                ),
                SizedBox(
                  width: actionButtonSize,
                  height: actionButtonSize,
                  child: _sipIdController.text.isNotEmpty
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _backspaceDial,
                          onLongPress: _clearDial,
                          child: Icon(
                            CupertinoIcons.delete_left_fill,
                            color: Color(0xFF6B7280),
                            size: actionIconSize - 1,
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

  Widget _dialNumberHeader(BoxConstraints constraints) {
    final isNarrow = constraints.maxWidth < 395;
    final isTight = constraints.maxWidth < 370;
    final fontSize = isTight ? 30.0 : (isNarrow ? 34.0 : 38.0);
    final placeholderSize = isTight ? 21.0 : (isNarrow ? 24.0 : 27.0);
    final cursorHeight = isTight ? 30.0 : (isNarrow ? 34.0 : 38.0);
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
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: const Color(0xFF111827),
          letterSpacing: isTight ? 1.0 : 1.6,
        ),
        placeholder: 'Введите номер',
        placeholderStyle: TextStyle(
          fontSize: placeholderSize,
          fontWeight: FontWeight.w300,
          color: const Color(0xFFD1D5DB),
        ),
        magnifierConfiguration: TextMagnifierConfiguration.disabled,
        padding: EdgeInsets.symmetric(
          horizontal: isTight ? 4 : 8,
          vertical: isTight ? 2 : 4,
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
    final innerSize = (outerSize - 8).clamp(74.0, 88.0);
    final isTight = outerSize < 90;
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
                    fontSize: isTight ? 30 : 34,
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
                      fontSize: isTight ? 9 : 10,
                      letterSpacing: isTight ? 0.8 : 1.2,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _collapsedDialPanel(SipUiState state) {
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
                        const Text(
                          'Набор',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          _sipIdController.text.trim().isEmpty
                              ? 'Открыть клавиатуру'
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
    const segmentCount = 3;

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
                  final selectedIndex = (_liquidNavDragIndex ??
                          _bottomTabIndex.clamp(0, maxIndex).toDouble())
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
                        Expanded(
                          child: _liquidNavItem(
                            iconAsset: 'assets/icons/sip/keypad_off.png',
                            activeIconAsset: 'assets/icons/sip/keypad_on.png',
                            label: l10n.translate('sip_tab_keypad'),
                            selected: isSelected(0),
                          ),
                        ),
                        const SizedBox(width: innerGap),
                        Expanded(
                          child: _liquidNavItem(
                            iconAsset: 'assets/icons/sip/recents_off.png',
                            activeIconAsset: 'assets/icons/sip/recents_on.png',
                            label: 'Вызовы',
                            selected: isSelected(1),
                          ),
                        ),
                        const SizedBox(width: innerGap),
                        Expanded(
                          child: _liquidNavItem(
                            iconAsset: 'assets/icons/sip/contact_off.png',
                            activeIconAsset: 'assets/icons/sip/contact_on.png',
                            label: 'Контакты',
                            selected: isSelected(2),
                          ),
                        ),
                      ],
                    );
                  }

                  void snapToLocalPosition(double localDx) {
                    final safeDx = localDx.clamp(0.0, usableWidth);
                    final nextIndex = (safeDx / (usableWidth / segmentCount))
                        .floor()
                        .clamp(0, maxIndex);
                    _updateView(() {
                      _bottomTabIndex = nextIndex;
                      _liquidNavDragIndex = nextIndex.toDouble();
                    });
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      _updateView(() {
                        _isLiquidNavPressed = true;
                        _liquidNavDragIndex =
                            _bottomTabIndex.clamp(0, maxIndex).toDouble();
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
                      final snappedIndex =
                          (_liquidNavDragIndex ?? _bottomTabIndex.toDouble())
                              .round()
                              .clamp(0, maxIndex);
                      _updateView(() {
                        _isLiquidNavPressed = false;
                        _bottomTabIndex = snappedIndex;
                        _liquidNavDragIndex = snappedIndex.toDouble();
                      });
                    },
                    onHorizontalDragCancel: () {
                      _updateView(() {
                        _isLiquidNavPressed = false;
                        _liquidNavDragIndex =
                            _bottomTabIndex.clamp(0, maxIndex).toDouble();
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
                                  (index) => index == highlightedIndex,
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
            _liquidSearchButton(
              selected: _bottomTabIndex == 3,
              onTap: () => _updateView(() => _bottomTabIndex = 3),
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

  Widget _liquidSearchButton({
    required bool selected,
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
                  Colors.white.withValues(alpha: selected ? 0.94 : 0.82),
                  Colors.white.withValues(alpha: selected ? 0.74 : 0.62),
                  const Color(0xFFEAF2FF).withValues(alpha: 0.46),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.88),
                width: 1.2,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(-4, 8),
                  ),
                BoxShadow(
                  color: const Color(0xFF111827).withValues(
                    alpha: selected ? 0.11 : 0.08,
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
                  selected
                      ? CupertinoIcons.search_circle_fill
                      : CupertinoIcons.search,
                  color: selected ? const Color(0xFF0A84FF) : Colors.black,
                  size: selected ? 28 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────

  Widget _contactTile({
    required _SipContactSuggestion suggestion,
    required VoidCallback onTap,
    required VoidCallback onCallTap,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 18 : 20,
            backgroundColor: const Color(0xFFF3F4F6),
            backgroundImage: suggestion.photo != null
                ? MemoryImage(suggestion.photo!)
                : null,
            child: suggestion.photo == null
                ? Text(
                    suggestion.name.isEmpty
                        ? '?'
                        : suggestion.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCallTap,
            child: Container(
              width: compact ? 38 : 44,
              height: compact ? 38 : 44,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                CupertinoIcons.phone_fill,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactsView(BuildContext context) {
    if (_contactsEnabled && !_contactsLoaded) {
      unawaited(_loadContacts());
    }

    final contacts = _contacts
        .map((contact) => _SipContactSuggestion(
              name: contact.displayName,
              phone: contact.phones.first.number,
              normalizedPhone: _digitsOnly(contact.phones.first.number),
              photo: contact.photo,
            ))
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));

    final query = _contactsViewQuery.trim().toLowerCase();
    final queryDigits = _digitsOnly(_contactsViewQuery);
    final filtered = query.isEmpty && queryDigits.isEmpty
        ? contacts
        : contacts.where((contact) {
            return contact.name.toLowerCase().contains(query) ||
                contact.normalizedPhone.contains(queryDigits) ||
                _nameToT9Digits(contact.name).contains(queryDigits);
          }).toList(growable: false);

    return Column(
      key: const ValueKey('contacts'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: _cleanSearchField(
            placeholder: 'Поиск по контактам',
            onChanged: (value) {
              _updateView(() {
                _contactsViewQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: _contactsPermissionDenied
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Нет доступа к контактам.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
                    return _contactTile(
                      suggestion: contact,
                      onTap: () {
                        _fillContactNumber(contact);
                        _updateView(() {
                          _bottomTabIndex = 0;
                        });
                      },
                      onCallTap: () async {
                        _updateView(() {
                          _bottomTabIndex = 0;
                        });
                        await _fillAndCallContact(contact);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _journalView(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;
    final entries =
        state.serverCallLogs.isNotEmpty ? state.serverCallLogs : state.callLogs;
    final items = _buildJournalItemsWithHeaders(entries);
    final filters = <(CallType?, String)>[
      (null, 'Все'),
      (CallType.incoming, 'Входящие'),
      (CallType.outgoing, 'Исходящие'),
      (CallType.missed, 'Пропущенные'),
    ];

    return Column(
      key: const ValueKey('journal'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Column(
            children: [
              _cleanSearchField(
                placeholder: 'Поиск звонков',
                controller: _journalSearchController,
                onChanged: _handleJournalSearchChanged,
                onClear: _clearJournalSearch,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in filters) ...[
                      _journalFilterChip(
                        label: filter.$2,
                        selected: state.serverCallFilter == filter.$1,
                        onTap: () async {
                          _updateView(() {
                            _expandedCallLogId = null;
                          });
                          await _sipRuntime.refreshRecentCallLogs(
                            callType: filter.$1,
                            searchQuery: _journalSearchQuery.trim(),
                            force: true,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.isServerCallLogsLoading && items.isEmpty
              ? const Padding(
                  key: ValueKey('journal_loading'),
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              : items.isEmpty
                  ? Padding(
                      key: const ValueKey('journal_empty'),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.translate('sip_journal_empty'),
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator.adaptive(
                      onRefresh: () => _refreshJournalCalls(force: true),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 120) {
                            _sipRuntime.loadMoreRecentCallLogs();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                          itemCount: items.length +
                              (state.isServerCallLogsLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              );
                            }

                            final item = items[index];
                            if (item is Map<String, String>) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['date'] ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontFamily: 'Gilroy',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      item['year'] ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontFamily: 'Gilroy',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final callItem = item as SipCallLogEntry;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _journalLogCard(
                                context,
                                callItem,
                                expanded: _expandedCallLogId == callItem.id,
                                onTap: () {
                                  _updateView(() {
                                    _expandedCallLogId =
                                        _expandedCallLogId == callItem.id
                                            ? null
                                            : callItem.id;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  List<Object> _buildJournalItemsWithHeaders(List<SipCallLogEntry> calls) {
    final sorted = [...calls]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final result = <Object>[];
    DateTime? lastDate;

    for (final call in sorted) {
      final dateOnly = DateTime(
        call.timestamp.year,
        call.timestamp.month,
        call.timestamp.day,
      );
      if (lastDate == null || dateOnly != lastDate) {
        result.add(_formatJournalDateHeader(call.timestamp));
        lastDate = dateOnly;
      }
      result.add(call);
    }

    return result;
  }

  Map<String, String> _formatJournalDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(itemDate).inDays;

    if (difference == 0) {
      return {'date': 'Сегодня', 'year': '${date.year}'};
    }
    if (difference == 1) {
      return {'date': 'Вчера', 'year': '${date.year}'};
    }

    final months = <int, String>{
      1: 'января',
      2: 'февраля',
      3: 'марта',
      4: 'апреля',
      5: 'мая',
      6: 'июня',
      7: 'июля',
      8: 'августа',
      9: 'сентября',
      10: 'октября',
      11: 'ноября',
      12: 'декабря',
    };

    return {
      'date': '${date.day} ${months[date.month] ?? ''}',
      'year': '${date.year}',
    };
  }

  Widget _journalFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF111827),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _journalLogCard(
    BuildContext context,
    SipCallLogEntry item, {
    required bool expanded,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final accentColor = _callLogAccentColor(item);
    final fillColor = _callLogFillColor(item);
    final logIcon = _callLogIcon(item);

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          logIcon,
          color: accentColor,
          size: 18,
        ),
      ),
      title: Text(
        item.target,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        _buildCallLogSubtitle(item, compact: compact),
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      trailing: compact
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                _openDialerWithNumber(item.dialTarget);
                await _startDialCall();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  CupertinoIcons.phone_fill,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            )
          : Text(
              _formatTime(item.timestamp),
              style: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
    );

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          tile,
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _callActionButton(
                          label: 'В набор',
                          icon: CupertinoIcons.circle_grid_3x3_fill,
                          onTap: () => _openDialerWithNumber(item.dialTarget),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _callActionButton(
                          label: 'Добавить',
                          icon: CupertinoIcons.add_circled,
                          onTap: () => _showAddNumberSheetFor(
                            item.dialTarget,
                            suggestedName: item.target == item.dialTarget
                                ? null
                                : item.target,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _callActionButton(
                          label: 'История',
                          icon: CupertinoIcons.clock,
                          onTap: () => _openCallLogHistory(item),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _callActionButton(
                          label: 'Инфо',
                          icon: CupertinoIcons.info_circle,
                          onTap: () => _openCallLogDetails(item),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('swipe_call_${item.id}_${compact ? 'compact' : 'full'}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.32},
      confirmDismiss: (_) async {
        _openDialerWithNumber(item.dialTarget);
        await _startDialCall();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.phone_fill,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Позвонить',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: const SizedBox.shrink(),
      child: card,
    );
  }

  // ─── УМНЫЙ ПОИСК: контакты + журнал одновременно ───────────────────────────
  Widget _searchView(BuildContext context, SipUiState state) {
    if (_contactsEnabled && !_contactsLoaded) {
      unawaited(_loadContacts());
    }

    final query = _searchViewQuery.trim();
    final lowerQuery = query.toLowerCase();
    final queryDigits = _digitsOnly(query);
    final availableSources = _availableSearchSources();
    final callEntries =
        state.serverCallLogs.isNotEmpty ? state.serverCallLogs : state.callLogs;
    final recentCalls = callEntries.take(12).toList(growable: false);

    final contactResults = (query.isEmpty
            ? const <_SipContactSuggestion>[]
            : _contacts
                .expand((contact) => contact.phones.map((phone) {
                      return _SipContactSuggestion(
                        name: contact.displayName,
                        phone: phone.number,
                        normalizedPhone: _digitsOnly(phone.number),
                        photo: contact.photo,
                      );
                    }))
                .where((contact) {
                return contact.name.toLowerCase().contains(lowerQuery) ||
                    (queryDigits.isNotEmpty &&
                        (contact.normalizedPhone.contains(queryDigits) ||
                            _nameToT9Digits(contact.name)
                                .contains(queryDigits)));
              }).toList(growable: false))
        .take(8)
        .toList(growable: false);

    final journalResults = query.isEmpty
        ? const <SipCallLogEntry>[]
        : callEntries
            .where((item) {
              final target = item.target.toLowerCase();
              final targetDigits = _digitsOnly(item.dialTarget);
              final phoneMatch =
                  queryDigits.isNotEmpty && targetDigits.contains(queryDigits);
              return target.contains(lowerQuery) || phoneMatch;
            })
            .take(10)
            .toList(growable: false);

    final leadResults = query.isEmpty
        ? const <Lead>[]
        : _searchLeadResults.where((lead) {
            final name = lead.name.toLowerCase();
            final phone = (lead.phone ?? '').trim();
            final phoneDigits = _digitsOnly(phone);
            return name.contains(lowerQuery) ||
                (queryDigits.isNotEmpty && phoneDigits.contains(queryDigits));
          }).toList(growable: false);

    final isEmpty = query.isEmpty;
    final noResults = !isEmpty &&
        contactResults.isEmpty &&
        journalResults.isEmpty &&
        (!_leadSearchEnabled || (!_isLeadSearchLoading && leadResults.isEmpty));

    return Column(
      key: const ValueKey('search'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: _cleanSearchField(
            placeholder: 'Поиск',
            autofocus: true,
            controller: _searchViewController,
            onChanged: _handleUnifiedSearchChanged,
          ),
        ),
        if (availableSources.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final source in availableSources) ...[
                    _searchSourceChip(
                      source: source,
                      selected: _searchSource == source,
                      onTap: () => _selectSearchSource(source),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        Expanded(
          child: isEmpty
              ? recentCalls.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Недавних звонков пока нет',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      children: [
                        Row(
                          children: const [
                            Text(
                              'Недавние звонки',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...recentCalls.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _journalLogCard(
                              context,
                              item,
                              compact: true,
                              expanded: _expandedCallLogId == item.id,
                              onTap: () {
                                _updateView(() {
                                  _expandedCallLogId =
                                      _expandedCallLogId == item.id
                                          ? null
                                          : item.id;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    )
              : noResults
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Ничего не найдено',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      children: [
                        if (_searchSource == _SipSearchSource.calls) ...[
                          _sectionHeader('Вызовы', journalResults.length),
                          const SizedBox(height: 10),
                          ...journalResults.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _journalLogCard(
                                context,
                                item,
                                compact: true,
                                expanded: _expandedCallLogId == item.id,
                                onTap: () {
                                  _updateView(() {
                                    _expandedCallLogId =
                                        _expandedCallLogId == item.id
                                            ? null
                                            : item.id;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                        if (_searchSource == _SipSearchSource.contacts &&
                            _contactsEnabled) ...[
                          _sectionHeader('Контакты', contactResults.length),
                          const SizedBox(height: 10),
                          ...contactResults.map(
                            (contact) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _contactTile(
                                suggestion: contact,
                                onTap: () {
                                  _fillContactNumber(contact);
                                  _updateView(() => _bottomTabIndex = 0);
                                },
                                onCallTap: () async {
                                  _updateView(() => _bottomTabIndex = 0);
                                  await _fillAndCallContact(contact);
                                },
                              ),
                            ),
                          ),
                        ],
                        if (_searchSource == _SipSearchSource.leads &&
                            _leadSearchEnabled) ...[
                          _sectionHeader('Лиды', leadResults.length),
                          const SizedBox(height: 10),
                          if (_isLeadSearchLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            ),
                          ...leadResults.map(
                            (lead) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _leadSearchTile(lead),
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _searchSourceChip({
    required _SipSearchSource source,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final label = switch (source) {
      _SipSearchSource.calls => 'Вызовы',
      _SipSearchSource.contacts => 'Контакты',
      _SipSearchSource.leads => 'Лиды',
    };

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFF0F0F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF111827),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Заголовок секции с количеством результатов
  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _buildCallLogSubtitle(SipCallLogEntry item, {required bool compact}) {
    final label = _resolvedCallLogLabel(context, item);
    final time = _formatTime(item.timestamp);
    final duration = item.isMissed ? null : _formatDuration(item.duration);

    if (compact) {
      if (item.dialTarget == item.target) {
        return '$label • $time';
      }
      return '${item.dialTarget} • $time';
    }

    if (item.dialTarget == item.target) {
      return duration == null ? '$label • $time' : '$label • $duration';
    }

    return duration == null
        ? '$label • ${item.dialTarget}'
        : '$label • $duration • ${item.dialTarget}';
  }

  Widget _callActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF374151)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadSearchTile(Lead lead) {
    final phone = (lead.phone ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () => _fillLeadPhone(lead),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            CupertinoIcons.person_crop_circle,
            color: Color(0xFF6B7280),
            size: 22,
          ),
        ),
        title: Text(
          lead.name.trim().isEmpty ? 'Без имени' : lead.name,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          phone.isEmpty ? 'Нет телефона' : phone,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        trailing: phone.isEmpty
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async => _callLead(lead),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    CupertinoIcons.phone_fill,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  // ─── ЧИСТОЕ ПОЛЕ ПОИСКА (белое, без стекла, тёмные буквы) ─────────────────
  Widget _cleanSearchField({
    required String placeholder,
    TextEditingController? controller,
    required ValueChanged<String> onChanged,
    bool autofocus = false,
    VoidCallback? onClear,
  }) {
    final hasText = controller?.text.trim().isNotEmpty ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF0F0F0),
        ),
      ),
      child: CupertinoTextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        decoration: const BoxDecoration(),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        placeholderStyle: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefix: const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(14, 0, 10, 0),
          child: Icon(
            CupertinoIcons.search,
            color: Color(0xFF9CA3AF),
            size: 18,
          ),
        ),
        suffix: hasText && onClear != null
            ? CupertinoButton(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
                minimumSize: Size.zero,
                onPressed: onClear,
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Color(0xFF9CA3AF),
                  size: 18,
                ),
              )
            : const SizedBox(width: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        placeholder: placeholder,
        onChanged: onChanged,
      ),
    );
  }

  String _declineSearchResultsLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return 'результат';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'результата';
    }
    return 'результатов';
  }

  Widget _bottomSwitcher(BuildContext context, {bool embedded = false}) {
    if (embedded) return const SizedBox.shrink();
    return _ios26LiquidNavBar(context);
  }
}
