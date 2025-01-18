
import 'package:crm_task_manager/bloc/history_my-task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_my-task/task_history_event.dart';
import 'package:crm_task_manager/bloc/history_my-task/task_history_state.dart';
import 'package:crm_task_manager/models/history_model_my-task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActionHistoryWidgetMyTask extends StatefulWidget {
  final int taskId;

  ActionHistoryWidgetMyTask({required this.taskId});

  @override
  _ActionHistoryWidgetState createState() => _ActionHistoryWidgetState();
}

class _ActionHistoryWidgetState extends State<ActionHistoryWidgetMyTask> {
  bool isActionHistoryExpanded = false;
  List<MyTaskHistory> actionHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<HistoryBlocMyTask>().add(FetchMyTaskHistory(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBlocMyTask, HistoryStateMyTask>(
      builder: (context, state) {
        if (state is HistoryLoadingMyTask) {
          // return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        } else if (state is HistoryLoadedMyTask) {
          actionHistory = state.taskHistory;
        } else if (state is HistoryErrorMyTask) {
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
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          borderRadius: BorderRadius.circular(8),
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
                      height: 250,
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
            ),
            overflow: TextOverflow.ellipsis,
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
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<String> _buildActionHistoryItems(List<MyTaskHistory> history) {
  return history.map((entry) {
    final changes = entry.changes;
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(entry.date.toLocal());
    String actionDetail = '${entry.status}\n${entry.user.name} $formattedDate';

    // Форматирование дат
    String formatDate(String? dateString) {
      if (dateString == null || dateString == "Не указано") {
        return "Не указано";
      }
      try {
        DateTime date = DateTime.parse(dateString);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        return "Не указано";
      }
    }

    if (changes != null) {

      // Статус задачи
      if (changes.taskStatusNewValue != null || changes.taskStatusPreviousValue != null) {
        actionDetail +=
            '\nСтатус задачи: ${changes.taskStatusPreviousValue ?? "Не указано"} > ${changes.taskStatusNewValue ?? "Не указано"}';
      }

      // Название
      if (changes.historyNameNewValue != null || changes.historyNamePreviousValue != null) {
        actionDetail +=
            '\nНазвание: ${changes.historyNamePreviousValue ?? "Не указано"} > ${changes.historyNameNewValue ?? "Не указано"}';
      }

      // Завершающий этап
      if (changes.isFinishedNewValue != null || changes.isFinishedPreviousValue != null) {
        actionDetail +=
            '\nЗавершающий этап: ${changes.isFinishedPreviousValue ?? "Не указано"} > ${changes.isFinishedNewValue ?? "Не указано"}';
      }

      // Дата начала
      if (changes.startDateNewValue != null || changes.startDatePreviousValue != null) {
        actionDetail +=
            '\nОт: ${formatDate(changes.startDatePreviousValue)} > ${formatDate(changes.startDateNewValue)}';
      }

      // Дата окончания
      if (changes.endDateNewValue != null || changes.endDatePreviousValue != null) {
        actionDetail +=
            '\nДо: ${formatDate(changes.endDatePreviousValue)} > ${formatDate(changes.endDateNewValue)}';
      }

      // Проект
      if (changes.projectNewValue != null || changes.projectPreviousValue != null) {
        actionDetail +=
            '\nПроект: ${changes.projectPreviousValue ?? "Не указано"} > ${changes.projectNewValue ?? "Не указано"}';
      }

      // Пользователи
      if (changes.usersNewValue != null || changes.usersPreviousValue != null) {
        actionDetail +=
            '\nПользователи: ${changes.usersPreviousValue ?? "Не указано"} > ${changes.usersNewValue ?? "Не указано"}';
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
