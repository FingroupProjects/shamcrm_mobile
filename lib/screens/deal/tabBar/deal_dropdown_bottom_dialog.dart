import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showDealStatusBottomSheet(
    BuildContext context,
    String defaultValue,
    Function(String, List<int>) onSelect,
    Deal deal,
    ApiService apiService,
    ) async {
  // Check permissions first
  final canEdit = await apiService.hasPermission('deal.update');
  final canDelete = await apiService.hasPermission('deal.delete');
  final canRead = await apiService.hasPermission('deal.read');

  if (!canEdit && !canDelete && !canRead) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('no_permission'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return;
  }

  // ✅ НОВАЯ ЛОГИКА: Проверяем оба флага
  final prefs = await SharedPreferences.getInstance();
  final bool managingVisibility = prefs.getBool('managing_deal_status_visibility') ?? false;
  final bool changeMultiple = prefs.getBool('change_deal_to_multiple_statuses') ?? false;
  
  // Если хотя бы один флаг true, включаем мультивыбор
  final bool isMultiSelectEnabled = managingVisibility || changeMultiple;
  
  final String? organizationId = prefs.getString('organization_id') ?? '1';
  final String? salesFunnelId = prefs.getString('sales_funnel_id') ?? '1';

  debugPrint('DropdownBottomSheet: organizationId = $organizationId');
  debugPrint('DropdownBottomSheet: salesFunnelId = $salesFunnelId');
  debugPrint('DropdownBottomSheet: managing_deal_status_visibility = $managingVisibility');
  debugPrint('DropdownBottomSheet: change_deal_to_multiple_statuses = $changeMultiple');
  debugPrint('DropdownBottomSheet: isMultiSelectEnabled = $isMultiSelectEnabled');
  debugPrint('DropdownBottomSheet: Режим работы = ${isMultiSelectEnabled ? "МУЛЬТИВЫБОР" : "ОДИНОЧНЫЙ"}');
  
  String selectedValue = defaultValue;
  List<int> selectedStatusIds = [];
  bool isLoading = false;
  bool isInitializing = true;

  // Initialize selected statuses from API
  try {
    final dealData = await apiService.getDealById(deal.id);
    if (dealData?.dealStatuses != null && dealData!.dealStatuses!.isNotEmpty) {
      selectedStatusIds = dealData.dealStatuses!.map((s) => s.id).toList();
      debugPrint('✅ Initialized from API: $selectedStatusIds');
    } else {
      selectedStatusIds = [deal.statusId];
      debugPrint('⚠️ Using current statusId: ${deal.statusId}');
    }
  } catch (e) {
    debugPrint('❌ Error loading deal statuses: $e');
    selectedStatusIds = [deal.statusId];
  }
  isInitializing = false;

  if (context.mounted) {
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
                      future: apiService.getDealStatuses(includeAll: true),
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
                                  if (isMultiSelectEnabled) {
                                    // Multi-select mode
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
                                    // Single-select mode
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
                    onPressed: selectedStatusIds.isEmpty ? null : () {
                      setState(() {
                        isLoading = true;
                      });

                      apiService.updateDealStatus(
                        deal.id, 
                        deal.statusId,  // from_status_id (текущий статус)
                        selectedStatusIds,
                        isMultiSelect: isMultiSelectEnabled,  // ← передаём флаг
                      ).then((_) {
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

                        debugPrint('✅ Deal status updated: $selectedStatusIds');
                        Navigator.pop(context);
                        onSelect(selectedValue, selectedStatusIds);
                      }).catchError((error) {
                        setState(() {
                          isLoading = false;
                        });

                        if (error is DealStatusUpdateException && error.code == 422) {
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
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.translate('error_text'),
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
                        }
                      });
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
}

class DealStatusUpdateException implements Exception {
  final int code;
  final String message;

  DealStatusUpdateException(this.code, this.message);

  @override
  String toString() => 'DealStatusUpdateException($code, $message)';
}