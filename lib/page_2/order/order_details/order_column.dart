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
  final List<Order> orders;
  final bool isLoading;
  final int? organizationId;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;
  final Function(int) onTabChange;

  const OrderColumn({
    required this.statusId,
    required this.name,
    this.searchQuery,
    required this.orders,
    this.isLoading = false,
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    final state = context.read<OrderBloc>().state;
    if (state is OrderLoaded) {
      final orderBloc = context.read<OrderBloc>();
      if (orderBloc.allOrdersFetched[widget.statusId] == true) {
        setState(() {
          _hasMore = false;
        });
        return;
      }

      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      context.read<OrderBloc>().add(FetchMoreOrders(
        statusId: widget.statusId,
        page: _currentPage,
        perPage: _perPage,
      ));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderLoaded) {
          final orderBloc = context.read<OrderBloc>();
          setState(() {
            _isLoadingMore = false;
            _hasMore = !(orderBloc.allOrdersFetched[widget.statusId] == true);
          });
        }
      },
      child: Column(
        children: [
          Expanded(
            child: widget.isLoading
                ? const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  )
                : widget.orders.isEmpty
                    ? const Center(child: Text('Нет заказов'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: widget.orders.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == widget.orders.length && _isLoadingMore) {
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
                          final order = widget.orders[index];
                          return OrderCard(
                            order: order,
                            organizationId: widget.organizationId ?? order.organizationId,
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
  }
}