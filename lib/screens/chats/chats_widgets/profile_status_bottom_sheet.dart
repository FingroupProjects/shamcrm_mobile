import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Модальное окно для изменения статуса лида из профиля
void showProfileStatusBottomSheet(
  BuildContext context,
  int leadId,
  int currentStatusId,
  String currentStatusTitle,
  Function() onStatusChanged,
) {
  String selectedValue = currentStatusTitle;
  int? selectedStatusId = currentStatusId;
  bool isLoading = false;
  List<LeadStatus>? cachedStatuses; // Кешируем статусы

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Индикатор модалки
                Container(
                  width: 100,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Color(0xffDFE3EC),
                    borderRadius: BorderRadius.circular(1200),
                  ),
                ),
                
                // Заголовок
                Text(
                  AppLocalizations.of(context)!.translate('change_status'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Список статусов
                Expanded(
                  child: cachedStatuses == null
                      ? FutureBuilder<List<LeadStatus>>(
                          future: ApiService().getLeadStatuses(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff1E2E52),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  AppLocalizations.of(context)!.translate('error_text'),
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  AppLocalizations.of(context)!.translate('no_statuses'),
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    color: Color(0xff6E7C97),
                                  ),
                                ),
                              );
                            }

                            // Кешируем статусы после первой загрузки
                            cachedStatuses = snapshot.data!
                                .where((status) => status.lead_status_id == null)
                                .toList();

                            return _buildStatusList(cachedStatuses!, selectedValue, (status) {
                              setState(() {
                                selectedValue = status.title;
                                selectedStatusId = status.id;
                              });
                            });
                          },
                        )
                      : _buildStatusList(cachedStatuses!, selectedValue, (status) {
                          setState(() {
                            selectedValue = status.title;
                            selectedStatusId = status.id;
                          });
                        }),
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка сохранения
                CustomButton(
                  buttonText: isLoading
                      ? ''
                      : AppLocalizations.of(context)!.translate('save'),
                  buttonColor: Color(0xff4F40EC),
                  textColor: Colors.white,
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (selectedStatusId != null && selectedStatusId != currentStatusId) {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              await ApiService().updateLeadStatus(
                                leadId,
                                currentStatusId,
                                selectedStatusId!,
                              );

                              // Закрываем модалку
                              if (context.mounted) {
                                Navigator.pop(context);

                                // Показываем успешное уведомление
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

                                // Вызываем callback для обновления данных
                                onStatusChanged();
                              }
                            } catch (error) {
                              setState(() {
                                isLoading = false;
                              });

                              if (!context.mounted) return;

                              // Получаем сообщение об ошибке
                              String errorMessage;
                              if (error is LeadStatusUpdateException) {
                                // Используем message из exception
                                errorMessage = error.message;
                              } else {
                                // Общая ошибка
                                errorMessage = AppLocalizations.of(context)!.translate('error_text');
                              }

                              Navigator.pop(context);

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
                            }
                          } else {
                            // Статус не изменился - просто закрываем
                            Navigator.pop(context);
                          }
                        },
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : null,
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

/// Виджет списка статусов
Widget _buildStatusList(
  List<LeadStatus> statuses,
  String selectedValue,
  Function(LeadStatus) onStatusSelected,
) {
  return ListView.builder(
    itemCount: statuses.length,
    itemBuilder: (context, index) {
      final status = statuses[index];
      return GestureDetector(
        onTap: () => onStatusSelected(status),
        child: buildDropDownStyles(
          text: status.title,
          isSelected: selectedValue == status.title,
        ),
      );
    },
  );
}

/// Exception для обработки ошибок обновления статуса
class LeadStatusUpdateException implements Exception {
  final int code;
  final String message;

  LeadStatusUpdateException(this.code, this.message);

  @override
  String toString() => 'LeadStatusUpdateException($code, $message)';
}