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
    unawaited(_reloadUnifiedSearch());
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
    _unifiedSearchDebounce?.cancel();

    _updateView(() {
      _searchViewQuery = value;
    });

    if (_searchSource == _SipSearchSource.contacts) {
      if (_contactsEnabled && !_contactsLoaded) {
        unawaited(_loadContacts());
      }
      return;
    }

    _unifiedSearchDebounce = Timer(const Duration(milliseconds: 320), () {
      unawaited(_reloadUnifiedSearch());
    });
  }

  Future<void> _reloadUnifiedSearch() async {
    switch (_searchSource) {
      case _SipSearchSource.calls:
        await _loadUnifiedCallResults(reset: true);
      case _SipSearchSource.contacts:
        if (_contactsEnabled && !_contactsLoaded) {
          await _loadContacts();
        }
      case _SipSearchSource.leads:
        await _loadUnifiedLeadResults(reset: true);
    }
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
        final phone = _dialSuggestionPhoneForCall(call);
        if (phone.isEmpty) continue;
        final rawName = call.leadName.trim();
        final name = _isCallableNumber(rawName) || _isOwnLineNumber(rawName)
            ? ''
            : rawName;
        suggestions.add(
          _SipInlineSuggestion(
            name: name == 'Неизвестно' ? '' : name,
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

  String _dialSuggestionPhoneForCall(CallLogEntry call) {
    final isOutgoing = call.callType == CallType.outgoing ||
        call.callType == CallType.outgoingMissed;
    final candidates = isOutgoing
        ? <String>[call.destinationNumber ?? '', call.leadName]
        : <String>[call.phoneNumber, call.leadName];

    for (final candidate in candidates) {
      final value = candidate.trim();
      if (_isCallableNumber(value) && !_isOwnLineNumber(value)) {
        return value;
      }
    }

    // Never offer the user's own SIP line as a dial recommendation.
    return '';
  }

  Future<void> _loadUnifiedCallResults({bool reset = false}) async {
    if (!reset &&
        (_isUnifiedCallSearchLoading ||
            _isUnifiedCallSearchLoadingMore ||
            !_unifiedCallSearchHasMore)) {
      return;
    }

    const perPage = 20;
    final query = _searchViewQuery.trim();
    final page = reset ? 1 : _unifiedCallSearchPage + 1;
    final requestId = ++_unifiedSearchRequestId;
    _updateView(() {
      if (reset) {
        _isUnifiedCallSearchLoading = true;
        _unifiedCallResults = const [];
        _unifiedCallSearchPage = 0;
        _unifiedCallSearchHasMore = true;
      } else {
        _isUnifiedCallSearchLoadingMore = true;
      }
    });

    try {
      final response = await _apiService.getAllCalls(
        page: page,
        perPage: perPage,
        searchQuery: query.isEmpty ? null : query,
      );
      if (!mounted ||
          requestId != _unifiedSearchRequestId ||
          _searchSource != _SipSearchSource.calls ||
          _searchViewQuery.trim() != query) {
        return;
      }

      final calls = (response['calls'] as List<CallLogEntry>)
          .map(SipCallLogEntry.fromServerCall)
          .toList(growable: false);
      final pagination = response['pagination'] as Map<String, dynamic>;
      final currentPage = pagination['current_page'] as int? ?? page;
      final totalPages = pagination['total_pages'] as int? ?? currentPage;
      _updateView(() {
        _unifiedCallResults =
            reset ? calls : [..._unifiedCallResults, ...calls];
        _unifiedCallSearchPage = currentPage;
        _unifiedCallSearchHasMore = currentPage < totalPages;
        _isUnifiedCallSearchLoading = false;
        _isUnifiedCallSearchLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _unifiedSearchRequestId) return;
      _updateView(() {
        if (reset) _unifiedCallResults = const [];
        _isUnifiedCallSearchLoading = false;
        _isUnifiedCallSearchLoadingMore = false;
      });
    }
  }

  Future<void> _loadUnifiedLeadResults({bool reset = false}) async {
    if (!_leadSearchEnabled ||
        (!reset &&
            (_isLeadSearchLoading ||
                _isUnifiedLeadSearchLoadingMore ||
                !_unifiedLeadSearchHasMore))) {
      return;
    }

    const perPage = 20;
    final query = _searchViewQuery.trim();
    final page = reset ? 1 : _unifiedLeadSearchPage + 1;
    final requestId = ++_unifiedSearchRequestId;
    _updateView(() {
      if (reset) {
        _isLeadSearchLoading = true;
        _searchLeadResults = const [];
        _unifiedLeadSearchPage = 0;
        _unifiedLeadSearchHasMore = true;
      } else {
        _isUnifiedLeadSearchLoadingMore = true;
      }
    });

    try {
      final leads = await _apiService.getLeads(
        null,
        page: page,
        perPage: perPage,
        search: query.isEmpty ? null : query,
        bypassAnalyticsCache: true,
      );
      if (!mounted ||
          requestId != _unifiedSearchRequestId ||
          _searchSource != _SipSearchSource.leads ||
          _searchViewQuery.trim() != query) {
        return;
      }

      _updateView(() {
        _searchLeadResults = reset ? leads : [..._searchLeadResults, ...leads];
        _unifiedLeadSearchPage = page;
        _unifiedLeadSearchHasMore = leads.length >= perPage;
        _isLeadSearchLoading = false;
        _isUnifiedLeadSearchLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _unifiedSearchRequestId) return;
      _updateView(() {
        if (reset) _searchLeadResults = const [];
        _isLeadSearchLoading = false;
        _isUnifiedLeadSearchLoadingMore = false;
      });
    }
  }

  void _loadMoreUnifiedSearchResults() {
    switch (_searchSource) {
      case _SipSearchSource.calls:
        unawaited(_loadUnifiedCallResults());
      case _SipSearchSource.contacts:
        break;
      case _SipSearchSource.leads:
        unawaited(_loadUnifiedLeadResults());
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
