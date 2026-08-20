import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/app/app_feature_flags.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/calendar/calendar_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/chat/lead/chat_lead_filter_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/chat/task/chat_task_filter_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/manager_app_bar_deal.dart';
import 'package:crm_task_manager/custom_widget/filter/event/manager_app_bar_event.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/manager_app_bar_lead.dart';
import 'package:crm_task_manager/models/lead/region_model.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/custom_widget/filter/task/user_app_bar_task.dart';
import 'package:crm_task_manager/models/user/user_byId_model..dart';
import 'package:crm_task_manager/screens/notifications_screen.dart';
import 'package:crm_task_manager/page_2/call_center/call_center_screen.dart';
import 'package:crm_task_manager/screens/event/event_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_planning_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_screen.dart';
import 'package:crm_task_manager/screens/timesheet/timesheet_screen.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatefulWidget {
  final GlobalKey? menuIconKey;
  final GlobalKey? SearchIconKey;
  final GlobalKey? FiltrEventIconKey;
  final GlobalKey? NotificationIconKey;
  final GlobalKey? MyTaskIconKey;
  final GlobalKey? CalendarIconKey;
  String title;
  Function() onClickProfileAvatar;
  FocusNode focusNode;
  TextEditingController textEditingController;
  ValueChanged<String>? onChangedSearchInput;
  Function(bool) clearButtonClick;
  Function(bool) clearButtonClickFiltr;
  bool showSearchIcon;
  bool showFilterIconEvent;
  final bool showFilterIcon;
  final bool showFilterIconOnSelectLead;
  final bool showFilterIconOnSelectDeal;
  final bool showFilterIconOnSelectTask;
  final bool showFilterIconDeal;
  final bool showFilterTaskIcon;
  final bool showEvent;
  final bool showSeparateTaskFilter;
  final bool showSeparateMyTasks;
  final bool showNotification;
  final bool showCalendar;
  final bool showCalendarDashboard;
  final bool showCallCenter; // Новый параметр
  final bool showGps; // Новый параметр
  final bool showFilterIconCallCenter; // Новый параметр для фильтра CallCenter

  final bool
      showFilterIconOnSelectCallCenter; // Добавлено: параметр для фильтра колл-центра

  final bool showFilterIconChat;
  final bool showFilterIconTaskChat;
  final Function(Map)? onManagersLeadSelected;

  final Function(Map)? onManagersDealSelected;
  final Function(Map)? onLeadsDealSelected;
  final Function(int?)? onStatusDealSelected;
  final Function(DateTime?, DateTime?)? onDateRangeDealSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeDealSelected;

  final Function(Map)? onManagersEventSelected;
  final Function(int?)? onStatusEventSelected;
  final Function(DateTime?, DateTime?)? onDateRangeEventSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeEventSelected;
  final Function(DateTime?, DateTime?)? onNoticeDateRangeEventSelected;
  final Function(int?, DateTime?, DateTime?)?
      onNoticeStatusAndDateRangeEventSelected;
  final Function(int?, DateTime?, DateTime?, DateTime?, DateTime?)?
      onDateNoticeStatusAndDateRangeSelected;
  final Function(DateTime?, DateTime?, DateTime?, DateTime?)?
      onDateNoticeAndDateRangeSelected;

  final Function(Map)? onUsersSelected;
  final Function(int?)? onStatusSelected;
  final Function(DateTime?, DateTime?)? onDateRangeSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeSelected;

  final List? initialUsers;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  final List? initialManagersLead;
  final List? initialManagersLeadRegions;
  final RegionData? initialManagersLeadState;
  final List? initialManagersLeadCities;
  final List? initialManagersLeadSources;
  final List? initialManagersLeadChannels;
  final List? initialManagersLeadAdvertisingCampaigns;
  final List<int>? initialManagersLeadReasonForRefusalIds;
  final int? initialManagerLeadStatuses;
  final DateTime? initialManagerLeadFromDate;
  final DateTime? initialManagerLeadToDate;

  final bool? initialManagerLeadHasSuccessDeals;
  final bool? initialManagerLeadHasInProgressDeals;
  final bool? initialManagerLeadHasFailureDeals;
  final bool? initialManagerLeadHasNotices;
  final bool? initialManagerLeadHasContact;
  final bool? initialManagerLeadHasChat;
  final bool? initialManagerLeadHasNoReplies;
  final bool? initialManagerLeadHasUnreadMessages;
  final bool? initialManagerLeadHasDeal;
  final bool? initialManagerLeadHasOrders;
  final int? initialManagerLeadDaysWithoutActivity;
  final int? initialManagerLeadNumberOfDaysDeal;
  final List<Map<String, dynamic>>?
      initialDirectoryValuesLead; // Новый параметр для лидов
  final Map<String, List<String>>?
      initialLeadCustomFields; // Пользовательские поля для фильтра лидов

  final List? initialManagersDeal;
  final List? initialRegionsDeal;
  final RegionData? initialStateDeal;
  final List? initialCitiesDeal;
  final List<UserData>? initialExecutorsDeal;
  final List? initialSourcesDeal;
  final List? initialLeadsDeal;
  final int? initialManagerDealStatuses;
  final DateTime? initialManagerDealFromDate;
  final DateTime? initialManagerDealToDate;
  final bool? initialManagerDealHasTasks;
  final bool? initialManagerDealWithoutNotices;
  final bool? initialManagerDealOverdueNotices;
  final int? initialManagerDealDaysWithoutActivity;
  final List<int>? initialLeadStatusesDeal;
  final List<int>? initialReasonForRefusalIdsDeal;
  final List<Map<String, dynamic>>?
      initialDirectoryValuesDeal; // Добавляем начальные значения справочников

  final List? initialManagersEvent;
  final int? initialManagerEventStatuses;
  final DateTime? initialManagerEventFromDate;
  final DateTime? initialManagerEventToDate;
  final DateTime? initialNoticeManagerEventFromDate;
  final DateTime? initialNoticeManagerEventToDate;

  final VoidCallback? onResetFilters;
  final VoidCallback? onLeadResetFilters;
  final VoidCallback? onDealResetFilters;
  final VoidCallback? onEventResetFilters;
  final List<String>? initialDealNames; // Новый параметр
  final bool showMyTaskIcon;
  final bool showMenuIcon;
  final bool showProjectsMenuItem;
  final VoidCallback? onProjectsPressed;
  final bool showSeparateFilter;

  final bool? initialTaskIsOverdue;
  final bool? initialTaskHasFile;
  final bool? initialTaskHasDeal;
  final bool? initialTaskIsUrgent;
  final DateTime? initialDeadlineFromDate;
  final DateTime? initialDeadlineToDate;
  final DateTime? initialCompletedFromDate;
  final DateTime? initialCompletedToDate;
  final List<int>? initialReasonForRefusalIdsTask;
  final List<String>? initialAuthors;
  final String? initialDepartment;
  final List<Map<String, dynamic>>?
      initialDirectoryValuesTask; // Добавляем начальные значения справочников
  final List? initialProjects; // Начальные проекты для фильтра

  final Function(Map<String, dynamic>)? onChatLeadFiltersApplied; // Для лидов
  final Function(Map<String, dynamic>)? onChatTaskFiltersApplied; // Для задач
  final VoidCallback? onChatLeadFiltersReset; // Сброс фильтров
  final bool hasActiveChatFilters; // Есть ли активные фильтры
  final bool hasActiveEventFilters; // Есть ли активные фильтры для Event
  final bool hasActiveDealFilters; // Есть ли активные фильтры для сделок
  final bool hasActiveTaskFilters; // Есть ли активные фильтры для задач
  final bool hasActiveLeadFilters; // Есть ли активные фильтры для лидов
  final Map<String, dynamic>? initialChatFilters; // Начальные фильтры
  final int? currentSalesFunnelId; // ID текущей воронки
  final bool showDashboardIcon; // Новый параметр
  final VoidCallback? onDashboardPressed; // Обработчик для Dashboard

  final Widget? titleWidget; // Новый параметр для кастомного заголовка
  final VoidCallback? onFiltersReset; // Добавляем этот параметр
  final bool showDashboardFilterMenuItem;
  final bool hasActiveDashboardFilters;
  final VoidCallback? onDashboardFilterPressed;
  final bool showDashboardChartSettingsMenuItem;
  final VoidCallback? onDashboardChartSettingsPressed;

  final VoidCallback? onChatTaskFiltersReset; // Новый параметр для сброса

  CustomAppBar({
    super.key,
    this.menuIconKey,
    this.SearchIconKey,
    this.FiltrEventIconKey,
    this.NotificationIconKey,
    this.MyTaskIconKey,
    this.CalendarIconKey,
    required this.title,
    required this.onClickProfileAvatar,
    required this.onChangedSearchInput,
    required this.textEditingController,
    required this.focusNode,
    required this.clearButtonClick,
    required this.clearButtonClickFiltr,
    this.initialUsers,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
    this.initialManagersLead,
    this.initialManagersLeadRegions,
    this.initialManagersLeadState,
    this.initialManagersLeadCities,
    this.initialManagersLeadSources,
    this.initialManagersLeadChannels,
    this.initialManagersLeadAdvertisingCampaigns,
    this.initialManagersLeadReasonForRefusalIds,
    this.initialManagerLeadStatuses,
    this.initialManagerLeadFromDate,
    this.initialManagerLeadToDate,
    this.initialManagerLeadHasSuccessDeals,
    this.initialManagerLeadHasInProgressDeals,
    this.initialManagerLeadHasFailureDeals,
    this.initialManagerLeadHasNotices,
    this.initialManagerLeadHasContact,
    this.initialManagerLeadHasChat,
    this.initialManagerLeadHasNoReplies,
    this.initialManagerLeadHasUnreadMessages,
    this.initialManagerLeadHasDeal,
    this.initialManagerLeadHasOrders,
    this.initialManagerLeadDaysWithoutActivity,
    this.initialManagerLeadNumberOfDaysDeal,
    this.initialDirectoryValuesLead, // Добавляем в конструктор
    this.initialLeadCustomFields,
    this.initialDirectoryValuesTask, // Добавляем в конструктор
    this.showFilterIconOnSelectCallCenter =
        false, // Добавлено: по умолчанию false

    this.showDashboardIcon = false,
    this.onDashboardPressed,
    this.onChatTaskFiltersReset,

// ДОБАВЛЯЕМ новые параметры
    this.onChatLeadFiltersApplied,
    this.onChatLeadFiltersReset,
    this.onChatTaskFiltersApplied, // Новый параметр
    this.hasActiveChatFilters = false,
    this.hasActiveEventFilters = false,
    this.hasActiveDealFilters = false,
    this.hasActiveTaskFilters = false,
    this.hasActiveLeadFilters = false,
    this.initialChatFilters,
    this.initialManagersDeal,
    this.initialRegionsDeal,
    this.initialStateDeal,
    this.initialCitiesDeal,
    this.initialExecutorsDeal,
    this.initialSourcesDeal,
    this.initialLeadsDeal,
    this.initialManagerDealStatuses,
    this.initialManagerDealFromDate,
    this.initialManagerDealToDate,
    this.initialManagerDealHasTasks,
    this.initialManagerDealWithoutNotices,
    this.initialManagerDealOverdueNotices,
    this.initialManagerDealDaysWithoutActivity,
    this.initialLeadStatusesDeal,
    this.initialReasonForRefusalIdsDeal,
    this.initialManagersEvent,
    this.initialManagerEventStatuses,
    this.initialManagerEventFromDate,
    this.initialManagerEventToDate,
    this.initialNoticeManagerEventFromDate,
    this.initialNoticeManagerEventToDate,
    this.onResetFilters,
    this.onLeadResetFilters,
    this.onDealResetFilters,
    this.onEventResetFilters,
    this.showSearchIcon = true,
    this.showFilterIconEvent = false,
    this.showFilterIcon = true,
    this.showFilterIconOnSelectLead = false,
    this.showFilterIconOnSelectDeal = false,
    this.showFilterIconCallCenter = false, // Значение по умолчанию
    this.showFilterIconOnSelectTask = false,
    this.showFilterIconDeal = true,
    this.showFilterTaskIcon = true,
    this.showFilterIconChat = false, // Значение по умолчанию
    this.showFilterIconTaskChat = false, // Значение по умолчанию
    this.showCallCenter = true, // Значение по умолчанию
    this.onManagersLeadSelected,
    this.onManagersDealSelected,
    this.onStatusDealSelected,
    this.onDateRangeDealSelected,
    this.onStatusAndDateRangeDealSelected,
    this.onManagersEventSelected,
    this.onStatusEventSelected,
    this.onDateRangeEventSelected,
    this.onStatusAndDateRangeEventSelected,
    this.onNoticeDateRangeEventSelected,
    this.onNoticeStatusAndDateRangeEventSelected,
    this.onDateNoticeStatusAndDateRangeSelected,
    this.onDateNoticeAndDateRangeSelected,
    this.onUsersSelected,
    this.onStatusSelected,
    this.onDateRangeSelected,
    this.onStatusAndDateRangeSelected,
    this.showEvent = false,
    this.showSeparateTaskFilter = false,
    this.showSeparateMyTasks = false,
    this.showMyTaskIcon = false,
    this.showMenuIcon = true,
    this.showProjectsMenuItem = false,
    this.onProjectsPressed,
    this.showNotification = true,
    this.showSeparateFilter = false,
    this.showCalendar = true,
    this.showCalendarDashboard = false,
    this.initialTaskIsOverdue,
    this.initialTaskHasFile,
    this.initialTaskHasDeal,
    this.initialTaskIsUrgent,
    this.initialDeadlineFromDate,
    this.initialDeadlineToDate,
    this.initialCompletedFromDate,
    this.initialCompletedToDate,
    this.initialReasonForRefusalIdsTask,
    this.initialAuthors,
    this.initialDepartment,
    this.initialProjects,
    this.onLeadsDealSelected,
    this.initialDirectoryValuesDeal, // Добавляем в конструктор

    this.titleWidget, // Добавляем в конструктор
    this.onFiltersReset,
    this.showDashboardFilterMenuItem = false,
    this.hasActiveDashboardFilters = false,
    this.onDashboardFilterPressed,
    this.showDashboardChartSettingsMenuItem = false,
    this.onDashboardChartSettingsPressed,
    this.showGps = true, // Добавляем по умолчанию true
    this.currentSalesFunnelId,
    this.initialDealNames, // Добавляем новый параметр
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  final ApiService _apiService = ApiService();
  late TextEditingController _searchController;
  late FocusNode focusNode;
  String _userImage = '';
  String _lastLoadedImage = '';
  static String _cachedUserImage = '';
  bool _isFiltering = false;
  bool _isTaskFiltering = false;
  bool _hasNewNotification = false;
  PusherChannelsClient? socketClient;
  StreamSubscription<ChannelReadEvent>? notificationSubscription;
  StreamSubscription<RemoteMessage>? _firebaseMessageSubscription;
  StreamSubscription<RemoteMessage>? _firebaseOpenedAppSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _checkOverdueTimer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  bool _hasOverdueTasks = false;
  bool _canReadCallCenter = false;
  bool _canReadNotice = false;
  bool _canReadCalendar = false;
  bool _canReadGps = false; // Новая переменная для GPS®
  bool _canOpenTimesheet = false;
  bool _canReadSalesPlanning = false;
  // DEAL custom fields were moved to filter screen

  late Timer _timer;
  bool _areFiltersActive = false; // Добавляем эту переменную
  bool _isFilterBlinkOn = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();

    _searchController = widget.textEditingController;
    focusNode = widget.focusNode;
// Устанавливаем начальное состояние фильтров на основе активности любых фильтров
    _areFiltersActive = widget.hasActiveChatFilters ||
        widget.hasActiveEventFilters ||
        widget.hasActiveDealFilters ||
        widget.hasActiveTaskFilters ||
        widget.hasActiveLeadFilters;
    if (_cachedUserImage.isNotEmpty) {
      _userImage = _cachedUserImage;
    } else {
      _loadUserProfile();
    }

    _loadNotificationState();
    _setUpSocketForNotifications();
    _setupFirebaseMessaging(); // Новый метод

    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _blinkAnimation = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );
    _checkOverdueTasks();
    _checkOverdueTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkOverdueTasks(),
    );

    // Модифицируем таймер
    _timer = Timer.periodic(Duration(milliseconds: 700), (timer) {
      if (_areFiltersActive) {
        setState(() {
          _isFilterBlinkOn = !_isFilterBlinkOn;
        });
      } else {
        setState(() {
          _isFilterBlinkOn = false;
        });
      }
    });
  }

  void _setFiltersActive(bool active) {
    setState(() {
      _areFiltersActive = active;
      if (!active) {
        _isFilterBlinkOn = false;
      }
    });
  }

// Метод для проверки активности фильтров (можно вызывать извне)
  void resetFilterIconState() {
    _setFiltersActive(false);
  }

  void _setupFirebaseMessaging() async {
    final prefs = await SharedPreferences.getInstance();

    // Отписываемся от старых подписок если они есть
    _firebaseMessageSubscription?.cancel();
    _firebaseOpenedAppSubscription?.cancel();

    _firebaseMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Получено push-уведомление: ${message.data}');
      final type = message.data['type']?.toString();
      if (type == 'incoming_call' ||
          type == 'call_cancelled' ||
          type == 'call_canceled' ||
          type == 'call_ended' ||
          type == 'call_end') {
        return;
      }
      if (mounted) {
        setState(() {
          _hasNewNotification = true;
        });
        prefs.setBool('hasNewNotification', true);
        if (type == 'message') {
          _playSound();
        }
      }
    });

    _firebaseOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Push-уведомление открыто: ${message.data}');
      if (mounted) {
        setState(() {
          _hasNewNotification = true;
        });
        prefs.setBool('hasNewNotification', true);
      }
    });
  }

  List<Map<String, dynamic>>? _safeConvertToMapList(dynamic data) {
    if (data == null) return null;
    if (data is List<Map<String, dynamic>>) return data;
    if (data is List) {
      try {
        return data.cast<Map<String, dynamic>>();
      } catch (e) {
        return data
            .where((item) => item is Map)
            .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }
    return null;
  }

  Future<void> _checkOverdueTasks() async {
    try {
      final apiService = ApiService();
      final hasOverdue = await apiService.checkOverdueTasks();

      if (mounted) {
        setState(() {
          _hasOverdueTasks = hasOverdue;
        });
      }
    } catch (e) {
      //debugPrint('Error checking overdue tasks: $e');
    }
  }

  @override
  void didUpdateWidget(CustomAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Синхронизируем _areFiltersActive с hasActiveChatFilters и hasActiveEventFilters при обновлении виджета
    if (widget.hasActiveChatFilters != oldWidget.hasActiveChatFilters ||
        widget.hasActiveEventFilters != oldWidget.hasActiveEventFilters ||
        widget.hasActiveDealFilters != oldWidget.hasActiveDealFilters ||
        widget.hasActiveTaskFilters != oldWidget.hasActiveTaskFilters ||
        widget.hasActiveLeadFilters != oldWidget.hasActiveLeadFilters) {
      _setFiltersActive(widget.hasActiveChatFilters ||
          widget.hasActiveEventFilters ||
          widget.hasActiveDealFilters ||
          widget.hasActiveTaskFilters ||
          widget.hasActiveLeadFilters);
    }
  }

  @override
  @override
  void dispose() {
    _blinkController.dispose();
    _checkOverdueTimer?.cancel();
    _timer.cancel();
    notificationSubscription?.cancel();
    _firebaseMessageSubscription?.cancel();
    _firebaseOpenedAppSubscription?.cancel();
    socketClient?.disconnect();

    super.dispose();
  }

// Обновляем обработчик сброса фильтров
  void _handleChatFiltersReset() {
    // debugPrint('CustomAppBar: Resetting chat filters');
    _setFiltersActive(false);
    widget.onChatLeadFiltersReset?.call();
    widget.onChatTaskFiltersReset?.call();
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.setAsset('assets/audio/get.mp3');
      await _audioPlayer.play();
    } catch (e) {
      //debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
    setState(() {
      _hasNewNotification = hasNewNotification;
    });
  }

  // -------- DEAL custom fields loading moved to filter screen --------

  Future<void> _setUpSocketForNotifications() async {
    // debugPrint(
    //     '--------------------------- start socket CUSTOM APPBAR:::::::----------------');
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    final customOptions = PusherChannelsOptions.custom(
      uriResolver: (metadata) =>
          Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    final client = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {},
      minimumReconnectDelayDuration: const Duration(seconds: 1),
    );
    socketClient = client;

    String userId = prefs.getString('unique_id') ?? '';
    //debugPrint('userID--------------------------------------------------popopop-p : $userId');
    //debugPrint(userId);

    final myPresenceChannel = client.presenceChannel(
      'presence-user.$userId',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(
            'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': '$enteredDomain-back'
        },
        onAuthFailed: (exception, trace) {
          // debugPrint('Auth failed: ${exception.toString()}');
        },
      ),
    );

    client.onConnectionEstablished.listen((_) {
      myPresenceChannel.subscribeIfNotUnsubscribed();
      notificationSubscription =
          myPresenceChannel.bind('notification.created').listen((event) {
        // debugPrint('Получено уведомление через сокет: ${event.data}');
        try {
          final data = jsonDecode(event.data);
          // debugPrint('Данные уведомления: $data');
          setState(() {
            _hasNewNotification = true;
          });
          prefs.setBool('hasNewNotification', true);
          _playSound();
        } catch (e) {
          // debugPrint('Ошибка парсинга данных уведомления: $e');
        }
      });
    });

    try {
      await client.connect();
      //debugPrint('Socket connection SUCCESSS');
    } catch (e) {
      if (kDebugMode) {
        //debugPrint('Socket connection error!');
      }
    }
  }

  Future<void> _checkPermissions() async {
    final canReadNotice = await _apiService.hasPermission('notice.read');
    // final canReadCalendar = await _apiService.hasPermission('notice.read');
    final canReadCalendar = await _apiService.hasPermission('calendar');
    final canReadCallCenter =
        await _apiService.hasPermission('call-center'); // Исправлено
    final canReadGps =
        await _apiService.hasPermission('call-center'); // Проверка прав для GPS
    final canReadTimesheet = await _apiService.canReadTimesheet();
    final canReadSalesPlanning =
        await _apiService.hasPermission('planning.read');
    if (!mounted) return;
    setState(() {
      _canReadNotice = canReadNotice;
      _canReadCalendar = canReadCalendar;
      _canReadCallCenter = canReadCallCenter;
      _canReadCallCenter = canReadCallCenter;
      _canReadGps = canReadGps;
      _canOpenTimesheet = canReadTimesheet;
      _canReadSalesPlanning = canReadSalesPlanning;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      String UUID = prefs.getString('userID') ??
          AppLocalizations.of(context)!.translate('not_found');

      UserByIdProfile userProfile =
          await ApiService().getUserById(int.parse(UUID));

      if (userProfile.image != null && userProfile.image != _lastLoadedImage) {
        if (!mounted) return;
        setState(() {
          _userImage = userProfile.image!;
          _lastLoadedImage = userProfile.image!;
          _cachedUserImage = userProfile.image!;
        });

        await prefs.setString('userProfileImage_$UUID', _userImage);
      } else if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _userImage = _cachedUserImage;
        });
      }
    } catch (e) {
      //debugPrint('Ошибка при загрузке изображения!');
      if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _userImage = _cachedUserImage;
        });
      }
    }
  }

  Future<void> refreshUserImage() async {
    _lastLoadedImage = '';
    await _loadUserProfile();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        FocusScope.of(context).requestFocus(focusNode);
      } else {
        _searchController.clear();
        focusNode.unfocus();
      }
    });
  }

  void _toggleFilter() {
    setState(() {
      _isFiltering = !_isFiltering;
      if (_isFiltering) {
        FocusScope.of(context).requestFocus(focusNode);
      } else {
        focusNode.unfocus();
      }
    });
    widget.clearButtonClickFiltr(_isFiltering);
  }

  void _toggleTaskFilter() {
    setState(() {
      _isTaskFiltering = !_isTaskFiltering;
      if (_isTaskFiltering) {
        FocusScope.of(context).requestFocus(focusNode);
      } else {
        focusNode.unfocus();
      }
    });
    widget.clearButtonClickFiltr(_isTaskFiltering);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(Duration(milliseconds: 1), () {
      if (mounted) {
        _loadUserProfile();
        _loadNotificationState(); // Перезагружаем состояние уведомлений
      }
    });
  }

  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
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

  Widget _buildAvatarImage(String imageSource) {
    if (imageSource.isEmpty) {
      return Image.asset(
        'assets/icons/playstore.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    }

    if (imageSource.startsWith('<svg')) {
      final imageUrl = extractImageUrlFromSvg(imageSource);

      if (imageUrl != null) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        final text =
            RegExp(r'>([^<]+)</text>').firstMatch(imageSource)?.group(1) ?? '';
        final backgroundColor =
            extractBackgroundColorFromSvg(imageSource) ?? Color(0xFF2C2C2C);

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  text,
                  style: context.appTextStyles.titleLg.copyWith(
                    color: context.appColors.textInverse,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Image.network(
      imageSource,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center();
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/icons/playstore.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Widget _buildAppBarAssetIcon(
    BuildContext context,
    String assetPath, {
    Color? color,
    double size = 24,
  }) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: color ?? context.appColors.iconPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tooltipDecoration = BoxDecoration(
      color: context.appColors.surfacePrimary,
      borderRadius: BorderRadius.circular(8),
      boxShadow: context.appShadows.card,
    );
    final tooltipTextStyle = context.appTextStyles.bodySm.copyWith(
      color: context.appColors.textPrimary,
    );
    final inactiveIconColor = context.appColors.iconPrimary;
    final activeIconColor = context.appColors.buttonPrimaryBg;
    final filterIconColor = _areFiltersActive && _isFilterBlinkOn
        ? activeIconColor
        : inactiveIconColor;
    final alertColor = context.appColors.error;

    return AppBarShell(
        leading: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: _buildAvatarImage(_userImage),
            onPressed: widget.onClickProfileAvatar,
          ),
        ),
        center: AppBarShell.capsule(
          context,
          child: !_isSearching
              ? Row(
                  children: [
                    Expanded(
                      child: widget.titleWidget ??
                          Text(
                            widget.title,
                            style: context.appTextStyles.titleLg.copyWith(
                              color: context.appColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                  ],
                )
              : AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _isSearching ? 200.0 : 0.0,
                  child: TextField(
                    controller: _searchController,
                    focusNode: focusNode,
                    onChanged: widget.onChangedSearchInput,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!
                          .translate('search_appbar'),
                      border: InputBorder.none,
                      hintStyle: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.fieldHint,
                      ),
                    ),
                    style: context.appTextStyles.bodyLg.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                    autofocus: true,
                  ),
                ),
        ),
        trailing: _hasTrailingActions()
            ? AppBarShell.capsule(context,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  // Иконка фильтра (первая в порядке)
                  if (widget.showFilterIconOnSelectCallCenter)
                    Transform.translate(
                      offset: const Offset(10, 0),
                      child: Tooltip(
                        message:
                            AppLocalizations.of(context)!.translate('filter'),
                        preferBelow: false,
                        decoration: BoxDecoration(
                          color: context.appColors.surfacePrimary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: context.appShadows.card,
                        ),
                        textStyle: context.appTextStyles.bodySm.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                        child: IconButton(
                          icon: Image.asset(
                            'assets/icons/AppBar/filter.png',
                            width: 24,
                            height: 24,
                            color: filterIconColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFiltering = !_isFiltering;
                              _setFiltersActive(
                                  _isFiltering); // Обновляем состояние фильтров
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ManagerFilterScreen(), // Новый экран фильтрации
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Иконка поиска
                  if (widget.showSearchIcon)
                    Transform.translate(
                      offset: const Offset(10, 0),
                      child: Tooltip(
                        message:
                            AppLocalizations.of(context)!.translate('search'),
                        preferBelow: false,
                        decoration: BoxDecoration(
                          color: context.appColors.surfacePrimary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: context.appShadows.card,
                        ),
                        textStyle: context.appTextStyles.bodySm.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                        child: IconButton(
                          key: widget.SearchIconKey,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: _isSearching
                              ? Icon(Icons.close, color: inactiveIconColor)
                              : _buildAppBarAssetIcon(
                                  context,
                                  'assets/icons/AppBar/search.png',
                                ),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              }
                            });
                            widget.clearButtonClick(_isSearching);
                            if (_isSearching) {
                              Future.delayed(Duration(milliseconds: 100), () {
                                FocusScope.of(context).requestFocus(focusNode);
                              });
                            }
                          },
                        ),
                      ),
                    ),

                  // Иконка уведомлений
                  if (widget.showNotification)
                    Transform.translate(
                      offset: const Offset(10, 0),
                      child: Tooltip(
                        message: AppLocalizations.of(context)!
                            .translate('notification'),
                        preferBelow: false,
                        decoration: tooltipDecoration,
                        textStyle: tooltipTextStyle,
                        child: IconButton(
                          key: widget.NotificationIconKey,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Stack(
                            children: [
                              _buildAppBarAssetIcon(
                                context,
                                'assets/icons/AppBar/notification.png',
                              ),
                              if (_hasNewNotification)
                                Positioned(
                                  right: 0,
                                  child: FadeTransition(
                                    opacity: _blinkAnimation,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: alertColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () {
                            setState(() {
                              _hasNewNotification = false;
                            });
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setBool('hasNewNotification', false);
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  // Иконка фильтра (первая в порядке)
                  if (widget.showFilterIconChat)
                    Transform.translate(
                      offset: const Offset(10, 0),
                      child: Tooltip(
                        message:
                            AppLocalizations.of(context)!.translate('filter'),
                        preferBelow: false,
                        decoration: tooltipDecoration,
                        textStyle: tooltipTextStyle,
                        child: IconButton(
                          icon: Image.asset(
                            'assets/icons/AppBar/filter.png',
                            width: 24,
                            height: 24,
                            color: widget.hasActiveChatFilters
                                ? activeIconColor
                                : filterIconColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFiltering = !_isFiltering;
                              if (widget.hasActiveChatFilters) {
                                _setFiltersActive(true);
                              }
                            });

                            // ОТКРЫВАЕМ ChatLeadFilterScreen с передачей данных
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // В секции showFilterIconChat:
                                builder: (context) => ChatLeadFilterScreen(
                                  // Безопасное преобразование типов
                                  initialManagers: _safeConvertToMapList(
                                      widget.initialChatFilters?['managers']),
                                  initialRegions: _safeConvertToMapList(
                                      widget.initialChatFilters?['regions']),
                                  initialSources: _safeConvertToMapList(
                                      widget.initialChatFilters?['sources']),
                                  initialStatuses:
                                      widget.initialChatFilters?['statuses'],
                                  initialFromDate:
                                      widget.initialChatFilters?['fromDate'],
                                  initialToDate:
                                      widget.initialChatFilters?['toDate'],
                                  initialHasSuccessDeals: widget
                                      .initialChatFilters?['hasSuccessDeals'],
                                  initialHasInProgressDeals:
                                      widget.initialChatFilters?[
                                          'hasInProgressDeals'],
                                  initialHasFailureDeals: widget
                                      .initialChatFilters?['hasFailureDeals'],
                                  initialHasNotices:
                                      widget.initialChatFilters?['hasNotices'],
                                  initialHasContact:
                                      widget.initialChatFilters?['hasContact'],
                                  initialHasChat:
                                      widget.initialChatFilters?['hasChat'],
                                  initialHasNoReplies: widget
                                      .initialChatFilters?['hasNoReplies'],
                                  initialHasUnreadMessages: widget
                                      .initialChatFilters?['hasUnreadMessages'],
                                  initialHasDeal:
                                      widget.initialChatFilters?['hasDeal'],
                                  // initialHasOrders: widget.initialChatFilters?['hasOrders'],
                                  initialDaysWithoutActivity:
                                      widget.initialChatFilters?[
                                          'daysWithoutActivity'],
                                  initialDirectoryValues: _safeConvertToMapList(
                                      widget.initialChatFilters?[
                                          'directory_values']),
                                  initialSalesFunnelId:
                                      widget.currentSalesFunnelId ??
                                          widget.initialChatFilters?[
                                              'current_sales_funnel_id'] ??
                                          widget.initialChatFilters?[
                                              'sales_funnel_id'],
                                  onManagersSelected:
                                      widget.onChatLeadFiltersApplied,
                                  onResetFilters: widget.onChatLeadFiltersReset,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  if (widget.showFilterIconTaskChat)
                    Transform.translate(
                      offset: const Offset(10, 0),
                      child: Tooltip(
                        message: AppLocalizations.of(context)!
                            .translate('task_filters'),
                        preferBelow: false,
                        decoration: tooltipDecoration,
                        textStyle: tooltipTextStyle,
                        child: IconButton(
                          icon: Image.asset(
                            'assets/icons/AppBar/filter.png',
                            width: 24,
                            height: 24,
                            color: widget.hasActiveChatFilters
                                ? activeIconColor
                                : filterIconColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isTaskFiltering = !_isTaskFiltering;
                              _setFiltersActive(_isTaskFiltering &&
                                  widget.hasActiveChatFilters);
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatTaskFilterScreen(
                                  initialUsers: widget
                                          .initialChatFilters?['executor_ids']
                                          ?.cast<int>() ??
                                      [],
// СТАЛО:
                                  initialAuthors: () {
                                    final authorIds = widget
                                        .initialChatFilters?['author_ids'];
                                    if (authorIds is List &&
                                        authorIds.isNotEmpty) {
                                      return authorIds
                                          .map((id) => id.toString())
                                          .toList();
                                    }
                                    return [];
                                  }(),

                                  initialProjects: () {
                                    final projectIds = widget
                                        .initialChatFilters?['project_ids'];
                                    if (projectIds is List &&
                                        projectIds.isNotEmpty) {
                                      return projectIds
                                          .map((id) => id.toString())
                                          .toList();
                                    }
                                    return [];
                                  }(),
                                  initialStatuses: (widget.initialChatFilters?[
                                                      'task_status_ids']
                                                  as List<dynamic>?)
                                              ?.cast<int>()
                                              .isNotEmpty ==
                                          true
                                      ? (widget.initialChatFilters![
                                                  'task_status_ids']
                                              as List<dynamic>)
                                          .cast<int>()
                                          .first
                                      : null,
                                  initialFromDate: widget.initialChatFilters?[
                                              'task_created_from'] !=
                                          null
                                      ? DateTime.parse(
                                          widget.initialChatFilters![
                                              'task_created_from'])
                                      : null,
                                  initialToDate: widget.initialChatFilters?[
                                              'task_created_to'] !=
                                          null
                                      ? DateTime.parse(
                                          widget.initialChatFilters![
                                              'task_created_to'])
                                      : null,
                                  initialDeadlineFromDate: widget
                                                  .initialChatFilters?[
                                              'deadline_from'] !=
                                          null
                                      ? DateTime.parse(widget
                                          .initialChatFilters!['deadline_from'])
                                      : null,
                                  initialDeadlineToDate: widget
                                                  .initialChatFilters?[
                                              'deadline_to'] !=
                                          null
                                      ? DateTime.parse(widget
                                          .initialChatFilters!['deadline_to'])
                                      : null,
                                  initialDepartment: widget
                                      .initialChatFilters?['department_id']
                                      ?.toString(),
                                  initialTaskNumber:
                                      widget.initialChatFilters?['task_number'],
                                  initialUnreadOnly: widget
                                          .initialChatFilters?['unread_only'] ??
                                      false,
                                  onUsersSelected:
                                      widget.onChatTaskFiltersApplied,
                                  onResetFilters: widget.onChatTaskFiltersReset,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Дополнительные иконки (например, календарь, задачи, меню и т.д.)
                  if (widget.showDashboardIcon)
                    Transform.translate(
                      offset: const Offset(10, 0),
                      child: Tooltip(
                        message: AppLocalizations.of(context)!
                            .translate('dashboard'),
                        preferBelow: false,
                        decoration: tooltipDecoration,
                        textStyle: tooltipTextStyle,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: _buildAppBarAssetIcon(
                            context,
                            'assets/icons/MyNavBar/dashboard_OFF.png',
                          ),
                          onPressed: widget.onDashboardPressed,
                        ),
                      ),
                    ),
                  if (widget.showFilterIconEvent)
                    Tooltip(
                      message:
                          AppLocalizations.of(context)!.translate('search'),
                      preferBelow: false,
                      decoration: tooltipDecoration,
                      textStyle: tooltipTextStyle,
                      child: IconButton(
                        key: widget.FiltrEventIconKey,
                        icon: Image.asset(
                          'assets/icons/AppBar/filter.png',
                          width: 24,
                          height: 24,
                          color: widget.hasActiveEventFilters
                              ? activeIconColor
                              : filterIconColor,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventManagerFilterScreen(
                                onManagersSelected:
                                    widget.onManagersEventSelected,
                                initialManagers: widget.initialManagersEvent,
                                initialStatuses:
                                    widget.initialManagerEventStatuses,
                                initialFromDate:
                                    widget.initialManagerEventFromDate,
                                initialToDate: widget.initialManagerEventToDate,
                                initialNoticeFromDate:
                                    widget.initialNoticeManagerEventFromDate,
                                initialNoticeToDate:
                                    widget.initialNoticeManagerEventToDate,
                                onResetFilters: widget.onEventResetFilters,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (widget.showFilterIconOnSelectLead)
                    IconButton(
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Image.asset(
                          'assets/icons/AppBar/filter.png',
                          width: 24,
                          height: 24,
                          color: filterIconColor,
                        ),
                      ),
                      onPressed: () {
                        navigateToLeadManagerFilterScreen(context);
                      },
                    ),
                  if (widget.showFilterIconOnSelectDeal)
                    IconButton(
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Image.asset(
                          'assets/icons/AppBar/filter.png',
                          width: 24,
                          height: 24,
                          color: filterIconColor,
                        ),
                      ),
                      onPressed: () {
                        navigateToDealManagerFilterScreen(context);
                      },
                    ),
                  if (widget.showFilterIconOnSelectTask)
                    IconButton(
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Image.asset(
                          'assets/icons/AppBar/filter.png',
                          width: 24,
                          height: 24,
                          color: filterIconColor,
                        ),
                      ),
                      onPressed: () {
                        navigateToTaskManagerFilterScreen(context);
                      },
                    ),
                  // if (widget.showSeparateMyTasks)
                  //   Transform.translate(
                  //     offset: const Offset(6, 0),
                  //     child: Tooltip(
                  //       message: AppLocalizations.of(context)!
                  //           .translate('appbar_my_tasks'),
                  //       preferBelow: false,
                  //       decoration: tooltipDecoration,
                  //       textStyle: tooltipTextStyle,
                  //       child: IconButton(
                  //         key: widget.MyTaskIconKey,
                  //         padding: EdgeInsets.zero,
                  //         constraints: BoxConstraints(),
                  //         icon: Stack(
                  //           children: [
                  //             _buildAppBarAssetIcon(
                  //               context,
                  //               'assets/icons/AppBar/my-task.png',
                  //             ),
                  //             if (_hasOverdueTasks)
                  //               Positioned(
                  //                 right: 0,
                  //                 child: FadeTransition(
                  //                   opacity: _blinkAnimation,
                  //                   child: Container(
                  //                     width: 10,
                  //                     height: 10,
                  //                     decoration: BoxDecoration(
                  //                       color: alertColor,
                  //                       shape: BoxShape.circle,
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //           ],
                  //         ),
                  //         onPressed: () {
                  //           Navigator.push(
                  //             context,
                  //             MaterialPageRoute(
                  //               builder: (context) => MyTaskScreen(),
                  //             ),
                  //           );
                  //         },
                  //       ),
                  //     ),
                  //   ),

                  if (widget.showCalendarDashboard && _canReadCalendar)
                    Transform.translate(
                      offset: const Offset(6, 0),
                      child: Tooltip(
                        message:
                            AppLocalizations.of(context)!.translate('calendar'),
                        preferBelow: false,
                        decoration: tooltipDecoration,
                        textStyle: tooltipTextStyle,
                        child: IconButton(
                          key: widget.CalendarIconKey,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: _buildAppBarAssetIcon(
                            context,
                            'assets/icons/AppBar/calendar.png',
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CalendarScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (widget.showMenuIcon)
                    Transform.translate(
                        offset: const Offset(8, 0),
                        child: PopupMenuButton<String>(
                            key: widget.menuIconKey,
                            padding: EdgeInsets.zero,
                            position: PopupMenuPosition.under,
                            icon: Stack(
                              children: [
                                Icon(
                                  Icons.more_vert,
                                  color: _areFiltersActive
                                      ? filterIconColor
                                      : inactiveIconColor,
                                ),
                                if (_hasOverdueTasks)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: FadeTransition(
                                      opacity: _blinkAnimation,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: alertColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            color: context.appColors.surfacePrimary,
                            onSelected: (String value) {
                              switch (value) {
                                case 'filter_task':
                                  navigateToTaskManagerFilterScreen(context);
                                  break;
                                case 'filter_lead':
                                  navigateToLeadManagerFilterScreen(context);
                                  break;
                                case 'filter_deal':
                                  navigateToDealManagerFilterScreen(context);
                                  break;
                                case 'events':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventScreen(),
                                    ),
                                  );
                                  break;
                                // case 'my_tasks':
                                //   Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) => MyTaskScreen(),
                                //     ),
                                //   );
                                //   break;
                                case 'calendar':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CalendarScreen(),
                                    ),
                                  );
                                  break;
                                case 'call_center':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CallCenterScreen(),
                                    ),
                                  );
                                  break;
                                case 'timesheet':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TimesheetScreen(),
                                    ),
                                  );
                                  break;
                                case 'sip':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SipScreen(),
                                    ),
                                  );
                                  break;
                                case 'sales_planning':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SalesPlanningScreen(),
                                    ),
                                  );
                                  break;
                                case 'projects':
                                  widget.onProjectsPressed?.call();
                                  break;
                                case 'filter_dashboard':
                                  widget.onDashboardFilterPressed?.call();
                                  break;
                                case 'dashboard_chart_settings':
                                  widget.onDashboardChartSettingsPressed
                                      ?.call();
                                  break;
                                // case 'gps':
                                //   Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) => MusicPage(),
                                //     ),
                                //   );
                                //   break;
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                                  if (widget.showDashboardChartSettingsMenuItem)
                                    PopupMenuItem<String>(
                                      value: 'dashboard_chart_settings',
                                      child: Row(
                                        children: [
                                          Icon(Icons.tune_rounded,
                                              color: filterIconColor),
                                          SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .translate(
                                                    'analytics_crm_settings'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (widget.showDashboardFilterMenuItem)
                                    PopupMenuItem<String>(
                                      value: 'filter_dashboard',
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/icons/AppBar/filter.png',
                                            width: 24,
                                            height: 24,
                                            color:
                                                widget.hasActiveDashboardFilters
                                                    ? activeIconColor
                                                    : filterIconColor,
                                          ),
                                          SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('filtr')),
                                        ],
                                      ),
                                    ),
                                  if (widget.showFilterIcon)
                                    PopupMenuItem<String>(
                                      value: 'filter_lead',
                                      child: Row(
                                        children: [
                                          _isFiltering
                                              ? Icon(Icons.close,
                                                  color: filterIconColor)
                                              : _buildAppBarAssetIcon(
                                                  context,
                                                  'assets/icons/AppBar/filter.png',
                                                  color: widget
                                                          .hasActiveLeadFilters
                                                      ? activeIconColor
                                                      : filterIconColor,
                                                ),
                                          SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('filtr')),
                                        ],
                                      ),
                                    ),
                                  if (widget.showFilterIconDeal)
                                    PopupMenuItem<String>(
                                      value: 'filter_deal',
                                      child: Row(
                                        children: [
                                          _isFiltering
                                              ? Icon(Icons.close,
                                                  color: filterIconColor)
                                              : _buildAppBarAssetIcon(
                                                  context,
                                                  'assets/icons/AppBar/filter.png',
                                                  color: filterIconColor,
                                                ),
                                          SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('filter')),
                                        ],
                                      ),
                                    ),
                                  if (widget.showEvent && _canReadNotice)
                                    PopupMenuItem<String>(
                                      value: 'events',
                                      child: Row(
                                        children: [
                                          Icon(Icons.event),
                                          SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('events')),
                                        ],
                                      ),
                                    ),
                                  if (widget.showFilterTaskIcon)
                                    PopupMenuItem<String>(
                                      value: 'filter_task',
                                      child: Row(
                                        children: [
                                          _isTaskFiltering
                                              ? Icon(Icons.close,
                                                  color: filterIconColor)
                                              : _buildAppBarAssetIcon(
                                                  context,
                                                  'assets/icons/AppBar/filter.png',
                                                  color: widget
                                                          .hasActiveTaskFilters
                                                      ? activeIconColor
                                                      : filterIconColor,
                                                ),
                                          SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('filtr')),
                                        ],
                                      ),
                                    ),
                                  if (widget.showProjectsMenuItem)
                                    PopupMenuItem<String>(
                                      value: 'projects',
                                      child: Row(
                                        children: [
                                          Icon(Icons.folder_outlined,
                                              color: inactiveIconColor),
                                          SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('appbar_projects')),
                                        ],
                                      ),
                                    ),
                                  // if (widget.showMyTaskIcon)
                                  //   PopupMenuItem<String>(
                                  //     value: 'my_tasks',
                                  //     child: Row(
                                  //       children: [
                                  //         Stack(
                                  //           children: [
                                  //             _buildAppBarAssetIcon(
                                  //               context,
                                  //               'assets/icons/AppBar/my-task.png',
                                  //             ),
                                  //             if (_hasOverdueTasks)
                                  //               Positioned(
                                  //                 right: 0,
                                  //                 child: FadeTransition(
                                  //                   opacity: _blinkAnimation,
                                  //                   child: Container(
                                  //                     width: 10,
                                  //                     height: 10,
                                  //                     decoration: BoxDecoration(
                                  //                       color: alertColor,
                                  //                       shape: BoxShape.circle,
                                  //                     ),
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //           ],
                                  //         ),
                                  //         SizedBox(width: 8),
                                  //         Text(AppLocalizations.of(context)!
                                  //             .translate('appbar_my_tasks')),
                                  //       ],
                                  //     ),
                                  //   ),
                                  if (widget.showCalendar && _canReadCalendar)
                                    PopupMenuItem<String>(
                                      value: 'calendar',
                                      child: Row(
                                        children: [
                                          _buildAppBarAssetIcon(
                                            context,
                                            'assets/icons/AppBar/calendar.png',
                                          ),
                                          SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('calendar')),
                                        ],
                                      ),
                                    ),
                                  // В методе build внутри PopupMenuButton, замените пункт 'call_center' на:
                                  if (widget.showCallCenter &&
                                      _canReadCallCenter)
                                    PopupMenuItem<String>(
                                      value: 'call_center',
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/icons/AppBar/call_center.png',
                                            width: 24,
                                            height: 24,
                                            color: inactiveIconColor,
                                          ),
                                          SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('call_center')),
                                        ],
                                      ),
                                    ),
                                  if (_canOpenTimesheet)
                                    PopupMenuItem<String>(
                                      value: 'timesheet',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.badge_outlined),
                                          const SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('appbar_timesheet')),
                                        ],
                                      ),
                                    ),
                                  if (kShowSip && _canReadCallCenter)
                                    PopupMenuItem<String>(
                                      value: 'sip',
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.phone_in_talk_outlined),
                                          const SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('appbar_sip')),
                                        ],
                                      ),
                                    ),
                                  if (kShowSalesPlanning &&
                                      _canReadSalesPlanning)
                                    PopupMenuItem<String>(
                                      value: 'sales_planning',
                                      child: Row(
                                        children: [
                                          Icon(Icons.flag_outlined,
                                              color: inactiveIconColor),
                                          const SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!
                                              .translate('sales_planning')),
                                        ],
                                      ),
                                    ),
                                  // if (widget.showGps && _canReadGps) // Новый пункт для GPS
                                  //             PopupMenuItem<String>(
                                  //               value: 'gps',
                                  //               child: Row(
                                  //                 children: [
                                  //                   Image.asset(
                                  //                     'assets/icons/AppBar/call_center.png', // Предполагаемый путь к иконке
                                  //                     width: 24,
                                  //                     height: 24,
                                  //                     color: _iconColor,
                                  //                   ),
                                  //                   SizedBox(width: 8),
                                  //                   Text(AppLocalizations.of(context)!.translate('gps')),
                                  //                 ],
                                  //               ),
                                  //             ),
                                ]))
                ]))
            : null);
  }

  bool _hasTrailingActions() {
    return widget.showFilterIconOnSelectCallCenter ||
        widget.showSearchIcon ||
        widget.showNotification ||
        widget.showFilterIconChat ||
        widget.showFilterIconTaskChat ||
        widget.showDashboardIcon ||
        widget.showFilterIconEvent ||
        widget.showFilterIconOnSelectLead ||
        widget.showFilterIconOnSelectDeal ||
        widget.showFilterIconOnSelectTask ||
        widget.showSeparateMyTasks ||
        (widget.showCalendarDashboard && _canReadCalendar) ||
        widget.showMenuIcon;
  }

  void navigateToLeadManagerFilterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerFilterScreen(
          onManagersSelected: widget.onManagersLeadSelected,
          initialManagers: widget.initialManagersLead,
          initialRegions: widget.initialManagersLeadRegions,
          initialState: widget.initialManagersLeadState,
          initialCities: widget.initialManagersLeadCities,
          initialSources: widget.initialManagersLeadSources,
          initialChannels: widget.initialManagersLeadChannels,
          initialAdvertisingCampaigns:
              widget.initialManagersLeadAdvertisingCampaigns,
          initialReasonForRefusalIds:
              widget.initialManagersLeadReasonForRefusalIds,
          initialStatuses: widget.initialManagerLeadStatuses,
          initialFromDate: widget.initialManagerLeadFromDate,
          initialToDate: widget.initialManagerLeadToDate,
          initialHasSuccessDeals: widget.initialManagerLeadHasSuccessDeals,
          initialHasInProgressDeals:
              widget.initialManagerLeadHasInProgressDeals,
          initialHasFailureDeals: widget.initialManagerLeadHasFailureDeals,
          initialHasNotices: widget.initialManagerLeadHasNotices,
          initialHasContact: widget.initialManagerLeadHasContact,
          initialHasChat: widget.initialManagerLeadHasChat,
          initialHasNoReplies: widget.initialManagerLeadHasNoReplies,
          initialHasUnreadMessages: widget.initialManagerLeadHasUnreadMessages,
          initialHasDeal: widget.initialManagerLeadHasDeal,
          initialHasOrders: widget.initialManagerLeadHasOrders,
          initialDaysWithoutActivity:
              widget.initialManagerLeadDaysWithoutActivity,
          initialNumberOfDaysDeal: widget.initialManagerLeadNumberOfDaysDeal,
          onResetFilters: widget.onLeadResetFilters,
          initialDirectoryValues:
              _safeConvertToMapList(widget.initialDirectoryValuesLead),
        ),
      ),
    );
  }

  void navigateToDealManagerFilterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DealManagerFilterScreen(
          onManagersSelected: widget.onManagersDealSelected,
          onLeadsSelected: widget.onLeadsDealSelected,
          onStatusSelected: widget.onStatusDealSelected,
          onDateRangeSelected: widget.onDateRangeDealSelected,
          onStatusAndDateRangeSelected: widget.onStatusAndDateRangeDealSelected,
          initialManagers: widget.initialManagersDeal,
          initialRegions: widget.initialRegionsDeal,
          initialState: widget.initialStateDeal,
          initialCities: widget.initialCitiesDeal,
          initialExecutors: widget.initialExecutorsDeal,
          initialSources: widget.initialSourcesDeal,
          initialLeads: widget.initialLeadsDeal,
          initialHasTasks: widget.initialManagerDealHasTasks,
          initialWithoutNotices: widget.initialManagerDealWithoutNotices,
          initialOverdueNotices: widget.initialManagerDealOverdueNotices,
          initialLeadStatuses: widget.initialLeadStatusesDeal,
          initialReasonForRefusalIds: widget.initialReasonForRefusalIdsDeal,
          initialStatuses: widget.initialManagerDealStatuses,
          initialFromDate: widget.initialManagerDealFromDate,
          initialToDate: widget.initialManagerDealToDate,
          onResetFilters: widget.onDealResetFilters,
          initialDealNames: widget.initialDealNames, // Передаем новый параметр
          initialDaysWithoutActivity:
              widget.initialManagerDealDaysWithoutActivity,
          initialDirectoryValues:
              _safeConvertToMapList(widget.initialDirectoryValuesDeal),
        ),
      ),
    );
  }

  void navigateToTaskManagerFilterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFilterScreen(
          onUsersSelected: widget.onUsersSelected,
          onStatusSelected: widget.onStatusSelected,
          onDateRangeSelected: widget.onDateRangeSelected,
          onStatusAndDateRangeSelected: widget.onStatusAndDateRangeSelected,
          initialUsers: widget.initialUsers,
          initialStatuses: widget.initialStatuses,
          initialFromDate: widget.initialFromDate,
          initialToDate: widget.initialToDate,
          initialIsOverdue: widget.initialTaskIsOverdue,
          initialHasFile: widget.initialTaskHasFile,
          initialHasDeal: widget.initialTaskHasDeal,
          initialIsUrgent: widget.initialTaskIsUrgent,
          onResetFilters: widget.onResetFilters,
          initialAuthors: widget.initialAuthors,
          initialDepartment: widget.initialDepartment,
          initialDeadlineFromDate: widget.initialDeadlineFromDate,
          initialDeadlineToDate: widget.initialDeadlineToDate,
          initialCompletedFromDate: widget.initialCompletedFromDate,
          initialCompletedToDate: widget.initialCompletedToDate,
          initialReasonForRefusalIds: widget.initialReasonForRefusalIdsTask,
          initialDirectoryValues:
              _safeConvertToMapList(widget.initialDirectoryValuesTask),
          initialProjects: widget.initialProjects,
        ),
      ),
    );
  }
}
