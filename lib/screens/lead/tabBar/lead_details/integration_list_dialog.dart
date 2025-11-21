import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class IntegrationListDialog extends StatelessWidget {
  final List<dynamic> integrations;
  final int leadId;
  final String leadName;
  final bool canSendMessage;

  const IntegrationListDialog({
    Key? key,
    required this.integrations,
    required this.leadId,
    required this.leadName,
    required this.canSendMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //print('IntegrationListDialog: Building with ${integrations.length} integrations: $integrations');
    
    // Если только одна интеграция, автоматически переходим в чат
    if (integrations.length == 1) {
      //print('IntegrationListDialog: Single integration found, navigating to chat ID: ${integrations[0]['id']}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateToChatScreen(context, integrations[0]['id'], canSendMessage);
      });
      return Container();
    }

    // Если интеграций больше одной, показываем модальное окно
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.translate('select_integration'),
              style: TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: integrations.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.translate('no_integrations'),
                      style: TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: integrations.length,
                    itemBuilder: (context, index) {
                      final integration = integrations[index];
                      final username = integration['username'].isNotEmpty
                          ? integration['username']
                          : AppLocalizations.of(context)!.translate('no_username');
                      //print('IntegrationListDialog: Building integration item $index - ID: ${integration['id']}, Username: $username');
                      return ListTile(
                        title: Text(
                          username,
                          style: TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 18,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          //print('IntegrationListDialog: Integration tapped - ID: ${integration['id']}, Username: $username');
                          navigateToChatScreen(context, integration['id'], canSendMessage);
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              buttonText: AppLocalizations.of(context)!.translate('close'),
              onPressed: () {
                //print('IntegrationListDialog: Closing dialog');
                Navigator.pop(context);
              },
              buttonColor: Color(0xff1E2E52),
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void navigateToChatScreen(BuildContext context, int chatId, bool canSendMessage) {
    //print('IntegrationListDialog: Navigating to chat screen with ID: $chatId, canSendMessage: $canSendMessage');
    Navigator.pop(context);
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MessagingCubit(ApiService()),
          child: ChatSmsScreen(
            chatItem: Chats(
              id: chatId,
              image: '',
              name: leadName,
              taskFrom: "",
              taskTo: "",
              description: "",
              channel: "",
              lastMessage: "",
              messageType: "",
              createDate: "",
              unreadCount: 0,
              canSendMessage: canSendMessage,
              chatUsers: [],
            ).toChatItem(),
            chatId: chatId,
            endPointInTab: 'lead',
            canSendMessage: canSendMessage,
          ),
        ),
      ),
    );
  }
}