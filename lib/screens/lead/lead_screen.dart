import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

class LeadScreen extends StatefulWidget {
  final int? initialStatusId;

  LeadScreen({this.initialStatusId});

  @override
  _LeadScreenState createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _tabTitles = [];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _canReadLeadStatus = false;
  bool _canCreateLeadStatus = false;
  bool _canDeleteLeadStatus = false;
  final ApiService _apiService = ApiService();
  bool navigateToEnd = false;
  bool navigateAfterDelete = false;
  int? _deletedIndex;
  int? _selectedManagerId; // ID выбранного менеджера.

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Попытка получить данные из кеша
   LeadCache.getLeadStatuses().then((cachedStatuses) {
    if (cachedStatuses.isNotEmpty) {
      setState(() {
        _tabTitles = cachedStatuses
            .map((status) => {'id': status['id'], 'title': status['title']})
            .toList();

        _tabController = TabController(length: _tabTitles.length, vsync: this);
        _tabController.index = _currentTabIndex;

        _tabController.addListener(() {
          setState(() {
            _currentTabIndex = _tabController.index;
          });
          _scrollToActiveTab();
        });
      });
    } else {
      // Если статусов в кэше нет — запрос через API
      final leadBloc = BlocProvider.of<LeadBloc>(context);
      leadBloc.add(FetchLeadStatuses());
    }
  });

  // Проверка лидов в кэше для начального статуса
  LeadCache.getLeadsForStatus(widget.initialStatusId).then((cachedLeads) {
    if (cachedLeads.isNotEmpty) {
      print('Leads loaded from cache.');
    }
  });
    // Проверка разрешений
    _checkPermissions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLeads(String query, int currentStatusId) async {
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    if (query.isEmpty) {
      leadBloc.add(FetchLeads(currentStatusId, managerId: _selectedManagerId));
    } else {
      leadBloc.add(FetchLeads(currentStatusId,
          query: query, managerId: _selectedManagerId));
    }
  }

// Добавляем метод для обработки выбора менеджера
  void _handleManagerSelected(dynamic manager) {
    setState(() {
      _selectedManagerId = manager?.id;
    });
    _refreshCurrentTab();

    // Запрашиваем обновленные данные с учетом выбранного менеджера
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeads(
      currentStatusId,
      managerId: _selectedManagerId,
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
    ));
  }

  void _refreshCurrentTab() {
    if (_tabTitles.isNotEmpty) {
      final currentStatusId = _tabTitles[_currentTabIndex]['id'];
      final leadBloc = BlocProvider.of<LeadBloc>(context);
      leadBloc.add(FetchLeads(
        currentStatusId,
        managerId: _selectedManagerId,
        query:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      ));
    }
  }

  void _onSearch(String query) {
    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    _searchLeads(query, currentStatusId);
  }

  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('leadStatus.read');
    final canCreate = await _apiService.hasPermission('leadStatus.create');
    final canDelete = await _apiService.hasPermission('leadStatus.delete');
    setState(() {
      _canReadLeadStatus = canRead;
      _canCreateLeadStatus = canCreate;
      _canDeleteLeadStatus = canDelete;
    });
  }

  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();
  ValueChanged<String>? onChangedSearchInput;

  bool isClickAvatarIcon = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: isClickAvatarIcon ? 'Настройки' : 'Лиды',
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
          onManagerSelected: _handleManagerSelected,
          textEditingController: textEditingController,
          focusNode: focusNode,
          showFilterTaskIcon: false,
          clearButtonClick: (value) {
            if (value == false) {
            // BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());

              final leadBloc = BlocProvider.of<LeadBloc>(context);
              leadBloc.add(FetchLeadStatuses());
              setState(() {
                _isSearching = false;
                _selectedManagerId = null;
              });
            }
          },
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Column(
              children: [
                const SizedBox(height: 15),
                if (!_isSearching && _selectedManagerId == null)
                  _buildCustomTabBar(),
                Expanded(
                  child: _selectedManagerId != null
                      ? _buildManagerView()
                      : _buildTabBarView(),
                ),
              ],
            ),
    );
  }

  Widget searchWidget(List<Lead> leads) {
    if (_isSearching && leads.isEmpty) {
      return Center(
        child: Text(
          'По запросу ничего не найдено',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LeadCard(
              lead: lead,
              title: lead.leadStatus?.title ?? "",
              statusId: lead.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusLeadId) {},
            ),
          );
        },
      ),
    );
  }

  Widget _buildManagerView() {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        if (state is LeadDataLoaded) {
          final List<Lead> leads = state.leads;
          return managerWidget(leads);
        }
        if (state is LeadLoading) {
          return const Center(
            child: PlayStoreImageLoading(
              size: 80.0,
              duration: Duration(milliseconds: 1000),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget managerWidget(List<Lead> leads) {
    if (_selectedManagerId != null && leads.isEmpty) {
      return Center(
        child: Text(
          'У выбранного менеджера нет лидов',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LeadCard(
              lead: lead,
              title: lead.leadStatus?.title ?? "",
              statusId: lead.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusLeadId) {},
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: [
          ...List.generate(_tabTitles.length, (index) {
            if (_tabKeys.length <= index) {
              _tabKeys.add(GlobalKey());
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildTabButton(index),
            );
          }),
          if (_canCreateLeadStatus)
            IconButton(
              icon: Image.asset('assets/icons/tabBar/add_black.png',
                  width: 24, height: 24),
              onPressed: _addNewTab,
            ),
        ],
      ),
    );
  }

  void _addNewTab() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => CreateStatusDialog(),
    );

    if (result == true) {
      context.read<LeadBloc>().add(FetchLeadStatuses());
    
       setState(() {
        navigateToEnd = true;
      });
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        int leadCount = 0;

        if (state is LeadLoaded) {
          final statusId = _tabTitles[index]['id'];
          final leadStatus = state.leadStatuses.firstWhere(
            (status) => status.id == statusId,
            // orElse: () => 1,
          );
          leadCount = leadStatus?.leadsCount ?? 0; // Используем leadsCount
        }

        return GestureDetector(
          key: _tabKeys[index],
          onTap: () {
            _tabController.animateTo(index);
          },
          onLongPress: () {
            if (_canDeleteLeadStatus) {
              _showDeleteDialog(index);
            }
          },
          child: Container(
            decoration: TaskStyles.tabButtonDecoration(isActive),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tabTitles[index]['title'],
                  style: TaskStyles.tabTextStyle.copyWith(
                    color: isActive
                        ? TaskStyles.activeColor
                        : TaskStyles.inactiveColor,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(12, 0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xff1E2E52)
                            : const Color(0xff99A4BA),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      leadCount.toString(),
                      style: TextStyle(
                        color:
                            isActive ? Colors.black : const Color(0xff99A4BA),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

void _showDeleteDialog(int index) async {
  final leadStatusId = _tabTitles[index]['id'];

  final result = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return DeleteLeadStatusDialog(leadStatusId: leadStatusId);
    },
  );

  if (result != null && result) {
    setState(() {
      _deletedIndex = _currentTabIndex;
      navigateAfterDelete = true;

      _tabTitles.removeAt(index);
      _tabKeys.removeAt(index);
      _tabController = TabController(length: _tabTitles.length, vsync: this);

      _currentTabIndex = 0;
      _isSearching = false;
      _searchController.clear();

      context.read<LeadBloc>().add(FetchLeads(_currentTabIndex));
    });

    // 🔄 Отправляем запрос на обновление статусов лидов
    context.read<LeadBloc>().add(FetchLeadStatuses()); // Pass forceRefresh flag
  }
}

  Widget _buildTabBarView() {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) async {
        if (state is LeadLoaded) {
          // Perform async work first
         await LeadCache.cacheLeadStatuses(state.leadStatuses
          .map((status) => {'id': status.id, 'title': status.title})
          .toList());

          // Now, update the state synchronously
          setState(() {
            _tabTitles = state.leadStatuses
                .where((status) => _canReadLeadStatus)
                .map((status) => {'id': status.id, 'title': status.title})
                .toList();

            _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

            if (_tabTitles.isNotEmpty) {
              _tabController =
                  TabController(length: _tabTitles.length, vsync: this);
              _tabController.addListener(() {
                setState(() {
                  _currentTabIndex = _tabController.index;
                });
                final currentStatusId = _tabTitles[_currentTabIndex]['id'];
                if (_scrollController.hasClients) {
                  _scrollToActiveTab();
                }
              });
              int initialIndex = state.leadStatuses
                  .indexWhere((status) => status.id == widget.initialStatusId);
              if (initialIndex != -1) {
                _tabController.index = initialIndex;
                _currentTabIndex = initialIndex;
              } else {
                _tabController.index = _currentTabIndex;
              }

              if (_scrollController.hasClients) {
                _scrollToActiveTab();
              }

              //Логика для перехода к созданн статусе
              if (navigateToEnd) {
                navigateToEnd = false;
                if (_tabController != null) {
                  _tabController.animateTo(_tabTitles.length - 1);
                }
              }

              //Логика для перехода к после удаления статусе на лево
              if (navigateAfterDelete) {
                navigateAfterDelete = false;
                if (_deletedIndex != null) {
                  if (_deletedIndex == 0 && _tabTitles.length > 1) {
                    _tabController.animateTo(1);
                  } else if (_deletedIndex == _tabTitles.length) {
                    _tabController.animateTo(_tabTitles.length - 1);
                  } else {
                    _tabController.animateTo(_deletedIndex! - 1);
                  }
                }
              }

              // Сохраняем данные в кеш
              // LeadCache.cacheLeadStatuses(_tabTitles);
            }
          });
        } else if (state is LeadError) {
          if (state.message.contains("Неавторизованный доступ!")) {
            ApiService apiService = ApiService();
            await apiService.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
            );
          } else if (state.message.contains("Нет подключения к интернету")) {
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
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          print('state: ${state.runtimeType}');
          if (state is LeadDataLoaded) {
            final List<Lead> leads = state.leads;
            print(leads);
            return searchWidget(leads);
          }
          if (state is LeadLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is LeadLoaded) {
            if (_tabTitles.isEmpty) {
              return const Center(child: Text(''));
            }
            return TabBarView(
              controller: _tabController,
              children: List.generate(_tabTitles.length, (index) {
                final statusId = _tabTitles[index]['id'];
                final title = _tabTitles[index]['title'];
                return LeadColumn(
                  statusId: statusId,
                  title: title,
                  managerId: _selectedManagerId, // Передаем ID менеджера
                  onStatusId: (newStatusId) {
                    print('Status ID changed: $newStatusId');
                    final index = _tabTitles.indexWhere((status) => status['id'] == newStatusId);

                    BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());

                    if (index != -1) {
                      _tabController.animateTo(index);
                    }
                  },
                );
              }),
            );
          }
          return const SizedBox();
        },
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
}
