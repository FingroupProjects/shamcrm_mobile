import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseStructureFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final String? categoryId;
  final String? goodId;
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  const ExpenseStructureFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.categoryId,
    this.goodId,
    this.initialDateFrom,
    this.initialDateTo,
  }) : super(key: key);

  @override
  _ExpenseStructureFilterScreenState createState() => _ExpenseStructureFilterScreenState();
}

class _ExpenseStructureFilterScreenState extends State<ExpenseStructureFilterScreen> {
  final ApiService _apiService = ApiService();
  SubCategoryAttributesData? selectedCategory;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<SubCategoryAttributesData> subCategories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
    fetchSubCategories();
    _loadFilterState();
  }

  Future<void> fetchSubCategories() async {
    setState(() => isLoading = true);
    try {
      final categories = await _apiService.getSubCategoryAttributes();
      setState(() {
        subCategories = categories;
      });
    } catch (e) {
      // Error fetching subcategories
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final categoryId = prefs.getInt('goods_category_id');
      if (categoryId != null && subCategories.isNotEmpty) {
        try {
          selectedCategory = subCategories.firstWhere((c) => c.id == categoryId);
        } catch (e) {
          selectedCategory = null;
        }
      }

      // Load date_from and date_to
      final dateFromMillis = prefs.getInt('goods_date_from');
      final dateToMillis = prefs.getInt('goods_date_to');
      if (dateFromMillis != null) _dateFrom = DateTime.fromMillisecondsSinceEpoch(dateFromMillis);
      if (dateToMillis != null) _dateTo = DateTime.fromMillisecondsSinceEpoch(dateToMillis);
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    if (selectedCategory != null) {
      await prefs.setString('goods_category', selectedCategory!.name);
      await prefs.setInt('goods_category_id', selectedCategory!.id);
    } else {
      await prefs.remove('goods_category');
      await prefs.remove('goods_category_id');
    }

    // Save date_from and date_to
    if (_dateFrom != null) {
      await prefs.setInt('goods_date_from', _dateFrom!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('goods_date_from');
    }
    if (_dateTo != null) {
      await prefs.setInt('goods_date_to', _dateTo!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('goods_date_to');
    }
  }

  void _resetFilters() {
    setState(() {
      selectedCategory = null;
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
    return selectedCategory != null || _dateFrom != null || _dateTo != null;
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'category_id': selectedCategory?.id,
        'date_from': _dateFrom,
        'date_to': _dateTo,
      });
    }
    Navigator.pop(context);
  }

  Widget _buildCategoryWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('category') ?? 'Категория',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            isLoading
                ? Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xffF4F7FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            )
                : CustomDropdown<SubCategoryAttributesData>.search(
              items: subCategories,
              searchHintText: AppLocalizations.of(context)!.translate('search') ?? 'Поиск',
              overlayHeight: 300,
              closeDropDownOnClearFilterSearch: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: const Color(0xffF4F7FD),
                expandedFillColor: Colors.white,
                closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1.5),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1.5),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                return Text(
                  selectedItem?.name ??
                      AppLocalizations.of(context)!.translate('select_category') ?? 'Выберите категорию',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('list_select_subcategories') ?? 'Выберите категорию',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              excludeSelected: false,
              initialItem: selectedCategory,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ],
        ),
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
                    : AppLocalizations.of(context)!.translate('select_date_range') ?? 'Выберите диапазон дат',
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
                    _buildCategoryWidget(),
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