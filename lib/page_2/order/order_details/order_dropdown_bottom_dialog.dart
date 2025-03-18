import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

void OrderDropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String, int) onSelect,
  Map<String, dynamic> order, // Передаем объект order
) {
  String selectedValue = defaultValue;
  int? selectedStatusId;

  // Список статусов (локальный, пока нет API)
  final List<Map<String, dynamic>> orderStatuses = [
    {'id': 1, 'name': 'Новый'},
    {'id': 2, 'name': 'Ожидает оплаты'},
    {'id': 3, 'name': 'Оплачен'},
    {'id': 4, 'name': 'В обработке'},
    {'id': 5, 'name': 'Отправлен'},
    {'id': 6, 'name': 'Завершен'},
    {'id': 7, 'name': 'Отменен'},
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: 700,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xffDFE3EC),
                    borderRadius: BorderRadius.circular(1200),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: orderStatuses.map((status) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedValue = status['name'];
                            selectedStatusId = status['id'];
                          });
                        },
                        child: buildDropDownStyles(
                          text: status['name'],
                          isSelected: selectedValue == status['name'],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('save'),
                  buttonColor: const Color(0xff4F40EC),
                  textColor: Colors.white,
                  onPressed: () {
                    if (selectedStatusId != null) {
                      // Локальная логика: показываем сообщение об успехе
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .translate('status_changed_successfully'),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.green,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          duration: const Duration(seconds: 3),
                        ),
                      );

                      // Закрываем bottom sheet и вызываем callback
                      Navigator.pop(context);
                      onSelect(selectedValue, selectedStatusId!);
                    } else {
                      print('Статус не выбран');
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}