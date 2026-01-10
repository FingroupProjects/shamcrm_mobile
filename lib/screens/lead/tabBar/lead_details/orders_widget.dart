import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrdersWidget extends StatefulWidget {
  final int leadId;
  final String? clientPhone; // Телефон клиента для автозаполнения
  final GlobalKey? key;

  OrdersWidget({required this.leadId, this.clientPhone, this.key});

  @override
  _OrdersWidgetState createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<OrderByLeadBloc>().add(FetchOrdersByLead(leadId: widget.leadId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderByLeadBloc, OrderByLeadState>(
      listener: (context, state) {
        if (state is OrderByLeadError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
        }
      },
      builder: (context, state) {
        List<Order> orders = [];
        if (state is OrderByLeadLoaded) {
          orders = state.orders;
        }

        return _buildOrdersList(orders);
      },
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(AppLocalizations.of(context)!.translate('appbar_orders')),
        SizedBox(height: 8),
        if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 300,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _buildOrderItem(orders[index]);
              },
            ),
          ),
      ],
    );
  }
 String formatPaymentType(String? paymentType, BuildContext context) {
    switch (paymentType?.toLowerCase()) {
      case 'cash':
        return 'Наличными';
      case 'alif':
        return 'ALIF';
      case 'click':
        return 'CLICK';
      case 'payme':
        return 'PAYME';
      default:
        return AppLocalizations.of(context)!.translate('');
    }
  }
Widget _buildOrderItem(Order order) {
  String formattedDate = order.createdAt != null
      ? DateFormat('dd.MM.yyyy').format(order.createdAt!)
      : AppLocalizations.of(context)!.translate('');

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(
            orderId: order.id,
            order: order,
            categoryName: '',
          ),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: TaskCardStyles.taskCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/MyNavBar/deal_ON.png',
                width: 24,
                height: 24,
                color: Color(0xff1E2E52),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.translate('order_title')}№${order.orderNumber}',
                      style: TaskCardStyles.titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                     SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.translate('creation_date_details')} ${formattedDate}',
                      style: TaskCardStyles.priorityStyle.copyWith(
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.translate('payment_method')}: ${formatPaymentType(order.paymentMethod, context)}',
                      style: TaskCardStyles.priorityStyle.copyWith(
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.translate('status_details')} ${order.orderStatus.name}',
                      style: TaskCardStyles.priorityStyle.copyWith(
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.translate('summa_history')} ${order.sum}',
                      style: TaskCardStyles.priorityStyle.copyWith(
                        color: Color(0xff1E2E52),
                        // fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                   
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  Widget _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderAddScreen(
                  leadId: widget.leadId,
                  clientPhone: widget.clientPhone, // Передаем телефон клиента
                ),
              ),
            ).then((_) {
              context.read<OrderByLeadBloc>().add(FetchOrdersByLead(leadId: widget.leadId));
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.translate('add'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}