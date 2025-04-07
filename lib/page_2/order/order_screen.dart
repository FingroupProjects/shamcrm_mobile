// screens/order/order_screen.dart
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_column.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderScreen extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToActiveTab() {
    if (_tabKeys.isEmpty || _currentTabIndex >= _tabKeys.length) return;
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;
      double targetOffset = _scrollController.offset +
          position.dx -
          (MediaQuery.of(context).size.width / 2) +
          (tabWidth / 2);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) => OrderBloc(ApiService())..add(FetchOrderStatuses()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            onChangedSearchInput: (value) => _onSearch(value),
            showFilterIcon: false,
            showSearchIcon: true,
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
              }
            },
            clearButtonClickFiltr: (value) {},
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : BlocListener<OrderBloc, OrderState>(
                listener: (context, state) {
                  if (state is OrderLoaded) {
                    if (_statuses.length != state.statuses.length ||
                        !_statuses.every(
                            (s) => state.statuses.any((st) => st.id == s.id))) {
                      setState(() {
                        _statuses = state.statuses;
                        _tabKeys =
                            List.generate(_statuses.length, (_) => GlobalKey());
                        _tabController.dispose();
                        _tabController = TabController(
                            length: _statuses.length, vsync: this);
                        _tabController.addListener(() {
                          if (_currentTabIndex != _tabController.index) {
                            setState(() {
                              _currentTabIndex = _tabController.index;
                            });
                            _scrollToActiveTab();
                            context.read<OrderBloc>().add(FetchOrders(
                                statusId: _statuses[_currentTabIndex].id));
                          }
                        });
                      });
                      if (_isInitialLoad && _statuses.isNotEmpty) {
                        context
                            .read<OrderBloc>()
                            .add(FetchOrders(statusId: _statuses[0].id));
                        _isInitialLoad = false;
                      }
                    }
                  }
                },
                child: BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    // Если статусы еще не загружены, показываем полную анимацию загрузки
                    if (_statuses.isEmpty) {
                      return const Center(
                        child: PlayStoreImageLoading(
                          size: 80.0,
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                    }

                    // Если статусы загружены, показываем интерфейс
                    return Column(
                      children: [
                        SizedBox(height: 15),
                        _buildCustomTabBar(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            physics: NeverScrollableScrollPhysics(),
                            children: _statuses.map((status) {
                              // Фильтруем заказы для текущего статуса с явным указанием типа
                              final List<Order> statusOrders =
                                  state is OrderLoaded
                                      ? state.orders
                                          .where((order) =>
                                              order.orderStatus.id == status.id)
                                          .toList() as List<Order>
                                      : <Order>[];

                              return OrderColumn(
                                statusId: status.id,
                                name: status.name,
                                searchQuery: _isSearching
                                    ? _searchController.text
                                    : null,
                                orders: statusOrders,
                                // Показываем анимацию загрузки только если идет загрузка и нет заказов для этого статуса
                                isLoading: state is OrderLoading &&
                                    statusOrders.isEmpty,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
                floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderAddScreen()),
          );
        },
        backgroundColor: const Color(0xff1E2E52),
        child: Icon(Icons.add, color: Colors.white),
      ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: List.generate(_statuses.length, (index) {
          bool isActive = _tabController.index == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              key: _tabKeys[index],
              onTap: () {
                _tabController.animateTo(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.black : const Color(0xff99A4BA),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  _statuses[index].name,
                  style: TaskStyles.tabTextStyle.copyWith(
                    color: isActive
                        ? TaskStyles.activeColor
                        : TaskStyles.inactiveColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
