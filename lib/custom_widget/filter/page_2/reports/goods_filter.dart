import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoodsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final String? initialAmountFrom;
  final String? initialAmountTo;
  final String? categoryId;
  final String? daysWithoutMovement;
  final String? goodId;

  const GoodsFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialAmountFrom,
    this.initialAmountTo,
    this.categoryId,
    this.daysWithoutMovement,
    this.goodId,
  }) : super(key: key);

  @override
  _GoodsFilterScreenState createState() => _GoodsFilterScreenState();
}

class _GoodsFilterScreenState extends State<GoodsFilterScreen> {
  final TextEditingController _amountFromController = TextEditingController();
  final TextEditingController _amountToController = TextEditingController();
  final TextEditingController _daysWithoutMovementController = TextEditingController();
  final ApiService _apiService = ApiService();

  SubCategoryAttributesData? selectedCategory;
  List<SubCategoryAttributesData> subCategories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountFromController.text = widget.initialAmountFrom ?? '';
    _amountToController.text = widget.initialAmountTo ?? '';
    _daysWithoutMovementController.text = widget.daysWithoutMovement ?? '';
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
      _amountFromController.text = prefs.getString('goods_amount_from') ?? widget.initialAmountFrom ?? '';
      _amountToController.text = prefs.getString('goods_amount_to') ?? widget.initialAmountTo ?? '';
      _daysWithoutMovementController.text = prefs.getString('goods_days_without_movement') ?? widget.daysWithoutMovement ?? '';

      final categoryName = prefs.getString('goods_category');
      final categoryId = prefs.getInt('goods_category_id');
      if (categoryName != null && categoryId != null && subCategories.isNotEmpty) {
        try {
          selectedCategory = subCategories.firstWhere((c) => c.id == categoryId);
        } catch (e) {
          selectedCategory = null;
        }
      }
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goods_amount_from', _amountFromController.text);
    await prefs.setString('goods_amount_to', _amountToController.text);
    await prefs.setString('goods_days_without_movement', _daysWithoutMovementController.text);

    if (selectedCategory != null) {
      await prefs.setString('goods_category', selectedCategory!.name);
      await prefs.setInt('goods_category_id', selectedCategory!.id);
    } else {
      await prefs.remove('goods_category');
      await prefs.remove('goods_category_id');
    }
  }

  void _resetFilters() {
    setState(() {
      _amountFromController.text = '';
      _amountToController.text = '';
      _daysWithoutMovementController.text = '';
      selectedCategory = null;
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  bool _isAnyFilterSelected() {
    return _amountFromController.text.isNotEmpty ||
        _amountToController.text.isNotEmpty ||
        _daysWithoutMovementController.text.isNotEmpty ||
        selectedCategory != null;
  }

  String? _parseAmount(String text) {
    if (text.isEmpty) return null;
    return text;
  }

  int? _parseDays(String text) {
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'sum_from': _parseAmount(_amountFromController.text),
        'sum_to': _parseAmount(_amountToController.text),
        'days_without_movement': _parseDays(_daysWithoutMovementController.text),
        'category_id': selectedCategory?.id,
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
                  selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_category') ?? 'Выберите категорию',
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
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _amountFromController,
                              keyboardType: TextInputType.number,
                              hintText: AppLocalizations.of(context)!.translate('enter_minimum_amount') ?? 'Введите минимальную сумму',
                              label: AppLocalizations.of(context)!.translate('amount_from') ?? 'Сумма от',
                            ),
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
                            CustomTextField(
                              controller: _amountToController,
                              keyboardType: TextInputType.number,
                              hintText: AppLocalizations.of(context)!.translate('enter_maximum_amount') ?? 'Введите максимальную сумму',
                              label: AppLocalizations.of(context)!.translate('amount_to') ?? 'Сумма до',
                            ),
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
                            CustomTextField(
                              controller: _daysWithoutMovementController,
                              keyboardType: TextInputType.number,
                              hintText: AppLocalizations.of(context)!.translate('enter_days') ?? 'Введите количество дней',
                              label: AppLocalizations.of(context)!.translate('days_without_movement') ?? 'Дни без движения',
                            ),
                          ],
                        ),
                      ),
                    ),
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
    _daysWithoutMovementController.dispose();
    super.dispose();
  }
}