import 'package:crm_task_manager/page_2/order/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:flutter/material.dart';

class OrderColumn extends StatefulWidget {
  final int statusId;
  final String name;
  final String? searchQuery;
  final Map<String, dynamic>? filters;
  final Function(Map<String, dynamic>)? onOrderTap;

  const OrderColumn({
    required this.statusId,
    required this.name,
    this.searchQuery,
    this.filters,
    this.onOrderTap,
  });

  @override
  _OrderColumnState createState() => _OrderColumnState();
}

class _OrderColumnState extends State<OrderColumn> {
  List<Map<String, dynamic>> _orders = [
    {
      'id': 1,
      'number': 'ORD001',
      'date': '2025-03-15',
      'client': 'Иван Иванов',
      'manager': 'Анна',
      'items': [
        {'name': 'Товар 1', 'quantity': 2, 'price': 500},
        {'name': 'Товар 2', 'quantity': 1, 'price': 300},
      ],
      'total': 1300,
      'statusId': 1,
      'paymentMethod': 'Наличные',
      'deliveryMethod': 'Самовывоз',
      'comment': 'Быстрая доставка',
    },
    {
      'id': 2,
      'number': 'ORD002',
      'date': '2025-03-14',
      'client': 'Петр Сидоров',
      'manager': 'Олег Смирнов',
      'items': [
        {'name': 'Товар 3', 'quantity': 1, 'price': 1000},
      ],
      'total': 1000,
      'statusId': 3,
      'paymentMethod': 'Карта',
      'deliveryMethod': 'Курьер',
      'deliveryAddress': 'ул. Ленина, 10',
      'comment': '',
    },
  ];

  void _addOrder(Map<String, dynamic> newOrder) {
    setState(() {
      _orders.add(newOrder);
    });
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> orders) {
    var filteredOrders = orders.where((order) => order['statusId'] == widget.statusId).toList();

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) {
        return order['number'].toString().toLowerCase().contains(widget.searchQuery!.toLowerCase()) ||
            order['client'].toString().toLowerCase().contains(widget.searchQuery!.toLowerCase());
      }).toList();
    }

    if (widget.filters != null) {
      if (widget.filters!['fromDate'] != null) {
        filteredOrders = filteredOrders.where((order) {
          DateTime orderDate = DateTime.parse(order['date']);
          return orderDate.isAfter(widget.filters!['fromDate'].subtract(const Duration(days: 1)));
        }).toList();
      }
      if (widget.filters!['toDate'] != null) {
        filteredOrders = filteredOrders.where((order) {
          DateTime orderDate = DateTime.parse(order['date']);
          return orderDate.isBefore(widget.filters!['toDate'].add(const Duration(days: 1)));
        }).toList();
      }
      if (widget.filters!['client'] != null && widget.filters!['client'].isNotEmpty) {
        filteredOrders = filteredOrders.where((order) {
          return order['client'].toString().toLowerCase().contains(widget.filters!['client'].toLowerCase());
        }).toList();
      }
      if (widget.filters!['status'] != null) {
        filteredOrders = filteredOrders.where((order) {
          return _getStatusName(order['statusId']) == widget.filters!['status'];
        }).toList();
      }
      if (widget.filters!['paymentMethod'] != null) {
        filteredOrders = filteredOrders.where((order) {
          return order['paymentMethod'] == widget.filters!['paymentMethod'];
        }).toList();
      }
    }

    return filteredOrders;
  }

  String _getStatusName(int statusId) {
    const statusMap = {
      1: 'Новый',
      2: 'Ожидает оплаты',
      3: 'Оплачен',
      4: 'В обработке',
      5: 'Отправлен',
      6: 'Завершен',
      7: 'Отменен',
    };
    return statusMap[statusId] ?? 'Неизвестный статус';
  }

  @override
  Widget build(BuildContext context) {
    var filteredOrders = _filterOrders(_orders);

    return Scaffold(
      backgroundColor: Colors.white,
      body: filteredOrders.isEmpty
          ? Center(
              child: Text(
                widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                    ? 'Ничего не найдено'
                    : 'Нет заказов в этом статусе',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff99A4BA),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: GestureDetector(
                    onTap: () => widget.onOrderTap?.call(order),
                    child: OrderCard(order: order),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newOrder = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderAddScreen(statusId: widget.statusId),
            ),
          );
          if (newOrder != null) {
            _addOrder(newOrder);
          }
        },
        backgroundColor: const Color(0xff1E2E52),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}