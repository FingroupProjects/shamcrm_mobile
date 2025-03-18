import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';

class CategoryDropdownWidget extends StatefulWidget {
  final String? selectedCategory;
  final Function(String) onSelectCategory;

  CategoryDropdownWidget({
    super.key,
    required this.onSelectCategory,
    this.selectedCategory,
  });

  @override
  State<CategoryDropdownWidget> createState() => _CategoryDropdownWidgetState();
}

class _CategoryDropdownWidgetState extends State<CategoryDropdownWidget> {
  final List<String> categories = ['Электроника', 'Бытовая техника', 'Продукты питания'];
  String? selectedCategory;

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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>.search(
          closeDropDownOnClearFilterSearch: true,
          items: categories,
          searchHintText: 'Поиск',
          overlayHeight: 300,
          enabled: true,
          decoration: CustomDropdownDecoration(
            closedFillColor: Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(color: Color(0xffF4F7FD), width: 1),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(color: Color(0xffF4F7FD), width: 1),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item,
              style: TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            );
            
          },
          hintBuilder: (context, hint, enabled) => Text(
            'Выберите категорию',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
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
      ],
    );
  }
}
