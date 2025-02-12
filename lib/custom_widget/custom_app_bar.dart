import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/manager_app_bar_deal.dart';
import 'package:crm_task_manager/custom_widget/filter/event/manager_app_bar_event.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/manager_app_bar_lead.dart';
import 'package:crm_task_manager/custom_widget/filter/task/user_app_bar_task.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/notifications_screen.dart';
import 'package:crm_task_manager/screens/event/event_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatefulWidget {
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
  final bool showFilterIconDeal;
  final bool showFilterTaskIcon;
  final bool showEvent;
  final bool showSeparateTaskFilter;
  final bool showSeparateMyTasks;
  final bool showNotification;
  final Function(Map)? onManagersLeadSelected;
  final Function(int?)? onStatusLeadSelected;
  final Function(DateTime?, DateTime?)? onDateRangeLeadSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeLeadSelected;

  final Function(Map)? onManagersDealSelected;
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
  final int? initialManagerLeadStatuses;
  final DateTime? initialManagerLeadFromDate;
  final DateTime? initialManagerLeadToDate;

  final List? initialManagersDeal;
  final int? initialManagerDealStatuses;
  final DateTime? initialManagerDealFromDate;
  final DateTime? initialManagerDealToDate;

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

  final bool showMyTaskIcon;
  final bool showMenuIcon;
  final bool showSeparateFilter;

  final bool? initialTaskIsOverdue;
  final bool? initialTaskHasFile;
  final bool? initialTaskHasDeal;
  final bool? initialTaskIsUrgent;
  final DateTime? initialTaskDeadline;
  CustomAppBar({
    super.key,
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
    this.initialManagerLeadStatuses,
    this.initialManagerLeadFromDate,
    this.initialManagerLeadToDate,
    this.initialManagersDeal,
    this.initialManagerDealStatuses,
    this.initialManagerDealFromDate,
    this.initialManagerDealToDate,
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
    this.showFilterIconDeal = true,
    this.showFilterTaskIcon = true,
    this.onManagersLeadSelected,
    this.onStatusLeadSelected,
    this.onDateRangeLeadSelected,
    this.onStatusAndDateRangeLeadSelected,
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
     this.initialTaskIsOverdue,
    this.initialTaskHasFile,
    this.initialTaskHasDeal,
    this.initialTaskIsUrgent,
    this.initialTaskDeadline,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;

  late TextEditingController _searchController;
  late FocusNode focusNode;
  String _userImage = '';
  String _lastLoadedImage = '';
  static String _cachedUserImage = '';
  bool _isFiltering = false;
  bool _isTaskFiltering = false;
  bool _hasNewNotification = false;
  late PusherChannelsClient socketClient;
  late StreamSubscription<ChannelReadEvent> notificationSubscription;
  Timer? _checkOverdueTimer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  bool _showCustomTabBar = true;
  bool _hasOverdueTasks = false;

  @override
  void initState() {
    super.initState();

    _searchController = widget.textEditingController;
    focusNode = widget.focusNode;

    if (_cachedUserImage.isNotEmpty) {
      _userImage = _cachedUserImage;
    } else {
      _loadUserProfile();
    }

    _loadNotificationState();
    _setUpSocketForNotifications();

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
      print('Error checking overdue tasks: $e');
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _checkOverdueTimer?.cancel();

    super.dispose();
  }

  Future<void> _loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
    setState(() {
      _hasNewNotification = hasNewNotification;
    });
  }

  Future<void> _setUpSocketForNotifications() async {
    debugPrint('--------------------------- start socket CUSTOM APPBAR:::::::----------------');
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final baseUrlSocket = await ApiService().getSocketBaseUrl();
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

    String userId = prefs.getString('userID') ?? '';

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
          debugPrint(exception);
        },
      ),
    );

    socketClient.onConnectionEstablished.listen((_) {
      myPresenceChannel.subscribeIfNotUnsubscribed();
      notificationSubscription =
          myPresenceChannel.bind('notification.created').listen((event) {
        debugPrint('Received notification: ${event.data}');
        setState(() {
          _hasNewNotification = true;
        });
        prefs.setBool('hasNewNotification', true);
      });
    });

    try {
      await socketClient.connect();
      print('Socket connection SUCCESSS');
    } catch (e) {
      if (kDebugMode) {
        print('Socket connection error!');
      }
    }
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
      print('Ошибка при загрузке изображения!');
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
        // Конвертируем hex в Color
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
          if (!_isSearching)
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xfff1E2E52),
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
          if (widget.showNotification)
            Transform.translate(
              offset: const Offset(10, 0), // Сдвигаем вправо
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
                  padding: EdgeInsets.zero, // Убираем внутренние отступы
                  constraints:
                      BoxConstraints(), // Убираем стандартные ограничения
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
          if (widget.showSearchIcon)
            Transform.translate(
              offset: const Offset(10, 0), // Сдвигаем немного вправо
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
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero, // Убираем внутренние отступы
                  constraints:
                      BoxConstraints(), // Убираем стандартные ограничения
                  icon: _isSearching
                      ? Icon(Icons.close)
                      : Image.asset(
                          'assets/icons/AppBar/search.png',
                          width: 24,
                          height: 24,
                        ),
                  onPressed: () {
                    _toggleSearch();
                    widget.clearButtonClick(_isSearching);
                    if (_isSearching) {
                      FocusScope.of(context).requestFocus(focusNode);
                    }
                  },
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
                icon: _isFiltering
                    ? Icon(Icons.close)
                    : Image.asset(
                        'assets/icons/AppBar/filter.png',
                        width: 24,
                        height: 24,
                      ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventManagerFilterScreen(
                        onManagersSelected: widget.onManagersEventSelected,
                        onStatusSelected: widget.onStatusEventSelected,
                        onDateRangeSelected: widget.onDateRangeEventSelected,
                        onStatusAndDateRangeSelected:
                            widget.onStatusAndDateRangeEventSelected,
                        onNoticeDateRangeSelected:
                            widget.onNoticeDateRangeEventSelected,
                        onNoticeStatusAndDateRangeSelected:
                            widget.onNoticeStatusAndDateRangeEventSelected,
                        onDateNoticeStatusAndDateRangeSelected:
                            widget.onDateNoticeStatusAndDateRangeSelected,
                        onDateNoticeAndDateRangeSelected:
                            widget.onDateNoticeAndDateRangeSelected,
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
          if (widget.showSeparateMyTasks)
            Transform.translate(
              offset: const Offset(6, 0), // Сдвиг вправо на 4 пикселя
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
                  padding: EdgeInsets.zero, // Убираем внутренние отступы
                  constraints:
                      BoxConstraints(), // Убираем стандартные ограничения
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
          if (widget.showMenuIcon)
            Transform.translate(
              offset: const Offset(8, 0), // Сдвигаем вправо
              child: PopupMenuButton<String>(
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserFilterScreen(
                            onUsersSelected: widget.onUsersSelected,
                            onStatusSelected: widget.onStatusSelected,
                            onDateRangeSelected: widget.onDateRangeSelected,
                            onStatusAndDateRangeSelected:
                                widget.onStatusAndDateRangeSelected,
                            initialUsers: widget.initialUsers,
                            initialStatuses: widget.initialStatuses,
                            initialFromDate: widget.initialFromDate,
                            initialToDate: widget.initialToDate,
                            initialIsOverdue: widget.initialTaskIsOverdue,
                            initialHasFile: widget.initialTaskHasFile,
                            initialHasDeal: widget.initialTaskHasDeal,
                            initialIsUrgent: widget.initialTaskIsUrgent,
                            initialDeadline: widget.initialTaskDeadline,
                            onResetFilters: widget.onResetFilters,
                          ),
                        ),
                      );
                      break;
                    case 'filter_lead':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManagerFilterScreen(
                            onManagersSelected: widget.onManagersLeadSelected,
                            onStatusSelected: widget.onStatusLeadSelected,
                            onDateRangeSelected: widget.onDateRangeLeadSelected,
                            onStatusAndDateRangeSelected:
                                widget.onStatusAndDateRangeLeadSelected,
                            initialManagers: widget.initialManagersLead,
                            initialStatuses: widget.initialManagerLeadStatuses,
                            initialFromDate: widget.initialManagerLeadFromDate,
                            initialToDate: widget.initialManagerLeadToDate,
                            onResetFilters: widget.onLeadResetFilters,
                          ),
                        ),
                      );
                      break;
                    case 'filter_deal':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealManagerFilterScreen(
                            onManagersSelected: widget.onManagersDealSelected,
                            onStatusSelected: widget.onStatusDealSelected,
                            onDateRangeSelected: widget.onDateRangeDealSelected,
                            onStatusAndDateRangeSelected:
                                widget.onStatusAndDateRangeDealSelected,
                            initialManagers: widget.initialManagersDeal,
                            initialStatuses: widget.initialManagerDealStatuses,
                            initialFromDate: widget.initialManagerDealFromDate,
                            initialToDate: widget.initialManagerDealToDate,
                            onResetFilters: widget.onDealResetFilters,
                          ),
                        ),
                      );
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
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (widget.showFilterIcon)
                    PopupMenuItem<String>(
                      value: 'filter_lead',
                      child: Row(
                        children: [
                          _isFiltering
                              ? Icon(Icons.close)
                              : Image.asset(
                                  'assets/icons/AppBar/filter.png',
                                  width: 24,
                                  height: 24,
                                ),
                          SizedBox(width: 8),
                          Text(
                              AppLocalizations.of(context)!.translate('filtr')),
                        ],
                      ),
                    ),
                  if (widget.showFilterIconDeal)
                    PopupMenuItem<String>(
                      value: 'filter_deal',
                      child: Row(
                        children: [
                          _isFiltering
                              ? Icon(Icons.close)
                              : Image.asset(
                                  'assets/icons/AppBar/filter.png',
                                  width: 24,
                                  height: 24,
                                ),
                          SizedBox(width: 8),
                          Text(
                              AppLocalizations.of(context)!.translate('filtr')),
                        ],
                      ),
                    ),
                  if (widget.showEvent)
                    PopupMenuItem<String>(
                      value: 'events',
                      child: Row(
                        children: [
                          Icon(Icons.event), // Иконка всегда отображается
                          SizedBox(width: 8), // Отступ между иконкой и текстом
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
                              ? Icon(Icons.close)
                              : Image.asset(
                                  'assets/icons/AppBar/filter.png',
                                  width: 24,
                                  height: 24,
                                ),
                          SizedBox(width: 8),
                          Text(
                              AppLocalizations.of(context)!.translate('filtr')),
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
                ],
              ),
            ),
        ]));
  }
}
