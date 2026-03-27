import 'dart:convert';
import 'package:crm_task_manager/models/lead_history_model.dart';
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
        final items = state is NoticeHistoryLoaded
            ? _buildNoticeHistoryItems(state.history, widget.noteId)
            : <String>[];

        return _buildExpandableNoticeContainer(
          'История событий',
          items,
          isExpanded,
          () => setState(() => isExpanded = !isExpanded),
        );
      },
    );
  }

  Widget _buildExpandableNoticeContainer(String title, List<String> items, bool isExpanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 8),
        decoration: BoxDecoration(color: const Color(0xFFF4F7FD), borderRadius: BorderRadius.circular(8)),
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
                      child: SingleChildScrollView(child: _buildItemList(items)),
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
        Text(title, style: const TextStyle(fontSize: 16, fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: Color(0xff1E2E52))),
        Image.asset('assets/icons/tabBar/dropdown.png', width: 16, height: 16),
      ],
    );
  }

  Column _buildItemList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => _buildNoticeItem(item)).toList(),
    );
  }

  Widget _buildNoticeItem(String item) {
    final parts = item.split('\n');
    final status = parts[0];
    final userAndDate = parts.length > 1 ? parts[1] : '';
    final details = parts.sublist(2).where((d) => d.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(status, userAndDate),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    d,
                    style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w400, color: Color(0xff1E2E52)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Row _buildStatusRow(String status, String userAndDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(status, style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xff1E2E52)), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(userAndDate, style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xff1E2E52)), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
        ),
      ],
    );
  }

  List<String> _buildNoticeHistoryItems(List<NoticeHistory> history, int noteId) {
    final target = history.firstWhere((n) => n.id == noteId, orElse: () => NoticeHistory(id: 0, title: '', history: []));
    if (target.id == 0) return [];

    return target.history.map((item) {
      final userName = item.user?.fullName ?? 'Система';
      final date = DateFormat('dd.MM.yyyy HH:mm').format(item.date.toLocal());
      final header = '${item.status}\n$userName $date';

      if (item.changes.isEmpty) return header;

      final lines = <String>[];

      for (final change in item.changes) {
        for (final MapEntry(:key, :value) in change.body.entries) {
          if (value is! Map<String, dynamic>) continue;

                     if (value is! ChangeValue) continue;

            final prev = value.previousValue?.toString() ?? '';
            final next = value.newValue?.toString() ?? '';

          final prevText = prev.isEmpty ? '—' : prev;
          final nextText = next.isEmpty ? '—' : next;

          final field = _formatFieldName(key);

          if (key == 'notifications_sent') {
            final prevNotif = _parseNotifications(prev);
            final nextNotif = _parseNotifications(next);
            if (prevNotif != nextNotif) {
              lines.add('$field: $prevNotif → $nextNotif');
            }
          } else if (key == 'date' || key == 'Дата') {
            final prevDate = _formatDateTime(prev);
            final nextDate = _formatDateTime(next);
            lines.add('$field: $prevDate → $nextDate');
          } else {
            lines.add('$field: $prevText → $nextText');
          }
        }
      }

      return lines.isEmpty ? header : '$header\n${lines.join('\n')}';
    }).toList();
  }

  String _formatFieldName(String key) {
    return switch (key) {
      'title' => 'Тематика',
      'body' => 'Описание',
      'date' => 'Напоминание',
      'Дата' => 'Напоминание',
      'notifications_sent' => 'Уведомления',
      _ => key[0].toUpperCase() + key.substring(1).replaceAll('_', ' '),
    };
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final date = DateTime.tryParse(dateStr);
    return date != null ? DateFormat('dd.MM.yyyy HH:mm').format(date) : dateStr;
  }

  String _parseNotifications(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty || jsonStr == '[]') return '—';
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((n) {
        return switch (n) {
          'morning_reminder' => 'утреннее напоминание',
          'two_hours_before' => 'за два часа',
          _ => n.toString(),
        };
      }).join(', ');
    } catch (e) {
      return jsonStr;
    }
  }
}
