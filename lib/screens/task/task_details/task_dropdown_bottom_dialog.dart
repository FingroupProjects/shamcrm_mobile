import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/task/task_model.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/undo_snackbar.dart';
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
    backgroundColor: context.appColors.surfacePrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: 700,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 7),
                  decoration: BoxDecoration(
                    color: context.appColors.borderSubtle,
                    borderRadius: BorderRadius.circular(1200),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sync_alt_rounded,
                        size: 18,
                        color: context.appColors.buttonPrimaryBg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Выполнение',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Выберите новый статус задачи',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
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
                                  selectedValue == status.taskStatus!.name, context: context,
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
                          color: context.appColors.buttonPrimaryBg,
                        ),
                      )
                    : CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('save'),
                        buttonColor: context.appColors.buttonPrimaryBg,
                        textColor: context.appColors.buttonPrimaryFg,
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

                            final previousStatusId = task.statusId;
                            final previousTitle = defaultValue;
                            final nextStatusId = selectedStatusId!;
                            final nextTitle = selectedValue;
                            final l10n = AppLocalizations.of(context)!;

                            ApiService()
                                .updateTaskStatus(
                              task.id,
                              task.statusId,
                              nextStatusId,
                              reasonForRefusalId: refusalData?.reasonId,
                              reasonForRefusal: refusalData?.comment,
                            )
                                .then((_) {
                              setState(() {
                                isLoading = false;
                              });

                              Navigator.pop(context);
                              onSelect(nextTitle, nextStatusId);
                              if (nextStatusId != previousStatusId) {
                                UndoActions.showRevert(
                                  message: l10n.translate('undo_status_changed'),
                                  actionLabel: l10n.translate('undo'),
                                  onUndo: () async {
                                    await ApiService().updateTaskStatus(
                                      task.id,
                                      nextStatusId,
                                      previousStatusId,
                                    );
                                    onSelect(previousTitle, previousStatusId);
                                  },
                                );
                              }
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
                                      color: context.appColors.textInverse,
                                    ),
                                  ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  backgroundColor: context.appColors.error,
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
