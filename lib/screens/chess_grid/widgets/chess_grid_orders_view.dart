import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/payment_schedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChessGridOrdersView extends StatefulWidget {
  final ChessGridController controller;

  const ChessGridOrdersView({super.key, required this.controller});

  @override
  State<ChessGridOrdersView> createState() => _ChessGridOrdersViewState();
}

class _ChessGridOrdersViewState extends State<ChessGridOrdersView> {
  OrderStatus? _selectedStatusFilter; // null = all

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;

    final allOrders = controller.orders;
    final filtered = _selectedStatusFilter == null
        ? allOrders
        : allOrders.where((o) => o.status == _selectedStatusFilter).toList();

    final inProgressCount = allOrders.where((o) => o.status == OrderStatus.inProgress).length;
    final successCount = allOrders.where((o) => o.status == OrderStatus.success).length;
    final rejectedCount = allOrders.where((o) => o.status == OrderStatus.rejected).length;

    return Column(
      children: [
        // Status filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterTab(
                label: 'Все',
                count: allOrders.length,
                isSelected: _selectedStatusFilter == null,
                onTap: () => setState(() => _selectedStatusFilter = null),
              ),
              const SizedBox(width: 8),
              _buildFilterTab(
                label: 'В работе',
                count: inProgressCount,
                color: OrderStatus.inProgress.color,
                isSelected: _selectedStatusFilter == OrderStatus.inProgress,
                onTap: () => setState(() => _selectedStatusFilter = OrderStatus.inProgress),
              ),
              const SizedBox(width: 8),
              _buildFilterTab(
                label: 'Успешно',
                count: successCount,
                color: OrderStatus.success.color,
                isSelected: _selectedStatusFilter == OrderStatus.success,
                onTap: () => setState(() => _selectedStatusFilter = OrderStatus.success),
              ),
              const SizedBox(width: 8),
              _buildFilterTab(
                label: 'Неуспешно',
                count: rejectedCount,
                color: OrderStatus.rejected.color,
                isSelected: _selectedStatusFilter == OrderStatus.rejected,
                onTap: () => setState(() => _selectedStatusFilter = OrderStatus.rejected),
              ),
            ],
          ),
        ),

        // List of orders
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 48, color: colors.iconSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'Нет заказов в этой категории',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return _buildOrderCard(context, order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterTab({
    required String label,
    required int count,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    final activeColor = color ?? colors.buttonPrimaryBg;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.16)
              : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : colors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
                color: isSelected ? activeColor : colors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final colors = context.appColors;
    final controller = widget.controller;
    final apt = controller.findApartmentById(order.apartmentId);
    final park = controller.findParkingById(order.parkingId);

    final itemTitle = apt != null
        ? 'Кв. № ${apt.number}'
        : (park != null ? 'Парк. ${park.number}' : 'Объект');

    final statusColor = order.status.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID + Item & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.id,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      itemTitle,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: colors.buttonPrimaryBg,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${order.price.toStringAsFixed(0)} \$',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Buyer Name & Manager
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: colors.iconSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.buyerName,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'Менеджер: ${order.manager}',
                  style: TextStyle(
                    fontFamily: 'Golos',
                    fontSize: 11.5,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),

            if (order.buyerPhone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: colors.iconSecondary),
                  const SizedBox(width: 6),
                  Text(
                    order.buyerPhone,
                    style: TextStyle(
                      fontFamily: 'Golos',
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),

            // Deal type & details
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.dealType.labelRu,
                    style: TextStyle(
                      fontFamily: 'Golos',
                      fontWeight: FontWeight.w600,
                      fontSize: 10.5,
                      color: colors.buttonPrimaryBg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (apt != null)
                  Expanded(
                    child: Text(
                      '${apt.buildingName}, ${apt.floor} эт., ${apt.rooms}к, ${apt.totalArea} м²',
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),

            // Active Reservation Timer for "В работе"
            if (order.status == OrderStatus.inProgress && order.reservedUntil != null) ...[
              const SizedBox(height: 10),
              _buildCountdownChip(context, order.reservedUntil!),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Bottom Actions: Status Dropdown + Schedule Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Selector Dropdown
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<OrderStatus>(
                      value: order.status,
                      icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 20),
                      items: OrderStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.labelRu,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: s.color,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != order.status) {
                          controller.updateOrderStatus(order, newStatus);
                        }
                      },
                    ),
                  ),
                ),

                // Payment Schedule button (if installment or mixed)
                if (order.paymentDetails != null)
                  TextButton.icon(
                    onPressed: () {
                      PaymentScheduleSheet.show(context: context, order: order);
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: const Text('График платежей'),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.buttonPrimaryBg,
                      textStyle: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownChip(BuildContext context, DateTime until) {
    final colors = context.appColors;
    final now = DateTime.now();
    final diff = until.difference(now);

    final isExpired = diff.isNegative;
    final isUrgent = !isExpired && diff.inHours < 24;

    String text;
    if (isExpired) {
      text = 'Срок бронирования истёк';
    } else if (diff.inDays >= 1) {
      text = 'Бронь до ${DateFormat('dd.MM.yyyy').format(until)} (осталось ${diff.inDays} дн.)';
    } else {
      text = 'Бронь до ${DateFormat('dd.MM HH:mm').format(until)} (осталось ${diff.inHours} ч.)';
    }

    final chipColor = isExpired
        ? colors.error
        : (isUrgent ? colors.warning : colors.buttonPrimaryBg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Golos',
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}
