import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_colors.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class _ConstructorFilter {
  String field;
  String value;
  String label;

  _ConstructorFilter({
    required this.field,
    required this.value,
    required this.label,
  });
}

class SalesPlanConstructorScreen extends StatefulWidget {
  final int? planId;
  final SalesPlan? plan;

  const SalesPlanConstructorScreen({super.key, this.planId, this.plan});

  @override
  State<SalesPlanConstructorScreen> createState() =>
      _SalesPlanConstructorScreenState();
}

class _SalesPlanConstructorScreenState
    extends State<SalesPlanConstructorScreen> {
  final _api = ApiService();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _commentController = TextEditingController();

  SalesPlanObjectType? _object;
  SalesPlanAggregation? _aggregation;
  String? _field;
  final List<_ConstructorFilter> _filters = [];

  SalesPlanPeriodType _periodType = SalesPlanPeriodType.month;
  SalesPlanRecurrence _recurrence = SalesPlanRecurrence.monthly;
  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  final Set<int> _selectedUserIds = {};
  List<ManagerData> _managers = [];
  bool _saving = false;
  bool _nameTouched = false;

  bool get _isEdit => widget.planId != null;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    final plan = widget.plan;
    if (plan != null) {
      _object = plan.objectType;
      _aggregation = plan.aggregation;
      _field = plan.aggregationField;
      _nameController.text = plan.name;
      _nameTouched = true;
      _valueController.text = plan.targetValue.toStringAsFixed(
          plan.targetValue % 1 == 0 ? 0 : 2);
      _commentController.text = plan.comment ?? '';
      _periodType = plan.periodType;
      _recurrence = plan.recurrence;
      _periodStart = plan.periodStart ?? _periodStart;
      _periodEnd = plan.periodEnd ?? _periodEnd;
      _selectedUserIds.addAll(plan.users.map((u) => u.id));
      for (final f in plan.filters) {
        _filters.add(_ConstructorFilter(
          field: f.field,
          value: f.value,
          label: f.field,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterDefsFor(SalesPlanObjectType object) {
    switch (object) {
      case SalesPlanObjectType.deals:
        return [
          {
            'field': 'deal_status_id',
            'label': 'sp_filter_deal_status',
            'options': ['new', 'in_progress', 'success', 'failed'],
          },
          {
            'field': 'source',
            'label': 'sp_filter_source',
            'options': ['Instagram', 'Telegram', 'Site', 'Call', 'Referral'],
          },
        ];
      case SalesPlanObjectType.leads:
        return [
          {
            'field': 'lead_status_id',
            'label': 'sp_filter_lead_status',
            'options': ['new', 'qualified', 'rejected', 'converted'],
          },
          {
            'field': 'source',
            'label': 'sp_filter_source',
            'options': ['Instagram', 'Telegram', 'Site', 'Call', 'Referral'],
          },
        ];
      case SalesPlanObjectType.calls:
        return [
          {
            'field': 'call_type',
            'label': 'sp_filter_call_type',
            'options': ['incoming', 'outgoing', 'missed'],
          },
        ];
      case SalesPlanObjectType.tasks:
        return [
          {
            'field': 'task_status',
            'label': 'sp_filter_task_status',
            'options': ['open', 'in_progress', 'done', 'overdue'],
          },
        ];
      case SalesPlanObjectType.notices:
        return [];
    }
  }

  bool get _aggReady =>
      _aggregation != null &&
      (_aggregation == SalesPlanAggregation.count ||
          (_field != null && _field!.isNotEmpty));

  SalesPlanType get _autoType =>
      _aggregation == SalesPlanAggregation.count
          ? SalesPlanType.count
          : SalesPlanType.sum;

  String _summaryText(BuildContext context) {
    if (_object == null || !_aggReady) return '—';
    final object = SalesPlanLabels.objectType(context, _object!).toLowerCase();
    String text;
    if (_aggregation == SalesPlanAggregation.count) {
      text =
          '${AppLocalizations.of(context)!.translate('sp_agg_count')} «$object»';
    } else {
      final fieldLabel =
          SalesPlanLabels.numericFieldLabel(context, _field ?? '');
      text =
          '${SalesPlanLabels.aggregation(context, _aggregation!)} «$fieldLabel» ($object)';
    }
    if (_filters.isNotEmpty) {
      text +=
          ', ${AppLocalizations.of(context)!.translate('sp_where')} ${_filters.map((f) => '${f.label} = «${SalesPlanLabels.filterOptionLabel(context, f.value)}»').join(', ')}';
    }
    return text;
  }

  void _selectObject(SalesPlanObjectType object) {
    setState(() {
      _object = object;
      _aggregation = null;
      _field = null;
      _filters.clear();
      if (!_nameTouched) {
        _nameController.text =
            '${SalesPlanLabels.objectType(context, object)} — ';
      }
    });
  }

  void _selectAgg(SalesPlanAggregation agg) {
    setState(() {
      _aggregation = agg;
      _field = null;
      if (!_nameTouched) {
        final objectLabel = SalesPlanLabels.objectType(context, _object!);
        _nameController.text = agg == SalesPlanAggregation.count
            ? '$objectLabel — ${AppLocalizations.of(context)!.translate('sp_agg_count').toLowerCase()}'
            : '$objectLabel — ';
      }
    });
  }

  void _addFilter() {
    if (_object == null) return;
    final defs = _filterDefsFor(_object!);
    final used = _filters.map((f) => f.field).toSet();
    final avail = defs.where((d) => !used.contains(d['field'])).toList();
    if (avail.isEmpty) return;
    final def = avail.first;
    final options = (def['options'] as List).cast<String>();
    setState(() {
      _filters.add(_ConstructorFilter(
        field: def['field'] as String,
        value: options.first,
        label: AppLocalizations.of(context)!.translate(def['label'] as String),
      ));
    });
  }

  DateTimeRange _defaultRangeFor(SalesPlanPeriodType type) {
    final now = DateTime.now();
    switch (type) {
      case SalesPlanPeriodType.day:
        return DateTimeRange(start: now, end: now);
      case SalesPlanPeriodType.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
            start: start, end: start.add(const Duration(days: 6)));
      case SalesPlanPeriodType.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case SalesPlanPeriodType.quarter:
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, q, 1),
          end: DateTime(now.year, q + 3, 0),
        );
      case SalesPlanPeriodType.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
    }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final allowed = await _api.hasPermission(
      _isEdit ? 'planning.update' : 'planning.create',
    );
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('sp_save_error'))),
      );
      return;
    }
    if (_object == null || !_aggReady || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('sp_fill_required'))),
      );
      return;
    }
    final value = double.tryParse(
        _valueController.text.replaceAll(' ', '').replaceAll(',', '.'));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('sp_invalid_target'))),
      );
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('sp_select_owners'))),
      );
      return;
    }

    setState(() => _saving = true);
    final request = SalesPlanCreateRequest(
      name: _nameController.text.trim(),
      planType: _autoType,
      objectType: _object!,
      aggregation: _aggregation!,
      aggregationField:
          _aggregation == SalesPlanAggregation.count ? null : _field,
      targetValue: value,
      periodType: _periodType,
      periodStart: _periodStart,
      periodEnd: _periodEnd,
      recurrence: _recurrence,
      userIds: _selectedUserIds.toList(),
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      filters: _filters
          .map((f) => SalesPlanFilterItem(
                field: f.field,
                value: f.value,
              ))
          .toList(),
    );

    final result = _isEdit
        ? await _api.updateSalesPlan(
            widget.planId!, request.toJson(includeOrg: false))
        : await _api.createSalesPlan(request.toJson());

    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? t.translate('sp_save_error'),
          ),
        ),
      );
    }
  }

  void _reset() {
    setState(() {
      _object = null;
      _aggregation = null;
      _field = null;
      _filters.clear();
      _nameController.clear();
      _valueController.clear();
      _commentController.clear();
      _nameTouched = false;
      _selectedUserIds.clear();
      _periodType = SalesPlanPeriodType.month;
      _recurrence = SalesPlanRecurrence.monthly;
      final range = _defaultRangeFor(_periodType);
      _periodStart = range.start;
      _periodEnd = range.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final numeric = _object == null
        ? <String>[]
        : SalesPlanLabels.numericFieldsFor(_object!);
    final filterDefs = _object == null ? <Map<String, dynamic>>[] : _filterDefsFor(_object!);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        foregroundColor: colors.textPrimary,
        title: Text(t.translate('sales_planning')),
      ),
      body: BlocListener<GetAllManagerBloc, GetAllManagerState>(
        listener: (context, state) {
          if (state is GetAllManagerSuccess) {
            setState(() => _managers = state.dataManager.result ?? []);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _steps(context),
            const SizedBox(height: 18),
            _sectionLabel(t.translate('sp_step_object')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SalesPlanObjectType.values.map((o) {
                final selected = _object == o;
                return _chip(
                  SalesPlanLabels.objectType(context, o),
                  selected: selected,
                  onTap: () => _selectObject(o),
                );
              }).toList(),
            ),
            if (_object != null) ...[
              const SizedBox(height: 16),
              _sectionLabel(t.translate('sp_step_aggregation')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SalesPlanAggregation.values.map((a) {
                  final disabled =
                      a != SalesPlanAggregation.count && numeric.isEmpty;
                  return _chip(
                    SalesPlanLabels.aggregation(context, a),
                    selected: _aggregation == a,
                    disabled: disabled,
                    onTap: disabled ? null : () => _selectAgg(a),
                  );
                }).toList(),
              ),
              if (_aggregation != null &&
                  _aggregation != SalesPlanAggregation.count) ...[
                const SizedBox(height: 14),
                _sectionLabel(t.translate('sp_pick_field')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: numeric.map((f) {
                    return _chip(
                      SalesPlanLabels.numericFieldLabel(context, f),
                      selected: _field == f,
                      onTap: () {
                        setState(() {
                          _field = f;
                          if (!_nameTouched) {
                            _nameController.text =
                                '${SalesPlanLabels.objectType(context, _object!)} — ${SalesPlanLabels.numericFieldLabel(context, f)}';
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              if (numeric.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    t.translate('sp_only_count'),
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
            ],
            if (_aggReady) ...[
              const SizedBox(height: 16),
              _sectionLabel(t.translate('sp_step_filters')),
              if (filterDefs.isEmpty)
                Text(
                  t.translate('sp_no_filters'),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                )
              else ...[
                ..._filters.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final f = entry.value;
                  final def = filterDefs.firstWhere(
                    (d) => d['field'] == f.field,
                    orElse: () => filterDefs.first,
                  );
                  final options = (def['options'] as List).cast<String>();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: f.field,
                                isExpanded: true,
                                decoration: _inputDecoration(),
                                items: filterDefs.map((d) {
                                  final used = _filters.any((sf) =>
                                      sf.field == d['field'] && sf != f);
                                  return DropdownMenuItem(
                                    value: d['field'] as String,
                                    enabled: !used,
                                    child: Text(
                                      t.translate(d['label'] as String),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final nd = filterDefs
                                      .firstWhere((d) => d['field'] == v);
                                  setState(() {
                                    _filters[idx] = _ConstructorFilter(
                                      field: v,
                                      value: (nd['options'] as List)
                                          .cast<String>()
                                          .first,
                                      label: t.translate(nd['label'] as String),
                                    );
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setState(() => _filters.removeAt(idx)),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: options.contains(f.value)
                              ? f.value
                              : options.first,
                          isExpanded: true,
                          decoration: _inputDecoration(),
                          items: options
                              .map((o) => DropdownMenuItem(
                                    value: o,
                                    child: Text(
                                      SalesPlanLabels.filterOptionLabel(
                                          context, o),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => f.value = v);
                          },
                        ),
                      ],
                    ),
                  );
                }),
                if (_filters.length < filterDefs.length)
                  _chip(
                    '+ ${t.translate('sp_add_filter')}',
                    selected: false,
                    dashed: true,
                    onTap: _addFilter,
                  ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SalesPlanColors.selectionBg(context),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: SalesPlanColors.selection(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translate('sp_indicator'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SalesPlanColors.selection(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _summaryText(context),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Divider(color: colors.borderSubtle),
            const SizedBox(height: 12),
            _fieldLabel('${t.translate('sp_name')} *'),
            TextField(
              controller: _nameController,
              onChanged: (_) => _nameTouched = true,
              decoration: _inputDecoration(
                hint: t.translate('sp_name_hint'),
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('${t.translate('sp_filter_type')} *'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: colors.backgroundPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Text(
                _aggReady
                    ? SalesPlanLabels.planType(context, _autoType)
                    : t.translate('sp_type_auto'),
                style: TextStyle(
                  color: _aggReady ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('${t.translate('sp_target')} *'),
            TextField(
              controller: _valueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration(hint: '500000'),
            ),
            const SizedBox(height: 12),
            _fieldLabel('${t.translate('sp_owners')} *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _managers.map((m) {
                final selected = _selectedUserIds.contains(m.id);
                final label = '${m.name} ${m.lastname ?? ''}'.trim();
                return _chip(
                  label,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedUserIds.remove(m.id);
                      } else {
                        _selectedUserIds.add(m.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_managers.isEmpty)
              Text(
                t.translate('sp_managers_loading'),
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            const SizedBox(height: 12),
            _fieldLabel('${t.translate('sp_period')} *'),
            DropdownButtonFormField<SalesPlanPeriodType>(
              value: _periodType,
              decoration: _inputDecoration(),
              items: SalesPlanPeriodType.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(SalesPlanLabels.periodType(context, p)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final range = _defaultRangeFor(v);
                setState(() {
                  _periodType = v;
                  _periodStart = range.start;
                  _periodEnd = range.end;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _periodStart,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _periodStart = d);
                    },
                    child: Text(DateFormat('dd.MM.yyyy').format(_periodStart)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _periodEnd,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _periodEnd = d);
                    },
                    child: Text(DateFormat('dd.MM.yyyy').format(_periodEnd)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _fieldLabel('${t.translate('sp_recurrence')} *'),
            DropdownButtonFormField<SalesPlanRecurrence>(
              value: _recurrence,
              decoration: _inputDecoration(),
              items: SalesPlanRecurrence.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(SalesPlanLabels.recurrence(context, r)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _recurrence = v);
              },
            ),
            const SizedBox(height: 12),
            _fieldLabel(t.translate('sp_comment')),
            TextField(
              controller: _commentController,
              decoration: _inputDecoration(),
              maxLines: 2,
            ),
          ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText: t.translate('sp_reset'),
                        buttonColor: colors.backgroundPrimary,
                        textColor: colors.textPrimary,
                        borderColor: colors.borderSubtle,
                        borderWidth: 1,
                        onPressed: _saving ? null : _reset,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        buttonText: t.translate('sp_save'),
                        buttonColor: colors.buttonPrimaryBg,
                        textColor: colors.buttonPrimaryFg,
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _steps(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;
    final s1Done = _object != null;
    final s2Done = _aggReady;
    final s3Active = _aggReady;

    Widget step(int n, String title, String sub, {bool active = false, bool done = false}) {
      final accent = active ? SalesPlanColors.orange : SalesPlanColors.green;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? SalesPlanColors.orange.withValues(alpha: 0.12)
                : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active
                  ? SalesPlanColors.orange
                  : done
                      ? SalesPlanColors.green.withValues(alpha: 0.5)
                      : colors.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? SalesPlanColors.orange
                      : done
                          ? SalesPlanColors.green.withValues(alpha: 0.2)
                          : colors.backgroundPrimary,
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? SalesPlanColors.actionNavy
                        : done
                            ? SalesPlanColors.green
                            : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
              Text(sub,
                  style: TextStyle(
                      fontSize: 11,
                      color: active ? accent : colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        step(1, t.translate('sp_step_object_short'),
            _object == null
                ? t.translate('sp_what')
                : SalesPlanLabels.objectType(context, _object!),
            active: !s1Done,
            done: s1Done),
        const SizedBox(width: 8),
        step(
          2,
          t.translate('sp_step_agg_short'),
          _aggregation == null
              ? t.translate('sp_how')
              : SalesPlanLabels.aggregation(context, _aggregation!),
          active: s1Done && !s2Done,
          done: s2Done,
        ),
        const SizedBox(width: 8),
        step(
          3,
          t.translate('sp_step_filters_short'),
          _filters.isEmpty
              ? t.translate('sp_refine')
              : '${_filters.length}',
          active: s3Active,
        ),
      ],
    );
  }

  Widget _chip(
    String label, {
    required bool selected,
    bool disabled = false,
    bool dashed = false,
    VoidCallback? onTap,
  }) {
    final colors = context.appColors;
    final sel = SalesPlanColors.selection(context);
    // Each option is its own bordered tile (never share a panel background).
    final borderColor = selected
        ? sel
        : colors.textSecondary.withValues(alpha: 0.55);
    final fill = selected
        ? SalesPlanColors.selectionBg(context)
        : colors.surfaceElevated;
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dashed
                    ? colors.textSecondary.withValues(alpha: 0.4)
                    : borderColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? sel : colors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: context.appColors.textSecondary,
          ),
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary.withValues(alpha: 0.82),
          ),
        ),
      );

  InputDecoration _inputDecoration({String? hint}) {
    final colors = context.appColors;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.85)),
      filled: true,
      fillColor: colors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colors.textSecondary.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.success, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
