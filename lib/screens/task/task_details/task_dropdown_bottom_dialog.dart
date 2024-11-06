import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:flutter/material.dart';

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String) onSelect,
  Task task,
) {
  String selectedValue = defaultValue;
  int? selectedStatusId;

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
                  child: FutureBuilder<List<TaskStatus>>(
                    future: ApiService().getTaskStatuses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Ошибка: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('Нет доступных статусов'));
                      }

                      List<TaskStatus> statuses = snapshot.data!;

                      return ListView(
                        children: statuses.map((TaskStatus status) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedValue = status.taskStatus.name; // Изменено
                                selectedStatusId = status.taskStatus.id; // Изменено
                              });
                            },
                            child: buildDropDownStyles(
                              text: status.taskStatus.name, // Изменено
                              isSelected: selectedValue == status.taskStatus.name, // Изменено
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
                      ApiService()
                          .updateTaskStatus(
                              task.id, task.statusId, selectedStatusId!)
                          .then((_) {
                        Navigator.pop(context);
                        onSelect(selectedValue);
                      }).catchError((error) {
                        print('Ошибка обновления статуса задачи: $error');
                      });
                    } else {
                      print('Статус не выбран');
                    }
                  },
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}
