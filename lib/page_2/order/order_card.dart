import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Для форматирования даты

class OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(int)? onStatusUpdated;

  const OrderCard({required this.order, this.onStatusUpdated});

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  late String dropdownValue;
  late int statusId;

  @override
  void initState() {
    super.initState();
    statusId = widget.order['statusId'];
    dropdownValue = _getStatusName(statusId);
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

  Color _getStatusTextColor(int statusId) {
    switch (statusId) {
      case 1:
        return Colors.green[800]!;
      case 2:
        return Colors.amber[900]!;
      case 3:
        return Colors.green[800]!;
      case 4:
        return Colors.blue[800]!;
      case 5:
        return Colors.orange[900]!;
      case 6:
        return Colors.teal[700]!;
      case 7:
        return Colors.red[900]!;
      default:
        return Colors.grey[800]!;
    }
  }

  Color _getStatusBackgroundColor(int statusId) {
    switch (statusId) {
      case 1:
        return Colors.green[100]!;
      case 2:
        return Colors.amber[50]!;
      case 3:
        return Colors.green[50]!;
      case 4:
        return Colors.blue[50]!;
      case 5:
        return Colors.orange[50]!;
      case 6:
        return Colors.teal[50]!;
      case 7:
        return Colors.red[50]!;
      default:
        return Colors.grey[100]!;
    }
  }

  // Форматирование даты в dd.MM.yyyy
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: widget.order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 244, 247, 254),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '№${widget.order['number']}',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                Text(
                  _formatDate(widget.order['date']),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff99A4BA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    OrderDropdownBottomSheet(
                      context,
                      dropdownValue,
                      (String newValue, int newStatusId) {
                        setState(() {
                          dropdownValue = newValue;
                          statusId = newStatusId;
                        });
                        if (widget.onStatusUpdated != null) {
                          widget.onStatusUpdated!(newStatusId);
                        }
                      },
                      widget.order,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xff1E2E52),
                        width: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          constraints: BoxConstraints(maxWidth: 200),
                          child: Text(
                            dropdownValue,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/icons/tabBar/dropdown.png',
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${widget.order['total'].toString().replaceAll('.0', '')} сом',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xff99A4BA),
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Лид: ${widget.order['client']}',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Text(
                  '${widget.order['manager']}',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}