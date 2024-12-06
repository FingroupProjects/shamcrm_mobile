import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/lead_model.dart'; 

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String) onSelect,
  Lead lead,
) {
  String selectedValue = defaultValue;
  int? selectedStatusId; 
  bool isLoading = false; 

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
                        return Center(child: Text('Загрузка....'));
                      }

                      List<LeadStatus> statuses = snapshot.data!;

                      return ListView(
                        children: statuses.map((LeadStatus status) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedValue = status.title; // Присваиваем новый статус
                                selectedStatusId = status.id; // Присваиваем id статуса
                              });
                            },
                            child: buildDropDownStyles(
                              text: status.title,
                              isSelected: selectedValue == status.title,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff1E2E52),
                        ),
                      )
                    : CustomButton(
                        buttonText: 'Сохранить',
                        buttonColor: Color(0xfff4F40EC),
                        textColor: Colors.white,
                        onPressed: () {
                          if (selectedStatusId != null) {
                            setState(() {
                              isLoading = true; // Start loading
                            });

                            ApiService()
                                .updateLeadStatus(
                                  lead.id, lead.statusId, selectedStatusId!
                                )
                                .then((_) {
                              Navigator.pop(context);
                              onSelect(selectedValue);
                            }).catchError((error) {
                              setState(() {
                                isLoading = false; // Stop loading
                              });

                              if (error is LeadStatusUpdateException &&
                                  error.code == 422) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Вы не можете переместить задачу на этот статус'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                Navigator.pop(context);
                              } else {
                                print('Ошибка обновления статуса задачи: $error');
                              }
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

class LeadStatusUpdateException implements Exception {
  final int code;
  final String message;

  LeadStatusUpdateException(this.code, this.message);

  @override
  String toString() => 'DealtatusUpdateException($code, $message)';
}
