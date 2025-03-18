import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';

class SubCategoryDropdownWidget extends StatefulWidget {
  final String? subSelectedCategory;
  final Function(String) onSelectCategory;

  SubCategoryDropdownWidget({
    super.key,
    required this.onSelectCategory,
    this.subSelectedCategory,
  });

  @override
  State<SubCategoryDropdownWidget> createState() => _SubCategoryDropdownWidgetState();
}

class _SubCategoryDropdownWidgetState extends State<SubCategoryDropdownWidget> {
  final List<String> subCategories = [
   'Смартфоны', 'Ноутбуки', 'Планшеты', 'Телевизоры', 'Аксессуары', 
   'Стиральные машины', 'Холодильники', 'Пылесосы', 'Микроволновки', 'Чайники'
   'Фрукты и овощи', 'Молочные продукты', 'Мясо и птица', 'Кондитерские изделия', 'Напитки'];

  String? subSelectedCategory;

@override
void initState() {
  super.initState();
  if (widget.subSelectedCategory != null && subCategories.contains(widget.subSelectedCategory)) {
    subSelectedCategory = widget.subSelectedCategory;
  } else {
    subSelectedCategory = null;
  }
}
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Подкатегория',
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
          items: subCategories,
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
            'Выберите подкатегорию',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          initialItem: subSelectedCategory,
          onChanged: (value) {
            if (value != null) {
              widget.onSelectCategory(value);
              setState(() {
                subSelectedCategory = value;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}
