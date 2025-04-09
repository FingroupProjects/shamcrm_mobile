import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_card.dart';
import 'package:flutter/material.dart';

class OrderColumn extends StatelessWidget {
  final int statusId;
  final String name;
  final String? searchQuery;
  final List<Order> orders;
  final bool isLoading;
  final int? organizationId;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;
  final Function(int) onTabChange; // Новый коллбэк

  const OrderColumn({
    required this.statusId,
    required this.name,
    this.searchQuery,
    required this.orders,
    this.isLoading = false,
    this.organizationId,
    required this.onStatusUpdated,
    required this.onStatusId,
    required this.onTabChange, // Добавляем в конструктор
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  ? const Center(child: Text('Нет заказов'))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return OrderCard(
                          order: order,
                          organizationId: organizationId ?? order.organizationId,
                          onStatusUpdated: onStatusUpdated,
                          onStatusId: onStatusId,
                          onTabChange: onTabChange, // Передаем коллбэк
                        );
                      },
                    ),
        ),
      ],
    );
  }
}