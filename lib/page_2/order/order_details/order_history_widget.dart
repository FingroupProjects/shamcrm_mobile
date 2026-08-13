import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_state.dart';
import 'package:crm_task_manager/models/page_2/order_history_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

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
    final colors = context.appColors;
    return BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
      builder: (context, state) {
        if (state is OrderHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is OrderHistoryLoaded) {
          orderHistory = state.orderHistory;
        } else if (state is OrderHistoryError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style:  TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: colors.error,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }

        return _buildExpandableContainer(
          AppLocalizations.of(context)!.translate('order_history'),
          _buildHistoryItems(orderHistory),
        );
      },
    );
  }

  Widget _buildExpandableContainer(
      String title,
      List<String> items,
      ) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () {
        setState(() {
          isHistoryExpanded = !isHistoryExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 8),
        decoration: BoxDecoration(
          color: colors.surfaceAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitleRow(title),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              constraints: BoxConstraints(
                maxHeight: isHistoryExpanded ? 250 : 0,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.isNotEmpty
                      ? items.map((item) => _buildHistoryItem(item)).toList()
                      : [
                    Padding(
                      padding:  EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppLocalizations.of(context)!.translate('no_history_available'),
                        style:  TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        AnimatedRotation(
          turns: isHistoryExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: colors.iconSecondary,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusRow(status, userName),
          if (additionalDetails.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildAdditionalDetails(additionalDetails),
          ],
        ],
      ),
    );
  }

  Row _buildStatusRow(String status, String userName) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            status,
            style:  TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
            color: colors.success,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            userName,
            style:  TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
            color: colors.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Column _buildAdditionalDetails(List<String> details) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: details.where((detail) => detail.isNotEmpty).map((detail) {
        final parts = detail.split(':');
        final keyText = parts.isNotEmpty ? parts.first.trim() : detail;
        final valueText = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: RichText(
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: colors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: keyText,
                  style: TextStyle(
                    color: colors.buttonPrimaryBg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (valueText.isNotEmpty) ...[
                  TextSpan(
                    text: ': ',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  TextSpan(
                    text: valueText,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
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
          final newValue = value['new_value'] ?? AppLocalizations.of(context)!.translate('');
          final previousValue = value['previous_value'] ?? AppLocalizations.of(context)!.translate('');

          String translatedKey = key;
          String translatedNewValue = newValue.toString();
          String translatedPreviousValue = previousValue.toString();

          if (key == 'deliveryType') {
            translatedKey = AppLocalizations.of(context)!.translate('delivery_method');
            if (newValue == 'pickup') {
              translatedNewValue = AppLocalizations.of(context)!.translate('pickup');
            } else if (newValue == 'delivery') {
              translatedNewValue = AppLocalizations.of(context)!.translate('delivery');
            }
            if (previousValue == 'pickup') {
              translatedPreviousValue = AppLocalizations.of(context)!.translate('pickup');
            } else if (previousValue == 'delivery') {
              translatedPreviousValue = AppLocalizations.of(context)!.translate('delivery');
            }
          } else {
            translatedKey = AppLocalizations.of(context)!.translate(key);
          }

          actionDetail += '\n$translatedKey: $translatedPreviousValue > $translatedNewValue';
        });
      }

      return actionDetail;
    }).toList();
  }
}
