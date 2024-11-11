import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Класс виджета для отображения карточки задачи
class TaskCard extends StatefulWidget {
  final Task task; // Модель данных задачи
  final String name; // Имя текущего статуса задачи
  final int statusId; // ID текущего статуса задачи
  final VoidCallback onStatusUpdated; // Коллбек при обновлении статуса задачи
  final String? project; // Название проекта (необязательно)
  final int? projectId; // ID проекта (необязательно)
  final int? user; // ID пользователя, ответственного за задачу (необязательно)
  final int? userId; // ID пользователя, который создал задачу (необязательно)

  TaskCard({
    required this.task,
    required this.name,
    required this.statusId,
    required this.onStatusUpdated,
    this.project,
    this.projectId,
    this.user,
    this.userId,
  });

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late String dropdownValue; // Хранит выбранный статус задачи для выпадающего списка

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.name; // Инициализация статуса задачи
  }

  /// Функция для форматирования даты из строки в формат `dd-MM-yyyy`
  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Переход на экран деталей задачи при нажатии на карточку
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              taskId: widget.task.id.toString(),
              taskName: widget.task.name ?? 'Без имени',
              startDate: widget.task.startDate,
              endDate: widget.task.endDate,
              taskStatus: dropdownValue,
              statusId: widget.statusId,
              description: widget.task.description,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12), // Внутренние отступы карточки
        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0), // Внешние отступы, с уменьшенными горизонтальными
        decoration: TaskCardStyles.taskCardDecoration, // Декорация карточки
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя строка с названием задачи и приоритетом
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Название задачи
                  child: Text(
                    widget.task.name ?? 'Без имени',
                    
                    style: TaskCardStyles.titleStyle,
                    overflow: TextOverflow.ellipsis, // Обрезка текста, если он длинный
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(widget.task.priority), // Цвет приоритета
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPriorityText(widget.task.priority), // Текст приоритета
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            // Строка с названием колонки и выпадающим списком для статусов
            Row(
              children: [
                const Text(
                  'Колонка: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    // Обработка клика для отображения выпадающего списка статусов
                    onTap: () {
                      DropdownBottomSheet(
                        context,
                        dropdownValue,
                        (String newValue) {
                          setState(() {
                            dropdownValue = newValue; // Обновление статуса в интерфейсе
                          });
                          widget.onStatusUpdated(); // Вызов коллбека при изменении статуса
                        },
                        widget.task,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xff1E2E52),
                          width: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            // Текущий выбранный статус
                            child: Text(
                              dropdownValue,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Color(0xff1E2E52),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/icons/tabBar/dropdown.png',
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 38),
            // Нижняя строка с датами начала и окончания задачи
            Row(
              children: [
                // Дата начала задачи
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/tabBar/date.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(widget.task.startDate ?? DateTime.now().toString()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Дата окончания задачи (если есть)
                if (widget.task.endDate != null)
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/tabBar/date.png',
                        width: 17,
                        height: 17,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(widget.task.endDate!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Метод для получения цвета приоритета
  /// Задает цвет в зависимости от числового значения приоритета
  Color _getPriorityColor(int? priority) {
    switch (priority) {
      case 1:
        return Colors.green; // Обычный
      case 2:
        return Colors.red;   // Критический
      case 3:
        return Colors.orange; // Сложный
      default:
        return Colors.green; // По умолчанию "Обычный"
    }
  }

  /// Метод для получения текста приоритета
  /// Возвращает текстовое представление приоритета в зависимости от его значения
  String _getPriorityText(int? priority) {
    switch (priority) {
      case 1:
        return 'Обычный';
      case 2:
        return 'Критический';
      case 3:
        return 'Сложный';
      default:
        return 'Обычный';
    }
  }
}
