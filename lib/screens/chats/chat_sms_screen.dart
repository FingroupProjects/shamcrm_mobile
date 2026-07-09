import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_event.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_state.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/models/chatGetId_model.dart';
import 'package:crm_task_manager/models/integration_model.dart';
import 'package:crm_task_manager/utils/active_chat_tracker.dart';
import 'package:crm_task_manager/services/message_cache_service.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chatById_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chatById_task_screen.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance_sheet.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/image_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/input_field.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/location_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/media_group_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/pin_lead_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_corporate_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_user_corporate.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/telegram_chat_app_bar.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/voice_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/pin_message_widget.dart';
import 'package:crm_task_manager/screens/chats/location_picker_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/api_service_chats.dart';
import 'package:crm_task_manager/api/service/http_log_model.dart';
import 'package:crm_task_manager/api/service/http_logger.dart';
import 'package:crm_task_manager/api/service/message_reaction_api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart';
import 'package:crm_task_manager/services/chat_unread_counter_service.dart';
import 'package:crm_task_manager/services/chat_file_send_service.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_media_preview_sheet.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/file_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/message_bubble.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/utils/global_value.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/premium_haptic_wrapper.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/premium_context_menu.dart';
import 'package:table_calendar/table_calendar.dart';

class ChatSmsScreen extends StatefulWidget {
  final ChatItem chatItem;
  final int chatId;
  final String? chatUniqueId;
  final String endPointInTab;
  final bool canSendMessage;
  final String? initialChannelName;
  final ApiService apiService = ApiService();
  final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

  ChatSmsScreen({
    super.key,
    required this.chatItem,
    required this.chatId,
    this.chatUniqueId,
    required this.endPointInTab,
    required this.canSendMessage,
    this.initialChannelName,
  });

  @override
  State<ChatSmsScreen> createState() => _ChatSmsScreenState();
}

class _ChatSmsScreenState extends State<ChatSmsScreen>
    with WidgetsBindingObserver {
  final ItemScrollController _scrollControllerMessage = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  WebSocket? _webSocket;
  late StreamSubscription<ChannelReadEvent>? chatSubscribtion;
  late PusherChannelsClient socketClient;
  final ApiService apiService = ApiService();
  late String baseUrl;
  bool _canCreateChat = false;
  bool _isRequestInProgress = false;
  int? _highlightedMessageId;
  bool _isMenuOpen = false;
  bool _isSearching = false;
  String? _searchQuery;
  Timer? _searchDebounce;
  String? integrationUsername;
  String? channelName;
  ChatAdvertising? _chatAdvertising;
  int? _lastMarkedMessageId;
  bool _isRecordingInProgress = false;
  String? referralBody;
  ChatsBloc? _chatsBloc;
  MessagingCubit?
      _messagingCubit; // Сохраняем ссылку на MessagingCubit для использования в dispose
  final ActiveChatTracker _chatTracker =
      ActiveChatTracker(); // ✅ ДОБАВЛЕНО: Трекер активного чата
  final MessageCacheService _cacheService =
      MessageCacheService(); // ✅ ДОБАВЛЕНО: Сервис кэширования сообщений
  bool _isDisposing =
      false; // ✅ Флаг для предотвращения двойного вызова dispose
  bool _isAttachmentPickerOpen = false;
  bool _isLoadingFromCache = false; // ✅ Флаг загрузки из кэша
  bool _isLoadingFromApi = false; // ✅ Флаг загрузки с API
  String? _cachedCompanionName; // Кэшированное имя собеседника
  bool? _isGroupChat; // Флаг, является ли чат группой
  String _myDisplayName = '';
  String? _instagramResponseType; // direct | comment
  final Set<int> _expandedPostIds = {};
  final MessageReactionApiService _reactionApi = MessageReactionApiService();
  final ChatFileSendService _chatFileSendService = ChatFileSendService();
  bool _isNearBottom = true;
  bool _isLoadingOlderFromScroll = false;
  final Set<int> _pendingScrollButtonMessageIds = <int>{};
  final List<Message> _queuedSocketMessagesDuringSend = <Message>[];
  ChatAppearanceData _chatAppearance = ChatAppearanceData.defaults();

  int get _pendingNewMessagesCount => _pendingScrollButtonMessageIds.length;

  bool get _shouldShowScrollToBottomButton => !_isNearBottom;

  bool get _canUseReactionsInCurrentChat {
    final isLeadWith24hRestriction =
        widget.endPointInTab == 'lead' && !widget.canSendMessage;
    return !isLeadWith24hRestriction && !_isInstagramCommentChannel;
  }

  bool get _isInstagramCommentChannel {
    final name = channelName ?? '';
    return name.contains('instagram_comment');
  }

  Future<void> _showInstagramResponseTypePicker(Message? message) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      Icon(Icons.reply, color: context.appColors.textPrimary),
                  title: Text(localizations.translate('reply_as_comment')),
                  onTap: () => Navigator.pop(context, 'comment'),
                ),
                ListTile(
                  leading:
                      Icon(Icons.send, color: context.appColors.textPrimary),
                  title: Text(localizations.translate('reply_in_direct')),
                  onTap: () => Navigator.pop(context, 'direct'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() {
      _instagramResponseType = selected;
    });

    if (message != null) {
      _focusNode.requestFocus();
      context.read<MessagingCubit>().setReplyMessage(message);
    }
  }

  // Локальные реакции для мгновенного UI-обновления после тапа.
  final Map<int, List<MessageReaction>> _localReactions = {};
  final Map<String, DateTime> _recentReactionEventFingerprints = {};
  final Map<String, DateTime> _recentReactionSemanticFingerprints = {};

  Message _messageWithLocalReactions(Message message) {
    final localReactions = _localReactions[message.id];
    if (localReactions == null) {
      return message;
    }
    return message.copyWith(reactions: localReactions);
  }

  List<MessageReaction> _applyReactionOptimistically({
    required List<MessageReaction> current,
    required String emoji,
    required bool shouldAdd,
    String? currentMyEmoji,
  }) {
    final updated = List<MessageReaction>.from(current);

    if (shouldAdd) {
      // Гарантируем правило: у текущего пользователя только 1 реакция на сообщение.
      for (int i = updated.length - 1; i >= 0; i--) {
        final reaction = updated[i];
        final isCurrentMyReaction =
            currentMyEmoji != null && reaction.emoji == currentMyEmoji;
        if (!isCurrentMyReaction || reaction.emoji == emoji) continue;

        final nextCount = reaction.count - 1;
        if (nextCount <= 0) {
          updated.removeAt(i);
        } else {
          updated[i] = reaction.copyWith(
            count: nextCount,
            isMyReaction: false,
          );
        }
      }
    }

    final index = updated.indexWhere((reaction) => reaction.emoji == emoji);

    if (shouldAdd) {
      if (index == -1) {
        updated.add(
          MessageReaction(
            emoji: emoji,
            count: 1,
            users: const [],
            isMyReaction: true,
          ),
        );
      } else {
        final reaction = updated[index];
        updated[index] = reaction.copyWith(
          count: reaction.count + (reaction.isMyReaction ? 0 : 1),
          isMyReaction: true,
        );
      }
      return updated;
    }

    if (index == -1) {
      return updated;
    }

    final reaction = updated[index];
    final isCurrentMyReaction =
        currentMyEmoji != null && reaction.emoji == currentMyEmoji;
    final nextCount = reaction.count - (isCurrentMyReaction ? 1 : 0);

    if (nextCount <= 0) {
      updated.removeAt(index);
    } else {
      updated[index] = reaction.copyWith(
        count: nextCount,
        isMyReaction: false,
      );
    }

    return updated;
  }

  List<MessageReaction> _normalizeSingleMyReaction(
    List<MessageReaction> reactions, {
    String? preferredMyEmoji,
  }) {
    final normalized = List<MessageReaction>.from(reactions);

    String? selectedMyEmoji = preferredMyEmoji;
    if (selectedMyEmoji == null ||
        !normalized.any((reaction) => reaction.emoji == selectedMyEmoji)) {
      for (final reaction in normalized) {
        if (reaction.isMyReaction) {
          selectedMyEmoji = reaction.emoji;
          break;
        }
      }
    }

    if (selectedMyEmoji == null) {
      return normalized;
    }

    for (int i = normalized.length - 1; i >= 0; i--) {
      final reaction = normalized[i];
      if (!reaction.isMyReaction || reaction.emoji == selectedMyEmoji) continue;

      final nextCount = reaction.count - 1;
      if (nextCount <= 0) {
        normalized.removeAt(i);
      } else {
        normalized[i] = reaction.copyWith(
          count: nextCount,
          isMyReaction: false,
        );
      }
    }

    return normalized;
  }

  bool _isMyReactionCandidate(
    MessageReaction reaction, {
    required String myName,
  }) {
    if (reaction.isMyReaction) return true;

    final myId = userID.value.trim();
    final normalizedMyName = myName.trim().toLowerCase();
    final normalizedNotifierName = (userName.value ?? '').trim().toLowerCase();

    for (final user in reaction.users) {
      if (myId.isNotEmpty && user.id > 0 && user.id.toString() == myId) {
        return true;
      }

      final reactionUserName = user.name.trim().toLowerCase();
      if (reactionUserName.isEmpty) continue;

      if (normalizedMyName.isNotEmpty &&
          (reactionUserName == normalizedMyName ||
              reactionUserName.contains(normalizedMyName) ||
              normalizedMyName.contains(reactionUserName))) {
        return true;
      }

      if (normalizedNotifierName.isNotEmpty &&
          (reactionUserName == normalizedNotifierName ||
              reactionUserName.contains(normalizedNotifierName) ||
              normalizedNotifierName.contains(reactionUserName))) {
        return true;
      }
    }

    return false;
  }

  Future<void> _toggleMessageReaction(Message message, String emoji) async {
    if (!_canUseReactionsInCurrentChat) return;
    if (message.id <= 0) return;

    final effectiveMessage = _messageWithLocalReactions(message);
    final previousReactions = effectiveMessage.reactions;
    final myName = await _getMyDisplayName();
    MessageReaction? currentMyReaction;
    for (final reaction in previousReactions) {
      if (_isMyReactionCandidate(reaction, myName: myName)) {
        currentMyReaction = reaction;
        break;
      }
    }
    final isMyReaction = previousReactions.any(
      (reaction) =>
          reaction.emoji == emoji &&
          _isMyReactionCandidate(reaction, myName: myName),
    );
    final optimisticReactions = _normalizeSingleMyReaction(
      _applyReactionOptimistically(
        current: previousReactions,
        emoji: emoji,
        shouldAdd: !isMyReaction,
        currentMyEmoji: currentMyReaction?.emoji,
      ),
      preferredMyEmoji: isMyReaction ? null : emoji,
    );

    setState(() {
      _localReactions[message.id] = optimisticReactions;
    });

    try {
      if (isMyReaction) {
        await _reactionApi.sendReaction(
          chatId: widget.chatId,
          messageId: message.id,
          reaction: emoji,
          remove: true,
        );
      } else {
        if (currentMyReaction != null && currentMyReaction.emoji != emoji) {
          await _reactionApi.sendReaction(
            chatId: widget.chatId,
            messageId: message.id,
            reaction: currentMyReaction.emoji,
            remove: true,
          );
        }

        await _reactionApi.sendReaction(
          chatId: widget.chatId,
          messageId: message.id,
          reaction: emoji,
          remove: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localReactions[message.id] = previousReactions;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .translate('failed_to_update_reaction'),
          ),
          backgroundColor: context.appColors.error,
        ),
      );
    }
  }

  void _logSocketEventToInspector({
    required String eventName,
    required String channel,
    required String payload,
    String? error,
  }) {
    final id = '${DateTime.now().microsecondsSinceEpoch}_$eventName';
    HttpLogger().addLog(
      HttpLogModel(
        id: id,
        timestamp: DateTime.now(),
        method: 'WS',
        url: '/socket/$channel/$eventName',
        requestHeaders: const {'Transport': 'WebSocket'},
        requestBody: payload,
        statusCode: error == null ? 200 : 500,
        responseBody: error == null ? 'Socket event received' : null,
        error: error,
        duration: Duration.zero,
      ),
    );
  }

  bool _shouldSkipDuplicateReactionEvent({
    required String eventName,
    required String payload,
  }) {
    final now = DateTime.now();
    _recentReactionEventFingerprints.removeWhere(
      (_, ts) => now.difference(ts).inSeconds > 8,
    );

    final fingerprint = '$eventName|${payload.trim()}';
    if (_recentReactionEventFingerprints.containsKey(fingerprint)) {
      return true;
    }
    _recentReactionEventFingerprints[fingerprint] = now;
    return false;
  }

  bool _shouldSkipDuplicateReactionSemantically(Map<String, dynamic> payload) {
    final now = DateTime.now();
    _recentReactionSemanticFingerprints.removeWhere(
      (_, ts) => now.difference(ts).inSeconds > 4,
    );

    final messageId = _parseMessageIdFromReactionEvent(payload);
    final emoji = _parseReactionEmojiFromPayload(payload);
    final removed = _parseReactionRemovedFromPayload(payload);
    if (messageId == null || emoji == null || emoji.isEmpty) {
      return false;
    }

    final semanticKey = '$messageId|$emoji|$removed';
    if (_recentReactionSemanticFingerprints.containsKey(semanticKey)) {
      return true;
    }

    _recentReactionSemanticFingerprints[semanticKey] = now;
    return false;
  }

  Future<void> _processReactionSocketEvent({
    required String eventName,
    required String channel,
    required String payload,
    required String logPrefix,
  }) async {
    if (_shouldSkipDuplicateReactionEvent(
        eventName: eventName, payload: payload)) {
      debugPrint('⏭️ [SOCKET] $logPrefix duplicate reaction event skipped');
      return;
    }

    debugPrint('🔔 [SOCKET] $logPrefix $eventName RECEIVED');
    _logSocketEventToInspector(
      eventName: eventName,
      channel: channel,
      payload: payload,
    );

    try {
      if (payload.trim().isEmpty) {
        context
            .read<MessagingCubit>()
            .refreshLatestPage(widget.chatId, chatType: widget.endPointInTab);
        return;
      }
      final decoded = json.decode(payload);
      if (decoded is! Map) {
        context
            .read<MessagingCubit>()
            .refreshLatestPage(widget.chatId, chatType: widget.endPointInTab);
        return;
      }
      final normalizedPayload =
          _coerceReactionPayload(Map<String, dynamic>.from(decoded));
      if (_shouldSkipDuplicateReactionSemantically(normalizedPayload)) {
        debugPrint(
            '⏭️ [SOCKET] $logPrefix duplicate semantic reaction skipped');
        return;
      }
      _handleMessageReactedEvent(normalizedPayload);
    } catch (e) {
      debugPrint('❌ [SOCKET] $logPrefix $eventName parse error: $e');
      _logSocketEventToInspector(
        eventName: '$eventName.error',
        channel: channel,
        payload: payload,
        error: e.toString(),
      );
      context
          .read<MessagingCubit>()
          .refreshLatestPage(widget.chatId, chatType: widget.endPointInTab);
    }
  }

  void _bindReactionAliasesToChannel({
    required dynamic channel,
    required String channelName,
    required List<String> reactionEventAliases,
    required String logPrefix,
  }) {
    for (final reactionEvent in reactionEventAliases) {
      channel.bind(reactionEvent).listen((event) async {
        await _processReactionSocketEvent(
          eventName: reactionEvent,
          channel: channelName,
          payload: event.data,
          logPrefix: logPrefix,
        );
      });
    }
  }

  List<MessageReaction> _parseReactionsFromDynamic(dynamic source) {
    if (source is List) {
      return source
          .whereType<Map>()
          .map((item) =>
              MessageReaction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (source is Map) {
      final List<MessageReaction> parsed = [];
      source.forEach((emojiKey, value) {
        if (value is! Map) return;
        final data = Map<String, dynamic>.from(value);

        final countRaw = data['count'];
        final count = countRaw is int
            ? countRaw
            : int.tryParse(countRaw?.toString() ?? '') ?? 0;

        final usersRaw = data['users'];
        final List<ReactionUser> users = [];
        if (usersRaw is List) {
          for (final user in usersRaw) {
            if (user is Map) {
              users.add(ReactionUser.fromJson(Map<String, dynamic>.from(user)));
            } else if (user is String) {
              users.add(ReactionUser(id: 0, name: user));
            }
          }
        }

        parsed.add(
          MessageReaction(
            emoji: emojiKey.toString(),
            count: count,
            users: users,
            isMyReaction: data['is_my_reaction'] == true,
          ),
        );
      });
      return parsed;
    }
    return const [];
  }

  int? _parseMessageIdFromReactionEvent(Map<String, dynamic> payload) {
    final dto = payload['dto'];
    final dtoProperties = (dto is Map) ? dto['properties'] : null;
    final candidates = [
      payload['message_id'],
      payload['id'],
      (payload['message'] is Map) ? payload['message']['id'] : null,
      (payload['data'] is Map) ? payload['data']['message_id'] : null,
      (payload['data'] is Map && payload['data']['message'] is Map)
          ? payload['data']['message']['id']
          : null,
      (dtoProperties is Map) ? dtoProperties['message_id'] : null,
    ];

    for (final value in candidates) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  List<MessageReaction> _parseReactionsFromReactionEvent(
      Map<String, dynamic> payload) {
    final topSummary = _parseReactionsFromDynamic(payload['reactions_summary']);
    if (topSummary.isNotEmpty || payload['reactions_summary'] is Map) {
      return topSummary;
    }

    final direct = _parseReactionsFromDynamic(payload['reactions']);
    if (direct.isNotEmpty) return direct;

    final message = payload['message'];
    if (message is Map) {
      final nested = _parseReactionsFromDynamic(message['reactions']);
      if (nested.isNotEmpty) return nested;
    }

    final data = payload['data'];
    if (data is Map) {
      final summary = _parseReactionsFromDynamic(data['reactions_summary']);
      if (summary.isNotEmpty || data['reactions_summary'] is Map) {
        return summary;
      }

      final dataDirect = _parseReactionsFromDynamic(data['reactions']);
      if (dataDirect.isNotEmpty) return dataDirect;
      if (data['message'] is Map) {
        final dataNested =
            _parseReactionsFromDynamic(data['message']['reactions']);
        if (dataNested.isNotEmpty) return dataNested;
      }
    }

    return const [];
  }

  Map<String, dynamic> _coerceReactionPayload(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = json.decode(data);
        if (decoded is Map) {
          final merged = Map<String, dynamic>.from(payload);
          merged['data'] = Map<String, dynamic>.from(decoded);
          return merged;
        }
      } catch (_) {}
    }
    return payload;
  }

  String? _parseReactionEmojiFromPayload(Map<String, dynamic> payload) {
    final dto = payload['dto'];
    final dtoProperties = (dto is Map) ? dto['properties'] : null;
    final candidates = [
      payload['reaction'],
      payload['emoji'],
      (payload['data'] is Map) ? payload['data']['reaction'] : null,
      (payload['data'] is Map) ? payload['data']['emoji'] : null,
      (dtoProperties is Map) ? dtoProperties['reaction'] : null,
      (dtoProperties is Map) ? dtoProperties['emoji'] : null,
    ];

    for (final value in candidates) {
      final emoji = value?.toString().trim() ?? '';
      if (emoji.isNotEmpty) return emoji;
    }
    return null;
  }

  bool _parseReactionRemovedFromPayload(Map<String, dynamic> payload) {
    final dto = payload['dto'];
    final dtoProperties = (dto is Map) ? dto['properties'] : null;
    final candidates = [
      payload['removed'],
      payload['remove'],
      (payload['data'] is Map) ? payload['data']['removed'] : null,
      (payload['data'] is Map) ? payload['data']['remove'] : null,
      (dtoProperties is Map) ? dtoProperties['removed'] : null,
      (dtoProperties is Map) ? dtoProperties['remove'] : null,
    ];

    for (final value in candidates) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
    }
    return false;
  }

  Message? _findMessageByIdInState(int messageId) {
    final state = context.read<MessagingCubit>().state;
    if (state is! MessagesCollectionState) return null;
    final source = state.messages;
    for (final message in source) {
      if (message.id == messageId) return message;
    }
    return null;
  }

  List<MessageReaction> _applySocketReactionDelta({
    required List<MessageReaction> current,
    required String emoji,
    required bool removed,
  }) {
    final updated = List<MessageReaction>.from(current);
    final index = updated.indexWhere((reaction) => reaction.emoji == emoji);

    if (removed) {
      if (index == -1) return updated;
      final reaction = updated[index];
      final nextCount = reaction.count - 1;
      if (nextCount <= 0) {
        updated.removeAt(index);
      } else {
        updated[index] = reaction.copyWith(count: nextCount);
      }
      return updated;
    }

    if (index == -1) {
      updated.add(
        MessageReaction(
          emoji: emoji,
          count: 1,
          users: const [],
          isMyReaction: false,
        ),
      );
      return updated;
    }

    final reaction = updated[index];
    updated[index] = reaction.copyWith(count: reaction.count + 1);
    return updated;
  }

  void _handleMessageReactedEvent(Map<String, dynamic> payload) {
    payload = _coerceReactionPayload(payload);
    final messageId = _parseMessageIdFromReactionEvent(payload);
    if (messageId == null) {
      debugPrint('⚠️ [SOCKET] chat.messageReacted: messageId not found');
      return;
    }

    List<MessageReaction> reactions =
        _normalizeSingleMyReaction(_parseReactionsFromReactionEvent(payload));

    if (reactions.isEmpty) {
      final emoji = _parseReactionEmojiFromPayload(payload);
      if (emoji != null) {
        final removed = _parseReactionRemovedFromPayload(payload);
        final currentMessage = _findMessageByIdInState(messageId);
        final currentReactions = currentMessage == null
            ? const <MessageReaction>[]
            : _messageWithLocalReactions(currentMessage).reactions;
        reactions = _applySocketReactionDelta(
          current: currentReactions,
          emoji: emoji,
          removed: removed,
        );
      }
    }

    debugPrint(
        '✅ [SOCKET] chat.messageReacted APPLY: messageId=$messageId, reactions=${reactions.length}');
    context.read<MessagingCubit>().updateMessageReactionsFromSocket(
          messageId: messageId,
          reactions: reactions,
        );

    if (_localReactions.containsKey(messageId)) {
      setState(() {
        _localReactions.remove(messageId);
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<MessagingCubit>().resetAndSearch(
            widget.chatId,
            search: query,
            chatType: widget.endPointInTab,
          );
    });
  }

  void _handleVisiblePositionsChanged() {
    if (!mounted) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final isNearBottomNow = positions.any(
      (position) => position.index <= 1 && position.itemTrailingEdge > 0,
    );
    final bottomStateChanged = _isNearBottom != isNearBottomNow;
    _isNearBottom = isNearBottomNow;

    if (_isNearBottom && _pendingScrollButtonMessageIds.isNotEmpty) {
      setState(() {
        _pendingScrollButtonMessageIds.clear();
      });
    } else if (bottomStateChanged) {
      setState(() {});
    }

    final currentState = context.read<MessagingCubit>().state;
    if (currentState is! MessagesCollectionState) {
      return;
    }

    final maxVisibleIndex = positions
        .map((position) => position.index)
        .reduce((value, element) => value > element ? value : element);

    if (maxVisibleIndex >= currentState.messages.length - 3) {
      _loadOlderMessagesFromScroll();
    }

    if (_isNearBottom) {
      _markMessagesAsRead();
    }
  }

  Future<void> _loadOlderMessagesFromScroll() async {
    final currentState = context.read<MessagingCubit>().state;
    if (currentState is! MessagesCollectionState ||
        _isLoadingOlderFromScroll ||
        currentState.isLoadingInitial ||
        currentState.isLoadingMore ||
        currentState.isFromCache ||
        currentState.hasReachedMax) {
      return;
    }

    _isLoadingOlderFromScroll = true;
    try {
      await context.read<MessagingCubit>().loadOlderPage(
            widget.chatId,
            chatType: widget.endPointInTab,
          );
    } finally {
      _isLoadingOlderFromScroll = false;
    }
  }

  Future<void> _scrollToBottom({
    bool force = false,
  }) async {
    if (!_scrollControllerMessage.isAttached) return;
    if (!force && !_isNearBottom) return;

    await _scrollControllerMessage.scrollTo(
      index: 0,
      alignment: 0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _registerIncomingMessageForScrollButton(Message message) {
    if (message.isMyMessage || _isNearBottom || !mounted) {
      return;
    }

    final wasAdded = _pendingScrollButtonMessageIds.add(message.id);
    if (wasAdded) {
      setState(() {});
    }
  }

  Future<void> _handleScrollToBottomTap() async {
    if (!mounted) return;

    setState(() {
      _pendingScrollButtonMessageIds.clear();
    });

    await _scrollToBottom(force: true);
    _markMessagesAsRead();
  }

  Widget _buildScrollToBottomButton() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      offset:
          _shouldShowScrollToBottomButton ? Offset.zero : const Offset(0, 0.25),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _shouldShowScrollToBottomButton ? 1 : 0,
        child: IgnorePointer(
          ignoring: !_shouldShowScrollToBottomButton,
          child: Material(
            color: context.appColors.overlay.withValues(alpha: 0.0),
            child: InkWell(
              onTap: _handleScrollToBottomTap,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appColors.backgroundSecondary,
                      context.appColors.surfacePrimary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: context.appColors.borderSubtle,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.appColors.buttonPrimaryBg,
                      size: 28,
                    ),
                    if (_pendingNewMessagesCount > 0)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.appColors.buttonPrimaryBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: context.appColors.textInverse,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _pendingNewMessagesCount > 99
                                ? '99+'
                                : '$_pendingNewMessagesCount',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.appColors.surfacePrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkPermissions() async {
    if (widget.endPointInTab == 'lead') {
      final canCreate = await apiService.hasPermission('chat.create');
      setState(() {
        _canCreateChat = canCreate;
      });
    } else {
      setState(() {
        _canCreateChat = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChatAppearance();
    _checkPermissions();
    _getMyDisplayName();
    ChatUnreadCounterService.instance.markChatOpened(
      unreadCount: widget.chatItem.unreadCount,
      type: widget.endPointInTab,
    );
    if (widget.initialChannelName != null &&
        widget.initialChannelName!.isNotEmpty) {
      channelName = widget.initialChannelName;
    }

    _chatsBloc = context.read<ChatsBloc>();
    _messagingCubit = context
        .read<MessagingCubit>(); // Сохраняем ссылку для использования в dispose
    _itemPositionsListener.itemPositions
        .addListener(_handleVisiblePositionsChanged);

    // ✅ КРИТИЧНО: Устанавливаем этот чат как активный
    // Это нужно, чтобы при обновлении через сокет не инкрементировать счетчик
    // для сообщений, которые пользователь читает в реальном времени
    // ✅ ИСПРАВЛЕНО: Используем uniqueId для привязки чата
    _chatTracker.setActiveChat(widget.chatUniqueId);

    context.read<ListenSenderFileCubit>().updateValue(false);
    context.read<ListenSenderVoiceCubit>().updateValue(false);
    context.read<ListenSenderTextCubit>().updateValue(false);

    // ✅ КРИТИЧНО: Используем addPostFrameCallback для оптимистичной параллельной загрузки
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ ШАГ 1: Загружаем кэш МГНОВЕННО (без await, не блокируем UI)
      _loadCachedMessagesOptimistically();

      // ✅ ШАГ 2: Параллельно инициализируем сервисы и загружаем свежие данные
      _initializeServicesOptimized();
    });
  }

  Future<void> _loadChatAppearance() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ChatAppearanceData.storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && mounted) {
        setState(() {
          _chatAppearance = ChatAppearanceData.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        });
      }
    } catch (error) {
      debugPrint('Failed to decode chat appearance: $error');
    }
  }

  Future<void> _saveChatAppearance(ChatAppearanceData appearance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ChatAppearanceData.storageKey,
      jsonEncode(appearance.toJson()),
    );
  }

  Future<void> _openChatAppearanceSheet() async {
    final updated = await showChatAppearanceSheet(
      context: context,
      initialValue: _chatAppearance,
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _chatAppearance = updated;
    });

    await _saveChatAppearance(updated);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_persistCurrentChatMessages());
    }
  }

  bool get _isSendingFilesNow {
    return context.read<ListenSenderFileCubit>().state;
  }

  void _dismissKeyboard() {
    _focusNode.unfocus();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _persistCurrentChatMessages() async {
    final currentState = _messagingCubit?.state;
    if (currentState is MessagesCollectionState) {
      await _cacheService.cacheMessages(widget.chatId, currentState.messages);
    }
  }

  bool _canMutateMessagingCubit(MessagingCubit cubit) {
    return mounted && !cubit.isClosed;
  }

  void _queueSocketMessageDuringSend(Message message) {
    _queuedSocketMessagesDuringSend.add(message);
  }

  void _flushQueuedSocketMessages() {
    if (!mounted || _queuedSocketMessagesDuringSend.isEmpty) return;
    final cubit = context.read<MessagingCubit>();
    for (final message in _queuedSocketMessagesDuringSend) {
      cubit.mergeIncomingMessage(message);
    }
    _queuedSocketMessagesDuringSend.clear();
  }

  Future<void> _retryInitialization() async {
    try {
      await _initializeBaseUrl();
      context
          .read<MessagingCubit>()
          .loadInitialPage(widget.chatId, chatType: widget.endPointInTab);
    } catch (e) {
      debugPrint('Retry failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .translate('retry_failed_with_error')
                  .replaceFirst('{error}', e.toString()),
            ),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

// ✅ НОВЫЙ МЕТОД: Единая логика определения isMyMessage для всех сокет-событий
  /// ✅ ИСПРАВЛЕННЫЙ МЕТОД: Единая логика определения isMyMessage для всех сокет-событий
  Future<bool> _determineIsMyMessage({
    required String? messageSenderId,
    required String? messageSenderType,
    required String? messageSenderName, // Added this parameter
    required String myUserId,
    required bool isLeadChat,
    bool? isMyMessageFromServer,
    String? debugContext = '', // для удобства понимания, откуда пришёл вызов
  }) async {
    // ✅ ПРИОРИТЕТ 1: Для lead-чата определяем сторону строго по sender.type
    if (isLeadChat && messageSenderType != null) {
      final normalizedType = messageSenderType.toLowerCase();
      if (normalizedType == 'lead') return false;
      if (normalizedType == 'user') return true;
    }

    // ✅ ПРИОРИТЕТ 2: Если есть ID отправителя и наш ID, это окончательный ответ
    if (messageSenderId != null &&
        messageSenderId.isNotEmpty &&
        myUserId.isNotEmpty) {
      bool idsMatch =
          (messageSenderId.toString().trim() == myUserId.toString().trim());
      if (idsMatch) {
        debugPrint('✅ [DETERMINE] ID matching success! TRUE');
        return true;
      }

      // Если ID не совпали — значит сообщение ЧУЖОЕ
      debugPrint('ℹ️ [DETERMINE] IDs do NOT match. FALSE');
      return false;
    }

    // ✅ ПРИОРИТЕТ 3: Флаг от сервера
    if (isMyMessageFromServer != null) {
      debugPrint('ℹ️ [DETERMINE] Using server flag: $isMyMessageFromServer');
      return isMyMessageFromServer;
    }

    debugPrint('🏁 [DETERMINE] Fallback → FALSE');
    return false;
  }

  Future<void> _initializeBaseUrl() async {
    debugPrint('Initializing baseUrl...');

    final prefs = await SharedPreferences.getInstance();

    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    String? verifiedDomain = await ApiService().getVerifiedDomain();
    debugPrint(
        'BaseUrl init - enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');

    if (enteredMainDomain == null || enteredDomain == null) {
      if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
        enteredMainDomain = verifiedDomain.split('-back.').last;
        enteredDomain = verifiedDomain.split('-back.').first;
        debugPrint(
            'BaseUrl init - Using verifiedDomain: $verifiedDomain, parsed mainDomain=$enteredMainDomain, domain=$enteredDomain');

        await prefs.setString('enteredMainDomain', enteredMainDomain);
        await prefs.setString('enteredDomain', enteredDomain);
      } else {
        throw Exception('Cannot determine domain for API calls');
      }
    }

    baseUrl = 'https://$enteredDomain-back.$enteredMainDomain';
    debugPrint('BaseUrl initialized: $baseUrl');

    await prefs.setString('cached_base_url', '$baseUrl/api');
    debugPrint('Cached baseUrl for all ApiService instances: $baseUrl/api');
  }

  /// ✅ НОВЫЙ МЕТОД: Получает и кэширует имя собеседника
  Future<void> _cacheCompanionName() async {
    try {
      debugPrint('🔍 Кэширование имени собеседника...');

      final prefs = await SharedPreferences.getInstance();
      final myUserId = prefs.getString('userID') ?? '';

      // Получаем данные чата
      final chatData = await widget.apiService.getChatById(widget.chatId);

      // ✅ Определяем, является ли чат группой
      final isGroup = chatData.group != null;
      setState(() {
        _isGroupChat = isGroup;
      });
      debugPrint(
          '=================-=== 📊 Чат является группой: $_isGroupChat');

      // Ищем собеседника в chatUsers
      if (chatData.chatUsers.isNotEmpty) {
        for (var chatUser in chatData.chatUsers) {
          final participantId = chatUser.participant.id.toString();

          if (participantId != myUserId) {
            // Это собеседник!
            final participantName = chatUser.participant.name;

            // Используем имя как есть (в модели нет lastname)
            String fullName = participantName;

            setState(() {
              _cachedCompanionName = fullName;
            });

            debugPrint('✅ Имя собеседника закэшировано: $_cachedCompanionName');
            return;
          }
        }
      }

      debugPrint(
          '=================-=== ⚠️ Имя участника не найдено в chatUsers');
    } catch (e) {
      debugPrint(
          '=================-=== ❌ Ошибка кэширования имени собеседника: $e');
    }
  }

  Future<String> _getMyDisplayName() async {
    if (_myDisplayName.isNotEmpty) return _myDisplayName;
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = (prefs.getString('userNameProfile') ??
              prefs.getString('userName') ??
              '')
          .trim();
      if (name.isNotEmpty) {
        if (mounted) {
          setState(() {
            _myDisplayName = name;
          });
        } else {
          _myDisplayName = name;
        }
      }
    } catch (e) {
      debugPrint('=================-=== ❌ Failed to load my display name: $e');
    }
    return _myDisplayName;
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // ========== РЕАКЦИИ ВРЕМЕННО ОТКЛЮЧЕНЫ ==========

  /// ✅ НОВЫЙ МЕТОД: Оптимистичная загрузка из кэша (мгновенно, без await)
  Future<void> _loadCachedMessagesOptimistically() async {
    try {
      setState(() {
        _isLoadingFromCache = true;
      });

      debugPrint(
          '=================-=== 🚀 ChatSmsScreen: Loading cached messages...');

      final cachedMessages =
          await _cacheService.getCachedMessages(widget.chatId);

      if (cachedMessages != null && cachedMessages.isNotEmpty && mounted) {
        debugPrint(
            '=================-=== ✅ ChatSmsScreen: Loaded ${cachedMessages.length} messages from CACHE');

        // ✅ Показываем кэшированные сообщения МГНОВЕННО (не ждем API)
        context.read<MessagingCubit>().showCachedMessages(cachedMessages);

        setState(() {
          _isLoadingFromCache = false;
        });

        // ✅ Скроллим вниз после небольшой задержки (чтобы UI успел отрисоваться)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scrollToBottom(force: true);
          }
        });
      } else {
        debugPrint(
            '=================-=== ⚠️ ChatSmsScreen: No cached messages found');
        setState(() {
          _isLoadingFromCache = false;
        });
      }
    } catch (e) {
      debugPrint(
          '=================-=== ❌ ChatSmsScreen: Error loading cache: $e');
      setState(() {
        _isLoadingFromCache = false;
      });
    }
  }

  /// ✅ ОПТИМИЗИРОВАННЫЙ МЕТОД: Параллельная инициализация (без блокировки UI)
  Future<void> _initializeServicesOptimized() async {
    setState(() {
      _isLoadingFromApi = true;
    });

    try {
      debugPrint(
          '🔧 ChatSmsScreen: Starting optimized parallel initialization...');

      // ✅ Запускаем ВСЁ параллельно (Future.wait)
      await Future.wait([
        _ensureDomainConfiguration(),
        apiService.initialize(),
        // ✅ Имя собеседника можно загрузить в фоне (не блокирует показ сообщений)
        _cacheCompanionName().catchError((e) {
          debugPrint(
              '=================-=== ⚠️ ChatSmsScreen: Name cache error (non-critical): $e');
        }),
      ], eagerError: false);

      baseUrl = await apiService.getDynamicBaseUrl();
      debugPrint(
          '=================-=== ✅ ChatSmsScreen: BaseURL initialized: $baseUrl');

      // ✅ Сокет подключается В ФОНЕ (не блокирует показ сообщений)
      _initializeSocket().catchError((e) {
        debugPrint(
            '=================-=== ⚠️ ChatSmsScreen: Socket init error (non-critical): $e');
      });

      // ✅ Загружаем свежие сообщения с API (обновляет кэш)
      await _loadMessagesFromApi();

      // ✅ Интеграцию для лидов загружаем в фоне (не блокирует UI)
      if (widget.endPointInTab == 'lead') {
        _fetchIntegration().catchError((e) {
          debugPrint(
              '=================-=== ⚠️ ChatSmsScreen: Integration error (non-critical): $e');
        });
      }

      debugPrint(
          '=================-=== ✅ ChatSmsScreen: Optimized initialization completed');
    } catch (e, stackTrace) {
      debugPrint(
          '=================-=== ❌ ChatSmsScreen: Initialization error: $e');
      debugPrint('StackTrace: $stackTrace');

      if (mounted) {
        _showInitializationError(e.toString());

        // ✅ Пытаемся загрузить сообщения даже при ошибке инициализации
        try {
          await _loadMessagesFromApi();
        } catch (e2) {
          debugPrint(
              '❌ ChatSmsScreen: Failed to load messages after init error: $e2');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFromApi = false;
        });
      }
    }
  }

  /// ✅ НОВЫЙ МЕТОД: Загрузка сообщений с API + кэширование
  Future<void> _loadMessagesFromApi() async {
    try {
      debugPrint('🌐 ChatSmsScreen: Fetching fresh messages from API...');

      final messagingCubit = context.read<MessagingCubit>();
      await messagingCubit.loadInitialPage(
        widget.chatId,
        chatType: widget.endPointInTab,
      );

      final state = messagingCubit.state;
      if (state is MessagesCollectionState && state.messages.isNotEmpty) {
        await _cacheService.cacheMessages(widget.chatId, state.messages);
        debugPrint(
            '=================-=== ✅ ChatSmsScreen: Cached ${state.messages.length} fresh messages');
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToBottom();
        }
      });
    } catch (e) {
      debugPrint(
          '=================-=== ❌ ChatSmsScreen: Error loading messages from API: $e');
    }
  }

  /// ✅ СТАРЫЙ МЕТОД: Оставлен для совместимости (можно использовать для retry)
  Future<void> _initializeServices() async {
    // Перенаправляем на оптимизированную версию
    await _initializeServicesOptimized();
  }

  Future<void> _ensureDomainConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    String? verifiedDomain = await ApiService().getVerifiedDomain();

    debugPrint(
        'Domain check: enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');

    if ((enteredMainDomain == null || enteredDomain == null) &&
        verifiedDomain != null) {
      if (verifiedDomain.contains('-back.')) {
        final parts = verifiedDomain.split('-back.');
        enteredDomain = parts[0];
        enteredMainDomain = parts[1];
      } else {
        enteredDomain = 'default';
        enteredMainDomain = verifiedDomain;
      }

      await prefs.setString('enteredMainDomain', enteredMainDomain);
      await prefs.setString('enteredDomain', enteredDomain);

      debugPrint(
          'Domain configured from verifiedDomain: $enteredDomain-back.$enteredMainDomain');
    } else if (enteredMainDomain == null || enteredDomain == null) {
      final qrData = await ApiService().getQrData();
      if (qrData['domain'] != null && qrData['mainDomain'] != null) {
        await prefs.setString('enteredDomain', qrData['domain']!);
        await prefs.setString('enteredMainDomain', qrData['mainDomain']!);
        debugPrint(
            'Domain configured from QR data: ${qrData['domain']}-back.${qrData['mainDomain']}');
      } else {
        throw Exception('Не удалось определить домен для подключения');
      }
    }
  }

  Future<void> _initializeSocket() async {
    try {
      debugPrint(
          '=================-=== 🔌 ChatSmsScreen: Starting socket initialization...');
      await setUpServices();
      debugPrint(
          '=================-=== ✅ ChatSmsScreen: Socket initialization completed');
    } catch (e) {
      debugPrint(
          '=================-=== ❌ ChatSmsScreen: Socket initialization error: $e');
    }
  }

  void _showInitializationError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppLocalizations.of(context)!.translate('partial_connection_error')}: ${_getReadableError(error)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appColors.surfacePrimary,
          ),
        ),
        backgroundColor: context.appColors.warning,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.translate('retry'),
          textColor: context.appColors.textInverse,
          onPressed: () {
            _initializeServices();
          },
        ),
      ),
    );
  }

  String _getReadableError(String error) {
    if (error.contains('type \'Null\' is not a subtype of type \'String\'')) {
      return 'ошибка данных сервера';
    }
    if (error.contains('No host specified in URI null')) {
      return 'проблема настроек подключения';
    }
    if (error.contains('Не удалось определить домен')) {
      return 'не настроен домен';
    }
    return 'неизвестная ошибка';
  }

  Future<void> _forceInitializeDomain() async {
    final prefs = await SharedPreferences.getInstance();

    String? verifiedDomain = await ApiService().getVerifiedDomain();

    if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
      String enteredMainDomain = verifiedDomain.split('-back.').last;
      String enteredDomain = verifiedDomain.split('-back.').first;

      await prefs.setString('enteredMainDomain', enteredMainDomain);
      await prefs.setString('enteredDomain', enteredDomain);

      debugPrint(
          'Force initialized domain: $enteredDomain-back.$enteredMainDomain');
    }
  }

  Future<void> _markMessagesAsRead() async {
    final state = context.read<MessagingCubit>().state;
    if (state is! MessagesCollectionState || !_isNearBottom) return;

    List<Message> messages = [];
    messages = state.messages;

    bool hasUnreadMessages = messages.any((msg) => !msg.isRead);
    if (messages.isNotEmpty && hasUnreadMessages) {
      final latestMessageId = messages.first.id;
      if (_lastMarkedMessageId == latestMessageId) {
        return;
      }
      try {
        await widget.apiService.readMessages(widget.chatId, latestMessageId);
        _lastMarkedMessageId = latestMessageId;
      } catch (e) {
        debugPrint(
            'ChatSmsScreen: Ошибка при пометке сообщений как прочитанными: $e');
      }
    }
  }

  Future<void> _fetchIntegration() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      debugPrint(
          'ChatSmsScreen: Fetching integration data for chatId: ${widget.chatId}');

      final chatData = await widget.apiService.getChatById(widget.chatId);
      debugPrint('=================-=== ChatSmsScreen: Chat data received');

      setState(() {
        referralBody = chatData.referralBody;
        _chatAdvertising = chatData.advertising;
        prefs.setString('referral_body_${widget.chatId}', referralBody ?? '');
      });

      IntegrationForLead? integration;
      try {
        integration =
            await widget.apiService.getIntegrationForLead(widget.chatId);
        debugPrint(
            'ChatSmsScreen: Integration data received: ${integration.username}');
      } catch (integrationError) {
        debugPrint(
            '=================-=== ChatSmsScreen: Integration request failed: $integrationError');
        integration = null;
      }

      setState(() {
        if (integration != null) {
          integrationUsername = integration.username ??
              AppLocalizations.of(context)!.translate('unknown_channel');
          channelName =
              _determineChannelType(integration) ?? chatData.channelName;
        } else {
          integrationUsername = chatData.name.isNotEmpty
              ? chatData.name
              : AppLocalizations.of(context)!.translate('unknown_channel');
          channelName = chatData.channelName;
        }

        prefs.setString(
            'integration_username_${widget.chatId}', integrationUsername!);
        prefs.setString('channel_name_${widget.chatId}', channelName!);
      });

      debugPrint(
          '=================-=== ChatSmsScreen: Integration configured - username: $integrationUsername, channel: $channelName');
    } catch (e) {
      debugPrint(
          '=================-=== ChatSmsScreen: Error fetching integration data: $e');

      setState(() {
        integrationUsername =
            prefs.getString('integration_username_${widget.chatId}') ??
                AppLocalizations.of(context)!.translate('unknown_channel');
        channelName =
            prefs.getString('channel_name_${widget.chatId}') ?? 'unknown';
        referralBody = prefs.getString('referral_body_${widget.chatId}');
      });

      debugPrint(
          '=================-=== ChatSmsScreen: Using cached integration data');
    }
  }

  String? _determineChannelType(IntegrationForLead integration) {
    if (integration.username != null) {
      final username = integration.username!.toLowerCase();

      if (username.contains('telegram') || username.contains('tg')) {
        return 'telegram';
      } else if (username.contains('green_api') ||
          username.contains('whatsapp') ||
          username.contains('wa')) {
        return 'whatsapp';
      } else if (username.contains('email') || username.contains('mail')) {
        return 'email';
      } else if (username.contains('instagram') || username.contains('ig')) {
        return 'instagram';
      } else if (username.contains('facebook') || username.contains('fb')) {
        return 'facebook';
      } else if (username.contains('web') || username.contains('site')) {
        return 'site';
      }
    }

    return 'messenger';
  }

  Future<void> _openTargetMediaUrl() async {
    final advertising = _chatAdvertising;
    if (advertising == null || !mounted) {
      return;
    }

    final mediaUrl = advertising.mediaUrl?.trim();
    if (mediaUrl == null || mediaUrl.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('target_has_no_media_url'),
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(mediaUrl);
    if (uri == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('invalid_media_url'),
          ),
        ),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('failed_to_open_media_url'),
          ),
        ),
      );
    }
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.setAsset('assets/audio/send.mp3');
      await _audioPlayer.play();
    } catch (e) {
      ////print('Error playing sound: $e');
    }
  }

  Future<void> _fetchBaseUrl() async {
    baseUrl = await apiService.getDynamicBaseUrl();
  }

  Future<void> _showDatePicker(
      BuildContext context, List<Message> messages) async {
    final DateTime currentDate = DateTime.now();
    final Map<DateTime, List> events = {};
    for (var message in messages) {
      try {
        final date = DateTime.parse(message.createMessateTime).toLocal();
        final eventDate = DateTime(date.year, date.month, date.day);
        if (events[eventDate] == null) {
          events[eventDate] = [true];
        }
      } catch (e) {
        ////print('Ошибка парсинга даты ${message.createMessateTime}: $e');
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 450,
                  width: double.maxFinite,
                  color: context.appColors.surfacePrimary,
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2101),
                    focusedDay: currentDate,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    locale: 'ru_RU',
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        border: Border.all(
                          color: context.appColors.buttonPrimaryBg,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: context.appColors.buttonPrimaryBg,
                      ),
                      outsideDaysVisible: true,
                      outsideTextStyle: TextStyle(
                        color: context.appColors.textSecondary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.error,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronVisible: true,
                      rightChevronVisible: true,
                      titleTextStyle:
                          const TextStyle(fontSize: 18, fontFamily: 'Gilroy'),
                      titleTextFormatter: (date, locale) {
                        return DateFormat.yMMMM(locale).format(date);
                      },
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            right: 18,
                            bottom: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: context.appColors.buttonPrimaryBg,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                    eventLoader: (day) {
                      final normalizedDay =
                          DateTime(day.year, day.month, day.day);
                      return events[normalizedDay] ?? [];
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      final index =
                          _findMessageIndexByDate(messages, selectedDay);
                      if (index != -1) {
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToMessageIndex(selectedDay);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!
                                  .translate('no_messages_for_date')
                                  .replaceFirst(
                                      '{date}', formatDate(selectedDay)),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: context.appColors.error,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _findMessageIndexByDate(List<Message> messages, DateTime targetDate) {
    for (int i = messages.length - 1; i >= 0; i--) {
      final messageDate =
          DateTime.parse(messages[i].createMessateTime).toLocal();
      if (isSameDay(messageDate, targetDate)) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _scrollToMessageIndex(DateTime selectedDate) async {
    int messageIndex = -1;

    while (mounted) {
      final state = context.read<MessagingCubit>().state;
      if (state is! MessagesCollectionState) {
        return;
      }

      messageIndex = _findMessageIndexByDate(state.messages, selectedDate);
      if (messageIndex != -1) {
        break;
      }

      if (state.hasReachedMax) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .translate('no_messages_for_date')
                  .replaceFirst('{date}', formatDate(selectedDate)),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: context.appColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      await context.read<MessagingCubit>().loadOlderPage(
            widget.chatId,
            chatType: widget.endPointInTab,
          );
    }

    if (!_scrollControllerMessage.isAttached || messageIndex == -1) return;

    await _scrollControllerMessage.scrollTo(
      index: messageIndex,
      alignment: 0.1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  Widget _buildAvatar(String avatar) {
    bool isSupportAvatar = avatar == 'assets/icons/Profile/support_chat.png';
    bool isTaskSection = widget.endPointInTab == 'task';

    if (isTaskSection && !avatar.contains('<svg')) {
      return CircleAvatar(
        backgroundImage: AssetImage('assets/images/AvatarTask.png'),
        radius: ChatSmsStyles.avatarRadius,
        backgroundColor: context.appColors.surfacePrimary,
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }

    if (avatar.contains('<svg')) {
      final imageUrl = extractImageUrlFromSvg(avatar);
      if (imageUrl != null) {
        return Container(
          width: ChatSmsStyles.avatarRadius * 2,
          height: ChatSmsStyles.avatarRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        final text = extractTextFromSvg(avatar);
        final backgroundColor = extractBackgroundColorFromSvg(avatar);
        if (text != null && backgroundColor != null) {
          return Container(
            width: ChatSmsStyles.avatarRadius * 2,
            height: ChatSmsStyles.avatarRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: context.appColors.surfacePrimary,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: context.appColors.textInverse,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          return SvgPicture.string(
            avatar,
            width: ChatSmsStyles.avatarRadius * 2,
            height: ChatSmsStyles.avatarRadius * 2,
            placeholderBuilder: (context) => CircularProgressIndicator(),
          );
        }
      }
    }

    try {
      return CircleAvatar(
        backgroundImage: AssetImage(avatar),
        radius: ChatSmsStyles.avatarRadius,
        backgroundColor: isSupportAvatar
            ? context.appColors.textPrimary
            : context.appColors.surfacePrimary,
        onBackgroundImageError: (exception, stackTrace) {},
      );
    } catch (e) {
      return CircleAvatar(
        backgroundImage: AssetImage(isTaskSection
            ? 'assets/images/AvatarTask.png'
            : 'assets/images/AvatarChat.png'),
        radius: ChatSmsStyles.avatarRadius,
        backgroundColor: isSupportAvatar
            ? context.appColors.textPrimary
            : context.appColors.surfacePrimary,
      );
    }
  }

  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  String? extractTextFromSvg(String svg) {
    final textMatch = RegExp(r'<text[^>]*>(.*?)</text>').firstMatch(svg);
    return textMatch?.group(1);
  }

  Color? extractBackgroundColorFromSvg(String svg) {
    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    if (fillMatch != null) {
      final colorHex = fillMatch.group(1);
      if (colorHex != null) {
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    bool isSupportChat =
        widget.chatItem.avatar == 'assets/icons/Profile/image.png';
    return BlocListener<MessagingCubit, MessagingState>(
      listener: (context, state) {
        if (kDebugMode) {
          //print('ChatSmsScreen: Слушатель MessagingCubit, текущее состояние: $state');
        }
        if (state is MessagesCollectionState) {
          _markMessagesAsRead();
        }
      },
      child: BlocListener<DeleteMessageBloc, DeleteMessageState>(
        listener: (context, state) {
          if (state is DeleteMessageSuccess) {
            context
                .read<MessagingCubit>()
                .removeMessageLocally(state.messageId);
            if (widget.endPointInTab == 'task' ||
                widget.endPointInTab == 'corporate') {
              final chatsBloc = context.read<ChatsBloc>();
              chatsBloc.add(ClearChats());
              chatsBloc.add(FetchChats(endPoint: widget.endPointInTab));
            }
          }
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: TelegramChatAppBar(
            name: isSupportChat
                ? AppLocalizations.of(context)!.translate('support_chat_name')
                : (widget.chatItem.name.isNotEmpty
                    ? widget.chatItem.name
                    : AppLocalizations.of(context)!.translate('no_name')),
            avatar: widget.chatItem.avatar,
            isGroupChat: _isGroupChat == true,
            isSearching: _isSearching,
            isSupportChat: isSupportChat,
            appearance: _chatAppearance,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onBack: () => Navigator.pop(context),
            onAppearanceTap: _openChatAppearanceSheet,
            onProfileTap: isSupportChat
                ? null
                : () async {
                    if (_isRequestInProgress) return;
                    setState(() => _isRequestInProgress = true);
                    try {
                      if (widget.endPointInTab == 'lead') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserProfileScreen(chatId: widget.chatId),
                          ),
                        );
                      } else if (widget.endPointInTab == 'task') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskByIdScreen(chatId: widget.chatId),
                          ),
                        );
                      } else if (widget.endPointInTab == 'corporate') {
                        try {
                          final getChatById = await widget.apiService
                              .getChatById(widget.chatId);
                          if (getChatById.chatUsers.isNotEmpty &&
                              getChatById.chatUsers.length == 2 &&
                              getChatById.group == null) {
                            final prefs = await SharedPreferences.getInstance();
                            final userIdCheck = prefs.getString('userID') ?? '';
                            final otherUsers = getChatById.chatUsers
                                .where((user) =>
                                    user.participant.id.toString() !=
                                    userIdCheck)
                                .toList();

                            if (otherUsers.isNotEmpty) {
                              final participant = otherUsers.first.participant;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ParticipantProfileScreen(
                                    userId: participant.id.toString(),
                                    image: participant.image,
                                    name: participant.name,
                                    email: participant.email,
                                    phone: participant.phone,
                                    login: participant.login,
                                    lastSeen: participant.lastSeen.toString(),
                                    buttonChat: false,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CorporateProfileScreen(
                                    chatId: widget.chatId,
                                    chatItem: widget.chatItem,
                                  ),
                                ),
                              );
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CorporateProfileScreen(
                                  chatId: widget.chatId,
                                  chatItem: widget.chatItem,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint(
                            'Ошибка при открытии профиля корпоративного чата: $e',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CorporateProfileScreen(
                                chatId: widget.chatId,
                                chatItem: widget.chatItem,
                              ),
                            ),
                          );
                        }
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isRequestInProgress = false);
                      } else {
                        _isRequestInProgress = false;
                      }
                    }
                  },
            onSearchToggle: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = null;
                }
              });
              if (!_isSearching) {
                _searchDebounce?.cancel();
                context.read<MessagingCubit>().resetAndSearch(
                      widget.chatId,
                      search: null,
                      chatType: widget.endPointInTab,
                    );
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _searchFocusNode.requestFocus();
                  }
                });
              }
            },
            onSearchChanged: _onSearchChanged,
          ),
          backgroundColor: Colors.transparent,
          body: ChatAppearanceScope(
            appearance: _chatAppearance,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _dismissKeyboard,
              child: DecoratedBox(
                decoration: _chatAppearance.buildFullScreenDecoration(context),
                child: Stack(
                  children: [
                    _chatAppearance.buildBackgroundLayer(context),
                    ..._chatAppearance.buildBackgroundOrbs(context),
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            22,
                      ),
                      child: Column(
                        children: [
                          Expanded(child: messageListUi()),
                          if (widget.canSendMessage && _canCreateChat)
                            inputWidget()
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 50),
                              child: Center(
                                child: Text(
                                  widget.canSendMessage
                                      ? AppLocalizations.of(context)!.translate(
                                          'not_premission_to_send_sms')
                                      : AppLocalizations.of(context)!
                                          .translate('24_hour_leads'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Gilroy',
                                    color: context.appColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scrollToMessageReply(int messageId) async {
    int messageIndex = -1;

    while (mounted) {
      final state = context.read<MessagingCubit>().state;
      if (state is! MessagesCollectionState) {
        return;
      }

      messageIndex = state.messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        break;
      }

      if (state.hasReachedMax) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .translate('message_not_found_in_history'),
            ),
            backgroundColor: context.appColors.error,
          ),
        );
        return;
      }

      await context.read<MessagingCubit>().loadOlderPage(
            widget.chatId,
            chatType: widget.endPointInTab,
          );
    }

    if (!_scrollControllerMessage.isAttached || messageIndex == -1) return;

    await _scrollControllerMessage.scrollTo(
      index: messageIndex,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
    );

    setState(() {
      _highlightedMessageId = messageId;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _highlightedMessageId == messageId) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
  }

  Widget messageListUi() {
    return BlocBuilder<MessagingCubit, MessagingState>(
      builder: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        debugPrint(
            '=================-=== messageListUi: Building with state: $state');

        if (state is MessagesPartialErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 64, color: context.appColors.warning),
                SizedBox(height: 16),
                Text(
                  localizations.translate('partial_connection_error'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: context.appColors.warning,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.read<MessagingCubit>().getMessagesWithFallback(
                            widget.chatId,
                            chatType: widget.endPointInTab);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appColors.warning,
                        foregroundColor: context.appColors.textInverse,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        localizations.translate('retry'),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        context.read<MessagingCubit>().showEmptyChat();
                      },
                      child: Text(
                        localizations.translate('empty_chat'),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: context.appColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (state is MessagesErrorState) {
          if (state.error.contains('No host specified in URI null')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: context.appColors.error),
                  SizedBox(height: 16),
                  Text(
                    localizations.translate('server_connection_error'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: context.appColors.error,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MessagingCubit>().getMessagesWithFallback(
                          widget.chatId,
                          chatType: widget.endPointInTab);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.error,
                      foregroundColor: context.appColors.textInverse,
                    ),
                    child: Text(localizations.translate('retry_attempt')),
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      context.read<MessagingCubit>().showEmptyChat();
                    },
                    child: Text(localizations.translate('open_empty_chat')),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.translate('messages_load_error')),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<MessagingCubit>().getMessagesWithFallback(
                        widget.chatId,
                        chatType: widget.endPointInTab);
                  },
                  child: Text(localizations.translate('retry')),
                ),
              ],
            ),
          );
        }

        if (state is MessagesLoadingState) {
          return Center(child: CircularProgressIndicator.adaptive());
        }
        if (state is MessagesCollectionState) {
          final messages = state.messages;
          debugPrint('messageListUi: Rendering ${messages.length} messages');
          final pinnedMessages = state.pinnedMessages;
          final hasLeadPinnedHeader =
              widget.endPointInTab == 'lead' && integrationUsername != null;
          final topOverlayOffset =
              hasLeadPinnedHeader ? 88.0 : 0.0;

          if (messages.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.translate('not_sms'),
                style: TextStyle(color: context.appColors.textPrimary),
              ),
            );
          }

          debugPrint(
              '=================-=== Rendering messageListUi: integrationUsername=$integrationUsername, channelName=$channelName');

          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  _dismissKeyboard();
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topOverlayOffset,
                    left: 8,
                    right: 8,
                    bottom: (_isInstagramCommentChannel &&
                            _instagramResponseType == null)
                        ? 80
                        : 0,
                  ),
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: (notification) {
                      if (notification.dragDetails != null) {
                        _dismissKeyboard();
                      }
                      return false;
                    },
                    child: ScrollablePositionedList.builder(
                      itemScrollController: _scrollControllerMessage,
                      itemPositionsListener: _itemPositionsListener,
                      itemCount:
                          messages.length + (state.isLoadingMore ? 1 : 0),
                      reverse: true,
                      itemBuilder: (context, index) {
                        if (index >= messages.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }

                        final message = messages[index];
                        final messageDate =
                            DateTime.parse(message.createMessateTime).toLocal();

                        bool shouldShowDate = false;
                        if (index == messages.length - 1) {
                          shouldShowDate = true;
                        } else {
                          final previousMessage = messages[index + 1];
                          final previousMessageDate =
                              DateTime.parse(previousMessage.createMessateTime)
                                  .toLocal();
                          shouldShowDate =
                              !isSameDay(messageDate, previousMessageDate);
                        }

                        bool isFirstMessage = index == messages.length - 1;

                        List<Widget> widgets = [];

                        if (shouldShowDate) {
                          final appearance = ChatAppearanceScope.of(context);
                          widgets.add(
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
                              child: GestureDetector(
                                onTap: () => _showDatePicker(context, messages),
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: appearance.chromeBlurSigma(),
                                        sigmaY: appearance.chromeBlurSigma(),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: appearance
                                              .chromeSurfaceColor(context),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: context
                                                .appColors.borderSubtle
                                                .withValues(alpha: 0.28),
                                          ),
                                        ),
                                        child: Text(
                                          formatDate(messageDate),
                                          style: TextStyle(
                                            fontSize: appearance.scaledFont(13),
                                            fontFamily: "Gilroy",
                                            fontWeight: FontWeight.w600,
                                            color:
                                                context.appColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        final effectiveMessage =
                            _messageWithLocalReactions(message);
                        final mediaGroupMessages = _collectMediaGroupMessages(
                          messages,
                          index,
                        );
                        final shouldSkipAsGroupedMedia =
                            _shouldSkipGroupedMediaMessage(
                          messages,
                          index,
                        );

                        if (!shouldSkipAsGroupedMedia) {
                          widgets.add(
                            MessageItemWidget(
                              message: effectiveMessage,
                              mediaGroupMessages: mediaGroupMessages,
                              chatId: widget.chatId,
                              endPointInTab: widget.endPointInTab,
                              isInstagramCommentChannel:
                                  _isInstagramCommentChannel,
                              onInstagramReplyTap: (type) {
                                final resolvedType =
                                    type ?? _instagramResponseType;
                                if (resolvedType == null) {
                                  _showInstagramResponseTypePicker(message);
                                  return;
                                }
                                setState(() {
                                  _instagramResponseType = resolvedType;
                                });
                                _focusNode.requestFocus();
                                context
                                    .read<MessagingCubit>()
                                    .setReplyMessage(message);
                              },
                              isPostExpanded:
                                  _expandedPostIds.contains(message.id),
                              onTogglePost: () {
                                setState(() {
                                  if (_expandedPostIds.contains(message.id)) {
                                    _expandedPostIds.remove(message.id);
                                  } else {
                                    _expandedPostIds.add(message.id);
                                  }
                                });
                              },
                              apiServiceDownload: widget.apiServiceDownload,
                              baseUrl: baseUrl,
                              onReplyTap: _scrollToMessageReply,
                              highlightedMessageId: _highlightedMessageId,
                              onMenuStateChanged: (isOpen) {
                                setState(() {
                                  _isMenuOpen = isOpen;
                                });
                              },
                              isMenuOpen: _isMenuOpen,
                              focusNode: _focusNode,
                              isRead: message.isRead,
                              isFirstMessage: isFirstMessage,
                              referralBody:
                                  state.hasReachedMax ? referralBody : null,
                              onTargetReferralTap:
                                  isFirstMessage && _chatAdvertising != null
                                      ? _openTargetMediaUrl
                                      : null,
                              isGroupChat: _isGroupChat,
                              chatChannelName: channelName,
                              companionName: _cachedCompanionName ??
                                  (widget.chatItem.name.isNotEmpty
                                      ? widget.chatItem.name
                                      : null),
                              canSendMessageInChat: widget.canSendMessage,
                              onReactionToggle: _canUseReactionsInCurrentChat
                                  ? _toggleMessageReaction
                                  : null,
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: widgets,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (widget.endPointInTab == 'lead' &&
                        integrationUsername != null)
                      Material(
                        color: context.appColors.overlay.withValues(alpha: 0.0),
                        child: PinnedLeadMessageWidget(
                          message: '@$integrationUsername',
                          channelType: channelName,
                          onTap: null,
                        ),
                      ),
                    if (pinnedMessages.isNotEmpty)
                      Material(
                        color: context.appColors.overlay.withValues(alpha: 0.0),
                        child: PinnedMessageWidget(
                          message: pinnedMessages.last.text,
                          onUnpin: () {
                            context
                                .read<MessagingCubit>()
                                .unpinMessage(pinnedMessages.last);
                          },
                          onTap: () {
                            _scrollToMessageReply(pinnedMessages.last.id);
                            if (pinnedMessages.isNotEmpty) {
                              final updatedPinnedMessages =
                                  List<Message>.from(pinnedMessages);
                              final firstPinnedMessage =
                                  updatedPinnedMessages.removeAt(0);
                              updatedPinnedMessages.add(firstPinnedMessage);
                              context
                                  .read<MessagingCubit>()
                                  .updatePinnedMessages(updatedPinnedMessages);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (_isMenuOpen)
                Positioned.fill(
                  child: Container(
                    color: context.appColors.overlay.withValues(alpha: 0.3),
                  ),
                ),
              Positioned(
                right: 14,
                bottom: 18,
                child: _buildScrollToBottomButton(),
              ),
            ],
          );
        }
        return Container();
      },
    );
  }

  Widget inputWidget() {
    if (widget.endPointInTab == 'lead' && channelName == null) {
      return const SizedBox.shrink();
    }
    if (_isInstagramCommentChannel && _instagramResponseType == null) {
      return _buildInstagramReplyHint();
    }

    return SafeArea(
      bottom: true,
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isInstagramCommentChannel && _instagramResponseType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: context.appColors.success),
                  const SizedBox(width: 6),
                  Text(
                    _instagramResponseType == 'direct'
                        ? AppLocalizations.of(context)!
                            .translate('answer_direct')
                        : AppLocalizations.of(context)!
                            .translate('answer_comment'),
                    style: TextStyle(
                        fontSize: 12, color: context.appColors.textSecondary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showInstagramResponseTypePicker(null),
                    child:
                        Text(AppLocalizations.of(context)!.translate('edit')),
                  ),
                ],
              ),
            ),
          InputField(
            onSend: _onSendInButton,
            onAttachFile: _onPickFilePressed,
            focusNode: _focusNode,
            isLeadChat: widget.endPointInTab == 'lead',
            onRecordVoice: () {
              debugPrint('Record voice triggered');
            },
            messageController: _messageController,
            sendRequestFunction: (File soundFile, String time) async {
              final myName = await _getMyDisplayName();
              Duration calculateDuration(String time) {
                List<String> parts = time.split(':');
                int minutes = int.parse(parts[0]);
                int seconds = int.parse(parts[1]);
                return Duration(minutes: minutes, seconds: seconds);
              }

              final tempMessage = Message(
                id: -DateTime.now().millisecondsSinceEpoch,
                text: AppLocalizations.of(context)!.translate('voice_message'),
                type: 'voice',
                createMessateTime: DateTime.now().toUtc().toIso8601String(),
                isMyMessage: true,
                senderName: myName,
                filePath: soundFile.path,
                duration: calculateDuration(time),
              );

              context.read<MessagingCubit>().addLocalMessage(tempMessage);
              _scrollToBottom(force: true);

              await _playSound();

              String inputPath = soundFile.path;
              String outputPath = await getOutputPath('converted_file.ogg');

              File? convertedFile =
                  await convertAudioFile(inputPath, outputPath);

              if (convertedFile != null) {
                String uploadUrl = '$baseUrl/chat/sendVoice/${widget.chatId}';
                await uploadFile(convertedFile, uploadUrl);
              } else {
                debugPrint('Conversion failed');
              }
              try {
                await widget.apiService.sendChatAudioFile(
                  widget.chatId,
                  soundFile,
                  responseType: _isInstagramCommentChannel
                      ? _instagramResponseType
                      : null,
                );
              } catch (e) {
                context.read<ListenSenderVoiceCubit>().updateValue(false);
              }
              context.read<ListenSenderVoiceCubit>().updateValue(false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramReplyHint() {
    return SafeArea(
      bottom: true,
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.appColors.surfacePrimary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: context.appColors.shadow.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.appColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.swipe_left_alt_rounded,
                  color: context.appColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!
                      .translate('instagram_comment_reply_hint'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> getOutputPath(String fileName) async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/$fileName';
  }

  Future<void> setUpServices() async {
    debugPrint(
        '=================-=== 🔌 ChatSmsScreen: setUpServices() STARTED');

    if (baseUrl.isEmpty || baseUrl == 'null') {
      debugPrint('=================-=== BaseURL not initialized, fetching...');
      baseUrl = await apiService.getDynamicBaseUrl();

      if (baseUrl.isEmpty || baseUrl == 'null') {
        debugPrint(
            '=================-=== ❌ Failed to get baseURL, aborting socket setup');
        return;
      }
    }

    debugPrint('=================-=== ✅ BaseURL for socket: $baseUrl');

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      debugPrint('❌ Error: Token is null or empty');
      return;
    }
    debugPrint('✅ Token retrieved successfully');

    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    String? verifiedDomain = await ApiService().getVerifiedDomain();
    debugPrint(
        '=================-=== 📡 Domain check: enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');

    if (enteredMainDomain == null || enteredDomain == null) {
      if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
        enteredMainDomain = verifiedDomain.split('-back.').last;
        enteredDomain = verifiedDomain.split('-back.').first;
        debugPrint(
            '=================-=== ✅ Using verifiedDomain: $verifiedDomain → mainDomain=$enteredMainDomain, domain=$enteredDomain');
      } else if (baseUrl.isNotEmpty && baseUrl != 'null') {
        final urlPattern = RegExp(r'https://(.+?)-back\.(.+?)(/|$)');
        final match = urlPattern.firstMatch(baseUrl);
        if (match != null) {
          enteredDomain = match.group(1);
          enteredMainDomain = match.group(2);
          debugPrint(
              '✅ Extracted from baseUrl: domain=$enteredDomain, mainDomain=$enteredMainDomain');

          await prefs.setString('enteredMainDomain', enteredMainDomain!);
          await prefs.setString('enteredDomain', enteredDomain!);
        } else {
          debugPrint(
              '=================-=== ❌ Failed to parse baseUrl, aborting socket setup');
          return;
        }
      } else {
        debugPrint(
            '=================-=== ❌ No domain configuration available, aborting socket setup');
        return;
      }
    }

    debugPrint(
        '=================-=== ✅ Final domains for socket: $enteredDomain-back.$enteredMainDomain');

    final socketUrl = 'wss://soketi.$enteredMainDomain/app/app-key';
    final authUrl =
        'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth';

    debugPrint('=================-=== 🔌 Socket URL: $socketUrl');
    debugPrint('=================-=== 🔌 Auth URL: $authUrl');

    final customOptions = PusherChannelsOptions.custom(
      uriResolver: (metadata) => Uri.parse(socketUrl),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    socketClient = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint(
            '=================-=== ❌ Socket connection error: $exception');
        Future.delayed(Duration(seconds: 5), () async {
          try {
            await socketClient.connect();
            debugPrint('=================-=== 🔄 Socket reconnect attempted');
          } catch (e) {
            debugPrint(
                '=================-=== ❌ Error reconnecting to socket: $e');
          }
        });
        refresh();
      },
      minimumReconnectDelayDuration: const Duration(seconds: 1),
    );

    String chatIdentifier = widget.chatUniqueId ?? widget.chatId.toString();
    if (widget.chatUniqueId == null || widget.chatUniqueId!.isEmpty) {
      try {
        final chatData = await widget.apiService.getChatById(widget.chatId);
        if (chatData.uniqueId != null && chatData.uniqueId!.isNotEmpty) {
          chatIdentifier = chatData.uniqueId!;
        }
      } catch (e) {
        debugPrint(
            '=================-=== ⚠️ Failed to resolve chat unique_id: $e');
      }
    }
    final channelName = 'presence-v2.chat.$chatIdentifier';
    final legacyReactionChannelName = 'presence-chat.$chatIdentifier';

    debugPrint(
        '=================-=== 📱 Chat identifier for socket: $chatIdentifier (uniqueId: ${widget.chatUniqueId}, chatId: ${widget.chatId})');
    debugPrint('=================-=== 📢 Channel name: $channelName');
    debugPrint(
        '=================-=== 📢 Legacy reaction channel: $legacyReactionChannelName');

    final myPresenceChannel = socketClient.presenceChannel(
      channelName,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(authUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': '$enteredDomain-back',
        },
        onAuthFailed: (exception, trace) {
          debugPrint(
              '=================-=== ❌ Auth failed for $channelName: $exception');
        },
      ),
    );

    final legacyReactionPresenceChannel = socketClient.presenceChannel(
      legacyReactionChannelName,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(authUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': '$enteredDomain-back',
        },
        onAuthFailed: (exception, trace) {
          debugPrint(
              '=================-=== ❌ Auth failed for $legacyReactionChannelName: $exception');
        },
      ),
    );

    socketClient.onConnectionEstablished.listen((_) {
      debugPrint(
          '=================-=== ✅ Socket connected successfully for chatIdentifier: $chatIdentifier');
      myPresenceChannel.subscribeIfNotUnsubscribed();
      debugPrint('=================-=== ✅ Subscribed to channel: $channelName');
      legacyReactionPresenceChannel.subscribeIfNotUnsubscribed();
      debugPrint(
          '=================-=== ✅ Subscribed to channel: $legacyReactionChannelName');
    });

    myPresenceChannel.bind('pusher:subscription_succeeded').listen((event) {
      debugPrint(
          '=================-=== ✅✅✅ CHAT_SMS: Successfully subscribed to $channelName');
      debugPrint(
          '=================-=== ✅✅✅ CHAT_SMS: Subscription data: ${event.data}');
    });

    myPresenceChannel.bind('pusher:subscription_error').listen((event) {
      debugPrint(
          '=================-=== ❌❌❌ CHAT_SMS: Subscription error for $channelName: ${event.data}');
    });

    legacyReactionPresenceChannel
        .bind('pusher:subscription_succeeded')
        .listen((event) {
      debugPrint(
          '=================-=== ✅✅✅ CHAT_SMS: Successfully subscribed to $legacyReactionChannelName');
      debugPrint(
          '=================-=== ✅✅✅ CHAT_SMS: Legacy subscription data: ${event.data}');
    });

    legacyReactionPresenceChannel
        .bind('pusher:subscription_error')
        .listen((event) {
      debugPrint(
          '=================-=== ❌❌❌ CHAT_SMS: Subscription error for $legacyReactionChannelName: ${event.data}');
    });

    myPresenceChannel.bind('pusher:member_added').listen((event) {
      debugPrint(
          '=================-=== 👤👤👤 CHAT_SMS: Member added: ${event.data}');
    });

    myPresenceChannel.bind('pusher:member_removed').listen((event) {
      debugPrint(
          '=================-=== 👤👤👤 CHAT_SMS: Member removed: ${event.data}');
    });

    debugPrint(
        '=================-=== 🎯🎯🎯 CHAT_SMS: Registering chat.updated listener for $channelName...');

    myPresenceChannel.bind('chat.updated').listen((event) async {
      debugPrint(
          '=================-=== 🔔 CHAT_SMS (ChatUpdated): ===== RECEIVED EVENT =====');
      _logSocketEventToInspector(
        eventName: 'chat.updated',
        channel: channelName,
        payload: event.data,
      );

      try {
        final rawData = json.decode(event.data);
        debugPrint('=================-=== 🔔 CHAT_SMS: Raw data: $rawData');

        final chatData = rawData['chat'];
        final eventChatId = chatData?['id'];

        debugPrint(
            '=================-=== 🔔 CHAT_SMS: eventChatId=$eventChatId, widget.chatId=${widget.chatId}');

        if (eventChatId != widget.chatId) {
          debugPrint(
              '=================-=== ⚠️ CHAT_SMS: Different chat, ignoring');
          return;
        }
        debugPrint(
            '=================-=== ℹ️ CHAT_SMS: chat.updated received for active chat, skipping history reload');
      } catch (e) {
        debugPrint('=================-=== ❌ CHAT_SMS (ChatUpdated): ERROR: $e');
        _logSocketEventToInspector(
          eventName: 'chat.updated.error',
          channel: channelName,
          payload: event.data,
          error: e.toString(),
        );
      }
    });
    debugPrint(
        '=================-=== ✅✅✅ CHAT_SMS: chat.updated listener registered');

    // ✅ ИСПРАВЛЕНО: Сервер отправляет событие как 'chat.message' (broadcastAs), а не 'MessageSent'
    debugPrint(
        '=================-=== 🎯🎯🎯 CHAT_SMS: Registering chat.message listener for $channelName...');
    chatSubscribtion =
        myPresenceChannel.bind('chat.message').listen((event) async {
      debugPrint('\n\n');
      debugPrint(
          '======================================================================');
      _logSocketEventToInspector(
        eventName: 'chat.message',
        channel: channelName,
        payload: event.data,
      );
      debugPrint('🚀 [SOCKET] chat.message RECEIVED!');
      debugPrint(
          '======================================================================');

      try {
        if (event.data == null || event.data.trim().isEmpty) {
          debugPrint('❌ [SOCKET] chat.message: event.data is empty!');
          return;
        }

        final rawData = json.decode(event.data);
        Map<String, dynamic> messageData;
        if (rawData is Map &&
            rawData['message'] != null &&
            rawData['message'] is Map) {
          messageData = rawData['message'] as Map<String, dynamic>;
        } else if (rawData is Map && rawData['id'] != null) {
          messageData = rawData as Map<String, dynamic>;
        } else {
          return;
        }

        final messageId = messageData['id'] as int?;
        final text = messageData['text'] as String?;
        final type = messageData['type'] as String? ?? 'text';
        final isMyMessageFromServer = messageData['is_my_message'];

        final senderData = messageData['sender'];
        String? senderId;
        String? senderType;
        String? senderName;

        if (senderData is Map) {
          senderId = senderData['id']?.toString();
          senderType = senderData['type']?.toString();
          senderName = senderData['name']?.toString();
        }

        final prefs = await SharedPreferences.getInstance();
        final myUserId = prefs.getString('userID') ?? '';
        final globalUserId = userID.value;
        debugPrint('🏠 [SOCKET] MY DEVICE USER ID (Prefs): "$myUserId"');
        debugPrint('🌍 [SOCKET] GLOBAL USER ID (Variable): "$globalUserId"');

        final isLeadChat = widget.endPointInTab == 'lead';
        debugPrint('📁 [SOCKET] IS LEAD CHAT: $isLeadChat');

        // Parse isMyMessageFromServer safely
        bool? parsedIsMyMessageFromServer;
        if (isMyMessageFromServer != null) {
          if (isMyMessageFromServer is bool) {
            parsedIsMyMessageFromServer = isMyMessageFromServer;
          } else if (isMyMessageFromServer is int) {
            parsedIsMyMessageFromServer = isMyMessageFromServer == 1;
          } else if (isMyMessageFromServer is String) {
            parsedIsMyMessageFromServer =
                isMyMessageFromServer.toLowerCase() == 'true' ||
                    isMyMessageFromServer == '1';
          }
        }

        final isMyMessageResult = await _determineIsMyMessage(
          messageSenderId: senderId,
          messageSenderType: senderType,
          messageSenderName: senderName,
          myUserId: myUserId.isNotEmpty ? myUserId : globalUserId,
          isLeadChat: isLeadChat,
          isMyMessageFromServer: parsedIsMyMessageFromServer,
          debugContext: 'SOCKET chat.message',
        );

        debugPrint('🎯 [SOCKET] FINAL isMyMessage RESULT: $isMyMessageResult');

        ForwardedMessage? forwardedMessage;
        if (messageData['forwarded_message'] != null) {
          try {
            forwardedMessage =
                ForwardedMessage.fromJson(messageData['forwarded_message']);
            debugPrint('↪️ [SOCKET] Forwarded message detected and parsed');
          } catch (e) {
            debugPrint('⚠️ [SOCKET] Error parsing forwarded_message: $e');
          }
        }

        final myName = await _getMyDisplayName();
        final fallbackCompanionName =
            (_cachedCompanionName != null && _cachedCompanionName!.isNotEmpty)
                ? _cachedCompanionName!
                : (_isGroupChat == true
                    ? ''
                    : (widget.chatItem.name.isNotEmpty
                        ? widget.chatItem.name
                        : ''));

        final senderDisplayName = isMyMessageResult
            ? (senderName ?? myName)
            : (senderName ?? fallbackCompanionName);
        final locationData = messageData['location'];
        final latitude = _parseCoordinate(messageData['lattitude'] ??
            messageData['latitude'] ??
            (locationData is Map
                ? locationData['lattitude'] ?? locationData['latitude']
                : null));
        final longitude = _parseCoordinate(messageData['longitude'] ??
            (locationData is Map ? locationData['longitude'] : null));
        final inferredLocation =
            Message.extractLocationCoordinatesFromText(text ?? '');
        final resolvedLatitude = latitude ?? inferredLocation?['latitude'];
        final resolvedLongitude = longitude ?? inferredLocation?['longitude'];
        final resolvedType = Message.resolveIncomingType(
          type,
          text ?? '',
          latitude: resolvedLatitude,
          longitude: resolvedLongitude,
        );

        final msg = Message(
          id: messageId ?? -1,
          text: text ??
              (type == 'voice'
                  ? AppLocalizations.of(context)!.translate('voice_message')
                  : type),
          type: resolvedType,
          createMessateTime:
              messageData['created_at'] ?? DateTime.now().toIso8601String(),
          isMyMessage: isMyMessageResult,
          senderName: senderDisplayName,
          filePath: messageData['file_path']?.toString(),
          latitude: resolvedLatitude,
          longitude: resolvedLongitude,
          duration: messageData['voice_duration'] != null
              ? Duration(
                  seconds:
                      double.tryParse(messageData['voice_duration'].toString())
                              ?.round() ??
                          0)
              : Duration.zero,
          forwardedMessage: forwardedMessage,
        );

        debugPrint(
            '✨ [SOCKET] Message object created: id=${msg.id}, isMyMsg=${msg.isMyMessage}, senderName="${msg.senderName}"');

        if (_isSendingFilesNow && !msg.isMyMessage) {
          debugPrint(
              '⏸️ [SOCKET] chat.message queued during active send: id=${msg.id}');
          _queueSocketMessageDuringSend(msg);
          return;
        }

        if (mounted) {
          debugPrint('📡 [SOCKET] Dispatching message to MessagingCubit...');
          context.read<MessagingCubit>().mergeIncomingMessage(msg);
        }

        if (!msg.isMyMessage) {
          _audioPlayer
              .setAsset('assets/audio/get.mp3')
              .then((_) => _audioPlayer.play())
              .catchError((e) => debugPrint('⚠️ Sound error: $e'));
        }

        if (msg.isMyMessage || _isNearBottom) {
          _scrollToBottom(force: true);
          if (!msg.isMyMessage) {
            _markMessagesAsRead();
          }
        } else {
          _registerIncomingMessageForScrollButton(msg);
        }
        debugPrint('✅ [SOCKET] chat.message processing FINISHED');
        debugPrint(
            '======================================================================');
      } catch (e, stackTrace) {
        debugPrint('❌ [SOCKET] FATAL ERROR in chat.message listener: $e');
        debugPrint('$stackTrace');
        _logSocketEventToInspector(
          eventName: 'chat.message.error',
          channel: channelName,
          payload: event.data,
          error: e.toString(),
        );
        debugPrint(
            '======================================================================');
      }
    });
    debugPrint(
        '=================-=== ✅✅✅ CHAT_SMS: chat.message listener registered');

    const reactionEventAliases = [
      'chat.messageReacted',
      '.chat.messageReacted',
      'chat.message_reacted',
      '.chat.message_reacted',
      'chat.messageReaction',
      'chat.reactionUpdated',
      'chat.reaction.updated',
      'message.reacted',
      'MessageReacted',
      '.MessageReacted',
      'App\\Events\\MessageReacted',
      '.App\\Events\\MessageReacted',
    ];
    _bindReactionAliasesToChannel(
      channel: myPresenceChannel,
      channelName: channelName,
      reactionEventAliases: reactionEventAliases,
      logPrefix: '[CHAT PRESENCE]',
    );
    _bindReactionAliasesToChannel(
      channel: legacyReactionPresenceChannel,
      channelName: legacyReactionChannelName,
      reactionEventAliases: reactionEventAliases,
      logPrefix: '[CHAT LEGACY PRESENCE]',
    );
    debugPrint(
        '=================-=== ✅✅✅ CHAT_SMS: reaction listeners registered (${reactionEventAliases.length})');

    final chatReactionPrivateChannelNames = <String>{
      'private-v2.chat.$chatIdentifier',
      'private-chat.$chatIdentifier',
      'private-v2.chat.${widget.chatId}',
      'private-chat.${widget.chatId}',
    };
    final chatReactionPublicChannelNames = <String>{
      'v2.chat.$chatIdentifier',
      'chat.$chatIdentifier',
      'v2.chat.${widget.chatId}',
      'chat.${widget.chatId}',
    };

    for (final privateName in chatReactionPrivateChannelNames) {
      final privateChannel = socketClient.privateChannel(
        privateName,
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Tenant': '$enteredDomain-back',
          },
          onAuthFailed: (exception, trace) {
            debugPrint(
                '=================-=== ❌ Auth failed for $privateName: $exception');
          },
        ),
      );

      socketClient.onConnectionEstablished.listen((_) {
        debugPrint(
            '=================-=== ✅ Subscribing to private reaction channel: $privateName');
        privateChannel.subscribeIfNotUnsubscribed();
      });

      _bindReactionAliasesToChannel(
        channel: privateChannel,
        channelName: privateName,
        reactionEventAliases: reactionEventAliases,
        logPrefix: '[CHAT PRIVATE]',
      );
    }

    for (final publicName in chatReactionPublicChannelNames) {
      final publicChannel = socketClient.publicChannel(publicName);

      socketClient.onConnectionEstablished.listen((_) {
        debugPrint(
            '=================-=== ✅ Subscribing to public reaction channel: $publicName');
        publicChannel.subscribeIfNotUnsubscribed();
      });

      _bindReactionAliasesToChannel(
        channel: publicChannel,
        channelName: publicName,
        reactionEventAliases: reactionEventAliases,
        logPrefix: '[CHAT PUBLIC]',
      );
    }
    debugPrint(
        '=================-=== 🎯🎯🎯 CHAT_SMS: Setting up USER channel subscription...');
    final userId = prefs.getString('unique_id') ?? '';
    final rawUserId = prefs.getString('userID') ?? '';
    final fallbackUserChannelIds = <String>{};
    if (rawUserId.isNotEmpty) {
      fallbackUserChannelIds.add(rawUserId);
      fallbackUserChannelIds.add('$enteredDomain-back-$rawUserId');
    }
    if (userId.isNotEmpty) {
      fallbackUserChannelIds.remove(userId);
    }
    if (userId.isNotEmpty) {
      final userChannelName = 'presence-user.$userId';
      debugPrint(
          '=================-=== 🎯🎯🎯 CHAT_SMS: User channel: $userChannelName');

      final userPresenceChannel = socketClient.presenceChannel(
        userChannelName,
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPresenceChannel(
          authorizationEndpoint: Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Tenant': '$enteredDomain-back',
          },
          onAuthFailed: (exception, trace) {
            debugPrint(
                '=================-=== ❌ Auth failed for $userChannelName: $exception');
          },
        ),
      );

      socketClient.onConnectionEstablished.listen((_) {
        debugPrint(
            '=================-=== ✅ Subscribing to user channel: $userChannelName');
        userPresenceChannel.subscribeIfNotUnsubscribed();
      });

      // ✅ КРИТИЧНО: chat.updated используется ТОЛЬКО для обновления списка чатов, НЕ для добавления сообщений!
      // ✅ Сообщения добавляются через событие chat.message (MessageSent), которое содержит правильный sender.id
      // ✅ Поэтому в chat.updated мы НЕ добавляем сообщения, а только обновляем lastMessage в списке чатов
      // ✅ ОБНОВЛЕННЫЙ СЛУШАТЕЛЬ chat.updated (внутри userPresenceChannel)
// ✅ ИСПРАВЛЕННЫЙ СЛУШАТЕЛЬ chat.updated (в файле chat_sms_screen.dart)
      userPresenceChannel.bind('chat.updated').listen((event) async {
        debugPrint('🔔🔔🔔 CHAT_SMS (USER CHANNEL): Received chat.updated!');
        _logSocketEventToInspector(
          eventName: 'chat.updated',
          channel: userChannelName,
          payload: event.data,
        );

        try {
          final chatData = json.decode(event.data);
          final chatObj = chatData['chat'];
          final eventChatId = chatObj?['id'];

          if (eventChatId != widget.chatId) {
            return;
          }

          final prefs = await SharedPreferences.getInstance();
          final myUserId = prefs.getString('userID') ?? '';

          String? extractedName;

          String? resolveNameFromMap(Map<dynamic, dynamic> data) {
            final firstName = data['name']?.toString() ?? '';
            final lastName = data['lastname']?.toString() ?? '';
            final fullName = '$firstName $lastName'.trim();
            return fullName.isNotEmpty ? fullName : null;
          }

          final chatUsers = chatObj?['chatUsers'];
          if (chatUsers is List) {
            for (final user in chatUsers) {
              if (user is Map) {
                final participant = user['participant'];
                if (participant is Map) {
                  final participantId = participant['id']?.toString();
                  if (participantId != null &&
                      participantId.isNotEmpty &&
                      participantId != myUserId) {
                    extractedName = resolveNameFromMap(participant);
                    if (extractedName != null) break;
                  }
                }
              }
            }
          }

          if (extractedName == null) {
            final user = chatObj?['user'];
            if (user is Map) {
              final userId = user['id']?.toString();
              if (userId != null && userId.isNotEmpty && userId != myUserId) {
                extractedName = resolveNameFromMap(user);
              }
            }
          }

          if (extractedName == null) {
            final chatName = chatObj?['name'];
            if (chatName is String && chatName.trim().isNotEmpty) {
              extractedName = chatName.trim();
            }
          }

          if (mounted &&
              extractedName != null &&
              extractedName.isNotEmpty &&
              (_cachedCompanionName == null || _cachedCompanionName!.isEmpty)) {
            setState(() {
              _cachedCompanionName = extractedName;
            });
            debugPrint(
                '✅ Обновлено имя собеседника из chat.updated: $extractedName');
          }

          // Для открытого чата сообщения добавляем только через chat.message.
          // chat.updated здесь нужен для имени/метаданных чата и списка чатов.
        } catch (e) {
          debugPrint('❌ Ошибка парсинга chat.updated: $e');
          _logSocketEventToInspector(
            eventName: 'chat.updated.error',
            channel: userChannelName,
            payload: event.data,
            error: e.toString(),
          );
        }
      });
      _bindReactionAliasesToChannel(
        channel: userPresenceChannel,
        channelName: userChannelName,
        reactionEventAliases: reactionEventAliases,
        logPrefix: '[USER PRESENCE]',
      );
      debugPrint(
          '=================-=== ✅✅✅ CHAT_SMS: User channel listener registered');

      final userReactionPrivateChannelNames = <String>{
        'private-user.$userId',
        if (rawUserId.isNotEmpty) 'private-user.$rawUserId',
        if (rawUserId.isNotEmpty) 'private-user.$enteredDomain-back-$rawUserId',
      };
      final userReactionPublicChannelNames = <String>{
        'user.$userId',
        if (rawUserId.isNotEmpty) 'user.$rawUserId',
        if (rawUserId.isNotEmpty) 'user.$enteredDomain-back-$rawUserId',
      };

      for (final privateName in userReactionPrivateChannelNames) {
        final userPrivateChannel = socketClient.privateChannel(
          privateName,
          authorizationDelegate:
              EndpointAuthorizableChannelTokenAuthorizationDelegate
                  .forPrivateChannel(
            authorizationEndpoint: Uri.parse(authUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'X-Tenant': '$enteredDomain-back',
            },
            onAuthFailed: (exception, trace) {
              debugPrint(
                  '=================-=== ❌ Auth failed for $privateName: $exception');
            },
          ),
        );

        socketClient.onConnectionEstablished.listen((_) {
          debugPrint(
              '=================-=== ✅ Subscribing to user private channel: $privateName');
          userPrivateChannel.subscribeIfNotUnsubscribed();
        });

        _bindReactionAliasesToChannel(
          channel: userPrivateChannel,
          channelName: privateName,
          reactionEventAliases: reactionEventAliases,
          logPrefix: '[USER PRIVATE]',
        );
      }

      for (final publicName in userReactionPublicChannelNames) {
        final userPublicChannel = socketClient.publicChannel(publicName);

        socketClient.onConnectionEstablished.listen((_) {
          debugPrint(
              '=================-=== ✅ Subscribing to user public channel: $publicName');
          userPublicChannel.subscribeIfNotUnsubscribed();
        });

        _bindReactionAliasesToChannel(
          channel: userPublicChannel,
          channelName: publicName,
          reactionEventAliases: reactionEventAliases,
          logPrefix: '[USER PUBLIC]',
        );
      }
    }

    // Дополнительно подписываемся на fallback user channels
    // (например presence-user.fingroupcrm-back-1), чтобы не терять reaction-события.
    for (final fallbackId in fallbackUserChannelIds) {
      final fallbackChannelName = 'presence-user.$fallbackId';
      debugPrint(
          '=================-=== 🎯 CHAT_SMS: Fallback user channel: $fallbackChannelName');

      final fallbackPresenceChannel = socketClient.presenceChannel(
        fallbackChannelName,
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPresenceChannel(
          authorizationEndpoint: Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Tenant': '$enteredDomain-back',
          },
          onAuthFailed: (exception, trace) {
            debugPrint(
                '=================-=== ❌ Auth failed for $fallbackChannelName: $exception');
          },
        ),
      );

      socketClient.onConnectionEstablished.listen((_) {
        debugPrint(
            '=================-=== ✅ Subscribing to fallback user channel: $fallbackChannelName');
        fallbackPresenceChannel.subscribeIfNotUnsubscribed();
      });

      _bindReactionAliasesToChannel(
        channel: fallbackPresenceChannel,
        channelName: fallbackChannelName,
        reactionEventAliases: reactionEventAliases,
        logPrefix: '[FALLBACK USER PRESENCE]',
      );

      final fallbackPrivateName = 'private-user.$fallbackId';
      final fallbackPrivateChannel = socketClient.privateChannel(
        fallbackPrivateName,
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Tenant': '$enteredDomain-back',
          },
          onAuthFailed: (exception, trace) {
            debugPrint(
                '=================-=== ❌ Auth failed for $fallbackPrivateName: $exception');
          },
        ),
      );
      socketClient.onConnectionEstablished.listen((_) {
        debugPrint(
            '=================-=== ✅ Subscribing to fallback private user channel: $fallbackPrivateName');
        fallbackPrivateChannel.subscribeIfNotUnsubscribed();
      });
      _bindReactionAliasesToChannel(
        channel: fallbackPrivateChannel,
        channelName: fallbackPrivateName,
        reactionEventAliases: reactionEventAliases,
        logPrefix: '[FALLBACK USER PRIVATE]',
      );

      final fallbackPublicName = 'user.$fallbackId';
      final fallbackPublicChannel =
          socketClient.publicChannel(fallbackPublicName);
      socketClient.onConnectionEstablished.listen((_) {
        debugPrint(
            '=================-=== ✅ Subscribing to fallback public user channel: $fallbackPublicName');
        fallbackPublicChannel.subscribeIfNotUnsubscribed();
      });
      _bindReactionAliasesToChannel(
        channel: fallbackPublicChannel,
        channelName: fallbackPublicName,
        reactionEventAliases: reactionEventAliases,
        logPrefix: '[FALLBACK USER PUBLIC]',
      );
    }

    try {
      debugPrint('=================-=== 🚀 Initiating socket connection...');
      await socketClient.connect();
      debugPrint(
          '=================-=== ✅ Socket connection initiated successfully');
    } catch (e) {
      debugPrint('=================-=== ❌ Error connecting to socket: $e');
    }

    debugPrint(
        '=================-=== 🔌 ChatSmsScreen: setUpServices() COMPLETED');
  }

  Future<void> _onSendInButton(
      String messageText, String? replyMessageId) async {
    final normalizedMessageText = messageText.trim();
    if (normalizedMessageText.isNotEmpty) {
      try {
        final myName = await _getMyDisplayName();
        final localMessage = Message(
          id: -DateTime.now().millisecondsSinceEpoch,
          text: normalizedMessageText,
          type: 'text',
          createMessateTime: DateTime.now().toUtc().toIso8601String(),
          isMyMessage: true,
          senderName: myName,
        );

        context.read<MessagingCubit>().addLocalMessage(localMessage);
        _scrollToBottom(force: true);

        await _playSound();

        _messageController.clear();

        await widget.apiService.sendMessage(
          widget.chatId,
          normalizedMessageText,
          replyMessageId: replyMessageId,
          responseType:
              _isInstagramCommentChannel ? _instagramResponseType : null,
        );

        context.read<ListenSenderTextCubit>().updateValue(false);
      } catch (e) {
        debugPrint('Ошибка отправки сообщения через API!');
      }
    } else {
      debugPrint('Сообщение пустое, отправка не выполнена');
    }
  }

  void _onPickFilePressed() async {
    if (_isAttachmentPickerOpen) return;

    _isAttachmentPickerOpen = true;
    try {
      final result = await showChatMediaPreviewSheet(context: context);
      if (!mounted || result == null) return;

      switch (result.action) {
        case ChatMediaPickerAction.send:
          if (result.items.isNotEmpty) {
            await _sendPickedFiles(result.items, quality: result.quality);
          }
          break;
        case ChatMediaPickerAction.openFilePicker:
          await _pickFilesFromDevice();
          break;
        case ChatMediaPickerAction.openLocationPicker:
          await _openLocationPicker();
          break;
        case ChatMediaPickerAction.openCameraPhoto:
          await _pickPhotoFromCamera(result.quality);
          break;
        case ChatMediaPickerAction.openCameraVideo:
          await _pickVideoFromCamera(result.quality);
          break;
      }
    } finally {
      _isAttachmentPickerOpen = false;
    }
  }

  Future<void> _pickPhotoFromCamera(ChatMediaQuality quality) async {
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (!mounted || image == null) return;

    await _sendPickedFiles(
      [
        PickedChatMedia(
          path: image.path,
          name: image.name,
          isImage: true,
          isVideo: false,
        ),
      ],
      quality: quality,
    );
  }

  Future<void> _pickVideoFromCamera(ChatMediaQuality quality) async {
    final XFile? video =
        await ImagePicker().pickVideo(source: ImageSource.camera);
    if (!mounted || video == null) return;

    await _sendPickedFiles(
      [
        PickedChatMedia(
          path: video.path,
          name: video.name,
          isImage: false,
          isVideo: true,
        ),
      ],
      quality: quality,
    );
  }

  Future<void> _pickFilesFromDevice() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (!mounted || result == null) return;

    final files = result.files
        .where((file) => file.path != null)
        .take(50)
        .map(
          (file) => PickedChatMedia(
            path: file.path!,
            name: file.name,
            isImage: _isImagePath(file.path!),
            isVideo: _isVideoPath(file.path!),
          ),
        )
        .toList();

    if (files.isNotEmpty) {
      await _sendPickedFiles(
        files,
        quality: ChatMediaQuality.hd,
      );
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );
    if (result == null) return;

    await _sendLocationMessage(result);
  }

  Future<void> _sendLocationMessage(PickedLocation location) async {
    try {
      final myName = await _getMyDisplayName();
      final localMessage = Message(
        id: -DateTime.now().millisecondsSinceEpoch,
        text: AppLocalizations.of(context)!.translate('geolocation'),
        type: 'location',
        createMessateTime: DateTime.now().toUtc().toIso8601String(),
        isMyMessage: true,
        senderName: myName,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      context.read<MessagingCubit>().addLocalMessage(localMessage);
      _scrollToBottom(force: true);
      await _playSound();

      await widget.apiService.sendLocation(
        widget.chatId,
        latitude: location.latitude,
        longitude: location.longitude,
        responseType:
            _isInstagramCommentChannel ? _instagramResponseType : null,
      );
    } catch (e) {
      debugPrint('Ошибка отправки местоположения: $e');
    }
  }

  bool _isImagePath(String path) {
    final value = path.toLowerCase();
    return value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.png') ||
        value.endsWith('.gif') ||
        value.endsWith('.webp') ||
        value.endsWith('.bmp') ||
        value.endsWith('.heic');
  }

  bool _isVideoPath(String path) {
    final value = path.toLowerCase();
    return value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.endsWith('.m4v') ||
        value.endsWith('.avi') ||
        value.endsWith('.mkv') ||
        value.endsWith('.webm') ||
        value.endsWith('.3gp') ||
        value.endsWith('.mpeg') ||
        value.endsWith('.mpg') ||
        value.endsWith('.mts') ||
        value.endsWith('.m2ts') ||
        value.endsWith('.ts') ||
        value.endsWith('.wmv') ||
        value.endsWith('.flv') ||
        value.endsWith('.hevc');
  }

  Future<void> _sendPickedFiles(
    List<PickedChatMedia> items, {
    required ChatMediaQuality quality,
  }) async {
    final messagingCubit = _messagingCubit ?? context.read<MessagingCubit>();
    final senderFileCubit = context.read<ListenSenderFileCubit>();
    final myName = await _getMyDisplayName();
    try {
      await _chatFileSendService.sendPickedFiles(
        items,
        quality: quality,
        context: ChatFileSendContext(
          chatId: widget.chatId,
          apiService: widget.apiService,
          isInstagramCommentChannel: _isInstagramCommentChannel,
          instagramResponseType: _instagramResponseType,
          myDisplayName: myName,
          onAddLocalMessage: (message) {
            if (!mounted || messagingCubit.isClosed) return;
            messagingCubit.addLocalMessage(message);
            _scrollToBottom(force: true);
          },
          onUpdateLocalMessageProgress: (localMessageId, updatedItems) {
            if (!mounted || messagingCubit.isClosed) return;
            final currentState = messagingCubit.state;
            if (currentState is! MessagesCollectionState) return;
            final localMessage = currentState.messages
                .where((message) => message.id == localMessageId)
                .cast<Message?>()
                .firstWhere((message) => message != null, orElse: () => null);
            if (localMessage == null) return;
            messagingCubit.mergeMessageUpdate(
              localMessage.copyWith(mediaItems: updatedItems),
            );
          },
          onFinalizeLocalMessages: (localMessageIds) {
            if (!mounted || messagingCubit.isClosed) return;
            final currentState = messagingCubit.state;
            if (currentState is! MessagesCollectionState) return;
            for (final localMessageId in localMessageIds) {
              final localMessage = currentState.messages
                  .where((message) => message.id == localMessageId)
                  .cast<Message?>()
                  .firstWhere((message) => message != null, orElse: () => null);
              if (localMessage == null) continue;
              messagingCubit.mergeMessageUpdate(
                localMessage.copyWith(
                  isUploading: false,
                  mediaItems: localMessage.mediaItems
                      .map((item) => item.copyWith(uploadProgress: 1))
                      .toList(),
                ),
              );
            }
          },
          onPersistState: _persistCurrentChatMessages,
          onSentSound: _playSound,
        ),
      );
      senderFileCubit.updateValue(false);
      _flushQueuedSocketMessages();
      unawaited(_persistCurrentChatMessages());
    } catch (e) {
      senderFileCubit.updateValue(false);
      if (_canMutateMessagingCubit(messagingCubit)) {
        _flushQueuedSocketMessages();
      }
      debugPrint('Ошибка пакетной отправки файлов: $e');
    }
  }

  List<Message> _collectMediaGroupMessages(
      List<Message> messages, int startIndex) {
    final current = messages[startIndex];
    if (!_isRenderableMediaMessage(current)) return const [];

    if (current.type == 'media_group') {
      return [current];
    }

    final group = <Message>[current];
    for (int index = startIndex + 1; index < messages.length; index++) {
      final next = messages[index];
      if (!_canBeGroupedTogether(messages[index - 1], next) ||
          group.length >= 10) {
        break;
      }
      group.add(next);
    }
    return group.length > 1 ? group : const [];
  }

  bool _shouldSkipGroupedMediaMessage(List<Message> messages, int index) {
    final current = messages[index];
    if (!_isRenderableMediaMessage(current) || current.type == 'media_group') {
      return false;
    }

    int runStart = index;
    while (runStart > 0 &&
        _canBeGroupedTogether(messages[runStart - 1], messages[runStart])) {
      runStart--;
    }

    final offsetInRun = index - runStart;
    return offsetInRun % 10 != 0;
  }

  bool _isRenderableMediaMessage(Message message) {
    return message.type == 'image' ||
        message.type == 'video' ||
        message.type == 'media_group';
  }

  bool _canBeGroupedTogether(Message first, Message second) {
    if (!_isRenderableMediaMessage(first) ||
        !_isRenderableMediaMessage(second)) {
      return false;
    }

    if (first.type == 'media_group' || second.type == 'media_group') {
      return false;
    }

    if (first.isMyMessage != second.isMyMessage) return false;
    if (first.senderName != second.senderName) return false;

    final firstTime = DateTime.tryParse(first.createMessateTime);
    final secondTime = DateTime.tryParse(second.createMessateTime);
    if (firstTime == null || secondTime == null) return false;

    final difference = firstTime.difference(secondTime).inSeconds.abs();
    return difference <= 90;
  }

  @override
  void dispose() {
    // ✅ Защита от двойного вызова dispose
    if (_isDisposing) {
      debugPrint(
          '⚠️ ChatSmsScreen.dispose already in progress for chat ${widget.chatId}');
      return;
    }
    _isDisposing = true;

    debugPrint('🗑️ ChatSmsScreen.dispose START for chat ${widget.chatId}');

    // ✅ ШАГ 1: Убираем флаг активности (ВАЖНО: передаём chatId для проверки)
    // Это нужно сделать ДО пометки сообщений как прочитанных,
    // чтобы обновления через сокет не инкрементировали счетчик
    // ✅ ИСПРАВЛЕНО: Используем uniqueId для привязки чата
    _chatTracker.clearActiveChat(widget.chatUniqueId);

    // ✅ ШАГ 2: Закрываем сокет-соединение для текущего чата
    apiService.closeChatSocket(widget.chatId);

    // ✅ ШАГ 3: Закрываем WebSocket соединение, если оно открыто
    if (_webSocket != null && _webSocket!.readyState != WebSocket.closed) {
      _webSocket?.close();
    }

    // ✅ ШАГ 4: Отменяем подписку на события чата через сокет
    if (chatSubscribtion != null) {
      chatSubscribtion?.cancel();
      chatSubscribtion = null;
    }

    // ✅ ШАГ 5: Освобождаем ресурсы контроллеров и фокус-ноды
    _searchDebounce?.cancel();
    _itemPositionsListener.itemPositions
        .removeListener(_handleVisiblePositionsChanged);

    final currentState = _messagingCubit?.state;
    if (currentState is MessagesCollectionState) {
      unawaited(
          _cacheService.cacheMessages(widget.chatId, currentState.messages));
    }

    _messageController.dispose();
    _searchController.dispose();
    socketClient.dispose();
    _focusNode.dispose();
    _searchFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);

    // ✅ ШАГ 6: Обнуляем счетчик непрочитанных сообщений локально
    // Это скрывает счетчик до момента прихода нового сообщения от сервера
    _chatsBloc?.add(ResetUnreadCount(widget.chatId));

    // ✅ ШАГ 7: Помечаем сообщения как прочитанные на сервере, затем обновляем
    // серверные счетчики. Не делаем refresh раньше readMessages, иначе сервер
    // вернет старый unreadCount и перезапишет локальный ноль.
    unawaited(_markMessagesAsReadOnExit());

    debugPrint(
        '=================-=== ✅ ChatSmsScreen.dispose COMPLETED for chat ${widget.chatId}');

    super.dispose();
  }

  // ✅ НОВЫЙ МЕТОД: Помечает сообщения как прочитанные при выходе из чата и обновляет список чатов
  Future<void> _markMessagesAsReadOnExit() async {
    try {
      // ✅ Используем сохраненную ссылку на MessagingCubit, так как context может быть недоступен в dispose
      if (_messagingCubit == null) {
        debugPrint(
            'ChatSmsScreen: MessagingCubit is null, skipping mark as read');
        return;
      }

      final state = _messagingCubit!.state;
      List<Message> messages = [];

      if (state is MessagesCollectionState) {
        messages = state.messages;
      }

      // ✅ Если есть сообщения, помечаем все как прочитанные на сервере
      if (messages.isNotEmpty) {
        final latestMessageId = messages.first.id;
        debugPrint(
            'ChatSmsScreen: Marking messages as read on exit, chatId: ${widget.chatId}, latestMessageId: $latestMessageId');

        // ✅ Отправляем запрос на сервер, что этот чат полностью прочитан
        await widget.apiService.readMessages(widget.chatId, latestMessageId);
        debugPrint(
            'ChatSmsScreen: Messages marked as read on server successfully');
        ChatUnreadCounterService.instance.refreshCounts(silent: true);
        if (_chatsBloc != null && !_chatsBloc!.isClosed) {
          _chatsBloc!.add(ClearChats());
          _chatsBloc!.add(FetchChats(endPoint: widget.endPointInTab));
        }
      } else {
        debugPrint('ChatSmsScreen: No messages to mark as read on exit');
        ChatUnreadCounterService.instance.refreshCounts(silent: true);
      }

      // ✅ ИСПРАВЛЕНО: НЕ обновляем список чатов сразу после выхода
      // Список чатов будет обновляться через сокет естественным образом
      // ActiveChatTracker уже убран в dispose, поэтому обновления через сокет будут правильно обрабатываться
      debugPrint(
          '=================-=== ChatSmsScreen: Messages marked as read, chats list will update via socket naturally');
    } catch (e) {
      debugPrint(
          '=================-=== ChatSmsScreen: Error marking messages as read on exit: $e');
      // Не критично, продолжаем работу
    }
  }
}

class MessageItemWidget extends StatelessWidget {
  final Message message;
  final List<Message> mediaGroupMessages;
  final int chatId;
  final String endPointInTab;
  final ApiServiceDownload apiServiceDownload;
  final String baseUrl;
  final bool isInstagramCommentChannel;
  final void Function(String?)? onInstagramReplyTap;
  final bool isPostExpanded;
  final VoidCallback? onTogglePost;
  final void Function(int)? onReplyTap;
  final int? highlightedMessageId;
  final void Function(bool)? onMenuStateChanged;
  final bool isMenuOpen;
  final FocusNode focusNode;
  final bool isRead;
  final bool isFirstMessage;
  final String? referralBody;
  final bool? isGroupChat;
  final String? chatChannelName;
  final String? companionName;
  final bool canSendMessageInChat;
  final void Function(Message message, String emoji)? onReactionToggle;
  final VoidCallback? onTargetReferralTap;

  const MessageItemWidget({
    super.key,
    required this.message,
    this.mediaGroupMessages = const [],
    required this.endPointInTab,
    required this.chatId,
    required this.apiServiceDownload,
    required this.baseUrl,
    this.isInstagramCommentChannel = false,
    this.onInstagramReplyTap,
    this.isPostExpanded = false,
    this.onTogglePost,
    this.onReplyTap,
    this.highlightedMessageId,
    this.onMenuStateChanged,
    this.isMenuOpen = false,
    required this.focusNode,
    required this.isRead,
    required this.isFirstMessage,
    this.referralBody,
    this.isGroupChat,
    this.chatChannelName,
    this.companionName,
    required this.canSendMessageInChat,
    this.onReactionToggle,
    this.onTargetReferralTap,
  });

  String get _normalizedChannelName {
    return (chatChannelName ?? '')
        .toLowerCase()
        .replaceAll('channel-', '')
        .trim();
  }

  bool get _isLead24hRestricted {
    return endPointInTab == 'lead' && !canSendMessageInChat;
  }

  bool get _isInstagramDirectSource {
    return _normalizedChannelName == 'instagram';
  }

  bool get _shouldShowMessageReactions {
    return !isInstagramCommentChannel;
  }

  bool get _isTelegramSourceForEdit {
    return _normalizedChannelName == 'telegram_bot' ||
        _normalizedChannelName == 'telegram_account';
  }

  bool get _canReplyToMessage {
    if (_isLead24hRestricted) return false;
    if (_isInstagramDirectSource) return false;
    return true;
  }

  bool get _canEditOwnTextMessages {
    if (_isLead24hRestricted) return false;
    return _isTelegramSourceForEdit;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(message.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (isInstagramCommentChannel) {
          focusNode.requestFocus();
          onInstagramReplyTap?.call(null);
          return false;
        }
        if (_canReplyToMessage) {
          focusNode.requestFocus();
          context.read<MessagingCubit>().setReplyMessage(message);
          return false;
        }
        return false;
      },
      child: PremiumHapticWrapper(
        onLongPress: () {
          if (message.type != 'location') {
            _showMessageContextMenu(context, message, focusNode);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          child: _buildMessageContent(context),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    String? replyMessageText;
    String? replyPreviewAuthorName;
    bool isTargetReferralReplyPreview = false;
    if (isFirstMessage && referralBody != null && referralBody!.isNotEmpty) {
      replyMessageText = referralBody;
      isTargetReferralReplyPreview = true;
      final fallbackCompanionName =
          (companionName != null && companionName!.trim().isNotEmpty)
              ? companionName!.trim()
              : message.senderName;
      replyPreviewAuthorName = fallbackCompanionName;
    } else if (message.forwardedMessage != null) {
      replyMessageText = message.forwardedMessage!.type == 'voice'
          ? AppLocalizations.of(context)!.translate('voice_message')
          : message.forwardedMessage!.text;
      final forwardedAuthor = message.forwardedMessage!.senderName?.trim();
      if (forwardedAuthor != null && forwardedAuthor.isNotEmpty) {
        replyPreviewAuthorName = forwardedAuthor;
      }
    }

    final bool isLeadChat = endPointInTab == 'lead';

    Widget content;
    switch (message.type) {
      case 'text':
        content = MessageBubble(
          message: message.text,
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          senderName: message.senderName.toString(),
          replyMessage: replyMessageText,
          replyAuthorName: replyPreviewAuthorName,
          isTargetReferralReplyPreview: isTargetReferralReplyPreview,
          onTargetReferralTap:
              isTargetReferralReplyPreview ? onTargetReferralTap : null,
          replyMessageId: message.forwardedMessage?.id,
          onReplyTap: (id) => onReplyTap?.call(id),
          isHighlighted: highlightedMessageId == message.id,
          isChanged: message.isChanged,
          isRead: message.isRead,
          isNote: message.isNote,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
          reactions: _shouldShowMessageReactions ? message.reactions : const [],
          onReactionTap: _shouldShowMessageReactions
              ? (emoji) => onReactionToggle?.call(message, emoji)
              : null,
        );
        break;
      case 'image':
        if (mediaGroupMessages.isNotEmpty) {
          content = MediaGroupMessageBubble(
            messages: mediaGroupMessages,
            time: time(message.createMessateTime),
            isSender: message.isMyMessage,
            senderName: message.senderName,
            isHighlighted: highlightedMessageId == message.id,
            isRead: message.isRead,
            isLeadChat: isLeadChat,
            isGroupChat: isGroupChat,
            isMenuOpen: isMenuOpen,
            reactions:
                _shouldShowMessageReactions ? message.reactions : const [],
            onReactionTap: _shouldShowMessageReactions
                ? (emoji) => onReactionToggle?.call(message, emoji)
                : null,
          );
          break;
        }
        content = ImageMessageBubble(
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          filePath: message.filePath ?? 'Unknown',
          fileName: message.text,
          message: message,
          senderName: message.senderName,
          replyMessage: replyMessageText,
          isHighlighted: highlightedMessageId == message.id,
          isRead: message.isRead,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
          isMenuOpen: isMenuOpen,
          reactions: _shouldShowMessageReactions ? message.reactions : const [],
          onReactionTap: _shouldShowMessageReactions
              ? (emoji) => onReactionToggle?.call(message, emoji)
              : null,
        );
        break;
      case 'media_group':
        content = MediaGroupMessageBubble(
          messages:
              mediaGroupMessages.isNotEmpty ? mediaGroupMessages : [message],
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          senderName: message.senderName,
          isHighlighted: highlightedMessageId == message.id,
          isRead: message.isRead,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
          isMenuOpen: isMenuOpen,
          reactions: _shouldShowMessageReactions ? message.reactions : const [],
          onReactionTap: _shouldShowMessageReactions
              ? (emoji) => onReactionToggle?.call(message, emoji)
              : null,
        );
        break;
      case 'video':
        content = MediaGroupMessageBubble(
          messages:
              mediaGroupMessages.isNotEmpty ? mediaGroupMessages : [message],
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          senderName: message.senderName,
          isHighlighted: highlightedMessageId == message.id,
          isRead: message.isRead,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
          isMenuOpen: isMenuOpen,
          reactions: _shouldShowMessageReactions ? message.reactions : const [],
          onReactionTap: _shouldShowMessageReactions
              ? (emoji) => onReactionToggle?.call(message, emoji)
              : null,
        );
        break;
      case 'file':
      case 'document':
        content = FileMessageBubble(
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          filePath: message.filePath ?? 'Unknown',
          fileName: message.text,
          isHighlighted: highlightedMessageId == message.id,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
          onTap: (path) async {
            if (message.filePath != null && message.filePath!.isNotEmpty) {
              try {
                await apiServiceDownload.downloadAndOpenFile(message.filePath!);
              } catch (e) {
                debugPrint('Error downloading file: $e');
              }
            }
          },
          senderName: message.senderName,
          isRead: message.isRead,
          reactions: _shouldShowMessageReactions ? message.reactions : const [],
          onReactionTap: _shouldShowMessageReactions
              ? (emoji) => onReactionToggle?.call(message, emoji)
              : null,
        );
        break;
      case 'voice':
        content = VoiceMessageWidget(
          message: message,
          baseUrl: baseUrl,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
          reactions: _shouldShowMessageReactions ? message.reactions : const [],
          onReactionTap: _shouldShowMessageReactions
              ? (emoji) => onReactionToggle?.call(message, emoji)
              : null,
        );
        break;
      case 'location':
        if (message.latitude == null || message.longitude == null) {
          content = MessageBubble(
            message: message.text.isNotEmpty
                ? message.text
                : AppLocalizations.of(context)!.translate('geolocation'),
            time: time(message.createMessateTime),
            isSender: message.isMyMessage,
            senderName: message.senderName.toString(),
            isHighlighted: highlightedMessageId == message.id,
            isChanged: message.isChanged,
            isRead: message.isRead,
            isNote: message.isNote,
            isLeadChat: isLeadChat,
            isGroupChat: isGroupChat,
          );
        } else {
          content = LocationMessageBubble(
            latitude: message.latitude!,
            longitude: message.longitude!,
            time: time(message.createMessateTime),
            isSender: message.isMyMessage,
            senderName: message.senderName,
            isRead: message.isRead,
            isLeadChat: isLeadChat,
            isGroupChat: isGroupChat,
            isHighlighted: highlightedMessageId == message.id,
            onTap: () => _openLocationInMap(message),
            onLongPress: () =>
                _showMessageContextMenu(context, message, focusNode),
          );
        }
        break;
      default:
        content = const SizedBox();
    }

    if (message.post == null) {
      return content;
    }

    return Column(
      crossAxisAlignment: message.isMyMessage
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _buildPostPreview(context, message.post!),
        content,
      ],
    );
  }

  Widget _buildPostPreview(BuildContext context, Post post) {
    final localizations = AppLocalizations.of(context)!;
    final appearance = ChatAppearanceScope.of(context);
    final caption = post.caption.trim();
    final text = caption.isNotEmpty
        ? caption
        : localizations.translate('instagram_post');

    return GestureDetector(
      onTap: onTogglePost,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 2),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isMyMessage
              ? appearance.senderBubbleColor(context).withValues(alpha: 0.88)
              : appearance.receiverBubbleColor(context).withValues(alpha: 0.9),
          borderRadius: appearance.bubbleRadius(message.isMyMessage),
          border: Border.all(
            color: appearance.borderColor(context, message.isMyMessage),
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/leads/instagram.png',
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  localizations.translate('reply_to_post'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appearance.secondaryForeground(
                      context,
                      message.isMyMessage,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: isPostExpanded ? null : 5,
              overflow:
                  isPostExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: appearance.scaledFont(13.5),
                color: message.isMyMessage
                    ? appearance.outgoingForeground(context)
                    : appearance.incomingForeground(context),
                fontWeight: appearance.messageFontWeight,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String time(String createMessateTime) {
    try {
      final dateTime = DateTime.parse(createMessateTime).toLocal();
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  void _showMessageContextMenu(
      BuildContext context, Message message, FocusNode focusNode) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox messageBox = context.findRenderObject() as RenderBox;
    final Offset position =
        messageBox.localToGlobal(Offset.zero, ancestor: overlay);

    onMenuStateChanged?.call(true);

    final List<ContextMenuItem> menuItems = [];

    // 1. Ответить / Instagram comment reply actions
    if (isInstagramCommentChannel) {
      menuItems.add(
        ContextMenuItem(
          icon: 'assets/icons/chats/menu_icons/reply.svg',
          text: AppLocalizations.of(context)!.translate('reply_as_comment'),
          onTap: () {
            onInstagramReplyTap?.call('comment');
          },
        ),
      );
      menuItems.add(
        ContextMenuItem(
          icon: 'assets/icons/chats/menu_icons/reply.svg',
          text: AppLocalizations.of(context)!.translate('reply_in_direct'),
          onTap: () {
            onInstagramReplyTap?.call('direct');
          },
        ),
      );
    } else if (_canReplyToMessage) {
      menuItems.add(
        ContextMenuItem(
          icon: 'assets/icons/chats/menu_icons/reply.svg',
          text: AppLocalizations.of(context)!.translate('reply'),
          onTap: () {
            focusNode.requestFocus();
            context.read<MessagingCubit>().setReplyMessage(message);
          },
        ),
      );
    }

    // 2. Копировать
    menuItems.add(
      ContextMenuItem(
        icon: 'assets/icons/chats/menu_icons/copy.svg',
        text: AppLocalizations.of(context)!.translate('copy'),
        onTap: () {
          _copyMessageToClipboardByType(context, message);
        },
      ),
    );

    // 3. Закрепить/Открепить
    menuItems.add(
      ContextMenuItem(
        icon: 'assets/icons/chats/menu_icons/pin.svg',
        text: message.isPinned
            ? AppLocalizations.of(context)!.translate('un_pin')
            : AppLocalizations.of(context)!.translate('pin'),
        onTap: () {
          context.read<MessagingCubit>().pinMessage(message);
        },
      ),
    );

    // 4. Редактировать (только свои тексты)
    if (message.isMyMessage &&
        message.type == 'text' &&
        _canEditOwnTextMessages) {
      menuItems.add(
        ContextMenuItem(
          icon: 'assets/icons/chats/menu_icons/edit.svg',
          text: AppLocalizations.of(context)!.translate('edit'),
          onTap: () {
            focusNode.requestFocus();
            context.read<MessagingCubit>().startEditingMessage(message);
          },
        ),
      );
    }

    // 5. Удалить (только свои)
    if (message.isMyMessage) {
      menuItems.add(
        ContextMenuItem(
          icon: 'assets/icons/chats/menu_icons/delete-red.svg',
          text: AppLocalizations.of(context)!.translate('delete'),
          isDestructive: true,
          onTap: () {
            _deleteMessage(context);
          },
        ),
      );
    }

    PremiumContextMenu.show(
      context: context,
      messagePosition: position,
      messageSize: messageBox.size,
      // В preview-слое блокируем интерактив, чтобы tap по фото не открывал viewer.
      messageWidget: IgnorePointer(
        child: _buildMessageContent(context),
      ),
      items: menuItems,
      channelKey: chatChannelName,
      onReactionSelected: _shouldShowMessageReactions &&
              message.id > 0 &&
              onReactionToggle != null
          ? (emoji) => onReactionToggle!.call(message, emoji)
          : null,
      showReactions: _shouldShowMessageReactions &&
          message.id > 0 &&
          onReactionToggle != null,
      onDismiss: () {
        onMenuStateChanged?.call(false);
      },
    );
  }

  void _copyMessageToClipboard(BuildContext context, String messageText) {
    Clipboard.setData(ClipboardData(text: messageText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate('copy_message'),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appColors.textInverse,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: context.appColors.success,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyMessageToClipboardByType(BuildContext context, Message message) {
    _copyMessageToClipboard(context, _getCopyableMessageText(message));
  }

  String _getCopyableMessageText(Message message) {
    if (message.type == 'location') {
      if (message.latitude != null && message.longitude != null) {
        return _buildLocationUrl(message.latitude!, message.longitude!);
      }

      final extractedUrl = _extractFirstUrl(message.text);
      if (extractedUrl != null && extractedUrl.isNotEmpty) {
        return extractedUrl;
      }
    }

    return message.text;
  }

  String _buildLocationUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  String? _extractFirstUrl(String rawText) {
    try {
      final document = parse(rawText);
      final href = document.querySelector('a[href]')?.attributes['href'];
      if (href != null && href.trim().isNotEmpty) {
        return href.trim();
      }
    } catch (_) {}

    final match = RegExp("https?://[^\\s'\"<]+", caseSensitive: false)
        .firstMatch(rawText);
    return match?.group(0);
  }

  Future<void> _openLocationInMap(Message message) async {
    final locationUrl = message.latitude != null && message.longitude != null
        ? _buildLocationUrl(message.latitude!, message.longitude!)
        : _extractFirstUrl(message.text);

    if (locationUrl == null || locationUrl.isEmpty) {
      return;
    }

    await launchUrl(
      Uri.parse(locationUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  void _deleteMessage(BuildContext context) {
    if (message.isMyMessage) {
      context.read<DeleteMessageBloc>().add(DeleteMessage(message.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('sms_deletes_successfully'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appColors.textInverse,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: context.appColors.success,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
