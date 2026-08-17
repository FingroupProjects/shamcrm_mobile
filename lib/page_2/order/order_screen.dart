import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderScreen extends StatefulWidget {
  final int? organizationId;

  const OrderScreen({this.organizationId});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
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
        final position = box.localToGlobal(
          Offset.zero,
          ancestor: context.findRenderObject(),
        );
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

  bool _hasActiveFilters() {
    if (_currentFilters.isEmpty) return false;
    return (_currentFilters['managers'] != null &&
            (_currentFilters['managers'] as List).isNotEmpty) ||
        (_currentFilters['regions'] != null &&
            (_currentFilters['regions'] as List).isNotEmpty) ||
        (_currentFilters['leads'] != null &&
            (_currentFilters['leads'] as List).isNotEmpty) ||
        _currentFilters['fromDate'] != null ||
        _currentFilters['toDate'] != null ||
        _currentFilters['status'] != null ||
        _currentFilters['paymentMethod'] != null ||
        _currentFilters['deliveryType'] != null ||
        (_currentFilters['reason_for_refusal_ids'] != null &&
            (_currentFilters['reason_for_refusal_ids'] as List).isNotEmpty) ||
        (_currentFilters['custom_field_filters'] != null &&
            (_currentFilters['custom_field_filters'] as Map).isNotEmpty);
  }

  List<int>? _currentReasonForRefusalIds() {
    return (_currentFilters['reason_for_refusal_ids'] as List?)
        ?.map((id) => int.parse(id.toString()))
        .toList();
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
        regionsIds: _currentFilters['regions'],
        leadIds: _currentFilters['leads'],
        fromDate: _currentFilters['fromDate'],
        toDate: _currentFilters['toDate'],
        status: _currentFilters['status'],
        paymentMethod: _currentFilters['paymentMethod'],
        deliveryType: _currentFilters['deliveryType'],
        reasonForRefusalIds: _currentReasonForRefusalIds(),
        customFieldFilters: (_currentFilters['custom_field_filters'] as Map?)
            ?.map((key, value) => MapEntry(
                  key.toString(),
                  List<String>.from(value as List),
                )),
      ));
    }
  }

  void _onStatusUpdated(int oldStatusId, int newStatusId) {
    final previousTabIndex = _currentTabIndex;
    final newTabIndex =
        _statuses.indexWhere((status) => status.id == newStatusId);

    if (newTabIndex != -1 && newTabIndex != previousTabIndex) {
      setState(() {
        _navigateToNewStatus = true;
        _newStatusId = newStatusId;
      });
      _tabController.animateTo(newTabIndex);
      _scrollToActiveTab();
    }

    if (_statuses.isNotEmpty) {
      // Сначала обновляем статусы и очищаем устаревший кэш. После этого
      // загружаем список заказов, чтобы OrderLoaded не был затёрт пустым
      // состоянием статусов.
      _orderBloc.add(FetchOrderStatuses(forceRefresh: true));

      _orderBloc.add(FetchOrders(
        statusId: oldStatusId,
        page: 1,
        perPage: 20,
        forceRefresh: true,
        query: _isSearching ? _searchController.text : null,
        managerIds: _currentFilters['managers'],
        regionsIds: _currentFilters['regions'],
        leadIds: _currentFilters['leads'],
        fromDate: _currentFilters['fromDate'],
        toDate: _currentFilters['toDate'],
        status: _currentFilters['status'],
        paymentMethod: _currentFilters['paymentMethod'],
        deliveryType: _currentFilters['deliveryType'],
        reasonForRefusalIds: _currentReasonForRefusalIds(),
        customFieldFilters: (_currentFilters['custom_field_filters'] as Map?)
            ?.map((key, value) =>
                MapEntry(key.toString(), List<String>.from(value as List))),
      ));
      _orderBloc.add(FetchOrderStatuses(forceRefresh: true));
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
    final colors = context.appColors;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      color: colors.surfacePrimary,
      items: [
        if (_canUpdateOrderStatus)
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: colors.iconSecondary),
              title: Text(
                'Изменить',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        if (_canDeleteOrderStatus)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: colors.iconSecondary),
              title: Text(
                'Удалить',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    ).then((value) {
      if (value == 'edit') {
        showDialog(
          context: context,
          barrierColor: colors.overlay,
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
          barrierColor: colors.overlay,
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
    final colors = context.appColors;
    return BlocProvider.value(
      value: _orderBloc,
      child: Scaffold(
        backgroundColor: colors.backgroundPrimary,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: colors.surfacePrimary,
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
                    statusId: _statuses.isNotEmpty
                        ? _statuses[_currentTabIndex].id
                        : null,
                    page: 1,
                    perPage: 20,
                    forceRefresh: true,
                    managerIds: _currentFilters['managers'],
                    regionsIds: _currentFilters['regions'],
                    leadIds: _currentFilters['leads'],
                    fromDate: _currentFilters['fromDate'],
                    toDate: _currentFilters['toDate'],
                    status: _currentFilters['status'],
                    paymentMethod: _currentFilters['paymentMethod'],
                    deliveryType: _currentFilters['deliveryType'],
                    reasonForRefusalIds: _currentReasonForRefusalIds(),
                    customFieldFilters:
                        (_currentFilters['custom_field_filters'] as Map?)
                            ?.map((key, value) => MapEntry(
                                  key.toString(),
                                  List<String>.from(value as List),
                                )),
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
              if (mounted) {
                setState(() {
                  _isFilterLoading = true;
                  _shouldShowLoader = true;
                  _showCustomTabBar = true;
                  _skipNextTabListener = true;
                  _isSearching = false;
                  _searchController.clear();
                  _lastSearchQuery = '';
                  _currentFilters = filters;
                });
              }
              _orderBloc.add(FetchOrderStatusesWithFilters(
                managerIds: filters['managers'],
                regionsIds: filters['regions'],
                leadIds: filters['leads'],
                fromDate: filters['fromDate'],
                toDate: filters['toDate'],
                status: filters['status'],
                paymentMethod: filters['paymentMethod'],
                deliveryType: filters['deliveryType'],
                reasonForRefusalIds:
                    (filters['reason_for_refusal_ids'] as List?)
                        ?.map((id) => int.parse(id.toString()))
                        .toList(),
                customFieldFilters:
                    (filters['custom_field_filters'] as Map<String, dynamic>?)
                        ?.map((key, value) => MapEntry(
                              key,
                              List<String>.from(value as List),
                            )),
              ));
            },
          ),
        ),
        body: isClickAvatarIcon
            ? const ProfileScreen()
            : Stack(
                fit: StackFit.expand,
                children: [
                  const AppBackgroundOverlay(
                    preset: AppBackgroundPreset.aurora,
                  ),
                  BlocListener<OrderBloc, OrderState>(
                    listener: (context, state) async {
                      if (state is OrderLoaded || state is OrderError) {
                        if (mounted &&
                            (_isFilterLoading || _isInitialLoad)) {
                          setState(() {
                            _isFilterLoading = false;
                            _shouldShowLoader = false;
                            _isInitialLoad = false;
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
                            _statuses = state.statuses;
                            _tabKeys = List.generate(
                                _statuses.length, (_) => GlobalKey());

                            if (_statuses.isNotEmpty) {
                              bool needNewController =
                                  _tabController.length != _statuses.length;

                              if (needNewController) {
                                if (_tabController.length > 0) {
                                  _tabController.dispose();
                                }
                                _tabController = TabController(
                                    length: _statuses.length, vsync: this);
                                _tabController.addListener(() {
                                  if (!_tabController.indexIsChanging) {
                                    if (_skipNextTabListener) {
                                      setState(() {
                                        _skipNextTabListener = false;
                                        _currentTabIndex = _tabController.index;
                                      });
                                      return;
                                    }
                                    if (_currentTabIndex !=
                                        _tabController.index) {
                                      setState(() {
                                        _currentTabIndex = _tabController.index;
                                      });
                                      _scrollToActiveTab();
                                      if (_statuses.isNotEmpty &&
                                          _showCustomTabBar) {
                                        bool hasActiveFilters =
                                            _hasActiveFilters();
                                        _orderBloc.add(FetchOrders(
                                          statusId:
                                              _statuses[_currentTabIndex].id,
                                          page: 1,
                                          perPage: 20,
                                          query: _lastSearchQuery.isNotEmpty
                                              ? _lastSearchQuery
                                              : null,
                                          managerIds: hasActiveFilters
                                              ? _currentFilters['managers']
                                              : null,
                                          regionsIds: hasActiveFilters
                                              ? _currentFilters['regions']
                                              : null,
                                          leadIds: hasActiveFilters
                                              ? _currentFilters['leads']
                                              : null,
                                          fromDate: hasActiveFilters
                                              ? _currentFilters['fromDate']
                                              : null,
                                          toDate: hasActiveFilters
                                              ? _currentFilters['toDate']
                                              : null,
                                          status: hasActiveFilters
                                              ? _currentFilters['status']
                                              : null,
                                          paymentMethod: hasActiveFilters
                                              ? _currentFilters['paymentMethod']
                                              : null,
                                          deliveryType: hasActiveFilters
                                              ? _currentFilters['deliveryType']
                                              : null,
                                          reasonForRefusalIds: hasActiveFilters
                                              ? _currentReasonForRefusalIds()
                                              : null,
                                          customFieldFilters: hasActiveFilters
                                              ? (_currentFilters[
                                                          'custom_field_filters']
                                                      as Map?)
                                                  ?.map(
                                                      (key, value) => MapEntry(
                                                      key.toString(),
                                                      List<String>.from(
                                                          value as List),
                                                    ))
                                              : null,
                                        ));
                                      }
                                    }
                                  }
                                });
                              }

                              if (needNewController) {
                                if (_currentTabIndex < _statuses.length &&
                                    _currentTabIndex >= 0) {
                                  _tabController.index = _currentTabIndex;
                                } else {
                                  _tabController.index = 0;
                                  _currentTabIndex = 0;
                                }
                              }
                              _scrollToActiveTab();

                              if (_navigateToNewStatus &&
                                  _statuses.isNotEmpty &&
                                  _newStatusId != null) {
                                final newTabIndex = _statuses.indexWhere(
                                    (status) => status.id == _newStatusId);
                                if (newTabIndex != -1) {
                                  setState(() {
                                    _currentTabIndex = newTabIndex;
                                    _navigateToNewStatus = false;
                                  });
                                  Future.delayed(
                                      Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      _tabController.animateTo(newTabIndex);
                                      _scrollToActiveTab();
                                    }
                                  });
                                }
                              }

                              Future.delayed(Duration(milliseconds: 150), () {
                                if (mounted &&
                                    _statuses.isNotEmpty &&
                                    _currentTabIndex < _statuses.length) {
                                  final activeStatusId =
                                      _statuses[_currentTabIndex].id;
                                  final bool hasActiveFilters =
                                      _hasActiveFilters();
                                  if (!hasActiveFilters && _isInitialLoad) {
                                    _orderBloc.add(FetchOrders(
                                      statusId: activeStatusId,
                                      page: 1,
                                      perPage: 20,
                                    ));
                                    _isInitialLoad = false;
                                  }
                                }
                              });
                            } else {
                              if (_tabController.length > 0) {
                                _tabController.dispose();
                              }
                              _tabController =
                                  TabController(length: 0, vsync: this);
                              _currentTabIndex = 0;
                            }
                          });
                        }
                      } else if (state is OrderStatusCreated) {
                        final snackColors = context.appColors;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.message,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: snackColors.textInverse,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: snackColors.success,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        _resetScreenState();
                        setState(() {
                          _navigateToNewStatus = true;
                          _newStatusId = state.newStatusId;
                        });
                        _orderBloc.add(FetchOrderStatuses());
                      } else if (state is OrderStatusDeleted ||
                          state is OrderStatusUpdated) {
                        final snackColors = context.appColors;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state is OrderStatusDeleted
                                  ? state.message
                                  : (state as OrderStatusUpdated).message,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: snackColors.textInverse,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: snackColors.success,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        _resetScreenState();
                        _orderBloc.add(FetchOrderStatuses());
                      } else if (state is OrderError) {
                        final snackColors = context.appColors;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.message,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: snackColors.textInverse,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: snackColors.error,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        if (_isInitialLoad) {
                          setState(() {
                            _isInitialLoad = false;
                          });
                        }
                      }
                    },
                    child: BlocBuilder<OrderBloc, OrderState>(
                      builder: (context, state) {
                        // Полный лоадер только при первой загрузке статусов.
                        // При смене таба OrderLoading не должен прятать чипы статусов
                        // (как в лидах/задачах).
                        if (_statuses.isEmpty &&
                            (_isInitialLoad || state is OrderLoading)) {
                          return const Center(
                            child: PlayStoreImageLoading(
                              size: 80.0,
                              duration: Duration(milliseconds: 1000),
                            ),
                          );
                        }
                        if (_statuses.isEmpty && state is OrderLoaded) {
                          return Center(
                            child: Text(
                              localizations!.translate('no_order_statuses'),
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return RefreshIndicator(
                          color: colors.iconPrimary,
                          backgroundColor: colors.surfacePrimary,
                          onRefresh: () {
                            final currentStatusId = _statuses.isNotEmpty &&
                                    _currentTabIndex < _statuses.length
                                ? _statuses[_currentTabIndex].id
                                : 0;
                            return _onRefresh(currentStatusId);
                          },
                          child: Column(
                            children: [
                              const SizedBox(height: 15),
                              if (!_isSearching && _showCustomTabBar)
                                _buildCustomTabBar(context),
                              Expanded(
                                child: _isSearching || _hasActiveFilters()
                                    ? _buildFilteredView()
                                    : TabBarView(
                                        controller: _tabController,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: _statuses.map((status) {
                                          return OrderColumn(
                                            statusId: status.id,
                                            name: status.name,
                                            searchQuery: _isSearching
                                                ? _searchController.text
                                                : null,
                                            organizationId:
                                                widget.organizationId,
                                            onStatusUpdated: _onStatusUpdated,
                                            onStatusId: (newStatusId) {
                                              final oldStatusId = status.id;
                                              _onStatusUpdated(
                                                oldStatusId,
                                                newStatusId,
                                              );
                                            },
                                            onTabChange: (newTabIndex) {
                                              setState(() {
                                                _currentTabIndex = newTabIndex;
                                              });
                                              _tabController
                                                  .animateTo(newTabIndex);
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
                ],
              ),
        floatingActionButton: _canCreateOrderStatus && !isClickAvatarIcon
            ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderAddScreen()),
                  );

                  if (result != null &&
                      result is Map<String, dynamic> &&
                      result['success'] == true) {
                    final newStatusId = result['statusId'];
                    final newTabIndex = _statuses
                        .indexWhere((status) => status.id == newStatusId);
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
                        query: _isSearching ? _searchController.text : null,
                        managerIds: _currentFilters['managers'],
                        regionsIds: _currentFilters['regions'],
                        leadIds: _currentFilters['leads'],
                        fromDate: _currentFilters['fromDate'],
                        toDate: _currentFilters['toDate'],
                        status: _currentFilters['status'],
                        paymentMethod: _currentFilters['paymentMethod'],
                        deliveryType: _currentFilters['deliveryType'],
                        reasonForRefusalIds: _currentReasonForRefusalIds(),
                        customFieldFilters:
                            (_currentFilters['custom_field_filters'] as Map?)
                                ?.map((key, value) => MapEntry(
                                      key.toString(),
                                      List<String>.from(value as List),
                                    )),
                      ));
                      if (newTabIndex == _currentTabIndex) {
                        _orderBloc.add(FetchOrders(
                          statusId: _statuses[_currentTabIndex].id,
                          page: 1,
                          perPage: 20,
                          forceRefresh: true,
                          query: _isSearching ? _searchController.text : null,
                          managerIds: _currentFilters['managers'],
                          regionsIds: _currentFilters['regions'],
                          leadIds: _currentFilters['leads'],
                          fromDate: _currentFilters['fromDate'],
                          toDate: _currentFilters['toDate'],
                          status: _currentFilters['status'],
                          paymentMethod: _currentFilters['paymentMethod'],
                          deliveryType: _currentFilters['deliveryType'],
                          reasonForRefusalIds: _currentReasonForRefusalIds(),
                          customFieldFilters:
                              (_currentFilters['custom_field_filters'] as Map?)
                                  ?.map((key, value) => MapEntry(
                                        key.toString(),
                                        List<String>.from(value as List),
                                      )),
                        ));
                      }
                    }
                  }
                },
                backgroundColor: colors.buttonPrimaryBg,
                child: Icon(
                  Icons.add,
                  color: colors.textInverse,
                  size: 25,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: Row(
          children: [
            ...List.generate(_statuses.length, (index) {
              if (_tabKeys.length <= index) {
                _tabKeys.add(GlobalKey());
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildTabButton(index),
              );
            }),
            if (_canCreateOrderStatus)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) =>
                            CreateOrderStatusDialog(orderBloc: _orderBloc),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surfacePrimary,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.borderSubtle.withValues(alpha: 0.52),
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 20,
                        color: colors.iconPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    final statusId = _statuses[index].id;

    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        int orderCount = _statuses[index].ordersCount;

        if (state is OrderLoaded) {
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
        }
        OrderCache.setPersistentOrderCount(statusId, orderCount);
        return _buildTabButtonUI(index, isActive, orderCount);
      },
    );
  }

  Widget _buildTabButtonUI(int index, bool isActive, int orderCount) {
    final colors = context.appColors;
    final title = _statuses[index].name;

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        if (_tabController.index != index) {
          setState(() {
            _isFilterLoading = true;
            _shouldShowLoader = true;
          });
        }
        _tabController.animateTo(index);
      },
      onLongPress: () {
        _showStatusOptions(context, index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isActive
              ? colors.buttonPrimaryBg
              : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? colors.buttonPrimaryBg
                : colors.borderSubtle.withValues(alpha: 0.58),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                title.isEmpty ? 'Статус' : title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive
                      ? colors.buttonPrimaryFg
                      : colors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.buttonPrimaryFg.withValues(alpha: 0.18)
                    : colors.buttonPrimaryBg.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? colors.buttonPrimaryBg.withValues(alpha: 0.85)
                      : colors.textInverse.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: Text(
                orderCount.toString(),
                style: TextStyle(
                  color: isActive
                      ? colors.buttonPrimaryFg
                      : colors.textPrimary,
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredView() {
    final colors = context.appColors;
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if ((state is OrderLoaded || state is OrderError) &&
            mounted &&
            (_isFilterLoading || _shouldShowLoader)) {
          setState(() {
            _isFilterLoading = false;
            _shouldShowLoader = false;
          });
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          final currentStatusId =
              _statuses.isNotEmpty && _currentTabIndex < _statuses.length
                  ? _statuses[_currentTabIndex].id
                  : 0;

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
              final l10n = AppLocalizations.of(context)!;
              return HelpfulEmptyState.refreshable(
                context: context,
                onRefresh: () => _onRefresh(currentStatusId),
                child: _isSearching
                    ? HelpfulEmptyState.search(l10n)
                    : HelpfulEmptyState.section(
                        l10n: l10n,
                        icon: Icons.shopping_bag_outlined,
                        titleKey: 'empty_orders_title',
                        subtitleKey: 'empty_orders_subtitle',
                        actionKey: _canCreateOrderStatus
                            ? 'empty_orders_action'
                            : null,
                        onAction: _canCreateOrderStatus
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderAddScreen(),
                                  ),
                                );
                              }
                            : null,
                      ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _onRefresh(currentStatusId),
              color: colors.iconPrimary,
              backgroundColor: colors.surfacePrimary,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: OrderCard(
                      order: order,
                      onStatusUpdated: _onStatusUpdated,
                      onStatusId: (newStatusId) {
                        final tabIndex = _statuses
                            .indexWhere((status) => status.id == newStatusId);
                        if (tabIndex != -1) {
                          _tabController.animateTo(tabIndex);
                        }
                      },
                      onTabChange: (int p1) {},
                    ),
                  );
                },
              ),
            );
          }

          if (state is OrderError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.error,
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
