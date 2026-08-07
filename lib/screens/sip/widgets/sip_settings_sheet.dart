// Этот файл отвечает за модальное окно SIP-настроек и поля подключения.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipSettingsSheetExtension on _SipScreenState {
  Future<void> _showSettingsSheet() async {
    final l10n = AppLocalizations.of(context)!;
    var passwordVisible = false;
    final currentState = _sipRuntime.state;
    final isRegistered =
        currentState.registrationStatus == SipRegistrationUiStatus.registered;
    _suspendDraftAutosave = true;
    _serverController.text = currentState.server;
    _loginController.text = currentState.login;
    _passwordController.text = currentState.password;
    _portController.text = currentState.port.toString();
    _selectedTransport = currentState.transport;
    _suspendDraftAutosave = false;

    var outboundNumber = currentState.outboundNumber.trim();
    var internalNumber = currentState.internalNumber.trim();
    if (isRegistered) {
      final resolved = await Future.wait<String>([
        _sipRuntime.ensureOutboundNumber(forceRefresh: true),
        _sipRuntime.ensureInternalNumber(forceRefresh: true),
      ]);
      outboundNumber = resolved[0];
      internalNumber = resolved[1];
    } else if (internalNumber.isEmpty) {
      internalNumber = await _sipRuntime.ensureInternalNumber();
    }

    final outboundNumberController = TextEditingController(
      text: outboundNumber,
    );
    final internalNumberController = TextEditingController(
      text: internalNumber,
    );

    try {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (context) {
          final mediaQuery = MediaQuery.of(context);
          final state = _sipRuntime.state;
          final showOutboundNumber = isRegistered &&
              outboundNumberController.text.trim().isNotEmpty;
          final showInternalNumber =
              internalNumberController.text.trim().isNotEmpty;
          return Material(
            color: Colors.transparent,
            child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      maxHeight: mediaQuery.size.height * 0.92,
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.appColors.surfacePrimary
                                .withValues(alpha: 0.92),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(28)),
                            border: Border.all(
                              color: context.appColors.borderSubtle
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 46,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: context.appColors.borderPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l10n.translate('sip_settings'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: context.appColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _iosField(
                                controller: _serverController,
                                placeholder: l10n.translate('sip_server'),
                              ),
                              const SizedBox(height: 10),
                              _iosField(
                                controller: _loginController,
                                placeholder: l10n.translate('sip_login'),
                              ),
                              if (showOutboundNumber) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 6,
                                    ),
                                    child: Text(
                                      l10n.translate('sip_outbound_number'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.appColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                _iosField(
                                  controller: outboundNumberController,
                                  placeholder:
                                      l10n.translate('sip_outbound_number'),
                                  readOnly: true,
                                  suffix: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    // child: Icon(
                                    //   CupertinoIcons.lock_fill,
                                    //   size: 18,
                                    //   color: context.appColors.iconSecondary,
                                    // ),
                                  ),
                                ),
                              ],
                              if (showInternalNumber) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 6,
                                    ),
                                    child: Text(
                                      l10n.translate('sip_internal_number'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.appColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                _iosField(
                                  controller: internalNumberController,
                                  placeholder:
                                      l10n.translate('sip_internal_number'),
                                  readOnly: true,
                                  suffix: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    // child: Icon(
                                    //   CupertinoIcons.lock_fill,
                                    //   size: 18,
                                    //   color: context.appColors.iconSecondary,
                                    // ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              StatefulBuilder(
                                builder: (context, setPasswordState) =>
                                    _iosField(
                                  controller: _passwordController,
                                  placeholder: l10n.translate('sip_password'),
                                  obscureText: !passwordVisible,
                                  suffix: CupertinoButton(
                                    minimumSize: const Size(44, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    onPressed: () {
                                      setPasswordState(() {
                                        passwordVisible = !passwordVisible;
                                      });
                                    },
                                    child: Icon(
                                      passwordVisible
                                          ? CupertinoIcons.eye_slash
                                          : CupertinoIcons.eye,
                                      size: 21,
                                      color: context.appColors.iconSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _transportSelector(context),
                              const SizedBox(height: 10),
                              _iosField(
                                controller: _portController,
                                placeholder: l10n.translate('sip_port'),
                                keyboardType: TextInputType.number,
                              ),
                              if (defaultTargetPlatform == TargetPlatform.iOS ||
                                  defaultTargetPlatform ==
                                      TargetPlatform.android) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    color: context.appColors.surfaceAccent,
                                    borderRadius: BorderRadius.circular(14),
                                    onPressed: () async {
                                      await _showIosDiagnosticsSheet(context);
                                    },
                                    child: Text(
                                      'Диагностика телефонии',
                                      style: TextStyle(
                                        color: _TelephonyVisualColors.blue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: CupertinoButton(
                                      color: _TelephonyVisualColors.blue,
                                      borderRadius: BorderRadius.circular(14),
                                      onPressed: state.registrationStatus ==
                                              SipRegistrationUiStatus
                                                  .registering
                                          ? null
                                          : () async {
                                              await _saveDraft();
                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                              }
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                unawaited(
                                                    _sipRuntime.connect());
                                              });
                                            },
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 15,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (state.registrationStatus ==
                                              SipRegistrationUiStatus
                                                  .registering) ...[
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CupertinoActivityIndicator(
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            state.registrationStatus ==
                                                    SipRegistrationUiStatus
                                                        .registering
                                                ? l10n
                                                    .translate('sip_connecting')
                                                : l10n.translate('sip_connect'),
                                            style: const TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CupertinoButton(
                                      color: context.appColors.buttonDangerBg,
                                      borderRadius: BorderRadius.circular(14),
                                      onPressed: () async {
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          unawaited(_sipRuntime.disconnect());
                                        });
                                      },
                                      child: Text(
                                        l10n.translate('sip_disconnect'),
                                      ),
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
                ),
              ),
              ),
            ),
          );
        },
      );
    } finally {
      outboundNumberController.dispose();
      internalNumberController.dispose();
    }
  }

  Widget _iosField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    final colors = context.appColors;
    return CupertinoTextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      enableInteractiveSelection: true,
      keyboardType: keyboardType,
      suffix: suffix,
      suffixMode: OverlayVisibilityMode.always,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      placeholder: placeholder,
      cursorColor: _TelephonyVisualColors.blue,
      style: TextStyle(
        color: readOnly
            ? colors.textPrimary.withValues(alpha: 0.78)
            : colors.textPrimary,
      ),
      placeholderStyle: TextStyle(color: colors.fieldHint),
      decoration: BoxDecoration(
        color: readOnly
            ? colors.fieldBg.withValues(alpha: 0.72)
            : colors.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.fieldBorder),
      ),
    );
  }

  Future<void> _showIosDiagnosticsSheet(BuildContext context) async {
    final isAndroid = Platform.isAndroid;
    // Flutter UI can lag behind native Linphone state (shows failed while
    // native is still registered). Sync first so diagnostics don't look like
    // a false disconnect and don't trigger unnecessary reconnect churn.
    await _sipRuntime.syncNativeStateForDiagnostics();

    final voipToken = isAndroid ? null : await _sipRuntime.getVoipPushToken();
    final logs = await _sipRuntime.getNativeDiagnosticLogs();
    final outboundDiagnostics = await _sipRuntime.getOutboundNumberDiagnostics();
    final backendSync = isAndroid
        ? const <String, dynamic>{}
        : await _apiService.getVoipSyncDiagnostics();

    final nativeSnapshot = Map<String, dynamic>.from(
      outboundDiagnostics['nativeSnapshot'] as Map? ?? const {},
    );
    final flutterRegistration = _sipRuntime.state.registrationStatus.name;
    final nativeRegistration =
        nativeSnapshot['registrationState']?.toString() ?? 'unknown';
    final registrationMismatch = flutterRegistration != nativeRegistration;

    final tokenText = (voipToken == null || voipToken.trim().isEmpty)
        ? 'VoIP token: MISSING'
        : 'VoIP token: ${voipToken.trim()}';
    final registrationText =
        'Registration (Flutter): $flutterRegistration\nRegistration (Native): $nativeRegistration${registrationMismatch ? '\nNOTE: Flutter/Native registration mismatch — native is source of truth; opening diagnostics does NOT unregister SIP.' : ''}';
    final callText =
        'Call (Flutter): ${_sipRuntime.state.callStatus.name}\nCall (Native): ${nativeSnapshot['callState'] ?? 'unknown'}';
    final syncedAtMillis = backendSync['syncedAt'] as int?;
    final syncedAt = syncedAtMillis == null
        ? 'unknown'
        : DateTime.fromMillisecondsSinceEpoch(syncedAtMillis)
            .toLocal()
            .toIso8601String();
    final backendText =
        'Backend sync: status=${backendSync['status']}, http=${backendSync['httpCode'] ?? 'n/a'}, pending=${backendSync['hasPendingToken']}, at=$syncedAt';
    final backendError = backendSync['error']?.toString();
    final outboundDiagnosticsText =
        _buildOutboundNumberDiagnosticsReport(outboundDiagnostics);

    final visibleLogs = logs.reversed.toList(growable: false);
    String formatLogLine(Map<String, dynamic> entry) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        (((entry['timestamp'] as num?) ?? 0) * 1000).round(),
      ).toLocal();
      final event = entry['event']?.toString() ?? 'unknown';
      final details = (entry['details'] as Map?)
              ?.map((key, value) => MapEntry('$key', '$value'))
              .entries
              .map((item) => '${item.key}=${item.value}')
              .join(', ') ??
          '';
      return '${timestamp.toIso8601String()} | $event${details.isEmpty ? '' : ' | $details'}';
    }

    bool isSipSignalLog(Map<String, dynamic> entry) {
      final event = (entry['event']?.toString() ?? '').toUpperCase();
      return event.contains('CALL_') ||
          event.contains('BUSY') ||
          event.contains('EARLY_MEDIA') ||
          event.contains('OUTGOING_INVITE') ||
          event.contains('OUTGOING_NETWORK_MEDIA') ||
          event.contains('OUTGOING_WATCHDOG') ||
          event.contains('REGISTRATION') ||
          event.contains('SIP_REGISTER') ||
          event.contains('MEDIA_CONNECTED') ||
          event.contains('INVITE_') ||
          event.contains('HANGUP') ||
          event.contains('CALL_SIGNAL') ||
          event.contains('BUSY_OR_DECLINE');
    }

    final sipSignalLogs =
        visibleLogs.where(isSipSignalLog).map(formatLogLine).toList();
    final logLines = visibleLogs.isEmpty
        ? <String>['Native logs: empty']
        : visibleLogs.map(formatLogLine).toList(growable: false);

    final report = [
      'Диагностика телефонии ${Platform.isAndroid ? 'Android' : 'iOS'}',
      registrationText,
      callText,
      '',
      'Как читать busy-сценарий:',
      '- Ищите CALL_STATE_CHANGED / EARLY_MEDIA / OUTGOING_NETWORK_MEDIA / protocol_code=486',
      '- TTL отдаёт busy звуком (183+RTP), не SIP 486 — слушайте early media',
      '- Если только ringing без RTP/early media — проблема у оператора линии',
      '- EARLY_MEDIA / OUTGOING_NETWORK_MEDIA = сеть прислала звук (гудок или «занят»)',
      '- Короткий гудок ~8 с + remote hangup без 486 — типично для TTL SoftX, это не баг приложения',
      '- Динамик при исходящем не включается автоматически — только по кнопке пользователя',
      '- Если есть OUTGOING_NETWORK_MEDIA + слышен только гудок — контент RTP от TTL/Sipuni',
      '- protocol_code=486 / busy_signal=true — явный SIP busy; у TTL чаще только звук без 486',
      '',
      'Источник нашего номера',
      outboundDiagnosticsText,
      if (!isAndroid) tokenText,
      if (!isAndroid) backendText,
      if (!isAndroid && backendError != null && backendError.trim().isNotEmpty)
        'Backend error: $backendError',
      '',
      'SIP signal logs: ${sipSignalLogs.length} (filtered, newest first)',
      '',
      if (sipSignalLogs.isEmpty)
        'SIP signal logs: empty — сделайте тестовый звонок после обновления'
      else
        ...sipSignalLogs,
      '',
      'Native logs: ${logs.length} stored, newest first',
      '',
      ...logLines,
    ].join('\n');

    if (!context.mounted) return;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: context.appColors.surfacePrimary
                          .withValues(alpha: 0.94),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border.all(
                        color: context.appColors.borderSubtle
                            .withValues(alpha: 0.72),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD5DAE8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Диагностика телефонии ${isAndroid ? 'Android' : 'iPhone'}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: context.appColors.textPrimary,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            Builder(
                              builder: (shareButtonContext) => CupertinoButton(
                                minimumSize: const Size(42, 42),
                                padding: EdgeInsets.zero,
                                onPressed: () => _shareIosDiagnosticsReport(
                                  report,
                                  shareButtonContext,
                                ),
                                child: Icon(
                                  CupertinoIcons.share,
                                  color: _TelephonyVisualColors.blue,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.appColors.surfaceElevated
                                    .withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE3E8F4),
                                ),
                              ),
                              child: SelectableText(
                                report,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: context.appColors.textPrimary,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                color: const Color(0xFF0A84FF),
                                borderRadius: BorderRadius.circular(14),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: report),
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                  _showSipSnackBar('Диагностика скопирована');
                                },
                                child: const Text('Копировать'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CupertinoButton(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(14),
                                onPressed: () async {
                                  await _sipRuntime.clearNativeDiagnosticLogs();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                  _showSipSnackBar('Диагностика очищена');
                                },
                                child: const Text('Очистить'),
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
          ),
        );
      },
    );
  }

  Future<void> _shareIosDiagnosticsReport(
    String report,
    BuildContext shareButtonContext,
  ) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toLocal()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${directory.path}/sip_diagnostics_$timestamp.md');
      await file.writeAsString(report, flush: true);

      final renderObject = shareButtonContext.findRenderObject();
      final viewSize = MediaQuery.sizeOf(shareButtonContext);
      final shareOrigin = renderObject is RenderBox && renderObject.hasSize
          ? renderObject.localToGlobal(Offset.zero) & renderObject.size
          : Rect.fromLTWH(
              math.max(1, viewSize.width - 48),
              12,
              40,
              40,
            );

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/markdown')],
        subject: 'Диагностика телефонии iOS',
        text: 'Диагностика телефонии iOS',
        sharePositionOrigin: shareOrigin,
      );
    } catch (error) {
      _showSipSnackBar(
        'Не удалось поделиться диагностикой: $error',
        isError: true,
      );
    }
  }

  String _buildOutboundNumberDiagnosticsReport(Map<String, dynamic> diagnostics) {
    final state =
        Map<String, dynamic>.from(diagnostics['state'] as Map? ?? const {});
    final storage =
        Map<String, dynamic>.from(diagnostics['storage'] as Map? ?? const {});
    final nativeSnapshot = Map<String, dynamic>.from(
      diagnostics['nativeSnapshot'] as Map? ?? const {},
    );
    final nativeConfig = Map<String, dynamic>.from(
      diagnostics['nativeConfig'] as Map? ?? const {},
    );
    final outgoingCalls = (diagnostics['outgoingCalls'] as List? ?? const [])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
    final allCalls = (diagnostics['allCalls'] as List? ?? const [])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
    final outgoingError = diagnostics['outgoingError']?.toString();
    final allCallsError = diagnostics['allCallsError']?.toString();

    String formatCallEntries(String title, List<Map<String, dynamic>> entries) {
      if (entries.isEmpty) return '$title: empty';
      final lines = <String>['$title:'];
      for (final entry in entries) {
        lines.add(
          '- id=${entry['id']}, type=${entry['type']}, trunk=${entry['trunk']}, caller=${entry['caller']}, destination=${entry['destinationNumber']}, candidate=${entry['candidate']}',
        );
      }
      return lines.join('\n');
    }

    final lines = <String>[
      'State: server=${state['server'] ?? ''}, login=${state['login'] ?? ''}, outbound=${state['outboundNumber'] ?? ''}, registration=${state['registrationStatus'] ?? ''}',
      'Storage: server=${storage['server'] ?? ''}, login=${storage['login'] ?? ''}, outbound=${storage['outboundNumber'] ?? ''}',
      'Native snapshot: registration=${nativeSnapshot['registrationState'] ?? ''}, call=${nativeSnapshot['callState'] ?? ''}, remote=${nativeSnapshot['remoteIdentity'] ?? ''}, message=${nativeSnapshot['message'] ?? ''}',
      'Native config: server=${nativeConfig['server'] ?? ''}, login=${nativeConfig['login'] ?? ''}, authUser=${nativeConfig['authUser'] ?? ''}, transport=${nativeConfig['transport'] ?? ''}, port=${nativeConfig['port'] ?? ''}',
      if (outgoingError != null && outgoingError.trim().isNotEmpty)
        'Outgoing API error: $outgoingError',
      formatCallEntries('Outgoing calls', outgoingCalls),
      if (allCallsError != null && allCallsError.trim().isNotEmpty)
        'All calls API error: $allCallsError',
      formatCallEntries('All calls', allCalls),
    ];

    return lines.join('\n');
  }

  Widget _transportSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.fieldBorder),
      ),
      child: CupertinoSlidingSegmentedControl<SipTransportUi>(
        groupValue: _selectedTransport,
        backgroundColor: colors.fieldBg,
        thumbColor: colors.surfaceElevated,
        children: <SipTransportUi, Widget>{
          SipTransportUi.ws: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              l10n.translate('sip_transport_ws'),
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
          SipTransportUi.udp: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text('UDP', style: TextStyle(color: colors.textPrimary)),
          ),
          SipTransportUi.tcp: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              l10n.translate('sip_transport_tcp'),
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
        },
        onValueChanged: (value) {
          if (value == null) return;
          _updateView(() {
            _selectedTransport = value;
            if (_portController.text.trim().isEmpty) {
              _portController.text =
                  value == SipTransportUi.ws ? '7443' : '5060';
            }
          });
          _handleDraftChanged();
        },
      ),
    );
  }
}
