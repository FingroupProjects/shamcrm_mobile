import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:intl/intl.dart';

/// Translates audit-history field names and statuses that the API sends in English.
class HistoryLabels {
  static const _fieldKeys = {
    'completed_at': 'history_field_completed_at',
    'working_hours': 'history_field_working_hours',
    'is_finished': 'history_field_is_finished',
    'task_status': 'task_status',
    'name': 'history_field_name',
    'from': 'history_field_from',
    'to': 'history_field_to',
    'start_date': 'start_date',
    'end_date': 'end_date',
    'project': 'history_field_project',
    'users': 'executors',
    'user': 'executors',
    'assignees': 'executors',
    'description': 'history_field_description',
    'priority': 'history_field_priority',
    'priority_level': 'history_field_priority',
    'author': 'author',
    'created_at': 'created_at',
    'updated_at': 'updated_at',
    'deadline': 'deadline',
    'files': 'file_details',
    'deal': 'deals',
    'deals': 'deals',
    'deal_id': 'deals',
  };

  static const _statusKeys = {
    'created': 'history_status_created',
    'updated': 'history_status_updated',
    'changed': 'history_status_updated',
    'modified': 'history_status_updated',
    'deleted': 'history_status_deleted',
    'создано': 'history_status_created',
    'создан': 'history_status_created',
    'изменено': 'history_status_updated',
    'изменен': 'history_status_updated',
    'удалено': 'history_status_deleted',
    'удален': 'history_status_deleted',
  };

  static const _emptyValues = {
    '',
    '-',
    '—',
    'none',
    'null',
    'nil',
    'нет',
    "yo'q",
  };

  static const dateTimeFieldKeys = {
    'completed_at',
    'created_at',
    'updated_at',
    'finished_at',
  };

  static const dateFieldKeys = {
    'from',
    'to',
    'start_date',
    'end_date',
    'deadline',
  };

  static String normalizeKey(String key) {
    return key
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[:]+$'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static bool isEmptyValue(String? raw) {
    if (raw == null) return true;
    return _emptyValues.contains(raw.trim().toLowerCase());
  }

  static String fieldName(AppLocalizations l10n, String key) {
    final locKey = _fieldKeys[normalizeKey(key)];
    if (locKey != null) return l10n.translate(locKey);
    return l10n.translate(key);
  }

  static String status(AppLocalizations l10n, String status) {
    final locKey = _statusKeys[status.trim().toLowerCase()];
    if (locKey != null) return l10n.translate(locKey);
    return l10n.translate(status);
  }

  static String value(AppLocalizations l10n, String? raw, {bool asBool = false}) {
    if (isEmptyValue(raw)) return '—';
    final normalized = raw!.trim().toLowerCase();
    if (asBool) {
      if (normalized == 'true' || normalized == '1') {
        return l10n.translate('yes');
      }
      if (normalized == 'false' || normalized == '0') {
        return l10n.translate('no');
      }
    }
    return raw;
  }

  static String formatDate(String? dateStr, {bool withTime = false}) {
    if (isEmptyValue(dateStr)) return '—';
    final date = DateTime.tryParse(dateStr!);
    if (date == null) return dateStr;
    return withTime
        ? DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal())
        : DateFormat('dd.MM.yyyy').format(date.toLocal());
  }
}
