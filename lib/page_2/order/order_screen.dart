import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/delete_status_order.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_column.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_status_add.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_status_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderScreen extends StatefulWidget {
  final int? organizationId;

  const OrderScreen({this.organizationId});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;
  int _currentTabIndex = 0;
  bool isClickAvatarIcon = false;
  List<OrderStatus> _statuses = [];
  bool _isInitialLoad = true;
  bool _navigateToNewStatus = false;
  int? _newStatusId;
  Map<String, dynamic> _currentFilters = {};
  bool _canCreateOrderStatus = false;
  final ApiService _apiService = ApiService();
  late OrderBloc _orderBloc;
  bool _showCustomTabBar = true;

  @override
  void initState() {
    super.initState();
    _orderBloc = OrderBloc(ApiService())..add(FetchOrderStatuses());
    _tabController = TabController(length: 0, vsync: this);
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final canCreate = await _apiService.hasPermission('order.create');
    setState(() {
      _canCreateOrderStatus = canCreate;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _orderBloc.close();
    super.dispose();
  }

  void _scrollToActiveTab() {
    if (_tabKeys.isEmpty || _currentTabIndex >= _tabKeys.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _tabKeys[_currentTabIndex].currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
        final tabWidth = box.size.width;
        double targetOffset = _scrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    if (_isSearching || _currentFilters.isNotEmpty) {
      _orderBloc.add(FetchOrders(
        statusId: _statuses.isNotEmpty ? _statuses[_currentTabIndex].id : null,
        page: 1,
        perPage: 20,
        query: query,
        forceRefresh: true,
        managerIds: _currentFilters['managers'],
        leadIds: _currentFilters['leads'],
        fromDate: _currentFilters['fromDate'],
        toDate: _currentFilters['toDate'],
        status: _currentFilters['status'],
        paymentMethod: _currentFilters['paymentMethod'],
      ));
    }
  }

void _onStatusUpdated(int newStatusId) {
  final newTabIndex = _statuses.indexWhere((status) => status.id == newStatusId);
  if (newTabIndex != -1 && newTabIndex != _currentTabIndex) {
    setState(() {
      _currentTabIndex = newTabIndex;
    });
    _tabController.animateTo(newTabIndex);
    _scrollToActiveTab();
  }
  // Обновляем заказы для текущего и нового статуса
  if (_statuses.isNotEmpty) {
    _orderBloc.add(FetchOrders(
      statusId: _statuses[_currentTabIndex].id,
      page: 1,
      perPage: 20,
      forceRefresh: true,
      query: _isSearching ? _searchController.text : null,
      managerIds: _currentFilters['managers'],
      leadIds: _currentFilters['leads'],
      fromDate: _currentFilters['fromDate'],
      toDate: _currentFilters['toDate'],
      status: _currentFilters['status'],
      paymentMethod: _currentFilters['paymentMethod'],
    ));
    if (newTabIndex != _currentTabIndex) {
      _orderBloc.add(FetchOrders(
        statusId: newStatusId,
        page: 1,
        perPage: 20,
        forceRefresh: true,
        query: _isSearching ? _searchController.text : null,
        managerIds: _currentFilters['managers'],
        leadIds: _currentFilters['leads'],
        fromDate: _currentFilters['fromDate'],
        toDate: _currentFilters['toDate'],
        status: _currentFilters['status'],
        paymentMethod: _currentFilters['paymentMethod'],
      ));
    }
  }
}

  void _resetScreenState() {
    setState(() {
      _statuses = [];
      _tabKeys = [];
      _currentTabIndex = 0;
      _isInitialLoad = true;
      _navigateToNewStatus = false;
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _showCustomTabBar = true;
    });
    _tabController.dispose();
    _tabController = TabController(length: 0, vsync: this);
  }

  void _showStatusOptions(BuildContext context, int index) {
    final RenderBox renderBox = _tabKeys[index].currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + renderBox.size.height,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height * 2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (context) => EditStatusOrder(
            status: _statuses[index],
            orderBloc: _orderBloc,
          ),
        ).then((result) {
          if (result == true) {
            _orderBloc.add(FetchOrderStatuses());
          }
        });
      } else if (value == 'delete') {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (context) => DeleteStatusOrder(
            statusId: _statuses[index].id,
            statusName: _statuses[index].name,
            orderBloc: _orderBloc,
          ),
        ).then((result) {
          if (result == true) {
            _orderBloc.add(FetchOrderStatuses());
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _orderBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            onChangedSearchInput: (value) => _onSearch(value),
            showFilterIcon: false,
            showSearchIcon: true,
            showFilterOrderIcon: true,
            title: isClickAvatarIcon
                ? localizations!.translate('appbar_settings')
                : localizations!.translate('appbar_orders'),
            onClickProfileAvatar: () {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
            },
            textEditingController: _searchController,
            focusNode: _focusNode,
            clearButtonClick: (value) {
              if (!value) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                if (_currentFilters.isEmpty) {
                  setState(() {
                    _showCustomTabBar = true;
                  });
                  _orderBloc.add(FetchOrderStatuses());
                } else {
                  _orderBloc.add(FetchOrders(
                    statusId: _statuses.isNotEmpty ? _statuses[_currentTabIndex].id : null,
                    page: 1,
                    perPage: 20,
                    forceRefresh: true,
                    managerIds: _currentFilters['managers'],
                    leadIds: _currentFilters['leads'],
                    fromDate: _currentFilters['fromDate'],
                    toDate: _currentFilters['toDate'],
                    status: _currentFilters['status'],
                    paymentMethod: _currentFilters['paymentMethod'],
                  ));
                }
              }
            },
            clearButtonClickFiltr: (value) {
              setState(() {
                _currentFilters = {};
                _showCustomTabBar = true;
                _isSearching = false;
                _searchController.clear();
              });
              _orderBloc.add(FetchOrderStatuses());
            },
            onGoodsResetFilters: () {
              setState(() {
                _currentFilters = {};
                _showCustomTabBar = true;
                _isSearching = false;
                _searchController.clear();
              });
              _orderBloc.add(FetchOrderStatuses());
            },
            currentFilters: _currentFilters,
            onFilterGoodsSelected: (filters) {
              setState(() {
                _currentFilters = filters;
                _showCustomTabBar = false;
              });
              _orderBloc.add(FetchOrders(
                statusId: _statuses.isNotEmpty ? _statuses[_currentTabIndex].id : null,
                page: 1,
                perPage: 20,
                forceRefresh: true,
                managerIds: filters['managers'],
                leadIds: filters['leads'],
                fromDate: filters['fromDate'],
                toDate: filters['toDate'],
                status: filters['status'],
                paymentMethod: filters['paymentMethod'],
              ));
            },
          ),
        ),
        body: isClickAvatarIcon
            ? const ProfileScreen()
            : BlocListener<OrderBloc, OrderState>(
                listener: (context, state) {
                  if (state is OrderLoaded) {
                    if (_statuses.length != state.statuses.length ||
                        !_statuses.every((s) => state.statuses.any((st) => st.id == s.id))) {
                      setState(() {
                        _statuses = state.statuses;
                        _tabKeys = List.generate(_statuses.length, (_) => GlobalKey());
                        _tabController.dispose();
                        _tabController = TabController(length: _statuses.length, vsync: this);
                        _tabController.addListener(() {
                          if (_currentTabIndex != _tabController.index) {
                            setState(() {
                              _currentTabIndex = _tabController.index;
                            });
                            _scrollToActiveTab();
                            if (_statuses.isNotEmpty && _showCustomTabBar) {
                              _orderBloc.add(FetchOrders(
                                statusId: _statuses[_currentTabIndex].id,
                                page: 1,
                                perPage: 20,
                              ));
                            }
                          }
                        });

                        if (_navigateToNewStatus && _statuses.isNotEmpty && _newStatusId != null) {
                          final newTabIndex = _statuses.indexWhere((status) => status.id == _newStatusId);
                          if (newTabIndex != -1) {
                            setState(() {
                              _currentTabIndex = newTabIndex;
                              _navigateToNewStatus = false;
                            });
                            _tabController.animateTo(newTabIndex);
                            _scrollToActiveTab();
                            _orderBloc.add(FetchOrders(
                              statusId: _statuses[newTabIndex].id,
                              page: 1,
                              perPage: 20,
                              forceRefresh: true,
                            ));
                          }
                        }
                      });
                      if (_isInitialLoad && _statuses.isNotEmpty) {
                        _orderBloc.add(FetchOrders(
                          statusId: _statuses[0].id,
                          page: 1,
                          perPage: 20,
                        ));
                        _isInitialLoad = false;
                        _scrollToActiveTab();
                      }
                    }
                    // Устанавливаем _isInitialLoad в false после первой загрузки
                    if (_isInitialLoad) {
                      setState(() {
                        _isInitialLoad = false;
                      });
                    }
                  } else if (state is OrderStatusCreated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.green,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    _resetScreenState();
                    setState(() {
                      _navigateToNewStatus = true;
                      _newStatusId = state.newStatusId;
                    });
                    _orderBloc.add(FetchOrderStatuses());
                  } else if (state is OrderStatusDeleted || state is OrderStatusUpdated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state is OrderStatusDeleted ? state.message : (state as OrderStatusUpdated).message,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.green,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    _resetScreenState();
                    _orderBloc.add(FetchOrderStatuses());
                  } else if (state is OrderError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.red,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    // Устанавливаем _isInitialLoad в false при ошибке, чтобы не показывать загрузку бесконечно
                    if (_isInitialLoad) {
                      setState(() {
                        _isInitialLoad = false;
                      });
                    }
                  }
                },
                child: BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    // Показываем индикатор загрузки, если идет начальная загрузка
                    if (_isInitialLoad || state is OrderLoading) {
                      return const Center(
                        child: PlayStoreImageLoading(
                          size: 80.0,
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                    }
                    // Показываем сообщение, если статусы не загружены и список пуст
                    if (_statuses.isEmpty && state is OrderLoaded) {
                      return Center(
                        child: Text(
                          localizations!.translate('no_order_statuses'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      );
                    }
                    // Основной контент, если есть статусы
                    return RefreshIndicator(
                      color: const Color(0xff1E2E52),
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        _orderBloc.add(FetchOrderStatuses());
                        if (_statuses.isNotEmpty && _showCustomTabBar) {
                          _orderBloc.add(FetchOrders(
                            statusId: _statuses[_currentTabIndex].id,
                            page: 1,
                            perPage: 20,
                          ));
                        }
                        return Future.delayed(const Duration(milliseconds: 1));
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          if (_showCustomTabBar) _buildCustomTabBar(context),
                          Expanded(
                            child: _isSearching || _currentFilters.isNotEmpty
                                ? _buildFilteredView()
                                : TabBarView(
                                    controller: _tabController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: _statuses.map((status) {
                                      final List<Order> statusOrders = state is OrderLoaded
                                          ? state.orders
                                              .where((order) => order.orderStatus.id == status.id)
                                              .toList()
                                          : <Order>[];
                                      return OrderColumn(
                                        statusId: status.id,
                                        name: status.name,
                                        searchQuery: _isSearching ? _searchController.text : null,
                                        organizationId: widget.organizationId,
                                        onStatusUpdated: () => _onStatusUpdated(status.id),
                                        onStatusId: (newStatusId) => _onStatusUpdated(newStatusId),
                                        onTabChange: (newTabIndex) {
                                          setState(() {
                                            _currentTabIndex = newTabIndex;
                                          });
                                          _tabController.animateTo(newTabIndex);
                                          _scrollToActiveTab();
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        floatingActionButton: _canCreateOrderStatus
            ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderAddScreen()),
                  );

                  if (result != null && result is Map<String, dynamic> && result['success'] == true) {
                    final newStatusId = result['statusId'];
                    final newTabIndex = _statuses.indexWhere((status) => status.id == newStatusId);
                    if (newTabIndex != -1) {
                      setState(() {
                        _currentTabIndex = newTabIndex;
                      });
                      _tabController.animateTo(newTabIndex);
                      _scrollToActiveTab();
                      _orderBloc.add(FetchOrders(
                        statusId: newStatusId,
                        page: 1,
                        perPage: 20,
                        forceRefresh: true,
                      ));
                      if (newTabIndex != _currentTabIndex) {
                        _orderBloc.add(FetchOrders(
                          statusId: _statuses[_currentTabIndex].id,
                          page: 1,
                          perPage: 20,
                          forceRefresh: true,
                        ));
                      }
                    }
                  }
                },
                backgroundColor: const Color(0xff1E2E52),
                child: const Icon(
                  Icons.add,
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 25,
                ),
              )
            : null,
      ),
    );
  }

 Widget _buildCustomTabBar(BuildContext context) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    controller: _scrollController,
    child: Row(
      children: [
        ...List.generate(_statuses.length, (index) {
          bool isActive = _tabController.index == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              key: _tabKeys[index],
              onTap: () {
                _tabController.animateTo(index);
              },
              onLongPress: () {
                _showStatusOptions(context, index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.black : const Color(0xff99A4BA),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statuses[index].name,
                      style: TaskStyles.tabTextStyle.copyWith(
                        color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.translate(
                      offset: const Offset(12, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? const Color(0xff1E2E52) : const Color(0xff99A4BA),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _statuses[index].ordersCount.toString(),
                          style: TextStyle(
                            color: isActive ? Colors.black : const Color(0xff99A4BA),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_canCreateOrderStatus)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: GestureDetector(
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) => CreateOrderStatusDialog(orderBloc: _orderBloc),
                );
              },
              child: const Text(
                '+',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
  Widget _buildFilteredView() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoaded) {
          final List<Order> orders = state.orders;
          if (orders.isEmpty) {
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
          return ListView.builder(
            controller: _scrollController,
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: OrderCard(
                  order: order,
                  onStatusUpdated: () => _onStatusUpdated(order.orderStatus.id),
                  onStatusId: (newStatusId) => _onStatusUpdated(newStatusId),
                  onTabChange: (int p1) {},
                ),
              );
            },
          );
        }
        if (state is OrderLoading) {
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
}

/*
теперь с сервера приходить order_count
вот так{
	"result": [
		{
			"id": 2,
			"name": "dsfasdf",
			"created_at": "2025-08-06T11:06:27.000000Z",
			"updated_at": "2025-08-20T06:41:27.000000Z",
			"is_success": 0,
			"is_failed": 0,
			"canceled": 0,
			"notification_message": null,
			"color": "#000",
			"position": 1,
			"orders_count": 1
		},
		{
			"id": 1,
			"name": "Тестовый статус",
			"created_at": "2025-07-31T04:54:04.000000Z",
			"updated_at": "2025-08-20T06:41:27.000000Z",
			"is_success": 0,
			"is_failed": 0,
			"canceled": 0,
			"notification_message": "Тестовый описание",
			"color": "#000",
			"position": 2,
			"orders_count": 2
		}
	],
	"errors": null
}

в запросе /order-status?organization_id=1 
ее нужно вывести рядом с названием статуса
вот так  Статус (кол-во)  Например: Новый (3)
в модели OrderStatus добавить поле final int ordersCount;
в конструктор и в fromJson добавить
    required this.ordersCount,
    ordersCount: json['orders_count'] ?? 0, // Убедимся, что orders_count читается
в виджете _buildCustomTabBar
изменить Text(
                    _statuses[index].name,   
                    style: TaskStyles.tabTextStyle.copyWith(
                      color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
                    ),
                  ),
                  Text(
                    '(${_statuses[index].ordersCount})',
                    style: TaskStyles.tabTextStyle.copyWith(
                      color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
                    ),
                  ),

кстати еще момент при смене статуса заказа тогда страница вообще обнолуяется и заного получает статусы и заказы
можно сделать так что бы при смене статуса заказа не обнулялась страница а просто перезагружались заказы в текущем статусе и в новом статусе
все больше нечего не нужно и кстати нужно сделать так чтобы при смене статуса заказа order_count в статусах не изменился а стоял как есть все реализуй 
*/