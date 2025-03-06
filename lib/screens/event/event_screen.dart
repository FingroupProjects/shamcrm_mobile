import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/event/event_details/event_add_screen.dart';
import 'package:crm_task_manager/screens/event/event_details/event_card.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class EventScreen extends StatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _tabScrollController; // Для вкладок
  late ScrollController _listScrollController; // Для списка событий
  late final List<Map<String, dynamic>> _tabTitles;
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  bool isClickAvatarIcon = false;
  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();
  late final EventBloc _eventBloc;
  String _lastSearchQuery = "";
  List<int>? _selectedManagerIds;
  int? _selectedManagerId;
  bool _showCustomTabBar = true;
  final TextEditingController _searchController = TextEditingController();
  bool _hasPermissionToAddEvent = true;
  final ApiService _apiService = ApiService();

  List<ManagerData> _selectedManagers = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _NoticefromDate;
  DateTime? _NoticetoDate;

  List<ManagerData> _initialselectedManagers = [];
  int? _initialSelStatus;
  DateTime? _intialFromDate;
  DateTime? _intialToDate;
  DateTime? _intialNoticeFromDate;
  DateTime? _intialNoticeToDate;
  // Добавляем ключи для подсказок
  final GlobalKey keyEventCard = GlobalKey();
  final GlobalKey keyFloatingActionButton = GlobalKey();
  List<TargetFocus> targets = [];
  // final GlobalKey keyDropdown = GlobalKey(); // Добавляем ключ для dropdown

// Состояние подсказок
  bool _isEventCardTutorialShown = false;
  bool _isFabTutorialShown = false;
  bool _isInProgressTabTutorialShown = false;
  bool _isCompletedTabTutorialShown = false;

// Флаги для отслеживания текущего состояния подсказок
  bool _isEventCardTutorialInProgress = false;
  bool _isFabTutorialInProgress = false;
  bool _isInProgressTabTutorialInProgress = false;
  bool _isCompletedTabTutorialInProgress = false;

  void _initTutorialTargets() {
      targets.addAll([
    createTarget(
      identify: "EventCard",
      keyTarget: keyEventCard,
      title: AppLocalizations.of(context)!.translate('EventCard'),
      description: AppLocalizations.of(context)!.translate('evetnCardDescription'),
      align: ContentAlign.bottom,
      context: context,
      contentPosition: ContentPosition.below,
      contentPadding: EdgeInsets.only(top: 50),
    ),
    createTarget(
      identify: "FloatingActionButton",
      keyTarget: keyFloatingActionButton,
      title: AppLocalizations.of(context)!.translate('addEvent'),
      description: AppLocalizations.of(context)!.translate('addEventDescription'),
      align: ContentAlign.top,
      context: context,
    ),
    createTarget(
      identify: "InProgressTab",
      keyTarget: _tabKeys[0],
      title: AppLocalizations.of(context)!.translate('События в процессе'),
      description: AppLocalizations.of(context)!.translate('Здесь хранятся события, которые находятся в процессе выполнения'),
      align: ContentAlign.bottom,
      context: context,
    ),
    createTarget(
      identify: "CompletedTab",
      keyTarget: _tabKeys[1],
      title: AppLocalizations.of(context)!.translate('Завершенные события'),
      description: AppLocalizations.of(context)!.translate('Здесь хранятся события, которые уже завершены'),
      align: ContentAlign.bottom,
      context: context,
    ),
  ]);
  }

// Загрузка состояния подсказок
  Future<void> _loadFeatureState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEventCardTutorialShown =
          prefs.getBool('isNoticeCardTutorialShow') ?? false;
      _isFabTutorialShown = prefs.getBool('isNoticeFabTutorialShow') ?? false;
      _isInProgressTabTutorialShown =
          prefs.getBool('isInProgressTabTutorialShowNotice') ?? false;
      _isCompletedTabTutorialShown =
          prefs.getBool('isCompletedTabTutorialShowNotice') ?? false;
    });
  }

// Показ подсказок
  void showTutorial(String tutorialType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await Future.delayed(const Duration(seconds: 1));

    // Определение целевого объекта для подсказки
    TargetFocus? targetFocus;
    for (var target in targets) {
      if (target.identify == tutorialType) {
        targetFocus = target;
        break;
      }
    }

    if (targetFocus == null) return;

    // Определение флагов для каждого типа подсказки
    bool isShown = false;
    bool isInProgress = false;
    Function()? onFinish = () {};

    switch (tutorialType) {
      case "EventCard":
        isShown = _isEventCardTutorialShown;
        isInProgress = _isEventCardTutorialInProgress;
        if (isShown || isInProgress) return;
        _isEventCardTutorialInProgress = true;
        onFinish = () {
          prefs.setBool('isNoticeCardTutorialShows', true);
          setState(() {
            _isEventCardTutorialShown = true;
          });
          _isEventCardTutorialInProgress = false;
        };
        break;
      case "FloatingActionButton":
        isShown = _isFabTutorialShown;
        isInProgress = _isFabTutorialInProgress;
        if (isShown || isInProgress) return;
        _isFabTutorialInProgress = true;
        onFinish = () {
          prefs.setBool('isNoticeFabTutorialShow', true);
          setState(() {
            _isFabTutorialShown = true;
          });
          _isFabTutorialInProgress = false;
        };
        break;
      case "InProgressTab":
        isShown = _isInProgressTabTutorialShown;
        isInProgress = _isInProgressTabTutorialInProgress;
        if (isShown || isInProgress) return;
        _isInProgressTabTutorialInProgress = true;
        onFinish = () {
          prefs.setBool('isInProgressTabTutorialShowNotice', true);
          setState(() {
            _isInProgressTabTutorialShown = true;
          });
          _isInProgressTabTutorialInProgress = false;
        };
        break;
      case "CompletedTab":
        isShown = _isCompletedTabTutorialShown;
        isInProgress = _isCompletedTabTutorialInProgress;
        if (isShown || isInProgress) return;
        _isCompletedTabTutorialInProgress = true;
        onFinish = () {
          prefs.setBool('isCompletedTabTutorialShowNotice', true);
          setState(() {
            _isCompletedTabTutorialShown = true;
          });
          _isCompletedTabTutorialInProgress = false;
        };
        break;
    }

    TutorialCoachMark(
      targets: [targetFocus],
      textSkip: AppLocalizations.of(context)!.translate('skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
        ],
      ),
      colorShadow: Color(0xff1E2E52),
      alignSkip: Alignment.bottomLeft, // Перемещаем кнопку в левый нижний угол
      onFinish: () {
        if (onFinish != null) {
          onFinish();
        }
      },
    ).show(context: context);
  }

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    _eventBloc = context.read<EventBloc>();
    _loadFeatureState();
    _checkPermission();

    _tabScrollController = ScrollController();
    _listScrollController = ScrollController();
    _tabKeys = List.generate(2, (_) => GlobalKey());
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      if (_tabScrollController.hasClients) {
        _scrollToActiveTab();
      }
      _loadEvents();
    });

    _listScrollController.addListener(() {
      if (_listScrollController.position.pixels >=
          _listScrollController.position.maxScrollExtent - 100) {
        if (!_eventBloc.allEventsFetched) {
          _eventBloc.add(FetchMoreEvents(
            _currentTabIndex + 1,
            query: _lastSearchQuery,
            managerIds: _selectedManagerIds,
          ));
        }
      }
    });
    if (!_isEventCardTutorialShown && _currentTabIndex == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTutorial("EventCard");
      });
    }
    if (!_isFabTutorialShown &&
        _hasPermissionToAddEvent &&
        _eventBloc.state is EventDataLoaded &&
        (_eventBloc.state as EventDataLoaded).events.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTutorial("FloatingActionButton");
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _initTutorialTargets();
      });
    });
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('notice.create');
    setState(() {
      _hasPermissionToAddEvent = hasPermission;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    _tabTitles = [
      {
        'id': 1,
        'title': localizations?.translate('in_progress') ?? 'В работе',
      },
      {
        'id': 2,
        'title': localizations?.translate('finished') ?? 'Завершенные',
      },
    ];

    if (_tabController.length != _tabTitles.length) {
      _tabController.dispose();
      _tabController = TabController(length: _tabTitles.length, vsync: this);
      _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
    }
    _loadEvents();
  }

  void _loadEvents() {
    final bool isCompleted = _currentTabIndex == 1;
    context.read<EventBloc>().add(FetchEvents());
  }

  Future<void> _searchEvents(String query, int currentStatusId) async {
    print('ПОИСК+++++++++++++++++++++++++++++++++++++++++++++++');

    context.read<EventBloc>().add(FetchEvents(
          query: query,
          managerIds: _selectedManagers.map((manager) => manager.id).toList(),
          statusIds: _selectedStatuses,
          fromDate: _fromDate,
          toDate: _toDate,
          noticefromDate: _NoticefromDate,
          noticetoDate: _NoticetoDate,
        ));
  }

  void _resetFilters() {
    setState(() {
      _showCustomTabBar = true;
      _selectedManagers = [];
      _selectedStatuses = null;
      _fromDate = null;
      _toDate = null;
      _NoticefromDate = null;
      _NoticetoDate = null;
      _initialselectedManagers = [];
      _initialSelStatus = null;
      _intialFromDate = null;
      _intialToDate = null;
      _intialFromDate = null;
      _intialToDate = null;
      _intialNoticeFromDate = null;
      _intialNoticeToDate = null;
      _lastSearchQuery = '';
      _searchController.clear();
    });
    final eventBloc = BlocProvider.of<EventBloc>(context);
    eventBloc.add(FetchEvents());
  }

  Future<void> _handleManagerSelected(Map managers) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedManagers = managers['managers'];
      _selectedStatuses = managers['statuses'];
      _fromDate = managers['fromDate'];
      _toDate = managers['toDate'];
      _NoticefromDate = managers['noticefromDate'];
      _NoticetoDate = managers['noticetoDate'];

      _initialselectedManagers = managers['managers'];
      _initialSelStatus = managers['statuses'];
      _intialFromDate = managers['fromDate'];
      _intialToDate = managers['toDate'];
      _intialNoticeFromDate = managers['noticefromDate'];
      _intialNoticeToDate = managers['noticetoDate'];
    });

    final leadBloc = BlocProvider.of<EventBloc>(context);
    leadBloc.add(FetchEvents(
      managerIds: _selectedManagers.map((manager) => manager.id).toList(),
      statusIds: _selectedStatuses,
      fromDate: _fromDate,
      toDate: _toDate,
      noticefromDate: _NoticefromDate,
      noticetoDate: _NoticetoDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  Future _handleStatusSelected(int? selectedStatusId) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatusId;

      _initialSelStatus = selectedStatusId;
    });

    final taskBloc = BlocProvider.of<EventBloc>(context);
    taskBloc.add(FetchEvents(
      statusIds: _selectedStatuses,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  Future _handleDateSelected(DateTime? fromDate, DateTime? toDate) async {
    setState(() {
      _showCustomTabBar = false;
      _fromDate = fromDate;
      _toDate = toDate;

      _intialFromDate = fromDate;
      _intialToDate = toDate;
    });

    final taskBloc = BlocProvider.of<EventBloc>(context);
    taskBloc.add(FetchEvents(
      fromDate: _fromDate,
      toDate: _toDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  Future _handleNoticeDateSelected(
      DateTime? noticefromDate, DateTime? noticetoDate) async {
    setState(() {
      _showCustomTabBar = false;
      _NoticefromDate = noticefromDate;
      _NoticetoDate = noticetoDate;

      _intialNoticeFromDate = noticefromDate;
      _intialNoticeToDate = noticetoDate;
    });

    final taskBloc = BlocProvider.of<EventBloc>(context);
    taskBloc.add(FetchEvents(
      noticefromDate: _NoticefromDate,
      noticetoDate: _NoticetoDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  Future _handleStatusAndDateSelected(
      int? selectedStatus, DateTime? fromDate, DateTime? toDate) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatus;
      _fromDate = fromDate;
      _toDate = toDate;

      _initialSelStatus = selectedStatus;
      _intialFromDate = fromDate;
      _intialToDate = toDate;
    });

    final taskBloc = BlocProvider.of<EventBloc>(context);
    taskBloc.add(FetchEvents(
      statusIds: selectedStatus,
      fromDate: _fromDate,
      toDate: _toDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  Future _handleNoticeStatusAndDateSelected(int? selectedStatus,
      DateTime? noticefromDate, DateTime? noticetoDate) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatus;
      _NoticefromDate = noticefromDate;
      _NoticetoDate = noticetoDate;

      _initialSelStatus = selectedStatus;
      _intialNoticeFromDate = noticefromDate;
      _intialNoticeToDate = noticetoDate;
    });

    final taskBloc = BlocProvider.of<EventBloc>(context);
    taskBloc.add(FetchEvents(
      statusIds: selectedStatus,
      fromDate: _fromDate,
      toDate: _toDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  Future _handleDateNoticeStatusAndDateSelected(
      int? selectedStatus,
      DateTime? noticefromDate,
      DateTime? noticetoDate,
      DateTime? fromDate,
      DateTime? toDate) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedStatuses = selectedStatus;

      _fromDate = fromDate;
      _toDate = toDate;
      _NoticefromDate = noticefromDate;
      _NoticetoDate = noticetoDate;

      _initialSelStatus = selectedStatus;
      _intialFromDate = fromDate;
      _intialToDate = toDate;
      _intialNoticeFromDate = noticefromDate;
      _intialNoticeToDate = noticetoDate;
    });

    final taskBloc = BlocProvider.of<EventBloc>(context);
    taskBloc.add(FetchEvents(
      statusIds: selectedStatus,
      fromDate: _fromDate,
      toDate: _toDate,
      noticefromDate: _NoticefromDate,
      noticetoDate: _NoticetoDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  Future _handleDateNoticeAndDateSelected(DateTime? noticefromDate,
      DateTime? noticetoDate, DateTime? fromDate, DateTime? toDate) async {
    setState(() {
      _showCustomTabBar = false;

      _fromDate = fromDate;
      _toDate = toDate;
      _NoticefromDate = noticefromDate;
      _NoticetoDate = noticetoDate;

      _intialFromDate = fromDate;
      _intialToDate = toDate;
      _intialNoticeFromDate = noticefromDate;
      _intialNoticeToDate = noticetoDate;
    });

    final taskBloc = BlocProvider.of<EventBloc>(context);
    taskBloc.add(FetchEvents(
      fromDate: _fromDate,
      toDate: _toDate,
      noticefromDate: _NoticefromDate,
      noticetoDate: _NoticetoDate,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  void _onSearch(String query) {
    _lastSearchQuery = query;
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchEvents(query, currentStatusId);
  }

  List<NoticeEvent> _filterEvents(List<NoticeEvent> events, bool isCompleted) {
    return events.where((event) => event.isFinished == isCompleted).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('events'),
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          onChangedSearchInput: (String value) {
            if (value.isNotEmpty) {
              setState(() {
                _isSearching = true;
              });
            }
            _onSearch(value);
          },
          onManagersEventSelected: _handleManagerSelected,
          onStatusEventSelected: _handleStatusSelected,
          onDateRangeEventSelected: _handleDateSelected,
          onNoticeDateRangeEventSelected: _handleNoticeDateSelected,
          onStatusAndDateRangeEventSelected: _handleStatusAndDateSelected,
          onNoticeStatusAndDateRangeEventSelected:
              _handleNoticeStatusAndDateSelected,
          onDateNoticeStatusAndDateRangeSelected:
              _handleDateNoticeStatusAndDateSelected,
          onDateNoticeAndDateRangeSelected: _handleDateNoticeAndDateSelected,
          initialManagersEvent: _initialselectedManagers,
          initialManagerEventStatuses: _initialSelStatus,
          initialManagerEventFromDate: _intialFromDate,
          initialManagerEventToDate: _intialToDate,
          initialNoticeManagerEventFromDate: _intialNoticeFromDate,
          initialNoticeManagerEventToDate: _intialNoticeToDate,
          onEventResetFilters: _resetFilters,
          textEditingController: textEditingController,
          focusNode: focusNode,
          showFilterTaskIcon: false,
          showMyTaskIcon: false,
          showEvent: false,
          showMenuIcon: false,
          showNotification: false,
          showSeparateFilter: true,
          showFilterIconEvent: true,
          clearButtonClick: (value) {
            if (value == false) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _lastSearchQuery = '';
              });

              if (_searchController.text.isEmpty) {
                if (_selectedManagers.isEmpty &&
                    _selectedStatuses == null &&
                    _fromDate == null &&
                    _toDate == null &&
                    _NoticefromDate == null &&
                    _NoticetoDate == null) {
                  print("IF SEARCH EMPTY AND NO FILTERS");
                  setState(() {
                    _showCustomTabBar = true;
                  });
                  final eventBloc = BlocProvider.of<EventBloc>(context);
                  eventBloc.add(FetchEvents());
                } else {
                  print("IF SEARCH EMPTY BUT FILTERS EXIST");
                  final taskBloc = BlocProvider.of<EventBloc>(context);
                  taskBloc.add(FetchEvents(
                    managerIds: _selectedManagers.isNotEmpty
                        ? _selectedManagers
                            .map((manager) => manager.id)
                            .toList()
                        : null,
                    statusIds: _selectedStatuses,
                    fromDate: _fromDate,
                    toDate: _toDate,
                    noticefromDate: _NoticefromDate,
                    noticetoDate: _NoticetoDate,
                  ));
                }
              } else if (_selectedManagerIds != null &&
                  _selectedManagerIds!.isNotEmpty) {
                print("ELSE IF SEARCH NOT EMPTY");
                final taskBloc = BlocProvider.of<EventBloc>(context);
                taskBloc.add(FetchEvents(
                  managerIds: _selectedManagerIds,
                  query: _searchController.text.isNotEmpty
                      ? _searchController.text
                      : null,
                ));
              }
            }
          },
          clearButtonClickFiltr: (value) {},
        ),
      ),
      floatingActionButton: _hasPermissionToAddEvent
          ? FloatingActionButton(
              key: keyFloatingActionButton, // Add the key here
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoticeAddScreen(),
                  ),
                ).then((_) => _loadEvents());
              },
              backgroundColor: Color(0xff1E2E52),
              child: Image.asset(
                'assets/icons/tabBar/add.png',
                width: 24,
                height: 24,
              ),
            )
          : null, // Если нет разрешения, просто null
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Column(
              children: [
                const SizedBox(height: 15),
                if (!_isSearching &&
                    _selectedManagers.isEmpty &&
                    _selectedStatuses == null &&
                    _fromDate == null &&
                    _toDate == null &&
                    _NoticefromDate == null &&
                    _NoticetoDate == null &&
                    _showCustomTabBar)
                  _buildCustomTabBar(),
                Expanded(
                  child: RefreshIndicator(
                    color: Color(0xff1E2E52),
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      _loadEvents();
                      return Future.delayed(Duration(milliseconds: 300));
                    },
                    child: BlocBuilder<EventBloc, EventState>(
                      builder: (context, state) {
                        if (state is EventLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: Color(0xff1E2E52),
                            ),
                          );
                        }
                        if (state is EventDataLoaded) {
                          return _buildEventsList(state.events);
                        }
                        if (state is EventError) {
                          return Center(
                            child: Text(
                              state.message,
                              style: TextStyle(
                                color: Color(0xff99A4BA),
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildEventsList(List<NoticeEvent> events) {
    final localizations = AppLocalizations.of(context);
    if (events.isEmpty &&
        _currentTabIndex == 0 &&
        !_isFabTutorialShown &&
        _hasPermissionToAddEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTutorial("FloatingActionButton");
      });
    }
    // Если активен поиск или фильтр, отображаем все события без разделения на вкладки
    if (_isSearching ||
        _selectedManagers.isNotEmpty ||
        _selectedStatuses != null ||
        _fromDate != null ||
        _toDate != null ||
        _NoticefromDate != null ||
        _NoticetoDate != null) {
      if (events.isEmpty) {
        return Center(
          child: Text(
            localizations?.translate('no_events') ?? 'Нет событий',
            style: TextStyle(
              color: Color(0xff99A4BA),
              fontSize: 14,
              fontFamily: 'Gilroy',
            ),
          ),
        );
      }

      return ListView.builder(
        controller: _listScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EventCard(
              key: index == 0 ? keyEventCard : null,
              event: events[index],
              onStatusUpdated: () {
                _loadEvents();
              },
            ),
          );
        },
      );
    }

    // Иначе разделяем события на вкладки
    final filteredEvents = _filterEvents(events, _currentTabIndex == 1);

    if (filteredEvents.isEmpty) {
      return Center(
        child: Text(
          localizations?.translate('no_events_in_section')?.replaceAll(
                  '{section}', _tabTitles[_currentTabIndex]['title']) ??
              'Нет событий в разделе "${_tabTitles[_currentTabIndex]['title']}"',
          style: TextStyle(
            color: Color(0xff99A4BA),
            fontSize: 14,
            fontFamily: 'Gilroy',
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _listScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EventCard(
            key: index == 0 ? keyEventCard : null,
            event: filteredEvents[index],
            onStatusUpdated: () {
              _loadEvents();
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabScrollController.dispose(); // Не забудьте освободить ресурсы
    _listScrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 45,
      child: SingleChildScrollView(
        controller: _tabScrollController, // Используем отдельный контроллер
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabTitles.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 16 : 8,
                right: index == _tabTitles.length - 1 ? 16 : 0,
              ),
              child: _buildTabButton(index),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return GestureDetector(
      key: _tabKeys[index], // Apply the key to the tab button
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Color(0xff1E2E52) : Color(0xffE9EDF3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tabTitles[index]['title'],
              style: TextStyle(
                color: isActive ? Color(0xff1E2E52) : Color(0xff99A4BA),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToActiveTab() {
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;

      if (position.dx < 0 ||
          (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
        double targetOffset = _tabScrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);

        if (targetOffset != _tabScrollController.offset) {
          _tabScrollController.animateTo(
            targetOffset,
            duration: Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      }
    }
  }
}
