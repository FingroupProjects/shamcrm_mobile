// lib/screens/deal/tabBar/deal_details/dropdown_history.dart

import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_event.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_state.dart';
import 'package:crm_task_manager/models/deal_history_model.dart';

class ActionHistoryWidget extends StatefulWidget {
  final int dealId;

  const ActionHistoryWidget({Key? key, required this.dealId}) : super(key: key);

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
        if (state is DealHistoryLoaded) {
          actionHistory = state.dealHistory;
        } else if (state is DealHistoryError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.buttonPrimaryFg,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: context.appColors.error,
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }

        return _buildExpandableActionContainer(
          'История действий',
          _buildActionHistoryItems(actionHistory),
          isActionHistoryExpanded,
          () => setState(
              () => isActionHistoryExpanded = !isActionHistoryExpanded),
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
          color: context.appColors.surfacePrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.appColors.borderSubtle.withValues(alpha: 0.4),
          ),
          boxShadow: context.appShadows.card,
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
          style: context.appTextStyles.bodyLg.copyWith(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        Icon(
          isActionHistoryExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: context.appColors.iconPrimary,
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
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
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
            style: context.appTextStyles.bodyMd.copyWith(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            userAndDate,
            style: context.appTextStyles.bodyMd.copyWith(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: context.appColors.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // MARK: - Формирование истории
  List<String> _buildActionHistoryItems(List<DealHistory> history) {
    return history.map((item) {
      final userName = item.user?.fullName ?? 'Система';
      final date = DateFormat('dd.MM.yyyy HH:mm').format(item.date.toLocal());
      final header = '${item.status}\n$userName $date';

      if (item.changes.isEmpty) return header;

      final lines = <String>[];

      for (final change in item.changes) {
        for (final MapEntry(:key, :value) in change.body.entries) {
          if (value is! ChangeValue) continue;

          final prev = value.previousValue?.toString() ?? '';
          final next = value.newValue?.toString() ?? '';

          final prevText = prev.isEmpty ? '—' : prev;
          final nextText = next.isEmpty ? '—' : next;

          final field = _formatFieldName(key);

          // ✅ Для дат используем dd.MM.yyyy (кроме created_at и updated_at)
          if (key == 'start_date' ||
              key == 'end_date' ||
              key == 'status_update_date') {
            final prevDate = _formatDate(prev, withTime: false);
            final nextDate = _formatDate(next, withTime: false);
            lines.add('$field: $prevDate → $nextDate');
          } else if (key == 'created_at' || key == 'updated_at') {
            // ✅ Для "Создан" и "Изменен" оставляем с часами
            final prevDate = _formatDate(prev, withTime: true);
            final nextDate = _formatDate(next, withTime: true);
            lines.add('$field: $prevDate → $nextDate');
          } else {
            lines.add('$field: $prevText → $nextText');
          }
        }
      }

      return lines.isEmpty ? header : '$header\n${lines.join('\n')}';
    }).toList();
  }

  // MARK: - Названия полей
  String _formatFieldName(String key) {
    return switch (key) {
      'deal_status' => 'Статус сделки',
      'name' => 'Название',
      'lead' => 'Лид',
      'manager' => 'Менеджер',
      'start_date' => 'Дата начала',
      'end_date' => 'Дата завершения',
      'sum' => 'Сумма',
      'description' => 'Описание',
      'status_update_date' => 'Дата обновления статуса',
      'created_at' => 'Создан',
      'updated_at' => 'Изменен',
      _ => key[0].toUpperCase() + key.substring(1).replaceAll('_', ' '),
    };
  }

  // MARK: - Формат даты
  String _formatDate(String? dateStr, {bool withTime = false}) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;

    // ✅ Единый формат: dd.MM.yyyy или dd.MM.yyyy HH:mm
    return withTime
        ? DateFormat('dd.MM.yyyy HH:mm').format(date)
        : DateFormat('dd.MM.yyyy').format(date);
  }
}
