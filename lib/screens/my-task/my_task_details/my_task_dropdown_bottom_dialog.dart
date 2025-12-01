import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String, int) onSelect, 
  MyTask task,
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
                  child: FutureBuilder<List<MyTaskStatus>>(
                    future: ApiService().getMyTaskStatuses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(AppLocalizations.of(context)!.translate('error')));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(AppLocalizations.of(context)!.translate('loading')));
                      }
                      List<MyTaskStatus> statuses = snapshot.data!;

                      return ListView(
                        children: statuses.map((MyTaskStatus status) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedValue = status.title ?? " ";
                                selectedStatusId = status.id;
                              });
                            },
                            child: buildDropDownStyles(
                              text: status.title ?? "",
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
                        buttonText: AppLocalizations.of(context)!.translate('save'),
                        buttonColor: Color(0xfff4F40EC),
                        textColor: Colors.white,
                        onPressed: () {
                          if (selectedStatusId != null) {
                            setState(() {
                              isLoading = true; 
                            });

                            ApiService().updateMyTaskStatus(task.id, task.statusId, selectedStatusId!).then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text(
                                     AppLocalizations.of(context)!.translate('status_changed_successfully'),
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
                                isLoading = false; 
                              });

                              Navigator.pop(context);
                              onSelect(selectedValue, selectedStatusId!);
                            }).catchError((error) {
                              setState(() {
                                isLoading = false; 
                              });

                              if (error is MyTaskStatusUpdateException &&
                                  error.statusCode == 422) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!.translate('cannot_move_task_to_status'),
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
                                    backgroundColor: Colors.red,
                                    elevation: 3,
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                Navigator.pop(context);
                              } else {
                                //print('Ошибка обновления статуса задачи!rror');
                              }
                            });
                          } else {
                            //print('Статус не выбран');
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

class MyTaskStatusUpdateException implements Exception {
  final int statusCode;
  final String message;

  MyTaskStatusUpdateException(this.statusCode, this.message);
}
