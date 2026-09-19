import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Фильтр отчёта по сроку годности: только даты «от» и «до».
class GoodsExpirationFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const GoodsExpirationFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  State<GoodsExpirationFilterScreen> createState() =>
      _GoodsExpirationFilterScreenState();
}

class _GoodsExpirationFilterScreenState
    extends State<GoodsExpirationFilterScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  void _applyFilters() {
    if (_fromDate == null && _toDate == null) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'date_from': _fromDate == null
            ? null
            : DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day),
        'date_to': _toDate == null
            ? null
            : DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59),
      });
    }
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    widget.onResetFilters?.call();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final hasRange = _fromDate != null && _toDate != null;

    return Scaffold(
      backgroundColor: colors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: colors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        title: Text(
          localizations.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              localizations.translate('reset'),
              style: TextStyle(color: colors.buttonPrimaryBg),
            ),
          ),
          TextButton(
            onPressed: _applyFilters,
            child: Text(
              localizations.translate('apply'),
              style: TextStyle(color: colors.buttonPrimaryBg),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasRange
                        ? '${_formatDate(_fromDate!)} — ${_formatDate(_toDate!)}'
                        : localizations.translate('select_date_range'),
                    style: context.appTextStyles.bodyMd.copyWith(
                      color: hasRange
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, color: colors.iconSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
