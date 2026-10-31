import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Item representing a day of the week in the working schedule.
class DayScheduleItem {
  final int dayIndex; // 1 = Monday .. 7 = Sunday
  final String shortName; // Пн, Вт, ...
  final String fullName; // Понедельник, ...
  bool isWorking;
  TimeOfDay timeFrom;
  TimeOfDay timeTo;

  DayScheduleItem({
    required this.dayIndex,
    required this.shortName,
    required this.fullName,
    required this.isWorking,
    required this.timeFrom,
    required this.timeTo,
  });

  DayScheduleItem copyWith({
    bool? isWorking,
    TimeOfDay? timeFrom,
    TimeOfDay? timeTo,
  }) {
    return DayScheduleItem(
      dayIndex: dayIndex,
      shortName: shortName,
      fullName: fullName,
      isWorking: isWorking ?? this.isWorking,
      timeFrom: timeFrom ?? this.timeFrom,
      timeTo: timeTo ?? this.timeTo,
    );
  }
}

/// Helper that generates standard 7 days of the week.
List<DayScheduleItem> createDefaultDays({
  TimeOfDay defaultFrom = const TimeOfDay(hour: 9, minute: 0),
  TimeOfDay defaultTo = const TimeOfDay(hour: 18, minute: 0),
  bool weekendsOff = true,
}) {
  return [
    DayScheduleItem(
      dayIndex: 1,
      shortName: 'Пн',
      fullName: 'Понедельник',
      isWorking: true,
      timeFrom: defaultFrom,
      timeTo: defaultTo,
    ),
    DayScheduleItem(
      dayIndex: 2,
      shortName: 'Вт',
      fullName: 'Вторник',
      isWorking: true,
      timeFrom: defaultFrom,
      timeTo: defaultTo,
    ),
    DayScheduleItem(
      dayIndex: 3,
      shortName: 'Ср',
      fullName: 'Среда',
      isWorking: true,
      timeFrom: defaultFrom,
      timeTo: defaultTo,
    ),
    DayScheduleItem(
      dayIndex: 4,
      shortName: 'Чт',
      fullName: 'Четверг',
      isWorking: true,
      timeFrom: defaultFrom,
      timeTo: defaultTo,
    ),
    DayScheduleItem(
      dayIndex: 5,
      shortName: 'Пт',
      fullName: 'Пятница',
      isWorking: true,
      timeFrom: defaultFrom,
      timeTo: defaultTo,
    ),
    DayScheduleItem(
      dayIndex: 6,
      shortName: 'Сб',
      fullName: 'Суббота',
      isWorking: !weekendsOff,
      timeFrom: defaultFrom,
      timeTo: defaultTo,
    ),
    DayScheduleItem(
      dayIndex: 7,
      shortName: 'Вс',
      fullName: 'Воскресенье',
      isWorking: false,
      timeFrom: defaultFrom,
      timeTo: defaultTo,
    ),
  ];
}

/// Formats a list of [DayScheduleItem] into a human-readable summary string:
/// e.g. "Пн–Пт: 09:00 – 18:00" or "Пн–Пт: 09:00 – 18:00, Сб: 10:00 – 16:00"
String formatScheduleSummary(List<DayScheduleItem> days) {
  final workingDays = days.where((d) => d.isWorking).toList();
  if (workingDays.isEmpty) return 'Выходной';

  String fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // 1. If all 7 days working with same hours
  if (workingDays.length == 7) {
    final first = workingDays.first;
    final allSame = workingDays.every(
        (d) => d.timeFrom == first.timeFrom && d.timeTo == first.timeTo);
    if (allSame) {
      return 'Пн–Вс: ${fmt(first.timeFrom)} – ${fmt(first.timeTo)}';
    }
  }

  // 2. If weekdays 1..5 working with same hours and 6,7 off
  final isWeekdaysOnly = workingDays.length == 5 &&
      workingDays.every((d) => d.dayIndex >= 1 && d.dayIndex <= 5);
  if (isWeekdaysOnly) {
    final first = workingDays.first;
    final allSame = workingDays.every(
        (d) => d.timeFrom == first.timeFrom && d.timeTo == first.timeTo);
    if (allSame) {
      return 'Пн–Пт: ${fmt(first.timeFrom)} – ${fmt(first.timeTo)}';
    }
  }

  // 3. Group consecutive days with same hours
  final chunks = <List<DayScheduleItem>>[];
  for (final day in days) {
    if (!day.isWorking) continue;
    if (chunks.isEmpty) {
      chunks.add([day]);
    } else {
      final lastChunk = chunks.last;
      final prev = lastChunk.last;
      final sameHours =
          prev.timeFrom == day.timeFrom && prev.timeTo == day.timeTo;
      final consecutive = day.dayIndex == prev.dayIndex + 1;
      if (sameHours && consecutive) {
        lastChunk.add(day);
      } else {
        chunks.add([day]);
      }
    }
  }

  final parts = chunks.map((chunk) {
    final hours =
        '${fmt(chunk.first.timeFrom)} – ${fmt(chunk.first.timeTo)}';
    if (chunk.length == 1) {
      return '${chunk.first.shortName}: $hours';
    } else {
      return '${chunk.first.shortName}–${chunk.last.shortName}: $hours';
    }
  }).toList();

  return parts.join(', ');
}

/// Interactive Working Hours Schedule Selector Widget.
class WorkScheduleSelector extends StatefulWidget {
  final List<DayScheduleItem>? initialDays;
  final TimeOfDay initialTimeFrom;
  final TimeOfDay initialTimeTo;
  final void Function(
    String summary,
    TimeOfDay startTime,
    TimeOfDay endTime,
    List<DayScheduleItem> days,
  ) onChanged;

  const WorkScheduleSelector({
    super.key,
    this.initialDays,
    this.initialTimeFrom = const TimeOfDay(hour: 9, minute: 0),
    this.initialTimeTo = const TimeOfDay(hour: 18, minute: 0),
    required this.onChanged,
  });

  /// Opens a modal bottom sheet allowing the user to configure the schedule.
  static Future<String?> showPickerBottomSheet({
    required BuildContext context,
    String? currentSchedule,
  }) async {
    final colors = context.appColors;
    String selectedSummary = currentSchedule ?? 'Пн–Пт: 09:00 – 18:00';

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: WorkScheduleSelector(
                  onChanged: (summary, startTime, endTime, days) {
                    selectedSummary = summary;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selectedSummary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.buttonPrimaryFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Применить',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<WorkScheduleSelector> createState() => _WorkScheduleSelectorState();
}

class _WorkScheduleSelectorState extends State<WorkScheduleSelector> {
  late List<DayScheduleItem> _days;
  late TimeOfDay _commonTimeFrom;
  late TimeOfDay _commonTimeTo;
  bool _applyToAllDays = true;
  bool _perDayExpanded = false;

  @override
  void initState() {
    super.initState();
    _commonTimeFrom = widget.initialTimeFrom;
    _commonTimeTo = widget.initialTimeTo;
    _days = widget.initialDays != null && widget.initialDays!.isNotEmpty
        ? widget.initialDays!.map((d) => d.copyWith()).toList()
        : createDefaultDays(
            defaultFrom: _commonTimeFrom,
            defaultTo: _commonTimeTo,
            weekendsOff: true,
          );

    // Initial sync
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChange());
  }

  void _notifyChange() {
    final summary = formatScheduleSummary(_days);
    final firstWorking = _days.firstWhere(
      (d) => d.isWorking,
      orElse: () => _days.first,
    );
    widget.onChanged(
      summary,
      firstWorking.timeFrom,
      firstWorking.timeTo,
      _days,
    );
  }

  void _toggleWeekdaysOnly() {
    setState(() {
      for (final day in _days) {
        day.isWorking = day.dayIndex >= 1 && day.dayIndex <= 5;
        if (_applyToAllDays && day.isWorking) {
          day.timeFrom = _commonTimeFrom;
          day.timeTo = _commonTimeTo;
        }
      }
    });
    _notifyChange();
  }

  void _toggleAllDays() {
    setState(() {
      for (final day in _days) {
        day.isWorking = true;
        if (_applyToAllDays) {
          day.timeFrom = _commonTimeFrom;
          day.timeTo = _commonTimeTo;
        }
      }
    });
    _notifyChange();
  }

  void _toggleDay(DayScheduleItem day) {
    setState(() {
      day.isWorking = !day.isWorking;
      if (day.isWorking && _applyToAllDays) {
        day.timeFrom = _commonTimeFrom;
        day.timeTo = _commonTimeTo;
      }
    });
    _notifyChange();
  }

  void _onCommonTimePicked({TimeOfDay? from, TimeOfDay? to}) {
    setState(() {
      if (from != null) _commonTimeFrom = from;
      if (to != null) _commonTimeTo = to;

      if (_applyToAllDays) {
        for (final day in _days) {
          if (day.isWorking) {
            if (from != null) day.timeFrom = from;
            if (to != null) day.timeTo = to;
          }
        }
      }
    });
    _notifyChange();
  }

  void _applyCommonToAll() {
    setState(() {
      for (final day in _days) {
        if (day.isWorking) {
          day.timeFrom = _commonTimeFrom;
          day.timeTo = _commonTimeTo;
        }
      }
      _applyToAllDays = true;
    });
    _notifyChange();
  }

  bool get _isWeekdaysSelected {
    final working = _days.where((d) => d.isWorking).toList();
    return working.length == 5 &&
        working.every((d) => d.dayIndex >= 1 && d.dayIndex <= 5);
  }

  bool get _isAllDaysSelected {
    return _days.every((d) => d.isWorking);
  }

  String _formatClock(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime({
    required BuildContext context,
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final colors = context.appColors;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
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
    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final summary = formatScheduleSummary(_days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header: Title & Live Summary ─────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Режим работы',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: colors.buttonPrimaryBg,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                        color: colors.buttonPrimaryBg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Quick Preset Chips (По будням, Все дни) ──────────────────────
        Row(
          children: [
            _buildPresetChip(
              label: 'По будням',
              icon: Icons.calendar_today_rounded,
              isSelected: _isWeekdaysSelected,
              onTap: _toggleWeekdaysOnly,
            ),
            const SizedBox(width: 8),
            _buildPresetChip(
              label: 'Все дни',
              icon: Icons.date_range_rounded,
              isSelected: _isAllDaysSelected,
              onTap: _toggleAllDays,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 7 Day Circle Buttons (Пн .. Вс) ─────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _days.map((day) {
            final isWeekend = day.dayIndex == 6 || day.dayIndex == 7;
            final isSelected = day.isWorking;

            return InkWell(
              onTap: () => _toggleDay(day),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.buttonPrimaryBg
                      : colors.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colors.buttonPrimaryBg
                        : (isWeekend
                            ? colors.error.withValues(alpha: 0.3)
                            : colors.borderSubtle),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.buttonPrimaryBg.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.shortName,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? colors.buttonPrimaryFg
                          : (isWeekend ? colors.error : colors.textPrimary),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // ── Apply to all days Checkbox ───────────────────────────────────
        InkWell(
          onTap: () {
            setState(() {
              _applyToAllDays = !_applyToAllDays;
              if (_applyToAllDays) {
                _applyCommonToAll();
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _applyToAllDays,
                    activeColor: colors.buttonPrimaryBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _applyToAllDays = val ?? false;
                        if (_applyToAllDays) {
                          _applyCommonToAll();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Применить время ко всем выбранным дням',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Common Time Pickers (От / До) ────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: colors.iconSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _applyToAllDays
                        ? 'Время работы (для всех дней)'
                        : 'Основное время',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeBox(
                      context: context,
                      label: 'Время от',
                      time: _commonTimeFrom,
                      onTap: () => _pickTime(
                        context: context,
                        initial: _commonTimeFrom,
                        onPicked: (val) => _onCommonTimePicked(from: val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeBox(
                      context: context,
                      label: 'Время до',
                      time: _commonTimeTo,
                      onTap: () => _pickTime(
                        context: context,
                        initial: _commonTimeTo,
                        onPicked: (val) => _onCommonTimePicked(to: val),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Expandable: Per-day individual time ──────────────────────────
        InkWell(
          onTap: () => setState(() => _perDayExpanded = !_perDayExpanded),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              children: [
                Icon(
                  _perDayExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: colors.buttonPrimaryBg,
                ),
                const SizedBox(width: 6),
                Text(
                  _perDayExpanded
                      ? 'Скрыть настройку по отдельным дням'
                      : 'Настроить каждый день отдельно',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: colors.buttonPrimaryBg,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_perDayExpanded) ...[
          const SizedBox(height: 8),
          Column(
            children: _days.map((day) => _buildPerDayRow(context, day)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonPrimaryBg.withValues(alpha: 0.15)
              : colors.fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : icon,
              size: 16,
              color: isSelected ? colors.buttonPrimaryBg : colors.iconSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.buttonPrimaryBg : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required BuildContext context,
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    final timeStr = _formatClock(time);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: colors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: colors.iconSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerDayRow(BuildContext context, DayScheduleItem day) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: day.isWorking
            ? colors.surfaceElevated
            : colors.fieldBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: day.isWorking
              ? colors.borderSubtle
              : colors.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header with Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: day.isWorking
                          ? colors.buttonPrimaryBg
                          : colors.fieldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: day.isWorking
                            ? colors.buttonPrimaryBg
                            : colors.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        day.shortName,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: day.isWorking
                              ? colors.buttonPrimaryFg
                              : colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    day.fullName,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: day.isWorking
                          ? colors.textPrimary
                          : colors.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    day.isWorking ? 'Рабочий' : 'Выходной',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: day.isWorking
                          ? colors.buttonPrimaryBg
                          : colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: day.isWorking,
                    activeThumbColor: colors.buttonPrimaryBg,
                    activeTrackColor: colors.buttonPrimaryBg.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() {
                        day.isWorking = val;
                        if (val && _applyToAllDays) {
                          day.timeFrom = _commonTimeFrom;
                          day.timeTo = _commonTimeTo;
                        }
                      });
                      _notifyChange();
                    },
                  ),
                ],
              ),
            ],
          ),

          // Time pickers for this day (день внизу дата/время от и до)
          if (day.isWorking) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTimeBox(
                    context: context,
                    label: 'Время от',
                    time: day.timeFrom,
                    onTap: () => _pickTime(
                      context: context,
                      initial: day.timeFrom,
                      onPicked: (val) {
                        setState(() {
                          day.timeFrom = val;
                          _applyToAllDays = false; // modified individually
                        });
                        _notifyChange();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTimeBox(
                    context: context,
                    label: 'Время до',
                    time: day.timeTo,
                    onTap: () => _pickTime(
                      context: context,
                      initial: day.timeTo,
                      onPicked: (val) {
                        setState(() {
                          day.timeTo = val;
                          _applyToAllDays = false; // modified individually
                        });
                        _notifyChange();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
