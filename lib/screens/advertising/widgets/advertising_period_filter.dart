import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

enum AdvertisingDatePreset {
  last30Days,
  today,
  last7Days,
  currentMonth,
  lastMonth,
  last90Days,
  custom,
}

class AdvertisingFilterResult {
  final AdvertisingDatePreset preset;
  final DateTime start;
  final DateTime end;

  const AdvertisingFilterResult({
    required this.preset,
    required this.start,
    required this.end,
  });
}

class AdvertisingPeriodFilter extends StatefulWidget {
  final AdvertisingDatePreset preset;
  final DateTime start;
  final DateTime end;

  const AdvertisingPeriodFilter({
    super.key,
    required this.preset,
    required this.start,
    required this.end,
  });

  @override
  State<AdvertisingPeriodFilter> createState() =>
      _AdvertisingPeriodFilterState();
}

class _AdvertisingPeriodFilterState extends State<AdvertisingPeriodFilter> {
  late AdvertisingDatePreset _preset;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _preset = widget.preset;
    _start = widget.start;
    _end = widget.end;
  }

  void _selectPreset(AdvertisingDatePreset preset) {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    switch (preset) {
      case AdvertisingDatePreset.today:
        start = DateTime(now.year, now.month, now.day);
        end = start;
      case AdvertisingDatePreset.last7Days:
        start = now.subtract(const Duration(days: 7));
        end = now;
      case AdvertisingDatePreset.last30Days:
        start = now.subtract(const Duration(days: 30));
        end = now;
      case AdvertisingDatePreset.last90Days:
        start = now.subtract(const Duration(days: 90));
        end = now;
      case AdvertisingDatePreset.currentMonth:
        start = DateTime(now.year, now.month, 1);
        end = now;
      case AdvertisingDatePreset.lastMonth:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        final lastOfPrev = firstOfMonth.subtract(const Duration(days: 1));
        start = DateTime(lastOfPrev.year, lastOfPrev.month, 1);
        end = lastOfPrev;
      case AdvertisingDatePreset.custom:
        return;
    }

    setState(() {
      _preset = preset;
      _start = start;
      _end = end;
    });
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      builder: (context, child) {
        final colors = context.appColors;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colors.buttonPrimaryBg,
              onPrimary: colors.buttonPrimaryFg,
              surface: colors.surfacePrimary,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _preset = AdvertisingDatePreset.custom;
      _start = picked.start;
      _end = picked.end;
    });
  }

  void _reset() {
    final now = DateTime.now();
    setState(() {
      _preset = AdvertisingDatePreset.last30Days;
      _start = now.subtract(const Duration(days: 30));
      _end = now;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      AdvertisingFilterResult(
        preset: _preset,
        start: _start,
        end: _end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final options = <AdvertisingDatePreset, String>{
      AdvertisingDatePreset.currentMonth: t.translate('current_month'),
      AdvertisingDatePreset.lastMonth: t.translate('previous_month'),
      AdvertisingDatePreset.last30Days: t.translate('period_30_days'),
      AdvertisingDatePreset.last7Days: t.translate('period_7_days'),
      AdvertisingDatePreset.today: t.translate('today'),
      AdvertisingDatePreset.last90Days: t.translate('period_90_days'),
    };

    return Scaffold(
      backgroundColor: colors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: colors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 1,
        title: Text(
          t.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(
              t.translate('reset'),
              style: context.appTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
          TextButton(
            onPressed: _apply,
            child: Text(
              t.translate('apply'),
              style: context.appTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            t.translate('figures_for_period'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...options.entries.map((entry) {
            return _choiceRow(
              context,
              title: entry.value,
              selected: _preset == entry.key,
              onTap: () => _selectPreset(entry.key),
            );
          }),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.date_range, color: colors.iconSecondary),
            title: Text(
              _preset == AdvertisingDatePreset.custom
                  ? '${_format(_start)} — ${_format(_end)}'
                  : t.translate('select_date'),
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            onTap: _pickRange,
          ),
        ],
      ),
    );
  }

  Widget _choiceRow(
    BuildContext context, {
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colors.buttonPrimaryBg : colors.iconSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Gilroy',
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
