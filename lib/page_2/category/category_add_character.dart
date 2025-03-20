import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class AddCustomCharacterFieldDialog extends StatefulWidget {
  final Function(String, String) onAddField;

  AddCustomCharacterFieldDialog({required this.onAddField});

  @override
  _AddCustomCharacterFieldDialogState createState() => _AddCustomCharacterFieldDialogState();
}

class _AddCustomCharacterFieldDialogState extends State<AddCustomCharacterFieldDialog> {
  final TextEditingController fieldNameController = TextEditingController();
  String? selectedType;
  bool isManualInput = true; // По умолчанию выбран ручной ввод

  final List<String> types = [
    'см', // Сантиметры
    'кг', // Килограммы
    'количество', // Количество (штуки)
    'мм', // Миллиметры
    'м', // Метры
    'км', // Километры
    'г', // Граммы
    'т', // Тонны
    'л', // Литр
    'мл', // Миллилитры
    'шт', // Штуки
    'уп', // Упаковки
    'пара', // Пары
    'комплект', // Комплекты
    'час', // Часы
    'мин', // Минуты
    'сек', // Секунды
    'день', // Дни
    'неделя', // Недели
    'месяц', // Месяцы
    'год', // Годы
    'м²', // Квадратные метры
    'м³', // Кубические метры
    '°C', // Градусы Цельсия
    '°F', // Градусы Фаренгейта
    'кВт', // Киловатты
    'Вт', // Ватты
    'А', // Амперы
    'В', // Вольты
    'Ом', // Омы
    'Гц', // Герцы
    'об/мин', // Обороты в минуту
    'км/ч', // Километры в час
    'м/с', // Метры в секунду
    'Па', // Паскали
    'бар', // Бары
    'атм', // Атмосферы
    'руб', // Рубли
    'USD', // Доллары США
    'EUR', // Евро
    'GBP', // Фунты стерлингов
    'JPY', // Японские иены
    'дБ', // Децибелы
    'pH', // Уровень pH
    'ppm', // Частей на миллион
    '%', // Проценты
    'ед.', // Единицы
    'пачка', // Пачки
    'коробка', // Коробки
    'ящик', // Ящики
    'блок', // Блоки
    'лист', // Листы
    'рулон', // Рулоны
    'пог. м', // Погонные метры
    'кв. м', // Квадратные метры
    'куб. м', // Кубические метры
    'га', // Гектары
    'акр', // Акры
    'сотка', // Сотки
    'ккал', // Килокалории
    'кДж', // Килоджоули
    'кал', // Калории
    'Дж', // Джоули
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        AppLocalizations.of(context)!.translate('Добавить характеристику'),
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
      ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Radio(
                value: true,
                groupValue: isManualInput,
                onChanged: (value) {
                  setState(() {
                    isManualInput = value as bool;
                  });
                },
              ),
              Text(AppLocalizations.of(context)!.translate('вручную')),
              Radio(
                value: false,
                groupValue: isManualInput,
                onChanged: (value) {
                  setState(() {
                    isManualInput = value as bool;
                  });
                },
              ),
              Text(AppLocalizations.of(context)!.translate('из списка')),
            ],
          ),
          const SizedBox(height: 16),
          if (isManualInput)
            TextField(
              controller: fieldNameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('введите название'),
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff99A4BA),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xffF4F7FD),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            )
          else
            DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              value: selectedType,
              items: types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                });
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('Выберете тип'),
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff99A4BA),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xffF4F7FD),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                buttonColor: Colors.red,
                textColor: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('add'),
                onPressed: () {
                  if (isManualInput && fieldNameController.text.isNotEmpty) {
                    widget.onAddField(fieldNameController.text, 'ручной ввод'); // Передаем название и тип
                    Navigator.of(context).pop();
                  } else if (!isManualInput && selectedType != null) {
                    widget.onAddField(selectedType!, 'выбор из списка'); // Передаем выбранный тип
                    Navigator.of(context).pop();
                  } else {
                    // Показать сообщение об ошибке, если данные не заполнены
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.translate('select_type_error')),
                      ),
                    );
                  }
                },
                buttonColor: Color(0xff1E2E52),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}