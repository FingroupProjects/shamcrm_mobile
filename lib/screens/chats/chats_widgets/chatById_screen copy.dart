import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_state.dart';
import 'package:flutter/material.dart';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                    leading: Icon(Icons.timelapse),
                    title: Text("Статус: ${task.taskStatus.taskStatus.name}"),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text("От: ${task.from}"),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text("До: ${task.to}"),
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
