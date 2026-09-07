import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_voice_mini_player.dart';
import 'package:crm_task_manager/services/chat_voice_player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatVoiceMiniPlayerHost extends StatelessWidget {
  final Widget child;

  const ChatVoiceMiniPlayerHost({
    super.key,
    required this.child,
  });

  void _openActiveVoiceChat() {
    final track = ChatVoicePlayerService.instance.track;
    final chatItem = track?.chatItem;
    final navigator = navigatorKey.currentState;
    if (track == null || chatItem == null || navigator == null) return;
    if (ChatVoicePlayerService.instance.foregroundChatId == track.chatId) {
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MessagingCubit(ApiService()),
          child: ChatSmsScreen(
            chatItem: chatItem,
            chatId: track.chatId,
            chatUniqueId: track.chatUniqueId,
            endPointInTab: track.endPointInTab,
            canSendMessage: track.canSendMessage,
            initialChannelName: track.channelName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + kToolbarHeight,
          left: 0,
          right: 0,
          child: Material(
            elevation: 3,
            color: Colors.transparent,
            child: ChatVoiceMiniPlayer(
              onOpenChat: _openActiveVoiceChat,
            ),
          ),
        ),
      ],
    );
  }
}
