import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_event.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/models/notice_history_model.dart';

class NoticeHistorySection extends StatefulWidget {
  final int leadId;

  const NoticeHistorySection({Key? key, required this.leadId})
      : super(key: key);

  @override
  _NoticeHistorySectionState createState() => _NoticeHistorySectionState();
}

class _NoticeHistorySectionState extends State<NoticeHistorySection> {
  Set<int> expandedNoticeIds = {};
  bool isContainerExpanded = false; // Переместите это сюда

  @override
  void initState() {
    super.initState();
    context.read<HistoryLeadsBloc>().add(FetchNoticeHistory(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryLeadsBloc, HistoryState>(
      builder: (context, state) {
        if (state is NoticeHistoryLoaded) {
          return _buildNoticeHistoryContent(state.history);
        } else if (state is HistoryLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52))
              );
        } else if (state is HistoryError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildNoticeHistoryContent(List<NoticeHistory> notices) {
    if (notices.isEmpty) {
      return Center(
        child: Text(
          'Нет данных для отображения',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff8F9BB3),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isContainerExpanded = !isContainerExpanded;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'История заметок',
                      style: TextStyle(
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
                ),
              ),
            ),
          ),
          if (isContainerExpanded) // Проверяйте состояние здесь
            ...notices.map((notice) {
              final bool isExpanded = expandedNoticeIds.contains(notice.id);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedNoticeIds.remove(notice.id);
                        } else {
                          expandedNoticeIds.add(notice.id);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FD),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Color(0xff1E2E52),
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/icons/tabBar/dropdown.png',
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    ...notice.history
                        .map((item) => _buildNoticeHistoryItem(item))
                        .toList(),
                  ],
                  SizedBox(height: 8),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildNoticeHistoryItem(HistoryItem item) {
    return Container(
      color: const Color(0xFFF4F7FD),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(item.date),
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff8F9BB3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.user.name,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
              if (item.changes.isNotEmpty)
                ..._buildNoticeChanges(item.changes.first),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNoticeChanges(ChangesLead changes) {
    final Map<String, dynamic> body = changes.body;
    if (body.isEmpty) return [];

    final Map<String, String> translations = {
      'body': 'Описание',
      'date': 'Напоминание',
      'lead': 'Лид',
      'title': 'Тематика',
      'notifications_sent': 'Отправить PUSH-уведомление',
    };

    String formatDateIfNeeded(String key, dynamic value) {
      if (key == 'date' && value != null && value.toString().isNotEmpty) {
        try {
          DateTime date;
          String dateStr = value.toString();

          if (dateStr.contains('T')) {
            date = DateTime.parse(dateStr);
          } else {
            date = DateTime.parse(dateStr);
          }

          return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          return value.toString();
        }
      }
      return value?.toString() ?? 'Не указано';
    }

    return body.entries.map((entry) {
      if (entry.value is Map) {
        final changeMap = Map.from(entry.value as Map);
        final String translatedKey = translations[entry.key] ?? entry.key;

        final formattedPreviousValue =
            formatDateIfNeeded(entry.key, changeMap['previous_value']);
        final formattedNewValue =
            formatDateIfNeeded(entry.key, changeMap['new_value']);

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$translatedKey: $formattedPreviousValue → $formattedNewValue',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w400,
              color: Color(0xff8F9BB3),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
