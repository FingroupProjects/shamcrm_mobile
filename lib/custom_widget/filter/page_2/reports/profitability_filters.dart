import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfitabilityFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final String? categoryId;
  final String? goodId;
  final DateTime? period; // Changed from String? to DateTime?

  const ProfitabilityFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.categoryId,
    this.goodId,
    this.period,
  }) : super(key: key);

  @override
  _ProfitabilityFilterScreenState createState() => _ProfitabilityFilterScreenState();
}

class _ProfitabilityFilterScreenState extends State<ProfitabilityFilterScreen> {
  final ApiService _apiService = ApiService();
  SubCategoryAttributesData? selectedCategory;
  DateTime? selectedPeriod; // Changed from String? to DateTime?
  List<SubCategoryAttributesData> subCategories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
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

      // Load period as DateTime
      final savedYear = prefs.getInt('goods_period_year');
      if (savedYear != null) {
        selectedPeriod = DateTime(savedYear);
      } else if (widget.period != null) {
        selectedPeriod = widget.period;
      }
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

    // Save period as year integer
    if (selectedPeriod != null) {
      await prefs.setInt('goods_period_year', selectedPeriod!.year);
    } else {
      await prefs.remove('goods_period_year');
    }
  }

  void _resetFilters() {
    setState(() {
      selectedCategory = null;
      selectedPeriod = null;
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  bool _isAnyFilterSelected() {
    return selectedCategory != null || selectedPeriod != null;
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'category_id': selectedCategory?.id,
        'period': selectedPeriod,
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

  Widget _buildPeriodWidget() {
    final int currentYear = DateTime.now().year;
    final List<DateTime> years = List.generate(
      10, // Last 10 years
          (index) => DateTime(currentYear - index), // Create DateTime objects with only year
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('period') ?? 'Период',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            CustomDropdown<DateTime>.search(
              items: years,
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
                  item.year.toString(),
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
                  selectedItem?.year.toString() ??
                      AppLocalizations.of(context)!.translate('select_year') ?? 'Выберите год',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_year') ?? 'Выберите год',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              excludeSelected: false,
              initialItem: selectedPeriod,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPeriod = value;
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
                    _buildPeriodWidget(),
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