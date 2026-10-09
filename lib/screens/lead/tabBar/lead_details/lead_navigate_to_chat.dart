import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_event.dart';
import 'package:crm_task_manager/models/lead/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/integration_list_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_green_api_chat.dart';
import 'package:crm_task_manager/utils/green_api_integration_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/widgets/channel_source_icon.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

/// Имя канала в списке чатов. Берётся из перевода текущего языка.
String leadChannelLabel(BuildContext context, String channelName) {
  final title = channelDisplayTitle(context, channelName);
  if (title != null) return title;
  if (channelName.trim().isEmpty) {
    return AppLocalizations.of(context)!.translate('no_name_chat');
  }
  return channelName;
}

Future<void> openLeadChatDirect(
  BuildContext context, {
  required int leadId,
  required String leadName,
  String? leadPhone,
  List<Map<String, dynamic>>? chats,
}) async {
  // Флаг мог не попасть в кэш после PIN — берём свежий get-user-data.
  try {
    await refreshGreenApiAccess(context.read<ApiService>());
  } catch (_) {}
  if (!context.mounted) return;
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

  // Нет чатов, но есть телефон и Green API — сразу пустой WhatsApp.
  if (leadChats.isEmpty) {
    if (canOfferGreenApiWhatsApp(leadPhone)) {
      openPendingGreenApiLeadChat(leadId: leadId, leadName: leadName);
      return;
    }
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

  final channels = visibleLeadChatChannels(leadChats, leadPhone);
  if (channels.length == 1) {
    final channelName = channels.first;
    final chatsForChannel = leadChats
        .where((chat) => chat.channel.name == channelName)
        .toList();

    if (chatsForChannel.isEmpty && isWhatsAppChannelName(channelName)) {
      openPendingGreenApiLeadChat(leadId: leadId, leadName: leadName);
      return;
    }

    if (chatsForChannel.length == 1) {
      openExistingLeadChatScreen(
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
                  final displayName =
                      leadChannelLabel(dialogContext, channelName);
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
                        leading: ChannelSourceIcon(
                          sourceName: channelName,
                          size: 30,
                          background: dialogContext.appColors.surfacePrimary,
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
                          if (chatsForChannel.isEmpty &&
                              isWhatsAppChannelName(channelName)) {
                            openPendingGreenApiLeadChat(
                              leadId: leadId,
                              leadName: leadName,
                            );
                            return;
                          }
                          if (chatsForChannel.length == 1) {
                            openExistingLeadChatScreen(
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

class LeadNavigateToChat extends StatefulWidget {
  final int leadId;
  final String leadName;
  final String? leadPhone;
  final List<Map<String, dynamic>>? chats;
  final bool autoOpen;

  LeadNavigateToChat({
    Key? key,
    required this.leadId,
    required this.leadName,
    this.leadPhone,
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
    _refreshGreenApiFlag();
  }

  /// Пока флаг не подтянулся, список чатов пустой. После запроса появится WhatsApp.
  Future<void> _refreshGreenApiFlag() async {
    try {
      await refreshGreenApiAccess(context.read<ApiService>());
    } catch (error) {
      debugPrint('LeadNavigateToChat: green api flag error: $error');
    }
    if (mounted) setState(() {});
  }

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
                        onPressed: () async {
                          await _refreshGreenApiFlag();
                          if (!mounted) return;
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
    final channels = visibleLeadChatChannels(leadtochat, widget.leadPhone);
    if (leadtochat.isEmpty && channels.length == 1) {
      _handleChannelTap(context, channels.first, const [], closeDialog: false);
      return;
    }
    if (leadtochat.isEmpty) {
      _showChatListDialog(context);
      return;
    }

    if (channels.length == 1) {
      final channelName = channels.first;
      final chatsForChannel =
          leadtochat.where((chat) => chat.channel.name == channelName).toList();
      _handleChannelTap(context, channelName, chatsForChannel, closeDialog: false);
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
                child: ValueListenableBuilder<bool>(
                  valueListenable: GreenApiIntegrationStore.enabled,
                  builder: (context, _, __) {
                    return BlocBuilder<LeadToChatBloc, LeadToChatState>(
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
                      final channels = visibleLeadChatChannels(
                        leadtochat,
                        widget.leadPhone,
                      );
                      if (channels.isEmpty) {
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
                        // Группируем чаты по каналам. WhatsApp может быть без чата.
                        return ListView.builder(
                          itemCount: channels.length,
                          itemBuilder: (context, index) {
                            final channelName = channels[index];
                            final displayName =
                                leadChannelLabel(context, channelName);
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
                                  leading: ChannelSourceIcon(
                                    sourceName: channelName,
                                    size: 30,
                                    background:
                                        context.appColors.surfacePrimary,
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
                    );
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
    List<dynamic> chatsForChannel, {
    bool closeDialog = true,
  }) {
    // Нет WhatsApp-чата — открываем пустой и шлём первое сообщение через Green API.
    if (chatsForChannel.isEmpty && isWhatsAppChannelName(channelName)) {
      if (closeDialog && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      openPendingGreenApiLeadChat(
        leadId: widget.leadId,
        leadName: widget.leadName,
      );
      return;
    }

    if (chatsForChannel.length == 1) {
      navigateToScreen(
        context,
        chatsForChannel[0].id,
        chatsForChannel[0].canSendMessage,
        chatsForChannel[0].channel.name,
        closeDialog: closeDialog,
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

    if (closeDialog && Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
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
    String initialChannelName, {
    bool closeDialog = true,
  }) {
    //print('LeadNavigateToChat: Navigating to chat screen with ID: $id, canSendMessage: $canSendMessage');
    if (closeDialog && Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
    openExistingLeadChatScreen(
      leadName: widget.leadName,
      chatId: id,
      canSendMessage: canSendMessage,
      initialChannelName: initialChannelName,
    );
  }
}
