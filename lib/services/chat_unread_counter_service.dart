import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/utils/active_chat_tracker.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ChatUnreadCounts {
  final int total;
  final int lead;
  final int task;
  final int support;
  final bool isLoading;
  final bool isInitialized;

  const ChatUnreadCounts({
    this.total = 0,
    this.lead = 0,
    this.task = 0,
    this.support = 0,
    this.isLoading = false,
    this.isInitialized = false,
  });

  int countForEndpoint(String endPoint) {
    switch (endPoint) {
      case 'lead':
        return lead;
      case 'task':
        return task;
      case 'corporate':
      case 'support':
        return support;
      default:
        return 0;
    }
  }

  ChatUnreadCounts copyWith({
    int? total,
    int? lead,
    int? task,
    int? support,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return ChatUnreadCounts(
      total: total ?? this.total,
      lead: lead ?? this.lead,
      task: task ?? this.task,
      support: support ?? this.support,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ChatUnreadCounterService {
  ChatUnreadCounterService._();

  static final ChatUnreadCounterService instance = ChatUnreadCounterService._();

  final ApiService _apiService = ApiService();
  final ActiveChatTracker _activeChatTracker = ActiveChatTracker();
  final ValueNotifier<ChatUnreadCounts> counts =
      ValueNotifier(const ChatUnreadCounts());

  PusherChannelsClient? _socketClient;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Map<String, String> _lastMessageFingerprints = {};

  Timer? _refreshDebounce;
  bool _isInitialized = false;
  bool _isConnecting = false;
  bool _isRefreshing = false;
  String? _currentUserUniqueId;

  Future<void> initialize() async {
    debugPrint(
      'ChatUnreadCounterService.initialize: isInitialized=$_isInitialized, isConnecting=$_isConnecting',
    );
    if (_isInitialized || _isConnecting) {
      debugPrint(
        'ChatUnreadCounterService.initialize: already initialized/connecting, refreshing counts silently',
      );
      unawaited(refreshCounts(silent: true));
      return;
    }

    _isConnecting = true;

    try {
      await refreshCounts();
      unawaited(_initializeSocket());
    } catch (e) {
      debugPrint('ChatUnreadCounterService.initialize error: $e');
      _isConnecting = false;
    }
  }

  Future<void> _initializeSocket() async {
    try {
      await _connectSocketIfNeeded();
      _isInitialized = true;
    } catch (e) {
      debugPrint('ChatUnreadCounterService._initializeSocket error: $e');
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> refreshCounts({bool silent = false}) async {
    if (_isRefreshing) {
      debugPrint(
        'ChatUnreadCounterService.refreshCounts: skipped, refresh already in progress',
      );
      return;
    }

    _isRefreshing = true;
    debugPrint(
        'ChatUnreadCounterService.refreshCounts: started, silent=$silent');

    if (!silent) {
      counts.value = counts.value.copyWith(isLoading: true);
    }

    try {
      await _apiService.initialize();
      final typeCounts = await _apiService.getUnreadMessagesCountByChatType();
      final lead = typeCounts['leads'] ?? 0;
      final task = typeCounts['tasks'] ?? 0;
      final support = typeCounts['corporate'] ?? 0;
      final total = typeCounts['all'] ?? (lead + task + support);

      debugPrint(
        'ChatUnreadCounterService.refreshCounts: loaded total=$total, lead=$lead, task=$task, support=$support',
      );

      counts.value = ChatUnreadCounts(
        total: total,
        lead: lead,
        task: task,
        support: support,
        isLoading: false,
        isInitialized: true,
      );
      debugPrint(
        'ChatUnreadCounterService.refreshCounts: notifier updated total=${counts.value.total}, lead=${counts.value.lead}, task=${counts.value.task}, support=${counts.value.support}, initialized=${counts.value.isInitialized}',
      );
    } catch (e) {
      debugPrint('ChatUnreadCounterService.refreshCounts error: $e');
      counts.value = counts.value.copyWith(
        isLoading: false,
        isInitialized: true,
      );
    } finally {
      _isRefreshing = false;
    }
  }

  void scheduleRefresh({Duration delay = const Duration(milliseconds: 900)}) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(delay, () {
      refreshCounts(silent: true);
    });
  }

  void markChatOpened({
    required int unreadCount,
    required String? type,
  }) {
    if (unreadCount <= 0) {
      return;
    }

    final normalizedType = _normalizeType(type);
    final current = counts.value;

    int nextLead = current.lead;
    int nextTask = current.task;
    int nextSupport = current.support;

    switch (normalizedType) {
      case 'lead':
        nextLead = (nextLead - unreadCount).clamp(0, nextLead);
        break;
      case 'task':
        nextTask = (nextTask - unreadCount).clamp(0, nextTask);
        break;
      case 'support':
        nextSupport = (nextSupport - unreadCount).clamp(0, nextSupport);
        break;
    }

    counts.value = current.copyWith(
      total: (current.total - unreadCount).clamp(0, current.total),
      lead: nextLead,
      task: nextTask,
      support: nextSupport,
      isInitialized: true,
    );
  }

  Future<void> _connectSocketIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userUniqueId = prefs.getString('unique_id');

    if (token == null ||
        token.isEmpty ||
        userUniqueId == null ||
        userUniqueId.isEmpty) {
      return;
    }

    if (_socketClient != null && _currentUserUniqueId == userUniqueId) {
      return;
    }

    _currentUserUniqueId = userUniqueId;

    final enteredDomainMap = await _apiService.getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];
    final verifiedDomain = await _apiService.getVerifiedDomain();

    if (enteredMainDomain == null || enteredDomain == null) {
      if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
        enteredMainDomain = verifiedDomain.split('-back.').last;
        enteredDomain = verifiedDomain.split('-back.').first;
      } else {
        await _apiService.initialize();
        final baseUrl = await _apiService.getDynamicBaseUrl();
        final match =
            RegExp(r'https://(.+?)-back\.(.+?)(/|$)').firstMatch(baseUrl);
        enteredDomain = match?.group(1) ?? 'fingroupcrm';
        enteredMainDomain = match?.group(2) ?? 'shamcrm.com';
      }
    }

    final customOptions = PusherChannelsOptions.custom(
      uriResolver: (metadata) =>
          Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    final socketClient = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint('ChatUnreadCounterService socket error: $exception');
        refresh();
      },
      minimumReconnectDelayDuration: const Duration(seconds: 1),
    );

    final userChannelName = 'presence-user.$userUniqueId';
    final presenceChannel = socketClient.presenceChannel(
      userChannelName,
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(
          'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': '$enteredDomain-back',
        },
      ),
    );

    _subscriptions.add(
      socketClient.onConnectionEstablished.listen((_) {
        presenceChannel.subscribeIfNotUnsubscribed();
      }),
    );

    for (final eventName in ['chat.created', 'chat.updated']) {
      _subscriptions.add(
        presenceChannel.bind(eventName).listen((event) {
          _handleSocketPayload(event.data);
        }),
      );
    }

    _socketClient = socketClient;
    await socketClient.connect();
  }

  void _handleSocketPayload(String rawPayload) {
    try {
      final decoded = json.decode(rawPayload);
      if (decoded is! Map) {
        return;
      }

      final chat = decoded['chat'];
      if (chat is! Map) {
        return;
      }

      final uniqueId = chat['unique_id']?.toString();
      if (_activeChatTracker.isChatActive(uniqueId)) {
        return;
      }

      final normalizedType = _normalizeType(chat['type']?.toString());
      if (normalizedType == null) {
        return;
      }

      final lastMessage = chat['lastMessage'];
      final fingerprint = _buildFingerprint(chat, lastMessage);
      final chatKey =
          uniqueId?.isNotEmpty == true ? uniqueId! : '${chat['id'] ?? ''}';

      if (fingerprint.isNotEmpty &&
          _lastMessageFingerprints[chatKey] == fingerprint) {
        return;
      }

      if (fingerprint.isNotEmpty) {
        _lastMessageFingerprints[chatKey] = fingerprint;
      }

      final current = counts.value;
      int nextLead = current.lead;
      int nextTask = current.task;
      int nextSupport = current.support;

      switch (normalizedType) {
        case 'lead':
          nextLead += 1;
          break;
        case 'task':
          nextTask += 1;
          break;
        case 'support':
          nextSupport += 1;
          break;
      }

      counts.value = current.copyWith(
        total: current.total + 1,
        lead: nextLead,
        task: nextTask,
        support: nextSupport,
        isInitialized: true,
      );
    } catch (e) {
      debugPrint('ChatUnreadCounterService._handleSocketPayload error: $e');
    }
  }

  String _buildFingerprint(Map chat, dynamic lastMessage) {
    if (lastMessage is Map) {
      final messageId = lastMessage['id']?.toString();
      final createdAt = lastMessage['created_at']?.toString();
      final text = lastMessage['text']?.toString();
      return '${messageId ?? ''}|${createdAt ?? ''}|${text ?? ''}';
    }

    return '${chat['id'] ?? ''}|${chat['updated_at'] ?? ''}|${chat['last_message'] ?? ''}';
  }

  String? _normalizeType(String? type) {
    switch (type) {
      case 'lead':
        return 'lead';
      case 'task':
        return 'task';
      case 'support':
      case 'corporate':
        return 'support';
      default:
        return null;
    }
  }

  Future<void> dispose() async {
    _refreshDebounce?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _socketClient?.dispose();
    _socketClient = null;
    _isInitialized = false;
    _isConnecting = false;
    _isRefreshing = false;
  }
}
