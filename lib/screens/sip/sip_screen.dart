import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sip_service.dart';
import 'sip_state.dart';

abstract class _G {
  static const activeBg = [
    Color(0xFF080C18),
    Color(0xFF0D1730),
    Color(0xFF0A1A2E),
  ];

  static const glassFill = Color(0x18FFFFFF);
  static const glassBorder = Color(0x30FFFFFF);

  static const accent = Color(0xFF3D8EFF);
  static const green = Color(0xFF34C759);
  static const red = Color(0xFFFF3B30);
  static const amber = Color(0xFFFFCC00);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xAAFFFFFF);
  static const textTertiary = Color(0x66FFFFFF);

  static const lightBg = Color(0xFFF2F6FF);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF0F172A);
  static const lightSubtext = Color(0xFF64748B);
  static const lightAccent = Color(0xFF0A84FF);
  static const lightGreen = Color(0xFF25A344);
}

class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.child,
    this.padding,
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _G.glassFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: _G.glassBorder, width: 0.8),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.child,
    required this.onPressed,
    this.borderRadius = 20,
    this.padding,
  });

  final Widget child;
  final VoidCallback onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _G.glassFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: _G.glassBorder, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SipScreen extends StatefulWidget {
  const SipScreen({super.key});

  @override
  State<SipScreen> createState() => _SipScreenState();
}

class _SipScreenState extends State<SipScreen>
    with SingleTickerProviderStateMixin {
  static final SipService _sipService = SipService();

  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _sipIdController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final FocusNode _dialFocusNode = FocusNode();
  final AudioPlayer _callFeedbackPlayer = AudioPlayer();

  SipTransportUi _selectedTransport = SipTransportUi.ws;

  int _bottomTabIndex = 0;
  late final AnimationController _pulseController;
  Timer? _callDurationTimer;
  SipCallUiStatus? _lastObservedCallStatus;
  String? _activeFeedbackAsset;
  DateTime? _connectedAt;
  Duration _connectedDuration = Duration.zero;
  bool _contactsEnabled = false;
  bool _contactsLoaded = false;
  bool _contactsPermissionDenied = false;
  List<Contact> _contacts = const [];
  List<_SipIndexedContact> _indexedContacts = const [];
  List<_SipContactSuggestion> _contactSuggestions = const [];
  bool _showInCallKeypad = false;
  String _inCallDigits = '';
  double _incomingAnswerDrag = 0;
  Timer? _contactSearchDebounce;
  Timer? _draftSaveDebounce;
  bool _suspendDraftAutosave = false;

  static const List<Map<String, String>> _dialPadItems = [
    {'key': '1', 'letters': ''},
    {'key': '2', 'letters': 'АБВГ'},
    {'key': '3', 'letters': 'ДЕЁЖ'},
    {'key': '4', 'letters': 'ЗИЙК'},
    {'key': '5', 'letters': 'ЛМНО'},
    {'key': '6', 'letters': 'ПРСТ'},
    {'key': '7', 'letters': 'УФХЦ'},
    {'key': '8', 'letters': 'ЧШЩЪ'},
    {'key': '9', 'letters': 'ЫЬЭЮЯ'},
    {'key': '*', 'letters': ''},
    {'key': '0', 'letters': '+'},
    {'key': '#', 'letters': ''},
  ];

  @override
  void initState() {
    super.initState();
    _sipService.setSipScreenVisible(true);
    _serverController.addListener(_handleDraftChanged);
    _loginController.addListener(_handleDraftChanged);
    _passwordController.addListener(_handleDraftChanged);
    _portController.addListener(_handleDraftChanged);
    _sipIdController.addListener(_handleDialChanged);
    _sipIdController.addListener(_handleDraftChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _configureCallFeedbackPlayer();
    _initializeSip();
  }

  Future<void> _configureCallFeedbackPlayer() async {
    try {
      await _callFeedbackPlayer.setReleaseMode(ReleaseMode.loop);
      await _callFeedbackPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _callFeedbackPlayer.setVolume(1);
    } catch (_) {}
  }

  Future<void> _initializeSip() async {
    await _sipService.initialize();
    await _sipService.prepareSipRuntimePermissions();
    await _loadContactsConfiguration();
    final state = _sipService.state;

    _suspendDraftAutosave = true;
    _serverController.text = state.server;
    _loginController.text = state.login;
    _passwordController.text = state.password;
    _sipIdController.text = state.sipId;
    _portController.text = state.port.toString();
    _selectedTransport = state.transport;
    _suspendDraftAutosave = false;

    if (mounted) {
      _refreshContactSuggestions();
      setState(() {});
    }
  }

  Future<void> _loadContactsConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _contactsEnabled = prefs.getBool('switchContact') ?? false;
    if (_contactsEnabled) {
      await _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    if (_contactsLoaded || !_contactsEnabled) return;

    try {
      final granted = await FlutterContacts.requestPermission();
      if (!granted) {
        _contactsPermissionDenied = true;
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      _contacts = contacts
          .where((contact) =>
              contact.displayName.trim().isNotEmpty &&
              contact.phones.isNotEmpty)
          .toList(growable: false);
      _indexedContacts = _contacts.expand((contact) {
        final lowerName = contact.displayName.toLowerCase();
        final t9Name = _nameToT9Digits(lowerName);
        return contact.phones.map(
          (phone) => _SipIndexedContact(
            name: contact.displayName,
            lowerName: lowerName,
            t9Name: t9Name,
            phone: phone.number,
            normalizedPhone: _digitsOnly(phone.number),
            photo: contact.photo,
          ),
        );
      }).toList(growable: false);
      _contactsLoaded = true;
      _contactsPermissionDenied = false;
      _refreshContactSuggestions();
    } catch (_) {
      _contactsPermissionDenied = true;
    }
  }

  @override
  void dispose() {
    _sipService.setSipScreenVisible(false);
    _callDurationTimer?.cancel();
    _contactSearchDebounce?.cancel();
    _draftSaveDebounce?.cancel();
    _pulseController.dispose();
    unawaited(_callFeedbackPlayer.stop());
    _callFeedbackPlayer.dispose();
    _sipIdController.removeListener(_handleDialChanged);
    _serverController.removeListener(_handleDraftChanged);
    _loginController.removeListener(_handleDraftChanged);
    _passwordController.removeListener(_handleDraftChanged);
    _portController.removeListener(_handleDraftChanged);
    _sipIdController.removeListener(_handleDraftChanged);
    _serverController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _sipIdController.dispose();
    _portController.dispose();
    _dialFocusNode.dispose();
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

  void _handleDraftChanged() {
    if (_suspendDraftAutosave) return;
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 250), () async {
      final parsedPort = int.tryParse(_portController.text.trim()) ??
          (_selectedTransport == SipTransportUi.ws ? 7443 : 5060);
      await _sipService.saveDraft(
        server: _serverController.text,
        login: _loginController.text,
        password: _passwordController.text,
        sipId: _sipIdController.text,
        transport: _selectedTransport,
        port: parsedPort,
        notifyUi: false,
      );
    });
  }

  bool _hasCredentials(SipUiState state) {
    return state.server.trim().isNotEmpty &&
        state.login.trim().isNotEmpty &&
        state.password.trim().isNotEmpty;
  }

  void _handleDialChanged() {
    if (!mounted) return;
    _contactSearchDebounce?.cancel();
    _contactSearchDebounce = Timer(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      _refreshContactSuggestions();
      setState(() {});
    });
  }

  void _insertDialText(String value) {
    final currentValue = _sipIdController.value;
    final selection = currentValue.selection;
    final start =
        selection.isValid ? selection.start : currentValue.text.length;
    final end = selection.isValid ? selection.end : currentValue.text.length;
    final safeStart = start < 0 ? currentValue.text.length : start;
    final safeEnd = end < 0 ? currentValue.text.length : end;
    final newText = currentValue.text.replaceRange(safeStart, safeEnd, value);
    _sipIdController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: safeStart + value.length),
    );
    _dialFocusNode.requestFocus();
  }

  void _backspaceDial() {
    final currentValue = _sipIdController.value;
    final text = currentValue.text;
    final selection = currentValue.selection;
    if (text.isEmpty) return;

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    if (start != end && start >= 0 && end >= 0) {
      final newText = text.replaceRange(start, end, '');
      _sipIdController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
      _dialFocusNode.requestFocus();
      return;
    }

    if (start <= 0) return;
    final newText = text.replaceRange(start - 1, start, '');
    _sipIdController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start - 1),
    );
    _dialFocusNode.requestFocus();
  }

  void _clearDial() {
    if (_sipIdController.text.isEmpty) return;
    _sipIdController.clear();
    _dialFocusNode.requestFocus();
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
    _insertDialText(normalized.isEmpty ? source : normalized);
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

  Future<void> _fillAndCallContact(_SipContactSuggestion suggestion) async {
    _sipIdController.value = TextEditingValue(
      text: suggestion.phone,
      selection: TextSelection.collapsed(offset: suggestion.phone.length),
    );
    await _saveDraft();
    await _sipService.makeCall();
  }

  void _fillContactNumber(_SipContactSuggestion suggestion) {
    _sipIdController.value = TextEditingValue(
      text: suggestion.phone,
      selection: TextSelection.collapsed(offset: suggestion.phone.length),
    );
    _dialFocusNode.requestFocus();
  }

  String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _nameToT9Digits(String input) {
    const map = <String, String>{
      'a': '2',
      'b': '2',
      'c': '2',
      'd': '3',
      'e': '3',
      'f': '3',
      'g': '4',
      'h': '4',
      'i': '4',
      'j': '5',
      'k': '5',
      'l': '5',
      'm': '6',
      'n': '6',
      'o': '6',
      'p': '7',
      'q': '7',
      'r': '7',
      's': '7',
      't': '8',
      'u': '8',
      'v': '8',
      'w': '9',
      'x': '9',
      'y': '9',
      'z': '9',
      'а': '2',
      'б': '2',
      'в': '2',
      'г': '2',
      'д': '3',
      'е': '3',
      'ё': '3',
      'ж': '3',
      'з': '3',
      'и': '4',
      'й': '4',
      'к': '4',
      'л': '4',
      'м': '5',
      'н': '5',
      'о': '5',
      'п': '5',
      'р': '6',
      'с': '6',
      'т': '6',
      'у': '6',
      'ф': '7',
      'х': '7',
      'ц': '7',
      'ч': '7',
      'ш': '8',
      'щ': '8',
      'ъ': '8',
      'ы': '8',
      'ь': '9',
      'э': '9',
      'ю': '9',
      'я': '9',
    };

    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final digit = map[char];
      if (digit != null) {
        buffer.write(digit);
      }
    }
    return buffer.toString();
  }

  void _refreshContactSuggestions() {
    if (!_contactsEnabled || !_contactsLoaded) {
      _contactSuggestions = const [];
      return;
    }

    final rawQuery = _sipIdController.text.trim();
    final queryDigits = _digitsOnly(rawQuery);
    if (rawQuery.isEmpty) {
      _contactSuggestions = const [];
      return;
    }

    final suggestions = <_SipContactSuggestion>[];
    final loweredQuery = rawQuery.toLowerCase();
    for (final contact in _indexedContacts) {
      final matches = contact.lowerName.contains(loweredQuery) ||
          (queryDigits.isNotEmpty &&
              (contact.normalizedPhone.contains(queryDigits) ||
                  contact.t9Name.contains(queryDigits)));

      if (!matches) continue;

      suggestions.add(
        _SipContactSuggestion(
          name: contact.name,
          phone: contact.phone,
          normalizedPhone: contact.normalizedPhone,
          photo: contact.photo,
        ),
      );
    }

    suggestions.sort((a, b) {
      final query = queryDigits;
      final aStarts = query.isNotEmpty && a.normalizedPhone.startsWith(query);
      final bStarts = query.isNotEmpty && b.normalizedPhone.startsWith(query);
      if (aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    final unique = <String>{};
    _contactSuggestions = suggestions
        .where((item) {
          final key = '${item.name}|${item.normalizedPhone}';
          return unique.add(key);
        })
        .take(6)
        .toList(growable: false);
  }

  List<_SipContactSuggestion> _recommendedContacts() {
    if (!_contactsEnabled || !_contactsLoaded) {
      return const [];
    }

    if (_contactSuggestions.isNotEmpty) {
      return _contactSuggestions.take(4).toList(growable: false);
    }

    final seen = <String>{};
    final suggestions = <_SipContactSuggestion>[];
    for (final contact in _indexedContacts) {
      final key = '${contact.name}|${contact.normalizedPhone}';
      if (!seen.add(key)) continue;
      suggestions.add(
        _SipContactSuggestion(
          name: contact.name,
          phone: contact.phone,
          normalizedPhone: contact.normalizedPhone,
          photo: contact.photo,
        ),
      );
      if (suggestions.length == 4) break;
    }
    return suggestions;
  }

  Future<void> _showContactsSheet() async {
    if (!_contactsEnabled) return;
    await _loadContacts();
    if (!mounted) return;

    final contacts = _contacts
        .map((contact) => _SipContactSuggestion(
              name: contact.displayName,
              phone: contact.phones.first.number,
              normalizedPhone: _digitsOnly(contact.phones.first.number),
              photo: contact.photo,
            ))
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var filtered = contacts;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.78,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5DAE8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Контакты',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: CupertinoSearchTextField(
                        onChanged: (value) {
                          final query = value.trim().toLowerCase();
                          final queryDigits = _digitsOnly(value);
                          setModalState(() {
                            if (query.isEmpty) {
                              filtered = contacts;
                            } else {
                              filtered = contacts.where((contact) {
                                return contact.name
                                        .toLowerCase()
                                        .contains(query) ||
                                    contact.normalizedPhone
                                        .contains(queryDigits) ||
                                    _nameToT9Digits(contact.name)
                                        .contains(queryDigits);
                              }).toList(growable: false);
                            }
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
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final contact = filtered[index];
                                return _contactTile(
                                  suggestion: contact,
                                  onTap: () {
                                    _fillContactNumber(contact);
                                    Navigator.of(context).pop();
                                  },
                                  onCallTap: () async {
                                    Navigator.of(context).pop();
                                    await _fillAndCallContact(contact);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _syncCallEffects(SipUiState state) {
    final status = state.callStatus;
    if (_lastObservedCallStatus == status) return;

    _lastObservedCallStatus = status;

    switch (status) {
      case SipCallUiStatus.incoming:
        _stopCallDurationTicker();
        unawaited(_playFeedbackLoop('audio/get.mp3'));
        break;
      case SipCallUiStatus.calling:
      case SipCallUiStatus.ringing:
        _stopCallDurationTicker();
        unawaited(_playFeedbackLoop('audio/send.mp3'));
        break;
      case SipCallUiStatus.inCall:
        _startCallDurationTicker();
        unawaited(_stopFeedbackLoop());
        break;
      case SipCallUiStatus.idle:
      case SipCallUiStatus.ended:
      case SipCallUiStatus.failed:
        _stopCallDurationTicker(reset: true);
        unawaited(_stopFeedbackLoop());
        break;
    }
  }

  Future<void> _playFeedbackLoop(String assetPath) async {
    if (_activeFeedbackAsset == assetPath) return;
    _activeFeedbackAsset = assetPath;

    try {
      await _callFeedbackPlayer.stop();
      await _callFeedbackPlayer.setReleaseMode(ReleaseMode.loop);
      await _callFeedbackPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> _stopFeedbackLoop() async {
    _activeFeedbackAsset = null;
    try {
      await _callFeedbackPlayer.stop();
    } catch (_) {}
  }

  void _startCallDurationTicker() {
    _connectedAt ??= DateTime.now();
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final connectedAt = _connectedAt;
      if (!mounted || connectedAt == null) return;
      setState(() {
        _connectedDuration = DateTime.now().difference(connectedAt);
      });
    });
  }

  void _stopCallDurationTicker({bool reset = false}) {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;

    if (reset) {
      _connectedAt = null;
      _connectedDuration = Duration.zero;
    }
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

  bool _isActiveCallState(SipCallUiStatus status) {
    return status == SipCallUiStatus.incoming ||
        status == SipCallUiStatus.calling ||
        status == SipCallUiStatus.ringing ||
        status == SipCallUiStatus.inCall;
  }

  String _displayIdentity(SipUiState state) {
    final raw = (state.remoteIdentity?.trim().isNotEmpty == true
            ? state.remoteIdentity!.trim()
            : _sipIdController.text.trim())
        .trim();

    if (raw.isEmpty) return 'Неизвестно';

    var value = raw;
    if (value.startsWith('sip:')) {
      value = value.substring(4);
    }
    if (value.contains('@')) {
      value = value.split('@').first;
    }
    return value;
  }

  String _callHint(SipCallUiStatus status) {
    switch (status) {
      case SipCallUiStatus.incoming:
        return 'Входящий вызов. Звучит сигнал вызова.';
      case SipCallUiStatus.calling:
        return 'Исходящий вызов. Включен сигнал ожидания ответа.';
      case SipCallUiStatus.ringing:
        return 'Абонент уведомлен. Ожидаем ответ.';
      case SipCallUiStatus.inCall:
        return 'Соединение активно.';
      case SipCallUiStatus.failed:
        return 'Не удалось завершить вызов успешно.';
      case SipCallUiStatus.ended:
        return 'Вызов завершен.';
      case SipCallUiStatus.idle:
        return 'Готов к новому вызову.';
    }
  }

  Future<void> _showSettingsSheet() async {
    final l10n = AppLocalizations.of(context)!;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return Material(
          color: Colors.transparent,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: Align(
              alignment: Alignment.bottomCenter,
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
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      unawaited(_sipService.connect());
                                    });
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
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      unawaited(_sipService.disconnect());
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
          _handleDraftChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sipService,
      builder: (context, child) {
        if (!_sipService.isConfigLoaded) {
          return const Scaffold(
            backgroundColor: _G.lightBg,
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final state = _sipService.state;
        final isActiveCall = _isActiveCallState(state.callStatus);

        _syncCallEffects(state);

        if (!_hasCredentials(state)) {
          return _buildAuthorizationView(context, state);
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: _G.lightBg,
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
                  child: isActiveCall
                      ? _activeCallView(context, state)
                      : Column(
                          children: [
                            _buildTopBar(context, state),
                            if (state.registrationStatus ==
                                    SipRegistrationUiStatus.registered ||
                                state.callStatus == SipCallUiStatus.incoming ||
                                state.registrationStatus ==
                                    SipRegistrationUiStatus.failed)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _statusBanner(context, state),
                              ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _bottomTabIndex == 0
                                    ? _dialPadView(context, state)
                                    : _journalView(context, state),
                              ),
                            ),
                            if (_bottomTabIndex != 0) _bottomSwitcher(context),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(children: [
        _buildTopIconButton(
          icon: CupertinoIcons.back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Телефония',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _G.lightText,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              state.registrationStatus == SipRegistrationUiStatus.registered
                  ? 'Линия активна и готова к входящим'
                  : 'Подключите линию для звонков в фоне',
              style: const TextStyle(
                fontSize: 13,
                color: _G.lightSubtext,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
        ),
        _buildTopIconButton(
          icon: CupertinoIcons.gear_alt_fill,
          onPressed: _showSettingsSheet,
        ),
      ]),
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
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1736).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, size: 21, color: _G.lightText),
      ),
    );
  }

  Widget _buildAuthorizationView(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;
    final isRegistering =
        state.registrationStatus == SipRegistrationUiStatus.registering;

    return Scaffold(
      backgroundColor: _G.lightBg,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTopIconButton(
                      icon: CupertinoIcons.back,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB)
                              .withValues(alpha: 0.3),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              CupertinoIcons.phone_circle_fill,
                              color: Colors.white,
                              size: 26,
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
                        ]),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('sip_welcome_subtitle'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _G.lightSurface,
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
                            color: _G.lightAccent,
                            borderRadius: BorderRadius.circular(15),
                            onPressed: isRegistering
                                ? null
                                : () async {
                                    await _saveDraft();
                                    await _sipService.connect();
                                  },
                            child: Text(
                              isRegistering
                                  ? 'Подключение...'
                                  : 'Подключить телефонию',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
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
                                color: _G.red,
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

    final bool isRegistered =
        state.registrationStatus == SipRegistrationUiStatus.registered;
    final Color toneColor = state.callStatus == SipCallUiStatus.incoming
        ? _G.amber
        : isRegistered
            ? _G.green
            : state.registrationStatus == SipRegistrationUiStatus.failed
                ? _G.red
                : _G.lightSubtext;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
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
                    color: _G.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.translate('sip_call_state')}: ${_callLabel(context, state.callStatus)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _G.lightSubtext,
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
                      await _sipService.connect();
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _G.lightText,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Подключить',
                  style: const TextStyle(color: Colors.white),
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
                      color: _G.green,
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
                      color: _G.red,
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
        final spacing = constraints.maxWidth < 380 ? 10.0 : 14.0;
        final quickContacts = _recommendedContacts();
        final widthBased =
            ((constraints.maxWidth - 48 - spacing * 2) / 3).clamp(74.0, 112.0);
        final keypadHeight = (constraints.maxHeight * 0.46).clamp(300.0, 420.0);
        final heightBased =
            ((keypadHeight - spacing * 3) / 4).clamp(74.0, 110.0);
        final buttonSize = math.min(widthBased, heightBased);
        final numberFont = (buttonSize * 0.42).clamp(26.0, 38.0);
        final lettersFont = (buttonSize * 0.13).clamp(10.0, 13.0);
        final callButtonHeight = constraints.maxHeight < 700 ? 58.0 : 64.0;
        final bottomPanelHeight = 430.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPanelHeight - 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (quickContacts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                          child: Row(
                            children: [
                              const Text(
                                'Рекомендуемые',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: _G.lightText,
                                ),
                              ),
                              const Spacer(),
                              if (_contactsEnabled)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: _showContactsSheet,
                                  child: const Icon(
                                    CupertinoIcons.person_2_fill,
                                    color: _G.lightSubtext,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            physics: const ClampingScrollPhysics(),
                            itemCount: quickContacts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final suggestion = quickContacts[index];
                              return _contactTile(
                                suggestion: suggestion,
                                onTap: () => _fillContactNumber(suggestion),
                                onCallTap: () =>
                                    _fillAndCallContact(suggestion),
                              );
                            },
                          ),
                        ),
                      ] else
                        Expanded(
                          child: Center(
                            child: Text(
                              _contactsEnabled
                                  ? 'Начните вводить номер или откройте контакты'
                                  : 'Телефония готова к набору',
                              style: const TextStyle(
                                color: _G.lightSubtext,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EBF1),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onLongPress: _showDialActions,
                              child: CupertinoTextField(
                                controller: _sipIdController,
                                focusNode: _dialFocusNode,
                                readOnly: true,
                                showCursor: true,
                                cursorColor: _G.lightText,
                                cursorWidth: 1.3,
                                cursorHeight: numberFont + 2,
                                keyboardType: TextInputType.phone,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:
                                      constraints.maxWidth < 380 ? 30 : 36,
                                  height: 1,
                                  fontWeight: FontWeight.w400,
                                  color: _G.lightText,
                                ),
                                placeholder: 'Введите номер',
                                placeholderStyle: TextStyle(
                                  fontSize:
                                      constraints.maxWidth < 380 ? 30 : 36,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF9AA6B8),
                                ),
                                magnifierConfiguration:
                                    TextMagnifierConfiguration.disabled,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: const BoxDecoration(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _backspaceDial,
                            onLongPress: _clearDial,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                CupertinoIcons.delete_left,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
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
                                    onTap: () => _insertDialText(key),
                                    onLongPress: key == '0'
                                        ? () => _insertDialText('+')
                                        : null,
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: math.min(constraints.maxWidth * 0.64, 260),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: state.registrationStatus ==
                                  SipRegistrationUiStatus.registered
                              ? _startDialCall
                              : null,
                          child: Container(
                            height: callButtonHeight,
                            decoration: BoxDecoration(
                              color: state.registrationStatus ==
                                      SipRegistrationUiStatus.registered
                                  ? _G.lightGreen
                                  : const Color(0xFF9CA3AF),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: state.registrationStatus ==
                                      SipRegistrationUiStatus.registered
                                  ? [
                                      BoxShadow(
                                        color: _G.lightGreen.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.phone_fill,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Позвонить',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _bottomSwitcher(context, embedded: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _activeCallView(BuildContext context, SipUiState state) {
    final target = _displayIdentity(state);
    final isConnected = state.callStatus == SipCallUiStatus.inCall;
    final statusText = isConnected
        ? _formatDuration(_connectedDuration)
        : _callHint(state.callStatus);

    if (state.callStatus == SipCallUiStatus.incoming) {
      return _incomingCallView(
        context,
        target: target,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _G.activeBg,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: Column(
            children: [
              _buildActiveCallTopBar(context),
              Expanded(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      borderRadius: 20,
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
                                : _callLabel(context, state.callStatus),
                            style: const TextStyle(
                              color: _G.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      target,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _G.textPrimary,
                        fontSize: 62,
                        height: 0.96,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _G.textTertiary,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (_showInCallKeypad) ...[
                      const SizedBox(height: 24),
                      _inCallKeypadPanel(),
                    ],
                    const Spacer(flex: 3),
                    _iosCallControls(context, state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _incomingCallView(
    BuildContext context, {
    required String target,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.35, 0.65, 1],
          colors: [
            Color(0xFF0A0E1A),
            Color(0xFF0F1E4A),
            Color(0xFF112960),
            Color(0xFF0D1F45),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x303D8EFF), Colors.transparent],
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x252563EB), Colors.transparent],
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
                  _GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    borderRadius: 16,
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
                        const Text(
                          'Аудиовызов shamCRM',
                          style: TextStyle(
                            color: _G.textSecondary,
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
                          color: const Color(0xFF3D8EFF)
                              .withValues(alpha: 0.4),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFF3D8EFF)
                              .withValues(alpha: 0.2),
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
                      color: _G.textPrimary,
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
                              color: _G.textSecondary.withValues(
                                alpha: opacity,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Входящий звонок',
                    style: TextStyle(
                      color: _G.textTertiary,
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
                        _GlassContainer(
                          borderRadius: 36,
                          child: const SizedBox(
                            width: 64,
                            height: 64,
                            child: Center(
                              child: Icon(
                                CupertinoIcons.alarm,
                                color: _G.textSecondary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Напомнить',
                          style: TextStyle(
                            color: _G.textSecondary,
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
                    onPressed: _sipService.decline,
                    child: _GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      borderRadius: 22,
                      child: const Text(
                        'Отклонить',
                        style: TextStyle(
                          color: _G.textSecondary,
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

  Widget _buildActiveCallTopBar(BuildContext context) {
    return Row(children: [
      _GlassButton(
        onPressed: () => Navigator.of(context).maybePop(),
        padding: const EdgeInsets.all(10),
        borderRadius: 16,
        child: const Icon(
          CupertinoIcons.chevron_back,
          color: _G.textPrimary,
          size: 22,
        ),
      ),
      const Spacer(),
      const SizedBox(width: 44, height: 44),
    ]);
  }

  Widget _iosCallControls(BuildContext context, SipUiState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state.callStatus == SipCallUiStatus.incoming) {
      return _incomingActionPanel(context);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _iosCircleAction(
                icon: state.isSpeakerOn
                    ? CupertinoIcons.speaker_slash_fill
                    : CupertinoIcons.speaker_3_fill,
                label: state.isSpeakerOn
                    ? l10n.translate('sip_speaker_off')
                    : l10n.translate('sip_speaker_on'),
                onTap: _sipService.toggleSpeaker,
              ),
            ),
            Expanded(
              child: _iosCircleAction(
                icon: CupertinoIcons.circle_grid_3x3_fill,
                label: 'Клавиши',
                onTap: _toggleInCallKeypad,
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
                onTap: _sipService.toggleMute,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Center(
          child: _iosCircleAction(
            icon: CupertinoIcons.phone_down_fill,
            label: 'Отбой',
            onTap: _sipService.hangup,
            destructive: true,
          ),
        ),
      ],
    );
  }

  Future<void> _handleInCallTone(String tone) async {
    setState(() {
      _inCallDigits = '$_inCallDigits$tone';
    });
    await _sipService.sendDtmf(tone);
  }

  void _toggleInCallKeypad() {
    setState(() {
      _showInCallKeypad = !_showInCallKeypad;
      if (!_showInCallKeypad) {
        _inCallDigits = '';
      }
    });
  }

  Widget _inCallKeypadPanel() {
    return _GlassContainer(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      borderRadius: 28,
      child: Column(
        children: [
          Container(
            height: 44,
            alignment: Alignment.center,
            child: Text(
              _inCallDigits.isEmpty ? 'Введите тон' : _inCallDigits,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    _inCallDigits.isEmpty ? _G.textTertiary : _G.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(4, (row) {
            final start = row * 3;
            return Padding(
              padding: EdgeInsets.only(bottom: row == 3 ? 0 : 12),
              child: Row(
                children: List.generate(3, (col) {
                  final item = _dialPadItems[start + col];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: col == 2 ? 0 : 10),
                      child: _inCallKeypadButton(
                        value: item['key']!,
                        letters: item['letters']!,
                        onTap: () => _handleInCallTone(item['key']!),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _inCallKeypadButton({
    required String value,
    required String letters,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: _GlassContainer(
        borderRadius: 20,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _G.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
              if (letters.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  letters,
                  style: const TextStyle(
                    color: _G.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _iosCircleAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          destructive
              ? Container(
                  width: 84,
                  height: 84,
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
                  child: Icon(icon, color: Colors.white, size: 32),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(42),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: _G.glassFill,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _G.glassBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Icon(icon, color: _G.textPrimary, size: 30),
                    ),
                  ),
                ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _G.textSecondary,
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomingActionPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _callControlTile(
            icon: CupertinoIcons.phone_down_fill,
            label: l10n.translate('sip_decline'),
            onTap: _sipService.decline,
            background: const Color(0xFFEF4444),
            foreground: Colors.white,
            emphasized: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _callControlTile(
            icon: CupertinoIcons.phone_fill,
            label: l10n.translate('sip_accept'),
            onTap: _sipService.acceptCall,
            background: const Color(0xFF22C55E),
            foreground: Colors.white,
            emphasized: true,
          ),
        ),
      ],
    );
  }

  Widget _incomingAnswerSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const knobSize = 80.0;
        const horizontalPadding = 10.0;
        final maxDrag =
            math.max(0.0, constraints.maxWidth - knobSize - horizontalPadding * 2);
        final knobOffset = (_incomingAnswerDrag * maxDrag).clamp(0.0, maxDrag);

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (maxDrag <= 0) return;
            setState(() {
              _incomingAnswerDrag = (_incomingAnswerDrag +
                      details.delta.dx / maxDrag)
                  .clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_incomingAnswerDrag >= 0.82) {
              _incomingAnswerDrag = 0;
              _sipService.acceptCall();
              return;
            }
            setState(() {
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
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(52),
                  border: Border.all(
                    color: const Color(0x28FFFFFF),
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: horizontalPadding,
                      child: Container(
                        width: knobOffset + knobSize / 2,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _G.green.withValues(alpha: 0.4),
                              _G.green.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Opacity(
                          opacity: 1 - (_incomingAnswerDrag * 0.9),
                          child: const Text(
                            'Ответьте',
                            style: TextStyle(
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
                              color: _G.green.withValues(
                                alpha: _incomingAnswerDrag * 0.5,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                            const BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_forward,
                          color: _incomingAnswerDrag > 0.5
                              ? _G.green
                              : _G.accent,
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

  Widget _callControlTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color background,
    required Color foreground,
    bool emphasized = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: emphasized ? 146 : 116,
          minHeight: 116,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: background.withValues(alpha: emphasized ? 0.28 : 0.10),
              blurRadius: emphasized ? 18 : 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 30),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
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
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(size * 0.26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8EA0BF).withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 5),
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

  Widget _contactTile({
    required _SipContactSuggestion suggestion,
    required VoidCallback onTap,
    required VoidCallback onCallTap,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 18 : 20,
            backgroundColor: const Color(0xFFE7ECF7),
            backgroundImage: suggestion.photo != null
                ? MemoryImage(suggestion.photo!)
                : null,
            child: suggestion.photo == null
                ? Text(
                    suggestion.name.isEmpty
                        ? '?'
                        : suggestion.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF111827),
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
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
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
                borderRadius: BorderRadius.circular(14),
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

  Widget _bottomSwitcher(BuildContext context, {bool embedded = false}) {
    final l10n = AppLocalizations.of(context)!;

    final switcher = Container(
      margin:
          embedded ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: embedded ? 0.76 : 1),
        borderRadius: BorderRadius.circular(18),
        boxShadow: embedded
            ? null
            : [
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
          const SizedBox(width: 8),
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
    );

    if (embedded) {
      return switcher;
    }

    return SafeArea(
      top: false,
      child: switcher,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE9F2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                  selected ? const Color(0xFF0A84FF) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF0A84FF)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _SipContactSuggestion {
  const _SipContactSuggestion({
    required this.name,
    required this.phone,
    required this.normalizedPhone,
    this.photo,
  });

  final String name;
  final String phone;
  final String normalizedPhone;
  final Uint8List? photo;
}

class _SipIndexedContact {
  const _SipIndexedContact({
    required this.name,
    required this.lowerName,
    required this.t9Name,
    required this.phone,
    required this.normalizedPhone,
    this.photo,
  });

  final String name;
  final String lowerName;
  final String t9Name;
  final String phone;
  final String normalizedPhone;
  final Uint8List? photo;
}
