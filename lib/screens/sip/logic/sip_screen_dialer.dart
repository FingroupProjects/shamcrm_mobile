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
      await _sipRuntime.saveDraft(
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
      _handleDialServerSuggestionsChanged(_sipIdController.text);
      _updateView(() {});
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

  Future<void> _showAddDialDestinationSheet() async {
    final rawNumber = _sipIdController.text.trim();
    if (rawNumber.isEmpty) return;
    await _showAddNumberSheetFor(rawNumber);
  }

  Future<void> _showAddNumberSheetFor(
    String rawNumber, {
    String? suggestedName,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Добавить номер'),
        message: Text(rawNumber),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await _openLeadCreationFromNumber(rawNumber);
            },
            child: const Text('Новый лид'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await _promptSaveContactForNumber(
                rawNumber,
                suggestedName: suggestedName,
              );
            },
            child: const Text('В контакты'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  Future<void> _promptSaveContactForNumber(
    String rawNumber, {
    String? suggestedName,
  }) async {
    final controller = TextEditingController(text: suggestedName ?? '');
    final saved = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Сохранить контакт'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            Text(rawNumber),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Имя контакта',
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (saved != true) {
      controller.dispose();
      return;
    }

    final contactName = controller.text.trim().isEmpty
        ? 'Новый контакт'
        : controller.text.trim();
    controller.dispose();
    await _saveContactForNumber(rawNumber, contactName: contactName);
  }

  Future<void> _saveContactForNumber(
    String rawNumber, {
    required String contactName,
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

    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      _showSipSnackBar('Нет доступа к контактам', isError: true);
      return;
    }

    try {
      final newContact = Contact()
        ..name.first = contactName
        ..phones = [Phone(resolvedPhone)];

      await newContact.insert();
      _contactsLoaded = false;
      await _loadContacts();
      if (!mounted) return;
      _updateView(() {});
      _showSipSnackBar('Контакт сохранён');
    } catch (_) {
      _showSipSnackBar('Не удалось сохранить контакт', isError: true);
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

  Future<void> _startDialCall() async {
    await _saveDraft();
    await _sipRuntime.makeCall();
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
    _sipIdController.value = TextEditingValue(
      text: phoneNumber,
      selection: TextSelection.collapsed(offset: phoneNumber.length),
    );
    _updateView(() {
      _bottomTabIndex = 0;
      _liquidNavDragIndex = 0;
      _isLiquidNavPressed = false;
      _expandedCallLogId = null;
    });
  }

  Future<void> _fillAndCallContact(_SipContactSuggestion suggestion) async {
    _sipIdController.value = TextEditingValue(
      text: suggestion.phone,
      selection: TextSelection.collapsed(offset: suggestion.phone.length),
    );
    await _saveDraft();
    await _sipRuntime.makeCall();
  }

  void _fillContactNumber(_SipContactSuggestion suggestion) {
    _sipIdController.value = TextEditingValue(
      text: suggestion.phone,
      selection: TextSelection.collapsed(offset: suggestion.phone.length),
    );
    _dialFocusNode.requestFocus();
  }
}
