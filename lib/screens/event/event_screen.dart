// event_screen.dart
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/event/event_details/event_add_screen.dart';
import 'package:crm_task_manager/screens/event/event_details/event_card.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventScreen extends StatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final List<Map<String, dynamic>> _tabTitles = [
    {'id': 1, 'title': 'В процессе'},
    {'id': 2, 'title': 'Завершено'},
  ];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  bool isClickAvatarIcon = false;
  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();
  late final EventBloc _eventBloc;
  String _lastSearchQuery = "";
  List<int>? _selectedManagerIds; // Add this field
  int? _selectedManagerId; // ID выбранного менеджера.
    bool _showCustomTabBar = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      if (_scrollController.hasClients) {
        _scrollToActiveTab();
      }
      // Загружаем события при смене таба
      _loadEvents();
    });

    // Начальная загрузка событий
    _loadEvents();
     // Добавляем слушатель для ScrollController
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_eventBloc.allEventsFetched) {
        _eventBloc.add(FetchMoreEvents(_currentTabIndex + 1));
      }
    });
  }

  void _loadEvents() {
    final bool isCompleted = _currentTabIndex == 1;
    context.read<EventBloc>().add(FetchEvents());
  }
Future<void> _searchEvents(String query, int currentStatusId) async {
    if (query.isEmpty) {
      if (_selectedManagerIds != null && _selectedManagerIds!.isNotEmpty) {
        context.read<EventBloc>().add(FetchEvents(
          managerIds: _selectedManagerIds,
        ));
      } else {
        context.read<EventBloc>().add(FetchEvents(query: " "));
      }
    } else {
      context.read<EventBloc>().add(FetchEvents(
        query: query,
        managerIds: _selectedManagerIds,
      ));
    }
  }

  Future<void> _handleManagerSelected(List<dynamic> managers) async {
    setState(() {
      _showCustomTabBar = false;
      _selectedManagerIds = managers
          .map((manager) {
            if (manager is String) {
              return int.tryParse(manager);
            } else if (manager is ManagerData) {
              return manager.id;
            }
            return null;
          })
          .where((id) => id != null)
          .cast<int>()
          .toList();
    });

    context.read<EventBloc>().add(FetchEvents(
      managerIds: _selectedManagerIds?.isNotEmpty == true ? _selectedManagerIds : null,
      query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
    ));
  }

  void _onSearch(String query) {
    _lastSearchQuery = query;
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchEvents(query, currentStatusId);
  }

  // Фильтрация событий по статусу
  List<NoticeEvent> _filterEvents(List<NoticeEvent> events, bool isCompleted) {
    return events.where((event) => event.isFinished == isCompleted).toList();
  }

  Widget _buildEventsList(List<NoticeEvent> events) {
    final filteredEvents = _filterEvents(events, _currentTabIndex == 1);

    if (filteredEvents.isEmpty) {
      return Center(
        child: Text(
          'Нет событий в разделе "${_tabTitles[_currentTabIndex]['title']}"',
          style: TextStyle(
            color: Color(0xff99A4BA),
            fontSize: 14,
            fontFamily: 'Gilroy',
          ),
        ),
      );
    }
//  final ScrollController _scrollController = ScrollController();
//               _scrollController.addListener(() {
//                 if (_scrollController.position.pixels ==
//                         _scrollController.position.maxScrollExtent &&
//                     !_eventBloc.allEventsFetched) {
//                   _eventBloc
//                       .add(FetchMoreEvents(widget. state.currentPage));
//                 }
//               });

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EventCard(
            event: filteredEvents[index],
            onStatusUpdated: () {
              // Обновляем список событий при изменении статуса
              _loadEvents();
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 45,
      child: SingleChildScrollView(
        controller: _scrollController,
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
      final position =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;

      if (position.dx < 0 ||
          (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
        double targetOffset = _scrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);

        if (targetOffset != _scrollController.offset) {
          _scrollController.animateTo(
            targetOffset,
            duration: Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      }
    }
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
              : localizations!.translate('События'),
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
          onManagersSelected: _handleManagerSelected,
          textEditingController: textEditingController,
          focusNode: focusNode,
          showFilterTaskIcon: false,
          showMyTaskIcon: true, 
          showEvent: true,

clearButtonClick: (value) {
  if (value == false) {
    // Сброс поиска
    setState(() {
      _isSearching = false;
      _searchController.clear(); 
      _lastSearchQuery = ''; 
    });
    // Если оба пустые (поиск и фильтр), сбрасываем состояние полностью
    if (_searchController.text.isEmpty && _selectedManagerIds == null) {
      setState(() {
        _showCustomTabBar = true; 
      });
      final leadBloc = BlocProvider.of<EventBloc>(context);
    } else if (_selectedManagerIds != null || _selectedManagerIds!.isNotEmpty) {
      // Если фильтр активен, показываем результаты фильтрации
      final currentStatusId = _tabTitles[_currentTabIndex]['id'];
      final dealBloc = BlocProvider.of<EventBloc>(context);
      dealBloc.add(FetchEvents(
        managerIds: _selectedManagerIds,
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
      ));
    } 
  }
},
clearButtonClickFiltr: (value) {
  if (value == false) {
    // Сброс фильтра
    setState(() {
      _selectedManagerIds = null; // Обнуляем выбранных менеджеров
    });
    // Если оба пустые (поиск и фильтр), сбрасываем состояние полностью
    if (_searchController.text.isEmpty && _selectedManagerIds == null) {
      setState(() {
        _showCustomTabBar = true; // Показываем кастомные табы
      });
      // Проверка на наличие предыдущего запроса поиска
      if (_lastSearchQuery.isNotEmpty) {
        final currentStatusId = _tabTitles[_currentTabIndex]['id'];
        final dealBloc = BlocProvider.of<EventBloc>(context);
        print('Возвращаем поиск после сброса фильтра');
        dealBloc.add(FetchEvents(query: _lastSearchQuery));
      } else  {
        // Если и поиск, и фильтр пусты, показываем все сделки
        final leadBloc = BlocProvider.of<EventBloc>(context);
        print('Сброс и поиск пуст, возвращаем все сделки');
        // leadBloc.add(FetchStatuses());
      }
    } else if (_searchController.text.isNotEmpty) {
      // Если поиск активен, показываем результаты поиска
      final currentStatusId = _tabTitles[_currentTabIndex]['id'];
      final dealBloc = BlocProvider.of<EventBloc>(context);
      dealBloc.add(FetchEvents(
        query: _searchController.text,
      ));
    }
  }
}

        ),
      ), // Add this floatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoticeAddScreen(),
            ),
          ).then((_) => _loadEvents()); // Reload events after returning
        },
        backgroundColor: Color(0xff1E2E52),
        child: Image.asset(
          'assets/icons/tabBar/add.png',
          width: 24,
          height: 24,
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Column(
              children: [
                const SizedBox(height: 15),
                if (!_isSearching) _buildCustomTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabTitles.map((status) {
                      return RefreshIndicator(
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
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
