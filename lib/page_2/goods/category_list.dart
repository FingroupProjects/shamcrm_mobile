import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class ProductCharacteristic {
  final String name; // Название характеристики (например, "Модель")
  final String hintText; // Подсказка для поля ввода (например, "Введите модель")
  final TextInputType keyboardType; // Тип клавиатуры (по умолчанию текстовый)

  ProductCharacteristic({
    required this.name,
    required this.hintText,
    this.keyboardType = TextInputType.text,
  });
}

final Map<String, List<ProductCharacteristic>> categoryCharacteristics = {
  'Электроника': [
    ProductCharacteristic(name: 'Модель', hintText: 'Введите модель'),
    ProductCharacteristic(name: 'Производитель', hintText: 'Введите производителя'),
    ProductCharacteristic(name: 'Гарантия', hintText: 'Введите срок гарантии'),
    ProductCharacteristic(name: 'Цвет', hintText: 'Введите цвет'),
    ProductCharacteristic(name: 'Операционная система', hintText: 'Введите ОС'),
  ],
  'Бытовая техника': [
    ProductCharacteristic(name: 'Мощность', hintText: 'Введите мощность'),
    ProductCharacteristic(name: 'Вес', hintText: 'Введите вес'),
    ProductCharacteristic(name: 'Габариты', hintText: 'Введите габариты'),
    ProductCharacteristic(name: 'Энергопотребление', hintText: 'Введите класс энергопотребления'),
    ProductCharacteristic(name: 'Материал', hintText: 'Введите материал'),
  ],
  'Продукты питания': [
    ProductCharacteristic(name: 'Срок годности', hintText: 'Введите срок годности'),
    ProductCharacteristic(name: 'Вес', hintText: 'Введите вес'),
    ProductCharacteristic(name: 'Состав', hintText: 'Введите состав'),
    ProductCharacteristic(name: 'Количество', hintText: 'Введите количество'),
    ProductCharacteristic(name: 'Условия хранения', hintText: 'Введите условия хранения'),
  ],
  'Одежда': [
    ProductCharacteristic(name: 'Размер', hintText: 'Введите размер'),
    ProductCharacteristic(name: 'Цвет', hintText: 'Введите цвет'),
    ProductCharacteristic(name: 'Материал', hintText: 'Введите материал'),
    ProductCharacteristic(name: 'Сезон', hintText: 'Введите сезон'),
    ProductCharacteristic(name: 'Бренд', hintText: 'Введите бренд'),
  ],
  'Обувь': [
    ProductCharacteristic(name: 'Размер', hintText: 'Введите размер'),
    ProductCharacteristic(name: 'Цвет', hintText: 'Введите цвет'),
    ProductCharacteristic(name: 'Материал', hintText: 'Введите материал'),
    ProductCharacteristic(name: 'Тип обуви', hintText: 'Введите тип обуви'),
    ProductCharacteristic(name: 'Бренд', hintText: 'Введите бренд'),
  ],
  'Аксессуары': [
    ProductCharacteristic(name: 'Тип аксессуара', hintText: 'Введите тип аксессуара'),
    ProductCharacteristic(name: 'Цвет', hintText: 'Введите цвет'),
    ProductCharacteristic(name: 'Материал', hintText: 'Введите материал'),
    ProductCharacteristic(name: 'Бренд', hintText: 'Введите бренд'),
    ProductCharacteristic(name: 'Размер', hintText: 'Введите размер (если применимо)'),
  ],
  'Мебель': [
    ProductCharacteristic(name: 'Материал', hintText: 'Введите материал'),
    ProductCharacteristic(name: 'Цвет', hintText: 'Введите цвет'),
    ProductCharacteristic(name: 'Габариты', hintText: 'Введите габариты'),
    ProductCharacteristic(name: 'Вес', hintText: 'Введите вес'),
    ProductCharacteristic(name: 'Стиль', hintText: 'Введите стиль мебели'),
  ],
  'Спортивные товары': [
    ProductCharacteristic(name: 'Тип товара', hintText: 'Введите тип товара'),
    ProductCharacteristic(name: 'Материал', hintText: 'Введите материал'),
    ProductCharacteristic(name: 'Цвет', hintText: 'Введите цвет'),
    ProductCharacteristic(name: 'Размер', hintText: 'Введите размер (если применимо)'),
    ProductCharacteristic(name: 'Бренд', hintText: 'Введите бренд'),
  ],
  'Книги': [
    ProductCharacteristic(name: 'Автор', hintText: 'Введите автора'),
    ProductCharacteristic(name: 'Жанр', hintText: 'Введите жанр'),
    ProductCharacteristic(name: 'Количество страниц', hintText: 'Введите количество страниц'),
    ProductCharacteristic(name: 'Издательство', hintText: 'Введите издательство'),
    ProductCharacteristic(name: 'Год издания', hintText: 'Введите год издания'),
  ],
  'Игрушки': [
    ProductCharacteristic(name: 'Тип игрушки', hintText: 'Введите тип игрушки'),
    ProductCharacteristic(name: 'Материал', hintText: 'Введите материал'),
    ProductCharacteristic(name: 'Возрастная группа', hintText: 'Введите возрастную группу'),
    ProductCharacteristic(name: 'Цвет', hintText: 'Введите цвет'),
    ProductCharacteristic(name: 'Бренд', hintText: 'Введите бренд'),
  ],
};

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
  final List<String> categories = [
    'Электроника', 
    'Бытовая техника', 
    'Продукты питания',
    'Одежда', 
    'Обувь', 
    'Аксессуары', 
    'Мебель', 
    'Спортивные товары', 
    'Книги', 
    'Игрушки'
  ];
  
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
          AppLocalizations.of(context)!.translate('category'), 
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
                item,
                style: categoryTextStyle,
              );
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Text(
                selectedItem ?? AppLocalizations.of(context)!.translate('select_category'), 
                style: categoryTextStyle,
              );
            },
            hintBuilder: (context, hint, enabled) => Text(
              AppLocalizations.of(context)!.translate('select_category'), 
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