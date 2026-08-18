import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';

class OrderColumn extends StatefulWidget {
  final int statusId;
  final String name;
  final String? searchQuery;
  final int? organizationId;
  final void Function(int oldStatusId, int newStatusId) onStatusUpdated;
  final void Function(int newStatusId) onStatusId;
  final Function(int) onTabChange;
  final bool canCreateOrder;

  const OrderColumn({
    required this.statusId,
    required this.name,
    this.searchQuery,
    this.organizationId,
    required this.onStatusUpdated,
    required this.onStatusId,
    required this.onTabChange,
    this.canCreateOrder = false,
  });

  @override
  _OrderColumnState createState() => _OrderColumnState();
}

class _OrderColumnState extends State<OrderColumn> {
  final ScrollController _scrollController = ScrollController();
  late OrderBloc _orderBloc;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderBloc = context.read<OrderBloc>();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreOrders();
    }
  }

  void _loadMoreOrders() {
    if (!mounted || _isLoadingMore || !_hasMore) return;

    final state = _orderBloc.state;
    if (state is OrderLoaded) {
      final orderBloc = _orderBloc;
      if (orderBloc.allOrdersFetched[widget.statusId] == true) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      setState(() {
        _isLoadingMore = true;
      });
      _orderBloc.add(FetchMoreOrders(
        statusId: widget.statusId,
        page: _currentPage + 1, // Следующая страница
        perPage: _perPage,
      ));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.mounted) {
      return HelpfulEmptyState.loading();
    }
    return BlocListener<OrderBloc, OrderState>(
      bloc: _orderBloc,
      listener: (context, state) {
        if (!mounted) return;
        if (state is OrderLoaded) {
          final orderBloc = _orderBloc;
          setState(() {
            _isLoadingMore = false;
            _hasMore = !(orderBloc.allOrdersFetched[widget.statusId] == true);
            if (!_isLoadingMore && _hasMore) {
              _currentPage = state.pagination?.currentPage ?? _currentPage;
            }
          });
        } else if (state is OrderError) {
          setState(() {
            _isLoadingMore = false;
            _hasMore = false; // Останавливаем подгрузку при ошибке
          });
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        bloc: _orderBloc,
        builder: (context, state) {
          List<Order> orders = [];
          bool isLoading = false;

          if (state is OrderLoading) {
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

          final orderBloc = _orderBloc;
          final readyForThisStatus = HelpfulEmptyState.isReadyForStatus(
            isFetching: orderBloc.isFetching,
            completedStatusId: orderBloc.lastCompletedFetchStatusId,
            statusId: widget.statusId,
          );
          final showLoader =
              isLoading || (orders.isEmpty && !readyForThisStatus);

          if (showLoader) {
            return HelpfulEmptyState.loading();
          }

          if (orders.isEmpty && !_isLoadingMore) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: orders.length + (_isLoadingMore ? 1 : 0),
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
                      organizationId:
                          widget.organizationId ?? order.organizationId,
                      onStatusUpdated: widget.onStatusUpdated,
                      onStatusId: widget.onStatusId,
                      onTabChange: widget.onTabChange,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return HelpfulEmptyState.refreshable(
      context: context,
      onRefresh: () async {
        _orderBloc.add(FetchOrders(
          statusId: widget.statusId,
          page: 1,
          perPage: _perPage,
          forceRefresh: true,
        ));
      },
      child: HelpfulEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: l10n.translate('empty_orders_title'),
        subtitle: l10n.translate('empty_orders_subtitle'),
        actionLabel: widget.canCreateOrder
            ? l10n.translate('empty_orders_action')
            : null,
        onAction: widget.canCreateOrder ? _openCreateOrder : null,
      ),
    );
  }

  Future<void> _openCreateOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderAddScreen(
          organizationId: widget.organizationId,
        ),
      ),
    );
    if (!mounted) return;
    if (result is Map && result['success'] == true) {
      _orderBloc.add(FetchOrders(
        statusId: widget.statusId,
        page: 1,
        perPage: _perPage,
        forceRefresh: true,
      ));
    }
  }
}
