import 'package:crm_task_manager/bloc/history_deal/deal_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_event.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_state.dart';
import 'package:crm_task_manager/models/deal_history_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActionHistoryWidget extends StatefulWidget {
  final int dealId;

  ActionHistoryWidget({required this.dealId});

  @override
  _ActionHistoryWidgetState createState() => _ActionHistoryWidgetState();
}

class _ActionHistoryWidgetState extends State<ActionHistoryWidget> {
  bool isActionHistoryExpanded = false;
  List<DealHistory> actionHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<DealHistoryBloc>().add(FetchDealHistory(widget.dealId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DealHistoryBloc, DealHistoryState>(
        builder: (context, state) {
      if (state is DealHistoryLoading) {
        // return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
      } else if (state is DealHistoryLoaded) {
        actionHistory = state.dealHistory;
      } else if (state is DealHistoryError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${state.message}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red,
            elevation: 3,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            duration: Duration(seconds: 3),
          ),
        );
      }

      return _buildExpandableActionContainer(
        'История действий',
        _buildActionHistoryItems(actionHistory),
        isActionHistoryExpanded,
        () {
          setState(() {
            isActionHistoryExpanded = !isActionHistoryExpanded;
          });
        },
      );
    });
  }

  Widget _buildExpandableActionContainer(
    String title,
    List<String> items,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(title),
            SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: isExpanded
                  ? SizedBox(
                      height: 250,
                      child: SingleChildScrollView(
                        child: _buildItemList(items),
                      ),
                    )
                  : SizedBox.shrink(),
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
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xfff1E2E52),
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
      children: items.map((item) {
        return _buildActionItem(item);
      }).toList(),
    );
  }

  Widget _buildActionItem(String item) {
    final parts = item.split('\n');
    final status = parts[0];
    final userName = parts.length > 1 ? parts[1] : '';

    final additionalDetails = [
      parts.length > 2 ? parts[2] : '',
      parts.length > 3 ? parts[3] : '',
      parts.length > 4 ? parts[4] : '',
      parts.length > 5 ? parts[5] : '',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(status, userName),
          SizedBox(height: 10),
          if (additionalDetails.any((detail) => detail.isNotEmpty))
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
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xfff1E2E52),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            userName,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xfff1E2E52),
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
                style: TextStyle(
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

  List<String> _buildActionHistoryItems(List<DealHistory> history) {
    return history.map((entry) {
      final changes = entry.changes;
      final formattedDate =
          DateFormat('dd-MM-yyyy HH:mm').format(entry.date.toLocal());
      String actionDetail =
          '${entry.status}\n${entry.user.name} $formattedDate';

      if (changes != null) {
        if (changes.positionNewValue != null &&
            changes.positionPreviousValue != null) {
          actionDetail +=
              '\nПозиция: ${changes.positionPreviousValue?.toString() ?? "Не указано"} > ${changes.positionNewValue?.toString() ?? "Не указано"}';
        }
        if (changes.dealStatusNewValue != null &&
            changes.dealStatusPreviousValue != null) {
          actionDetail +=
              '\nСтатус клиента: ${changes.dealStatusNewValue ?? "Не указано"} > ${changes.dealStatusPreviousValue ?? "Не указано"}';
        }
      }

      return actionDetail;
    }).toList();
  }
}
