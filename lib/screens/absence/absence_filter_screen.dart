import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/material.dart';

/// Отдельный экран фильтра, как у лидов: даты и поле «Исполнители».
class AbsenceFilterScreen extends StatefulWidget {
  const AbsenceFilterScreen({
    super.key,
    required this.initial,
    required this.showExecutors,
    this.stats = AbsenceStats.empty,
  });

  final AbsenceFilters initial;
  final bool showExecutors;
  final AbsenceStats stats;

  @override
  State<AbsenceFilterScreen> createState() => _AbsenceFilterScreenState();
}

class _AbsenceFilterScreenState extends State<AbsenceFilterScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  List<UserData> _executors = const [];
  String? _status;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initial.dateFrom;
    _toDate = widget.initial.dateTo;
    _status = widget.initial.status;
    _executors = [
      for (final id in widget.initial.userIds)
        UserData(
          id: id,
          name: widget.initial.userNames[id] ?? '',
          lastname: '',
        ),
    ];
  }

  void _reset() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _status = null;
      _executors = const [];
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      AbsenceFilters(
        userIds: _executors.map((user) => user.id).toList(),
        userNames: {for (final user in _executors) user.id: user.displayName},
        dateFrom: _fromDate,
        dateTo: _toDate,
        status: _status,
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (context, child) => Theme(
        data: absencePickerTheme(context),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _fromDate = dateOnly(picked.start);
      _toDate = dateOnly(picked.end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final period = _fromDate != null && _toDate != null
        ? '${formatAbsenceDisplayDate(_fromDate!)} - ${formatAbsenceDisplayDate(_toDate!)}'
        : l10n.translate('select_date_range');

    return Scaffold(
      backgroundColor: colors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: colors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 1,
        foregroundColor: colors.textPrimary,
        title: Text(
          l10n.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(color: colors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            style: _actionStyle(context),
            child: Text(
              l10n.translate('reset'),
              style: context.appTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _apply,
            style: _actionStyle(context),
            child: Text(
              l10n.translate('apply'),
              style: context.appTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            color: colors.surfacePrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        period,
                        style: context.appTextStyles.bodyMd.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today, color: colors.iconSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (widget.showExecutors) ...[
            const SizedBox(height: 8),
            Card(
              color: colors.surfacePrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: UserMultiSelectWidget(
                  isRequired: false,
                  selectedUsers: _executors.map((user) => user.id.toString()).toList(),
                  onSelectUsers: (users) => setState(() => _executors = users),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Card(
            color: colors.surfacePrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _StatusDropdown(
                value: _status,
                stats: widget.stats,
                onChanged: (value) => setState(() => _status = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _actionStyle(BuildContext context) {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor: context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
    );
  }
}

class _StatusChoice {
  const _StatusChoice({required this.value, required this.label});

  final String? value;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is _StatusChoice && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Одно значение, тем же полем, что исполнители, без мультивыбора.
class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.value,
    required this.stats,
    required this.onChanged,
  });

  final String? value;
  final AbsenceStats stats;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final choices = <_StatusChoice>[
      _StatusChoice(
        value: null,
        label: _withCount(absenceTr(context, 'absence_chip_total'), stats.total),
      ),
      _StatusChoice(
        value: 'pending',
        label: _withCount(
          absenceTr(context, 'absence_status_pending'),
          stats.pending,
        ),
      ),
      _StatusChoice(
        value: 'approved',
        label: _withCount(
          absenceTr(context, 'absence_status_approved'),
          stats.approved,
        ),
      ),
      _StatusChoice(
        value: 'rejected',
        label: _withCount(
          absenceTr(context, 'absence_status_rejected'),
          stats.rejected,
        ),
      ),
      _StatusChoice(
        value: 'cancelled',
        label: _withCount(
          absenceTr(context, 'absence_status_cancelled'),
          stats.cancelled,
        ),
      ),
    ];
    final selected = choices.firstWhere(
      (item) => item.value == value,
      orElse: () => choices.first,
    );
    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          absenceTr(context, 'status'),
          style: textStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 4),
        CustomDropdown<_StatusChoice>(
          key: ValueKey(value ?? 'all'),
          items: choices,
          initialItem: selected,
          hintText: absenceTr(context, 'absence_chip_total'),
          overlayHeight: 280,
          decoration: CustomDropdownDecoration(
            closedFillColor: colors.fieldBg,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: AppFieldStyle.dropdownBorder(context),
            expandedBorder: AppFieldStyle.dropdownBorder(context),
            closedBorderRadius: AppFieldStyle.radius,
            expandedBorderRadius: AppFieldStyle.radius,
            headerStyle: textStyle,
            hintStyle: textStyle.copyWith(color: colors.textSecondary),
            listItemStyle: textStyle,
          ),
          headerBuilder: (context, item, enabled) =>
              Text(item.label, style: textStyle),
          listItemBuilder: (context, item, isSelected, onItemSelect) =>
              Text(item.label, style: textStyle),
          onChanged: (choice) => onChanged(choice?.value),
        ),
      ],
    );
  }

  String _withCount(String label, int count) => '$label ($count)';
}
