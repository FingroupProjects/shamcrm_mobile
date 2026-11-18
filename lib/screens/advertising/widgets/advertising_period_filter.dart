import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_funnel/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final SalesFunnel? funnel;

  const AdvertisingFilterResult({
    required this.preset,
    required this.start,
    required this.end,
    this.funnel,
  });
}

class AdvertisingPeriodFilter extends StatefulWidget {
  final AdvertisingDatePreset preset;
  final DateTime start;
  final DateTime end;
  final SalesFunnel? selectedFunnel;

  const AdvertisingPeriodFilter({
    super.key,
    required this.preset,
    required this.start,
    required this.end,
    this.selectedFunnel,
  });

  @override
  State<AdvertisingPeriodFilter> createState() =>
      _AdvertisingPeriodFilterState();
}

class _AdvertisingPeriodFilterState extends State<AdvertisingPeriodFilter> {
  late AdvertisingDatePreset _preset;
  late DateTime _start;
  late DateTime _end;
  SalesFunnel? _selectedFunnel;

  @override
  void initState() {
    super.initState();
    _preset = widget.preset;
    _start = widget.start;
    _end = widget.end;
    _selectedFunnel = widget.selectedFunnel;
  }

  (DateTime, DateTime) _rangeForPreset(AdvertisingDatePreset preset) {
    final now = DateTime.now();
    switch (preset) {
      case AdvertisingDatePreset.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start);
      case AdvertisingDatePreset.last7Days:
        return (now.subtract(const Duration(days: 7)), now);
      case AdvertisingDatePreset.last30Days:
        return (now.subtract(const Duration(days: 30)), now);
      case AdvertisingDatePreset.last90Days:
        return (now.subtract(const Duration(days: 90)), now);
      case AdvertisingDatePreset.currentMonth:
        return (DateTime(now.year, now.month, 1), now);
      case AdvertisingDatePreset.lastMonth:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        final lastOfPrev = firstOfMonth.subtract(const Duration(days: 1));
        final start = DateTime(lastOfPrev.year, lastOfPrev.month, 1);
        return (start, lastOfPrev);
      case AdvertisingDatePreset.custom:
        return (_start, _end);
    }
  }

  void _selectPreset(AdvertisingDatePreset preset) {
    if (preset == AdvertisingDatePreset.custom) {
      _pickRange();
      return;
    }

    final range = _rangeForPreset(preset);
    setState(() {
      _preset = preset;
      _start = range.$1;
      _end = range.$2;
    });
  }

  Future<void> _pickRange() async {
    final colors = context.appColors;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: colors.surfacePrimary,
            canvasColor: colors.surfacePrimary,
            colorScheme: ColorScheme.dark(
              primary: colors.buttonPrimaryBg,
              onPrimary: colors.buttonPrimaryFg,
              surface: colors.surfacePrimary,
              onSurface: colors.textPrimary,
              secondary: colors.buttonSecondaryBg.withValues(alpha: 0.16),
              onSecondary: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: colors.surfacePrimary,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colors.surfacePrimary,
              foregroundColor: colors.textPrimary,
              surfaceTintColor: colors.surfacePrimary,
              elevation: 0,
            ),
            dividerColor: colors.borderSubtle,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.surfacePrimary,
              surfaceTintColor: colors.surfacePrimary,
              headerBackgroundColor: colors.surfacePrimary,
              headerForegroundColor: colors.textPrimary,
              weekdayStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
              dayStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
              yearStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
              rangePickerHeaderForegroundColor: colors.textPrimary,
              rangePickerBackgroundColor: colors.surfacePrimary,
              rangeSelectionBackgroundColor:
                  colors.buttonPrimaryBg.withValues(alpha: 0.18),
              rangeSelectionOverlayColor: WidgetStatePropertyAll(
                colors.buttonPrimaryBg.withValues(alpha: 0.10),
              ),
              todayForegroundColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg),
              todayBackgroundColor: WidgetStatePropertyAll(
                colors.buttonPrimaryBg.withValues(alpha: 0.12),
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryFg;
                }
                return colors.textPrimary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryBg;
                }
                return null;
              }),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: colors.buttonPrimaryBg,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
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
      _selectedFunnel = widget.selectedFunnel;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      AdvertisingFilterResult(
        preset: _preset,
        start: _start,
        end: _end,
        funnel: _selectedFunnel,
      ),
    );
  }

  String _format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _presetLabel(AdvertisingDatePreset preset, AppLocalizations t) {
    switch (preset) {
      case AdvertisingDatePreset.currentMonth:
        return t.translate('current_month');
      case AdvertisingDatePreset.lastMonth:
        return t.translate('previous_month');
      case AdvertisingDatePreset.last30Days:
        return t.translate('period_30_days');
      case AdvertisingDatePreset.last7Days:
        return t.translate('period_7_days');
      case AdvertisingDatePreset.today:
        return t.translate('today');
      case AdvertisingDatePreset.last90Days:
        return t.translate('period_90_days');
      case AdvertisingDatePreset.custom:
        return t.translate('select_date');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;

    final presets = <AdvertisingDatePreset>[
      AdvertisingDatePreset.currentMonth,
      AdvertisingDatePreset.lastMonth,
      AdvertisingDatePreset.last30Days,
      AdvertisingDatePreset.last7Days,
      AdvertisingDatePreset.today,
      AdvertisingDatePreset.last90Days,
    ];

    return Scaffold(
      backgroundColor: colors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: colors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.translate('filter'),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(
              t.translate('reset'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // 1. Sales Funnel section
          BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
            builder: (context, state) {
              if (state is! SalesFunnelLoaded || state.funnels.isEmpty) {
                return const SizedBox.shrink();
              }
              final funnels = state.funnels;
              final currentFunnel = _selectedFunnel ??
                  funnels.firstWhere(
                    (f) => f.id == widget.selectedFunnel?.id,
                    orElse: () => funnels.first,
                  );

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.buttonPrimaryBg
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.filter_alt_outlined,
                              size: 20,
                              color: colors.buttonPrimaryBg,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Воронка продаж',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Фильтрация данных рекламы по воронке',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: funnels.map((funnel) {
                          final isSelected = currentFunnel.id == funnel.id;
                          return ChoiceChip(
                            label: Text(
                              funnel.name,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colors.buttonPrimaryFg
                                    : colors.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: colors.buttonPrimaryBg,
                            backgroundColor: colors.fieldBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? colors.buttonPrimaryBg
                                    : colors.borderSubtle,
                              ),
                            ),
                            showCheckmark: false,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedFunnel = funnel);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Custom Date Range card
          Container(
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _preset == AdvertisingDatePreset.custom
                    ? colors.buttonPrimaryBg
                    : colors.borderSubtle,
                width: _preset == AdvertisingDatePreset.custom ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: colors.buttonPrimaryBg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Произвольный период',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Выберите точный диапазон дат в календаре',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_preset == AdvertisingDatePreset.custom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.buttonPrimaryBg.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Выбран',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.buttonPrimaryBg,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _preset == AdvertisingDatePreset.custom
                            ? colors.buttonPrimaryBg.withValues(alpha: 0.5)
                            : colors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'С даты',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _format(_start),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: colors.borderSubtle,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'По дату',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _format(_end),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.date_range_outlined,
                          color: colors.buttonPrimaryBg,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Quick Presets Card
          Container(
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.flash_on_rounded,
                          size: 20,
                          color: colors.buttonPrimaryBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Быстрый выбор',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.translate('figures_for_period'),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...presets.map((preset) {
                  final isSelected = _preset == preset;
                  final range = _rangeForPreset(preset);
                  final dateStr =
                      '${_format(range.$1)} — ${_format(range.$2)}';
                  final isLast = preset == presets.last;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _selectPreset(preset),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          color: isSelected
                              ? colors.buttonPrimaryBg.withValues(alpha: 0.08)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.buttonPrimaryBg
                                        : colors.borderSubtle,
                                    width: isSelected ? 6.5 : 1.5,
                                  ),
                                  color: isSelected
                                      ? colors.surfacePrimary
                                      : Colors.transparent,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _presetLabel(preset, t),
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? colors.buttonPrimaryBg
                                            : colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  color: colors.buttonPrimaryBg,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, indent: 52),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          border: Border(
            top: BorderSide(color: colors.borderSubtle),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: colors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  t.translate('reset'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.buttonPrimaryFg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  t.translate('apply'),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
