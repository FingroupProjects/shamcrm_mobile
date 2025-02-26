import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_event.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_state.dart';
import 'package:crm_task_manager/models/notice_history_model.dart';
import 'package:intl/intl.dart';

class NoticeHistorySection extends StatefulWidget {
  final int leadId;
  final int noteId; 

  const NoticeHistorySection({Key? key, required this.leadId, required this.noteId}) : super(key: key);

  @override
  _NoticeHistorySectionState createState() => _NoticeHistorySectionState();
}
class _NoticeHistorySectionState extends State<NoticeHistorySection> {
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<HistoryLeadsBloc>().add(FetchNoticeHistory(widget.leadId));
  }

@override
Widget build(BuildContext context) {
  return BlocBuilder<HistoryLeadsBloc, HistoryState>(
    builder: (context, state) {
      return _buildExpandableNoticeContainer(
        'История заметок',
        state is NoticeHistoryLoaded ? _buildNoticeHistoryItems(state.history, widget.noteId) : [],
        isExpanded,
        () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
      );
    },
  );
}

Widget _buildExpandableNoticeContainer(
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
        return _buildNoticeItem(item);
      }).toList(),
    );
  }

  Widget _buildNoticeItem(String item) {
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
          SizedBox(height: 10),
          if (additionalDetails.isNotEmpty) _buildAdditionalDetails(additionalDetails),
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
List<String> _buildNoticeHistoryItems(List<NoticeHistory> history, int noteId) {
  return history.expand((entry) {
    if (entry.id == noteId) {
      return entry.history.map((historyItem) {
        final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(historyItem.date.toLocal());
        String actionDetail = '${historyItem.status}\n${historyItem.user?.name ?? "Unknown"} $formattedDate';

        if (historyItem.changes.isNotEmpty) {
          for (var change in historyItem.changes) {
            if (change.body.isNotEmpty && change.body is Map) {
              change.body.forEach((key, value) {
                if (value is Map) {
                  if (key == "notifications_sent") {
                    actionDetail += '\nУведомления: ${_parseNotifications(value["new_value"])}';
                    if (value["previous_value"] != null) {
                      actionDetail += '\nПредыдущие уведомления: ${_parseNotifications(value["previous_value"])}';
                    }
                  } else if (key == "title") {
                    actionDetail += '\nТематика: ${value["previous_value"]} > ${value["new_value"]}';
                  } else if (key == "date") {
                    DateTime previousDate = DateTime.parse(value["previous_value"]);
                    DateTime newDate = DateTime.parse(value["new_value"]);
                    String formattedPreviousDate = DateFormat('dd.MM.yyyy HH:mm').format(previousDate);
                    String formattedNewDate = DateFormat('dd.MM.yyyy HH:mm').format(newDate);

                    actionDetail += '\nНапоминание: $formattedPreviousDate > $formattedNewDate';
                  } else if (key == "lead") {
                    actionDetail += '\nЛид: ${value["previous_value"]} > ${value["new_value"]}';
                  } else if (key == "body") {
                    actionDetail += '\nОписание: ${value["previous_value"]} > ${value["new_value"]}';
                  } else {
                    // actionDetail += '\nИзменения по $key: Новое значение: ${value["new_value"]}, Предыдущее значение: ${value["previous_value"]}';
                  }
                }
              });
            } else {
              // actionDetail += '\nИзменения: ${change.body}';
            }
          }
        }

        return actionDetail;
      });
    } else {
      return <String>[];
    }
  }).toList();
}

String _parseNotifications(dynamic notifications) {
  if (notifications is String) {
    try {
      List<dynamic> parsed = jsonDecode(notifications);
      return parsed.map((n) {
        switch (n) {
          case "morning_reminder":
            return "утреннее напоминание";
          default:
            return n;
        }
      }).join(", ");
    } catch (e) {
      return notifications;
    }
  }
  return notifications.toString();
}
}