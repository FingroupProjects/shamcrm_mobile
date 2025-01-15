import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; 

class UserProfileScreen extends StatelessWidget {
  final int chatId;

  UserProfileScreen({
    required this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatProfileBloc(ApiService())..add(FetchChatProfile(chatId)),
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FD),
        appBar: AppBar(
          title: Text(
            "Профиль лида",
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          backgroundColor: Color(0xffF4F7FD),
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
        body: BlocBuilder<ChatProfileBloc, ChatProfileState>(
          builder: (context, state) {
            if (state is ChatProfileLoading) {
              return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)),
);
            } else if (state is ChatProfileLoaded) {
              final profile = state.profile;
              final DateTime parsedDate = DateTime.parse(profile.createdAt);
              final String formattedDate =
                  DateFormat('dd-MM-yyyy').format(parsedDate);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),

                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        children: [
                      buildInfoRow("Имя", profile.name, Icons.person, null),
                      buildDivider(),
                      buildInfoRow("Телефон", profile.phone ?? 'Не указано', Icons.phone, null),
                      buildDivider(),
                      buildInfoRow("Instagram", profile.instaLogin ?? 'Не указано', null, 
                      'assets/icons/leads/instagram.png' 
                      ),
                      buildDivider(),
                      buildInfoRow("Telegram", profile.tgNick ?? 'Не указано', null, 
                      'assets/icons/leads/telegram.png' 
                      ),
                      buildDivider(),
                      buildInfoRow("WhatsApp", profile.waPhone ?? 'Не указано', null, 
                      'assets/icons/leads/whatsapp.png' 
                      ),
                      buildDivider(),
                      buildInfoRow("WhatsApp", profile.facebookLogin ?? 'Не указано', null, 
                      'assets/icons/leads/facebook.png' 
                      ),                      buildDivider(),
                      buildInfoRow("Описание", profile.description ?? 'Не указано', Icons.description, null),
                      buildDivider(),
                      buildInfoRow("Дата создания", formattedDate, Icons.calendar_today, null),
                      buildDivider(),
                      buildInfoRow("Менеджер", profile.manager?.name ?? 'Не указано', Icons.supervisor_account, null),
                      buildDivider(),
                      buildInfoRow("Статус", profile.leadStatus?.title ?? 'Не указано', Icons.assignment, null),
                      
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is ChatProfileError) {
              return Center(child: Text(state.error));
            }
            return Center(child: Text("Загрузите данные"));
          },
        ),
      ),
    );
  }

  // Info row widget to match the design
 Widget buildInfoRow(String title, String value, IconData? icon, String? customIconPath) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // If a custom icon path is provided, use it; otherwise, fall back to the default icon.
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
