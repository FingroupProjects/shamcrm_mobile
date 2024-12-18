import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class ParticipantProfileScreen extends StatelessWidget {
  final String userId;
  final String image;
  final String name;
  final String email;
  final String phone;
  final String login;
  final String lastSeen;

  const ParticipantProfileScreen({
    required this.userId,
    required this.image,
    required this.name,
    required this.email,
    required this.phone,
    required this.login,
    required this.lastSeen,
  });
  
  String formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return "Неизвестно";  
    }
    
    try {
      DateTime parsedDate = DateTime.parse(date); 
      return DateFormat('dd-MM-yyyy HH:mm:ss').format(parsedDate);
    } catch (e) {
      return "Неизвестно";  
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD), 
      appBar: AppBar(
        title: Text(
          "Профиль пользователя",
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        backgroundColor: Color(0xffF4F7FD), 
        leading: IconButton(
          icon: Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16,right: 16, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  child: ClipOval(
                    child: image.isEmpty || image == 'assets/images/AvatarChat.png'
                        ? Image.asset(
                            'assets/images/AvatarChat.png', 
                            height: 140,
                            width: 140,
                            fit: BoxFit.cover,
                          )
                        : image.startsWith('<svg')
                            ? SvgPicture.string(
                                image,
                                height: 140,
                                width: 140,
                              )
                            : Image.network(
                                image,
                                height: 140,
                                width: 140,
                                fit: BoxFit.cover,
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  children: [
                    buildInfoRow("ФИО", name, Icons.person),
                    buildDivider(),
                    buildInfoRow("Email", email, Icons.email),
                    buildDivider(),
                    buildInfoRow("Номер телефона", phone, Icons.phone),
                    buildDivider(),
                    buildInfoRow("Логин", login, Icons.account_circle),
                    buildDivider(),
                    buildInfoRow("Последний вход", formatDate(lastSeen), Icons.access_time)
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
              //   context.read<CreateClientBloc>().add(
              //   CreateClientEv(userId: userId.toString()),
              // );
              // context.read<ChatsBloc>().add(FetchChats(endPoint: 'corporate'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff1E2E52),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Перейти в чат",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Строка информации с иконкой
  Widget buildInfoRow(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: Color(0xff1E2E52)),
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

  // Разделитель
  Widget buildDivider() {
    return const Divider(
      color: Color(0xffE1E6F0),
      thickness: 1,
      height: 24,
    );
  }
}
