import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/event/event_cache.dart';
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

class _EventScreenState extends State<EventScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _tabScrollController;
  late ScrollController _listScrollController;
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
  bool _isFilterLoading = false;
  bool _shouldShowLoader = false;
  bool _skipNextTabListener = false; // КРИТИЧНО: Флаг для пропуска TabListener при фильтрации
  final TextEditingController _searchController = TextEditingController();
  bool _hasPermissionToAddEvent = false;
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

  // Ключи для туториала
  final GlobalKey keyEventCard = GlobalKey();
  final GlobalKey keyFloatingActionButton = GlobalKey();
  final GlobalKey keySearchIcon = GlobalKey();
  final GlobalKey keyFiltrIcon = GlobalKey();
  List<TargetFocus> targets = [];

  bool _isTutorialShown = false; // Единый флаг для туториала
  bool _isTutorialInProgress = false; // Защита от повторного вызова
  Map<String, dynamic>? tutorialProgress; // Данные с сервера
int _tutorialStep = 0; // Добавляем шаг туториала
  SalesFunnel? _selectedFunnel; // Новый параметр для текущей воронки



 @override
  void initState() {
    super.initState();
    //print('EventScreen: initState started');
    _eventBloc = context.read<EventBloc>();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels()); // Загружаем воронки
    //print('EventScreen: initState - Dispatched FetchSalesFunnels');

    _tabScrollController = ScrollController();
    _listScrollController = ScrollController();
    _tabKeys = List.generate(2, (_) => GlobalKey());
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // ← КРИТИЧНО: Проверяем флаг пропуска!
        if (_skipNextTabListener) {
          debugPrint('EventScreen: TabController listener - SKIPPED (filter just applied)');
          setState(() {
            _skipNextTabListener = false;
            _currentTabIndex = _tabController.index;
          });
          return; // ← ВЫХОДИМ БЕЗ ЗАПРОСА!
        }

        setState(() {
          _currentTabIndex = _tabController.index;
        });
        if (_tabScrollController.hasClients) {
          _scrollToActiveTab();
        }
        _loadEvents();
      }
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

    // Загружаем сохранённую воронку для событий
    _apiService.getSelectedEventSalesFunnel().then((funnelId) {
      //print('EventScreen: initState - Retrieved selected event funnel ID: $funnelId');
      if (funnelId != null && mounted) {
        context.read<SalesFunnelBloc>().add(SelectSalesFunnel(
          SalesFunnel(
            id: int.parse(funnelId),
            name: '',
            organizationId: 1,
            isActive: true,
            createdAt: '',
            updatedAt: '',
          ),
        ));
        //print('EventScreen: initState - Dispatched SelectSalesFunnel with ID: $funnelId');
      }
    });

    // Слушаем изменения состояния SalesFunnelBloc
    context.read<SalesFunnelBloc>().stream.listen((state) {
      if (state is SalesFunnelLoaded && mounted) {
        //print('EventScreen: initState - SalesFunnelLoaded received, selectedFunnel: ${state.selectedFunnel}');
        setState(() {
          _selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
        });
        _loadEvents(); // Загружаем события при смене воронки
      }
    });

    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _apiService.hasPermission('notice.create');
    setState(() {
      _hasPermissionToAddEvent = hasPermission;
    });
    await _fetchTutorialProgress();
  }

 Future<void> _fetchTutorialProgress() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final progress = await _apiService.getTutorialProgress();
    setState(() {
      tutorialProgress = progress['result'];
    });
    await prefs.setString('tutorial_progress', json.encode(progress['result']));

    bool isTutorialShown = prefs.getBool('isTutorialShownNoticeIndex') ?? false;
    setState(() {
      _isTutorialShown = isTutorialShown;
    });

    _initTutorialTargets();

    if (tutorialProgress != null &&
        tutorialProgress!['notices']?['index'] == false &&
        !isTutorialShown &&
        !_isTutorialInProgress &&
        targets.isNotEmpty &&
        mounted) {
      _tutorialStep = 0; // Начинаем с первого шага
      //showTutorial(); // Запускаем туториал
    }
  } catch (e) {
    ////print('Error fetching tutorial progress: $e');
    final prefs = await SharedPreferences.getInstance();
    final savedProgress = prefs.getString('tutorial_progress');
    if (savedProgress != null) {
      setState(() {
        tutorialProgress = json.decode(savedProgress);
      });
      bool isTutorialShown = prefs.getBool('isTutorialShownNoticeIndex') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });

      _initTutorialTargets();

      if (tutorialProgress != null &&
          tutorialProgress!['notices']?['index'] == false &&
          !isTutorialShown &&
          !_isTutorialInProgress &&
          targets.isNotEmpty &&
          mounted) {
        _tutorialStep = 0; // Начинаем с первого шага
        //showTutorial(); // Запускаем туториал
      }
    }
  }
}
  void _initTutorialTargets() {
    targets.clear();
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
      if (_hasPermissionToAddEvent)
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
        title: AppLocalizations.of(context)!.translate('events_in_progress'),
        description: AppLocalizations.of(context)!.translate('events_in_progress_description'),
        align: ContentAlign.bottom,
        context: context,
      ),
      createTarget(
        identify: "CompletedTab",
        keyTarget: _tabKeys[1],
        title: AppLocalizations.of(context)!.translate('completed_events'),
        description: AppLocalizations.of(context)!.translate('completed_events_description'),
        align: ContentAlign.bottom,
        context: context,
      ),
      createTarget(
        identify: "EventSearchIcon",
        keyTarget: keySearchIcon,
        title: AppLocalizations.of(context)!.translate('tutorial_task_screen_search_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_event_screen_search_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      createTarget(
        identify: "EventFiltrIcon",
        keyTarget: keyFiltrIcon,
        title: AppLocalizations.of(context)!.translate('tutorial_event_screen_filtr_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_event_screen_filtr_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
    ]);
  }

  void showTutorial() async {
  if (_isTutorialInProgress) {
    ////print('Tutorial already in progress, skipping');
    return;
  }

  if (targets.isEmpty) {
    ////print('No targets available for tutorial, skipping');
    return;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isTutorialShown = prefs.getBool('isTutorialShownNoticeIndex') ?? false;

  if (tutorialProgress == null ||
      tutorialProgress!['notices']?['index'] == true ||
      isTutorialShown ||
      _isTutorialShown) {
    ////print('Tutorial conditions not met');
    return;
  }

  setState(() {
    _isTutorialInProgress = true;
  });
  await Future.delayed(const Duration(milliseconds: 500));

  // Определяем текущую цель в зависимости от шага
  List<TargetFocus> currentTargets = [];
  bool isLastStep = false;

  switch (_tutorialStep) {
    case 0: // Поиск
      currentTargets = targets.where((t) => t.identify == "EventSearchIcon").toList();
      break;
    case 1: // Фильтр
      currentTargets = targets.where((t) => t.identify == "EventFiltrIcon").toList();
      break;
    case 2: // Статусы
      currentTargets = targets
          .where((t) => t.identify == "InProgressTab" || t.identify == "CompletedTab")
          .toList();
      break;
    case 3: // Карточка или Кнопка "Добавить"
      if (_eventBloc.state is EventDataLoaded) {
        final events = (_eventBloc.state as EventDataLoaded).events;
        if (events.isEmpty && _hasPermissionToAddEvent) {
          currentTargets = targets.where((t) => t.identify == "FloatingActionButton").toList();
          isLastStep = true; // Если нет карточек, это последний шаг
        } else {
          currentTargets = targets.where((t) => t.identify == "EventCard").toList();
        }
      }
      break;
    case 4: // Кнопка "Добавить" (если были карточки)
      if (_hasPermissionToAddEvent) {
        currentTargets = targets.where((t) => t.identify == "FloatingActionButton").toList();
        isLastStep = true; // Это последний шаг
      }
      break;
  }

  if (currentTargets.isEmpty) {
    setState(() {
      _isTutorialInProgress = false;
    });
    return;
  }

  TutorialCoachMark(
    targets: currentTargets,
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
    alignSkip: Alignment.bottomLeft,
    onFinish: () {
      if (isLastStep) {
        prefs.setBool('isTutorialShownNoticeIndex', true);
        _apiService.markPageCompleted("notices", "index").catchError((e) {
          ////print('Error marking page completed on finish: $e');
        });
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
      } else {
        setState(() {
          _tutorialStep++;
          _isTutorialInProgress = false;
        });
        //showTutorial(); // Переходим к следующему шагу
      }
    },
    onSkip: () {
      prefs.setBool('isTutorialShownNoticeIndex', true);
      _apiService.markPageCompleted("notices", "index").catchError((e) {
        ////print('Error marking page completed on skip: $e');
      });
      setState(() {
        _isTutorialShown = true;
        _isTutorialInProgress = false;
      });
      return true;
    },
  ).show(context: context);
}
// Новый метод для построения заголовка с выбором воронки
 Widget _buildTitleWidget(BuildContext context) {
  return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
    builder: (context, state) {
      // Дефолтный заголовок — всегда "События"
      String title = AppLocalizations.of(context)!.translate('events');
      SalesFunnel? selectedFunnel;

      // Только если воронки успешно загружены — пытаемся показать название текущей
      if (state is SalesFunnelLoaded) {
        selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
        _selectedFunnel = selectedFunnel;

        if (selectedFunnel != null) {
          title = selectedFunnel.name;
        }
      }
      // При Loading, Error, Initial — просто оставляем "События". Пользователь не должен видеть ошибку в шапке.

      return Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Стрелочка переключения воронок — только если есть несколько воронок
          if (state is SalesFunnelLoaded && state.funnels.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: PopupMenuButton<SalesFunnel>(
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xff1E2E52)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                elevation: 8,
                offset: const Offset(0, 40),
                onSelected: (SalesFunnel funnel) async {
                  try {
                    // Сохраняем выбор пользователя
                    await _apiService.saveSelectedEventSalesFunnel(funnel.id.toString());

                    // Очищаем старое состояние
                    _resetFilters();

                    setState(() {
                      _selectedFunnel = funnel;
                      _isSearching = false;
                      _searchController.clear();
                      _lastSearchQuery = '';
                    });

                    // Обновляем глобальный выбор воронки
                    context.read<SalesFunnelBloc>().add(SelectSalesFunnel(funnel));

                    // Перезагружаем события для новой воронки
                    _loadEvents();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ошибка при смене воронки'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (_) => state.funnels
                    .map((f) => PopupMenuItem<SalesFunnel>(
                          value: f,
                          child: Text(
                            f.name,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      );
    },
  );
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
        'title': localizations?.translate('finished_status') ?? 'Завершенные',
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
    context.read<EventBloc>().add(FetchEvents(
      statusIds: isCompleted ? 2 : 1,
      salesFunnelId: _selectedFunnel?.id, // Передаем ID воронки
    ));
  }

  Future<void> _searchEvents(String query, int currentStatusId) async {
    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true;
      });
    }

    await EventCache.clearEventsForStatus(currentStatusId);

    context.read<EventBloc>().add(FetchEvents(
      query: query,
      managerIds: _selectedManagers.isNotEmpty
          ? _selectedManagers.map((manager) => manager.id).toList()
          : null,
      statusIds: _selectedStatuses ?? currentStatusId,
      fromDate: _fromDate,
      toDate: _toDate,
      noticefromDate: _NoticefromDate,
      noticetoDate: _NoticetoDate,
      salesFunnelId: _selectedFunnel?.id,
    ));
  }

  void _resetFilters() {
    if (mounted) {
      setState(() {
        _showCustomTabBar = true;
        _isSearching = false;
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
        _intialNoticeFromDate = null;
        _intialNoticeToDate = null;
        _lastSearchQuery = '';
        _searchController.clear();
      });
    }
    
    _loadEvents();
  }

  Future<void> _onRefresh() async {
    try {
      await EventCache.clearAllData();
      await EventCache.clearPersistentCounts();

      if (mounted) {
        setState(() {
          _isSearching = false;
          _lastSearchQuery = '';
          _searchController.clear();
          _showCustomTabBar = true;
          _isFilterLoading = false;
          _shouldShowLoader = false;

          _selectedManagers.clear();
          _selectedStatuses = null;
          _fromDate = null;
          _toDate = null;
          _NoticefromDate = null;
          _NoticetoDate = null;

          _initialselectedManagers.clear();
          _initialSelStatus = null;
          _intialFromDate = null;
          _intialToDate = null;
          _intialNoticeFromDate = null;
          _intialNoticeToDate = null;
        });
      }

      final eventBloc = context.read<EventBloc>();
      await eventBloc.clearAllCountsAndCache();
      
      // Загружаем события для текущей вкладки
      final bool isCompleted = _currentTabIndex == 1;
      eventBloc.add(FetchEvents(
        statusIds: isCompleted ? 2 : 1,
        salesFunnelId: _selectedFunnel?.id,
        forceRefresh: true,
      ));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при обновлении данных: ${e.toString()}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Повторить',
              textColor: Colors.white,
              onPressed: () => _onRefresh(),
            ),
          ),
        );

        final eventBloc = context.read<EventBloc>();
        final bool isCompleted = _currentTabIndex == 1;
        eventBloc.add(FetchEvents(
          statusIds: isCompleted ? 2 : 1,
          salesFunnelId: _selectedFunnel?.id,
          forceRefresh: false,
        ));
      }
    }
  }

  // Метод для проверки наличия активных фильтров
  bool _hasActiveFilters() {
    return _selectedManagers.isNotEmpty ||
        _selectedStatuses != null ||
        _fromDate != null ||
        _toDate != null ||
        _NoticefromDate != null ||
        _NoticetoDate != null;
  }

  Future<void> _handleManagerSelected(Map managers) async {
    debugPrint('EventScreen: _handleManagerSelected - START WITH NEW LOGIC');
    
    if (mounted) {
      setState(() {
        _isFilterLoading = true;
        _shouldShowLoader = true;
        _showCustomTabBar = true;
        _skipNextTabListener = true; // ← КРИТИЧНО: Пропускаем следующий TabListener!
        _isSearching = false;
        _searchController.clear();
        _lastSearchQuery = '';

        _selectedManagers = managers['managers'];
        _selectedStatuses = managers['statuses'];
        _fromDate = managers['fromDate'];
        _toDate = managers['toDate'];
        _NoticefromDate = managers['noticefromDate'];
        _NoticetoDate = managers['noticetoDate'];

        // Сохраняем initial значения
        _initialselectedManagers = managers['managers'];
        _initialSelStatus = managers['statuses'];
        _intialFromDate = managers['fromDate'];
        _intialToDate = managers['toDate'];
        _intialNoticeFromDate = managers['noticefromDate'];
        _intialNoticeToDate = managers['noticetoDate'];
      });
    }

    await Future.delayed(Duration(milliseconds: 50));

    context.read<EventBloc>().add(FetchEventsWithFilters(
      managerIds: _selectedManagers.isNotEmpty
          ? _selectedManagers.map((manager) => manager.id).toList()
          : null,
      statusIds: _selectedStatuses ?? (_currentTabIndex == 1 ? 2 : 1),
      fromDate: _fromDate,
      toDate: _toDate,
      noticefromDate: _NoticefromDate,
      noticetoDate: _NoticetoDate,
      salesFunnelId: _selectedFunnel?.id,
    ));

    debugPrint('EventScreen: _handleManagerSelected - Dispatched FetchEventsWithFilters');
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
    //print('EventScreen: Building widget tree');
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _eventBloc),
        BlocProvider.value(value: context.read<SalesFunnelBloc>()), // Добавляем SalesFunnelBloc
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBar(
            FiltrEventIconKey: keyFiltrIcon,
            SearchIconKey: keySearchIcon,
            title: '',
            titleWidget: isClickAvatarIcon
                ? Text(
                    localizations!.translate('appbar_settings'),
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  )
                : _buildTitleWidget(context), // Используем новый виджет заголовка
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
            initialManagersEvent: _initialselectedManagers,
            initialManagerEventStatuses: _initialSelStatus,
            initialManagerEventFromDate: _intialFromDate,
            initialManagerEventToDate: _intialToDate,
            initialNoticeManagerEventFromDate: _intialNoticeFromDate,
            initialNoticeManagerEventToDate: _intialNoticeToDate,
            onEventResetFilters: _resetFilters,
            hasActiveEventFilters: _hasActiveFilters(),
            textEditingController: textEditingController,
            focusNode: focusNode,
            showFilterTaskIcon: false,
            showMyTaskIcon: false,
            showCallCenter: true,
            showEvent: false,
            showMenuIcon: false,
            showNotification: false,
            showSeparateFilter: true,
            showFilterIconEvent: true,
            clearButtonClick: (value) {
              if (value == false) {
                if (mounted) {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _lastSearchQuery = '';
                  });
                }

                if (_searchController.text.isEmpty) {
                  if (_hasActiveFilters()) {
                    // Есть активные фильтры - загружаем с фильтрами
                    _loadEvents();
                  } else {
                    // Нет фильтров - показываем табы
                    if (mounted) {
                      setState(() {
                        _showCustomTabBar = true;
                      });
                    }
                    _loadEvents();
                  }
                } else if (_selectedManagerIds != null && _selectedManagerIds!.isNotEmpty) {
                  _loadEvents();
                }
              }
            },
            clearButtonClickFiltr: (value) {},
          ),
        ),
        floatingActionButton: _hasPermissionToAddEvent
            ? FloatingActionButton(
                key: keyFloatingActionButton,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NoticeAddScreen()),
                  ).then((_) => _loadEvents());
                },
                backgroundColor: Color(0xff1E2E52),
                child: Image.asset(
                  'assets/icons/tabBar/add.png',
                  width: 24,
                  height: 24,
                ),
              )
            : null,
        body: isClickAvatarIcon
            ? ProfileScreen()
            : Column(
                children: [
                  const SizedBox(height: 15),
                  if (!_isSearching && _showCustomTabBar)
                    _buildCustomTabBar(),
                  Expanded(
                    child: RefreshIndicator(
                      color: Color(0xff1E2E52),
                      backgroundColor: Colors.white,
                      onRefresh: () => _onRefresh(),
                      child: BlocListener<EventBloc, EventState>(
                        listener: (context, state) {
                          debugPrint('EventScreen: BlocListener - state: ${state.runtimeType}');
                          // Сбрасываем флаги когда данные загружены или произошла ошибка
                          if ((state is EventDataLoaded || state is EventError) &&
                              mounted &&
                              (_isFilterLoading || _shouldShowLoader)) {
                            debugPrint('EventScreen: Resetting loader flags');
                            setState(() {
                              _isFilterLoading = false;
                              _shouldShowLoader = false;
                            });
                          }
                        },
                        child: BlocBuilder<EventBloc, EventState>(
                          builder: (context, state) {
                            // Показываем лоадер только если флаги активны ИЛИ состояние - EventLoading
                            if (_shouldShowLoader || _isFilterLoading || state is EventLoading) {
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
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEventsList(List<NoticeEvent> events) {
    final localizations = AppLocalizations.of(context);

    // Если есть активные фильтры или поиск - показываем отфильтрованный список
    if (_isSearching || _hasActiveFilters()) {
      if (events.isEmpty) {
        return Center(
          child: Text(
            localizations?.translate('Нет событий') ?? 'Нет событий',
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
    _tabScrollController.dispose();
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
        controller: _tabScrollController,
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
      key: _tabKeys[index],
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
      final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;

      if (position.dx < 0 || (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
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