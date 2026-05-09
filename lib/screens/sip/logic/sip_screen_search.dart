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
