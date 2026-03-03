import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:math' as math;

import 'sip_service.dart';
import 'sip_state.dart';

class SipScreen extends StatefulWidget {
  const SipScreen({super.key});

  @override
  State<SipScreen> createState() => _SipScreenState();
}

class _SipScreenState extends State<SipScreen> {
  static final SipService _sipService = SipService();

  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _sipIdController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  SipTransportUi _selectedTransport = SipTransportUi.ws;

  int _bottomTabIndex = 0;

  static const List<Map<String, String>> _dialPadItems = [
    {'key': '1', 'letters': ''},
    {'key': '2', 'letters': 'ABC'},
    {'key': '3', 'letters': 'DEF'},
    {'key': '4', 'letters': 'GHI'},
    {'key': '5', 'letters': 'JKL'},
    {'key': '6', 'letters': 'MNO'},
    {'key': '7', 'letters': 'PQRS'},
    {'key': '8', 'letters': 'TUV'},
    {'key': '9', 'letters': 'WXYZ'},
    {'key': '*', 'letters': ''},
    {'key': '0', 'letters': '+'},
    {'key': '#', 'letters': ''},
  ];

  @override
  void initState() {
    super.initState();
    _initializeSip();
  }

  Future<void> _initializeSip() async {
    await _sipService.initialize();
    final state = _sipService.state;

    _serverController.text = state.server;
    _loginController.text = state.login;
    _passwordController.text = state.password;
    _sipIdController.text = state.sipId;
    _portController.text = state.port.toString();
    _selectedTransport = state.transport;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _sipIdController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    final parsedPort = int.tryParse(_portController.text.trim()) ??
        (_selectedTransport == SipTransportUi.ws ? 7443 : 5060);
    await _sipService.saveDraft(
      server: _serverController.text,
      login: _loginController.text,
      password: _passwordController.text,
      sipId: _sipIdController.text,
      transport: _selectedTransport,
      port: parsedPort,
    );
  }

  bool _hasCredentials(SipUiState state) {
    return state.server.trim().isNotEmpty &&
        state.login.trim().isNotEmpty &&
        state.password.trim().isNotEmpty;
  }

  void _appendDial(String value) {
    _sipIdController.text = '${_sipIdController.text}$value';
    setState(() {});
  }

  void _backspaceDial() {
    if (_sipIdController.text.isEmpty) return;
    _sipIdController.text =
        _sipIdController.text.substring(0, _sipIdController.text.length - 1);
    setState(() {});
  }

  void _clearDial() {
    if (_sipIdController.text.isEmpty) return;
    _sipIdController.clear();
    setState(() {});
  }

  Future<void> _copyDial() async {
    final text = _sipIdController.text.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _pasteDial() async {
    final data = await Clipboard.getData('text/plain');
    final source = (data?.text ?? '').trim();
    if (source.isEmpty) return;
    final normalized = source.replaceAll(RegExp(r'[^0-9+*#]'), '');
    _sipIdController.text = normalized.isEmpty ? source : normalized;
    setState(() {});
  }

  Future<void> _showDialActions() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await _copyDial();
            },
            child: const Text('Копировать'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await _pasteDial();
            },
            child: const Text('Вставить'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _clearDial();
            },
            child: const Text('Очистить'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  Future<void> _startDialCall() async {
    await _saveDraft();
    await _sipService.makeCall();
  }

  String _callLabel(BuildContext context, SipCallUiStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case SipCallUiStatus.idle:
        return l10n.translate('sip_call_idle');
      case SipCallUiStatus.incoming:
        return l10n.translate('sip_call_incoming');
      case SipCallUiStatus.calling:
        return l10n.translate('sip_call_calling');
      case SipCallUiStatus.ringing:
        return l10n.translate('sip_call_ringing');
      case SipCallUiStatus.inCall:
        return l10n.translate('sip_call_in_call');
      case SipCallUiStatus.ended:
        return l10n.translate('sip_call_ended');
      case SipCallUiStatus.failed:
        return l10n.translate('sip_call_failed');
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _showSettingsSheet() async {
    final l10n = AppLocalizations.of(context)!;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SafeArea(
                top: false,
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFF0A84FF),
                            borderRadius: BorderRadius.circular(14),
                            onPressed: () async {
                              await _saveDraft();
                              await _sipService.connect();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(l10n.translate('sip_connect')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(14),
                            onPressed: () async {
                              await _sipService.disconnect();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(l10n.translate('sip_disconnect')),
                          ),
                        ),
                      ],
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

  Widget _iosField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CupertinoTextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      placeholder: placeholder,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F4)),
      ),
    );
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
          setState(() {
            _selectedTransport = value;
            if (_portController.text.trim().isEmpty) {
              _portController.text =
                  value == SipTransportUi.ws ? '7443' : '5060';
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sipService,
      builder: (context, child) {
        final state = _sipService.state;
        final isRegistered =
            state.registrationStatus == SipRegistrationUiStatus.registered;

        if (!_hasCredentials(state) || !isRegistered) {
          return _buildAuthorizationView(context, state);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FD),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEFF4FF), Color(0xFFF8FAFF)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      _buildTopBar(context, state),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _statusBanner(context, state),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _bottomTabIndex == 0
                              ? _dialPadView(context, state)
                              : _journalView(context, state),
                        ),
                      ),
                      _bottomSwitcher(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.translate('appbar_sip'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _showSettingsSheet,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B1736).withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.gear_alt_fill,
                size: 20,
                color: Color(0xFF1F2937),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAuthorizationView(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;
    final isRegistering =
        state.registrationStatus == SipRegistrationUiStatus.registering;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE5EEFF), Color(0xFFF8FAFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF17A1C9), Color(0xFF0A6AB8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0A6AB8).withValues(alpha: 0.24),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                CupertinoIcons.phone_circle_fill,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF102350).withValues(alpha: 0.08),
                          blurRadius: 18,
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: const Color(0xFF0A84FF),
                            borderRadius: BorderRadius.circular(15),
                            onPressed: isRegistering
                                ? null
                                : () async {
                                    await _saveDraft();
                                    await _sipService.connect();
                                  },
                            child: Text(
                              isRegistering
                                  ? l10n.translate('sip_status_registering')
                                  : l10n.translate('sip_enter_dialer'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
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
                                color: Color(0xFFDC2626),
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

    final Color toneColor;
    if (state.callStatus == SipCallUiStatus.incoming) {
      toneColor = const Color(0xFFF59E0B);
    } else if (state.callStatus == SipCallUiStatus.inCall) {
      toneColor = const Color(0xFF10B981);
    } else if (state.callStatus == SipCallUiStatus.failed) {
      toneColor = const Color(0xFFEF4444);
    } else {
      toneColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: toneColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l10n.translate('sip_call_state')}: ${_callLabel(context, state.callStatus)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          if (state.callStatus == SipCallUiStatus.incoming)
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _sipService.acceptCall,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.translate('sip_accept'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _sipService.decline,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.translate('sip_decline'),
                      style: const TextStyle(color: Colors.white),
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
        const horizontalPadding = 8.0;
        final spacing = constraints.maxWidth < 380 ? 10.0 : 16.0;
        final widthBased =
            ((constraints.maxWidth - horizontalPadding * 2 - spacing * 2) / 3)
                .clamp(62.0, 102.0);
        final keypadHeight = (constraints.maxHeight * 0.58).clamp(260.0, 420.0);
        final heightBased =
            ((keypadHeight - spacing * 3) / 4).clamp(62.0, 102.0);
        final buttonSize = math.min(widthBased, heightBased);
        final numberFont = (buttonSize * 0.46).clamp(28.0, 40.0);
        final lettersFont = (buttonSize * 0.13).clamp(10.0, 13.0);
        final callButtonSize = (buttonSize * 0.84).clamp(62.0, 78.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onLongPress: _showDialActions,
                      child: SelectableText(
                        _sipIdController.text.isEmpty
                            ? ' '
                            : _sipIdController.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: constraints.maxWidth < 380 ? 30 : 36,
                          height: 1,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.8,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: buttonSize * 4 + spacing * 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (row) {
                    final start = row * 3;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (col) {
                        final item = _dialPadItems[start + col];
                        final key = item['key']!;
                        return Padding(
                          padding: EdgeInsets.only(
                            right: col == 2 ? 0 : spacing,
                          ),
                          child: _dialButton(
                            value: key,
                            letters: item['letters']!,
                            size: buttonSize,
                            numberFontSize: numberFont,
                            lettersFontSize: lettersFont,
                            onTap: () => _appendDial(key),
                            onLongPress:
                                key == '0' ? () => _appendDial('+') : null,
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: callButtonSize * 0.75),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _startDialCall,
                    child: Container(
                      width: callButtonSize,
                      height: callButtonSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF22C55E).withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.phone_fill,
                        color: Colors.white,
                        size: (callButtonSize * 0.38).clamp(24.0, 30.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: _backspaceDial,
                    onLongPress: _clearDial,
                    child: Container(
                      width: (callButtonSize * 0.58).clamp(40.0, 46.0),
                      height: (callButtonSize * 0.58).clamp(40.0, 46.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7ECF7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.delete_left,
                        color: Color(0xFF111827),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (state.callStatus == SipCallUiStatus.inCall ||
                  state.callStatus == SipCallUiStatus.ringing ||
                  state.callStatus == SipCallUiStatus.calling)
                _inCallActions(context, state),
              if (state.callStatus == SipCallUiStatus.inCall)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _videoPreview(context),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialButton({
    required String value,
    required String letters,
    required double size,
    required double numberFontSize,
    required double lettersFontSize,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8EA0BF).withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: numberFontSize,
                height: 1,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF0B1220),
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: TextStyle(
                  fontSize: lettersFontSize,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inCallActions(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _sipService.toggleMute,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.isMuted
                    ? l10n.translate('sip_unmute')
                    : l10n.translate('sip_mute'),
                style: const TextStyle(color: Color(0xFF0F172A)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _sipService.toggleSpeaker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.isSpeakerOn
                    ? l10n.translate('sip_speaker_off')
                    : l10n.translate('sip_speaker_on'),
                style: const TextStyle(color: Color(0xFF0F172A)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _sipService.hangup,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.translate('sip_hangup'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoPreview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: _sipService.renderersReady &&
                    _sipService.remoteRenderer.srcObject != null
                ? RTCVideoView(
                    _sipService.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Center(
                    child: Text(
                      l10n.translate('sip_no_remote_video'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            width: 76,
            height: 102,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black54,
              ),
              child: _sipService.renderersReady &&
                      _sipService.localRenderer.srcObject != null
                  ? RTCVideoView(
                      _sipService.localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
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
              color: Color(0xFF64748B),
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
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1220).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isFailed
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncoming
                    ? CupertinoIcons.arrow_down_left
                    : CupertinoIcons.arrow_up_right,
                color: isFailed
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF2563EB),
                size: 20,
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
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              _formatTime(item.timestamp),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomSwitcher(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1736).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _switchItem(
                icon: CupertinoIcons.circle_grid_3x3_fill,
                label: l10n.translate('sip_tab_keypad'),
                selected: _bottomTabIndex == 0,
                onTap: () => setState(() => _bottomTabIndex = 0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _switchItem(
                icon: CupertinoIcons.clock_fill,
                label: l10n.translate('sip_tab_journal'),
                selected: _bottomTabIndex == 1,
                onTap: () => setState(() => _bottomTabIndex = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9F2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  selected ? const Color(0xFF0A84FF) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF0A84FF)
                    : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
