// Этот файл отвечает за внутренние модели контактов для SIP-поиска и подсказок.
part of 'package:crm_task_manager/screens/sip/sip_screen.dart';

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
