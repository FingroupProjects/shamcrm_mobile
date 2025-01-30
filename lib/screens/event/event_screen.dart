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
  double _scrollPosition = 0.0;

 @override
void initState() {
  super.initState();
  _eventBloc = context.read<EventBloc>();

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
          managerIds: _selectedManagerIds?.isNotEmpty == true
              ? _selectedManagerIds
              : null,
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

  Widget _buildEventsList(List<NoticeEvent> events) {
    final localizations = AppLocalizations.of(context);

    if (_selectedManagerIds != null && _selectedManagerIds!.isNotEmpty) {
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
        controller: _tabScrollController, // Используем отдельный контроллер
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EventCard(
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
      controller: _listScrollController, // Используем отдельный контроллер
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EventCard(
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
              : localizations!
                  .translate('events'), // Changed from 'Событие' to 'events'
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
          showMyTaskIcon: false,
          showEvent: false,
          showMenuIcon: false,
          showNotification: false,
          showSeparateFilter: true,
          clearButtonClick: (value) {
            if (value == false) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _lastSearchQuery = '';
              });
              if (_searchController.text.isEmpty &&
                  _selectedManagerIds == null) {
                setState(() {
                  _showCustomTabBar = true;
                });
              } else if (_selectedManagerIds != null ||
                  _selectedManagerIds!.isNotEmpty) {
                final dealBloc = BlocProvider.of<EventBloc>(context);
                dealBloc.add(FetchEvents(
                  managerIds: _selectedManagerIds,
                  query: _searchController.text.isNotEmpty
                      ? _searchController.text
                      : null,
                ));
              }
            }
          },
          clearButtonClickFiltr: (value) {
            if (value == false) {
              setState(() {
                _selectedManagerIds = null;
              });
              if (_searchController.text.isEmpty &&
                  _selectedManagerIds == null) {
                setState(() {
                  _showCustomTabBar = true;
                });
                if (_lastSearchQuery.isNotEmpty) {
                  final dealBloc = BlocProvider.of<EventBloc>(context);
                  dealBloc.add(FetchEvents(query: _lastSearchQuery));
                } else {
                  final leadBloc = BlocProvider.of<EventBloc>(context);
                }
              } else if (_searchController.text.isNotEmpty) {
                final dealBloc = BlocProvider.of<EventBloc>(context);
                dealBloc.add(FetchEvents(
                  query: _searchController.text,
                ));
              }
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Column(
              children: [
                const SizedBox(height: 15),
                if (!_isSearching &&
                    (_selectedManagerIds == null ||
                        _selectedManagerIds!.isEmpty))
                  _buildCustomTabBar(),
                Expanded(
                  child: _selectedManagerIds != null &&
                          _selectedManagerIds!.isNotEmpty
                      ? RefreshIndicator(
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
                        )
                      // If no manager filter, show tab view as before
                      : TabBarView(
                          controller: _tabController,
                          children: _tabTitles.map((status) {
                            return RefreshIndicator(
                              color: Color(0xff1E2E52),
                              backgroundColor: Colors.white,
                              onRefresh: () async {
                                _loadEvents();
                                return Future.delayed(
                                    Duration(milliseconds: 300));
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
