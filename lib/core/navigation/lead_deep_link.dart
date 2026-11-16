import 'dart:convert';

/// Куда ведёт адрес на shamcrm.com. Сам домен открывает приложение,
/// а раздел выбирается уже после PIN.
enum ShamcrmLinkSection { app, lead, deal, task, myTask, event, chat, order }

/// Любая ссылка `https://….shamcrm.com/…`.
/// Лид: `https://tenant.shamcrm.com/leads?lead_id=7270&active_tab=info`
class LeadDeepLink {
  const LeadDeepLink({
    required this.section,
    this.entityId,
    this.organizationId,
    this.salesFunnelId,
    this.host,
    this.activeTab,
  });

  final ShamcrmLinkSection section;
  final int? entityId;
  final int? organizationId;
  final int? salesFunnelId;

  int get leadId => section == ShamcrmLinkSection.lead ? (entityId ?? 0) : 0;

  /// Тип, который уже умеет открывать карточки из пушей.
  String? get navigationType {
    switch (section) {
      case ShamcrmLinkSection.lead:
        return 'lead';
      case ShamcrmLinkSection.deal:
        return 'dealDeadLineNotification';
      case ShamcrmLinkSection.task:
        return 'task';
      case ShamcrmLinkSection.myTask:
        return 'myTaskOutDated';
      case ShamcrmLinkSection.event:
        return 'event';
      case ShamcrmLinkSection.chat:
        return 'message';
      case ShamcrmLinkSection.order:
        return 'orders';
      case ShamcrmLinkSection.app:
        return null;
    }
  }

  /// Хост веб-ссылки. У `shamcrm://leads` его нет: компания берётся из сессии.
  final String? host;
  final String? activeTab;

  static LeadDeepLink? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !_isShamcrmUri(uri)) return null;

    final section = _section(uri);
    return LeadDeepLink(
      section: section,
      entityId: _entityId(uri, section),
      organizationId: _positive(uri.queryParameters['organization_id']),
      salesFunnelId: _positive(uri.queryParameters['sales_funnel_id']),
      host: _tenantHost(uri),
      activeTab: _nonEmpty(uri.queryParameters['active_tab']),
    );
  }
}

enum LeadLinkAccess { granted, denied, unavailable }

/// 200 с телом лида — можно открывать.
/// 403/404 и пустой result — лида нет или у пользователя нет доступа.
/// 401 и 5xx — это не отказ в доступе к лиду.
LeadLinkAccess classifyLeadHttpResponse(int statusCode, String body) {
  if (statusCode == 401 || statusCode >= 500) {
    return LeadLinkAccess.unavailable;
  }
  if (statusCode == 200) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['result'] != null) {
        return LeadLinkAccess.granted;
      }
    } catch (_) {}
    return LeadLinkAccess.denied;
  }
  if (statusCode == 400 ||
      statusCode == 403 ||
      statusCode == 404 ||
      statusCode == 422) {
    return LeadLinkAccess.denied;
  }

  final text = body.toLowerCase();
  if (text.contains('не существует') ||
      text.contains('не найден') ||
      text.contains('not found') ||
      text.contains('нет доступа')) {
    return LeadLinkAccess.denied;
  }
  return LeadLinkAccess.unavailable;
}

/// Ссылка чужой компании не должна запрашивать лид в текущем API:
/// одинаковый id в другом тенанте — это другой лид.
bool leadLinkMatchesSignedInTenant({
  required String? linkHost,
  String? enteredDomain,
  String? enteredMainDomain,
  String? verifiedDomain,
}) {
  if (linkHost == null || linkHost.isEmpty) return true;

  final host = linkHost.toLowerCase();
  final domain = enteredDomain?.trim().toLowerCase();
  final main = enteredMainDomain?.trim().toLowerCase();
  final verified = verifiedDomain?.trim().toLowerCase();
  final candidates = <String>{};

  if (domain != null &&
      domain.isNotEmpty &&
      domain != 'null' &&
      main != null &&
      main.isNotEmpty &&
      main != 'null') {
    candidates.add('$domain.$main');
    candidates.add('$domain-back.$main');
  }
  if (verified != null && verified.isNotEmpty && verified != 'null') {
    candidates.add(verified);
    if (verified.contains('-back.')) {
      candidates.add(verified.replaceFirst('-back.', '.'));
    }
  }
  if (candidates.isEmpty) return true;
  return candidates.contains(host);
}

bool _isShamcrmUri(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  if (scheme == 'shamcrm') return host != 'widget';
  if (scheme != 'https' && scheme != 'http') return false;
  return host == 'shamcrm.com' || host.endsWith('.shamcrm.com');
}

ShamcrmLinkSection _section(Uri uri) {
  final parts = uri.path.split('/').where((part) => part.isNotEmpty).toList();
  final head = (parts.isEmpty ? uri.host : parts.first).toLowerCase();
  switch (head) {
    case 'lead':
    case 'leads':
      return ShamcrmLinkSection.lead;
    case 'deal':
    case 'deals':
      return ShamcrmLinkSection.deal;
    case 'task':
    case 'tasks':
      return ShamcrmLinkSection.task;
    case 'my-task':
    case 'my-tasks':
    case 'my_task':
    case 'my_tasks':
      return ShamcrmLinkSection.myTask;
    case 'event':
    case 'events':
    case 'notice':
    case 'notices':
      return ShamcrmLinkSection.event;
    case 'chat':
    case 'chats':
      return ShamcrmLinkSection.chat;
    case 'order':
    case 'orders':
      return ShamcrmLinkSection.order;
    default:
      return ShamcrmLinkSection.app;
  }
}

int? _entityId(Uri uri, ShamcrmLinkSection section) {
  const keys = <ShamcrmLinkSection, List<String>>{
    ShamcrmLinkSection.lead: ['lead_id', 'id'],
    ShamcrmLinkSection.deal: ['deal_id', 'id'],
    ShamcrmLinkSection.task: ['task_id', 'id'],
    ShamcrmLinkSection.myTask: ['task_id', 'id'],
    ShamcrmLinkSection.event: ['event_id', 'notice_id', 'id'],
    ShamcrmLinkSection.chat: ['chat_id', 'id'],
    ShamcrmLinkSection.order: ['order_id', 'id'],
  };
  for (final key in keys[section] ?? const <String>[]) {
    final id = _positive(uri.queryParameters[key]);
    if (id != null) return id;
  }
  final parts = uri.path.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.length >= 2) return _positive(parts[1]);
  return null;
}

String? _tenantHost(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'https' && scheme != 'http') return null;
  final host = uri.host.trim().toLowerCase();
  return host.isEmpty ? null : host;
}

int? _positive(String? raw) {
  final value = int.tryParse((raw ?? '').trim());
  if (value == null || value <= 0) return null;
  return value;
}

String? _nonEmpty(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
