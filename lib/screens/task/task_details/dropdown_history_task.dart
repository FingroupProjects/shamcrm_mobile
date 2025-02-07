import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_event.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_state.dart';
import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActionHistoryWidgetTask extends StatefulWidget {
  final int taskId;

  ActionHistoryWidgetTask({required this.taskId});

  @override
  _ActionHistoryWidgetState createState() => _ActionHistoryWidgetState();
}

class _ActionHistoryWidgetState extends State<ActionHistoryWidgetTask> {
  bool isActionHistoryExpanded = false;
  List<TaskHistory> actionHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<HistoryBlocTask>().add(FetchTaskHistory(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBlocTask, HistoryStateTask>(
      builder: (context, state) {
        if (state is HistoryLoadingTask) {
          // return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        } else if (state is HistoryLoadedTask) {
          actionHistory = state.taskHistory;
        } else if (state is HistoryErrorTask) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
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
          AppLocalizations.of(context)!.translate('action_history'),
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

  List<String> _buildActionHistoryItems(List<TaskHistory> history) {
  return history.map((entry) {
    final changes = entry.changes;
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(entry.date.toLocal());
    String actionDetail = '${entry.status}\n${entry.user.name} $formattedDate';

    // Форматирование дат
    String formatDate(String? dateString) {
      if (dateString == null || dateString == AppLocalizations.of(context)!.translate('not_specified')) {
        return AppLocalizations.of(context)!.translate('not_specified');
      }
      try {
        DateTime date = DateTime.parse(dateString);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        return AppLocalizations.of(context)!.translate('not_specified');
      }
    }

    if (changes != null) {

      // Статус задачи
      if (changes.taskStatusNewValue != null || changes.taskStatusPreviousValue != null) {
        actionDetail +=
            '\n${AppLocalizations.of(context)!.translate('status_task')}${changes.taskStatusPreviousValue ?? AppLocalizations.of(context)!.translate('not_specified')} > ${changes.taskStatusNewValue ?? AppLocalizations.of(context)!.translate('not_specified')}';
      }

      // Название
      if (changes.historyNameNewValue != null || changes.historyNamePreviousValue != null) {
        actionDetail +=
            '\n${AppLocalizations.of(context)!.translate('name_history')}${changes.historyNamePreviousValue ?? AppLocalizations.of(context)!.translate('not_specified')} > ${changes.historyNameNewValue ?? AppLocalizations.of(context)!.translate('not_specified')}';
      }

      // Завершающий этап
      if (changes.isFinishedNewValue != null || changes.isFinishedPreviousValue != null) {
        actionDetail +=
            '\n${AppLocalizations.of(context)!.translate('final_stage')}${changes.isFinishedPreviousValue ?? AppLocalizations.of(context)!.translate('not_specified')} > ${changes.isFinishedNewValue ?? AppLocalizations.of(context)!.translate('not_specified')}';
      }

      // // Дата начала
      // if (changes.startDateNewValue != null || changes.startDatePreviousValue != null) {
      //   actionDetail +=
      //       '\n${AppLocalizations.of(context)!.translate('from')}${formatDate(changes.startDatePreviousValue)} > ${formatDate(changes.startDateNewValue)}';
      // }

      // Дата окончания
      if (changes.endDateNewValue != null || changes.endDatePreviousValue != null) {
        actionDetail +=
            '\n${AppLocalizations.of(context)!.translate('deadLine')}${formatDate(changes.endDatePreviousValue)} > ${formatDate(changes.endDateNewValue)}';
      }

      // Проект
      if (changes.projectNewValue != null || changes.projectPreviousValue != null) {
        actionDetail +=
            '\n${AppLocalizations.of(context)!.translate('project')}${changes.projectPreviousValue ?? AppLocalizations.of(context)!.translate('not_specified')} > ${changes.projectNewValue ?? AppLocalizations.of(context)!.translate('not_specified')}';
      }

      // Пользователи
      if (changes.usersNewValue != null || changes.usersPreviousValue != null) {
        actionDetail +=
            '\n${AppLocalizations.of(context)!.translate('users')}${changes.usersPreviousValue ?? AppLocalizations.of(context)!.translate('not_specified')} > ${changes.usersNewValue ?? AppLocalizations.of(context)!.translate('not_specified')}';
      }

      // Описание
      if (changes.descriptionNewValue != null || changes.descriptionPreviousValue != null) {
        actionDetail +=
            '\n${AppLocalizations.of(context)!.translate('description')}${changes.descriptionPreviousValue ?? AppLocalizations.of(context)!.translate('not_specified')} > ${changes.descriptionNewValue ?? AppLocalizations.of(context)!.translate('not_specified')}';
      }
    }

    return actionDetail;
  }).toList();
}

}
