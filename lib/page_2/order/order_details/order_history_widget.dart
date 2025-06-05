import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_state.dart';
import 'package:crm_task_manager/models/page_2/order_history_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderHistoryWidget extends StatefulWidget {
  final int orderId;

  const OrderHistoryWidget({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderHistoryWidgetState createState() => _OrderHistoryWidgetState();
}

class _OrderHistoryWidgetState extends State<OrderHistoryWidget> {
  bool isHistoryExpanded = false;
  List<OrderHistory> orderHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<OrderHistoryBloc>().add(FetchOrderHistory(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
      builder: (context, state) {
        if (state is OrderHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is OrderHistoryLoaded) {
          orderHistory = state.orderHistory;
        } else if (state is OrderHistoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        return _buildExpandableContainer(
          AppLocalizations.of(context)!.translate('order_history'),
          _buildHistoryItems(orderHistory),
          isHistoryExpanded,
          () {
            setState(() {
              isHistoryExpanded = !isHistoryExpanded;
            });
          },
        );
      },
    );
  }

  Widget _buildExpandableContainer(
    String title,
    List<String> items,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(title),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: isExpanded
                  ? SizedBox(
                      height: 250,
                      child: SingleChildScrollView(
                        child: _buildItemList(items),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff1E2E52),
          ),
        ),
        Image.asset(
          'assets/icons/tabBar/dropdown.png',
          width: 16,
          height: 16,
        ),
      ],
    );
  }

  Column _buildItemList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.isNotEmpty
          ? items.map((item) {
              return _buildHistoryItem(item);
            }).toList()
          : [
              Text(
                AppLocalizations.of(context)!.translate('no_history_available'),
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff1E2E52),
                ),
              ),
            ],
    );
  }

  Widget _buildHistoryItem(String item) {
    final parts = item.split('\n');
    final status = parts[0];
    final userName = parts.length > 1 ? parts[1] : '';
    final additionalDetails = parts.sublist(2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(status, userName),
          const SizedBox(height: 10),
          if (additionalDetails.isNotEmpty)
            _buildAdditionalDetails(additionalDetails),
        ],
      ),
    );
  }

  Row _buildStatusRow(String status, String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            userName,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Column _buildAdditionalDetails(List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.where((detail) => detail.isNotEmpty).map((detail) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff1E2E52),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

List<String> _buildHistoryItems(List<OrderHistory> history) {
  return history.map((entry) {
    final changes = entry.changes;
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(entry.date.toLocal());
    String actionDetail = '${entry.status}\n${entry.user?.name ?? AppLocalizations.of(context)!.translate('unknown_user')} $formattedDate';

    if (changes != null && changes.body != null) {
      changes.body!.forEach((key, value) {
        final newValue = value['new_value'] ?? AppLocalizations.of(context)!.translate('not_specified');
        final previousValue = value['previous_value'] ?? AppLocalizations.of(context)!.translate('not_specified');

        // Перевод для deliveryType
        String translatedKey = key;
        String translatedNewValue = newValue.toString();
        String translatedPreviousValue = previousValue.toString();

        if (key == 'deliveryType') {
          translatedKey = AppLocalizations.of(context)!.translate('delivery_method'); // Способ доставки
          if (newValue == 'pickup') {
            translatedNewValue = AppLocalizations.of(context)!.translate('pickup'); // Самовывоз
          } else if (newValue == 'delivery') {
            translatedNewValue = AppLocalizations.of(context)!.translate('delivery'); // Курьер
          }
          if (previousValue == 'pickup') {
            translatedPreviousValue = AppLocalizations.of(context)!.translate('pickup'); // Самовывоз
          } else if (previousValue == 'delivery') {
            translatedPreviousValue = AppLocalizations.of(context)!.translate('delivery'); // Курьер
          }
        } else {
          translatedKey = AppLocalizations.of(context)!.translate(key); // Другие ключи
        }

        actionDetail += '\n$translatedKey: $translatedPreviousValue > $translatedNewValue';
      });
    }

    return actionDetail;
  }).toList();
}
}