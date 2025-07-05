import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_status_style.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final int? organizationId;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;
  final Function(int) onTabChange;

  const OrderCard({
    required this.order,
    this.organizationId,
    required this.onStatusUpdated,
    required this.onStatusId,
    required this.onTabChange,
    super.key,
  });

  @override
  _OrderCardState createState() => _OrderCardState();
}

class PaymentTypeStyle {
  final Widget content;
  final Color backgroundColor;
  final bool isImage;

  PaymentTypeStyle({
    required this.content,
    required this.backgroundColor,
    this.isImage = false,
  });
}

PaymentTypeStyle getPaymentTypeStyle(String? paymentType, BuildContext context) {
  switch (paymentType?.toLowerCase()) {
    case 'cash':
      return PaymentTypeStyle(
        content: Text(
          'Наличными',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 242, 242, 242),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color.fromARGB(255, 23, 178, 36),
        isImage: false,
      );
    case 'alif':
      return PaymentTypeStyle(
        content: Transform.translate(
          offset: const Offset(0.0, 0), // Сдвиг влево на 8 пикселей
          child: Transform.scale(
            scaleY: 1.2, // Увеличиваем высоту на 20%
            scaleX: 1.2,
            child: Image.asset(
              'assets/icons/alif.png',
              width: 60,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'ALIF',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 242, 242, 242),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    case 'click':
      return PaymentTypeStyle(
        content: Transform.translate(
          offset: const Offset(0.0, 0), // Сдвиг влево на 8 пикселей
          child: Transform.scale(
            scaleY: 1.2, // Увеличиваем высоту на 20%
            scaleX: 1.2,
            child: Image.asset(
              'assets/icons/click3.png',
              width: 60,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'CLICK',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 242, 242, 242),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    case 'payme':
      return PaymentTypeStyle(
        content: Transform.translate(
       offset: const Offset(0.0, 0), // Сдвиг влево на 8 пикселей
          child: Transform.scale(
            scaleY: 1.2, // Увеличиваем высоту на 20%
            scaleX: 1.2,
            child: Image.asset(
              'assets/icons/payme.png',
              width: 60,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'PAYME',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 242, 242, 242),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    default:
      return PaymentTypeStyle(
        content: Text(
          'Неизвестно',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.grey[300]!,
        isImage: false,
      );
  }
}

class _OrderCardState extends State<OrderCard> {
  late String dropdownValue;
  late int statusId;

  @override
  void initState() {
    super.initState();
    statusId = widget.order.orderStatus.id;
    dropdownValue = widget.order.orderStatus.name;
  }

  Color _getStatusTextColor(int statusId) {
    switch (statusId) {
      case 1:
        return const Color.fromARGB(255, 58, 217, 66)!;
      case 2:
        return Colors.amber[900]!;
      default:
        return Colors.grey[800]!;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)!.translate('no_date');
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatSum(double? sum) {
    if (sum == null) return '0 сом';
    return NumberFormat('#,##0 сом', 'ru_RU').format(sum);
  }

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(
            orderId: widget.order.id,
            categoryName: '',
            order: widget.order,
            organizationId: widget.organizationId,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          // Номер заказа и дата
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Заказ №${widget.order.orderNumber}',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Создан: ${_formatDate(widget.order.lead.createdAt)}',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff99A4BA),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Статус и сумма
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
                      widget.onStatusId(newStatusId);
                      widget.onStatusUpdated();
                      context.read<OrderBloc>().add(ChangeOrderStatus(
                            orderId: widget.order.id,
                            statusId: newStatusId,
                            organizationId: widget.organizationId,
                          ));
                    },
                    widget.order,
                    onTabChange: widget.onTabChange,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 150),
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
              Text(
                _formatSum(widget.order.sum),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 18),
// Способ оплаты, статус платежа и менеджер
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.3 - 8, // 30% ширины минус отступы
      ),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getPaymentTypeStyle(widget.order.paymentMethod, context).backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: getPaymentTypeStyle(widget.order.paymentMethod, context).content,
        ),
      ),
    ),
    ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.3 - 8, // 30% ширины минус отступы
      ),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getPaymentStatusStyle(widget.order.paymentStatus, context).backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: getPaymentStatusStyle(widget.order.paymentStatus, context).content,
        ),
      ),
    ),
    ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.4 - 8, // 40% ширины минус отступы
      ),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDF5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.order.manager?.name ?? 'Система',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff99A4BA),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ),
  ],
),
          const SizedBox(height: 18),
          // Клиент и номер лида
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xff99A4BA),
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.order.lead.name,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.order.phone.isNotEmpty
                    ? widget.order.phone
                    : AppLocalizations.of(context)!.translate('no_phone'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
}