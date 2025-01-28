import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
import 'package:crm_task_manager/screens/lead/lead_status_edit.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
  bool _isManager = false;
  bool _isFiltr = false;
  final TextEditingController _searchController = TextEditingController();
  bool _canReadLeadStatus = false;
  bool _canCreateLeadStatus = false;
  bool _canDeleteLeadStatus = false;
  final ApiService _apiService = ApiService();
  bool navigateToEnd = false;
  bool navigateAfterDelete = false;
  int? _deletedIndex;

  bool _showCustomTabBar = true;

  int? _selectedManagerId; // ID выбранного менеджера.
  List<int> _selectedManagerIds = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Попытка получить данные из кеша
    LeadCache.getLeadStatuses().then((cachedStatuses) {
      if (cachedStatuses.isNotEmpty) {
        setState(() {
          final leadBloc = BlocProvider.of<LeadBloc>(context);
          leadBloc.add(FetchLeadStatuses());

          _tabTitles = cachedStatuses
              .map((status) => {'id': status['id'], 'title': status['title']})
              .toList();
          _tabController =
              TabController(length: _tabTitles.length, vsync: this);
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
      leadBloc.add(FetchLeads(
        currentStatusId, // status_id передается
        managerIds: _selectedManagerIds, // менеджеры передаются
      ));
    } else {
      leadBloc.add(FetchLeads(
        currentStatusId, // status_id передается
        query: query, // поисковый запрос передается
        managerIds: _selectedManagerIds, // менеджеры передаются
      ));
    }
  }
}

// Добавляем метод для обработки выбора менеджера

  Future<void> _handleManagerSelected(List<dynamic> managers) async {
    await LeadCache.clearAllLeads();

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
    _refreshCurrentTab();

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeads(
      currentStatusId,
      managerIds: _selectedManagerIds.isNotEmpty ? _selectedManagerIds : null,
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
    ));
  }

  void _refreshCurrentTab() {
    if (_tabTitles.isNotEmpty) {
      final currentStatusId = _tabTitles[_currentTabIndex]['id'];
      final leadBloc = BlocProvider.of<LeadBloc>(context);
      leadBloc.add(FetchLeads(
        currentStatusId,
        managerIds: _selectedManagerIds.isNotEmpty ? _selectedManagerIds : null,
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
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('appbar_leads'),
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
          showMyTaskIcon: true, // Выключаем иконку My Tasks
          showEvent: false,

          clearButtonClick: (value) {
            if (value == false) {
              // BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());

              final leadBloc = BlocProvider.of<LeadBloc>(context);
              leadBloc.add(FetchLeadStatuses());
              setState(() {
                _isSearching = false;
                _showCustomTabBar = true;
                _selectedManagerId = null;
              });
            }
          },
          clearButtonClickFiltr: (value) {
            if (value == false) {
              final leadBloc = BlocProvider.of<LeadBloc>(context);
              leadBloc.add(FetchLeadStatuses());
              setState(() {
                _isFiltr = false;
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
                // Условие для отображения табов с использованием флага
                if (!_isSearching &&
                    _selectedManagerId == null &&
                    _showCustomTabBar)
                  _buildCustomTabBar(),
                Expanded(
                  child: _isSearching || _selectedManagerId != null
                      ? _buildManagerView()
                      : _buildTabBarView(),
                ),
              ],
            ),
    );
  }

  Widget searchWidget(List<Lead> leads) {
    print('_isSearching: $_isSearching, _isManager: $_isManager, leads.isEmpty: ${leads.isEmpty}, leads.length: ${leads.length}');

    // Если идёт поиск и ничего не найдено
    if (_isSearching && leads.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('nothing_found'),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }
    // Если это менеджер и список лидов пуст
    else if (_isManager && leads.isEmpty) {
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
    // Если лидов вообще нет
    else if (leads.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('nothing_lead_for_manager'),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }
    // Если лиды есть, показываем список
    return Flexible(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          print('Отображение лида: $lead');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LeadCard(
              lead: lead,
              title: lead.leadStatus?.title ?? "",
              statusId: lead.statusId,
              onStatusUpdated: () {
                print('Статус лида обновлён');
              },
              onStatusId: (StatusLeadId) {
                print('onStatusId вызван с id: $StatusLeadId');
              },
            ),
          );
        },
      ),
    );
  }

// Обновляем метод _buildManagerView для корректной обработки обоих случаев
  Widget _buildManagerView() {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        if (state is LeadDataLoaded) {
          final List<Lead> leads = state.leads;

          // Filtrujeme podle vybraného statusu
          final statusId = _tabTitles[_tabController.index]['id'];
          final filteredLeads =
              leads.where((lead) => lead.statusId == statusId).toList();

          if (filteredLeads.isEmpty) {
            return Center(
              child: Text(
                _selectedManagerId != null
                    ? AppLocalizations.of(context)!
                        .translate('selected_manager_has_any_lead')
                    : AppLocalizations.of(context)!.translate('nothing_found'),
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
              itemCount: filteredLeads.length,
              itemBuilder: (context, index) {
                final lead = filteredLeads[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  void _showStatusOptions(BuildContext context, int index) {
    final RenderBox renderBox =
        _tabKeys[index].currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + renderBox.size.height,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height * 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      color: Colors.white,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Color(0xff99A4BA)),
            title: Text(
              'Изменить',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Color(0xff99A4BA)),
            title: Text(
              'Удалить',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _editLeadStatus(index);
      } else if (value == 'delete') {
        _showDeleteDialog(index);
      }
    });
  }

// Update the GestureDetector in _buildTabButton to use the new _showStatusOptions

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
              _showStatusOptions(context, index);
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

  void _deleteLeadStatus(int index) {
    // Вызываем вашу существующую логику удаления
    _showDeleteDialog(index);
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

      context.read<LeadBloc>().add(FetchLeadStatuses());
    }
  }

  void _editLeadStatus(int index) {
    // Extract lead status data if needed for editing
    final leadStatus = _tabTitles[
        index]; // Assuming _tabTitles holds the relevant data for the lead

    // Show the Edit Lead Status Screen as a modal dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditLeadStatusScreen(
          leadStatusId: leadStatus['id'], // Pass the lead status ID for editing
        );
      },
    );
  }

  Widget _buildTabBarView() {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) async {
        if (state is LeadLoaded) {
          await LeadCache.cacheLeadStatuses(state.leadStatuses
              .map((status) => {'id': status.id, 'title': status.title})
              .toList());
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
          if (state.message.contains(
              AppLocalizations.of(context)!.translate('unauthorized_access'))) {
            ApiService apiService = ApiService();
            await apiService.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
            );
          } else if (state.message.contains(AppLocalizations.of(context)!
              .translate('no_internet_connection'))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate(state.message), // Локализация сообщения
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
                    final index = _tabTitles
                        .indexWhere((status) => status['id'] == newStatusId);

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
