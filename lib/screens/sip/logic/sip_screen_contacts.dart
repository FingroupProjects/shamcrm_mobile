// Этот файл отвечает за загрузку контактов, поиск по ним и SIP-подсказки.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

extension _SipScreenContactsExtension on _SipScreenState {
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
}
