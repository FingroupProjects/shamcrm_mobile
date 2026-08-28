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
    final headerForeground = _sipHeaderForeground(context);
    final headerSecondary = _sipHeaderSecondary(context);
    final headerShadows = _sipHeaderShadows(context);
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
                    : _sipRuntime.wantsSipConnection
                        ? 'Подключите линию для звонков в фоне'
                        : null;

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
                        color: headerForeground,
                        letterSpacing: 0,
                        shadows: headerShadows,
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
                          color: headerSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          shadows: headerShadows,
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

  /// Ink for text/icons on frosted glass (search, chips, AppBar, nav),
  /// not on the raw wallpaper behind them.
  Color _glassControlInk(BuildContext context, {double alpha = 0.92}) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Prefer field/surface blend: search bars use fieldBg, chips use surface.
    final surfaceLuminance = Color.lerp(
          colors.surfacePrimary,
          colors.fieldBg,
          0.35,
        )!
        .computeLuminance();
    final onDarkSurface = surfaceLuminance < 0.42 ||
        (isDark && surfaceLuminance < 0.55);
    final base = onDarkSurface ? Colors.white : const Color(0xFF1E293B);
    return base.withValues(alpha: alpha.clamp(0.0, 1.0));
  }

  Color _glassControlSecondaryInk(BuildContext context) {
    return _glassControlInk(context, alpha: 0.58);
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _glassControlInk(context);
    return SizedBox(
      width: 46,
      height: 46,
      child: _GlassButton(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        // Slightly denser frost so icon contrast stays stable on bright wallpapers.
        color: colors.surfacePrimary.withValues(alpha: isDark ? 0.72 : 0.86),
        borderColor: colors.borderSubtle.withValues(alpha: isDark ? 0.62 : 0.78),
        onPressed: onPressed,
        child: Center(
          child: Icon(
            icon,
            size: 21,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Future<void> _showTelephonyMenu(BuildContext anchorContext) async {
    final colors = anchorContext.appColors;
    final l10n = AppLocalizations.of(anchorContext)!;
    final result = await showGeneralDialog<_TelephonyMenuAction>(
      context: anchorContext,
      barrierDismissible: true,
      barrierLabel: 'telephony_menu',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 58,
                right: 14,
                child: FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    alignment: Alignment.topRight,
                    child: Material(
                      color: Colors.transparent,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 236,
                          maxWidth: 278,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfacePrimary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.borderSubtle.withValues(alpha: 0.55),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.18),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _TelephonyOverflowMenuPanel(
                            settingsLabel: l10n.translate('sip_settings'),
                            funnelsLabel: l10n.translate('sales_funnel'),
                            loadFunnels: () async {
                              try {
                                return await _apiService.getSalesFunnels();
                              } catch (_) {
                                return _apiService.getCachedSalesFunnels();
                              }
                            },
                            loadSelectedFunnelId: () async {
                              return int.tryParse(
                                await _apiService.getSelectedSalesFunnel() ??
                                    '',
                              );
                            },
                            onSettingsSelected: () {
                              Navigator.of(dialogContext).pop(
                                const _TelephonyMenuAction.settings(),
                              );
                            },
                            onFunnelSelected: (funnel) {
                              Navigator.of(dialogContext).pop(
                                _TelephonyMenuAction.funnel(funnel),
                              );
                            },
                            onLoadError: () {
                              Navigator.of(dialogContext).pop(
                                const _TelephonyMenuAction.loadError(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );

    if (!mounted || result == null) return;

    if (result.isSettings) {
      await _showSettingsSheet();
      return;
    }

    if (result.isLoadError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Не удалось загрузить список воронок'),
          backgroundColor: context.appColors.error,
        ),
      );
      return;
    }

    final selected = result.funnel;
    if (selected == null) return;

    final selectedId =
        int.tryParse(await _apiService.getSelectedSalesFunnel() ?? '');
    if (selected.id == selectedId) return;

    await _apiService.saveSelectedSalesFunnel(selected.id.toString());
    await LeadCache.clearAllLeads();
    await LeadCache.clearCache();
    if (!mounted) return;
    context.read<SalesFunnelBloc>().add(SelectSalesFunnel(selected));
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
                            color: _sipHeaderForeground(context),
                            letterSpacing: 0,
                            shadows: _sipHeaderShadows(context),
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
                    color: _glassControlInk(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _glassControlSecondaryInk(context),
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
    final glassInk = _glassControlInk(context);
    final glassSecondaryInk = _glassControlSecondaryInk(context);
    final nameStyle = TextStyle(
      color: glassSecondaryInk,
      fontSize: isTight ? 12.0 : 13.0,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );
    final phoneStyle = TextStyle(
      color: glassInk,
      fontSize: isTight ? 13.0 : 14.0,
      fontWeight: FontWeight.w600,
      height: 1.1,
    );
    final sourceStyle = TextStyle(
      color: glassSecondaryInk,
      fontSize: isTight ? 12.0 : 13.0,
      fontWeight: FontWeight.w500,
      height: 1.1,
    );

    Widget phoneAndSource({TextAlign textAlign = TextAlign.left}) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: suggestion!.phone, style: phoneStyle),
            TextSpan(
              text: '  ${suggestion.sourceLabel}',
              style: sourceStyle,
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      );
    }

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
                                      color: glassSecondaryInk,
                                    ),
                                    SizedBox(width: gap),
                                    Expanded(
                                      child: suggestion.name.isEmpty
                                          ? phoneAndSource()
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  suggestion.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: nameStyle,
                                                ),
                                                const SizedBox(height: 2),
                                                phoneAndSource(),
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
                                      color: glassSecondaryInk,
                                    ),
                                    SizedBox(width: gap),
                                    if (suggestion.name.isNotEmpty) ...[
                                      Expanded(
                                        child: Text(
                                          suggestion.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: nameStyle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: phoneAndSource(
                                        textAlign: suggestion.name.isEmpty
                                            ? TextAlign.left
                                            : TextAlign.right,
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
                                  color: glassSecondaryInk,
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: Text(
                                    'Еще $extraResults ${_declineSearchResultsLabel(extraResults)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: glassSecondaryInk,
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
    final keypadForeground = _sipKeypadForeground(context);
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
              child: AnimatedBuilder(
                animation: _sipIdController,
                builder: (context, _) => _dialNumberHeader(
                  constraints,
                  isCompact: isCompact,
                  isVeryCompact: isVeryCompact,
                ),
              ),
            ),
          ),
          if (isRegistered && !isCompact)
            AnimatedBuilder(
              animation: _sipIdController,
              builder: (context, _) => ValueListenableBuilder<int>(
                valueListenable: _dialSuggestionsTick,
                builder: (context, _, __) =>
                    _inlineDialSuggestion(constraints),
              ),
            )
          else
            SizedBox(height: suggestionHeight),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: RepaintBoundary(
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
                          onLongPress: key == '0'
                              ? () => _replaceLastDialChar('0', '+')
                              : null,
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding + 2,
              0,
              horizontalPadding + 2,
              bottomPadding,
            ),
            child: AnimatedBuilder(
              animation: _sipIdController,
              builder: (context, _) {
                final hasNumber = _sipIdController.text.isNotEmpty;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: actionButtonSize,
                      height: actionButtonSize,
                      child: hasNumber
                          ? CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _showAddDialDestinationSheet,
                              child: Icon(
                                CupertinoIcons.person_crop_circle_badge_plus,
                                color: keypadForeground.withValues(alpha: 0.9),
                                size: actionIconSize,
                                shadows: _sipKeypadShadows(context),
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
                      child: hasNumber
                          ? Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (_) => _backspaceDial(),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onLongPress: _clearDial,
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.delete_left_fill,
                                    color:
                                        keypadForeground.withValues(alpha: 0.9),
                                    size: actionIconSize - 1,
                                    shadows: _sipKeypadShadows(context),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
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
          fontFamily: 'SF Pro Display',
          fontSize: maxFontSize,
          fontWeight: FontWeight.w400,
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
    final keypadForeground = _sipKeypadForeground();
    final keypadSecondary = _sipKeypadSecondary();
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDialPointerDown,
      onPointerMove: _onDialPointerMove,
      onPointerUp: _onDialPointerUp,
      onPointerCancel: _onDialPointerUp,
      child: CupertinoTextField(
        controller: _sipIdController,
        focusNode: _dialFocusNode,
        readOnly: true,
        enableInteractiveSelection: true,
        showCursor: true,
        cursorColor: keypadForeground,
        cursorWidth: 2,
        cursorHeight: fontSize,
        textAlign: TextAlign.center,
        maxLines: 1,
        onTap: () {
          _dialFocusNode.requestFocus();
          _expandDialPanel();
        },
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: keypadForeground.withValues(alpha: 0.98),
          letterSpacing: 0,
          shadows: _sipKeypadShadows(),
        ),
        placeholder: AppLocalizations.of(context)!
            .translate('telephony_enter_number'),
        placeholderStyle: TextStyle(
          fontSize: placeholderSize,
          fontWeight: FontWeight.w300,
          color: keypadSecondary.withValues(alpha: 0.78),
          letterSpacing: 0,
          shadows: _sipKeypadShadows(),
        ),
        contextMenuBuilder: _dialContextMenuBuilder,
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
    final isTight = outerSize < 84;
    final innerInset = isTight ? 4.0 : 8.0;
    final innerSize = (outerSize - innerInset).clamp(52.0, 88.0);

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: LiquidPinKey(
        key: ValueKey('sip_dial_$value'),
        digit: value,
        letters: letters,
        size: innerSize,
        onPressed: onTap,
        onLongPress: onLongPress,
        textColor: _sipKeypadForeground(),
        isDarkBackground: _isSipKeypadOnDark(),
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
            onLongPress: () => unawaited(_showDialActions()),
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
                      color: _glassControlInk(context),
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
                            color: _glassControlInk(context),
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
                            color: _glassControlSecondaryInk(context),
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
            const horizontalPadding = 7.0;
            const verticalPadding = 5.0;
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
            final segmentLeft = selectedIndex * (segmentWidth + innerGap);
            final highlightedIndex = selectedIndex.round().clamp(0, maxIndex);
            final restingThumbWidth = segmentWidth;
            final restingThumbLeft = segmentLeft;
            final pressedExpansion = math.min(30.0, segmentWidth * 0.24);
            final thumbExpansion = _isLiquidNavPressed ? pressedExpansion : 0.0;
            final thumbWidth = restingThumbWidth + thumbExpansion;
            final thumbLeft = (restingThumbLeft - thumbExpansion / 2)
                .clamp(0.0, usableWidth - thumbWidth);
            final thumbTop = _isLiquidNavPressed ? 0.0 : 2.0;
            final thumbHeight = _isLiquidNavPressed ? 70.0 : 66.0;

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
                        pressed: isSelected(i) && _isLiquidNavPressed,
                      ),
                    ),
                  ],
                ],
              );
            }

            int tapPositionFor(double localDx) {
              final safeDx = localDx.clamp(
                0.0,
                math.max(0.0, constraints.maxWidth - 0.001),
              );
              return ((safeDx / constraints.maxWidth) * segmentCount)
                  .floor()
                  .clamp(0, maxIndex);
            }

            void selectPosition(int nextPosition) {
              final nextIndex = navItems[nextPosition].index;
              _updateView(() {
                _bottomTabIndex = nextIndex;
                _liquidNavDragIndex = nextPosition.toDouble();
                _isLiquidNavPressed = false;
              });
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                // Continue from the glass position shown under the finger.
                final dragStartPosition = (_liquidNavDragIndex ??
                        currentSelectedNavPosition().toDouble())
                    .clamp(0.0, maxIndex.toDouble());
                _updateView(() {
                  _isLiquidNavPressed = true;
                  _liquidNavDragIndex = dragStartPosition;
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
                final pressedPosition =
                    tapPositionFor(details.localPosition.dx);
                _updateView(() {
                  _isLiquidNavPressed = true;
                  // Move only the glass highlight on touch-down. The actual
                  // page is committed on touch-up, so taps and swipes cannot
                  // open neighboring tabs by accident.
                  _liquidNavDragIndex = pressedPosition.toDouble();
                });
              },
              onTapUp: (details) {
                selectPosition(tapPositionFor(details.localPosition.dx));
              },
              onTapCancel: () {
                final resetPosition = currentSelectedNavPosition();
                _updateView(() {
                  _isLiquidNavPressed = false;
                  _liquidNavDragIndex = resetPosition.toDouble();
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(46),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.surfacePrimary.withValues(
                            alpha: isDark ? 0.78 : 0.90,
                          ),
                          colors.surfaceElevated.withValues(
                            alpha: isDark ? 0.70 : 0.84,
                          ),
                          colors.surfaceAccent.withValues(
                            alpha: isDark ? 0.42 : 0.48,
                          ),
                        ],
                        stops: const [0.0, 0.58, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(46),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.88),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(
                            alpha: isDark ? 0.28 : 0.14,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: Duration(
                            milliseconds: _isLiquidNavPressed ? 90 : 300,
                          ),
                          curve: _isLiquidNavPressed
                              ? Curves.easeOut
                              : Curves.easeOutQuart,
                          left: thumbLeft,
                          top: thumbTop,
                          width: thumbWidth,
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
    required bool pressed,
  }) {
    final unselectedColor = _glassControlInk(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutQuart,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(34),
      ),
      child: AnimatedScale(
        scale: pressed ? 1.15 : 1.0,
        duration: Duration(milliseconds: pressed ? 100 : 320),
        curve: pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              selected ? activeIconAsset : iconAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              color: selected ? _TelephonyVisualColors.blue : unselectedColor,
              colorBlendMode: BlendMode.srcIn,
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
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? _TelephonyVisualColors.blue
                        : unselectedColor,
                    letterSpacing: 0,
                    height: 1.05,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liquidMirrorThumb({required bool isPressed}) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const outerRadius = 44.0;
    final thumbPadding = isPressed ? 2.6 : 1.0;
    final innerRadius = outerRadius - thumbPadding;

    return AnimatedContainer(
      duration: Duration(milliseconds: isPressed ? 100 : 320),
      curve: isPressed ? Curves.easeOutCubic : Curves.easeOutBack,
      padding: EdgeInsets.all(thumbPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isPressed ? 0.88 : 0.58),
            _TelephonyVisualColors.blue.withValues(
              alpha: isPressed ? 0.58 : 0.38,
            ),
            Colors.white.withValues(alpha: isPressed ? 0.30 : 0.16),
            _TelephonyVisualColors.blue.withValues(
              alpha: isPressed ? 0.66 : 0.42,
            ),
          ],
          stops: const [0.0, 0.28, 0.62, 1.0],
        ),
        borderRadius: BorderRadius.circular(outerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isPressed ? (isDark ? 0.34 : 0.18) : 0.10,
            ),
            blurRadius: isPressed ? 24 : 14,
            spreadRadius: isPressed ? 1.0 : 0.0,
            offset: Offset(0, isPressed ? 8 : 4),
          ),
          BoxShadow(
            color: _TelephonyVisualColors.blue.withValues(
              alpha: isPressed ? 0.30 : 0.12,
            ),
            blurRadius: isPressed ? 22 : 12,
            spreadRadius: isPressed ? 0.8 : 0.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isPressed ? 32 : 22,
            sigmaY: isPressed ? 32 : 22,
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: isPressed ? 100 : 300),
            curve: isPressed ? Curves.easeOutCubic : Curves.easeOutQuart,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(
                    alpha: isPressed ? (isDark ? 0.18 : 0.46) : 0.16,
                  ),
                  Color.alphaBlend(
                    _TelephonyVisualColors.blue.withValues(
                      alpha: isPressed ? 0.28 : (isDark ? 0.18 : 0.12),
                    ),
                    colors.surfaceElevated.withValues(
                      alpha: isDark ? 0.82 : 0.90,
                    ),
                  ),
                  colors.surfacePrimary.withValues(
                    alpha: isPressed ? 0.70 : 0.82,
                  ),
                ],
                stops: const [0.0, 0.46, 1.0],
              ),
              borderRadius: BorderRadius.circular(innerRadius),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 26,
                  right: 26,
                  top: 1,
                  height: isPressed ? 2.0 : 1.2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(
                            alpha: isPressed ? 0.92 : 0.56,
                          ),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 30,
                  right: 30,
                  bottom: 1,
                  height: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _TelephonyVisualColors.blue.withValues(alpha: 0),
                          _TelephonyVisualColors.blue.withValues(
                            alpha: isPressed ? 0.48 : 0.24,
                          ),
                          _TelephonyVisualColors.blue.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
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

class _TelephonyMenuAction {
  const _TelephonyMenuAction.settings()
      : isSettings = true,
        isLoadError = false,
        funnel = null;

  const _TelephonyMenuAction.loadError()
      : isSettings = false,
        isLoadError = true,
        funnel = null;

  const _TelephonyMenuAction.funnel(this.funnel)
      : isSettings = false,
        isLoadError = false;

  final bool isSettings;
  final bool isLoadError;
  final SalesFunnel? funnel;
}

class _TelephonyOverflowMenuPanel extends StatefulWidget {
  const _TelephonyOverflowMenuPanel({
    required this.settingsLabel,
    required this.funnelsLabel,
    required this.loadFunnels,
    required this.loadSelectedFunnelId,
    required this.onSettingsSelected,
    required this.onFunnelSelected,
    required this.onLoadError,
  });

  final String settingsLabel;
  final String funnelsLabel;
  final Future<List<SalesFunnel>> Function() loadFunnels;
  final Future<int?> Function() loadSelectedFunnelId;
  final VoidCallback onSettingsSelected;
  final ValueChanged<SalesFunnel> onFunnelSelected;
  final VoidCallback onLoadError;

  @override
  State<_TelephonyOverflowMenuPanel> createState() =>
      _TelephonyOverflowMenuPanelState();
}

class _TelephonyOverflowMenuPanelState
    extends State<_TelephonyOverflowMenuPanel> {
  bool _funnelsExpanded = false;
  bool _isLoadingFunnels = false;
  List<SalesFunnel> _funnels = const [];
  int? _selectedFunnelId;

  Future<void> _toggleFunnels() async {
    if (_funnelsExpanded) {
      setState(() => _funnelsExpanded = false);
      return;
    }

    if (_funnels.isNotEmpty) {
      setState(() => _funnelsExpanded = true);
      return;
    }

    setState(() {
      _funnelsExpanded = true;
      _isLoadingFunnels = true;
    });

    try {
      final results = await Future.wait([
        widget.loadFunnels(),
        widget.loadSelectedFunnelId(),
      ]);
      if (!mounted) return;
      final funnels = results[0] as List<SalesFunnel>;
      final selectedId = results[1] as int?;
      setState(() {
        _funnels = funnels;
        _selectedFunnelId = selectedId;
        _isLoadingFunnels = false;
        _funnelsExpanded = funnels.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingFunnels = false;
        _funnelsExpanded = false;
      });
      widget.onLoadError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              _buildMenuRow(
                icon: CupertinoIcons.gear_alt_fill,
                label: widget.settingsLabel,
                trailing: CupertinoIcons.chevron_right,
                onTap: widget.onSettingsSelected,
              ),
              _buildMenuRow(
                icon: CupertinoIcons.chart_bar_alt_fill,
                label: widget.funnelsLabel,
                trailing: _funnelsExpanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_right,
                onTap: _toggleFunnels,
              ),
              if (_funnelsExpanded) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.borderSubtle.withValues(alpha: 0.55),
                  ),
                ),
                if (_isLoadingFunnels)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _funnels.map(_buildFunnelRow).toList(),
                      ),
                    ),
                  ),
              ],
              if (!_funnelsExpanded) const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String label,
    required IconData trailing,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: colors.iconSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
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
            const SizedBox(width: 8),
            Icon(
              trailing,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelRow(SalesFunnel funnel) {
    final colors = context.appColors;
    final isSelected = _selectedFunnelId == funnel.id;
    return InkWell(
      onTap: () => widget.onFunnelSelected(funnel),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            const SizedBox(width: 31),
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
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: colors.buttonPrimaryBg,
              ),
          ],
        ),
      ),
    );
  }
}
