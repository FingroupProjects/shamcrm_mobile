import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CostStructureFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialAmountFrom;
  final String? initialAmountTo;

  const CostStructureFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialAmountFrom,
    this.initialAmountTo,
  });

  @override
  State<CostStructureFilterScreen> createState() =>
      _CostStructureFilterScreenState();
}

class _CostStructureFilterScreenState extends State<CostStructureFilterScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _amountFromController = TextEditingController();
  final TextEditingController _amountToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _amountFromController.text = widget.initialAmountFrom ?? '';
    _amountToController.text = widget.initialAmountTo ?? '';
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final fromDateMillis = prefs.getInt('cost_structure_from_date');
      final toDateMillis = prefs.getInt('cost_structure_to_date');
      if (fromDateMillis != null) {
        _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
      }
      if (toDateMillis != null) {
        _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
      }
      _amountFromController.text =
          prefs.getString('cost_structure_amount_from') ??
              widget.initialAmountFrom ??
              '';
      _amountToController.text = prefs.getString('cost_structure_amount_to') ??
          widget.initialAmountTo ??
          '';
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_fromDate != null) {
      await prefs.setInt(
          'cost_structure_from_date', _fromDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('cost_structure_from_date');
    }
    if (_toDate != null) {
      await prefs.setInt(
          'cost_structure_to_date', _toDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('cost_structure_to_date');
    }
    await prefs.setString(
        'cost_structure_amount_from', _amountFromController.text);
    await prefs.setString('cost_structure_amount_to', _amountToController.text);
  }

  Widget _buildFilterCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      shadowColor: context.appColors.shadowColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  ButtonStyle _buildActionButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor:
          context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
    );
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: this.context.appColors.surfacePrimary,
            colorScheme: ColorScheme.light(
              primary: this.context.appColors.buttonPrimaryBg,
              onPrimary: this.context.appColors.buttonPrimaryFg,
              onSurface: this.context.appColors.textPrimary,
              secondary: this
                  .context
                  .appColors
                  .buttonSecondaryBg
                  .withValues(alpha: 0.1),
              surface: this.context.appColors.surfacePrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: this.context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  bool _isAnyFilterSelected() {
    return _fromDate != null ||
        _toDate != null ||
        _amountFromController.text.isNotEmpty ||
        _amountToController.text.isNotEmpty;
  }

  double? _parseAmount(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', ''));
  }

  Future<void> _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      DateTime? fromDateWithTime = _fromDate;
      DateTime? toDateWithTime = _toDate;

      if (fromDateWithTime != null) {
        fromDateWithTime = DateTime(
          fromDateWithTime.year,
          fromDateWithTime.month,
          fromDateWithTime.day,
          0,
          0,
          0,
        );
      }
      if (toDateWithTime != null) {
        toDateWithTime = DateTime(
          toDateWithTime.year,
          toDateWithTime.month,
          toDateWithTime.day,
          23,
          59,
          59,
        );
      }

      widget.onSelectedDataFilter?.call({
        'fromDate': fromDateWithTime,
        'toDate': toDateWithTime,
        'amountFrom': _parseAmount(_amountFromController.text),
        'amountTo': _parseAmount(_amountToController.text),
      });
    }
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _amountFromController.clear();
      _amountToController.clear();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          localizations.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            style: _buildActionButtonStyle(),
            child: Text(
              localizations.translate('reset'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _applyFilters,
            style: _buildActionButtonStyle(),
            child: Text(
              localizations.translate('apply'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFilterCard(
                      padding: EdgeInsets.zero,
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.appColors.surfacePrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromDate != null && _toDate != null
                                    ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                    : localizations
                                        .translate('select_date_range'),
                                style: context.appTextStyles.bodyMd.copyWith(
                                  color: _fromDate != null && _toDate != null
                                      ? context.appColors.textPrimary
                                      : context.appColors.textSecondary,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: context.appColors.iconSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterCard(
                      child: CustomTextField(
                        controller: _amountFromController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        hintText:
                            localizations.translate('enter_minimum_amount'),
                        label: localizations.translate('amount_from'),
                        backgroundColor: context.appColors.fieldBg,
                        borderColor: context.appColors.fieldBorder,
                        focusedBorderColor: context.appColors.borderPrimary,
                        labelColor: context.appColors.textPrimary,
                        hintColor: context.appColors.fieldHint,
                        textColor: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterCard(
                      child: CustomTextField(
                        controller: _amountToController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        hintText:
                            localizations.translate('enter_maximum_amount'),
                        label: localizations.translate('amount_to'),
                        backgroundColor: context.appColors.fieldBg,
                        borderColor: context.appColors.fieldBorder,
                        focusedBorderColor: context.appColors.borderPrimary,
                        labelColor: context.appColors.textPrimary,
                        hintColor: context.appColors.fieldHint,
                        textColor: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountFromController.dispose();
    _amountToController.dispose();
    super.dispose();
  }
}
