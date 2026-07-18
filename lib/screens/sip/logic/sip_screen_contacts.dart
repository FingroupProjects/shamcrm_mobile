// Этот файл отвечает за загрузку контактов, поиск по ним и SIP-подсказки.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipScreenContactsExtension on _SipScreenState {
  static const double _contactsListItemExtent = 84;
  static const int _contactsFirstChunkSize = 24;
  static const int _contactsChunkSize = 120;
  static const String _contactsCacheKey = 'sip_contacts_cache_v2';

  Future<void> _refreshContactsView() async {
    if (_isRefreshingContactsTabState) return;

    _isRefreshingContactsTabState = true;
    try {
      await _loadSearchCapabilities();
      await _loadContactsConfiguration();

      if (_contactsEnabled) {
        _contactsLoaded = false;
        _isContactsLoading = false;
        _contactsPermissionDenied = false;
        _contactsTotalCount = 0;
        _displayContacts = const [];
        _indexedContacts = const [];
        if (mounted) {
          _updateView(() {});
        }
        await _loadContacts();
      }

      if (_leadSearchEnabled) {
        await _loadContactsLeadCount();
        await _loadContactsLeadResults(reset: true);
      }
    } finally {
      _isRefreshingContactsTabState = false;
    }
  }

  Future<void> _loadContactsConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _contactsEnabled = prefs.getBool('switchContact') ?? false;
    if (!_contactsEnabled) {
      _contactsTotalCount = 0;
      _displayContacts = const [];
      _contactsLoaded = false;
    }
    _ensureValidBottomTabIndex();
    _ensureValidSearchSource();
    if (_contactsEnabled) {
      unawaited(_loadContacts());
    }
  }

  Future<void> _loadContacts() async {
    if (_contactsLoaded || !_contactsEnabled || _isContactsLoading) return;
    _isContactsLoading = true;
    if (mounted) {
      _updateView(() {});
    }

    try {
      await _restoreCachedContacts();

      final granted = await FlutterContacts.requestPermission();
      if (!granted) {
        _contactsPermissionDenied = true;
        _contactsTotalCount = 0;
        _ensureValidBottomTabIndex();
        _ensureValidSearchSource();
        if (_leadSearchEnabled) {
          unawaited(_loadContactsLeadResults(reset: true));
        }
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      final filteredContacts = contacts
          .where((contact) =>
              contact.displayName.trim().isNotEmpty &&
              contact.phones.isNotEmpty)
          .toList(growable: true)
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      _contactsTotalCount = filteredContacts.length;

      final visibleContacts = <_SipContactSuggestion>[];
      final indexedContacts = <_SipIndexedContact>[];

      _displayContacts = const [];
      _indexedContacts = const [];
      _contactsPermissionDenied = false;
      _ensureValidBottomTabIndex();
      _ensureValidSearchSource();

      for (var start = 0;
          start < filteredContacts.length;
          start += _contactsChunkSize) {
        final end =
            math.min(start + _contactsChunkSize, filteredContacts.length);
        final batch = filteredContacts.sublist(start, end);

        for (final contact in batch) {
          final mapped = _mapContact(contact);
          if (mapped == null) continue;
          visibleContacts.add(mapped.$1);
          indexedContacts.addAll(mapped.$2);
        }

        final reachedFirstPaint =
            visibleContacts.length >= _contactsFirstChunkSize ||
                end == filteredContacts.length;
        if (reachedFirstPaint || start > 0) {
          _displayContacts = List<_SipContactSuggestion>.unmodifiable(
            visibleContacts,
          );
          _indexedContacts = List<_SipIndexedContact>.unmodifiable(
            indexedContacts,
          );
          _contactsLoaded = true;
          _refreshContactSuggestions();
          if (mounted) {
            _updateView(() {});
          }
          await Future<void>.delayed(Duration.zero);
        }
      }

      await _persistCachedContacts(_displayContacts);
    } catch (_) {
      _contactsPermissionDenied = true;
      _ensureValidBottomTabIndex();
      _ensureValidSearchSource();
    } finally {
      _isContactsLoading = false;
      if (mounted) {
        _updateView(() {});
      }
    }
  }

  (_SipContactSuggestion, List<_SipIndexedContact>)? _mapContact(
      Contact contact) {
    final displayName = contact.displayName.trim();
    if (displayName.isEmpty || contact.phones.isEmpty) return null;

    final primaryPhone = contact.phones.first.number;
    final lowerName = displayName.toLowerCase();
    final t9Name = _nameToT9Digits(lowerName);
    final photo = contact.photo;
    final indexedPhones = contact.phones
        .map(
          (phone) => _SipIndexedContact(
            name: displayName,
            lowerName: lowerName,
            t9Name: t9Name,
            phone: phone.number,
            normalizedPhone: _digitsOnly(phone.number),
            photo: photo,
          ),
        )
        .toList(growable: false);

    return (
      _SipContactSuggestion(
        name: displayName,
        phone: primaryPhone,
        normalizedPhone: _digitsOnly(primaryPhone),
        photo: photo,
      ),
      indexedPhones,
    );
  }

  Future<void> _restoreCachedContacts() async {
    if (_displayContacts.isNotEmpty || _contactsLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final rawCache = prefs.getString(_contactsCacheKey);
    if (rawCache == null || rawCache.isEmpty) return;

    try {
      final decoded = jsonDecode(rawCache);
      if (decoded is! List) return;

      final cached = decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map(
            (item) => _SipContactSuggestion(
              name: (item['name'] as String? ?? '').trim(),
              phone: (item['phone'] as String? ?? '').trim(),
              normalizedPhone:
                  (item['normalizedPhone'] as String? ?? '').trim(),
            ),
          )
          .where((item) => item.name.isNotEmpty && item.phone.isNotEmpty)
          .toList(growable: false);

      if (cached.isEmpty) return;

      _displayContacts = cached;
      _contactsTotalCount = cached.length;
      _contactsLoaded = true;
      if (mounted) {
        _updateView(() {});
      }
    } catch (_) {
      // Ignore broken cache and continue with a fresh native load.
    }
  }

  Future<void> _persistCachedContacts(
    List<_SipContactSuggestion> contacts,
  ) async {
    if (contacts.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final payload = contacts
        .map(
          (contact) => <String, String>{
            'name': contact.name,
            'phone': contact.phone,
            'normalizedPhone': contact.normalizedPhone,
          },
        )
        .toList(growable: false);
    await prefs.setString(_contactsCacheKey, jsonEncode(payload));
  }

  Future<void> _loadContactsLeadCount() async {
    if (!_leadSearchEnabled || _isLeadCountLoading) return;

    _isLeadCountLoading = true;
    if (mounted) {
      _updateView(() {});
    }

    try {
      _leadTotalCount = await _apiService.getLeadCountAll();
    } catch (_) {
      _leadTotalCount = 0;
    } finally {
      _isLeadCountLoading = false;
      if (mounted) {
        _updateView(() {});
      }
    }
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
      _rebuildDialSuggestions();
      return;
    }

    final rawQuery = _sipIdController.text.trim();
    final queryDigits = _digitsOnly(rawQuery);
    if (rawQuery.isEmpty) {
      _contactSuggestions = const [];
      _rebuildDialSuggestions();
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
    final uniqueSuggestions = suggestions.where((item) {
      final key = '${item.name}|${item.normalizedPhone}';
      return unique.add(key);
    }).toList(growable: false);
    _contactSuggestions = uniqueSuggestions.take(6).toList(growable: false);
    _rebuildDialSuggestions();
  }

  void _rebuildDialSuggestions({
    List<_SipInlineSuggestion>? serverSuggestions,
  }) {
    final merged = <_SipInlineSuggestion>[
      ..._contactSuggestions.map(
        (item) => _SipInlineSuggestion(
          name: item.name,
          phone: item.phone,
          normalizedPhone: item.normalizedPhone,
          sourceLabel: 'Контакт',
          photo: item.photo,
        ),
      ),
      ...(serverSuggestions ??
          _dialSuggestions.where((item) {
            return item.sourceLabel != 'Контакт';
          })),
    ];

    final unique = <String>{};
    final uniqueSuggestions = merged.where((item) {
      final key = '${item.normalizedPhone}|${item.sourceLabel}|${item.name}';
      return unique.add(key);
    }).toList(growable: false);

    _dialSuggestionTotalCount = uniqueSuggestions.length;
    _dialSuggestions = uniqueSuggestions.take(8).toList(growable: false);
  }

  void _handleContactsViewChanged(String value) {
    _updateView(() {
      _contactsViewQuery = value;
    });

    if (_resolvedContactsTabSource() == _SipContactsTabSource.leads) {
      _contactsLeadSearchDebounce?.cancel();
      _contactsLeadSearchDebounce =
          Timer(const Duration(milliseconds: 320), () async {
        await _loadContactsLeadResults(reset: true);
      });
    }
  }

  _SipContactsTabSource _resolvedContactsTabSource() {
    if (!_contactsEnabled && _leadSearchEnabled) {
      return _SipContactsTabSource.leads;
    }
    if (_contactsPermissionDenied) {
      return _SipContactsTabSource.leads;
    }
    if (_contactsTabSource == _SipContactsTabSource.leads &&
        !_leadSearchEnabled) {
      return _SipContactsTabSource.contacts;
    }
    return _contactsTabSource;
  }

  void _selectContactsTabSource(_SipContactsTabSource source) {
    if (_contactsPermissionDenied && source == _SipContactsTabSource.contacts) {
      return;
    }
    if (source == _SipContactsTabSource.leads && !_leadSearchEnabled) return;
    if (source == _SipContactsTabSource.contacts && !_contactsEnabled) return;
    if (_contactsTabSource == source) return;
    _updateView(() {
      _contactsTabSource = source;
    });
    if (source == _SipContactsTabSource.leads) {
      unawaited(_loadContactsLeadResults(reset: true));
    }
  }

  Future<void> _loadContactsLeadResults({bool reset = false}) async {
    if (!_leadSearchEnabled) return;
    if (_isContactsLeadLoading || _isContactsLeadLoadingMore) return;

    const perPage = 20;
    final nextPage = reset ? 1 : _contactsLeadCurrentPage + 1;
    if (!reset && !_contactsLeadHasMore) return;

    final requestId = ++_contactsLeadRequestId;
    _updateView(() {
      if (reset) {
        _isContactsLeadLoading = true;
        _contactsLeadCurrentPage = 0;
        _contactsLeadHasMore = true;
      } else {
        _isContactsLeadLoadingMore = true;
      }
    });

    try {
      final leads = await _apiService.getLeads(
        null,
        page: nextPage,
        perPage: perPage,
        search: _contactsViewQuery.trim().isEmpty
            ? null
            : _contactsViewQuery.trim(),
        bypassAnalyticsCache: true,
      );

      if (!mounted || requestId != _contactsLeadRequestId) return;

      _updateView(() {
        final filteredLeads = leads
            .where((lead) => (lead.phone ?? '').trim().isNotEmpty)
            .toList(growable: false);
        if (reset) {
          _contactsLeadResults = filteredLeads;
        } else {
          _contactsLeadResults = [
            ..._contactsLeadResults,
            ...filteredLeads,
          ];
        }
        _contactsLeadCurrentPage = nextPage;
        _contactsLeadHasMore = leads.length >= perPage;
        _isContactsLeadLoading = false;
        _isContactsLeadLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _contactsLeadRequestId) return;

      _updateView(() {
        if (reset) {
          _contactsLeadResults = const [];
          _contactsLeadCurrentPage = 0;
          _contactsLeadHasMore = true;
        }
        _isContactsLeadLoading = false;
        _isContactsLeadLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreContactsLeadResults() async {
    await _loadContactsLeadResults();
  }

  String _contactIndexLetter(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '#';
    final first = String.fromCharCode(trimmed.runes.first).toUpperCase();
    return RegExp(r'[A-ZА-ЯЁ]').hasMatch(first) ? first : '#';
  }

  List<String> _contactIndexLetters(List<_SipContactSuggestion> contacts) {
    final letters = <String>[];
    final seen = <String>{};
    for (final contact in contacts) {
      final letter = _contactIndexLetter(contact.name);
      if (seen.add(letter)) {
        letters.add(letter);
      }
    }
    return letters;
  }

  int _contactIndexPositionForLetter(
    List<_SipContactSuggestion> contacts,
    String letter,
  ) {
    for (var i = 0; i < contacts.length; i++) {
      if (_contactIndexLetter(contacts[i].name) == letter) {
        return i;
      }
    }
    return 0;
  }

  void _showContactsIndexOverlay(String letter, {double? top}) {
    _contactsIndexOverlayTimer?.cancel();
    _updateView(() {
      _contactsIndexOverlayLetter = letter;
      if (top != null) {
        _contactsIndexOverlayTop = top;
      }
    });
    _contactsIndexOverlayTimer = Timer(const Duration(milliseconds: 720), () {
      if (!mounted) return;
      _updateView(() {
        _contactsIndexOverlayLetter = null;
        _contactsIndexOverlayTop = null;
      });
    });
  }

  void _jumpToContactsLetter(
    String letter,
    List<_SipContactSuggestion> contacts,
    {double? overlayTop}
  ) {
    if (!_contactsListController.hasClients || contacts.isEmpty) return;
    final targetIndex = _contactIndexPositionForLetter(contacts, letter);
    final maxExtent = _contactsListController.position.maxScrollExtent;
    final targetOffset =
        (targetIndex * _contactsListItemExtent).clamp(0.0, maxExtent);
    _contactsListController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    _showContactsIndexOverlay(letter, top: overlayTop);
  }
}
