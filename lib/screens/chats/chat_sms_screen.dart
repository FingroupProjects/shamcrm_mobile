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
  final String? chatUniqueId; // Новое поле для unique_id
  final String endPointInTab;
  final bool canSendMessage;
  final ApiService apiService = ApiService();
  final ApiServiceDownload apiServiceDownload = ApiServiceDownload();

  ChatSmsScreen({
    super.key,
    required this.chatItem,
    required this.chatId,
    this.chatUniqueId, // Опциональный параметр
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
  String? integrationUsername; // Новое поле для хранения username
  String? channelName; // Новое поле для хранения channel.name
  bool _hasMarkedMessagesAsRead = false;
  bool _isRecordingInProgress = false; // Флаг для отслеживания состояния записи
  String? referralBody; // Новое поле для хранения referral_body всего чата
  ChatsBloc? _chatsBloc; // Сохраняем ссылку на bloc для использования в dispose


  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    context.read<MessagingCubit>().getMessages(widget.chatId, search: query);
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
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    
    // Сохраняем ссылку на ChatsBloc для использования в dispose
    _chatsBloc = context.read<ChatsBloc>();

    // Сбрасываем состояния
    context.read<ListenSenderFileCubit>().updateValue(false);
    context.read<ListenSenderVoiceCubit>().updateValue(false);
    context.read<ListenSenderTextCubit>().updateValue(false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeServices();
    });
  }


// Также добавьте метод для повторной попытки
  Future<void> _retryInitialization() async {
    try {
      await _initializeBaseUrl();
      context.read<MessagingCubit>().getMessages(widget.chatId);
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

  Future<void> _initializeBaseUrl() async {
    debugPrint('Initializing baseUrl...');

    final prefs = await SharedPreferences.getInstance();

    // Получаем домены из той же логики, что используется в сокете
    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    // Проверяем домен для email-верификации
    String? verifiedDomain = await ApiService().getVerifiedDomain();
    debugPrint('BaseUrl init - enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');

    // Если домены отсутствуют, используем verifiedDomain
    if (enteredMainDomain == null || enteredDomain == null) {
      if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
        enteredMainDomain = verifiedDomain.split('-back.').last;
        enteredDomain = verifiedDomain.split('-back.').first;
        debugPrint('BaseUrl init - Using verifiedDomain: $verifiedDomain, parsed mainDomain=$enteredMainDomain, domain=$enteredDomain');

        // Принудительно сохраняем в SharedPreferences
        await prefs.setString('enteredMainDomain', enteredMainDomain);
        await prefs.setString('enteredDomain', enteredDomain);
      } else {
        throw Exception('Cannot determine domain for API calls');
      }
    }

    // Формируем baseUrl по той же логике, что и сокет
    baseUrl = 'https://$enteredDomain-back.$enteredMainDomain';
    debugPrint('BaseUrl initialized: $baseUrl');

    // ВАЖНО: Сохраняем для использования во ВСЕХ экземплярах ApiService
    await prefs.setString('cached_base_url', '$baseUrl/api');
    debugPrint('Cached baseUrl for all ApiService instances: $baseUrl/api');
  }

  Future<void> _initializeServices() async {
    try {
      debugPrint('ChatSmsScreen: Starting initialization...');

      // Шаг 1: Проверяем и инициализируем домены
      await _ensureDomainConfiguration();

      // Шаг 2: Инициализируем ApiService
      await apiService.initialize();

      // Шаг 3: Получаем базовый URL
      baseUrl = await apiService.getDynamicBaseUrl();
      debugPrint('ChatSmsScreen: BaseURL initialized: $baseUrl');

      // Шаг 4: Инициализируем сокет
      await _initializeSocket();

      // Шаг 5: Загружаем сообщения
      context.read<MessagingCubit>().getMessagesWithFallback(widget.chatId);
      _scrollToBottom();

      // Шаг 6: Загружаем интеграцию для лидов
      if (widget.endPointInTab == 'lead') {
        await _fetchIntegration();
      }

      debugPrint('ChatSmsScreen: Initialization completed successfully');
    } catch (e, stackTrace) {
      debugPrint('ChatSmsScreen: Initialization error: $e');
      debugPrint('StackTrace: $stackTrace');

      // Показываем ошибку пользователю, но пытаемся загрузить хотя бы сообщения
      if (mounted) {
        _showInitializationError(e.toString());

        // Попытка загрузить сообщения даже при ошибке инициализации
        try {
          context.read<MessagingCubit>().getMessagesWithFallback(widget.chatId);
        } catch (e2) {
          debugPrint('ChatSmsScreen: Failed to load messages after init error: $e2');
        }
      }
    }
  }

  Future<void> _ensureDomainConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    // Проверяем текущие домены
    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    // Проверяем email верификацию
    String? verifiedDomain = await ApiService().getVerifiedDomain();

    debugPrint('Domain check: enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');

    // Если домены не настроены, используем verifiedDomain или QR данные
    if ((enteredMainDomain == null || enteredDomain == null) && verifiedDomain != null) {
      // Парсим verifiedDomain
      if (verifiedDomain.contains('-back.')) {
        final parts = verifiedDomain.split('-back.');
        enteredDomain = parts[0];
        enteredMainDomain = parts[1];
      } else {
        // Fallback для других форматов
        enteredDomain = 'default';
        enteredMainDomain = verifiedDomain;
      }

      // Сохраняем распарсенные домены
      await prefs.setString('enteredMainDomain', enteredMainDomain);
      await prefs.setString('enteredDomain', enteredDomain);

      debugPrint('Domain configured from verifiedDomain: $enteredDomain-back.$enteredMainDomain');
    } else if (enteredMainDomain == null || enteredDomain == null) {
      // Проверяем QR данные
      final qrData = await ApiService().getQrData();
      if (qrData['domain'] != null && qrData['mainDomain'] != null) {
        await prefs.setString('enteredDomain', qrData['domain']!);
        await prefs.setString('enteredMainDomain', qrData['mainDomain']!);
        debugPrint('Domain configured from QR data: ${qrData['domain']}-back.${qrData['mainDomain']}');
      } else {
        throw Exception('Не удалось определить домен для подключения');
      }
    }
  }

  Future<void> _initializeSocket() async {
    try {
      debugPrint('🔌 ChatSmsScreen: Starting socket initialization...');
      // ИСПРАВЛЕНИЕ: Добавлен await для ожидания завершения инициализации сокета
      await setUpServices();
      debugPrint('✅ ChatSmsScreen: Socket initialization completed');
    } catch (e) {
      debugPrint('❌ ChatSmsScreen: Socket initialization error: $e');
      // Сокет не критичен для работы чата, продолжаем без него
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

    // Получаем verifiedDomain
    String? verifiedDomain = await ApiService().getVerifiedDomain();

    if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
      // Парсим домен
      String enteredMainDomain = verifiedDomain.split('-back.').last;
      String enteredDomain = verifiedDomain.split('-back.').first;

      // Принудительно сохраняем в SharedPreferences
      await prefs.setString('enteredMainDomain', enteredMainDomain);
      await prefs.setString('enteredDomain', enteredDomain);

      debugPrint('Force initialized domain: $enteredDomain-back.$enteredMainDomain');
    }
  }
  Future<void> _markMessagesAsRead() async {
    // Проверяем, не был ли метод уже вызван
    if (_hasMarkedMessagesAsRead) {
      if (kDebugMode) {
        //print('ChatSmsScreen: _markMessagesAsRead уже вызван, пропускаем');
      }
      return;
    }

    final state = context.read<MessagingCubit>().state;
    // Лог для отладки текущего состояния
    if (kDebugMode) {
      //print('ChatSmsScreen: Текущее состояние в _markMessagesAsRead: $state');
    }
    List<Message> messages = [];
    // Проверяем оба состояния: MessagesLoadedState и PinnedMessagesState
    if (state is MessagesLoadedState) {
      messages = state.messages;
    } else if (state is PinnedMessagesState) {
      messages = state.messages;
    }

    // Лог для количества сообщений
    if (kDebugMode) {
      //print('ChatSmsScreen: Количество сообщений: ${messages.length}');
    }

    // Проверяем, есть ли непрочитанные сообщения
    bool hasUnreadMessages = messages.any((msg) => !msg.isRead);
    if (messages.isNotEmpty && hasUnreadMessages) {
      final latestMessageId = messages.first.id;
      // Лог для chatId и messageId
      if (kDebugMode) {
        //print('ChatSmsScreen: Пометка сообщений как прочитанных, chatId: ${widget.chatId}, latestMessageId: $latestMessageId');
      }
      try {
        await widget.apiService.readMessages(widget.chatId, latestMessageId);
        if (kDebugMode) {
          //print('ChatSmsScreen: Сообщения успешно помечены как прочитанные');
        }
        // Устанавливаем флаг, чтобы предотвратить повторные вызовы
        _hasMarkedMessagesAsRead = true;
      } catch (e) {
        // Лог для ошибок API
        if (kDebugMode) {
          //print('ChatSmsScreen: Ошибка при пометке сообщений как прочитанных: $e');
        }
        // ScaffoldMessenger.of(context).showSnackBar(
        //   // SnackBar(
        //   //   content: Text(
        //   //     AppLocalizations.of(context)!.translate('error_marking_messages_read'),
        //   //     style: const TextStyle(
        //   //       fontFamily: 'Gilroy',
        //   //       fontSize: 16,
        //   //       fontWeight: FontWeight.w500,
        //   //       color: Colors.white,
        //   //     ),
        //   //   ),
        //   //   backgroundColor: Colors.red,
        //   //   duration: const Duration(seconds: 3),
        //   // ),
        // );
      }
    } else {
      if (kDebugMode) {
        //print('ChatSmsScreen: Нет непрочитанных сообщений или список пуст');
      }
      // Устанавливаем флаг, даже если сообщений нет, чтобы избежать повторных проверок
      _hasMarkedMessagesAsRead = true;
    }
  }
// Обновлённый метод для получения интеграции в ChatSmsScreen



// Исправленный метод для получения интеграции в ChatSmsScreen
  Future<void> _fetchIntegration() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      debugPrint('ChatSmsScreen: Fetching integration data for chatId: ${widget.chatId}');

      final chatData = await widget.apiService.getChatById(widget.chatId);
      debugPrint('ChatSmsScreen: Chat data received');

      // Сохраняем referralBody из chatData
      setState(() {
        referralBody = chatData.referralBody;
        prefs.setString('referral_body_${widget.chatId}', referralBody ?? '');
      });

      IntegrationForLead? integration;
      try {
        integration = await widget.apiService.getIntegrationForLead(widget.chatId);
        debugPrint('ChatSmsScreen: Integration data received: ${integration.username}');
      } catch (integrationError) {
        debugPrint('ChatSmsScreen: Integration request failed: $integrationError');
        integration = null;
      }

      setState(() {
        if (integration != null) {
          integrationUsername = integration.username ??
              AppLocalizations.of(context)!.translate('unknown_channel');
          channelName = _determineChannelType(integration) ?? chatData.channelName;
        } else {
          integrationUsername = chatData.name.isNotEmpty
              ? chatData.name
              : AppLocalizations.of(context)!.translate('unknown_channel');
          channelName = chatData.channelName;
        }

        prefs.setString('integration_username_${widget.chatId}', integrationUsername!);
        prefs.setString('channel_name_${widget.chatId}', channelName!);
      });

      debugPrint('ChatSmsScreen: Integration configured - username: $integrationUsername, channel: $channelName');

    } catch (e) {
      debugPrint('ChatSmsScreen: Error fetching integration data: $e');

      setState(() {
        integrationUsername = prefs.getString('integration_username_${widget.chatId}') ??
            AppLocalizations.of(context)!.translate('unknown_channel');
        channelName = prefs.getString('channel_name_${widget.chatId}') ?? 'unknown';
        referralBody = prefs.getString('referral_body_${widget.chatId}');
      });

      debugPrint('ChatSmsScreen: Using cached integration data');
    }
  }

// Вспомогательный метод для определения типа канала из интеграции
  String? _determineChannelType(IntegrationForLead integration) {
    // Здесь можно определить тип канала на основе данных интеграции
    // Примеры типов: telegram, whatsapp, instagram, facebook, website

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

    // По умолчанию возвращаем общий тип
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

  Future<void> _showDatePicker(BuildContext context, List<Message> messages) async {
    final DateTime currentDate = DateTime.now(); // 16:25, 27 июня 2025
    DateTime? selectedDate;

    // Преобразуем сообщения в карту дат
    final Map<DateTime, List> events = {};
    ////print('Начало обработки сообщений. Количество сообщений: ${messages.length}');
    for (var message in messages) {
      ////print('Обработка сообщения: $message');
      try {
        final date = DateTime.parse(message.createMessateTime).toLocal();
        ////print('Парсинг даты: ${message.createMessateTime} -> $date');
        final eventDate = DateTime(date.year, date.month, date.day); // Нормализуем до начала дня
        ////print('Сформирована дата для события: $eventDate');
        if (events[eventDate] == null) {
          ////print('Добавление нового события для даты: $eventDate');
          events[eventDate] = [true]; // Добавляем индикатор события
        } else {
          ////print('Событие для даты $eventDate уже существует');
        }
      } catch (e) {
        ////print('Ошибка парсинга даты ${message.createMessateTime}: $e');
      }
    }
    ////print('Карта событий после обработки: $events');

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
                  height: 450, // Увеличиваем высоту для корректного отображения дней недели
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
                      outsideTextStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
                    ),
                    // Добавляем стиль для дней недели чтобы они не обрезались
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
                      titleTextStyle: const TextStyle(fontSize: 18, fontFamily: 'Gilroy'),
                      // Добавляем форматирование заголовка для заглавной буквы
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
                        ////print('Проверка даты $date, события: $events');
                        if (events.isNotEmpty) {
                          ////print('Отображение точки для даты $date');
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
                        ////print('Нет событий для даты $date');
                        return null;
                      },
                    ),
                    eventLoader: (day) {
                      final normalizedDay = DateTime(day.year, day.month, day.day); // Нормализуем день
                      ////print('Загрузка событий для дня $normalizedDay: ${events[normalizedDay] ?? []}');
                      return events[normalizedDay] ?? [];
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      final index = _findMessageIndexByDate(messages, selectedDay);
                      ////print('Выбрана дата $selectedDay, индекс сообщения: $index');
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
      final messageDate = DateTime.parse(messages[i].createMessateTime).toLocal();
      if (isSameDay(messageDate, targetDate)) {
        return i; // Возвращаем индекс последнего сообщения за дату
      }
    }
    return -1; // Если сообщений нет
  }

  void _scrollToMessageIndex(DateTime selectedDate) {
    final state = context.read<MessagingCubit>().state;
    if (state is MessagesLoadedState || state is PinnedMessagesState) {
      final messages = state is MessagesLoadedState
          ? state.messages
          : (state as PinnedMessagesState).messages;

      final messageIndex = _findMessageIndexByDate(messages, selectedDate);

      if (messageIndex != -1) {
        debugPrint('Scrolling to index: $messageIndex for date: ${formatDate(selectedDate)}');
        _scrollControllerMessage.scrollTo(
          index: messageIndex,
          alignment: 0.0, // Позиционируем сообщение вверху экрана
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
    // //print('Avatar path: $avatar'); // Отладочный вывод
    bool isSupportAvatar = avatar == 'assets/icons/Profile/support_chat.png';
    bool isTaskSection = widget.endPointInTab == 'task'; // Проверка на task

    // Для endPointInTab == 'task' используем AvatarTask.png, если avatar не SVG
    if (isTaskSection && !avatar.contains('<svg')) {
      return CircleAvatar(
        backgroundImage: AssetImage('assets/images/AvatarTask.png'),
        radius: ChatSmsStyles.avatarRadius,
        backgroundColor: Colors.white,
        onBackgroundImageError: (exception, stackTrace) {
          // //print('Error loading asset image: assets/images/AvatarTask.png, $exception');
        },
      );
    }

    // Обработка SVG-аватарок
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

    // Обработка остальных случаев (локальные изображения)
    try {
      return CircleAvatar(
        backgroundImage: AssetImage(avatar),
        radius: ChatSmsStyles.avatarRadius,
        backgroundColor: isSupportAvatar ? Colors.black : Colors.white,
        onBackgroundImageError: (exception, stackTrace) {
          // //print('Error loading asset image: $avatar, $exception');
        },
      );
    } catch (e) {
      // //print('Fallback avatar due to error: $e');
      return CircleAvatar(
        backgroundImage: AssetImage(isTaskSection ? 'assets/images/AvatarTask.png' : 'assets/images/AvatarChat.png'),
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
  bool isSupportChat = widget.chatItem.avatar == 'assets/icons/Profile/image.png';
  return BlocListener<MessagingCubit, MessagingState>(
    // Добавлен BlocListener для вызова _markMessagesAsRead только при первой загрузке
    listener: (context, state) {
      if (kDebugMode) {
        //print('ChatSmsScreen: Слушатель MessagingCubit, текущее состояние: $state');
      }
      // Вызываем _markMessagesAsRead только для MessagesLoadedState или PinnedMessagesState
      if ((state is MessagesLoadedState || state is PinnedMessagesState) && !_hasMarkedMessagesAsRead) {
        _markMessagesAsRead();
      }
    },
    child: BlocListener<DeleteMessageBloc, DeleteMessageState>(
      listener: (context, state) {
        if (state is DeleteMessageSuccess) {
          context.read<MessagingCubit>().getMessages(widget.chatId);
          if (widget.endPointInTab == 'task' || widget.endPointInTab == 'corporate') {
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
                    context.read<MessagingCubit>().getMessages(widget.chatId);
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
                hintText: AppLocalizations.of(context)!.translate('search_appbar'),
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.black, fontFamily: 'Gilroy'),
              ),
              onChanged: _onSearchChanged,
            )
                : GestureDetector(
              onTap: (widget.endPointInTab == 'corporate')
                  ? null  // Блокировка нажатия для corporate
                  : isSupportChat
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
                            builder: (context) => UserProfileScreen(chatId: widget.chatId),
                          ),
                        );
                      } else if (widget.endPointInTab == 'task') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskByIdScreen(chatId: widget.chatId),
                          ),
                        );
                      } else if (widget.endPointInTab == 'corporate') {
                        // Этот блок не выполнится из-за проверки выше, но оставляем для полноты
                        final getChatById = await widget.apiService.getChatById(widget.chatId);
                        if (getChatById.chatUsers.length == 2 && getChatById.group == null) {
                          String userIdCheck = '';
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          userIdCheck = prefs.getString('userID') ?? '';
                          final participant = getChatById.chatUsers
                              .firstWhere((user) => user.participant.id.toString() != userIdCheck)
                              .participant;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParticipantProfileScreen(
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
                          ? AppLocalizations.of(context)!.translate('support_chat_name')
                          : widget.chatItem.name.isEmpty
                          ? AppLocalizations.of(context)!.translate('no_name')
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
                        ? AppLocalizations.of(context)!.translate('not_premission_to_send_sms')
                        : AppLocalizations.of(context)!.translate('24_hour_leads'),
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


// Модифицируйте messageListUi для добавления кнопки повтора
  Widget messageListUi() {
    return BlocBuilder<MessagingCubit, MessagingState>(
      builder: (context, state) {
        debugPrint('messageListUi: Building with state: $state');

        // НОВОЕ: Обработка частичной ошибки
        if (state is MessagesPartialErrorState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
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
                        context.read<MessagingCubit>().getMessagesWithFallback(widget.chatId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        // Показываем пустой чат
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
          // Специальная обработка ошибки с null URL
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
                      context.read<MessagingCubit>().getMessagesWithFallback(widget.chatId);
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
                    context.read<MessagingCubit>().getMessagesWithFallback(widget.chatId);
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

          debugPrint('Rendering messageListUi: integrationUsername=$integrationUsername, channelName=$channelName'); // Лог для отладки

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
                          referralBody: referralBody, // Передаем
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
                    if (widget.endPointInTab == 'lead' && integrationUsername != null)
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
            createMessateTime: DateTime.now().add(Duration(hours: -0)).toString(),
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
    debugPrint('🔌 ChatSmsScreen: setUpServices() STARTED');
    
    // Проверяем, что baseUrl инициализирован
    if (baseUrl.isEmpty || baseUrl == 'null') {
      debugPrint('BaseURL not initialized, fetching...');
      baseUrl = await apiService.getDynamicBaseUrl();

      if (baseUrl.isEmpty || baseUrl == 'null') {
        debugPrint('❌ Failed to get baseURL, aborting socket setup');
        return;
      }
    }

    debugPrint('✅ BaseURL for socket: $baseUrl');

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      debugPrint('❌ Error: Token is null or empty');
      return;
    }
    debugPrint('✅ Token retrieved successfully');

    // Проверяем домены для старой логики
    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    // Проверяем домен для email-верификации
    String? verifiedDomain = await ApiService().getVerifiedDomain();
    debugPrint('📡 Domain check: enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');

    // ИСПРАВЛЕНИЕ: Используем домен из baseUrl если verifiedDomain null
    if (enteredMainDomain == null || enteredDomain == null) {
      if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
        // Для email-верификации используем verifiedDomain
        enteredMainDomain = verifiedDomain.split('-back.').last;
        enteredDomain = verifiedDomain.split('-back.').first;
        debugPrint('✅ Using verifiedDomain: $verifiedDomain → mainDomain=$enteredMainDomain, domain=$enteredDomain');
      } else if (baseUrl.isNotEmpty && baseUrl != 'null') {
        // Извлекаем домен из baseUrl
        // baseUrl формат: https://fingroupcrm-back.shamcrm.com/api
        final urlPattern = RegExp(r'https://(.+?)-back\.(.+?)(/|$)');
        final match = urlPattern.firstMatch(baseUrl);
        if (match != null) {
          enteredDomain = match.group(1);
          enteredMainDomain = match.group(2);
          debugPrint('✅ Extracted from baseUrl: domain=$enteredDomain, mainDomain=$enteredMainDomain');
          
          // Сохраняем извлеченные значения
          await prefs.setString('enteredMainDomain', enteredMainDomain!);
          await prefs.setString('enteredDomain', enteredDomain!);
      } else {
          debugPrint('❌ Failed to parse baseUrl, aborting socket setup');
          return;
        }
      } else {
        debugPrint('❌ No domain configuration available, aborting socket setup');
        return;
      }
    }

    debugPrint('✅ Final domains for socket: $enteredDomain-back.$enteredMainDomain');
    
    final socketUrl = 'wss://soketi.$enteredMainDomain/app/app-key';
    final authUrl = 'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth';
    
    debugPrint('🔌 Socket URL: $socketUrl');
    debugPrint('🔌 Auth URL: $authUrl');

    final customOptions = PusherChannelsOptions.custom(
      uriResolver: (metadata) => Uri.parse(socketUrl),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    socketClient = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint('❌ Socket connection error: $exception');
        Future.delayed(Duration(seconds: 5), () async {
          try {
            await socketClient.connect();
            debugPrint('🔄 Socket reconnect attempted');
          } catch (e) {
            debugPrint('❌ Error reconnecting to socket: $e');
          }
        });
        refresh();
      },
      minimumReconnectDelayDuration: const Duration(seconds: 1),
    );

    // Используем uniqueId если доступен, иначе chatId
    final chatIdentifier = widget.chatUniqueId ?? widget.chatId.toString();
    final channelName = 'presence-chat.$chatIdentifier';
    
    debugPrint('📱 Chat identifier for socket: $chatIdentifier (uniqueId: ${widget.chatUniqueId}, chatId: ${widget.chatId})');
    debugPrint('📢 Channel name: $channelName');

    final myPresenceChannel = socketClient.presenceChannel(
      channelName,
      authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
        authorizationEndpoint: Uri.parse(authUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': '$enteredDomain-back',
        },
        onAuthFailed: (exception, trace) {
          debugPrint('❌ Auth failed for $channelName: $exception');
        },
      ),
    );

    socketClient.onConnectionEstablished.listen((_) {
      debugPrint('✅ Socket connected successfully for chatIdentifier: $chatIdentifier');
      myPresenceChannel.subscribeIfNotUnsubscribed();
      debugPrint('✅ Subscribed to channel: $channelName');
    });

    myPresenceChannel.bind('pusher:subscription_succeeded').listen((event) {
      debugPrint('✅✅✅ CHAT_SMS: Successfully subscribed to $channelName');
      debugPrint('✅✅✅ CHAT_SMS: Subscription data: ${event.data}');
    });

    myPresenceChannel.bind('pusher:subscription_error').listen((event) {
      debugPrint('❌❌❌ CHAT_SMS: Subscription error for $channelName: ${event.data}');
    });

    // КРИТИЧНО: Подписываемся на ВСЕ события для отладки
    myPresenceChannel.bind('pusher:member_added').listen((event) {
      debugPrint('👤👤👤 CHAT_SMS: Member added: ${event.data}');
    });

    myPresenceChannel.bind('pusher:member_removed').listen((event) {
      debugPrint('👤👤👤 CHAT_SMS: Member removed: ${event.data}');
    });

    // КРИТИЧНО: Подписываемся на событие chat.updated (приходит при новых сообщениях)
    debugPrint('🎯🎯🎯 CHAT_SMS: Registering chat.updated listener for $channelName...');
    
    myPresenceChannel.bind('chat.updated').listen((event) async {
      debugPrint('🔔🔔🔔🔔🔔 CHAT_SMS: ===== RECEIVED chat.updated EVENT =====');
      debugPrint('🔔🔔🔔 CHAT_SMS: Channel: $channelName');
      debugPrint('🔔🔔🔔 CHAT_SMS: Event type: ${event.name}');
      debugPrint('🔔🔔🔔 CHAT_SMS: Event data: ${event.data}');
      debugPrint('🔔🔔🔔 CHAT_SMS: Widget mounted: $mounted');
      debugPrint('🔔🔔🔔 CHAT_SMS: Current chatId: ${widget.chatId}');
      
      try {
        final chatData = json.decode(event.data);
        final eventChatId = chatData['chat']?['id'];
        
        debugPrint('🔔🔔🔔 CHAT_SMS: Event chatId: $eventChatId, our chatId: ${widget.chatId}');
        
        // Проверяем что событие для нашего чата
        if (eventChatId != widget.chatId) {
          debugPrint('⚠️⚠️⚠️ CHAT_SMS: Event is for different chat, ignoring');
          return;
        }
        
        // Просто перезагружаем сообщения когда приходит обновление
        if (mounted) {
          debugPrint('🔔🔔🔔 CHAT_SMS: ✅ RELOADING messages NOW...');
          context.read<MessagingCubit>().getMessages(widget.chatId);
          
          // Прокручиваем вниз после небольшой задержки
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _scrollToBottom();
              debugPrint('🔔🔔🔔 CHAT_SMS: ✅ Scrolled to bottom');
            }
          });
          
          // Воспроизводим звук если сообщение не от меня
          final lastMessage = chatData['chat']?['lastMessage'];
          final isMyMessage = lastMessage?['is_my_message'] ?? false;
          
          debugPrint('🔔🔔🔔 CHAT_SMS: Last message is mine: $isMyMessage');
          
          if (!isMyMessage) {
            try {
              await _audioPlayer.setAsset('assets/audio/get.mp3');
              await _audioPlayer.play();
              debugPrint('🔔🔔🔔 CHAT_SMS: ✅ Played notification sound');
            } catch (e) {
              debugPrint('⚠️ CHAT_SMS: Could not play sound: $e');
            }
          }
          
          debugPrint('✅✅✅ CHAT_SMS: ===== chat.updated handled successfully =====');
        } else {
          debugPrint('⚠️⚠️⚠️ CHAT_SMS: Widget NOT MOUNTED, skipping reload');
        }
      } catch (e, stackTrace) {
        debugPrint('❌❌❌ CHAT_SMS: Error handling chat.updated: $e');
        debugPrint('❌❌❌ CHAT_SMS: StackTrace: $stackTrace');
      }
    });
    
    debugPrint('✅✅✅ CHAT_SMS: chat.updated listener registered');

    chatSubscribtion = myPresenceChannel.bind('chat.message').listen((event) async {
      debugPrint('📨📨📨 CHAT_SMS: Received chat.message event: ${event.data}');
      try {
        if (event.data == null || event.data.isEmpty) {
          debugPrint('Error: chat.message event data is null or empty');
          return;
        }

        debugPrint('Raw event data type: ${event.data.runtimeType}');
        debugPrint('Raw event data: ${event.data}');

        MessageSocketData mm = messageSocketDataFromJson(event.data);
        debugPrint('Parsed MessageSocketData: $mm');

        if (mm.message == null) {
          debugPrint('Error: MessageSocketData.message is null');
          return;
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String UUID = prefs.getString('userID') ?? '';
        debugPrint('User UUID: $UUID');

        Message msg;
        if (mm.message?.type == 'voice' ||
            mm.message?.type == 'file' ||
            mm.message?.type == 'image' ||
            mm.message?.type == 'document') {
          ForwardedMessage? forwardedMessage;
          if (mm.message?.forwardedMessage != null) {
            forwardedMessage = ForwardedMessage.fromJson(mm.message!.forwardedMessage!);
          }

          msg = Message(
            id: mm.message?.id ?? 0,
            filePath: mm.message?.filePath.toString() ?? '',
            text: mm.message?.text ?? mm.message?.type ?? '',
            type: mm.message?.type ?? '',
            isMyMessage: (UUID == mm.message?.sender?.id.toString() &&
                mm.message?.sender?.type == 'user'),
            createMessateTime: mm.message?.createdAt?.toString() ?? '',
            duration: Duration(
                seconds: (mm.message?.voiceDuration != null)
                    ? double.parse(mm.message!.voiceDuration.toString()).round()
                    : 20),
            senderName: mm.message?.sender?.name ?? 'Unknown sender',
            forwardedMessage: forwardedMessage,
          );
        } else {
          ForwardedMessage? forwardedMessage;
          if (mm.message?.forwardedMessage != null) {
            forwardedMessage = ForwardedMessage.fromJson(mm.message!.forwardedMessage!);
          }
          msg = Message(
            id: mm.message?.id ?? 0,
            text: mm.message?.text ?? mm.message?.type ?? '',
            type: mm.message?.type ?? '',
            createMessateTime: mm.message?.createdAt?.toString() ?? '',
            isMyMessage: (UUID == mm.message?.sender?.id.toString() &&
                mm.message?.sender?.type == 'user'),
            senderName: mm.message?.sender?.name ?? 'Unknown sender',
            forwardedMessage: forwardedMessage,
          );
        }

        debugPrint('Constructed Message: $msg');
        context.read<MessagingCubit>().updateMessageFromSocket(msg);
        debugPrint('Message dispatched to MessagingCubit: $msg');

        if (!msg.isMyMessage) {
          await _audioPlayer.setAsset('assets/audio/get.mp3');
          await _audioPlayer.play();
          debugPrint('Played notification sound for incoming message');
        }

        _scrollToBottom();
        debugPrint('Scrolled to bottom after receiving message');

        // Опциональная фоновая синхронизация с API без изменения состояния
        try {
          await context.read<MessagingCubit>().syncMessagesInBackground(widget.chatId);
          debugPrint('Synced messages with API in background');
        } catch (e, stackTrace) {
          debugPrint('Error syncing messages with API: $e, StackTrace: $stackTrace');
        }
      } catch (e, stackTrace) {
        debugPrint('Error processing chat.message event: $e, StackTrace: $stackTrace');
      }
    });

    // ДОПОЛНИТЕЛЬНО: Подписываемся на канал пользователя для получения обновлений чата
    debugPrint('🎯🎯🎯 CHAT_SMS: Setting up USER channel subscription...');
    final userId = prefs.getString('unique_id') ?? '';
    if (userId.isNotEmpty) {
      final userChannelName = 'presence-user.$userId';
      debugPrint('🎯🎯🎯 CHAT_SMS: User channel: $userChannelName');
      
      final userPresenceChannel = socketClient.presenceChannel(
        userChannelName,
        authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
          authorizationEndpoint: Uri.parse(authUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Tenant': '$enteredDomain-back',
          },
          onAuthFailed: (exception, trace) {
            debugPrint('❌ Auth failed for $userChannelName: $exception');
          },
        ),
      );
      
      socketClient.onConnectionEstablished.listen((_) {
        debugPrint('✅ Subscribing to user channel: $userChannelName');
        userPresenceChannel.subscribeIfNotUnsubscribed();
      });
      
      // Слушаем события на канале пользователя
      userPresenceChannel.bind('chat.updated').listen((event) async {
        debugPrint('🔔🔔🔔 CHAT_SMS (USER CHANNEL): Received chat.updated!');
        
        try {
          final chatData = json.decode(event.data);
          final eventChatId = chatData['chat']?['id'];
          
          debugPrint('🔔🔔🔔 CHAT_SMS (USER CHANNEL): Event chatId: $eventChatId, our chatId: ${widget.chatId}');
          
          // Проверяем что событие для нашего чата
          if (eventChatId == widget.chatId && mounted) {
            final lastMessage = chatData['chat']?['lastMessage'];
            final chatUsers = chatData['chat']?['chatUsers'];
            
            if (lastMessage != null) {
              debugPrint('🔔🔔🔔 CHAT_SMS (USER CHANNEL): ✅ Adding new message...');
              debugPrint('🔔🔔🔔 CHAT_SMS: Full chat data keys: ${chatData['chat']?.keys.toList()}');
              debugPrint('🔔🔔🔔 CHAT_SMS: lastMessage keys: ${lastMessage.keys.toList()}');
              debugPrint('🔔🔔🔔 CHAT_SMS: sender in lastMessage: ${lastMessage.containsKey('sender')}');
              debugPrint('🔔🔔🔔 CHAT_SMS: sender data: ${lastMessage['sender']}');
              debugPrint('🔔🔔🔔 CHAT_SMS: chatUsers count: ${chatUsers?.length ?? 0}');
              if (chatUsers != null && chatUsers is List) {
                for (int i = 0; i < chatUsers.length; i++) {
                  debugPrint('🔔🔔🔔 CHAT_SMS: chatUsers[$i]: ${chatUsers[i]}');
                }
              }
              
              // КРИТИЧНО: Определяем правильно кто отправил сообщение
              final prefs = await SharedPreferences.getInstance();
              final myUserId = prefs.getString('userID') ?? '';
              final myUniqueId = prefs.getString('unique_id') ?? '';
              
              debugPrint('🔔🔔🔔 CHAT_SMS: My IDs - userID=$myUserId, unique_id=$myUniqueId');
              
              // КРИТИЧНО: Ищем ВСЕХ участников чата и определяем кто отправитель
              String otherUserName = 'Собеседник';
              String myName = 'Вы';
              String? senderId;
              
              // Получаем имена всех участников
              if (chatUsers != null && chatUsers is List && chatUsers.isNotEmpty) {
                debugPrint('🔔🔔🔔 CHAT_SMS: Searching in ${chatUsers.length} chatUsers...');
                for (var user in chatUsers) {
                  if (user['participant'] != null) {
                    final participantId = user['participant']?['id']?.toString() ?? '';
                    final participantName = user['participant']?['name'] ?? '';
                    
                    debugPrint('🔔🔔🔔 CHAT_SMS: Participant: id=$participantId, name=$participantName');
                    
                    if (participantId == myUserId) {
                      myName = participantName;
                      debugPrint('🔔🔔🔔 CHAT_SMS: This is ME: $myName');
                    } else if (participantId.isNotEmpty) {
                      otherUserName = participantName;
                      senderId = participantId;
                      debugPrint('🔔🔔🔔 CHAT_SMS: This is OTHER user: $otherUserName');
                    }
                  }
                }
              }
              
              // КРИТИЧНО: Определяем isMyMessage на основе is_my_message из события
              final isMyMessageFromEvent = lastMessage['is_my_message'] ?? false;
              
              debugPrint('🔔🔔🔔 CHAT_SMS: is_my_message from event: $isMyMessageFromEvent');
              
              // Если это мое сообщение - используем мое имя, иначе - собеседника
              final isMyMessage = isMyMessageFromEvent;
              final senderName = isMyMessage ? myName : otherUserName;
              
              debugPrint('🔔🔔🔔 CHAT_SMS: FINAL - isMyMessage=$isMyMessage, senderName=$senderName');
              
              // Создаем объект Message из lastMessage
              final newMessage = Message(
                id: lastMessage['id'] ?? 0,
                text: lastMessage['text'] ?? '',
                type: lastMessage['type'] ?? 'text',
                filePath: lastMessage['file_path'],
                isMyMessage: isMyMessage, // Используем правильно определенное значение
                createMessateTime: lastMessage['created_at'] ?? '',
                senderName: senderName,
                duration: Duration(
                  seconds: lastMessage['voice_duration'] != null 
                    ? double.tryParse(lastMessage['voice_duration'].toString())?.round() ?? 20
                    : 20
                ),
                isPinned: lastMessage['is_pinned'] ?? false,
                isChanged: lastMessage['is_changed'] ?? false,
                isNote: lastMessage['is_note'] ?? false,
              );
              
              debugPrint('🔔🔔🔔 CHAT_SMS (USER CHANNEL): Message created: ${newMessage.text}');
              
              // Добавляем сообщение БЕЗ перезагрузки всей страницы
              context.read<MessagingCubit>().updateMessageFromSocket(newMessage);
              
              // Прокручиваем вниз
              Future.delayed(Duration(milliseconds: 100), () {
                if (mounted) {
                  _scrollToBottom();
                  debugPrint('🔔🔔🔔 CHAT_SMS (USER CHANNEL): ✅ Scrolled to bottom');
                }
              });
              
              // Воспроизводим звук если сообщение не от меня
              if (!newMessage.isMyMessage) {
                try {
                  await _audioPlayer.setAsset('assets/audio/get.mp3');
                  await _audioPlayer.play();
                  debugPrint('🔔🔔🔔 CHAT_SMS (USER CHANNEL): ✅ Played sound');
                } catch (e) {
                  debugPrint('⚠️ CHAT_SMS (USER CHANNEL): Sound error: $e');
                }
              }
              
              debugPrint('✅✅✅ CHAT_SMS (USER CHANNEL): Message added successfully!');
            }
          }
    } catch (e, stackTrace) {
          debugPrint('❌ CHAT_SMS (USER CHANNEL): Error: $e');
          debugPrint('❌ CHAT_SMS (USER CHANNEL): StackTrace: $stackTrace');
        }
      });
      
      debugPrint('✅✅✅ CHAT_SMS: User channel listener registered');
    }

    try {
      debugPrint('🚀 Initiating socket connection...');
      await socketClient.connect();
      debugPrint('✅ Socket connection initiated successfully');
    } catch (e) {
      debugPrint('❌ Error connecting to socket: $e');
    }
    
    debugPrint('🔌 ChatSmsScreen: setUpServices() COMPLETED');
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
    apiService.closeChatSocket(widget.chatId);

    if (_webSocket != null && _webSocket!.readyState != WebSocket.closed) {
      _webSocket?.close();
    }
    if (chatSubscribtion != null) {
      chatSubscribtion?.cancel();
      chatSubscribtion = null;
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    socketClient.dispose();
    _focusNode.dispose();

    // ✅ Используем сохраненную ссылку на bloc вместо context.read
    _chatsBloc?.add(ResetUnreadCount(widget.chatId));

    super.dispose();
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
  final String? referralBody; // Новый параметр: referral_body чата

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
      replyMessageText = referralBody; // Выводим как есть из чата
    } else if (message.forwardedMessage != null) {
      replyMessageText = message.forwardedMessage!.type == 'voice'
          ? "Голосовое сообщение"
          : message.forwardedMessage!.text;
    }

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
          isNote: message.isNote, // Передаем is_note
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
        );
      case 'file':
      case 'document':
        return FileMessageBubble(
          time: time(message.createMessateTime),
          isSender: message.isMyMessage,
          filePath: message.filePath ?? 'Unknown file format',
          fileName: message.text,
          isHighlighted: highlightedMessageId == message.id,
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

/*
*/