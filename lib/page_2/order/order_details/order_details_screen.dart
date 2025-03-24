import 'package:crm_task_manager/page_2/category/category_details/category_goods_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_delete.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_edits.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_good_screen.dart';
import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final String categoryName;

  OrderDetailsScreen({
    required this.order,
    required this.categoryName,
  });

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List<Map<String, String>> details = [];

  @override
  void initState() {
    super.initState();
    _updateDetails();
  }

  void _updateDetails() {
    details = [
      {'label': 'Номер заказа:', 'value': widget.order['number'] ?? 'Не указан'},
      {'label': 'Дата заказа:', 'value': widget.order['date'] ?? 'Не указана'},
      {'label': 'Клиент:', 'value': widget.order['client'] ?? 'Не указан'},
      {
        'label': 'Ответственный менеджер:',
        'value': widget.order['manager'] ?? 'Не указан'
      },
      {'label': 'Сумма заказа:', 'value': '${widget.order['total'] ?? 0} ₽'},
      {
        'label': 'Статус заказа:',
        'value': _getStatusName(widget.order['statusId'] ?? 1)
      },
      {
        'label': 'Способ оплаты:',
        'value': widget.order['paymentMethod'] ?? 'Не указан'
      },
      {
        'label': 'Способ доставки:',
        'value': widget.order['deliveryMethod'] ?? 'Не указан'
      },
      if (widget.order['deliveryMethod'] != 'Самовывоз')
        {
          'label': 'Адрес доставки:',
          'value': widget.order['deliveryAddress'] ?? 'Не указан'
        },
      {'label': 'Комментарий клиента:', 'value': widget.order['comment'] ?? ''},
    ];
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

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff1E2E52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Закрыть',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          children: [
            _buildDetailsList(),
            CategoryGoodsScreen(
              categoryName: widget.categoryName,
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xff1E2E52)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Заказ #${widget.order['number']}',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          icon: Image.asset(
            'assets/icons/edit.png',
            width: 24,
            height: 24,
          ),
          onPressed: () async {
            final updatedOrder = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderEditScreen(order: widget.order),
              ),
            );
            if (updatedOrder != null) {
              setState(() {
                widget.order.clear();
                widget.order.addAll(updatedOrder);
                _updateDetails();
              });
            }
          },
        ),
        IconButton(
          padding: EdgeInsets.only(right: 8),
          constraints: BoxConstraints(),
          icon: Image.asset(
            'assets/icons/delete.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) =>
                  DeleteOrderDialog(orderId: widget.order['id']),
            ).then((shouldDelete) {
              if (shouldDelete == true) {
                Navigator.pop(context, true); // Указываем, что заказ удален
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
              details[index]['label']!, details[index]['value']!),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    if (label == 'Комментарий клиента') {
      return GestureDetector(
        onTap: () {
          if (value.isNotEmpty) _showFullTextDialog(label, value);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                  decoration:
                      value.isNotEmpty ? TextDecoration.underline : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(width: 8),
        Expanded(child: _buildValue(value)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }
}
