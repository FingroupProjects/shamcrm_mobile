import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/lead_model.dart';

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String, int) onSelect,
  Lead lead,
) {
  final rootContext = context;
  String selectedValue = defaultValue;
  int? selectedStatusId;
  bool isLoading = false;
  List<LeadStatus> loadedStatuses = [];

  showModalBottomSheet(
    context: context,
    backgroundColor: rootContext.appColors.surfacePrimary,
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
                    color: rootContext.appColors.borderSubtle,
                    borderRadius: BorderRadius.circular(1200),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<LeadStatus>>(
                    future: ApiService().getLeadStatuses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(AppLocalizations.of(context)!
                                .translate('error_text')));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                            child: Text(AppLocalizations.of(context)!
                                .translate('loading')));
                      }

                      List<LeadStatus> statuses = snapshot.data!;
                      loadedStatuses = statuses;

                      return ListView(
                        children: statuses.map((LeadStatus status) {
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
                          color: rootContext.appColors.buttonPrimaryBg,
                        ),
                      )
                    : CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('save'),
                        buttonColor: rootContext.appColors.buttonPrimaryBg,
                        textColor: rootContext.appColors.buttonPrimaryFg,
                        onPressed: () async {
                          if (selectedStatusId != null) {
                            final targetStatus =
                                loadedStatuses.cast<LeadStatus?>().firstWhere(
                                      (status) =>
                                          status?.id == selectedStatusId,
                                      orElse: () => null,
                                    );
                            final statusChanged =
                                selectedStatusId != lead.statusId;
                            final requiresReason = statusChanged &&
                                targetStatus != null &&
                                targetStatus.isFailure;

                            ReasonForRefusalSubmitData? refusalData;
                            if (requiresReason) {
                              refusalData = await showReasonForRefusalDialog(
                                context: context,
                                type: 'lead',
                              );
                              if (refusalData == null) {
                                setState(() {
                                  isLoading = false;
                                });
                                return;
                              }
                            }

                            setState(() {
                              isLoading = true;
                            });

                            ApiService()
                                .updateLeadStatus(
                              lead.id,
                              lead.statusId,
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
                                    style: rootContext.appTextStyles.bodyMd
                                        .copyWith(
                                      color: rootContext.appColors.textInverse,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor:
                                      rootContext.appColors.success,
                                  elevation: 3,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              Navigator.pop(context);

                              onSelect(selectedValue, selectedStatusId!);
                            }).catchError((error) {
                              setState(() {
                                isLoading = false;
                              });
                              if (error is LeadStatusUpdateException &&
                                  error.code == 422) {
                                String errorMessage = error.message
                                    .replaceAll(
                                        RegExp(r'\(and \d+ more error[s]?\)'),
                                        '')
                                    .trim();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorMessage,
                                      style: rootContext.appTextStyles.bodyMd
                                          .copyWith(
                                        color:
                                            rootContext.appColors.textInverse,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor:
                                        rootContext.appColors.error,
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

class LeadStatusUpdateException implements Exception {
  final int code;
  final String message;

  LeadStatusUpdateException(this.code, this.message);

  @override
  String toString() => 'LeadStatusUpdateException($code, $message)';
}
