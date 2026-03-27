import 'package:crm_task_manager/bloc/history_lead/history_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead/history_event.dart';
import 'package:crm_task_manager/bloc/history_lead/history_state.dart';
import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActionHistoryWidget extends StatefulWidget {
  final int leadId;

  const ActionHistoryWidget({required this.leadId, Key? key}) : super(key: key);

  @override
  _ActionHistoryWidgetState createState() => _ActionHistoryWidgetState();
}

class _ActionHistoryWidgetState extends State<ActionHistoryWidget> {
  bool isActionHistoryExpanded = false;
  List<LeadHistory> actionHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(FetchLeadHistory(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          // Можно показать лоадер
        } else if (state is HistoryLoaded) {
          actionHistory = state.leadHistory;
        } else if (state is HistoryError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.red,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }

        return _buildExpandableActionContainer(
          'История действий',
          _buildActionHistoryItems(actionHistory),
          isActionHistoryExpanded,
          () => setState(() => isActionHistoryExpanded = !isActionHistoryExpanded),
        );
      },
    );
  }

  // MARK: - Контейнер
  Widget _buildExpandableActionContainer(
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
          borderRadius: BorderRadius.circular(12),
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
      children: items.map((item) => _buildActionItem(item)).toList(),
    );
  }

  // MARK: - Элемент действия
  Widget _buildActionItem(String item) {
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff1E2E52),
                    ),
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
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            userAndDate,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // MARK: - Формирование строк
  List<String> _buildActionHistoryItems(List<LeadHistory> history) {
    return history.map((entry) {
      final userName = entry.user?.fullName ?? 'Система';
      final date = DateFormat('dd.MM.yyyy HH:mm').format(entry.date.toLocal());
      final header = '${entry.status}\n$userName $date';

      if (entry.changes.isEmpty) {
        return header;
      }

      final lines = <String>[];

      for (final change in entry.changes) {
        for (final MapEntry(:key, :value) in change.body.entries) {
          final prev = value.previousValue ?? '';
          final next = value.newValue ?? '';
          final field = _formatFieldName(key);

          final prevText = prev.isEmpty ? '—' : prev;
          final nextText = next.isEmpty ? '—' : next;

          lines.add('$field: $prevText → $nextText');
        }
      }

      return lines.isEmpty ? header : '$header\n${lines.join('\n')}';
    }).toList();
  }

  // MARK: - Названия полей
  String _formatFieldName(String key) {
    return switch (key) {
      'lead_status' => 'Статус',
      'name' => 'Имя',
      'phone' => 'Телефон',
      'email' => 'Email',
      'region' => 'Регион',
      'manager' => 'Менеджер',
      'tg_nick' => 'Telegram',
      'wa_name' => 'WhatsApp',
      'source' => 'Источник',
      'birthday' => 'День рождения',
      'city_id' => 'Область',
      'description' => 'Описание',
      'insta_login' => 'Instagram',
      'facebook_login' => 'Facebook',
      'Телефон' => 'Телефон',
      _ => key[0].toUpperCase() + key.substring(1).replaceAll('_', ' '),
    };
  }
}
