import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:flutter/material.dart';

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String) onSelect,
  Deal deal,
) {
  String selectedValue = defaultValue;
  int? selectedStatusId;
  bool isLoading = false; // Variable to manage the loading state

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
                  child: FutureBuilder<List<DealStatus>>(
                    future: ApiService().getDealStatuses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Ошибка: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('Загрузка....'));
                      }

                      List<DealStatus> statuses = snapshot.data!;

                      return ListView(
                        children: statuses.map((DealStatus status) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedValue = status.title; // Set the selected status
                                selectedStatusId = status.id; // Set the status ID
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

                            ApiService().updateDealStatus(deal.id, deal.statusId, selectedStatusId!).then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text(
                                     'Статус успешно изменен!',
                                     style: TextStyle(
                                       fontFamily: 'Gilroy',
                                       fontSize: 16,
                                       fontWeight: FontWeight.w500,
                                       color: Colors.white,
                                     ),
                                   ),
                                   behavior: SnackBarBehavior.floating,
                                   margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   backgroundColor: Colors.green,
                                   elevation: 3,
                                   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                   duration: Duration(seconds: 3),
                                 ),
                               );
                              setState(() {
                                isLoading = false; // Stop loading
                              });

                              Navigator.pop(context);
                              onSelect(selectedValue);
                            }).catchError((error) {
                              setState(() {
                                isLoading = false; // Stop loading
                              });

                              if (error is DealStatusUpdateException &&
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

class DealStatusUpdateException implements Exception {
  final int code;
  final String message;

  DealStatusUpdateException(this.code, this.message);

  @override
  String toString() => 'DealtatusUpdateException($code, $message)';
}
