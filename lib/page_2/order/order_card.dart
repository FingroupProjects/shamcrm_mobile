import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  OrderCard({required this.order});

  // Получение названия статуса
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

  // Цвет текста для статуса
  Color _getStatusTextColor(int statusId) {
    switch (statusId) {
      case 1:
        return Colors.grey[800]!; // Новый
      case 2:
        return Colors.amber[900]!; // Ожидает оплаты
      case 3:
        return Colors.green[800]!; // Оплачен
      case 4:
        return Colors.blue[800]!; // В обработке
      case 5:
        return Colors.orange[900]!; // Отправлен
      case 6:
        return Colors.teal[700]!; // Завершен
      case 7:
        return Colors.red[900]!; // Отменен
      default:
        return Colors.grey[800]!;
    }
  }

  // Цвет фона для статуса
  Color _getStatusBackgroundColor(int statusId) {
    switch (statusId) {
      case 1:
        return Colors.grey[100]!; // Новый
      case 2:
        return Colors.amber[50]!; // Ожидает оплаты
      case 3:
        return Colors.green[50]!; // Оплачен
      case 4:
        return Colors.blue[50]!; // В обработке
      case 5:
        return Colors.orange[50]!; // Отправлен
      case 6:
        return Colors.teal[50]!; // Завершен
      case 7:
        return Colors.red[50]!; // Отменен
      default:
        return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 1),
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
                  '№${order['number']}',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                Text(
                  order['date'],
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff99A4BA),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), // Gap 10px
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(12, 8, 12,
                      8), // Left 12px, Top 8px, Right 12px, Bottom 8px
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(order['statusId']),
                    borderRadius: BorderRadius.circular(8), // Radius 8px
                  ),

                  child: Text(
                    _getStatusName(order['statusId']),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusTextColor(order['statusId']),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Gap 10px
                Expanded(
                  child: Text(
                    '${order['total'].toString().replaceAll('.0', '')} сом',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign:
                        TextAlign.right, // Выравнивание текста по правому краю
                    overflow: TextOverflow
                        .ellipsis, // Обрезка текста, если он слишком длинный
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), // Gap 10px
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Color(0xff99A4BA),
                  size: 16,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['client'],
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
