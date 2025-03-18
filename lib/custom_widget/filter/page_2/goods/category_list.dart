import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';

class CategoryDropdownWidget extends StatefulWidget {
  final String? selectedCategory;
  final Function(String) onSelectCategory;

  CategoryDropdownWidget({
    Key? key,
    required this.onSelectCategory,
    this.selectedCategory,
  }) : super(key: key);

  @override
  State<CategoryDropdownWidget> createState() => _CategoryDropdownWidgetState();
}

class _CategoryDropdownWidgetState extends State<CategoryDropdownWidget> {
  final List<String> categories = ['Электроника', 'Бытовая техника', 'Продукты питания'];
  String? selectedCategory;

  final TextStyle categoryTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategory != null && categories.contains(widget.selectedCategory)) {
      selectedCategory = widget.selectedCategory;
    } else {
      selectedCategory = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категория',
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
          child: CustomDropdown<String>.search(
            closeDropDownOnClearFilterSearch: true,
            items: categories,
            searchHintText: 'Поиск',
            overlayHeight: 300,
            decoration: CustomDropdownDecoration(
              closedFillColor: Colors.white,
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
                item,
                style: categoryTextStyle,
              );
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Text(
                selectedItem ?? 'Выберите категорию',
                style: categoryTextStyle,
              );
            },
            hintBuilder: (context, hint, enabled) => Text(
              'Выберите категорию',
              style: categoryTextStyle.copyWith(fontSize: 14),
            ),
            excludeSelected: false,
            initialItem: selectedCategory,
            onChanged: (value) {
              if (value != null) {
                widget.onSelectCategory(value);
                setState(() {
                  selectedCategory = value;
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