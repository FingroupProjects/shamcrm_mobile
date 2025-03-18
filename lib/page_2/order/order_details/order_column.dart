import 'package:crm_task_manager/page_2/order/order_card.dart';
import 'package:flutter/material.dart';

class OrderColumn extends StatelessWidget {
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

  // Пример списка заказов (в реальном проекте данные будут из API)
  List<Map<String, dynamic>> _getOrders() {
    return [
      {
        'id': 1,
        'number': 'ORD001',
        'date': '2025-03-18',
        'client': 'Иван Иванов',
        'total': 1500.0,
        'statusId': 1,
        'paymentMethod': 'Наличные',
        'deliveryMethod': 'Курьер',
      },
      {
        'id': 2,
        'number': 'ORD002',
        'date': '2025-03-17',
        'client': 'Петр Петров',
        'total': 2000.0,
        'statusId': 2,
        'paymentMethod': 'Онлайн',
        'deliveryMethod': 'Самовывоз',
      },
      // Добавить больше заказов по необходимости
    ].where((order) => order['statusId'] == statusId).toList();
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> orders) {
    var filteredOrders = orders;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) {
        return order['number'].toString().toLowerCase().contains(searchQuery!.toLowerCase()) ||
            order['client'].toString().toLowerCase().contains(searchQuery!.toLowerCase());
      }).toList();
    }

    if (filters != null) {
      if (filters!['fromDate'] != null) {
        filteredOrders = filteredOrders.where((order) {
          DateTime orderDate = DateTime.parse(order['date']);
          return orderDate.isAfter(filters!['fromDate'].subtract(const Duration(days: 1)));
        }).toList();
      }
      if (filters!['toDate'] != null) {
        filteredOrders = filteredOrders.where((order) {
          DateTime orderDate = DateTime.parse(order['date']);
          return orderDate.isBefore(filters!['toDate'].add(const Duration(days: 1)));
        }).toList();
      }
      if (filters!['client'] != null && filters!['client'].isNotEmpty) {
        filteredOrders = filteredOrders.where((order) {
          return order['client'].toString().toLowerCase().contains(filters!['client'].toLowerCase());
        }).toList();
      }
      if (filters!['status'] != null) {
        filteredOrders = filteredOrders.where((order) {
          return _getStatusName(order['statusId']) == filters!['status'];
        }).toList();
      }
      if (filters!['paymentMethod'] != null) {
        filteredOrders = filteredOrders.where((order) {
          return order['paymentMethod'] == filters!['paymentMethod'];
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
    var orders = _getOrders();
    var filteredOrders = _filterOrders(orders);

    return filteredOrders.isEmpty
        ? const Center(child: Text('Нет заказов'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return GestureDetector(
                onTap: () => onOrderTap?.call(order),
                child: OrderCard(order: order),
              );
            },
          );
  }
}