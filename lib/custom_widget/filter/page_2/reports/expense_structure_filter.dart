import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/expense_article_dashboard_warehouse/expense_article_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/category_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/expense_article_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseStructureFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final String? categoryId;
  final String? articleId;
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  const ExpenseStructureFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.categoryId,
    this.articleId,
    this.initialDateFrom,
    this.initialDateTo,
  });

  @override
  State<ExpenseStructureFilterScreen> createState() =>
      _ExpenseStructureFilterScreenState();
}

class _ExpenseStructureFilterScreenState extends State<ExpenseStructureFilterScreen> {
  final ApiService _apiService = ApiService();
  String? selectedCategoryId;
  String? selectedExpenseArticleId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  Key _expenseArticleKey = UniqueKey();
  Key _categoryKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.categoryId;
    selectedExpenseArticleId = widget.articleId;
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCategoryId = prefs.getString('expense_structure_category_id') ?? widget.categoryId;
      selectedExpenseArticleId = prefs.getString('expense_structure_article_id') ?? widget.articleId;

      // Load date_from and date_to
      final dateFromMillis = prefs.getInt('expense_structure_date_from');
      final dateToMillis = prefs.getInt('expense_structure_date_to');
      if (dateFromMillis != null) _dateFrom = DateTime.fromMillisecondsSinceEpoch(dateFromMillis);
      if (dateToMillis != null) _dateTo = DateTime.fromMillisecondsSinceEpoch(dateToMillis);
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();

    if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
      await prefs.setString('expense_structure_category_id', selectedCategoryId!);
    } else {
      await prefs.remove('expense_structure_category_id');
    }

    if (selectedExpenseArticleId != null && selectedExpenseArticleId!.isNotEmpty) {
      await prefs.setString('expense_structure_article_id', selectedExpenseArticleId!);
    } else {
      await prefs.remove('expense_structure_article_id');
    }

    // Save date_from and date_to
    if (_dateFrom != null) {
      await prefs.setInt('expense_structure_date_from', _dateFrom!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('expense_structure_date_from');
    }
    if (_dateTo != null) {
      await prefs.setInt('expense_structure_date_to', _dateTo!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('expense_structure_date_to');
    }
  }

  void _resetFilters() {
    setState(() {
      selectedCategoryId = null;
      selectedExpenseArticleId = null;
      _dateFrom = null;
      _dateTo = null;
      _categoryKey = UniqueKey();
      _expenseArticleKey = UniqueKey();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: this.context.appColors.surfacePrimary,
            colorScheme: ColorScheme.light(
              primary: this.context.appColors.buttonPrimaryBg,
              onPrimary: this.context.appColors.buttonPrimaryFg,
              onSurface: this.context.appColors.textPrimary,
              secondary:
                  this.context.appColors.buttonSecondaryBg.withValues(alpha: 0.1),
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
        _dateFrom = pickedRange.start;
        _dateTo = pickedRange.end;
      });
    }
  }

  bool _isAnyFilterSelected() {
    return selectedCategoryId != null || selectedExpenseArticleId != null || _dateFrom != null || _dateTo != null;
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      // Set from date to 00:00:00 and to date to 23:59:59
      DateTime? fromDateWithTime = _dateFrom;
      DateTime? toDateWithTime = _dateTo;
      
      if (fromDateWithTime != null) {
        fromDateWithTime = DateTime(fromDateWithTime.year, fromDateWithTime.month, fromDateWithTime.day, 0, 0, 0);
      }
      if (toDateWithTime != null) {
        toDateWithTime = DateTime(toDateWithTime.year, toDateWithTime.month, toDateWithTime.day, 23, 59, 59);
      }
      
      widget.onSelectedDataFilter?.call({
        'category_id': selectedCategoryId != null ? int.tryParse(selectedCategoryId!) : null,
        'article_id': selectedExpenseArticleId != null ? int.tryParse(selectedExpenseArticleId!) : null,
        'date_from': fromDateWithTime,
        'date_to': toDateWithTime,
      });
    }
    Navigator.pop(context);
  }

  Widget _buildCategoryWidget() {
    return BlocProvider<CategoryDashboardWarehouseBloc>(
      create: (context) => CategoryDashboardWarehouseBloc(_apiService),
      child: CategoryDashboardWarehouseWidget(
        key: _categoryKey,
        selectedCategoryDashboardWarehouse: selectedCategoryId,
        onChanged: (id) {
          setState(() {
            selectedCategoryId = id;
          });
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildExpenseArticleWidget() {
    return BlocProvider<ExpenseArticleDashboardWarehouseBloc>(
      create: (context) => ExpenseArticleDashboardWarehouseBloc(_apiService),
      child: ExpenseArticleDashboardWarehouseWidget(
        key: _expenseArticleKey,
        selectedExpenseArticleDashboardWarehouse: selectedExpenseArticleId,
        onChanged: (id) {
          setState(() {
            selectedExpenseArticleId = id;
          });
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildFilterCard(Widget child, {EdgeInsetsGeometry? padding}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      shadowColor: context.appColors.shadowColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12),
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

  Widget _buildDateRangeWidget() {
    return _buildFilterCard(
      GestureDetector(
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
                _dateFrom != null && _dateTo != null
                    ? "${_dateFrom!.day.toString().padLeft(2, '0')}.${_dateFrom!.month.toString().padLeft(2, '0')}.${_dateFrom!.year} - ${_dateTo!.day.toString().padLeft(2, '0')}.${_dateTo!.month.toString().padLeft(2, '0')}.${_dateTo!.year}"
                    : AppLocalizations.of(context)!.translate('select_date_range'),
                style: context.appTextStyles.bodyMd.copyWith(
                  color: _dateFrom != null && _dateTo != null
                      ? context.appColors.textPrimary
                      : context.appColors.textSecondary,
                ),
              ),
              Icon(Icons.calendar_today, color: context.appColors.iconSecondary),
            ],
          ),
        ),
      ),
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
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
              AppLocalizations.of(context)!.translate('reset'),
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
              AppLocalizations.of(context)!.translate('apply'),
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
                    _buildDateRangeWidget(),
                    const SizedBox(height: 8),
                    _buildFilterCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildCategoryWidget()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildExpenseArticleWidget()],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
