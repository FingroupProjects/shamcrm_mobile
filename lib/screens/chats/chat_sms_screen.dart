import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_event.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_state.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/utils/active_chat_tracker.dart'; // ✅ ДОБАВЛЕНО: Импорт для отслеживания активного чата
import 'package:crm_task_manager/services/message_cache_service.dart'; // ✅ ДОБАВЛЕНО: Импорт для кэширования сообщений
import 'package:crm_task_manager/models/integration_model.dart';
import 'package:crm_task_manager/models/msg_data_in_socket.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chatById_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chatById_task_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/image_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/input_field.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/pin_lead_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_corporate_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_user_corporate.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/voice_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/pin_message_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/api_service_chats.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/file_message_bubble.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/message_bubble.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:table_calendar/table_calendar.dart';

class ChatSmsScreen extends StatefulWidget {
  final ChatItem chatItem;
  final int chatId;
  final String? chatUniqueId;
  final String endPointInTab;
  final bool canSendMessage;
  final ApiService apiService = ApiService();
  final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

  ChatSmsScreen({
    super.key,
    required this.chatItem,
    required this.chatId,
    this.chatUniqueId,
    required this.endPointInTab,
    required this.canSendMessage,
  });

  @override
  State<ChatSmsScreen> createState() => _ChatSmsScreenState();
}

class _ChatSmsScreenState extends State<ChatSmsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ItemScrollController _scrollControllerMessage = ItemScrollController();
  final TextEditingController _messageController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  WebSocket? _webSocket;
  late StreamSubscription<ChannelReadEvent>? chatSubscribtion;
  late PusherChannelsClient socketClient;
  final ApiService apiService = ApiService();
  late String baseUrl;
  String? _currentDate;
  bool _canCreateChat = false;
  bool _isRequestInProgress = false;
  int? _highlightedMessageId;
  bool _isMenuOpen = false;
  bool _isSearching = false;
  String? _searchQuery;
  String? integrationUsername;
  String? channelName;
  bool _hasMarkedMessagesAsRead = false;
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
  bool _isLoadingFromCache = false; // ✅ Флаг загрузки из кэша
  bool _isLoadingFromApi = false; // ✅ Флаг загрузки с API
  String? _cachedCompanionName; // Кэшированное имя собеседника
  bool? _isGroupChat; // Флаг, является ли чат группой

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    context.read<MessagingCubit>().getMessages(widget.chatId,
        search: query, chatType: widget.endPointInTab);
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
    _checkPermissions();

    _chatsBloc = context.read<ChatsBloc>();
    _messagingCubit = context
        .read<MessagingCubit>(); // Сохраняем ссылку для использования в dispose

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

  Future<void> _retryInitialization() async {
    try {
      await _initializeBaseUrl();
      context
          .read<MessagingCubit>()
          .getMessages(widget.chatId, chatType: widget.endPointInTab);
    } catch (e) {
      debugPrint('Retry failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Повторная попытка не удалась: $e'),
            backgroundColor: Colors.red,
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
    required String myUserId,
    required bool isLeadChat,
    bool? isMyMessageFromServer,
    String? debugContext = '', // для удобства понимания, откуда пришёл вызов
  }) async {
    final logPrefix = '[_determineIsMyMessage] $debugContext → ';

    debugPrint(
        '=================-=== ┌───────────── $logPrefix START ─────────────┐');
    debugPrint('=================-=== │ myUserId            : $myUserId');
    debugPrint('=================-=== │ isLeadChat          : $isLeadChat');
    debugPrint(
        '=================-=== │ isMyMessageFromServer: $isMyMessageFromServer');
    debugPrint(
        '=================-=== │ sender.id           : $messageSenderId');
    debugPrint(
        '=================-=== │ sender.type         : $messageSenderType');

    bool isMyMessage;

    // ✅ ПРИОРИТЕТ 1: Сравнение ID отправителя (САМЫЙ НАДЕЖНЫЙ СПОСОБ!)
    // ✅ КРИТИЧНО: Если есть sender.id - используем его, а НЕ is_my_message от сервера!
    // Сервер иногда ошибается с is_my_message, но sender.id всегда правильный
    if (messageSenderId != null &&
        messageSenderId.isNotEmpty &&
        myUserId.isNotEmpty) {
      // ✅ КРИТИЧНО: Приводим к строке и убираем пробелы для надежного сравнения
      final senderIdStr = messageSenderId.toString().trim();
      final myIdStr = myUserId.toString().trim();

      // ✅ ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Пробуем сравнить как числа, если оба являются числами
      bool idsMatch = false;
      try {
        final senderIdNum = int.tryParse(senderIdStr);
        final myIdNum = int.tryParse(myIdStr);
        if (senderIdNum != null && myIdNum != null) {
          idsMatch = senderIdNum == myIdNum;
          debugPrint(
              '=================-=== │ 🔢 ПРИОРИТЕТ 1 → Сравнение как числа: $senderIdNum ${idsMatch ? "==" : "!="} $myIdNum');
        } else {
          idsMatch = senderIdStr == myIdStr;
          debugPrint(
              '=================-=== │ 📝 ПРИОРИТЕТ 1 → Сравнение как строки: "$senderIdStr" ${idsMatch ? "==" : "!="} "$myIdStr"');
        }
      } catch (e) {
        idsMatch = senderIdStr == myIdStr;
        debugPrint(
            '=================-=== │ ⚠ ПРИОРИТЕТ 1 → Ошибка при сравнении ID, используем строковое сравнение: $e');
      }

      // ✅ КРИТИЧНО: ИСПРАВЛЕНО: Если ID совпадают - это НАШЕ сообщение (isMyMessage = true)
      // ✅ Если ID НЕ совпадают - это ЧУЖОЕ сообщение (isMyMessage = false)
      isMyMessage = idsMatch;
      debugPrint(
          '=================-=== │ ✓✓✓✓✓ ПРИОРИТЕТ 1 → sender.id "$senderIdStr" ${idsMatch ? "==" : "!="} myUserId "$myIdStr" → isMyMessage = $isMyMessage (НАДЕЖНО!)');

      // ✅ КРИТИЧНО: Если ID НЕ совпадают - это точно НЕ мое сообщение, возвращаем сразу
      if (!isMyMessage) {
        debugPrint(
            '=================-=== │ ⚠⚠⚠ ВАЖНО: ID НЕ совпадают - это точно НЕ мое сообщение!');
        debugPrint(
            '=================-=== │ ⚠ Игнорируем is_my_message от сервера ($isMyMessageFromServer), т.к. sender.id не совпадает!');
        debugPrint('=================-=== │');
        debugPrint(
            '=================-=== │ ИТОГ: isMyMessage = $isMyMessage (ID НЕ совпадают)');
        debugPrint(
            '=================-=== └───────────── $logPrefix END ─────────────┘');
        return isMyMessage;
      }

      // ✅ Если ID совпадают - это точно мое сообщение, возвращаем сразу
      debugPrint(
          '=================-=== │ ✓✓✓✓✓ ID совпадают - это точно МОЁ сообщение!');
      debugPrint('=================-=== │');
      debugPrint(
          '=================-=== │ ИТОГ: isMyMessage = $isMyMessage (ID совпадают)');
      debugPrint(
          '=================-=== └───────────── $logPrefix END ─────────────┘');
      return isMyMessage;
    }

    // ✅ ПРИОРИТЕТ 2: Специфичная логика для lead-чатов (только если нет sender.id)
    // ✅ КРИТИЧНО: В lead-чатах sender.type имеет ВЫСОКИЙ приоритет
    if (isLeadChat && messageSenderType != null) {
      if (messageSenderType.toLowerCase() == 'user') {
        isMyMessage = true;
        debugPrint(
            '=================-=== │ ✓✓✓ ПРИОРИТЕТ 2 → lead-чат, sender.type = "user" → это МОЁ сообщение (менеджер)');
        debugPrint('=================-=== │');
        debugPrint('=================-=== │ ИТОГ: isMyMessage = $isMyMessage');
        debugPrint(
            '=================-=== └───────────── $logPrefix END ─────────────┘');
        return isMyMessage;
      } else if (messageSenderType.toLowerCase() == 'lead') {
        isMyMessage = false;
        debugPrint(
            '=================-=== │ ✓✓✓ ПРИОРИТЕТ 2 → lead-чат, sender.type = "lead" → это СООБЩЕНИЕ КЛИЕНТА (лид)');
        debugPrint('=================-=== │');
        debugPrint('=================-=== │ ИТОГ: isMyMessage = $isMyMessage');
        debugPrint(
            '=================-=== └───────────── $logPrefix END ─────────────┘');
        return isMyMessage;
      } else {
        debugPrint(
            '=================-=== │ ⚠ ПРИОРИТЕТ 2 → неизвестный sender.type "$messageSenderType" → переходим к fallback');
      }
    }

    // ✅ ПРИОРИТЕТ 3: is_my_message от сервера (только если нет sender.id и sender.type)
    // ✅ ВНИМАНИЕ: Сервер иногда ошибается, поэтому это последний приоритет!
    if (isMyMessageFromServer != null) {
      isMyMessage = isMyMessageFromServer;
      debugPrint(
          '=================-=== │ ⚠ ПРИОРИТЕТ 3 → берём is_my_message от сервера = $isMyMessage (НЕ НАДЕЖНО, но fallback)');
      debugPrint(
          '=================-=== │ ⚠ ВНИМАНИЕ: sender.id отсутствует, используем значение от сервера');
      debugPrint('=================-=== │');
      debugPrint('=================-=== │ ИТОГ: isMyMessage = $isMyMessage');
      debugPrint(
          '=================-=== └───────────── $logPrefix END ─────────────┘');
      return isMyMessage;
    }

    // ✅ Последний fallback — безопасность (считаем чужим, если ничего не определили)
    isMyMessage = false;
    debugPrint(
        '=================-=== │ ✗ FALLBACK → не смогли определить → считаем ЧУЖИМ сообщением');

    debugPrint('=================-=== │');
    debugPrint('=================-=== │ ИТОГ: isMyMessage = $isMyMessage');
    debugPrint(
        '=================-=== └───────────── $logPrefix END ─────────────┘');

    return isMyMessage;
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
          if (mounted) _scrollToBottom();
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
      await messagingCubit.getMessagesWithFallback(widget.chatId,
          chatType: widget.endPointInTab);

      // ✅ Сохраняем в кэш после успешной загрузки
      final state = messagingCubit.state;
      if (state is MessagesLoadedState && state.messages.isNotEmpty) {
        await _cacheService.cacheMessages(widget.chatId, state.messages);
        debugPrint(
            '=================-=== ✅ ChatSmsScreen: Cached ${state.messages.length} fresh messages');
      } else if (state is PinnedMessagesState && state.messages.isNotEmpty) {
        await _cacheService.cacheMessages(widget.chatId, state.messages);
        debugPrint(
            '=================-=== ✅ ChatSmsScreen: Cached ${state.messages.length} fresh messages (with pins)');
      }

      // ✅ Скроллим вниз после небольшой задержки
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToBottom();
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
          'Частичная ошибка подключения: ${_getReadableError(error)}',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Повторить',
          textColor: Colors.white,
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
    if (_hasMarkedMessagesAsRead) {
      if (kDebugMode) {
        //print('ChatSmsScreen: _markMessagesAsRead уже вызван, пропускаем');
      }
      return;
    }

    final state = context.read<MessagingCubit>().state;
    if (kDebugMode) {
      //print('ChatSmsScreen: Текущее состояние в _markMessagesAsRead: $state');
    }
    List<Message> messages = [];
    if (state is MessagesLoadedState) {
      messages = state.messages;
    } else if (state is PinnedMessagesState) {
      messages = state.messages;
    }

    if (kDebugMode) {
      //print('ChatSmsScreen: Количество сообщений: ${messages.length}');
    }

    bool hasUnreadMessages = messages.any((msg) => !msg.isRead);
    if (messages.isNotEmpty && hasUnreadMessages) {
      final latestMessageId = messages.first.id;
      if (kDebugMode) {
        //print('ChatSmsScreen: Пометка сообщений как прочитанных, chatId: ${widget.chatId}, latestMessageId: $latestMessageId');
      }
      try {
        await widget.apiService.readMessages(widget.chatId, latestMessageId);
        if (kDebugMode) {
          //print('ChatSmsScreen: Сообщения успешно помечены как прочитанные');
        }
        _hasMarkedMessagesAsRead = true;
      } catch (e) {
        if (kDebugMode) {
          //print('ChatSmsScreen: Ошибка при пометке сообщений как прочитанных: $e');
        }
      }
    } else {
      if (kDebugMode) {
        //print('ChatSmsScreen: Нет непрочитанных сообщений или список пуст');
      }
      _hasMarkedMessagesAsRead = true;
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
      } else if (username.contains('whatsapp') || username.contains('wa')) {
        return 'whatsapp';
      } else if (username.contains('instagram') || username.contains('ig')) {
        return 'instagram';
      } else if (username.contains('facebook') || username.contains('fb')) {
        return 'facebook';
      } else if (username.contains('web') || username.contains('site')) {
        return 'website';
      }
    }

    return 'messenger';
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
    DateTime? selectedDate;

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
                  color: Colors.white,
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
                          color: Colors.blue,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(color: Colors.blue),
                      outsideDaysVisible: true,
                      outsideTextStyle:
                          TextStyle(color: Colors.black.withOpacity(0.3)),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
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
                        final monthNames = {
                          1: 'Январь',
                          2: 'Февраль',
                          3: 'Март',
                          4: 'Апрель',
                          5: 'Май',
                          6: 'Июнь',
                          7: 'Июль',
                          8: 'Август',
                          9: 'Сентябрь',
                          10: 'Октябрь',
                          11: 'Ноябрь',
                          12: 'Декабрь'
                        };

                        final monthName = monthNames[date.month] ?? '';
                        return '$monthName ${date.year} г.';
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
                              decoration: const BoxDecoration(
                                color: Colors.blue,
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
                              'Нет сообщений за ${formatDate(selectedDay)}',
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: Colors.red,
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

  void _scrollToMessageIndex(DateTime selectedDate) {
    final state = context.read<MessagingCubit>().state;
    if (state is MessagesLoadedState || state is PinnedMessagesState) {
      final messages = state is MessagesLoadedState
          ? state.messages
          : (state as PinnedMessagesState).messages;

      final messageIndex = _findMessageIndexByDate(messages, selectedDate);

      if (messageIndex != -1) {
        debugPrint(
            'Scrolling to index: $messageIndex for date: ${formatDate(selectedDate)}');
        _scrollControllerMessage.scrollTo(
          index: messageIndex,
          alignment: 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Нет сообщений за ${formatDate(selectedDate)}',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
        backgroundColor: Colors.white,
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
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
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
        backgroundColor: isSupportAvatar ? Colors.black : Colors.white,
        onBackgroundImageError: (exception, stackTrace) {},
      );
    } catch (e) {
      return CircleAvatar(
        backgroundImage: AssetImage(isTaskSection
            ? 'assets/images/AvatarTask.png'
            : 'assets/images/AvatarChat.png'),
        radius: ChatSmsStyles.avatarRadius,
        backgroundColor: isSupportAvatar ? Colors.black : Colors.white,
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
        if ((state is MessagesLoadedState || state is PinnedMessagesState) &&
            !_hasMarkedMessagesAsRead) {
          _markMessagesAsRead();
        }
      },
      child: BlocListener<DeleteMessageBloc, DeleteMessageState>(
        listener: (context, state) {
          if (state is DeleteMessageSuccess) {
            context
                .read<MessagingCubit>()
                .getMessages(widget.chatId, chatType: widget.endPointInTab);
            if (widget.endPointInTab == 'task' ||
                widget.endPointInTab == 'corporate') {
              final chatsBloc = context.read<ChatsBloc>();
              chatsBloc.add(ClearChats());
              chatsBloc.add(FetchChats(endPoint: widget.endPointInTab));
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            forceMaterialTransparency: false,
            scrolledUnderElevation: 0,
            elevation: 0,
            centerTitle: false,
            leadingWidth: 40,
            leading: Transform.translate(
              offset: const Offset(6, 0),
              child: IconButton(
                icon: Image.asset(
                  'assets/icons/arrow-left.png',
                  width: 40,
                  height: 40,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: _isSearching
                      ? const Icon(Icons.close)
                      : Image.asset('assets/icons/AppBar/search.png',
                          width: 24, height: 24),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      _searchQuery = null;
                    });
                    if (!_isSearching) {
                      context.read<MessagingCubit>().getMessages(widget.chatId,
                          chatType: widget.endPointInTab);
                    }
                  },
                ),
              ),
            ],
            title: Transform.translate(
              offset: const Offset(-12, 0),
              child: _isSearching
                  ? TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!
                            .translate('search_appbar'),
                        border: InputBorder.none,
                        hintStyle: const TextStyle(
                            color: Colors.black, fontFamily: 'Gilroy'),
                      ),
                      onChanged: _onSearchChanged,
                    )
                  : GestureDetector(
                      onTap: isSupportChat
                          ? null
                          : () async {
                              if (_isRequestInProgress) return;
                              setState(() {
                                _isRequestInProgress = true;
                              });
                              try {
                                if (widget.endPointInTab == 'lead') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(
                                          chatId: widget.chatId),
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
                                } else if (widget.endPointInTab ==
                                    'corporate') {
                                  try {
                                    final getChatById = await widget.apiService
                                        .getChatById(widget.chatId);
                                    if (getChatById.chatUsers.isNotEmpty &&
                                        getChatById.chatUsers.length == 2 &&
                                        getChatById.group == null) {
                                      String userIdCheck = '';
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      userIdCheck =
                                          prefs.getString('userID') ?? '';
                                      final otherUsers = getChatById.chatUsers
                                          .where((user) =>
                                              user.participant.id.toString() !=
                                              userIdCheck)
                                          .toList();

                                      if (otherUsers.isNotEmpty) {
                                        final participant =
                                            otherUsers.first.participant;
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
                                              lastSeen: participant.lastSeen
                                                  .toString(),
                                              buttonChat: false,
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Если не найден другой участник, открываем профиль группы
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CorporateProfileScreen(
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
                                          builder: (context) =>
                                              CorporateProfileScreen(
                                            chatId: widget.chatId,
                                            chatItem: widget.chatItem,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint(
                                        "Ошибка при открытии профиля корпоративного чата: $e");
                                    // В случае ошибки открываем профиль группы
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CorporateProfileScreen(
                                          chatId: widget.chatId,
                                          chatItem: widget.chatItem,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'ОШИБКА!',
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } finally {
                                setState(() {
                                  _isRequestInProgress = false;
                                });
                              }
                            },
                      child: Row(
                        children: [
                          _buildAvatar(widget.chatItem.avatar),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isSupportChat
                                  ? AppLocalizations.of(context)!
                                      .translate('support_chat_name')
                                  : widget.chatItem.name.isEmpty
                                      ? AppLocalizations.of(context)!
                                          .translate('no_name')
                                      : widget.chatItem.name,
                              style: const TextStyle(
                                fontSize: 18,
                                color: ChatSmsStyles.appBarTitleColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Gilroy',
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          backgroundColor: const Color(0xffF4F7FD),
          body: Column(
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
                          ? AppLocalizations.of(context)!
                              .translate('not_premission_to_send_sms')
                          : AppLocalizations.of(context)!
                              .translate('24_hour_leads'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        color: AppColors.textPrimary700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToMessageReply(int messageId) {
    final state = context.read<MessagingCubit>().state;
    if (state is MessagesLoadedState || state is PinnedMessagesState) {
      final messages = state is MessagesLoadedState
          ? state.messages
          : (state as PinnedMessagesState).messages;

      final messageIndex = messages.indexWhere((msg) => msg.id == messageId);

      if (messageIndex != -1) {
        _scrollControllerMessage.scrollTo(
          index: messageIndex,
          duration: const Duration(milliseconds: 1),
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
    }
  }

  Widget messageListUi() {
    return BlocBuilder<MessagingCubit, MessagingState>(
      builder: (context, state) {
        debugPrint(
            '=================-=== messageListUi: Building with state: $state');

        if (state is MessagesPartialErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  "Частичная ошибка подключения",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: Colors.orange,
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
                      color: Colors.grey[600],
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
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        "Повторить",
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
                        "Пустой чат",
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.grey[600],
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Ошибка подключения к серверу",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: Colors.red,
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
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Повторить попытку"),
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      context.read<MessagingCubit>().showEmptyChat();
                    },
                    child: Text("Открыть пустой чат"),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Ошибка загрузки сообщений"),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<MessagingCubit>().getMessagesWithFallback(
                        widget.chatId,
                        chatType: widget.endPointInTab);
                  },
                  child: Text("Повторить"),
                ),
              ],
            ),
          );
        }

        if (state is MessagesLoadingState) {
          return Center(child: CircularProgressIndicator.adaptive());
        }
        if (state is MessagesLoadedState ||
            state is ReplyingToMessageState ||
            state is PinnedMessagesState ||
            state is EditingMessageState) {
          final messages = state is MessagesLoadedState
              ? state.messages
              : state is ReplyingToMessageState
                  ? state.messages
                  : state is PinnedMessagesState
                      ? state.messages
                      : (state as EditingMessageState).messages;
          debugPrint('messageListUi: Rendering ${messages.length} messages');
          final pinnedMessages = state is PinnedMessagesState
              ? state.pinnedMessages
              : state is ReplyingToMessageState
                  ? state.pinnedMessages
                  : state is EditingMessageState
                      ? state.pinnedMessages
                      : [];

          if (messages.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.translate('not_sms'),
                style: TextStyle(color: AppColors.textPrimary700),
              ),
            );
          }

          debugPrint(
              '=================-=== Rendering messageListUi: integrationUsername=$integrationUsername, channelName=$channelName');

          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _scrollControllerMessage,
                    itemCount: messages.length,
                    reverse: true,
                    itemBuilder: (context, index) {
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
                        widgets.add(
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: GestureDetector(
                              onTap: () => _showDatePicker(context, messages),
                              child: Center(
                                child: Text(
                                  formatDate(messageDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: "Gilroy",
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      widgets.add(
                        MessageItemWidget(
                          message: message,
                          chatId: widget.chatId,
                          endPointInTab: widget.endPointInTab,
                          apiServiceDownload: widget.apiServiceDownload,
                          baseUrl: baseUrl,
                          onReplyTap: _scrollToMessageReply,
                          highlightedMessageId: _highlightedMessageId,
                          onMenuStateChanged: (isOpen) {
                            setState(() {
                              _isMenuOpen = isOpen;
                            });
                          },
                          focusNode: _focusNode,
                          isRead: message.isRead,
                          isFirstMessage: isFirstMessage,
                          referralBody: referralBody,
                          isGroupChat: _isGroupChat,
                        ),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widgets,
                      );
                    },
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
                        color: Colors.transparent,
                        child: PinnedLeadMessageWidget(
                          message: '@$integrationUsername',
                          channelType: channelName,
                          onTap: null,
                        ),
                      ),
                    if (pinnedMessages.isNotEmpty)
                      Material(
                        color: Colors.transparent,
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
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
            ],
          );
        }
        return Container();
      },
    );
  }

  Widget inputWidget() {
    return SafeArea(
      bottom: true,
      top: false,
      child: InputField(
        onSend: _onSendInButton,
        onAttachFile: _onPickFilePressed,
        focusNode: _focusNode,
        isLeadChat: widget.endPointInTab == 'lead',
        onRecordVoice: () {
          debugPrint('Record voice triggered');
        },
        messageController: _messageController,
        sendRequestFunction: (File soundFile, String time) async {
          Duration calculateDuration(String time) {
            List<String> parts = time.split(':');
            int minutes = int.parse(parts[0]);
            int seconds = int.parse(parts[1]);
            return Duration(minutes: minutes, seconds: seconds);
          }

          final tempMessage = Message(
            id: -DateTime.now().millisecondsSinceEpoch,
            text: "Голосовое сообщение",
            type: 'voice',
            createMessateTime:
                DateTime.now().add(Duration(hours: -0)).toString(),
            isMyMessage: true,
            senderName: "Вы",
            filePath: soundFile.path,
            duration: calculateDuration(time),
          );

          context.read<MessagingCubit>().addLocalMessage(tempMessage);

          await _playSound();

          String inputPath = soundFile.path;
          String outputPath = await getOutputPath('converted_file.ogg');

          File? convertedFile = await convertAudioFile(inputPath, outputPath);

          if (convertedFile != null) {
            String uploadUrl = '$baseUrl/chat/sendVoice/${widget.chatId}';
            await uploadFile(convertedFile, uploadUrl);
          } else {
            debugPrint('Conversion failed');
          }
          try {
            await widget.apiService.sendChatAudioFile(widget.chatId, soundFile);
          } catch (e) {
            context.read<ListenSenderVoiceCubit>().updateValue(false);
          }
          context.read<ListenSenderVoiceCubit>().updateValue(false);
        },
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

    debugPrint(
        '=================-=== 📱 Chat identifier for socket: $chatIdentifier (uniqueId: ${widget.chatUniqueId}, chatId: ${widget.chatId})');
    debugPrint('=================-=== 📢 Channel name: $channelName');

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

    socketClient.onConnectionEstablished.listen((_) {
      debugPrint(
          '=================-=== ✅ Socket connected successfully for chatIdentifier: $chatIdentifier');
      myPresenceChannel.subscribeIfNotUnsubscribed();
      debugPrint('=================-=== ✅ Subscribed to channel: $channelName');
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

        if (mounted) {
          debugPrint(
              '=================-=== 🔔 CHAT_SMS: ✅ RELOADING messages...');
          context
              .read<MessagingCubit>()
              .getMessages(widget.chatId, chatType: widget.endPointInTab);

          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) _scrollToBottom();
          });

          final lastMessage = chatData?['lastMessage'];

          if (lastMessage != null) {
            // ✅ КРИТИЧНО: Извлекаем is_my_message с проверкой на разные форматы
            bool? isMyMessageFromServer;
            if (lastMessage['is_my_message'] != null) {
              final isMyMsgValue = lastMessage['is_my_message'];
              if (isMyMsgValue is bool) {
                isMyMessageFromServer = isMyMsgValue;
              } else if (isMyMsgValue is int) {
                isMyMessageFromServer = isMyMsgValue == 1;
              } else if (isMyMsgValue is String) {
                isMyMessageFromServer =
                    isMyMsgValue.toLowerCase() == 'true' || isMyMsgValue == '1';
              }
              debugPrint(
                  '=================-=== 🔍🔍🔍 ChatUpdated: is_my_message извлечено: $isMyMessageFromServer (тип: ${isMyMsgValue.runtimeType})');
            } else {
              debugPrint(
                  '=================-=== ⚠️⚠️⚠️ ChatUpdated: is_my_message ОТСУТСТВУЕТ в lastMessage!');
            }
            debugPrint(
                '=================-=== 🔔 CHAT_SMS: lastMessage.is_my_message=$isMyMessageFromServer ⭐⭐⭐');

            final prefs = await SharedPreferences.getInstance();
            final myUserId = prefs.getString('userID') ?? '';
            final isLeadChat = widget.endPointInTab == 'lead';

            String? senderId = lastMessage['sender']?['id']?.toString();
            String? senderType = lastMessage['sender']?['type']?.toString();

            bool isMyMessage = await _determineIsMyMessage(
              messageSenderId: senderId,
              messageSenderType: senderType,
              myUserId: myUserId,
              isLeadChat: isLeadChat,
              isMyMessageFromServer: isMyMessageFromServer,
            );

            debugPrint(
                '=================-=== 🔔 CHAT_SMS: Determined isMyMessage=$isMyMessage');

            if (!isMyMessage) {
              try {
                await _audioPlayer.setAsset('assets/audio/get.mp3');
                await _audioPlayer.play();
                debugPrint(
                    '=================-=== 🔊 CHAT_SMS (ChatUpdated): Played sound');
              } catch (e) {
                debugPrint(
                    '=================-=== ⚠️ CHAT_SMS: Sound error: $e');
              }
            }
          }

          debugPrint(
              '=================-=== ✅ CHAT_SMS (ChatUpdated): Handled successfully');
        }
      } catch (e, stackTrace) {
        debugPrint('=================-=== ❌ CHAT_SMS (ChatUpdated): ERROR: $e');
      }
    });
    debugPrint(
        '=================-=== ✅✅✅ CHAT_SMS: chat.updated listener registered');

    // ✅ ИСПРАВЛЕНО: Сервер отправляет событие как 'chat.message' (broadcastAs), а не 'MessageSent'
    debugPrint(
        '=================-=== 🎯🎯🎯 CHAT_SMS: Registering chat.message listener for $channelName...');
    chatSubscribtion =
        myPresenceChannel.bind('chat.message').listen((event) async {
      debugPrint(
          '=================-=== \n╔══════════════════════════════════════════════╗');
      debugPrint(
          '=================-=== ║    📨 chat.message — НОВОЕ СООБЩЕНИЕ         ║');
      debugPrint(
          '=================-=== ╚══════════════════════════════════════════════╝');

      try {
        // 1. Проверка входных данных
        if (event.data == null || event.data.trim().isEmpty) {
          debugPrint(
              '=================-=== ❌ MessageSent: event.data пустой или null');
          return;
        }

        debugPrint('=================-=== Raw event.data: ${event.data}');

        // 2. Парсинг JSON
        final rawData = json.decode(event.data);
        debugPrint('=================-=== Parsed JSON: $rawData');

        // 3. Определяем, где лежат данные сообщения
        Map<String, dynamic> messageData;
        if (rawData is Map &&
            rawData['message'] != null &&
            rawData['message'] is Map) {
          messageData = rawData['message'] as Map<String, dynamic>;
          debugPrint(
              '=================-=== Структура: {"message": {...}} → берём вложенный message');
        } else if (rawData is Map && rawData['id'] != null) {
          messageData = rawData as Map<String, dynamic>;
          debugPrint(
              '=================-=== Структура: данные сообщения на верхнем уровне');
        } else {
          debugPrint(
              '=================-=== ❌ Неизвестная структура данных: $rawData');
          return;
        }

        // 4. Извлекаем ключевые поля
        final messageId = messageData['id'] as int?;
        final text = messageData['text'] as String?;
        final type = messageData['type'] as String? ?? 'text';
        final createdAt = messageData['created_at'] as String?;
        final filePath = messageData['file_path']?.toString();
        final voiceDuration = messageData['voice_duration'];

        // ✅ КРИТИЧНО: Извлекаем is_my_message с проверкой на разные форматы
        bool? isMyMessageFromServer;
        if (messageData['is_my_message'] != null) {
          final isMyMsgValue = messageData['is_my_message'];
          if (isMyMsgValue is bool) {
            isMyMessageFromServer = isMyMsgValue;
          } else if (isMyMsgValue is int) {
            isMyMessageFromServer = isMyMsgValue == 1;
          } else if (isMyMsgValue is String) {
            isMyMessageFromServer =
                isMyMsgValue.toLowerCase() == 'true' || isMyMsgValue == '1';
          }
          debugPrint(
              '=================-=== 🔍🔍🔍 MessageSent: is_my_message извлечено: $isMyMessageFromServer (тип: ${isMyMsgValue.runtimeType})');
        } else {
          debugPrint(
              '=================-=== ⚠️⚠️⚠️ MessageSent: is_my_message ОТСУТСТВУЕТ в messageData!');
        }

        debugPrint(
            '=================-=== ┌─ Данные сообщения ───────────────────────────────┐');
        debugPrint('=================-=== │ id              : $messageId');
        debugPrint('=================-=== │ type            : $type');
        debugPrint(
            '=================-=== │ text            : ${text?.substring(0, (text?.length ?? 0) > 60 ? 60 : (text?.length ?? 0))}...');
        debugPrint('=================-=== │ created_at      : $createdAt');
        debugPrint(
            '=================-=== │ is_my_message   : $isMyMessageFromServer ⭐⭐⭐');
        debugPrint('=================-=== │ file_path       : $filePath');
        debugPrint('=================-=== │ voice_duration  : $voiceDuration');
        debugPrint(
            '=================-=== └─────────────────────────────────────────────────────┘');

        // 5. Sender - ✅ КРИТИЧНО: Правильное извлечение данных отправителя
        // ✅ СЕРВЕР ОТПРАВЛЯЕТ: message.sender с полями id, name, type
        final senderData = messageData['sender'];
        String? senderId;
        String? senderType;
        String? senderName;

        debugPrint(
            '=================-=== 🔍🔍🔍 MessageSent: Проверяем sender данные...');
        debugPrint('=================-===    senderData: $senderData');
        debugPrint(
            '=================-===    senderData type: ${senderData?.runtimeType}');

        if (senderData != null) {
          if (senderData is Map<String, dynamic>) {
            senderId = senderData['id']?.toString();
            senderType = senderData['type']?.toString();
            senderName = senderData['name']?.toString();
            debugPrint(
                '=================-=== ┌─ Sender данные (Map) ───────────────────────────────┐');
            debugPrint('=================-=== │ id   : $senderId ⭐⭐⭐');
            debugPrint('=================-=== │ type : $senderType');
            debugPrint('=================-=== │ name : $senderName');
            debugPrint(
                '=================-=== └─────────────────────────────────────────────────────┘');
          } else if (senderData is Map) {
            // Fallback для Map без типизации
            final senderMap = Map<String, dynamic>.from(senderData);
            senderId = senderMap['id']?.toString();
            senderType = senderMap['type']?.toString();
            senderName = senderMap['name']?.toString();
            debugPrint(
                '=================-=== ┌─ Sender данные (Map fallback) ───────────────────────────────┐');
            debugPrint('=================-=== │ id   : $senderId ⭐⭐⭐');
            debugPrint('=================-=== │ type : $senderType');
            debugPrint('=================-=== │ name : $senderName');
            debugPrint(
                '=================-=== └─────────────────────────────────────────────────────┘');
          } else {
            debugPrint(
                '=================-=== ⚠️⚠️⚠️ Sender имеет неверный тип: ${senderData.runtimeType}');
            debugPrint('=================-=== ⚠️ senderData: $senderData');
          }
        } else {
          debugPrint('=================-=== ⚠️⚠️⚠️ Sender отсутствует (null)!');
          debugPrint(
              '=================-=== ⚠️ messageData keys: ${messageData.keys.toList()}');
        }

        // ✅ КРИТИЧНО: Если sender.id отсутствует, это проблема!
        if (senderId == null || senderId.isEmpty) {
          debugPrint(
              '=================-=== ❌❌❌ КРИТИЧЕСКАЯ ОШИБКА: sender.id отсутствует или пустой!');
          debugPrint(
              '=================-===    Это означает, что мы не сможем правильно определить отправителя!');
          debugPrint('=================-===    messageData: $messageData');
        }

        // 6. Мой ID
        final prefs = await SharedPreferences.getInstance();
        final myUserId = prefs.getString('userID') ?? '';

        if (myUserId.isEmpty) {
          debugPrint(
              '=================-=== !!! КРИТИЧЕСКАЯ ОШИБКА !!! userID в SharedPreferences пустой');
          // Можно добавить fallback или уведомление, но пока продолжаем
        }

        final isLeadChat = widget.endPointInTab == 'lead';
        debugPrint(
            '=================-=== Мой userID: "$myUserId" | Чат lead? $isLeadChat');

        // 7. Самое важное — определяем, чьё это сообщение
        // ✅ КРИТИЧНО: sender.id имеет ПРИОРИТЕТ 1 в _determineIsMyMessage
        // Если sender.id != null, он будет использован для сравнения с myUserId
        debugPrint(
            '=================-=== ╔═══════════════════════════════════════════════════════╗');
        debugPrint(
            '=================-=== ║  🎯 chat.message: ОПРЕДЕЛЯЕМ isMyMessage            ║');
        debugPrint(
            '=================-=== ╠═══════════════════════════════════════════════════════╣');
        debugPrint('=================-=== ║  sender.id ⭐⭐⭐        : $senderId');
        debugPrint(
            '=================-=== ║  sender.type            : $senderType');
        debugPrint(
            '=================-=== ║  myUserId                : $myUserId');
        debugPrint(
            '=================-=== ║  isLeadChat              : $isLeadChat');
        debugPrint(
            '=================-=== ║  is_my_message от сервера: $isMyMessageFromServer');
        debugPrint(
            '=================-=== ║  ⚠️ ВАЖНО: sender.id имеет ПРИОРИТЕТ 1!');
        debugPrint(
            '=================-=== ╚═══════════════════════════════════════════════════════╝');

        bool isMyMessage = await _determineIsMyMessage(
          messageSenderId: senderId,
          messageSenderType: senderType,
          myUserId: myUserId,
          isLeadChat: isLeadChat,
          isMyMessageFromServer: isMyMessageFromServer,
          debugContext: 'chat.message',
        );

        debugPrint(
            '=================-=== ╔═══════════════════════════════════════════════════════╗');
        debugPrint(
            '=================-=== ║  ✅✅✅ ИТОГОВОЕ РЕШЕНИЕ: isMyMessage = $isMyMessage ║');
        debugPrint(
            '=================-=== ╚═══════════════════════════════════════════════════════╝');

        // 8. Создаём модель сообщения
        ForwardedMessage? forwardedMessage;
        if (messageData['forwarded_message'] != null) {
          try {
            forwardedMessage =
                ForwardedMessage.fromJson(messageData['forwarded_message']);
          } catch (e) {
            debugPrint(
                '=================-=== Ошибка парсинга forwarded_message: $e');
          }
        }

        String? resolvedSenderName = senderName;
        if (resolvedSenderName != null && resolvedSenderName.trim().isEmpty) {
          resolvedSenderName = null;
        }
        final fallbackCompanionName =
            (_cachedCompanionName != null && _cachedCompanionName!.isNotEmpty)
                ? _cachedCompanionName!
                : (_isGroupChat == true
                    ? ''
                    : (widget.chatItem.name.isNotEmpty
                        ? widget.chatItem.name
                        : ''));

        final msg = Message(
          id: messageId ?? -1, // -1 — маркер ошибки
          text: text ??
              (type == 'voice' ? 'Голосовое сообщение' : type ?? 'Сообщение'),
          type: type,
          createMessateTime: createdAt ?? DateTime.now().toIso8601String(),
          isMyMessage: isMyMessage,
          senderName:
              resolvedSenderName ?? (isMyMessage ? 'Вы' : fallbackCompanionName),
          filePath: filePath,
          duration: voiceDuration != null
              ? Duration(
                  seconds:
                      double.tryParse(voiceDuration.toString())?.round() ?? 0)
              : Duration.zero,
          forwardedMessage: forwardedMessage,
          // isRead: true, // если нужно — можно добавить логику
        );

        debugPrint(
            '=================-=== Создано сообщение → id: ${msg.id} | isMyMessage: ${msg.isMyMessage} | type: ${msg.type}');

        // 9. Добавляем в UI
        if (mounted) {
          context.read<MessagingCubit>().updateMessageFromSocket(msg);
          debugPrint(
              '=================-=== Сообщение добавлено в UI через MessagingCubit');
        }

        // 10. Звук только для входящих
        if (!msg.isMyMessage) {
          try {
            await _audioPlayer.setAsset('assets/audio/get.mp3');
            await _audioPlayer.play();
            debugPrint(
                '=================-=== Воспроизведён звук входящего сообщения');
          } catch (e) {
            debugPrint(
                '=================-=== Не удалось воспроизвести звук: $e');
          }
        } else {
          debugPrint('=================-=== Звук пропущен — это моё сообщение');
        }

        // 11. Скролл вниз
        _scrollToBottom();

        // 12. Фоновая синхронизация (опционально)
        try {
          await context
              .read<MessagingCubit>()
              .syncMessagesInBackground(widget.chatId);
          debugPrint('=================-=== Фоновая синхронизация запущена');
        } catch (e) {
          debugPrint('=================-=== Ошибка фоновой синхронизации: $e');
        }

        debugPrint(
            '=================-=== ╚══════ chat.message обработан успешно ══════╝');
      } catch (e, stackTrace) {
        debugPrint(
            '=================-=== ╔══════ ОШИБКА В ОБРАБОТЧИКЕ chat.message ══════╗');
        debugPrint('=================-=== Ошибка: $e');
        debugPrint('=================-=== StackTrace:\n$stackTrace');
        debugPrint(
            '=================-=== ╚══════════════════════════════════════════════╝');
      }
    });
    debugPrint(
        '=================-=== ✅✅✅ CHAT_SMS: chat.message listener registered');
    debugPrint(
        '=================-=== 🎯🎯🎯 CHAT_SMS: Setting up USER channel subscription...');
    final userId = prefs.getString('unique_id') ?? '';
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
      debugPrint('✅ Обновлено имя собеседника из chat.updated: $extractedName');
    }

    // ✅ Если chat.message не пришёл, подстрахуемся lastMessage из chat.updated
    final lastMessage = chatObj?['lastMessage'];
    if (lastMessage is Map) {
      final rawMessageId = lastMessage['id'];
      final messageId = rawMessageId is int
          ? rawMessageId
          : int.tryParse(rawMessageId?.toString() ?? '');

      if (messageId != null) {
        bool alreadyExists = false;
        final state = context.read<MessagingCubit>().state;
        if (state is MessagesLoadedState) {
          alreadyExists = state.messages.any((msg) => msg.id == messageId);
        } else if (state is PinnedMessagesState) {
          alreadyExists = state.messages.any((msg) => msg.id == messageId);
        } else if (state is EditingMessageState) {
          alreadyExists = state.messages.any((msg) => msg.id == messageId);
        }

        if (!alreadyExists) {
          bool? isMyMessageFromServer;
          final isMyMsgValue = lastMessage['is_my_message'];
          if (isMyMsgValue is bool) {
            isMyMessageFromServer = isMyMsgValue;
          } else if (isMyMsgValue is int) {
            isMyMessageFromServer = isMyMsgValue == 1;
          } else if (isMyMsgValue is String) {
            isMyMessageFromServer =
                isMyMsgValue.toLowerCase() == 'true' || isMyMsgValue == '1';
          }

          final senderId = lastMessage['sender']?['id']?.toString();
          final senderType = lastMessage['sender']?['type']?.toString();
          final isLeadChat = widget.endPointInTab == 'lead';

          final isMyMessage = await _determineIsMyMessage(
            messageSenderId: senderId,
            messageSenderType: senderType,
            myUserId: myUserId,
            isLeadChat: isLeadChat,
            isMyMessageFromServer: isMyMessageFromServer,
            debugContext: 'user_channel.chat.updated',
          );

          final fallbackName = extractedName ??
              _cachedCompanionName ??
              (_isGroupChat == true
                  ? ''
                  : (widget.chatItem.name.isNotEmpty
                      ? widget.chatItem.name
                      : ''));

          final newMessage = Message(
            id: messageId,
            text: lastMessage['text'] ?? '',
            type: lastMessage['type'] ?? 'text',
            filePath: lastMessage['file_path'],
            isMyMessage: isMyMessage,
            createMessateTime: lastMessage['created_at'] ??
                DateTime.now().toIso8601String(),
            senderName: isMyMessage ? 'Вы' : fallbackName,
            duration: Duration(
              seconds: lastMessage['voice_duration'] != null
                  ? double.tryParse(lastMessage['voice_duration'].toString())
                          ?.round() ??
                      0
                  : 0,
            ),
            isPinned: lastMessage['is_pinned'] ?? false,
            isChanged: lastMessage['is_changed'] ?? false,
            isNote: lastMessage['is_note'] ?? false,
          );

          if (mounted) {
            context.read<MessagingCubit>().updateMessageFromSocket(newMessage);
          }

          if (!isMyMessage) {
            try {
              await _audioPlayer.setAsset('assets/audio/get.mp3');
              await _audioPlayer.play();
            } catch (e) {
              // ignore
            }
          }
        }
      }
    }
  } catch (e, stack) {
    debugPrint('❌ Ошибка парсинга chat.updated: $e');
  }
});
      debugPrint(
          '=================-=== ✅✅✅ CHAT_SMS: User channel listener registered');
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.pixels,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onSendInButton(
      String messageText, String? replyMessageId) async {
    if (messageText.trim().isNotEmpty) {
      try {
        final localMessage = Message(
          id: -DateTime.now().millisecondsSinceEpoch,
          text: messageText,
          type: 'text',
          createMessateTime: DateTime.now().add(Duration(hours: 0)).toString(),
          isMyMessage: true,
          senderName: '',
        );

        context.read<MessagingCubit>().addLocalMessage(localMessage);

        await _playSound();

        _messageController.clear();

        await widget.apiService.sendMessage(
          widget.chatId,
          messageText.trim(),
          replyMessageId: replyMessageId,
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
    final source = await _showPickerDialog();
    if (source == null) return;

    if (source == 'gallery') {
      final XFile? image =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        _handlePickedFile(image.path, image.name);
      }
    } else if (source == 'file') {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result != null && result.files.single.path != null) {
        _handlePickedFile(result.files.single.path!, result.files.single.name);
      }
    }
  }

  Future<String?> _showPickerDialog() async {
    return await showModalBottomSheet<String>(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF1E1E1E)),
                title: Text(
                  'Выбрать из галереи',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading:
                    Icon(Icons.insert_drive_file, color: Color(0xFF1E1E1E)),
                title: Text(
                  'Выбрать файл',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _handlePickedFile(String path, String name) async {
    final localMessage = Message(
      id: -DateTime.now().millisecondsSinceEpoch,
      text: name,
      type: 'file',
      createMessateTime: DateTime.now().add(Duration(hours: -0)).toString(),
      isMyMessage: true,
      senderName: "Вы",
      filePath: path,
    );

    context.read<MessagingCubit>().addLocalMessage(localMessage);
    await _playSound();

    await widget.apiService.sendChatFile(widget.chatId, path);
    context.read<ListenSenderFileCubit>().updateValue(false);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final viewportOffset = position.pixels;
      final viewportExtent = position.viewportDimension;
      for (final entry in _messagePositions.entries) {
        if (viewportOffset < entry.value &&
            entry.value < viewportOffset + viewportExtent) {
          setState(() {
            _currentDate = entry.key;
          });
          break;
        }
      }
    }
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    socketClient.dispose();
    _focusNode.dispose();

    // ✅ ШАГ 6: Помечаем сообщения как прочитанные на сервере
    // Это гарантирует, что сервер знает, что пользователь прочитал все сообщения в этом чате
    // После этого сервер будет правильно отправлять счетчик непрочитанных (начиная с 1 для новых сообщений)
    _markMessagesAsReadOnExit();

    // ✅ ШАГ 7: Обнуляем счетчик непрочитанных сообщений локально
    // Это скрывает счетчик до момента прихода нового сообщения от сервера
    _chatsBloc?.add(ResetUnreadCount(widget.chatId));

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

      if (state is MessagesLoadedState) {
        messages = state.messages;
      } else if (state is PinnedMessagesState) {
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
      } else {
        debugPrint('ChatSmsScreen: No messages to mark as read on exit');
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

extension on Key? {
  get currentContext => null;
}

final Map<String, double> _messagePositions = {};

class MessageItemWidget extends StatelessWidget {
  final Message message;
  final int chatId;
  final String endPointInTab;
  final ApiServiceDownload apiServiceDownload;
  final String baseUrl;
  final void Function(int)? onReplyTap;
  final int? highlightedMessageId;
  final void Function(bool)? onMenuStateChanged;
  final FocusNode focusNode;
  final bool isRead;
  final bool isFirstMessage;
  final String? referralBody;
  final bool? isGroupChat;

  MessageItemWidget({
    super.key,
    required this.message,
    required this.endPointInTab,
    required this.chatId,
    required this.apiServiceDownload,
    required this.baseUrl,
    this.onReplyTap,
    this.highlightedMessageId,
    this.onMenuStateChanged,
    required this.focusNode,
    required this.isRead,
    required this.isFirstMessage,
    this.referralBody,
    this.isGroupChat,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(message.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (endPointInTab == 'task' || endPointInTab == 'corporate') {
          focusNode.requestFocus();
          context.read<MessagingCubit>().setReplyMessage(message);
          return false;
        }
        return false;
      },
      child: GestureDetector(
        onLongPress: () {
          _showMessageContextMenu(context, message, focusNode);
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
    if (isFirstMessage && referralBody != null && referralBody!.isNotEmpty) {
      replyMessageText = referralBody;
    } else if (message.forwardedMessage != null) {
      replyMessageText = message.forwardedMessage!.type == 'voice'
          ? "Голосовое сообщение"
          : message.forwardedMessage!.text;
    }

    // Определяем, является ли чат лид-чатом
    final bool isLeadChat = endPointInTab == 'lead';

    switch (message.type) {
      case 'text':
        return MessageBubble(
          message: message.text,
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          senderName: message.senderName.toString(),
          replyMessage: replyMessageText,
          replyMessageId: message.forwardedMessage?.id,
          onReplyTap: (int replyMessageId) {
            onReplyTap?.call(replyMessageId);
          },
          isHighlighted: highlightedMessageId == message.id,
          isChanged: message.isChanged,
          isRead: message.isRead,
          isNote: message.isNote,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
        );
      case 'image':
        return ImageMessageBubble(
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          filePath: message.filePath ?? 'Unknown file format',
          fileName: message.text,
          message: message,
          senderName: message.senderName,
          replyMessage: replyMessageText,
          isHighlighted: highlightedMessageId == message.id,
          isRead: message.isRead,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
        );
      case 'file':
      case 'document':
        return FileMessageBubble(
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          filePath: message.filePath ?? 'Unknown file format',
          fileName: message.text,
          isHighlighted: highlightedMessageId == message.id,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
          onTap: (path) async {
            if (message.filePath != null && message.filePath!.isNotEmpty) {
              try {
                await apiServiceDownload.downloadAndOpenFile(message.filePath!);
              } catch (e) {
                if (kDebugMode) {
                  ////print('Error opening file!');
                }
              }
            } else {
              if (kDebugMode) {
                ////print('Invalid file path. Cannot open file.');
              }
            }
          },
          senderName: message.senderName,
          isRead: message.isRead,
        );
      case 'voice':
        return VoiceMessageWidget(
          message: message,
          baseUrl: baseUrl,
          isLeadChat: isLeadChat,
          isGroupChat: isGroupChat,
        );
      default:
        return SizedBox();
    }
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

    bool showReadersList = false;
    bool isSingleUserChat = message.readStatus?.read.length == 1;

    if (endPointInTab == 'lead') {
      showMenu(
        context: context,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        position: RelativeRect.fromLTRB(
          position.dx + messageBox.size.width / 2.5,
          position.dy,
          position.dx + messageBox.size.width / 2 + 1,
          position.dy + messageBox.size.height,
        ),
        items: [
          _buildMenuItem(
            icon: 'assets/icons/chats/menu_icons/copy.svg',
            text: AppLocalizations.of(context)!.translate('copy'),
            iconColor: Colors.black,
            textColor: Colors.black,
            onTap: () {
              Navigator.pop(context);
              _copyMessageToClipboard(context, message.text);
            },
          ),
        ],
      ).then((_) {
        onMenuStateChanged?.call(false);
      });
      return;
    }

    void showMenuItems() {
      final List<PopupMenuItem> menuItems = [];

      if (showReadersList) {
        menuItems.add(
          PopupMenuItem(
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                showReadersList = false;
                showMenuItems();
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.black),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.translate('back'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(
                      color: Colors.grey,
                      height: 10,
                      thickness: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        bool isUserNavigating = false;

        for (var user in message.readStatus?.read ?? []) {
          String formattedTime = user.readAt != null
              ? DateFormat('HH:mm').format(user.readAt!)
              : AppLocalizations.of(context)!.translate('unknown_time');
          menuItems.add(
            _buildMenuItemWithAvatar(
              avatarSvg: user.image,
              text: "${user.fullName} — $formattedTime",
              textColor: Colors.black,
              onTap: () async {
                if (isUserNavigating) return;
                isUserNavigating = true;
                final getChatById = await ApiService().getChatById(chatId);
                final selectedUser = getChatById.chatUsers
                    .firstWhere(
                      (chatUser) =>
                          chatUser.participant.id.toString() ==
                          user.id.toString(),
                    )
                    ?.participant;

                if (selectedUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParticipantProfileScreen(
                        userId: selectedUser.id.toString(),
                        image: selectedUser.image,
                        name: selectedUser.name,
                        email: selectedUser.email,
                        phone: selectedUser.phone,
                        login: selectedUser.login,
                        lastSeen: selectedUser.lastSeen?.toString() ??
                            AppLocalizations.of(context)!.translate('unknow'),
                        buttonChat: true,
                      ),
                    ),
                  ).then((_) {
                    isUserNavigating = false;
                  });
                } else {
                  isUserNavigating = false;
                }
              },
            ),
          );
        }

        showMenu(
          context: context,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          position: RelativeRect.fromLTRB(
            position.dx + messageBox.size.width / 2.5,
            position.dy,
            position.dx + messageBox.size.width / 2 + 1,
            position.dy + messageBox.size.height,
          ),
          items: menuItems,
        ).then((_) {
          onMenuStateChanged?.call(false);
        });
        return;
      }

      if (message.isMyMessage) {
        if (message.readStatus?.read.isNotEmpty ?? false) {
          if (isSingleUserChat) {
            User reader = message.readStatus!.read.first;
            String formattedTime = reader.readAt != null
                ? DateFormat('HH:mm').format(reader.readAt!)
                : AppLocalizations.of(context)!.translate('unknown_time');
            menuItems.add(
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.done_all,
                        color: ChatSmsStyles.messageBubbleSenderColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${reader.name} ${AppLocalizations.of(context)!.translate('read_at')} $formattedTime",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: ChatSmsStyles.messageBubbleSenderColor,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            menuItems.add(
              PopupMenuItem(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showReadersList = true;
                    showMenuItems();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.done_all,
                            color: ChatSmsStyles.messageBubbleSenderColor),
                        const SizedBox(width: 10),
                        Text(
                          "${message.readStatus!.read.length} ${AppLocalizations.of(context)!.translate('views')}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: ChatSmsStyles.messageBubbleSenderColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        } else {
          menuItems.add(
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.done, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.translate('not_read_at'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      menuItems.add(
        _buildMenuItem(
          icon: 'assets/icons/chats/menu_icons/reply.svg',
          text: AppLocalizations.of(context)!.translate('reply'),
          iconColor: Colors.black,
          textColor: Colors.black,
          onTap: () {
            Navigator.pop(context);
            focusNode.requestFocus();
            context.read<MessagingCubit>().setReplyMessage(message);
          },
        ),
      );

      menuItems.add(
        _buildMenuItem(
          icon: 'assets/icons/chats/menu_icons/pin.svg',
          text: message.isPinned
              ? AppLocalizations.of(context)!.translate('un_pin')
              : AppLocalizations.of(context)!.translate('pin'),
          iconColor: Colors.black,
          textColor: Colors.black,
          onTap: () {
            Navigator.pop(context);
            context.read<MessagingCubit>().pinMessage(message);
          },
        ),
      );

      menuItems.add(
        _buildMenuItem(
          icon: 'assets/icons/chats/menu_icons/copy.svg',
          text: AppLocalizations.of(context)!.translate('copy'),
          iconColor: Colors.black,
          textColor: Colors.black,
          onTap: () {
            Navigator.pop(context);
            _copyMessageToClipboard(context, message.text);
          },
        ),
      );

      if (message.isMyMessage) {
        menuItems.add(
          _buildMenuItem(
            icon: 'assets/icons/chats/menu_icons/edit.svg',
            text: AppLocalizations.of(context)!.translate('edit'),
            iconColor: Colors.black,
            textColor: Colors.black,
            onTap: () {
              Navigator.pop(context);
              focusNode.requestFocus();
              context.read<MessagingCubit>().startEditingMessage(message);
            },
          ),
        );

        menuItems.add(
          _buildMenuItem(
            icon: 'assets/icons/chats/menu_icons/delete-red.svg',
            text: AppLocalizations.of(context)!.translate('delete'),
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(context);
            },
          ),
        );
      }

      showMenu(
        context: context,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        position: RelativeRect.fromLTRB(
          position.dx + messageBox.size.width / 2.5,
          position.dy,
          position.dx + messageBox.size.width / 2 + 1,
          position.dy + messageBox.size.height,
        ),
        items: menuItems,
      ).then((_) {
        onMenuStateChanged?.call(false);
      });
    }

    showMenuItems();
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
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.green,
        elevation: 3,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  PopupMenuItem _buildMenuItemWithAvatar({
    required String avatarSvg,
    required String text,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            children: [
              SvgPicture.string(
                avatarSvg,
                width: 30,
                height: 30,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem _buildMenuItem({
    required String icon,
    required String text,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            children: [
              if (icon.isNotEmpty)
                SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  color: iconColor,
                ),
              if (icon.isNotEmpty) const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMessage(BuildContext context) {
    if (message.isMyMessage) {
      int messageId = message.id;

      context.read<DeleteMessageBloc>().add(DeleteMessage(messageId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('sms_deletes_successfully'),
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
          backgroundColor: Colors.green,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .translate('cannot_someone_delete_sms'),
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
  }
}
