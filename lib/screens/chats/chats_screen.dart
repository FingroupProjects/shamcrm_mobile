import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
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
  Map<String, dynamic>? _activeFilters;
  bool _hasActiveFilters = false;

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
  SalesFunnel? _selectedFunnel;

  final Map<String, PagingController<int, Chats>> _pagingControllers = {
    'lead': PagingController(firstPageKey: 0),
    'task': PagingController(firstPageKey: 0),
    'corporate': PagingController(firstPageKey: 0),
  };

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

  void _handleFiltersApplied(Map<String, dynamic> filters) {
    //print('ChatsScreen._handleFiltersApplied: Received filters: $filters');
    setState(() {
      _activeFilters = filters;
      _hasActiveFilters = _checkIfFiltersActive(filters);
      //print( 'ChatsScreen._handleFiltersApplied: Updated _activeFilters: $_activeFilters, _hasActiveFilters: $_hasActiveFilters');
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('active_chat_filters');
      //print('ChatsScreen: Removed active filters from SharedPreferences');
    });

    final chatsBloc = _chatsBlocs[endPointInTab]!;
    chatsBloc.add(ClearChats());
    _pagingControllers[endPointInTab]!.itemList = null;
    _pagingControllers[endPointInTab]!.refresh();

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      //print(  'ChatsScreen._handleFiltersApplied: Dispatching FetchChats with filters: $filters, salesFunnelId: ${_selectedFunnel?.id}');
      chatsBloc.add(FetchChats(
        endPoint: endPointInTab,
        salesFunnelId: endPointInTab == 'lead' ? _selectedFunnel?.id : null,
        filters: filters,
      ));
    });
  }

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

  void _resetFilters() {
    //print('ChatsScreen._resetFilters: Resetting filters');
    setState(() {
      _activeFilters = null;
      _hasActiveFilters = false;
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('active_chat_filters');
      //print('ChatsScreen: Removed active filters from SharedPreferences');
    });

    final chatsBloc = _chatsBlocs[endPointInTab]!;
    chatsBloc.add(ClearChats());
    _pagingControllers[endPointInTab]!.itemList = null;
    _pagingControllers[endPointInTab]!.refresh();

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      //print(  'ChatsScreen._resetFilters: Dispatching FetchChats with no filters, salesFunnelId: ${_selectedFunnel?.id}');
      chatsBloc.add(FetchChats(
        endPoint: endPointInTab,
        salesFunnelId: endPointInTab == 'lead' ? _selectedFunnel?.id : null,
        filters: null,
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    //print('ChatsScreen: initState started');
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

        //print('ChatsScreen: Fetching sales funnels');
        context.read<SalesFunnelBloc>().add(FetchSalesFunnels());

        apiService.getSelectedChatSalesFunnel().then((funnelId) {
          if (kDebugMode) {
            //print(  'ChatsScreen: ApiService initialized with baseUrl: ${apiService.baseUrl}');
          }
          //print('ChatsScreen: Retrieved saved funnel ID: $funnelId');
          if (funnelId != null && mounted) {
            final funnel = SalesFunnel(
              id: int.parse(funnelId),
              name: '',
              organizationId: 1,
              isActive: true,
              createdAt: '',
              updatedAt: '',
            );
            context.read<SalesFunnelBloc>().add(SelectSalesFunnel(funnel));
            setState(() {
              _selectedFunnel = funnel;
            });
            if (endPointInTab == 'lead') {
              //print(    'ChatsScreen: Dispatching FetchChats with saved funnelId: $funnelId, filters: $_activeFilters');
              _chatsBlocs[endPointInTab]!.add(FetchChats(
                endPoint: endPointInTab,
                salesFunnelId: int.parse(funnelId),
                filters: _activeFilters,
              ));
            }
          } else {
            //print(    'ChatsScreen: No saved funnel ID found or widget not mounted');
          }
        });

        context.read<SalesFunnelBloc>().stream.listen((state) {
          if (state is SalesFunnelLoaded && mounted) {
            //print(   'ChatsScreen: SalesFunnelLoaded, funnels: ${state.funnels.length}, selectedFunnel: ${state.selectedFunnel?.id}');
            setState(() {
              _selectedFunnel =
                  state.selectedFunnel ?? state.funnels.firstOrNull;
            });
            if (endPointInTab == 'lead' && _selectedFunnel != null) {
              //print(    'ChatsScreen: Dispatching FetchChats with selectedFunnel: ${_selectedFunnel!.id}, filters: $_activeFilters');
              _chatsBlocs[endPointInTab]!.add(ClearChats());
              _pagingControllers[endPointInTab]!.itemList = null;
              _pagingControllers[endPointInTab]!.refresh();
              _chatsBlocs[endPointInTab]!.add(FetchChats(
                endPoint: endPointInTab,
                salesFunnelId: _selectedFunnel!.id,
                filters: _activeFilters,
              ));
            }
          }
        });
      }
      _fetchTutorialProgress();
    });

    _pagingControllers.forEach((endPoint, controller) {
      controller.addPageRequestListener((pageKey) {
        //print( 'ChatsScreen: Page request for endpoint $endPoint, pageKey: $pageKey');
        if (pageKey == 0) {
          controller.refresh();
        }
        if (endPointInTab == endPoint) {
          _chatsBlocs[endPoint]!.add(GetNextPageChats());
        }
      });
    });
    //print('ChatsScreen: initState completed');
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

  Widget _buildTitleWidget(BuildContext context) {
    //print('ChatsScreen: Entering _buildTitleWidget');
    return BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
      builder: (context, state) {
        //print( 'ChatsScreen: _buildTitleWidget - Current SalesFunnelBloc state: $state');
        //print('ChatsScreen: _buildTitleWidget - endPointInTab: $endPointInTab');
        //print( 'ChatsScreen: _buildTitleWidget - _selectedFunnel: $_selectedFunnel');

        String title = AppLocalizations.of(context)!.translate('appbar_chats');
        SalesFunnel? selectedFunnel;

        if (state is SalesFunnelLoading) {
          //print('ChatsScreen: _buildTitleWidget - State is SalesFunnelLoading');
          title = AppLocalizations.of(context)!.translate('appbar_chats');
        } else if (state is SalesFunnelLoaded && endPointInTab == 'lead') {
          //print('ChatsScreen: _buildTitleWidget - State is SalesFunnelLoaded');
          //print( 'ChatsScreen: _buildTitleWidget - Available funnels: ${state.funnels.map((f) => '${f.id}: ${f.name}').toList()}');
          //print('ChatsScreen: _buildTitleWidget - Selected funnel from state: ${state.selectedFunnel}');

          selectedFunnel = state.selectedFunnel ?? state.funnels.firstOrNull;
          _selectedFunnel = selectedFunnel;

          if (selectedFunnel != null) {
            title = selectedFunnel.name;
            //print( 'ChatsScreen: _buildTitleWidget - Using funnel: ${selectedFunnel.id} - ${selectedFunnel.name}');
          } else {
            //print(  'ChatsScreen: _buildTitleWidget - No funnel selected, using default title');
          }
        } else if (state is SalesFunnelError) {
          //print(   'ChatsScreen: _buildTitleWidget - State is SalesFunnelError: ${state.message}');
          title = 'Ошибка загрузки';
        }

        //print('ChatsScreen: _buildTitleWidget - Final title: $title');
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
            if (state is SalesFunnelLoaded &&
                state.funnels.length > 1 &&
                endPointInTab == 'lead')
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
                    //print('ChatsScreen: PopupMenuButton - Selected funnel: ${funnel.id} - ${funnel.name}');
                    try {
                      await apiService
                          .saveSelectedChatSalesFunnel(funnel.id.toString());
                      //print('ChatsScreen: PopupMenuButton - Saved funnel to preferences');

                      setState(() {
                        _selectedFunnel = funnel;
                        _isSearching = false;
                        searchController.clear();
                        searchQuery = '';
                      });

                      context
                          .read<SalesFunnelBloc>()
                          .add(SelectSalesFunnel(funnel));
                      _chatsBlocs[endPointInTab]!.add(ClearChats());
                      _pagingControllers[endPointInTab]!.itemList = null;
                      _pagingControllers[endPointInTab]!.refresh();

                      //print(   'ChatsScreen: PopupMenuButton - Fetching chats with new funnel and active filters: $_activeFilters');
                      _chatsBlocs[endPointInTab]!.add(FetchChats(
                        endPoint: endPointInTab,
                        salesFunnelId: funnel.id,
                        filters: _activeFilters,
                      ));
                    } catch (e) {
                      //print('ChatsScreen: PopupMenuButton - Error: $e');
                    }
                  },
                  itemBuilder: (BuildContext context) {
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

  String _getActiveFiltersText() {
    if (_activeFilters == null || !_hasActiveFilters) {
      return AppLocalizations.of(context)!.translate('no_filters_applied');
    }

    List<String> activeFiltersList = [];

    if (endPointInTab == 'lead') {
      if (_activeFilters!['managers']?.isNotEmpty == true) {
        activeFiltersList.add(
            '${AppLocalizations.of(context)!.translate('managers')} (${_activeFilters!['managers'].length})');
      }
      if (_activeFilters!['regions']?.isNotEmpty == true) {
        activeFiltersList.add(
            '${AppLocalizations.of(context)!.translate('regions')} (${_activeFilters!['regions'].length})');
      }
      if (_activeFilters!['sources']?.isNotEmpty == true) {
        activeFiltersList.add(
            '${AppLocalizations.of(context)!.translate('sources')} (${_activeFilters!['sources'].length})');
      }
      if (_activeFilters!['statuses']?.isNotEmpty == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('status'));
      }
      if (_activeFilters!['fromDate'] != null ||
          _activeFilters!['toDate'] != null) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('date_range'));
      }
      if (_activeFilters!['hasSuccessDeals'] == true) {
        activeFiltersList.add(
            AppLocalizations.of(context)!.translate('with_successful_deal'));
      }
      if (_activeFilters!['hasInProgressDeals'] == true) {
        activeFiltersList.add(
            AppLocalizations.of(context)!.translate('with_deal_in_progress'));
      }
      if (_activeFilters!['hasFailureDeals'] == true) {
        activeFiltersList.add(
            AppLocalizations.of(context)!.translate('with_unsuccessful_deal'));
      }
      if (_activeFilters!['hasNotices'] == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('with_note'));
      }
      if (_activeFilters!['hasContact'] == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('with_contacts'));
      }
      if (_activeFilters!['hasChat'] == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('with_chat'));
      }
      if (_activeFilters!['hasNoReplies'] == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('without_replies'));
      }
      if (_activeFilters!['hasUnreadMessages'] == true) {
        activeFiltersList.add(
            AppLocalizations.of(context)!.translate('with_unread_messages'));
      }
      if (_activeFilters!['hasDeal'] == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('without_deal'));
      }
      if (_activeFilters!['unreadOnly'] == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('unread_only'));
      }
      if (_activeFilters!['daysWithoutActivity'] != null &&
          _activeFilters!['daysWithoutActivity'] > 0) {
        activeFiltersList.add(
            '${AppLocalizations.of(context)!.translate('days_without_activity')} (${_activeFilters!['daysWithoutActivity']} дн.)');
      }
      if (_activeFilters!['directory_values']?.isNotEmpty == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('directory_values'));
      }
    } else if (endPointInTab == 'task') {
      if (_activeFilters!['department_id'] != null) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('department'));
      }
      if (_activeFilters!['task_created_from'] != null ||
          _activeFilters!['task_created_to'] != null) {
        activeFiltersList.add(
            AppLocalizations.of(context)!.translate('task_creation_period'));
      }
      if (_activeFilters!['deadline_from'] != null ||
          _activeFilters!['deadline_to'] != null) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('deadline_period'));
      }
      if (_activeFilters!['executor_ids']?.isNotEmpty == true) {
        activeFiltersList.add(
            '${AppLocalizations.of(context)!.translate('executors')} (${_activeFilters!['executor_ids'].length})');
      }
      if (_activeFilters!['author_ids']?.isNotEmpty == true) {
        activeFiltersList.add(
            '${AppLocalizations.of(context)!.translate('authors')} (${_activeFilters!['author_ids'].length})');
      }
      if (_activeFilters!['project_ids']?.isNotEmpty == true) {
        activeFiltersList.add(
            '${AppLocalizations.of(context)!.translate('projects')} (${_activeFilters!['project_ids'].length})');
      }
      if (_activeFilters!['task_status_ids']?.isNotEmpty == true) {
        activeFiltersList.add(
            '${AppLocalizations.of(context)!.translate('task_statuses')} (${_activeFilters!['task_status_ids'].length})');
      }
      if (_activeFilters!['unread_only'] == true) {
        activeFiltersList
            .add(AppLocalizations.of(context)!.translate('unread_only'));
      }
    }

    if (activeFiltersList.isEmpty) {
      return AppLocalizations.of(context)!.translate('no_filters_applied');
    }

    if (activeFiltersList.length <= 2) {
      return activeFiltersList.join(', ');
    } else {
      return '${activeFiltersList.take(2).join(', ')} ${AppLocalizations.of(context)!.translate('and_more')} ${activeFiltersList.length - 2}';
    }
  }

  // void _initTutorialTargets() {
  //   targets.addAll([
  //     createTarget(
  //       identify: "chatLead",
  //       keyTarget: keyChatLead,
  //       title:
  //           AppLocalizations.of(context Trepanillo!translate('tutorial_chat_lead_title'),
  //       description: AppLocalizations.of(context)!
  //           .translate('tutorial_chat_lead_description'),
  //       align: ContentAlign.bottom,
  //       extraPadding:
  //           EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.2),
  //       context: context,
  //     ),
  //     createTarget(
  //       identify: "chatTask",
  //       keyTarget: keyChatTask,
  //       title:
  //           AppLocalizations.of(context)!.translate('tutorial_chat_task_title'),
  //       description: AppLocalizations.of(context)!
  //           .translate('tutorial_chat_task_description'),
  //       align: ContentAlign.bottom,
  //       extraPadding:
  //           EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.2),
  //       context: context,
  //     ),
  //     createTarget(
  //       identify: "chatCorporate",
  //       keyTarget: keyChatCorporate,
  //       title: AppLocalizations.of(context)!
  //           .translate('tutorial_chat_corporate_title'),
  //       description: AppLocalizations.of(context)!
  //           .translate('tutorial_chat_corporate_description'),
  //       align: ContentAlign.bottom,
  //       extraPadding:
  //           EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.2),
  //       context: context,
  //     ),
  //   ]);
  // }

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
        filters:
            endPoint == 'lead' || endPoint == 'task' ? _activeFilters : null,
      ));
    });
  }

Future<void> setUpServices() async {
  debugPrint('ChatsScreen: Starting socket setup');
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? userId = prefs.getString('unique_id');

  if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
    debugPrint('ChatsScreen: Error: Token or userId is null or empty (token: $token, userId: $userId)');
    return;
  }

  // Проверяем домены для старой логики
  final enteredDomainMap = await ApiService().getEnteredDomain();
  String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
  String? enteredDomain = enteredDomainMap['enteredDomain'];

  // Проверяем домен для email-верификации
  String? verifiedDomain = await ApiService().getVerifiedDomain();
  debugPrint('ChatsScreen: Domain parameters: enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain, verifiedDomain=$verifiedDomain');

  // Если домены отсутствуют, используем verifiedDomain или резервные значения
  if (enteredMainDomain == null || enteredDomain == null) {
    if (verifiedDomain != null && verifiedDomain.isNotEmpty) {
      // Для email-верификации используем verifiedDomain
      enteredMainDomain = verifiedDomain.split('-back.').last;
      enteredDomain = verifiedDomain.split('-back.').first;
      debugPrint('ChatsScreen: Using verifiedDomain: $verifiedDomain, parsed mainDomain=$enteredMainDomain, domain=$enteredDomain');
    } else {
      // Резервные значения для отладки
      enteredMainDomain = 'shamcrm.com'; // Замени на реальный домен
      enteredDomain = 'info1fingrouptj'; // Замени на реальный поддомен
      debugPrint('ChatsScreen: Using fallback domains: enteredMainDomain=$enteredMainDomain, enteredDomain=$enteredDomain');
      // Сохраняем резервные значения в SharedPreferences
      await prefs.setString('enteredMainDomain', enteredMainDomain);
      await prefs.setString('enteredDomain', enteredDomain);
    }
  }

  final customOptions = PusherChannelsOptions.custom(
    uriResolver: (metadata) => Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
    metadata: PusherChannelsOptionsMetadata.byDefault(),
  );

  socketClient = PusherChannelsClient.websocket(
    options: customOptions,
    connectionErrorHandler: (exception, trace, refresh) {
      debugPrint('ChatsScreen: Socket connection error: $exception, StackTrace: $trace');
      Future.delayed(Duration(seconds: 5), () async {
        try {
          await socketClient.connect();
          debugPrint('ChatsScreen: Socket reconnect attempted');
        } catch (e, stackTrace) {
          debugPrint('ChatsScreen: Error reconnecting to socket: $e, StackTrace: $stackTrace');
        }
      });
      refresh();
    },
    minimumReconnectDelayDuration: const Duration(seconds: 1),
  );

  final myPresenceChannel = socketClient.presenceChannel(
    'presence-user.$userId',
    authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
      authorizationEndpoint: Uri.parse('https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Tenant': '$enteredDomain-back',
      },
      onAuthFailed: (exception, trace) {
        debugPrint('ChatsScreen: Auth failed for presence-user.$userId: $exception, StackTrace: $trace');
      },
    ),
  );

  socketClient.onConnectionEstablished.listen((_) {
    debugPrint('ChatsScreen: Socket connected successfully for userId: $userId');
    myPresenceChannel.subscribeIfNotUnsubscribed();
    debugPrint('ChatsScreen: Subscribed to channel: presence-user.$userId');
  });

  myPresenceChannel.bind('pusher:subscription_succeeded').listen((event) {
    debugPrint('ChatsScreen: Successfully subscribed to presence-user.$userId: ${event.data}');
  });

  myPresenceChannel.bind('pusher:subscription_error').listen((event) {
    debugPrint('ChatsScreen: Subscription error for presence-user.$userId: ${event.data}');
  });

  // Используем список подписок, чтобы избежать перезаписи
  final List<StreamSubscription<ChannelReadEvent>> subscriptions = [];

  subscriptions.add(
    myPresenceChannel.bind('chat.created').listen((event) async {
      debugPrint('ChatsScreen: Received chat.created event: ${event.data}');
      try {
        final chatData = json.decode(event.data);
        if (chatData.containsKey('chat') && chatData['chat'] is Map<String, dynamic>) {
          final chat = Chats.fromJson(chatData['chat']);
          await updateFromSocket(chat: chat);
        } else {
          debugPrint('ChatsScreen: Invalid chat.created data format: ${event.data}');
        }
      } catch (e, stackTrace) {
        debugPrint('ChatsScreen: Error processing chat.created event: $e, StackTrace: $stackTrace');
      }
    }),
  );

  subscriptions.add(
    myPresenceChannel.bind('chat.updated').listen((event) async {
      debugPrint('ChatsScreen: Received chat.updated event: ${event.data}');
      try {
        final chatData = json.decode(event.data);
        if (chatData.containsKey('chat') && chatData['chat'] is Map<String, dynamic>) {
          final chat = Chats.fromJson(chatData['chat']);
          await updateFromSocket(chat: chat);
        } else {
          debugPrint('ChatsScreen: Invalid chat.updated data format: ${event.data}');
        }
      } catch (e, stackTrace) {
        debugPrint('ChatsScreen: Error processing chat.updated event: $e, StackTrace: $stackTrace');
      }
    }),
  );

  // Сохраняем подписки для последующей очистки
  chatSubscribtion = subscriptions.first; // Для совместимости с текущей структурой

  try {
    await socketClient.connect();
    debugPrint('ChatsScreen: Socket connection initiated');
  } catch (e, stackTrace) {
    debugPrint('ChatsScreen: Error connecting to socket: $e, StackTrace: $stackTrace');
  }
}

Future<void> updateFromSocket({required Chats chat}) async {
  debugPrint('ChatsScreen: updateFromSocket called for chat ID: ${chat.id}, type: ${chat.type}, unreadCount: ${chat.unreadCount}, lastMessage: "${chat.lastMessage}", current endPointInTab: $endPointInTab');
  
  if (chat.type == null) {
    debugPrint('ChatsScreen: Skipping update due to null chat type');
    return;
  }
  
  // Определяем, к какой вкладке относится чат
  String chatEndpoint;
  if (chat.type == 'lead') {
    chatEndpoint = 'lead';
  } else if (chat.type == 'task') {
    chatEndpoint = 'task';
  } else if (chat.type == 'corporate') {
    chatEndpoint = 'corporate';
  } else {
    debugPrint('ChatsScreen: Unknown chat type: ${chat.type}, skipping update');
    return;
  }
  
  // Обновляем соответствующий блок
  if (_chatsBlocs.containsKey(chatEndpoint)) {
    debugPrint('ChatsScreen: Updating chat ID: ${chat.id} for endpoint $chatEndpoint');
    _chatsBlocs[chatEndpoint]!.add(UpdateChatsFromSocket(chat: chat));
    
    // Если обновляется текущая вкладка, обновляем UI
    if (chatEndpoint == endPointInTab) {
      debugPrint('ChatsScreen: Chat update for active tab $chatEndpoint, refreshing UI');
      // НЕ вызываем refresh, чтобы не перезагружать данные
      // _pagingControllers[chatEndpoint]!.refresh();
    } else {
      // Для неактивной вкладки очищаем данные, чтобы они загрузились заново при переключении
      debugPrint('ChatsScreen: Chat update for inactive tab $chatEndpoint, marking for refresh');
      _pagingControllers[chatEndpoint]!.itemList = null;
    }
  } else {
    debugPrint('ChatsScreen: No bloc found for endpoint $chatEndpoint');
  }
}
  void updateChats() {
    _chatsBlocs[endPointInTab]!.add(RefreshChats());
  }

  bool isClickAvatarIcon = false;
  int selectTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    _tabTitles = _getTabTitles(context);

    if (_isTabControllerInitialized &&
        _tabController.length != _tabTitles.length) {
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
                      filters: endPointInTab == 'lead'
                          ? _activeFilters
                          : null,
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
              showFilterIconChat: endPointInTab == 'lead' ? true : false,
              showFilterIconTaskChat: endPointInTab == 'task' ? true : false,
              onChatLeadFiltersApplied: _handleFiltersApplied,
              onChatLeadFiltersReset: _resetFilters,
              onChatTaskFiltersApplied: _handleFiltersApplied,
              onChatTaskFiltersReset: _resetFilters,
              hasActiveChatFilters: _hasActiveFilters,
              initialChatFilters: _activeFilters,
              currentSalesFunnelId: _selectedFunnel?.id,
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
                        filters: endPointInTab == 'lead'
                            ? _activeFilters
                            : null,
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
                        if (_hasActiveFilters)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.filter_list,
                                    color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getActiveFiltersText(),
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
                                    AppLocalizations.of(context)!
                                        .translate('reset'),
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
                        if (_hasActiveFilters) SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_tabTitles.length, (index) {
                              if ((index == 0 && !_showLeadChat) ||
                                  (index == 2 && !_showCorporateChat)) {
                                return Container();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
        // //print(
        //     'ChatsScreen._buildTabButton: Switching to tab $index (endpoint: ${[
        //   'lead',
        //   'task',
        //   'corporate'
        // ][index]})');
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
          filters: newEndPoint == 'task' || newEndPoint == 'lead'
              ? _activeFilters
              : null,
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
              color:
                  isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
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
    //print('_ChatItemsWidget: initState for endpoint ${widget.endPointInTab}');
  }

  @override
  void dispose() {
    //print('_ChatItemsWidget: dispose for endpoint ${widget.endPointInTab}');
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
  ); // ✅ УДАЛИЛИ .then((_) { widget.updateChats.call(); });
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
bool _shouldRefreshData(List<Chats> current, List<Chats> updated) {
  if (current.isEmpty && updated.isEmpty) {
    debugPrint('_ChatItemsWidget._shouldRefreshData: Both lists are empty, no refresh needed');
    return false;
  }
  
  if (current.length != updated.length) {
    debugPrint('_ChatItemsWidget._shouldRefreshData: Length changed from ${current.length} to ${updated.length}');
    return true;
  }
  
  final currentIds = current.map((c) => c.id).toSet();
  final updatedIds = updated.map((c) => c.id).toSet();
  
  if (!currentIds.containsAll(updatedIds) || !updatedIds.containsAll(currentIds)) {
    debugPrint('_ChatItemsWidget._shouldRefreshData: Chat IDs changed');
    return true;
  }
  
  // 🔹 НОВАЯ ПРОВЕРКА: сравниваем unreadCount и lastMessage
  for (int i = 0; i < updated.length; i++) {
    final updatedChat = updated[i];
    final currentChat = current.firstWhere(
      (c) => c.id == updatedChat.id, 
      orElse: () => updatedChat,
    );
    
    if (currentChat.unreadCount != updatedChat.unreadCount) {
      debugPrint('_ChatItemsWidget._shouldRefreshData: unreadCount changed for chat ID ${updatedChat.id}: ${currentChat.unreadCount} -> ${updatedChat.unreadCount}');
      return true;
    }
    
    if (currentChat.lastMessage != updatedChat.lastMessage) {
      debugPrint('_ChatItemsWidget._shouldRefreshData: lastMessage changed for chat ID ${updatedChat.id}');
      return true;
    }
  }
  
  // Проверяем изменение порядка
  if (_isOrderChanged(current, updated)) {
    debugPrint('_ChatItemsWidget._shouldRefreshData: Order changed');
    return true;
  }
  
  debugPrint('_ChatItemsWidget._shouldRefreshData: No changes detected');
  return false;
}
  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatsBloc, ChatsState>(
  listener: (context, state) {
    //print('_ChatItemsWidget: State=$state, endpoint=${widget.endPointInTab}');
    
    if (state is ChatsLoaded) {
      final newChats = state.chatsPagination.data;
      final currentPage = state.chatsPagination.currentPage;
      final totalPage = state.chatsPagination.totalPage;
      
      //print('_ChatItemsWidget: Loaded page $currentPage/$totalPage with ${newChats.length} chats');
      
      // ✅ КРИТИЧЕСКАЯ ПРОВЕРКА #1: Первая страница пустая
      if (currentPage == 1 && newChats.isEmpty) {
        //print('_ChatItemsWidget: No data, showing empty state');
        widget.pagingController.appendLastPage([]);
        return;
      }
      
      // ✅ КРИТИЧЕСКАЯ ПРОВЕРКА #2: Проверка на изменения
      final currentItems = widget.pagingController.itemList ?? [];
      
      if (!_shouldRefreshData(currentItems, newChats)) {
        //print('_ChatItemsWidget: No changes detected, skipping update');
        return;
      }
      
      // Обновляем данные
      widget.pagingController.itemList = null;
      
      if (currentPage >= totalPage) {
        //print('_ChatItemsWidget: Appending last page with ${newChats.length} chats');
        widget.pagingController.appendLastPage(newChats);
      } else {
        //print('_ChatItemsWidget: Appending page $currentPage with ${newChats.length} chats');
        widget.pagingController.appendPage(newChats, currentPage);
      }
      
    } else if (state is ChatsError) {
      //print('_ChatItemsWidget: Error - ${state.message}');
      widget.pagingController.error = state.message;
      
      if (state.message.contains(
        AppLocalizations.of(context)!.translate('no_internet_connection'),
      )) {
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
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } else if (state is ChatsInitial) {
      //print('_ChatItemsWidget: Initial state, resetting');
      widget.pagingController.itemList = null;
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
            //print('_ChatItemsWidget: Showing first page progress indicator for endpoint ${widget.endPointInTab}');
            return Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          },
          newPageProgressIndicatorBuilder: (context) {
            //print('_ChatItemsWidget: Showing new page progress indicator for endpoint ${widget.endPointInTab}');
            return Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          },
          itemBuilder: (context, item, index) {
            //print('_ChatItemsWidget: Rendering chat ID: ${item.id} at index $index for endpoint ${widget.endPointInTab}, unreadCount: ${item.unreadCount}');
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
  
  // НОВЫЙ МЕТОД: Проверка изменения порядка элементов
  bool _isOrderChanged(List<Chats> current, List<Chats> updated) {
    if (current.length != updated.length) return true;
    
    for (int i = 0; i < current.length && i < updated.length; i++) {
      if (current[i].id != updated[i].id) {
        return true;
      }
    }
    return false;
  }
}