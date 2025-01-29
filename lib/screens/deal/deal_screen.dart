import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/deal/deal_status_delete.dart';
import 'package:crm_task_manager/screens/deal/deal_status_edit.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_card.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_column.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_add.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

class DealScreen extends StatefulWidget {
  final int? initialStatusId;

  DealScreen({this.initialStatusId});

  @override
  _DealScreenState createState() => _DealScreenState();
}

class _DealScreenState extends State<DealScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _tabTitles = [];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  bool _isManager = false;

  final TextEditingController _searchController = TextEditingController();
  bool _canReadDealStatus = false;
  bool _canCreateDealStatus = false;
  bool _canDeleteDealStatus = false;
  final ApiService _apiService = ApiService();
  bool navigateToEnd = false;
  bool navigateAfterDelete = false;
  int? _deletedIndex;
  List<int>? _selectedManagerIds; // Add this field
  int? _selectedManagerId; // ID выбранного менеджера.
  late final DealBloc _dealBloc;

  bool _showCustomTabBar = true;
  String _lastSearchQuery = "";


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    DealCache.getDealStatuses().then((cachedStatuses) {
      if (cachedStatuses.isNotEmpty) {
        setState(() {
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
        final leadBloc = BlocProvider.of<DealBloc>(context);
        leadBloc.add(FetchDealStatuses());
      }
    });

    // Проверка лидов в кэше для начального статуса
    DealCache.getDealsForStatus(widget.initialStatusId).then((cachedLeads) {
      if (cachedLeads.isNotEmpty) {
        print('Leads loaded from cache.');
      }
    });

    _checkPermissions();
  }

  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canRead = await _apiService.hasPermission('dealStatus.read');
    final canCreate = await _apiService.hasPermission('dealStatus.create');
    final canDelete = await _apiService.hasPermission('dealStatus.delete');
    // final canDelete = await _apiService.hasPermission('dealStatus.delete');
    setState(() {
      _canReadDealStatus = canRead;
      _canCreateDealStatus = canCreate;
      _canDeleteDealStatus = canDelete;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchDeals(String query, int currentStatusId) async {
  final dealBloc = BlocProvider.of<DealBloc>(context);

  if (query.isEmpty) {
    // Если фильтр активен, выполняем запрос только с фильтром
    if (_selectedManagerIds != null && _selectedManagerIds!.isNotEmpty) {
      print('Очистка поиска, но фильтр активен — загружаем сделки по фильтру');
      dealBloc.add(FetchDeals(
        currentStatusId,
        managerIds: _selectedManagerIds,
      ));
    } else {
      print('Очистка поиска и фильтра — загружаем все сделки');
      dealBloc.add(FetchDeals(currentStatusId,query: " "));
    }
  } else {
    await DealCache.clearAllDeals();

    dealBloc.add(FetchDeals(
      currentStatusId,
      query: query,
      managerIds: _selectedManagerIds, // Передаем список ID менеджеров
    ));
  }
}


  Future<void> _handleManagerSelected(List<dynamic> managers) async {
    await DealCache.clearAllDeals();

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

    final currentStatusId = _tabTitles[_currentTabIndex]['id'];
    final dealBloc = BlocProvider.of<DealBloc>(context);

    dealBloc.add(FetchDeals(
    currentStatusId,
    managerIds: _selectedManagerIds?.isNotEmpty == true ? _selectedManagerIds : null,
    query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null, // Учитываем последний поиск

    ));
  }

void _onSearch(String query) {
  _lastSearchQuery = query; // Сохраняем последний поисковый запрос
  final currentStatusId = _tabTitles[_currentTabIndex]['id'];
  _searchDeals(query, currentStatusId);
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
              : localizations!.translate('appbar_deals'),
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
      final leadBloc = BlocProvider.of<DealBloc>(context);
      leadBloc.add(FetchDealStatuses());
    } else if (_selectedManagerIds != null || _selectedManagerIds!.isNotEmpty) {
      // Если фильтр активен, показываем результаты фильтрации
      final currentStatusId = _tabTitles[_currentTabIndex]['id'];
      final dealBloc = BlocProvider.of<DealBloc>(context);
      dealBloc.add(FetchDeals(
        currentStatusId,
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
        final dealBloc = BlocProvider.of<DealBloc>(context);
        print('Возвращаем поиск после сброса фильтра');
        dealBloc.add(FetchDeals(currentStatusId, query: _lastSearchQuery));
      } else  {
        // Если и поиск, и фильтр пусты, показываем все сделки
        final leadBloc = BlocProvider.of<DealBloc>(context);
        print('Сброс и поиск пуст, возвращаем все сделки');
        leadBloc.add(FetchDealStatuses());
      }
    } else if (_searchController.text.isNotEmpty) {
      // Если поиск активен, показываем результаты поиска
      final currentStatusId = _tabTitles[_currentTabIndex]['id'];
      final dealBloc = BlocProvider.of<DealBloc>(context);
      dealBloc.add(FetchDeals(
        currentStatusId,
        query: _searchController.text,
      ));
    }
  }
}


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

  Widget searchWidget(List<Deal> deals) {
    // Показать анимацию загрузки, если идет поиск
    if (_isSearching) {
      return const Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }

    // Показать анимацию загрузки, если это менеджер и данные ещё загружаются
    if (_isManager && deals.isEmpty) {
      return const Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }

    // Если идёт поиск и ничего не найдено
    if (_isSearching && deals.isEmpty) {
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

    // Если это менеджер и список сделок пуст после загрузки
    else if (_isManager && deals.isEmpty) {
      return Center(
        child: Text(
          'У выбранного менеджера нет сделок',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }

    // Если сделки существуют, отображаем их список
    if (deals.isNotEmpty) {
      return Flexible(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final deal = deals[index];
            print('Отображение сделки: $deal');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DealCard(
                deal: deal,
                title: deal.dealStatus?.title ?? "",
                statusId: deal.statusId,
                onStatusUpdated: () {
                  print('Статус сделки обновлён');
                },
                onStatusId: (StatusDealId) {
                  print('onStatusId вызван с id: $StatusDealId');
                },
              ),
            );
          },
        ),
      );
    }

    // Если список сделок пуст, но это не поиск и не менеджер
    return Center(
      child: Text(
        AppLocalizations.of(context)!.translate('nothing_deal_for_manager'),
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xff99A4BA),
        ),
      ),
    );
  }

  Widget _buildManagerView() {
    return BlocBuilder<DealBloc, DealState>(
      builder: (context, state) {
        if (state is DealDataLoaded) {
          final List<Deal> deals = state.deals;
          if (deals.isEmpty) {
            return Center(
              child: Text(
                _selectedManagerIds?.isNotEmpty == true
                    ? AppLocalizations.of(context)!
                        .translate('no_manager_in_deal')
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
          return ListView.builder(
            controller: _scrollController,
            itemCount: deals.length,
            itemBuilder: (context, index) {
              final deal = deals[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DealCard(
                  deal: deal,
                  title: deal.dealStatus?.title ?? "",
                  statusId: deal.statusId,
                  onStatusUpdated: () {},
                  onStatusId: (StatusDealId) {},
                ),
              );
            },
          );
        }
        if (state is DealLoading) {
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

  Widget managerWidget(List<Deal> deals) {
    if (_selectedManagerId != null && deals.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_manager_in_deals'),
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
        itemCount: deals.length,
        itemBuilder: (context, index) {
          final deal = deals[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DealCard(
              deal: deal,
              title: deal.dealStatus?.title ?? "",
              statusId: deal.statusId,
              onStatusUpdated: () {},
              onStatusId: (StatusDealId) {},
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
          if (_canCreateDealStatus)
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
      // await DealCache.clearCache();
      // print('Все данные удалены успешно. Статусы обновлены.');
      context.read<DealBloc>().add(FetchDealStatuses());

      setState(() {
        navigateToEnd = true;
      });
    }
  }

  // Widget _buildTabButton(int index) {
  //   bool isActive = _tabController.index == index;

  //   return BlocBuilder<DealBloc, DealState>(
  //     builder: (context, state) {
  //       int dealCount = 0;

  //       if (state is DealLoaded) {
  //         final statusId = _tabTitles[index]['id'];
  //         final dealStatus = state.dealStatuses.firstWhere(
  //           (status) => status.id == statusId,
  //           // orElse: () => null,
  //         );
  //         dealCount = dealStatus?.dealsCount ?? 0; // Берём количество сделок
  //       }

  //       return GestureDetector(
  //         key: _tabKeys[index],
  //         onTap: () {
  //           _tabController.animateTo(index);
  //         },
  //         onLongPress: () {
  //           if (_canDeleteDealStatus) {
  //             _showDeleteDialog(index);
  //           }
  //         },
  //         child: Container(
  //           decoration: TaskStyles.tabButtonDecoration(isActive),
  //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 _tabTitles[index]['title'],
  //                 style: TaskStyles.tabTextStyle.copyWith(
  //                   color: isActive
  //                       ? TaskStyles.activeColor
  //                       : TaskStyles.inactiveColor,
  //                 ),
  //               ),
  //               Transform.translate(
  //                 offset: const Offset(12, 0),
  //                 child: Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(12),
  //                     border: Border.all(
  //                       color: isActive
  //                           ? const Color(0xff1E2E52)
  //                           : const Color(0xff99A4BA),
  //                       width: 1,
  //                     ),
  //                   ),
  //                   child: Text(
  //                     dealCount.toString(),
  //                     style: TextStyle(
  //                       color:
  //                           isActive ? Colors.black : const Color(0xff99A4BA),
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //               )
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
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
        _showEditDealStatusDialog(index);
      } else if (value == 'delete') {
        _showDeleteDialog(index);
      }
    });
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return BlocBuilder<DealBloc, DealState>(
      builder: (context, state) {
        int dealCount = 0;

        if (state is DealLoaded) {
          final statusId = _tabTitles[index]['id'];
          final dealStatus = state.dealStatuses.firstWhere(
            (status) => status.id == statusId,
          );
          dealCount = dealStatus.dealsCount;
        }

        return GestureDetector(
          key: _tabKeys[index],
          onTap: () {
            _tabController.animateTo(index);
          },
          onLongPress: () {
            _showStatusOptions(context, index);
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
                      dealCount.toString(),
                      style: TextStyle(
                        color:
                            isActive ? Colors.black : const Color(0xff99A4BA),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

// 2. Новый метод для показа диалога редактирования
  void _showEditDealStatusDialog(int index) {
    final dealStatus = _tabTitles[index];

    showDialog(
      context: context,
      builder: (context) => EditDealStatusScreen(
        dealStatusId: dealStatus['id'],
      ),
    ).then((_) =>
        // final leadBloc = BlocProvider.of<DealBloc>(context);
        // leadBloc.add(FetchDealStatuses());

        _dealBloc.add(FetchDeals(dealStatus['id'])));
  }

  void _showDeleteDialog(int index) async {
    final dealStatusId = _tabTitles[index]['id'];

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteDealStatusDialog(dealStatusId: dealStatusId);
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

        context.read<DealBloc>().add(FetchDeals(_currentTabIndex));
      });

      final dealBloc = BlocProvider.of<DealBloc>(context);
      dealBloc.add(FetchDealStatuses());
    }
  }

  Widget _buildTabBarView() {
    return BlocListener<DealBloc, DealState>(
      listener: (context, state) async {
        if (state is DealLoaded) {
          await DealCache.cacheDealStatuses(state.dealStatuses
              .map((status) => {'id': status.id, 'title': status.title})
              .toList());

          setState(() {
            _tabTitles = state.dealStatuses
                .where((status) => _canReadDealStatus)
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
              int initialIndex = state.dealStatuses
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
            }
          });
        } else if (state is DealError) {
          if (state.message.contains(
              AppLocalizations.of(context)!.translate('unauthorized_access'))) {
            ApiService apiService = ApiService();
            await apiService.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
            );
          } else if (state.message.contains(
              AppLocalizations.of(context)!.translate('unauthorized_access'))) {
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
      child: BlocBuilder<DealBloc, DealState>(
        builder: (context, state) {
          print('state: ${state.runtimeType}');
          if (state is DealDataLoaded) {
            final List<Deal> deals = state.deals;
            print(deals);
            return searchWidget(deals);
          }
          if (state is DealLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is DealLoaded) {
            if (_tabTitles.isEmpty) {
              return const Center(child: Text(''));
            }
            return TabBarView(
              controller: _tabController,
              // key: UniqueKey(),
              children: List.generate(_tabTitles.length, (index) {
                final statusId = _tabTitles[index]['id'];
                final title = _tabTitles[index]['title'];
                return DealColumn(
                  statusId: statusId,
                  title: title,
                  managerId: _selectedManagerId, // Передаем ID менеджера

                  onStatusId: (newStatusId) {
                    print('Status ID changed: $newStatusId');
                    final index = _tabTitles
                        .indexWhere((status) => status['id'] == newStatusId);

                    BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());

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
