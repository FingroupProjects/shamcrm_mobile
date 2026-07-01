import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
  final colors = context.appColors;
  String selectedValue = defaultValue;
  int? selectedStatusId;
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: colors.surfacePrimary,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(1200),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppLocalizations.of(context)!.translate('select_status'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<MyTaskStatus>>(
                    future: ApiService().getMyTaskStatuses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.translate('error'),
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.translate('loading'),
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        );
                      }

                      final statuses = snapshot.data!;

                      return ListView(
                        children: statuses.map((status) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedValue = status.title;
                                selectedStatusId = status.id;
                              });
                            },
                            child: buildDropDownStyles(
                              context: context,
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
                          color: colors.buttonPrimaryBg,
                        ),
                      )
                    : CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('save'),
                        buttonColor: colors.buttonPrimaryBg,
                        textColor: colors.buttonPrimaryFg,
                        onPressed: () {
                          if (selectedStatusId == null) return;

                          setState(() {
                            isLoading = true;
                          });

                          ApiService()
                              .updateMyTaskStatus(
                            task.id,
                            task.statusId,
                            selectedStatusId!,
                          )
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .translate('status_changed_successfully'),
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textInverse,
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: colors.success,
                                elevation: 3,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.pop(context);
                            onSelect(selectedValue, selectedStatusId!);
                          }).catchError((_) {
                            setState(() {
                              isLoading = false;
                            });
                          });
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

class MyTaskStatusUpdateException implements Exception {
  final int statusCode;
  final String message;

  MyTaskStatusUpdateException(this.statusCode, this.message);
}
