import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_event.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/task/history_model_task.dart';
import 'package:crm_task_manager/models/lead/lead_history_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActionHistoryWidgetTask extends StatefulWidget {
  final int taskId;

  const ActionHistoryWidgetTask({Key? key, required this.taskId})
      : super(key: key);

  @override
  _ActionHistoryWidgetState createState() => _ActionHistoryWidgetState();
}

class _ActionHistoryWidgetState extends State<ActionHistoryWidgetTask> {
  bool isActionHistoryExpanded = false;
  List<TaskHistory> actionHistory = [];

  Color _sectionBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? context.appColors.backgroundSecondary.withValues(alpha: 0.94)
        : context.appColors.surfacePrimary.withValues(alpha: 0.84);
  }

  BoxDecoration _sectionDecoration(BuildContext context) => BoxDecoration(
        color: _sectionBackground(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.adaptiveBorderOn(_sectionBackground(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      );

  @override
  void initState() {
    super.initState();
    context.read<HistoryBlocTask>().add(FetchTaskHistory(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBlocTask, HistoryStateTask>(
      builder: (context, state) {
        if (state is HistoryLoadedTask) {
          actionHistory = state.taskHistory;
        } else if (state is HistoryErrorTask) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          'История',
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
        padding:
            const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 10),
        decoration: _sectionDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(title),
            const SizedBox(height: 10),
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
    final sectionBackground = _sectionBackground(context);
    final primaryText = context.adaptiveForegroundOn(sectionBackground);
    final secondaryText = context.adaptiveHintOn(
      sectionBackground,
      lightAlpha: 0.82,
    );

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.history_rounded,
            size: 18,
            color: context.appColors.buttonPrimaryBg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          isActionHistoryExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: secondaryText,
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
    final sectionBackground = _sectionBackground(context);
    final dividerColor = context.adaptiveBorderOn(
      sectionBackground,
      lightAlpha: 0.08,
      darkAlpha: 0.4,
    );
    final detailTextColor = context.adaptiveHintOn(
      sectionBackground,
      lightAlpha: 0.82,
    );

    final parts = item.split('\n');
    final status = parts[0];
    final userAndDate = parts.length > 1 ? parts[1] : '';
    final details = parts.sublist(2).where((d) => d.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: dividerColor,
          ),
          const SizedBox(height: 10),
          _buildStatusRow(status, userAndDate),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: detailTextColor,
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
    final sectionBackground = _sectionBackground(context);
    final primaryText = context.adaptiveForegroundOn(sectionBackground);
    final secondaryText = context.adaptiveHintOn(
      sectionBackground,
      lightAlpha: 0.72,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            userAndDate,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: secondaryText,
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
  List<String> _buildActionHistoryItems(List<TaskHistory> history) {
    return history.map((entry) {
      final userName = entry.user.fullName;
      final date =
          DateFormat('dd.MM.yyyy HH:mm').format(entry.date.toLocal());
      final header = '${entry.status}\n$userName $date';

      if (entry.changes.isEmpty) return header;

      final lines = <String>[];

      for (final change in entry.changes) {
        for (final MapEntry(:key, :value) in change.body.entries) {
          if (value is! ChangeValue) continue;

          final prev = value.previousValue?.toString() ?? '';
          final next = value.newValue?.toString() ?? '';

          final prevText = prev.isEmpty ? '—' : prev;
          final nextText = next.isEmpty ? '—' : next;

          final field = _formatFieldName(key);

          if (key == 'from' || key == 'to') {
            final prevDate = _formatDate(prev);
            final nextDate = _formatDate(next);
            lines.add('$field: $prevDate → $nextDate');
          } else if (key == 'is_finished') {
            final prevBool = _formatBool(prev);
            final nextBool = _formatBool(next);
            lines.add('$field: $prevBool → $nextBool');
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
      'task_status' => 'Статус задачи',
      'name' => 'Название',
      'is_finished' => 'Завершающий этап',
      'from' => 'Дата начала',
      'to' => 'Дата завершения',
      'project' => 'Проект',
      'users' => 'Пользователи',
      'description' => 'Описание',
      _ => key[0].toUpperCase() + key.substring(1).replaceAll('_', ' '),
    };
  }

  // MARK: - Формат даты
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final date = DateTime.tryParse(dateStr);
    return date != null ? DateFormat('dd.MM.yyyy').format(date) : dateStr;
  }

  // MARK: - Формат bool
  String _formatBool(String? value) {
    if (value == null || value.isEmpty) return '—';
    return value.toLowerCase() == 'true' ? 'Да' : 'Нет';
  }
}
