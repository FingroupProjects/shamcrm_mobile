// models/order_model.dart
import 'package:flutter/material.dart';

class OrderModel {
  final String id;
  final DateTime date;
  final String clientName;
  final String managerName;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final DeliveryMethod deliveryMethod;
  final String? deliveryAddress;
  final String? clientComment;

  OrderModel({
    required this.id,
    required this.date,
    required this.clientName,
    required this.managerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.deliveryMethod,
    this.deliveryAddress,
    this.clientComment,
  });
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

enum OrderStatus {
  new_,
  awaitingPayment,
  paid,
  processing,
  shipped,
  completed,
  canceled
}

enum PaymentMethod {
  cash,
  online,
  card,
  other
}

enum DeliveryMethod {
  pickup,
  courier,
  post,
  other
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.new_:
        return 'Новый';
      case OrderStatus.awaitingPayment:
        return 'Ожидает оплаты';
      case OrderStatus.paid:
        return 'Оплачен';
      case OrderStatus.processing:
        return 'В обработке';
      case OrderStatus.shipped:
        return 'Отправлен';
      case OrderStatus.completed:
        return 'Завершен';
      case OrderStatus.canceled:
        return 'Отменен';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.new_:
        return Colors.blue;
      case OrderStatus.awaitingPayment:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.green;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.shipped:
        return Colors.teal;
      case OrderStatus.completed:
        return Colors.green.shade800;
      case OrderStatus.canceled:
        return Colors.red;
    }
  }
}