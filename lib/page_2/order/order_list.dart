// import 'package:flutter/material.dart';
// import 'order_card.dart';

// class OrderList extends StatefulWidget {
//   final String selectedStatus;
//   final String searchQuery;

//   const OrderList({required this.selectedStatus, required this.searchQuery, super.key});

//   @override
//   _OrderListState createState() => _OrderListState();
// }

// class _OrderListState extends State<OrderList> {
//   // Локальный список заказов (вместо API)
//   List<Map<String, dynamic>> orders = [
//     {'number': '1001', 'client': 'Иван Иванов', 'date': '2025-03-14', 'amount': 1500, 'status': 'Новый'},
//     {'number': '1002', 'client': 'Анна Петрова', 'date': '2025-03-13', 'amount': 2300, 'status': 'Оплачен'},
//     {'number': '1003', 'client': 'Петр Сидоров', 'date': '2025-03-12', 'amount': 800, 'status': 'Отправлен'},
//     {'number': '1004', 'client': 'Мария Козлова', 'date': '2025-03-11', 'amount': 5000, 'status': 'Ожидает оплаты'},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     // Фильтрация заказов
//     List<Map<String, dynamic>> filteredOrders = orders.where((order) {
//       final matchesStatus = widget.selectedStatus.isEmpty || order['status'] == widget.selectedStatus;
//       final matchesSearch = widget.searchQuery.isEmpty ||
//           order['number'].contains(widget.searchQuery) ||
//           order['client'].toLowerCase().contains(widget.searchQuery.toLowerCase());
//       return matchesStatus && matchesSearch;
//     }).toList();

//     return filteredOrders.isEmpty
//         ? const Center(child: Text('Нет заказов по заданным фильтрам'))
//         : ListView.builder(
//             itemCount: filteredOrders.length,
//             itemBuilder: (context, index) {
//               final order = filteredOrders[index];
//               return OrderCard(
//                 order: order,
//                 onTap: () {
//                   Navigator.pushNamed(context, '/order_details', arguments: order);
//                 },
//               );
//             },
//           );
//   }
// }