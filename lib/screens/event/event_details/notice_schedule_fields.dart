import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Дата напоминания и интервал «Время от / Время до», как в форме веба.
class NoticeScheduleFields extends StatefulWidget {
  final TextEditingController dateController;
  final String? initialTimeFrom;
  final String? initialTimeTo;
  final ValueChanged<String?> onTimeFromChanged;
  final ValueChanged<String?> onTimeToChanged;

  const NoticeScheduleFields({
    super.key,
    required this.dateController,
    this.initialTimeFrom,
    this.initialTimeTo,
    required this.onTimeFromChanged,
    required this.onTimeToChanged,
  });

  @override
  State<NoticeScheduleFields> createState() => _NoticeScheduleFieldsState();
}

class _NoticeScheduleFieldsState extends State<NoticeScheduleFields> {
  TimeOfDay? _timeFrom;
  TimeOfDay? _timeTo;

  @override
  void initState() {
    super.initState();
    _timeFrom = _parseClock(widget.initialTimeFrom);
    _timeTo = _parseClock(widget.initialTimeTo);
    widget.dateController.addListener(_onDateEdited);
  }

  @override
  void dispose() {
    widget.dateController.removeListener(_onDateEdited);
    super.dispose();
  }

  void _onDateEdited() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quick = _quickDay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextFieldDate(
          controller: widget.dateController,
          label: l10n.translate('reminder_date'),
          withTime: false,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _QuickDay(
              label: l10n.translate('today'),
              checked: quick == 0,
              onChanged: (value) => _applyQuick(0, value),
            ),
            const SizedBox(width: 8),
            _QuickDay(
              label: l10n.translate('event_tomorrow'),
              checked: quick == 1,
              onChanged: (value) => _applyQuick(1, value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: l10n.translate('time_from'),
                value: _timeFrom,
                onPick: (time) {
                  setState(() => _timeFrom = time);
                  widget.onTimeFromChanged(_formatClock(time));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: l10n.translate('time_to'),
                value: _timeTo,
                onPick: (time) {
                  setState(() => _timeTo = time);
                  widget.onTimeToChanged(_formatClock(time));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 0 — сегодня, 1 — завтра, null — другая дата или пусто.
  int? _quickDay() {
    final text = widget.dateController.text.trim();
    if (text.isEmpty) return null;
    DateTime? picked;
    try {
      picked = DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      return null;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(picked.year, picked.month, picked.day);
    final diff = day.difference(today).inDays;
    if (diff == 0 || diff == 1) return diff;
    return null;
  }

  void _applyQuick(int offset, bool checked) {
    if (!checked) return;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
    widget.dateController.text = DateFormat('dd/MM/yyyy').format(day);
    setState(() {});
  }
}

class _QuickDay extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _QuickDay({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: checked,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: colors.success,
            side: BorderSide(color: colors.borderPrimary),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onPick;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = _formatClock(value) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.appTextStyles.labelLg.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: colors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pick(context),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text.isEmpty ? '--:--' : text,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: text.isEmpty
                            ? colors.fieldHint
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  if (value != null)
                    GestureDetector(
                      onTap: () => onPick(null),
                      child: Icon(Icons.close, size: 18, color: colors.textMuted),
                    ),
                  const SizedBox(width: 6),
                  Icon(Icons.access_time, size: 18, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final colors = context.appColors;
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: colors.buttonPrimaryBg,
                    onPrimary: colors.buttonPrimaryFg,
                    surface: colors.surfacePrimary,
                    onSurface: colors.textPrimary,
                  ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
    if (picked != null) onPick(picked);
  }
}

TimeOfDay? _parseClock(String? value) {
  final text = value?.trim() ?? '';
  final parts = text.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String? _formatClock(TimeOfDay? time) {
  if (time == null) return null;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Строка как на вебе: «02.10.2026 От 14:36 До 15:06».
String formatNoticeSchedule(
  DateTime? date,
  String? timeFrom,
  String? timeTo, {
  required String fromLabel,
  required String toLabel,
}) {
  if (date == null) return '';
  final local = date.toLocal();
  final day = DateFormat('dd.MM.yyyy').format(local);
  final from = (timeFrom ?? '').trim();
  final to = (timeTo ?? '').trim();
  if (from.isNotEmpty && to.isNotEmpty) {
    return '$day $fromLabel $from $toLabel $to';
  }
  if (from.isNotEmpty) return '$day $fromLabel $from';
  if (to.isNotEmpty) return '$day $toLabel $to';
  if (local.hour == 0 && local.minute == 0) return day;
  return DateFormat('dd.MM.yyyy HH:mm').format(local);
}
