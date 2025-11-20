import 'dart:convert';

import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_event.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_state.dart';
import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:crm_task_manager/models/notice_history_model.dart';
import 'package:crm_task_manager/models/deal_history_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class HistoryDialog extends StatefulWidget {
  final int leadId;
  const HistoryDialog({Key? key, required this.leadId}) : super(key: key);

  @override
  _HistoryDialogState createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  int _selectedTab = 0;
  final Set<int> expandedNoticeIds = {};
  final Set<int> expandedDealIds = {};
  int _noticeCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<HistoryLeadsBloc>().add(FetchLeadHistory(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('history'),
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xff1E2E52)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return BlocBuilder<HistoryLeadsBloc, HistoryState>(
      builder: (context, state) {
        if (state is NoticeHistoryLoaded) {
          _noticeCount = state.history.fold(0, (sum, notice) => sum + notice.history.length);
        }

        final localizations = AppLocalizations.of(context)!;

        final eventsTabTitle = _noticeCount == 1
            ? localizations.translate('history_dialog_event')
            : _noticeCount > 1
            ? localizations.translate('history_dialog_events')
            : localizations.translate('history_dialog_events');

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildTab(localizations.translate('tab_lead'), 0),
              _buildTab(eventsTabTitle, 1),
              _buildTab(localizations.translate('deals'), 2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          switch (index) {
            case 0:
              context.read<HistoryLeadsBloc>().add(FetchLeadHistory(widget.leadId));
              break;
            case 1:
              context.read<HistoryLeadsBloc>().add(FetchNoticeHistory(widget.leadId));
              break;
            case 2:
              context.read<HistoryLeadsBloc>().add(FetchDealHistory(widget.leadId));
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xff1E2E52),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: BlocBuilder<HistoryLeadsBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is HistoryError) {
            return Center(child: Text(state.message));
          } else if (state is LeadHistoryLoaded) {
            return _buildLeadHistoryContent(state.history);
          } else if (state is NoticeHistoryLoaded) {
            return _buildNoticeHistoryContent(state.history);
          } else if (state is DealHistoryLoaded) {
            return _buildDealHistoryContent(state.history);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // MARK: - Лид
  Widget _buildLeadHistoryContent(List<LeadHistory> history) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_data_to_display'),
          style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: Color(0xff8F9BB3)),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: history.map((item) => _buildLeadHistoryItem(item)).toList(),
      ),
    );
  }

  Widget _buildLeadHistoryItem(LeadHistory item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF4F7FD), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.status,
                    style: const TextStyle(fontSize: 16, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xFF1E2E52)),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    '${item.user?.fullName ?? AppLocalizations.of(context)!.translate('system_text')} ${_formatDate(item.date)}',
                    style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xFF1E2E52)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (item.changes.isNotEmpty) ..._buildChanges(item.changes, _leadFieldNames),
          ],
        ),
      ),
    );
  }

  // MARK: - События
  Widget _buildNoticeHistoryContent(List<NoticeHistory> notices) {
    if (notices.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.translate('no_data_to_display'), style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: Color(0xff8F9BB3))));
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notices.map((notice) {
          final isExpanded = expandedNoticeIds.contains(notice.id);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded ? expandedNoticeIds.remove(notice.id) : expandedNoticeIds.add(notice.id);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notice.title,
                          style: const TextStyle(fontSize: 16, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xff1E2E52)),
                        ),
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xff8F9BB3)),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...notice.history.map((item) => _buildNoticeHistoryItem(item)).toList(),
              const Divider(color: Color(0xFFE0E0E0), height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoticeHistoryItem(HistoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF4F7FD), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.status,
                    style: const TextStyle(fontSize: 16, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xFF1E2E52)),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    '${item.user?.fullName ?? AppLocalizations.of(context)!.translate('system_text')} ${_formatDate(item.date)}',
                    style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xFF1E2E52)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (item.changes.isNotEmpty) ..._buildChanges(item.changes, _noticeFieldNames),
          ],
        ),
      ),
    );
  }

  // MARK: - Сделки
  Widget _buildDealHistoryContent(List<DealHistoryLead> deals) {
    if (deals.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.translate('no_data_to_display'), style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w500, color: Color(0xff8F9BB3))));
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: deals.map((deal) {
          final isExpanded = expandedDealIds.contains(deal.id);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded ? expandedDealIds.remove(deal.id) : expandedDealIds.add(deal.id);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          deal.title,
                          style: const TextStyle(fontSize: 16, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xff1E2E52)),
                        ),
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xff8F9BB3)),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...deal.history.map((item) => _buildDealHistoryItem(item)).toList(),
              const Divider(color: Color(0xFFE0E0E0), height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDealHistoryItem(HistoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF4F7FD), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.status,
                    style: const TextStyle(fontSize: 16, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xFF1E2E52)),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    '${item.user?.fullName ?? AppLocalizations.of(context)!.translate('system_text')} ${_formatDate(item.date)}',
                    style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w600, color: Color(0xFF1E2E52)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (item.changes.isNotEmpty) ..._buildChanges(item.changes, _dealFieldNames),
          ],
        ),
      ),
    );
  }

  // MARK: - Универсальные изменения
  List<Widget> _buildChanges(List<ChangeItem> changesList, Map<String, String> fieldNames) {
    final List<Widget> widgets = [];

    for (final change in changesList) {
      for (final MapEntry(key: key, value: ChangeValue changeValue) in change.body.entries) {
        final prev = changeValue.previousValue ?? '';
        final next = changeValue.newValue ?? '';
        final prevText = prev.isEmpty ? '—' : prev;
        final nextText = next.isEmpty ? '—' : next;

        final field = fieldNames[key] ?? key[0].toUpperCase() + key.substring(1).replaceAll('_', ' ');

        String format(String text) {
          if (key == 'date' || key.contains('date') || key == 'from' || key == 'to') {
            return _formatDateTime(text);
          }
          if (key == 'notifications_sent') {
            return _parseNotifications(text);
          }
          return text;
        }

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$field: ${format(prevText)} → ${format(nextText)}',
              style: const TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w400, color: Color(0xff8F9BB3)),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  // MARK: - Названия полей
  static const Map<String, String> _leadFieldNames = {
    'lead_status': 'Статус',
    'name': 'Название',
    'phone': 'Телефон',
    'email': 'Email',
    'region': 'Регион',
    'manager': 'Менеджер',
    'tg_nick': 'Telegram',
    'birthday': 'День рождения',
    'description': 'Описание',
    'insta_login': 'Instagram',
    'facebook_login': 'Facebook',
  };

  static const Map<String, String> _noticeFieldNames = {
    'title': 'Тематика',
    'body': 'Описание',
    'date': 'Напоминание',
    'notifications_sent': 'Уведомления',
    'conclusion': 'Заключение',
    'Send notification': 'Отправлены уведомления',
  };

  static const Map<String, String> _dealFieldNames = {
    'deal_status': 'Статус сделки',
    'name': 'Название',
    'lead': 'Лид',
    'manager': 'Менеджер',
    'start_date': 'Дата начала',
    'end_date': 'Дата завершения',
    'sum': 'Сумма',
    'description': 'Описание',
  };

  // MARK: - Формат даты
  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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