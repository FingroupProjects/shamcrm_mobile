import 'package:crm_task_manager/page_2/order/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:flutter/material.dart';


class OrderColumn extends StatefulWidget {
  final int statusId;
  final String name;
  final String? searchQuery;

  OrderColumn({required this.statusId, required this.name, this.searchQuery});

  @override
  _OrderColumnState createState() => _OrderColumnState();
}

class _OrderColumnState extends State<OrderColumn> {
  // Локальные данные для теста
  List<Map<String, dynamic>> _orders = [
    {
      'id': 1,
      'number': 'ORD001',
      'date': '2025-03-15',
      'client': 'Иван Иванов',
      'manager': 'Анна Петрова',
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredOrders = _orders
        .where((order) => order['statusId'] == widget.statusId)
        .where((order) {
          if (widget.searchQuery == null || widget.searchQuery!.isEmpty) return true;
          return order['number'].toString().toLowerCase().contains(widget.searchQuery!.toLowerCase()) ||
              order['client'].toString().toLowerCase().contains(widget.searchQuery!.toLowerCase());
        })
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: filteredOrders.isEmpty
          ? Center(
              child: Text(
                widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                    ? 'Ничего не найдено'
                    : 'Нет заказов в статусе "${widget.name}"',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff99A4BA),
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 15),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OrderCard(order: filteredOrders[index]),
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
        backgroundColor: Color(0xff1E2E52),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}