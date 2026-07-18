// Этот файл отвечает за модальное окно SIP-настроек и поля подключения.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipSettingsSheetExtension on _SipScreenState {
  Future<void> _showSettingsSheet() async {
    final l10n = AppLocalizations.of(context)!;
    var passwordVisible = false;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final state = _sipRuntime.state;
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FC),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(28)),
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
                              Text(
                                l10n.translate('sip_settings'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
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
                                      color: const Color(0xFF7A8499),
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
                                    color: const Color(0xFFE9F2FF),
                                    borderRadius: BorderRadius.circular(14),
                                    onPressed: () async {
                                      await _showIosDiagnosticsSheet(context);
                                    },
                                    child: const Text(
                                      'SIP Диагностика',
                                      style: TextStyle(
                                        color: Color(0xFF0A84FF),
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
                                      color: const Color(0xFF0A84FF),
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
                                                ? 'Подключение...'
                                                : l10n.translate('sip_connect'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CupertinoButton(
                                      color: const Color(0xFFFF3B30),
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
  }

  Widget _iosField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return CupertinoTextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      suffix: suffix,
      suffixMode: OverlayVisibilityMode.always,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      placeholder: placeholder,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F4)),
      ),
    );
  }

  Future<void> _showIosDiagnosticsSheet(BuildContext context) async {
    final isAndroid = Platform.isAndroid;
    final voipToken = isAndroid ? null : await _sipRuntime.getVoipPushToken();
    final logs = await _sipRuntime.getNativeDiagnosticLogs();
    final backendSync = isAndroid
        ? const <String, dynamic>{}
        : await _apiService.getVoipSyncDiagnostics();

    final tokenText = (voipToken == null || voipToken.trim().isEmpty)
        ? 'VoIP token: MISSING'
        : 'VoIP token: ${voipToken.trim()}';
    final registrationText =
        'Registration: ${_sipRuntime.state.registrationStatus.name}';
    final callText = 'Call: ${_sipRuntime.state.callStatus.name}';
    final syncedAtMillis = backendSync['syncedAt'] as int?;
    final syncedAt = syncedAtMillis == null
        ? 'unknown'
        : DateTime.fromMillisecondsSinceEpoch(syncedAtMillis)
            .toLocal()
            .toIso8601String();
    final backendText =
        'Backend sync: status=${backendSync['status']}, http=${backendSync['httpCode'] ?? 'n/a'}, pending=${backendSync['hasPendingToken']}, at=$syncedAt';
    final backendError = backendSync['error']?.toString();

    final visibleLogs = logs.reversed.toList(growable: false);
    final logLines = visibleLogs.isEmpty
        ? <String>['Native logs: empty']
        : visibleLogs.map((entry) {
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
          }).toList(growable: false);

    final report = [
      '${Platform.isAndroid ? 'Android' : 'iOS'} SIP Diagnostics',
      registrationText,
      callText,
      if (!isAndroid) tokenText,
      if (!isAndroid) backendText,
      if (!isAndroid && backendError != null && backendError.trim().isNotEmpty)
        'Backend error: $backendError',
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FC),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 0,
                                child: Container(
                                  width: 46,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD5DAE8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const Positioned(
                                left: 48,
                                right: 48,
                                bottom: 3,
                                child: Text(
                                  'SIP Диагностика',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Builder(
                                  builder: (shareButtonContext) {
                                    return Tooltip(
                                      message: 'Поделиться диагностикой',
                                      child: CupertinoButton(
                                        minimumSize: const Size.square(40),
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          await _shareIosDiagnosticsReport(
                                            report,
                                            shareButtonContext,
                                          );
                                        },
                                        child: const Icon(
                                          CupertinoIcons.share,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE3E8F4),
                                ),
                              ),
                              child: SelectableText(
                                report,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: Color(0xFF1F2937),
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
                                color: const Color(0xFFE9F2FF),
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
                                child: const Text(
                                  'Копировать',
                                  style: TextStyle(
                                    color: Color(0xFF0A84FF),
                                  ),
                                ),
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
        subject: 'iOS SIP Diagnostics',
        text: 'iOS SIP Diagnostics',
        sharePositionOrigin: shareOrigin,
      );
    } catch (error) {
      _showSipSnackBar(
        'Не удалось поделиться диагностикой: $error',
        isError: true,
      );
    }
  }

  Widget _transportSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8F4)),
      ),
      child: CupertinoSlidingSegmentedControl<SipTransportUi>(
        groupValue: _selectedTransport,
        children: <SipTransportUi, Widget>{
          SipTransportUi.ws: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(l10n.translate('sip_transport_ws')),
          ),
          SipTransportUi.udp: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text('UDP'),
          ),
          SipTransportUi.tcp: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(l10n.translate('sip_transport_tcp')),
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
