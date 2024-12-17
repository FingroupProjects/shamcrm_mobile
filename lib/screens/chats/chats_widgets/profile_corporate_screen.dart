// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart'; // Для форматирования даты

// class CorporateProfileScreen extends StatelessWidget {
//   final int chatId;
  

//   CorporateProfileScreen({required this.chatId, });

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) =>
//           CorporateProfileBloc(ApiService())..add(FetchCorporateProfile(chatId)),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             "Профиль пользователя",
//             style: TextStyle(color: Colors.black), // Цвет текста AppBar
//           ),
//           backgroundColor: Colors.white, // Цвет фона AppBar
//                   leading: IconButton(
//            icon: Image.asset(
//             'assets/icons/arrow-left.png',
//             width: 24,
//             height: 24,
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         ),
//         body: BlocBuilder<CorporateProfileBloc, CorporateProfileState>(
//           builder: (context, state) {
//             if (state is CorporateProfileLoading) {
//               return Center(child: CircularProgressIndicator());
//             } else if (state is CorporateProfileLoaded) {
//               final profile = state.profile;
//               // Преобразование и форматирование даты
//               final DateTime parsedDate = DateTime.parse(profile.createdAt);
//               final String formattedDate =
//                   DateFormat('dd-MM-yyyy').format(parsedDate);

//               return ListView(
//                 padding: const EdgeInsets.all(16.0),
//                 children: [
//                   ListTile(
//                     leading: Icon(Icons.person),
//                     title: Text("Имя: ${profile.name}"),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.phone),
//                     title: Text("Телефон: ${profile.phone ?? 'Не указано'}"),
//                   ),
//                   ListTile(
//                     leading: Image.asset('assets/icons/leads/instagram.png',
//                         width: 24, height: 24),
//                     title: Text(
//                         "Instagram: ${profile.instaLogin ?? 'Не указано'}"),
//                   ),
//                   ListTile(
//                     leading: Image.asset('assets/icons/leads/telegram.png',
//                         width: 24, height: 24),
//                     title: Text("Telegram: ${profile.tgNick ?? 'Не указано'}"),
//                   ),
//                   ListTile(
//                     leading: Image.asset(
//                       'assets/icons/leads/whatsapp.png',
//                       width: 24,
//                       height: 24,
//                     ),
//                     title: Text(
//                       "WhatsApp: ${profile.waName ?? 'Имя не указано'}, Номер: ${profile.waPhone ?? 'Телефон не указан'}",
//                     ),
//                   ),
//                   ListTile(
//                     leading: Image.asset('assets/icons/leads/facebook.png',
//                         width: 24, height: 24),
//                     title: Text(
//                         "Facebook: ${profile.facebookLogin ?? 'Не указано'}"),
//                   ),
//                   // ListTile(
//                   //   leading: Icon(Icons.location_on),
//                   //   title: Text("Адрес: ${profile.address ?? 'Не указано'}"),
//                   // ),
//                   ListTile(
//                     leading: Icon(Icons.description),
//                     title: Text(
//                         "Описание: ${profile.description ?? 'Не указано'}"),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.calendar_today),
//                     title: Text("Дата создания: $formattedDate"),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.supervisor_account),
//                     title: Text("Менеджер: ${profile.manager ?? 'Не указано'}"),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.assignment),
//                     title: Text("Статус: ${profile.leadStatus?.title ?? 'Не указано'}"), // Только name
//                   ),
//                 ],
//               );
//             } else if (state is CorporateProfileError) {
//               return Center(child: Text(state.error));
//             }
//             return Center(child: Text("Загрузите данные"));
//           },
//         ),
//       ),
//     );
//   }
// }
