import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_bloc.dart';
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_event.dart';
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/task/task_overdue_history_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TaskHistoryDialog extends StatefulWidget {
  final int taskId;
  const TaskHistoryDialog({Key? key, required this.taskId}) : super(key: key);

  @override
  _TaskHistoryDialogState createState() => _TaskHistoryDialogState();
}

class _TaskHistoryDialogState extends State<TaskHistoryDialog> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _dialogSurface => _isDark
      ? context.appColors.backgroundSecondary.withValues(alpha: 0.96)
      : context.appColors.surfacePrimary;

  Color get _dialogBorder => context.adaptiveBorderOn(_dialogSurface);

  Color get _dialogPrimaryText => context.adaptiveForegroundOn(_dialogSurface);

  Color get _dialogSecondaryText =>
      context.adaptiveHintOn(_dialogSurface, lightAlpha: 0.72);

  @override
  void initState() {
    super.initState();
    context
        .read<TaskOverdueHistoryBloc>()
        .add(FetchTaskOverdueHistory(widget.taskId));
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _dialogSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _dialogBorder),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
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
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.translate('execution_history'),
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: _dialogPrimaryText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.close, color: _dialogPrimaryText, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return _buildOverdueHistory();
  }

  // ✨ КРАСИВАЯ История выполнения
  Widget _buildOverdueHistory() {
    return BlocBuilder<TaskOverdueHistoryBloc, TaskOverdueHistoryState>(
      builder: (context, state) {
        if (state is TaskOverdueHistoryLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: context.appColors.buttonPrimaryBg,
            ),
          );
        } else if (state is TaskOverdueHistoryLoaded) {
          if (state.history.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: state.history.length,
            itemBuilder: (context, index) {
              return _buildOverdueHistoryItem(state.history[index]);
            },
          );
        } else if (state is TaskOverdueHistoryError) {
          return _buildEmptyState();
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ✨ КОМПАКТНЫЙ и красивый дизайн как в веб-версии
  Widget _buildOverdueHistoryItem(TaskOverdueHistoryItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline линия слева
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getBorderColorForType(item.type),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 80,
              color: _dialogBorder,
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Карточка
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _getBackgroundColorForType(item.type),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColorForType(item.type).withValues(alpha: 0.32),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок и дата
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTypeTitle(item.type),
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: _getTextColorForType(item.type),
                      ),
                    ),
                    Text(
                      _formatDateTimeCompact(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        color: _getTextColorForType(item.type)
                            .withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
                // Детали
                if (item.body != null) ...[
                  const SizedBox(height: 10),
                  _buildBodyInfoCompact(item.body!, item.type),
                ],
                // Автор
                if (item.author != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Кто изменил: ${item.author!.fullName}',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      color: _getTextColorForType(item.type)
                          .withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyInfoCompact(HistoryBody body, String type) {
    final textColor = _getTextColorForType(type).withValues(alpha: 0.92);
    final items = <String>[];

    if (body.fromDate != null && body.toDate != null) {
      items.add('С: ${_formatDateShort(body.fromDate!)}');
      items.add('До: ${_formatDateShort(body.toDate!)}');
    }

    if (body.overdueDays != null) {
      items.add('Просрочено дней: ${body.overdueDays}');
    }

    if (body.workingHours != null) {
      items.add('Время выполнения: ${body.workingHours}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Gilroy',
                    color: textColor,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // Цветовая схема - чистая и компактная
  Color _getBackgroundColorForType(String type) {
    if (_isDark) {
      switch (type) {
        case 'overdue':
          return const Color(0xFF3A1618);
        case 'finished':
          return const Color(0xFF0F2F25);
        case 'change_deadline':
          return const Color(0xFF102A36);
        default:
          return context.appColors.surfaceElevated.withValues(alpha: 0.86);
      }
    }

    switch (type) {
      case 'overdue':
        return const Color(0xFFFEF2F2);
      case 'finished':
        return const Color(0xFFF0FDF4);
      case 'change_deadline':
        return const Color(0xFFF0F9FF);
      default:
        return const Color(0xFFF9FAFB);
    }
  }

  Color _getBorderColorForType(String type) {
    switch (type) {
      case 'overdue':
        return const Color(0xFFDC2626);
      case 'finished':
        return const Color(0xFF059669);
      case 'change_deadline':
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getTextColorForType(String type) {
    switch (type) {
      case 'overdue':
        return const Color(0xFFDC2626);
      case 'finished':
        return const Color(0xFF059669);
      case 'change_deadline':
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF1F2937);
    }
  }

  String _getTypeTitle(String type) {
    switch (type) {
      case 'overdue':
        return 'Просрочено';
      case 'finished':
        return 'Завершено';
      case 'change_deadline':
        return 'Изменён срок';
      default:
        return 'Действие';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.translate('no_data'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: _dialogSecondaryText,
        ),
      ),
    );
  }

  String _formatDateTimeCompact(String dateTime) {
    try {
      final DateTime parsed = DateTime.parse(dateTime);
      return DateFormat('dd.MM.yyyy HH:mm').format(parsed);
    } catch (e) {
      return dateTime;
    }
  }

  String _formatDateShort(String date) {
    try {
      final DateTime parsed = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }
}
