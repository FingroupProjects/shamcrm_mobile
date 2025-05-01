import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_edits.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_good_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_history_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final String categoryName;
  final Order order;
  final int? organizationId;

  const OrderDetailsScreen({
    required this.orderId,
    required this.order,
    required this.categoryName,
    this.organizationId,
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
        : AppLocalizations.of(context)!.translate('not_specified');

    details = [
      {
        'label': AppLocalizations.of(context)!.translate('order_number'),
        'value': order.orderNumber
      },
      {
        'label': AppLocalizations.of(context)!.translate('client'),
        'value': order.lead.name
      },
      {
        'label': AppLocalizations.of(context)!.translate('client_phone'),
        'value': order.phone
      },
      {
        'label': AppLocalizations.of(context)!.translate('order_date'),
        'value': formattedDate
      },
      {
        'label': AppLocalizations.of(context)!.translate('order_status'),
        'value': order.orderStatus.name
      },
      if (order.deliveryAddress != null)
        {
          'label': AppLocalizations.of(context)!.translate('order_address'),
          'value': order.deliveryAddress ??
              AppLocalizations.of(context)!.translate('not_specified')
        },
      {
        'label': AppLocalizations.of(context)!.translate('comment_client'),
        'value': order.commentToCourier ??
            AppLocalizations.of(context)!.translate('no_comment')
      },
      {
        'label': AppLocalizations.of(context)!.translate('price'),
        'value': order.sum != null && order.sum! > 0
            ? '${order.sum!.toStringAsFixed(3)} ${AppLocalizations.of(context)!.translate('currency')}'
            : AppLocalizations.of(context)!.translate('0')
      },
    ];
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: Text(
                    AppLocalizations.of(context)!.translate('close'),
                    style: const TextStyle(
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

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.translate('order_history'),
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
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BlocProvider(
                  create: (context) => OrderHistoryBloc(context.read<ApiService>())
                    ..add(FetchOrderHistory(widget.orderId)),
                  child: OrderHistoryWidget(orderId: widget.orderId),
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
                  child: Text(
                    AppLocalizations.of(context)!.translate('close'),
                    style: const TextStyle(
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderHistoryBloc>(
          create: (context) => OrderHistoryBloc(context.read<ApiService>()),
        ),
      ],
      child: BlocBuilder<OrderBloc, OrderState>(
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
                    ),
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
      ),
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
        '${AppLocalizations.of(context)!.translate('order_title')} #${order.orderNumber}',
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
          onPressed: _showHistoryDialog,
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
                builder: (context) => OrderEditScreen(order: order),
              ),
            );
            if (updatedOrder != null) {
              context.read<OrderBloc>().add(FetchOrderDetails(widget.orderId));
            }
          },
        ),
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
    if (label == AppLocalizations.of(context)!.translate('order_address') ||
        label == AppLocalizations.of(context)!.translate('comment_client')) {
      return GestureDetector(
        onTap: () {
          if (value.isNotEmpty &&
              value != AppLocalizations.of(context)!.translate('no_comment')) {
            _showFullTextDialog(label.replaceAll(':', ''), value);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff1E2E52),
                  decoration: value.isNotEmpty &&
                          value !=
                              AppLocalizations.of(context)!
                                  .translate('no_comment')
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
        const SizedBox(width: 8),
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