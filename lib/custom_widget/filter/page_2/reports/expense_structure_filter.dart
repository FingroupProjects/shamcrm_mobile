import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/expense_article_dashboard_warehouse/expense_article_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/category_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/expense_article_dashboard_warehouse_widget.dart';
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
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.categoryId,
    this.articleId,
    this.initialDateFrom,
    this.initialDateTo,
  }) : super(key: key);

  @override
  _ExpenseStructureFilterScreenState createState() => _ExpenseStructureFilterScreenState();
}

class _ExpenseStructureFilterScreenState extends State<ExpenseStructureFilterScreen> {
  final ApiService _apiService = ApiService();
  String? selectedCategoryId;
  String? selectedExpenseArticleId;
  DateTime? _dateFrom;
  DateTime? _dateTo;

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
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              secondary: Colors.blue.withOpacity(0.1),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
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
      widget.onSelectedDataFilter?.call({
        'category_id': selectedCategoryId != null ? int.tryParse(selectedCategoryId!) : null,
        'article_id': selectedExpenseArticleId != null ? int.tryParse(selectedExpenseArticleId!) : null,
        'date_from': _dateFrom,
        'date_to': _dateTo,
      });
    }
    Navigator.pop(context);
  }

  Widget _buildCategoryWidget() {
    return BlocProvider<CategoryDashboardWarehouseBloc>(
      create: (context) => CategoryDashboardWarehouseBloc(_apiService),
      child: CategoryDashboardWarehouseWidget(
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

  Widget _buildDateRangeWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: GestureDetector(
        onTap: _selectDateRange,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dateFrom != null && _dateTo != null
                    ? "${_dateFrom!.day.toString().padLeft(2, '0')}.${_dateFrom!.month.toString().padLeft(2, '0')}.${_dateFrom!.year} - ${_dateTo!.day.toString().padLeft(2, '0')}.${_dateTo!.month.toString().padLeft(2, '0')}.${_dateTo!.year}"
                    : AppLocalizations.of(context)!.translate('select_date_range'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  color: _dateFrom != null && _dateTo != null ? Colors.black : const Color(0xff99A4BA),
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.calendar_today, color: Color(0xff99A4BA)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _applyFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
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
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryWidget(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildExpenseArticleWidget(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateRangeWidget(),
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