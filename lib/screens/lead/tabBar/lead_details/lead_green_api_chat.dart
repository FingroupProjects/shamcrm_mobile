import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/models/lead/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/utils/green_api_integration_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Имя канала Green API на бэке. В UI показываем как WhatsApp.
const String kGreenApiChannelName = 'green_api';

/// Берём первый непустой телефон лида. wa_phone тоже подходит.
String? firstLeadPhone(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') {
      return trimmed;
    }
  }
  return null;
}

bool hasLeadPhoneNumber(String? phone) {
  return firstLeadPhone([phone]) != null;
}

/// green_api и whatsapp — один канал в CRM.
bool isWhatsAppChannelName(String? name) {
  final normalized = name?.trim().toLowerCase() ?? '';
  return normalized == 'green_api' || normalized == 'whatsapp';
}

/// Пункт WhatsApp в «Перейти в чат», если Green API включён.
/// Телефон лида сервер берёт сам по leadId. На клиенте номер может
/// не прийти в модели — из-за этого раньше пункт пропадали.
bool canOfferGreenApiWhatsApp(String? leadPhone) {
  return GreenApiIntegrationStore.enabled.value;
}

/// Тянем флаг с сервера. PIN его мог не успеть записать.
Future<void> refreshGreenApiAccess(ApiService apiService) async {
  await GreenApiIntegrationStore.hydrateFromPrefs();
  await apiService.fetchAndCacheUserData();
}

LeadNavigateChat? findWhatsAppLeadChat(List<LeadNavigateChat> chats) {
  for (final chat in chats) {
    if (isWhatsAppChannelName(chat.channel.name)) {
      return chat;
    }
  }
  return null;
}

/// Каналы лида плюс WhatsApp, если чата ещё нет, но писать уже можно.
List<String> visibleLeadChatChannels(
  List<LeadNavigateChat> chats,
  String? leadPhone,
) {
  final channels = <String>[];
  for (final chat in chats) {
    final name = chat.channel.name;
    if (name.isEmpty) continue;
    if (!channels.contains(name)) {
      channels.add(name);
    }
  }

  // Чата WhatsApp нет — добавляем пункт, чтобы открыть пустой чат.
  if (canOfferGreenApiWhatsApp(leadPhone) &&
      !channels.any(isWhatsAppChannelName)) {
    channels.add(kGreenApiChannelName);
  }
  return channels;
}

/// Уже существующий чат лида. Дальше сообщения идут как обычно.
void openExistingLeadChatScreen({
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
            taskFrom: '',
            taskTo: '',
            description: '',
            channel: initialChannelName,
            lastMessage: '',
            messageType: '',
            createDate: '',
            unreadCount: 0,
            canSendMessage: canSendMessage,
            chatUsers: const [],
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

/// Пустой WhatsApp. Первое сообщение уйдёт через send-green-api-message.
void openPendingGreenApiLeadChat({
  required int leadId,
  required String leadName,
}) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => BlocProvider(
        create: (context) => MessagingCubit(ApiService()),
        child: ChatSmsScreen(
          chatItem: Chats(
            id: 0,
            image: '',
            name: leadName,
            taskFrom: '',
            taskTo: '',
            description: '',
            channel: kGreenApiChannelName,
            lastMessage: '',
            messageType: '',
            createDate: '',
            unreadCount: 0,
            canSendMessage: true,
            chatUsers: const [],
          ).toChatItem(),
          chatId: 0,
          leadId: leadId,
          isPendingGreenApiChat: true,
          endPointInTab: 'lead',
          canSendMessage: true,
          initialChannelName: kGreenApiChannelName,
        ),
      ),
    ),
  );
}
