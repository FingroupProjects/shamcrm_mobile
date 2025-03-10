import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
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

Map<String, dynamic>? tutorialProgress; // Добавлено: Для хранения прогресса туториалов

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

  Future<void> _checkPermissions() async {
    final LeadChat = await apiService.hasPermission('chat.read');
    final CorporateChat = await apiService.hasPermission('corporateChat.read');

    setState(() {
      _showLeadChat = LeadChat;
      _showCorporateChat = CorporateChat;

      if (!_showLeadChat && !_showCorporateChat) {
        selectTabIndex = 1;
        context.read<ChatsBloc>().add(FetchChats(endPoint: 'task'));
      } else if (!_showLeadChat) {
        selectTabIndex = 1;
        context.read<ChatsBloc>().add(FetchChats(endPoint: 'task'));
      } else if (!_showCorporateChat) {
        selectTabIndex = 0;
        context.read<ChatsBloc>().add(FetchChats(endPoint: 'lead'));
      } else {
        selectTabIndex = 0;
        context.read<ChatsBloc>().add(FetchChats(endPoint: 'lead'));
      }
      _isPermissionsChecked = true;
    });
  }

@override
void initState() {
  super.initState();
  _checkPermissions().then((_) {
    if (_isPermissionsChecked) {
      setState(() {
        _tabTitles = [
          AppLocalizations.of(context)!.translate('tab_leads'),
          AppLocalizations.of(context)!.translate('tab_tasks'),
          AppLocalizations.of(context)!.translate('tab_corp_chat'),
        ];

        _tabController = TabController(
          length: _tabTitles.length,
          vsync: this,
          initialIndex: selectTabIndex,
        );
      });
      setUpServices();
    }
    _fetchTutorialProgress(); // Переносим сюда для синхронной загрузки
  });
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initTutorialTargets();
  });
}
Future<void> _fetchTutorialProgress() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final progress = await apiService.getTutorialProgress();
    setState(() {
      tutorialProgress = progress['result'];
    });
    await prefs.setString('tutorial_progress', json.encode(progress['result']));
    bool isTutorialShown = prefs.getBool('isTutorialShowninChat') ?? false;
    if (isTutorialShown) {
      setState(() {
        _isTaskScreenTutorialCompleted = true;
        _isTutorialShown = true; // Синхронизируем флаг
      });
    }
    // Проверяем условия и вызываем туториал только если он еще не показан
    if (tutorialProgress != null &&
        tutorialProgress!['chat']?['index'] == false &&
        !isTutorialShown &&
        !_isTutorialShown && // Добавляем проверку локального флага
        mounted) {
      showTutorial();
    }
  } catch (e) {
    print('Error fetching tutorial progress: $e');
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
          _isTutorialShown = true; // Синхронизируем флаг
        });
      }
      if (tutorialProgress != null &&
          tutorialProgress!['chat']?['index'] == false &&
          !isTutorialShown &&
          !_isTutorialShown && // Добавляем проверку локального флага
          mounted) {
        showTutorial();
      }
    }
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
  if (_isTutorialShown) return; // Предотвращаем повторный вызов

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
      print("Пропустить");
      prefs.setBool('isTutorialShowninChat', true);
      apiService.markPageCompleted("chat", "index").catchError((e) {
        print('Error marking page completed on skip: $e');
      });
      setState(() {
        _isTaskScreenTutorialCompleted = true;
        _isTutorialShown = true;
      });
      return true;
    },
    onFinish: () async {
      print("Завершено");
      await prefs.setBool('isTutorialShowninChat', true);
      try {
        await apiService.markPageCompleted("chat", "index");
      } catch (e) {
        print('Error marking page completed on finish: $e');
      }
      setState(() {
        _isTaskScreenTutorialCompleted = true;
        _isTutorialShown = true;
      });
    },
  ).show(context: context);
}
  final PagingController<int, Chats> _pagingController =
      PagingController(firstPageKey: 0);

  void _searchChats(String query, String endPoint) {
    _pagingController.refresh();

    final chatsBloc = BlocProvider.of<ChatsBloc>(context);
    if (query.isEmpty) {
      chatsBloc.add(FetchChats(endPoint: endPoint));
    } else {
      chatsBloc.add(FetchChats(endPoint: endPoint, query: query));
    }
  }

  Timer? _debounce;

  void _onSearch(String query) {
    setState(() {
      searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    final endPoint = endPointInTab;

    final chatsBloc = context.read<ChatsBloc>();
    chatsBloc.add(ClearChats());

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      chatsBloc.add(FetchChats(endPoint: endPoint, query: query));
    });
  }

  void updateFromSocket() {
    context.read<ChatsBloc>().add(UpdateChatsFromSocket());
  }

  Future<void> setUpServices() async {
    debugPrint('--------------------------- start socket:::::::');
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final baseUrlSocket = await apiService.getSocketBaseUrl();
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
      minimumReconnectDelayDuration: const Duration(
        seconds: 1,
      ),
    );
    String userId = prefs.getString('userID').toString();
    print('userID : $userId');

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

      chatSubscribtion = myPresenceChannel.bind('chat.created').listen((event) {
        if (kDebugMode) {
          print(event.data);
          print(event.channelName);
          print('------ socket');
          print('--------');
          print('--------');
        }
        updateFromSocket();
      });

      chatSubscribtion = myPresenceChannel.bind('chat.updated').listen((event) {
        if (kDebugMode) {
          print(event.data);
          print(event.channelName);
          print('------ socket');
          print('--------');
          print('--------');
        }
        updateFromSocket();
      });
    });

    try {
      await socketClient.connect();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void updateChats() {
    // context.read<ChatsBloc>().add(RefreshChats());
  }

  bool isClickAvatarIcon = false;
  int selectTabIndex = 0;

@override
Widget build(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  return Unfocuser(
    child: Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        elevation: 1,
        title: CustomAppBar(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('appbar_chats'),
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
              if (!isClickAvatarIcon) {
                if (selectTabIndex == 0) {
                  context.read<ChatsBloc>().add(FetchChats(endPoint: 'lead'));
                } else if (selectTabIndex == 1) {
                  context.read<ChatsBloc>().add(FetchChats(endPoint: 'task'));
                } else if (selectTabIndex == 2) {
                  context.read<ChatsBloc>().add(FetchChats(endPoint: 'corporate'));
                }
              }
            });
          },
          textEditingController: searchController,
          focusNode: focusNode,
          showFilterIcon: false,
          showFilterTaskIcon: false,
          showMyTaskIcon: false,
          showMenuIcon: false,
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
                  final chatsBloc = context.read<ChatsBloc>();
                  chatsBloc.add(ClearChats());
                  if (selectTabIndex == 0) {
                    context.read<ChatsBloc>().add(FetchChats(endPoint: 'lead'));
                  } else if (selectTabIndex == 1) {
                    context.read<ChatsBloc>().add(FetchChats(endPoint: 'task'));
                  } else if (selectTabIndex == 2) {
                    context.read<ChatsBloc>().add(FetchChats(endPoint: 'corporate'));
                  }
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_tabTitles.length, (index) {
                          if ((index == 0 && !_showLeadChat) || (index == 2 && !_showCorporateChat)) {
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
              child: Image.asset('assets/icons/tabBar/add.png', width: 24, height: 24),
            )
          : null,
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
      setState(() {
        selectTabIndex = index;
      });
      _tabController.animateTo(index);

      if (index == 0) {
        endPointInTab = 'lead';
        context.read<ChatsBloc>().add(ClearChats());
      }
      if (index == 1) {
        endPointInTab = 'task';
        context.read<ChatsBloc>().add(ClearChats());
      }
      if (index == 2) {
        endPointInTab = 'corporate';
        context.read<ChatsBloc>().add(ClearChats());
      }

      if (_debounce?.isActive ?? false) _debounce?.cancel();

      _debounce = Timer(const Duration(seconds: 2), () {
        final chatsBloc = context.read<ChatsBloc>();
        chatsBloc.add(ClearChats());

        chatsBloc.add(FetchChats(endPoint: endPointInTab));
      });
    },
    child: Container(
      key: tabKey, // Привязываем ключ к контейнеру таба
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
          (index) => _ChatItemsWidget(
                updateChats: updateChats,
                endPointInTab: index == 1 ? 'task' : endPointInTab,
              )),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    chatSubscribtion.cancel();
    socketClient.dispose();
    super.dispose();
  }
}

class _ChatItemsWidget extends StatefulWidget {
  final VoidCallback updateChats;
  final String endPointInTab;

  const _ChatItemsWidget(
      {required this.updateChats, required this.endPointInTab});

  @override
  State<_ChatItemsWidget> createState() => _ChatItemsWidgetState();
}

class _ChatItemsWidgetState extends State<_ChatItemsWidget> {
  final PagingController<int, Chats> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      if (pageKey == 0) {
        _pagingController.refresh();
      }
      context.read<ChatsBloc>().add(GetNextPageChats());
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
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
          _pagingController.refresh();
        }
        if (state is ChatsLoaded) {
          if (state.chatsPagination.currentPage ==
              state.chatsPagination.totalPage) {
            _pagingController.appendLastPage(state.chatsPagination.data);
          } else {
            _pagingController.appendPage(state.chatsPagination.data,
                state.chatsPagination.currentPage + 1);
          }
        }
        if (state is ChatsError) {
          if (state.message.contains(AppLocalizations.of(context)!
              .translate('no_internet_connection'))) {
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
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Chats>(
          noItemsFoundIndicatorBuilder: (context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .translate('nothing_found_chat'),
                    style:
                        TextStyle(fontSize: 18, color: AppColors.primaryBlue),
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
            return Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          },
          newPageProgressIndicatorBuilder: (context) {
            return Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          },
          itemBuilder: (context, item, index) {
            return InkWell(
              onTap: () => onTap(item),
              onLongPress: () => onLongPress(item),
              splashColor: Colors.grey,
              focusColor: Colors.black87,
              child: ChatListItem(
                chatItem: item.toChatItem(),
              ),
            );
          },
        ),
      ),
    );
  }
}
