import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_state.dart';
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
        appBar: AppBar(
          title: Text(
            "Информация о задаче",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: BlocBuilder<TaskProfileBloc, TaskProfileState>(
          builder: (context, state) {
            if (state is TaskProfileLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is TaskProfileLoaded) {
              final task = state.profile;

              // Преобразование и форматирование даты
              final DateTime fromDate = DateTime.parse(task.from);
              final DateTime toDate = DateTime.parse(task.to);

              final String formattedFromDate = DateFormat('dd-MM-yyyy').format(fromDate);
              final String formattedToDate = DateFormat('dd-MM-yyyy').format(toDate);

              // Разделяем строку пользователей на список и обрезаем его, если больше 3 пользователей
              List<String> userNamesList = task.usersNames.split(',');
              String displayUserNames = userNamesList.length > 1
                  ? '${userNamesList.sublist(0, 1).join(', ')}...'
                  : userNamesList.join(', ');

              // Преобразование уровня приоритета
              String priorityLevelText;
              switch (task.priority_level) {
                case '1':
                  priorityLevelText = 'Обычный';
                  break;
                case '2':
                  priorityLevelText = 'Критический';
                  break;
                case '3':
                  priorityLevelText = 'Сложный';
                  break;
                default:
                  priorityLevelText = 'Не указано';
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  ListTile(
                    leading: Icon(Icons.assignment),
                    title: Text("Название задачи: ${task.name}"),
                  ),
                  ListTile(
                    leading: Icon(Icons.format_list_numbered),
                    title: Text("Номер задачи: ${task.taskNumber}"),
                  ),
                  ListTile(
                    leading: Icon(Icons.low_priority),
                    title: Text("Уровень приоритета: $priorityLevelText"),
                  ),
                  ListTile(
                    leading: Icon(Icons.assignment),
                    title: Text("Статус: ${task.taskStatus.taskStatus.name}"),
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("Автор: ${task.authorName}"),
                  ),
                  ListTile(
                    leading: Icon(Icons.group),
                    title: GestureDetector(
                      onTap: () {
                        // Показать всплывающее окно со списком всех пользователей
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text(
                                "Список исполнителей",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: userNamesList.asMap().entries.map((entry) {
                                    int index = entry.key + 1; // Нумерация с 1
                                    String name = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        '$index. $name',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: Text("Закрыть", style: TextStyle(fontSize: 16)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        "Исполнители: $displayUserNames",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text("От: ${formattedFromDate}"),
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text("До: ${formattedToDate}"),
                  ),
                ],
              );
            } else if (state is TaskProfileError) {
              return Center(child: Text(state.error));
            }
            return Center(child: Text("Загрузите данные"));
          },
        ),
      ),
    );
  }
}