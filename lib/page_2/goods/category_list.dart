import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CategoryDropdownWidget extends StatefulWidget {
  final String? selectedCategory;
  final Function(SubCategoryAttributesData?) onSelectCategory;
  final List<SubCategoryAttributesData> subCategories;
  final bool isValid;
  final VoidCallback? onValidationChanged;

  CategoryDropdownWidget({
    Key? key,
    required this.onSelectCategory,
    this.selectedCategory,
    required this.subCategories,
    this.isValid = true,
    this.onValidationChanged,
  }) : super(key: key);

  @override
  State<CategoryDropdownWidget> createState() => _CategoryDropdownWidgetState();
}

class _CategoryDropdownWidgetState extends State<CategoryDropdownWidget> {
  final ApiService _apiService = ApiService();
  SubCategoryAttributesData? selectedSubCategory;

  TextStyle get categoryTextStyle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: context.appColors.textPrimary,
      );

  @override
  void initState() {
    super.initState();
    _syncSelectedCategory();
  }

  @override
  void didUpdateWidget(covariant CategoryDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory ||
        oldWidget.subCategories != widget.subCategories) {
      _syncSelectedCategory();
    }
  }

  void _syncSelectedCategory() {
    if (widget.selectedCategory == null || widget.subCategories.isEmpty) {
      selectedSubCategory = null;
      return;
    }

    for (final subCategory in widget.subCategories) {
      if (subCategory.name == widget.selectedCategory) {
        selectedSubCategory = subCategory;
        return;
      }
    }

    selectedSubCategory = null;
  }

  Future<List<SubCategoryAttributesData>> _searchSubCategories(
    String query,
  ) async {
    try {
      final serverItems = await _apiService.getSubCategoryAttributes(
        search: query,
      );
      if (serverItems.isNotEmpty || query.trim().isEmpty) {
        return serverItems;
      }
    } catch (_) {
      // Fall back to local filtering when server search is unavailable.
    }

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return widget.subCategories;
    }

    return widget.subCategories
        .where((item) => item.filter(normalizedQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('list_subcategories'),
          style: categoryTextStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 4),
        Container(
          child: CustomDropdown<SubCategoryAttributesData>.search(
            closeDropDownOnClearFilterSearch: true,
            items: widget.subCategories,
            searchHintText: AppLocalizations.of(context)!.translate('search'),
            overlayHeight: 300,
            decoration: CustomDropdownDecoration(
              closedFillColor: colors.fieldBg,
              expandedFillColor: colors.surfacePrimary,
              closedBorder: Border.all(
                color: widget.isValid ? colors.borderSubtle : colors.error,
                width: 1.5,
              ),
              closedBorderRadius: BorderRadius.circular(12),
              expandedBorder: Border.all(
                color: widget.isValid ? colors.borderSubtle : colors.error,
                width: 1.5,
              ),
              expandedBorderRadius: BorderRadius.circular(12),
            ),
            listItemBuilder: (context, item, isSelected, onItemSelect) {
              return Text(
                item.name,
                style: categoryTextStyle,
              );
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Text(
                selectedItem.name,
                style: categoryTextStyle,
              );
            },
            hintBuilder: (context, hint, enabled) => Text(
              AppLocalizations.of(context)!
                  .translate('list_select_subcategories'),
              style: categoryTextStyle.copyWith(fontSize: 14),
            ),
            excludeSelected: false,
            initialItem: selectedSubCategory,
            onChanged: (value) {
              if (value != null) {
                widget.onSelectCategory(value);
                setState(() {
                  selectedSubCategory = value;
                });
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ),
        if (!widget.isValid)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '    ${AppLocalizations.of(context)!.translate('field_required')}',
              style: TextStyle(
                fontSize: 14,
                color: colors.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}
