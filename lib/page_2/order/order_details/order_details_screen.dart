import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_edits.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_good_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final String categoryName;
  final Order order;
  final int? organizationId; // Добавляем новое поле

  const OrderDetailsScreen({
    required this.orderId,
    required this.order,
    required this.categoryName,
     this.organizationId, // Добавляем в конструктор
  });

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List<Map<String, String>> details = [];

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(FetchOrderDetails(widget.orderId));
  }

  void _updateDetails(Order order) {
    String formattedDate = order.lead.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(order.lead.createdAt!)
        : 'Не указана';

    details = [
      {'label': 'Номер заказа:', 'value': order.orderNumber},
      {'label': 'Дата заказа:', 'value': formattedDate},
      {'label': 'Клиент:', 'value': order.lead.name},
      {'label': 'Статус заказа:', 'value': order.orderStatus.name},
      if (order.deliveryAddress != null)
        {
          'label': 'Адрес доставки:',
          'value': order.deliveryAddress ?? 'Не указан'
        },
    ];
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1E2E52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
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
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is OrderLoaded && state.orderDetails != null) {
          _updateDetails(state.orderDetails!);
          return Scaffold(
            appBar: _buildAppBar(context, state.orderDetails!),
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView(
                children: [
                  _buildDetailsList(),
                  OrderGoodsScreen(
                    goods: state.orderDetails!.goods,
                    order: widget.order,
                  ), // Передаем товары
                ],
              ),
            ),
          );
        } else if (state is OrderError) {
          return Scaffold(
            body: Center(child: Text(state.message)),
          );
        }
        return const Scaffold(
          body: Center(child: Text('')),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, Order order) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xff1E2E52)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Заказ #${order.orderNumber}',
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(
            Icons.history,
            size: 30,
            color: Color.fromARGB(224, 0, 0, 0),
          ),
          onPressed: () {},
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Image.asset(
            'assets/icons/edit.png',
            width: 24,
            height: 24,
          ),
          onPressed: () async {
            final updatedOrder = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OrderEditScreen(order: order), // Передаем объект Order
              ),
            );
            if (updatedOrder != null) {
              context.read<OrderBloc>().add(FetchOrderDetails(widget.orderId));
            }
          },
        ),
        // IconButton(
        //   padding: EdgeInsets.only(right: 8),
        //   constraints: const BoxConstraints(),
        //   icon: Image.asset(
        //     'assets/icons/delete.png',
        //     width: 24,
        //     height: 24,
        //   ),
        //   onPressed: () {
        //     showDialog(
        //       context: context,
        //       builder: (context) => DeleteOrderDialog(orderId: widget.orderId),
        //     ).then((shouldDelete) {
        //       if (shouldDelete == true) {
        //         // Предполагаем, что у вас есть доступ к organizationId
        //         // Если его нет, нужно будет добавить в виджет
        //         context.read<OrderBloc>().add(DeleteOrder(
        //               orderId: widget.orderId,
        //               organizationId: order.organizationId, // Добавьте это поле в Order модель если его нет
        //             ));
        //         // Подписываемся на изменение состояния после удаления
        //         context.read<OrderBloc>().stream.listen((state) {
        //           if (state is OrderSuccess) {
        //             Navigator.pop(context, true);
        //           } else if (state is OrderError) {
        //             ScaffoldMessenger.of(context).showSnackBar(
        //               SnackBar(
        //                 content: Text(state.message),
        //                 backgroundColor: Colors.red,
        //               ),
        //             );
        //           }
        //         });
        //       }
        //     });
        //   },
        // ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    if (label == 'Комментарий клиента:') {
      return GestureDetector(
        onTap: () {
          if (value.isNotEmpty && value != 'Нет комментария') {
            _showFullTextDialog(label.replaceAll(':', ''), value);
          }
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
                  decoration: value.isNotEmpty && value != 'Нет комментария'
                      ? TextDecoration.underline
                      : null,
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
      style: const TextStyle(
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
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }
}
