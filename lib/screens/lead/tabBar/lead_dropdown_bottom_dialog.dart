import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/lead_model.dart';

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String, int) onSelect, 
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
                        return Center(child: Text(AppLocalizations.of(context)!.translate('error_text')));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(AppLocalizations.of(context)!.translate('loading')));
                      }

                      List<LeadStatus> statuses = snapshot.data!;

                      statuses = statuses.where((status) => status.lead_status_id == null).toList();

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
                        buttonText: AppLocalizations.of(context)!.translate('save'),
                        buttonColor: Color(0xfff4F40EC),
                        textColor: Colors.white,
                        onPressed: () {
                          if (selectedStatusId != null) {
                            setState(() {
                              isLoading = true;
                            });

                            ApiService().updateLeadStatus(lead.id, lead.statusId, selectedStatusId!).then((_) {
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
                              Navigator.pop(context);
                              
                              onSelect(selectedValue, selectedStatusId!);
                            }).catchError((error) {
                              setState(() {
                                isLoading = false;
                              });
                              if (error is LeadStatusUpdateException && error.code == 422) {
                                String errorMessage = error.message.replaceAll(RegExp(r'\(and \d+ more error[s]?\)'), '').trim();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorMessage, 
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
                                print('Ошибка обновления статуса задачи!rror');
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
  String toString() => 'LeadStatusUpdateException($code, $message)';
}
