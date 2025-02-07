import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart'; // Импорт кастомного виджета для задач в TabBar
import 'package:crm_task_manager/models/task_model.dart'; // Импорт модели задачи
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart'; // Импорт экрана деталей задачи
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart'; // Импорт виджета выпадающего диалога для выбора статуса задачи
import 'package:flutter/material.dart'; // Импорт Flutter фреймворка
import 'package:intl/intl.dart'; // Импорт для форматирования даты

/// Класс виджета для отображения карточки задачи
class TaskCard extends StatefulWidget {
  final Task task; // Модель данных задачи
  final String name; // Имя текущего статуса задачи
  final int statusId; // ID текущего статуса задачи
  final VoidCallback onStatusUpdated; // Коллбек для обновления статуса задачи
  final String? project; // Название проекта (опционально)
  final int? projectId; // ID проекта (опционально)
  final int? user; // ID ответственного пользователя (опционально)
  final int? userId; // ID пользователя, создавшего задачу (опционально)
  final List<UserTaskImage>? usersImage;
  final void Function(int newStatusId) onStatusId;

  TaskCard({
    required this.task,
    required this.name,
    required this.statusId,
    required this.onStatusUpdated,
    this.project,
    this.projectId,
    this.user,
    this.usersImage,
    this.userId,
    required this.onStatusId,
  });

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late String
      dropdownValue; // Текущее значение выпадающего списка статусов задачи
  late int statusId;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.name;
    statusId = widget.statusId;
  }

  /// Форматирование даты в `dd-MM-yyyy`
  String formatDate(String dateString) {
    DateTime dateTime =
        DateTime.parse(dateString); // Преобразование строки в дату
    return DateFormat('dd.MM.yyyy').format(dateTime); // Форматирование даты
  }

  /// Получение количества просроченных дней
  int _getOverdueDays(String? endDateString) {
    if (endDateString == null) return 0;

    DateTime endDate = DateTime.parse(endDateString);
    DateTime now = DateTime.now();

    // Только если дата уже прошла
    if (endDate.isBefore(now)) {
      return now.difference(endDate).inDays;
    }

    return 0;
  }

  /// Получение цвета фона для приоритета задачи
  Color _getPriorityBackgroundColor(int? priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFE8F5E9); // Цвет для обычного приоритета
      case 3:
        return const Color(0xFFFFEBEE); // Цвет для критического приоритета
      case 2:
        return const Color(0xFFFFF3E0); // Цвет для сложного приоритета
      default:
        return const Color(0xFFE8F5E9); // Цвет по умолчанию
    }
  }

  /// Получение цвета текста для приоритета задачи
  Color _getPriorityTextColor(int? priority) {
    switch (priority) {
      case 1:
        return const Color(0xFF2E7D32); // Цвет для обычного приоритета
      case 3:
        return const Color(0xFFC62828); // Цвет для критического приоритета
      case 2:
        return const Color(0xFFEF6C00); // Цвет для сложного приоритета
      default:
        return const Color(0xFF2E7D32); // Цвет по умолчанию
    }
  }

  /// Получение текстового представления приоритета
String _getPriorityText(int? priority, BuildContext context) {
  switch (priority) {
    case 1:
      return AppLocalizations.of(context)!.translate('normal'); 
    case 3:
      return AppLocalizations.of(context)!.translate('urgent'); 
    case 2:
      return AppLocalizations.of(context)!.translate('important'); 
    default:
      return AppLocalizations.of(context)!.translate('normal');
  }
}

  /// Получение инициалов пользователя из имени
  String _getUserInitials(String name) {
    final parts = name.split(' '); // Разделение имени на части
    if (parts.length == 1) {
      return parts[0][0]; // Если только одно слово, берем первую букву
    } else if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'; // Если больше двух, берем первые буквы двух слов
    }
    return '';
  }


 @override
Widget build(BuildContext context) {
  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  Color? extractBackgroundColorFromSvg(String svg) {
    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    if (fillMatch != null) {
      final colorHex = fillMatch.group(1);
      if (colorHex != null) {
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  Widget buildSvgAvatar(String svg, {double size = 32}) {
    if (svg.contains('image href=')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(extractImageUrlFromSvg(svg) ?? ''),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      final backgroundColor = extractBackgroundColorFromSvg(svg) ?? Color(0xFF2C2C2C);
      
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: EdgeInsets.all(size * 0.3),
              child: Text(
                RegExp(r'>([^<]+)</text>').firstMatch(svg)?.group(1) ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
  }

    // Получаем количество просроченных дней
    int overdueDays = _getOverdueDays(widget.task.endDate);

    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(
                taskId: widget.task.id.toString(), // ID задачи для детального экрана
                taskNumber: widget.task.taskNumber,
                taskName: widget.task.name ?? AppLocalizations.of(context)!.translate('no_name'), // Название задачи
                startDate: widget.task.startDate, // Дата начала задачи
                endDate: widget.task.endDate, // Дата окончания задачи
                taskStatus: dropdownValue, // Текущий статус задачи
                statusId: widget.statusId, // ID статуса задачи
                priority: widget.task.priority, // Приоритет задачи
                description: widget.task.description, // Описание задачи
                project: widget.task.project?.name ?? widget.project ?? AppLocalizations.of(context)!.translate('no_project'),
                taskCustomFields: widget.task.taskCustomFields,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          decoration:
          TaskCardStyles.taskCardDecoration, // Стиль карточки задачи
          child: Stack(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.name ?? AppLocalizations.of(context)!.translate('no_name'), // Название задачи
                        style:TaskCardStyles.titleStyle, // Стиль заголовка задачи
                        overflow: TextOverflow.ellipsis, // Обрезка текста, если не помещается
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityBackgroundColor( widget.task.priority), // Цвет фона приоритета
                        borderRadius: BorderRadius.circular(16), // Радиус скругления
                      ),
                      child: Text(
                        _getPriorityText(widget.task.priority, context),// Текст приоритета
                        style: TextStyle(
                          color: _getPriorityTextColor(widget.task.priority), // Цвет текста приоритета
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 0), 
                Text(
                  widget.task.project?.name ?? AppLocalizations.of(context)!.translate('no_project'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff99A4BA),
                  ),
                ),
                const SizedBox(height: 0),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('column'), 
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    IntrinsicWidth(
                      child: GestureDetector(
                        onTap: () {
                          DropdownBottomSheet(
                            context,
                            dropdownValue,
                            (String newValue, int newStatusId) {
                              setState(() {
                                dropdownValue = newValue;
                                statusId = newStatusId;
                              });
                              widget.onStatusId(newStatusId);
                              widget.onStatusUpdated();
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        200), //Размер колонки Выбора Статуса
                                child: Text(
                                  dropdownValue,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52),
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 5),
                Row(
                  children: [
                    widget.task.usersImage != null &&
                            widget.task.usersImage!.isNotEmpty
                        ? Stack(
                            children: [
                              if (widget.task.usersImage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: widget.task.usersImage![0].image
                                          .startsWith('<svg')
                                      ? buildSvgAvatar(
                                          widget.task.usersImage![0].image)
                                      : Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: NetworkImage(widget
                                                  .task.usersImage![0].image),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                ),
                              if (widget.task.usersImage!.length > 1)
                                Positioned(
                                  left: 20,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: widget.task.usersImage![1].image
                                            .isNotEmpty
                                        ? widget.task.usersImage![1].image
                                                .startsWith('<svg')
                                            ? buildSvgAvatar(widget
                                                .task.usersImage![1].image)
                                            : Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: NetworkImage(widget
                                                        .task
                                                        .usersImage![1]
                                                        .image),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              )
                                        : const CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.purple,
                                          ),
                                  ),
                                ),
                            ],
                          )
                        : const SizedBox(),

                    // Display the count of additional users
                    if (widget.task.usersImage != null &&
                        widget.task.usersImage!.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          '+${widget.task.usersImage!.length - 2}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                  ],
                ),
                // const SizedBox(height: 5),
                Row(
                  children: [
                    const SizedBox(width: 1),
                    if (widget.task.user?.name !=
                        null) // Проверка на наличие имени пользователя
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 51, 65,
                                  98), // Фон иконки инициалов пользователя
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _getUserInitials(widget.task.user!
                                  .name), // Отображение инициалов пользователя
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.all(0), // Отступы
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Пространство между элементами
                        children: [
                          // Иконка и текст даты
                          Row(
                            crossAxisAlignment: CrossAxisAlignment
                                .center, // Выровнять по центру по вертикали
                            children: [
                              // Используем ColorFiltered для изменения цвета иконки
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  overdueDays > 0
                                      ? const Color.fromARGB(255, 198, 40, 40)
                                      : const Color(
                                          0xff99A4BA), // Красный цвет, если просрочено, иначе обычный
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  'assets/icons/tabBar/date.png', // Иконка даты
                                  width: 24,
                                  height: 36,
                                ),
                              ),
                              const SizedBox(
                                  width: 4), // Отступ между иконкой и текстом
                              Text(
                                formatDate(widget.task.endDate ??
                                    DateTime.now().toString()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: overdueDays > 0
                                      ? const Color.fromARGB(255, 198, 40, 40)
                                      : const Color(
                                          0xff99A4BA), // Красный цвет, если просрочено, иначе обычный
                                ),
                              ),
                            ],
                          ),

                          if (widget.task.overdue! > 0)
                            Padding(
                              padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.50,
                              ),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 253, 98, 87),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.task.overdue.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
            ],
          ),
        ));
  }
}
