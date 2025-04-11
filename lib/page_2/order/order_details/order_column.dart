import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderColumn extends StatefulWidget {
  final int statusId;
  final String name;
  final String? searchQuery;
  final int? organizationId;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;
  final Function(int) onTabChange;

  const OrderColumn({
    required this.statusId,
    required this.name,
    this.searchQuery,
    this.organizationId,
    required this.onStatusUpdated,
    required this.onStatusId,
    required this.onTabChange,
  });

  @override
  _OrderColumnState createState() => _OrderColumnState();
}

class _OrderColumnState extends State<OrderColumn> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _perPage = 20;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Начальная загрузка только если данные еще не загружены
    if (_isInitialLoad) {
      _loadInitialOrders();
      _isInitialLoad = false;
    }
  }

  void _loadInitialOrders() {
    final orderBloc = context.read<OrderBloc>();
    if (orderBloc.allOrders[widget.statusId]?.isEmpty ?? true) {
      context.read<OrderBloc>().add(FetchOrders(
        statusId: widget.statusId,
        page: _currentPage,
        perPage: _perPage,
        query: widget.searchQuery,
      ));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreOrders();
    }
  }

  void _loadMoreOrders() {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    context.read<OrderBloc>().add(FetchMoreOrders(
      statusId: widget.statusId,
      page: _currentPage + 1,
      perPage: _perPage,
      query: widget.searchQuery,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });

    context.read<OrderBloc>().add(FetchOrders(
      statusId: widget.statusId,
      page: _currentPage,
      perPage: _perPage,
      query: widget.searchQuery,
      forceRefresh: true,
    ));

    // Ждем завершения обновления
    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 100));
      return context.read<OrderBloc>().state is OrderLoading;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderLoaded) {
          setState(() {
            _isLoadingMore = false;
            final orderBloc = context.read<OrderBloc>();
            _hasMore = !(orderBloc.allOrdersFetched[widget.statusId] == true);
            if (!_isLoadingMore && _hasMore) {
              _currentPage = state.pagination?.currentPage ?? _currentPage;
            }
          });
        } else if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                    content: Text(
                      '${state.message}',
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
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          List<Order> orders = [];
          bool isLoading = false;

          if (state is OrderLoading && orders.isEmpty) {
            isLoading = true;
          } else if (state is OrderLoaded) {
            orders = state.orders
                .where((order) => order.orderStatus.id == widget.statusId)
                .toList();
            if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
              final query = widget.searchQuery!.toLowerCase();
              orders = orders
                  .where((order) =>
                      order.orderNumber.toLowerCase().contains(query) ||
                      order.lead.name.toLowerCase().contains(query))
                  .toList();
            }
          }

          return RefreshIndicator(
            color: const Color(0xff1E2E52),
            backgroundColor: Colors.white,
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: PlayStoreImageLoading(
                            size: 80.0,
                            duration: Duration(milliseconds: 1000),
                          ),
                        )
                      : orders.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 200),
                                Center(child: Text('Нет заказов')),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount:
                                  orders.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == orders.length && _isLoadingMore) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: PlayStoreImageLoading(
                                        size: 80.0,
                                        duration: Duration(milliseconds: 1000),
                                      ),
                                    ),
                                  );
                                }
                                final order = orders[index];
                                return OrderCard(
                                  order: order,
                                  organizationId: widget.organizationId ??
                                      order.organizationId,
                                  onStatusUpdated: widget.onStatusUpdated,
                                  onStatusId: widget.onStatusId,
                                  onTabChange: widget.onTabChange,
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}