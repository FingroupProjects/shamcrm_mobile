import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrdersWidget extends StatefulWidget {
  final int entityId;
  final String relationType;
  final int? leadId;
  final String? clientPhone; // Телефон клиента для автозаполнения
  final bool autoFetch;
  final Future<void> Function()? onOrdersChanged;

  OrdersWidget({
    required this.entityId,
    this.relationType = 'lead',
    this.leadId,
    this.clientPhone,
    this.autoFetch = true,
    this.onOrdersChanged,
    super.key,
  });

  @override
  _OrdersWidgetState createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> {
  late ScrollController _scrollController;

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appColors.textInverse.withValues(alpha: 0.16),
        ),
      );

  Future<void> _refreshOrders() async {
    if (!mounted) return;

    context.read<OrderByLeadBloc>().add(
          FetchOrdersByLead(
            entityId: widget.entityId,
            relationType: widget.relationType,
          ),
        );

    await widget.onOrdersChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.autoFetch) {
      _refreshOrders();
    }
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
        _buildTitleRow(
            AppLocalizations.of(context)!.translate('appbar_orders')),
        SizedBox(height: 8),
        if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: _cardDecoration(context),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary
                          .withValues(alpha: 0.9),
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
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(
              orderId: order.id,
              order: order,
              categoryName: '',
            ),
          ),
        );
        await _refreshOrders();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: _cardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/MyNavBar/deal_ON.png',
                  width: 24,
                  height: 24,
                  color: context.appColors.buttonPrimaryBg,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.translate('order_title')}№${order.orderNumber}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('creation_date_details')} ${formattedDate}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('payment_method')}: ${formatPaymentType(order.paymentMethod, context)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('status_details')} ${order.orderStatus.name}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('summa_history')} ${order.sum}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
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
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderAddScreen(
                  leadId: widget.relationType == 'lead'
                      ? widget.entityId
                      : widget.leadId,
                  dealId:
                      widget.relationType == 'deal' ? widget.entityId : null,
                  clientPhone: widget.clientPhone, // Передаем телефон клиента
                ),
              ),
            );

            if (!mounted) return;

            if (result is Map<String, dynamic> && result['success'] == true) {
              await _refreshOrders();
              return;
            }

            await _refreshOrders();
          },
          style: TextButton.styleFrom(
            foregroundColor: context.appColors.buttonPrimaryFg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: context.appColors.buttonPrimaryBg,
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
              color: context.appColors.buttonPrimaryFg,
            ),
          ),
        ),
      ],
    );
  }
}
