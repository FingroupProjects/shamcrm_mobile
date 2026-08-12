import 'dart:convert';

import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_event.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_state.dart';
import 'package:crm_task_manager/models/lead/lead_history_model.dart';
import 'package:crm_task_manager/models/event/notice_history_model.dart';
import 'package:crm_task_manager/models/deal/deal_history_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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

  Color _primary(BuildContext context) =>
      context.appColors.textPrimary;
  Color _secondary(BuildContext context) =>
      context.appColors.textSecondary;
  Color _hint(BuildContext context) =>
      context.appColors.fieldHint;
  Color _border(BuildContext context) =>
      context.appColors.borderSubtle;
  Color _surface(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _surfaceAlt(BuildContext context) =>
      context.appColors.surfaceElevated;

  @override
  void initState() {
    super.initState();
    context.read<HistoryLeadsBloc>().add(FetchLeadHistory(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _border(context)),
      ),
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
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: _primary(context),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: _primary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return BlocBuilder<HistoryLeadsBloc, HistoryState>(
      builder: (context, state) {
        if (state is NoticeHistoryLoaded) {
          _noticeCount = state.history
              .fold(0, (sum, notice) => sum + notice.history.length);
        }

        final localizations = AppLocalizations.of(context)!;

        final eventsTabTitle = _noticeCount == 1
            ? localizations.translate('history_dialog_event')
            : _noticeCount > 1
                ? localizations.translate('history_dialog_events')
                : localizations.translate('history_dialog_events');

        return Container(
          decoration: BoxDecoration(
            color: _surfaceAlt(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border(context)),
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
              context
                  .read<HistoryLeadsBloc>()
                  .add(FetchLeadHistory(widget.leadId));
              break;
            case 1:
              context
                  .read<HistoryLeadsBloc>()
                  .add(FetchNoticeHistory(widget.leadId));
              break;
            case 2:
              context
                  .read<HistoryLeadsBloc>()
                  .add(FetchDealHistory(widget.leadId));
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: isSelected ? _primary(context) : _secondary(context),
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
        color: _surfaceAlt(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(context)),
      ),
      child: BlocBuilder<HistoryLeadsBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: context.appColors.buttonPrimaryBg,
              ),
            );
          } else if (state is HistoryError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: _secondary(context)),
              ),
            );
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
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: _hint(context),
          ),
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Маленькие экраны (меньше 360px)

    return SingleChildScrollView(
      child: Column(
        children: history.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == history.length - 1;

          return Column(
            children: [
              _buildLeadHistoryItem(item, isSmallScreen),
              // Добавляем разделитель только на маленьких экранах и не после последнего элемента
              if (isSmallScreen && !isLast)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    color: context.appColors.borderSubtle,
                    height: 1,
                    thickness: 1,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeadHistoryItem(LeadHistory item, [bool isSmallScreen = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceAlt(context),
          borderRadius: BorderRadius.circular(16),
          // Добавляем границу только на маленьких экранах
          border: isSmallScreen
              ? Border.all(
                  color: _border(context),
                  width: 1,
                )
              : Border.all(color: _border(context)),
        ),
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
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: _primary(context)),
                  ),
                ),
                Flexible(
                  child: Text(
                    '${item.user?.fullName ?? AppLocalizations.of(context)!.translate('system_text')}\n${_formatDate(item.date)}',
                    style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: _secondary(context)),
                    maxLines: 3,
                    softWrap: true,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (item.changes.isNotEmpty)
              ..._buildChanges(item.changes, _leadFieldNames),
          ],
        ),
      ),
    );
  }

  // MARK: - События
  Widget _buildNoticeHistoryContent(List<NoticeHistory> notices) {
    if (notices.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_data_to_display'),
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: _hint(context),
          ),
        ),
      );
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
                    isExpanded
                        ? expandedNoticeIds.remove(notice.id)
                        : expandedNoticeIds.add(notice.id);
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
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: _primary(context),
                          ),
                        ),
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: _hint(context)),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                ...notice.history.map((item) => _buildNoticeHistoryItem(item)),
              Divider(color: _border(context), height: 24),
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
        decoration: BoxDecoration(
          color: _screenCardBackground(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border(context)),
        ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: _primary(context),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '${item.user?.fullName ?? AppLocalizations.of(context)!.translate('system_text')}\n${_formatDate(item.date)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: _secondary(context),
                    ),
                    maxLines: 3,
                    softWrap: true,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (item.changes.isNotEmpty)
              ..._buildChanges(item.changes, _noticeFieldNames),
          ],
        ),
      ),
    );
  }

  // MARK: - Сделки
  Widget _buildDealHistoryContent(List<DealHistoryLead> deals) {
    if (deals.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_data_to_display'),
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: _hint(context),
          ),
        ),
      );
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
                    isExpanded
                        ? expandedDealIds.remove(deal.id)
                        : expandedDealIds.add(deal.id);
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
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: _primary(context),
                          ),
                        ),
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: _hint(context)),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                ...deal.history.map((item) => _buildDealHistoryItem(item)),
              Divider(color: _border(context), height: 24),
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
        decoration: BoxDecoration(
          color: _screenCardBackground(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border(context)),
        ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: _primary(context),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '${item.user?.fullName ?? AppLocalizations.of(context)!.translate('system_text')}\n${_formatDate(item.date)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: _secondary(context),
                    ),
                    maxLines: 3,
                    softWrap: true,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (item.changes.isNotEmpty)
              ..._buildChanges(item.changes, _dealFieldNames),
          ],
        ),
      ),
    );
  }

  // MARK: - Универсальные изменения
  List<Widget> _buildChanges(
      List<ChangeItem> changesList, Map<String, String> fieldNames) {
    final List<Widget> widgets = [];

    for (final change in changesList) {
      for (final MapEntry(key: key, value: ChangeValue changeValue)
          in change.body.entries) {
        final prev = changeValue.previousValue ?? '';
        final next = changeValue.newValue ?? '';
        final prevText = prev.isEmpty ? '—' : prev;
        final nextText = next.isEmpty ? '—' : next;

        final field = fieldNames[key] ??
            key[0].toUpperCase() + key.substring(1).replaceAll('_', ' ');

        String format(String text) {
          if (key == 'date' ||
              key.contains('date') ||
              key == 'from' ||
              key == 'to') {
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
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: _hint(context),
              ),
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
    'city_id': 'Область',
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

  Color _screenCardBackground() => _surface(context);

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
