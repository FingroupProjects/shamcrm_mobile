

// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_bloc.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class TaskProfileScreen extends StatelessWidget {
//   final int chatId;

//   TaskProfileScreen({required this.chatId});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => TaskProfileBloc(ApiService())
//         ..add(FetchChatProfile(chatId)),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             "Профиль задачи",
//             style: TextStyle(color: Colors.black),
//           ),
//           backgroundColor: Colors.white,
//           iconTheme: IconThemeData(color: Colors.black),
//         ),
//         body: BlocBuilder<ChatProfileBloc, ChatProfileState>(
//           builder: (context, state) {
//             if (state is ChatProfileLoading) {
//               return Center(child: CircularProgressIndicator());
//             } else if (state is ChatProfileLoaded) {
//               final taskProfile = state.profile;

//               return ListView(
//                 padding: const EdgeInsets.all(16.0),
//                 children: [
//                   ListTile(
//                     leading: Icon(Icons.label),
//                     title: Text("Название задачи: ${taskProfile.name}"),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.format_list_numbered),
//                     title: Text("Номер задачи: ${taskProfile.taskNumber}"),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.access_time),
//                     title: Text("Срок: ${taskProfile.to}"),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.calendar_today),
//                     title: Text("Дата начала: ${taskProfile.from}"),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.check_circle),
//                     title: Text("Статус задачи: ${taskProfile.taskStatus.color}"), // Добавьте другие поля, если нужно
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.assessment),
//                     title: Text("ID задачи: ${taskProfile.id}"),
//                   ),
//                 ],
//               );
//             } else if (state is ChatProfileError) {
//               return Center(child: Text(state.error));
//             }
//             return Center(child: Text("Загрузите данные"));
//           },
//         ),
//       ),
//     );
//   }
// }
