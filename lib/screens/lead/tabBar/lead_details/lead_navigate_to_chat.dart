import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_event.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/integration_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

Future<void> openLeadChatDirect(
  BuildContext context, {
  required int leadId,
  required String leadName,
  List<Map<String, dynamic>>? chats,
}) async {
  final chatBloc = context.read<LeadToChatBloc>();
  chatBloc.add(FetchLeadToChat(leadId));

  final state = await chatBloc.stream.firstWhere(
    (state) => state is LeadToChatLoaded || state is LeadToChatError,
  );

  if (!context.mounted) return;

  if (state is LeadToChatError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate(state.message),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appColors.buttonPrimaryFg,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: context.appColors.error,
      ),
    );
    return;
  }

  final loadedState = state as LeadToChatLoaded;
  final leadChats = loadedState.leadtochat;

  if (leadChats.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate('no_chat_in_list'),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appColors.buttonPrimaryFg,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: context.appColors.error,
      ),
    );
    return;
  }

  final channels = leadChats.map((chat) => chat.channel.name).toSet().toList();
  if (channels.length == 1) {
    final channelName = channels.first;
    final chatsForChannel =
        leadChats.where((chat) => chat.channel.name == channelName).toList();

    if (chatsForChannel.length == 1) {
      _navigateToLeadChatScreen(
        leadName: leadName,
        chatId: chatsForChannel.first.id,
        canSendMessage: chatsForChannel.first.canSendMessage,
        initialChannelName: chatsForChannel.first.channel.name,
      );
      return;
    }

    final integrations = _buildLeadIntegrations(chatsForChannel, chats);
    showDialog(
      context: context,
      builder: (context) {
        return IntegrationListDialog(
          integrations: integrations,
          leadId: leadId,
          leadName: leadName,
          canSendMessage: chatsForChannel.first.canSendMessage,
          initialChannelName: channelName,
        );
      },
    );
    return;
  }

  showDialog(
    context: context,
    builder: (dialogContext) {
      final Map<String, String> sourceIcons = {
        'telegram_account': 'assets/icons/leads/telegram.png',
        'telegram_bot': 'assets/icons/leads/telegram.png',
        'mini_app': 'assets/icons/leads/telegram.png',
        'whatsapp': 'assets/icons/leads/whatsapp.png',
        'green_api': 'assets/icons/leads/whatsapp.png',
        'facebook': 'assets/icons/leads/messenger.png',
        'instagram': 'assets/icons/leads/instagram.png',
        'site': '',
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

      return Dialog(
        backgroundColor: dialogContext.appColors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: dialogContext.appColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(dialogContext)!.translate('list_chat'),
                style: TextStyle(
                  color: dialogContext.appColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channelName = channels[index];
                  final iconPath = sourceIcons[channelName] ??
                      'assets/icons/leads/default.png';
                  final displayName =
                      channelName.toLowerCase() == 'support'
                          ? AppLocalizations.of(dialogContext)!
                              .translate('support_chat_name')
                          : customChannelNames[channelName] ??
                              (channelName.isNotEmpty
                                  ? channelName
                                  : AppLocalizations.of(dialogContext)!
                                      .translate('no_name_chat'));
                  final chatsForChannel = leadChats
                      .where((chat) => chat.channel.name == channelName)
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Material(
                      color: dialogContext.appColors.surfacePrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: dialogContext.appColors.borderSubtle,
                        ),
                      ),
                      child: ListTile(
                        leading: channelName == 'site'
                            ? Icon(
                                Icons.language,
                                size: 30,
                                color: dialogContext.appColors.buttonPrimaryBg,
                              )
                            : Image.asset(
                                iconPath,
                                width: 30,
                                height: 30,
                              ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            color: dialogContext.appColors.textPrimary,
                            fontSize: 18,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          if (chatsForChannel.length == 1) {
                            _navigateToLeadChatScreen(
                              leadName: leadName,
                              chatId: chatsForChannel.first.id,
                              canSendMessage:
                                  chatsForChannel.first.canSendMessage,
                              initialChannelName:
                                  chatsForChannel.first.channel.name,
                            );
                            return;
                          }

                          final integrations =
                              _buildLeadIntegrations(chatsForChannel, chats);
                          showDialog(
                            context: context,
                            builder: (context) {
                              return IntegrationListDialog(
                                integrations: integrations,
                                leadId: leadId,
                                leadName: leadName,
                                canSendMessage:
                                    chatsForChannel.first.canSendMessage,
                                initialChannelName: channelName,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

List<Map<String, dynamic>> _buildLeadIntegrations(
  List<LeadNavigateChat> chatsForChannel,
  List<Map<String, dynamic>>? chats,
) {
  return chatsForChannel.map((chat) {
    final Map<String, dynamic> chatData = chats?.firstWhere(
          (c) => c['id'] == chat.id,
          orElse: () => <String, dynamic>{},
        ) ??
        <String, dynamic>{};
    final username = chatData['integration'] != null
        ? chatData['integration']['username'] ?? ''
        : '';
    return {
      'id': chat.id,
      'username': username,
      'channel_name': chat.channel.name,
    };
  }).toList();
}

void _navigateToLeadChatScreen({
  required String leadName,
  required int chatId,
  required bool canSendMessage,
  required String initialChannelName,
}) {
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
          initialChannelName: initialChannelName,
        ),
      ),
    ),
  );
}

class LeadNavigateToChat extends StatefulWidget {
  final int leadId;
  final String leadName;
  final List<Map<String, dynamic>>? chats;
  final bool autoOpen;

  LeadNavigateToChat({
    Key? key,
    required this.leadId,
    required this.leadName,
    this.chats,
    this.autoOpen = false,
  }) : super(key: key);

  @override
  _LeadNavigateToChatDialogState createState() =>
      _LeadNavigateToChatDialogState();
}

class _LeadNavigateToChatDialogState extends State<LeadNavigateToChat> {
  bool _autoOpened = false;

  BoxDecoration _sectionDecoration(BuildContext context) => BoxDecoration(
        color: context.appColors.surfacePrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.appColors.borderSubtle,
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
                  color: context.appColors.buttonPrimaryFg,
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
        } else if (widget.autoOpen &&
            !_autoOpened &&
            state is LeadToChatLoaded) {
          _autoOpened = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _openChatsFromState(state);
          });
        }
      },
      child: widget.autoOpen
          ? const SizedBox.shrink()
          : SingleChildScrollView(
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
                        buttonColor: context.appColors.buttonPrimaryBg,
                        textColor: context.appColors.buttonPrimaryFg,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('go_to_chat'),
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

  void _openChatsFromState(LeadToChatLoaded state) {
    final leadtochat = state.leadtochat;
    if (leadtochat.isEmpty) {
      _showChatListDialog(context);
      return;
    }

    final channels = leadtochat.map((chat) => chat.channel.name).toSet().toList();
    if (channels.length == 1) {
      final channelName = channels.first;
      final chatsForChannel =
          leadtochat.where((chat) => chat.channel.name == channelName).toList();
      _handleChannelTap(context, channelName, chatsForChannel);
      return;
    }

    _showChatListDialog(context);
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
              color: context.appColors.borderSubtle,
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
                    color: context.appColors.textPrimary,
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
                          color: context.appColors.buttonPrimaryBg,
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
                              color: context.appColors.textSecondary,
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Material(
                                color: context.appColors.surfacePrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(
                                    color: context.appColors.borderSubtle,
                                  ),
                                ),
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
                                      color: context.appColors.textPrimary,
                                      fontSize: 18,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () {
                                    final chatsForChannel = leadtochat
                                        .where((chat) =>
                                            chat.channel.name == channelName)
                                        .toList();

                                    _handleChannelTap(
                                      context,
                                      channelName,
                                      chatsForChannel,
                                    );
                                  },
                                ),
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
                            color: context.appColors.textSecondary,
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

  void _handleChannelTap(
    BuildContext context,
    String channelName,
    List<dynamic> chatsForChannel,
  ) {
    if (chatsForChannel.length == 1) {
      navigateToScreen(
        context,
        chatsForChannel[0].id,
        chatsForChannel[0].canSendMessage,
        chatsForChannel[0].channel.name,
      );
      return;
    }

    final integrations = chatsForChannel.map((chat) {
      final chatData = widget.chats?.firstWhere(
        (c) => c['id'] == chat.id,
        orElse: () => <String, dynamic>{},
      );
      final username = chatData != null && chatData['integration'] != null
          ? chatData['integration']['username'] ?? ''
          : '';
      return {
        'id': chat.id,
        'username': username,
        'channel_name': chat.channel.name,
      };
    }).toList();

    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return IntegrationListDialog(
          integrations: integrations,
          leadId: widget.leadId,
          leadName: widget.leadName,
          canSendMessage: chatsForChannel[0].canSendMessage,
          initialChannelName: channelName,
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
