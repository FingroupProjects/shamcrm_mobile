import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_event.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class LeadNavigateToChat extends StatefulWidget {
  final int leadId;
  final String leadName;

  LeadNavigateToChat({required this.leadId, required this.leadName});

  @override
  _LeadNavigateToChatDialogState createState() =>
      _LeadNavigateToChatDialogState();
}

class _LeadNavigateToChatDialogState extends State<LeadNavigateToChat> {
  @override
  void initState() {
    super.initState();
    context.read<LeadToChatBloc>().add(FetchLeadToChat(widget.leadId));
  }

  final Map<String, String> sourceIcons = {
    'telegram_account': 'assets/icons/leads/telegram.png',
    'telegram_bot': 'assets/icons/leads/telegram.png',
    'whatsapp': 'assets/icons/leads/whatsapp.png',
    'facebook': 'assets/icons/leads/facebook.png',
    'instagram': 'assets/icons/leads/instagram.png',
  };

  final Map<String, String> customChannelNames = {
    'telegram_account': 'Telegram',
    'telegram_bot': 'Telegram бот',
    'whatsapp': 'WhatsApp',
    'facebook': 'Facebook',
    'instagram': 'Instagram',
  };

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadToChatBloc, LeadToChatState>(
      listener: (context, state) {
        if (state is LeadToChatError) {
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
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomButton(
                  buttonText: '',
                  onPressed: () {
                    _showChatListDialog(context);
                  },
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('go_to_chat'),
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
      ),
    );
  }

  void _showChatListDialog(BuildContext context) {
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
                  AppLocalizations.of(context)!.translate('list_chat'), 
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 300,
                child: BlocBuilder<LeadToChatBloc, LeadToChatState>(
                  builder: (context, state) {
                    if (state is LeadToChatLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff1E2E52),
                        ),
                      );
                    } else if (state is LeadToChatLoaded) {
                      final leadtochat = state.leadtochat;
                      if (leadtochat.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.translate('no_chat_in_list'),
                            style: TextStyle(
                                color: Color(0xff1E2E52), fontSize: 16),
                          ),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: leadtochat.length,
                          itemBuilder: (context, index) {
                            final LeadNavigateToChat = leadtochat[index];
                            final channelName = LeadNavigateToChat.channel.name;
                            final iconPath = sourceIcons[channelName] ??
                                'assets/icons/leads/default.png';
                            final displayName =
                                customChannelNames[channelName] ??
                                    (channelName.isNotEmpty
                                        ? channelName
                                        : AppLocalizations.of(context)!.translate('no_name_chat'));
                            return ListTile(
                              leading: Image.asset(
                                iconPath,
                                width: 30,
                                height: 30,
                              ),
                              title: Text(
                                displayName,
                                style: TextStyle(
                                  color: Color(0xff1E2E52),
                                  fontSize: 18,
                                ),
                              ),
                              onTap: () {
                                navigateToScreen(LeadNavigateToChat.id,
                                    LeadNavigateToChat.canSendMessage);
                              },
                            );
                          },
                        );
                      }
                    } else {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context)!.translate('no_chat_in_list'),
                          style: TextStyle(color: Color(0xff1E2E52)),
                        ),
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
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

  void navigateToScreen(int id, bool canSendMessage) {
    Navigator.pop(context);
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MessagingCubit(ApiService()),
          child: ChatSmsScreen(
            chatItem: Chats(
              id: id,
              image: '',
              name: widget.leadName,
              taskFrom: "",
              taskTo: "",
              description: "",
              channel: "",
              lastMessage: "",
              messageType: "",
              createDate: "",
              unredMessage: 0,
              canSendMessage: canSendMessage,
              chatUsers: [],
            ).toChatItem(),
            chatId: id,
            endPointInTab: 'lead',
            canSendMessage: canSendMessage,
          ),
        ),
      ),
    );
  }
}
