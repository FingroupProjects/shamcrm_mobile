import 'package:crm_task_manager/bloc/history_lead/history_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead/history_event.dart';
import 'package:crm_task_manager/bloc/history_lead/history_state.dart';
import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActionHistoryWidget extends StatefulWidget {
  final int leadId;

  ActionHistoryWidget({required this.leadId});

  @override
  _ActionHistoryWidgetState createState() => _ActionHistoryWidgetState();
}

class _ActionHistoryWidgetState extends State<ActionHistoryWidget> {
  bool isActionHistoryExpanded = false;
  List<LeadHistory> actionHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(FetchLeadHistory(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          // return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        } else if (state is HistoryLoaded) {
          actionHistory = state.leadHistory;
        } else if (state is HistoryError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${state.message}',
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
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      duration: Duration(seconds: 3),
                    ),
                  );
                });
        }

        return _buildExpandableActionContainer(
          'История действий',
          _buildActionHistoryItems(actionHistory),
          isActionHistoryExpanded,
          () {
            setState(() {
              isActionHistoryExpanded = !isActionHistoryExpanded;
            });
          },
        );
      },
    );
  }

  Widget _buildExpandableActionContainer(
    String title,
    List<String> items,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(title),
            SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: isExpanded
                  ? SizedBox(
                      height: 250, // Ограничиваем высоту для прокрутки
                      child: SingleChildScrollView(
                        child: _buildItemList(items),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xfff1E2E52),
          ),
        ),
        Image.asset(
          'assets/icons/tabBar/dropdown.png',
          width: 16,
          height: 16,
        ),
      ],
    );
  }

Column _buildItemList(List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items.map((item) {
      return _buildActionItem(item);
    }).toList(),
  );
}

Widget _buildActionItem(String item) {
  final parts = item.split('\n');
  final status = parts[0];
  final userName = parts.length > 1 ? parts[1] : '';
  final additionalDetails = parts.sublist(2); 

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow(status, userName),
        SizedBox(height: 10),
        if (additionalDetails.isNotEmpty) _buildAdditionalDetails(additionalDetails),
      ],
    ),
  );
}


  Row _buildStatusRow(String status, String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xfff1E2E52),
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 3,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            userName,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xfff1E2E52),
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Column _buildAdditionalDetails(List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.where((detail) => detail.isNotEmpty).map((detail) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff1E2E52),
                  overflow: TextOverflow.ellipsis, // Ensures long text is truncated
                ),
                maxLines: 2,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

List<String> _buildActionHistoryItems(List<LeadHistory> history) {
  return history.map((entry) {
    final changes = entry.changes;

    String formatBirthday(String? birthdayString) {
  if (birthdayString == null || birthdayString == "Не указано") {
    return "Не указано";
  }

  try {
    DateTime birthday = DateTime.parse(birthdayString);
    return DateFormat('dd-MM-yyyy').format(birthday);
  } catch (e) {
    return "Не указано"; 
  }
}

    final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(entry.date.toLocal());
    String actionDetail = '${entry.status}\n${entry.user.name} $formattedDate';

    if (changes != null) {
      // Позиция
      // Статус клиента
      if (changes.leadStatusNewValue != null || changes.leadStatusPreviousValue != null) {
        actionDetail +=
            '\nСтатус: ${changes.leadStatusPreviousValue ?? "Не указано"} > ${changes.leadStatusNewValue ?? "Не указано"}';
      }

      // Название
      if (changes.historyNamePreviousValue != null || changes.historyNameNewValue != null) {
        actionDetail +=
            '\nНазвание: ${changes.historyNamePreviousValue ?? "Не указано"} > ${changes.historyNameNewValue ?? "Не указано"}';
      }
      
      // Email
      if (changes.emailPreviousValue != null || changes.emailNewValue != null) {
        actionDetail +=
            '\nEmail: ${changes.emailPreviousValue ?? "Не указано"} > ${changes.emailNewValue ?? "Не указано"}';
      }

      // Телефон
      if (changes.phonePreviousValue != null || changes.phoneNewValue != null) {
        actionDetail +=
            '\nТелефон: ${changes.phonePreviousValue ?? "Не указано"} > ${changes.phoneNewValue ?? "Не указано"}';
      }

      // Регион
      if (changes.regionPreviousValue != null || changes.regionNewValue != null) {
        actionDetail +=
            '\nРегион: ${changes.regionPreviousValue ?? "Не указано"} > ${changes.regionNewValue ?? "Не указано"}';
      }

      // Менеджер
      if (changes.managerNewValue != null || changes.managerPreviousValue != null) {
        actionDetail +=
            '\nМенеджер: ${changes.managerPreviousValue ?? "Не указано"} > ${changes.managerNewValue ?? "Не указано"}';
      }
      
      // Дата рождения
        if (changes.birthdayNewValue != null || changes.birthdayPreviousValue != null) {
          actionDetail +=
              '\nДата рождения: ${formatBirthday(changes.birthdayPreviousValue)} > ${formatBirthday(changes.birthdayNewValue)}';
        }

      // TG Никнейм
      if (changes.tgNickNewValue != null || changes.tgNickPreviousValue != null) {
        actionDetail +=
          '\nТелеграм: ${changes.tgNickPreviousValue ?? "Не указано"} > ${changes.tgNickNewValue ?? "Не указано"}';
      }

      // Instagram логин
      if (changes.instaLoginNewValue != null || changes.instaLoginPreviousValue != null) {
        actionDetail +=
            '\nInstagram: ${changes.instaLoginPreviousValue ?? "Не указано"} > ${changes.instaLoginNewValue ?? "Не указано"}';
      }

      // Facebook логин
      if (changes.facebookLoginNewValue != null || changes.facebookLoginPreviousValue != null) {
        actionDetail +=
            '\nFacebook: ${changes.facebookLoginPreviousValue ?? "Не указано"} > ${changes.facebookLoginNewValue ?? "Не указано"}';
      }
      
      // Описание
      if (changes.descriptionNewValue != null || changes.descriptionPreviousValue != null) {
        actionDetail +=
            '\nОписание: ${changes.descriptionPreviousValue ?? "Не указано"} > ${changes.descriptionNewValue ?? "Не указано"}';
      }
    }

    return actionDetail;
  }).toList();
}

}
