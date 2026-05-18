// Этот файл отвечает за умный SIP-поиск: звонки, контакты и лиды с сервера.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipScreenSearchExtension on _SipScreenState {
  Future<void> _loadSearchCapabilities() async {
    try {
      final permissions = await _apiService.getPermissions();
      _leadSearchEnabled = permissions.contains('lead.read');
    } catch (_) {
      _leadSearchEnabled = false;
    }
    if (_leadSearchEnabled) {
      unawaited(_loadContactsLeadCount());
    } else {
      _leadTotalCount = 0;
      _isLeadCountLoading = false;
    }
    _ensureValidBottomTabIndex();
    _ensureValidSearchSource();
  }

  List<_SipSearchSource> _availableSearchSources() {
    final sources = <_SipSearchSource>[_SipSearchSource.calls];
    if (_contactsEnabled) {
      sources.add(_SipSearchSource.contacts);
    }
    if (_leadSearchEnabled) {
      sources.add(_SipSearchSource.leads);
    }
    return sources;
  }

  void _ensureValidSearchSource() {
    final sources = _availableSearchSources();
    if (!sources.contains(_searchSource)) {
      _searchSource = sources.first;
    }
  }

  void _selectSearchSource(_SipSearchSource source) {
    if (_searchSource == source) return;
    _updateView(() {
      _searchSource = source;
    });
  }

  void _openUnifiedSearchWithQuery(
    String query, {
    _SipSearchSource? preferredSource,
  }) {
    final trimmed = query.trim();
    final availableSources = _availableSearchSources();
    final resolvedSource =
        preferredSource != null && availableSources.contains(preferredSource)
            ? preferredSource
            : _searchSource;

    _searchViewController.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );

    _updateView(() {
      _bottomTabIndex = 3;
      _searchSource = resolvedSource;
      _searchViewQuery = trimmed;
    });

    _handleUnifiedSearchChanged(trimmed);
  }

  void _handleUnifiedSearchChanged(String value) {
    _leadSearchDebounce?.cancel();
    _searchLeadRequestIdSafeBump();

    _updateView(() {
      _searchViewQuery = value;
      if (value.trim().isEmpty) {
        _isLeadSearchLoading = false;
        _searchLeadResults = const [];
      }
    });

    final query = value.trim();
    if (query.isEmpty || !_leadSearchEnabled) {
      return;
    }

    _leadSearchDebounce = Timer(const Duration(milliseconds: 320), () async {
      await _searchLeadsFromServer(query);
    });
  }

  void _handleJournalSearchChanged(String value) {
    _journalSearchDebounce?.cancel();
    _updateView(() {
      _journalSearchQuery = value;
    });

    if (value.trim().isEmpty) {
      unawaited(_refreshJournalCalls(force: true));
      return;
    }

    _journalSearchDebounce = Timer(const Duration(milliseconds: 320), () async {
      await _refreshJournalCalls(force: true);
    });
  }

  Future<void> _refreshJournalCalls({bool force = false}) async {
    await _sipRuntime.refreshRecentCallLogs(
      callType: _sipRuntime.state.serverCallFilter,
      searchQuery: _journalSearchQuery.trim(),
      force: force,
    );
  }

  void _clearJournalSearch() {
    _journalSearchDebounce?.cancel();
    _journalSearchController.clear();
    _updateView(() {
      _journalSearchQuery = '';
      _expandedCallLogId = null;
    });
    unawaited(_refreshJournalCalls(force: true));
  }

  void _searchDialSuggestionRequestSafeBump() {
    _dialSuggestionRequestId += 1;
  }

  void _handleDialServerSuggestionsChanged(String value) {
    _serverDialSearchDebounce?.cancel();
    _searchDialSuggestionRequestSafeBump();

    final query = value.trim();
    if (query.isEmpty) {
      _rebuildDialSuggestions(serverSuggestions: const []);
      return;
    }

    _serverDialSearchDebounce =
        Timer(const Duration(milliseconds: 320), () async {
      await _searchDialSuggestionsFromServer(query);
    });
  }

  Future<void> _searchDialSuggestionsFromServer(String query) async {
    final requestId = _dialSuggestionRequestId;

    try {
      final futures = <Future<dynamic>>[
        _apiService.getAllCalls(page: 1, perPage: 6, searchQuery: query),
      ];
      if (_leadSearchEnabled) {
        futures.add(
          _apiService.getLeads(
            null,
            perPage: 6,
            search: query,
            bypassAnalyticsCache: true,
          ),
        );
      }

      final results = await Future.wait(futures);
      if (!mounted ||
          requestId != _dialSuggestionRequestId ||
          _sipIdController.text.trim() != query) {
        return;
      }

      final suggestions = <_SipInlineSuggestion>[];
      final calls = results.first as Map<String, dynamic>;
      final callEntries = calls['calls'] as List<CallLogEntry>;
      for (final call in callEntries) {
        final phone = call.phoneNumber.trim();
        if (phone.isEmpty) continue;
        suggestions.add(
          _SipInlineSuggestion(
            name: call.leadName.trim().isEmpty ? phone : call.leadName,
            phone: phone,
            normalizedPhone: _digitsOnly(phone),
            sourceLabel: 'Вызов',
          ),
        );
      }

      if (_leadSearchEnabled && results.length > 1) {
        final leads = results[1] as List<Lead>;
        for (final lead in leads) {
          final phone = (lead.phone ?? '').trim();
          if (phone.isEmpty) continue;
          suggestions.add(
            _SipInlineSuggestion(
              name: lead.name,
              phone: phone,
              normalizedPhone: _digitsOnly(phone),
              sourceLabel: 'Лид',
            ),
          );
        }
      }

      final queryDigits = _digitsOnly(query);
      suggestions.sort((a, b) {
        final aStarts =
            queryDigits.isNotEmpty && a.normalizedPhone.startsWith(queryDigits);
        final bStarts =
            queryDigits.isNotEmpty && b.normalizedPhone.startsWith(queryDigits);
        if (aStarts != bStarts) {
          return aStarts ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

      _rebuildDialSuggestions(serverSuggestions: suggestions);
      if (mounted) {
        _updateView(() {});
      }
    } catch (_) {
      if (!mounted ||
          requestId != _dialSuggestionRequestId ||
          _sipIdController.text.trim() != query) {
        return;
      }
      _rebuildDialSuggestions(serverSuggestions: const []);
      _updateView(() {});
    }
  }

  void _searchLeadRequestIdSafeBump() {
    _leadSearchRequestId += 1;
  }

  Future<void> _searchLeadsFromServer(String query) async {
    final requestId = _leadSearchRequestId;
    _updateView(() {
      _isLeadSearchLoading = true;
    });

    try {
      final leads = await _apiService.getLeads(
        null,
        perPage: 8,
        search: query,
        bypassAnalyticsCache: true,
      );

      if (!mounted ||
          requestId != _leadSearchRequestId ||
          _searchViewQuery.trim() != query) {
        return;
      }

      _updateView(() {
        _searchLeadResults = leads
            .where((lead) => (lead.phone ?? '').trim().isNotEmpty)
            .toList(growable: false);
        _isLeadSearchLoading = false;
      });
    } catch (_) {
      if (!mounted ||
          requestId != _leadSearchRequestId ||
          _searchViewQuery.trim() != query) {
        return;
      }

      _updateView(() {
        _searchLeadResults = const [];
        _isLeadSearchLoading = false;
      });
    }
  }

  void _fillLeadPhone(Lead lead) {
    final phone = (lead.phone ?? '').trim();
    if (phone.isEmpty) return;

    _sipIdController.value = TextEditingValue(
      text: phone,
      selection: TextSelection.collapsed(offset: phone.length),
    );
    _updateView(() {
      _bottomTabIndex = 0;
    });
  }

  Future<void> _callLead(Lead lead) async {
    final phone = (lead.phone ?? '').trim();
    if (phone.isEmpty) return;

    _sipIdController.value = TextEditingValue(
      text: phone,
      selection: TextSelection.collapsed(offset: phone.length),
    );
    _updateView(() {
      _bottomTabIndex = 0;
    });
    await _startDialCall();
  }
}
