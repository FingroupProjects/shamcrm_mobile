import 'package:crm_task_manager/custom_widget/custom_card_my-tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart'; // Импорт Flutter фреймворка
import 'package:intl/intl.dart'; // Импорт для форматирования даты

/// Класс виджета для отображения карточки задачи
class MyTaskCard extends StatefulWidget {
  final MyTask task;
  final String name;
  final int statusId;
  final VoidCallback onStatusUpdated;
  final int? user;
  final int? userId;
  final void Function(int newStatusId) onStatusId;

  MyTaskCard({
    required this.task,
    required this.name,
    required this.statusId,
    required this.onStatusUpdated,
    this.user,
    this.userId,
    required this.onStatusId,
  });

  @override
  _MyTaskCardState createState() => _MyTaskCardState();
}

class _MyTaskCardState extends State<MyTaskCard> {
  late String dropdownValue;
  late int statusId;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.name;
    statusId = widget.statusId;
  }

  String formatDate(String? dateString) {
    if (dateString == null)
      return AppLocalizations.of(context)!.translate('date_not');
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('Invalid_date_format');
    }
  }

  int _getOverdueDays(String? endDateString) {
    if (endDateString == null) return 0;
    try {
      DateTime endDate = DateTime.parse(endDateString);
      DateTime now = DateTime.now();
      return endDate.isBefore(now) ? now.difference(endDate).inDays : 0;
    } catch (e) {
      return 0;
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
        final backgroundColor =
            extractBackgroundColorFromSvg(svg) ?? Color(0xFF2C2C2C);

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
            builder: (context) => MyTaskDetailsScreen(
              taskId:
                  widget.task.id.toString(), // ID задачи для детального экрана
              taskName: widget.task.name ??
                  AppLocalizations.of(context)!
                      .translate('no_name'), // Название задачи
              startDate: widget.task.startDate, // Дата начала задачи
              taskNumber: widget.task.taskNumber,
              endDate: widget.task.endDate, // Дата окончания задачи
              taskStatus: dropdownValue, // Текущий статус задачи
              statusId: widget.statusId, // ID статуса задачи
              description: widget.task.description, // Описание задачи
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        decoration:
            MyTaskCardStyles.taskCardDecoration, // Стиль карточки задачи
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: widget.task.name ??
                            AppLocalizations.of(context)!.translate('no_name'),
                        style: MyTaskCardStyles.titleStyle,
                        children: const <TextSpan>[
                          TextSpan(
                            text:
                                '\n\u200B', // Невидимый пробел (Zero Width Space)
                            style: TaskCardStyles.titleStyle,
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate(
                        'column'), // Надпись "Колонка" для статуса задачи
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
              Padding(
                padding: const EdgeInsets.all(2), // Отступы
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Пространство между элементами
                  children: [
                    // Date section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Date icon
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            (widget.task.overdue != null &&
                                    widget.task.overdue! > 0)
                                ? const Color.fromARGB(255, 198, 40, 40)
                                : const Color(0xff99A4BA),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/icons/tabBar/date.png',
                            width: 24,
                            height: 36,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(
                              widget.task.endDate ?? DateTime.now().toString()),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: (widget.task.overdue != null &&
                                    widget.task.overdue! > 0)
                                ? const Color.fromARGB(255, 198, 40, 40)
                                : const Color(0xff99A4BA),
                          ),
                        ),
                      ],
                    ),
                    // Overdue indicator, positioned 10px from the right
                    if (widget.task.overdue != null && widget.task.overdue! > 0)
                      Container(
                        margin: const EdgeInsets.only(
                            right: 10), // Strictly 10px from the right
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 253, 98, 87),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.task.overdue.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily:
                                  'Gilroy', // Ensure consistent font (if used elsewhere)
                              fontWeight: FontWeight.w500, // Consistent weight
                              height:
                                  1.0, // Set line height to 1.0 to remove extra vertical space
                            ),
                            textAlign: TextAlign
                                .center, // Ensure text is centered horizontally
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
