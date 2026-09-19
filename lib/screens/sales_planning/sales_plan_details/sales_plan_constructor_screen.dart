import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_filter_field.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_filter_field_loader.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _ConstructorFilter {
  String key;
  String field;
  String value;
  String label;
  int? customFieldId;
  int? directoryId;

  _ConstructorFilter({
    required this.key,
    required this.field,
    required this.value,
    required this.label,
    this.customFieldId,
    this.directoryId,
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
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  SalesPlanObjectType? _object;
  SalesPlanAggregation? _aggregation;
  String? _field;
  final List<_ConstructorFilter> _filters = [];

  SalesPlanPeriodType _periodType = SalesPlanPeriodType.month;
  SalesPlanRecurrence _recurrence = SalesPlanRecurrence.monthly;
  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  final Set<int> _selectedUserIds = {};
  bool _saving = false;
  bool _nameTouched = false;
  late final SalesPlanFilterFieldLoader _filterLoader;
  List<SalesPlanFilterField> _filterFields = [];
  bool _filterFieldsLoading = false;
  final Map<String, List<SalesPlanFilterOption>> _filterOptions = {};
  final Set<String> _loadingFilterKeys = {};

  // Даты в том же формате, что у полей дедлайна в задачах.
  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  DateTime? _parseDate(String text) {
    try {
      return DateFormat('dd/MM/yyyy').parse(text);
    } catch (_) {
      return null;
    }
  }

  void _syncDateFields() {
    _startDateController.text = _formatDate(_periodStart);
    _endDateController.text = _formatDate(_periodEnd);
  }

  bool get _isEdit => widget.planId != null;

  @override
  void initState() {
    super.initState();
    _filterLoader = SalesPlanFilterFieldLoader(_api);
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
          key: f.field,
          field: f.field,
          value: f.value,
          label: f.field,
          customFieldId: f.customFieldId,
          directoryId: f.directoryId,
        ));
      }
    }
    _syncDateFields();
    if (_object != null) {
      _filterFieldsLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _object == null) return;
        _loadFilterFields(_object!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _commentController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  SalesPlanFilterField? _fieldByKey(String key) {
    for (final field in _filterFields) {
      if (field.key == key) return field;
    }
    return null;
  }

  List<SalesPlanFilterOption> _optionsFor(SalesPlanFilterField field, String current) {
    final options = List<SalesPlanFilterOption>.from(
      _filterOptions[field.key] ?? field.presetOptions,
    );
    if (current.isNotEmpty && !options.any((o) => o.value == current)) {
      options.insert(
        0,
        SalesPlanFilterOption(value: current, label: current),
      );
    }
    return options;
  }

  Future<void> _loadFilterFields(SalesPlanObjectType object) async {
    setState(() {
      _filterFieldsLoading = true;
      _filterFields = [];
      _filterOptions.clear();
      _loadingFilterKeys.clear();
    });
    final fields = await _filterLoader.load(object);
    if (!mounted || _object != object) return;
    setState(() {
      _filterFields = fields;
      _filterFieldsLoading = false;
      _syncExistingFilters();
    });
    for (final filter in _filters) {
      final field = _fieldByKey(filter.key);
      if (field != null) {
        _ensureFilterOptions(field);
      }
    }
  }

  void _syncExistingFilters() {
    final t = AppLocalizations.of(context)!;
    for (final filter in _filters) {
      SalesPlanFilterField? match;
      for (final field in _filterFields) {
        final sameCustom = field.customFieldId != null &&
            field.customFieldId == filter.customFieldId;
        final sameDirectory = field.directoryId != null &&
            field.directoryId == filter.directoryId;
        if (sameCustom || sameDirectory || field.field == filter.field) {
          match = field;
          break;
        }
      }
      if (match == null) continue;
      filter.key = match.key;
      filter.field = match.field;
      filter.label = match.displayLabel(t);
      filter.customFieldId = match.customFieldId;
      filter.directoryId = match.directoryId;
    }
  }

  Future<void> _ensureFilterOptions(SalesPlanFilterField field) async {
    if (_object == null) return;
    if (field.inputType != SalesPlanFilterInputType.select) return;
    if (_filterOptions.containsKey(field.key) ||
        _loadingFilterKeys.contains(field.key)) {
      return;
    }
    if (field.presetOptions.isNotEmpty) {
      _filterOptions[field.key] = field.presetOptions;
      return;
    }
    _loadingFilterKeys.add(field.key);
    final options = await _filterLoader.loadOptions(
      object: _object!,
      field: field,
    );
    if (!mounted) return;
    setState(() {
      _filterOptions[field.key] = options;
      _loadingFilterKeys.remove(field.key);
    });
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
    _loadFilterFields(object);
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
    final used = _filters.map((f) => f.key).toSet();
    final avail =
        _filterFields.where((field) => !used.contains(field.key)).toList();
    if (avail.isEmpty) return;
    final field = avail.first;
    final t = AppLocalizations.of(context)!;
    setState(() {
      _filters.add(_ConstructorFilter(
        key: field.key,
        field: field.field,
        value: '',
        label: field.displayLabel(t),
        customFieldId: field.customFieldId,
        directoryId: field.directoryId,
      ));
    });
    _ensureFilterOptions(field);
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
    final start = _parseDate(_startDateController.text) ?? _periodStart;
    final end = _parseDate(_endDateController.text) ?? _periodEnd;
    _periodStart = start;
    _periodEnd = end;

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
          .where((f) => f.value.trim().isNotEmpty)
          .map((f) => SalesPlanFilterItem(
                field: f.field,
                value: f.value,
                customFieldId: f.customFieldId,
                directoryId: f.directoryId,
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
      _filterFields = [];
      _filterOptions.clear();
      _loadingFilterKeys.clear();
      _filterFieldsLoading = false;
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
      _syncDateFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final numeric = _object == null
        ? <String>[]
        : SalesPlanLabels.numericFieldsFor(_object!);
    final filterDefs = _filterFields;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        foregroundColor: colors.textPrimary,
        title: Text(t.translate('sales_planning')),
      ),
      body: Column(
          children: [
            Expanded(
              child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
              if (_filterFieldsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (filterDefs.isEmpty)
                Text(
                  t.translate('sp_no_filters'),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                )
              else ...[
                ..._filters.asMap().entries.map((entry) {
                  return _buildFilterRow(entry.key, entry.value, t);
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceAccent,
                  borderRadius: AppFieldStyle.radius,
                  border: Border.all(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translate('sp_indicator'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                        color: colors.buttonPrimaryBg,
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
            const SizedBox(height: 16),
            Divider(color: colors.borderSubtle.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            // Поля как в создании задачи: CustomTextField + мультиселект.
            CustomTextField(
              controller: _nameController,
              label: t.translate('sp_name'),
              hintText: t.translate('sp_name_hint'),
              onChanged: (_) => _nameTouched = true,
            ),
            const SizedBox(height: 12),
            Text(
              t.translate('sp_filter_type'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colors.fieldBg,
                borderRadius: AppFieldStyle.radius,
                border: AppFieldStyle.dropdownBorder(context),
              ),
              child: Text(
                _aggReady
                    ? SalesPlanLabels.planType(context, _autoType)
                    : t.translate('sp_type_auto'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 15,
                  color: _aggReady ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _valueController,
              label: t.translate('sp_target'),
              hintText: '500000',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            UserMultiSelectWidget(
              selectedUsers:
                  _selectedUserIds.map((id) => id.toString()).toList(),
              customLabelText: t.translate('sp_owners'),
              hintText: t.translate('sp_select_owners'),
              isRequired: true,
              onSelectUsers: (List<UserData> users) {
                setState(() {
                  _selectedUserIds
                    ..clear()
                    ..addAll(users.map((user) => user.id));
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              t.translate('sp_period'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<SalesPlanPeriodType>(
              value: _periodType,
              isExpanded: true,
              decoration: _inputDecoration(),
              items: SalesPlanPeriodType.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          SalesPlanLabels.periodType(context, p),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            color: colors.textPrimary,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final range = _defaultRangeFor(v);
                setState(() {
                  _periodType = v;
                  _periodStart = range.start;
                  _periodEnd = range.end;
                  _syncDateFields();
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextFieldDate(
                    controller: _startDateController,
                    label: t.translate('sp_period_from'),
                    onDateSelected: (value) {
                      final parsed = _parseDate(value);
                      if (parsed != null) {
                        setState(() => _periodStart = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextFieldDate(
                    controller: _endDateController,
                    label: t.translate('sp_period_to'),
                    onDateSelected: (value) {
                      final parsed = _parseDate(value);
                      if (parsed != null) {
                        setState(() => _periodEnd = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t.translate('sp_recurrence'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<SalesPlanRecurrence>(
              value: _recurrence,
              isExpanded: true,
              decoration: _inputDecoration(),
              items: SalesPlanRecurrence.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          SalesPlanLabels.recurrence(context, r),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            color: colors.textPrimary,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _recurrence = v);
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _commentController,
              label: t.translate('sp_comment'),
              hintText: t.translate('sp_comment'),
              maxLines: 3,
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
    );
  }

  Widget _buildFilterRow(
    int idx,
    _ConstructorFilter filter,
    AppLocalizations t,
  ) {
    final field = _fieldByKey(filter.key);
    final seen = <String>{};
    final fieldItems = <SalesPlanFilterField>[];
    for (final item in _filterFields) {
      if (seen.add(item.key)) fieldItems.add(item);
    }
    if (field == null && seen.add(filter.key)) {
      fieldItems.insert(
        0,
        SalesPlanFilterField(
          key: filter.key,
          field: filter.field,
          label: filter.label,
          inputType: SalesPlanFilterInputType.text,
          customFieldId: filter.customFieldId,
          directoryId: filter.directoryId,
        ),
      );
    }
    if (fieldItems.isEmpty) return const SizedBox.shrink();
    final selectedKey = fieldItems.any((item) => item.key == filter.key)
        ? filter.key
        : fieldItems.first.key;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedKey,
                  isExpanded: true,
                  decoration: _inputDecoration(),
                  items: fieldItems.map((item) {
                    final used = _filters.any(
                      (other) => other.key == item.key && other != filter,
                    );
                    return DropdownMenuItem(
                      value: item.key,
                      enabled: !used,
                      child: Text(
                        item.displayLabel(t),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (key) {
                    if (key == null) return;
                    final next = fieldItems.firstWhere((item) => item.key == key);
                    setState(() {
                      _filters[idx] = _ConstructorFilter(
                        key: next.key,
                        field: next.field,
                        value: '',
                        label: next.displayLabel(t),
                        customFieldId: next.customFieldId,
                        directoryId: next.directoryId,
                      );
                    });
                    _ensureFilterOptions(next);
                  },
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _filters.removeAt(idx)),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFilterValue(filter, field ?? fieldItems.first, t),
        ],
      ),
    );
  }

  Widget _buildFilterValue(
    _ConstructorFilter filter,
    SalesPlanFilterField field,
    AppLocalizations t,
  ) {
    if (field.inputType == SalesPlanFilterInputType.date) {
      final display = _dateValueForUi(filter.value);
      return InkWell(
        onTap: () => _pickFilterDate(filter),
        child: InputDecorator(
          decoration: _inputDecoration(hint: t.translate('select_date')),
          child: Text(
            display.isEmpty ? t.translate('select_date') : display,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              color: display.isEmpty
                  ? context.appColors.textSecondary
                  : context.appColors.textPrimary,
            ),
          ),
        ),
      );
    }

    final options = _optionsFor(field, filter.value);
    final loading = _loadingFilterKeys.contains(field.key);
    if (field.inputType == SalesPlanFilterInputType.select &&
        (loading || options.isNotEmpty)) {
      if (loading && options.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(minHeight: 2),
        );
      }
      final value = options.any((o) => o.value == filter.value)
          ? filter.value
          : (filter.value.isEmpty ? null : filter.value);
      return DropdownButtonFormField<String>(
        value: value != null && options.any((o) => o.value == value)
            ? value
            : null,
        isExpanded: true,
        decoration: _inputDecoration(),
        items: options
            .map((option) => DropdownMenuItem(
                  value: option.value,
                  child: Text(
                    SalesPlanLabels.filterOptionLabel(context, option.label),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (next) {
          if (next == null) return;
          setState(() => filter.value = next);
        },
      );
    }

    return TextFormField(
      key: ValueKey('filter_value_${filter.key}'),
      initialValue: filter.value,
      keyboardType: field.inputType == SalesPlanFilterInputType.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _inputDecoration(),
      onChanged: (next) => filter.value = next,
    );
  }

  Future<void> _pickFilterDate(_ConstructorFilter filter) async {
    DateTime initial = DateTime.now();
    if (filter.value.isNotEmpty) {
      try {
        initial = DateTime.parse(filter.value);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked == null || !mounted) return;
    setState(() {
      filter.value = DateFormat('yyyy-MM-dd').format(picked);
    });
  }

  String _dateValueForUi(String apiDate) {
    if (apiDate.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(apiDate));
    } catch (_) {
      return apiDate;
    }
  }

  Widget _steps(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;
    final s1Done = _object != null;
    final s2Done = _aggReady;
    final s3Active = _aggReady;

    Widget step(int n, String title, String sub, {bool active = false, bool done = false}) {
      final accent = colors.buttonPrimaryBg;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.12)
                : colors.fieldBg,
            borderRadius: AppFieldStyle.radius,
            border: Border.all(
              color: active
                  ? accent
                  : done
                      ? colors.success.withValues(alpha: 0.45)
                      : colors.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? accent
                      : done
                          ? colors.success.withValues(alpha: 0.2)
                          : colors.surfaceElevated,
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                    color: active
                        ? colors.buttonPrimaryFg
                        : done
                            ? colors.success
                            : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Gilroy',
                  color: active ? accent : colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
    final sel = colors.buttonPrimaryBg;
    // Компактные чипы как в остальных мобильных формах.
    final borderColor = selected ? sel : colors.borderSubtle;
    final fill = selected
        ? sel.withValues(alpha: 0.14)
        : colors.fieldBg;
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: AppFieldStyle.radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: AppFieldStyle.radius,
              border: Border.all(
                color: dashed
                    ? colors.textSecondary.withValues(alpha: 0.4)
                    : borderColor,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Gilroy',
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
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: context.appColors.textPrimary,
          ),
        ),
      );

  InputDecoration _inputDecoration({String? hint}) {
    final colors = context.appColors;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Gilroy',
        color: colors.fieldHint,
      ),
      filled: true,
      fillColor: colors.fieldBg,
      border: AppFieldStyle.outline(context),
      enabledBorder: AppFieldStyle.outline(context),
      focusedBorder: AppFieldStyle.outline(context, focused: true),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
