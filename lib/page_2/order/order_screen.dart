import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_cache.dart';
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
  bool _canUpdateOrderStatus = false;
  bool _canDeleteOrderStatus = false;
  final ApiService _apiService = ApiService();
  late OrderBloc _orderBloc;
  bool _showCustomTabBar = true;
  bool _isFilterLoading = false;
  bool _shouldShowLoader = false;
  bool _skipNextTabListener = false;
  String _lastSearchQuery = "";

  @override
  void initState() {
    super.initState();
    
    // ← КРИТИЧНО: Инициализируем пустой TabController
    _tabController = TabController(length: 0, vsync: this);
    
    _orderBloc = OrderBloc(ApiService())..add(FetchOrderStatuses());
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final canCreate = await _apiService.hasPermission('order.create');
    final canUpdate = await _apiService.hasPermission('orderStatus.update');
    final canDelete = await _apiService.hasPermission('orderStatus.delete');
    setState(() {
      _canCreateOrderStatus = canCreate;
      _canUpdateOrderStatus = canUpdate;
      _canDeleteOrderStatus = canDelete;
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

  Future<void> _onRefresh(int currentStatusId) async {
    try {
      await OrderCache.clearAllData();
      await OrderCache.clearPersistentCounts();

      if (mounted) {
        setState(() {
          _isSearching = false;
          _lastSearchQuery = '';
          _searchController.clear();
          _showCustomTabBar = true;
          _isFilterLoading = false;
          _shouldShowLoader = false;
          _currentFilters.clear();

          _statuses.clear();
          _tabKeys.clear();
          _currentTabIndex = 0;

          if (_tabController.length > 0) {
            _tabController.dispose();
          }
          _tabController = TabController(length: 0, vsync: this);
        });
      }

      final orderBloc = _orderBloc;
      await orderBloc.clearAllCountsAndCache();
      orderBloc.add(FetchOrderStatuses(forceRefresh: true));

    } catch (e) {
      // ✅ УБРАНО: Не показываем SnackBar с кнопкой "Повторить"
      debugPrint('OrderScreen: Ошибка при обновлении данных: $e');
      
      if (mounted) {
        _orderBloc.add(FetchOrderStatuses(forceRefresh: false));
      }
    }
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

  // Метод для проверки наличия активных фильтров
  bool _hasActiveFilters() {
    return _currentFilters.isNotEmpty;
  }

  void _onSearch(String query) {
    _lastSearchQuery = query;
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    if (_statuses.isEmpty || _currentTabIndex >= _statuses.length) return;
    
    if (_isSearching || _currentFilters.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isFilterLoading = true;
          _shouldShowLoader = true;
        });
      }

      _orderBloc.add(FetchOrders(
        statusId: _statuses[_currentTabIndex].id,
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
        if (_canUpdateOrderStatus)
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
        if (_canDeleteOrderStatus)
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
              if (mounted) {
                setState(() {
                  _currentFilters = {};
                  _showCustomTabBar = true;
                  _isSearching = false;
                  _searchController.clear();
                  _lastSearchQuery = '';
                });
              }
              _orderBloc.add(FetchOrderStatuses());
            },
            onGoodsResetFilters: () {
              if (mounted) {
                setState(() {
                  _currentFilters = {};
                  _showCustomTabBar = true;
                  _isSearching = false;
                  _searchController.clear();
                  _lastSearchQuery = '';
                });
              }
              
              final orderBloc = _orderBloc;
              orderBloc.add(FetchOrderStatuses());
            },
            currentFilters: _currentFilters,
            onFilterGoodsSelected: (filters) {
              debugPrint('OrderScreen: onFilterGoodsSelected - START WITH NEW LOGIC');
              
              if (mounted) {
                setState(() {
                  _isFilterLoading = true;
                  _shouldShowLoader = true;
                  _showCustomTabBar = true;
                  _skipNextTabListener = true; // ← КРИТИЧНО: Пропускаем следующий TabListener!
                  _isSearching = false;
                  _searchController.clear();
                  _lastSearchQuery = '';
                  _currentFilters = filters;
                });
              }

              _orderBloc.add(FetchOrderStatusesWithFilters(
                managerIds: filters['managers'],
                leadIds: filters['leads'],
                fromDate: filters['fromDate'],
                toDate: filters['toDate'],
                status: filters['status'],
                paymentMethod: filters['paymentMethod'],
              ));

              debugPrint('OrderScreen: onFilterGoodsSelected - Dispatched FetchOrderStatusesWithFilters');
            },
          ),
        ),
        body: isClickAvatarIcon
            ? const ProfileScreen()
            : BlocListener<OrderBloc, OrderState>(
                listener: (context, state) async {
                  debugPrint('OrderScreen: BlocListener - state: ${state.runtimeType}');
                  
                  // Сбрасываем флаги загрузки когда получены данные
                  if (state is OrderLoaded || state is OrderError) {
                    if (mounted && _isFilterLoading) {
                      debugPrint('OrderScreen: Resetting loader flags');
                      setState(() {
                        _isFilterLoading = false;
                        _shouldShowLoader = false;
                      });
                    }
                  }
                  
                  if (state is OrderLoaded) {
                    await OrderCache.cacheOrderStatuses(state.statuses
                        .map((status) => {
                              'id': status.id,
                              'name': status.name,
                              'orders_count': status.ordersCount,
                            })
                        .toList());

                    if (mounted) {
                      setState(() {
                        // Обновляем статусы с новыми данными
                        _statuses = state.statuses;
                        _tabKeys = List.generate(_statuses.length, (_) => GlobalKey());

                        if (_statuses.isNotEmpty) {
                          // Проверяем, нужно ли создавать новый контроллер
                          bool needNewController = _tabController.length != _statuses.length;

                          if (needNewController) {
                            // Dispose старого контроллера если он существует
                            if (_tabController.length > 0) {
                              _tabController.dispose();
                            }

                            // Создаем новый контроллер
                            _tabController = TabController(length: _statuses.length, vsync: this);
                            
                            // ← КРИТИЧНО: Добавляем listener ТОЛЬКО при создании нового контроллера!
                            _tabController.addListener(() {
                            if (!_tabController.indexIsChanging) {
                              // ← КРИТИЧНО: Проверяем флаг пропуска!
                              if (_skipNextTabListener) {
                                debugPrint('OrderScreen: TabController listener - SKIPPED (filter just applied)');
                                setState(() {
                                  _skipNextTabListener = false;
                                  _currentTabIndex = _tabController.index;
                                });
                                return; // ← ВЫХОДИМ БЕЗ ЗАПРОСА!
                              }

                              if (_currentTabIndex != _tabController.index) {
                                setState(() {
                                  _currentTabIndex = _tabController.index;
                                });
                                _scrollToActiveTab();
                                
                                if (_statuses.isNotEmpty && _showCustomTabBar) {
                                  bool hasActiveFilters = _hasActiveFilters();
                                  
                                  _orderBloc.add(FetchOrders(
                                    statusId: _statuses[_currentTabIndex].id,
                                    page: 1,
                                    perPage: 20,
                                    query: _lastSearchQuery.isNotEmpty ? _lastSearchQuery : null,
                                    managerIds: hasActiveFilters ? _currentFilters['managers'] : null,
                                    leadIds: hasActiveFilters ? _currentFilters['leads'] : null,
                                    fromDate: hasActiveFilters ? _currentFilters['fromDate'] : null,
                                    toDate: hasActiveFilters ? _currentFilters['toDate'] : null,
                                    status: hasActiveFilters ? _currentFilters['status'] : null,
                                    paymentMethod: hasActiveFilters ? _currentFilters['paymentMethod'] : null,
                                  ));
                                }
                              }
                            }
                            }); // ← Закрываем listener здесь, только для нового контроллера!
                          }

                          // Установка правильного индекса
                          if (needNewController) {
                            if (_currentTabIndex < _statuses.length && _currentTabIndex >= 0) {
                              _tabController.index = _currentTabIndex;
                            } else {
                              _tabController.index = 0;
                              _currentTabIndex = 0;
                            }
                          }

                          // Прокручиваем к активному табу
                          _scrollToActiveTab();

                          // Обрабатываем специальные навигации
                          if (_navigateToNewStatus && _statuses.isNotEmpty && _newStatusId != null) {
                            final newTabIndex = _statuses.indexWhere((status) => status.id == _newStatusId);
                            if (newTabIndex != -1) {
                              setState(() {
                                _currentTabIndex = newTabIndex;
                                _navigateToNewStatus = false;
                              });
                              Future.delayed(Duration(milliseconds: 100), () {
                                if (mounted) {
                                  _tabController.animateTo(newTabIndex);
                                  _scrollToActiveTab();
                                }
                              });
                            }
                          }

                          // Автоматически загружаем заказы для активного статуса после refresh
                          Future.delayed(Duration(milliseconds: 150), () {
                            if (mounted && _statuses.isNotEmpty && _currentTabIndex < _statuses.length) {
                              final activeStatusId = _statuses[_currentTabIndex].id;

                              final bool hasActiveFilters = _hasActiveFilters();

                              if (!hasActiveFilters && _isInitialLoad) {
                                _orderBloc.add(FetchOrders(
                                  statusId: activeStatusId,
                                  page: 1,
                                  perPage: 20,
                                ));
                                _isInitialLoad = false;
                              } else {
                                debugPrint('OrderScreen: Skip auto FetchOrders due to active filters or not initial load');
                              }
                            }
                          });

                        } else {
                          // Если статусы пустые, создаем пустой контроллер
                          if (_tabController.length > 0) {
                            _tabController.dispose();
                          }
                          _tabController = TabController(length: 0, vsync: this);
                          _currentTabIndex = 0;
                        }
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
                      onRefresh: () {
                        final currentStatusId = _statuses.isNotEmpty && _currentTabIndex < _statuses.length
                            ? _statuses[_currentTabIndex].id
                            : 0;
                        return _onRefresh(currentStatusId);
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          if (!_isSearching && _showCustomTabBar) _buildCustomTabBar(context),
                          Expanded(
                            child: _isSearching || _hasActiveFilters()
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
                      if (newTabIndex == _currentTabIndex) {
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildTabButton(index),
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

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;

    return FutureBuilder<int>(
      future: OrderCache.getPersistentOrderCount(_statuses[index].id),
      builder: (context, snapshot) {
        // Сначала пробуем получить count из постоянного кэша
        int orderCount = snapshot.data ?? 0;

        // Если в постоянном кэше нет данных, пробуем другие источники
        if (orderCount == 0) {
          return BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              // Используем данные из состояния только если нет постоянного счетчика
              if (state is OrderLoaded) {
                final statusId = _statuses[index].id;
                final orderStatus = state.statuses.firstWhere(
                  (status) => status.id == statusId,
                  orElse: () => OrderStatus(
                    id: 0,
                    name: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    isSuccess: false,
                    isFailed: false,
                    canceled: false,
                    color: '#000000',
                    position: 1,
                    ordersCount: 0,
                  ),
                );
                orderCount = orderStatus.ordersCount;

                // Сразу сохраняем в постоянный кэш
                OrderCache.setPersistentOrderCount(statusId, orderCount);
              }

              return _buildTabButtonUI(index, isActive, orderCount);
            },
          );
        }

        // Если есть постоянный счетчик, используем его напрямую
        return _buildTabButtonUI(index, isActive, orderCount);
      },
    );
  }

  // Вспомогательный метод для построения UI кнопки табы
  Widget _buildTabButtonUI(int index, bool isActive, int orderCount) {
    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
      },
      onLongPress: () {
        _showStatusOptions(context, index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                  orderCount.toString(),
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
    );
  }
  Widget _buildFilteredView() {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        debugPrint('OrderScreen: _buildFilteredView listener - state: ${state.runtimeType}');
        // Сбрасываем флаги когда данные загружены или произошла ошибка
        if ((state is OrderLoaded || state is OrderError) &&
            mounted &&
            (_isFilterLoading || _shouldShowLoader)) {
          debugPrint('OrderScreen: _buildFilteredView - Resetting loader flags');
          setState(() {
            _isFilterLoading = false;
            _shouldShowLoader = false;
          });
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          final currentStatusId = _statuses.isNotEmpty && _currentTabIndex < _statuses.length
              ? _statuses[_currentTabIndex].id
              : 0;

          // Показываем лоадер только если флаги активны ИЛИ состояние - OrderLoading
          if (_shouldShowLoader || _isFilterLoading || state is OrderLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          }

          if (state is OrderLoaded) {
            final List<Order> orders = state.orders;
            
            if (orders.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _onRefresh(currentStatusId),
                color: const Color(0xff1E2E52),
                backgroundColor: Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Text(
                      AppLocalizations.of(context)!.translate('nothing_found'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _onRefresh(currentStatusId),
              color: const Color(0xff1E2E52),
              backgroundColor: Colors.white,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: OrderCard(
                      order: order,
                      onStatusUpdated: () => _onStatusUpdated(order.orderStatus.id),
                      onStatusId: (newStatusId) {
                        final index = _statuses.indexWhere(
                                (status) => status.id == newStatusId);
                        if (index != -1) {
                          _tabController.animateTo(index);
                        }
                      },
                      onTabChange: (int p1) {},
                    ),
                  );
                },
              ),
            );
          }

          // Если состояние OrderError - показываем ошибку
          if (state is OrderError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

