import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void DropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String, int) onSelect, 
  Deal deal,
) async {
  // НОВОЕ: Читаем флаг мультивыбора из настроек
  final prefs = await SharedPreferences.getInstance();
  final bool isMultiSelectEnabled = prefs.getBool('managing_deal_status_visibility') ?? false;

  String selectedValue = defaultValue;
  List<int> selectedStatusIds = [];
  bool isLoading = false;
print('DropdownBottomSheet: managing_deal_status_visibility = $isMultiSelectEnabled');
  print('DropdownBottomSheet: Режим работы = ${isMultiSelectEnabled ? "МУЛЬТИВЫБОР" : "ОДИНОЧНЫЙ"}');

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
                        return Center(child: Text(AppLocalizations.of(context)!.translate('error_text')));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(AppLocalizations.of(context)!.translate('loading')));
                      }

                      List<DealStatus> statuses = snapshot.data!;

                      return ListView(
                        children: statuses.map((DealStatus status) {
                          bool isSelected = selectedStatusIds.contains(status.id);
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                // НОВОЕ: Условная логика на основе флага
                                if (isMultiSelectEnabled) {
                                  // Режим мультивыбора
                                  if (isSelected) {
                                    selectedStatusIds.remove(status.id);
                                    if (selectedStatusIds.isEmpty) {
                                      selectedValue = '';
                                    }
                                  } else {
                                    selectedStatusIds.add(status.id);
                                    selectedValue = status.title;
                                  }
                                } else {
                                  // Режим одиночного выбора
                                  selectedStatusIds.clear();
                                  selectedStatusIds.add(status.id);
                                  selectedValue = status.title;
                                }
                              });
                            },
                            child: buildDropDownStyles(
                              text: status.title,
                              isSelected: isSelected,
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
                          if (selectedStatusIds.isNotEmpty) {
                            setState(() {
                              isLoading = true;
                            });

                            // Отправка всегда массивом (не изменяется)
                            ApiService().updateDealStatus(deal.id, deal.statusId, selectedStatusIds).then((_) {
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
                              onSelect(selectedValue, selectedStatusIds.first);
                            }).catchError((error) {
                              setState(() {
                                isLoading = false;
                              });

                              if (error is DealStatusUpdateException &&
                                  error.code == 422) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                     AppLocalizations.of(context)!.translate('cannot_move_deal_to_status'),
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
                              }
                            });
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