import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_event.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/integration_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class LeadNavigateToChat extends StatefulWidget {
  final int leadId;
  final String leadName;
  final List<Map<String, dynamic>>? chats;

  LeadNavigateToChat({
    Key? key,
    required this.leadId,
    required this.leadName,
    this.chats,
  }) : super(key: key);

  @override
  _LeadNavigateToChatDialogState createState() =>
      _LeadNavigateToChatDialogState();
}

class _LeadNavigateToChatDialogState extends State<LeadNavigateToChat> {
  BoxDecoration _sectionDecoration(BuildContext context) => BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.appColors.textInverse.withValues(alpha: 0.16),
        ),
      );
  @override
  void initState() {
    super.initState();
    //print('LeadNavigateToChat: Initializing with leadId: ${widget.leadId}');
    context.read<LeadToChatBloc>().add(FetchLeadToChat(widget.leadId));
  }

  final Map<String, String> sourceIcons = {
    'telegram_account': 'assets/icons/leads/telegram.png',
    'telegram_bot': 'assets/icons/leads/telegram.png',
    'mini_app': 'assets/icons/leads/telegram.png',
    'whatsapp': 'assets/icons/leads/whatsapp.png',
    'green_api': 'assets/icons/leads/whatsapp.png',
    'facebook': 'assets/icons/leads/messenger.png',
    'instagram': 'assets/icons/leads/instagram.png',
    'site': '', // Будет использоваться Flutter иконка
  };

  final Map<String, String> customChannelNames = {
    'telegram_account': 'Telegram',
    'telegram_bot': 'Telegram бот',
    'mini_app': 'Mini App',
    'whatsapp': 'WhatsApp',
    'green_api': 'WhatsApp',
    'facebook': 'Facebook',
    'instagram': 'Instagram',
    'site': 'Интернет магазин',
  };

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadToChatBloc, LeadToChatState>(
      listener: (context, state) {
        if (state is LeadToChatError) {
          //print('LeadNavigateToChat: Error state - ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
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
                    //print('LeadNavigateToChat: Opening chat list dialog');
                    _showChatListDialog(context);
                  },
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('go_to_chat'),
                        style: TextStyle(
                          color: context.appColors.buttonPrimaryFg,
                          fontSize: 16,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: context.appColors.buttonPrimaryFg,
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
          backgroundColor: context.appColors.surfacePrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: context.appColors.textInverse.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.translate('list_chat'),
                  style: TextStyle(
                    color:
                        context.appColors.textInverse.withValues(alpha: 0.96),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
              SizedBox(
                height: 300,
                child: BlocBuilder<LeadToChatBloc, LeadToChatState>(
                  builder: (context, state) {
                    //print('LeadNavigateToChat: Building chat list dialog with state: $state');
                    if (state is LeadToChatLoading) {
                      //print('LeadNavigateToChat: Loading state');
                      return Center(
                        child: CircularProgressIndicator(
                          color: context.appColors.textInverse
                              .withValues(alpha: 0.96),
                        ),
                      );
                    } else if (state is LeadToChatLoaded) {
                      final leadtochat = state.leadtochat;
                      //print('LeadNavigateToChat: Loaded ${leadtochat.length} chats: $leadtochat');
                      if (leadtochat.isEmpty) {
                        //print('LeadNavigateToChat: No chats available');
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!
                                .translate('no_chat_in_list'),
                            style: TextStyle(
                              color: context.appColors.textInverse
                                  .withValues(alpha: 0.82),
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      } else {
                        // Группируем чаты по каналам
                        final channels = leadtochat
                            .map((chat) => chat.channel.name)
                            .toSet()
                            .toList();
                        return ListView.builder(
                          itemCount: channels.length,
                          itemBuilder: (context, index) {
                            final channelName = channels[index];
                            final iconPath = sourceIcons[channelName] ??
                                'assets/icons/leads/default.png';
                            final displayName =
                                channelName.toLowerCase() == 'support'
                                    ? AppLocalizations.of(context)!
                                        .translate('support_chat_name')
                                    : customChannelNames[channelName] ??
                                        (channelName.isNotEmpty
                                            ? channelName
                                            : AppLocalizations.of(context)!
                                                .translate('no_name_chat'));
                            //print('LeadNavigateToChat: Building chat item $index - Channel: $channelName, DisplayName: $displayName');
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: _sectionDecoration(context),
                              child: ListTile(
                                leading: channelName == 'site'
                                    ? Icon(
                                        Icons.language,
                                        size: 30,
                                        color:
                                            context.appColors.buttonPrimaryBg,
                                      )
                                    : Image.asset(
                                        iconPath,
                                        width: 30,
                                        height: 30,
                                      ),
                                title: Text(
                                  displayName,
                                  style: TextStyle(
                                    color: context.appColors.textInverse
                                        .withValues(alpha: 0.96),
                                    fontSize: 18,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  //print('LeadNavigateToChat: Channel tapped - Channel: $channelName');
                                  // Собираем чаты для выбранного канала
                                  final chatsForChannel = leadtochat
                                      .where((chat) =>
                                          chat.channel.name == channelName)
                                      .toList();
                                  //print('LeadNavigateToChat: Found ${chatsForChannel.length} chats for $channelName: $chatsForChannel');

                                  if (chatsForChannel.length == 1) {
                                    //print('LeadNavigateToChat: Single chat found, navigating to chat ID: ${chatsForChannel[0].id}');
                                    navigateToScreen(
                                      context,
                                      chatsForChannel[0].id,
                                      chatsForChannel[0].canSendMessage,
                                      chatsForChannel[0].channel.name,
                                    );
                                  } else {
                                    //print('LeadNavigateToChat: Multiple chats found, opening IntegrationListDialog');
                                    final integrations =
                                        chatsForChannel.map((chat) {
                                      // Ищем соответствующий чат в widget.chats
                                      final chatData = widget.chats?.firstWhere(
                                        (c) => c['id'] == chat.id,
                                        orElse: () => <String, dynamic>{},
                                      );
                                      final username = chatData != null &&
                                              chatData['integration'] != null
                                          ? chatData['integration']
                                                  ['username'] ??
                                              ''
                                          : '';
                                      //print('LeadNavigateToChat: Processing chat ID: ${chat.id}, Username: $username');
                                      return {
                                        'id': chat.id,
                                        'username': username,
                                        'channel_name': chat.channel.name,
                                      };
                                    }).toList();
                                    //print('LeadNavigateToChat: Integrations for dialog: $integrations');
                                    Navigator.pop(
                                        context); // Закрываем список чатов
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return IntegrationListDialog(
                                          integrations: integrations,
                                          leadId: widget.leadId,
                                          leadName: widget.leadName,
                                          canSendMessage:
                                              chatsForChannel[0].canSendMessage,
                                          initialChannelName: channelName,
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      }
                    } else {
                      //print('LeadNavigateToChat: Error or initial state');
                      return Center(
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('no_chat_in_list'),
                          style: TextStyle(
                            color: context.appColors.textInverse
                                .withValues(alpha: 0.82),
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                          ),
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
                    //print('LeadNavigateToChat: Closing chat list dialog');
                    Navigator.pop(context);
                  },
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void navigateToScreen(
    BuildContext context,
    int id,
    bool canSendMessage,
    String initialChannelName,
  ) {
    //print('LeadNavigateToChat: Navigating to chat screen with ID: $id, canSendMessage: $canSendMessage');
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
              unreadCount: 0,
              canSendMessage: canSendMessage,
              chatUsers: [],
            ).toChatItem(),
            chatId: id,
            endPointInTab: 'lead',
            canSendMessage: canSendMessage,
            initialChannelName: initialChannelName,
          ),
        ),
      ),
    );
  }
}
