import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class TaskNavigateToChat extends StatefulWidget {
  final int chatId;

  TaskNavigateToChat({required this.chatId});

  @override
  _TaskNavigateToChatDialogState createState() => _TaskNavigateToChatDialogState();
}

class _TaskNavigateToChatDialogState extends State<TaskNavigateToChat> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomButton(
                buttonText: '',
                onPressed: () {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => MessagingCubit(ApiService()),
                        child: ChatSmsScreen(
                          chatItem: Chats(
                            id: widget.chatId,
                            name: "",
                            taskFrom: "",
                            taskTo: "",
                            description: "",
                            channel: "",
                            lastMessage: "",
                            messageType: "",
                            createDate: "",
                            unredMessage: 0,
                          ).toChatItem("assets/images/AvatarChat.png"),
                          chatId: widget.chatId, endPointInTab: '',
                        ),
                      ),
                    ),
                  );
                },
                buttonColor: Color(0xff1E2E52),
                textColor: Colors.white,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Перейти в чат',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}