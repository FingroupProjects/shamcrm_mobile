import 'dart:async';
<<<<<<< HEAD

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
=======
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
>>>>>>> main
import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase_api.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
<<<<<<< HEAD
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    setUpServices((context.read<LoginBloc>().state as LoginLoaded).user.id);
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
      connectionErrorHandler: (exception, trace, refresh) {
      },
      minimumReconnectDelayDuration: const Duration(
        seconds: 1,
      ),
    );

    final myPresenceChannel = socketClient.presenceChannel(
      'presence-user.$userId',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint:
            Uri.parse(baseUrlSocket),
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
    context.read<ChatsBloc>().add(RefreshChats());
  }

  bool isClickAvatarIcon = false;
  int selectTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          title: CustomAppBar(
            title: 'Чаты',
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
=======
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ApiService apiService = ApiService();
  bool isNavigating = false;
  bool isClickAvatarIcon = false;  
  bool _isSearching = false; 
  TextEditingController _searchController = TextEditingController();
  FocusNode _focusNode = FocusNode();


 Future<void> _searchChats(String query) async {
    print("Searching for chats: $query");
  }

  
  @override
  void initState() {
    super.initState();
    print('Инициализация ChatsScreen');
    _initializeFirebase();
  }

  void _initializeFirebase() async {
    await FirebaseApi().initNotifications();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Получено сообщение на переднем плане!');
      final chatId = message.data['chatId'];

      if (chatId != null) {
        print('Получено уведомление для чата с id: $chatId');
        
        // Передаем контекст и chatId
        checkChatExists(context, chatId).then((chatExists) async {
          if (chatExists) {
            print('Чат с id $chatId найден. Открываем его.');
            ChatItem? chatItem = await _buildChatItemById(int.parse(chatId)); // Используем await для получения результата Future
            if (chatItem != null) {
              apiService.getMessages(int.parse(chatId)).then((messages) {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatSmsScreen(
                        chatId: int.parse(chatId),
                        chatItem: chatItem,
                        messages: messages,
                      ),
                    ),
                  );
                }
              });
            } else {
              print('Ошибка: chatItem равен null.');
            }
          } else {
            print('Чат с id $chatId не найден в списке.');
          }
        });
      } else {
        print('chatId отсутствует в данных уведомления.');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final chatId = message.data['chatId'];

      if (chatId != null) {
        print('Открытие приложения через уведомление для чата с id: $chatId');
        
        // Передаем контекст и chatId
        checkChatExists(context, chatId).then((chatExists) async {
          if (chatExists) {
            print('Чат с id $chatId найден. Открываем его.');
            var chatItem = await _buildChatItemById(int.parse(chatId));
            var messages = await apiService.getMessages(int.parse(chatId));
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatSmsScreen(
                    chatId: int.parse(chatId),
                    chatItem: chatItem!,
                    messages: messages,
                  ),
                ),
              );
            }
          } else {
            print('Чат с id $chatId не найден в списке.');
          }
        }).catchError((error) {
          print('Ошибка при проверке существования чата: $error');
        });
      } else {
        print('chatId отсутствует в данных уведомления.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: 'Чат', 
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon; 
            });
          },
          onChangedSearchInput: (String value) {
            setState(() {
              if (value.isNotEmpty) {
                _isSearching = true;
              } else {
                _isSearching = false;
              }
            });
            _searchChats(value); 
          },
          textEditingController: _searchController,
          focusNode: _focusNode,
          clearButtonClick: (value) {
            if (value == false) {
              setState(() {
                _searchController.clear();
                _isSearching = false;
              });
          
            }
          },
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()  
          : FutureBuilder<List<Chats>>(
              future: apiService.getAllChats(), 
              builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки чатов: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет доступных чатов'));
          }

          final List<Chats> chats = snapshot.data!;
          for (var chat in chats) {
            print('ID чата: ${chat.id}, Имя: ${chat.name}');
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return GestureDetector(
                onTap: () async {
                  if (!isNavigating) {
                    isNavigating = true;
                    final messages = await apiService.getMessages(chat.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatSmsScreen(
                          chatItem: _buildChatItem(chat),
                          messages: messages,
                          chatId: chat.id,
                        ),
                      ),
                    ).then((_) {
                      isNavigating = false; // Сбрасываем флаг навигации
                    });
                  }
                },
                child: ChatListItem(chatItem: _buildChatItem(chat)),
              );
>>>>>>> main
            },
            onChangedSearchInput: _filterChats,
            textEditingController: searchController,
            focusNode: focusNode,
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
        floatingActionButton:(selectTabIndex == 2) ? FloatingActionButton(
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
          child:
          Image.asset('assets/icons/tabBar/add.png', width: 24, height: 24),
        ) : null,
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() {});
        selectTabIndex = index;
        _tabController.animateTo(index);

        String endPoint = '';
        if (index == 0) {
          endPoint = 'lead';
        }

        if (index == 1) {
          endPoint = 'task';
        }

        if (index == 2) {
          endPoint = 'corporate';
        }
        context.read<ChatsBloc>().add(FetchChats(endPoint: endPoint));
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
=======
  ChatItem _buildChatItem(Chats chat) {
    return ChatItem(
       chat.name,
       chat.lastMessage,
       "08:00", // Здесь можно заменить на актуальное время
       "assets/images/AvatarChat.png",
    _mapChannelToIcon(chat.channel),
>>>>>>> main
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(_tabTitles.length,
          (index) => _ChatItemsWidget(updateChats: updateChats)),
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
  const _ChatItemsWidget({required this.updateChats});

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

  Future<ChatItem?> _buildChatItemById(int chatId) async {
    final chat = await apiService.getChatById(chatId);
    if (chat != null) {
      return ChatItem(
        chat.name,
       chat.lastMessage,
        "08:00",
        "assets/images/AvatarChat.png",
        _mapChannelToIcon(chat.channel),
      );
    } else {
      print('Чат с id $chatId не найден.');
      return null;
    }
  }

  Future<bool> checkChatExists(BuildContext context, String chatId) async {
    final List<Chats> chats = await apiService.getAllChats();
    print('Полученный chatId: $chatId');
    print('Список id чатов: ${chats.map((chat) => chat.id).toList()}');

    for (var chat in chats) {
      if (chat.id == int.parse(chatId)) {
        print('Найден чат с id: $chatId');

        // Получение сообщений чата
        final messages = await apiService.getMessages(chat.id);

        // Переход на экран с сообщениями чата
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatSmsScreen(
              chatItem: _buildChatItem(chat),
              messages: messages,
              chatId: chat.id,
            ),
          ),
        );

        return true;
      }
    }
    print('Чат с id $chatId не найден.');
    return false;
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

}
