
import 'package:crm_task_manager/api/service/api_service.dart';
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
@override
void initState() {
  super.initState();
  _scrollController = ScrollController();

  // Попытка получить данные из кеша
  LeadCache.getLeadStatuses().then((cachedStatuses) {
    if (cachedStatuses.isNotEmpty) {
      setState(() {
        _tabTitles = cachedStatuses;
        // Инициализация TabController только один раз
        _tabController = TabController(length: _tabTitles.length, vsync: this);
        int initialIndex = cachedStatuses
            .indexWhere((status) => status['id'] == widget.initialStatusId);
        if (initialIndex != -1) {
          _currentTabIndex = initialIndex;
        }
        _tabController.index = _currentTabIndex;
      });

      // Добавляем слушатель для _tabController после его инициализации
      _tabController.addListener(() {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        final currentStatusId = _tabTitles[_currentTabIndex]['id'];
        if (_scrollController.hasClients) {
          _scrollToActiveTab();
        }
      });

      if (_scrollController.hasClients) {
        _scrollToActiveTab();
      }
    } else {
      // Если нет данных в кеше, запрашиваем их через API
      final leadBloc = BlocProvider.of<LeadBloc>(context);
      leadBloc.add(FetchLeadStatuses());
      print("Инициализация: отправлен запрос на получение статусов лидов");
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
      leadBloc.add(FetchLeads(currentStatusId));
    } else {
      leadBloc.add(FetchLeads(currentStatusId, query: query));
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
              final leadBloc = BlocProvider.of<LeadBloc>(context);
              leadBloc.add(FetchLeadStatuses());
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
          textEditingController: textEditingController,
          focusNode: focusNode,
          clearButtonClick: (value) {
            if (value == false) {
              final leadBloc = BlocProvider.of<LeadBloc>(context);
              leadBloc.add(FetchLeadStatuses());
              setState(() {
                _isSearching = false;
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
                if (!_isSearching) _buildCustomTabBar(),
                Expanded(child: _buildTabBarView()),
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
            title: lead.leadStatus?.title ?? '', 
            statusId: lead.statusId, 
            onStatusUpdated: () {},
            onStatusId: (newStatusId) {},
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
      setState(() {
        navigateToEnd = true;
      });
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
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
            Center(
              child: Text(
                _tabTitles[index]['title'],
                style: TaskStyles.tabTextStyle.copyWith(
                  color: isActive
                      ? TaskStyles.activeColor
                      : TaskStyles.inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
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
        setState(() {
          _deletedIndex = _currentTabIndex;
          navigateAfterDelete = true;
        });
        _tabTitles.removeAt(index);
        _tabKeys.removeAt(index);
        _tabController = TabController(length: _tabTitles.length, vsync: this);
        
        _currentTabIndex = 0;

        _isSearching = false;
        _searchController.clear();

        context.read<LeadBloc>().add(FetchLeads(_currentTabIndex));
      });
    }
  }

  Widget _buildTabBarView() {
  return BlocListener<LeadBloc, LeadState>(
    listener: (context, state) async {
      if (state is LeadLoaded) {
        setState(() {
          _tabTitles = state.leadStatuses
              .where((status) => _canReadLeadStatus)
              .map((status) => {'id': status.id, 'title': status.title})
              .toList();

          _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

          if (_tabTitles.isNotEmpty) {
            _tabController = TabController(length: _tabTitles.length, vsync: this);
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

            // Сохраняем данные в кеш
            LeadCache.cacheLeadStatuses(_tabTitles);
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
              child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        } else if (state is LeadLoaded) {
          if (_tabTitles.isEmpty) {
            return const Center(child: Text('Нет статусов для отображения'));
          }
          return TabBarView(
            controller: _tabController,
            children: List.generate(_tabTitles.length, (index) {
              final statusId = _tabTitles[index]['id'];
              final title = _tabTitles[index]['title'];
              return LeadColumn(
                statusId: statusId,
                title: title,
                onStatusId: (newStatusId) {
                  print('Status ID changed: $newStatusId');
                  final index = _tabTitles.indexWhere((status) => status['id'] == newStatusId);
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
            duration: Duration(milliseconds: 10),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }
}


