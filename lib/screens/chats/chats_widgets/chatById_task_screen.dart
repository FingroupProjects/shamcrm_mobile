import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TaskByIdScreen extends StatelessWidget {
  final int chatId;

  TaskByIdScreen({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskProfileBloc(ApiService())..add(FetchTaskProfile(chatId)),
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FD),
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.translate('about_task'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          backgroundColor: Colors.white,
          forceMaterialTransparency: true,
          leading: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<TaskProfileBloc, TaskProfileState>(
          builder: (context, state) {
            if (state is TaskProfileLoading) {
              return Center(
                  child: CircularProgressIndicator(color: Color(0xff1E2E52)));
            } else if (state is TaskProfileLoaded) {
              final task = state.profile;

              final DateTime fromDate = DateTime.parse(task.from);
              final DateTime toDate = DateTime.parse(task.to);

              final String formattedFromDate =
                  DateFormat('dd.MM.yyyy').format(fromDate);
              final String formattedToDate =
                  DateFormat('dd.MM.yyyy').format(toDate);

              List<String> userNamesList = task.usersNames.split(',');

              String priorityLevelText;
              switch (task.priority_level) {
                case '1':
                  priorityLevelText = AppLocalizations.of(context)!.translate('normal');
                  break;
                case '2':
                  priorityLevelText = AppLocalizations.of(context)!.translate('urgent');
                  break;
                case '3':
                  priorityLevelText = AppLocalizations.of(context)!.translate('urgent');
                  break;
                default:
                  priorityLevelText = AppLocalizations.of(context)!.translate('not_specified');
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: Column(
                        children: [
                          buildInfoRow(
                              AppLocalizations.of(context)!
                                  .translate('task_name_profile'),
                              task.name,
                              Icons.assignment,
                              null),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!
                                  .translate('number_task'),
                              task.taskNumber.toString(),
                              Icons.format_list_numbered,
                              null),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!
                                  .translate('priority_level'),
                              priorityLevelText,
                              Icons.low_priority,
                              null),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!
                                  .translate('status_lead_profile'),
                              task.taskStatus.taskStatus!.name ?? "",
                              Icons.assignment,
                              null),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!.translate('author'),
                              task.authorName,
                              Icons.person,
                              null),
                          buildDivider(),
                          GestureDetector(
                            onTap: () {
                              _showUsersDialog(context, userNamesList);
                            },
                            child: buildInfoRow(
                              userNamesList.length == 1
                                  ? AppLocalizations.of(context)!
                                      .translate('assignee')
                                  : AppLocalizations.of(context)!
                                      .translate('assignees'),
                              userNamesList.take(3).join(', ') +
                                  (userNamesList.length > 3
                                      ? '${AppLocalizations.of(context)!.translate('and_else')} ${userNamesList.length - 3}...'
                                      : ''),
                              Icons.group,
                              null,
                            ),
                          ),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!
                                  .translate('from_list'),
                              formattedFromDate,
                              Icons.calendar_month_outlined,
                              null),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!
                                  .translate('to_list'),
                              formattedToDate,
                              Icons.calendar_month,
                              null),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is TaskProfileError) {
              return Center(child: Text(state.error));
            }
            return Center(
                child: Text(
                    AppLocalizations.of(context)!.translate('download_data')));
          },
        ),
      ),
    );
  }

  void _showUsersDialog(BuildContext context, List<String> users) {
    List<String> userNamesList = users.map((user) => user.trim()).toList();

    // Проверка количества исполнителей
    String dialogTitle = userNamesList.length == 1
        ? AppLocalizations.of(context)!.translate('assignee')
        : AppLocalizations.of(context)!.translate('assignees');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  dialogTitle, // Используем динамическое название
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemExtent: 40,
                  itemCount: userNamesList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      title: Text(
                        '${index + 1}. ${userNamesList[index]}',
                        style: TextStyle(
                          color: Color(0xff1E2E52),
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!
                      .translate('close'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildInfoRow(
      String title, String value, IconData? icon, String? customIconPath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        customIconPath != null
            ? Image.asset(customIconPath, width: 32, height: 32)
            : Icon(icon, size: 32, color: const Color(0xff1E2E52)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff6E7C97),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDivider() {
    return const Divider(
      color: Color(0xffE1E6F0),
      thickness: 1,
      height: 24,
    );
  }
}
