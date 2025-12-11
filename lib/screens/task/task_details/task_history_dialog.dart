import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_event.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_state.dart';
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_bloc.dart';
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_event.dart';
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_state.dart';
import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:crm_task_manager/models/task_overdue_history_model.dart';
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
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    context.read<HistoryBlocTask>().add(FetchTaskHistory(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTabs(),
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
        Text(
          AppLocalizations.of(context)!.translate('history'),
          style: const TextStyle(
            fontSize: 22,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            color: Color(0xff1E2E52),
          ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, color: Color(0xff1E2E52), size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab('История действий', 0),
          _buildTab('История выполнения', 1),
        ],
      ),
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
              context.read<HistoryBlocTask>().add(FetchTaskHistory(widget.taskId));
              break;
            case 1:
              context.read<TaskOverdueHistoryBloc>().add(FetchTaskOverdueHistory(widget.taskId));
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xff1E2E52) : const Color(0xff9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab == 0) {
      return _buildActionHistory();
    } else {
      return _buildOverdueHistory();
    }
  }

  // История действий (существующая)
  Widget _buildActionHistory() {
    return BlocBuilder<HistoryBlocTask, HistoryStateTask>(
      builder: (context, state) {
        if (state is HistoryLoadingTask) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xff1E2E52),
            ),
          );
        } else if (state is HistoryLoadedTask) {
          if (state.taskHistory.isEmpty) {
            return _buildEmptyState('История действий пуста');
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: state.taskHistory.length,
            itemBuilder: (context, index) {
              return _buildActionHistoryItem(state.taskHistory[index]);
            },
          );
        } else if (state is HistoryErrorTask) {
          return _buildErrorState(state.message);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActionHistoryItem(TaskHistory history) {
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
                color: const Color(0xff1E2E52),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 70,
              color: const Color(0xFFE5E7EB),
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
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Статус и дата
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _translateStatus(history.status),
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1F2937),
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(history.date),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        color: Color(0xff9CA3AF),
                      ),
                    ),
                  ],
                ),
                // Изменения
                if (history.changes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...history.changes.expand((change) {
                    return change.body.entries.map((entry) {
                      final changeValue = entry.value;
                      final fieldName = _translateFieldName(entry.key);
                      final from = changeValue.previousValue ?? '-';
                      final to = changeValue.newValue ?? '-';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$fieldName: $from → $to',
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            color: Color(0xff6B7280),
                          ),
                        ),
                      );
                    });
                  }),
                ],
                // Автор
                const SizedBox(height: 8),
                Text(
                  'Автор: ${history.user.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    color: Color(0xff9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _translateFieldName(String field) {
    // Переводы полей - все возможные поля задач
    final translations = {
      // Основные поля
      'name': 'Название',
      'title': 'Заголовок',
      'description': 'Описание',
      'deadline': 'Дедлайн',
      'end_date': 'Дата окончания',
      'start_date': 'Дата начала',
      'status': 'Статус',
      'task_status': 'Статус задачи',
      'priority': 'Приоритет',
      'project': 'Проект',
      'project_id': 'Проект',
      
      // Исполнители
      'user': 'Исполнитель',
      'users': 'Исполнители',
      'author': 'Автор',
      'assignee': 'Назначено',
      'responsible': 'Ответственный',
      'executor': 'Исполнитель',
      'performer': 'Исполнитель',
      
      // Даты
      'to': 'До',
      'from': 'С',
      'created_at': 'Дата создания',
      'updated_at': 'Дата обновления',
      'completed_at': 'Дата завершения',
      'deleted_at': 'Дата удаления',
      'started_at': 'Дата начала',
      'finished_at': 'Дата окончания',
      'due_date': 'Срок выполнения',
      
      // Отсрочки и время
      'number_of_deferments': 'Количество отсрочек',
      'number_of_defeeerments': 'Количество отсрочек',
      'deferment': 'Отсрочка',
      'postponed': 'Отложено',
      'duration': 'Длительность',
      'time_spent': 'Затраченное время',
      'estimated_time': 'Планируемое время',
      
      // Финансы
      'sum': 'Сумма',
      'amount': 'Сумма',
      'cost': 'Стоимость',
      'price': 'Цена',
      'budget': 'Бюджет',
      
      // Коммуникации
      'comment': 'Комментарий',
      'comments': 'Комментарии',
      'note': 'Заметка',
      'notes': 'Заметки',
      'message': 'Сообщение',
      
      // Файлы
      'file': 'Файл',
      'files': 'Файлы',
      'attachment': 'Вложение',
      'attachments': 'Вложения',
      'document': 'Документ',
      'documents': 'Документы',
      
      // Метки и категории
      'tag': 'Тег',
      'tags': 'Теги',
      'label': 'Метка',
      'labels': 'Метки',
      'category': 'Категория',
      'type': 'Тип',
      
      // Организация
      'department': 'Отдел',
      'team': 'Команда',
      'group': 'Группа',
      'organization': 'Организация',
      'division': 'Подразделение',
      
      // Люди
      'manager': 'Менеджер',
      'client': 'Клиент',
      'customer': 'Заказчик',
      'company': 'Компания',
      'contact': 'Контакт',
      'contacts': 'Контакты',
      
      // Контакты
      'phone': 'Телефон',
      'email': 'Email',
      'address': 'Адрес',
      'website': 'Веб-сайт',
      
      // Уведомления
      'reminder': 'Напоминание',
      'reminders': 'Напоминания',
      'notification': 'Уведомление',
      'notifications': 'Уведомления',
      'alert': 'Оповещение',
      
      // Дополнительные поля
      'importance': 'Важность',
      'urgency': 'Срочность',
      'progress': 'Прогресс',
      'percentage': 'Процент выполнения',
      'result': 'Результат',
      'outcome': 'Итог',
      'reason': 'Причина',
      'details': 'Детали',
      'info': 'Информация',
      'reference': 'Ссылка',
      'link': 'Ссылка',
      'url': 'URL',
      'location': 'Местоположение',
      'place': 'Место',
      'venue': 'Место проведения',
      'repeat': 'Повтор',
      'recurrence': 'Повторение',
      'frequency': 'Частота',
      'interval': 'Интервал',
      'color': 'Цвет',
      'icon': 'Иконка',
      'image': 'Изображение',
      'photo': 'Фото',
      'avatar': 'Аватар',
      'visibility': 'Видимость',
      'access': 'Доступ',
      'permission': 'Разрешение',
      'permissions': 'Разрешения',
      'role': 'Роль',
      'roles': 'Роли',
      'setting': 'Настройка',
      'settings': 'Настройки',
      'configuration': 'Конфигурация',
      'custom_field': 'Пользовательское поле',
      'custom_fields': 'Пользовательские поля',
      'field': 'Поле',
      'value': 'Значение',
      'old_value': 'Старое значение',
      'new_value': 'Новое значение',
      'previous': 'Предыдущее',
      'current': 'Текущее',
      'next': 'Следующее',
    };
    
    // Пробуем разные варианты
    String normalized = field.toLowerCase().trim();
    
    // Заменяем подчеркивания на пробелы для поиска
    String withSpaces = normalized.replaceAll('_', ' ');
    
    // Ищем перевод
    if (translations.containsKey(normalized)) {
      return translations[normalized]!;
    } else if (translations.containsKey(withSpaces)) {
      return translations[withSpaces]!;
    }
    
    // Если не найден, возвращаем оригинал с заглавной буквы
    return field.split('_').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  String _translateStatus(String status) {
    // Переводы статусов
    final translations = {
      'created': 'Создано',
      'updated': 'Обновлено',
      'deleted': 'Удалено',
      'completed': 'Завершено',
      'started': 'Начато',
      'paused': 'Приостановлено',
      'resumed': 'Возобновлено',
      'cancelled': 'Отменено',
      'assigned': 'Назначено',
      'reassigned': 'Переназначено',
      'commented': 'Комментарий добавлен',
      'status changed': 'Статус изменён',
      'priority changed': 'Приоритет изменён',
      'deadline changed': 'Дедлайн изменён',
      'file attached': 'Файл прикреплён',
      'file removed': 'Файл удалён',
    };
    
    return translations[status.toLowerCase()] ?? status;
  }

  // ✨ КРАСИВАЯ История выполнения
  Widget _buildOverdueHistory() {
    return BlocBuilder<TaskOverdueHistoryBloc, TaskOverdueHistoryState>(
      builder: (context, state) {
        if (state is TaskOverdueHistoryLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xff1E2E52),
            ),
          );
        } else if (state is TaskOverdueHistoryLoaded) {
          if (state.history.isEmpty) {
            return _buildEmptyState('История выполнения пуста');
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: state.history.length,
            itemBuilder: (context, index) {
              return _buildOverdueHistoryItem(state.history[index]);
            },
          );
        } else if (state is TaskOverdueHistoryError) {
          return _buildErrorState(state.message);
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
              color: const Color(0xFFE5E7EB),
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
                color: _getBorderColorForType(item.type).withOpacity(0.3),
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
                        color: _getTextColorForType(item.type).withOpacity(0.7),
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
                      color: _getTextColorForType(item.type).withOpacity(0.8),
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
    final textColor = _getTextColorForType(type).withOpacity(0.9);
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
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          item,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Gilroy',
            color: textColor,
          ),
        ),
      )).toList(),
    );
  }

  // Цветовая схема - чистая и компактная
  Color _getBackgroundColorForType(String type) {
    switch (type) {
      case 'overdue':
        return const Color(0xFFFEF2F2); // Светло-красный
      case 'finished':
        return const Color(0xFFF0FDF4); // Светло-зелёный
      case 'change_deadline':
        return const Color(0xFFF0F9FF); // Светло-голубой
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_outlined,
              size: 48,
              color: Color(0xff9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              color: Color(0xFF6B7280),
            ),
          ),
        ],
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
