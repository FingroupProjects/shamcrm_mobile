import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CategoryDropdownWidget extends StatefulWidget {
  final String? selectedCategory;
  final Function(SubCategoryAttributesData?) onSelectCategory;
  final List<SubCategoryAttributesData> subCategories;

  CategoryDropdownWidget({
    Key? key,
    required this.onSelectCategory,
    this.selectedCategory,
    required this.subCategories,
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
        orElse: () => widget.subCategories.first // This must return a non-nullable SubCategoryAttributesData
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('Подкатегория'),
          style: categoryTextStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: const Color(0xFFF4F7FD),
            ),
          ),
          child: CustomDropdown<SubCategoryAttributesData>.search(
            closeDropDownOnClearFilterSearch: true,
            items: widget.subCategories,
            searchHintText: AppLocalizations.of(context)!.translate('search'),
            overlayHeight: 300,
            decoration: CustomDropdownDecoration(
              closedFillColor: Color(0xffF4F7FD),
              expandedFillColor: Colors.white,
              closedBorder: Border.all(
                color: const Color(0xffF4F7FD),
                width: 1,
              ),
              closedBorderRadius: BorderRadius.circular(12),
              expandedBorder: Border.all(
                color: const Color(0xffF4F7FD),
                width: 1,
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
              // No loading animation, just text
              return Text(
                selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_category'),
                style: categoryTextStyle,
              );
            },
            hintBuilder: (context, hint, enabled) => Text(
              AppLocalizations.of(context)!.translate('Выберите подкатегорию'),
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
      ],
    );
  }
}