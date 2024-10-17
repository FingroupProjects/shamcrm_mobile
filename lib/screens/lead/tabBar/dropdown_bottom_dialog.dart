import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/lead_model.dart'; // Import your LeadStatus model

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String) onSelect,
  Lead lead,
) {
  String selectedValue = defaultValue;
  int? selectedStatusId; // Для хранения идентификатора статуса

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
                    color: Color(0xfffDFE3EC),
                    borderRadius: BorderRadius.circular(1200),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<LeadStatus>>(
                    future: ApiService().getLeadStatuses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Ошибка: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('Нет доступных статусов'));
                      }

                      List<LeadStatus> statuses = snapshot.data!;

                      return ListView(
                        children: statuses.map((LeadStatus status) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedValue =
                                    status.title; // Присваиваем новый статус
                                selectedStatusId =
                                    status.id; // Присваиваем id статуса
                              });
                            },
                            child: _buildDropDownStyles(
                              text: status.title,
                              isSelected: selectedValue == status.title,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                CustomButton(
                  buttonText: 'Сохранить',
                  buttonColor: Color(0xfff4F40EC),
                  textColor: Colors.white,
                  onPressed: () {
                    if (selectedStatusId != null) {
                      // Передаем id статуса в метод обновления
                      ApiService()
                          .updateLeadStatus(
                              lead.id, lead.statusId, selectedStatusId!)
                          .then((_) {
                        // Закрываем диалог и обновляем данные
                        Navigator.pop(context);
                        onSelect(selectedValue);
                      }).catchError((error) {
                        print('Ошибка обновления статуса лида: $error');
                      });
                    } else {
                      print('Статус не выбран');
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

const Color backgroundColor = Color(0xFFF4F7FD);
const Color textColor = Color(0xFFf1E2E52);
const TextStyle titleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  fontFamily: 'Gilroy',
  color: textColor,
);

Widget _buildDropDownStyles({required String text, required bool isSelected}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 7),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Color(0xfff4F40EC) : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.transparent : Color(0xfff99A4BA),
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
              : Container(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: titleStyle,
          ),
        ),
        Image.asset(
          'assets/icons/arrow-right.png',
          width: 16,
          height: 16,
        ),
      ],
    ),
  );
}
