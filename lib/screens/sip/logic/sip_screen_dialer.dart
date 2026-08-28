// Этот файл отвечает за набор номера, черновик SIP-настроек и быстрые действия с полем номера.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipScreenDialerExtension on _SipScreenState {
  Future<void> _saveDraft() async {
    final parsedPort = int.tryParse(_portController.text.trim()) ??
        (_selectedTransport == SipTransportUi.ws ? 7443 : 5060);
    await _sipRuntime.saveDraft(
      server: _serverController.text,
      login: _loginController.text,
      password: _passwordController.text,
      sipId: '',
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
      await _sipRuntime.saveDraft(
        server: _serverController.text,
        login: _loginController.text,
        password: _passwordController.text,
        sipId: '',
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
    _syncDialSelectionToolbar();
    final text = _sipIdController.text;
    if (text == _lastDialTextForSuggestions) {
      return;
    }
    _lastDialTextForSuggestions = text;
    _contactSearchDebounce?.cancel();
    if (text.isEmpty) {
      _refreshContactSuggestions();
      _handleDialServerSuggestionsChanged(text);
      return;
    }
    _contactSearchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _refreshContactSuggestions();
      _handleDialServerSuggestionsChanged(_sipIdController.text);
    });
  }

  void _syncDialSelectionToolbar() {
    final selection = _sipIdController.selection;
    final text = _sipIdController.text;
    if (!selection.isValid || selection.isCollapsed || text.isEmpty) {
      _dialShouldSelectAllOnToolbar = true;
      _lastDialSelectionKey = null;
      return;
    }

    final key = '${selection.start}:${selection.end}:${text.length}';
    if (key == _lastDialSelectionKey) {
      return;
    }
    _lastDialSelectionKey = key;
    _dialToolbarDebounce?.cancel();
    _dialToolbarDebounce = Timer(const Duration(milliseconds: 40), () {
      if (!mounted) return;
      final current = _sipIdController.selection;
      if (!current.isValid || current.isCollapsed) return;
      _dialEditableTextState?.showToolbar();
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
    if (!_dialFocusNode.hasFocus) {
      _dialFocusNode.requestFocus();
    }
  }

  void _replaceLastDialChar(String expected, String replacement) {
    final currentValue = _sipIdController.value;
    final text = currentValue.text;
    if (text.isEmpty) return;

    final selection = currentValue.selection;
    final end = selection.isValid ? selection.end : text.length;
    if (end <= 0 || end > text.length) return;
    if (text.substring(end - 1, end) != expected) return;

    final newText = text.replaceRange(end - 1, end, replacement);
    _sipIdController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: end - 1 + replacement.length,
      ),
    );
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
      return;
    }

    if (start <= 0) return;
    final newText = text.replaceRange(start - 1, start, '');
    _sipIdController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start - 1),
    );
  }

  void _clearDial() {
    if (_sipIdController.text.isEmpty) return;
    _sipIdController.clear();
    _dialFocusNode.requestFocus();
  }

  Future<String> _clipboardDialText() async {
    final data = await Clipboard.getData('text/plain');
    final source = (data?.text ?? '').trim();
    if (source.isEmpty) return '';
    final normalized = source.replaceAll(RegExp(r'[^0-9+*#]'), '');
    return normalized.isEmpty ? source : normalized;
  }

  Future<bool> _pasteDial() async {
    final text = await _clipboardDialText();
    if (text.isEmpty) return false;
    _insertDialText(text);
    HapticFeedback.lightImpact();
    return true;
  }

  String _selectedDialText() {
    final value = _sipIdController.value;
    final selection = value.selection;
    if (selection.isValid && !selection.isCollapsed) {
      return value.text.substring(selection.start, selection.end);
    }
    return value.text;
  }

  Future<bool> _copyDial({bool notify = false}) async {
    final text = _selectedDialText().trim();
    if (text.isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    if (notify && mounted) {
      _showSipSnackBar(AppLocalizations.of(context)!.translate('copied'));
    }
    return true;
  }

  Future<bool> _cutDial() async {
    final value = _sipIdController.value;
    final selection = value.selection;
    final copied = await _copyDial();
    if (!copied) return false;
    if (selection.isValid && !selection.isCollapsed) {
      final newText = value.text.replaceRange(selection.start, selection.end, '');
      _sipIdController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    } else {
      _clearDial();
    }
    _dialFocusNode.requestFocus();
    return true;
  }

  void _selectAllDial() {
    final text = _sipIdController.text;
    if (text.isEmpty) return;
    _sipIdController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
    _dialFocusNode.requestFocus();
  }

  Widget _dialContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final value = editableTextState.textEditingValue;
    final selection = value.selection;
    final text = value.text;
    final hasText = text.isNotEmpty;
    final hasSelection = selection.isValid && !selection.isCollapsed;
    final isAllSelected = hasText &&
        selection.start == 0 &&
        selection.end == text.length;
    _dialEditableTextState = editableTextState;
    final anchors = editableTextState.contextMenuAnchors;

    if (hasText && _dialShouldSelectAllOnToolbar) {
      _dialShouldSelectAllOnToolbar = false;
      if (!isAllSelected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _selectAllDial();
          editableTextState.showToolbar();
        });
      }
    }

    final buttons = <Widget>[
      if (hasText)
        _DialGlassMenuButton(
          label: l10n.translate('cut'),
          onPressed: () {
            ContextMenuController.removeAny();
            unawaited(_cutDial());
          },
        ),
      if (hasText)
        _DialGlassMenuButton(
          label: l10n.translate('copy'),
          onPressed: () {
            ContextMenuController.removeAny();
            unawaited(_copyDial());
          },
        ),
      _DialGlassMenuButton(
        label: l10n.translate('paste'),
        onPressed: () {
          ContextMenuController.removeAny();
          unawaited(_pasteDialFromMenu());
        },
      ),
      if (hasText && !isAllSelected)
        _DialGlassMenuButton(
          label: l10n.translate('select_text_all'),
          onPressed: () {
            _selectAllDial();
            editableTextState.showToolbar();
          },
        ),
    ];

    return _DialLiquidGlassToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      buttons: buttons,
    );
  }

  Future<void> _pasteDialFromMenu() async {
    final pasted = await _pasteDial();
    if (!pasted && mounted) {
      _showSipSnackBar(
        AppLocalizations.of(context)!.translate('clipboard_empty'),
        isError: true,
      );
    }
  }

  void _onDialPointerDown(PointerDownEvent event) {
    _dialPointers[event.pointer] = event.position;
    if (_dialPointers.length == 3) {
      _dialThreeFingerStartSpan = _dialPointerSpan();
      _dialThreeFingerFired = false;
    }
  }

  void _onDialPointerMove(PointerMoveEvent event) {
    if (!_dialPointers.containsKey(event.pointer)) return;
    _dialPointers[event.pointer] = event.position;
    if (_dialPointers.length != 3 ||
        _dialThreeFingerStartSpan == null ||
        _dialThreeFingerFired) {
      return;
    }
    final span = _dialPointerSpan();
    final delta = span - _dialThreeFingerStartSpan!;
    if (delta < -36) {
      _dialThreeFingerFired = true;
      unawaited(_copyDial(notify: true));
    } else if (delta > 36) {
      _dialThreeFingerFired = true;
      unawaited(_pasteDialFromMenu());
    }
  }

  void _onDialPointerUp(PointerEvent event) {
    _dialPointers.remove(event.pointer);
    if (_dialPointers.length < 3) {
      _dialThreeFingerStartSpan = null;
      _dialThreeFingerFired = false;
    }
  }

  double _dialPointerSpan() {
    final points = _dialPointers.values.toList();
    var maxDistance = 0.0;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        maxDistance = math.max(maxDistance, (points[i] - points[j]).distance);
      }
    }
    return maxDistance;
  }

  Future<void> _showDialActions([Offset? globalPosition]) async {
    if (_isDialActionsSheetVisible) return;
    _isDialActionsSheetVisible = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      final overlayBox =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (!mounted) return;

      final tap = globalPosition ?? _dialHeaderMenuAnchor();
      final selected = overlayBox == null
          ? await _showDialPasteActionSheet()
          : await showMenu<String>(
              context: context,
              position: RelativeRect.fromRect(
                Rect.fromLTWH(tap.dx, tap.dy, 1, 1),
                Offset.zero & overlayBox.size,
              ),
              items: [
                PopupMenuItem<String>(
                  value: 'paste',
                  child: Text(l10n.translate('paste')),
                ),
              ],
            );
      if (!mounted || selected != 'paste') return;

      final pasted = await _pasteDial();
      if (!pasted) {
        _showSipSnackBar(
          l10n.translate('clipboard_empty'),
          isError: true,
        );
      }
    } finally {
      _isDialActionsSheetVisible = false;
    }
  }

  Offset _dialHeaderMenuAnchor() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return const Offset(120, 180);
    }
    final topCenter = box.localToGlobal(Offset(box.size.width / 2, 72));
    return topCenter;
  }

  Future<String?> _showDialPasteActionSheet() async {
    final l10n = AppLocalizations.of(context)!;
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop('paste'),
            child: Text(l10n.translate('paste')),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(l10n.translate('cancel')),
        ),
      ),
    );
  }

  Future<void> _showDialClipboardSheet(String clipboardText) async {
    final l10n = AppLocalizations.of(context)!;
    final previewText = clipboardText.isEmpty
        ? l10n.translate('clipboard_empty')
        : clipboardText;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(l10n.translate('clipboard')),
        message: Text(previewText),
        actions: [
          if (clipboardText.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _insertDialText(clipboardText);
              },
              child: Text(l10n.translate('paste')),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(l10n.translate('cancel')),
        ),
      ),
    );
  }

  Future<void> _showAddDialDestinationSheet() async {
    final rawNumber = _sipIdController.text.trim();
    if (rawNumber.isEmpty) return;
    await _showAddNumberSheetFor(rawNumber);
  }

  Future<void> _showAddNumberSheetFor(
    String rawNumber, {
    String? suggestedName,
    int? leadId,
    bool showCreateLead = true,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Добавить номер'),
        message: Text(rawNumber),
        actions: [
          if (showCreateLead)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await _openLeadCreationFromNumber(rawNumber);
              },
              child: const Text('Создать лид'),
            ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await _openLeadUpdateFromNumber(rawNumber, leadId: leadId);
            },
            child: const Text('Обновить лид'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await _openSystemContactCreationForNumber(
                rawNumber,
                suggestedName: suggestedName,
              );
            },
            child: const Text('Добавить в контакт'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await _updateExistingSystemContactForNumber(rawNumber);
            },
            child: const Text('Обновить существующий контакт'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  Future<void> _openSystemContactCreationForNumber(
    String rawNumber, {
    String? suggestedName,
  }) async {
    final resolvedPhone = await _resolveFullDialPhone(rawNumber: rawNumber);
    if (resolvedPhone == null) return;

    final normalizedPhone = _digitsOnly(resolvedPhone);
    final alreadyExists = _indexedContacts.any(
      (contact) => contact.normalizedPhone == normalizedPhone,
    );

    if (alreadyExists) {
      _showSipSnackBar('Этот номер уже есть в контактах', isError: true);
      return;
    }

    final granted = await FlutterContacts.requestPermission(readonly: false);
    if (!granted) {
      _showSipSnackBar('Нет доступа к контактам', isError: true);
      return;
    }

    try {
      final newContact = Contact()
        ..name.first = (suggestedName ?? '').trim()
        ..phones = [Phone(resolvedPhone)];

      final createdContact = await FlutterContacts.openExternalInsert(
        newContact,
      );
      _contactsLoaded = false;
      await _loadContacts();
      if (!mounted) return;
      _updateView(() {});
      if (createdContact != null) {
        _showSipSnackBar('Контакт сохранён');
      }
    } catch (_) {
      _showSipSnackBar('Не удалось открыть системные контакты', isError: true);
    }
  }

  Future<void> _updateExistingSystemContactForNumber(String rawNumber) async {
    final resolvedPhone = await _resolveFullDialPhone(rawNumber: rawNumber);
    if (resolvedPhone == null) return;

    final granted = await FlutterContacts.requestPermission(readonly: false);
    if (!granted) {
      _showSipSnackBar('Нет доступа к контактам', isError: true);
      return;
    }

    try {
      final picked = await FlutterContacts.openExternalPick();
      if (picked == null || picked.id.isEmpty) return;

      final contact = await FlutterContacts.getContact(
        picked.id,
        withProperties: true,
        withPhoto: true,
        withAccounts: true,
      );
      if (contact == null) {
        _showSipSnackBar('Контакт не найден', isError: true);
        return;
      }

      final normalizedPhone = _digitsOnly(resolvedPhone);
      final hasPhone = contact.phones.any(
        (phone) => _digitsOnly(phone.number) == normalizedPhone,
      );
      if (!hasPhone) {
        contact.phones = [
          ...contact.phones,
          Phone(resolvedPhone),
        ];
        final updated = await FlutterContacts.updateContact(contact);
        await FlutterContacts.openExternalEdit(updated.id);
      } else {
        await FlutterContacts.openExternalEdit(contact.id);
      }

      _contactsLoaded = false;
      await _loadContacts();
      if (mounted) {
        _updateView(() {});
      }
    } catch (_) {
      _showSipSnackBar('Не удалось обновить контакт', isError: true);
    }
  }

  Future<void> _openLeadCreationFromNumber(String rawNumber) async {
    final preparedPhone = await _prepareLeadPhoneSeed(rawNumber: rawNumber);
    if (preparedPhone == null) return;

    final statusId = await _resolveLeadStatusId();
    if (!mounted) return;

    if (statusId == null) {
      _showSipSnackBar('Не удалось определить статус для нового лида',
          isError: true);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeadAddScreen(
          statusId: statusId,
          initialPhone: preparedPhone.$2,
          initialCountry: preparedPhone.$1,
        ),
      ),
    );
  }

  Future<void> _openLeadUpdateFromNumber(
    String rawNumber, {
    int? leadId,
  }) async {
    final resolvedLeadId = leadId ?? await _findLeadIdByNumber(rawNumber);
    if (!mounted) return;

    if (resolvedLeadId == null) {
      _showSipSnackBar('Лид с этим номером не найден', isError: true);
      return;
    }

    try {
      final lead = await _apiService.getLeadById(resolvedLeadId);
      if (!mounted) return;
      await _openLeadEditScreen(lead);
    } catch (_) {
      _showSipSnackBar('Не удалось открыть лид', isError: true);
    }
  }

  Future<int?> _findLeadIdByNumber(String rawNumber) async {
    final digits = _digitsOnly(rawNumber);
    if (digits.isEmpty) return null;

    try {
      final leads = await _apiService.getLeads(
        null,
        page: 1,
        perPage: 10,
        search: digits,
        bypassAnalyticsCache: true,
      );
      if (leads.isEmpty) return null;

      for (final lead in leads) {
        if (_digitsOnly(lead.phone ?? '').endsWith(digits) ||
            digits.endsWith(_digitsOnly(lead.phone ?? ''))) {
          return lead.id;
        }
      }
      return leads.first.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openLeadEditScreen(LeadById lead) async {
    String? formatLeadDate(String? raw) {
      if (raw == null || raw.trim().isEmpty) return null;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return raw;
      return DateFormat('dd/MM/yyyy').format(parsed);
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeadEditScreen(
          leadId: lead.id,
          leadName: lead.name,
          statusId: lead.statusId,
          sourceId: lead.source?.id.toString() ?? '',
          salesFunnelId: lead.salesFunnel?.id.toString() ?? '',
          region: lead.region?.id.toString() ?? '',
          manager: lead.manager?.id.toString() ?? '',
          birthday: formatLeadDate(lead.birthday),
          cityId: lead.cityId,
          createAt: formatLeadDate(lead.createdAt),
          instagram: lead.instagram,
          facebook: lead.facebook,
          telegram: lead.telegram,
          phone: lead.phone,
          whatsApp: lead.whatsApp,
          email: lead.email,
          description: lead.description,
          leadCustomFieldValues: lead.leadCustomFieldValues,
          directoryValues: lead.directoryValues,
          existedFiles: lead.files,
          priceTypeId: lead.priceType?.id.toString(),
          priceTypeName: lead.priceType?.name,
        ),
      ),
    );
  }

  Future<(Country, String)?> _prepareLeadPhoneSeed({String? rawNumber}) async {
    final sourceNumber = (rawNumber ?? _sipIdController.text).trim();
    if (sourceNumber.isEmpty) return null;

    final defaultCountry = await _resolveDefaultCountry();
    final sanitized = sourceNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitized.isEmpty) return null;

    final hasInternationalPrefix =
        sanitized.startsWith('+') || sanitized.startsWith('00');
    final normalizedInternational =
        sanitized.startsWith('00') ? '+${sanitized.substring(2)}' : sanitized;
    final withPlus = normalizedInternational.startsWith('+')
        ? normalizedInternational
        : '+$normalizedInternational';
    Country? matchedCountry;

    for (final country in countries) {
      if (withPlus.startsWith(country.dialCode)) {
        if (matchedCountry == null ||
            country.dialCode.length > matchedCountry.dialCode.length) {
          matchedCountry = country;
        }
      }
    }

    if (hasInternationalPrefix && matchedCountry != null) {
      final localNumber = normalizedInternational
          .substring(matchedCountry.dialCode.length)
          .replaceAll(RegExp(r'[^0-9]'), '');
      return (matchedCountry, localNumber);
    }

    final digitOnly = sanitized.replaceAll(RegExp(r'[^0-9]'), '');
    // Без явного международного префикса номер считаем локальным для текущей
    // страны. Иначе 927... ошибочно распознаётся как +92 вместо +992.
    return (defaultCountry, digitOnly);
  }

  Future<String?> _resolveFullDialPhone({String? rawNumber}) async {
    final prepared = await _prepareLeadPhoneSeed(rawNumber: rawNumber);
    if (prepared == null) return null;

    final country = prepared.$1;
    final localNumber = prepared.$2;
    if (localNumber.isEmpty) return null;
    return '${country.dialCode}$localNumber';
  }

  Future<Country> _resolveDefaultCountry() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDialCode = prefs.getString('default_dial_code');
    if (savedDialCode != null && savedDialCode.isNotEmpty) {
      for (final country in countries) {
        if (country.dialCode == savedDialCode) {
          return country;
        }
      }
    }

    return countries.firstWhere(
      (country) => country.name == 'TJ',
      orElse: () => countries.first,
    );
  }

  Future<int?> _resolveLeadStatusId() async {
    final cachedStatuses = await LeadCache.getLeadStatuses();
    final cachedStatusId = _pickLeadStatusIdFromCache(cachedStatuses);
    if (cachedStatusId != null) {
      return cachedStatusId;
    }

    try {
      final statuses = await _apiService.getLeadStatuses();
      if (statuses.isEmpty) return 1;

      statuses.sort((a, b) => a.position.compareTo(b.position));
      for (final status in statuses) {
        if (!status.isSuccess && !status.isFailure) {
          return status.id;
        }
      }

      return statuses.first.id;
    } catch (_) {
      return 1;
    }
  }

  int? _pickLeadStatusIdFromCache(List<Map<String, dynamic>> statuses) {
    if (statuses.isEmpty) return null;

    for (final status in statuses) {
      final id = status['id'];
      if (id is int) {
        return id;
      }
      if (id is String) {
        return int.tryParse(id);
      }
    }
    return null;
  }

  void _showSipSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    showCustomSnackBar(
      context: context,
      message: message,
      isSuccess: !isError,
    );
  }

  Future<void> _startDialCall({String? fallbackNumber}) async {
    var target = _sipIdController.text.trim();
    if (target.isEmpty) {
      final fallbackTarget = fallbackNumber?.trim();
      target = fallbackTarget?.isNotEmpty == true
          ? fallbackTarget!
          : _lastCallDialTarget();
      if (target.isNotEmpty) {
        _setDialControllerText(target);
        if (fallbackTarget == null || fallbackTarget.isEmpty) {
          await _saveDraft();
          return;
        }
      }
    }

    await _saveDraft();
    await _sipRuntime.makeCallTo(target);
  }

  String _lastCallDialTarget() {
    final calls = <SipCallLogEntry>[
      ..._sipRuntime.state.serverCallLogs,
      ..._sipRuntime.state.callLogs,
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (final call in calls) {
      final target = _callLogDialTarget(call);
      if (target.isNotEmpty) return target;
    }

    return '';
  }

  String _callLogDialTarget(SipCallLogEntry entry) {
    final candidates = <String>[
      entry.dialTarget,
      entry.target,
    ];

    for (final candidate in candidates) {
      final value = candidate.trim();
      if (_isCallableNumber(value) && !_isOwnLineNumber(value)) {
        return value;
      }
    }

    for (final candidate in candidates) {
      final value = candidate.trim();
      if (_isCallableNumber(value)) {
        return value;
      }
    }

    return entry.dialTarget.trim().isNotEmpty
        ? entry.dialTarget.trim()
        : entry.target.trim();
  }

  bool _isCallableNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'Неизвестно') return false;
    if (trimmed.startsWith('sip:') || trimmed.contains('@')) return true;

    final digits = _digitsOnly(trimmed);
    if (digits.length < 3) return false;

    return RegExp(r'^[+0-9()\-\s#*]+$').hasMatch(trimmed);
  }

  bool _isOwnLineNumber(String value) {
    final candidateDigits = _identityDigits(value);
    if (candidateDigits.length < 4) return false;

    final state = _sipRuntime.state;
    final ownCandidates = <String>[
      state.login,
      state.login.split('@').first,
      state.outboundNumber,
      state.internalNumber,
    ];

    for (final ownCandidate in ownCandidates) {
      final ownDigits = _identityDigits(ownCandidate);
      if (ownDigits.length < 4) continue;
      if (candidateDigits == ownDigits ||
          ownDigits.endsWith(candidateDigits) ||
          candidateDigits.endsWith(ownDigits)) {
        return true;
      }
    }

    return false;
  }

  String _identityDigits(String value) {
    var identity = value.trim();
    identity = identity.replaceFirst(
      RegExp(r'^sips?:', caseSensitive: false),
      '',
    );
    if (identity.contains('@')) {
      identity = identity.split('@').first;
    }
    return _digitsOnly(identity);
  }

  void _setDialControllerText(String phoneNumber) {
    _sipIdController.value = TextEditingValue(
      text: phoneNumber,
      selection: TextSelection.collapsed(offset: phoneNumber.length),
    );
  }

  Future<void> _openCallLogDetails(SipCallLogEntry entry) async {
    if (entry.serverCallId == null) {
      _showSipSnackBar('Детали доступны только для серверных звонков',
          isError: true);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallDetailsScreen(callEntry: entry.toCallLogEntry()),
      ),
    );
    await _sipRuntime.refreshRecentCallLogs(
      callType: _sipRuntime.state.serverCallFilter,
      force: true,
    );
  }

  Future<void> _openCallLogHistory(SipCallLogEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SipCallHistoryScreen(
          entry: entry,
          apiService: _apiService,
        ),
      ),
    );
  }

  void _openDialerWithNumber(String phoneNumber) {
    _setDialControllerText(phoneNumber);
    _updateView(() {
      _bottomTabIndex = 0;
      _liquidNavDragIndex = 0;
      _isLiquidNavPressed = false;
      _expandedCallLogId = null;
    });
  }

  Future<void> _fillAndCallContact(_SipContactSuggestion suggestion) async {
    _setDialControllerText(suggestion.phone);
    await _saveDraft();
    await _sipRuntime.makeCallTo(suggestion.phone);
  }

  void _fillContactNumber(_SipContactSuggestion suggestion) {
    _setDialControllerText(suggestion.phone);
    _dialFocusNode.requestFocus();
  }
}
