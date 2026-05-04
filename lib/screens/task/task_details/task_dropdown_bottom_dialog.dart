import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String, int) onSelect,
  Task task,
) {
  final rootContext = context;
  String selectedValue = defaultValue;
  int? selectedStatusId;
  bool isLoading = false;
  List<TaskStatus> loadedStatuses = [];

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
                        return Center(
                            child: Text(AppLocalizations.of(context)!
                                .translate('error')));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                            child: Text(AppLocalizations.of(context)!
                                .translate('loading')));
                      }
                      List<TaskStatus> statuses = snapshot.data!;
                      loadedStatuses = statuses;

                      return ListView(
                        children: statuses.map((TaskStatus status) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedValue = status.taskStatus!.name ?? " ";
                                selectedStatusId = status.id;
                              });
                            },
                            child: buildDropDownStyles(
                              text: status.taskStatus!.name ?? "",
                              isSelected:
                                  selectedValue == status.taskStatus!.name,
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
                        buttonText:
                            AppLocalizations.of(context)!.translate('save'),
                        buttonColor: Color(0xfff4F40EC),
                        textColor: Colors.white,
                        onPressed: () async {
                          if (selectedStatusId != null) {
                            final prefs = await SharedPreferences.getInstance();
                            final askReason =
                                prefs.getBool('ask_reason_for_refusal') ??
                                    false;
                            final targetStatus =
                                loadedStatuses.cast<TaskStatus?>().firstWhere(
                                      (status) =>
                                          status?.id == selectedStatusId,
                                      orElse: () => null,
                                    );

                            ReasonForRefusalSubmitData? refusalData;
                            if (askReason &&
                                targetStatus != null &&
                                targetStatus.isUnassembled) {
                              refusalData = await showReasonForRefusalDialog(
                                context: context,
                                type: 'task',
                              );
                              if (refusalData == null) {
                                return;
                              }
                            }

                            setState(() {
                              isLoading = true;
                            });

                            ApiService()
                                .updateTaskStatus(
                              task.id,
                              task.statusId,
                              selectedStatusId!,
                              reasonForRefusalId: refusalData?.reasonId,
                              reasonForRefusal: refusalData?.comment,
                            )
                                .then((_) {
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.translate(
                                        'status_changed_successfully'),
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.green,
                                  elevation: 3,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
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

                              if (error is TaskStatusUpdateException &&
                                  error.statusCode == 422) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error.message,
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.red,
                                    elevation: 3,
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
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

class TaskStatusUpdateException implements Exception {
  final int statusCode;
  final String message;

  TaskStatusUpdateException(this.statusCode, this.message);
}
