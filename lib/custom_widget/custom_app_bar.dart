import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/calendar/calendar_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/call_center_filter_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/chat/lead/chat_lead_filter_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/chat/task/chat_task_filter_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/manager_app_bar_deal.dart';
import 'package:crm_task_manager/custom_widget/filter/event/manager_app_bar_event.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/manager_app_bar_lead.dart';
import 'package:crm_task_manager/custom_widget/filter/task/user_app_bar_task.dart';
import 'package:crm_task_manager/custom_widget/gps_screen_for_admin.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/notifications_screen.dart';
import 'package:crm_task_manager/page_2/call_center/call_center_screen.dart';
import 'package:crm_task_manager/screens/event/event_screen.dart';
import 'package:crm_task_manager/screens/gps/background_location_service.dart';
import 'package:crm_task_manager/screens/my-task/my_task_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
  final List? initialManagersLeadSources;
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
  final List<Map<String, dynamic>>?
  initialDirectoryValuesLead; // Новый параметр для лидов
  final Map<String, List<String>>?
  initialLeadCustomFields; // Пользовательские поля для фильтра лидов

  final List? initialManagersDeal;
  final List? initialLeadsDeal;
  final int? initialManagerDealStatuses;
  final DateTime? initialManagerDealFromDate;
  final DateTime? initialManagerDealToDate;
  final bool? initialManagerDealHasTasks;
  final int? initialManagerDealDaysWithoutActivity;
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
  final bool showSeparateFilter;

  final bool? initialTaskIsOverdue;
  final bool? initialTaskHasFile;
  final bool? initialTaskHasDeal;
  final bool? initialTaskIsUrgent;
  final DateTime? initialDeadlineFromDate;
  final DateTime? initialDeadlineToDate;
  final List<String>? initialAuthors;
  final String? initialDepartment;
  final List<Map<String, dynamic>>?
  initialDirectoryValuesTask; // Добавляем начальные значения справочников

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
    this.initialManagersLeadSources,
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
    this.initialLeadsDeal,
    this.initialManagerDealStatuses,
    this.initialManagerDealFromDate,
    this.initialManagerDealToDate,
    this.initialManagerDealHasTasks,
    this.initialManagerDealDaysWithoutActivity,
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
    this.initialAuthors,
    this.initialDepartment,
    this.onLeadsDealSelected,
    this.initialDirectoryValuesDeal, // Добавляем в конструктор

    this.titleWidget, // Добавляем в конструктор
    this.onFiltersReset,
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
  late PusherChannelsClient socketClient;
  StreamSubscription<ChannelReadEvent>? notificationSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _checkOverdueTimer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  bool _hasOverdueTasks = false;
  bool _canReadCallCenter = false;
  bool _canReadNotice = false;
  bool _canReadCalendar = false;
  bool _canReadGps = false; // Новая переменная для GPS®
  // DEAL custom fields were moved to filter screen

  Color _iconColor = const Color.fromARGB(255, 0, 0, 0);
  late Timer _timer;
  bool _areFiltersActive = false; // Добавляем эту переменную

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
    _iconColor = _areFiltersActive ? Colors.blue : Colors.black;
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
          _iconColor = (_iconColor == Colors.blue) ? Colors.black : Colors.blue;
        });
      } else {
        setState(() {
          _iconColor = Colors.black; // Возвращаем черный цвет когда фильтры неактивны
        });
      }
    });
  }

  void _setFiltersActive(bool active) {
    setState(() {
      _areFiltersActive = active;
      if (!active) {
        _iconColor = Colors.black; // Сразу устанавливаем черный цвет при сбросе
      }
    });
  }

// Метод для проверки активности фильтров (можно вызывать извне)
  void resetFilterIconState() {
    _setFiltersActive(false);
  }

  void _setupFirebaseMessaging() async {
    final prefs = await SharedPreferences.getInstance();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Получено push-уведомление: ${message.data}');
      if (message.data['type'] == 'message') {
        setState(() {
          _hasNewNotification = true;
        });
        prefs.setBool('hasNewNotification', true);
        _playSound();
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Push-уведомление открыто: ${message.data}');
      if (message.data['type'] == 'message') {
        setState(() {
          _hasNewNotification = true;
        });
        prefs.setBool('hasNewNotification', true);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationsScreen()),
        );
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
  void dispose() {
    _blinkController.dispose();
    _checkOverdueTimer?.cancel();
    _timer.cancel();
    notificationSubscription?.cancel();
    socketClient.disconnect();

    super.dispose();
  }

// Обновляем обработчик сброса фильтров
  void _handleChatFiltersReset() {
    debugPrint('CustomAppBar: Resetting chat filters');
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
    debugPrint(
        '--------------------------- start socket CUSTOM APPBAR:::::::----------------');
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

    socketClient = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {},
      minimumReconnectDelayDuration: const Duration(seconds: 1),
    );

    String userId = prefs.getString('unique_id') ?? '';
    //debugPrint('userID--------------------------------------------------popopop-p : $userId');
    //debugPrint(userId);

    final myPresenceChannel = socketClient.presenceChannel(
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
          debugPrint('Auth failed: ${exception.toString()}');
        },
      ),
    );

    socketClient.onConnectionEstablished.listen((_) {
      myPresenceChannel.subscribeIfNotUnsubscribed();
      notificationSubscription =
          myPresenceChannel.bind('notification.created').listen((event) {
            debugPrint('Получено уведомление через сокет: ${event.data}');
            try {
              final data = jsonDecode(event.data);
              debugPrint('Данные уведомления: $data');
              setState(() {
                _hasNewNotification = true;
              });
              prefs.setBool('hasNewNotification', true);
              _playSound();
            } catch (e) {
              debugPrint('Ошибка парсинга данных уведомления: $e');
            }
          });
    });

    try {
      await socketClient.connect();
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
    setState(() {
      _canReadNotice = canReadNotice;
      _canReadCalendar = canReadCalendar;
      _canReadCallCenter = canReadCallCenter;
      _canReadCallCenter = canReadCallCenter;
      _canReadGps = canReadGps;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String UUID = prefs.getString('userID') ??
          AppLocalizations.of(context)!.translate('not_found');

      UserByIdProfile userProfile =
      await ApiService().getUserById(int.parse(UUID));

      if (userProfile.image != null && userProfile.image != _lastLoadedImage) {
        setState(() {
          _userImage = userProfile.image!;
          _lastLoadedImage = userProfile.image!;
          _cachedUserImage = userProfile.image!;
        });

        await prefs.setString('userProfileImage_$UUID', _userImage);
      } else if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        setState(() {
          _userImage = _cachedUserImage;
        });
      }
    } catch (e) {
      //debugPrint('Ошибка при загрузке изображения!');
      if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
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
              color: Colors.white,
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
                  style: TextStyle(
                    color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: kToolbarHeight,
        color: Colors.white,
        padding: EdgeInsets.zero,
        child: Row(children: [
          // Аватар пользователя
          Container(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: _buildAvatarImage(_userImage),
              onPressed: widget.onClickProfileAvatar,
            ),
          ),
          SizedBox(width: 8),

          // Заголовок
          if (!_isSearching)
            Expanded(
              child: widget.titleWidget ??
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
            ),
          if (_isSearching)
            Expanded(
              child: AnimatedContainer(
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
                  ),
                  style: TextStyle(fontSize: 16),
                  autofocus: true,
                ),
              ),
            ),

          // Иконка фильтра (первая в порядке)
          if (widget.showFilterIconOnSelectCallCenter)
            Transform.translate(
              offset: const Offset(10, 0),
              child: Tooltip(
                message: AppLocalizations.of(context)!.translate('filter'),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/AppBar/filter.png',
                    width: 24,
                    height: 24,
                    color: _iconColor, // Анимация цвета
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
                message: AppLocalizations.of(context)!.translate('search'),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  key: widget.SearchIconKey,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: _isSearching
                      ? Icon(Icons.close)
                      : Image.asset(
                    'assets/icons/AppBar/search.png',
                    width: 24,
                    height: 24,
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
                message:
                AppLocalizations.of(context)!.translate('notification'),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  key: widget.NotificationIconKey,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Stack(
                    children: [
                      Image.asset(
                        'assets/icons/AppBar/notification.png',
                        width: 24,
                        height: 24,
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
                                color: Colors.red,
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
                message: AppLocalizations.of(context)!.translate('filter'),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/AppBar/filter.png',
                    width: 24,
                    height: 24,
                    // ОБНОВЛЯЕМ: Цвет иконки зависит от активности фильтров
                    color:
                    widget.hasActiveChatFilters ? Colors.blue : _iconColor,
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
                          initialToDate: widget.initialChatFilters?['toDate'],
                          initialHasSuccessDeals:
                          widget.initialChatFilters?['hasSuccessDeals'],
                          initialHasInProgressDeals:
                          widget.initialChatFilters?['hasInProgressDeals'],
                          initialHasFailureDeals:
                          widget.initialChatFilters?['hasFailureDeals'],
                          initialHasNotices:
                          widget.initialChatFilters?['hasNotices'],
                          initialHasContact:
                          widget.initialChatFilters?['hasContact'],
                          initialHasChat: widget.initialChatFilters?['hasChat'],
                          initialHasNoReplies:
                          widget.initialChatFilters?['hasNoReplies'],
                          initialHasUnreadMessages:
                          widget.initialChatFilters?['hasUnreadMessages'],
                          initialHasDeal: widget.initialChatFilters?['hasDeal'],
                          // initialHasOrders: widget.initialChatFilters?['hasOrders'],
                          initialDaysWithoutActivity:
                          widget.initialChatFilters?['daysWithoutActivity'],
                          initialDirectoryValues: _safeConvertToMapList(
                              widget.initialChatFilters?['directory_values']),
                          initialSalesFunnelId: widget.currentSalesFunnelId ??
                              widget.initialChatFilters?[
                              'current_sales_funnel_id'] ??
                              widget.initialChatFilters?['sales_funnel_id'],
                          onManagersSelected: widget.onChatLeadFiltersApplied,
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
                message:
                AppLocalizations.of(context)!.translate('task_filters'),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/AppBar/filter.png',
                    width: 24,
                    height: 24,
                    color:
                    widget.hasActiveChatFilters ? Colors.blue : _iconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isTaskFiltering = !_isTaskFiltering;
                      _setFiltersActive(
                          _isTaskFiltering && widget.hasActiveChatFilters);
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
                            final authorIds =
                            widget.initialChatFilters?['author_ids'];
                            if (authorIds is List && authorIds.isNotEmpty) {
                              return authorIds
                                  .map((id) => id.toString())
                                  .toList();
                            }
                            return [];
                          }(),

                          initialProjects: () {
                            final projectIds =
                            widget.initialChatFilters?['project_ids'];
                            if (projectIds is List && projectIds.isNotEmpty) {
                              return projectIds
                                  .map((id) => id.toString())
                                  .toList();
                            }
                            return [];
                          }(),
                          initialStatuses: (widget.initialChatFilters?[
                          'task_status_ids'] as List<dynamic>?)
                              ?.cast<int>()
                              .isNotEmpty ==
                              true
                              ? (widget.initialChatFilters!['task_status_ids']
                          as List<dynamic>)
                              .cast<int>()
                              .first
                              : null,
                          initialFromDate:
                          widget.initialChatFilters?['task_created_from'] !=
                              null
                              ? DateTime.parse(widget
                              .initialChatFilters!['task_created_from'])
                              : null,
                          initialToDate: widget
                              .initialChatFilters?['task_created_to'] !=
                              null
                              ? DateTime.parse(
                              widget.initialChatFilters!['task_created_to'])
                              : null,
                          initialDeadlineFromDate: widget
                              .initialChatFilters?['deadline_from'] !=
                              null
                              ? DateTime.parse(
                              widget.initialChatFilters!['deadline_from'])
                              : null,
                          initialDeadlineToDate:
                          widget.initialChatFilters?['deadline_to'] != null
                              ? DateTime.parse(
                              widget.initialChatFilters!['deadline_to'])
                              : null,
                          initialDepartment: widget
                              .initialChatFilters?['department_id']
                              ?.toString(),
                          initialTaskNumber:
                          widget.initialChatFilters?['task_number'],
                          initialUnreadOnly:
                          widget.initialChatFilters?['unread_only'] ??
                              false,
                          onUsersSelected: widget.onChatTaskFiltersApplied,
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
                message: AppLocalizations.of(context)!.translate('dashboard'),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/MyNavBar/dashboard_OFF.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: widget.onDashboardPressed,
                ),
              ),
            ),
          if (widget.showFilterIconEvent)
            Tooltip(
              message: AppLocalizations.of(context)!.translate('search'),
              preferBelow: false,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              textStyle: TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
              child: IconButton(
                key: widget.FiltrEventIconKey,
                icon: Image.asset(
                  'assets/icons/AppBar/filter.png',
                  width: 24,
                  height: 24,
                  color: widget.hasActiveEventFilters ? Colors.blue : _iconColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventManagerFilterScreen(
                        onManagersSelected: widget.onManagersEventSelected,
                        initialManagers: widget.initialManagersEvent,
                        initialStatuses: widget.initialManagerEventStatuses,
                        initialFromDate: widget.initialManagerEventFromDate,
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
                  color: _iconColor,
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
                  color: _iconColor,
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
                  color: _iconColor,
                ),
              ),
              onPressed: () {
                navigateToTaskManagerFilterScreen(context);
              },
            ),
          if (widget.showSeparateMyTasks)
            Transform.translate(
              offset: const Offset(6, 0),
              child: Tooltip(
                message:
                AppLocalizations.of(context)!.translate('appbar_my_tasks'),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  key: widget.MyTaskIconKey,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Stack(
                    children: [
                      Image.asset(
                        'assets/icons/AppBar/my-task.png',
                        width: 24,
                        height: 24,
                      ),
                      if (_hasOverdueTasks)
                        Positioned(
                          right: 0,
                          child: FadeTransition(
                            opacity: _blinkAnimation,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyTaskScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

          if (widget.showCalendarDashboard && _canReadCalendar)
            Transform.translate(
              offset: const Offset(6, 0),
              child: Tooltip(
                message: AppLocalizations.of(context)!.translate('calendar'),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  key: widget.CalendarIconKey,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/AppBar/calendar.png',
                    width: 24,
                    height: 24,
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
                        Icon(Icons.more_vert),
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
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    color: Colors.white,
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
                        case 'my_tasks':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyTaskScreen(),
                            ),
                          );
                          break;
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
                      if (widget.showFilterIcon)
                        PopupMenuItem<String>(
                          value: 'filter_lead',
                          child: Row(
                            children: [
                              _isFiltering
                                  ? Icon(Icons.close, color: _iconColor)
                                  : Image.asset(
                                'assets/icons/AppBar/filter.png',
                                width: 24,
                                height: 24,
                                color: _iconColor,
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
                                  ? Icon(Icons.close, color: _iconColor)
                                  : Image.asset(
                                'assets/icons/AppBar/filter.png',
                                width: 24,
                                height: 24,
                                color: _iconColor,
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
                                  ? Icon(Icons.close, color: _iconColor)
                                  : Image.asset(
                                'assets/icons/AppBar/filter.png',
                                width: 24,
                                height: 24,
                                color: _iconColor,
                              ),
                              SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!
                                  .translate('filtr')),
                            ],
                          ),
                        ),
                      if (widget.showMyTaskIcon)
                        PopupMenuItem<String>(
                          value: 'my_tasks',
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Image.asset(
                                    'assets/icons/AppBar/my-task.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  if (_hasOverdueTasks)
                                    Positioned(
                                      right: 0,
                                      child: FadeTransition(
                                        opacity: _blinkAnimation,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!
                                  .translate('appbar_my_tasks')),
                            ],
                          ),
                        ),
                      if (widget.showCalendar && _canReadCalendar)
                        PopupMenuItem<String>(
                          value: 'calendar',
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/AppBar/calendar.png',
                                width: 24,
                                height: 24,
                              ),
                              SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!
                                  .translate('calendar')),
                            ],
                          ),
                        ),
                      // В методе build внутри PopupMenuButton, замените пункт 'call_center' на:
                      if (widget.showCallCenter && _canReadCallCenter)
                        PopupMenuItem<String>(
                          value: 'call_center',
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/AppBar/call_center.png',
                                width: 24,
                                height: 24,
                                color:
                                _iconColor, // Добавляем изменение цвета иконки
                              ),
                              SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!
                                  .translate('call_center')),
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
        ]));
  }

  void navigateToLeadManagerFilterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerFilterScreen(
          onManagersSelected: widget.onManagersLeadSelected,
          initialManagers: widget.initialManagersLead,
          initialRegions: widget.initialManagersLeadRegions,
          initialSources: widget.initialManagersLeadSources,
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
          initialLeads: widget.initialLeadsDeal,
          initialHasTasks: widget.initialManagerDealHasTasks,
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
          initialDirectoryValues:
          _safeConvertToMapList(widget.initialDirectoryValuesTask),
        ),
      ),
    );
  }
}
