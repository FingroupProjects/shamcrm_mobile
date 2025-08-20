import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/chats/chat_delete_dialog.dart';
import 'package:crm_task_manager/screens/chats/create_chat.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_unfocuser/flutter_unfocuser.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with TickerProviderStateMixin {
  final ApiService apiService = ApiService();
  bool isNavigating = false;
  late Future<List<Chats>> futureChats;
  List<Chats> allChats = [];
  List<Chats> filteredChats = [];
  TextEditingController searchController = TextEditingController();
  FocusNode focusNode = FocusNode();
  late TabController _tabController;
  late List<String> _tabTitles;
  late PusherChannelsClient socketClient;
  late StreamSubscription<ChannelReadEvent> chatSubscribtion;
  String endPointInTab = 'lead';
   Map<String, dynamic>? _activeFilters; // Хранит активные фильтры
  bool _hasActiveFilters = false; // Показывает есть ли активные фильтры

  Map<String, dynamic>? tutorialProgress;

  bool _showCorporateChat = false;
  bool _showLeadChat = false;
  bool _isPermissionsChecked = false;
  bool _isSearching = false;
  String searchQuery = '';

  final GlobalKey keyChatLead = GlobalKey();
  final GlobalKey keyChatTask = GlobalKey();
  final GlobalKey keyChatCorporate = GlobalKey();
  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isTaskScreenTutorialCompleted = false;

  bool _isTabControllerInitialized = false;
  SalesFunnel? _selectedFunnel; // Новый параметр для текущей воронки

  // Создаём отдельные PagingController для каждой вкладки
  final Map<String, PagingController<int, Chats>> _pagingControllers = {
    'lead': PagingController(firstPageKey: 0),
    'task': PagingController(firstPageKey: 0),
    'corporate': PagingController(firstPageKey: 0),
  };

  // Отдельные экземпляры ChatsBloc для каждой вкладки
  final Map<String, ChatsBloc> _chatsBlocs = {
    'lead': ChatsBloc(ApiService()),
    'task': ChatsBloc(ApiService()),
    'corporate': ChatsBloc(ApiService()),
  };

  Future<void> _checkPermissions() async {
    final LeadChat = await apiService.hasPermission('chat.read');
    final CorporateChat = await apiService.hasPermission('corporateChat.read');

    setState(() {
      _showLeadChat = LeadChat;
      _showCorporateChat = CorporateChat;

      if (!_showLeadChat && !_showCorporateChat) {
        selectTabIndex = 1;
        endPointInTab = 'task';
        _chatsBlocs['task']!.add(FetchChats(endPoint: 'task'));
      } else if (!_showLeadChat) {
        selectTabIndex = 1;
        endPointInTab = 'task';
        _chatsBlocs['task']!.add(FetchChats(endPoint: 'task'));
      } else if (!_showCorporateChat) {
        selectTabIndex = 0;
        endPointInTab = 'lead';
        _chatsBlocs['lead']!.add(FetchChats(endPoint: 'lead'));
      } else {
        selectTabIndex = 0;
        endPointInTab = 'lead';
        _chatsBlocs['lead']!.add(FetchChats(endPoint: 'lead'));
      }
      _isPermissionsChecked = true;
    });
  }
  // НОВЫЙ МЕТОД: Обработка фильтров от ChatLeadFilterScreen
 void _handleFiltersApplied(Map<String, dynamic> filters) {
  print('ChatsScreen._handleFiltersApplied: Received filters: $filters');
  
  setState(() {
    _activeFilters = filters;
    _hasActiveFilters = _checkIfFiltersActive(filters);
  });

  // Применяем фильтры к текущей вкладке
  if (endPointInTab == 'lead' || endPointInTab == 'task') {
    final chatsBloc = _chatsBlocs[endPointInTab]!;
    chatsBloc.add(ClearChats());
    _pagingControllers[endPointInTab]!.itemList = null;
    _pagingControllers[endPointInTab]!.refresh();
    
    chatsBloc.add(FetchChats(
      endPoint: endPointInTab,
      salesFunnelId: endPointInTab == 'lead' ? _selectedFunnel?.id : null,
      filters: filters, // Передаем фильтры как есть
    ));
  }

    setState(() {
      _activeFilters = filters;
      _hasActiveFilters = _checkIfFiltersActive(filters);
    });

    // Применяем фильтры только к вкладке lead
    if (endPointInTab == 'lead') {
      final chatsBloc = _chatsBlocs['lead']!;
      chatsBloc.add(ClearChats());
      _pagingControllers['lead']!.itemList = null;
      _pagingControllers['lead']!.refresh();
      
      chatsBloc.add(FetchChats(
        endPoint: 'lead',
        salesFunnelId: _selectedFunnel?.id,
        filters: filters, // Передаем фильтры
      ));
    }
  }

  // НОВЫЙ МЕТОД: Проверка активности фильтров
  bool _checkIfFiltersActive(Map<String, dynamic> filters) {
  if (endPointInTab == 'lead') {
    return filters['managers']?.isNotEmpty == true ||
        filters['regions']?.isNotEmpty == true ||
        filters['sources']?.isNotEmpty == true ||
        filters['statuses'] != null ||
        filters['fromDate'] != null ||
        filters['toDate'] != null ||
        filters['hasSuccessDeals'] == true ||
        filters['hasInProgressDeals'] == true ||
        filters['hasFailureDeals'] == true ||
        filters['hasNotices'] == true ||
        filters['hasContact'] == true ||
        filters['hasChat'] == true ||
        filters['hasNoReplies'] == true ||
        filters['unreadOnly'] == true ||
        filters['hasUnreadMessages'] == true ||
        filters['hasDeal'] == true ||
        filters['daysWithoutActivity'] != null ||
        filters['directory_values']?.isNotEmpty == true;
  } else if (endPointInTab == 'task') {
    return filters['department_id'] != null ||
        filters['task_created_from'] != null ||
        filters['task_created_to'] != null ||
        filters['deadline_from'] != null ||
        filters['deadline_to'] != null ||
        filters['executor_ids']?.isNotEmpty == true ||
        filters['author_ids']?.isNotEmpty == true ||
        filters['project_ids']?.isNotEmpty == true ||
        filters['task_status_ids']?.isNotEmpty == true ||
        filters['unread_only'] == true;
  }
  return false;
}

  // НОВЫЙ МЕТОД: Сброс фильтров
  void _resetFilters() {
    print('ChatsScreen._resetFilters: Resetting filters');
    
    setState(() {
      _activeFilters = null;
      _hasActiveFilters = false;
    });

    if (endPointInTab == 'lead') {
      final chatsBloc = _chatsBlocs['lead']!;
      chatsBloc.add(ClearChats());
      _pagingControllers['lead']!.itemList = null;
      _pagingControllers['lead']!.refresh();
      
      chatsBloc.add(FetchChats(
        endPoint: 'lead',
        salesFunnelId: _selectedFunnel?.id,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) {
      if (_isPermissionsChecked) {
        setState(() {
          _tabTitles = _getTabTitles(context);
          _tabController = TabController(
            length: _tabTitles.length,
            vsync: this,
            initialIndex: selectTabIndex,
          );
          _isTabControllerInitialized = true;
        });
        setUpServices();
        
        // Загружаем воронки
        context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
        print('ChatsScreen: initState - Dispatched FetchSalesFunnels');

        // Загружаем сохранённую воронку для чатов
        apiService.getSelectedChatSalesFunnel().then((funnelId) {
          print('ChatsScreen: initState - Retrieved selected chat funnel ID: $funnelId');
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
            print('ChatsScreen: initState - Dispatched SelectSalesFunnel with ID: $funnelId');
          }
        });

        // Слушаем изменения состояния SalesFunnelBloc
        context.read<SalesFunnelBloc>().stream.listen((state) {
          if (state is SalesFunnelLoaded && mounted) {
            print('ChatsScreen: initState - SalesFunnelLoaded received, selectedFunnel: ${state.selectedFunnel}');
            setState(() {
              _selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
            });
            
            // Обновляем чаты только для вкладки lead с учетом фильтров
            if (endPointInTab == 'lead') {
              _chatsBlocs[endPointInTab]!.add(ClearChats());
              _pagingControllers[endPointInTab]!.itemList = null;
              _pagingControllers[endPointInTab]!.refresh();
              _chatsBlocs[endPointInTab]!.add(FetchChats(
                endPoint: endPointInTab,
                salesFunnelId: _selectedFunnel?.id,
                filters: _activeFilters, // ВАЖНО: Передаем фильтры
              ));
            }
          }
        });
      }
      _fetchTutorialProgress();
    });

    // Настройка контроллеров пагинации
    _pagingControllers.forEach((endPoint, controller) {
      controller.addPageRequestListener((pageKey) {
        print('ChatsScreen: Page request for endpoint $endPoint, pageKey: $pageKey');
        if (pageKey == 0) {
          controller.refresh();
        }
        if (endPointInTab == endPoint) {
          _chatsBlocs[endPoint]!.add(GetNextPageChats());
        }
      });
    });
  }

  List<String> _getTabTitles(BuildContext context) {
    return [
      AppLocalizations.of(context)!.translate('tab_leads'),
      AppLocalizations.of(context)!.translate('tab_tasks'),
      AppLocalizations.of(context)!.translate('tab_corp_chat'),
    ];
  }

  Future<void> _fetchTutorialProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await apiService.getTutorialProgress();
      setState(() {
        tutorialProgress = progress['result'];
      });
      await prefs.setString(
          'tutorial_progress', json.encode(progress['result']));
      bool isTutorialShown = prefs.getBool('isTutorialShowninChat') ?? false;
      if (isTutorialShown) {
        setState(() {
          _isTaskScreenTutorialCompleted = true;
          _isTutorialShown = true;
        });
      }
      if (tutorialProgress != null &&
          tutorialProgress!['chat']?['index'] == false &&
          !isTutorialShown &&
          !_isTutorialShown &&
          mounted) {
        //showTutorial();
      }
    } catch (e) {
      //print('Error fetching tutorial progress: $e');
      final prefs = await SharedPreferences.getInstance();
      final savedProgress = prefs.getString('tutorial_progress');
      if (savedProgress != null) {
        setState(() {
          tutorialProgress = json.decode(savedProgress);
        });
        bool isTutorialShown = prefs.getBool('isTutorialShowninChat') ?? false;
        if (isTutorialShown) {
          setState(() {
            _isTaskScreenTutorialCompleted = true;
            _isTutorialShown = true;
          });
        }
        if (tutorialProgress != null &&
            tutorialProgress!['chat']?['index'] == false &&
            !isTutorialShown &&
            !_isTutorialShown &&
            mounted) {
          //showTutorial();
        }
      }
    }
  }
  // ОБНОВЛЕННЫЙ МЕТОД: Переключение воронок с сохранением фильтров
  Widget _buildTitleWidget(BuildContext context) {
    print('ChatsScreen: Entering _buildTitleWidget');
    return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
      builder: (context, state) {
        print('ChatsScreen: _buildTitleWidget - Current SalesFunnelBloc state: $state');
        String title = AppLocalizations.of(context)!.translate('appbar_chats');
        SalesFunnel? selectedFunnel;
        
        if (state is SalesFunnelLoading) {
          print('ChatsScreen: _buildTitleWidget - State is SalesFunnelLoading');
          title = AppLocalizations.of(context)!.translate('appbar_chats');
        } else if (state is SalesFunnelLoaded && endPointInTab == 'lead') {
          print('ChatsScreen: _buildTitleWidget - State is SalesFunnelLoaded, funnels: ${state.funnels}, selectedFunnel: ${state.selectedFunnel}');
          selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
          _selectedFunnel = selectedFunnel;
          print('ChatsScreen: _buildTitleWidget - Selected funnel set to: $selectedFunnel');
          title = selectedFunnel?.name ?? AppLocalizations.of(context)!.translate('appbar_chats');
          print('ChatsScreen: _buildTitleWidget - Title set to: $title');
        } else if (state is SalesFunnelError) {
          print('ChatsScreen: _buildTitleWidget - State is SalesFunnelError: ${state.message}');
          title = 'Ошибка загрузки';
        }
        
        print('ChatsScreen: _buildTitleWidget - Rendering title: $title');
        return Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (state is SalesFunnelLoaded && state.funnels.length > 1 && endPointInTab == 'lead')
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: PopupMenuButton<SalesFunnel>(
                  icon: Icon(Icons.arrow_drop_down, color: Color(0xff1E2E52)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  color: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.2),
                  offset: Offset(0, 40),
                  onSelected: (SalesFunnel funnel) async {
                    print('ChatsScreen: _buildTitleWidget - Selected new funnel: ${funnel.name} (ID: ${funnel.id})');
                    try {
                      await apiService.saveSelectedChatSalesFunnel(funnel.id.toString());
                      print('ChatsScreen: _buildTitleWidget - Saved funnel ID ${funnel.id} to SharedPreferences');
                      setState(() {
                        _selectedFunnel = funnel;
                        _isSearching = false;
                        searchController.clear();
                        searchQuery = '';
                        print('ChatsScreen: _buildTitleWidget - Updated _selectedFunnel: $_selectedFunnel, cleared search');
                      });
                      context.read<SalesFunnelBloc>().add(SelectSalesFunnel(funnel));
                      _chatsBlocs[endPointInTab]!.add(ClearChats());
                      _pagingControllers[endPointInTab]!.itemList = null;
                      _pagingControllers[endPointInTab]!.refresh();
                      
                      // ВАЖНО: Передаем фильтры при переключении воронки
                      _chatsBlocs[endPointInTab]!.add(FetchChats(
                        endPoint: endPointInTab,
                        salesFunnelId: funnel.id,
                        filters: _activeFilters, // Сохраняем активные фильтры
                      ));
                    } catch (e) {
                      print('ChatsScreen: Error switching funnel: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ошибка при смене воронки',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    print('ChatsScreen: _buildTitleWidget - Building PopupMenu with funnels: ${state.funnels}');
                    return state.funnels
                        .map((funnel) => PopupMenuItem<SalesFunnel>(
                              value: funnel,
                              child: Text(
                                funnel.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff1E2E52),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList();
                  },
                ),
              ),
          ],
        );
      },
    );
  }
// НОВЫЙ МЕТОД: Получение текста активных фильтров для отображения
 String _getActiveFiltersText() {
  if (_activeFilters == null || !_hasActiveFilters) {
    return 'Применены фильтры';
  }

  List<String> activeFiltersList = [];

  if (endPointInTab == 'lead') {
    // Существующая логика для лидов
    if (_activeFilters!['managers']?.isNotEmpty == true) {
      activeFiltersList.add('Менеджеры (${_activeFilters!['managers'].length})');
    }
    if (_activeFilters!['regions']?.isNotEmpty == true) {
      activeFiltersList.add('Регионы (${_activeFilters!['regions'].length})');
    }
    if (_activeFilters!['sources']?.isNotEmpty == true) {
      activeFiltersList.add('Источники (${_activeFilters!['sources'].length})');
    }
    if (_activeFilters!['statuses'] != null) {
      activeFiltersList.add('Статус');
    }
    if (_activeFilters!['fromDate'] != null || _activeFilters!['toDate'] != null) {
      activeFiltersList.add('Период');
    }
    List<String> booleanFilters = [];
    if (_activeFilters!['hasSuccessDeals'] == true) booleanFilters.add('Успешные сделки');
    if (_activeFilters!['hasInProgressDeals'] == true) booleanFilters.add('Сделки в работе');
    if (_activeFilters!['hasFailureDeals'] == true) booleanFilters.add('Неуспешные сделки');
    if (_activeFilters!['hasNotices'] == true) booleanFilters.add('С заметками');
    if (_activeFilters!['hasContact'] == true) booleanFilters.add('С контактами');
    if (_activeFilters!['hasChat'] == true) booleanFilters.add('С чатом');
    if (_activeFilters!['hasNoReplies'] == true) booleanFilters.add('Без ответов');
    if (_activeFilters!['hasUnreadMessages'] == true) booleanFilters.add('Непрочитанные');
    if (_activeFilters!['hasDeal'] == true) booleanFilters.add('Без сделок');
    if (booleanFilters.isNotEmpty) {
      activeFiltersList.addAll(booleanFilters);
    }
    if (_activeFilters!['daysWithoutActivity'] != null && _activeFilters!['daysWithoutActivity'] > 0) {
      activeFiltersList.add('Без активности (${_activeFilters!['daysWithoutActivity']} дн.)');
    }
  } else if (endPointInTab == 'task') {
    // Новая логика для задач
    if (_activeFilters!['department_id'] != null) {
      activeFiltersList.add('Отдел');
    }
    if (_activeFilters!['task_created_from'] != null || _activeFilters!['task_created_to'] != null) {
      activeFiltersList.add('Период создания');
    }
    if (_activeFilters!['deadline_from'] != null || _activeFilters!['deadline_to'] != null) {
      activeFiltersList.add('Период дедлайна');
    }
    if (_activeFilters!['executor_ids']?.isNotEmpty == true) {
      activeFiltersList.add('Исполнители (${_activeFilters!['executor_ids'].length})');
    }
    if (_activeFilters!['author_ids']?.isNotEmpty == true) {
      activeFiltersList.add('Авторы (${_activeFilters!['author_ids'].length})');
    }
    if (_activeFilters!['project_ids']?.isNotEmpty == true) {
      activeFiltersList.add('Проекты (${_activeFilters!['project_ids'].length})');
    }
    if (_activeFilters!['task_status_ids']?.isNotEmpty == true) {
      activeFiltersList.add('Статусы (${_activeFilters!['task_status_ids'].length})');
    }
    if (_activeFilters!['unread_only'] == true) {
      activeFiltersList.add('Только непрочитанные');
    }
  }

  if (activeFiltersList.isEmpty) {
    return 'Применены фильтры';
  }

  if (activeFiltersList.length <= 2) {
    return activeFiltersList.join(', ');
  } else {
    return '${activeFiltersList.take(2).join(', ')} и еще ${activeFiltersList.length - 2}';
  }
}


  void _initTutorialTargets() {
    targets.addAll([
      createTarget(
        identify: "chatLead",
        keyTarget: keyChatLead,
        title: AppLocalizations.of(context)!.translate('tutorial_chat_lead_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_chat_lead_description'),
        align: ContentAlign.bottom,
        extraPadding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.2),
        context: context,
      ),
      createTarget(
        identify: "chatTask",
        keyTarget: keyChatTask,
        title: AppLocalizations.of(context)!.translate('tutorial_chat_task_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_chat_task_description'),
        align: ContentAlign.bottom,
        extraPadding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.2),
        context: context,
      ),
      createTarget(
        identify: "chatCorporate",
        keyTarget: keyChatCorporate,
        title: AppLocalizations.of(context)!.translate('tutorial_chat_corporate_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_chat_corporate_description'),
        align: ContentAlign.bottom,
        extraPadding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.2),
        context: context,
      ),
    ]);
  }

  void showTutorial() async {
    if (_isTutorialShown) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShowninChat') ?? false;

    if (tutorialProgress == null ||
        tutorialProgress!['chat']?['index'] == true ||
        isTutorialShown ||
        _isTutorialShown) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    TutorialCoachMark(
      targets: targets,
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
      onSkip: () {
        prefs.setBool('isTutorialShowninChat', true);
        apiService.markPageCompleted("chat", "index").catchError((e) {
          //print('Error marking page completed on skip: $e');
        });
        setState(() {
          _isTaskScreenTutorialCompleted = true;
          _isTutorialShown = true;
        });
        return true;
      },
      onFinish: () async {
        await prefs.setBool('isTutorialShowninChat', true);
        try {
          await apiService.markPageCompleted("chat", "index");
        } catch (e) {
          //print('Error marking page completed on finish: $e');
        }
        setState(() {
          _isTaskScreenTutorialCompleted = true;
          _isTutorialShown = true;
        });
      },
    ).show(context: context);
  }

  Timer? _debounce;

 void _onSearch(String query) {
    setState(() {
      searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    final endPoint = endPointInTab;
    final chatsBloc = _chatsBlocs[endPoint]!;
    chatsBloc.add(ClearChats());

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      chatsBloc.add(FetchChats(
        endPoint: endPoint,
        query: query,
        salesFunnelId: endPoint == 'lead' ? _selectedFunnel?.id : null,
        filters: endPoint == 'lead' ? _activeFilters : null, // ДОБАВЛЯЕМ фильтры в поиск
      ));
    });
  }
 Future<void> updateFromSocket() async {
    _chatsBlocs[endPointInTab]!.add(UpdateChatsFromSocket());
  }
  Future<void> setUpServices() async {
    debugPrint('--------------------------- start socket:::::::');
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
);
String userId = prefs.getString('unique_id').toString();
final myPresenceChannel = socketClient.presenceChannel(
  'presence-user.$userId',
  authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate
      .forPresenceChannel(
    authorizationEndpoint: Uri.parse(
        'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
    headers: {
      'Authorization': 'Bearer $token',
      'X-Tenant': '$enteredDomain-back'
    },
  ),
);
socketClient.onConnectionEstablished.listen((_) {
  myPresenceChannel.subscribeIfNotUnsubscribed();
  chatSubscribtion = myPresenceChannel.bind('chat.created').listen((event) {
    //print(event.data);
    updateFromSocket();
  });
  chatSubscribtion = myPresenceChannel.bind('chat.updated').listen((event) {
    //print(event.data);
    updateFromSocket();
  });
});
await socketClient.connect();

    socketClient.onConnectionEstablished.listen((_) {
      myPresenceChannel.subscribeIfNotUnsubscribed();

      chatSubscribtion = myPresenceChannel.bind('chat.created').listen((event) {
        if (kDebugMode) {
          //print(event.data);
          //print(event.channelName);
          //print('------ socket');
          //print('--------');
          //print('--------');
        }
        updateFromSocket();
      });

      chatSubscribtion =
          myPresenceChannel.bind('chat.updated').listen((event) async {
        if (kDebugMode) {
          //print(event.data);
          //print(event.channelName);
          //print('------ socket');
          //print('--------');
          //print('--------');
        }
        updateFromSocket();
      });
    });

    try {
      await socketClient.connect();
    } catch (e) {
      if (kDebugMode) {
        //print(e);
      }
    }
  }

  void updateChats() {
    // _chatsBlocs[endPointInTab]!.add(RefreshChats());
  }

  bool isClickAvatarIcon = false;
  int selectTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    _tabTitles = _getTabTitles(context);

    if (_isTabControllerInitialized && _tabController.length != _tabTitles.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: _tabTitles.length,
        vsync: this,
        initialIndex: selectTabIndex.clamp(0, _tabTitles.length - 1),
      );
    }

    return Unfocuser(
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _chatsBlocs['lead']!),
          BlocProvider.value(value: _chatsBlocs['task']!),
          BlocProvider.value(value: _chatsBlocs['corporate']!),
          BlocProvider.value(value: context.read<SalesFunnelBloc>()),
        ],
        child: Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            elevation: 1,
            title: CustomAppBar(
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
                  : _buildTitleWidget(context),
              onClickProfileAvatar: () {
                setState(() {
                  isClickAvatarIcon = !isClickAvatarIcon;
                  if (!isClickAvatarIcon) {
                    _chatsBlocs[endPointInTab]!.add(FetchChats(
                      endPoint: endPointInTab,
                      salesFunnelId: _selectedFunnel?.id,
                      filters: endPointInTab == 'lead' ? _activeFilters : null, // Передаем фильтры
                    ));
                  }
                });
              },
              textEditingController: TextEditingController(),
              focusNode: FocusNode(),
              showFilterIcon: false,
              showFilterTaskIcon: false,
              showMyTaskIcon: false,
              showMenuIcon: false,
              showCallCenter: true,
              // ОБНОВЛЯЕМ: Передаем информацию о фильтрах в CustomAppBar
              showFilterIconChat: endPointInTab == 'lead' ? true : false,
              showFilterIconTaskChat: endPointInTab == 'task' ? true : false,
              // ДОБАВЛЯЕМ: Обработчики для фильтров
              onChatLeadFiltersApplied: _handleFiltersApplied, // Новый параметр
              onChatLeadFiltersReset: _resetFilters, // Новый параметр
              hasActiveChatFilters: _hasActiveFilters, // Новый параметр
              initialChatFilters: _activeFilters, // Новый параметр
              currentSalesFunnelId: _selectedFunnel?.id, // ИЗМЕНЕНО: Добавили передачу
              onChangedSearchInput: (String value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
                _onSearch(value);
              },
              clearButtonClick: (isSearching) {
                if (!isSearching) {
                  searchController.clear();
                  if (!isClickAvatarIcon) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(seconds: 1), () {
                      final chatsBloc = _chatsBlocs[endPointInTab]!;
                      chatsBloc.add(ClearChats());
                      chatsBloc.add(FetchChats(
                        endPoint: endPointInTab,
                        salesFunnelId: _selectedFunnel?.id,
                        filters: endPointInTab == 'lead' ? _activeFilters : null, // Передаем фильтры
                      ));
                    });
                  }
                  setState(() {
                    _isSearching = false;
                  });
                }
              },
              clearButtonClickFiltr: (bool) {},
            ),
            backgroundColor: Colors.white,
          ),
          backgroundColor: Colors.white,
          body: isClickAvatarIcon
              ? ProfileScreen()
              : _isPermissionsChecked
                  ? Column(
                      children: [
                        SizedBox(height: 12),
                        // ДОБАВЛЯЕМ: Индикатор активных фильтров
                        if (_hasActiveFilters && endPointInTab == 'lead')
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.filter_list, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Применены фильтры',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _resetFilters,
                                  child: Text(
                                    'Сбросить',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_hasActiveFilters && endPointInTab == 'lead')
                          SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_tabTitles.length, (index) {
                              if ((index == 0 && !_showLeadChat) ||
                                  (index == 2 && !_showCorporateChat)) {
                                return Container();
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: _buildTabButton(index),
                              );
                            }),
                          ),
                        ),
                        SizedBox(height: 12),
                        Expanded(child: _buildTabBarView()),
                      ],
                    )
                  : Center(child: CircularProgressIndicator()),
          floatingActionButton: (selectTabIndex == 2)
              ? FloatingActionButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddClientDialog(),
                    );
                  },
                  backgroundColor: Color(0xff1E2E52),
                  child: Image.asset('assets/icons/tabBar/add.png',
                      width: 24, height: 24),
                )
              : null,
        ),
      ),
    );
  }

  // ОБНОВЛЯЕМ: _buildTabButton для передачи фильтров
  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    GlobalKey? tabKey;

    if (index == 0) {
      tabKey = keyChatLead;
    } else if (index == 1) {
      tabKey = keyChatTask;
    } else if (index == 2) {
      tabKey = keyChatCorporate;
    }

    return GestureDetector(
      onTap: () {
        print('ChatsScreen._buildTabButton: Switching to tab $index (endpoint: ${['lead', 'task', 'corporate'][index]})');
        setState(() {
          selectTabIndex = index;
        });
        _tabController.animateTo(index);

        String newEndPoint = index == 0
            ? 'lead'
            : index == 1
                ? 'task'
                : 'corporate';
        endPointInTab = newEndPoint;

        final chatsBloc = _chatsBlocs[newEndPoint]!;
        chatsBloc.add(ClearChats());
        _pagingControllers[newEndPoint]!.itemList = null;
        _pagingControllers[newEndPoint]!.refresh();
        chatsBloc.add(FetchChats(
          endPoint: newEndPoint,
          salesFunnelId: newEndPoint == 'lead' ? _selectedFunnel?.id : null,
          filters: newEndPoint == 'lead' ? _activeFilters : null, // ДОБАВЛЯЕМ фильтры
        ));
      },
      child: Container(
        key: tabKey,
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Center(
          child: Text(
            _tabTitles[index],
            style: TaskStyles.tabTextStyle.copyWith(
              color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        _tabTitles.length,
        (index) {
          String endPoint = index == 0
              ? 'lead'
              : index == 1
                  ? 'task'
                  : 'corporate';
          return BlocProvider.value(
            value: _chatsBlocs[endPoint]!,
            child: _ChatItemsWidget(
              updateChats: updateChats,
              endPointInTab: endPoint,
              pagingController: _pagingControllers[endPoint]!,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    chatSubscribtion.cancel();
    socketClient.dispose();
    _pagingControllers.forEach((_, controller) => controller.dispose());
    _chatsBlocs.forEach((_, bloc) => bloc.close());
    super.dispose();
  }
}

class _ChatItemsWidget extends StatefulWidget {
  final VoidCallback updateChats;
  final String endPointInTab;
  final PagingController<int, Chats> pagingController;

  const _ChatItemsWidget({
    required this.updateChats,
    required this.endPointInTab,
    required this.pagingController,
  });

  @override
  State<_ChatItemsWidget> createState() => _ChatItemsWidgetState();
}

class _ChatItemsWidgetState extends State<_ChatItemsWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onTap(Chats chat) {
    setState(() {
      chat.unreadCount = 0;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MessagingCubit(ApiService()),
          child: ChatSmsScreen(
            chatItem: chat.toChatItem(),
            chatId: chat.id,
            endPointInTab: widget.endPointInTab,
            canSendMessage: chat.canSendMessage,
          ),
        ),
      ),
    ).then((_) {
      widget.updateChats.call();
    });
  }

  void onLongPress(Chats chat) {
    if (widget.endPointInTab == 'task' || widget.endPointInTab == 'lead') {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DeleteChatDialog(
        chatId: chat.id,
        endPointInTab: widget.endPointInTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatsBloc, ChatsState>(
      listener: (context, state) {
        if (state is ChatsInitial) {
         // //print('_ChatItemsWidget: ChatsInitial - Refreshing PagingController and clearing itemList for endpoint ${widget.endPointInTab}');
          widget.pagingController.itemList = null;
          widget.pagingController.refresh();
        }
        if (state is ChatsLoaded) {
         // //print('_ChatItemsWidget: ChatsLoaded - Received ${state.chatsPagination.data.length} chats for page ${state.chatsPagination.currentPage}, endpoint: ${widget.endPointInTab}');
         // //print('_ChatItemsWidget: Chat IDs: ${state.chatsPagination.data.map((chat) => chat.id).toList()}');

          // Очищаем текущий список перед добавлением новых данных
          widget.pagingController.itemList = null;

          // Фильтруем уникальные чаты по id
          final uniqueChats = state.chatsPagination.data
              .asMap()
              .entries
              .fold<Map<int, Chats>>({}, (map, entry) {
                map[entry.value.id] = entry.value;
                return map;
              })
              .values
              .toList();

        //  //print('_ChatItemsWidget: Unique chats after filtering: ${uniqueChats.length}');
////print('_ChatItemsWidget: Unique chat IDs: ${uniqueChats.map((chat) => chat.id).toList()}');

          if (state.chatsPagination.currentPage == state.chatsPagination.totalPage) {
           // //print('_ChatItemsWidget: Appending last page with ${uniqueChats.length} chats for endpoint ${widget.endPointInTab}');
            widget.pagingController.appendLastPage(uniqueChats);
          } else {
          //  //print('_ChatItemsWidget: Appending page ${state.chatsPagination.currentPage} with ${uniqueChats.length} chats for endpoint ${widget.endPointInTab}');
            widget.pagingController.appendPage(uniqueChats, state.chatsPagination.currentPage);
          }
        }
        if (state is ChatsError) {
         // //print('_ChatItemsWidget: ChatsError - ${state.message}');
          if (state.message.contains(AppLocalizations.of(context)!.translate('no_internet_connection'))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
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
              ),
            );
          }
        }
      },
      child: PagedListView<int, Chats>(
        padding: EdgeInsets.symmetric(vertical: 0),
        pagingController: widget.pagingController,
        builderDelegate: PagedChildBuilderDelegate<Chats>(
          noItemsFoundIndicatorBuilder: (context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('nothing_found_chat'),
                    style: TextStyle(fontSize: 18, color: AppColors.primaryBlue),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('list_empty_chat'),
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
          firstPageProgressIndicatorBuilder: (context) {
         //   //print('_ChatItemsWidget: Showing first page progress indicator for endpoint ${widget.endPointInTab}');
            return Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          },
          newPageProgressIndicatorBuilder: (context) {
           // //print('_ChatItemsWidget: Showing new page progress indicator for endpoint ${widget.endPointInTab}');
            return Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          },
          itemBuilder: (context, item, index) {
         //   //print('_ChatItemsWidget: Rendering chat ID: ${item.id} at index $index for endpoint ${widget.endPointInTab}');
            return InkWell(
              onTap: () => onTap(item),
              onLongPress: () => onLongPress(item),
              splashColor: Colors.grey,
              focusColor: Colors.black87,
              child: ChatListItem(
                chatItem: item.toChatItem(),
                 endPointInTab: widget.endPointInTab,


              ),
            );
          },
        ),
      ),
    );
  }
}
