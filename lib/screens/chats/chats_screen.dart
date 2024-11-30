import 'dart:async';

import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_state.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/screens/lead/tabBar/bottom_sheet_add_client_dialog.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
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
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with TickerProviderStateMixin {
  final ApiService apiService = ApiService(); // Инициализация ApiService
  bool isNavigating = false;
  late Future<List<Chats>> futureChats;
  List<Chats> allChats = [];
  List<Chats> filteredChats = [];
  TextEditingController searchController = TextEditingController();
  FocusNode focusNode = FocusNode();
  late TabController _tabController;
  final List<String> _tabTitles = ['Лиды', 'Задачи', 'Корпоративный чат'];
  late PusherChannelsClient socketClient;
  late StreamSubscription<ChannelReadEvent> chatSubscribtion;

  // todo: 1. tab's key value for opened profile screen.
  String endPointInTab = 'lead';
@override
void initState() {
  super.initState();
  _tabController = TabController(length: _tabTitles.length, vsync: this);

  final currentState = context.read<LoginBloc>().state;
  if (currentState is LoginLoaded) {
    setUpServices(currentState.user.id);
  } else {
    // Логируем или обрабатываем случай, когда состояние ещё не `LoginLoaded`
    print('Состояние LoginBloc: $currentState');
  }

  context.read<ChatsBloc>().add(FetchChats(endPoint: 'lead'));
}


  void _filterChats(String query) {
    isClickAvatarIcon = false;
    if (query.isEmpty) {
      setState(() {
        filteredChats = allChats;
      });
    } else {
      setState(() {
        filteredChats = allChats
            .where(
                (chat) => chat.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void updateFromSocket() {
    context.read<ChatsBloc>().add(UpdateChatsFromSocket());
  }

  Future<void> setUpServices(int userId) async {
    debugPrint('--------------------------- start socket:::::::');
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final customOptions = PusherChannelsOptions.custom(
      // You may also apply the given metadata in your custom uri
      uriResolver: (metadata) =>
          Uri.parse('wss://soketi.shamcrm.com/app/app-key'),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    socketClient = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {},
      minimumReconnectDelayDuration: const Duration(
        seconds: 1,
      ),
    );

    final myPresenceChannel = socketClient.presenceChannel(
      'presence-user.$userId',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(baseUrlSocket),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': 'fingroup-back'
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
    return Unfocuser(
      child: Scaffold(
        appBar: AppBar(
        forceMaterialTransparency: true,
          elevation: 1,
          title: CustomAppBar(
            title: 'Чаты',
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
            },
            onChangedSearchInput: _filterChats,
            textEditingController: searchController,
            focusNode: focusNode,
            clearButtonClick: (isSearching) {},
          ),
          backgroundColor: Colors.white,
        ),
        backgroundColor: Colors.white,
        body: isClickAvatarIcon == true
            ? ProfileScreen()
            : Column(
                children: [
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabTitles.length, (index) {
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
              ),
        floatingActionButton: (selectTabIndex == 2)
            ? FloatingActionButton(
                onPressed: () {
                  showCupertinoModalBottomSheet(
                    context: context,
                    expand: false,
                    elevation: 4,
                    isDismissible: false,
                    builder: (context) => BottomSheetAddClientDialog(),
                  );
                },
                backgroundColor: Color(0xff1E2E52),
                child: Image.asset('assets/icons/tabBar/add.png',
                    width: 24, height: 24),
              )
            : null,
      ),
    );
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() {});
        selectTabIndex = index;
        _tabController.animateTo(index);

        // todo: 2. tab's key value for opened profile screen.
        if (index == 0) {
          endPointInTab = 'lead';
        }
        // todo: 3. tab's key value for opened profile screen.
        if (index == 1) {
          endPointInTab = 'task';
        }
        // todo: 4. tab's key value for opened profile screen.
        if (index == 2) {
          endPointInTab = 'corporate';
        }
        context.read<ChatsBloc>().add(FetchChats(endPoint: endPointInTab));
      },
      child: Container(
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
      children: List.generate(_tabTitles.length,
          (index) => _ChatItemsWidget(updateChats: updateChats, endPointInTab: endPointInTab,)),
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
  // todo: tab's key value for opened profile screen.
  final String endPointInTab;
  const _ChatItemsWidget({required this.updateChats, required this.endPointInTab});

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
      context.read<ChatsBloc>().add(GetNextPageChats());
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void onTap(Chats chat) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MessagingCubit(ApiService()),
          child: ChatSmsScreen(
            chatItem: chat.toChatItem("assets/images/AvatarChat.png"),
            chatId: chat.id,
            // todo: tab's key value for opened profile screen.
            endPointInTab: widget.endPointInTab,
          ),
        ),
      ),
    ).then((_) {
      widget.updateChats.call();
    });
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
      },
      child: PagedListView<int, Chats>(
        padding: EdgeInsets.symmetric(vertical: 0),
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Chats>(
            itemBuilder: (context, item, index) {
          return InkWell(
            onTap: () => onTap(item),
            splashColor: AppColors.primaryBlue,
            focusColor: Colors.black87,
            child: ChatListItem(
              chatItem: item.toChatItem("assets/images/AvatarChat.png"),
            ),
          );
        }),
      ),
    );
  }
}
