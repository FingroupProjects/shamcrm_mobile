import 'package:animated_custom_dropdown/custom_dropdown.dart';
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
  SubCategoryAttributesData? selectedSubCategory;

  final TextStyle categoryTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategory != null && widget.subCategories.isNotEmpty) {
      selectedSubCategory = widget.subCategories.firstWhere(
        (subCat) => subCat.name == widget.selectedCategory,
        orElse: () => widget.subCategories.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              closedFillColor: Color(0xffF4F7FD),
              expandedFillColor: Colors.white,
              closedBorder: Border.all(
                color: widget.isValid ? const Color(0xffF4F7FD) : Colors.red,
                width: 1.5,
              ),
              closedBorderRadius: BorderRadius.circular(12),
              expandedBorder: Border.all(
                color: widget.isValid ? const Color(0xffF4F7FD) : Colors.red,
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
                selectedItem?.name ??
                    AppLocalizations.of(context)!.translate('select_category'),
                style: categoryTextStyle,
              );
            },
            hintBuilder: (context, hint, enabled) => Text(
              AppLocalizations.of(context)!.translate('list_select_subcategories'),
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
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}