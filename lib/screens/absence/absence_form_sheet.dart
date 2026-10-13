import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/screens/absence/absence_logic.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

/// Новая заявка и изменение. Закрытие с правками спрашивает подтверждение.
class AbsenceFormSheet extends StatefulWidget {
  const AbsenceFormSheet({
    super.key,
    required this.onSubmit,
    this.initial,
  });

  final AbsenceRequest? initial;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  @override
  State<AbsenceFormSheet> createState() => _AbsenceFormSheetState();
}

class _AbsenceFormSheetState extends State<AbsenceFormSheet> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _timeFrom;
  String? _timeTo;
  late final TextEditingController _reason;
  AbsenceFormErrors _errors = const AbsenceFormErrors();
  bool _saving = false;
  bool _forcePop = false;
  late final AbsenceDraft _initialDraft;

  bool get _editing => widget.initial != null;

  bool get _timesFilled =>
      (_timeFrom?.isNotEmpty ?? false) && (_timeTo?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    final request = widget.initial;
    _dateFrom = request?.dateFrom;
    _dateTo = request?.dateTo;
    _timeFrom = request?.timeFrom;
    _timeTo = request?.timeTo;
    _reason = TextEditingController(text: request?.reason ?? '');
    _initialDraft = _draft();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  AbsenceDraft _draft() {
    return AbsenceDraft(
      dateFrom: _dateFrom,
      dateTo: _timesFilled ? _dateFrom : _dateTo,
      timeFrom: _timeFrom,
      timeTo: _timeTo,
      reason: _reason.text,
    );
  }

  bool get _dirty => !_draft().sameAs(_initialDraft);

  Future<void> _close() async {
    if (!_dirty) {
      _popSheet();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          absenceTr(context, 'absence_discard'),
          style: absenceStyle(context, size: 18, weight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(absenceTr(context, 'absence_stay')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(absenceTr(context, 'absence_leave')),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _popSheet();
  }

  void _popSheet() {
    setState(() => _forcePop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _pickDate({required bool from}) async {
    final today = dateOnly(DateTime.now());
    final current = from ? _dateFrom : _dateTo;
    final earliest = _editing ? DateTime(2020) : today;
    final first = from ? earliest : (_dateFrom ?? earliest);
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null || current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: DateTime(today.year + 3, 12, 31),
      builder: (context, child) =>
          Theme(data: absencePickerTheme(context), child: child ?? const SizedBox.shrink()),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (from) {
        _dateFrom = dateOnly(picked);
        if (_dateTo != null && _dateTo!.isBefore(_dateFrom!)) {
          _dateTo = _dateFrom;
        }
      } else {
        _dateTo = dateOnly(picked);
      }
    });
  }

  Future<void> _submit() async {
    final errors = validateAbsenceDraft(
      _draft(),
      today: DateTime.now(),
      allowPast: _editing,
    );
    if (!errors.isEmpty) {
      setState(() => _errors = errors);
      return;
    }
    setState(() {
      _saving = true;
      _errors = const AbsenceFormErrors();
    });
    try {
      await widget.onSubmit(absenceRequestBody(_draft()));
      if (!mounted) return;
      setState(() => _forcePop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errors = AbsenceFormErrors(error.fieldErrors);
      });
      if (error.fieldErrors.isEmpty && error.message.isNotEmpty) {
        showCustomSnackBar(
          context: context,
          message: error.message,
          isSuccess: false,
          aboveDialogs: true,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasonError = _errors['reason'];
    return PopScope(
      canPop: _forcePop || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        _close();
      },
      child: Column(
        children: [
          AbsenceSheetHeader(
            title: absenceTr(
              context,
              _editing ? 'absence_edit' : 'absence_new',
            ),
            onClose: _saving ? null : _close,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              children: [
                AbsenceTapField(
                  label: absenceTr(context, 'absence_date_from'),
                  value: _dateFrom == null ? '' : formatAbsenceDisplayDate(_dateFrom!),
                  error: _translated(_errors['date_from']),
                  onTap: _saving ? null : () => _pickDate(from: true),
                ),
                if (!_timesFilled) ...[
                  const SizedBox(height: 12),
                  AbsenceTapField(
                    label: absenceTr(context, 'absence_date_to'),
                    value: _dateTo == null ? '' : formatAbsenceDisplayDate(_dateTo!),
                    error: _translated(_errors['date_to']),
                    onTap: _saving ? null : () => _pickDate(from: false),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _timeField(from: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _timeField(from: false)),
                  ],
                ),
                const SizedBox(height: 12),
                AbsenceFieldLabel(absenceTr(context, 'absence_reason')),
                TextField(
                  controller: _reason,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 5000,
                  onChanged: (_) => setState(() {}),
                  style: absenceStyle(context, size: 16),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: context.appColors.fieldBg,
                    errorText: _translated(reasonError),
                    errorStyle: AppFieldStyle.errorTextStyle(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: AppFieldStyle.outline(context, hasError: reasonError != null),
                    enabledBorder: AppFieldStyle.outline(context, hasError: reasonError != null),
                    focusedBorder: AppFieldStyle.outline(context, focused: true),
                  ),
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) {
                    if (currentLength < 4500 || maxLength == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '$currentLength / $maxLength',
                      style: absenceStyle(context, size: 12),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: absencePrimaryButton(
              context: context,
              label: absenceTr(
                context,
                _editing ? 'absence_save_changes' : 'absence_send',
              ),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.appColors.textInverse,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeField({required bool from}) {
    final value = from ? _timeFrom : _timeTo;
    final error = from ? _errors['time_from'] : _errors['time_to'];
    return AbsenceTapField(
      label: absenceTr(context, from ? 'absence_time_from' : 'absence_time_to'),
      value: value ?? '',
      error: _translated(error),
      onClear: value == null || _saving
          ? null
          : () => setState(() {
                if (from) {
                  _timeFrom = null;
                } else {
                  _timeTo = null;
                }
              }),
      onTap: _saving ? null : () => _pickTime(from: from),
    );
  }

  Future<void> _pickTime({required bool from}) async {
    final current = from ? _timeFrom : _timeTo;
    final parts = (current ?? '09:00').split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 0,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
      builder: (context, child) =>
          Theme(data: absencePickerTheme(context), child: child ?? const SizedBox.shrink()),
    );
    if (picked == null || !mounted) return;
    final text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (from) {
        _timeFrom = text;
      } else {
        _timeTo = text;
      }
    });
  }

  String? _translated(String? key) {
    if (key == null || key.isEmpty) return null;
    return absenceTr(context, key);
  }
}
