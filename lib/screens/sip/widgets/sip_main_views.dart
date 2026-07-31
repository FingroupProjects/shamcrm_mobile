// Этот файл отвечает за основные SIP-экраны: авторизация, набор, журнал и верхняя панель.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipMainViewsExtension on _SipScreenState {
  Widget _buildTopBar(BuildContext context, SipUiState state) {
    final colors = context.appColors;
    final isRegistered =
        state.registrationStatus == SipRegistrationUiStatus.registered;
    final showCompactStatus =
        isRegistered && state.callStatus != SipCallUiStatus.incoming;
    final isReconnectInProgress = _isReconnectInProgress(state);
    final isNetworkUnavailable = _isNetworkUnavailableState(state);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveCall = state.callStatus == SipCallUiStatus.incoming ||
        state.callStatus == SipCallUiStatus.calling ||
        state.callStatus == SipCallUiStatus.ringing ||
        state.callStatus == SipCallUiStatus.inCall;
    final String? subtitle = hasActiveCall
        ? _resolvedCallLabel(context, state)
        : isReconnectInProgress
            ? 'Восстанавливаем телефонную линию...'
            : isNetworkUnavailable
                ? 'Сеть потеряна. Ждём восстановление соединения'
                : isRegistered
                    ? null
                    : 'Подключите линию для звонков в фоне';

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
                      'Телефония',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    if (showCompactStatus) ...[
                      const SizedBox(height: 4),
                      _buildRegisteredIndicator(),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? colors.textPrimary.withValues(alpha: 0.96)
                              : colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          shadows: isDark
                              ? [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.58),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildTopIconButton(
                icon: CupertinoIcons.search,
                onPressed: () => _updateView(() => _bottomTabIndex = 3),
              ),
              const SizedBox(width: 8),
              _buildTopIconButton(
                icon: Icons.more_vert_rounded,
                onPressed: () => _showTelephonyMenu(context),
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
            //       // SizedBox(width: 8),
            //       // Expanded(
            //       //   child: Text(
            //       //     'На iPhone не закрывайте приложение свайпом из недавних. Для входящих держите его просто свернутым.',
            //       //     style: TextStyle(
            //       //       fontSize: 12,
            //       //       fontWeight: FontWeight.w600,
            //       //       color: Color(0xFF8A5A00),
            //       //       height: 1.25,
            //       //     ),
            //       //   ),
            //       // ),
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
    final colors = context.appColors;
    return SizedBox(
      width: 46,
      height: 46,
      child: _GlassButton(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Center(
          child: Icon(icon, size: 21, color: colors.iconPrimary),
        ),
      ),
    );
  }

  Future<void> _showTelephonyMenu(BuildContext anchorContext) async {
    final colors = anchorContext.appColors;
    final overlay = Navigator.of(anchorContext).overlay;
    if (overlay == null) return;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final selected = await showMenu<String>(
      context: anchorContext,
      position: RelativeRect.fromLTRB(
        overlayBox.size.width - 222,
        70,
        14,
        0,
      ),
      color: colors.surfacePrimary,
      surfaceTintColor: colors.surfacePrimary,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _telephonyMenuItem(
          value: 'settings',
          icon: CupertinoIcons.gear_alt_fill,
          label: AppLocalizations.of(anchorContext)!.translate('sip_settings'),
        ),
        _telephonyMenuItem(
          value: 'funnels',
          icon: CupertinoIcons.chart_bar_alt_fill,
          label: AppLocalizations.of(anchorContext)!.translate('sales_funnel'),
        ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected == 'settings') {
      await _showSettingsSheet();
    } else if (selected == 'funnels') {
      await _showSalesFunnelsMenu(anchorContext);
    }
  }

  PopupMenuItem<String> _telephonyMenuItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final colors = context.appColors;
    return PopupMenuItem<String>(
      value: value,
      height: 46,
      child: Row(
        children: [
          Icon(icon, size: 19, color: colors.iconSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSalesFunnelsMenu(BuildContext anchorContext) async {
    final colors = anchorContext.appColors;
    final overlay = Navigator.of(anchorContext).overlay;
    if (overlay == null) return;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    try {
      List<SalesFunnel> funnels;
      try {
        funnels = await _apiService.getSalesFunnels();
      } catch (_) {
        funnels = await _apiService.getCachedSalesFunnels();
      }
      if (!mounted || funnels.isEmpty) return;

      final selectedId =
          int.tryParse(await _apiService.getSelectedSalesFunnel() ?? '');
      if (!mounted) return;
      final selected = await showMenu<SalesFunnel>(
        context: anchorContext,
        position: RelativeRect.fromLTRB(
          overlayBox.size.width - 278,
          70,
          14,
          0,
        ),
        color: colors.surfacePrimary,
        surfaceTintColor: colors.surfacePrimary,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        items: funnels
            .map(
              (funnel) => PopupMenuItem<SalesFunnel>(
                value: funnel,
                height: 46,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        funnel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (selectedId == funnel.id)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: colors.buttonPrimaryBg,
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      );

      if (selected == null || selected.id == selectedId) return;
      await _apiService.saveSelectedSalesFunnel(selected.id.toString());
      await LeadCache.clearAllLeads();
      await LeadCache.clearCache();
      if (!mounted) return;
      context.read<SalesFunnelBloc>().add(SelectSalesFunnel(selected));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Не удалось загрузить список воронок'),
          backgroundColor: context.appColors.error,
        ),
      );
    }
  }

  Widget _buildRegisteredIndicator() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _TelephonyVisualColors.green.withValues(
          alpha: isDark ? 0.18 : 0.12,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _TelephonyVisualColors.green.withValues(alpha: 0.38),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 12,
            color: _TelephonyVisualColors.green,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.translate('telephony_online'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _TelephonyVisualColors.green,
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
      backgroundColor: context.appColors.backgroundPrimary,
      body: _TelephonyBackground(
        child: SafeArea(
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
                          'Телефония',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appColors.surfacePrimary
                          .withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xff1E2E52).withValues(alpha: 0.06),
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
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.appColors.textPrimary,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.translate('sip_welcome_subtitle'),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.appColors.textSecondary,
                                  height: 1.35,
                                  letterSpacing: 0,
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
                      color: context.appColors.surfacePrimary
                          .withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xff1E2E52).withValues(alpha: 0.06),
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
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                            letterSpacing: 0,
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
                          child: Text(
                            isRegistering
                                ? l10n.translate('sip_connecting')
                                : l10n.translate('sip_connect'),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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

  Widget _projectTransportSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final items = <(SipTransportUi, String)>[
      (SipTransportUi.ws, l10n.translate('sip_transport_ws')),
      (SipTransportUi.udp, 'UDP'),
      (SipTransportUi.tcp, l10n.translate('sip_transport_tcp')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('telephony_transport'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.fieldBorder),
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
                            ? colors.surfaceElevated
                            : colors.fieldBg.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedTransport == items[i].$1
                            ? [
                                BoxShadow(
                                  color: colors.shadow.withValues(alpha: 0.18),
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
                              ? colors.textPrimary
                              : colors.textSecondary,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        ? 'Восстанавливаем соединение'
        : isNetworkUnavailable
            ? 'Сеть недоступна'
            : isRegistered
                ? 'Телефония подключена'
                : 'Телефония не подключена';
    final subtitle = isReconnectInProgress
        ? 'Сеть восстановлена. Переподключаем телефонную линию'
        : isNetworkUnavailable
            ? 'Как только сеть вернётся, телефония подключится автоматически'
            : '${l10n.translate('sip_call_state')}: ${_resolvedCallLabel(context, state)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: isDark ? 0.70 : 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.06),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
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
                  color: _TelephonyVisualColors.blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRegistering) ...[
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CupertinoActivityIndicator(
                          color: colors.buttonPrimaryFg,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isRegistering ? 'Подключение...' : 'Подключить',
                      style: TextStyle(
                        color: colors.buttonPrimaryFg,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      color: colors.textSecondary,
      fontSize: isTight ? 12.0 : 13.0,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );
    final phoneStyle = TextStyle(
      color: colors.textPrimary,
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
                    color: colors.surfacePrimary.withValues(
                      alpha: isDark ? 0.72 : 0.90,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(
                          alpha: isDark ? 0.18 : 0.06,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: colors.borderSubtle,
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
                                      color: colors.iconSecondary,
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
                                      color: colors.iconSecondary,
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
                                  color: colors.iconSecondary,
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: Text(
                                    'Еще $extraResults ${_declineSearchResultsLabel(extraResults)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRegistered =
        state.registrationStatus == SipRegistrationUiStatus.registered;
    final maxWidth =
        constraints.maxWidth.isFinite ? constraints.maxWidth : 390.0;
    final maxHeight =
        constraints.maxHeight.isFinite ? constraints.maxHeight : 680.0;
    final isVeryCompact = maxHeight < 560 || maxWidth < 360;
    final isCompact = isVeryCompact || maxHeight < 640 || maxWidth < 395;
    final horizontalPadding = isVeryCompact
        ? 14.0
        : isCompact
            ? 18.0
            : 24.0;
    final rowGap = isVeryCompact
        ? 5.0
        : isCompact
            ? 8.0
            : 12.0;
    final headerHeight = isVeryCompact
        ? 38.0
        : isCompact
            ? 44.0
            : 52.0;
    final suggestionHeight = isCompact ? 6.0 : 108.0;
    final bottomPadding = isVeryCompact ? 4.0 : 10.0;
    final widthKeySize =
        ((maxWidth - (horizontalPadding * 2) - (rowGap * 2)) / 3)
            .clamp(58.0, 92.0);
    final reservedHeight =
        headerHeight + suggestionHeight + bottomPadding + (rowGap * 4) + 52;
    final heightKeySize = ((maxHeight - reservedHeight) / 4).clamp(58.0, 92.0);
    final keyOuterSize = math.min(widthKeySize, heightKeySize);
    final actionButtonSize = (keyOuterSize * 0.76).clamp(46.0, 68.0);
    final actionIconSize = (actionButtonSize * 0.42).clamp(21.0, 32.0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: headerHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                isVeryCompact ? 0 : 2,
                20,
                isVeryCompact ? 0 : 2,
              ),
              child: _dialNumberHeader(
                constraints,
                isCompact: isCompact,
                isVeryCompact: isVeryCompact,
              ),
            ),
          ),
          if (isRegistered && !isCompact)
            _inlineDialSuggestion(constraints)
          else
            SizedBox(height: suggestionHeight),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: List.generate(4, (row) {
                final start = row * 3;
                return Padding(
                  padding: EdgeInsets.only(bottom: rowGap),
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
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding + 2,
              0,
              horizontalPadding + 2,
              bottomPadding,
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
                            color: isDark
                                ? colors.textPrimary.withValues(alpha: 0.9)
                                : const Color(0xFF6B7280),
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
                            color: isDark
                                ? colors.textPrimary.withValues(alpha: 0.9)
                                : const Color(0xFF6B7280),
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

  double _fitDialTextFontSize({
    required String text,
    required double maxWidth,
    required double maxFontSize,
    required double minFontSize,
  }) {
    if (text.isEmpty || maxWidth <= 0) return maxFontSize;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: maxFontSize,
          fontWeight: FontWeight.w300,
          letterSpacing: 0,
        ),
      ),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    if (painter.width <= maxWidth) return maxFontSize;
    return (maxFontSize * maxWidth / painter.width)
        .clamp(minFontSize, maxFontSize);
  }

  Widget _dialNumberHeader(
    BoxConstraints constraints, {
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final typedNumber = _sipIdController.text.trim();
    final maxFontSize = isVeryCompact
        ? 28.0
        : isCompact
            ? 32.0
            : 38.0;
    final fontSize = _fitDialTextFontSize(
      text: typedNumber,
      maxWidth: constraints.maxWidth - 40,
      maxFontSize: maxFontSize,
      minFontSize: isVeryCompact ? 20.0 : 22.0,
    );
    final placeholderSize = isVeryCompact
        ? 19.0
        : isCompact
            ? 22.0
            : 27.0;
    return GestureDetector(
      onTap: _expandDialPanel,
      onLongPress: _showDialActions,
      child: CupertinoTextField(
        controller: _sipIdController,
        focusNode: _dialFocusNode,
        readOnly: true,
        showCursor: true,
        cursorColor: context.appColors.textPrimary,
        cursorWidth: 2,
        cursorHeight: fontSize,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: context.appColors.textPrimary.withValues(alpha: 0.98),
          letterSpacing: 0,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 2,
            ),
          ],
        ),
        placeholder:
            AppLocalizations.of(context)!.translate('telephony_enter_number'),
        placeholderStyle: TextStyle(
          fontSize: placeholderSize,
          fontWeight: FontWeight.w300,
          color: context.appColors.textMuted,
          letterSpacing: 0,
        ),
        magnifierConfiguration: TextMagnifierConfiguration.disabled,
        padding: EdgeInsets.symmetric(
          horizontal: isVeryCompact ? 2 : 6,
          vertical: isVeryCompact ? 0 : 2,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary
                        .withValues(alpha: isDark ? 0.48 : 0.62),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.12),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: colors.borderSubtle.withValues(alpha: 0.72),
                      width: 1,
                    ),
                  ),
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
                    color: colors.textPrimary,
                    letterSpacing: 0,
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
                      color: isDark
                          ? colors.textPrimary.withValues(alpha: 0.92)
                          : colors.textSecondary,
                      height: 1.2,
                      shadows: isDark
                          ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.38),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: colors.surfacePrimary.withValues(
                  alpha: isDark ? 0.70 : 0.88,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(
                      alpha: isDark ? 0.18 : 0.06,
                    ),
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
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.circle_grid_3x3_fill,
                      size: 18,
                      color: colors.iconPrimary,
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          _sipIdController.text.trim().isEmpty
                              ? l10n.translate('telephony_open_keypad')
                              : _sipIdController.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
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
  // Три основные вкладки; поиск находится в верхней панели.
  Widget _ios26LiquidNavBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        label: l10n.translate('telephony_calls'),
      ),
      if (_hasContactsTab)
        (
          index: 2,
          iconAsset: 'assets/icons/sip/contact_off.png',
          activeIconAsset: 'assets/icons/sip/contact_on.png',
          label: l10n.translate('telephony_contacts'),
        ),
    ];
    final segmentCount = navItems.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 5.0;
            const innerGap = 2.0;
            final maxIndex = segmentCount - 1;
            final currentNavPosition =
                navItems.indexWhere((item) => item.index == _bottomTabIndex);
            final fallbackNavPosition = navItems.indexWhere(
              (item) => item.index == 1,
            );
            int currentSelectedNavPosition() {
              final position = navItems.indexWhere(
                (item) => item.index == _bottomTabIndex,
              );
              return position >= 0
                  ? position
                  : math.max(0, fallbackNavPosition);
            }

            final selectedIndex = (_liquidNavDragIndex ??
                    (currentNavPosition >= 0
                        ? currentNavPosition.toDouble()
                        : math.max(0, fallbackNavPosition).toDouble()))
                .clamp(0.0, maxIndex.toDouble());
            final usableWidth = constraints.maxWidth - (horizontalPadding * 2);
            final segmentWidth =
                (usableWidth - innerGap * (segmentCount - 1)) / segmentCount;
            final thumbLeft = selectedIndex * (segmentWidth + innerGap);
            final highlightedIndex = selectedIndex.round().clamp(0, maxIndex);
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
              final nextPosition = (safeDx / (segmentWidth + innerGap))
                  .round()
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
                // onTapDown may have already selected another tab before
                // Flutter recognizes the same touch as a short drag.
                // Read the current state here, not the value captured by
                // this build, otherwise the drag end can restore the old tab.
                final dragStartPosition = currentSelectedNavPosition();
                _updateView(() {
                  _isLiquidNavPressed = true;
                  _liquidNavDragIndex = dragStartPosition.toDouble();
                });
              },
              onHorizontalDragUpdate: (details) {
                final safeDx = (details.localPosition.dx - horizontalPadding)
                    .clamp(0.0, usableWidth);
                final dragIndex = safeDx / (segmentWidth + innerGap);
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
                final resetPosition = currentSelectedNavPosition();
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
                          colors.surfacePrimary.withValues(
                            alpha: isDark ? 0.62 : 0.78,
                          ),
                          colors.surfaceElevated.withValues(
                            alpha: isDark ? 0.52 : 0.68,
                          ),
                          colors.surfaceAccent.withValues(alpha: 0.48),
                        ],
                        stops: const [0.0, 0.58, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(42),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(
                            alpha: isDark ? 0.26 : 0.12,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
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
    );
  }

  Widget _liquidNavItem({
    required String iconAsset,
    required String activeIconAsset,
    required String label,
    required bool selected,
  }) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: selected
                  ? _TelephonyVisualColors.blue
                  : (isDark
                      ? colors.textPrimary.withValues(alpha: 0.84)
                      : colors.iconSecondary),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 15,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                sanitizeUtf16(label),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? _TelephonyVisualColors.blue
                      : (Theme.of(context).brightness == Brightness.dark
                          ? colors.textPrimary.withValues(alpha: 0.88)
                          : colors.textSecondary),
                  letterSpacing: 0,
                  shadows: Theme.of(context).brightness == Brightness.dark
                      ? [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.38),
                            blurRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liquidMirrorThumb({required bool isPressed}) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isPressed ? 28 : 22,
          sigmaY: isPressed ? 28 : 22,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              _TelephonyVisualColors.blue.withValues(
                alpha: isPressed ? 0.24 : (isDark ? 0.18 : 0.12),
              ),
              colors.surfaceElevated.withValues(alpha: isDark ? 0.88 : 0.94),
            ),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: _TelephonyVisualColors.blue.withValues(
                alpha: isPressed ? 0.58 : 0.36,
              ),
              width: isPressed ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _TelephonyVisualColors.blue.withValues(alpha: 0.12),
                blurRadius: isPressed ? 20 : 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
}
