// Этот файл отвечает за основные SIP-экраны: авторизация, набор, журнал и верхняя панель.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipMainViewsExtension on _SipScreenState {
  Widget _buildTopBar(BuildContext context, SipUiState state) {
    final isRegistered =
        state.registrationStatus == SipRegistrationUiStatus.registered;
    final showCompactStatus =
        isRegistered && state.callStatus != SipCallUiStatus.incoming;

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
                        isRegistered
                            ? 'Линия готова к звонкам'
                            : 'Подключите линию для звонков в фоне',
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
                            child: Text(
                              isRegistering
                                  ? 'Подключение...'
                                  : 'Подключить телефонию',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
    if (isRegistered && state.callStatus != SipCallUiStatus.incoming) {
      return const SizedBox.shrink();
    }

    final toneColor = state.callStatus == SipCallUiStatus.incoming
        ? const Color(0xFFF59E0B)
        : isRegistered
            ? const Color(0xFF22C55E)
            : state.registrationStatus == SipRegistrationUiStatus.failed
                ? const Color(0xFFEF4444)
                : const Color(0xFF9CA3AF);

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
                  isRegistered
                      ? 'Телефония подключена'
                      : 'Телефония не подключена',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.translate('sip_call_state')}: ${_callLabel(context, state.callStatus)}',
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
              onPressed: state.registrationStatus ==
                      SipRegistrationUiStatus.registering
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
                child: const Text(
                  'Подключить',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
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

  Widget _inlineDialSuggestion() {
    if (_contactSuggestions.isEmpty || _sipIdController.text.trim().isEmpty) {
      return const SizedBox(height: 52);
    }

    final suggestion = _contactSuggestions.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GestureDetector(
        onTap: () => _fillContactNumber(suggestion),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.person_crop_circle,
                size: 20,
                color: Color(0xFF374151),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  suggestion.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  suggestion.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
            child: _dialNumberHeader(),
          ),
          if (isRegistered) _inlineDialSuggestion(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: List.generate(4, (row) {
                final start = row * 3;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (col) {
                      final item = _SipScreenState._dialPadItems[start + col];
                      final key = item['key']!;
                      return _ios26DialKey(
                        value: key,
                        letters: item['letters']!,
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
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: _sipIdController.text.isNotEmpty
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _showAddDialDestinationSheet,
                          child: const Icon(
                            CupertinoIcons.person_crop_circle_badge_plus,
                            color: Color(0xFF6B7280),
                            size: 30,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                GestureDetector(
                  onTap: isRegistered ? _startDialCall : null,
                  child: Container(
                    width: 72,
                    height: 72,
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
                    child: const Icon(
                      CupertinoIcons.phone_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: _sipIdController.text.isNotEmpty
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _backspaceDial,
                          onLongPress: _clearDial,
                          child: const Icon(
                            CupertinoIcons.delete_left_fill,
                            color: Color(0xFF6B7280),
                            size: 28,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          _ios26LiquidNavBar(context),
        ],
      ),
    );
  }

  Widget _dialNumberHeader() {
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
        cursorHeight: 40,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w300,
          color: Color(0xFF111827),
          letterSpacing: 2,
        ),
        placeholder: 'Введите номер',
        placeholderStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: Color(0xFFD1D5DB),
        ),
        magnifierConfiguration: TextMagnifierConfiguration.disabled,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: const BoxDecoration(),
      ),
    );
  }

  Widget _ios26DialKey({
    required String value,
    required String letters,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
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
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1.0,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF111827),
                  ),
                ),
                if (letters.isNotEmpty)
                  Text(
                    letters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
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
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          height: 76,
                          padding: const EdgeInsets.all(horizontalPadding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(42),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF111827).withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOutCubic,
                                left: thumbLeft,
                                top: _isLiquidNavPressed ? 1 : 3,
                                width: segmentWidth,
                                height: _isLiquidNavPressed ? 64 : 60,
                                child: _liquidMirrorThumb(
                                  isPressed: _isLiquidNavPressed,
                                ),
                              ),
                              IgnorePointer(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _liquidNavItem(
                                        icon: CupertinoIcons.circle_grid_3x3,
                                        iconFilled:
                                            CupertinoIcons.circle_grid_3x3_fill,
                                        label: l10n.translate('sip_tab_keypad'),
                                        selected: _bottomTabIndex == 0,
                                      ),
                                    ),
                                    const SizedBox(width: innerGap),
                                    Expanded(
                                      child: _liquidNavItem(
                                        icon: CupertinoIcons.clock,
                                        iconFilled: CupertinoIcons.clock_fill,
                                        label:
                                            l10n.translate('sip_tab_journal'),
                                        selected: _bottomTabIndex == 1,
                                      ),
                                    ),
                                    const SizedBox(width: innerGap),
                                    Expanded(
                                      child: _liquidNavItem(
                                        icon: CupertinoIcons.person_2,
                                        iconFilled:
                                            CupertinoIcons.person_2_fill,
                                        label: 'Контакты',
                                        selected: _bottomTabIndex == 2,
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
    required IconData icon,
    required IconData iconFilled,
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
            child: Icon(
              selected ? iconFilled : icon,
              key: ValueKey(selected),
              size: 22,
              color: selected ? const Color(0xFF0A84FF) : Colors.black,
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
              sigmaX: isPressed ? 24 : 20,
              sigmaY: isPressed ? 24 : 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.05,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.98 : 0.95),
                    const Color(0xFFF8F8FA),
                    const Color(0xFFF1F2F5),
                  ],
                  stops: const [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color:
                      Colors.white.withValues(alpha: isPressed ? 0.92 : 0.85),
                  width: isPressed ? 1.4 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.white.withValues(alpha: isPressed ? 0.92 : 0.82),
                    blurRadius: isPressed ? 16 : 14,
                    spreadRadius: 0.5,
                    offset: const Offset(0, -2),
                  ),
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(
                      alpha: isPressed ? 0.08 : 0.06,
                    ),
                    blurRadius: isPressed ? 18 : 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.40 : 0.30),
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                  stops: const [0.0, 0.38, 1.0],
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
                    Colors.white.withValues(alpha: isPressed ? 0.95 : 0.88),
                    Colors.white.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 18,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.6,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.30 : 0.22),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 6,
            height: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(alpha: isPressed ? 0.16 : 0.10),
                    Colors.transparent,
                  ],
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
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 68,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(
                    alpha: selected ? 0.10 : 0.07,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              selected
                  ? CupertinoIcons.search_circle_fill
                  : CupertinoIcons.search,
              color: selected ? const Color(0xFF0A84FF) : Colors.black,
              size: selected ? 28 : 24,
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

    if (state.callLogs.isEmpty) {
      return Padding(
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
      );
    }

    return ListView.separated(
      key: const ValueKey('journal'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      itemCount: state.callLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = state.callLogs[index];
        final isIncoming = item.direction == SipCallDirection.incoming;
        final isFailed = item.result == SipCallUiStatus.failed;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isFailed
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isIncoming
                    ? CupertinoIcons.arrow_down_left
                    : CupertinoIcons.arrow_up_right,
                color: isFailed
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
                size: 18,
              ),
            ),
            title: Text(
              item.target,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            subtitle: Text(
              '${_callLabel(context, item.result)} • ${_formatDuration(item.duration)}',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            trailing: Text(
              _formatTime(item.timestamp),
              style: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
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
    final recentCalls = state.callLogs.take(12).toList(growable: false);

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
        : state.callLogs
            .where((item) {
              final target = item.target.toLowerCase();
              final targetDigits = _digitsOnly(item.target);
              return target.contains(lowerQuery) ||
                  (queryDigits.isNotEmpty &&
                      targetDigits.contains(queryDigits));
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
                            child: _journalSearchTile(context, item),
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
                              child: _journalSearchTile(context, item),
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

  Widget _journalSearchTile(BuildContext context, SipCallLogEntry item) {
    final isIncoming = item.direction == SipCallDirection.incoming;
    final isFailed = item.result == SipCallUiStatus.failed;

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
        onTap: () {
          _sipIdController.value = TextEditingValue(
            text: item.target,
            selection: TextSelection.collapsed(offset: item.target.length),
          );
          _updateView(() => _bottomTabIndex = 0);
        },
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isFailed ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            isIncoming
                ? CupertinoIcons.arrow_down_left
                : CupertinoIcons.arrow_up_right,
            color: isFailed ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
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
          '${_callLabel(context, item.result)} • ${_formatTime(item.timestamp)}',
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            _sipIdController.value = TextEditingValue(
              text: item.target,
              selection: TextSelection.collapsed(offset: item.target.length),
            );
            _updateView(() => _bottomTabIndex = 0);
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
    required ValueChanged<String> onChanged,
    bool autofocus = false,
  }) {
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
      child: CupertinoSearchTextField(
        autofocus: autofocus,
        backgroundColor: Colors.transparent,
        itemColor: const Color(0xFF9CA3AF),
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
        prefixInsets: const EdgeInsetsDirectional.fromSTEB(14, 0, 10, 0),
        suffixInsets: const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        placeholder: placeholder,
        onChanged: onChanged,
      ),
    );
  }

  Widget _bottomSwitcher(BuildContext context, {bool embedded = false}) {
    if (embedded) return const SizedBox.shrink();
    return _ios26LiquidNavBar(context);
  }
}
