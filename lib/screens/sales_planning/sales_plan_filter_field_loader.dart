import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_filter_field.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';

/// Грузит поля фильтров плана из /v3/field-position.
class SalesPlanFilterFieldLoader {
  final ApiService api;

  SalesPlanFilterFieldLoader(this.api);

  static String? tableFor(SalesPlanObjectType object) {
    switch (object) {
      case SalesPlanObjectType.deals:
        return 'deals';
      case SalesPlanObjectType.leads:
        return 'leads';
      case SalesPlanObjectType.tasks:
        return 'tasks';
      case SalesPlanObjectType.calls:
      case SalesPlanObjectType.notices:
        return null;
    }
  }

  Future<List<SalesPlanFilterField>> load(SalesPlanObjectType object) async {
    final table = tableFor(object);
    if (table == null) return fallbackFor(object);

    try {
      final rows = await api.getSalesPlanFieldPositions(table);
      final fields = rows
          .where((row) => !SalesPlanFilterField.shouldSkip(row))
          .map(SalesPlanFilterField.fromPosition)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      if (fields.isEmpty) return fallbackFor(object);

      // В вебе Источник есть всегда, даже если его нет в field-position.
      if ((object == SalesPlanObjectType.deals ||
              object == SalesPlanObjectType.leads) &&
          !fields.any((f) => f.field == 'source' || f.field == 'source_id')) {
        final statusIndex = fields.indexWhere((f) =>
            f.field == 'deal_status_id' || f.field == 'lead_status_id');
        final insertAt =
            statusIndex >= 0 ? statusIndex + 1 : fields.length;
        fields.insert(
          insertAt,
          const SalesPlanFilterField(
            key: 'source',
            field: 'source',
            label: 'Источник',
            labelKey: 'source',
            inputType: SalesPlanFilterInputType.select,
            position: 3,
          ),
        );
      }

      return fields;
    } catch (_) {
      return fallbackFor(object);
    }
  }

  Future<List<SalesPlanFilterOption>> loadOptions({
    required SalesPlanObjectType object,
    required SalesPlanFilterField field,
  }) async {
    if (field.presetOptions.isNotEmpty) return field.presetOptions;

    try {
      if (field.field == 'deal_status_id') {
        final statuses = await api.getDealStatuses(includeAll: true);
        return statuses
            .map((s) => SalesPlanFilterOption(
                  value: s.id.toString(),
                  label: s.title,
                ))
            .toList();
      }
      if (field.field == 'lead_status_id') {
        final statuses = await api.getLeadStatuses();
        return statuses
            .map((s) => SalesPlanFilterOption(
                  value: s.id.toString(),
                  label: s.title,
                ))
            .toList();
      }
      if (field.field == 'source' || field.field == 'source_id') {
        final sources = await api.getAllSource();
        return sources
            .map((s) => SalesPlanFilterOption(
                  value: s.id.toString(),
                  label: s.name,
                ))
            .toList();
      }
      if (field.directoryId != null) {
        final response = await api.getMainFields(field.directoryId!);
        return (response.result ?? [])
            .map((item) => SalesPlanFilterOption(
                  value: item.id.toString(),
                  label: item.value,
                ))
            .toList();
      }
      if (field.customFieldId != null ||
          field.inputType == SalesPlanFilterInputType.select) {
        final values = await _customValues(object, field.field);
        return values
            .map((v) => SalesPlanFilterOption(value: v, label: v))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<List<String>> _customValues(
    SalesPlanObjectType object,
    String key,
  ) async {
    switch (object) {
      case SalesPlanObjectType.deals:
        return api.getDealCustomFieldValues(key);
      case SalesPlanObjectType.leads:
        return api.getLeadCustomFieldValues(key);
      case SalesPlanObjectType.tasks:
        return api.getTaskCustomFieldValues(key);
      case SalesPlanObjectType.calls:
      case SalesPlanObjectType.notices:
        return const [];
    }
  }

  static List<SalesPlanFilterField> fallbackFor(SalesPlanObjectType object) {
    switch (object) {
      case SalesPlanObjectType.deals:
        return const [
          SalesPlanFilterField(
            key: 'deal_status_id',
            field: 'deal_status_id',
            label: 'Статус',
            labelKey: 'status',
            inputType: SalesPlanFilterInputType.select,
          ),
          SalesPlanFilterField(
            key: 'source',
            field: 'source',
            label: 'Источник',
            labelKey: 'source',
            inputType: SalesPlanFilterInputType.select,
          ),
        ];
      case SalesPlanObjectType.leads:
        return const [
          SalesPlanFilterField(
            key: 'lead_status_id',
            field: 'lead_status_id',
            label: 'Статус',
            labelKey: 'status',
            inputType: SalesPlanFilterInputType.select,
          ),
          SalesPlanFilterField(
            key: 'source',
            field: 'source',
            label: 'Источник',
            labelKey: 'source',
            inputType: SalesPlanFilterInputType.select,
          ),
        ];
      case SalesPlanObjectType.calls:
        return const [
          SalesPlanFilterField(
            key: 'call_type',
            field: 'call_type',
            label: 'Тип звонка',
            labelKey: 'sp_filter_call_type',
            inputType: SalesPlanFilterInputType.select,
            presetOptions: [
              SalesPlanFilterOption(value: 'incoming', label: 'incoming'),
              SalesPlanFilterOption(value: 'outgoing', label: 'outgoing'),
              SalesPlanFilterOption(value: 'missed', label: 'missed'),
            ],
          ),
        ];
      case SalesPlanObjectType.tasks:
        return const [
          SalesPlanFilterField(
            key: 'task_status',
            field: 'task_status',
            label: 'Статус',
            labelKey: 'sp_filter_task_status',
            inputType: SalesPlanFilterInputType.select,
            presetOptions: [
              SalesPlanFilterOption(value: 'open', label: 'open'),
              SalesPlanFilterOption(value: 'in_progress', label: 'in_progress'),
              SalesPlanFilterOption(value: 'done', label: 'done'),
              SalesPlanFilterOption(value: 'overdue', label: 'overdue'),
            ],
          ),
        ];
      case SalesPlanObjectType.notices:
        return const [];
    }
  }
}
