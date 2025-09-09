// import 'dart:async';
// import 'dart:convert';
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/custom_widget/calendar/calendar_screen.dart';
// import 'package:crm_task_manager/custom_widget/filter/call_center/call_center_screen.dart';
// import 'package:crm_task_manager/custom_widget/filter/deal/manager_app_bar_deal.dart';
// import 'package:crm_task_manager/custom_widget/filter/event/manager_app_bar_event.dart';
// import 'package:crm_task_manager/custom_widget/filter/lead/manager_app_bar_lead.dart';
// import 'package:crm_task_manager/custom_widget/filter/task/user_app_bar_task.dart';
// import 'package:crm_task_manager/models/user_byId_model..dart';
// import 'package:crm_task_manager/notifications_screen.dart';
// import 'package:crm_task_manager/page_2/call_center/call_center_screen.dart';
// import 'package:crm_task_manager/screens/event/event_screen.dart';
// import 'package:crm_task_manager/screens/my-task/my_task_screen.dart';
// import 'package:crm_task_manager/screens/gps/gps_screen_for_admin.dart'; // Новый импорт
// import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
// import 'package:dart_pusher_channels/dart_pusher_channels.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class CustomAppBar extends StatefulWidget {
//   final GlobalKey? menuIconKey;
//   final GlobalKey? SearchIconKey;
//   final GlobalKey? FiltrEventIconKey;
//   final GlobalKey? NotificationIconKey;
//   final GlobalKey? MyTaskIconKey;
//   final GlobalKey? CalendarIconKey;
//   String title;
//   Function() onClickProfileAvatar;
//   FocusNode focusNode;
//   TextEditingController textEditingController;
//   ValueChanged<String>? onChangedSearchInput;
//   Function(bool) clearButtonClick;
//   Function(bool) clearButtonClickFiltr;
//   bool showSearchIcon;
//   bool showFilterIconEvent;
//   final bool showFilterIcon;
//   final bool showFilterIconOnSelectLead;
//   final bool showFilterIconOnSelectDeal;
//   final bool showFilterIconOnSelectTask;
//   final bool showFilterIconDeal;
//   final bool showFilterTaskIcon;
//   final bool showEvent;
//   final bool showSeparateTaskFilter;
//   final bool showSeparateMyTasks;
//   final bool showNotification;
//   final bool showCalendar;
//   final bool showCalendarDashboard;
//   final bool showCallCenter;
//   final bool showGps; // Новый параметр для GPS
//   final bool showFilterIconCallCenter;
//   final bool showFilterIconOnSelectCallCenter;
//   final Function(Map)? onManagersLeadSelected;
//   final Function(Map)? onManagersDealSelected;
//   final Function(Map)? onLeadsDealSelected;
//   final Function(int?)? onStatusDealSelected;
//   final Function(DateTime?, DateTime?)? onDateRangeDealSelected;
//   final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeDealSelected;
//   final Function(Map)? onManagersEventSelected;
//   final Function(int?)? onStatusEventSelected;
//   final Function(DateTime?, DateTime?)? onDateRangeEventSelected;
//   final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeEventSelected;
//   final Function(DateTime?, DateTime?)? onNoticeDateRangeEventSelected;
//   final Function(int?, DateTime?, DateTime?)? onNoticeStatusAndDateRangeEventSelected;
//   final Function(int?, DateTime?, DateTime?, DateTime?, DateTime?)? onDateNoticeStatusAndDateRangeSelected;
//   final Function(DateTime?, DateTime?, DateTime?, DateTime?)? onDateNoticeAndDateRangeSelected;
//   final Function(Map)? onUsersSelected;
//   final Function(int?)? onStatusSelected;
//   final Function(DateTime?, DateTime?)? onDateRangeSelected;
//   final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeSelected;
//   final List? initialUsers;
//   final int? initialStatuses;
//   final DateTime? initialFromDate;
//   final DateTime? initialToDate;
//   final List? initialManagersLead;
//   final List? initialManagersLeadRegions;
//   final List? initialManagersLeadSources;
//   final int? initialManagerLeadStatuses;
//   final DateTime? initialManagerLeadFromDate;
//   final DateTime? initialManagerLeadToDate;
//   final bool? initialManagerLeadHasSuccessDeals;
//   final bool? initialManagerLeadHasInProgressDeals;
//   final bool? initialManagerLeadHasFailureDeals;
//   final bool? initialManagerLeadHasNotices;
//   final bool? initialManagerLeadHasContact;
//   final bool? initialManagerLeadHasChat;
//   final bool? initialManagerLeadHasNoReplies;
//   final bool? initialManagerLeadHasUnreadMessages;
//   final bool? initialManagerLeadHasDeal;
//   final int? initialManagerLeadDaysWithoutActivity;
//   final List<Map<String, dynamic>>? initialDirectoryValuesLead;
//   final List? initialManagersDeal;
//   final List? initialLeadsDeal;
//   final int? initialManagerDealStatuses;
//   final DateTime? initialManagerDealFromDate;
//   final DateTime? initialManagerDealToDate;
//   final bool? initialManagerDealHasTasks;
//   final int? initialManagerDealDaysWithoutActivity;
//   final List<Map<String, dynamic>>? initialDirectoryValuesDeal;
//   final List? initialManagersEvent;
//   final int? initialManagerEventStatuses;
//   final DateTime? initialManagerEventFromDate;
//   final DateTime? initialManagerEventToDate;
//   final DateTime? initialNoticeManagerEventFromDate;
//   final DateTime? initialNoticeManagerEventToDate;
//   final VoidCallback? onResetFilters;
//   final VoidCallback? onLeadResetFilters;
//   final VoidCallback? onDealResetFilters;
//   final VoidCallback? onEventResetFilters;
//   final bool showMyTaskIcon;
//   final bool showMenuIcon;
//   final bool showSeparateFilter;
//   final bool? initialTaskIsOverdue;
//   final bool? initialTaskHasFile;
//   final bool? initialTaskHasDeal;
//   final bool? initialTaskIsUrgent;
//   final DateTime? initialDeadlineFromDate;
//   final DateTime? initialDeadlineToDate;
//   final List<String>? initialAuthors;
//   final String? initialDepartment;
//   final List<Map<String, dynamic>>? initialDirectoryValuesTask;
//   final bool showDashboardIcon;
//   final VoidCallback? onDashboardPressed;
//   final Widget? titleWidget;
//   final VoidCallback? onFiltersReset;

//   CustomAppBar({
//     super.key,
//     this.menuIconKey,
//     this.SearchIconKey,
//     this.FiltrEventIconKey,
//     this.NotificationIconKey,
//     this.MyTaskIconKey,
//     this.CalendarIconKey,
//     required this.title,
//     required this.onClickProfileAvatar,
//     required this.onChangedSearchInput,
//     required this.textEditingController,
//     required this.focusNode,
//     required this.clearButtonClick,
//     required this.clearButtonClickFiltr,
//     this.initialUsers,
//     this.initialStatuses,
//     this.initialFromDate,
//     this.initialToDate,
//     this.initialManagersLead,
//     this.initialManagersLeadRegions,
//     this.initialManagersLeadSources,
//     this.initialManagerLeadStatuses,
//     this.initialManagerLeadFromDate,
//     this.initialManagerLeadToDate,
//     this.initialManagerLeadHasSuccessDeals,
//     this.initialManagerLeadHasInProgressDeals,
//     this.initialManagerLeadHasFailureDeals,
//     this.initialManagerLeadHasNotices,
//     this.initialManagerLeadHasContact,
//     this.initialManagerLeadHasChat,
//     this.initialManagerLeadHasNoReplies,
//     this.initialManagerLeadHasUnreadMessages,
//     this.initialManagerLeadHasDeal,
//     this.initialManagerLeadDaysWithoutActivity,
//     this.initialDirectoryValuesLead,
//     this.initialDirectoryValuesTask,
//     this.showDashboardIcon = false,
//     this.onDashboardPressed,
//     this.initialManagersDeal,
//     this.initialLeadsDeal,
//     this.initialManagerDealStatuses,
//     this.initialManagerDealFromDate,
//     this.initialManagerDealToDate,
//     this.initialManagerDealHasTasks,
//     this.initialManagerDealDaysWithoutActivity,
//     this.initialManagersEvent,
//     this.initialManagerEventStatuses,
//     this.initialManagerEventFromDate,
//     this.initialManagerEventToDate,
//     this.initialNoticeManagerEventFromDate,
//     this.initialNoticeManagerEventToDate,
//     this.onResetFilters,
//     this.onLeadResetFilters,
//     this.onDealResetFilters,
//     this.onEventResetFilters,
//     this.showSearchIcon = true,
//     this.showFilterIconEvent = false,
//     this.showFilterIcon = true,
//     this.showFilterIconOnSelectLead = false,
//     this.showFilterIconOnSelectDeal = false,
//     this.showFilterIconCallCenter = false,
//     this.showFilterIconOnSelectTask = false,
//     this.showFilterIconDeal = true,
//     this.showFilterTaskIcon = true,
//     this.showCallCenter = true,
//     this.showGps = true, // Новый параметр
//     this.showFilterIconOnSelectCallCenter = false,
//     this.onManagersLeadSelected,
//     this.onManagersDealSelected,
//     this.onStatusDealSelected,
//     this.onDateRangeDealSelected,
//     this.onStatusAndDateRangeDealSelected,
//     this.onManagersEventSelected,
//     this.onStatusEventSelected,
//     this.onDateRangeEventSelected,
//     this.onStatusAndDateRangeEventSelected,
//     this.onNoticeDateRangeEventSelected,
//     this.onNoticeStatusAndDateRangeEventSelected,
//     this.onDateNoticeStatusAndDateRangeSelected,
//     this.onDateNoticeAndDateRangeSelected,
//     this.onUsersSelected,
//     this.onStatusSelected,
//     this.onDateRangeSelected,
//     this.onStatusAndDateRangeSelected,
//     this.showEvent = false,
//     this.showSeparateTaskFilter = false,
//     this.showSeparateMyTasks = false,
//     this.showMyTaskIcon = false,
//     this.showMenuIcon = true,
//     this.showNotification = true,
//     this.showSeparateFilter = false,
//     this.showCalendar = true,
//     this.showCalendarDashboard = false,
//     this.initialTaskIsOverdue,
//     this.initialTaskHasFile,
//     this.initialTaskHasDeal,
//     this.initialTaskIsUrgent,
//     this.initialDeadlineFromDate,
//     this.initialDeadlineToDate,
//     this.initialAuthors,
//     this.initialDepartment,
//     this.onLeadsDealSelected,
//     this.initialDirectoryValuesDeal,
//     this.titleWidget,
//     this.onFiltersReset,
//   });

//   @override
//   State<CustomAppBar> createState() => _CustomAppBarState();
// }

// class _CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
//   bool _isSearching = false;
//   final ApiService _apiService = ApiService();
//   late TextEditingController _searchController;
//   late FocusNode focusNode;
//   String _userImage = '';
//   String _lastLoadedImage = '';
//   static String _cachedUserImage = '';
//   bool _isFiltering = false;
//   bool _isTaskFiltering = false;
//   bool _hasNewNotification = false;
//   late PusherChannelsClient socketClient;
//   late StreamSubscription<ChannelReadEvent> notificationSubscription;
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   Timer? _checkOverdueTimer;
//   late AnimationController _blinkController;
//   late Animation<double> _blinkAnimation;
//   bool _hasOverdueTasks = false;
//   bool _canReadCallCenter = false;
//   bool _canReadNotice = false;
//   bool _canReadCalendar = false;
//   bool _canReadGps = false; // Новая переменная для GPS
//   Color _iconColor = const Color.fromARGB(255, 0, 0, 0);
//   late Timer _timer;
//   bool _areFiltersActive = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkPermissions();
//     _searchController = widget.textEditingController;
//     focusNode = widget.focusNode;

//     if (_cachedUserImage.isNotEmpty) {
//       _userImage = _cachedUserImage;
//     } else {
//       _loadUserProfile();
//     }

//     _loadNotificationState();
//     _setUpSocketForNotifications();
//     _setupFirebaseMessaging();

//     _blinkController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 700),
//       lowerBound: 0.0,
//       upperBound: 1.0,
//     )..repeat(reverse: true);

//     _blinkAnimation = CurvedAnimation(
//       parent: _blinkController,
//       curve: Curves.easeInOut,
//     );
//     _checkOverdueTasks();
//     _checkOverdueTimer = Timer.periodic(
//       const Duration(minutes: 5),
//       (_) => _checkOverdueTasks(),
//     );

//     _timer = Timer.periodic(Duration(milliseconds: 700), (timer) {
//       if (_areFiltersActive) {
//         setState(() {
//           _iconColor = (_iconColor == Colors.blue) ? Colors.black : Colors.blue;
//         });
//       } else {
//         setState(() {
//           _iconColor = Colors.black;
//         });
//       }
//     });
//   }

//   void _setFiltersActive(bool active) {
//     setState(() {
//       _areFiltersActive = active;
//       if (!active) {
//         _iconColor = Colors.black;
//       }
//     });
//   }

//   void resetFilterIconState() {
//     _setFiltersActive(false);
//   }

//     Future<void> _checkOverdueTasks() async {
//     try {
//       final apiService = ApiService();
//       final hasOverdue = await apiService.checkOverdueTasks();

//       if (mounted) {
//         setState(() {
//           _hasOverdueTasks = hasOverdue;
//         });
//       }
//     } catch (e) {
//       //print('Error checking overdue tasks: $e');
//     }
//   }

//   Future<void> _loadNotificationState() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
//     setState(() {
//       _hasNewNotification = hasNewNotification;
//     });
//   }
//  Future<void> _setUpSocketForNotifications() async {
//     debugPrint(
//         '--------------------------- start socket CUSTOM APPBAR:::::::----------------');
//     final prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');
//     final enteredDomainMap = await ApiService().getEnteredDomain();
//     String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
//     String? enteredDomain = enteredDomainMap['enteredDomain'];

//     final customOptions = PusherChannelsOptions.custom(
//       uriResolver: (metadata) =>
//           Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
//       metadata: PusherChannelsOptionsMetadata.byDefault(),
//     );

//     socketClient = PusherChannelsClient.websocket(
//       options: customOptions,
//       connectionErrorHandler: (exception, trace, refresh) {},
//       minimumReconnectDelayDuration: const Duration(seconds: 1),
//     );

//     String userId = prefs.getString('unique_id') ?? '';
//     //print('userID--------------------------------------------------popopop-p : $userId');
//     //print(userId);

//     final myPresenceChannel = socketClient.presenceChannel(
//       'presence-user.$userId',
//       authorizationDelegate:
//           EndpointAuthorizableChannelTokenAuthorizationDelegate
//               .forPresenceChannel(
//         authorizationEndpoint: Uri.parse(
//             'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'X-Tenant': '$enteredDomain-back'
//         },
//         onAuthFailed: (exception, trace) {
//           debugPrint(exception);
//         },
//       ),
//     );

//     socketClient.onConnectionEstablished.listen((_) {
//       myPresenceChannel.subscribeIfNotUnsubscribed();
//       notificationSubscription =
//           myPresenceChannel.bind('notification.created').listen((event) {
//         debugPrint('Получено уведомление через сокет: ${event.data}');
//         try {
//           final data = jsonDecode(event.data);
//           debugPrint('Данные уведомления: $data');
//           setState(() {
//             _hasNewNotification = true;
//           });
//           prefs.setBool('hasNewNotification', true);
//           _playSound();
//         } catch (e) {
//           debugPrint('Ошибка парсинга данных уведомления: $e');
//         }
//       });
//     });

//     try {
//       await socketClient.connect();
//       //print('Socket connection SUCCESSS');
//     } catch (e) {
//       if (kDebugMode) {
//         //print('Socket connection error!');
//       }
//     }
//   }

// void _setupFirebaseMessaging() async {
//     final prefs = await SharedPreferences.getInstance();
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint('Получено push-уведомление: ${message.data}');
//       if (message.data['type'] == 'message') {
//         setState(() {
//           _hasNewNotification = true;
//         });
//         prefs.setBool('hasNewNotification', true);
//         _playSound();
//       }
//     });
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint('Push-уведомление открыто: ${message.data}');
//       if (message.data['type'] == 'message') {
//         setState(() {
//           _hasNewNotification = true;
//         });
//         prefs.setBool('hasNewNotification', true);
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => NotificationsScreen()),
//         );
//       }
//     });
//   }
//   Future<void> _playSound() async {
//     try {
//       await _audioPlayer.setAsset('assets/audio/get.mp3');
//       await _audioPlayer.play();
//     } catch (e) {
//       //print('Error playing sound: $e');
//     }
//   }
//   Future<void> _loadUserProfile() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String UUID = prefs.getString('userID') ??
//           AppLocalizations.of(context)!.translate('not_found');

//       UserByIdProfile userProfile =
//           await ApiService().getUserById(int.parse(UUID));

//       if (userProfile.image != null && userProfile.image != _lastLoadedImage) {
//         setState(() {
//           _userImage = userProfile.image!;
//           _lastLoadedImage = userProfile.image!;
//           _cachedUserImage = userProfile.image!;
//         });

//         await prefs.setString('userProfileImage_$UUID', _userImage);
//       } else if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
//         setState(() {
//           _userImage = _cachedUserImage;
//         });
//       }
//     } catch (e) {
//       //print('Ошибка при загрузке изображения!');
//       if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
//         setState(() {
//           _userImage = _cachedUserImage;
//         });
//       }
//     }
//   }
//   Future<void> _checkPermissions() async {
//     final canReadNotice = await _apiService.hasPermission('notice.read');
//     final canReadCalendar = await _apiService.hasPermission('calendar');
//     final canReadCallCenter = await _apiService.hasPermission('call-center');
//     final canReadGps = await _apiService.hasPermission('gps'); // Проверка прав для GPS
//     setState(() {
//       _canReadNotice = canReadNotice;
//       _canReadCalendar = canReadCalendar;
//       _canReadCallCenter = canReadCallCenter;
//       _canReadGps = canReadGps;
//     });
//   }

//   // Остальные методы (_setupFirebaseMessaging, _loadUserProfile, etc.) остаются без изменений

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: kToolbarHeight,
//       color: Colors.white,
//       padding: EdgeInsets.zero,
//       child: Row(children: [
//         Container(
//           width: 40,
//           height: 40,
//           child: IconButton(
//             padding: EdgeInsets.zero,
//             icon: _buildAvatarImage(_userImage),
//             onPressed: widget.onClickProfileAvatar,
//           ),
//         ),
//         SizedBox(width: 8),
//         if (!_isSearching)
//           Expanded(
//             child: widget.titleWidget ??
//                 Text(
//                   widget.title,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontFamily: 'Gilroy',
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xff1E2E52),
//                   ),
//                 ),
//           ),
//         if (_isSearching)
//           Expanded(
//             child: AnimatedContainer(
//               duration: Duration(milliseconds: 300),
//               curve: Curves.easeInOut,
//               width: _isSearching ? 200.0 : 0.0,
//               child: TextField(
//                 controller: _searchController,
//                 focusNode: focusNode,
//                 onChanged: widget.onChangedSearchInput,
//                 decoration: InputDecoration(
//                   hintText: AppLocalizations.of(context)!.translate('search_appbar'),
//                   border: InputBorder.none,
//                 ),
//                 style: TextStyle(fontSize: 16),
//                 autofocus: true,
//               ),
//             ),
//           ),
//         if (widget.showDashboardIcon)
//           Transform.translate(
//             offset: const Offset(10, 0),
//             child: Tooltip(
//               message: AppLocalizations.of(context)!.translate('dashboard'),
//               preferBelow: false,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 6,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               textStyle: TextStyle(
//                 fontSize: 12,
//                 color: Colors.black,
//               ),
//               child: IconButton(
//                 padding: EdgeInsets.zero,
//                 constraints: BoxConstraints(),
//                 icon: Image.asset(
//                   'assets/icons/MyNavBar/dashboard_OFF.png',
//                   width: 24,
//                   height: 24,
//                 ),
//                 onPressed: widget.onDashboardPressed,
//               ),
//             ),
//           ),
//         if (widget.showNotification)
//           Transform.translate(
//             offset: const Offset(10, 0),
//             child: Tooltip(
//               message: AppLocalizations.of(context)!.translate('notification'),
//               preferBelow: false,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 6,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               textStyle: TextStyle(
//                 fontSize: 12,
//                 color: Colors.black,
//               ),
//               child: IconButton(
//                 key: widget.NotificationIconKey,
//                 padding: EdgeInsets.zero,
//                 constraints: BoxConstraints(),
//                 icon: Stack(
//                   children: [
//                     Image.asset(
//                       'assets/icons/AppBar/notification.png',
//                       width: 24,
//                       height: 24,
//                     ),
//                     if (_hasNewNotification)
//                       Positioned(
//                         right: 0,
//                         child: FadeTransition(
//                           opacity: _blinkAnimation,
//                           child: Container(
//                             width: 10,
//                             height: 10,
//                             decoration: BoxDecoration(
//                               color: Colors.red,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _hasNewNotification = false;
//                   });
//                   SharedPreferences.getInstance().then((prefs) {
//                     prefs.setBool('hasNewNotification', false);
//                   });
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => NotificationsScreen(),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         if (widget.showSearchIcon)
//           Transform.translate(
//             offset: const Offset(10, 0),
//             child: Tooltip(
//               message: AppLocalizations.of(context)!.translate('search'),
//               preferBelow: false,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 6,
//                     offset: Offset(0, 0),
//                   ),
//                 ],
//               ),
//               textStyle: TextStyle(
//                 fontSize: 12,
//                 color: Colors.black,
//               ),
//               child: IconButton(
//                 key: widget.SearchIconKey,
//                 padding: EdgeInsets.zero,
//                 constraints: BoxConstraints(),
//                 icon: _isSearching
//                     ? Icon(Icons.close)
//                     : Image.asset(
//                         'assets/icons/AppBar/search.png',
//                         width: 24,
//                         height: 24,
//                       ),
//                 onPressed: () {
//                   setState(() {
//                     _isSearching = !_isSearching;
//                     if (!_isSearching) {
//                       _searchController.clear();
//                       FocusScope.of(context).unfocus();
//                     }
//                   });
//                   widget.clearButtonClick(_isSearching);
//                   if (_isSearching) {
//                     Future.delayed(Duration(milliseconds: 100), () {
//                       FocusScope.of(context).requestFocus(focusNode);
//                     });
//                   }
//                 },
//               ),
//             ),
//           ),
//         if (widget.showFilterIconCallCenter)
//           IconButton(
//             icon: Padding(
//               padding: const EdgeInsets.only(left: 12),
//               child: Image.asset(
//                 'assets/icons/AppBar/filter.png',
//                 width: 24,
//                 height: 24,
//                 color: _iconColor,
//               ),
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => CallCenterFilterScreen(),
//                 ),
//               );
//             },
//           ),
//         if (widget.showFilterIconEvent)
//           Tooltip(
//             message: AppLocalizations.of(context)!.translate('search'),
//             preferBelow: false,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 6,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             textStyle: TextStyle(
//               fontSize: 12,
//               color: Colors.black,
//             ),
//             child: IconButton(
//               key: widget.FiltrEventIconKey,
//               icon: Image.asset(
//                 'assets/icons/AppBar/filter.png',
//                 width: 24,
//                 height: 24,
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => EventManagerFilterScreen(
//                       onManagersSelected: widget.onManagersEventSelected,
//                       initialManagers: widget.initialManagersEvent,
//                       initialStatuses: widget.initialManagerEventStatuses,
//                       initialFromDate: widget.initialManagerEventFromDate,
//                       initialToDate: widget.initialManagerEventToDate,
//                       initialNoticeFromDate: widget.initialNoticeManagerEventFromDate,
//                       initialNoticeToDate: widget.initialNoticeManagerEventToDate,
//                       onResetFilters: widget.onEventResetFilters,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         if (widget.showFilterIconOnSelectLead)
//           IconButton(
//             icon: Padding(
//               padding: const EdgeInsets.only(left: 12),
//               child: Image.asset(
//                 'assets/icons/AppBar/filter.png',
//                 width: 24,
//                 height: 24,
//                 color: _iconColor,
//               ),
//             ),
//             onPressed: () {
//               navigateToLeadManagerFilterScreen(context);
//             },
//           ),
//         if (widget.showFilterIconOnSelectDeal)
//           IconButton(
//             icon: Padding(
//               padding: const EdgeInsets.only(left: 12),
//               child: Image.asset(
//                 'assets/icons/AppBar/filter.png',
//                 width: 24,
//                 height: 24,
//                 color: _iconColor,
//               ),
//             ),
//             onPressed: () {
//               navigateToDealManagerFilterScreen(context);
//             },
//           ),
//         if (widget.showFilterIconOnSelectTask)
//           IconButton(
//             icon: Padding(
//               padding: const EdgeInsets.only(left: 12),
//               child: Image.asset(
//                 'assets/icons/AppBar/filter.png',
//                 width: 24,
//                 height: 24,
//                 color: _iconColor,
//               ),
//             ),
//             onPressed: () {
//               navigateToTaskManagerFilterScreen(context);
//             },
//           ),
//         if (widget.showSeparateMyTasks)
//           Transform.translate(
//             offset: const Offset(6, 0),
//             child: Tooltip(
//               message: AppLocalizations.of(context)!.translate('appbar_my_tasks'),
//               preferBelow: false,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 6,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               textStyle: TextStyle(
//                 fontSize: 12,
//                 color: Colors.black,
//               ),
//               child: IconButton(
//                 key: widget.MyTaskIconKey,
//                 padding: EdgeInsets.zero,
//                 constraints: BoxConstraints(),
//                 icon: Stack(
//                   children: [
//                     Image.asset(
//                       'assets/icons/AppBar/my-task.png',
//                       width: 24,
//                       height: 24,
//                     ),
//                     if (_hasOverdueTasks)
//                       Positioned(
//                         right: 0,
//                         child: FadeTransition(
//                           opacity: _blinkAnimation,
//                           child: Container(
//                             width: 10,
//                             height: 10,
//                             decoration: BoxDecoration(
//                               color: Colors.red,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => MyTaskScreen(),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         if (widget.showCalendarDashboard && _canReadCalendar)
//           Transform.translate(
//             offset: const Offset(6, 0),
//             child: Tooltip(
//               message: AppLocalizations.of(context)!.translate('calendar'),
//               preferBelow: false,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 6,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               textStyle: TextStyle(
//                 fontSize: 12,
//                 color: Colors.black,
//               ),
//               child: IconButton(
//                 key: widget.CalendarIconKey,
//                 padding: EdgeInsets.zero,
//                 constraints: BoxConstraints(),
//                 icon: Image.asset(
//                   'assets/icons/AppBar/calendar.png',
//                   width: 24,
//                   height: 24,
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => CalendarScreen(),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         if (widget.showMenuIcon)
//           Transform.translate(
//             offset: const Offset(8, 0),
//             child: PopupMenuButton<String>(
//               key: widget.menuIconKey,
//               padding: EdgeInsets.zero,
//               position: PopupMenuPosition.under,
//               icon: Stack(
//                 children: [
//                   Icon(Icons.more_vert),
//                   if (_hasOverdueTasks)
//                     Positioned(
//                       right: 0,
//                       top: 0,
//                       child: FadeTransition(
//                         opacity: _blinkAnimation,
//                         child: Container(
//                           width: 10,
//                           height: 10,
//                           decoration: BoxDecoration(
//                             color: Colors.red,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               color: Colors.white,
//               onSelected: (String value) {
//                 switch (value) {
//                   case 'filter_task':
//                     navigateToTaskManagerFilterScreen(context);
//                     break;
//                   case 'filter_lead':
//                     navigateToLeadManagerFilterScreen(context);
//                     break;
//                   case 'filter_deal':
//                     navigateToDealManagerFilterScreen(context);
//                     break;
//                   case 'events':
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => EventScreen(),
//                       ),
//                     );
//                     break;
//                   case 'my_tasks':
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => MyTaskScreen(),
//                       ),
//                     );
//                     break;
//                   case 'calendar':
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => CalendarScreen(),
//                       ),
//                     );
//                     break;
//                   case 'call_center':
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => CallCenterScreen(),
//                       ),
//                     );
//                     break;
//                   case 'gps':
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => GpsScreenForAdmin(),
//                       ),
//                     );
//                     break;
//                 }
//               },
//               itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//                 if (widget.showFilterIcon)
//                   PopupMenuItem<String>(
//                     value: 'filter_lead',
//                     child: Row(
//                       children: [
//                         _isFiltering
//                             ? Icon(Icons.close)
//                             : Image.asset(
//                                 'assets/icons/AppBar/filter.png',
//                                 width: 24,
//                                 height: 24,
//                               ),
//                         SizedBox(width: 8),
//                         Text(AppLocalizations.of(context)!.translate('filtr')),
//                       ],
//                     ),
//                   ),
//                 if (widget.showFilterIconDeal)
//                   PopupMenuItem<String>(
//                     value: 'filter_deal',
//                     child: Row(
//                       children: [
//                         _isFiltering
//                             ? Icon(Icons.close)
//                             : Image.asset(
//                                 'assets/icons/AppBar/filter.png',
//                                 width: 24,
//                                 height: 24,
//                               ),
//                         SizedBox(width: 8),
//                         Text(AppLocalizations.of(context)!.translate('filtr')),
//                       ],
//                     ),
//                   ),
//                 if (widget.showEvent && _canReadNotice)
//                   PopupMenuItem<String>(
//                     value: 'events',
//                     child: Row(
//                       children: [
//                         Icon(Icons.event),
//                         SizedBox(width: 8),
//                         Text(AppLocalizations.of(context)!.translate('events')),
//                       ],
//                     ),
//                   ),
//                 if (widget.showFilterTaskIcon)
//                   PopupMenuItem<String>(
//                     value: 'filter_task',
//                     child: Row(
//                       children: [
//                         _isTaskFiltering
//                             ? Icon(Icons.close)
//                             : Image.asset(
//                                 'assets/icons/AppBar/filter.png',
//                                 width: 24,
//                                 height: 24,
//                               ),
//                         SizedBox(width: 8),
//                         Text(AppLocalizations.of(context)!.translate('filtr')),
//                       ],
//                     ),
//                   ),
//                 if (widget.showMyTaskIcon)
//                   PopupMenuItem<String>(
//                     value: 'my_tasks',
//                     child: Row(
//                       children: [
//                         Stack(
//                           children: [
//                             Image.asset(
//                               'assets/icons/AppBar/my-task.png',
//                               width: 24,
//                               height: 24,
//                             ),
//                             if (_hasOverdueTasks)
//                               Positioned(
//                                 right: 0,
//                                 child: FadeTransition(
//                                   opacity: _blinkAnimation,
//                                   child: Container(
//                                     width: 10,
//                                     height: 10,
//                                     decoration: BoxDecoration(
//                                       color: Colors.red,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(width: 8),
//                         Text(AppLocalizations.of(context)!.translate('appbar_my_tasks')),
//                       ],
//                     ),
//                   ),
//                 if (widget.showCalendar && _canReadCalendar)
//                   PopupMenuItem<String>(
//                     value: 'calendar',
//                     child: Row(
//                       children: [
//                         Image.asset(
//                           'assets/icons/AppBar/calendar.png',
//                           width: 24,
//                           height: 24,
//                         ),
//                         SizedBox(width: 8),
//                         Text(AppLocalizations.of(context)!.translate('calendar')),
//                       ],
//                     ),
//                   ),
//                 if (widget.showCallCenter && _canReadCallCenter)
//                   PopupMenuItem<String>(
//                     value: 'call_center',
//                     child: Row(
//                       children: [
//                         Image.asset(
//                           'assets/icons/AppBar/call_center.png',
//                           width: 24,
//                           height: 24,
//                           color: _iconColor,
//                         ),
//                         SizedBox(width: 8),
//                         Text(AppLocalizations.of(context)!.translate('call_center')),
//                       ],
//                     ),
//                   ),
//                 if (widget.showGps && _canReadGps)
//                   PopupMenuItem<String>(
//                     value: 'gps',
//                     child: Row(
//                       children: [
//                         Image.asset(
//                           'assets/icons/AppBar/gps.png', // Предполагаемый путь к иконке GPS
//                           width: 24,
//                           height: 24,
//                           color: _iconColor,
//                         ),
//                         SizedBox(width: 8),
//                         Text(AppLocalizations.of(context)!.translate('gps')),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//       ]),
//     );
//   }

//   void navigateToLeadManagerFilterScreen(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ManagerFilterScreen(
//           onManagersSelected: widget.onManagersLeadSelected,
//           initialManagers: widget.initialManagersLead,
//           initialRegions: widget.initialManagersLeadRegions,
//           initialSources: widget.initialManagersLeadSources,
//           initialStatuses: widget.initialManagerLeadStatuses,
//           initialFromDate: widget.initialManagerLeadFromDate,
//           initialToDate: widget.initialManagerLeadToDate,
//           initialHasSuccessDeals: widget.initialManagerLeadHasSuccessDeals,
//           initialHasInProgressDeals: widget.initialManagerLeadHasInProgressDeals,
//           initialHasFailureDeals: widget.initialManagerLeadHasFailureDeals,
//           initialHasNotices: widget.initialManagerLeadHasNotices,
//           initialHasContact: widget.initialManagerLeadHasContact,
//           initialHasChat: widget.initialManagerLeadHasChat,
//           initialHasNoReplies: widget.initialManagerLeadHasNoReplies,
//           initialHasUnreadMessages: widget.initialManagerLeadHasUnreadMessages,
//           initialHasDeal: widget.initialManagerLeadHasDeal,
//           initialDaysWithoutActivity: widget.initialManagerLeadDaysWithoutActivity,
//           onResetFilters: widget.onLeadResetFilters,
//           initialDirectoryValues: widget.initialDirectoryValuesLead,
//         ),
//       ),
//     );
//   }

//   void navigateToDealManagerFilterScreen(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DealManagerFilterScreen(
//           onManagersSelected: widget.onManagersDealSelected,
//           onLeadsSelected: widget.onLeadsDealSelected,
//           onStatusSelected: widget.onStatusDealSelected,
//           onDateRangeSelected: widget.onDateRangeDealSelected,
//           onStatusAndDateRangeSelected: widget.onStatusAndDateRangeDealSelected,
//           initialManagers: widget.initialManagersDeal,
//           initialLeads: widget.initialLeadsDeal,
//           initialHasTasks: widget.initialManagerDealHasTasks,
//           initialStatuses: widget.initialManagerDealStatuses,
//           initialFromDate: widget.initialManagerDealFromDate,
//           initialToDate: widget.initialManagerDealToDate,
//           onResetFilters: widget.onDealResetFilters,
//           initialDaysWithoutActivity: widget.initialManagerDealDaysWithoutActivity,
//           initialDirectoryValues: widget.initialDirectoryValuesDeal,
//         ),
//       ),
//     );
//   }

//   void navigateToTaskManagerFilterScreen(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => UserFilterScreen(
//           onUsersSelected: widget.onUsersSelected,
//           onStatusSelected: widget.onStatusSelected,
//           onDateRangeSelected: widget.onDateRangeSelected,
//           onStatusAndDateRangeSelected: widget.onStatusAndDateRangeSelected,
//           initialUsers: widget.initialUsers,
//           initialStatuses: widget.initialStatuses,
//           initialFromDate: widget.initialFromDate,
//           initialToDate: widget.initialToDate,
//           initialIsOverdue: widget.initialTaskIsOverdue,
//           initialHasFile: widget.initialTaskHasFile,
//           initialHasDeal: widget.initialTaskHasDeal,
//           initialIsUrgent: widget.initialTaskIsUrgent,
//           onResetFilters: widget.onResetFilters,
//           initialAuthors: widget.initialAuthors,
//           initialDepartment: widget.initialDepartment,
//           initialDeadlineFromDate: widget.initialDeadlineFromDate,
//           initialDeadlineToDate: widget.initialDeadlineToDate,
//           initialDirectoryValues: widget.initialDirectoryValuesTask,
//         ),
//       ),
//     );
//   }

// }